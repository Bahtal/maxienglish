<script>
import { onBeforeUnmount, watch } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';
import { useBottomSheetDrag } from '../../composables/useBottomSheetDrag.js';
import { acquireTelegramSwipeLock } from '../../utils/telegramSwipeLock.js';

import HomeworkDetailsModal from '../modals/HomeworkDetailsModal.vue';
import LessonFormModal from '../modals/LessonFormModal.vue';
import RescheduleFormModal from '../modals/RescheduleFormModal.vue';
import CancelConfirmModal from '../modals/CancelConfirmModal.vue';
import DeletePastLessonModal from '../modals/DeletePastLessonModal.vue';
import LessonDetailsModal from '../modals/LessonDetailsModal.vue';
import HomeworkFormModal from '../modals/HomeworkFormModal.vue';
import StudentFormModal from '../modals/StudentFormModal.vue';
import StudentInvitationModal from '../modals/StudentInvitationModal.vue';
import PaymentRequestModal from '../modals/PaymentRequestModal.vue';
import PaymentHistoryModal from '../modals/PaymentHistoryModal.vue';
import StudentDetailsModal from '../modals/StudentDetailsModal.vue';
import TeacherPublicProfileModal from '../modals/TeacherPublicProfileModal.vue';
import TeacherSettingsModal from '../modals/TeacherSettingsModal.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: {
      HomeworkDetailsModal,
      LessonFormModal,
      RescheduleFormModal,
      CancelConfirmModal,
      DeletePastLessonModal,
      LessonDetailsModal,
      HomeworkFormModal,
      StudentFormModal,
      StudentInvitationModal,
      PaymentRequestModal,
      PaymentHistoryModal,
      StudentDetailsModal,
      TeacherPublicProfileModal,
      TeacherSettingsModal,
  },

  setup(props, { emit }) {
      const view = useWorkspaceView(props, emit);
      const sheetDrag = useBottomSheetDrag(() => view.closeModal());
      let releaseTelegramSwipeLock = null;

      watch(() => Boolean(props.workspace.modal.type), (isOpen) => {
          if (isOpen && !releaseTelegramSwipeLock) {
              releaseTelegramSwipeLock = acquireTelegramSwipeLock();
          }
      }, { immediate: true });

      function handleAfterLeave() {
          sheetDrag.resetSheetDrag();
          releaseTelegramSwipeLock?.();
          releaseTelegramSwipeLock = null;
      }

      onBeforeUnmount(() => {
          releaseTelegramSwipeLock?.();
          releaseTelegramSwipeLock = null;
      });

      return { ...view, ...sheetDrag, handleAfterLeave };
  },
};
</script>

<template>
    <Transition
        name="mobile-sheet"
        appear
        @before-enter="resetSheetDrag"
        @after-leave="handleAfterLeave"
    >
        <div
            v-if="modal.type"
            :class="$style.modalBackdrop"
            @click.self="closeModal"
        >
            <section
                :class="[$style.modal, { [$style.wide]: ['homework','payment-history','teacher-view','student'].includes(modal.type) }]"
                :style="sheetDragStyle"
                role="dialog"
                aria-modal="true"
                :aria-label="modal.title"
            >
                <div
                    :class="$style.sheetHandle"
                    aria-hidden="true"
                    @pointerdown="startSheetDrag"
                />
                <header :class="$style.modalHead">
                    <div>
                        <h2>{{ modal.title }}</h2>
                        <p v-if="modal.subtitle">{{ modal.subtitle }}</p>
                    </div>
                    <button
                        :class="$style.closeButton"
                        aria-label="Закрыть"
                        @click="closeModal"
                    >
                        <svg>
                            <use href="#icon-plus" />
                        </svg>
                    </button>
                </header>
                <div :class="$style.modalBody">
                    <HomeworkDetailsModal
                        v-if="modal.type === 'homework'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <LessonFormModal
                        v-else-if="modal.type === 'lesson-form'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <RescheduleFormModal
                        v-else-if="modal.type === 'reschedule'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <CancelConfirmModal
                        v-else-if="modal.type === 'cancel-confirm'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <DeletePastLessonModal
                        v-else-if="modal.type === 'delete-past-lesson'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <LessonDetailsModal
                        v-else-if="modal.type === 'lesson'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <HomeworkFormModal
                        v-else-if="modal.type === 'homework-form'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <StudentFormModal
                        v-else-if="modal.type === 'student-form'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <StudentInvitationModal
                        v-else-if="modal.type === 'student-invitation'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <PaymentRequestModal
                        v-else-if="modal.type === 'payment'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <PaymentHistoryModal
                        v-else-if="modal.type === 'payment-history'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <StudentDetailsModal
                        v-else-if="modal.type === 'student'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <TeacherPublicProfileModal
                        v-else-if="modal.type === 'teacher-view'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                    <TeacherSettingsModal
                        v-else-if="modal.type === 'teacher-settings'"
                        :workspace="workspace"
                        @workspace-action="$emit('workspace-action', $event)"
                    />
                </div>
            </section>
        </div>
    </Transition>
