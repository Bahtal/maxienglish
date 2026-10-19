<script setup>
import { computed, defineAsyncComponent, onMounted, toRef, unref } from 'vue';
import AppSidebar from './AppSidebar.vue';
import AppHeader from './AppHeader.vue';
import PageHeading from './PageHeading.vue';
import BottomNavigation from './BottomNavigation.vue';
import ThemePickerPage from '../../pages/ThemePickerPage.vue';
import StudentHomePage from '../../pages/StudentHomePage.vue';
import TeacherHomePage from '../../pages/TeacherHomePage.vue';
import HomeworkPage from '../../pages/HomeworkPage.vue';
import CalendarPage from '../../pages/CalendarPage.vue';
import TeacherStudentsPage from '../../pages/TeacherStudentsPage.vue';
import TeacherProfilePage from '../../pages/TeacherProfilePage.vue';
import StudentProfilePage from '../../pages/StudentProfilePage.vue';
import ModalHost from './ModalHost.vue';
import ToastMessage from './ToastMessage.vue';
import VLoading from './VLoading.vue';
import AppButton from '../AppButton.vue';

const PaymentsPage = defineAsyncComponent(() => import('../../pages/PaymentsPage.vue'));

const props = defineProps({
    workspace: {
        type: Object,
        required: true,
    },
});

const emit = defineEmits(['workspace-action']);
const workspace = toRef(props, 'workspace');

onMounted(() => {
    props.workspace.applyTheme();
});

function forwardWorkspaceAction(action) {
    emit('workspace-action', action);
}

function retryCachedAuth() {
    emit('workspace-action', { name: 'authenticateTelegram', args: [] });
}

const isLoadApp = computed(() => {
    const currentWorkspace = workspace.value;

    const hasCachedWorkspace = unref(currentWorkspace.cachedWorkspace);
    const workspaceReady = unref(currentWorkspace.workspaceReady);

    return !currentWorkspace.isTelegram
        || (hasCachedWorkspace && workspaceReady && !currentWorkspace.auth.setup)
        || (!currentWorkspace.auth.loading && !currentWorkspace.auth.setup && !currentWorkspace.auth.error);
});

const isCachedReadOnly = computed(() => {
    const currentWorkspace = workspace.value;

    return unref(currentWorkspace.cachedWorkspace)
        && currentWorkspace.isTelegram
        && (currentWorkspace.auth.loading
            || !currentWorkspace.auth.user
            || currentWorkspace.auth.user.id !== unref(currentWorkspace.cachedWorkspaceUserId)
            || Boolean(currentWorkspace.auth.error));
});

const isTheme = computed(() => {
    return props.workspace.state.page === 'themes';
});

const isHomeStudent = computed(() => {
    return props.workspace.state.page === 'home' && props.workspace.state.role === 'student';
});

const isHomeTeacher = computed(() => {
    return props.workspace.state.page === 'home' && props.workspace.state.role === 'teacher';
});

const isHomework = computed(() => {
    return props.workspace.state.page === 'homework';
});

const isPayments = computed(() => {
    return props.workspace.state.page === 'payments';
});

const isCalendar = computed(() => {
    return props.workspace.state.page === 'calendar';
});

const isStudentsPage = computed(() => {
    return props.workspace.state.page === 'students' && props.workspace.state.role === 'teacher';
});

const isTeacherProfile = computed(() => {
    return props.workspace.state.page === 'profile' && props.workspace.state.role === 'teacher';
});

const isStudentProfile = computed(() => {
    return props.workspace.state.page === 'profile' && props.workspace.state.role === 'student';
});
</script>

