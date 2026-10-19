<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import HomeworkRow from '../HomeworkRow.vue';
import StudentHomeSection from './StudentHomeSection.vue';

export default {
    props: { workspace: { type: Object, required: true } },
    emits: ['workspace-action'],
    components: { HomeworkRow, StudentHomeSection },
    setup(props, { emit }) {
        return useWorkspaceView(props, emit);
    },
};
</script>

<template>
    <StudentHomeSection
        title="Домашние задания"
        description="Небольшие шаги между занятиями"
        action-label="Все задания"
        action-aria-label="Открыть все домашние задания"
        @action="go('homework')"
    >
        <div :class="$style.homeworkList">
            <HomeworkRow
                v-for="item in studentHomework.filter((entry) => !isDoneHomework(entry)).slice(0, 2)"
                :key="item.id"
                :item="item"
                @open="openHomework"
                @done="markHomeworkDone"
            />
        </div>
    </StudentHomeSection>
</template>

<style lang="scss" module>
.homeworkList {
    display: grid;
}
</style>
