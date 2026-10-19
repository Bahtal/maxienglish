<script>
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import StudentUpcomingLessons from '../components/student/StudentUpcomingLessons.vue';
import StudentHomeworkPreview from '../components/student/StudentHomeworkPreview.vue';
import StudentTeacherCard from '../components/student/StudentTeacherCard.vue';
import StudentReminders from '../components/student/StudentReminders.vue';
import StudentLessonLinks from '../components/student/StudentLessonLinks.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { StudentUpcomingLessons, StudentHomeworkPreview, StudentTeacherCard, StudentReminders, StudentLessonLinks },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <div :class="$style.dashboardGrid">
        <div :class="$style.column">
            <StudentLessonLinks
                :zoom-url="state.teacher.zoomLink"
                :board-url="state.studentUser.boardLink" />
            <StudentUpcomingLessons :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
            <StudentHomeworkPreview :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        </div>
        <div :class="$style.column">
            <StudentTeacherCard :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
            <StudentReminders :workspace="workspace" @workspace-action="$emit('workspace-action', $event)" />
        </div>
    </div>
</template>

<style lang="scss" module>
.dashboardGrid {
    display: grid;
    width: 100%;
    min-width: 0;
    grid-template-columns: minmax(0, 1.65fr) minmax(0, 0.85fr);
    gap: 20px;
    align-items: start;

    > * {
        min-width: 0;
    }
}

.column {
    display: grid;
    gap: 18px;
    min-width: 0;
}

@include respond-to(tablet) {
    .dashboardGrid {
        grid-template-columns: minmax(0, 1.4fr) minmax(0, 0.9fr);
        gap: $gap-sm;
    }
}

@include respond-to(mobile) {
    .dashboardGrid {
        grid-template-columns: minmax(0, 1fr);
        gap: $gap-sm;
    }

    .column {
        gap: $gap-sm;
    }
}
</style>
