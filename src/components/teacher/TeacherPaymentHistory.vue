<script>
import { computed } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
    props: { workspace: { type: Object, required: true } },
    emits: ['workspace-action'],
    setup(props, { emit }) {
        const view = useWorkspaceView(props, emit);
        const payments = computed(() => props.workspace.state.payments);

        return { ...view, payments };
    },
};
</script>

<template>
    <section :class="[$style.card, $style.historyCard]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>История оплат</h2>
                <p>Заявки, подтверждения и суммы по ученикам</p>
            </div>
            <span :class="$style.statIcon">
                <svg>
                    <use href="#icon-wallet" />
                </svg>
            </span>
        </div>

        <div v-if="payments.length" :class="$style.paymentList">
            <article
                v-for="payment in payments"
                :key="payment.id"
                :class="$style.paymentRow">
                <span :class="$style.avatar">{{ initials(studentById(payment.studentId)?.name || '') }}</span>
                <div :class="$style.paymentInfo">
                    <b>{{ studentById(payment.studentId)?.name || 'Ученик' }}</b>
                    <span>{{ payment.date }} · {{ payment.lessons }} {{ humanCount(payment.lessons, 'занятие', 'занятия', 'занятий') }}</span>
                </div>
                <div :class="$style.paymentMeta">
                    <strong>{{ Number(payment.amount || 0).toLocaleString('ru-RU') }} ₽</strong>
                    <span :class="[$style.status, $style[payment.status]]">
                        {{ payment.status === 'awaiting' ? 'Ожидает' : payment.status === 'rejected' ? 'Отклонена' : 'Оплачено' }}
                    </span>
                </div>
            </article>
        </div>

        <div v-else :class="$style.emptyState">
            <b>История пока пуста</b>
            <span>Здесь будут заявки и подтверждённые оплаты учеников.</span>
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
    flex: 0 0 $width-block;
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

.avatar {
    width: $width-block-big;
    height: $height-block-big;
    flex: 0 0 $width-block-big;
    display: grid;
    place-items: center;
    border-radius: $radius-mini;
    color: $white;
    background: linear-gradient(140deg, var(--purple), var(--purple-dark));
    font-weight: 700;

    @include text(px2);

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        flex: 0 0 $width-block;
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

.status {
    color: var(--green);
    width: fit-content;
    font-weight: 400;

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

    .avatar {
        color: var(--canvas);
    }
}
</style>
