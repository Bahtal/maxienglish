import { supabase } from '../supabase.js';
import { humanCount, isValidHttpsUrl } from '../utils/appConfig.js';

export function useWorkspaceStudents(workspace) {
    const { state, auth, modal } = workspace;
    const { persist, showToast, loadRemoteWorkspace, openModal, studentById } = workspace;

    function createInviteToken() {
        const bytes = new Uint8Array(24);
        window.crypto.getRandomValues(bytes);
        return Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
    }

    async function hashInviteToken(token) {
        const bytes = new TextEncoder().encode(token);
        const digest = await window.crypto.subtle.digest('SHA-256', bytes);
        return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, '0')).join('');
    }

    function showInvitation(token, expiresAt) {
        openModal(
            'student-invitation',
            'Приглашение ученика',
            {
                inviteUrl: `https://t.me/MaxiEnglish_bot?start=i_${token}`,
                expiresAt,
            },
            'Скопируйте ссылку и отправьте будущему ученику. Он появится в списке после нажатия Start.',
        );
    }

    async function createInvitation({ studentId = '' } = {}) {
        const token = createInviteToken();
        const tokenHash = await hashInviteToken(token);
        const rpcName = studentId
            ? 'create_student_invitation_for_existing'
            : 'create_student_invitation';
        const args = studentId
            ? { p_student_id: studentId, p_token_hash: tokenHash }
            : { p_name: '', p_board_link: '', p_token_hash: tokenHash };
        const { data, error } = await supabase.rpc(rpcName, args);

        if (error) throw error;

        return {
            token,
            studentId: data?.student_id || studentId,
            expiresAt: data?.expires_at || '',
        };
    }

    function invitationErrorMessage(error) {
        if (['PGRST202', '42883'].includes(error?.code)
            || /create_student_invitation|schema cache/i.test(error?.message || '')) {
            return 'Приглашения ещё не настроены в Supabase. Выполните student-confirmation-and-history.sql и обновите webhook.';
        }

        return error?.message || 'Не удалось создать приглашение.';
    }


    async function createStudent() {
        if (modal.busy) return;

        modal.error = '';
        if (auth.user) {
            let invitation;
            modal.busy = true;

            try {
                invitation = await createInvitation();
            } catch (error) {
                modal.error = invitationErrorMessage(error);
                modal.busy = false;
                return;
            }

            modal.busy = false;
            showInvitation(invitation.token, invitation.expiresAt);
            loadRemoteWorkspace().catch((error) => {
                console.error('Invitation created, but workspace refresh failed', error);
            });
        } else {
            modal.error = 'Чтобы создать настоящую ссылку-приглашение, войдите в Telegram как учитель.';
        }

        persist();
    }

    async function createStudentInvitation(studentId) {
        const student = state.students.find((entry) => entry.id === studentId);

        if (!auth.user || !student) {
            showToast('Не удалось найти ученика для приглашения.');
            return;
        }

        try {
            const invitation = await createInvitation({ studentId });
            showInvitation(invitation.token, invitation.expiresAt);
            await loadRemoteWorkspace();
        } catch (error) {
            showToast(invitationErrorMessage(error));
        }
    }

    async function updateStudentSetup(payload) {
        if (!auth.user || state.role !== 'teacher' || modal.busy) return;

        const studentId = String(payload.studentId || '');
        const student = studentById(studentId);
        const boardLink = String(payload.boardLink || '').trim();
        const additionalLessons = Number(payload.additionalLessons || 0);
        const customPriceText = String(payload.customSingleLessonPrice ?? '').trim();
        const customSingleLessonPrice = customPriceText ? Number(customPriceText) : null;
        const customPlans = Array.isArray(payload.customPlans) ? payload.customPlans : [];
        const planCounts = customPlans.map((plan) => Number(plan.lessons));

        if (!student) {
            showToast('Ученик не найден. Обновите страницу и попробуйте ещё раз.');
            return;
        }
        if (boardLink && !isValidHttpsUrl(boardLink)) {
            showToast('Ссылка на доску должна начинаться с https://.');
            return;
        }
        if (!Number.isInteger(additionalLessons) || additionalLessons < 0 || additionalLessons > 100) {
            showToast('Количество занятий должно быть от 0 до 100.');
            return;
        }
        if (customSingleLessonPrice !== null
            && (!Number.isFinite(customSingleLessonPrice) || customSingleLessonPrice < 0 || customSingleLessonPrice > 99999999)) {
            showToast('Индивидуальная цена должна быть от 0 до 99 999 999 ₽.');
            return;
        }
        if (customPlans.some((plan) => !Number.isInteger(Number(plan.lessons))
            || Number(plan.lessons) < 1
            || Number(plan.lessons) > 100
            || !Number.isFinite(Number(plan.price))
            || Number(plan.price) < 0
            || Number(plan.price) > 99999999)
            || new Set(planCounts).size !== planCounts.length) {
            showToast('Проверьте абонементы: число занятий должно быть уникальным (от 1 до 100), цена — неотрицательной.');
            return;
        }

        modal.busy = true;
        try {
            const { data, error } = await supabase.rpc('teacher_update_student_profile', {
                p_student_id: studentId,
                p_board_link: boardLink,
                p_additional_lessons: additionalLessons,
                p_custom_single_lesson_price_rub: customSingleLessonPrice,
                p_custom_plans: customPlans.map((plan) => ({
                    lesson_count: Number(plan.lessons),
                    price_rub: Number(plan.price),
                    is_active: Boolean(plan.active),
                })),
            });
            if (error) {
                const migrationMissing = ['PGRST202', '42883'].includes(error.code)
                    || /teacher_update_student_profile|schema cache/i.test(error.message || '');
                showToast(migrationMissing
                    ? 'Индивидуальные цены ещё не настроены в Supabase. Выполните supabase/student-individual-pricing.sql в SQL Editor.'
                    : error.message || 'Не удалось сохранить данные ученика.');
                return;
            }

            const savedStudent = {
                ...student,
                boardLink,
                customSingleLessonPrice,
                customPlans: customPlans.map((plan, index) => ({
                    id: student.customPlans?.[index]?.id || `draft-${index}`,
                    studentId,
                    lessons: Number(plan.lessons),
                    price: Number(plan.price),
                    active: Boolean(plan.active),
                })),
                paidLessons: Number(data?.lessons_remaining ?? student.paidLessons),
                paymentStatus: Number(data?.lessons_remaining ?? student.paidLessons) > 0 ? 'paid' : 'unpaid',
            };
            Object.assign(student, savedStudent);
            if (modal.data?.id === studentId) {
                Object.assign(modal.data, savedStudent, { additionalLessonsInput: '0' });
            }

            try {
                await loadRemoteWorkspace();
                const refreshedStudent = studentById(studentId);
                if (refreshedStudent && modal.data?.id === studentId) {
                    Object.assign(modal.data, refreshedStudent, { additionalLessonsInput: '0' });
                }
            } catch (refreshError) {
                console.error('Student setup saved, but workspace refresh failed', refreshError);
            }

            showToast(additionalLessons
                ? `Данные и цены сохранены. На баланс добавлено ${additionalLessons} ${humanCount(additionalLessons, 'занятие', 'занятия', 'занятий')}.`
                : 'Данные и индивидуальные условия оплаты сохранены.');
        } catch (error) {
            showToast(error?.message || 'Не удалось сохранить данные ученика. Проверьте подключение и попробуйте ещё раз.');
        } finally {
            modal.busy = false;
        }
    }

    return {
        createStudent,
        createStudentInvitation,
        updateStudentSetup,
    };
}
