const CACHE_VERSION = 2;
const CACHE_PREFIX = 'lessonly-workspace-cache-v2:';

function readTelegramUserId(initData) {
    if (!initData) return '';

    try {
        const user = new URLSearchParams(initData).get('user');
        return String(JSON.parse(user || '{}').id || '');
    } catch {
        return '';
    }
}

export function getTelegramUserId(webApp = window.Telegram?.WebApp) {
    const id = webApp?.initDataUnsafe?.user?.id
        || readTelegramUserId(webApp?.initData)
        || readTelegramUserId(new URLSearchParams(window.location.search).get('tgWebAppData'));

    return /^\d+$/.test(String(id || '')) ? String(id) : '';
}

export function readWorkspaceCache(telegramUserId) {
    if (!telegramUserId) return null;

    try {
        const cached = JSON.parse(localStorage.getItem(`${CACHE_PREFIX}${telegramUserId}`) || 'null');

        if (
            cached?.version !== CACHE_VERSION
            || cached.telegramUserId !== String(telegramUserId)
            || !cached.supabaseUserId
            || !cached.profile
            || cached.profile.id !== cached.supabaseUserId
            || String(cached.profile.telegram_id || '') !== String(telegramUserId)
            || !['teacher', 'student'].includes(cached.state?.role)
            || cached.profile.role !== cached.state.role
            || !Array.isArray(cached.state?.students)
            || !Array.isArray(cached.state?.lessons)
            || !Array.isArray(cached.state?.homework)
        ) {
            return null;
        }

        return cached;
    } catch {
        return null;
    }
}

export function writeWorkspaceCache(telegramUserId, supabaseUserId, profile, state) {
    if (!telegramUserId || !supabaseUserId || !profile || !state) return;

    try {
        const snapshot = JSON.parse(JSON.stringify(state));
        snapshot.notificationOpen = false;

        const cached = {
            version: CACHE_VERSION,
            telegramUserId: String(telegramUserId),
            supabaseUserId,
            profile,
            savedAt: new Date().toISOString(),
            state: snapshot,
        };

        localStorage.setItem(`${CACHE_PREFIX}${telegramUserId}`, JSON.stringify(cached));
    } catch {
        // Keep remote data usable if local storage is unavailable or full.
    }
}
