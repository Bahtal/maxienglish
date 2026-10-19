<script>
import { onBeforeUnmount, onMounted } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';
import { useBottomSheetDrag } from '../../composables/useBottomSheetDrag.js';
import { acquireTelegramSwipeLock } from '../../utils/telegramSwipeLock.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  
  setup(props, { emit }) {
    const view = useWorkspaceView(props, emit);
    let releaseTelegramSwipeLock = null;
    const sheetDrag = useBottomSheetDrag(() => {
        view.state.notificationOpen = false;
    });

    onMounted(() => {
        releaseTelegramSwipeLock = acquireTelegramSwipeLock();
    });

    onBeforeUnmount(() => releaseTelegramSwipeLock?.());

    return {
        ...view,
        ...sheetDrag,
    };
  },
};
</script>

<template>
    <div
        :class="$style.notificationLayer"
        @click.self="state.notificationOpen = false"
    >
        <section
            :class="$style.notificationPopover"
            :style="sheetDragStyle"
        >
            <div
                :class="$style.sheetHandle"
                aria-hidden="true"
                @pointerdown="startSheetDrag"
            />
            <div :class="$style.sectionHeading">
                <div>
                    <h2>Уведомления</h2>
                    <p>События и изменения</p>
                </div>
                <button
                    :class="$style.textLink"
                    @click="markNotificationsRead"
                >
                    Прочитать всё
                </button>
            </div>
            <button
                v-for="notice in state.notifications.filter((item) => !item.role || item.role === state.role).slice(0,12)"
                :key="notice.id"
                :class="[$style.notificationItemButton, { [$style.unread]: !notice.read }]"
                @click="openNotification(notice)"
            >
                <span :class="$style.noticeDot"></span>
                <span>
                    <b>{{ notice.title }}</b>
                    <p>{{ notice.body }}</p>
                    <small>{{ notice.time }}</small>
                    <small
                        v-if="notice.outcome"
                        :class="$style.notificationStatus"
                        :data-status="notice.outcome"
                    >
                        {{ ({awaiting:'Ожидает',rescheduled:'Перенесён',cancelled:'Отменён'})[notice.outcome] }}
                    </small>
                </span>
            </button>
            <div
                v-if="!state.notifications.length"
                :class="$style.emptyState"
            >
                <b>Новых уведомлений нет</b>
            </div>
        </section>
    </div>
</template>

<style lang="scss" module>
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

        @include text(px2);
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);
    }
}

.textLink {
    display: flex;
    flex-direction: row;
    justify-content: flex-start;
    align-items: center;
    padding: 4px 0;
    border: 0;
    color: var(--purple) !important;
    background: $transparent;
    font-size: 10px !important;
    font-weight: 500 !important;
    cursor: pointer;
    white-space: nowrap;

    svg {
        width: 14px;
        height: 14px;
        transform: rotate(0deg);
        fill: currentColor;
        transition: all .3s ease;
    }

    &:hover {
        svg {
            transform: rotate(0deg) translateX(3px);
        }
    }
}

.sectionHeading {
    > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
    }
}

.emptyState {
    padding: $padding;

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
        padding: $padding-mobile;
    }
}

[data-theme=darked] {
    .emptyState {
        b {
            color: var(--ink);
        }
    }
}

.noticeDot {
    width: 8px;
    height: 8px;
    flex: 0 0 8px;
    margin-top: 5px;
    border-radius: 50%;
    background: var(--purple);
}

.notificationStatus {
    margin-left: auto;
    margin-top: 6px;
    padding: 4px 8px;
    border-radius: 999px;
    color: var(--purple);
    background: var(--purple-pale);
    font-size: 8px;
    font-weight: 700;
    &[data-status=rescheduled] {
        color: var(--green);
        background: var(--mint);
    }

    &[data-status=cancelled] {
        color: var(--red);
        background: color-mix(in srgb, var(--red) 10%, var(--surface));
    }
}

