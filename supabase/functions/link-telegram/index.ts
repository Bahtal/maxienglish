import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const encoder = new TextEncoder()
const avatarBucket = 'profile-avatars'
const maxAvatarBytes = 5 * 1024 * 1024

class TelegramValidationError extends Error {}

function hex(bytes: Uint8Array) {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('')
}

async function hmac(keyBytes: Uint8Array, message: string | Uint8Array) {
  const key = await crypto.subtle.importKey(
    'raw', keyBytes,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const data = typeof message === 'string' ? encoder.encode(message) : message
  return new Uint8Array(await crypto.subtle.sign('HMAC', key, data))
}

function constantTimeEqual(left: string, right: string) {
  if (left.length !== right.length) return false
  let difference = 0
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index)
  }
  return difference === 0
}

async function storeTelegramPhoto(
  admin: ReturnType<typeof createClient>,
  profileId: string,
  photoUrl: string | null,
  previousPath: string | null,
  previousUrl: string | null,
) {
  const storage = admin.storage.from(avatarBucket)
  if (!photoUrl) {
    if (previousPath) {
      const { error } = await storage.remove([previousPath])
      if (error) console.warn('Could not remove hidden Telegram profile photo', error.message)
    }
    return { avatarPath: null, avatarUrl: null }
  }
  if (previousPath && previousUrl === photoUrl) {
    return { avatarPath: previousPath, avatarUrl: photoUrl }
  }

  try {
    const response = await fetch(photoUrl, { signal: AbortSignal.timeout(6000) })
    if (!response.ok) throw new Error(`Telegram photo returned HTTP ${response.status}`)

    const contentType = (response.headers.get('content-type') ?? '').split(';')[0].trim().toLowerCase()
    const allowedTypes = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml'])
    if (!allowedTypes.has(contentType)) throw new Error('Telegram photo has an unsupported content type')

    const declaredLength = Number(response.headers.get('content-length') ?? 0)
    if (declaredLength > maxAvatarBytes) throw new Error('Telegram photo is too large')
    const photo = await response.arrayBuffer()
    if (photo.byteLength === 0 || photo.byteLength > maxAvatarBytes) throw new Error('Telegram photo has an invalid size')

    const path = `${profileId}/avatar`
    const { error } = await storage.upload(path, photo, {
      contentType,
      cacheControl: '3600',
      upsert: true,
    })
    if (error) throw error
    return { avatarPath: path, avatarUrl: photoUrl }
  } catch (error) {
    console.warn('Could not copy Telegram profile photo to Supabase Storage', error)
    return { avatarPath: null, avatarUrl: photoUrl }
  }
}

