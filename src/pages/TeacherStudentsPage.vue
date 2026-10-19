<script>
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import AppButton from '../components/AppButton.vue';
import VAvatar from '../components/VAvatar.vue';

import VSectionHeader from '../components/VSectionHeader.vue';

import VEmptyState from '../components/VEmptyState.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VAvatar, VSectionHeader, VEmptyState },
  setup(props, { emit }) {
    return useWorkspaceView(props, emit);
  },
};
</script>

<template>
    <section :class="[$style.card, $style.sectionCard, $style.teacherStudentsPage]">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="Все ученики"
            :description="`${state.students.length} ${humanCount(state.students.length, 'ученик', 'ученика', 'учеников')}`"
        />
        <div :class="$style.teacherStudentsList">
            <div
                v-for="student in [...state.students].sort((a,b)=>a.name.localeCompare(b.name,'ru'))"
                :key="student.id"
                :class="$style.teacherStudentRow">
                <VAvatar
                    :class="$style.avatar"
                    size="large"
                    :tone="colorFor(student.color)"
                    radius="mini"
                    mobile-radius="mini"
                    :src="student.avatarUrl"
                    :name="student.name"
                />
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
            <VEmptyState
                v-if="!state.students.length"
                :class="$style.emptyState"
                title="Пока нет учеников"
            >
                <AppButton
                    size="small"
                    @click="openStudentForm"
                >
                    Добавить ученика
                </AppButton>
            </VEmptyState>
        </div>
    </section>
</template>

<style lang="scss" module>
.avatar {
    border-radius: 14px;
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

        @include text(px1);

        @include respond-to(mobile) {
            @include text(px1_5);
        }
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
            font-weight: 100;
        }
    }
}

.teacherStudentsPage {
    --module-placeholder: 0;
}
</style>