.notificationPopover {
    position: absolute;
    top: calc(100% + 12px);
    right: 0;
    z-index: 30;
    width: min(390px, 100vw - 24px);
    max-height: min(70vh, 620px);
    overflow: auto;
    padding: $padding-mobile;
    border: 1px solid var(--line);
    border-radius: $radius;
    background: var(--surface);
    box-shadow: 0 20px 70px rgba($ink, 0.18);
}

.notificationLayer {
    display: contents;
}

.sheetHandle {
    display: none;
}

[data-theme=darked] {
    .notificationPopover {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);
    }

    .notificationItemButton {
        color: var(--ink);

        &:hover {
            background-color: color-mix(in srgb, var(--ink) 6%, var(--surface));
        }
    }

    .notificationStatus {
        color: $dark-purple-dark;
        background: $dark-purple-pale;

        &[data-status=rescheduled] {
            color: var(--green);
            background: $dark-mint;
        }

        &[data-status=cancelled] {
            color: var(--red);
            background: color-mix(in srgb, var(--red) 20%, var(--surface));
        }
    }
}

.notificationItemButton {
    border: 0;
    border-radius: 0;
    display: flex;
    width: 100%;
    gap: 12px;
    padding: 12px 8px;
    border-bottom: 1px solid var(--line);
    background: $transparent;
    color: inherit;
    font: inherit;
    text-align: left;
    cursor: pointer;

    p {
        margin: 5px 0;
        color: var(--muted);

        @include text(px2);
    }

    small {
        display: block;
        color: var(--muted);
    }

    &:hover {
        background: var(--surface);
    }

    &:focus-visible {
        outline: 2px solid var(--purple);
        outline-offset: 2px;
    }

    &.unread {
        .noticeDot {
            opacity: 1;
        }
    }
}

.student {
    --module-placeholder: 0;
}

.teacher {
    --module-placeholder: 0;
}

@include respond-to(mobile) {
    .notificationLayer {
        position: fixed;
        inset: 0;
        z-index: 100;
        display: flex;
        align-items: flex-end;
        overflow: hidden;
        background: rgba($ink, 0.48);
        backdrop-filter: blur(5px);
        opacity: 1;
    }

    .notificationPopover {
        position: relative;
        top: auto;
        right: auto;
        width: 100%;
        max-height: min(90vh, 90dvh);
        overflow: auto;
        padding: 4px $padding-mobile calc($padding-mobile + var(--device-safe-bottom));
        border-radius: 20px 20px 0 0;
        box-shadow: 0 -14px 48px rgba($ink, 0.2);
        overscroll-behavior: contain;
        transform: translate3d(0, var(--sheet-drag-offset, 0px), 0);
        transition: transform 0.32s cubic-bezier(0.22, 1, 0.36, 1);
        will-change: transform;
    }

    .sheetHandle {
        position: sticky;
        top: 0;
        z-index: 1;
        display: block;
        width: 48px;
        height: 28px;
        margin: 0 auto 6px;
        background: var(--surface);
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

    :global(.mobile-sheet-enter-active).notificationLayer,
    :global(.mobile-sheet-leave-active).notificationLayer {
        transition: opacity 0.32s ease;
    }

    :global(.mobile-sheet-enter-from).notificationLayer,
    :global(.mobile-sheet-appear-from).notificationLayer,
    :global(.mobile-sheet-leave-to).notificationLayer {
        opacity: 0;
    }

    :global(.mobile-sheet-enter-from) .notificationPopover,
    :global(.mobile-sheet-appear-from) .notificationPopover,
    :global(.mobile-sheet-leave-to) .notificationPopover {
        transform: translate3d(0, 100%, 0);
    }

    :global(.mobile-sheet-enter-to) .notificationPopover,
    :global(.mobile-sheet-appear-to) .notificationPopover {
        transform: translate3d(0, 0, 0);
    }
}
</style>
