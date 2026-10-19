<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <div :class="$style.historyList">
        <div
            v-for="payment in state.payments.filter((item)=>item.studentId===state.studentUser.id)"
            :key="payment.id"
            :class="$style.historyRow">
            <span>{{ payment.date }} · {{ payment.lessons }} занятий</span>
            <span>{{ payment.status==='awaiting'?'Заявка':statusLabel(payment.status) }}</span>
        </div>
        <div
            v-if="!state.payments.some((item)=>item.studentId===state.studentUser.id)"
            :class="$style.emptyState">
            <b>Оплат пока нет</b>
            <span>Предыдущие оплаты будут отображаться здесь.</span>
        </div>
    </div>
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

.historyRow {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    padding: 8px 0;
    border-bottom: 1px solid var(--line);
    font-size: 10px;

    &:last-child {
        border: 0;
    }

    span:last-child {
        color: var(--muted);
    }
}

[data-theme=darked] {
    .historyRow {
        border-color: var(--line);

        span:last-child {
            color: var(--ink);
        }
    }

    .emptyState {
        b {
            color: var(--ink);
        }
    }

}

.historyList {
    display: grid;
    gap: 2px;
}
</style>
