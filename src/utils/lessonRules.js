import { dateObject } from './appConfig.js';

export function findPastLessonForAttendance(lessons, studentId, now = new Date()) {
    return lessons
        .filter((lesson) => lesson.studentId === studentId
            && lesson.lessonStatus === 'scheduled'
            && !lesson.attendanceStatus
            && dateObject(lesson.date, lesson.time) < now)
        .sort((first, second) => `${second.date} ${second.time}`.localeCompare(`${first.date} ${first.time}`))[0];
}

export function hasLessonOverlap(lessons, startAt, durationMinutes, options = {}) {
    const start = startAt instanceof Date ? startAt.getTime() : Number(startAt);
    if (!Number.isFinite(start)) return true;

    const duration = Number(durationMinutes) || 60;
    const end = start + duration * 60000;
    const ignoreCompleted = Boolean(options.ignoreCompleted);
    const excludeLessonId = options.excludeLessonId || '';

    return lessons.some((lesson) => {
        if (lesson.id === excludeLessonId
            || lesson.lessonStatus === 'cancelled'
            || (ignoreCompleted && lesson.lessonStatus === 'completed')) {
            return false;
        }

        const otherStart = dateObject(lesson.date, lesson.time).getTime();
        if (!Number.isFinite(otherStart)) return false;

        const otherEnd = otherStart + (Number(lesson.durationMinutes) || 60) * 60000;
        return otherStart < end && start < otherEnd;
    });
}
