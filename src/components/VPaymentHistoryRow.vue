<script setup>
import VStatusBadge from './VStatusBadge.vue';

defineProps({
    payment: {
        type: Object,
        required: true,
    },
    statusLabel: {
        type: String,
        required: true,
    },
    metaClass: {
        type: [String, Array, Object],
        default: '',
    },
});
</script>

<template>
    <article>
        <slot name="leading" />
        <slot name="content" />
        <div :class="metaClass">
            <strong>{{ Number(payment.amount || 0).toLocaleString('ru-RU') }} ₽</strong>
            <VStatusBadge
                :status="payment.status"
                :tone="payment.status"
                variant="text"
                :label="statusLabel"
            />
        </div>
    </article>
</template>
