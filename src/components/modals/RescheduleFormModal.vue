<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

import VModalActions from '../VModalActions.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VModalActions },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <form
        :class="$style.formStack"
        @submit.prevent="submitWorkspaceForm($event, 'submitReschedule')">
        <label :class="$style.field">
            <span>Новая дата</span>
            <input
                name="date"
                type="date"
                :min="todayKey()"
                :value="modal.data.date"
                required />
        </label>
        <label :class="$style.field">
            <span>Новое время</span>
            <input
                name="time"
                type="time"
                :value="modal.data.time"
                required />
        </label>
        <VModalActions :class="$style.modalActions">
            <AppButton type="submit">Перенести урок</AppButton>
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
</style>
