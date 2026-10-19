<script>
import { useWorkspaceView } from '../../composables/useWorkspaceView.js';

import AppButton from '../AppButton.vue';
import ValidatedField from '../ValidatedField.vue';

export default {
  props: { workspace: { type: Object, required: true } },
  emits: ['workspace-action'],
  components: { AppButton, ValidatedField },
  setup(props, { emit }) { return useWorkspaceView(props, emit); },
};
</script>

<template>
    <section :class="$style.teacherProfileSettings">
        <div :class="$style.sectionHeading">
            <div>
                <p :class="$style.eyebrow">НАСТРОЙКИ</p>
                <h2>Настройки профиля</h2>
                <p>Эту информацию о себе и занятиях увидят ученики.</p>
            </div>
        </div>
        <form
            :class="[$style.card, $style.teacherSettingsForm, $style.formStack]"
            @submit.prevent="submitWorkspaceForm($event, 'saveTeacherSettings')">
            <ValidatedField
                :model-value="profileForm.specialization"
                @update:model-value="setTeacherSetting('specialization', $event)"
                label="Предметы и специализация"
                :max-length="160" />
            <ValidatedField
                :model-value="profileForm.experience"
                @update:model-value="setTeacherSetting('experience', $event)"
                label="Стаж"
                placeholder="Например, 7 лет"
                :max-length="80" />
            <ValidatedField
                :model-value="profileForm.bio"
                @update:model-value="setTeacherSetting('bio', $event)"
                label="Описание для учеников"
                as="textarea"
                :max-length="1200" />
            <ValidatedField
                :model-value="profileForm.lessonFormat"
                @update:model-value="setTeacherSetting('lessonFormat', $event)"
                label="Формат занятий"
                :max-length="160" />
            <ValidatedField
                :model-value="profileForm.lessonRules"
                @update:model-value="setTeacherSetting('lessonRules', $event)"
                label="Правила занятий"
                as="textarea"
                :max-length="1200" />
            <ValidatedField
                :model-value="profileForm.zoomLink"
                @update:model-value="setTeacherSetting('zoomLink', $event)"
                label="Постоянная ссылка Zoom"
                type="url"
                placeholder="https://zoom.us/j/..."
                hint="Эту ссылку увидят все ваши ученики на главной."
                :max-length="500" />
            <div :class="$style.formGrid">
                <ValidatedField
                    :model-value="profileForm.duration"
                    @update:model-value="setTeacherSetting('duration', $event)"
                    label="Длительность урока, минут"
                    type="number"
                    :max-length="3"
                    :validator="(value)=>Number(value)>=15 && Number(value)<=240 || 'Укажите длительность от 15 до 240 минут.'" />
                <ValidatedField
                    :model-value="profileForm.price"
                    @update:model-value="setTeacherSetting('price', $event)"
                    label="Цена одного урока, ₽"
                    type="number"
                    :max-length="8" />
            </div>
            <section :class="$style.detailSection">
                <div :class="$style.sectionHeading">
                    <div>
                        <h3>Абонементы</h3>
                        <p>Пакеты для заявок на оплату.</p>
                    </div>
                    <AppButton
                        variant="outline"
                        size="small"
                        type="button"
                        @click="addPlan">Добавить пакет</AppButton>
                </div>
                <div
                    v-for="(plan,index) in profileForm.plans"
                    :key="plan.id || index"
                    :class="$style.subscriptionPlanEditorRow">
                    <label :class="$style.field">
                        <span>Занятий</span>
                        <input
                            :value="plan.lessons"
                            @input="setTeacherPlan(index, 'lessons', $event.target.value)"
                            type="number"
                            min="1"
                            max="100"
                            required />
                    </label>
                    <label :class="$style.field">
                        <span>Цена, ₽</span>
                        <input
                            :value="plan.price"
                            @input="setTeacherPlan(index, 'price', $event.target.value)"
                            type="number"
                            min="0"
                            step="100"
                            required />
                    </label>
                    <label :class="$style.planActiveToggle">
                        <input
                            :checked="plan.active"
                            @change="setTeacherPlan(index, 'active', $event.target.checked)"
                            type="checkbox" />
                        &#32;&#32;Активен&#32;
                    </label>
                    <AppButton
                        :class="$style.planRemove"
                        variant="ghost"
                        size="small"
                        type="button"
                        @click="removePlan(index)">Удалить</AppButton>
                </div>
                <div
                    v-if="!profileForm.plans.length"
                    :class="$style.emptyState">
                    <span>Добавьте пакет, чтобы ученик мог отправить заявку на оплату.</span>
                </div>
            </section>
            <div :class="$style.modalActions">
                <AppButton type="submit">Сохранить настройки</AppButton>
            </div>
        </form>
    </section>
