<script>
import { computed } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VSectionHeader from '../VSectionHeader.vue';
import VIcon from '../VIcon.vue';

import VEmptyState from '../VEmptyState.vue';
import VPaymentHistoryRow from '../VPaymentHistoryRow.vue';

export default {
    props: { workspace: { type: Object, required: true } },
    emits: ['workspace-action'],
  components: { VSectionHeader, VIcon, VEmptyState, VPaymentHistoryRow },
    setup(props, { emit }) {
        const view = useWorkspaceView(props, emit);
        const payments = computed(() => props.workspace.state.payments
            .filter((payment) => payment.studentId === props.workspace.state.studentUser.id));

        return { ...view, payments };
    },
};
</script>

<template>
    <section :class="$style.historyCard">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="История оплат"
            description="Заявки и подтверждённые платежи"
        >
            <template #aside>
                <VIcon
                    name="wallet"
                    size="small"
                    tile
                />
            </template>
        </VSectionHeader>

        <div v-if="payments.length" :class="$style.historyList">
            <VPaymentHistoryRow
                v-for="payment in payments"
                :key="payment.id"
                :payment="payment"
                :status-label="payment.status === 'awaiting' ? 'Ожидает подтверждения' : payment.status === 'rejected' ? 'Отклонена' : 'Подтверждена'"
                :meta-class="$style.paymentMeta"
                :class="$style.paymentRow"
            >
                <template #content>
                    <div :class="$style.paymentMain">
                        <b>{{ payment.lessons }} {{ humanCount(payment.lessons, 'занятие', 'занятия', 'занятий') }}</b>
                        <span>{{ payment.date }}</span>
                    </div>
                </template>
            </VPaymentHistoryRow>
        </div>

        <VEmptyState
            v-else
            :class="$style.emptyState"
            title="Оплат пока нет"
            description="История заявок и платежей появится здесь."
        />
    </section>
</template>

<style lang="scss" module>
.historyCard {
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

.historyList {
    display: grid;
}

.paymentRow {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 13px 0;
    border-bottom: 1px solid var(--line);

    &:last-child {
        border-bottom: 0;
        padding-bottom: 0;
    }
}

.paymentMain,
.paymentMeta {
    display: grid;
    gap: 5px;
}

.paymentMain {
    min-width: 0;

    b {
        font-size: 12px;
    }

    span {
        color: var(--muted);
        font-size: 10px;
    }
}

.paymentMeta {
    justify-items: end;
    flex: 0 0 auto;

    strong {
        font-size: 12px;
    }
}

.emptyState {
    display: grid;
    justify-items: center;
    gap: 5px;
    padding: 18px 0 6px;
    color: var(--muted);
    text-align: center;
    font-size: 11px;

    b {
        color: var(--ink);
        font-size: 13px;
    }
}

</style>
