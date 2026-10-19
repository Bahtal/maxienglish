<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VSectionHeader from '../VSectionHeader.vue';
import VNotificationItem from '../VNotificationItem.vue';
import VIcon from '../VIcon.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { VSectionHeader, VNotificationItem, VIcon },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.sectionCard">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="Напоминания"
            description="Важное для ваших занятий"
        >
            <template #aside>
                <VIcon
                    name="bell"
                    tile
                    size="small"
                />
            </template>
        </VSectionHeader>
        <VNotificationItem
            v-for="notice in state.notifications.filter((item) => item.role === 'student').slice(0,2)"
            :key="notice.id"
            as="article"
            :class="$style.notificationItem"
            :title="notice.title"
            :body="notice.body"
            :time="notice.time"
            :dot-class="$style.noticeDot"
        />
    </section>
</template>

<style lang="scss" module>
.sectionCard {
    padding: $padding;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }
}

.sectionHeading {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: $gap;
    margin-bottom: 8px;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }

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

.notificationItem {
    width: 100%;
    border-bottom: 1px solid var(--line);
    display: flex;
    gap: 10px;

    &:not(:last-child) {
        padding-bottom: 8px;
    }

    &:not(:first-child) {
        padding-top: 8px;
    }

    &:last-child {
        border: 0;
    }

    b {
        display: block;
        font-size: 10px;
    }

    p {
        display: block;
        margin: 4px 0;
        color: $muted;
        line-height: 1.45;

        @include text(px2);
    }

    small {
        color: var(--muted);
        font-size: 8px;
    }
}

[data-theme=darked] {
    .notificationItem {
        color: var(--ink);
        border-color: var(--line);

        p {
            color: var(--muted);
        }

        small {
            color: var(--muted);
        }
    }
}
</style>
