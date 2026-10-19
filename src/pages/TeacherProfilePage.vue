<script>
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import TeacherProfileOverview from '../components/teacher/TeacherProfileOverview.vue';
import TeacherLessonHistory from '../components/teacher/TeacherLessonHistory.vue';
import TeacherSettingsPanel from '../components/teacher/TeacherSettingsPanel.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { TeacherProfileOverview, TeacherLessonHistory, TeacherSettingsPanel },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <div :class="$style.teacherProfilePage">
        <TeacherProfileOverview :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <TeacherLessonHistory :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <TeacherSettingsPanel :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
    </div>
</template>

<style lang="scss" module>
.teacherProfilePage {
    display: grid;
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}
</style>
