<script setup>
const props = defineProps({
  modelValue: { type: [String, Number], required: true },
  options: { type: Array, required: true },
  ariaLabel: { type: String, default: 'Выбор значения' },
  disabled: { type: Boolean, default: false },
});
const emit = defineEmits(['update:modelValue', 'change']);
function select(option) {
  if (props.disabled || option.disabled) return;
  emit('update:modelValue', option.value);
  emit('change', option.value);
}
</script>

<template>
    <div
        :class="$style.toggle"
        role="group"
        :aria-label="ariaLabel">
        <button
            v-for="option in options"
            :key="option.value"
            type="button"
            :class="[$style.option, { [$style.active]: modelValue === option.value }]"
            :aria-pressed="modelValue === option.value"
            :disabled="disabled || option.disabled"
            @click="select(option)">
            <slot
                name="option"
                :option="option">{{ option.label }}</slot>
        </button>
    </div>
</template>

<style lang="scss" module>
.toggle {
    display: none;
    gap: 0.2rem;
    height: 100%;
    max-height: $width-block;
    padding: 0.25rem;
    border: 1px solid var(--line);
    border-radius: $radius-mini;
    background: var(--purple-dark);
}

.option {
    padding: 4px 8px;
    border: 0;
    border-radius: calc($radius-mini - 4px);
    background: $transparent;
    color: var(--muted);
    font: inherit;
    font-size: 0.875rem;
    font-weight: 700;
    cursor: pointer;
    transition: color 150ms ease, background-color 150ms ease, box-shadow 150ms ease;

    &:hover:not(:disabled) {
        color: var(--muted);
    }

    &:focus-visible {
        outline: 2px solid var(--purple);
        outline-offset: 2px;
    }

    &:disabled {
        cursor: not-allowed;
        opacity: 0.55;
    }
}

[data-theme='darked'] {
    .toggle {
        border-color: var(--line);
        background: var(--purple-dark);
    }

    .option {
        color: var(--muted);

        &:hover:not(:disabled) {
            color: var(--purple-pale);
        }
    }

    .active {
        border-color: var(--purple);
        color: $white;
        background: var(--purple);
        box-shadow: 0 2px 8px rgba($ink, 0.22);
    }
}

.active {
    border-color: var(--purple);
    color: $white;
    background: var(--purple);
    box-shadow: 0 4px 11px color-mix(in srgb, var(--purple) 17%, transparent);
}
</style>