async function verifyTelegramInitData(initData: string, botToken: string) {
  if (!initData || initData.length > 8192) {
    throw new TelegramValidationError('Telegram data is missing or too large')
  }

  const params = new URLSearchParams(initData)
  const receivedHash = params.get('hash')
  const authDate = Number(params.get('auth_date'))
  const userValue = params.get('user')
  if (!receivedHash || !Number.isFinite(authDate) || !userValue) {
    throw new TelegramValidationError('Telegram data is incomplete')
  }

  const nowSeconds = Math.floor(Date.now() / 1000)
  if (authDate > nowSeconds + 30 || nowSeconds - authDate > 86400) {
    throw new TelegramValidationError('Telegram data has expired')
  }

  const checkString = Array.from(params.entries())
    .filter(([key]) => key !== 'hash')
    .sort(([left], [right]) => left < right ? -1 : left > right ? 1 : 0)
    .map(([key, value]) => `${key}=${value}`)
    .join('\n')

  // Telegram derives this key as HMAC(key="WebAppData", message=botToken).
  const secretKey = await hmac(encoder.encode('WebAppData'), botToken)
  const expectedHash = hex(await hmac(secretKey, checkString))
  if (!constantTimeEqual(expectedHash, receivedHash.toLowerCase())) {
    throw new TelegramValidationError('Telegram signature is invalid')
  }

  let user: {
    id?: unknown
    first_name?: unknown
    last_name?: unknown
    username?: unknown
    photo_url?: unknown
  }
  try {
    user = JSON.parse(userValue)
  } catch {
    throw new TelegramValidationError('Telegram user data is invalid')
  }
  const userId = user.id
  if (typeof userId !== 'number' || !Number.isSafeInteger(userId) || userId <= 0) {
    throw new TelegramValidationError('Telegram user ID is invalid')
  }

  const firstName = typeof user.first_name === 'string' ? user.first_name.trim() : ''
  const lastName = typeof user.last_name === 'string' ? user.last_name.trim() : ''
  let photoUrl: string | null = null
  if (typeof user.photo_url === 'string' && user.photo_url.length <= 2048) {
    try {
      const parsedPhotoUrl = new URL(user.photo_url)
      if (parsedPhotoUrl.protocol === 'https:') photoUrl = parsedPhotoUrl.toString()
    } catch {
      // Ignore invalid optional profile photos and keep the initials avatar.
    }
  }
  return {
    id: userId,
    fullName: [firstName, lastName].filter(Boolean).join(' '),
    username: typeof user.username === 'string' ? user.username : null,
    photoUrl,
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') {
    return Response.json({ error: 'Method not allowed' }, { status: 405, headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const adminKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY')
    const botToken = Deno.env.get('TELEGRAM_BOT_TOKEN')
    const authSecret = Deno.env.get('TELEGRAM_AUTH_SECRET')
    if (!supabaseUrl || !anonKey || !adminKey || !botToken || !authSecret) {
      throw new Error('Server authentication is not configured')
    }

    const body = await request.json()
    const telegramUser = await verifyTelegramInitData(String(body.initData ?? ''), botToken)
    const email = `tg-${telegramUser.id}@telegram.lessonly.invalid`
    const password = `Mx!${hex(await hmac(encoder.encode(authSecret), String(telegramUser.id)))}Aa7`
    const admin = createClient(supabaseUrl, adminKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
    const authClient = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    })

    let { data: profile, error: profileError } = await admin
      .from('profiles')
      .select('id, role, full_name, telegram_id, telegram_username, avatar_url, avatar_path')
      .eq('telegram_id', telegramUser.id)
      .maybeSingle()
    if (profileError) throw profileError

    if (!profile) {
      const { data: created, error: createError } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: telegramUser.fullName,
          telegram_id: telegramUser.id,
          telegram_username: telegramUser.username,
        },
      })
      if (createError) throw createError
      if (!created.user) throw new Error('Could not create the Telegram profile')

      const { data, error } = await admin
        .from('profiles')
        .update({
          telegram_id: telegramUser.id,
          telegram_username: telegramUser.username,
          full_name: telegramUser.fullName,
        })
        .eq('id', created.user.id)
        .select('id, role, full_name, telegram_id, telegram_username, avatar_url, avatar_path')
        .single()
      if (error) throw error
      profile = data
    } else {
      const { data, error } = await admin
        .from('profiles')
        .update({
          telegram_username: telegramUser.username,
          full_name: telegramUser.fullName,
        })
        .eq('id', profile.id)
        .select('id, role, full_name, telegram_id, telegram_username, avatar_url, avatar_path')
        .single()
      if (error) throw error
      profile = data
    }

    const storedPhoto = await storeTelegramPhoto(
      admin,
      profile.id,
      telegramUser.photoUrl,
      profile.avatar_path,
      profile.avatar_url,
    )
    const { data: refreshedProfile, error: avatarError } = await admin
      .from('profiles')
      .update({ avatar_url: storedPhoto.avatarUrl, avatar_path: storedPhoto.avatarPath })
      .eq('id', profile.id)
      .select('id, role, full_name, telegram_id, telegram_username, avatar_url, avatar_path')
      .single()
    if (avatarError) throw avatarError
    profile = refreshedProfile

    const { data: telegramStudent, error: telegramStudentError } = await admin
      .from('students')
      .select('id, auth_user_id')
      .eq('telegram_id', telegramUser.id)
      .maybeSingle()
    if (telegramStudentError) throw telegramStudentError

    if (telegramStudent) {
      if (profile.role === 'teacher') {
        throw new Error('Этот Telegram-аккаунт зарегистрирован как аккаунт преподавателя и не может быть привязан как ученик.')
      }
      if (telegramStudent.auth_user_id && telegramStudent.auth_user_id !== profile.id) {
        throw new Error('Этот Telegram-аккаунт уже привязан к другой записи ученика. Попросите преподавателя проверить привязку.')
      }

      const { data: existingStudentLink, error: existingStudentLinkError } = await admin
        .from('students')
        .select('id')
        .eq('auth_user_id', profile.id)
        .maybeSingle()
      if (existingStudentLinkError) throw existingStudentLinkError
      if (existingStudentLink && existingStudentLink.id !== telegramStudent.id) {
        throw new Error('Этот Telegram-аккаунт уже привязан к другой записи ученика. Попросите преподавателя проверить привязку.')
      }

      if (!telegramStudent.auth_user_id) {
        const { error: linkError } = await admin
          .from('students')
          .update({ auth_user_id: profile.id })
          .eq('id', telegramStudent.id)
          .is('auth_user_id', null)
        if (linkError) throw linkError
      }
    }

    const { data: sessionData, error: sessionError } = await authClient.auth.signInWithPassword({ email, password })
    if (sessionError || !sessionData.session) throw sessionError || new Error('Could not create an app session')

    return Response.json({ profile, session: sessionData.session }, { headers: corsHeaders })
  } catch (error) {
    const errorObject = error !== null && typeof error === 'object'
      ? error as Record<string, unknown>
      : null
    const message = error instanceof Error
      ? error.message
      : typeof error === 'string'
        ? error
        : typeof errorObject?.message === 'string'
          ? errorObject.message
          : typeof errorObject?.error_description === 'string'
            ? errorObject.error_description
            : 'Unexpected authentication error'
    const status = error instanceof TelegramValidationError ? 401 : 500
    console.error('Telegram sign-in failed', {
      errorType: errorObject?.name ?? (error instanceof Error ? error.name : typeof error),
      errorCode: errorObject?.code ?? null,
      status,
      message,
    })
    return Response.json({ error: message }, { status, headers: corsHeaders })
  }
})
