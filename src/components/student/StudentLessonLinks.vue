<script setup>
import { computed } from 'vue';
import { isValidHttpsUrl } from '../../utils/appConfig.js';

const props = defineProps({
    zoomUrl: { type: String, default: '' },
    boardUrl: { type: String, default: '' },
});

const links = computed(() => {
    const zoomUrl = String(props.zoomUrl || '').trim();
    const boardUrl = String(props.boardUrl || '').trim();
    const safeZoomUrl = isValidHttpsUrl(zoomUrl) ? zoomUrl : '';
    const safeBoardUrl = isValidHttpsUrl(boardUrl) ? boardUrl : '';

    return [
        {
            key: 'zoom',
            title: 'Zoom',
            description: safeZoomUrl ? 'Открыть встречу' : 'Ссылка не добавлена',
            url: safeZoomUrl,
            icon: 'video',
        },
        {
            key: 'board',
            title: 'Доска урока',
            description: safeBoardUrl ? 'Открыть доску' : 'Ссылка не добавлена',
            url: safeBoardUrl,
            icon: 'board',
        },
    ];
});

function openLink(url) {
    if (!url) return;

    const webApp = window.Telegram?.WebApp;

    if (typeof webApp?.openLink === 'function') {
        webApp.openLink(url);
        return;
    }

    window.open(url, '_blank', 'noopener,noreferrer');
}
</script>

<template>
    <section :class="$style.lessonLinks" aria-label="Ссылки для занятий">
        <a
            v-for="link in links"
            :key="link.key"
            :class="[$style.linkCard, { [$style.disabled]: !link.url }]"
            :href="link.url || undefined"
            :aria-disabled="!link.url"
            @click.prevent="openLink(link.url)"
        >
            <span :class="$style.icon">
                <svg
                    v-if="link.icon === 'video'"
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                >
                    <rect x="3" y="6" width="12" height="12" rx="2" />
                    <path d="m15 10 6-3v10l-6-3z" />
                </svg>
                <svg
                    v-else
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                >
                    <rect x="3" y="3" width="18" height="18" rx="3" />
                    <path d="M3 9h18M9 21V9" />
                </svg>
            </span>

            <span :class="$style.copy">
                <b>{{ link.title }}</b>
                <small>{{ link.description }}</small>
            </span>

            <svg
                :class="$style.arrow"
                viewBox="0 0 24 24"
                aria-hidden="true"
            >
                <path d="M7 17 17 7M8 7h9v9" />
            </svg>
        </a>
    </section>
</template>

<style lang="scss" module>
.lessonLinks {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 12px;
    min-width: 0;
}

.linkCard {
    display: flex;
    align-items: center;
    gap: 10px;
    min-width: 0;
    padding: $padding;
    border: 1px solid var(--border-color);
    border-radius: $radius;
    background: var(--surface);
    color: var(--ink);
    text-decoration: none;
    box-shadow: var(--shadow);
    transition: border-color 160ms ease, transform 160ms ease, box-shadow 160ms ease;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }

    &:hover {
        border-color: var(--purple-pale);
        transform: translateY(-1px);
    }
}

.disabled {
    cursor: default;
    box-shadow: none;

    &:hover {
        border-color: var(--border-color);
        transform: none;
    }
}

.icon {
    display: grid;
    place-items: center;
    flex: 0 0 $width-block-big;
    width: $width-block-big;
    height: $height-block-big;
    border-radius: $radius-mini;
    background: var(--purple-pale);
    color: var(--purple);

    svg {
        width: $svg;
        height: $svg;
        fill: none;
        stroke: currentColor;
        stroke-width: 1.7;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
}

.copy {
    display: grid;
    gap: 4px;
    flex: 1 1 auto;
    min-width: 0;

    b {
        overflow: hidden;
        font-size: 13px;
        font-weight: 750;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    small {
        overflow: hidden;
        color: var(--muted);
        font-size: 10px;
        line-height: 1.35;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
}

.arrow {
    flex: 0 0 16px;
    width: 16px;
    height: 16px;
    color: var(--muted);
    fill: none;
    stroke: currentColor;
    stroke-width: 1.7;
    stroke-linecap: round;
    stroke-linejoin: round;
}

@include respond-to(mobile) {
    .lessonLinks {
        gap: 8px;
    }

    .linkCard {
        gap: 8px;
        padding: 10px;
    }

    .icon {
        flex-basis: $width-block;
        width: $width-block;
        height: $height-block;
    }

    .arrow {
        display: none;
    }

    .copy {
        b {
            @include text(px2);
        }

        small {
            @include text(px2);
        }
    }
}
</style>
