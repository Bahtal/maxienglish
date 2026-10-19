<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.sectionCard]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>Ближайшие занятия</h2>
                <p>Ваше расписание на ближайшее время</p>
            </div>

            <button
                :class="$style.textLink"
                @click="go('calendar')"
            >
                &#32;Весь календарь&#32;&#32;
                <svg>
                    <use href="#icon-arrow" />
                </svg>
            </button>
        </div>

        <div :class="$style.lessonList">
            <button
                v-for="lesson in visibleLessons.filter((item) => item.studentId === state.studentUser.id).slice(0,3)"
                :key="lesson.id"
                :class="$style.lessonRow"
                @click="openLesson(lesson)"
            >
                <span :class="$style.dateBlock">
                    <b>{{ dateObject(lesson.date).getDate() }}</b>
                    <small>{{ formatWeekday(lesson.date, true) }}</small>
                </span>

                <span :class="$style.lessonInfo">
                    <b>{{ lesson.title || 'Английский' }}</b>
                    <small>{{ cap(formatDay(lesson.date)) }} · {{ lesson.durationMinutes }} мин</small>
                </span>

                <span :class="$style.lessonTime">{{ lesson.time }}</span>
            </button>

            <div
                v-if="!visibleLessons.filter((item) => item.studentId === state.studentUser.id).length"
                :class="$style.emptyState"
            >
                <b>Пока нет занятий</b>
                <span>Когда появится запись, она будет здесь.</span>
            </div>
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

    & > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
    }
}

.textLink {
    display: flex;
    flex-direction: row;
    justify-content: flex-start;
    align-items: center;
    padding: 4px 0;
    border: 0;
    color: var(--purple) !important;
    background: $transparent;
    font-size: 10px !important;
    font-weight: 500 !important;
    cursor: pointer;
    white-space: nowrap;

    svg {
        width: 14px;
        height: 14px;
        transform: rotate(0deg);
        fill: currentColor;
        transition: all .3s ease;
    }

    &:hover {
        svg {
            transform: rotate(0deg) translateX(3px);
        }
    }
}

.emptyState {
    padding: 0 $padding;

    text-align: center;
    color: var(--muted);

    @include text(px2);

    b {
        display: block;
        margin-bottom: 5px;
        color: var(--ink);
        font-weight: 700;

        @include text(px2);
    }

    @include respond-to(mobile) {
        padding: 0 $padding-mobile;
    }
}

.lessonList {
    display: grid;
}

.lessonRow {
    height: fit-content;
    display: flex;
    align-items: center;
    gap: $gap;
    border-bottom: 1px solid var(--line);
    cursor: pointer;
    width: 100%;
    appearance: none;
    border-left: 0;
    border-right: 0;
    border-top: 0;
    background: $transparent;
    color: inherit;
    font: inherit;
    text-align: left;
    padding-right: 0;
    padding-left: 0;

    &:not(:first-child) {
        padding-top: 8px;
    }

    &:not(:last-child) {
        padding-bottom: 8px;
    }

    &:last-child {
        border-bottom: 0;
    }

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.dateBlock {
    width: $width-block-big;
    height: $height-block-big;
    flex: 0 0 $width-block-big;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    border-radius: $radius-mini;
    color: var(--purple);
    background: var(--purple-pale);

    b {
        font-weight: 700;

        @include text(px2);
    }

    small {
        color: var(--purple);
        text-transform: lowercase;

        @include text(px2);
    }

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        flex: 0 0 $width-block;
    }
}

.lessonInfo {
    min-width: 0;
    flex: 1;

    b {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        font-size: 12px;
    }

    small {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        color: var(--muted);
        font-size: 10px;
    }
}

.lessonTime {
    margin-left: auto;
    color: var(--muted);
    font-size: 12px;
    font-weight: 700;
    white-space: nowrap;
}

[data-theme=darked] {
    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }

    .emptyState {
        b {
            color: var(--ink);
        }
    }

    .dateBlock {
        color: $dark-purple-dark;
        background: $dark-purple-pale;

        small {
            color: var(--muted);
        }
    }

    .lessonTime {
        color: var(--muted);
    }
}
</style>
