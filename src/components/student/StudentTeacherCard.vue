<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="[$style.card, $style.teacherProfileShortcut]">
        <div :class="$style.teacherProfileShortcutCopy">
            <span :class="$style.avatar">
                <img
                    v-if="state.teacher.avatarUrl"
                    :src="state.teacher.avatarUrl"
                    alt="" />
                <template
                    v-else>{{ initials(state.teacher.name) }}</template>
            </span>
            <span>
                <b>{{ state.teacher.name }}</b>
                <small>Ваш преподаватель</small>
            </span>
        </div>

        <AppButton
            variant="secondary"
            size="small"
            @click="openModal('teacher-view', 'Преподаватель', state.teacher)"
        >
            Профиль
        </AppButton>
    </section>
</template>

<style lang="scss" module>
.avatar {
    width: $width-block-big;
    height: $height-block-big;
    flex: 0 0 $width-block-big;
    min-width: 0;
    display: grid;
    place-items: center;
    overflow: hidden;
    border-radius: $radius-mini;
    color: $white;
    background: linear-gradient(140deg, var(--amber), var(--red));
    font-weight: 700;

    @include text(px2);

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        flex: 0 0 $width-block;
    }

    > img {
        display: block;
        width: 100%;
        height: 100%;
        max-width: 100%;
        object-fit: cover;
    }
}

.card {
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius;
    box-shadow: var(--shadow);
}

[data-theme=darked] {
    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }
}

.teacherProfileShortcut {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: $gap;
    padding: $padding;

    @include respond-to(mobile) {
        padding: $padding-mobile;
        gap: $gap-sm;
    }

    button {
        font-size: 12px !important;
    }
}

.teacherProfileShortcutCopy {
    display: flex;
    align-items: center;
    gap: 11px;
    min-width: 0;

    > span:last-child {
        min-width: 0;
        display: grid;
    }

    b {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;

        @include text(px2);
    }

    small {
        color: var(--muted);

        @include text(px2);
    }
}

@include respond-to(mobile) {
    .teacherProfileShortcut {
        align-items: flex-start;
        flex-flow: row nowrap;
    }
}
</style>
