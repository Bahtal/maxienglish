<script setup>
import { ref, watch } from 'vue';
import { initials } from '../utils/appConfig.js';

const props = defineProps({
    src: {
        type: String,
        default: '',
    },
    name: {
        type: String,
        default: '',
    },
    alt: {
        type: String,
        default: '',
    },
    size: {
        type: String,
        default: 'large',
        validator: (value) => ['small', 'medium', 'large'].includes(value),
    },
    responsive: {
        type: Boolean,
        default: false,
    },
    tone: {
        type: String,
        default: 'default',
        validator: (value) => ['', 'default', 'purple', 'blue', 'mint'].includes(value),
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
    darkText: {
        type: Boolean,
        default: false,
    },
});

const imageFailed = ref(false);

watch(() => props.src, () => {
    imageFailed.value = false;
});
</script>

<template>
    <span
        :class="$style.avatar"
        :data-size="size"
        :data-tone="tone || 'default'"
        :data-radius="radius"
        :data-mobile-radius="mobileRadius || undefined"
        :data-responsive="responsive || undefined"
        :data-dark-text="darkText || undefined"
    >
        <img
            v-if="src && !imageFailed"
            :class="$style.image"
            :src="src"
            :alt="alt || name"
            @error="imageFailed = true"
        >
        <template v-else>{{ initials(name) }}</template>
    </span>
</template>

<style lang="scss" module>
.avatar {
    display: grid;
    place-items: center;
    overflow: hidden;
    min-width: 0;
    color: $white;
    font-weight: 700;
    background: linear-gradient(140deg, var(--amber), var(--red));

    @include text(px2);

    &[data-size='small'] {
        width: $width-block;
        height: $height-block;
        flex: 0 0 $width-block;
    }

    &[data-size='medium'] {
        width: 38px;
        height: 38px;
        flex: 0 0 38px;
    }

    &[data-size='large'] {
        width: $width-block-big;
        height: $height-block-big;
        flex: 0 0 $width-block-big;
    }

    &[data-tone='purple'],
    &[data-tone='blue'] {
        background: linear-gradient(140deg, var(--purple), var(--purple-dark));
    }

    &[data-tone='mint'] {
        background: linear-gradient(140deg, var(--mint), var(--green));
    }

    &[data-radius='micro'] {
        border-radius: $radius-micro;
    }

    &[data-radius='mini'] {
        border-radius: $radius-mini;
    }

    &[data-radius='default'] {
        border-radius: $radius;
    }

    @include respond-to(mobile) {
        &[data-responsive='true'][data-size='large'] {
            width: $width-block;
            height: $height-block;
            flex-basis: $width-block;
        }

        &[data-mobile-radius='micro'] {
            border-radius: $radius-micro;
        }

        &[data-mobile-radius='mini'] {
            border-radius: $radius-mini;
        }

        &[data-mobile-radius='default'] {
            border-radius: $radius;
        }
    }
}

:global([data-theme='darked']) {
    .avatar[data-dark-text='true'] {
        color: var(--canvas);
    }
}

.image {
    display: block;
    width: 100%;
    height: 100%;
    max-width: 100%;
    object-fit: cover;
}
</style>