<template>
    <VLoading
        v-if="!isLoadApp"
        :workspace="workspace"
        @workspace-action="forwardWorkspaceAction"
    />

    <template v-else>
        <div :class="$style.appShell" :data-theme="workspace.state.themeId">
            <div v-if="isCachedReadOnly" :class="$style.cacheStatus" role="status">
                <span :class="$style.cacheStatusDot"></span>
                <span :class="$style.cacheStatusText">
                    {{ workspace.auth.loading ? 'Сохранённые данные · проверяем доступ…' : workspace.auth.error ? 'Не удалось проверить доступ · данные только для чтения' : 'Нет подключения · показаны сохранённые данные' }}
                </span>
                <AppButton
                    :class="$style.cacheRetry"
                    variant="ghost"
                    size="small"
                    :loading="workspace.auth.loading"
                    :disabled="workspace.auth.loading"
                    @click="retryCachedAuth">
                    Повторить
                </AppButton>
            </div>

            <div :class="$style.interactionLayer" :inert="isCachedReadOnly">
                <AppSidebar :workspace="workspace" @workspace-action="forwardWorkspaceAction" />

                <main :class="$style.mainArea">
                    <AppHeader :workspace="workspace" @workspace-action="forwardWorkspaceAction" />

                    <section :class="[$style.content, $style[workspace.state.role]]">
                        <PageHeading
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <ThemePickerPage
                            v-if="isTheme"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <StudentHomePage
                            v-else-if="isHomeStudent"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <TeacherHomePage
                            v-else-if="isHomeTeacher"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <PaymentsPage
                            v-else-if="isPayments"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <HomeworkPage
                            v-else-if="isHomework"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <CalendarPage
                            v-else-if="isCalendar"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <TeacherStudentsPage
                            v-else-if="isStudentsPage"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <TeacherProfilePage
                            v-else-if="isTeacherProfile"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />

                        <StudentProfilePage
                            v-else-if="isStudentProfile"
                            :workspace="workspace"
                            @workspace-action="forwardWorkspaceAction"
                        />
                    </section>
                </main>

                <BottomNavigation :workspace="workspace" @workspace-action="forwardWorkspaceAction" />

                <ModalHost
                    :workspace="workspace"
                    @workspace-action="forwardWorkspaceAction"
                />

                <ToastMessage :workspace="workspace" @workspace-action="forwardWorkspaceAction" />
            </div>
        </div>
    </template>
</template>

<style lang="scss" module>
.appShell {
    color-scheme: light;

    --device-safe-bottom: var(--tg-safe-area-inset-bottom, env(safe-area-inset-bottom, 0px));
    --mobile-navigation-clearance: calc(72px + var(--device-safe-bottom) + 12px);

    @include apply-theme(default);

    font-family: $font-family;
    font-synthesis: none;
    text-rendering: optimizeLegibility;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;

    display: block;
    line-height: 1.45;
    min-height: var(--tg-viewport-stable-height, 100vh);
    background: var(--canvas);
    color: var(--ink);

    @include text(px2);

    button {
        font: inherit;
    }

    input {
        font: inherit;
    }

    textarea {
        font: inherit;
    }

    h1 {
        margin-top: 0;
        margin-bottom: 5px;
        letter-spacing: -0.9px;
        font-weight: 700;

        @include text(px2);
    }

    h2 {
        margin-top: 0;
    }

    h3 {
        margin-top: 0;
    }

    p {
        margin-top: 0;
    }
}

.cacheStatus {
    position: fixed;
    top: max(10px, env(safe-area-inset-top));
    left: 50%;
    z-index: 1000;
    display: flex;
    align-items: center;
    gap: 8px;
    max-width: calc(100vw - 32px);
    padding: 8px 12px;
    border: 1px solid var(--line);
    border-radius: 999px;
    background: var(--surface);
    box-shadow: 0 8px 24px color-mix(in srgb, var(--ink) 12%, transparent);
    color: var(--muted);
    line-height: 1.35;
    transform: translateX(-50%);

    @include text(px2);
}

.cacheStatusText {
    flex: 1 1 auto;
}

.cacheRetry {
    flex: 0 0 auto;
}

.interactionLayer {
    display: contents;
}

.cacheStatusDot {
    width: 7px;
    height: 7px;
    flex: 0 0 auto;
    border-radius: 50%;
    background: var(--amber);
}

.appShell, .appShell * {
    box-sizing: border-box;
}

@keyframes brand {
    0% {
        box-shadow: 0 0 22px var(--purple);
    }

    50% {
        box-shadow: 0 0 1px var(--purple-pale);
    }

    100% {
        box-shadow: 0 0 22px var(--purple);
    }
}

.mainArea {
    display: flex;
    flex-direction: column;
    margin-left: 290px;
    min-height: var(--tg-viewport-stable-height, 100vh);
    min-width: 0;
    padding: 0 42px 54px;
}

.content {
    width: 100%;
    min-width: 0;
    max-width: 1200px;
    margin: 0 auto;
}

@keyframes fade-in {
    from {
        opacity: 0;
    }

    to {
        opacity: 1;
    }
}

@keyframes rise-in {
    from {
        opacity: 0;
        transform: translateY(8px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}

@include respond-to(tablet) {
    .mainArea {
        padding: $padding;
    }
}

@include respond-to(mobile) {
    .mainArea {
        margin: 0;
        padding: 0 $padding-mobile var(--mobile-navigation-clearance);
    }
}

.appShell {
    &[data-theme=darked] {
        color-scheme: dark;

        @include apply-theme(darked);

        color: var(--ink);
        background: var(--canvas);
    }
}

.student {
    --module-placeholder: 0;
}

.teacher {
    --module-placeholder: 0;
}
</style>
