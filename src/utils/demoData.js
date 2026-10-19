import { STORE_KEY, todayKey, nextDate, formatDay } from './appConfig.js';

// Initial local workspace used before connecting a Telegram profile.
export function makeSeed() {
  const students = [
    { id: 'maria', name: 'Мария Соколова', color: 'purple', paidLessons: 3, paymentStatus: 'paid', username: 'maria_sokolova', boardLink: '', attendance: [] },
    { id: 'artem', name: 'Артём Бахталов', color: 'blue', paidLessons: 4, paymentStatus: 'paid', username: 'artem_bahtalov', boardLink: '', attendance: [] },
    { id: 'liza', name: 'Елизавета Ким', color: 'mint', paidLessons: 2, paymentStatus: 'awaiting', username: 'liza_kim', boardLink: '', attendance: [] },
    { id: 'marina', name: 'Марина Орлова', color: '', paidLessons: 6, paymentStatus: 'paid', username: 'marina_orlova', boardLink: '', attendance: [] },
    { id: 'nikita', name: 'Никита Павлов', color: 'blue', paidLessons: 1, paymentStatus: 'unpaid', username: 'nikita_pavlov', boardLink: '', attendance: [] },
    { id: 'sofia', name: 'София Иванова', color: 'mint', paidLessons: 5, paymentStatus: 'paid', username: 'sofia_ivanova', boardLink: '', attendance: [] },
  ];
  const lesson = (id, studentId, weekday, weeks, time, status = 'paid') => ({
    id, studentId, date: nextDate(weekday, weeks, time), time, status,
    lessonStatus: 'scheduled', durationMinutes: 60, title: 'Английский', kind: 'Английский · 60 мин',
  });
  return {
    role: 'student', page: 'home', themeId: 'default', demoThemeIds: { student: 'default', teacher: 'default' },
    selectedFilter: 'all', selectedDate: '', calendarMonth: '', notificationOpen: false,
    teacher: { id: '', name: 'Елена', role: 'Репетитор английского', username: 'english_teacher_demo', avatarUrl: '', bio: 'Помогаю говорить по-английски увереннее и спокойно использовать язык в жизни.', experience: '7 лет', specialization: 'Разговорный английский · грамматика', lessonFormat: 'Онлайн · Zoom', lessonRules: 'Если нужно перенести занятие, пожалуйста, сообщите заранее.', zoomLink: '', lessonDurationMinutes: 60, singleLessonPrice: 1200 },
    subscriptionPlans: [{ id: 'plan-4', lessons: 4, price: 4800, active: true }, { id: 'plan-8', lessons: 8, price: 8800, active: true }, { id: 'plan-12', lessons: 12, price: 12000, active: true }],
    studentUser: { id: 'maria', name: 'Мария Соколова', avatarUrl: '', boardLink: '', lessonsLeft: 3, lastPayment: todayKey(), nextPayment: nextDate(3), progress: 76 },
    students,
    lessons: [lesson('lesson-1', 'maria', 3, 0, '11:00'), lesson('lesson-2', 'artem', 3, 0, '13:00', 'awaiting'), lesson('lesson-3', 'liza', 5, 0, '12:30'), lesson('lesson-4', 'marina', 5, 0, '15:00'), lesson('lesson-5', 'artem', 1, 0, '17:00', 'unpaid'), lesson('lesson-6', 'maria', 3, 1, '11:00')],
    homework: [
      { id: 'hw-1', studentId: 'maria', title: 'Unit 4 · Vocabulary', description: 'Повторить слова и составить 5 предложений.', dueDate: nextDate(3), label: '', filename: '', status: 'new', createdAt: new Date().toISOString() },
      { id: 'hw-2', studentId: 'artem', title: 'Past Simple practice', description: 'Упражнение 6, страница 42.', dueDate: nextDate(5), label: '', filename: '', status: 'new', createdAt: new Date(Date.now() - 3600000).toISOString() },
    ],
    payments: [{ id: 'pay-liza', studentId: 'liza', lessons: 4, amount: 4800, status: 'awaiting', date: formatDay(todayKey()) }],
    notifications: [
      { id: 'n-1', role: 'student', title: 'Скоро занятие', body: 'Следующее занятие — в среду в 11:00.', time: 'Сегодня', read: false },
      { id: 'n-2', role: 'teacher', title: 'Подтвердите оплату', body: 'Заявка на абонемент ждёт проверки.', time: 'Сегодня', read: false },
    ],
  };
}

export function loadDemo() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORE_KEY) || 'null');
    const base = makeSeed();
    if (!saved) return base;
    return { ...base, ...saved, teacher: { ...base.teacher, ...(saved.teacher || {}) }, demoThemeIds: { ...base.demoThemeIds, ...(saved.demoThemeIds || {}) } };
  } catch { return makeSeed(); }
}
