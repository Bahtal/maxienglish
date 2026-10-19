<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

import VModalActions from '../VModalActions.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VModalActions },
  setup(props, { emit }) {
    return useWorkspaceView(props, emit);
  },
};
</script>

<template>
    <div :class="$style.deletePastLesson">
        <p>Запись исчезнет из календаря и истории занятий. Остаток оплаченных занятий ученика не изменится.</p>
        <VModalActions :class="$style.modalActions">
            <AppButton
                variant="danger"
                :loading="modal.busy"
                @click="deletePastLesson(modal.data)">
                Удалить урок
            </AppButton>
            <AppButton
                variant="ghost"
                :disabled="modal.busy"
                @click="closeModal">
                Не удалять
            </AppButton>
        </VModalActions>
    </div>
</template>

<style lang="scss" module>
.deletePastLesson {
    > p {
        margin: 0;
        color: var(--muted);
        line-height: 1.65;
    }
}

.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 18px;
}
</style>
