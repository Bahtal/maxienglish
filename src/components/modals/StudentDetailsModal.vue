<script>
import { computed, reactive, watch } from 'vue';
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
    const studentPricing = reactive({ singleLessonPrice: '', plans: [] });

    function hydrateStudentPricing() {
      const student = props.workspace.modal.data;
      studentPricing.singleLessonPrice = student?.customSingleLessonPrice ?? '';
      studentPricing.plans = (student?.customPlans || []).map((plan) => ({ ...plan }));
    }

    watch(() => props.workspace.modal.data?.id, hydrateStudentPricing, { immediate: true });

    view.attendanceLesson = computed(() => {
      const studentId = props.workspace.modal.data?.id;
      return studentId ? props.workspace.pastLessonForAttendance(studentId) : null;
    });
    view.studentPricing = studentPricing;
    view.addStudentPlan = () => studentPricing.plans.push({ id: '', lessons: 4, price: 0, active: true });
    view.removeStudentPlan = (index) => studentPricing.plans.splice(index, 1);
    view.submitStudentSetup = (event) => view.submitWorkspaceForm(event, 'updateStudentSetup', {
      customSingleLessonPrice: studentPricing.singleLessonPrice,
      customPlans: studentPricing.plans.map((plan) => ({ ...plan })),
    });
    return view;
  },
};
</script>

<template>
    <div :class="$style.studentDetail">
        <div :class="$style.modalProfile">
            <VAvatar
                :class="$style.avatar"
                size="large"
                responsive
                :tone="colorFor(modal.data.color)"
                radius="default"
                mobile-radius="micro"
                :src="modal.data.avatarUrl"
                :name="modal.data.name"
            />
            <span>
                <b>{{ modal.data.name }}</b>
                <small>{{ modal.data.username ? `@${modal.data.username}` : 'Telegram username не указан' }}</small>
            </span>
        </div>
        <div :class="$style.detailStats">
            <div :class="$style.detailStat">
                <b>{{ modal.data.paidLessons }}</b>
                <small>оплачено занятий</small>
            </div>
            <div :class="$style.detailStat">
                <VStatusBadge
                    :status="modal.data.paymentStatus"
                    :tone="statusClass(modal.data.paymentStatus)"
                    variant="value"
                    :label="statusLabel(modal.data.paymentStatus)"
                />
                <small>статус оплаты</small>
            </div>
        </div>
        <form
            v-if="state.role === 'teacher' && auth.user"
            :class="$style.setupForm"
            @submit.prevent="submitStudentSetup($event)">
            <h3>Данные ученика</h3>
            <input
                type="hidden"
                name="studentId"
                :value="modal.data.id" />
            <label :class="$style.setupField">
                <span>Ссылка на доску или материалы</span>
                <input
                    name="boardLink"
                    type="url"
                    maxlength="500"
                    placeholder="https://miro.com/..."
                    :value="modal.data.boardLink || ''" />
            </label>
            <label :class="$style.setupField">
                <span>Добавить оплаченные занятия</span>
                <input
                    name="additionalLessons"
                    type="number"
                    min="0"
                    max="100"
                    step="1"
                    :value="modal.data.additionalLessonsInput ?? '0'"
                    @input="modal.data.additionalLessonsInput = $event.target.value" />
                <small>Введите это число один раз. Например: добавьте 8 оплаченных занятий, затем внесите 5 прошедших уроков в календарь — останется 3.</small>
            </label>
            <section :class="$style.pricingSection">
                <div :class="$style.pricingSectionHeading">
                    <h3>Индивидуальные условия оплаты</h3>
                    <p>Пустые настройки используют общий прайс учителя.</p>
                </div>
                <label :class="$style.setupField">
                    <span>Индивидуальная цена одного урока, ₽</span>
                    <input
                        v-model="studentPricing.singleLessonPrice"
                        type="number"
                        min="0"
                        step="100"
                        placeholder="Общий прайс"
                        aria-label="Индивидуальная цена одного урока" />
                    <small>Пустое поле — общий прайс: {{ Number(state.teacher.singleLessonPrice || 0).toLocaleString('ru-RU') }} ₽.</small>
                </label>
                <div :class="$style.studentPlans">
                    <div :class="$style.studentPlansHeading">
                        <div>
                            <b>Индивидуальные абонементы</b>
                            <small>Пустой список — общие абонементы. Если добавить пакет, ученик увидит только эти пакеты.</small>
                        </div>
                        <AppButton
                            variant="outline"
                            size="small"
                            type="button"
                            @click="addStudentPlan">Добавить пакет</AppButton>
                    </div>
                    <div
                        v-for="(plan, index) in studentPricing.plans"
                        :key="plan.id || `new-${index}`"
                        :class="$style.studentPlanRow">
                        <label :class="$style.setupField">
                            <span>Количество занятий</span>
                            <input
                                v-model.number="plan.lessons"
                                type="number"
                                min="1"
                                max="100"
                                step="1"
                                required />
                        </label>
                        <label :class="$style.setupField">
                            <span>Цена, ₽</span>
                            <input
                                v-model.number="plan.price"
                                type="number"
                                min="0"
                                step="100"
                                required />
                        </label>
                        <label :class="$style.planActiveToggle">
                            <input v-model="plan.active" type="checkbox" />
                            Активен
                        </label>
                        <AppButton
                            variant="ghost"
                            size="small"
                            type="button"
                            @click="removeStudentPlan(index)">Удалить</AppButton>
                    </div>
                </div>
            </section>
            <AppButton
                type="submit"
                :loading="modal.busy">Сохранить данные</AppButton>
        </form>
        <h3>История посещаемости</h3>
        <div
            v-for="item in modal.data.attendance || []"
            :key="`${item.date}-${item.time}`"
            :class="$style.historyRow">
            <span>{{ cap(formatDay(item.date)) }} · {{ item.time }}</span>
            <VStatusBadge
                :status="item.status"
                tone="muted"
                variant="text"
                :label="item.status"
            />
        </div>
        <VModalActions :class="$style.modalActions">
            <AppButton
                v-if="state.role === 'teacher' && auth.user && !modal.data.telegramId && !modal.data.authUserId"
                variant="secondary"
                @click="createStudentInvitation(modal.data.id)">Создать ссылку-приглашение</AppButton>
            <AppButton
                v-if="state.role === 'teacher' && attendanceLesson"
                variant="secondary"
                @click="markAttendance(modal.data, attendanceLesson)">Отметить · {{ cap(formatDay(attendanceLesson.date)) }} в {{ attendanceLesson.time }}</AppButton>
            <AppButton
                variant="outline"
                @click="openChat(modal.data.id)">Написать ученику</AppButton>
            <AppButton
                variant="secondary"
                @click="openHomeworkForm(modal.data.id)">Прикрепить ДЗ</AppButton>
            <AppButton
                variant="ghost"
                @click="closeModal">Закрыть</AppButton>
        </VModalActions>
    </div>
