<script setup>
import {
    computed,
    nextTick,
    onBeforeUnmount,
    onMounted,
    ref,
    useId,
    watch,
} from 'vue';
import { useBottomSheetDrag } from '../composables/useBottomSheetDrag.js';
import { acquireTelegramSwipeLock } from '../utils/telegramSwipeLock.js';

const props = defineProps({
    modelValue: {
        type: [String, Number],
        default: '',
    },
    options: {
        type: Array,
        default: () => [],
    },
    name: {
        type: String,
        default: '',
    },
    label: {
        type: String,
        default: '',
    },
    placeholder: {
        type: String,
        default: 'Выберите вариант',
    },
    valueName: {
        type: String,
        default: 'value',
    },
    labelName: {
        type: String,
        default: 'label',
    },
    size: {
        type: String,
        default: 'default',
        validator: (value) => ['default', 'small'].includes(value),
    },
    disabled: Boolean,
});

const emit = defineEmits([
    'update:modelValue',
    'change',
    'open',
    'close',
    'focus',
    'blur',
]);

const root = ref(null);
const trigger = ref(null);
const desktopMenu = ref(null);
const teleportTarget = ref('body');
const isOpen = ref(false);
const isMobile = ref(false);
const activeIndex = ref(-1);
const desktopMenuStyle = ref({});
const componentId = `custom-select-${useId()}`;
let mediaQuery = null;
let previousBodyOverflow = '';
let bodyScrollLocked = false;
let releaseTelegramSwipeLock = null;
const {
    sheetDragStyle,
    startSheetDrag,
    resetSheetDrag,
} = useBottomSheetDrag(() => closeMenu());

const normalizedOptions = computed(() => props.options.map((option) => {
    if (option !== null && typeof option === 'object') {
        return {
            source: option,
            value: option[props.valueName],
            label: String(option[props.labelName] ?? ''),
            disabled: Boolean(option.disabled),
        };
    }

    return {
        source: option,
        value: option,
        label: String(option ?? ''),
        disabled: false,
    };
}));

const selectedOption = computed(() => normalizedOptions.value.find((option) => (
    String(option.value ?? '') === String(props.modelValue ?? '')
)));

const displayValue = computed(() => selectedOption.value?.label || props.placeholder);
const isDisabled = computed(() => props.disabled || !normalizedOptions.value.length);
const activeOptionId = computed(() => (
    activeIndex.value >= 0 ? `${componentId}-option-${activeIndex.value}` : undefined
));

function optionId(index) {
    return `${componentId}-option-${index}`;
}

function firstEnabledIndex(fromEnd = false) {
    const indexes = normalizedOptions.value.map((option, index) => index);
    if (fromEnd) indexes.reverse();

    return indexes.find((index) => !normalizedOptions.value[index].disabled) ?? -1;
}

function selectedEnabledIndex() {
    const index = normalizedOptions.value.findIndex((option) => (
        String(option.value ?? '') === String(props.modelValue ?? '') && !option.disabled
    ));

    return index >= 0 ? index : firstEnabledIndex();
}

function positionDesktopMenu() {
    if (!trigger.value || typeof window === 'undefined') return;

    const bounds = trigger.value.getBoundingClientRect();
    const panelHeight = Math.min(desktopMenu.value?.scrollHeight || 260, window.innerHeight - 24);
    const gap = 8;
    const edge = 12;
    const below = window.innerHeight - bounds.bottom - gap - edge;
    const above = bounds.top - gap - edge;
    const openAbove = below < panelHeight && above > below;
    const left = Math.min(Math.max(bounds.left, edge), window.innerWidth - bounds.width - edge);

    desktopMenuStyle.value = {
        left: `${left}px`,
        width: `${Math.min(bounds.width, window.innerWidth - edge * 2)}px`,
        maxHeight: `${Math.max(120, Math.min(panelHeight, openAbove ? above : below))}px`,
        ...(openAbove
            ? { bottom: `${window.innerHeight - bounds.top + gap}px` }
            : { top: `${Math.min(bounds.bottom + gap, window.innerHeight - edge - 120)}px` }),
    };
}

