import { dateObject } from './appConfig.js';

export const calendarLessonLegend = [
    { key: 'paidUpcoming', label: 'Оплачен · впереди' },
    { key: 'paidPast', label: 'Оплачен · прошёл' },
    { key: 'cancelled', label: 'Отменён' },
    { key: 'unpaidPast', label: 'Не оплачен · прошёл' },
    { key: 'unpaidUpcoming', label: 'Не оплачен · впереди' },
];

export function getCalendarLessonMarker(lesson, now = new Date()) {
    if (lesson.lessonStatus === 'cancelled' || lesson.status === 'cancelled') {
        return 'cancelled';
    }

    const paymentStatus = lesson.paymentStatus
        || (['paid', 'awaiting', 'unpaid'].includes(lesson.status) ? lesson.status : 'unpaid');
    const hasPassed = lesson.lessonStatus === 'completed'
        || dateObject(lesson.date, lesson.time) <= now;

    if (paymentStatus === 'paid') {
        return hasPassed ? 'paidPast' : 'paidUpcoming';
    }

    return hasPassed ? 'unpaidPast' : 'unpaidUpcoming';
}
