import { computed, onUnmounted, reactive, ref } from 'vue';
import { STORE_KEY, weekdays, weekdaysShort, themeOptions, allowedThemeIds, normalizeTheme, dateKey, todayKey, nextDate, dateObject, formatDay, formatWeekday, cap, initials, humanCount, dateTimeIso, statusLabel, statusClass, isDoneHomework } from '../utils/appConfig.js';
import { getCalendarLessonMarker } from '../utils/calendarMarkers.js';
import { makeSeed, loadDemo } from '../utils/demoData.js';

export function useWorkspaceState() {
    const state = reactive(loadDemo());
    const calendarNow = ref(new Date());
    const calendarClockTimer = window.setInterval(() => {
        calendarNow.value = new Date();
    }, 60000);

    onUnmounted(() => window.clearInterval(calendarClockTimer));

    if (!state.selectedDate) {
        state.selectedDate = [...state.lessons]
            .sort((a, b) => `${a.date} ${a.time}`.localeCompare(`${b.date} ${b.time}`))[0]?.date || todayKey();
    }

    if (!state.calendarMonth) {
        state.calendarMonth = state.selectedDate.slice(0, 7);
    }

    const webApp = window.Telegram?.WebApp;
    const telegramParams = new URLSearchParams(window.location.search);
    const isTelegram = Boolean(
        webApp?.initData
        || (webApp?.platform && webApp.platform !== 'unknown')
        || telegramParams.has('tgWebAppData')
        || telegramParams.has('tgWebAppVersion')
        || telegramParams.has('tgWebAppPlatform')
    );
    const auth = reactive({ loading: isTelegram, user: null, profile: null, error: '', setup: false });
    const modal = reactive({ type: '', title: '', subtitle: '', data: null, busy: false, error: '' });
    const toast = ref('');
    const toastTimer = ref(0);
    const realtimeChannel = ref(null);
    const persistedTheme = ref(state.themeId);
    const themeSync = reactive({ revision: 0, pending: false, saving: false });
    const notificationRef = ref(null);
    const profileForm = reactive({ plans: [] });
    const themeReturnPage = ref('home');

    const filters = computed(() => [
        { value: 'all', label: 'Все' },
        ...[...new Set(upcomingLessons.value.map((lesson) => dateObject(lesson.date).getDay()))]
            .sort((a, b) => ((a + 6) % 7) - ((b + 6) % 7))
            .map((day) => ({ value: `weekday:${day}`, label: cap(weekdays[day]) })),
    ]);
    const activeProfile = computed(() => state.role === 'student'
        ? { name: state.studentUser.name, avatarUrl: state.studentUser.avatarUrl, color: 'purple', caption: 'Ученица' }
        : { name: state.teacher.name, avatarUrl: state.teacher.avatarUrl, color: '', caption: 'Преподаватель' });
    const selectedStudent = computed(() => state.students.find((student) => student.id === state.studentUser.id) || state.students[0]);
    const selectedLesson = computed(() => state.lessons.find((lesson) => lesson.date === state.selectedDate));
    const upcomingLessons = computed(() => state.lessons
        .filter((lesson) => lesson.lessonStatus !== 'cancelled'
            && lesson.lessonStatus !== 'completed'
            && lesson.status !== 'cancelled'
            && lesson.status !== 'completed'
            && dateObject(lesson.date, lesson.time) >= new Date())
        .sort((a, b) => `${a.date} ${a.time}`.localeCompare(`${b.date} ${b.time}`)));
    const visibleLessons = computed(() => upcomingLessons.value.filter((lesson) => state.role === 'teacher' || lesson.studentId === state.studentUser.id));
    const calendarLessons = computed(() => state.lessons
        .filter((lesson) => state.role === 'teacher' || lesson.studentId === state.studentUser.id)
        .sort((a, b) => `${a.date} ${a.time}`.localeCompare(`${b.date} ${b.time}`)));
    const filteredTeacherLessons = computed(() => state.selectedFilter === 'all'
        ? upcomingLessons.value
        : upcomingLessons.value.filter((lesson) => `weekday:${dateObject(lesson.date).getDay()}` === state.selectedFilter));
    const homeworkList = computed(() => [...state.homework]
        .filter((item) => state.role === 'teacher' || item.studentId === state.studentUser.id)
        .sort((a, b) => Date.parse(b.createdAt || '') - Date.parse(a.createdAt || '')));
    const homeworkLabels = computed(() => {
        const labels = new Map();

        state.homework.forEach((item) => {
            const label = String(item.label || '').trim().replace(/\s+/g, ' ');
            const key = label.toLocaleLowerCase('ru-RU');

            if (label && !labels.has(key)) {
                labels.set(key, label);
            }
        });

        return [...labels.values()].sort((first, second) => first.localeCompare(second, 'ru'));
    });
    const studentHomework = computed(() => homeworkList.value.filter((item) => item.studentId === state.studentUser.id));
    const calendarDays = computed(() => {
        const [year, month] = state.calendarMonth.split('-').map(Number);
        const first = new Date(year, month - 1, 1);
        const offset = (first.getDay() + 6) % 7;
        const total = Math.ceil((offset + new Date(year, month, 0).getDate()) / 7) * 7;
        const markersByDate = new Map();

        calendarLessons.value.forEach((lesson) => {
            const marker = getCalendarLessonMarker(lesson, calendarNow.value);
            const markers = markersByDate.get(lesson.date) || new Set();
            markers.add(marker);
            markersByDate.set(lesson.date, markers);
        });

        return Array.from({ length: total }, (_, index) => {
            const date = new Date(year, month - 1, index - offset + 1);
            const key = dateKey(date);
            const markers = [...(markersByDate.get(key) || [])];

            return {
                key,
                label: date.getDate(),
                muted: date.getMonth() !== month - 1,
                today: key === todayKey(),
                selected: key === state.selectedDate,
                markers,
            };
        });
    });
    const monthLabel = computed(() => {
        if (!state.calendarMonth) return '';
        const [year, month] = state.calendarMonth.split('-').map(Number);
        return cap(new Intl.DateTimeFormat('ru-RU', { month: 'long', year: 'numeric' }).format(new Date(year, month - 1, 1)));
    });
    const selectedDayLessons = computed(() => calendarLessons.value.filter((lesson) => lesson.date === state.selectedDate));
    const firstName = computed(() => (state.role === 'teacher' ? state.teacher.name : state.studentUser.name).trim().split(/\s+/)[0] || '');
    const teacherStats = computed(() => [
        { label: 'Всего учеников', value: state.students.length, caption: 'в вашей студии', icon: 'users', clickable: true },
        { label: 'Ждут подтверждения', value: state.payments.filter((payment) => payment.status === 'awaiting').length, caption: 'нужно проверить оплату', icon: 'clock' },
        { label: 'Не оплачено', value: state.students.filter((student) => student.paymentStatus === 'unpaid').length, caption: 'требуют внимания', icon: 'wallet' },
    ]);
    const daySummary = computed(() => {
        const todayLessons = state.lessons.filter((lesson) => lesson.date === todayKey() && lesson.lessonStatus !== 'cancelled');
        return { todayCount: todayLessons.length, next: upcomingLessons.value[0] };
    });

    return {
        STORE_KEY,
        weekdays,
        weekdaysShort,
        themeOptions,
        allowedThemeIds,
        normalizeTheme,
        dateKey,
        todayKey,
        nextDate,
        dateObject,
        formatDay,
        formatWeekday,
        cap,
        initials,
        humanCount,
        dateTimeIso,
        statusLabel,
        statusClass,
        isDoneHomework,
        makeSeed,
        loadDemo,
        state,
        isTelegram,
        auth,
        modal,
        toast,
        toastTimer,
        realtimeChannel,
        persistedTheme,
        themeSync,
        notificationRef,
        profileForm,
        themeReturnPage,
        filters,
        activeProfile,
        selectedStudent,
        selectedLesson,
        upcomingLessons,
        visibleLessons,
        calendarLessons,
        filteredTeacherLessons,
        homeworkList,
        homeworkLabels,
        studentHomework,
        calendarDays,
        monthLabel,
        selectedDayLessons,
        firstName,
        teacherStats,
        daySummary,
    };
}