</template>

<style lang="scss" module>
.modalBackdrop {
    position: fixed;
    inset: 0;
    z-index: 100;
    display: grid;
    place-items: center;
    overflow-y: auto;
    overscroll-behavior: contain;
    background: rgba($ink, 0.48);
    backdrop-filter: blur(5px);
    animation: fade-in 0.15s ease;

    @include respond-to(mobile) {
        display: flex;
        align-items: flex-end;
        justify-content: center;
        overflow: hidden;
        animation: none;
        opacity: 1;
        transition: opacity 0.32s ease;
    }
}

.modal {
    width: min(100%, 540px);
    max-height: min(90vh, 900px);
    overflow: auto;
    overscroll-behavior: contain;
    border-radius: $radius;
    padding: $padding;
    background: var(--surface);
    box-shadow: 0 26px 90px rgba($ink, 0.28);
    animation: rise-in 0.19s ease;

    &.wide {
        width: min(640px, 100%);
    }

    .sheetHandle {
        display: none;
    }

    .modalHead {
        position: sticky;
        top: 0;
        z-index: 1;
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 18px;
        margin-bottom: 20px;
        border-bottom: 1px solid var(--line);
        background: var(--surface);

        h2 {
            margin: 0;
            font-weight: 700;

            @include text(px1);

            @include respond-to(mobile) {
                @include text(px1_5);
            }
        }

        p {
            margin: 5px 0 0;
            color: var(--muted);

            @include text(px2);

            @include respond-to(mobile) {
                @include text(px3);
            }
        }
    }

    .closeButton {
        width: 36px;
        height: 36px;
        display: grid;
        place-items: center;
        border: 0;
        border-radius: 10px;
        background: var(--canvas);
        color: var(--muted);
        font-size: 23px;
        line-height: 1;
        cursor: pointer;

        svg {
            width: $svg;
            height: $svg;
            fill: none;
            stroke: currentColor;
            transform: rotate(45deg);
        }
    }

    .modalBody {
        padding: $padding;
    }

    @include respond-to(mobile) {
        position: relative;
        width: 100%;
        max-width: none;
        max-height: min(90vh, 90dvh);
        margin: 0;
        border-radius: $radius $radius 0 0;
        padding: 4px $padding-mobile calc($padding-mobile + var(--device-safe-bottom));
        overflow-y: auto;
        box-shadow: 0 -14px 48px rgba($canvas, 0.08);
        animation: none;
        transform: translate3d(0, var(--sheet-drag-offset, 0px), 0);
        transition: transform 0.32s cubic-bezier(0.22, 1, 0.36, 1);
        will-change: transform;

        &.wide {
            width: 100%;
        }

        .sheetHandle {
            position: relative;
            display: block;
            width: 48px;
            height: 28px;
            margin: 0 auto 6px;
            touch-action: none;
            user-select: none;
            -webkit-user-select: none;
            cursor: grab;

            &::before {
                position: absolute;
                top: 10px;
                left: 50%;
                width: 38px;
                height: 4px;
                border-radius: 999px;
                background: var(--muted);
                content: "";
                opacity: 0.48;
                transform: translateX(-50%);
            }

            &:active {
                cursor: grabbing;
            }
        }

        .modalHead {
            padding: 0 0 14px;
        }

        .modalBody {
            padding: 0;
        }
    }
}

@include respond-to(mobile) {
    :global(.mobile-sheet-enter-active).modalBackdrop,
    :global(.mobile-sheet-leave-active).modalBackdrop {
        transition: opacity 0.32s ease;
    }

    :global(.mobile-sheet-enter-from).modalBackdrop,
    :global(.mobile-sheet-leave-to).modalBackdrop {
        opacity: 0;
    }

    :global(.mobile-sheet-enter-from) .modal,
    :global(.mobile-sheet-appear-from) .modal,
    :global(.mobile-sheet-leave-to) .modal {
        transform: translate3d(0, 100%, 0);
    }

    :global(.mobile-sheet-enter-to) .modal,
    :global(.mobile-sheet-appear-to) .modal {
        transform: translate3d(0, 0, 0);
    }
}

[data-theme=darked] {
    .modal {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);

        .modalHead h2 {
            color: var(--ink);
        }
    }

    .closeButton {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--line);
    }
}
</style>
