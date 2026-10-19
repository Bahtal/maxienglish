<script>
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import TeacherStatsCards from '../components/teacher/TeacherStatsCards.vue';
import TeacherSchedule from '../components/teacher/TeacherSchedule.vue';
import TeacherHomeworkPreview from '../components/teacher/TeacherHomeworkPreview.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { TeacherStatsCards, TeacherSchedule, TeacherHomeworkPreview },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <div :class="$style.teacherHomePage">
        <TeacherStatsCards :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <TeacherSchedule :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <TeacherHomeworkPreview :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
    </div>
</template>

<style lang="scss" module>
.teacherHomePage {
    --module-placeholder: 0;
}
</style>
