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
    <div :class="$style.invitation">
        <div :class="$style.successMark" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none">
                <path d="m6 12.5 4 4L18.5 8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
        </div>

        <div :class="$style.description">
            <b>Ссылка готова</b>
            <span>Отправьте её ученику. Он появится в списке после того, как откроет ссылку в Telegram и нажмёт Start.</span>
        </div>

        <label :class="$style.linkField">
            <span>Одноразовая ссылка</span>
            <input
                :value="modal.data?.inviteUrl || ''"
                readonly
                @focus="$event.target.select()" />
        </label>

        <p :class="$style.expiryNote">
            Ссылка действует 7 дней и привязывается к Telegram-аккаунту, который первым её активирует.
        </p>

        <div :class="$style.actions">
            <AppButton
                :class="$style.copyButton"
                @click="copyText(modal.data?.inviteUrl || '', 'Ссылка-приглашение скопирована')">
                Скопировать ссылку
            </AppButton>
            <AppButton
                variant="ghost"
                @click="closeModal">Закрыть</AppButton>
        </div>
    </div>
</template>

<style lang="scss" module>
.invitation {
    display: grid;
    justify-items: center;
    gap: 16px;
    text-align: center;
}

.successMark {
    display: grid;
    width: 48px;
    height: 48px;
    place-items: center;
    border-radius: 16px;
    background: var(--mint);
    color: var(--green);

    svg {
        width: $svg;
        height: $svg;
    }
}

.description {
    display: grid;
    gap: 6px;

    b {
        color: var(--ink);
        font-size: 15px;
    }

    span {
        max-width: 390px;
        color: var(--muted);
        font-size: 12px;
        line-height: 1.5;
    }
}

.linkField {
    display: grid;
    width: 100%;
    gap: 7px;
    text-align: left;

    > span {
        color: var(--muted);
        font-size: 12px;
        font-weight: 650;
    }

    input {
        width: 100%;
        min-width: 0;
        min-height: 46px;
        padding: 10px 12px;
        border: 1px solid var(--line);
        border-radius: 12px;
        outline: none;
        background: var(--canvas);
        color: var(--ink);
        font: 12px/1.4 ui-monospace, SFMono-Regular, Menlo, monospace;
        user-select: all;
    }
}

.expiryNote {
    margin: 0;
    color: var(--muted);
    font-size: 11px;
    line-height: 1.45;
}

.actions {
    display: flex;
    width: 100%;
    flex-wrap: wrap;
    justify-content: center;
    gap: 10px;
    margin-top: 2px;
}

.copyButton {
    min-width: 190px;
}

@include respond-to(mobile) {
    .invitation {
        gap: $gap-sm;
    }

    .copyButton {
        width: 100%;
    }
}
</style>
