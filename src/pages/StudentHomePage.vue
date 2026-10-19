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
        <StudentLessonLinks
            :zoom-url="state.teacher.zoomLink"
            :board-url="state.studentUser.boardLink"
        />

        <StudentUpcomingLessons
            :class="$style.board"
            :workspace="workspace"
            @workspace-action="$emit('workspace-action', $event)"
        />

        <StudentHomeworkPreview
            :class="$style.board"
            :workspace="workspace"
            @workspace-action="$emit('workspace-action', $event)"
        />

        <StudentTeacherCard
            :class="$style.board"
            :workspace="workspace"
            @workspace-action="$emit('workspace-action', $event)"
        />

        <StudentReminders
            :class="$style.board"
            :workspace="workspace"
            @workspace-action="$emit('workspace-action', $event)"
        />
    </div>
</template>

<style lang="scss" module>
.dashboardGrid {
    display: flex;
    flex-direction: column;
    width: 100%;
    min-width: 0;
    gap: $gap;
    align-items: start;

    > * {
        min-width: 0;
        width: 100%;
    }

    .board,
    :global(.linkCard) {
        border: 1px solid var(--border-color);
        border-radius: $radius;
        background: var(--surface);
        box-shadow: var(--shadow);
    }
}

[data-theme='darked'] {
    .dashboardGrid {
        .board,
        :global(.linkCard) {
            border-color: var(--line);
            background: var(--surface);
        }
    }
}

@include respond-to(tablet) {
    .dashboardGrid {
        gap: $gap-sm;
    }
}

@include respond-to(mobile) {
    .dashboardGrid {
        gap: $gap-sm;
    }
}
</style>
