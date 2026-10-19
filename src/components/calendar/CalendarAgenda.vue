<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.calendarAgenda]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>{{ state.selectedDate === todayKey() ? 'Сегодня' : cap(formatDay(state.selectedDate,{weekday:'long',day:'numeric',month:'long'})) }}</h2>
                <p>{{ selectedDayLessons.length ? `${selectedDayLessons.length} ${humanCount(selectedDayLessons.length,'занятие','занятия','занятий')}` : 'План на выбранный день' }}</p>
            </div>
            <div v-if="state.role === 'teacher'" :class="$style.calendarActions">
                <AppButton
                    size="small"
                    @click="openLessonForm(state.selectedDate)"
                >
                    <svg>
                        <use href="#icon-plus" />
                    </svg>
                    &#32;&#32;Добавить урок&#32;
                </AppButton>
                <AppButton
                    variant="secondary"
                    size="small"
                    @click="openHomeworkForm()"
                >
                    <svg>
                        <use href="#icon-plus" />
                    </svg>
                    &#32;&#32;Дать ДЗ&#32;
                </AppButton>
            </div>
        </div>
        <button
            v-for="lesson in selectedDayLessons"
            :key="lesson.id"
            :class="$style.agendaDay"
            @click="openLesson(lesson)"
        >
            <span :class="$style.agendaTime">{{ lesson.time }}</span>
            <span :class="$style.agendaMain">
                <b>{{ state.role === 'teacher' ? studentById(lesson.studentId)?.name : `${lesson.title} с ${state.teacher.name}` }}</b>
                <small>{{ lesson.kind }} · {{ statusLabel(lesson.status) }}</small>
            </span>
            <span :class="[$style.status, $style[statusClass(lesson.status)]]">{{ statusLabel(lesson.status) }}</span>
        </button>
        <div
            v-if="!selectedDayLessons.length"
            :class="$style.emptyState"
        >
            <b>Занятий нет</b>
            <span>На эту дату расписание свободно.</span>
        </div>
    </section>
</template>

<style lang="scss" module>
.agendaDay {
    display: flex;
    align-items: center;
    gap: $gap;
    border-bottom: 1px solid var(--line);
    cursor: pointer;
    appearance: none;
    border-left: 0;
    border-right: 0;
    border-top: 0;
    background: $transparent;
    color: inherit;
    font: inherit;
    text-align: left;
    width: 100%;
    padding-right: 0;
    padding-left: 0;

    &:last-child {
        border-bottom: 0;
    }

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.calendarAgenda {
    padding: $padding;
}

.calendarActions {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 8px;
    flex-wrap: wrap;

    button {
        svg {
            width: $svg;
            height: $svg;
            stroke: currentColor;
        }
    }
}

.agendaTime {
    display: flex;
    justify-content: center;
    align-items: center;
    background: var(--purple-pale);
    border-radius: $radius;
    width: $width-block-big;
    height: $height-block-big;
    color: var(--purple);
    font-weight: 700;

    @include text(px2);

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        border-radius: $radius-mini;
        font-weight: 400;

        @include text(px2);
    }
}

.agendaMain {
    flex: 1;
    min-width: 0;

    b {
        display: block;

        @include text(px2);
    }

    small {
        display: block;
        margin-top: 5px;
        color: var(--muted);

        @include text(px2);
    }
}

@include respond-to(mobile) {
    .calendarAgenda {
        padding: $padding-mobile;

        .sectionHeading {
            align-items: flex-start;
            flex-wrap: wrap;
        }
    }

    .calendarActions {
        width: 100%;
        justify-content: flex-start;
    }
}

[data-theme=darked] {
    .calendarAgenda {
        border-color: var(--line);
        background-color: var(--surface);
    }

    .agendaMain {
        small {
            color: var(--ink);
        }
    }

    .agendaDay {
        border-color: var(--line);
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
        letter-spacing: -0.25px;
        font-weight: 700;

        @include text(px2);
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);
        font-size: 10px;
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
    & > svg {
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

    @include text(px2);

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

.paid {
    --module-placeholder: 0;
}

.pending {
    --module-placeholder: 0;
}

.student {
    --module-placeholder: 0;
}

.teacher {
    --module-placeholder: 0;
}
</style>
