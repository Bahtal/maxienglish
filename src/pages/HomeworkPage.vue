<script>
import { computed, ref, watch } from 'vue';
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import AppButton from '../components/AppButton.vue';
import CustomSelect from '../components/CustomSelect.vue';
import HomeworkRow from '../components/HomeworkRow.vue';

import VSectionHeader from '../components/VSectionHeader.vue';

import VEmptyState from '../components/VEmptyState.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, CustomSelect, HomeworkRow, VSectionHeader, VEmptyState },
  setup(props, { emit }) {
    const view = useWorkspaceView(props, emit);
    const selectedHomeworkStudent = ref('');
    const selectedHomeworkDate = ref('');
    const selectedHomeworkLabel = ref('');
    const showAllHomework = ref(false);
    const noDueDateFilter = '__no_due_date__';

    const homeworkDateOptions = computed(() => {
        const dates = [...new Set(props.workspace.homeworkList.value
            .map((item) => item.dueDate)
            .filter(Boolean))];

        return dates
            .sort((first, second) => second.localeCompare(first))
            .map((value) => ({
                value,
                label: new Intl.DateTimeFormat('ru-RU', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                }).format(new Date(`${value}T00:00:00`)),
            }));
    });

    const homeworkStudentFilterOptions = computed(() => [
        { value: '', label: 'Все ученики' },
        ...props.workspace.state.students.map((student) => ({
            value: student.id,
            label: student.name,
        })),
    ]);

    const homeworkDateFilterOptions = computed(() => [
        { value: '', label: 'Любая дата' },
        ...(hasHomeworkWithoutDueDate.value
            ? [{ value: noDueDateFilter, label: 'Без срока' }]
            : []),
        ...homeworkDateOptions.value,
    ]);

    const homeworkLabelFilterOptions = computed(() => [
        { value: '', label: 'Все метки' },
        ...props.workspace.homeworkLabels.value.map((label) => ({ value: label, label })),
    ]);

    const hasHomeworkWithoutDueDate = computed(() => props.workspace.homeworkList.value
        .some((item) => !item.dueDate));

    const filteredHomework = computed(() => {
        const items = props.workspace.homeworkList.value;

        if (props.workspace.state.role !== 'teacher') {
            return items;
        }

        return items.filter((item) => {
            if (selectedHomeworkStudent.value && item.studentId !== selectedHomeworkStudent.value) {
                return false;
            }

            if (selectedHomeworkDate.value === noDueDateFilter && item.dueDate) {
                return false;
            }

            if (selectedHomeworkDate.value
                && selectedHomeworkDate.value !== noDueDateFilter
                && item.dueDate !== selectedHomeworkDate.value) {
                return false;
            }

            if (selectedHomeworkLabel.value
                && String(item.label || '').trim().toLocaleLowerCase('ru-RU')
                    !== selectedHomeworkLabel.value.toLocaleLowerCase('ru-RU')) {
                return false;
            }

            return true;
        });
    });

    const displayedHomework = computed(() => {
        if (props.workspace.state.role !== 'teacher' || showAllHomework.value) {
            return filteredHomework.value;
        }

        return filteredHomework.value.slice(0, 4);
    });

    watch(
        [selectedHomeworkStudent, selectedHomeworkDate, selectedHomeworkLabel],
        () => {
            showAllHomework.value = false;
        },
    );

    const hasHomeworkFilters = computed(() => Boolean(
        selectedHomeworkStudent.value
        || selectedHomeworkDate.value
        || selectedHomeworkLabel.value,
    ));

    function resetHomeworkFilters() {
        selectedHomeworkStudent.value = '';
        selectedHomeworkDate.value = '';
        selectedHomeworkLabel.value = '';
    }

    view.selectedHomeworkStudent = selectedHomeworkStudent;
    view.selectedHomeworkDate = selectedHomeworkDate;
    view.selectedHomeworkLabel = selectedHomeworkLabel;
    view.homeworkDateOptions = homeworkDateOptions;
    view.homeworkStudentFilterOptions = homeworkStudentFilterOptions;
    view.homeworkDateFilterOptions = homeworkDateFilterOptions;
    view.homeworkLabelFilterOptions = homeworkLabelFilterOptions;
    view.hasHomeworkWithoutDueDate = hasHomeworkWithoutDueDate;
    view.filteredHomework = filteredHomework;
    view.displayedHomework = displayedHomework;
    view.showAllHomework = showAllHomework;
    view.hasHomeworkFilters = hasHomeworkFilters;
    view.noDueDateFilter = noDueDateFilter;
    view.resetHomeworkFilters = resetHomeworkFilters;
    view.toggleHomeworkList = () => {
        showAllHomework.value = !showAllHomework.value;
    };

    return view;
  },
};
</script>