async function openMenu() {
    if (isDisabled.value || isOpen.value) return;

    isOpen.value = true;
    activeIndex.value = selectedEnabledIndex();
    emit('open');
    await nextTick();

    if (!isMobile.value) positionDesktopMenu();
}

function closeMenu({ restoreFocus = false, emitEvent = true } = {}) {
    if (!isOpen.value) return;

    isOpen.value = false;
    activeIndex.value = -1;

    if (emitEvent) emit('close');
    if (restoreFocus) nextTick(() => trigger.value?.focus());
}

function toggleMenu() {
    if (isOpen.value) {
        closeMenu();
        return;
    }

    openMenu();
}

function selectOption(option) {
    if (option.disabled) return;

    emit('update:modelValue', option.value);
    emit('change', option.value, option.source);
    closeMenu({ restoreFocus: true });
}

function moveActiveOption(direction) {
    const options = normalizedOptions.value;
    if (!options.length) return;

    let index = activeIndex.value;
    for (let attempts = 0; attempts < options.length; attempts += 1) {
        index = (index + direction + options.length) % options.length;
        if (!options[index].disabled) {
            activeIndex.value = index;
            return;
        }
    }
}

function onKeydown(event) {
    if (event.key === 'Escape' && isOpen.value) {
        event.preventDefault();
        closeMenu({ restoreFocus: true });
        return;
    }

    if (event.target !== trigger.value) return;

    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
        event.preventDefault();

        if (!isOpen.value) {
            openMenu();
            return;
        }

        moveActiveOption(event.key === 'ArrowDown' ? 1 : -1);
        return;
    }

    if (event.key === 'Home' && isOpen.value) {
        event.preventDefault();
        activeIndex.value = firstEnabledIndex();
        return;
    }

    if (event.key === 'End' && isOpen.value) {
        event.preventDefault();
        activeIndex.value = firstEnabledIndex(true);
        return;
    }

    if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();

        if (!isOpen.value) {
            openMenu();
        } else if (normalizedOptions.value[activeIndex.value]) {
            selectOption(normalizedOptions.value[activeIndex.value]);
        }

        return;
    }
}

function onOutsidePointerDown(event) {
    if (root.value?.contains(event.target) || desktopMenu.value?.contains(event.target)) return;
    closeMenu({ emitEvent: true });
}

function onViewportChange() {
    if (!isOpen.value) return;

    if (isMobile.value) {
        desktopMenuStyle.value = {};
    } else {
        positionDesktopMenu();
    }
}

function onMediaChange(event) {
    isMobile.value = event.matches;
}

function syncOpenListeners() {
    if (typeof document === 'undefined') return;

    document.removeEventListener('keydown', onKeydown);
    document.removeEventListener('pointerdown', onOutsidePointerDown, true);
    window.removeEventListener('resize', onViewportChange);
    window.removeEventListener('scroll', onViewportChange, true);

    if (bodyScrollLocked) {
        document.body.style.overflow = previousBodyOverflow;
        bodyScrollLocked = false;
    }

    if (!isOpen.value) {
        return;
    }

    document.addEventListener('keydown', onKeydown);

    if (isMobile.value) {
        releaseTelegramSwipeLock ||= acquireTelegramSwipeLock();
        previousBodyOverflow = document.body.style.overflow;
        document.body.style.overflow = 'hidden';
        bodyScrollLocked = true;
    } else {
        releaseTelegramSwipeLock?.();
        releaseTelegramSwipeLock = null;
        document.addEventListener('pointerdown', onOutsidePointerDown, true);
        window.addEventListener('resize', onViewportChange);
        window.addEventListener('scroll', onViewportChange, true);
        nextTick(positionDesktopMenu);
    }
}

