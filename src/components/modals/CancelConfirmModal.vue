<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

import VModalActions from '../VModalActions.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: {
      AppButton,
      VModalActions,
  },
  setup(props, { emit }) {
      return useWorkspaceView(props, emit);
  },
};
</script>

<template>
    <div :class="$style.cancelConfirm">
        <p>Оплаченный урок останется на балансе ученика. Ученик получит уведомление об отмене.</p>
        <VModalActions :class="$style.modalActions">
            <AppButton
                variant="danger"
                @click="changeLesson('cancel', modal.data)"
            >
                Да, отменить урок
            </AppButton>

            <AppButton
                variant="ghost"
                @click="closeModal"
            >
                Оставить в расписании
            </AppButton>
        </VModalActions>
    </div>
</template>

<style lang="scss" module>
.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 18px;
}

.cancelConfirm {
    > p {
        margin: 0;
        color: var(--muted);
        line-height: 1.65;
    }
}
</style>
