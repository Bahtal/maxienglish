import { supabase } from '../supabase.js';
import { isValidHttpsUrl } from '../utils/appConfig.js';

export function useWorkspaceTeacherProfile(workspace) {
    const { state, auth, profileForm } = workspace;
    const { showToast, persist, closeModal, loadRemoteWorkspace, openModal } = workspace;


    function hydrateTeacherSettings() {
        Object.assign(profileForm, {
            bio: state.teacher.bio || '', experience: state.teacher.experience || '', specialization: state.teacher.specialization || '',
            lessonFormat: state.teacher.lessonFormat || '', lessonRules: state.teacher.lessonRules || '', zoomLink: state.teacher.zoomLink || '',
            duration: Number(state.teacher.lessonDurationMinutes) || 60, price: Number(state.teacher.singleLessonPrice) || 1200,
            plans: (state.subscriptionPlans || []).map((plan) => ({ ...plan })),
        });
    }

    function openTeacherSettings() {
        hydrateTeacherSettings();
        openModal('teacher-settings', 'Настройки профиля', null, 'Эту информацию о себе и занятиях увидят ученики.');
    }

    function addPlan() {
        profileForm.plans.push({ id: '', lessons: 4, price: 0, active: true });
    }

    function removePlan(index) {
        profileForm.plans.splice(index, 1);
    }

    function updateTeacherSettings(patch) {
        if (Array.isArray(patch.plans)) {
            profileForm.plans = patch.plans.map((plan) => ({ ...plan }));
            return;
        }

        Object.assign(profileForm, patch);
    }

    async function saveTeacherSettings() {
        const lessonDuration = Number(profileForm.duration);
        const singlePrice = Number(profileForm.price);
        const zoomLink = String(profileForm.zoomLink || '').trim();
        const planCounts = profileForm.plans.map((plan) => Number(plan.lessons));
        if (!isValidHttpsUrl(zoomLink)) {
            showToast('Укажите ссылку Zoom в формате https://...');
            return;
        }
        if (lessonDuration < 15 || lessonDuration > 240 || singlePrice < 0) {
            showToast('Проверьте длительность и стоимость урока.');
            return;
        }
        if (new Set(planCounts).size !== planCounts.length || planCounts.some((count) => count < 1 || count > 100)) {
            showToast('Количество занятий в абонементах должно быть уникальным и от 1 до 100.');
            return;
        }
        if (auth.user) {
            const { error } = await supabase.rpc('save_teacher_setup', {
                p_profile: {
                    teacher_bio: profileForm.bio,
                    teacher_experience: profileForm.experience,
                    teacher_specialization: profileForm.specialization,
                    lesson_format: profileForm.lessonFormat,
                    lesson_rules: profileForm.lessonRules,
                    zoom_link: zoomLink,
                },
                p_settings: { lesson_duration_minutes: lessonDuration, single_lesson_price_rub: singlePrice },
                p_plans: profileForm.plans.map((plan) => ({ lesson_count: Number(plan.lessons), price_rub: Number(plan.price), is_active: Boolean(plan.active) })),
            });
            if (error) {
                showToast(error.message || 'Не удалось сохранить профиль и настройки. Проверьте SQL-настройку учителя.');
                return;
            }
            await loadRemoteWorkspace();
            if (String(state.teacher.zoomLink || '').trim() !== zoomLink) {
                showToast('Ссылка Zoom не сохранилась в базе. Выполните supabase/lesson-links.sql в Supabase SQL Editor и сохраните настройки ещё раз.');
                return;
            }
        } else {
            state.subscriptionPlans = profileForm.plans.map((plan, index) => ({ ...plan, id: plan.id || `plan-${Date.now()}-${index}`, lessons: Number(plan.lessons), price: Number(plan.price), active: Boolean(plan.active) }));
            Object.assign(state.teacher, {
                bio: profileForm.bio,
                experience: profileForm.experience,
                specialization: profileForm.specialization,
                lessonFormat: profileForm.lessonFormat,
                lessonRules: profileForm.lessonRules,
                zoomLink,
                lessonDurationMinutes: lessonDuration,
                singleLessonPrice: singlePrice,
            });
        }
        closeModal();
        persist();
        showToast('Настройки профиля сохранены');
    }

    return {
        hydrateTeacherSettings,
        openTeacherSettings,
        addPlan,
        removePlan,
        updateTeacherSettings,
        saveTeacherSettings,
    };
}
