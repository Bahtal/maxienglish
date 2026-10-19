<script setup>
import VSectionHeader from '../VSectionHeader.vue';

defineProps({
    title: {
        type: String,
        required: true,
    },
    description: {
        type: String,
        default: '',
    },
    actionLabel: {
        type: String,
        default: '',
    },
    actionAriaLabel: {
        type: String,
        default: '',
    },
});

const emit = defineEmits(['action']);
</script>

<template>
    <section :class="$style.section">
        <VSectionHeader
            :class="$style.header"
            :title="title"
            :description="description"
        >
            <template #aside>
            <button
                v-if="actionLabel"
                :class="$style.actionButton"
                :aria-label="actionAriaLabel || actionLabel"
                type="button"
                @click="emit('action')"
            >
                {{ actionLabel }}
                <svg aria-hidden="true">
                    <use href="#icon-arrow" />
                </svg>
            </button>
            </template>
        </VSectionHeader>

        <div :class="$style.content">
            <slot />
        </div>
    </section>
</template>

<style lang="scss" module>
.section {
    min-width: 0;
    padding: $padding;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: $gap;
    margin-bottom: 8px;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.header > div {
    min-width: 0;

    h2 {
        margin: 0;
        font-weight: 700;

        @include text(px1);

        @include respond-to(mobile) {
            @include text(px1_5);
        }
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);

        @include respond-to(mobile) {
            @include text(px3);
        }
    }
}

.actionButton {
    display: flex;
    flex-direction: row;
    justify-content: flex-start;
    align-items: center;
    padding: 4px 0;
    border: 0;
    color: var(--purple) !important;
    background: $transparent;
    font-size: 10px !important;
    font-weight: 500 !important;
    cursor: pointer;
    white-space: nowrap;

    svg {
        width: 14px;
        height: 14px;
        transform: rotate(0deg);
        fill: currentColor;
        transition: all .3s ease;
    }

    &:hover svg {
        transform: rotate(0deg) translateX(3px);
    }
}

.content { min-width: 0; }

</style>
