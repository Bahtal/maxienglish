<script>
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import AppButton from '../components/AppButton.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton },
  setup(props, { emit }) {
    return useWorkspaceView(props, emit);
  },
};
</script>

<template>
    <section :class="[$style.card, $style.sectionCard, $style.teacherStudentsPage]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>Все ученики</h2>
                <p>{{ state.students.length }}{{ humanCount(state.students.length,'ученик','ученика','учеников') }}</p>
            </div>
        </div>
        <div :class="$style.teacherStudentsList">
            <div
                v-for="student in [...state.students].sort((a,b)=>a.name.localeCompare(b.name,'ru'))"
                :key="student.id"
                :class="$style.teacherStudentRow">
                <span :class="[$style.avatar, $style[colorFor(student.color)]]">
                    <img
                        v-if="student.avatarUrl"
                        :src="student.avatarUrl"
                        alt="" />
                    <template
                        v-else>{{ initials(student.name) }}</template>
                </span>
                <div :class="$style.teacherStudentCopy">
                    <button
                        :class="$style.teacherStudentName"
                        @click="openStudent(student)">{{ student.name }}</button>
                    <small>{{ student.username ? `@${student.username}` : 'Telegram username не указан' }}</small>
                </div>
                <AppButton
                    variant="outline"
                    size="small"
                    @click="openChat(student.id)">
                    <svg>
                        <use href="#icon-message"/>
                    </svg>
                    &#32;Чат
                </AppButton>
            </div>
            <div
                v-if="!state.students.length"
                :class="$style.emptyState">
                <b>Пока нет учеников</b>
                <AppButton
                    size="small"
                    @click="openStudentForm">Добавить ученика</AppButton>
            </div>
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
    border-radius: 14px;
    color: $white;
    font-weight: 700;
    background: linear-gradient(140deg, var(--amber), var(--red));

    @include text(px2);

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        flex: 0 0 $width-block;
    }

    > img {
        display: block;
        width: 100%;
        height: 100%;
        max-width: 100%;
        object-fit: cover;
    }

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
        letter-spacing: -0.25px;

        @include text(px2);
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);
    }

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

.teacherStudentsList {
    display: grid;
}

.teacherStudentRow {
    display: grid;
    grid-template-columns: 42px minmax(0, 1fr) auto;
    align-items: center;
    gap: $gap;
    min-width: 0;
    padding: 12px 0;
    border-bottom: 1px solid var(--line);

    @include respond-to(mobile) {
        gap: $gap-sm;
    }

    &:last-child {
        border-bottom: 0;
    }

    button {
        svg {
            width: $svg;
            height: $svg;
            fill: none;
            stroke: currentColor;
        }
    }
}

.teacherStudentCopy {
    display: grid;
    min-width: 0;
    gap: 4px;

    small {
        overflow: hidden;
        color: var(--muted);
        text-overflow: ellipsis;
        white-space: nowrap;

        @include text(px2);
    }
}

.teacherStudentName {
    justify-self: start;
    max-width: 100%;
    overflow: hidden;
    border: 0;
    padding: 0;
    background: $transparent;
    color: var(--ink);
    font-size: 12px !important;
    font-weight: 700 !important;
    text-align: left;
    text-overflow: ellipsis;
    white-space: nowrap;
    cursor: pointer;

    &:hover {
        color: var(--purple);
    }
}

@include respond-to(mobile) {
    .teacherStudentRow {
        grid-template-columns: $width-block-big minmax(0, 1fr) auto;
        gap: $gap-sm;

        > .avatar {
            width: $width-block-big;
            height: $width-block-big;
            flex-basis: $width-block-big;
            border-radius: $radius-mini;
            font-weight: 100;

            @include text(px2);
        }
    }
}

.teacherStudentsPage {
    --module-placeholder: 0;
}
</style>
