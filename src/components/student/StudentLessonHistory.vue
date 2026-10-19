<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VSectionHeader from '../VSectionHeader.vue';

import VEmptyState from '../VEmptyState.vue';
import VStatusBadge from '../VStatusBadge.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { VSectionHeader, VEmptyState, VStatusBadge },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.sectionCard">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="История занятий"
            description="Ваши последние уроки и посещаемость"
        />
        <div
            v-for="item in selectedStudent?.attendance || []"
            :key="`${item.date}-${item.time}`"
            :class="$style.historyRow">
            <span>{{ cap(formatDay(item.date)) }} · {{ item.time }}</span>
            <VStatusBadge
                :status="item.status"
                tone="muted"
                variant="text"
                :label="item.status"
            />
        </div>
        <VEmptyState
            v-if="!selectedStudent?.attendance?.length"
            :class="$style.emptyState"
            title="История занятий пока пуста."
        />
    </section>
</template>

<style lang="scss" module>
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

    &:last-child {
        border: 0;
    }
}

[data-theme=darked] {
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
