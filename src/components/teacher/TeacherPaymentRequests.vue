<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';
import VAvatar from '../VAvatar.vue';
import VStatusBadge from '../VStatusBadge.vue';

import VSectionHeader from '../VSectionHeader.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VAvatar, VStatusBadge, VSectionHeader },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section
        v-if="state.payments.some((payment) => payment.status === 'awaiting')"
        :class="[$style.sectionCard, $style.paymentRequests]">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="Заявки на оплату"
            description="Проверьте поступление и подтвердите абонементы"
        >
            <template #aside>
                <VStatusBadge
                    status="awaiting"
                    tone="pending"
                    strong
                    :label="`${state.payments.filter((payment) => payment.status === 'awaiting').length} ожидают`"
                />
            </template>
        </VSectionHeader>
        <div
            v-for="payment in state.payments.filter((entry) => entry.status === 'awaiting')"
            :key="payment.id"
            :class="[$style.paymentRow, $style.paymentRequestRow]">
            <span :class="$style.paymentLabel">
                <VAvatar
                    size="medium"
                    radius="default"
                    :name="studentById(payment.studentId)?.name || ''"
                />
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

        @include text(px1);

        @include respond-to(mobile) {
            @include text(px1_5);
        }
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);

        @include respond-to(mobile) {
            @include text(px3);
        }
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

    .paymentLabel {
        color: var(--muted);
    }
}
</style>
