import { supabase } from '../supabase.js';
import { STORE_KEY, themeOptions, normalizeTheme, dateKey, todayKey } from '../utils/appConfig.js';
import { makeSeed } from '../utils/demoData.js';
import { getTelegramUserId, writeWorkspaceCache } from '../utils/workspaceCache.js';

export function useWorkspaceInterface(workspace) {
    const { state, auth, modal, toast, toastTimer, persistedTheme, themeSync, themeReturnPage, daySummary } = workspace;
    const telegramUserId = getTelegramUserId();
    let themeSaveQueue = Promise.resolve();

    function cacheTheme(profile = auth.profile) {
        if (!auth.user || !profile || !telegramUserId) return;

        writeWorkspaceCache(telegramUserId, auth.user.id, profile, state);
    }

    function persist() {
        if (auth.user) return;
        try {
            localStorage.setItem(STORE_KEY, JSON.stringify(state));
        } catch {
            // Browser storage may be unavailable.
        }
    }

    function applyTheme() {
        state.themeId = normalizeTheme(state.themeId);
        document.documentElement.dataset.theme = state.themeId;
        const meta = document.querySelector('meta[name="theme-color"]');
        const appShell = document.querySelector('#app [data-theme]');

        if (appShell) {
            appShell.dataset.theme = state.themeId;
            const canvasColor = getComputedStyle(appShell).getPropertyValue('--canvas').trim();
            if (canvasColor) {
                if (meta) meta.content = canvasColor;

                const webApp = window.Telegram?.WebApp;
                if (typeof webApp?.setHeaderColor === 'function') {
                    webApp.setHeaderColor(canvasColor);
                }
            }
        }
    }

    function showToast(message) {
        toast.value = message;
        window.clearTimeout(toastTimer.value);
        toastTimer.value = window.setTimeout(() => {
            toast.value = '';
        }, 2800);
    }

    function studentById(id) {
        return state.students.find((student) => student.id === id);
    }

    function lessonById(id) {
        return state.lessons.find((lesson) => lesson.id === id);
    }

    function go(page) {
        state.page = page;
        state.notificationOpen = false;
        persist();
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    function toggleNotifications() {
        state.notificationOpen = !state.notificationOpen;
    }

    function setSelectedFilter(value) {
        state.selectedFilter = value;
    }

    function resetDemo() {
        Object.assign(state, makeSeed());
        persist();
        showToast('Демо-данные восстановлены');
    }

    function openThemes() {
        if (state.page !== 'themes') themeReturnPage.value = state.page;
        go('themes');
    }

    function closeThemes() {
        go(themeReturnPage.value || 'home');
    }

    function changeRole(role) {
        if (!auth.user) state.demoThemeIds[state.role] = state.themeId;
        state.role = role;
        if (!auth.user) state.themeId = normalizeTheme(state.demoThemeIds[role]);
        state.page = 'home';
        state.notificationOpen = false;
        persist();
    }

    async function setTheme(themeId) {
        const value = normalizeTheme(themeId);

        if (value === state.themeId && (!auth.user || (!themeSync.pending && value === persistedTheme.value))) return;

        state.themeId = value;
        applyTheme();

        if (!auth.user) {
            state.demoThemeIds[state.role] = value;
            persist();
            showToast(`Тема «${themeOptions.find((theme) => theme.id === value).name}» включена`);
            return;
        }

        const saveRevision = ++themeSync.revision;
        const profileId = auth.user.id;
        themeSync.pending = true;
        themeSync.saving = true;
        cacheTheme();

        const saveRequest = themeSaveQueue
            .catch(() => {})
            .then(async () => {
                const { data, error } = await supabase
                    .from('profiles')
                    .update({ theme_id: value })
                    .eq('id', profileId)
                    .select('theme_id')
                    .single();
                if (error) throw error;
                if (normalizeTheme(data?.theme_id) !== value) throw new Error('Supabase did not save the selected theme.');
            });
        themeSaveQueue = saveRequest;

        try {
            await saveRequest;
            persistedTheme.value = value;
            if (auth.profile) auth.profile = { ...auth.profile, theme_id: value };

            if (themeSync.revision === saveRevision) {
                themeSync.pending = false;
                themeSync.saving = false;
                showToast('Тема сохранена в профиле');
            }
            cacheTheme();
        } catch (error) {
            console.error('Could not save the selected theme', error);

            if (themeSync.revision === saveRevision) {
                themeSync.pending = true;
                themeSync.saving = false;
                showToast('Тема оставлена на этом устройстве. Не удалось синхронизировать её с профилем; проверьте подключение.');
            }
            cacheTheme();
        }
    }

    function openModal(type, title, data = null, subtitle = '') {
        modal.type = type;
        modal.title = title;
        modal.subtitle = subtitle;
        modal.data = data;
        modal.busy = false;
        modal.error = '';
        document.body.style.overflow = 'hidden';
    }

    function closeModal() {
        modal.type = '';
        modal.data = null;
        modal.busy = false;
        modal.error = '';
        document.body.style.overflow = '';
    }

    function openLesson(lesson) {
        openModal('lesson', state.role === 'teacher' ? 'Занятие ученика' : 'Занятие по английскому', lesson);
    }

    function openHomework(item) {
        openModal('homework', 'ДЗ', item);
    }

    function openStudent(student) {
        openModal('student', student.name, {
            ...student,
            customPlans: (student.customPlans || []).map((plan) => ({ ...plan })),
        }, 'Профиль ученика');
    }

    function openPayment() {
        openModal('payment', 'Продлить абонемент', null, 'Выберите пакет занятий');
    }

    function openHomeworkForm(studentId = '') {
        openModal('homework-form', 'Новое домашнее задание', { studentId }, 'Описание, срок и файл появятся у ученика в разделе ДЗ');
    }

    function openLessonForm(date = '') {
        openModal('lesson-form', 'Добавить урок', { date: date || state.selectedDate || todayKey() }, 'Выберите ученика, дату и время. Длительность установлена в настройках профиля.');
    }

    function openStudentForm() {
        openModal('student-form', 'Пригласить ученика', null, 'Ученик появится в списке после подтверждения приглашения в Telegram.');
    }

    function openReschedule(lesson) {
        openModal('reschedule', 'Перенести урок', { ...lesson }, studentById(lesson.studentId)?.name || 'Ученик');
    }

    function openPaymentHistory() {
        openModal('payment-history', 'История оплат', null, 'Платежи и заявки на абонемент');
    }

    function addMonth(amount) {
        const [year, month] = state.calendarMonth.split('-').map(Number);
        state.calendarMonth = dateKey(new Date(year, month - 1 + amount, 1)).slice(0, 7);
    }

    function openProfileNextLesson() {
        const lesson = daySummary.value.next;
        if (!lesson) return;

        state.selectedDate = lesson.date;
        state.calendarMonth = lesson.date.slice(0, 7);
        go('calendar');
        openLesson(lesson);
    }

    function colorFor(name) {
        return ['purple', 'blue', 'mint'].includes(name) ? name : '';
    }

    function openChat(studentId = '') {
        const student = studentById(studentId);
        const person = state.role === 'teacher' ? student : { name: state.teacher.name, username: state.teacher.username };
        const username = String(person?.username || '').replace(/^@/, '').trim();

        if (!username) {
            showToast('Для этого профиля не указан Telegram username.');
            return;
        }

        const first = (person?.name || 'Здравствуйте').split(/\s+/)[0];
        const link = `https://t.me/${encodeURIComponent(username)}?text=${encodeURIComponent(`Здравствуйте, ${first}!`)}`;
        closeModal();

        if (window.Telegram?.WebApp?.openTelegramLink) {
            window.Telegram.WebApp.openTelegramLink(link);
        } else {
            window.open(link, '_blank', 'noopener,noreferrer');
        }
    }

    return {
        persist,
        applyTheme,
        showToast,
        studentById,
        lessonById,
        go,
        toggleNotifications,
        setSelectedFilter,
        resetDemo,
        openThemes,
        closeThemes,
        changeRole,
        setTheme,
        openModal,
        closeModal,
        openLesson,
        openHomework,
        openStudent,
        openPayment,
        openHomeworkForm,
        openLessonForm,
        openStudentForm,
        openReschedule,
        openPaymentHistory,
        addMonth,
        openProfileNextLesson,
        colorFor,
        openChat,
    };
}
