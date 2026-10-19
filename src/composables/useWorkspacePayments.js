import { supabase } from '../supabase.js';
import { cap, formatDay, todayKey } from '../utils/appConfig.js';

export function useWorkspacePayments(workspace) {
    const { state, auth, selectedStudent } = workspace;
    const { persist, showToast, studentById, closeModal, loadRemoteWorkspace } = workspace;


    async function confirmPayment(payment) {
        if (auth.user) {
            const { error } = await supabase.from('payments').update({ status: 'confirmed' }).eq('id', payment.id);
            if (error) {
                showToast(error.message || 'Не удалось подтвердить оплату');
                return;
            }
            await loadRemoteWorkspace();
        } else {
            payment.status = 'paid';
            const student = studentById(payment.studentId);
            if (student) {
                student.paymentStatus = 'paid'; student.paidLessons += Number(payment.lessons) || 0;
            }
        }
        persist();
        showToast('Оплата подтверждена');
    }

    async function markNotificationsRead() {
        if (auth.user) {
            const { error } = await supabase.from('notifications').update({ read_at: new Date().toISOString() }).eq('recipient_profile_id', auth.user.id).is('read_at', null);
            if (error) {
                showToast(error.message || 'Не удалось обновить уведомления.');
                return;
            }
        }
        state.notifications.forEach((notice) => { notice.read = true; });
        persist();
    }

    async function requestPayment(payload) {
        if (workspace.modal.busy) return;

        const plan = state.subscriptionPlans.find((entry) => entry.id === String(payload.plan) && entry.active);
        if (!plan) {
            showToast('Выберите активный абонемент.');
            return;
        }

        const student = selectedStudent.value;
        if (state.payments.some((payment) => payment.studentId === student?.id && payment.status === 'awaiting')) {
            showToast('Заявка на оплату уже ожидает подтверждения.');
            closeModal();
            return;
        }

        workspace.modal.busy = true;
        try {
            if (auth.user) {
                if (!student?.teacherId) {
                    showToast('Профиль ученика ещё не связан с преподавателем.');
                    return;
                }

                const { data, error } = await supabase.rpc('request_student_payment', {
                    p_plan_id: plan.id,
                });
                if (error) {
                    showToast(error.message || 'Не удалось отправить заявку на оплату.');
                    return;
                }
                if (data?.status === 'already_pending') {
                    closeModal();
                    showToast('Заявка на оплату уже ожидает подтверждения.');
                    try {
                        await loadRemoteWorkspace();
                    } catch (loadError) {
                        workspace.handleRemoteError(loadError);
                    }
                    return;
                }
                if (data?.status !== 'created') {
                    showToast('Сервер не подтвердил создание заявки. Обновите данные и попробуйте снова.');
                    return;
                }
            } else {
                state.payments.unshift({ id: `pay-${Date.now()}`, studentId: state.studentUser.id, lessons: plan.lessons, amount: plan.price, status: 'awaiting', date: cap(formatDay(todayKey())) });
                state.notifications.unshift({ id: `notice-${Date.now()}`, role: 'teacher', title: 'Новая заявка на оплату', body: `${state.studentUser.name} отправила заявку на ${plan.lessons} занятий.`, time: 'Только что', read: false });
            }

            closeModal();
            persist();
            showToast('Заявка отправлена преподавателю');

            if (auth.user) {
                try {
                    await loadRemoteWorkspace();
                } catch (loadError) {
                    workspace.handleRemoteError(loadError);
                }
            }
        } catch (error) {
            showToast(error?.message || 'Не удалось отправить заявку на оплату.');
        } finally {
            workspace.modal.busy = false;
        }
    }

    return {
        confirmPayment,
        markNotificationsRead,
        requestPayment,
    };
}
