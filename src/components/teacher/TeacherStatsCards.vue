<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <div :class="$style.statsGrid">
        <button
            v-for="stat in teacherStats"
            :key="stat.label"
            :class="[$style.card, $style.statCard, { [$style.interactive]: stat.clickable }]"
            @click="stat.clickable && go('students')"
        >
             <span :class="$style.statIcon">
                <svg>
                    <use :href="`#icon-${stat.icon}`" />
                </svg>
            </span>

            <div :class="$style.statCopy">
                <b>{{ stat.value }}</b>
                <small>{{ stat.label }}</small>
            </div>
        </button>
    </div>
</template>

<style lang="scss" module>
.card {
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius;
    box-shadow: var(--shadow);
}

[data-theme=darked] {
    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }
}

.statsGrid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    margin-bottom: 16px;
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.statCard {
    aspect-ratio: 1/.9;
    border: 1px solid var(--border-color);
    min-height: 100px;
    padding: $padding;
    display: flex;
    justify-content: space-between;
    gap: 10px;
    align-items: flex-start;
    appearance: none;
    background: $transparent;
    color: inherit;
    font: inherit;
    text-align: left;
    width: 100%;

    @include respond-to(mobile) {
        position: relative;
        align-items: center;
        justify-content: flex-start;
        min-height: auto;
        padding: 8px 12px 8px 12px;
        aspect-ratio: auto;
    }

    &.interactive {
        cursor: pointer;
        transition: border-color 0.18s ease, transform 0.18s ease, box-shadow 0.18s ease;

        &:hover {
            border-color: var(--purple-pale);
            transform: translateY(-1px);
            box-shadow: 0 9px 24px color-mix(in srgb, var(--purple) 7%, transparent);
        }

        &:focus-visible {
            outline: 3px solid color-mix(in srgb, var(--purple) 24%, transparent);
            outline-offset: 2px;
        }
    }
}

.statCopy {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    height: 100%;

    small {
        color: var(--muted);

        @include text(px2);
    }

    b {
        display: block;
        font-size: 65px;
        line-height: 1.3;
        font-weight: 700;
        letter-spacing: -0.7px;
    }

    span {
        display: block;
        color: var(--muted);

        @include text(px2);
    }
}

.statIcon {
    position: absolute;
    top: 8px;
    right: 8px;
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

    @include respond-to(mobile) {
        position: static;
    }
}

@include respond-to(tablet) {
    .statsGrid {
        gap: 10px;
    }
}

@include respond-to(mobile) {
    .statsGrid {
        grid-template-columns: none;
        gap: 4px;
        margin-bottom: 16px;
    }

    .statCopy {
        flex-direction: row-reverse;
        flex-wrap: nowrap;
        align-items: center;
        justify-content: space-between;
        width: 100%;

        b {
            font-size: 52px;
        }
    }

    .statIcon {
        flex-shrink: 0;
        width: $width-block;
        height: $height-block;
        border-radius: $radius-micro;

        svg {
            width: $svg;
            height: $svg;
        }
    }
}

@media (max-width: 450px) {
    .statCopy {
        b {
            font-size: 32px;
        }
    }
}

[data-theme=darked] {
    .statCopy {
        span {
            color: var(--muted);
        }
    }
}
</style>
