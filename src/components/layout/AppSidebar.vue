<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VAvatar from '../VAvatar.vue';
import VIcon from '../VIcon.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { VAvatar, VIcon },
    setup(props, { emit }) {
        return useWorkspaceView(props, emit);
    },
};
</script>

<template>
    <aside :class="$style.sidebar">
        <div :class="$style.brand">
            <span :class="$style.brandMark">
                <svg>
                    <use href="#icon-spark" />
                </svg>
            </span>
            <span>maxienglish</span>
        </div>
        <p :class="$style.navCaption">Меню</p>
        <nav :class="$style.navList">
            <button
                v-for="item in (state.role === 'student' ? [{ page:'home',label:'Главная',icon:'home' },{ page:'payments',label:'Оплата',icon:'wallet' },{ page:'homework',label:'Домашка',icon:'book' },{ page:'calendar',label:'Календарь',icon:'calendar' },{ page:'profile',label:'Профиль',icon:'user' }] : [{ page:'home',label:'Ученики',icon:'users' },{ page:'payments',label:'Оплата',icon:'wallet' },{ page:'homework',label:'ДЗ',icon:'book' },{ page:'calendar',label:'Календарь',icon:'calendar' },{ page:'profile',label:'Профиль',icon:'user' }])"
                :key="item.page"
                :class="[$style.navItem, { [$style.active]: state.page === item.page || (state.page === 'students' && item.page === 'home') }]"
                @click="go(item.page)"
            >
                <VIcon
                    :name="item.icon"
                    size="nav"
                />
                <span>{{ item.label }}</span>
            </button>
        </nav>
        <div :class="$style.sidebarBottom">
            <div :class="$style.profileMini">
                <VAvatar
                    size="small"
                    :tone="colorFor(activeProfile.color)"
                    radius="mini"
                    :src="activeProfile.avatarUrl"
                    :name="activeProfile.name"
                />
                <span :class="$style.profileMeta">
                    <b>{{ activeProfile.name }}</b>
                    <small>{{ activeProfile.caption }}</small>
                </span>
            </div>
            <button
                v-if="!auth.user"
                :class="$style.resetButton"
                @click="resetDemo"
            >
                Сбросить демо-данные
            </button>
        </div>
    </aside>
</template>

<style lang="scss" module>
.sidebar {
    position: fixed;
    inset: 0 auto 0 0;
    width: 290px;
    padding: $padding;
    background: var(--surface);
    border-right: 1px solid var(--border-color);
    display: flex;
    flex-direction: column;
    z-index: 5;

    @include respond-to(mobile) {
        display: none;
    }
}

.brand {
    display: flex;
    align-items: center;
    gap: $gap;
    padding: 0 $padding;
    letter-spacing: -0.8px;
    font-weight: 700;

    @include text(px2);
}

.brandMark {
    width: $width-block;
    height: $height-block;
    border-radius: $radius-mini;
    background: linear-gradient(145deg, var(--purple), var(--purple-dark));
    display: grid;
    place-items: center;
    color: $white;
    box-shadow: 0 0 22px var(--purple);
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

.navCaption {
    margin: 32px 0 16px !important;
    padding: 0 $padding;
    color: var(--purple);
    letter-spacing: 1.15px;
    font-weight: 700;
    text-transform: uppercase;

    @include text(px2);
}

.navList {
    display: grid;
    gap: 6px;
}

.navItem {
    appearance: none;
    border: 0;
    border-radius: $radius-mini;
    background: $transparent;
    width: 100%;
    min-height: 47px;
    padding: 0 $padding-mobile;
    display: flex;
    align-items: center;
    gap: 13px;
    color: var(--muted);
    text-align: left;
    cursor: pointer;
    transition: 0.18s ease;

    span {
        font-size: 14px;
        font-weight: 400;
    }

    &:hover {
        color: var(--on-purple-pale);
        background: var(--purple-pale);
    }

    &.active {
        color: var(--on-purple-pale);
        background: var(--purple-pale);
    }
}

.sidebarBottom {
    margin-top: auto;
}

.profileMini {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: $padding-mobile 0;
    border-top: 1px solid var(--line);
}

.profileMeta {
    min-width: 0;
    flex: 1;

    b {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;

        @include text(px2);
    }

    small {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        color: var(--muted);
        font-size: 10px;
    }
}

.resetButton {
    display: block;
    width: calc(100% - 20px);
    margin: 14px 10px 0;
    border: 0;
    padding: 8px 0;
    color: var(--muted);
    background: $transparent;
    text-align: left;
    cursor: pointer;

    @include text(px2);
}

button.active {
    color: $white;
    background: var(--ink);
}

.active {
    border-color: var(--purple);
    color: $white;
    background: var(--purple);
    box-shadow: 0 4px 9px color-mix(in srgb, var(--purple-dark) 17%, transparent)
}

.mint {
    color: var(--green);
    background: var(--mint);
}

[data-theme=darked] {
    .mint {
        color: var(--green);
        background: $dark-mint;
    }

    .sidebar {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);
    }

    .navItem {
        color: var(--ink);

        &:hover {
            background-color: color-mix(in srgb, var(--ink) 6%, var(--surface));
        }
    }

    button.active {
        color: $white;
        background: var(--purple);
    }

    .active {
        color: var(--canvas);
    }

    .navCaption {
        color: var(--muted);
    }

    .resetButton {
        color: var(--muted);
    }
}

.student {
    --module-placeholder: 0;
}

.teacher {
    --module-placeholder: 0;
}
</style>
