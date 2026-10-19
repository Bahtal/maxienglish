<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';
import VIcon from '../VIcon.vue';
import VStatusBadge from '../VStatusBadge.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, VIcon, VStatusBadge },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.homeworkDetail">
        <div :class="$style.homeworkDetailMeta">
            <span>Ученик · {{ state.role === 'teacher' ? studentById(modal.data.studentId)?.name : state.studentUser.name }}</span>
            <span>Срок · {{ modal.data.dueDate ? cap(formatDay(modal.data.dueDate)) : 'не указан' }}</span>
            <span v-if="state.role === 'teacher' && modal.data.label">Метка · {{ modal.data.label }}</span>
        </div>
        <section :class="[$style.detailSection, $style.homeworkDescription]">
            <h3>Задание</h3>
            <b
                v-if="modal.data.title"
                :class="$style.homeworkDetailTitle"
            >
                {{ modal.data.title }}
            </b>
            <p>{{ modal.data.description || 'Преподаватель не добавил описание к заданию.' }}</p>
        </section>
        <a
            v-if="modal.data.fileData"
            :class="$style.homeworkDetailFile"
            :href="modal.data.fileData"
            :download="modal.data.filename"
        >
            <VIcon
                :class="$style.homeworkIcon"
                name="file"
                size="small"
                tile
                :stroke-width="1.7"
            />
            <span>
                <b>{{ modal.data.filename }}</b>
                <small>Открыть или скачать материал</small>
            </span>
            <span :class="$style.homeworkFileArrow">↗</span>
        </a>
        <div :class="$style.homeworkDetailFooter">
            <VStatusBadge
                :status="isDoneHomework(modal.data) ? 'done' : 'incomplete'"
                :tone="isDoneHomework(modal.data) ? 'paid' : 'unpaid'"
                :label="isDoneHomework(modal.data) ? 'Выполнено' : 'Не выполнено'"
            />
            <AppButton
                v-if="state.role === 'student' && !isDoneHomework(modal.data)"
                variant="secondary"
                size="small"
                :loading="modal.busy"
                @click="markHomeworkDone(modal.data)"
            >
                Отметить выполненным
            </AppButton>

            <AppButton
                variant="ghost"
                size="small"
                @click="closeModal"
            >
                Закрыть
            </AppButton>
        </div>
    </section>
</template>

<style lang="scss" module>
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

.homeworkDetailMeta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 8px 18px;
    padding: 12px 14px;
    border-radius: $radius-mini;
    background: var(--canvas);
    color: var(--muted);

    @include text(px2);

    span:first-child {
        color: var(--ink);
        font-weight: 700;
    }
}

.homeworkDetailTitle {
    display: block;
    margin: 8px 0;
    color: var(--ink);
    font-size: 17px;
    line-height: 1.5;
    overflow-wrap: anywhere;
}

.homeworkDescription {
    p {
        margin: 0;
        color: var(--muted);
        font-size: 13px;
        line-height: 1.75;
        white-space: pre-wrap;
        overflow-wrap: anywhere;
    }
}

.homeworkDetailFile {
    margin-top: 16px;
    padding: $padding;
    display: grid;
    grid-template-columns: 36px minmax(0, 1fr) 20px;
    align-items: center;
    gap: $gap;
    border: 1px solid var(--line);
    border-radius: $radius;
    color: var(--ink);
    text-decoration: none;

    @include respond-to(mobile) {
        gap: $gap-sm;
        padding: $padding-mobile;
    }

    > span:nth-child(2) {
        min-width: 0;
    }

    b {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        font-size: 11px;
    }

    small {
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        margin-top: 4px;
        color: var(--muted);

        @include text(px2);
    }
}

.homeworkDetailFooter {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 10px;
    margin-top: 18px;
    padding-top: 16px;
    border-top: 1px solid var(--line);

    > :last-child {
        margin-left: auto;
    }

    [data-action=modal-close] {
        margin-left: auto;
    }
}

@media (max-width: 420px) {
    .homeworkDetailFooter {
        display: grid;
        grid-template-columns: minmax(0, 1fr) auto;

        [data-ref=status] {
            grid-row: 1;
            grid-column: 1;
        }

        [data-action=modal-close] {
            grid-row: 1;
            grid-column: 2;
            margin-left: 0;
        }

        [data-action=homework-done] {
            grid-row: 2;
            grid-column: 1/-1;
            justify-self: start;
        }
    }
}

.homeworkFileArrow {
    color: var(--purple);
    font-size: 17px;
}

@include respond-to(mobile) {
    .homeworkIcon {
        align-self: start;
    }
}

[data-theme=darked] {
    .homeworkDescription {
        p {
            color: var(--ink);
        }
    }

    .homeworkDetailMeta {
        color: var(--ink);
        background-color: color-mix(in srgb, var(--ink) 6%, var(--surface));
    }

    .homeworkDetailFile {
        border-color: var(--line);
        background-color: var(--surface);
    }

    .homeworkDetailFooter {
        border-color: var(--line);
    }

}

@include respond-to(mobile) {
    .homeworkDetailFooter {
        > :last-child {
            margin-left: 0;
        }
    }
}

.homeworkDetail {
    --module-placeholder: 0;
}

.pending {
    --module-placeholder: 0;
}

.student {
    --module-placeholder: 0;
}

.teacher {
    --module-placeholder: 0;
}
</style>
