<script>
import { computed, onUnmounted, ref, watch } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';
import VIcon from '../VIcon.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action', 'page-navigate'],
  components: { VIcon },
    setup(props, { emit }) {
        const workspace = useWorkspaceView(props, emit);
        const studentItems = [
            { page: 'home', label: 'Главная', icon: 'home' },
            { page: 'payments', label: 'Оплата', icon: 'wallet' },
            { page: 'homework', label: 'Домашка', icon: 'book' },
            { page: 'calendar', label: 'Календарь', icon: 'calendar' },
            { page: 'profile', label: 'Профиль', icon: 'user' },
        ];
        const teacherItems = [
            { page: 'home', label: 'Ученики', icon: 'users' },
            { page: 'payments', label: 'Оплата', icon: 'wallet' },
            { page: 'homework', label: 'ДЗ', icon: 'book' },
            { page: 'calendar', label: 'Календарь', icon: 'calendar' },
            { page: 'profile', label: 'Профиль', icon: 'user' },
        ];

        const navItems = computed(() => workspace.state.role === 'student' ? studentItems : teacherItems);

        const isActive = (item) => workspace.state.page === item.page
            || (workspace.state.page === 'students' && item.page === 'home');

        const activeNavShift = computed(() => {
            const activeIndex = navItems.value.findIndex(isActive);
            const offset = Math.max(activeIndex, 0);

            return offset === 0 ? '0px' : `calc(${offset * 100}% + ${offset * 4}px)`;
        });

        function navigateToItem(item) {
            const activeIndex = navItems.value.findIndex(isActive);
            const targetIndex = navItems.value.findIndex((navItem) => navItem.page === item.page);

            if (activeIndex >= 0 && targetIndex !== activeIndex) {
                emit('page-navigate', targetIndex > activeIndex ? 'forward' : 'backward');
            }

            workspace.go(item.page);
        }

        const indicatorStretched = ref(false);
        let indicatorFrame = 0;
        let indicatorTimer = 0;

        watch(activeNavShift, () => {
            window.cancelAnimationFrame(indicatorFrame);
            window.clearTimeout(indicatorTimer);
            indicatorStretched.value = false;

            indicatorFrame = window.requestAnimationFrame(() => {
                indicatorStretched.value = true;
                indicatorTimer = window.setTimeout(() => {
                    indicatorStretched.value = false;
                }, 300);
            });
        });

        onUnmounted(() => {
            window.cancelAnimationFrame(indicatorFrame);
            window.clearTimeout(indicatorTimer);
        });

        return Object.assign(workspace, {
            navItems,
            isActive,
            activeNavShift,
            navigateToItem,
            indicatorStretched,
        });
    },
};
</script>

<template>
    <nav
        :class="[$style.bottomNav, { [$style.stretched]: indicatorStretched }]"
        :style="{ '--active-nav-shift': activeNavShift }"
    >
        <button
            v-for="item in navItems"
            :key="item.page"
            :class="[$style.navItem, { [$style.active]: isActive(item) }]"
            @click="navigateToItem(item)"
        >
            <VIcon
                :class="$style.navIcon"
                :name="item.icon"
                size="nav"
            />
            <span>{{ item.label }}</span>
        </button>
    </nav>
</template>

<style lang="scss" module>
.bottomNav {
    display: none;
}

.navItem {
    appearance: none;
    width: 100%;
    min-width: 0;
    min-height: 47px;
    padding: 0 $padding-mobile;
    display: flex;
    align-items: center;
    gap: 13px;
    border: 0;
    border-radius: $radius-mini;
    background: $transparent;
    color: var(--muted);
    font-family: $font-family;
    font-weight: 700;
    text-align: left;
    cursor: pointer;
    transition: color 0.18s ease;
    border: none;
    margin: 0;
    outline: none;
    -webkit-tap-highlight-color: $transparent;

    @include text(px2);

    &:focus-visible {
        outline: 2px solid var(--purple);
        outline-offset: 2px;
    }

    &.active {
        color: $white;
    }
}

.navIcon {
    color: inherit;
}

@include respond-to(mobile) {
    .bottomNav {
        position: fixed;
        z-index: 15;
        inset: auto 0 0;
        display: grid;
        grid-template-columns: repeat(5, minmax(0, 1fr));
        gap: 4px;
        padding: 8px $radius-mini calc(9px + var(--device-safe-bottom));
        border-top: 1px solid var(--border-color);
        background: var(--surface);
        backdrop-filter: blur(18px);

        &::before {
            content: '';
            position: absolute;
            z-index: 0;
            top: 9px;
            bottom: calc(9px + var(--device-safe-bottom));
            left: $radius-mini;
            width: calc((100% - 40px) / 5);
            border-radius: $radius-mini;
            background: var(--purple-pale);
            opacity: .72;
            transform: translateX(var(--active-nav-shift, 0)) scaleX(1) scaleY(1);
            transform-origin: center;
            transition: all 300ms ease;
            pointer-events: none;
            will-change: transform;
        }

        &.stretched::before {
            transform: translateX(var(--active-nav-shift, 0)) scaleX(.8) scaleY(1.3);
        }

        .navItem {
            position: relative;
            z-index: 1;
            min-height: 53px;
            padding: 4px;
            flex-direction: column;
            justify-content: center;
            gap: 3px;
            font-size: 8px;
            text-align: center;
            -webkit-tap-highlight-color: $transparent;

            &:active {
                background-color: $transparent;
            }

            &.active {
                color: var(--purple);
            }
        }

        .navIcon {
            color: var(--purple);
        }
    }
}

[data-theme='darked'] {
    .bottomNav {
        background: var(--surface);
    }

    .navItem {
        color: var(--purple);

        &.active {
            color: var(--purple);
        }
    }
}

@media (prefers-reduced-motion: reduce) {
    .bottomNav {
        &::before {
            transition: none;
        }

        &.stretched::before {
            transform: translateX(var(--active-nav-shift, 0)) scaleX(1) scaleY(1);
        }
    }
}
</style>
