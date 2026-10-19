<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.paymentCard]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>Даты оплаты</h2>
                <p>Последняя и следующая оплата</p>
            </div>
            <span :class="$style.statIcon">
                <svg>
                    <use href="#icon-wallet" />
                </svg>
            </span>
        </div>
        <div :class="$style.paymentRows">
            <div :class="$style.paymentRow">
                <span :class="$style.paymentLabel">
                    <span :class="$style.paymentIcon">
                        <svg>
                            <use href="#icon-check" />
                        </svg>
                    </span>
                    Последняя оплата
                </span>
                <strong>{{ state.studentUser.lastPayment ? cap(formatDay(state.studentUser.lastPayment)) : 'Пока нет оплат' }}</strong>
            </div>
            <div :class="$style.paymentRow">
                <span :class="$style.paymentLabel">
                    <span :class="$style.paymentIcon">
                        <svg>
                            <use href="#icon-calendar" />
                        </svg>
                    </span>
                    Следующая оплата
                </span>
                <strong>{{ state.studentUser.nextPayment ? cap(formatDay(state.studentUser.nextPayment)) : 'Не назначена' }}</strong>
            </div>
        </div>
    </section>
</template>

<style lang="scss" module>
.card {
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius;
    box-shadow: var(--shadow);
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

.paymentIcon {
    width: $width-block-big;
    height: $height-block-big;
    display: grid;
    place-items: center;
    border-radius: $radius-mini;
    color: var(--purple);
    background: var(--purple-pale);

    svg {
        width: calc($svg + 4px);
        height: calc($svg + 4px);
        stroke: currentColor;
        fill: none;
        stroke-width: 1.8;
        stroke-linecap: round;
        stroke-linejoin: round;
    }

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
    }
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
        stroke: currentColor;
        fill: none;
        stroke-width: 1.8;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
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
