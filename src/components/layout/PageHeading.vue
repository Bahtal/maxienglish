<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  
  setup(props, { emit }) {
    return useWorkspaceView(props, emit);
  },
};
</script>

<template>
    <div :class="$style.pageHeading">
        <div :class="$style.welcomeRow">
            <div>
                <h1 v-if="state.page !== 'profile' || state.role !== 'teacher'">
                    {{ state.page === 'home' ? `Привет, ${firstName}!` : state.page === 'payments' ? 'Оплата' : state.page === 'homework' ? 'Домашка' : state.page === 'profile' ? 'Профиль' : state.page === 'themes' ? 'Выбор темы' : state.page === 'students' ? 'Ученики' : 'Календарь' }}
                </h1>
                <p v-if="state.page === 'home'" :class="$style.subtitle">
                    {{ state.role === 'student' ? 'Каждое занятие приближает к вашей цели.' : 'Все ученики и занятия на одной странице.' }}
                </p>
                <p v-else-if="state.page === 'homework'" :class="$style.subtitle">
                    {{ state.role === 'student' ? 'Задания от преподавателя и сроки сдачи.' : 'Задания для ваших учеников.' }}
                </p>
                <p v-else-if="state.page === 'payments'" :class="$style.subtitle">
                    {{ state.role === 'student' ? 'Ваш баланс, абонементы и история оплат.' : 'Заявки, балансы учеников и поступившие оплаты.' }}
                </p>
                <p v-else-if="state.page === 'profile' && state.role === 'student'" :class="$style.subtitle">
                    Ваш прогресс, баланс уроков и история обучения.
                </p>
                <p v-else-if="state.page === 'calendar'" :class="$style.subtitle">
                    Все запланированные занятия и свободный график.
                </p>
            </div>
            <div
                v-if="state.page !== 'themes' && !(state.page === 'profile' && state.role === 'teacher')"
                :class="$style.dateChip"
            >
                {{ cap(new Intl.DateTimeFormat('ru-RU', { weekday:'long', day:'numeric', month:'long' }).format(new Date())) }}
            </div>
        </div>
    </div>
</template>

<style lang="scss" module>
.eyebrow {
    margin: 0 0 5px;
    color: var(--ink);
    letter-spacing: 0.5px;
    font-weight: 700;

    @include text(px3);
}

.welcomeRow {
    display: flex;
    align-items: flex-end;
    justify-content: space-between;
    gap: 20px;
    margin: 2px 0 28px;
}

.subtitle {
    margin: 0;
    color: var(--muted);
    font-size: 13px;
}

.dateChip {
    padding: 8px 12px;
    border: 1px solid $line;
    border-radius: $radius-mini;
    color: var(--muted);
    background: var(--surface);
    white-space: nowrap;

    @include text(px2);
}

@include respond-to(mobile) {
    .welcomeRow {
        align-items: flex-start;
        margin: 10px 0 20px;

        h1 {
            font-size: 25px;
        }
    }

    .subtitle {
        @include text(px2);
    }

    .dateChip {
        display: none;
    }
}

[data-theme=darked] {
    .dateChip {
        color: var(--ink);
        border-color: var(--line);
        background-color: var(--surface);
    }
}

.pageHeading {
    --module-placeholder: 0;
}

.student {
    --module-placeholder: 0;
}

.teacher {
    --module-placeholder: 0;
}
</style>
