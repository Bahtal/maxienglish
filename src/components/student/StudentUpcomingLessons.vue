<script setup>
import { computed } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';
import VEmptyState from '../VEmptyState.vue';
import StudentHomeSection from './StudentHomeSection.vue';

const props = defineProps({
    workspace: {
        type: Object,
        required: true,
    },
});

const emit = defineEmits(['workspace-action']);
const workspace = useWorkspaceView(props, emit);

const studentLessons = computed(() => workspace.visibleLessons.value
    .filter((lesson) => lesson.studentId === workspace.state.studentUser.id));
const nextLesson = computed(() => studentLessons.value[0] || null);
const laterLessons = computed(() => studentLessons.value.slice(1, 3));

function monthLabel(date) {
    return new Intl.DateTimeFormat('ru-RU', { month: 'short' })
        .format(workspace.dateObject(date))
        .replace(/\.$/, '');
}

function openCalendar() {
    workspace.go('calendar');
}

function openLesson(lesson) {
    workspace.openLesson(lesson);
}
</script>

<template>
    <StudentHomeSection
        title="Ближайшие занятия"
        description="Ваше расписание на ближайшее время"
        action-label="Весь календарь"
        action-aria-label="Открыть весь календарь"
        @action="openCalendar"
    >
        <div :class="$style.lessonList">
            <button
                v-if="nextLesson"
                :class="$style.featuredLesson"
                type="button"
                aria-label="Открыть ближайшее занятие"
                @click="openLesson(nextLesson)"
            >
                <span :class="$style.featuredDate" aria-hidden="true">
                    <span>{{ workspace.cap(workspace.formatWeekday(nextLesson.date, true)) }}</span>
                    <strong>{{ workspace.dateObject(nextLesson.date).getDate() }}</strong>
                    <small>{{ monthLabel(nextLesson.date) }}</small>
                </span>

                <span :class="$style.featuredCopy">
                    <strong>{{ nextLesson.title || 'Английский' }}</strong>
                    <span>{{ workspace.state.teacher.name }} · {{ nextLesson.durationMinutes }} мин</span>
                </span>

                <time
                    :class="$style.featuredTime"
                    :datetime="workspace.dateTimeIso(nextLesson.date, nextLesson.time)"
                >
                    {{ nextLesson.time }}
                </time>
            </button>

            <button
                v-for="lesson in laterLessons"
                :key="lesson.id"
                :class="$style.lessonRow"
                type="button"
                @click="openLesson(lesson)"
            >
                <span :class="$style.dateBlock">
                    <b>{{ workspace.dateObject(lesson.date).getDate() }}</b>
                    <small>{{ workspace.formatWeekday(lesson.date, true) }}</small>
                </span>

                <span :class="$style.lessonInfo">
                    <b>{{ lesson.title || 'Английский' }}</b>
                    <small>{{ workspace.cap(workspace.formatDay(lesson.date)) }} · {{ lesson.durationMinutes }} мин</small>
                </span>

                <span :class="$style.lessonTime">{{ lesson.time }}</span>
            </button>

            <VEmptyState
                v-if="!studentLessons.length"
                :class="$style.emptyState"
                title="Пока нет занятий"
                description="Когда появится запись, она будет здесь."
            />
        </div>
    </StudentHomeSection>
</template>

<style lang="scss" module>
.lessonList {
    display: grid;
}

.featuredLesson {
    display: grid;
    grid-template-columns: 60px minmax(0, 1fr) auto;
    align-items: center;
    gap: 16px;
    width: 100%;
    min-width: 0;
    border: 0;
    padding: 0;
    background: transparent;
    border-radius: $radius-mini;
    color: var(--ink);
    font: inherit;
    text-align: left;
    cursor: pointer;
}

.featuredDate {
    display: grid;
    justify-items: center;
    gap: 1px;
    padding-right: 12px;
    border-right: 1px solid var(--border-color);
    color: var(--purple);
    font-size: 11px;
    line-height: 1.2;
    text-transform: lowercase;

    strong {
        font-size: 28px;
        font-weight: 600;
        line-height: 1.05;
        font-variant-numeric: tabular-nums;
    }

    small {
        font-size: 11px;
    }
}

.featuredCopy {
    display: grid;
    gap: 5px;
    min-width: 0;

    strong {
        overflow: hidden;
        font-size: 15px;
        font-weight: 600;
        line-height: 1.35;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    span {
        overflow: hidden;
        color: var(--muted);
        font-size: 13px;
        line-height: 1.4;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
}

.featuredTime {
    color: var(--purple);
    font-size: 20px;
    font-weight: 600;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
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
    display: flex;
    flex: 0 0 $width-block-big;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: $width-block-big;
    height: $height-block-big;
    border-radius: $radius-mini;
    color: var(--on-purple-pale);
    background: var(--purple-pale);

    b {
        font-weight: 700;

        @include text(px2);
    }

    small {
        color: var(--on-purple-pale);
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
    flex: 1;
    min-width: 0;

    b,
    small {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    b {
        font-size: 12px;
    }

    small {
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

.emptyState {
    padding: 0 $padding;
    color: var(--muted);
    text-align: center;

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

[data-theme='darked'] {
    .featuredDate {
        color: $dark-purple-dark;

        small {
            color: var(--muted);
        }
    }

    .dateBlock {
        color: var(--on-purple-pale);
        background: $dark-purple-pale;

        small {
            color: var(--muted);
        }
    }

    .lessonTime {
        color: var(--muted);
    }
}

@include respond-to(mobile) {
    .featuredLesson {
        grid-template-columns: 52px minmax(0, 1fr) auto;
        gap: $gap-sm;
    }

    .featuredDate {
        padding-right: 8px;

        strong {
            font-size: 25px;
        }
    }

    .featuredCopy {
        strong {
            font-size: 14px;
        }

        span {
            font-size: 12px;
        }
    }

    .featuredTime {
        font-size: 17px;
    }

}
</style>
