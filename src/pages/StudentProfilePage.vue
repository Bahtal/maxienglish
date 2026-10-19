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
        <StudentProfileOverview :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <StudentLessonHistory :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <StudentHomeworkHistory :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
    </div>
</template>

<style lang="scss" module>
.profilePage {
    display: grid;
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}
</style>
