<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';
import SegmentedToggle from '../SegmentedToggle.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, SegmentedToggle },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.teacherSchedule]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>Расписание занятий</h2>
                <p>{{ upcomingLessons.length }} занятий запланировано</p>
            </div>
            <div :class="$style.scheduleHeadingActions">
                <AppButton
                    size="small"
                    @click="openLessonForm()">
                    <svg>
                        <use href="#icon-plus" />
                    </svg>
                    &#32;&#32;Добавить урок&#32;
                </AppButton>
                <AppButton
                    variant="secondary"
                    size="small"
                    @click="openStudentForm">
                    <svg>
                        <use href="#icon-plus" />
                    </svg>
                    &#32;&#32;Добавить ученика&#32;
                </AppButton>
            </div>
        </div>
        <div :class="$style.filterRow">
            <SegmentedToggle
                :model-value="state.selectedFilter"
                :options="filters"
                aria-label="Фильтр занятий по дню недели"
                @update:model-value="setSelectedFilter"
            />

            <AppButton
                variant="outline"
                size="small"
                :class="$style.calendarAction"
                @click="go('calendar')"
            >
                <svg>
                    <use href="#icon-calendar" />
                </svg>
                &#32;&#32;Открыть весь календарь&#32;
            </AppButton>
        </div>
        <div :class="$style.scheduleList">
            <button
                v-for="lesson in filteredTeacherLessons"
                :key="lesson.id"
                :class="$style.scheduleRow"
                @click="openLesson(lesson)"
            >
                <span :class="$style.scheduleDate">
                    {{ cap(formatWeekday(lesson.date, true)) }}{{ dateObject(lesson.date).getDate() }}
                </span>
                <span :class="$style.scheduleCenter">
                     <span :class="[$style.avatar, $style[colorFor(studentById(lesson.studentId)?.color)]]">
                         {{ initials(studentById(lesson.studentId)?.name) }}
                     </span>

                     <span :class="$style.schedulePerson">
                        <b @click.stop="openStudent(studentById(lesson.studentId))">
                            {{ studentById(lesson.studentId)?.name }}
                        </b>
                         <span :class="$style.schedulePersonBottom">
                             <span :class="$style.scheduleDetail">{{ formatWeekday(lesson.date) }} · {{ lesson.time }}</span>
                             <span :class="[$style.status, $style[statusClass(lesson.status)]]">{{ statusLabel(lesson.status) }}</span>
                         </span>
                    </span>

                </span>
                <span :class="$style.lessonCount">{{ studentById(lesson.studentId)?.paidLessons || 0 }}</span>
            </button>

            <div
                v-if="!filteredTeacherLessons.length"
                :class="$style.emptyState"
            >
                <b>На этот день занятий нет</b>
                <span>Выберите другой день или откройте календарь.</span>
            </div>
        </div>
    </section>
</template>

<style lang="scss" module>
.avatar {
    width: $width-block-big;
    height: $height-block-big;
    flex: 0 0 $width-block-big;
    display: grid;
    place-items: center;
    border-radius: $radius-mini;
    color: $white;
    background: linear-gradient(140deg, var(--amber), var(--red));
    font-weight: 700;

    @include text(px2);

    &.purple,
    &.blue {
        background: linear-gradient(140deg, var(--purple), var(--purple-dark));
    }

    &.mint {
        background: linear-gradient(140deg, var(--mint), var(--green));
    }
}

.card {
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius;
    box-shadow: var(--shadow);
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

    &.unpaid {
        color: var(--red);
        background: color-mix(in srgb, var(--red) 10%, var(--surface));
    }

    &.paid {
        color: var(--green);
        background: color-mix(in srgb, var(--green) 10%, var(--surface));
    }

    &.pending {
        color: var(--amber);
        background: color-mix(in srgb, var(--amber) 14%, var(--surface));
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
    padding: 0 $padding;

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
        padding: 0 $padding-mobile;
    }
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

    .status {
        &.unpaid {
            color: var(--red);
            background: color-mix(in srgb, var(--red) 20%, var(--surface));
        }
    }
}

.mint {
    color: var(--green);
    background: var(--mint);
}

[data-theme=darked] {
    .mint {
        color: var(--green);
        background: $dark-mint;
    }
}

