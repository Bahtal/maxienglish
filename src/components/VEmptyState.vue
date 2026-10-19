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
});
</script>

<template>
    <div>
        <b v-if="title">{{ title }}</b>
        <span v-if="description">{{ description }}</span>
        <slot />
    </div>
</template>
