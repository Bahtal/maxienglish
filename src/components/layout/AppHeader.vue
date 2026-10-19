<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VAvatar from '../VAvatar.vue';
import SegmentedToggle from '../SegmentedToggle.vue';
import NotificationPopover from './NotificationPopover.vue';

export default {
  props: {
      workspace: {
          type: Object,
          required: true,
      },
  },

  emits: ['workspace-action'],

  components: {
      VAvatar,
      SegmentedToggle,
      NotificationPopover,
  },

  setup(props, { emit }) {
    const view = useWorkspaceView(props, emit);

    view.setNotificationAnchor = (element) => {
        props.workspace.notificationRef.value = element;
    };

    return view;
  },
};
</script>

<template>
<header :class="$style.topbar">
    <div :class="$style.mobileBrand">
        <span :class="$style.brandMark">
            <svg>
                <use href="#icon-spark" />
            </svg>
        </span>

        <span>maxienglish</span>
    </div>

    <div :class="$style.headerRight"></div>

    <SegmentedToggle
        v-if="!auth.user"
        :model-value="state.role"
        :options="[{value:'student',label:'Ученик'},{value:'teacher',label:'Учитель'}]"
        aria-label="Режим кабинета"
        @change="changeRole"
    />

    <div :class="$style.rightHeader">
        <button
            :class="$style.themeTrigger"
            type="button"
            aria-label="Выбрать тему"
            @click="openThemes"
        >
            <svg>
                <use href="#icon-palette" />
            </svg>
            <span>Выбрать тему</span>
        </button>

        <div :ref="setNotificationAnchor" :class="$style.notificationAnchor">
            <button
                :class="$style.iconButton"
                type="button"
                aria-label="Уведомления"
                @click="toggleNotifications"
            >
                <svg>
                    <use href="#icon-bell" />
                </svg>
                <span
                    v-if="state.notifications.some((notice) => !notice.read && (!notice.role || notice.role === state.role))"
                    :class="$style.notificationDot"
                >
            </span>
            </button>

            <Transition name="mobile-sheet" appear>
                <NotificationPopover
                    v-if="state.notificationOpen"
                    :workspace="workspace"
                    @workspace-action="$emit('workspace-action', $event)"
                />
            </Transition>
        </div>

        <VAvatar
            :class="[$style.avatar, $style.topAvatar]"
            size="large"
            responsive
            :tone="colorFor(activeProfile.color)"
            radius="mini"
            :src="activeProfile.avatarUrl"
            :name="activeProfile.name"
            alt="AvatarProfile"
        />
    </div>
</header>
</template>

<style lang="scss" module>
.brandMark {
    width: $width-block;
    height: $height-block;
    border-radius: $radius-mini;
    background: linear-gradient(145deg, $purple, $purple-dark);
    display: grid;
    place-items: center;
    color: $white;
    box-shadow: 0 0 22px -7px var(--ink);
    animation: brand 10s infinite linear;

    svg {
        width: $svg;
        height: $svg;
        stroke: currentColor;
        fill: none;
        stroke-width: 1.8;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
}

.topbar {
    height: 94px;
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: $gap;
}

.themeTrigger {
    min-height: $width-block-big;
    min-width: $width-block-big;
    width: 100%;
    height: 100%;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: $gap-sm;
    border: 1px solid var(--border-color);
    border-radius: $radius-mini;
    color: var(--ink);
    background: var(--surface);
    box-shadow: 0 4px 14px rgba($ink, 0.035);
    cursor: pointer;
    font-weight: 700;
    transition: border-color 0.18s ease, transform 0.18s ease, background 0.18s ease;

    @include text(px2);

    @include respond-to(mobile) {
        min-height: $width-block;
        min-width: $width-block;
    }

    svg {
        width: $svg;
        height: $svg;
        stroke: var(--purple);
        fill: none;
        stroke-width: 1.8;
        stroke-linecap: round;
        stroke-linejoin: round;
    }

    &:hover {
        transform: translateY(-1px);
        border-color: var(--purple);
    }
}

.iconButton {
    position: relative;
    width: $width-block-big;
    height: $height-block-big;
    display: grid;
    place-items: center;
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius-mini;
    cursor: pointer;

    svg {
        width: $svg;
        height: $svg;
        stroke: var(--purple);
        fill: none;
        stroke-width: 1.8;
        stroke-linecap: round;
        stroke-linejoin: round;
    }

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
    }
}

.notificationDot {
    position: absolute;
    right: 8px;
    top: 7px;
    width: 7px;
    height: 7px;
    background: var(--red);
    border: 1px solid $white;
    border-radius: 50%;
}
.topAvatar {
    --module-placeholder: 0;
}
.mobileBrand {
  display: none;
}

@include respond-to(mobile) {
  .topbar {
    height: 52px;
    justify-content: space-between;
    gap: $gap-sm;
  }
  .mobileBrand {
    display: flex;
    align-items: center;
    gap: $gap-sm;
    font-weight: 700;
    letter-spacing: -0.5px;

    @include text(px2);

      .brandMark {
          width: $width-block;
          height: $height-block;
          border-radius: $radius-mini;

          svg {
              width: $svg;
              height: $svg;
          }
      }
  }

  .themeTrigger {
    width: $width-block-big;
    min-height: $height-block-big;
    flex: 0 0 $width-block-big;
    margin-left: 0;
    padding: 0;
    gap: 0;
    border-radius: $radius-mini;

      span {
          display: none;
      }

      svg {
          width: $svg;
          height: $svg;
      }

      @include respond-to(mobile) {
          width: $width-block;
          min-height: $height-block;
          flex: 0 0 $width-block;
      }
  }

  .iconButton {
    width: $width-block-big;
    height: $height-block-big;
    border-radius: $radius-mini;

      @include respond-to(mobile) {
          width: $width-block;
          height: $height-block;
      }
  }
  .topAvatar {
    display: none;
  }
}

.notificationAnchor {
    position: relative;
}
.avatar {
    color: var(--surface);
    font-weight: 300;
}

[data-theme=darked] {
    .iconButton {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);
    }

    .themeTrigger {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);
    }

    .iconButton svg {
        color: var(--ink);
    }

}

.headerRight {
    --module-placeholder: 0;
}
.rightHeader {
    --module-placeholder: 0;
    display: flex;
    flex-flow: row nowrap;
    align-items: center;
    gap: $gap-sm;
}
.student {
    --module-placeholder: 0;
}
.teacher {
    --module-placeholder: 0;
}

</style>
