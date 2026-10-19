import { onMounted, onUnmounted, ref } from 'vue';
import { supabase } from '../supabase.js';
import { dateKey, todayKey, formatDay, cap, normalizeTheme } from '../utils/appConfig.js';
import { getStudentPlans } from '../utils/studentPricing.js';
import { getTelegramUserId, readWorkspaceCache, writeWorkspaceCache } from '../utils/workspaceCache.js';

export function useWorkspaceRemote(workspace) {
    const { state, auth, isTelegram, persistedTheme, themeSync, realtimeChannel, toastTimer } = workspace;
    const workspaceReady = ref(!isTelegram);
    const applyTheme = (...args) => workspace.applyTheme(...args);
    const showToast = (...args) => workspace.showToast(...args);
    const onOutsideClick = (...args) => workspace.onOutsideClick(...args);
    const onKeyDown = (...args) => workspace.onKeyDown(...args);
    const { upcomingLessons } = workspace;
    let realtimeRefreshTimer = 0;
    const cachedWorkspace = ref(false);
    const telegramUserId = getTelegramUserId();
    const initialCache = isTelegram ? readWorkspaceCache(telegramUserId) : null;
    const cachedWorkspaceUserId = ref(initialCache?.supabaseUserId || '');
    let profileThemeReadVersion = 0;
    let fullscreenWebApp = null;

    function onTelegramFullscreenFailed(event = {}) {
        console.warn(
            'Telegram Mini App could not enter fullscreen mode:',
            event.error || 'UNKNOWN',
        );
    }

    function requestTelegramFullscreen(webApp) {
        if (!isTelegram || typeof webApp?.requestFullscreen !== 'function') return;

        if (typeof webApp.isVersionAtLeast === 'function' && !webApp.isVersionAtLeast('8.0')) {
            return;
        }

        if (webApp.isFullscreen) return;

        fullscreenWebApp = webApp;
        webApp.onEvent?.('fullscreenFailed', onTelegramFullscreenFailed);

        try {
            webApp.requestFullscreen();
        } catch (error) {
            console.warn('Telegram Mini App fullscreen request threw an error:', error);
        }
    }

    function withTimeout(promise, duration, message) {
        let timeoutId = 0;
        const timeout = new Promise((_, reject) => {
            timeoutId = window.setTimeout(() => reject(new Error(message)), duration);
        });

        return Promise.race([promise, timeout]).finally(() => window.clearTimeout(timeoutId));
    }

    if (initialCache) {
        Object.assign(state, initialCache.state);
        state.teacher = { ...state.teacher, ...initialCache.state.teacher };
        state.studentUser = { ...state.studentUser, ...initialCache.state.studentUser };
        state.themeId = normalizeTheme(initialCache.state.themeId);
        persistedTheme.value = normalizeTheme(initialCache.profile.theme_id);
        themeSync.pending = state.themeId !== persistedTheme.value;
        auth.profile = initialCache.profile;
        cachedWorkspace.value = true;
        workspaceReady.value = true;
        applyTheme();
    }

    function scheduleRemoteRefresh() {
        if (!auth.user) return;

        window.clearTimeout(realtimeRefreshTimer);
        realtimeRefreshTimer = window.setTimeout(() => {
            workspace.loadRemoteWorkspace().catch(workspace.handleRemoteError);
        }, 120);
    }

    function refreshWhenVisible() {
        if (!document.hidden) scheduleRemoteRefresh();
    }

    async function resolveAvatar(path, fallback = '') {
        if (!path) return fallback;
        const { data } = await supabase.storage.from('profile-avatars').createSignedUrl(path, 86400);
        return data?.signedUrl || fallback;
    }

    function handleRemoteError(error) {
        console.error(error);
        const message = error?.message || 'Не удалось загрузить профиль. Проверьте подключение и права доступа.';

        if (workspaceReady.value) {
            if (cachedWorkspace.value) {
                auth.error = message;
            }
            showToast(`Не удалось обновить данные: ${message}`);
            return;
        }

        auth.error = message;
    }

    async function loadRemoteWorkspace() {
        if (!auth.user) return;
        const themeReadVersion = ++profileThemeReadVersion;
        const themeRevisionAtStart = themeSync.revision;
        const themeWasPendingAtStart = themeSync.pending;
        const themeWasSavingAtStart = themeSync.saving;
        const { data: profile, error: profileError } = await supabase.from('profiles').select('*').eq('id', auth.user.id).single();
        if (profileError) throw profileError;
        const profileTheme = normalizeTheme(profile.theme_id);
        auth.profile = profile;
        const query = supabase.from('students').select('*').order('name');
        const { data: studentRows, error: studentsError } = await (profile.role === 'teacher'
            ? query.eq('teacher_id', auth.user.id).eq('is_confirmed', true)
            : query.eq('auth_user_id', auth.user.id));
        if (studentsError) throw studentsError;
        const rows = studentRows || [];
        auth.setup = profile.role === 'student' && rows.length === 0;
        const ids = rows.map((student) => student.id);
        let lessonRows = [], paymentRows = [], homeworkRows = [], notificationRows = [];
        if (ids.length) {
            const responses = await Promise.all([
                supabase.from('lessons').select('*').in('student_id', ids).order('starts_at'),
                supabase.from('payments').select('*').in('student_id', ids).order('requested_at', { ascending: false }),
                supabase.from('homework').select('*').in('student_id', ids).order('created_at', { ascending: false }),
                supabase.from('notifications').select('*').order('created_at', { ascending: false }),
            ]);
            const failed = responses.find((result) => result.error);
            if (failed) throw failed.error;
            [lessonRows, paymentRows, homeworkRows, notificationRows] = responses.map(({ data }) => data || []);
        } else if (profile.role === 'teacher') {
            const result = await supabase.from('notifications').select('*').order('created_at', { ascending: false });
            if (result.error) throw result.error;
            notificationRows = result.data || [];
        }
        let customPlanRows = [];
        const students = await Promise.all(rows.map(async (row) => {
            const linkedProfile = row.auth_user_id ? await supabase.from('profiles').select('avatar_url, avatar_path, telegram_username').eq('id', row.auth_user_id).maybeSingle() : { data: null };
            const attendance = lessonRows.filter((lesson) => lesson.student_id === row.id && lesson.status === 'completed').map((lesson) => ({ date: dateKey(new Date(lesson.starts_at)), time: new Intl.DateTimeFormat('ru-RU', { hour: '2-digit', minute: '2-digit' }).format(new Date(lesson.starts_at)), status: ({ attended: 'Была', missed: 'Не была', rescheduled: 'Перенос' })[lesson.attendance_status] || 'Завершено' })).sort((a, b) => b.date.localeCompare(a.date));
            const linked = linkedProfile.data;
            return { id: row.id, name: row.name, color: row.color || '', paidLessons: row.lessons_remaining || 0, paymentStatus: row.payment_status || 'unpaid', username: row.telegram_username || linked?.telegram_username || '', telegramId: row.telegram_id ? String(row.telegram_id) : '', phone: row.phone || '', teacherId: row.teacher_id, authUserId: row.auth_user_id, lastPayment: row.last_payment_at || '', nextPayment: row.next_payment_at || '', boardLink: row.board_link || '', customSingleLessonPrice: row.custom_single_lesson_price_rub === null || row.custom_single_lesson_price_rub === undefined ? null : Number(row.custom_single_lesson_price_rub), customPlans: [], attendance, avatarUrl: await resolveAvatar(linked?.avatar_path, linked?.avatar_url) };
        }));
        const lessons = lessonRows.map((row) => {
            const start = new Date(row.starts_at);
            return {
                id: row.id,
                studentId: row.student_id,
                teacherId: row.teacher_id,
                date: dateKey(start),
                time: new Intl.DateTimeFormat('ru-RU', {
                    hour: '2-digit',
                    minute: '2-digit',
                }).format(start),
                status: row.status === 'completed' || row.status === 'cancelled'
                    ? row.status
                    : row.payment_status,
                paymentStatus: row.payment_status,
                lessonStatus: row.status,
                durationMinutes: row.duration_minutes,
                title: row.title || 'Английский',
                kind: `${row.title || 'Английский'} · ${row.duration_minutes} мин`,
                attendanceStatus: row.attendance_status,
            };
        });
        const homework = await Promise.all(homeworkRows.map(async (row) => {
            const fileResult = row.file_path ? await supabase.storage.from('homework-files').createSignedUrl(row.file_path, 86400) : null;
            return { id: row.id, studentId: row.student_id, teacherId: row.teacher_id, title: row.title, description: row.description, dueDate: row.due_at || '', label: row.label || '', filename: row.file_name || '', fileData: fileResult?.data?.signedUrl || '', filePath: row.file_path || '', status: row.status, createdAt: row.created_at || '' };
        }));
        const teacherId = profile.role === 'teacher' ? auth.user.id : rows[0]?.teacher_id;
        let teacherProfile = profile.role === 'teacher' ? profile : null;
        if (profile.role === 'student' && teacherId) {
            const result = await supabase.from('profiles').select('*').eq('id', teacherId).maybeSingle();
            if (result.error) throw result.error;
            teacherProfile = result.data;
        }
        let settings = null, plans = [];
        if (teacherId) {
            const [settingsResult, plansResult, customPlansResult] = await Promise.all([
                supabase.from('teacher_settings').select('*').eq('teacher_id', teacherId).maybeSingle(),
                supabase.from('subscription_plans').select('*').eq('teacher_id', teacherId).order('sort_order'),
                supabase.from('student_subscription_plans').select('*').eq('teacher_id', teacherId).order('sort_order'),
            ]);
            if (settingsResult.error) throw settingsResult.error;
            if (plansResult.error) throw plansResult.error;
            if (customPlansResult.error) throw customPlansResult.error;
            settings = settingsResult.data;
            plans = plansResult.data || [];
            customPlanRows = customPlansResult.data || [];
        }
        const defaultPlans = plans.map((plan) => ({ id: plan.id, lessons: plan.lesson_count, price: Number(plan.price_rub) || 0, active: Boolean(plan.is_active) }));
        const customPlansByStudent = new Map();
        customPlanRows.forEach((plan) => {
            const plansForStudent = customPlansByStudent.get(plan.student_id) || [];
            plansForStudent.push({ id: plan.id, studentId: plan.student_id, lessons: plan.lesson_count, price: Number(plan.price_rub) || 0, active: Boolean(plan.is_active) });
            customPlansByStudent.set(plan.student_id, plansForStudent);
        });
        students.forEach((studentItem) => {
            studentItem.customPlans = customPlansByStudent.get(studentItem.id) || [];
        });
        const student = students[0];
        const teacherAvatar = teacherProfile ? await resolveAvatar(teacherProfile.avatar_path, teacherProfile.avatar_url) : '';
        state.role = profile.role;
        const canApplyProfileTheme = themeReadVersion === profileThemeReadVersion
            && themeRevisionAtStart === themeSync.revision
            && !themeWasPendingAtStart
            && !themeSync.pending;
        if (canApplyProfileTheme) {
            state.themeId = profileTheme;
            persistedTheme.value = profileTheme;
        } else if (themeSync.pending && !themeSync.saving) {
            persistedTheme.value = profileTheme;
        } else if (themeRevisionAtStart === themeSync.revision && !themeWasSavingAtStart && !themeSync.saving) {
            persistedTheme.value = profileTheme;
        }
        if (themeSync.pending && !themeSync.saving && profileTheme === state.themeId) {
            themeSync.pending = false;
            auth.profile = { ...profile, theme_id: state.themeId };
        }
        state.students = students;
        state.lessons = lessons;
        state.homework = homework;
        state.payments = paymentRows.map((row) => ({ id: row.id, studentId: row.student_id, teacherId: row.teacher_id, lessons: row.lesson_count, amount: Number(row.amount_rub) || 0, status: row.status === 'confirmed' ? 'paid' : row.status, date: cap(formatDay(dateKey(new Date(row.requested_at)))) }));
        state.notifications = notificationRows.map((row) => ({ id: row.id, role: profile.role, title: row.title, body: row.body, time: row.created_at ? 'Недавно' : 'Сегодня', read: Boolean(row.read_at), lessonId: row.lesson_id || '', outcome: row.lesson_outcome || '' }));
        state.teacher = { ...state.teacher, id: teacherId || '', name: teacherProfile?.full_name || auth.user.user_metadata?.full_name || auth.user.email || 'Преподаватель', username: teacherProfile?.telegram_username || '', avatarUrl: teacherAvatar, bio: teacherProfile?.teacher_bio || '', experience: teacherProfile?.teacher_experience || '', specialization: teacherProfile?.teacher_specialization || '', lessonFormat: teacherProfile?.lesson_format || '', lessonRules: teacherProfile?.lesson_rules || '', zoomLink: teacherProfile?.zoom_link || '', lessonDurationMinutes: settings?.lesson_duration_minutes || 60, singleLessonPrice: Number(settings?.single_lesson_price_rub ?? 1200) };
        state.subscriptionPlans = profile.role === 'student'
            ? getStudentPlans(defaultPlans, student?.customPlans || [])
            : defaultPlans;
        state.studentUser = { id: student?.id || '', name: profile.full_name || student?.name || auth.user.user_metadata?.full_name || 'Ученик', avatarUrl: await resolveAvatar(profile.avatar_path, profile.avatar_url), boardLink: student?.boardLink || '', lessonsLeft: student?.paidLessons || 0, lastPayment: student?.lastPayment || '', nextPayment: student?.nextPayment || '', progress: Math.max(0, Math.min(100, ((8 - (student?.paidLessons || 0)) / 8) * 100)) };
        if (!state.selectedDate) state.selectedDate = upcomingLessons.value[0]?.date || todayKey();
        if (!state.calendarMonth) state.calendarMonth = state.selectedDate.slice(0, 7);
        applyTheme();
        workspaceReady.value = true;
        auth.error = '';
        cachedWorkspaceUserId.value = auth.user.id;
        if (themeReadVersion === profileThemeReadVersion && themeSync.pending && !themeSync.saving) {
            await workspace.setTheme(state.themeId);
        }
        if (!themeSync.pending && auth.profile?.theme_id !== persistedTheme.value) {
            auth.profile = { ...auth.profile, theme_id: persistedTheme.value };
        }
        writeWorkspaceCache(telegramUserId || profile.telegram_id, auth.user.id, auth.profile || profile, state);
    }

    async function authenticateTelegram() {
        const initData = window.Telegram?.WebApp?.initData
            || new URLSearchParams(window.location.search).get('tgWebAppData');

        if (!initData) {
            auth.loading = false;
            auth.error = 'Telegram не передал данные авторизации. Закройте приложение и откройте его через кнопку бота.';
            return;
        }

        auth.loading = true;
        auth.error = '';
        auth.setup = false;
        try {
            const { data, error } = await withTimeout(
                supabase.functions.invoke('link-telegram', { body: { initData } }),
                20000,
                'Проверка подключения заняла слишком много времени. Проверьте интернет и попробуйте снова.',
            );
            if (error) {
                const response = error.context;
                const body = response?.clone ? await response.clone().json().catch(() => null) : null;
                throw new Error(body?.error ? `${body.error} (HTTP ${response.status})` : error.message);
            }
            if (!data?.session?.access_token || !data.session.refresh_token || !data.profile) throw new Error(data?.error || 'Сервер не вернул сессию Telegram.');
            const { data: session, error: sessionError } = await supabase.auth.setSession(data.session);
            if (sessionError) throw sessionError;
            auth.user = session.session?.user || data.session.user;
            await loadRemoteWorkspace();
            auth.loading = false;
        } catch (error) {
            auth.loading = false;
            handleRemoteError(error);
        }
    }

    function startRealtimeSubscription() {
        if (!auth.user || realtimeChannel.value) return;

        const profileRole = auth.profile?.role || state.role;
        const teacherId = profileRole === 'teacher' ? auth.user.id : state.teacher.id;
        const studentFilter = profileRole === 'teacher'
            ? `teacher_id=eq.${auth.user.id}`
            : `auth_user_id=eq.${auth.user.id}`;
        let channel = supabase.channel(`lessonly-vue-${auth.user.id}`)
            .on('postgres_changes', { event: '*', schema: 'public', table: 'payments' }, scheduleRemoteRefresh)
            .on('postgres_changes', { event: '*', schema: 'public', table: 'lessons' }, scheduleRemoteRefresh)
            .on('postgres_changes', { event: '*', schema: 'public', table: 'homework' }, scheduleRemoteRefresh)
            .on('postgres_changes', { event: '*', schema: 'public', table: 'students', filter: studentFilter }, scheduleRemoteRefresh)
            .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles', filter: `id=eq.${auth.user.id}` }, scheduleRemoteRefresh)
            .on('postgres_changes', { event: '*', schema: 'public', table: 'notifications', filter: `recipient_profile_id=eq.${auth.user.id}` }, scheduleRemoteRefresh);

        if (teacherId) {
            if (teacherId !== auth.user.id) {
                channel = channel.on('postgres_changes', { event: '*', schema: 'public', table: 'profiles', filter: `id=eq.${teacherId}` }, scheduleRemoteRefresh);
            }
            channel = channel
                .on('postgres_changes', { event: '*', schema: 'public', table: 'teacher_settings', filter: `teacher_id=eq.${teacherId}` }, scheduleRemoteRefresh)
                .on('postgres_changes', { event: '*', schema: 'public', table: 'subscription_plans', filter: `teacher_id=eq.${teacherId}` }, scheduleRemoteRefresh)
                .on('postgres_changes', { event: '*', schema: 'public', table: 'student_subscription_plans', filter: profileRole === 'teacher' ? `teacher_id=eq.${teacherId}` : `student_id=eq.${state.studentUser.id}` }, scheduleRemoteRefresh);
        }

        realtimeChannel.value = channel.subscribe((status, error) => {
                if (status === 'SUBSCRIBED') {
                    scheduleRemoteRefresh();
                } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
                    console.error(`Supabase Realtime ${status.toLowerCase()}:`, error);
                }
            });
    }

    async function restoreCachedSession() {
        if (!initialCache) return false;

        try {
            const { data, error } = await withTimeout(
                supabase.auth.getSession(),
                10000,
                'Проверка сохранённой сессии заняла слишком много времени.',
            );
            const session = data?.session;

            if (error || session?.user?.id !== initialCache.supabaseUserId) return false;

            auth.user = session.user;
            auth.profile = initialCache.profile;
            auth.error = '';
            auth.loading = false;
            startRealtimeSubscription();
            loadRemoteWorkspace().catch(handleRemoteError);

            return true;
        } catch {
            return false;
        }
    }

    onMounted(async () => {
        document.addEventListener('click', onOutsideClick);
        document.addEventListener('keydown', onKeyDown);
        document.addEventListener('visibilitychange', refreshWhenVisible);
        window.addEventListener('focus', scheduleRemoteRefresh);

        const webApp = window.Telegram?.WebApp;
        webApp?.ready();
        webApp?.expand();
        requestTelegramFullscreen(webApp);

        if (isTelegram && !await restoreCachedSession()) {
            await authenticateTelegram();
            startRealtimeSubscription();
        }
    });

    onUnmounted(() => {
        document.removeEventListener('click', onOutsideClick);
        document.removeEventListener('keydown', onKeyDown);
        document.removeEventListener('visibilitychange', refreshWhenVisible);
        window.removeEventListener('focus', scheduleRemoteRefresh);
        window.clearTimeout(realtimeRefreshTimer);
        window.clearTimeout(toastTimer.value);
        fullscreenWebApp?.offEvent?.('fullscreenFailed', onTelegramFullscreenFailed);
        fullscreenWebApp = null;

        if (realtimeChannel.value) {
            void supabase.removeChannel(realtimeChannel.value);
        }
    });

    return {
        workspaceReady,
        cachedWorkspace,
        cachedWorkspaceUserId,
        resolveAvatar,
        handleRemoteError,
        loadRemoteWorkspace,
        authenticateTelegram,
    };
}