function handleMobileSheetAfterLeave() {
    resetSheetDrag();

    if (!isOpen.value || !isMobile.value) {
        releaseTelegramSwipeLock?.();
        releaseTelegramSwipeLock = null;
    }
}

watch([isOpen, isMobile], syncOpenListeners);

watch(() => props.options, (options) => {
    if (!options.length) closeMenu();
    if (isOpen.value && !isMobile.value) nextTick(positionDesktopMenu);
});

watch(isDisabled, (disabled) => {
    if (disabled) closeMenu();
});

onMounted(() => {
    teleportTarget.value = root.value?.closest('[data-theme]') || document.body;
    mediaQuery = window.matchMedia('(max-width: 768px)');
    isMobile.value = mediaQuery.matches;
    mediaQuery.addEventListener?.('change', onMediaChange);
    if (!mediaQuery.addEventListener) mediaQuery.addListener(onMediaChange);
});

onBeforeUnmount(() => {
    isOpen.value = false;
    syncOpenListeners();
    releaseTelegramSwipeLock?.();
    releaseTelegramSwipeLock = null;
    mediaQuery?.removeEventListener?.('change', onMediaChange);
    mediaQuery?.removeListener?.(onMediaChange);
});
</script>

<template>
    <div
        ref="root"
        :class="[$style.customSelect, $style[`_${size}`], { [$style.opened]: isOpen, [$style.disabled]: isDisabled }]"
    >
        <span
            v-if="label"
            :class="$style.label"
        >
            {{ label }}
        </span>

        <button
            ref="trigger"
            :class="$style.trigger"
            type="button"
            role="combobox"
            aria-haspopup="listbox"
            :aria-label="label || placeholder"
            :aria-expanded="isOpen"
            :aria-controls="`${componentId}-listbox`"
            :aria-activedescendant="activeOptionId"
            :aria-disabled="isDisabled"
            :disabled="isDisabled"
            @click="toggleMenu"
            @focus="emit('focus', $event)"
            @blur="emit('blur', $event)"
        >
            <span :class="[$style.value, { [$style.placeholder]: !selectedOption }]">
                {{ displayValue }}
            </span>
            <svg
                :class="$style.chevron"
                viewBox="0 0 20 20"
                aria-hidden="true"
            >
                <path d="m5 7.5 5 5 5-5" />
            </svg>
        </button>

        <input
            v-if="name"
            type="hidden"
            :name="name"
            :value="modelValue"
            :disabled="disabled"
        >

        <Teleport :to="teleportTarget">
            <div
                v-if="isOpen && !isMobile"
                :id="`${componentId}-listbox`"
                ref="desktopMenu"
                :class="$style.desktopMenu"
                :style="desktopMenuStyle"
                role="listbox"
                :aria-label="label || placeholder"
            >
                <button
                    v-for="(option, index) in normalizedOptions"
                    :id="optionId(index)"
                    :key="`${typeof option.value}-${String(option.value)}-${index}`"
                    :class="[$style.option, { [$style.active]: index === activeIndex, [$style.selected]: String(option.value ?? '') === String(modelValue ?? ''), [$style.optionDisabled]: option.disabled }]"
                    type="button"
                    role="option"
                    :aria-selected="String(option.value ?? '') === String(modelValue ?? '')"
                    :disabled="option.disabled"
                    @mouseenter="activeIndex = index"
                    @click="selectOption(option)"
                >
                    <span>{{ option.label }}</span>
                    <svg
                        v-if="String(option.value ?? '') === String(modelValue ?? '')"
                        :class="$style.checkIcon"
                        viewBox="0 0 20 20"
                        aria-hidden="true"
                    >
                        <path d="m4 10 4 4 8-8" />
                    </svg>
                </button>
            </div>

            <Transition
                name="custom-select-sheet"
                appear
                @before-enter="resetSheetDrag"
                @after-leave="handleMobileSheetAfterLeave"
            >
                <div
                    v-if="isOpen && isMobile"
                    :class="$style.mobileBackdrop"
                    @click.self="closeMenu()"
                >
                    <section
                        :class="$style.mobileSheet"
                        :style="sheetDragStyle"
                        role="dialog"
                        aria-modal="true"
                        :aria-label="label || 'Выбор значения'"
                    >
                        <div
                            :class="$style.sheetHandle"
                            aria-hidden="true"
                            @pointerdown="startSheetDrag"
                        />
                        <header :class="$style.sheetHeader">
                            <h2>{{ label || 'Выберите вариант' }}</h2>
                            <button
                                :class="$style.sheetClose"
                                type="button"
                                aria-label="Закрыть список"
                                @click="closeMenu({ restoreFocus: true })"
                            >
                                <svg viewBox="0 0 20 20" aria-hidden="true">
                                    <path d="m5 5 10 10M15 5 5 15" />
                                </svg>
                            </button>
                        </header>

                        <div
                            :id="`${componentId}-listbox`"
                            :class="$style.mobileOptions"
                            role="listbox"
                            :aria-label="label || placeholder"
                        >
                            <button
                                v-for="(option, index) in normalizedOptions"
                                :id="optionId(index)"
                                :key="`${typeof option.value}-${String(option.value)}-${index}`"
                                :class="[$style.option, $style.mobileOption, { [$style.active]: index === activeIndex, [$style.selected]: String(option.value ?? '') === String(modelValue ?? ''), [$style.optionDisabled]: option.disabled }]"
                                type="button"
                                role="option"
                                :aria-selected="String(option.value ?? '') === String(modelValue ?? '')"
                                :disabled="option.disabled"
                                @mouseenter="activeIndex = index"
                                @click="selectOption(option)"
                            >
                                <span>{{ option.label }}</span>
                                <svg
                                    v-if="String(option.value ?? '') === String(modelValue ?? '')"
                                    :class="$style.checkIcon"
                                    viewBox="0 0 20 20"
                                    aria-hidden="true"
                                >
                                    <path d="m4 10 4 4 8-8" />
                                </svg>
                            </button>
                        </div>
                    </section>
                </div>
            </Transition>
        </Teleport>
    </div>
