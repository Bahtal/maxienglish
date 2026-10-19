export function getStudentPlans(defaultPlans = [], customPlans = []) {
    return customPlans.length ? customPlans : defaultPlans;
}

export function getStudentSingleLessonPrice(customPrice, defaultPrice) {
    return customPrice ?? defaultPrice;
}
