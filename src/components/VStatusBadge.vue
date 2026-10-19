<script setup>
defineProps({
    status: {
        type: String,
        default: '',
    },
    label: {
        type: String,
        default: '',
    },
    tone: {
        type: String,
        default: '',
        validator: (value) => [
            '',
            'neutral',
            'muted',
            'paid',
            'completed',
            'unpaid',
            'pending',
            'awaiting',
            'rejected',
            'cancelled',
            'rescheduled',
        ].includes(value),
    },
    variant: {
        type: String,
        default: 'pill',
        validator: (value) => ['pill', 'text', 'notice', 'value'].includes(value),
    },
    strong: {
        type: Boolean,
        default: false,
    },
});

const toneAliases = {
    awaiting: 'pending',
    completed: 'paid',
};
</script>

<template>
    <span
        :class="[$style.badge, $style[variant], $style[toneAliases[tone] || tone || 'neutral'], { [$style.strong]: strong }]"
        :data-status="status"
        :data-tone="toneAliases[tone] || tone || 'neutral'"
    >
        <slot>{{ label }}</slot>
    </span>
</template>

<style lang="scss" module>
.badge {
    width: fit-content;
    font-weight: 400;
    white-space: nowrap;
}

.pill {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 1px 4px;
    border-radius: $radius;

    @include text(px3);

    &:before {
        content: "";
        width: 5px;
        height: 5px;
        flex: 0 0 5px;
        border-radius: 50%;
        background: currentColor;
    }
}

.text {
    color: var(--muted);
    @include text(px3);
}

.value {
    display: block;
    width: fit-content;
    font-weight: 700;
    @include text(px2);
}

.notice {
    margin-left: auto;
    margin-top: 6px;
    padding: 4px 8px;
    border-radius: 999px;
    color: var(--purple);
    background: var(--purple-pale);
    font-size: 8px;
    font-weight: 700;
}

.paid {
    &.pill {
        color: var(--green);
        background: color-mix(in srgb, var(--green) 10%, var(--surface));
    }

    &.text {
        color: var(--green);
    }

    &.value {
        color: var(--green);
    }
}

.unpaid {
    &.pill {
        color: var(--red);
        background: color-mix(in srgb, var(--red) 10%, var(--surface));
    }

    &.value {
        color: var(--red);
    }
}

.pending {
    &.pill {
        color: var(--amber);
        background: color-mix(in srgb, var(--amber) 14%, var(--surface));
    }

    &.text {
        color: var(--amber);
    }

    &.value {
        color: var(--amber);
    }
}

.rejected {
    &.text {
        color: var(--red);
    }

    &.value {
        color: var(--red);
    }
}

.muted {
    &.text {
        color: var(--muted);
    }

    &.value {
        color: var(--muted);
    }
}

.rescheduled {
    &.notice {
        color: var(--green);
        background: var(--mint);
    }
}

.cancelled {
    &.notice {
        color: var(--red);
        background: color-mix(in srgb, var(--red) 10%, var(--surface));
    }
}

.strong {
    &.pending.pill {
        background: color-mix(in srgb, var(--amber) 20%, var(--surface));
    }
}

:global([data-theme='darked']) {
    .unpaid.pill {
        background: color-mix(in srgb, var(--red) 20%, var(--surface));
    }

    .strong.pending.pill {
        background: color-mix(in srgb, var(--amber) 20%, var(--surface));
    }

    .notice {
        color: $dark-purple-dark;
        background: $dark-purple-pale;
    }

    .muted.text {
        color: var(--ink);
    }

    .rescheduled.notice {
        color: var(--green);
        background: $dark-mint;
    }

    .cancelled.notice {
        background: color-mix(in srgb, var(--red) 20%, var(--surface));
    }
}
</style>