</template>

<style lang="scss" module>
.customSelect {
    position: relative;
    display: grid;
    min-width: 0;
    gap: 7px;
    color: var(--ink);

    @include text(px1);

    @include respond-to(mobile) {
        @include text(px2);
    }

    &.opened {
        .trigger {
            border-color: var(--purple);
            box-shadow: 0 0 0 3px color-mix(in srgb, var(--purple) 10%, transparent);
        }

        .chevron {
            transform: rotate(180deg);
        }
    }

    &.disabled {
        opacity: 0.6;
    }

    &._small {
        gap: 6px;

        .trigger {
            min-height: 42px;
            padding: 8px 11px;
        }
    }
}

.label {
    color: var(--muted);
    font-weight: 700;

    @include text(px2);
}

.trigger {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    width: 100%;
    min-width: 0;
    min-height: 44px;
    padding: 10px 12px;
    border: 1px solid var(--line);
    border-radius: $radius-mini;
    outline: none;
    background: var(--surface);
    color: var(--ink);
    font: inherit;
    text-align: left;
    cursor: pointer;
    transition: border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease;

    &:hover:not(:disabled) {
        border-color: color-mix(in srgb, var(--purple) 45%, var(--line));
    }

    &:focus-visible {
        border-color: var(--purple);
        box-shadow: 0 0 0 3px color-mix(in srgb, var(--purple) 14%, transparent);
    }

    &:disabled {
        cursor: not-allowed;
    }
}

