<script>
import { computed } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
    props: { workspace: { type: Object, required: true } },
    emits: ['workspace-action'],
    setup(props, { emit }) {
        const view = useWorkspaceView(props, emit);
        const payments = computed(() => props.workspace.state.payments
            .filter((payment) => payment.studentId === props.workspace.state.studentUser.id));

        return { ...view, payments };
    },
};
</script>

<template>
    <section :class="[$style.card, $style.historyCard]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>История оплат</h2>
                <p>Заявки и подтверждённые платежи</p>
            </div>
            <span :class="$style.statIcon">
                <svg>
                    <use href="#icon-wallet" />
                </svg>
            </span>
        </div>

        <div v-if="payments.length" :class="$style.historyList">
            <article
                v-for="payment in payments"
                :key="payment.id"
                :class="$style.paymentRow">
                <div :class="$style.paymentMain">
                    <b>{{ payment.lessons }} {{ humanCount(payment.lessons, 'занятие', 'занятия', 'занятий') }}</b>
                    <span>{{ payment.date }}</span>
                </div>
                <div :class="$style.paymentMeta">
                    <strong>{{ Number(payment.amount || 0).toLocaleString('ru-RU') }} ₽</strong>
                    <span :class="[$style.status, $style[payment.status]]">
                        {{ payment.status === 'awaiting' ? 'Ожидает подтверждения' : payment.status === 'rejected' ? 'Отклонена' : 'Подтверждена' }}
                    </span>
                </div>
            </article>
        </div>

        <div v-else :class="$style.emptyState">
            <b>Оплат пока нет</b>
            <span>История заявок и платежей появится здесь.</span>
        </div>
    </section>
</template>

<style lang="scss" module>
.card {
    border: 1px solid var(--border-color);
    border-radius: $radius;
    background: var(--surface);
    box-shadow: var(--shadow);
}

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

        @include text(px2);
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);
    }
}

.statIcon {
    width: $width-block;
    height: $height-block;
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

.status {
    color: var(--green);
    font-weight: 400;
    width: fit-content;

    @include text(px3);

    &.awaiting {
        color: var(--amber);
    }

    &.rejected {
        color: var(--red);
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

[data-theme='darked'] {
    .card {
        border-color: var(--line);
        background: var(--surface);
    }
}
</style>