</template>

<style lang="scss" module>
.historyRow {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    padding: 8px 0;
    border-bottom: 1px solid var(--line);
    font-size: 10px;

    &:last-child {
        border: 0;
    }
}

[data-theme=darked] {
    .historyRow {
        border-color: var(--line);
    }
}

.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 18px;
}

.setupForm {
    display: grid;
    gap: 12px;
    margin: 18px 0 22px;
    padding: 15px;
    border: 1px solid var(--line);
    border-radius: 15px;
    background: var(--canvas);

    h3 {
        margin: 0;
    }
}

.setupField {
    display: grid;
    gap: 6px;

    > span {
        color: var(--ink);
        font-size: 12px;
        font-weight: 650;
    }

    > small {
        color: var(--muted);
        font-size: 10px;
        line-height: 1.45;
    }

    input {
        width: 100%;
        min-width: 0;
        min-height: 42px;
        padding: 9px 11px;
        border: 1px solid var(--line);
        border-radius: 10px;
        outline: none;
        background: var(--surface);
        color: var(--ink);
        font: inherit;

        &:focus {
            border-color: var(--purple);
            box-shadow: 0 0 0 3px color-mix(in srgb, var(--purple) 10%, transparent);
        }
    }
}

.pricingSection {
    display: grid;
    gap: $gap;
    padding-top: 14px;
    border-top: 1px solid var(--line);

    @include respond-to(mobile) {
        gap: $gap-sm;
    }
}

.pricingSectionHeading {
    display: grid;
    gap: 4px;

    h3,
    p {
        margin: 0;
    }

    p {
        color: var(--muted);
        font-size: 11px;
        line-height: 1.45;
    }
}

.studentPlans {
    display: grid;
    gap: 10px;
}

.studentPlansHeading {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 12px;

    > div {
        display: grid;
        gap: 4px;
    }

    b {
        color: var(--ink);
        font-size: 12px;
    }

    small {
        max-width: 360px;
        color: var(--muted);
        font-size: 10px;
        line-height: 1.45;
    }
}

.studentPlanRow {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) auto auto;
    align-items: end;
    gap: 8px;
    padding: 10px;
    border: 1px solid var(--line);
    border-radius: $radius-mini;
    background: var(--surface);
}

.planActiveToggle {
    display: flex;
    align-items: center;
    gap: 6px;
    min-height: 42px;
    color: var(--ink);
    font-size: 11px;
    white-space: nowrap;
}

.modalProfile {
    display: flex;
    align-items: center;
    gap: $gap-sm;
    margin-bottom: 16px;
    padding: $padding-mobile;
    border-radius: $radius;
    background: var(--canvas);

    .avatar {
        @include text(px1);
        font-weight: 300;
    }

    > span:last-child {
        display: grid;
        gap: 4px;
    }

    b {
        display: block;
        font-size: 13px;
    }

    small {
        display: block;
        margin-top: 5px;
        color: var(--muted);
        font-size: 10px;
    }
}

.detailStats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 9px;
    margin: 15px 0;
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
    .detailStats {
        gap: 6px;
    }

    .detailStat {
        padding: 10px 8px;

        b {
            font-size: 15px;
        }

        small {
            font-size: 8px;
        }
    }

    .studentPlansHeading {
        flex-direction: column;
    }

    .studentPlanRow {
        grid-template-columns: repeat(2, minmax(0, 1fr));
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

.mint {
    color: var(--green);
    background: var(--mint);
}

[data-theme=darked] {
    .mint {
        color: var(--green);
        background: $dark-mint;
    }
}

.studentDetail {
    --module-placeholder: 0;
}
</style>
