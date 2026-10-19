<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.teacherProfileOverview]">
        <div :class="$style.teacherProfileIdentity">
            <span :class="[$style.avatar, $style.teacherProfileAvatar]">
                <img
                    v-if="state.teacher.avatarUrl"
                    :src="state.teacher.avatarUrl"
                    alt="" />
                <template
                    v-else>{{ initials(state.teacher.name) }}</template>
            </span>
            <div :class="$style.teacherProfileIdentityCopy">
                <h2>{{ state.teacher.name }}</h2>
                <p>{{ state.teacher.experience ? `Стаж ${state.teacher.experience}` : 'Стаж не указан' }}</p>
                <span>{{ state.teacher.specialization || 'Предметы пока не указаны' }}</span>
            </div>
        </div>
        <button
            :class="$style.teacherProfileRoster"
            @click="go('students')">
            <span>
                <small>Всего учеников</small>
                <b>{{ state.students.length }}</b>
            </span>
            <span :class="$style.teacherProfileRosterLink">
                &#32;Открыть список&#32;&#32;
                <svg>
                    <use href="#icon-arrow"/>
                </svg>
            </span>
        </button>
        <div :class="$style.teacherProfileStats">
            <div :class="[$style.card, $style.teacherProfileStat]">
                <div :class="$style.top">
                    <small>Сегодня</small>
                    <b :class="$style.today">{{ daySummary.todayCount }}</b>
                </div>
                <span>уроков в расписании</span>
            </div>
            <button
                :class="[$style.card, $style.teacherProfileStat, $style.interactive]"
                :disabled="!daySummary.next"
                @click="openProfileNextLesson">
                <div :class="$style.top">
                    <small>Следующий урок</small>
                    <b>{{ daySummary.next ? `${cap(formatDay(daySummary.next.date,{weekday:'long',day:'numeric',month:'long'}))} · ${daySummary.next.time}` : 'Нет ближайших уроков' }}</b>
                </div>
                <span>{{ daySummary.next ? studentById(daySummary.next.studentId)?.name : '' }}</span>
            </button>
        </div>
    </section>
</template>

<style lang="scss" module>
.avatar {
    width: $width-block-big;
    height: $height-block-big;
    flex: 0 0 $width-block-big;
    min-width: 0;
    display: grid;
    place-items: center;
    overflow: hidden;
    border-radius: $radius;
    color: $white;
    background: linear-gradient(140deg, var(--amber), var(--red));
    font-weight: 700;

    @include text(px2);

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        flex: 0 0 $width-block;
        border-radius: $radius-micro;
    }

    > img {
        display: block;
        width: 100%;
        height: 100%;
        max-width: 100%;
        object-fit: cover;
    }
}

.card {
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius;
    box-shadow: var(--shadow);
}

[data-theme=darked] {
    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }
}

.teacherProfileOverview {
    padding: $padding;
}

@include respond-to(mobile) {
    .teacherProfileOverview {
        padding: $padding-mobile;
    }
}

.teacherProfileIdentity {
    display: flex;
    align-items: center;
    gap: $gap;
    min-width: 0;

    @include respond-to(mobile) {
        gap: $gap-sm
    }
}

.teacherProfileAvatar {
    width: $width-block-big;
    height: $height-block-big;
    flex-basis: $width-block-big;
    border-radius: $radius;

    @include text(px2);

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        flex-basis: $width-block;
        border-radius: $radius-micro;
    }
}

.teacherProfileIdentityCopy {
    min-width: 0;

    h2 {
        margin: 0;
        font-size: 19px;
    }

    p {
        margin: 5px 0 3px;
        color: var(--muted);

        @include text(px2);
    }

    span {
        color: var(--purple);

        @include text(px2);
    }
}

.teacherProfileStats {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: $gap;
    margin-top: 12px;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.teacherProfileRoster {
    width: 100%;
    margin-top: 16px;
    padding: 12px 16px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: $gap;
    border: 1px solid var(--line);
    border-radius: $radius;
    background: var(--surface);
    text-align: left;
    cursor: pointer;
    transition: border-color 0.18s ease, background 0.18s ease;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }

    &:hover {
        background: var(--purple-pale);
    }

    > span:first-child {
        display: flex;
        align-items: center;
        gap: $gap;

        @include respond-to(mobile) {
            gap: $gap-sm;
        }
    }

    small {
        color: var(--muted);
        font-size: 10px;
    }

    b {
        color: var(--ink);
        font-size: 17px;
    }
}

.teacherProfileRosterLink {
    display: flex;
    align-items: center;
    gap: 6px;
    color: var(--purple);
    font-weight: 400;

    @include text(px2);

    svg {
        width: 10px;
        height: 10px;
        transform: rotate(90deg);
        stroke: currentColor;
        fill: none;
    }
}

.teacherProfileStat {
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    gap: $gap;
    min-width: 0;
    min-height: 112px;
    padding: 12px 16px;
    border: 1px solid var(--line);
    text-align: left;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }

    small {
        display: block;
        color: var(--muted);
        font-size: 10px;
    }

    b {
        display: block;
        margin-top: 5px;
        color: var(--ink);
        font-weight: 700;

        @include text(px2);
    }

    .today {
        font-size: 52px;
        line-height: .8;
    }

    span {
        display: flex;
        align-items: center;
        gap: 5px;
        margin-top: auto;
        color: var(--purple);
        line-height: 1.4;

        @include text(px2);

        svg {
            width: 10px;
            height: 10px;
            transform: rotate(90deg);
            stroke: currentColor;
            fill: none;
        }
    }

    [data-ref=next-lesson-date] {
        @include text(px2);
    }

    [data-ref=next-lesson-student] {
        color: var(--muted);
    }
}

@include respond-to(mobile) {
    .teacherProfileStats {
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 8px;
    }

    .teacherProfileStat {
        min-height: 116px;
        padding: $padding;

        @include respond-to(mobile) {
            padding: $padding-mobile;
        }

        [data-ref=next-lesson-date] {
            overflow-wrap: anywhere;

            @include text(px2);
        }

        span {
            @include text(px2);
        }
    }

    .teacherProfileRoster {
        padding: $padding;

        @include respond-to(mobile) {
            padding: $padding-mobile;
        }
    }

    .teacherProfileRosterLink {
        @include text(px2);
    }
}

[data-theme=darked] {
    .teacherProfileRoster {
        color: var(--ink);
        background-color: color-mix(in srgb, var(--ink) 6%, var(--surface));
        border-color: var(--line);
        background-color: var(--surface);

        &:hover {
            border-color: var(--purple);
            background-color: var(--purple-pale);
        }

        b {
            color: var(--ink);
        }
    }

    .teacherProfileIdentityCopy {
        h2 {
            color: var(--ink);
        }
    }

}

.teacherProfileOverview {
    .teacherProfileStats {
        .teacherProfileStat {
            width: 100%;
            text-align: left;
        }
    }
}

.interactive {
    width: 100%;
    cursor: pointer;
    transition: border-color 0.18s ease, transform 0.18s ease, box-shadow 0.18s ease;

    &:hover:not(:disabled) {
        border-color: var(--purple-pale);
        transform: translateY(-1px);
        box-shadow: 0 9px 24px color-mix(in srgb, var(--purple) 7%, transparent);
    }

    &:focus-visible {
        outline: 3px solid color-mix(in srgb, var(--purple) 24%, transparent);
        outline-offset: 2px;
    }

    &:disabled {
        cursor: default;
        opacity: 0.75;
    }
}
</style>
