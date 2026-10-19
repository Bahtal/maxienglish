<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VSectionHeader from '../VSectionHeader.vue';
import VStatusBadge from '../VStatusBadge.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { VSectionHeader, VStatusBadge },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.sectionCard">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="Домашние задания"
            description="Статус выполненных и текущих заданий"
        />
        <div
            v-for="item in studentHomework"
            :key="item.id"
            :class="$style.historyRow"
        >
            <span>{{ item.title }}</span>
            <VStatusBadge
                :status="isDoneHomework(item) ? 'done' : 'in-progress'"
                tone="muted"
                variant="text"
                :label="isDoneHomework(item) ? 'Выполнено' : 'В работе'"
            />
        </div>
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

}

[data-theme=darked] {
    .historyRow {
        border-color: var(--line);

        span:last-child {
            color: var(--ink);
        }
    }
}
</style>
