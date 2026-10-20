<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

import VSectionHeader from '../VSectionHeader.vue';

import VEmptyState from '../VEmptyState.vue';
import VStatusBadge from '../VStatusBadge.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VSectionHeader, VEmptyState, VStatusBadge },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.calendarAgenda">
        <VSectionHeader
            :class="$style.sectionHeading"
            :title="state.selectedDate === todayKey() ? 'Сегодня' : cap(formatDay(state.selectedDate,{weekday:'long',day:'numeric',month:'long'}))"
            :description="selectedDayLessons.length ? `${selectedDayLessons.length} ${humanCount(selectedDayLessons.length,'занятие','занятия','занятий')}` : 'План на выбранный день'"
        >
            <template #aside>
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
            </template>
        </VSectionHeader>
        <button
            v-for="lesson in selectedDayLessons"
            :key="lesson.id"
            :class="$style.agendaDay"
            @click="openLesson(lesson)"
        >
            <span :class="$style.agendaTime">{{ lesson.time }}</span>
            <span :class="$style.agendaMain">
                <b>{{ state.role === 'teacher' ? studentById(lesson.studentId)?.name : `${lesson.title} с ${state.teacher.name}` }}</b>
                <small>{{ lesson.kind }}</small>
            </span>
            <VStatusBadge
                :status="lesson.status"
                :tone="statusClass(lesson.status)"
                :label="statusLabel(lesson.status)"
            />
        </button>
        <VEmptyState
            v-if="!selectedDayLessons.length"
            :class="$style.emptyState"
            title="Занятий нет"
            description="На эту дату расписание свободно."
        />
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

    &:not(:first-child) {
        padding-top: 8px;
    }

    &:not(:last-child) {
        padding-bottom: 8px;
    }

    &:last-child {
        padding-bottom: 0;
        border-bottom: 0;
    }

    &:first-child {
        padding-top: 0;
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
    color: var(--on-purple-pale);
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
    .agendaMain {
        small {
            color: var(--ink);
        }
    }

    .agendaDay {
        border-color: var(--line);
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
        letter-spacing: -0.25px;
        font-weight: 700;

        @include text(px1);

        @include respond-to(mobile) {
            @include text(px1_5);
        }
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);
        font-size: 10px;
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
    .emptyState {
        b {
            color: var(--ink);
        }
    }

}
</style>
