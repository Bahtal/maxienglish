<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VSectionHeader from '../VSectionHeader.vue';
import VIcon from '../VIcon.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { VSectionHeader, VIcon },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.paymentCard">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="Даты оплаты"
            description="Последняя и следующая оплата"
        >
            <template #aside>
                <VIcon name="wallet" size="small" tile />
            </template>
        </VSectionHeader>
        <div :class="$style.paymentRows">
            <div :class="$style.paymentRow">
                <span :class="$style.paymentLabel">
                    <VIcon name="check" size="large" tile :glyph-size="24" />
                    Последняя оплата
                </span>
                <strong>{{ state.studentUser.lastPayment ? cap(formatDay(state.studentUser.lastPayment)) : 'Пока нет оплат' }}</strong>
            </div>
            <div :class="$style.paymentRow">
                <span :class="$style.paymentLabel">
                    <VIcon name="calendar" size="large" tile :glyph-size="24" />
                    Следующая оплата
                </span>
                <strong>{{ state.studentUser.nextPayment ? cap(formatDay(state.studentUser.nextPayment)) : 'Не назначена' }}</strong>
            </div>
        </div>
    </section>
</template>

<style lang="scss" module>
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

    > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
    }
}

.paymentCard {
    padding: $padding;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.paymentRows {
    display: grid;
    gap: 0;
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
}

.paymentLabel {
    display: flex;
    align-items: center;
    gap: 9px;
    color: $muted;
    font-size: 10px;
}

.paymentRow {
    strong {
        @include text(px2);
    }
}

.miniProgress {
    padding: 8px 0;
}

.miniProgressHead {
    display: flex;
    justify-content: space-between;
    color: var(--muted);
    font-size: 10px;

    b {
        color: var(--ink);
    }
}

.progressTrack {
    height: 6px;
    margin-top: 6px;
    border-radius: 8px;
    overflow: hidden;
    background: var(--line);
}

.progressFill {
    height: 100%;
    border-radius: inherit;
    background: linear-gradient(90deg, var(--purple-dark), var(--purple));
}

.smallNote {
    margin: 10px 0 0;
    color: var(--muted);
    line-height: 1.5;

    @include text(px2);
}

[data-theme=darked] {
    .paymentRow {
        color: var(--ink);
    }

    .smallNote {
        color: var(--muted);
    }

    .progressTrack {
        background-color: var(--line);
    }

    .paymentLabel {
        color: var(--muted);
    }

    .miniProgressHead {
        color: var(--muted);
    }
}
</style>
