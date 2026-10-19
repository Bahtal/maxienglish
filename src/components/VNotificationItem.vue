<script setup>
import VStatusBadge from './VStatusBadge.vue';

defineProps({
    as: {
        type: String,
        default: 'article',
        validator: (tag) => ['article', 'button', 'div'].includes(tag),
    },
    title: {
        type: String,
        required: true,
    },
    body: {
        type: String,
        default: '',
    },
    time: {
        type: String,
        default: '',
    },
    outcome: {
        type: String,
        default: '',
    },
    dotClass: {
        type: String,
        default: '',
    },
});

const outcomeLabels = {
    awaiting: 'Ожидает',
    rescheduled: 'Перенесён',
    cancelled: 'Отменён',
};
</script>

<template>
    <component
        :is="as"
        :type="as === 'button' ? 'button' : undefined"
    >
        <span :class="[$style.dot, dotClass]" />
        <span>
            <b>{{ title }}</b>
            <p v-if="body">{{ body }}</p>
            <small v-if="time">{{ time }}</small>
            <VStatusBadge
                v-if="outcome"
                :status="outcome"
                :tone="outcome"
                variant="notice"
                :label="outcomeLabels[outcome] || outcome"
            />
        </span>
    </component>
</template>

<style lang="scss" module>
.dot {
    width: 8px;
    height: 8px;
    flex: 0 0 8px;
    margin-top: 5px;
    border-radius: 50%;
    background: var(--purple);
}
</style>
