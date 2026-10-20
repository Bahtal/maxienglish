<script>
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import CalendarMonth from '../components/calendar/CalendarMonth.vue';
import CalendarAgenda from '../components/calendar/CalendarAgenda.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { CalendarMonth, CalendarAgenda },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <div :class="$style.calendarLayout">
        <CalendarMonth :class="$style.board" :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <CalendarAgenda :class="$style.board" :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
    </div>
</template>

<style lang="scss" module>
.board {
    min-width: 0;
    border-radius: $radius;
    background: var(--surface);
    box-shadow: $board-shadow;
}

.calendarLayout {
    display: grid;
    min-width: 0;
    grid-template-columns: repeat(2, 1fr);
    gap: $gap;

    > * {
        min-width: 0;
    }
}

[data-theme='darked'] {
    .board {
        background: var(--surface);
    }
}

@media (max-width: 1100px) {
    .calendarLayout {
        grid-template-columns: 1fr;
        gap: $gap-sm;
    }
}
</style>