.value {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.placeholder {
    color: var(--muted);
}

.chevron {
    flex: 0 0 $svg;
    width: $svg;
    height: $svg;
    fill: none;
    stroke: var(--muted);
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 1.7;
    transition: transform 0.22s ease;
}

.desktopMenu {
    position: fixed;
    z-index: 130;
    overflow: auto;
    overscroll-behavior: contain;
    padding: 5px;
    border: 1px solid var(--line);
    border-radius: $radius-mini;
    background: var(--surface);
    box-shadow: 0 16px 38px rgba($ink, 0.14);
    animation: menu-enter 0.16s ease both;
}

.option {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    width: 100%;
    min-height: 42px;
    padding: 9px 11px;
    border: 0;
    border-radius: $radius-mini;
    background: transparent;
    color: var(--ink);
    font: inherit;
    text-align: left;
    cursor: pointer;
    transition: background-color 0.16s ease, color 0.16s ease;

    &.active,
    &:hover:not(:disabled) {
        background: var(--canvas);
    }

    &.selected {
        color: var(--purple);
        font-weight: 700;
    }

    &.optionDisabled {
        opacity: 0.42;
        cursor: not-allowed;
    }
}

.checkIcon {
    flex: 0 0 $svg;
    width: $svg;
    height: $svg;
    fill: none;
    stroke: currentColor;
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 2;
}

.mobileBackdrop {
    position: fixed;
    inset: 0;
    z-index: 140;
    display: flex;
    align-items: flex-end;
    justify-content: center;
    background: rgba($ink, 0.42);
    backdrop-filter: blur(4px);
}

.mobileSheet {
    display: flex;
    flex-direction: column;
    width: 100%;
    max-height: 90vh;
    max-height: min(90vh, var(--tg-viewport-stable-height, 90vh));
    overflow: hidden;
    padding: 8px $padding-mobile max(16px, env(safe-area-inset-bottom, 0px));
    border-radius: $radius $radius 0 0;
    background: var(--surface);
    color: var(--ink);
    box-shadow: 0 -12px 40px rgba($ink, 0.14);
    transform: translateY(var(--sheet-drag-offset, 0px));
    transition: transform 0.32s cubic-bezier(0.2, 0.75, 0.25, 1);
}

.sheetHandle {
    flex: 0 0 auto;
    width: 36px;
    height: 4px;
    margin: 0 auto 12px;
    border-radius: 999px;
    background: var(--line);
    touch-action: none;
    cursor: grab;
}

.sheetHeader {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding-bottom: 12px;
    border-bottom: 1px solid var(--line);

    h2 {
        margin: 0;
        font-weight: 700;

        @include text(px1);

        @include respond-to(mobile) {
            @include text(px1_5);
        }
    }
}

.sheetClose {
    display: grid;
    flex: 0 0 36px;
    place-items: center;
    width: 36px;
    height: 36px;
    padding: 0;
    border: 0;
    border-radius: 50%;
    background: var(--canvas);
    color: var(--muted);
    cursor: pointer;

    svg {
        width: $svg;
        height: $svg;
        fill: none;
        stroke: currentColor;
        stroke-linecap: round;
        stroke-width: 1.8;
    }
}

.mobileOptions {
    overflow: auto;
    overscroll-behavior: contain;
    padding-top: 8px;
}

.mobileOption {
    min-height: 50px;
    padding: $padding;
    border-radius: $radius-mini;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

:global(.custom-select-sheet-enter-active),
:global(.custom-select-sheet-leave-active) {
    transition: opacity 0.25s ease;
}

:global(.custom-select-sheet-enter-from),
:global(.custom-select-sheet-leave-to) {
    opacity: 0;
}

:global(.custom-select-sheet-enter-active) .mobileSheet,
:global(.custom-select-sheet-leave-active) .mobileSheet {
    transition: transform 0.32s cubic-bezier(0.2, 0.75, 0.25, 1);
}

:global(.custom-select-sheet-enter-from) .mobileSheet,
:global(.custom-select-sheet-leave-to) .mobileSheet {
    transform: translateY(100%);
}

@keyframes menu-enter {
    from {
        opacity: 0;
        transform: translateY(-4px) scale(0.99);
    }

    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
}

@include respond-to(mobile) {
    .desktopMenu {
        display: none;
    }
}
</style>
