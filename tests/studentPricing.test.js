import test from 'node:test';
import assert from 'node:assert/strict';
import { getStudentPlans, getStudentSingleLessonPrice } from '../src/utils/studentPricing.js';

test('a student with individual packages sees only those packages', () => {
    const defaults = [{ id: 'default-plan' }];
    const custom = [{ id: 'student-plan' }];

    assert.deepEqual(getStudentPlans(defaults, custom), custom);
});

test('an empty individual package list inherits teacher packages', () => {
    const defaults = [{ id: 'default-plan' }];

    assert.equal(getStudentPlans(defaults, []).at(0), defaults[0]);
});

test('an inactive individual package still overrides teacher packages', () => {
    const custom = [{ id: 'student-plan', active: false }];

    assert.deepEqual(getStudentPlans([{ id: 'default-plan' }], custom), custom);
});

test('a missing individual price inherits the teacher price while zero remains valid', () => {
    assert.equal(getStudentSingleLessonPrice(null, 1500), 1500);
    assert.equal(getStudentSingleLessonPrice(undefined, 1500), 1500);
    assert.equal(getStudentSingleLessonPrice(0, 1500), 0);
    assert.equal(getStudentSingleLessonPrice(2000, 1500), 2000);
});
