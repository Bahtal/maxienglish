<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import HomeworkRow from '../HomeworkRow.vue';

import VSectionHeader from '../VSectionHeader.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { HomeworkRow, VSectionHeader },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.sectionCard, $style.teacherHomeworkCard]">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="Последние задания"
            description="Материалы, отправленные ученикам"
        >
            <template #aside>
                <button
                    :class="$style.textLink"
                    @click="go('homework')"
                >
                    &#32;Перейти к ДЗ&#32;&#32;
                    <svg>
                        <use href="#icon-arrow" />
                    </svg>
                </button>
            </template>
        </VSectionHeader>
        <div :class="$style.homeworkList">
            <HomeworkRow
                v-for="item in homeworkList.slice(0,3)"
                :key="item.id"
                :item="item"
                :student-name="studentById(item.studentId)?.name"
                teacher
                @open="openHomework" />
        </div>
    </section>
</template>

<style lang="scss" module>
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

        @include text(px1);

        @include respond-to(mobile) {
            @include text(px1_5);
        }
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);

        @include respond-to(mobile) {
            @include text(px3);
        }
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

.sectionHeading {
    > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
    }
}

.homeworkList {
    display: grid;
}
</style>
