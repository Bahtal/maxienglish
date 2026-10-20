<script>
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import StudentProfileOverview from '../components/student/StudentProfileOverview.vue';
import StudentLessonHistory from '../components/student/StudentLessonHistory.vue';
import StudentHomeworkHistory from '../components/student/StudentHomeworkHistory.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { StudentProfileOverview, StudentLessonHistory, StudentHomeworkHistory },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <div :class="$style.profilePage">
        <StudentProfileOverview :class="$style.board" :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <StudentLessonHistory :class="$style.board" :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <StudentHomeworkHistory :class="$style.board" :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
    </div>
</template>

<style lang="scss" module>
.profilePage {
    display: flex;
    flex-direction: column;
    min-width: 0;
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }

    .board {
        min-width: 0;
        border-radius: $radius;
        background: var(--surface);

        &:not(:first-child) {
            box-shadow: $board-shadow;
        }
    }
}

[data-theme='darked'] {
    .board {
        background: var(--surface);
    }
}
</style>