.filterRow {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
}

.calendarAction {
    margin-left: auto;

    svg {
        width: $svg;
        height: $svg;
        fill: none;
        stroke: currentColor;
    }
}

.teacherSchedule {
    padding: $padding;
}

.scheduleHeadingActions {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: flex-end;
    gap: 8px;

    svg {
        width: $svg;
        height: $svg;
        fill: none;
        stroke: currentColor;
    }
}

.scheduleList {
    display: grid;
    margin-top: 16px;
}

.scheduleRow {
    display: grid;
    grid-template-columns: 45px minmax(140px, 1fr) minmax(135px, 0.9fr) auto 34px;
    align-items: center;
    gap: $gap;
    border-bottom: 1px solid var(--line);
    cursor: pointer;
    padding: 12px 0;

    appearance: none;
    width: 100%;
    border-top: 0;
    border-right: 0;
    border-left: 0;
    background: $transparent;
    color: inherit;
    font: inherit;
    text-align: left;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }

    &:first-child {
        padding-top: 0;
    }

    &:last-child {
        padding-bottom: 0;
        border-bottom: 0;
    }
}

.scheduleDate {
    display: flex;
    align-items: center;
    justify-content: center;
    width: $width-block-big;
    height: $height-block-big;
    border-radius: $radius-mini;
    color: var(--purple);
    background: var(--purple-pale);
    font-weight: 700;

    @include text(px2);

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
    }
}

.scheduleCenter {
    display: flex;
    flex-flow: row nowrap;
    align-items: flex-start;
    gap: 8px;
}

.schedulePerson {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    min-width: 0;

    .schedulePersonBottom {
        display: flex;
        flex-flow: row nowrap;
        align-items: center;
        gap: 8px;
    }

    .avatar {
        width: $width-block-big;
        height: $height-block-big;
        flex-basis: $width-block-big;
        border-radius: $radius-mini;
        font-size: 10px;
    }

    b {
        min-width: 0;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        cursor: pointer;

        @include text(px2);
    }
}

.scheduleDetail {
    color: var(--muted);
    font-size: 10px;
    white-space: nowrap;
}

.lessonCount {
    width: 31px;
    height: 31px;
    display: grid;
    place-items: center;
    border-radius: 11px;
    color: var(--purple);
    background: var(--purple-pale);
    font-weight: 700;
}

@include respond-to(tablet) {
    .scheduleRow {
        grid-template-columns: 40px minmax(120px, 1fr) 32px;
        gap: 9px;
    }
}

@include respond-to(mobile) {
    .avatar {
        width: $width-block;
        height: $height-block;
        flex-basis: $height-block;

        @include text(px2);
    }

    .teacherSchedule {
        padding: $padding-mobile;
    }

    .scheduleRow {
        grid-template-columns: 36px minmax(100px, 1fr) 30px;
        gap: 8px;
        padding: 8px 0;

        .status {
            padding: 1px 4px;
            width: fit-content;

            @include text(px3);
        }
    }

    .schedulePerson {
        .avatar {
            width: $width-block;
            height: $height-block;
            flex-basis: $height-block;

            @include text(px2);
        }

        b {
            @include text(px2);
        }
    }

    .lessonCount {
        width: 28px;
        height: 28px;
    }

    .filterRow {
        gap: 6px;
    }

    .calendarAction {
        margin-left: 0;
    }
}

@include respond-to(mobile) {
    .scheduleHeadingActions {
        width: 100%;
        justify-content: flex-start;
    }

    .teacherSchedule {
        > .sectionHeading {
            align-items: flex-start;
            flex-direction: column;
        }
    }
}

@media (max-width: 400px) {
    .scheduleRow {
        align-items: start;

        .schedulePerson {
            .schedulePersonBottom {
                align-items: flex-start;
                gap: 2px;
                flex-flow: column;
            }
        }
    }
}

[data-theme=darked] {
    .scheduleDetail {
        color: var(--muted);
    }

    .avatar {
        color: var(--canvas);
    }

    .scheduleHeadingActions {
        button[data-variant=primary] {
            color: var(--canvas);
        }
    }
}

.paid {
    --module-placeholder: 0;
}

.pending {
    --module-placeholder: 0;
}
</style>
