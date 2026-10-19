<script setup>
defineProps({
    title: {
        type: String,
        default: '',
    },
    description: {
        type: String,
        default: '',
    },
    headingTag: {
        type: String,
        default: 'h2',
        validator: (tag) => ['h2', 'h3'].includes(tag),
    },
});
</script>

<template>
    <div>
        <div>
            <slot name="heading">
                <component :is="headingTag">{{ title }}</component>
                <p v-if="description">{{ description }}</p>
            </slot>
        </div>
        <slot name="aside" />
    </div>
</template>
