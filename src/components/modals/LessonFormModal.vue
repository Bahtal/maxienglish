<script>
import { computed, ref } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';
import { todayKey } from '../../utils/appConfig.js';

import ValidatedField from '../ValidatedField.vue';
import AppButton from '../AppButton.vue';
import CustomSelect from '../CustomSelect.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { CustomSelect, ValidatedField, AppButton },
  setup(props, { emit }) {
    const view = useWorkspaceView(props, emit);
    const selectedStudentId = ref(props.workspace.state.students[0]?.id ?? '');
    const selectedPaymentStatus = ref('paid');
    const lessonTitle = ref('Английский');
    const isHistorical = ref(false);
    const lessonDate = ref(props.workspace.modal.data?.date || todayKey());
    const lessonTime = ref('11:00');
    const studentOptions = computed(() => props.workspace.state.students.map((student) => ({
        value: student.id,
        label: student.name,
    })));
    const paymentOptions = [
        { value: 'paid', label: 'Оплачено' },
        { value: 'awaiting', label: 'Ожидает оплаты' },
        { value: 'unpaid', label: 'Не оплачено' },
    ];

    view.selectedStudentId = selectedStudentId;
    view.selectedPaymentStatus = selectedPaymentStatus;
    view.lessonTitle = lessonTitle;
    view.isHistorical = isHistorical;
    view.lessonDate = lessonDate;
    view.lessonTime = lessonTime;
    view.studentOptions = studentOptions;
    view.paymentOptions = paymentOptions;
    view.submitLessonForm = (event) => {
        const form = new FormData(event.currentTarget);
        const payload = Object.fromEntries(form.entries());

        payload.date = lessonDate.value;
        payload.time = lessonTime.value;
        if (isHistorical.value) {
            payload.historical = 'true';
        } else {
            delete payload.historical;
        }

        emit('workspace-action', { name: 'createLesson', args: [payload] });
    };

    return view;
  },
};
</script>

<template>
    <form
        :class="$style.formStack"
        @submit.prevent="submitLessonForm($event)">
        <div :class="$style.field">
            <span>Ученик</span>
            <CustomSelect
                v-model="selectedStudentId"
                name="studentId"
                :options="studentOptions" />
        </div>
        <ValidatedField
            v-model="lessonTitle"
            name="title"
            label="Предмет или тема"
            :max-length="100"
            required />
        <div :class="$style.formGrid">
            <label :class="$style.field">
                <span>Дата</span>
                <input
                    v-model="lessonDate"
                    name="date"
                    type="date"
                    required />
            </label>
            <label :class="$style.field">
                <span>Время</span>
                <input
                    v-model="lessonTime"
                    name="time"
                    type="time"
                    required />
            </label>
        </div>
        <div :class="$style.field">
            <span>Длительность</span>
            <div :class="$style.settingValue">{{ state.teacher.lessonDurationMinutes }} минут (из настроек профиля)</div>
        </div>
        <label :class="$style.historicalToggle">
            <input
                v-model="isHistorical"
                type="checkbox"
                name="historical"
                value="true" />
            <span>
                <b>Урок уже прошёл</b>
                <small>Занятие попадёт в историю посещаемости и уменьшит остаток оплаченных уроков.</small>
            </span>
        </label>
        <div
            v-if="!isHistorical"
            :class="$style.field">
            <span>Оплата</span>
            <CustomSelect
                v-model="selectedPaymentStatus"
                name="paymentStatus"
                :options="paymentOptions" />
        </div>
        <div :class="$style.modalActions">
            <AppButton
                type="submit"
                :loading="modal.busy"
                :disabled="modal.busy">Сохранить урок</AppButton>
            <AppButton
                variant="ghost"
                @click="closeModal">Отмена</AppButton>
        </div>
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

.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 18px;
}

.settingValue {
    min-height: 38px;
    display: flex;
    align-items: center;
    padding: 0 12px;
    border: 1px solid var(--line);
    border-radius: 11px;
    color: var(--ink);
    background: var(--canvas);
    font-size: 11px;
}

.historicalToggle {
    display: flex;
    align-items: flex-start;
    gap: $gap;
    padding: $padding;
    border: 1px solid var(--line);
    border-radius: $radius;
    background: var(--canvas);
    cursor: pointer;

    @include respond-to(mobile) {
        gap: $gap-sm;
        padding: $padding-mobile;
    }

    > input {
        width: 17px;
        height: 17px;
        flex: 0 0 17px;
        margin: 2px 0 0;
        accent-color: var(--purple);
    }

    > span {
        display: grid;
        gap: 4px;
    }

    b {
        color: var(--ink);
        font-size: 12px;
    }

    small {
        color: var(--muted);
        font-size: 11px;
        line-height: 1.45;
    }
}

[data-theme=darked] {
    .settingValue {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);
    }
}

.formGrid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: $gap;

    @include respond-to(mobile) {
        grid-template-columns: minmax(0, 1fr);

        gap: $gap-sm;
    }
}
</style>
