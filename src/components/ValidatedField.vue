<script setup>
import { computed, ref, watch } from 'vue';

const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  label: { type: String, required: true },
  name: { type: String, default: '' },
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  autocomplete: { type: String, default: 'off' },
  required: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
  maxLength: { type: Number, default: 250 },
  as: { type: String, default: 'input' },
  rows: { type: Number, default: 4 },
  validator: { type: Function, default: null },
  validationType: { type: String, default: 'text' },
  allowedColors: { type: Array, default: () => [] },
  hint: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue', 'validity']);
const touched = ref(false);
const internalError = computed(() => {
  const value = String(props.modelValue ?? '');
  if (props.required && !value.trim()) return 'Заполните это поле.';
  if (value.length > props.maxLength) return `Не более ${props.maxLength} символов.`;
  if (props.validationType === 'color' && value && !/^#(?:[0-9a-f]{3}|[0-9a-f]{6})$/i.test(value)
    && !props.allowedColors.includes(value)) return 'Укажите корректный цвет.';
  if (props.validator) {
    const result = props.validator(value);
    if (result !== true && result !== undefined && result !== null) return typeof result === 'string' ? result : 'Проверьте значение.';
  }
  return '';
});
const error = computed(() => touched.value ? internalError.value : '');
watch(internalError, (value) => emit('validity', !value));

function update(event) {
  touched.value = true;
  emit('update:modelValue', event.target.value);
}
function blur() {
  touched.value = true;
  emit('validity', !internalError.value);
}
</script>

<template>
    <label :class="$style.field">
        <span :class="$style.label">{{ label }}</span>
        <textarea
            v-if="as === 'textarea'"
            :name="name || undefined"
            :value="modelValue"
            :placeholder="placeholder"
            :maxlength="maxLength"
            :rows="rows"
            :required="required"
            :disabled="disabled"
            :aria-invalid="Boolean(error)"
            :class="$style.control"
            @input="update"
            @blur="blur" />
        <input
            v-else
            :name="name || undefined"
            :type="type"
            :value="modelValue"
            :placeholder="placeholder"
            :maxlength="maxLength"
            :required="required"
            :disabled="disabled"
            :aria-invalid="Boolean(error)"
            :class="$style.control"
            @input="update"
            @blur="blur" />
        <small
            v-if="error"
            :class="$style.error"
            role="alert">{{ error }}</small>
        <small
            v-else-if="hint"
            :class="$style.hint">{{ hint }}</small>
    </label>
</template>

<style lang="scss" module>
.field {
    display: grid;
    gap: 0.45rem;
    min-width: 0;

    .label {
        color: var(--ink);
        font-size: 0.875rem;
        font-weight: 650;
    }

    .control {
        width: 100%;
        min-width: 0;
        min-height: 2.8rem;
        padding: 0.72rem 0.85rem;
        border: 1px solid var(--line);
        border-radius: 0.8rem;
        outline: 0;
        background: var(--surface);
        color: var(--ink);
        font: inherit;
        font-size: 0.95rem;
        transition: border-color 140ms ease, box-shadow 140ms ease;

        &:focus {
            border-color: var(--purple);
            box-shadow: 0 0 0 3px color-mix(in srgb, var(--purple) 12%, transparent);
        }

        &[aria-invalid='true'] {
            border-color: var(--red);
        }

        &:disabled {
            background: var(--canvas);
            color: var(--muted);
        }
    }

    textarea.control {
        min-height: 7rem;
        resize: vertical;
    }

    .error {
        color: var(--red);
        font-size: 0.78rem;
    }

    .hint {
        color: var(--muted);
        font-size: 0.78rem;
    }
}

[data-theme='darked'] {
    .field {
        .label {
            color: var(--ink);
        }

        .control {
            border-color: var(--line);
            background: $dark-surface;
            color: var(--ink);

            &:disabled {
                background: var(--surface);
                color: var(--muted);
            }
        }

        .hint {
            color: var(--muted);
        }
    }
}
</style>
