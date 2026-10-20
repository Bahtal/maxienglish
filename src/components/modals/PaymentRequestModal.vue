<script>
import { computed, ref, unref, watch } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';
import { getStudentPaymentAmount, getStudentSingleLessonPrice } from '../../utils/studentPricing.js';

import AppButton from '../AppButton.vue';
import StudentLessonCountPicker from '../student/StudentLessonCountPicker.vue';
import VEmptyState from '../VEmptyState.vue';
import VModalActions from '../VModalActions.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, StudentLessonCountPicker, VEmptyState, VModalActions },
  setup(props, { emit }) {
    const view = useWorkspaceView(props, emit);
    const selectedLessonCount = ref(1);

    view.activePlans = computed(() => props.workspace.state.subscriptionPlans.filter((plan) => plan.active));
    view.maxLessonCount = computed(() => view.activePlans.value.reduce((maximum, plan) => (
      Math.max(maximum, Number(plan.lessons) || 0)
    ), 0));
    view.effectiveSingleLessonPrice = computed(() => {
      const student = unref(props.workspace.selectedStudent);
      return getStudentSingleLessonPrice(
        student?.customSingleLessonPrice,
        props.workspace.state.teacher.singleLessonPrice,
        student?.customPlans,
      );
    });
    view.selectedLessonCount = selectedLessonCount;
    view.matchingPlan = computed(() => view.activePlans.value.find((plan) => (
      Number(plan.lessons) === selectedLessonCount.value
    )) || null);
    view.totalAmount = computed(() => getStudentPaymentAmount(
      selectedLessonCount.value,
      view.activePlans.value,
      view.effectiveSingleLessonPrice.value,
    ));
    view.formatRubles = (amount) => new Intl.NumberFormat('ru-RU', {
      maximumFractionDigits: 2,
    }).format(Number(amount) || 0);
    view.hasPendingPayment = computed(() => {
      const student = unref(props.workspace.selectedStudent);
      return Boolean(student?.id && props.workspace.state.payments.some((payment) => (
        payment.studentId === student.id && payment.status === 'awaiting'
      )));
    });

    watch(view.maxLessonCount, (maximum) => {
      selectedLessonCount.value = Math.min(Math.max(maximum, 1), selectedLessonCount.value);
    });

    return view;
  },
};
</script>

<template>
    <form
        id="payment-form"
        :class="$style.formStack"
        @submit.prevent="submitWorkspaceForm($event, 'requestPayment')">
        <div :class="$style.singleLessonPrice">
            <span>Цена занятия при оплате поштучно</span>
            <b>{{ formatRubles(effectiveSingleLessonPrice) }} ₽</b>
        </div>
        <input
            type="hidden"
            name="lessonCount"
            :value="selectedLessonCount" />
        <div
            v-if="maxLessonCount"
            :class="$style.quantitySection">
            <p>Сколько занятий оплатить?</p>
            <StudentLessonCountPicker
                v-model="selectedLessonCount"
                :max="maxLessonCount" />
            <small>Можно выбрать от 1 до {{ maxLessonCount }} занятий</small>
        </div>
        <div
            v-if="maxLessonCount"
            :class="$style.totalAmount">
            <span>К оплате</span>
            <b>{{ formatRubles(totalAmount) }} ₽</b>
            <small v-if="matchingPlan">
                Цена абонемента на {{ selectedLessonCount }}
                {{ humanCount(selectedLessonCount, 'занятие', 'занятия', 'занятий') }}
            </small>
            <small v-else>
                {{ formatRubles(effectiveSingleLessonPrice) }} ₽ × {{ selectedLessonCount }}
            </small>
        </div>
        <VEmptyState
            v-if="hasPendingPayment || !activePlans.length"
            :class="$style.emptyState"
            :title="hasPendingPayment
                ? 'Заявка на оплату уже ожидает подтверждения'
                : !state.subscriptionPlans.length
                    ? 'Абонементы пока не настроены'
                    : 'Сейчас нет активных абонементов'"
        />
        <VModalActions :class="$style.modalActions">
            <AppButton
                type="submit"
                :loading="modal.busy"
                :disabled="modal.busy || hasPendingPayment || !activePlans.length">Отправить заявку</AppButton>
            <AppButton
                variant="ghost"
                @click="closeModal">Отмена</AppButton>
        </VModalActions>
    </form>
</template>

<style lang="scss" module>
.emptyState {
    padding: 0 $padding;

    text-align: center;
    color: var(--muted);
    font-size: 12px;

    b {
        display: block;
        margin-bottom: 5px;
        color: var(--ink);
        font-weight: 700;

        @include text(px2);
    }

    @include respond-to(mobile) {
        padding: 0 $padding-mobile;
    }
}

[data-theme=darked] {
    .emptyState {
        b {
            color: var(--ink);
        }
    }
}

.formStack {
    display: grid;
    gap: 16px;
}

.singleLessonPrice {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 12px 14px;
    border: 1px solid var(--line);
    border-radius: 13px;
    background: var(--canvas);
    color: var(--muted);
    font-size: 12px;

    b {
        color: var(--ink);
        font-size: 14px;
    }
}

.quantitySection {
    display: grid;
    justify-items: center;
    gap: 8px;

    p {
        margin: 0;
        color: var(--ink);
        font-size: 13px;
        font-weight: 700;
    }

    > small {
        color: var(--muted);
        font-size: 11px;
    }
}

.totalAmount {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: center;
    gap: 4px 12px;
    padding: 12px 14px;
    border: 1px solid var(--line);
    border-radius: 13px;
    background: var(--canvas);
    color: var(--ink);

    > span {
        color: var(--muted);
        font-size: 12px;
    }

    > b {
        font-size: 18px;
        font-variant-numeric: tabular-nums;
    }

    > small {
        grid-column: 1 / -1;
        color: var(--muted);
        font-size: 11px;
    }
}

.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 18px;
}

</style>
