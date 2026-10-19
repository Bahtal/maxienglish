<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  
  setup(props, { emit }) {
    return useWorkspaceView(props, emit);
  },
};
</script>

<template>
    <Transition
        :enter-from-class="$style.toastEnterFrom"
        :enter-active-class="$style.toastEnterActive"
        :leave-active-class="$style.toastLeaveActive"
        :leave-to-class="$style.toastLeaveTo">
        <div
            v-if="toast"
            :class="$style.toast"
            role="status">{{ toast }}</div>
    </Transition>
</template>

<style lang="scss" module>
.toast {
    position: fixed;
    z-index: 50;
    bottom: 24px;
    left: 50%;
    transform: translateX(-50%);
    padding: 8px 12px;
    border-radius: $radius-mini;
    color: $white;
    background: var(--purple);
    box-shadow: 0 10px 30px rgba($ink, 0.17);
    white-space: nowrap;
    animation: rise-in 0.18s ease;

    @include text(px2);
}

.toastEnterActive,
.toastLeaveActive {
    transition: opacity 160ms ease, transform 160ms ease;
}

.toastEnterFrom,
.toastLeaveTo {
    opacity: 0;
    transform: translateY(8px);
}
</style>
