<script setup>
defineProps({
    name: {
        type: String,
        required: true,
    },
    size: {
        type: String,
        default: 'small',
        validator: (value) => ['small', 'large', 'nav'].includes(value),
    },
    tile: {
        type: Boolean,
        default: false,
    },
    radius: {
        type: String,
        default: 'mini',
        validator: (value) => ['micro', 'mini', 'default'].includes(value),
    },
    mobileRadius: {
        type: String,
        default: '',
        validator: (value) => ['', 'micro', 'mini', 'default'].includes(value),
    },
    glyphSize: {
        type: Number,
        default: 20,
    },
    strokeWidth: {
        type: Number,
        default: 1.8,
    },
});
</script>

<template>
    <span
        :class="[$style.icon, $style[size], tile && $style.tile, tile && $style[radius]]"
        :style="{
            '--icon-glyph-size': `${glyphSize}px`,
            '--icon-stroke-width': strokeWidth,
        }"
        :data-mobile-radius="mobileRadius || undefined"
        aria-hidden="true"
    >
        <svg>
            <use :href="`#icon-${name}`" />
        </svg>
    </span>
</template>

<style lang="scss" module>
.icon {
    display: grid;
    place-items: center;
    width: $svg;
    height: $svg;
    flex: 0 0 $svg;
    color: inherit;

    svg {
        display: block;
        width: var(--icon-glyph-size);
        height: var(--icon-glyph-size);
        fill: none;
        stroke: currentColor;
        stroke-width: var(--icon-stroke-width);
        stroke-linecap: round;
        stroke-linejoin: round;
    }
}

.small,
.large {
    &.tile {
        width: $width-block;
        height: $height-block;
        flex-basis: $width-block;
        border-radius: $radius-mini;
        color: var(--purple);
        background: var(--purple-pale);
    }
}

.nav {
    width: $svg;
    height: $svg;
    flex: 0 0 $svg;
}

.large.tile {
    width: $width-block-big;
    height: $height-block-big;
    flex-basis: $width-block-big;

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        flex-basis: $width-block;
    }
}

.micro {
    border-radius: $radius-micro;
}

.mini {
    border-radius: $radius-mini;
}

.default {
    border-radius: $radius;
}

@include respond-to(mobile) {
    .icon[data-mobile-radius='micro'] {
        border-radius: $radius-micro;
    }

    .icon[data-mobile-radius='mini'] {
        border-radius: $radius-mini;
    }

    .icon[data-mobile-radius='default'] {
        border-radius: $radius;
    }
}

:global([data-theme='darked']) {
    .tile {
        color: $dark-purple-dark;
        background: $dark-purple-pale;
    }
}
</style>
