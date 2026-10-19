<script>
import { useWorkspaceView } from '../composables/useWorkspaceView.js';

import AppButton from '../components/AppButton.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton },
  setup(props, { emit }) {
    return useWorkspaceView(props, emit);
  },
};
</script>

<template>
    <div :class="$style.themeSelectorPage">
        <AppButton
            :class="$style.themeSelectorBack"
            variant="ghost"
            size="small"
            @click="closeThemes"
        >
            ← Назад
        </AppButton>
        <div :class="$style.themeSelectorToolbar">
            <p>Выберите оформление. Оно сразу применится к приложению и сохранится в вашем профиле.</p>
        </div>
        <div :class="$style.themeOptionGrid">
            <button
                v-for="theme in themeOptions"
                :key="theme.id"
                :class="[$style.themeOption, [{ [$style.selected]: state.themeId === theme.id }, (theme.id === 'darked' ? $style.themePreviewDarked : $style.themePreviewDefault)]]"
                :aria-pressed="state.themeId === theme.id"
                @click="setTheme(theme.id)"
            >
                <span :class="$style.themeOptionCopy">
                    <span>
                        <b>{{ theme.name }}</b>
                        <small>{{ theme.description }}</small>
                    </span>
                    <span
                        v-if="state.themeId === theme.id"
                        :class="$style.themeCurrent">Выбрана</span>
                </span>
                <span :class="$style.themeOptionSwatches">
                    <i
                        v-for="color in theme.colors"
                        :key="color"
                        :class="$style.themeSwatch"
                        :style="{ backgroundColor: color }"></i>
                </span>
            </button>
        </div>
    </div>
</template>

<style lang="scss" module>
.themePreviewDefault {
    @include apply-theme-preview(default);

    color: var(--preview-text);
    background: var(--preview-background);
    border-color: var(--preview-border);
}

.themePreviewDarked {
    @include apply-theme-preview(darked);

    color: var(--preview-text);
    background: var(--preview-background);
    border-color: var(--preview-border);
}

.themeSelectorPage {
    display: grid;
    gap: 8px;

    .themeSelectorBack {
        width: fit-content;
        min-height: fit-content;
        padding: 0;
    }
}

.themeSelectorToolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    margin-bottom: 8px;
    padding: 16px;
    border: 1px solid var(--line);
    border-radius: $radius;
    background: var(--surface);

    button {
        white-space: nowrap;
    }

    p {
        max-width: 600px;
        margin: 0;
        color: var(--muted);
        @include text(px2);
        line-height: 1.6;
    }
}

.themeOptionGrid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 290px), 1fr));
    gap: 16px;
}

.themeOption {
    min-width: 0;
    padding: $padding;
    display: grid;
    gap: 8px;
    border: 1px solid var(--line);
    border-radius: $radius;
    color: var(--ink);
    background: var(--surface);
    box-shadow: var(--shadow);
    text-align: left;
    cursor: pointer;
    transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;

    &:hover {
        transform: translateY(-3px);
        border-color: color-mix(in srgb, var(--purple) 48%, var(--line));
        box-shadow: 0 20px 45px color-mix(in srgb, var(--muted) 12%, transparent);
    }

    &.selected {
        border: 1px solid var(--purple);
    }

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.themePreview {
    min-height: 205px;
    display: grid;
    grid-template-rows: 19px 31px 65px 1fr 15px;
    gap: 8px;
    overflow: hidden;
    border: 1px solid $transparent;
}

.themePreviewTop {
    display: flex;
    align-items: center;
    gap: 6px;

    i:first-child {
        width: 15px;
        height: 15px;
        border-radius: 6px;
        background: linear-gradient(145deg, var(--purple), var(--purple-dark));
    }

    b {
        @include text(px2);
        letter-spacing: -0.3px;
    }

    i:last-child {
        width: 12px;
        height: 12px;
        margin-left: auto;
        border-radius: 50%;
        background: var(--preview-purple);
    }
}

.themePreviewGreeting {
    display: flex;
    align-items: flex-end;
    gap: 5px;

    i {
        width: 20px;
        height: 4px;
        margin-bottom: 3px;
        border-radius: 4px;
        background: var(--preview-purple);
    }

    b {
        font-size: 14px;
    }
}

.themePreviewBalance {
    padding: 10px 12px;
    display: grid;
    grid-template-columns: 1fr auto;
    align-content: center;
    gap: 4px 8px;
    border-radius: $radius-mini;
    color: $white;
    background: linear-gradient(115deg, var(--purple-dark), var(--purple));

    small {
        grid-column: 1;
        color: rgba($white, 0.75);
        @include text(px2);
        letter-spacing: 0.7px;
    }

    b {
        grid-column: 1;
        font-size: 13px;
    }

    i {
        width: 28px;
        height: 28px;
        grid-column: 2;
        grid-row: 1/3;
        align-self: center;
        border: 1px solid rgba($white, 0.35);
        border-radius: 50%;
        background: rgba($white, 0.15);
    }
}

.themePreviewCard {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    padding: 0 10px;
    border: 1px solid color-mix(in srgb, var(--muted) 18%, transparent);
    border-radius: 9px;
    background: var(--preview-surface);

    i {
        height: 5px;
        border-radius: 5px;
        background: color-mix(in srgb, currentColor 18%, $transparent);
    }

    i {
        &:first-child {
            width: 42%;
        }

        &:nth-child(2) {
            width: 23%;
        }

        &:last-child {
            width: 12%;
            background: var(--preview-purple);
        }
    }
}

.themePreviewNav {
    display: flex;
    align-items: center;
    justify-content: space-around;
    border-radius: 6px;
    background: var(--preview-surface);

    i {
        width: 14px;
        height: 3px;
        border-radius: 4px;
        background: color-mix(in srgb, currentColor 24%, $transparent);
    }

    i {
        &:first-child {
            background: var(--preview-purple);
        }
    }
}

.themeOptionCopy {
    min-width: 0;
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 12px;

    > span:first-child {
        min-width: 0;
    }

    b {
        display: block;
        @include text(px2);
    }

    small {
        display: block;
        margin-top: 4px;
        color: var(--muted);
        @include text(px2);
        line-height: 1.4;
    }
}

.themeCurrent {
    flex: 0 0 auto;
    padding: 4px 8px;
    border-radius: 999px;
    color: var(--purple);
    background: var(--purple-pale);
    font-weight: 700;

    @include text(px2);
}

.themeOptionSwatches {
    display: flex;
    gap: 6px;
    padding: 0 2px 2px;
}

.themeSwatch {
    width: 20px;
    height: 20px;
    border: 1px solid color-mix(in srgb, var(--muted) 25%, transparent);
    border-radius: $radius-micro;
}

[data-theme=darked] {
    .themeSelectorToolbar {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);
    }

    .themeOption {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);

        &.selected {
            border-color: var(--purple);
        }
    }

}
</style>
