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
                <h2>История занятий</h2>
                <p>Ваши последние уроки и посещаемость</p>
            </div>
        </div>
        <div
            v-for="item in selectedStudent?.attendance || []"
            :key="`${item.date}-${item.time}`"
            :class="$style.historyRow">
            <span>{{ cap(formatDay(item.date)) }} · {{ item.time }}</span>
            <span>{{ item.status }}</span>
        </div>
        <div
            v-if="!selectedStudent?.attendance?.length"
            :class="$style.emptyState">
            <b>История занятий пока пуста.</b>
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

    > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
    }
}

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

    @include text(px2);
}

.historyRow {
    &:last-child {
        border: 0;
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
        span:last-child {
            color: var(--ink);
        }
    }

    .emptyState {
        b {
            color: var(--ink);
        }
    }

    .historyRow {
        border-color: var(--line);
    }
}
</style>
