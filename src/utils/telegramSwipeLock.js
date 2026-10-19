const activeLocks = new Set();
let lockedWebApp = null;
let wasVerticalSwipeEnabled = null;

export function acquireTelegramSwipeLock() {
    if (typeof window === 'undefined' || !window.matchMedia('(max-width: 768px)').matches) {
        return () => {};
    }

    const webApp = window.Telegram?.WebApp;

    if (typeof webApp?.disableVerticalSwipes !== 'function') {
        return () => {};
    }

    const lockId = Symbol('telegram-vertical-swipe-lock');

    if (!activeLocks.size) {
        const wasEnabled = webApp.isVerticalSwipesEnabled !== false;

        try {
            if (wasEnabled) webApp.disableVerticalSwipes();
        } catch {
            return () => {};
        }

        lockedWebApp = webApp;
        wasVerticalSwipeEnabled = wasEnabled;
    }

    activeLocks.add(lockId);
    let isReleased = false;

    return () => {
        if (isReleased) return;
        isReleased = true;
        activeLocks.delete(lockId);

        if (activeLocks.size) return;

        try {
            if (wasVerticalSwipeEnabled) lockedWebApp?.enableVerticalSwipes?.();
        } catch {
            // Keep the sheet usable if an older Telegram client rejects the call.
        } finally {
            lockedWebApp = null;
            wasVerticalSwipeEnabled = null;
        }
    };
}
