<script>
import { computed } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';
import VAvatar from '../VAvatar.vue';
import VStatusBadge from '../VStatusBadge.vue';

import VModalActions from '../VModalActions.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VAvatar, VStatusBadge, VModalActions },
  setup(props, { emit }) {
    const view = useWorkspaceView(props, emit);
    view.canDeletePastLesson = computed(() => {
      const lesson = props.workspace.modal.data;
      return props.workspace.state.role === 'teacher'
        && Boolean(lesson?.id)
        && props.workspace.dateObject(lesson.date, lesson.time) < new Date();
    });
    return view;
  },
};
</script>

<template>
    <div :class="$style.lessonDetail">
        <div :class="$style.modalProfile">
            <VAvatar
                :class="$style.avatar"
                size="large"
                responsive
                radius="default"
                mobile-radius="micro"
                :name="state.role === 'teacher' ? studentById(modal.data.studentId)?.name || '' : state.teacher.name"
            />
            <span>
                <b>{{ state.role === 'teacher' ? studentById(modal.data.studentId)?.name : state.teacher.name }}</b>
                <small>{{ cap(formatDay(modal.data.date,{weekday:'long',day:'numeric',month:'long'})) }} · {{ modal.data.time }}</small>
            </span>
        </div>
        <div :class="$style.detailStat">
            <small>Статус оплаты</small>
            <VStatusBadge
                :status="modal.data.status"
                :tone="statusClass(modal.data.status)"
                variant="value"
                :label="statusLabel(modal.data.status)"
            />
        </div>
        <p>{{ modal.data.kind }}</p>
        <VModalActions :class="$style.modalActions">
            <AppButton
                v-if="state.role==='teacher' && modal.data.lessonStatus==='scheduled' && modal.data.status!=='paid'"
                variant="secondary"
                @click="markLessonPaid(modal.data)">Оплачен</AppButton>
            <AppButton
                v-if="state.role==='teacher' && modal.data.lessonStatus==='scheduled'"
                variant="outline"
                @click="openReschedule(modal.data)">Перенести</AppButton>
            <AppButton
                v-if="state.role==='teacher' && modal.data.lessonStatus==='scheduled'"
                variant="danger"
                @click="openModal('cancel-confirm', 'Отменить урок?', modal.data, studentById(modal.data.studentId)?.name)">Отменить урок</AppButton>
            <AppButton
                v-if="canDeletePastLesson"
                variant="danger"
                @click="openModal('delete-past-lesson', 'Удалить прошедший урок?', modal.data, studentById(modal.data.studentId)?.name)">Удалить урок</AppButton>
            <AppButton
                v-if="state.role==='student' && modal.data.lessonStatus==='scheduled'"
                variant="outline"
                @click="requestReschedule(modal.data)">Предложить перенести урок</AppButton>
            <AppButton
                variant="ghost"
                @click="openChat(modal.data.studentId)">{{ state.role==='teacher' ? 'Написать ученику' : 'Написать преподавателю' }}</AppButton>
        </VModalActions>
    </div>
</template>

<style lang="scss" module>
.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: $gap;
    margin-top: 16px;

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.modalProfile {
    display: flex;
    align-items: center;
    gap: $gap;
    margin-bottom: 16px;
    padding: $padding-mobile;
    border-radius: $radius;
    background: var(--canvas);

    .avatar {
        font-size: 14px;
    }

    > span:last-child {
        display: grid;
        gap: 4px;
    }

    b {
        display: block;

        @include text(px2);
    }

    small {
        display: block;
        margin-top: 5px;
        color: var(--muted);

        @include text(px2);
    }
}

.detailStat {
    padding: 12px 10px;
    border: 1px solid var(--line);
    border-radius: $radius;

    b {
        display: block;
        font-weight: 700;

        @include text(px2);
    }

    small {
        display: block;
        margin-top: 5px;
        color: var(--muted);

        @include text(px2);
    }
}

@include respond-to(mobile) {
    .detailStat {
        padding: 10px 8px;

        b {
            @include text(px2);
        }

        small {
            font-size: 8px;
        }
    }
}

[data-theme=darked] {
    .modalProfile {
        color: var(--ink);
    }

    .detailStat {
        color: var(--ink);

        b {
            color: var(--ink);
        }

        small {
            color: var(--muted);
        }
    }
}

.lessonDetail {
    --module-placeholder: 0;
}

.student {
    --module-placeholder: 0;
}

.teacher {
    --module-placeholder: 0;
}
</style>
