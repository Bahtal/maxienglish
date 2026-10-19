import { createClient } from 'npm:@supabase/supabase-js@2'

const appUrl = 'https://maxienglish-33b6c.web.app'
const encoder = new TextEncoder()

function constantTimeEqual(left: string, right: string) {
  if (left.length !== right.length) return false
  let difference = 0
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index)
  }
  return difference === 0
}

async function sha256Hex(value: string) {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', encoder.encode(value)))
  return Array.from(digest, (byte) => byte.toString(16).padStart(2, '0')).join('')
}

async function sendBotMessage(token: string, chatId: number, text: string, withAppButton = false) {
  const response = await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      chat_id: chatId,
      text,
      disable_web_page_preview: true,
      ...(withAppButton ? {
        reply_markup: {
          inline_keyboard: [[{ text: 'Открыть приложение', web_app: { url: appUrl } }]],
        },
      } : {}),
    }),
    signal: AbortSignal.timeout(10_000),
  })
  const result = await response.json().catch(() => ({}))
  if (!response.ok || !result.ok) {
    throw new Error(result.description || `Telegram returned HTTP ${response.status}`)
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405 })
  }

  const expectedSecret = Deno.env.get('TELEGRAM_WEBHOOK_SECRET') ?? ''
  const receivedSecret = request.headers.get('x-telegram-bot-api-secret-token') ?? ''
  if (!expectedSecret || !constantTimeEqual(receivedSecret, expectedSecret)) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const body = await request.json()
    const message = body?.message
    const sender = message?.from
    const chat = message?.chat
    const text = typeof message?.text === 'string' ? message.text.trim() : ''

    if (chat?.type !== 'private'
      || !Number.isSafeInteger(sender?.id)
      || sender.id <= 0
      || sender.is_bot
      || !Number.isSafeInteger(chat.id)) {
      return Response.json({ ok: true })
    }

    const startCommand = text.match(/^\/start(?:@\w+)?(?:\s+([A-Za-z0-9_-]+))?$/)
    if (!startCommand) return Response.json({ ok: true })

    const botToken = Deno.env.get('TELEGRAM_BOT_TOKEN')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const adminKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY')
    if (!botToken || !supabaseUrl || !adminKey) {
      throw new Error('Telegram webhook secrets are not configured')
    }

    const admin = createClient(supabaseUrl, adminKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const startPayload = startCommand[1] ?? ''
    if (!startPayload) {
      const { data: profile, error: profileError } = await admin
        .from('profiles')
        .select('id, role')
        .eq('telegram_id', sender.id)
        .maybeSingle()
      if (profileError) throw profileError

      if (profile?.role === 'teacher') {
        await sendBotMessage(botToken, chat.id, 'Добро пожаловать в MaxiEnglish! Откройте приложение кнопкой ниже.', true)
        return Response.json({ ok: true })
      }

      if (profile) {
        const { data: student, error: studentError } = await admin
          .from('students')
          .select('id, auth_user_id')
          .eq('telegram_id', sender.id)
          .maybeSingle()
        if (studentError) throw studentError

        if (student && (!student.auth_user_id || student.auth_user_id === profile.id)) {
          if (!student.auth_user_id) {
            const { data: existingLink, error: existingLinkError } = await admin
              .from('students')
              .select('id')
              .eq('auth_user_id', profile.id)
              .maybeSingle()
            if (existingLinkError) throw existingLinkError

            if (existingLink && existingLink.id !== student.id) {
              await sendBotMessage(botToken, chat.id, 'Этот Telegram-аккаунт уже привязан к другой записи ученика. Попросите преподавателя проверить привязку.')
              return Response.json({ ok: true })
            }

            const { error: linkError } = await admin
              .from('students')
              .update({ auth_user_id: profile.id })
              .eq('id', student.id)
              .is('auth_user_id', null)
            if (linkError) throw linkError
          }

          await sendBotMessage(botToken, chat.id, 'Ваш профиль ученика подключён. Откройте приложение кнопкой ниже.', true)
          return Response.json({ ok: true })
        }
      }

      await sendBotMessage(
        botToken,
        chat.id,
        'Чтобы подключить профиль, откройте персональную ссылку-приглашение от преподавателя и нажмите Start на странице бота. Команда /start без ссылки не передаёт приглашение.',
      )
      return Response.json({ ok: true })
    }

    const inviteToken = startPayload.match(/^i_([a-f0-9]{48})$/)?.[1]
    if (!inviteToken) {
      await sendBotMessage(botToken, chat.id, 'Не удалось распознать приглашение. Попросите преподавателя прислать новую ссылку.')
      return Response.json({ ok: true })
    }

    const { data, error } = await admin.rpc('accept_student_invitation', {
      p_token_hash: await sha256Hex(inviteToken),
      p_telegram_user_id: sender.id,
      p_telegram_username: typeof sender.username === 'string' ? sender.username : null,
      p_telegram_full_name: [sender.first_name, sender.last_name]
        .filter((part) => typeof part === 'string' && part.trim())
        .join(' ')
        .slice(0, 120),
    })
    if (error) throw error

    const result = data as { status?: string; student_name?: string; teacher_name?: string } | null
    if (result?.status === 'accepted') {
      await sendBotMessage(
        botToken,
        chat.id,
        `Привет, ${result.student_name || 'ученик'}! 👋\nВы подключены к кабинету преподавателя ${result.teacher_name || 'преподавателя'}. Откройте приложение кнопкой ниже.`,
        true,
      )
    } else if (result?.status === 'already_linked') {
      await sendBotMessage(botToken, chat.id, 'Это приглашение уже активировано в вашем аккаунте. Откройте приложение кнопкой ниже.', true)
    } else if (result?.status === 'wrong_account_type') {
      await sendBotMessage(botToken, chat.id, 'Это приглашение предназначено для аккаунта ученика. Откройте его из аккаунта ученика.')
    } else if (result?.status === 'account_already_linked') {
      await sendBotMessage(botToken, chat.id, 'Этот Telegram-аккаунт уже привязан к другому ученику. Попросите преподавателя проверить привязку.')
    } else {
      await sendBotMessage(botToken, chat.id, 'Приглашение недействительно, уже использовано или истекло. Попросите преподавателя создать новое.')
    }

    return Response.json({ ok: true })
  } catch (error) {
    console.error('Telegram bot webhook failed', error)
    return Response.json({ error: 'Webhook processing failed' }, { status: 500 })
  }
})
