<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <form
        :class="$style.formStack"
        @submit.prevent="submitWorkspaceForm($event, 'createStudent')">
        <p :class="$style.description">
            Создайте ссылку и отправьте её ученику. Его имя и Telegram-профиль добавятся после нажатия Start.
            Ссылку на доску и начальный баланс занятий можно указать в карточке ученика после подключения.
        </p>
        <p
            v-if="modal.error"
            :class="$style.formError"
            role="alert">{{ modal.error }}</p>
        <div :class="$style.modalActions">
            <AppButton
                type="submit"
                :loading="modal.busy"
                :disabled="modal.busy">Создать ссылку</AppButton>
            <AppButton
                variant="ghost"
                :disabled="modal.busy"
                @click="closeModal">Отмена</AppButton>
        </div>
    </form>
</template>

<style lang="scss" module>
.formStack {
    display: grid;
    gap: 16px;
}

.description {
    margin: 0;
    color: var(--muted);
    font-size: 13px;
    line-height: 1.55;
}

.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 18px;
}

.formError {
    margin: 0;
    padding: 11px 12px;
    border: 1px solid color-mix(in srgb, var(--red) 28%, transparent);
    border-radius: 11px;
    background: color-mix(in srgb, var(--red) 8%, var(--surface));
    color: var(--red);
    font-size: 12px;
    line-height: 1.45;
}
</style>
