import { createClient } from 'npm:@supabase/supabase-js@2'

const appUrl = 'https://maxienglish-33b6c.web.app'

function constantTimeEqual(left: string, right: string) {
  if (left.length !== right.length) return false
  let difference = 0
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index)
  }
  return difference === 0
}

function localParts(date: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date)
  const values = Object.fromEntries(parts.map(({ type, value }) => [type, value]))
  return {
    year: Number(values.year),
    month: Number(values.month),
    day: Number(values.day),
    hour: Number(values.hour),
    minute: Number(values.minute),
  }
}

function localDateKey({ year, month, day }: { year: number; month: number; day: number }) {
  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
}

function zonedMidnightUtc(dateKey: string, timeZone: string) {
  const [year, month, day] = dateKey.split('-').map(Number)
  const target = Date.UTC(year, month - 1, day)
  let estimate = target

  for (let attempt = 0; attempt < 3; attempt += 1) {
    const local = localParts(new Date(estimate), timeZone)
    const represented = Date.UTC(local.year, local.month - 1, local.day, local.hour, local.minute)
    estimate += target - represented
  }

  return new Date(estimate)
}

function previousWeekRange(now: Date, timeZone: string) {
  const current = localParts(now, timeZone)
  const currentDate = new Date(Date.UTC(current.year, current.month - 1, current.day))
  const daysFromMonday = (currentDate.getUTCDay() + 6) % 7
  const monday = new Date(currentDate)
  monday.setUTCDate(monday.getUTCDate() - daysFromMonday)
  const previousMonday = new Date(monday)
  previousMonday.setUTCDate(previousMonday.getUTCDate() - 7)
  const previousSunday = new Date(monday)
  previousSunday.setUTCDate(previousSunday.getUTCDate() - 1)
  const mondayKey = localDateKey({
    year: monday.getUTCFullYear(),
    month: monday.getUTCMonth() + 1,
    day: monday.getUTCDate(),
  })
  const startKey = localDateKey({
    year: previousMonday.getUTCFullYear(),
    month: previousMonday.getUTCMonth() + 1,
    day: previousMonday.getUTCDate(),
  })
  const endKey = mondayKey
  const sundayKey = localDateKey({
    year: previousSunday.getUTCFullYear(),
    month: previousSunday.getUTCMonth() + 1,
    day: previousSunday.getUTCDate(),
  })

  return {
    mondayKey,
    start: zonedMidnightUtc(startKey, timeZone),
    end: zonedMidnightUtc(endKey, timeZone),
    label: `${new Intl.DateTimeFormat('ru-RU', { timeZone, day: '2-digit', month: '2-digit' }).format(zonedMidnightUtc(startKey, timeZone))}–${new Intl.DateTimeFormat('ru-RU', { timeZone, day: '2-digit', month: '2-digit', year: 'numeric' }).format(zonedMidnightUtc(sundayKey, timeZone))}`,
  }
}

async function queueWeeklyReports(admin: ReturnType<typeof createClient>) {
  const now = new Date()
  const { data: teachers, error } = await admin
    .from('profiles')
    .select('id, full_name, timezone')
    .eq('role', 'teacher')
    .not('telegram_id', 'is', null)
  if (error) throw error

  let queued = 0
  for (const teacher of teachers ?? []) {
    const timeZone = teacher.timezone || 'Europe/Volgograd'
    let current: ReturnType<typeof localParts>
    try {
      current = localParts(now, timeZone)
    } catch {
      current = localParts(now, 'Europe/Volgograd')
    }

    // Queue once the local Monday window has started. The stable event key
    // below makes the minute-by-minute cron safe and gives missed runs a catch-up.
    const localDate = new Date(Date.UTC(current.year, current.month - 1, current.day))
    if (localDate.getUTCDay() !== 1 || current.hour < 9) continue

    const range = previousWeekRange(now, timeZone)
    const [lessonsResult, paymentsResult, upcomingResult, unpaidResult] = await Promise.all([
      admin.from('lessons').select('status').eq('teacher_id', teacher.id).gte('starts_at', range.start.toISOString()).lt('starts_at', range.end.toISOString()),
      admin.from('payments').select('amount_rub').eq('teacher_id', teacher.id).eq('status', 'confirmed').gte('confirmed_at', range.start.toISOString()).lt('confirmed_at', range.end.toISOString()),
      admin.from('lessons').select('id', { count: 'exact', head: true }).eq('teacher_id', teacher.id).eq('status', 'scheduled').gte('starts_at', now.toISOString()).lt('starts_at', new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString()),
      admin.from('students').select('id', { count: 'exact', head: true }).eq('teacher_id', teacher.id).eq('is_confirmed', true).eq('payment_status', 'unpaid'),
    ])
    for (const result of [lessonsResult, paymentsResult, upcomingResult, unpaidResult]) {
      if (result.error) throw result.error
    }

    const lessons = lessonsResult.data ?? []
    const completed = lessons.filter((lesson) => lesson.status === 'completed').length
    const cancelled = lessons.filter((lesson) => lesson.status === 'cancelled').length
    const earned = (paymentsResult.data ?? []).reduce((sum, payment) => sum + Number(payment.amount_rub || 0), 0)
    const body = [
      `📊 Итоги недели: ${range.label}`,
      `⭐️Проведено уроков: ${completed}`,
      `🦥Отменено: ${cancelled}`,
      `🌼Подтверждено оплат: ${new Intl.NumberFormat('ru-RU').format(earned)} ₽`,
      `Предстоит в ближайшие 7 дней: ${upcomingResult.count ?? 0}`,
      `🌬️Учеников без оплаченных занятий: ${unpaidResult.count ?? 0}`,
      `Открыть приложение: ${appUrl}`,
    ].join('\n')
    const { error: queueError } = await admin.from('telegram_message_queue').upsert({
      event_key: `weekly-summary:${teacher.id}:${range.mondayKey}`,
      recipient_profile_id: teacher.id,
      message: body,
    }, { onConflict: 'event_key', ignoreDuplicates: true })
    if (queueError) throw queueError
    queued += 1
  }
  return queued
}

