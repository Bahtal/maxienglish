<script setup>
import { computed } from 'vue';
import { humanCount } from '../../utils/appConfig.js';

const props = defineProps({
    modelValue: {
        type: Number,
        required: true,
    },
    max: {
        type: Number,
        required: true,
    },
});

const emit = defineEmits(['update:modelValue']);

const maxValue = computed(() => Math.max(
    1,
    Math.min(100, Math.floor(Number(props.max) || 1)),
));
const selectedValue = computed(() => Math.min(
    maxValue.value,
    Math.max(1, Math.floor(Number(props.modelValue) || 1)),
));
const progress = computed(() => selectedValue.value / maxValue.value);
const markerAngle = computed(() => ((selectedValue.value - 0.5) / maxValue.value) * 360);
const progressOffset = computed(() => 439.82 * (1 - progress.value));
const countLabel = computed(() => humanCount(selectedValue.value, 'занятие', 'занятия', 'занятий'));
const markerTransform = computed(() => (
    `rotate(${markerAngle.value}deg) translateY(-68px) rotate(-${markerAngle.value}deg)`
));

function updateValue(value) {
    const nextValue = Math.min(maxValue.value, Math.max(1, Math.round(value)));
    emit('update:modelValue', nextValue);
}

function updateFromPointer(event) {
    const bounds = event.currentTarget.getBoundingClientRect();
    const centerX = bounds.left + bounds.width / 2;
    const centerY = bounds.top + bounds.height / 2;
    const deltaX = event.clientX - centerX;
    const deltaY = event.clientY - centerY;
    const distance = Math.hypot(deltaX, deltaY);

    if (distance < bounds.width * 0.28) {
        return;
    }

    const angleFromTop = (
        Math.atan2(deltaY, deltaX) + Math.PI / 2 + Math.PI * 2
    ) % (Math.PI * 2);
    const selectedIndex = Math.floor((angleFromTop / (Math.PI * 2)) * maxValue.value);
    updateValue(selectedIndex + 1);
}

function onPointerDown(event) {
    if (event.button !== 0) {
        return;
    }

    event.currentTarget.setPointerCapture(event.pointerId);
    updateFromPointer(event);
}

function onPointerMove(event) {
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
        updateFromPointer(event);
    }
}

function onKeydown(event) {
    if (event.key === 'ArrowRight' || event.key === 'ArrowUp') {
        event.preventDefault();
        updateValue(selectedValue.value + 1);
    } else if (event.key === 'ArrowLeft' || event.key === 'ArrowDown') {
        event.preventDefault();
        updateValue(selectedValue.value - 1);
    } else if (event.key === 'Home') {
        event.preventDefault();
        updateValue(1);
    } else if (event.key === 'End') {
        event.preventDefault();
        updateValue(maxValue.value);
    }
}
</script>

<template>
    <div :class="$style.lessonCountPicker">
        <button
            :class="$style.stepButton"
            type="button"
            aria-label="Уменьшить количество занятий"
            :disabled="selectedValue <= 1"
            @click="updateValue(selectedValue - 1)">
            <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M5 12h14" />
            </svg>
        </button>

        <div
            :class="$style.dial"
            role="slider"
            tabindex="0"
            aria-label="Количество занятий"
            aria-valuemin="1"
            :aria-valuemax="maxValue"
            :aria-valuenow="selectedValue"
            :aria-valuetext="`${selectedValue} ${countLabel}`"
            @pointerdown="onPointerDown"
            @pointermove="onPointerMove"
            @keydown="onKeydown">
            <svg
                :class="$style.ring"
                viewBox="0 0 160 160"
                aria-hidden="true">
                <circle
                    :class="$style.ringTrack"
                    cx="80"
                    cy="80"
                    r="70" />
                <circle
                    :class="$style.ringValue"
                    cx="80"
                    cy="80"
                    r="70"
                    :stroke-dashoffset="progressOffset" />
            </svg>

            <span
                :class="$style.marker"
                :style="{ transform: markerTransform }"
                aria-hidden="true" />

            <span :class="$style.countValue" aria-hidden="true">
                <strong>{{ selectedValue }}</strong>
                <small>{{ countLabel }}</small>
            </span>
        </div>

        <button
            :class="$style.stepButton"
            type="button"
            aria-label="Увеличить количество занятий"
            :disabled="selectedValue >= maxValue"
            @click="updateValue(selectedValue + 1)">
            <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M12 5v14M5 12h14" />
            </svg>
        </button>
    </div>
</template>

<style lang="scss" module>
.lessonCountPicker {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 20px;
    padding: 4px 0;
}

.dial {
    position: relative;
    display: grid;
    place-items: center;
    width: 168px;
    height: 168px;
    flex: 0 0 168px;
    border-radius: 50%;
    touch-action: none;
    user-select: none;
    cursor: grab;

    &:active {
        cursor: grabbing;
    }

    &:focus-visible {
        outline: 2px solid var(--purple);
        outline-offset: 4px;
    }
}

.ring {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    overflow: visible;
    transform: rotate(-90deg);
    pointer-events: none;
}

.ringTrack,
.ringValue {
    fill: none;
    stroke-width: 8;
}

.ringTrack {
    stroke: var(--line);
}

.ringValue {
    stroke: var(--purple);
    stroke-dasharray: 439.82;
    stroke-linecap: round;
    transition: stroke-dashoffset 260ms cubic-bezier(0.2, 0.8, 0.2, 1);
}

.marker {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 13px;
    height: 13px;
    margin: -6.5px;
    border: 3px solid var(--surface);
    border-radius: 50%;
    background: var(--purple);
    box-shadow: 0 1px 5px color-mix(in srgb, var(--ink) 20%, transparent);
    transition: transform 260ms cubic-bezier(0.2, 0.8, 0.2, 1);
    pointer-events: none;
}

.countValue {
    display: grid;
    justify-items: center;
    gap: 2px;

    strong {
        color: var(--ink);
        font-size: 42px;
        font-weight: 600;
        font-variant-numeric: tabular-nums;
        line-height: 1;
    }

    small {
        color: var(--muted);
        font-size: 12px;
    }
}

.stepButton {
    display: grid;
    place-items: center;
    width: 38px;
    height: 38px;
    flex: 0 0 38px;
    padding: 0;
    border: 1px solid var(--line);
    border-radius: 50%;
    background: var(--surface);
    color: var(--purple);
    cursor: pointer;
    transition: color 160ms ease, background-color 160ms ease, border-color 160ms ease, transform 160ms ease;

    &:hover:not(:disabled) {
        border-color: var(--purple);
        background: var(--purple);
        color: $white;
        transform: scale(1.06);
    }

    &:focus-visible {
        outline: 2px solid var(--purple);
        outline-offset: 3px;
    }

    &:disabled {
        opacity: 0.42;
        cursor: default;
    }

    svg {
        width: 18px;
        height: 18px;
        fill: none;
        stroke: currentColor;
        stroke-width: 1.8;
        stroke-linecap: round;
    }
}

@media (prefers-reduced-motion: reduce) {
    .ringValue,
    .marker,
    .stepButton {
        transition: none;
    }
}
</style>
