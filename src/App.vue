<script setup>
import AppShell from './components/layout/AppShell.vue';
import { useWorkspace } from './composables/useWorkspace.js';

const workspace = useWorkspace();

function handleWorkspaceAction({ name, args = [] }) {
    const action = workspace[name];

    if (typeof action === 'function') {
        return action(...args);
    }
}
</script>

<template>
    <AppShell
        :workspace="workspace"
        @workspace-action="handleWorkspaceAction"
    />
</template>
