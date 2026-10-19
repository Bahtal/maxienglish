<script>
import { computed } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import VAvatar from '../VAvatar.vue';
import VIcon from '../VIcon.vue';

import VSectionHeader from '../VSectionHeader.vue';

import VEmptyState from '../VEmptyState.vue';

export default {
    props: { workspace: { type: Object, required: true } },
    emits: ['workspace-action'],
    components: { VAvatar, VIcon, VSectionHeader, VEmptyState },
    setup(props, { emit }) {
        const view = useWorkspaceView(props, emit);
        const students = computed(() => [...props.workspace.state.students]
            .sort((first, second) => first.name.localeCompare(second.name, 'ru')));

        return { ...view, students };
    },
};
</script>

<template>
    <section :class="$style.balanceCard">
        <VSectionHeader
            :class="$style.sectionHeading"
            title="Баланс учеников"
            description="Остаток оплаченных занятий и дата последней оплаты"
        >
            <template #aside>
                <VIcon
                    name="users"
                    size="small"
                    tile
                />
            </template>
        </VSectionHeader>

        <div v-if="students.length" :class="$style.studentList">
            <article
                v-for="student in students"
                :key="student.id"
                :class="$style.studentRow">
                <VAvatar
                    size="large"
                    responsive
                    tone="purple"
                    radius="mini"
                    dark-text
                    :name="student.name"
                />
                <div :class="$style.studentInfo">
                    <b>{{ student.name }}</b>
                    <span>Последняя оплата: {{ student.lastPayment ? cap(formatDay(student.lastPayment)) : 'нет данных' }}</span>
                </div>
                <span :class="[$style.balance, { [$style.emptyBalance]: Number(student.paidLessons) === 0 }]">
                    {{ Number(student.paidLessons) || 0 }} {{ humanCount(Number(student.paidLessons) || 0, 'урок', 'урока', 'уроков') }}
                </span>
            </article>
        </div>

        <VEmptyState
            v-else
            :class="$style.emptyState"
            title="Учеников пока нет"
            description="Когда появятся ученики, здесь будет их баланс."
        />
    </section>
</template>

<style lang="scss" module>
.balanceCard {
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

.studentList {
    display: grid;
}

.studentRow {
    display: flex;
    align-items: center;
    gap: 11px;
    min-width: 0;
    padding: 12px 0;
    border-bottom: 1px solid var(--line);

    &:last-child {
        border-bottom: 0;
        padding-bottom: 0;
    }
}

.studentInfo {
    display: grid;
    gap: 5px;
    min-width: 0;

    b,
    span {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    b {
        @include text(px2);
    }

    span {
        color: var(--muted);

        @include text(px2);
    }
}

.balance {
    flex: 0 0 auto;
    margin-left: auto;
    padding: 1px 4px;
    border-radius: $radius;
    color: var(--green);
    background: color-mix(in srgb, var(--green) 12%, var(--surface));
    font-weight: 700;
    white-space: nowrap;

    @include text(px2);

    @include respond-to(mobile) {
        font-weight: 400;

        @include text(px3);
    }
}

.emptyBalance {
    color: var(--red);
    background: color-mix(in srgb, var(--red) 12%, var(--surface));
}

.emptyState {
    display: grid;
    justify-items: center;
    gap: 5px;
    padding: 18px 0 6px;
    color: var(--muted);
    text-align: center;
    font-size: 11px;

    b {
        color: var(--ink);
        font-size: 13px;
    }
}

</style>
