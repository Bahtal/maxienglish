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
                <h2>Домашние задания</h2>
                <p>Статус выполненных и текущих заданий</p>
            </div>
        </div>
        <div
            v-for="item in studentHomework"
            :key="item.id"
            :class="$style.historyRow"
        >
            <span>{{ item.title }}</span>
            <span>{{ isDoneHomework(item) ? 'Выполнено' : 'В работе' }}</span>
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

    & > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
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
        padding-bottom: 0;
    }

    span:last-child {
        color: var(--muted);
    }
}

[data-theme=darked] {
    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }

    .historyRow {
        border-color: var(--line);

        span:last-child {
            color: var(--ink);
        }
    }
}
</style>
