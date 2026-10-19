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
        <CalendarMonth :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <CalendarAgenda :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
    </div>
</template>

<style lang="scss" module>
.calendarLayout {
    display: grid;
    min-width: 0;
    grid-template-columns: repeat(2, 1fr);
    gap: $gap;

    > * {
        min-width: 0;
    }
}

@media (max-width: 1100px) {
    .calendarLayout {
        grid-template-columns: 1fr;
        gap: $gap-sm;
    }
}
</style>
