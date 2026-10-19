<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import HomeworkRow from '../HomeworkRow.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
    components: { HomeworkRow },
    setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.sectionCard]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>Домашние задания</h2>
                <p>Небольшие шаги между занятиями</p>
            </div>

            <button
                :class="$style.textLink"
                @click="go('homework')"
            >
                &#32;Все задания&#32;&#32;
                <svg>
                    <use href="#icon-arrow" />
                </svg>
            </button>
        </div>

        <div :class="$style.homeworkList">
            <HomeworkRow
                v-for="item in studentHomework.filter((entry) => !isDoneHomework(entry)).slice(0,2)"
                :key="item.id"
                :item="item"
                @open="openHomework"
                @done="markHomeworkDone"
            />
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

[data-theme=darked] .card {
  border-color: var(--line);
  background-color: var(--surface);
}

.homeworkList {
  display: grid;
}
</style>
