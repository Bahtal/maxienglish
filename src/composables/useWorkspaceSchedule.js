import { supabase } from '../supabase.js';
import { dateObject, dateTimeIso, dateKey, cap, formatDay } from '../utils/appConfig.js';
import { findPastLessonForAttendance, hasLessonOverlap } from '../utils/lessonRules.js';

export function useWorkspaceSchedule(workspace) {
    const { state, auth, modal } = workspace;
    const { persist, showToast, studentById, closeModal, loadRemoteWorkspace } = workspace;


    function pastLessonForAttendance(studentId) {
        return findPastLessonForAttendance(state.lessons, studentId);
    }

    function submitReschedule(payload) {
        return changeLesson('reschedule', modal.data, String(payload.date || ''), String(payload.time || ''));
    }

    function updateSelectedDay(value) {
        state.selectedDate = value;
        state.calendarMonth = value.slice(0, 7);
    }

    async function markAttendance(student, lesson) {
        if (state.role !== 'teacher' || !student || !lesson) {
            return;
        }
        if (lesson.lessonStatus !== 'scheduled'
            || lesson.attendanceStatus
            || dateObject(lesson.date, lesson.time) >= new Date()) {
            showToast('Отметить можно только прошедшее занятие.');
            return;
        }
        if (auth.user) {
            const { data, error } = await supabase.from('lessons')
                .update({ status: 'completed', attendance_status: 'attended' })
                .eq('id', lesson.id)
                .eq('status', 'scheduled')
                .is('attendance_status', null)
                .select('id')
                .maybeSingle();
            if (error) {
                showToast(error.message || 'Не удалось сохранить посещение.');
                return;
            }
            if (!data) {
                showToast('Занятие уже изменено или отмечено. Обновите данные.');
                return;
            }
        } else {
            student.attendance.unshift({ date: lesson.date, time: lesson.time, status: 'Была' });
            student.paidLessons = Math.max(0, student.paidLessons - 1);
            if (student.id === state.studentUser.id) {
                state.studentUser.lessonsLeft = Math.max(0, state.studentUser.lessonsLeft - 1);
            }
            lesson.paymentStatus ||= ['paid', 'awaiting', 'unpaid'].includes(lesson.status) ? lesson.status : 'unpaid';
            lesson.lessonStatus = 'completed'; lesson.status = 'completed';
        }
        closeModal();
        persist();
        showToast('Посещение сохранено в истории');
        if (auth.user) {
            try {
                await loadRemoteWorkspace();
            } catch (error) {
                workspace.handleRemoteError(error);
            }
        }
    }

    async function markLessonPaid(lesson) {
        if (auth.user) {
            const { error } = await supabase.from('lessons').update({ payment_status: 'paid' }).eq('id', lesson.id);
            if (error) {
                showToast(error.message || 'Не удалось изменить статус оплаты.');
                return;
            }
            closeModal();
            showToast('Урок отмечен как оплаченный');
            try {
                await loadRemoteWorkspace();
            } catch (loadError) {
                workspace.handleRemoteError(loadError);
            }
        } else {
            lesson.status = 'paid';
            lesson.paymentStatus = 'paid';
            closeModal();
            persist();
            showToast('Урок отмечен как оплаченный');
        }
    }

    async function requestReschedule(lesson) {
        let toastMessage = 'Запрос на перенос отправлен учителю';
        if (auth.user) {
            const { data, error } = await supabase.rpc('request_lesson_reschedule', { p_lesson_id: lesson.id });
            if (error) {
                showToast(error.message || 'Не удалось отправить запрос.');
                return;
            }
            toastMessage = data ? 'Запрос на перенос отправлен учителю' : 'Запрос уже ожидает ответа';
            closeModal();
            showToast(toastMessage);
            try {
                await loadRemoteWorkspace();
            } catch (loadError) {
                workspace.handleRemoteError(loadError);
            }
            return;
        } else {
            const exists = state.notifications.some((notice) => notice.lessonId === lesson.id && notice.outcome === 'awaiting');
            if (exists) {
                showToast('Запрос уже ожидает ответа');
                return;
            }
            state.notifications.unshift({ id: `notice-${Date.now()}`, role: 'teacher', title: 'Запрос на перенос урока', body: `${studentById(lesson.studentId)?.name || 'Ученик'} хочет обсудить перенос занятия.`, time: 'Только что', read: false, lessonId: lesson.id, outcome: 'awaiting' });
        }
        closeModal(); persist(); showToast(toastMessage);
    }

    async function changeLesson(action, lesson, newDate = '', newTime = '') {
        const startsAt = action === 'reschedule' ? dateTimeIso(newDate, newTime) : null;
        if (auth.user) {
            const { error } = await supabase.rpc('teacher_change_lesson', { p_lesson_id: lesson.id, p_action: action, p_new_starts_at: startsAt });
            if (error) {
                showToast(error.message || 'Не удалось изменить занятие.');
                return;
            }
            if (action === 'reschedule') {
                state.selectedDate = newDate;
                state.calendarMonth = newDate.slice(0, 7);
            }
            closeModal();
            persist();
            showToast(action === 'cancel' ? 'Урок отменён, оплаченный урок сохранён' : 'Урок перенесён');
            try {
                await loadRemoteWorkspace();
            } catch (loadError) {
                workspace.handleRemoteError(loadError);
            }
            return;
        } else if (action === 'cancel') {
            lesson.lessonStatus = 'cancelled'; lesson.status = 'cancelled';
        } else {
            const start = dateObject(newDate, newTime).getTime();
            const collision = hasLessonOverlap(state.lessons, start, Number(lesson.durationMinutes) || 60, {
                ignoreCompleted: true,
                excludeLessonId: lesson.id,
            });
            if (collision) {
                showToast('На это время уже назначено занятие.');
                return;
            }
            lesson.date = newDate;
            lesson.time = newTime;
        }
        if (!auth.user) {
            const outcome = action === 'cancel' ? 'cancelled' : 'rescheduled';
            state.notifications.forEach((notice) => {
                if (notice.lessonId === lesson.id && notice.outcome === 'awaiting') {
                    notice.outcome = outcome;
                }
            });
            state.notifications.unshift({
                id: `notice-${Date.now()}`, role: 'student', title: action === 'cancel' ? 'Урок отменён' : 'Урок перенесён',
                body: action === 'cancel'
                    ? 'Оплаченное занятие сохранено на балансе. Напишите преподавателю, чтобы договориться о новой записи.'
                    : `Новое время занятия: ${cap(formatDay(lesson.date))} в ${lesson.time}.`,
                time: 'Только что', read: false, lessonId: lesson.id, outcome,
            });
            state.selectedDate = lesson.date;
            state.calendarMonth = lesson.date.slice(0, 7);
            state.page = 'calendar';
        }
        closeModal();
        persist();
        showToast(action === 'cancel' ? 'Урок отменён, оплаченный урок сохранён' : 'Урок перенесён');
    }

    async function createLesson(payload) {
        if (modal.busy) {
            return;
        }
        const date = String(payload.date || '');
        const time = String(payload.time || '');
        const studentId = String(payload.studentId || '');
        const title = String(payload.title || 'Английский').trim().slice(0, 100) || 'Английский';
        const isHistorical = payload.historical === 'true' || payload.historical === 'on';
        if (!studentById(studentId)) {
            showToast('Сначала добавьте ученика в кабинете учителя.');
            return;
        }
        const duration = Number(state.teacher.lessonDurationMinutes) || 60;
        const lessonStartsAt = dateObject(date, time);
        if (Number.isNaN(lessonStartsAt.getTime())) {
            showToast('Укажите корректные дату и время.');
            return;
        }
        const now = new Date();
        const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
        const selectedLocalDateTime = `${date}T${time.slice(0, 5)}`;
        const currentLocalDateTime = `${dateKey(now)}T${currentTime}`;
        if (isHistorical && selectedLocalDateTime > currentLocalDateTime) {
            showToast('Прошедшее занятие должно быть в прошлом.');
            return;
        }
        if (!isHistorical && lessonStartsAt <= new Date()) {
            showToast('Для прошедшей даты включите отметку «Урок уже прошёл».');
            return;
        }
        const student = studentById(studentId);
        if (isHistorical && Number(student?.paidLessons || 0) < 1) {
            showToast('Сначала добавьте оплаченные занятия в карточке ученика.');
            return;
        }
        const start = lessonStartsAt.getTime();
        if (hasLessonOverlap(state.lessons, start, duration, { ignoreCompleted: !isHistorical })) {
            showToast('В это время уже есть занятие.');
            return;
        }
        const newLesson = {
            id: `lesson-${Date.now()}`,
            studentId,
            date,
            time,
            durationMinutes: duration,
            title,
            kind: `${title} · ${duration} мин`,
            status: isHistorical ? 'completed' : String(payload.paymentStatus || 'unpaid'),
            paymentStatus: isHistorical ? 'paid' : String(payload.paymentStatus || 'unpaid'),
            lessonStatus: isHistorical ? 'completed' : 'scheduled',
            attendanceStatus: isHistorical ? 'attended' : null,
        };
        modal.busy = true;
        try {
            if (auth.user) {
                const { error } = await supabase.from('lessons').insert({
                    teacher_id: auth.user.id,
                    student_id: studentId,
                    starts_at: dateTimeIso(date, time),
                    duration_minutes: duration,
                    title: newLesson.title,
                    status: newLesson.lessonStatus,
                    payment_status: isHistorical ? 'paid' : newLesson.status,
                    attendance_status: newLesson.attendanceStatus,
                });
                if (error) {
                    const message = error.message?.includes('lesson_time_conflict')
                        ? 'На это время уже назначено занятие. Обновите календарь.'
                        : error.message || 'Не удалось создать урок.';
                    showToast(message);
                    return;
                }
            } else {
                state.lessons.push(newLesson);
                if (isHistorical) {
                    student.paidLessons = Math.max(0, student.paidLessons - 1);
                    if (student.id === state.studentUser.id) {
                        state.studentUser.lessonsLeft = Math.max(0, state.studentUser.lessonsLeft - 1);
                    }
                    student.attendance.unshift({ date, time, status: 'Была' });
                }
            }

            closeModal();
            state.selectedDate = date;
            state.calendarMonth = date.slice(0, 7);
            persist();
            showToast(isHistorical ? 'Прошедшее занятие добавлено и списано с баланса' : 'Урок добавлен в календарь');

            if (auth.user) {
                try {
                    await loadRemoteWorkspace();
                } catch (error) {
                    workspace.handleRemoteError(error);
                }
            }
        } catch (error) {
            showToast(error?.message || 'Не удалось создать урок.');
        } finally {
            modal.busy = false;
        }
    }

    async function deleteLesson(lesson) {
        if (state.role !== 'teacher' || modal.busy || !lesson?.id) return;

        modal.busy = true;
        try {
            if (auth.user) {
                const { error } = await supabase.rpc('teacher_delete_lesson', {
                    p_lesson_id: lesson.id,
                });

                if (error) {
                    const migrationMissing = ['PGRST202', '42883'].includes(error.code)
                        || /teacher_delete_lesson|schema cache/i.test(error.message || '');
                    showToast(migrationMissing
                        ? 'Удаление уроков ещё не настроено в Supabase. Выполните новую миграцию из supabase/migrations в SQL Editor.'
                        : error.message || 'Не удалось удалить урок.');
                    return;
                }
            } else {
                const lessonIndex = state.lessons.findIndex((item) => item.id === lesson.id);
                if (lessonIndex === -1) {
                    showToast('Урок уже удалён или обновлён.');
                    return;
                }
                state.lessons.splice(lessonIndex, 1);
                const student = studentById(lesson.studentId);
                if (student) {
                    student.attendance = (student.attendance || []).filter((item) => (
                        item.date !== lesson.date || item.time !== lesson.time
                    ));
                }
            }

            closeModal();
            persist();
            showToast('Урок удалён из календаря и истории. Остаток занятий не изменился.');

            if (auth.user) {
                try {
                    await loadRemoteWorkspace();
                } catch (loadError) {
                    workspace.handleRemoteError(loadError);
                }
            }
        } catch (error) {
            showToast(error?.message || 'Не удалось удалить урок. Проверьте подключение и попробуйте снова.');
        } finally {
            modal.busy = false;
        }
    }

    return {
        pastLessonForAttendance,
        submitReschedule,
        updateSelectedDay,
        markAttendance,
        markLessonPaid,
        requestReschedule,
        changeLesson,
        createLesson,
        deleteLesson,
    };
}
