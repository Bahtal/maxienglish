import { supabase } from '../supabase.js';

export function useWorkspaceNotifications(workspace) {
    const { state, auth, modal, notificationRef } = workspace;
    const { lessonById, openLesson, closeModal, persist, showToast } = workspace;


    async function openNotification(item) {
        if (auth.user && !item.read) {
            const { error } = await supabase.from('notifications').update({ read_at: new Date().toISOString() }).eq('id', item.id);

            if (error) {
                showToast(error.message || 'Не удалось отметить уведомление прочитанным.');
                return;
            }
        }

        item.read = true;
        state.notificationOpen = false;
        if (item.lessonId) {
            const lesson = lessonById(item.lessonId);
            if (lesson) {
                state.page = 'calendar';
                state.selectedDate = lesson.date;
                state.calendarMonth = lesson.date.slice(0, 7);
                openLesson(lesson);
            }
        }
        persist();
    }

    async function copyText(text, success) {
        try { await navigator.clipboard.writeText(text); showToast(success); }
        catch { showToast('Не удалось скопировать автоматически. Выделите и скопируйте текст.'); }
    }

    function onOutsideClick(event) {
        if (state.notificationOpen && notificationRef.value && !notificationRef.value.contains(event.target)) state.notificationOpen = false;
        if (event.target?.classList?.contains('modal-backdrop')) closeModal();
    }

    function onKeyDown(event) { if (event.key === 'Escape' && modal.type) closeModal(); }

    return {
        openNotification,
        copyText,
        onOutsideClick,
        onKeyDown,
    };
}
