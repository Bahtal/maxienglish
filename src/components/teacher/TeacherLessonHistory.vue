<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.sectionCard, $style.teacherLessonHistory]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>История уроков</h2>
                <p>Проведённые, отменённые и прошлые занятия</p>
            </div>
        </div>
        <div
            v-for="lesson in [...state.lessons].filter((item) => item.lessonStatus !== 'scheduled' || dateObject(item.date,item.time) < new Date()).sort((a,b)=>dateObject(b.date,b.time)-dateObject(a.date,a.time))"
            :key="lesson.id"
            :class="$style.historyRow"
        >
            <span :class="$style.historyRowContainer">
                <span :class="$style.historyRowName">{{ studentById(lesson.studentId)?.name }}</span>
                 <span>{{ cap(formatDay(lesson.date)) }} · {{ lesson.time }}</span>
            </span>
            <span>{{ lesson.lessonStatus === 'cancelled' ? 'Отменён' : lesson.lessonStatus === 'completed' ? 'Проведён' : statusLabel(lesson.status) }}</span>
        </div>
        <div
            v-if="!state.lessons.some((lesson) => lesson.lessonStatus !== 'scheduled' || dateObject(lesson.date,lesson.time) < new Date())"
            :class="$style.emptyState">
            <b>История уроков появится здесь</b>
        </div>
    </section>
</template>

<style lang="scss" module>
.card {
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius;
    box-shadow: var(--shadow);
}

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

        @include text(px2);
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);
    }
}

.status {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    width: fit-content;
    padding: 1px 4px;
    border-radius: $radius;
    font-weight: 400;
    white-space: nowrap;

    @include text(px3);

    &:before {
        content: "";
        width: 5px;
        height: 5px;
        border-radius: 50%;
        background: currentColor;
    }

    &.paid {
        color: var(--green);
        background: color-mix(in srgb, var(--green) 10%, var(--surface));
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
    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }

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
