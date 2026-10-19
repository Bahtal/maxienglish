<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.sectionCard]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>Напоминания</h2>
                <p>Важное для ваших занятий</p>
            </div>
            <span :class="$style.icon">
                <svg>
                <use href="#icon-bell" />
            </svg>
            </span>
        </div>
        <div
            v-for="notice in state.notifications.filter((item) => item.role === 'student').slice(0,2)"
            :key="notice.id"
            :class="$style.notificationItem">
            <span :class="$style.noticeDot"></span>
            <div>
                <b>{{ notice.title }}</b>
                <p>{{ notice.body }}</p>
                <small>{{ notice.time }}</small>
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

    .icon {
        display: flex;
        align-items: center;
        justify-content: center;
        width: $width-block;
        height: $width-block;
        border-radius: $radius-mini;
        background-color: var(--purple-pale);
        color: var(--purple);

        svg {
            width: $svg;
            height: $svg;
            flex: 0 0 $svg;
            stroke: currentColor;
            fill: none;
        }
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

[data-theme=darked] {
    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }
}

.notificationItem {
    width: 100%;
    border-bottom: 1px solid var(--line);
    display: flex;
    gap: 10px;

    &:not(:last-child) {
        padding-bottom: 8px;
    }

    &:not(:first-child) {
        padding-top: 8px;
    }

    &:last-child {
        border: 0;
    }

    b {
        display: block;
        font-size: 10px;
    }

    p {
        display: block;
        margin: 4px 0;
        color: $muted;
        line-height: 1.45;

        @include text(px2);
    }

    small {
        color: var(--muted);
        font-size: 8px;
    }
}

.noticeDot {
    width: 8px;
    height: 8px;
    flex: 0 0 8px;
    margin-top: 5px;
    border-radius: 50%;
    background: var(--purple);
}

[data-theme=darked] {
    .notificationItem {
        color: var(--ink);
        border-color: var(--line);

        p {
            color: var(--muted);
        }

        small {
            color: var(--muted);
        }
    }
}
</style>
