<script>
import { computed, unref } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';
import { getStudentSingleLessonPrice } from '../../utils/studentPricing.js';

import AppButton from '../AppButton.vue';

import VEmptyState from '../VEmptyState.vue';

import VModalActions from '../VModalActions.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VEmptyState, VModalActions },
  setup(props, { emit }) {
    const view = useWorkspaceView(props, emit);
    view.activePlans = computed(() => props.workspace.state.subscriptionPlans.filter((plan) => plan.active));
    view.effectiveSingleLessonPrice = computed(() => {
      const student = unref(props.workspace.selectedStudent);
      return getStudentSingleLessonPrice(student?.customSingleLessonPrice, props.workspace.state.teacher.singleLessonPrice);
    });
    view.hasPendingPayment = computed(() => {
      const student = unref(props.workspace.selectedStudent);
      return Boolean(student?.id && props.workspace.state.payments.some((payment) => (
        payment.studentId === student.id && payment.status === 'awaiting'
      )));
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
            <span>Цена одного урока</span>
            <b>{{ Number(effectiveSingleLessonPrice || 0).toLocaleString('ru-RU') }} ₽</b>
        </div>
        <label
            v-for="(plan,index) in activePlans"
            :key="plan.id"
            :class="$style.planOption">
            <input
                type="radio"
                name="plan"
                :value="plan.id"
                :checked="index===0" />
            <span>
                <b>{{ plan.lessons }}{{ humanCount(plan.lessons,'занятие','занятия','занятий') }}</b>
                <small>{{ plan.price.toLocaleString('ru-RU') }} ₽</small>
            </span>
        </label>
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

.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 18px;
}

.planOption {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px;
    border: 1px solid var(--line);
    border-radius: 13px;
    cursor: pointer;

    &:has(input:checked) {
        border-color: var(--purple);
        background: var(--purple-pale);
    }

    input {
        accent-color: var(--purple);
    }

    b {
        font-size: 11px;
    }

    small {
        display: block;
        margin-top: 4px;
        color: var(--muted);

        @include text(px2);
    }

    span {
        display: flex;
        flex: 1;
        justify-content: space-between;
        gap: 12px;
    }
}

[data-theme=darked] {
    .planOption {
        border-color: var(--line);
        background-color: var(--surface);

        &:has(input:checked) {
            border-color: var(--purple);
            background-color: var(--purple-pale);
        }
    }
}
</style>
