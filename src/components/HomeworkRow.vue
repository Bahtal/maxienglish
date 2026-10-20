<script setup>
import AppButton from './AppButton.vue';
import VIcon from './VIcon.vue';
import VStatusBadge from './VStatusBadge.vue';

const props = defineProps({
  item: { type: Object, required: true },
  teacher: { type: Boolean, default: false },
  studentName: { type: String, default: '' },
});
const emit = defineEmits(['open', 'done']);
const done = (item) => item.status === 'done' || item.status === 'completed';
const dueLabel = (value) => value ? `до ${new Intl.DateTimeFormat('ru-RU', { day: 'numeric', month: 'short' }).format(new Date(`${value}T00:00:00`))}` : '';
</script>

<template>
    <div :class="[$style.homeworkRow, $style.row]">
        <button
            :class="$style.homeworkOpen"
            type="button"
            :aria-label="`Открыть домашнее задание: ${item.title}`"
            @click="emit('open', item)"
        >
            <VIcon
                :class="$style.homeworkIcon"
                name="file"
                size="large"
                tile
                :stroke-width="1.7"
            />

            <span :class="$style.homeworkInfo">
                <span :class="$style.homeworkInfoContainer">
                    <b>{{ item.title }}</b>
                    <span :class="$style.homeworkDue">{{ dueLabel(item.dueDate) }}</span>
                </span>
                <span :class="$style.homeworkMeta">
                    <small>{{ [teacher ? studentName : '', item.description || 'Домашнее задание', item.filename].filter(Boolean).join(' · ') }}</small>
                    <span
                        v-if="teacher && item.label"
                        :class="$style.homeworkLabel">{{ item.label }}</span>
                </span>
            </span>
        </button>
        <span :class="$style.homeworkActions">
            <a
                v-if="item.fileData"
                :class="[$style.button, $style.outline, $style.small]"
                :href="item.fileData"
                :download="item.filename || 'homework-file'"
            >
                Скачать
            </a>

            <AppButton
                v-if="!teacher && !done(item)"
                variant="secondary"
                size="small"
                @click="emit('done', item)"
            >
                Готово
            </AppButton>
            <VStatusBadge
                v-if="done(item)"
                status="done"
                tone="paid"
                label="Выполнено"
            />
        </span>
    </div>
</template>

<style lang="scss" module>
.row {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: center;
    gap: 0.75rem;
    min-width: 0;
    border-bottom: 1px solid var(--line);

    &:not(:first-child) {
        padding-top: 8px;
    }

    &:not(:last-child) {
        padding-bottom: 8px;
    }
}

@media (max-width: 520px) {
    .row {
      grid-template-columns: minmax(0, 1fr);
    }
}

.button {
    min-height: $width-block;
    padding: 0 $padding;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    border: 0;
    border-radius: $radius-mini;
    font-weight: 700;
    cursor: pointer;
    transition: transform 0.16s, box-shadow 0.16s, background 0.16s;

    @include text(px2);

    &.outline {
        color: var(--muted);
        border: 1px solid var(--line);
        background: var(--surface);
    }

    &.small {
        min-height: $height-block;
        padding: 0 8px;

        @include text(px2);
    }

    svg {
        width: $svg;
        height: $svg;
        stroke: currentColor;
        fill: none;
        stroke-width: 1.8;
        stroke-linecap: round;
        stroke-linejoin: round;
    }

    &:hover {
        transform: translateY(-1px);
    }
}

.homeworkRow {
    min-width: 0;
    display: grid;
    grid-template-columns: minmax(0, 1fr) max-content;
    align-items: center;
    gap: 10px;
    border-bottom: 1px solid var(--line);

    &:last-child {
        border: 0;
    }
}
.homeworkOpen {
    appearance: none;
    width: 100%;
    min-width: 0;
    display: grid;
    grid-template-columns: $width-block-big minmax(0, 1fr);
    align-items: center;
    gap: 12px;
    border: 0;
    padding: 8px 0;
    background: $transparent;
    color: var(--ink);
    font-family: inherit;
    line-height: inherit;
    text-align: left;
    cursor: pointer;
    transition: background 0.16s ease;

    @include respond-to(mobile) {
        grid-template-columns: $width-block minmax(0, 1fr);
    }
}



.homeworkInfo {
    min-width: 0;

    b {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;

        @include text(px2);
    }

    small {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        color: var(--muted);

        @include text(px2);
    }

}

.homeworkMeta {
    display: flex;
    align-items: center;
    gap: 7px;
    min-width: 0;

    small {
        min-width: 0;
        flex: 1 1 auto;
    }
}

.homeworkLabel {
    flex: 0 0 auto;
    max-width: 90px;
    overflow: hidden;
    padding: 0 8px;
    border-radius: 999px;
    color: var(--on-purple-pale);
    background: var(--purple-pale);
    font-size: 8px;
    font-weight: 700;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.homeworkInfoContainer {
    display: flex;
    flex-flow: row nowrap;
    align-items: center;
    justify-content: space-between;
    gap: 4px;

    @include respond-to(mobile) {
        flex-flow: column-reverse;
        align-items: flex-start;
    }
}
.homeworkDue {
    color: var(--purple);
    white-space: nowrap;
}
.homeworkActions {
    min-width: 0;
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px;

    button {
        min-height: 0 !important;
    }
}

@include respond-to(mobile) {
    .homeworkRow {
        align-items: start;
        gap: 8px 12px;

        &:not(:first-child) {
            padding-top: 8px;
        }

        &:not(:last-child) {
            padding-bottom: 8px;
        }
    }
    .homeworkOpen {
        align-items: start;
        padding: 0;
    }
    .homeworkIcon {
        align-self: start;
    }
    .homeworkDue {
        white-space: normal;
        line-height: 1.4;
    }
}
[data-theme=darked] {
    .button {
        &.outline {
            color: var(--ink);
            border-color: var(--line);
            background: color-mix(in srgb, var(--ink) 4%, var(--surface));
        }
    }

}
</style>
