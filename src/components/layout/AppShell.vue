<script setup>
import { computed, defineAsyncComponent, onMounted, ref, toRef, unref } from 'vue';
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
const pageSlideDirection = ref('forward');
const pageSlideActive = ref(false);

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

const activePageComponent = computed(() => {
    if (isTheme.value) return ThemePickerPage;
    if (isHomeStudent.value) return StudentHomePage;
    if (isHomeTeacher.value) return TeacherHomePage;
    if (isPayments.value) return PaymentsPage;
    if (isHomework.value) return HomeworkPage;
    if (isCalendar.value) return CalendarPage;
    if (isStudentsPage.value) return TeacherStudentsPage;
    if (isTeacherProfile.value) return TeacherProfilePage;
    if (isStudentProfile.value) return StudentProfilePage;

    return null;
});

const pageTransitionName = computed(() => {
    return pageSlideActive.value
        ? `page-slide-${pageSlideDirection.value}`
        : 'page-static';
});

function startPageSlide(direction) {
    pageSlideDirection.value = direction;
    pageSlideActive.value = true;
}

function finishPageSlide() {
    pageSlideActive.value = false;
}
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

                        <div :class="$style.pageViewport">
                            <Transition
                                :name="pageTransitionName"
                                @after-enter="finishPageSlide"
                            >
                                <component
                                    :is="activePageComponent"
                                    v-if="activePageComponent"
                                    :key="`${workspace.state.role}:${workspace.state.page}`"
                                    :workspace="workspace"
                                    @workspace-action="forwardWorkspaceAction"
                                />
                            </Transition>
                        </div>
                    </section>
                </main>

                <BottomNavigation
                    :workspace="workspace"
                    @workspace-action="forwardWorkspaceAction"
                    @page-navigate="startPageSlide"
                />

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

    --device-safe-top: calc(
        var(--tg-safe-area-inset-top, env(safe-area-inset-top, 0px))
        + var(--tg-content-safe-area-inset-top, 0px)
    );
    --device-safe-bottom: calc(
        var(--tg-safe-area-inset-bottom, env(safe-area-inset-bottom, 0px))
        + var(--tg-content-safe-area-inset-bottom, 0px)
    );
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
    top: max(10px, var(--device-safe-top));
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

.pageViewport {
    display: grid;
    min-width: 0;

    > * {
        grid-area: 1 / 1;
        width: 100%;
        min-width: 0;
        height: fit-content;
    }
}

:global(.page-slide-forward-enter-active),
:global(.page-slide-forward-leave-active),
:global(.page-slide-backward-enter-active),
:global(.page-slide-backward-leave-active) {
    transition: transform $page-transition-duration $ease-in-out;
    will-change: transform;
}

:global(.page-slide-forward-enter-from) {
    transform: translateX(100%);
}

:global(.page-slide-forward-leave-to) {
    transform: translateX(-100%);
}

:global(.page-slide-backward-enter-from) {
    transform: translateX(-100%);
}

:global(.page-slide-backward-leave-to) {
    transform: translateX(100%);
}

@media (prefers-reduced-motion: reduce) {
    :global(.page-slide-forward-enter-active),
    :global(.page-slide-forward-leave-active),
    :global(.page-slide-backward-enter-active),
    :global(.page-slide-backward-leave-active) {
        transition: opacity 120ms ease-out;
        will-change: opacity;
    }

    :global(.page-slide-forward-enter-from),
    :global(.page-slide-forward-leave-to),
    :global(.page-slide-backward-enter-from),
    :global(.page-slide-backward-leave-to) {
        opacity: 0;
        transform: none;
    }
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
        padding: var(--device-safe-top) $padding-mobile var(--mobile-navigation-clearance);
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
