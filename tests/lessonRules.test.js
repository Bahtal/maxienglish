import test from 'node:test';
import assert from 'node:assert/strict';
import { findPastLessonForAttendance, hasLessonOverlap } from '../src/utils/lessonRules.js';

test('attendance picker returns the closest past scheduled lesson only', () => {
    const now = new Date('2026-10-16T12:00:00');
    const lessons = [
        { id: 'future', studentId: 'student-1', date: '2026-10-16', time: '13:00', lessonStatus: 'scheduled' },
        { id: 'old', studentId: 'student-1', date: '2026-10-15', time: '16:00', lessonStatus: 'scheduled' },
        { id: 'recent', studentId: 'student-1', date: '2026-10-16', time: '11:00', lessonStatus: 'scheduled' },
        { id: 'attended', studentId: 'student-1', date: '2026-10-16', time: '10:00', lessonStatus: 'scheduled', attendanceStatus: 'attended' },
        { id: 'other-student', studentId: 'student-2', date: '2026-10-16', time: '11:30', lessonStatus: 'scheduled' },
        { id: 'cancelled', studentId: 'student-1', date: '2026-10-16', time: '09:00', lessonStatus: 'cancelled' },
    ];

    assert.equal(findPastLessonForAttendance(lessons, 'student-1', now)?.id, 'recent');
});

test('attendance picker has no result when there is no unmarked past lesson', () => {
    const now = new Date('2026-10-16T12:00:00');
    const lessons = [
        { id: 'future', studentId: 'student-1', date: '2026-10-16', time: '13:00', lessonStatus: 'scheduled' },
        { id: 'attended', studentId: 'student-1', date: '2026-10-16', time: '11:00', lessonStatus: 'scheduled', attendanceStatus: 'attended' },
    ];

    assert.equal(findPastLessonForAttendance(lessons, 'student-1', now), undefined);
});

test('lesson overlap handles intersecting and adjacent time ranges', () => {
    const lessons = [
        { id: 'scheduled', date: '2026-10-17', time: '10:00', durationMinutes: 60, lessonStatus: 'scheduled' },
    ];

    assert.equal(hasLessonOverlap(lessons, new Date('2026-10-17T10:30:00'), 60), true);
    assert.equal(hasLessonOverlap(lessons, new Date('2026-10-17T11:00:00'), 60), false);
});

test('lesson overlap options ignore completed lessons and the lesson being moved', () => {
    const lessons = [
        { id: 'completed', date: '2026-10-17', time: '10:00', durationMinutes: 60, lessonStatus: 'completed' },
        { id: 'moving', date: '2026-10-17', time: '10:00', durationMinutes: 60, lessonStatus: 'scheduled' },
    ];

    assert.equal(hasLessonOverlap(lessons, new Date('2026-10-17T10:30:00'), 60, { ignoreCompleted: true }), true);
    assert.equal(hasLessonOverlap(lessons, new Date('2026-10-17T10:30:00'), 60, {
        ignoreCompleted: true,
        excludeLessonId: 'moving',
    }), false);
});
