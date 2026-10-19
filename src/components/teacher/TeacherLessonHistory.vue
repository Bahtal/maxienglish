<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VSectionHeader from '../VSectionHeader.vue';

import VEmptyState from '../VEmptyState.vue';
import VStatusBadge from '../VStatusBadge.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { VSectionHeader, VEmptyState, VStatusBadge },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.sectionCard, $style.teacherLessonHistory]">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="История уроков"
            description="Проведённые, отменённые и прошлые занятия"
        />
        <div
            v-for="lesson in [...state.lessons].filter((item) => item.lessonStatus !== 'scheduled' || dateObject(item.date,item.time) < new Date()).sort((a,b)=>dateObject(b.date,b.time)-dateObject(a.date,a.time))"
            :key="lesson.id"
            :class="$style.historyRow"
        >
            <span :class="$style.historyRowContainer">
                <span :class="$style.historyRowName">{{ studentById(lesson.studentId)?.name }}</span>
                 <span>{{ cap(formatDay(lesson.date)) }} · {{ lesson.time }}</span>
            </span>
            <VStatusBadge
                :status="lesson.lessonStatus"
                tone="muted"
                variant="text"
                :label="lesson.lessonStatus === 'cancelled' ? 'Отменён' : lesson.lessonStatus === 'completed' ? 'Проведён' : statusLabel(lesson.status)"
            />
        </div>
        <VEmptyState
            v-if="!state.lessons.some((lesson) => lesson.lessonStatus !== 'scheduled' || dateObject(lesson.date, lesson.time) < new Date())"
            :class="$style.emptyState"
            title="История уроков появится здесь"
        />
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
}

.sectionHeading {
    > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
    }
}

.emptyState {
    padding: $padding;

    text-align: center;
    color: var(--muted);
    font-size: 12px;

    b {
        display: block;
        margin-bottom: 5px;
        color: var(--ink);
        font-weight: 700;

        @include text(px2);
    }

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.historyRow {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    padding: 8px 0;
    border-bottom: 1px solid var(--line);

    @include text(px2);
}

.historyRowName {
    font-weight: 700;
}

.historyRowContainer {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.historyRow {
    &:last-child {
        border: 0;
    }

    span:last-child {
        color: var(--muted);
    }
}

[data-theme=darked] {
    .historyRow {
        span:last-child {
            color: var(--ink);
        }
    }

    .emptyState {
        b {
            color: var(--ink);
        }
    }

    .historyRow {
        border-color: var(--line);
    }
}

.teacherLessonHistory {
    .historyRow {
        > span:first-child {
            min-width: 0;
            overflow-wrap: anywhere;
        }
    }
}

</style>
