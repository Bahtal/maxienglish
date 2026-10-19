<script setup>
import { computed } from 'vue';
import AppButton from '../AppButton.vue';

const props = defineProps({
    workspace: {
        type: Object,
        required: true,
    },
});

const emit = defineEmits(['workspace-action']);
const auth = computed(() => props.workspace.auth);

function authenticateTelegram() {
    emit('workspace-action', { name: 'authenticateTelegram', args: [] });
}
</script>

<template>
    <main :class="$style.authView" :aria-busy="auth.loading">
        <section :class="$style.authCard">
            <div :class="[$style.brand, $style.authBrand]">
                <span :class="$style.brandMark">
                    <svg>
                        <use href="#icon-spark" />
                    </svg>
                </span>
                <span>maxienglish</span>
            </div>

            <template v-if="auth.loading">
                <p :class="$style.eyebrow">TELEGRAM MINI APP</p>
                <span :class="$style.spinner" aria-hidden="true"></span>
                <h1>Подключаем Telegram</h1>
                <p :class="$style.subtitle">Загружаем ваш профиль и расписание.</p>
            </template>

            <template v-else-if="auth.setup">
                <p :class="$style.eyebrow">ПОДКЛЮЧЕНИЕ УЧЕНИКА</p>
                <h1>Профиль пока не привязан</h1>
                <p :class="$style.subtitle">
                    Откройте персональную ссылку-приглашение от преподавателя в Telegram и нажмите
                    <strong>Start</strong> на странице бота. Команда <code>/start</code>, набранная вручную,
                    не передаёт приглашение и не подключает профиль.
                </p>
                <AppButton @click="authenticateTelegram">Проверить профиль</AppButton>
            </template>

            <template v-else>
                <p :class="$style.eyebrow">TELEGRAM MINI APP</p>
                <h1>Не удалось войти</h1>
                <p :class="$style.subtitle">{{ auth.error || 'Проверьте подключение и попробуйте ещё раз.' }}</p>
                <AppButton @click="authenticateTelegram">Повторить подключение</AppButton>
            </template>
        </section>
    </main>
</template>

<style lang="scss" module>
.eyebrow {
    margin: 0 0 5px;
    color: var(--ink);
    font-weight: 700;

    @include text(px3);
}

.spinner {
    display: block;
    width: 2rem;
    height: 2rem;
    margin: 1.25rem 0 0.5rem;
    border: 3px solid color-mix(in srgb, var(--purple) 20%, transparent);
    border-top-color: var(--purple);
    border-radius: 50%;
    animation: spin 700ms linear infinite;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}

.brand {
    display: flex;
    align-items: center;
    gap: 11px;
    padding: 0 13px 38px;
    font-weight: 700;

    @include text(px2);

    span {
        text-shadow: 1px 2px 5px rgba($ink, .5);
    }
}

.brandMark {
    width: $width-block;
    height: $height-block;
    border-radius: $radius-mini;
    background: linear-gradient(145deg, var(--purple), var(--purple-dark));
    display: grid;
    place-items: center;
    color: $white;
    box-shadow: 0 0 7px -3px $ink;
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

.subtitle {
    margin: 0;
    color: var(--muted);
    font-size: 13px;
}

@include respond-to(mobile) {
    .subtitle {
        font-size: 11px;
    }
}

.authView {
    min-height: 100vh;
    min-height: 100dvh;
    display: grid;
    place-items: center;
    padding: $padding;
    background: radial-gradient(circle at 15% 10%, color-mix(in srgb, var(--purple) 34%, transparent), $transparent 34%), radial-gradient(circle at 90% 88%, color-mix(in srgb, var(--green) 42%, transparent), $transparent 32%), var(--canvas);

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.authCard {
    width: min(100%, 460px);
    max-width: calc(100% - ($padding * 2));
    padding: clamp(24px, 6vw, 42px);
    background: linear-gradient(var(--purple) 60%, var(--purple-dark) 100%);
    border: 1px solid color-mix(in srgb, var(--muted) 80%, transparent);
    border-radius: 28px;
    box-shadow: 0 28px 90px color-mix(in srgb, var(--muted) 12%, transparent);
}

.authBrand {
    padding: 0;
    margin-bottom: 34px;
}

.authCard {
    h1 {
        margin: 8px 0 10px;
        font-size: clamp(28px, 7vw, 36px);
        line-height: 1.1;
        letter-spacing: -1.4px;
    }

    > .subtitle {
        margin: 0 0 26px;
        color: var(--muted);
        font-size: 14px;
        line-height: 1.55;
    }
}

[data-theme=darked] {
    .authCard {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);
    }

    .authView {
        background: radial-gradient(circle at 15% 10%, color-mix(in srgb, var(--purple) 18%, transparent), $transparent 34%), radial-gradient(circle at 90% 88%, color-mix(in srgb, var(--green) 12%, transparent), $transparent 32%), var(--canvas);
    }
}
</style>
