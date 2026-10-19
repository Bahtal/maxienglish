<script>
import { computed } from 'vue';
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
    props: { workspace: { type: Object, required: true } },
    emits: ['workspace-action'],
    setup(props, { emit }) {
        const view = useWorkspaceView(props, emit);
        const students = computed(() => [...props.workspace.state.students]
            .sort((first, second) => first.name.localeCompare(second.name, 'ru')));

        return { ...view, students };
    },
};
</script>

<template>
    <section :class="[$style.card, $style.balanceCard]">
        <div :class="$style.sectionHeading">
            <div>
                <h2>Баланс учеников</h2>
                <p>Остаток оплаченных занятий и дата последней оплаты</p>
            </div>
            <span :class="$style.statIcon">
                <svg>
                    <use href="#icon-users" />
                </svg>
            </span>
        </div>

        <div v-if="students.length" :class="$style.studentList">
            <article
                v-for="student in students"
                :key="student.id"
                :class="$style.studentRow">
                <span :class="$style.avatar">{{ initials(student.name) }}</span>
                <div :class="$style.studentInfo">
                    <b>{{ student.name }}</b>
                    <span>Последняя оплата: {{ student.lastPayment ? cap(formatDay(student.lastPayment)) : 'нет данных' }}</span>
                </div>
                <span :class="[$style.balance, { [$style.emptyBalance]: Number(student.paidLessons) === 0 }]">
                    {{ Number(student.paidLessons) || 0 }} {{ humanCount(Number(student.paidLessons) || 0, 'урок', 'урока', 'уроков') }}
                </span>
            </article>
        </div>

        <div v-else :class="$style.emptyState">
            <b>Учеников пока нет</b>
            <span>Когда появятся ученики, здесь будет их баланс.</span>
        </div>
    </section>
</template>

<style lang="scss" module>
.card {
    border: 1px solid var(--border-color);
    border-radius: $radius;
    background: var(--surface);
    box-shadow: var(--shadow);
}

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

        @include text(px2);
    }

    p {
        margin: 4px 0 0;
        color: var(--muted);

        @include text(px2);
    }
}

.statIcon {
    width: $width-block;
    height: $height-block;
    display: grid;
    place-items: center;
    flex: 0 0 $width-block;
    border-radius: $radius-mini;
    color: var(--purple);
    background: var(--purple-pale);

    svg {
        width: $svg;
        height: $svg;
        fill: none;
        stroke: currentColor;
        stroke-width: 1.8;
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

.avatar {
    width: $width-block-big;
    height: $height-block-big;
    flex: 0 0 $width-block-big;
    display: grid;
    place-items: center;
    border-radius: $radius-mini;
    color: $white;
    background: linear-gradient(140deg, var(--purple), var(--purple-dark));
    font-weight: 700;

    @include text(px2);

    @include respond-to(mobile) {
        width: $width-block;
        height: $height-block;
        flex: 0 0 $width-block;
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

[data-theme='darked'] {
    .card {
        border-color: var(--line);
        background: var(--surface);
    }

    .avatar {
        color: var(--canvas);
    }
}
</style>
