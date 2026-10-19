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
        <TeacherProfileOverview :class="$style.board" :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <TeacherLessonHistory :class="$style.board" :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        <TeacherSettingsPanel :class="$style.board" :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
    </div>
</template>

<style lang="scss" module>
.teacherProfilePage {
    display: flex;
    flex-direction: column;
    min-width: 0;
    gap: $gap;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.board {
    min-width: 0;
    border: 1px solid var(--border-color);
    border-radius: $radius;
    background: var(--surface);
    box-shadow: var(--shadow);
}

[data-theme='darked'] {
    .board {
        border-color: var(--line);
        background: var(--surface);
    }
}
</style>
