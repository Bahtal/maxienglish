<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';
import VAvatar from '../VAvatar.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VAvatar },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.teacherProfileShortcut">
        <div :class="$style.teacherProfileShortcutCopy">
            <VAvatar
                size="large"
                responsive
                radius="mini"
                :src="state.teacher.avatarUrl"
                :name="state.teacher.name"
            />
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
