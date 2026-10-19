<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section
        v-if="state.payments.some((payment) => payment.status === 'awaiting')"
        :class="[$style.card, $style.sectionCard, $style.paymentRequests]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>Заявки на оплату</h2>
                <p>Проверьте поступление и подтвердите абонементы</p>
            </div>
            <span
                :class="[$style.status, $style.pending]">{{ state.payments.filter((payment) => payment.status === 'awaiting').length }} ожидают</span>
        </div>
        <div
            v-for="payment in state.payments.filter((entry) => entry.status === 'awaiting')"
            :key="payment.id"
            :class="[$style.paymentRow, $style.paymentRequestRow]">
            <span :class="$style.paymentLabel">
                <span :class="$style.avatar">{{ initials(studentById(payment.studentId)?.name) }}</span>
                <span>{{ studentById(payment.studentId)?.name }} · {{ payment.lessons }} занятий · {{ payment.date }}</span>
            </span>
            <AppButton
                :class="$style.paymentConfirmButton"
                size="small"
                @click="confirmPayment(payment)">Подтвердить</AppButton>
            <AppButton
                :class="$style.paymentMessageButton"
                variant="outline"
                size="small"
                @click="openChat(payment.studentId)">Написать ученику</AppButton>
        </div>
    </section>
</template>

<style lang="scss" module>
.avatar {
    width: 38px;
    height: 38px;
    flex: 0 0 38px;
    display: grid;
    place-items: center;
    border-radius: $radius;
    color: $white;
    background: linear-gradient(140deg, var(--amber), var(--red));
    font-weight: 700;

    @include text(px2);
}

.card {
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius;
    box-shadow: var(--shadow);
}

.sectionCard {
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

.status {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    width: fit-content;
    padding: 1px 4px;
    border-radius: $radius;
    font-weight: 400;
    white-space: nowrap;

    @include text(px3);

    &:before {
        content: "";
        width: 5px;
        height: 5px;
        border-radius: 50%;
        background: currentColor;
    }

    &.pending {
        color: var(--amber);
        background: color-mix(in srgb, var(--amber) 14%, var(--surface));
    }
}

.sectionHeading {
    > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
    }
}

[data-theme=darked] {
    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }
}

.paymentRow {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    padding: 12px 0;
    border-bottom: 1px solid var(--line);

    &:last-child {
        border: 0;
        padding-bottom: 2px;
    }

    strong {
        font-size: 10px;
    }
}

.paymentRequestRow {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    grid-template-areas: "label confirm" "message message";
    align-items: center;
    gap: 10px 12px;

    .paymentLabel {
        grid-area: label;
        min-width: 0;
    }
}

.paymentConfirmButton {
    grid-area: confirm;
}

.paymentMessageButton {
    grid-area: message;
    width: 100%;

    &:disabled {
        cursor: not-allowed;
        opacity: 0.55;
    }
}

.paymentLabel {
    display: flex;
    align-items: center;
    gap: 9px;
    color: $muted;

    @include text(px2);
}

.paymentRequests {
    margin-bottom: 16px;
}

[data-theme=darked] {
    .paymentRow {
        color: var(--ink);
    }

    .status {
        &.pending {
            color: var(--amber);
            background: color-mix(in srgb, var(--amber) 20%, var(--surface));
        }
    }

    .paymentLabel {
        color: var(--muted);
    }
}
</style>