<template>
    <section :class="[$style.card, $style.sectionCard, $style.homeworkPage]">
        <VSectionHeader
            :class="$style.sectionHeading"
            :title="state.role === 'student' ? 'Мои задания' : 'Задания учеников'"
            :description="filteredHomework.length + ' ' + humanCount(filteredHomework.length, 'задание', 'задания', 'заданий')"
        >
            <template #aside>
                <AppButton
                    v-if="state.role === 'teacher'"
                    size="small"
                    @click="openHomeworkForm()"
                >
                    <svg>
                        <use href="#icon-plus" />
                    </svg>
                    &#32;Добавить задание
                </AppButton>
            </template>
        </VSectionHeader>

        <div
            v-if="state.role === 'teacher'"
            :class="$style.homeworkFilters">
            <CustomSelect
                v-model="selectedHomeworkStudent"
                :class="$style.filterField"
                label="Ученик"
                size="small"
                :options="homeworkStudentFilterOptions" />

            <CustomSelect
                v-model="selectedHomeworkDate"
                :class="$style.filterField"
                label="Срок выполнения"
                size="small"
                :options="homeworkDateFilterOptions" />

            <CustomSelect
                v-if="homeworkLabels.length"
                v-model="selectedHomeworkLabel"
                :class="$style.filterField"
                label="Метка"
                size="small"
                :options="homeworkLabelFilterOptions" />

            <button
                v-if="hasHomeworkFilters"
                :class="$style.clearFilters"
                type="button"
                @click="resetHomeworkFilters">Сбросить фильтры</button>
        </div>

        <div :class="$style.homeworkList">
            <HomeworkRow
                v-for="item in displayedHomework"
                :key="item.id"
                :item="item"
                :student-name="studentById(item.studentId)?.name"
                :teacher="state.role === 'teacher'"
                @open="openHomework"
                @done="markHomeworkDone"
            />

            <VEmptyState
                v-if="!filteredHomework.length"
                :class="$style.emptyState"
                :title="hasHomeworkFilters ? 'Ничего не найдено' : 'Заданий нет'"
                :description="hasHomeworkFilters ? 'Попробуйте изменить фильтры.' : 'Новые материалы появятся здесь.'"
            />
        </div>

        <button
            v-if="state.role === 'teacher' && filteredHomework.length > 4"
            :class="$style.showHomeworkButton"
            type="button"
            :aria-expanded="showAllHomework"
            @click="toggleHomeworkList">
            {{ showAllHomework ? 'Скрыть' : 'Показать ещё' }}
        </button>
    </section>
</template>

<style lang="scss" module>
.card {
    background: var(--surface);
    border-radius: $radius;
    box-shadow: $board-shadow;
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

    svg {
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

.homeworkList {
    display: grid;
}

.showHomeworkButton {
    display: block;
    margin: 8px auto 0;
    padding: 8px 10px;
    border: 0;
    color: var(--purple);
    background: $transparent;
    font: inherit;
    font-weight: 700;
    cursor: pointer;
    transition: color .2s ease, opacity .2s ease;

    @include text(px2);

    &:hover {
        opacity: .75;
    }
}

.homeworkFilters {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    align-items: end;
    gap: 12px;
    margin-bottom: 14px;
}

.filterField {
    display: grid;
    min-width: 0;
}

.clearFilters {
    justify-self: start;
    min-height: 42px;
    padding: 0 8px;
    border: 0;
    color: var(--purple);
    background: $transparent;
    font: inherit;
    font-size: 11px;
    font-weight: 700;
    cursor: pointer;
}

@include respond-to(tablet) {
    .homeworkFilters {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
}

@include respond-to(mobile) {
    .homeworkFilters {
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 10px;
    }

    .filterField:first-child,
    .clearFilters {
        grid-column: 1 / -1;
    }
}

.homeworkPage {
    --module-placeholder: 0;
}

.student {
    --module-placeholder: 0;
}

.teacher {
    --module-placeholder: 0;
}
</style>
