import { watch } from 'vue';
import { useWorkspaceHomework } from './useWorkspaceHomework.js';
import { useWorkspaceInterface } from './useWorkspaceInterface.js';
import { useWorkspaceNotifications } from './useWorkspaceNotifications.js';
import { useWorkspacePayments } from './useWorkspacePayments.js';
import { useWorkspaceRemote } from './useWorkspaceRemote.js';
import { useWorkspaceSchedule } from './useWorkspaceSchedule.js';
import { useWorkspaceState } from './useWorkspaceState.js';
import { useWorkspaceStudents } from './useWorkspaceStudents.js';
import { useWorkspaceTeacherProfile } from './useWorkspaceTeacherProfile.js';

export function useWorkspace() {
    const workspace = useWorkspaceState();

    Object.assign(workspace, useWorkspaceInterface(workspace));
    Object.assign(workspace, useWorkspaceNotifications(workspace));
    Object.assign(workspace, useWorkspaceRemote(workspace));
    Object.assign(workspace, useWorkspaceSchedule(workspace));
    Object.assign(workspace, useWorkspaceHomework(workspace));
    Object.assign(workspace, useWorkspacePayments(workspace));
    Object.assign(workspace, useWorkspaceStudents(workspace));
    Object.assign(workspace, useWorkspaceTeacherProfile(workspace));

    watch(() => workspace.state.themeId, workspace.applyTheme, { immediate: true });
    watch(workspace.state, workspace.persist, { deep: true });
    watch(
        () => [workspace.state.page, workspace.state.role, workspace.state.teacher],
        ([page, role]) => {
            if (page === 'profile' && role === 'teacher') {
                workspace.hydrateTeacherSettings();
            }
        },
        { deep: true },
    );

    return workspace;
}
