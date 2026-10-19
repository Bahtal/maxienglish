<script>
import { computed, ref } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';
import CustomSelect from '../CustomSelect.vue';

import VModalActions from '../VModalActions.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, CustomSelect, VModalActions },
  setup(props, { emit }) {
    const view = useWorkspaceView(props, emit);
    const selectedStudentId = ref(
        props.workspace.modal?.data?.studentId
        ?? props.workspace.state.students[0]?.id
        ?? '',
    );
    const selectedHomeworkLabel = ref('');
    const isAddingHomeworkLabel = ref(false);
    const homeworkStudentOptions = computed(() => props.workspace.state.students.map((student) => ({
        value: student.id,
        label: student.name,
    })));
    const homeworkLabelOptions = computed(() => props.workspace.homeworkLabels.value);
    const homeworkLabelSelectOptions = computed(() => [
        { value: '', label: 'Без метки' },
        ...homeworkLabelOptions.value.map((label) => ({ value: label, label })),
    ]);

    function startAddingHomeworkLabel() {
        selectedHomeworkLabel.value = '';
        isAddingHomeworkLabel.value = true;
    }

    function chooseExistingHomeworkLabel() {
        isAddingHomeworkLabel.value = false;
    }

    view.selectedHomeworkLabel = selectedHomeworkLabel;
    view.selectedStudentId = selectedStudentId;
    view.isAddingHomeworkLabel = isAddingHomeworkLabel;
    view.homeworkStudentOptions = homeworkStudentOptions;
    view.homeworkLabelOptions = homeworkLabelOptions;
    view.homeworkLabelSelectOptions = homeworkLabelSelectOptions;
    view.startAddingHomeworkLabel = startAddingHomeworkLabel;
    view.chooseExistingHomeworkLabel = chooseExistingHomeworkLabel;

    return view;
  },
};
</script>

<template>
    <form
        :class="$style.formStack"
        @submit.prevent="submitWorkspaceForm($event, 'createHomework')">
        <div :class="$style.field">
            <span>Ученик</span>
            <CustomSelect
                v-model="selectedStudentId"
                name="studentId"
                :options="homeworkStudentOptions" />
        </div>
        <label :class="$style.field">
            <span>Название задания</span>
            <input
                name="title"
                maxlength="160"
                required />
        </label>
        <label :class="$style.field">
            <span>Описание</span>
            <textarea
                name="description"
                rows="5"
                maxlength="5000"></textarea>
        </label>
        <label :class="$style.field">
            <span>Срок выполнения</span>
            <input
                name="dueDate"
                type="date"
                :min="todayKey()" />
        </label>
        <div :class="$style.field">
            <span>Метка</span>
            <CustomSelect
                v-if="homeworkLabelOptions.length && !isAddingHomeworkLabel"
                v-model="selectedHomeworkLabel"
                name="label"
                :options="homeworkLabelSelectOptions" />
            <input
                v-else
                name="label"
                type="text"
                maxlength="40"
                placeholder="Например, топ" />
            <button
                v-if="homeworkLabelOptions.length && !isAddingHomeworkLabel"
                :class="$style.labelAction"
                type="button"
                @click="startAddingHomeworkLabel">Добавить новую метку</button>
            <button
                v-else-if="homeworkLabelOptions.length && isAddingHomeworkLabel"
                :class="$style.labelAction"
                type="button"
                @click="chooseExistingHomeworkLabel">Выбрать существующую метку</button>
        </div>
        <label :class="$style.field">
            <span>Прикрепить материал</span>
            <input
                name="attachment"
                type="file" />
        </label>
        <VModalActions :class="$style.modalActions">
            <AppButton
                type="submit"
                :loading="modal.busy"
                :disabled="modal.busy">Добавить задание</AppButton>
            <AppButton
                variant="ghost"
                @click="closeModal">Отмена</AppButton>
        </VModalActions>
    </form>
</template>

<style lang="scss" module>

[data-theme=darked] {
    .field {
        input {
            color: var(--ink);
            border-color: var(--line);
            background-color: var(--surface);
        }

        textarea {
            color: var(--ink);
            border-color: var(--line);
            background-color: var(--surface);
        }

    }
}

.formStack {
    display: grid;
    gap: 16px;

    .field {
        display: grid;
        gap: 7px;
        min-width: 0;

        > span {
            color: var(--muted);
            font-size: 13px;
            font-weight: 650;
        }

        input {
            width: 100%;
            min-width: 0;
            min-height: 44px;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 11px;
            outline: none;
            background: var(--surface);
            color: var(--ink);
            font: inherit;

            &:focus {
                border-color: var(--purple);
                box-shadow: 0 0 0 3px color-mix(in srgb, var(--purple) 10%, transparent);
            }

            &[type=file] {
                padding: 9px;
            }
        }

        textarea {
            width: 100%;
            min-width: 0;
            min-height: 110px;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 11px;
            outline: none;
            background: var(--surface);
            color: var(--ink);
            font: inherit;
            resize: vertical;

            &:focus {
                border-color: var(--purple);
                box-shadow: 0 0 0 3px color-mix(in srgb, var(--purple) 10%, transparent);
            }
        }

    }
}

.labelAction {
    justify-self: start;
    padding: 0;
    border: 0;
    color: var(--purple);
    background: $transparent;
    font: inherit;
    font-size: 12px;
    font-weight: 700;
    cursor: pointer;
}

.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 18px;
}
</style>
