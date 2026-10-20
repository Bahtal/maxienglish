<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';
import { calendarLessonLegend } from '../../utils/calendarMarkers.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  setup(props, { emit }) {
    function dayAriaLabel(day) {
      const descriptions = day.markers
        .map((marker) => calendarLessonLegend.find((item) => item.key === marker)?.label)
        .filter(Boolean);

      return descriptions.length ? `${day.label}, ${descriptions.join(', ')}` : String(day.label);
    }

    return {
      ...useWorkspaceView(props, emit),
      calendarLessonLegend,
      dayAriaLabel,
    };
  },
};
</script>

<template>
    <section :class="$style.calendarCard">
        <div :class="$style.monthHead">
            <strong>{{ monthLabel }}</strong>
            <span :class="$style.monthControls">
                <button
                    :class="$style.left"
                    aria-label="Предыдущий месяц"
                    @click="addMonth(-1)"
                >
                    <svg>
                        <use href="#icon-arrow"/>
                    </svg>
                </button>

                <button
                    :class="$style.right"
                    aria-label="Следующий месяц"
                    @click="addMonth(1)"
                >
                    <svg>
                        <use href="#icon-arrow"/>
                    </svg>
                </button>
            </span>
        </div>
        <div :class="$style.calendarGrid">
            <span
                v-for="day in ['пн','вт','ср','чт','пт','сб','вс']"
                :key="day"
                :class="$style.calendarWeekday"
            >
                {{ day }}
            </span>
            <div :class="$style.calendarDays">
                <button
                    v-for="day in calendarDays"
                    :key="day.key"
                    :class="[$style.calendarDay, { [$style.muted]: day.muted, [$style.today]: day.today, [$style.selected]: day.selected }]"
                    :aria-label="dayAriaLabel(day)"
                    @click="updateSelectedDay(day.key)"
                >
                    {{ day.label }}
                    <span
                        v-if="day.markers.length"
                        :class="$style.lessonMarkers"
                        aria-hidden="true">
                        <span
                            v-for="marker in day.markers"
                            :key="marker"
                            :class="$style.lessonMarker"
                            :data-status="marker" />
                    </span>
                </button>
            </div>
        </div>
    </section>
</template>

<style lang="scss" module>
.calendarCard {
    padding: $padding;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.monthHead {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;

    strong {
        font-weight: 700;

        @include text(px2);
    }
}

.monthControls {
    display: flex;
    gap: $gap-sm;

    button {
        display: flex;
        justify-content: center;
        align-items: center;
        width: $width-block;
        height: $height-block;
        border: 1px solid var(--line);
        border-radius: $radius-mini;
        background: var(--surface);
        cursor: pointer;
        color: var(--muted);

        svg {
            width: $svg;
            height: $svg;
            fill: var(--purple-dark);
        }

        &.left {
            transform: rotate(180deg);
        }
    }
}

.calendarGrid {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: $grid-gap;
}

.calendarDays {
    display: contents;
}

.calendarWeekday {
    height: $height-block;
    display: grid;
    place-items: center;
    color: var(--purple-dark);
    font-weight: 400;

    @include text(px2);
}

.calendarDay {
    margin: 0 auto;
    width: 40px;
    height: 40px;
    display: grid;
    place-items: center;
    color: var(--muted);
    position: relative;
    border: 0;
    background: $transparent;
    border-radius: $radius-mini;
    cursor: pointer;

    @include text(px2);

    @include respond-to(mobile) {
        width: 30px;
        height: 30px;
        border-radius: $radius-micro;
    }

    &:hover {
        background: var(--purple-pale);
        color: var(--on-purple-pale);
    }

    &.muted {
        color: var(--line);
    }

    &.today {
        color: var(--on-purple-pale);
        background: var(--purple-pale);
        font-weight: 800;
    }

    &.selected {
        color: $white;
        background: var(--purple);
        font-weight: 800;

        .lessonMarker {
            box-shadow: 0 0 0 1px var(--surface);
        }
    }
}

.lessonMarkers {
    position: absolute;
    bottom: 3px;
    left: 50%;
    display: flex;
    justify-content: center;
    gap: 1px;
    max-width: 100%;
    transform: translateX(-50%);
}

.lessonMarker,
.legendMarker {
    display: block;
    flex: 0 0 5px;
    width: 5px;
    height: 5px;
    border-radius: 50%;

    &[data-status='paidUpcoming'] {
        background: var(--green);
    }

    &[data-status='paidPast'] {
        background: var(--calendar-blue);
    }

    &[data-status='cancelled'] {
        background: var(--red);
    }

    &[data-status='unpaidPast'] {
        background: var(--calendar-purple);
    }

    &[data-status='unpaidUpcoming'] {
        background: var(--amber);
    }
}

.markerLegend {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 8px 12px;
    margin: 12px 0 0;
    padding: 0;
    color: var(--muted);
    line-height: 1.35;
    list-style: none;

    @include text(px2);

    li {
        display: flex;
        align-items: center;
        gap: 6px;
        min-width: 0;
    }
}

.legendMarker {
    flex-basis: 7px;
    width: 7px;
    height: 7px;
}

@include respond-to(mobile) {
    .markerLegend {
        grid-template-columns: 1fr;
        gap: 7px;
    }
}

[data-theme=darked] {
    .monthControls {
        button {
            color: var(--ink);
            border-color: var(--line);
            background-color: var(--surface);
        }
    }

    .calendarCard {
        border-color: var(--line);
        background-color: var(--surface);
    }

    .calendarDay {
        color: var(--ink);

        &:hover {
            background-color: color-mix(in srgb, var(--ink) 6%, var(--surface));
        }

        &.today {
            color: $dark-purple-dark;
            background: $dark-purple-pale;
        }

        &.selected {
            color: var(--canvas);
        }

        &.muted {
            color: var(--muted);
        }
    }

    .calendarWeekday {
        color: var(--ink);
    }

    .monthHead {
        strong {
            color: var(--ink);
        }
    }

}
</style>
