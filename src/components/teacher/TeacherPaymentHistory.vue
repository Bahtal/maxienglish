<script>
import { computed } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VAvatar from '../VAvatar.vue';
import VIcon from '../VIcon.vue';

import VSectionHeader from '../VSectionHeader.vue';

import VEmptyState from '../VEmptyState.vue';
import VPaymentHistoryRow from '../VPaymentHistoryRow.vue';

export default {
    props: { workspace: { type: Object, required: true } },
    emits: ['workspace-action'],
    components: { VAvatar, VIcon, VSectionHeader, VEmptyState, VPaymentHistoryRow },
    setup(props, { emit }) {
        const view = useWorkspaceView(props, emit);
        const payments = computed(() => props.workspace.state.payments);

        return { ...view, payments };
    },
};
</script>

<template>
    <section :class="$style.historyCard">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="История оплат"
            description="Заявки, подтверждения и суммы по ученикам"
        >
            <template #aside>
                <VIcon
                    name="wallet"
                    size="small"
                    tile
                />
            </template>
        </VSectionHeader>

        <div v-if="payments.length" :class="$style.paymentList">
            <VPaymentHistoryRow
                v-for="payment in payments"
                :key="payment.id"
                :payment="payment"
                :status-label="payment.status === 'awaiting' ? 'Ожидает' : payment.status === 'rejected' ? 'Отклонена' : 'Оплачено'"
                :meta-class="$style.paymentMeta"
                :class="$style.paymentRow"
            >
                <template #leading>
                    <VAvatar
                        size="large"
                        responsive
                        tone="purple"
                        radius="mini"
                        dark-text
                        :name="studentById(payment.studentId)?.name || ''"
                    />
                </template>
                <template #content>
                    <div :class="$style.paymentInfo">
                        <b>{{ studentById(payment.studentId)?.name || 'Ученик' }}</b>
                        <span>{{ payment.date }} · {{ payment.lessons }} {{ humanCount(payment.lessons, 'занятие', 'занятия', 'занятий') }}</span>
                    </div>
                </template>
            </VPaymentHistoryRow>
        </div>

        <VEmptyState
            v-else
            :class="$style.emptyState"
            title="История пока пуста"
            description="Здесь будут заявки и подтверждённые оплаты учеников."
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

.paymentList {
    display: grid;
}

.paymentRow {
    display: flex;
    align-items: center;
    gap: 11px;
    min-width: 0;
    padding: 12px 0;
    border-bottom: 1px solid var(--line);

    &:last-child {
        border-bottom: 0;
        padding-bottom: 0;
    }
}

.paymentInfo {
    display: grid;
    gap: 5px;
    min-width: 0;

    b,
    span {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    b {
        @include text(px2);
    }

    span {
        color: var(--muted);

        @include text(px2);
    }
}

.paymentMeta {
    display: grid;
    justify-items: end;
    gap: 5px;
    flex: 0 0 auto;
    margin-left: auto;

    strong {
        font-size: 11px;
        white-space: nowrap;
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
