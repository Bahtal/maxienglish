<script>
import { computed, unref } from 'vue';
import { useWorkspaceView } from '../composables/useWorkspaceView.js';
import { getStudentSingleLessonPrice } from '../utils/studentPricing.js';

import AppButton from '../components/AppButton.vue';
import StudentBalanceCard from '../components/student/StudentBalanceCard.vue';
import StudentPaymentSummary from '../components/student/StudentPaymentSummary.vue';
import StudentPaymentHistory from '../components/student/StudentPaymentHistory.vue';
import TeacherPaymentRequests from '../components/teacher/TeacherPaymentRequests.vue';
import TeacherPaymentBalances from '../components/teacher/TeacherPaymentBalances.vue';
import TeacherPaymentHistory from '../components/teacher/TeacherPaymentHistory.vue';

export default {
    props: { workspace: { type: Object, required: true } },
    emits: ['workspace-action'],
    components: {
        AppButton,
        StudentBalanceCard,
        StudentPaymentSummary,
        StudentPaymentHistory,
        TeacherPaymentRequests,
        TeacherPaymentBalances,
        TeacherPaymentHistory,
    },
    setup(props, { emit }) {
        const view = useWorkspaceView(props, emit);
        const activePlans = computed(() => props.workspace.state.subscriptionPlans
            .filter((plan) => plan.active));
        const singleLessonPrice = computed(() => {
            const student = unref(props.workspace.selectedStudent);
            return getStudentSingleLessonPrice(
                student?.customSingleLessonPrice,
                props.workspace.state.teacher.singleLessonPrice,
            );
        });
        const paymentMetrics = computed(() => {
            const payments = props.workspace.state.payments;
            const students = props.workspace.state.students;
            const confirmedAmount = payments
                .filter((payment) => payment.status === 'paid')
                .reduce((total, payment) => total + Number(payment.amount || 0), 0);

            return [
                {
                    label: 'Заявки ожидают',
                    value: payments.filter((payment) => payment.status === 'awaiting').length,
                    icon: 'clock',
                },
                {
                    label: 'Занятий осталось',
                    value: students.reduce((total, student) => total + (Number(student.paidLessons) || 0), 0),
                    icon: 'cap',
                },
                {
                    label: 'Подтверждено оплат',
                    value: `${confirmedAmount.toLocaleString('ru-RU')} ₽`,
                    icon: 'wallet',
                },
            ];
        });

        return { ...view, activePlans, singleLessonPrice, paymentMetrics };
    },
};
</script>

<template>
    <div v-if="state.role === 'student'" :class="$style.studentLayout">
        <div :class="$style.column">
            <StudentBalanceCard
                :workspace="workspace"
                @workspace-action="$emit('workspace-action', $event)"
            />
        </div>

        <div :class="$style.column">
            <StudentPaymentSummary :workspace="workspace" />
            <StudentPaymentHistory :workspace="workspace" />
        </div>
    </div>

    <div v-else :class="$style.teacherLayout">
        <div :class="$style.metricsGrid">
            <article
                v-for="metric in paymentMetrics"
                :key="metric.label"
                :class="[$style.card, $style.metricCard]">
                <span :class="$style.sectionIcon">
                    <svg>
                        <use :href="`#icon-${metric.icon}`" />
                    </svg>
                </span>
                <b>{{ metric.value }}</b>
                <span>{{ metric.label }}</span>
            </article>
        </div>

        <TeacherPaymentRequests
            :workspace="workspace"
            @workspace-action="$emit('workspace-action', $event)" />

        <div :class="$style.teacherColumns">
            <TeacherPaymentBalances :workspace="workspace" />
            <TeacherPaymentHistory :workspace="workspace" />
        </div>
    </div>
</template>

<style lang="scss" module>
.studentLayout,
.teacherLayout,
.column {
    display: grid;
    min-width: 0;
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.studentLayout {
    grid-template-columns: minmax(0, 1.05fr) minmax(0, .95fr);
    align-items: start;
}

.teacherLayout {
    grid-template-columns: minmax(0, 1fr);
}

.teacherColumns {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    align-items: start;
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.card {
    min-width: 0;
    border: 1px solid var(--border-color);
    border-radius: $radius;
    background: var(--surface);
    box-shadow: var(--shadow);
}

.planCard {
    padding: $padding;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.sectionHeading {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: $gap;
    margin-bottom: 8px;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }

    h2 {
        margin: 0;
        font-weight: 700;

        @include text(px2);
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);
    }
}

.sectionIcon {
    width: $width-block;
    height: $height-block;
    flex: 0 0 $width-block;
    display: grid;
    place-items: center;
    border-radius: $radius-mini;
    color: var(--purple);
    background: var(--purple-pale);

    svg {
        width: $svg;
        height: $svg;
        fill: none;
        stroke: currentColor;
        stroke-width: 1.8;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
}

.singlePrice,
.planRow {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.singlePrice {
    padding: 12px 13px;
    border-radius: $radius-mini;
    background: var(--canvas);
    color: var(--muted);

    @include text(px2);

    b {
        color: var(--ink);
    }
}

.planList {
    display: grid;
    margin-top: 8px;
}

.planRow {
    padding: 11px 2px;
    border-bottom: 1px solid var(--line);

    @include text(px2);

    strong {
        color: var(--ink);
    }
}

.emptyPlans {
    padding: 15px 3px 4px;
    color: var(--muted);
    font-size: 11px;
    line-height: 1.5;
}

.choosePlanButton {
    width: 100%;
    margin-top: 14px;
}

.metricsGrid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.metricCard {
    min-height: 112px;
    padding: 17px;
    display: grid;
    grid-template-columns: 1fr auto;
    align-items: start;
    gap: $gap-sm;

    > b {
        grid-column: 1;
        overflow-wrap: anywhere;
        font-weight: 700;

        @include text(px2);
    }

    > span:last-child {
        grid-column: 1 / -1;
        color: var(--muted);

        @include text(px2);
    }
}

[data-theme='darked'] {
    .card {
        border-color: var(--line);
        background: var(--surface);
    }

    .singlePrice {
        background: var(--canvas);
    }
}

@include respond-to(tablet) {
    .studentLayout,
    .teacherColumns {
        grid-template-columns: minmax(0, 1fr);
    }
}

@include respond-to(mobile) {
    .studentLayout,
    .teacherLayout,
    .column {
        gap: $gap-sm;
    }

    .teacherColumns {
        grid-template-columns: minmax(0, 1fr);
        gap: $gap-sm;
    }

    .metricsGrid {
        grid-template-columns: minmax(0, 1fr);
        gap: $gap-sm;
    }

    .metricCard {
        min-height: 0;
        padding: 10px 12px;
        grid-template-columns: auto minmax(0, 1fr);
        align-items: center;
        gap: $gap-sm;

        > b,
        > span:last-child {
            grid-column: 2;
        }

        > b {
            grid-row: 1;
            font-size: 16px;
        }

        > span:last-child {
            grid-row: 2;
        }

        .sectionIcon {
            grid-column: 1;
            grid-row: 1 / span 2;
        }
    }
}
</style>