async function sendTelegramMessage(token: string, chatId: number, text: string) {
  let response: Response
  try {
    response = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: chatId, text, disable_web_page_preview: true }),
      signal: AbortSignal.timeout(10_000),
    })
  } catch (cause) {
    const error = new Error(cause instanceof Error ? cause.message : 'Telegram network request failed')
    Object.assign(error, { retryable: true })
    throw error
  }
  const result = await response.json().catch(() => ({}))
  if (!response.ok || !result.ok) {
    const error = new Error(result.description || `Telegram returned HTTP ${response.status}`)
    Object.assign(error, { retryable: response.status === 429 || response.status >= 500 })
    throw error
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405 })
  }

  const expectedSecret = Deno.env.get('TELEGRAM_CRON_SECRET')
  const receivedSecret = request.headers.get('x-telegram-cron-secret') ?? ''
  if (!expectedSecret || !constantTimeEqual(receivedSecret, expectedSecret)) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const adminKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY')
    const botToken = Deno.env.get('TELEGRAM_BOT_TOKEN')
    if (!supabaseUrl || !adminKey || !botToken) {
      throw new Error('Telegram notification secrets are not configured')
    }

    const admin = createClient(supabaseUrl, adminKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const { error: reminderError } = await admin.rpc('enqueue_telegram_lesson_reminders')
    if (reminderError) throw reminderError
    const weeklyQueued = await queueWeeklyReports(admin)
    const { data: messages, error: claimError } = await admin.rpc('claim_telegram_messages', { p_limit: 50 })
    if (claimError) throw claimError

    const queue = messages ?? []
    const profileIds = [...new Set(
      queue
        .map((item) => item.recipient_profile_id)
        .filter((profileId): profileId is string => Boolean(profileId)),
    )]
    const { data: profiles, error: profilesError } = profileIds.length
      ? await admin.from('profiles').select('id, telegram_id').in('id', profileIds)
      : { data: [], error: null }
    if (profilesError) throw profilesError

    const telegramIds = new Map((profiles ?? []).map((profile) => [profile.id, profile.telegram_id]))
    let sent = 0
    let failed = 0
    for (const item of queue) {
      const telegramId = item.telegram_chat_id
        ?? (item.recipient_profile_id ? telegramIds.get(item.recipient_profile_id) : undefined)
      try {
        if (!telegramId) throw Object.assign(new Error('Telegram account is not linked'), { retryable: false })
        await sendTelegramMessage(botToken, Number(telegramId), item.message)
        const { error } = await admin.from('telegram_message_queue').update({
          status: 'sent',
          sent_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          last_error: '',
        }).eq('id', item.id)
        if (error) throw error
        sent += 1
      } catch (error) {
        const retryable = Boolean((error as Error & { retryable?: boolean }).retryable)
        const errorMessage = String((error as Error)?.message || error)
        const waitingForTelegramStart = Boolean(item.telegram_chat_id)
          && /can't initiate conversation|chat not found|bot was blocked/i.test(errorMessage)
          && Date.now() - new Date(item.created_at).getTime() < 30 * 24 * 60 * 60_000
        const canRetry = (retryable && item.attempt_count < 8) || waitingForTelegramStart
        const delayMinutes = Math.min(5 * 2 ** Math.max(0, item.attempt_count - 1), 360)
        const { error: updateError } = await admin.from('telegram_message_queue').update({
          status: canRetry ? 'pending' : 'failed',
          next_attempt_at: new Date(Date.now() + (waitingForTelegramStart ? 5 : delayMinutes) * 60_000).toISOString(),
          updated_at: new Date().toISOString(),
          last_error: errorMessage.slice(0, 500),
        }).eq('id', item.id)
        if (updateError) console.error('Could not update Telegram queue item', updateError.message)
        failed += 1
      }
    }

    return Response.json({ ok: true, sent, failed, weeklyQueued })
  } catch (error) {
    console.error('Telegram notification cycle failed', error)
    return Response.json({ error: 'Telegram notification cycle failed' }, { status: 500 })
  }
})
