export function getStudentPlans(defaultPlans = [], customPlans = []) {
    return customPlans.length ? customPlans : defaultPlans;
}

export function getStudentSingleLessonPrice(customPrice, defaultPrice, customPlans = []) {
    if (customPrice !== null && customPrice !== undefined && customPrice !== '') {
        return Number(customPrice) || 0;
    }

    const activeCustomPlans = customPlans
        .filter((plan) => plan.active && Number(plan.lessons) > 0)
        .sort((first, second) => Number(first.lessons) - Number(second.lessons));
    const smallestCustomPlan = activeCustomPlans[0];

    if (smallestCustomPlan) {
        const price = Number(smallestCustomPlan.price) || 0;
        const lessonCount = Number(smallestCustomPlan.lessons);

        return Number((price / lessonCount).toFixed(2));
    }

    return Number(defaultPrice) || 0;
}

export function getStudentPaymentAmount(lessonCount, plans = [], unitPrice = 0) {
    const matchingPlan = plans.find((plan) => (
        plan.active && Number(plan.lessons) === Number(lessonCount)
    ));

    if (matchingPlan) {
        return Number(matchingPlan.price) || 0;
    }

    return (Number(unitPrice) || 0) * Number(lessonCount);
}