</template>

<style lang="scss" module>
.eyebrow {
    margin: 0 0 5px;
    color: var(--ink);
    letter-spacing: 0.5px;
    font-weight: 700;

    @include text(px3);
}

.card {
    border: 1px solid var(--border-color);
    background: var(--surface);
    border-radius: $radius;
    box-shadow: var(--shadow);
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

    > svg {
        width: $svg;
        height: $svg;
        flex: 0 0 $svg;
        stroke: currentColor;
        fill: none;
    }
}

.emptyState {
    padding: 0 $padding;

    text-align: center;
    color: var(--muted);

    @include text(px2);

    b {
        display: block;
        margin-bottom: 5px;
        color: var(--ink);
        font-weight: 700;

        @include text(px2);
    }

    @include respond-to(mobile) {
        padding: 0 $padding-mobile;
    }
}

[data-theme=darked] {
    .field {
        input {
            color: var(--ink);
            border-color: var(--line);
            background-color: var(--surface);
        }

        textarea {
            color: var(--ink);
            border-color: var(--line);
            background-color: var(--surface);
        }

    }

    .card {
        border-color: var(--line);
        background-color: var(--surface);
    }

    .emptyState {
        b {
            color: var(--ink);
        }
    }
}

.formStack {
    display: grid;
    gap: 16px;
    padding: $padding;

    @include respond-to(mobile) {
        padding: $padding-mobile;
    }

    .field {
        display: grid;
        gap: 7px;
        min-width: 0;

        > span {
            color: var(--muted);
            font-size: 13px;
            font-weight: 650;
        }

        input {
            width: 100%;
            min-width: 0;
            min-height: 44px;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 11px;
            outline: none;
            background: var(--surface);
            color: var(--ink);
            font: inherit;

            &:focus {
                border-color: var(--purple);
                box-shadow: 0 0 0 3px color-mix(in srgb, var(--purple) 10%, transparent);
            }
        }

        textarea {
            width: 100%;
            min-width: 0;
            min-height: 110px;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 11px;
            outline: none;
            background: var(--surface);
            color: var(--ink);
            font: inherit;
            resize: vertical;

            &:focus {
                border-color: var(--purple);
                box-shadow: 0 0 0 3px color-mix(in srgb, var(--purple) 10%, transparent);
            }
        }

    }
}

.modalActions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 16px;
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

.teacherProfileSettings {
    > .sectionHeading {
        margin: 0 0 12px;
    }

    .sectionHeading {
        h2 {
            margin: 0;
            font-size: 18px;
        }

        .eyebrow {
            margin: 0 0 5px;
        }

        p:last-child {
            margin: 5px 0 0;
        }
    }
}

.subscriptionPlanEditorRow {
    display: grid;
    grid-template-columns: minmax(80px, 1fr) minmax(100px, 1fr) auto auto;
    align-items: end;
    gap: 10px;
    padding: 11px;
    border: 1px solid var(--line);
    border-radius: $radius-mini;

    .field {
        margin: 0;

        input {
            min-width: 0;
        }
    }
}

.planRemove {
    min-height: 38px;
    color: var(--red);
}

@include respond-to(mobile) {
    .subscriptionPlanEditorRow {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .planActiveToggle {
        grid-column: 1;
    }

    .planRemove {
        grid-column: 2;
        justify-self: end;
    }
}

.formGrid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: $gap;

    @include respond-to(mobile) {
        grid-template-columns: minmax(0, 1fr);
        gap: $gap-sm;
    }
}

.planActiveToggle {
    display: flex;
    min-height: 38px;
    align-items: center;
    gap: 7px;
    white-space: nowrap;

    input {
        accent-color: var(--purple);
    }
}

.teacherSettingsForm {
    --module-placeholder: 0;
}
</style>
