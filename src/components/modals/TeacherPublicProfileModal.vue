<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';
import VAvatar from '../VAvatar.vue';

import VModalActions from '../VModalActions.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VAvatar, VModalActions },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <div :class="$style.teacherPublicProfile">
        <div :class="$style.modalProfile">
            <VAvatar
                size="large"
                responsive
                radius="default"
                mobile-radius="micro"
                :src="modal.data.avatarUrl"
                :name="modal.data.name"
            />
            <span>
                <b>{{ modal.data.name }}</b>
            </span>
        </div>
        <section :class="$style.detailSection">
            <h3>О преподавателе</h3>
            <p>{{ modal.data.bio || 'Описание пока не добавлено.' }}</p>
        </section>
        <VModalActions :class="$style.modalActions">
            <AppButton
                variant="outline"
                @click="openChat()"
            >
                Написать преподавателю
            </AppButton>
        </VModalActions>
    </div>
</template>

<style lang="scss" module>
.modalActions {
    display: flex;
    margin-top: 16px;

    > * {
        width: 100%;
    }
}

.detailSection {
    margin-top: 16px;

    h3 {
        margin: 0 0 10px;
        font-weight: 700;

        @include text(px2);
    }

    p {
        margin: 0;
        line-height: 1.7;
        white-space: pre-wrap;
    }
}

.modalProfile {
    display: flex;
    align-items: center;
    gap: $gap;
    margin-bottom: 16px;
    border-radius: $radius;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }

    > span:last-child {
        display: grid;
    }

    b {
        display: block;

        @include text(px2);
    }

}

[data-theme=darked] {
    .modalProfile {
        color: var(--ink);
    }
}

.teacherPublicProfile {
    --module-placeholder: 0;
}
</style>
