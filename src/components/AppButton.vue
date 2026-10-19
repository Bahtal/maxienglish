<script setup>
import { computed } from 'vue';

const props = defineProps({
  type: { type: String, default: 'button' },
  variant: { type: String, default: 'primary' },
  size: { type: String, default: 'normal' },
  color: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  loading: { type: Boolean, default: false },
  ariaLabel: { type: String, default: '' },
});
const emit = defineEmits(['click']);

const safeColor = computed(() => ['violet', 'blue', 'mint', 'amber', 'red'].includes(props.color) ? props.color : '');
</script>

<template>
    <button
        :type="type"
        :disabled="disabled || loading"
        :aria-label="ariaLabel || undefined"
        :aria-busy="loading || undefined"
        :class="$style.button"
        :data-variant="variant"
        :data-size="size"
        :data-color="safeColor || undefined"
        @click="emit('click', $event)">
        <span
            v-if="loading"
            :class="$style.spinner"
            aria-hidden="true"></span>
        <slot />
    </button>
</template>

<style lang="scss" module>
.button {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    min-height: 32px;
    padding: 4px 8px;
    border: 1px solid $transparent;
    border-radius: $radius-micro;
    background: var(--purple);
    color: $white;
    font: inherit;
    font-weight: 700;
    line-height: 1.15;
    cursor: pointer;
    transition: background-color 160ms ease, border-color 160ms ease, transform 160ms ease, opacity 160ms ease;

    &:hover:not(:disabled) {
        transform: translateY(-1px);
    }

    &:disabled {
        cursor: not-allowed;
        opacity: 0.56;
    }

    &[data-variant='secondary'] {
        background: var(--purple-pale);
        color: var(--purple-dark);
    }

    &[data-variant='outline'] {
        border-color: var(--purple);
        background: $transparent;
        color: var(--purple);
    }

    &[data-variant='ghost'] {
        background: $transparent;
        color: var(--muted);
    }

    &[data-variant='danger'] {
        background: color-mix(in srgb, var(--red) 10%, var(--surface));
        color: var(--red);
    }

    &[data-variant='white'] {
        background: var(--surface);
        color: var(--purple-dark);
    }

    &[data-size='small'] {
        min-height: 32px;
        padding: 4px 8px;
        border-radius: $radius-mini;

        @include text(px2);

        @include respond-to(mobile) {
            @include text(px4);
        }
    }

    &[data-size='large'] {
        min-height: 3.15rem;
        padding: 0.85rem 1.25rem;
    }

    &[data-color='blue'] {
        background: var(--purple);
    }

    &[data-color='mint'] {
        background: var(--green);
    }

    &[data-color='amber'] {
        background: var(--amber);
    }

    &[data-color='red'] {
        background: var(--red);
    }
}

[data-theme='darked'] {
    .button {
        &[data-variant='secondary'] {
            background: $dark-purple-pale;
            color: $dark-purple-dark;
        }

        &[data-variant='outline'] {
            border-color: var(--line);
            color: var(--ink);
        }

        &[data-variant='ghost'] {
            color: var(--muted);
        }

        &[data-variant='white'] {
            background: var(--surface);
            color: $dark-purple-dark;
        }

        &[data-variant='primary'] {
            color: var(--canvas);
        }
    }
}

.spinner {
    width: 1rem;
    height: 1rem;
    border: 2px solid currentColor;
    border-right-color: $transparent;
    border-radius: 50%;
    animation: spin 700ms linear infinite;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}
</style>
