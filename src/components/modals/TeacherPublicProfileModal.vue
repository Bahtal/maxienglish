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
    <div :class="$style.teacherPublicProfile">
        <div :class="$style.modalProfile">
            <span :class="$style.avatar">
                <img
                    v-if="modal.data.avatarUrl"
                    :src="modal.data.avatarUrl"
                    alt=""
                />
                <template v-else>{{ initials(modal.data.name) }}</template>
            </span>
            <span>
                <b>{{ modal.data.name }}</b>
            </span>
        </div>
        <section :class="$style.detailSection">
            <h3>О преподавателе</h3>
            <p>{{ modal.data.bio || 'Описание пока не добавлено.' }}</p>
        </section>
        <div :class="$style.modalActions">
            <AppButton
                variant="outline"
                @click="openChat()"
            >
                Написать преподавателю
            </AppButton>
        </div>
    </div>
</template>

<style lang="scss" module>
.avatar {
    width: $width-block;
    height: $height-block;
    flex: 0 0 $width-block;
    min-width: 0;
    display: grid;
    place-items: center;
    overflow: hidden;
    border-radius: $radius-mini;
    color: $white;
    background: linear-gradient(140deg, var(--amber), var(--red));
    font-weight: 700;

    @include text(px2);

    > img {
        display: block;
        width: 100%;
        height: 100%;
        max-width: 100%;
        object-fit: cover;
    }
}

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

    .avatar {
        width: $width-block-big;
        height: $height-block-big;
        flex-basis: $width-block-big;
        border-radius: $radius;

        @include text(px2);
    }

    > span:last-child {
        display: grid;
    }

    b {
        display: block;
        font-size: 13px;
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
