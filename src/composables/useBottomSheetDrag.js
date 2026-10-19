import { computed, onBeforeUnmount, ref } from 'vue';

const DISMISS_TRANSITION_FALLBACK_MS = 400;

export function useBottomSheetDrag(onDismiss, threshold = 96) {
    const dragOffset = ref(0);
    const isDragging = ref(false);
    const isClosing = ref(false);
    let pointerId = null;
    let startY = 0;
    let lastY = 0;
    let lastMoveAt = 0;
    let dragHandle = null;
    let globalListenersAttached = false;
    let dismissTimer = null;
    let dismissElement = null;
    let dismissTransitionHandler = null;

    const sheetDragStyle = computed(() => {
        const style = {};

        if (dragOffset.value > 0) {
            style['--sheet-drag-offset'] = `${dragOffset.value}px`;
        }

        if (isDragging.value) {
            style.transition = 'none';
        }

        return style;
    });

    function startSheetDrag(event) {
        if (isDragging.value || isClosing.value) return;
        if (event.isPrimary === false || (event.pointerType === 'mouse' && event.button !== 0)) return;

        pointerId = event.pointerId;
        dragHandle = event.currentTarget;
        startY = event.clientY;
        lastY = event.clientY;
        lastMoveAt = performance.now();
        dragOffset.value = 0;
        isDragging.value = true;

        try {
            dragHandle.setPointerCapture?.(event.pointerId);
        } catch {
            // Pointer capture is unavailable in some embedded WebViews.
        }

        attachGlobalListeners();
        event.preventDefault();
    }

    function attachGlobalListeners() {
        if (globalListenersAttached || typeof window === 'undefined') return;

        window.addEventListener('pointermove', moveSheetDrag, { capture: true, passive: false });
        window.addEventListener('pointerup', endSheetDrag, true);
        window.addEventListener('pointercancel', cancelSheetDrag, true);
        globalListenersAttached = true;
    }

    function detachGlobalListeners() {
        if (!globalListenersAttached || typeof window === 'undefined') return;

        window.removeEventListener('pointermove', moveSheetDrag, true);
        window.removeEventListener('pointerup', endSheetDrag, true);
        window.removeEventListener('pointercancel', cancelSheetDrag, true);
        globalListenersAttached = false;
    }

    function moveSheetDrag(event) {
        if (!isDragging.value || event.pointerId !== pointerId) return;

        lastY = event.clientY;
        lastMoveAt = performance.now();
        const sheetHeight = dragHandle?.parentElement?.getBoundingClientRect().height;
        const maxOffset = sheetHeight || window.innerHeight;
        dragOffset.value = Math.min(maxOffset, Math.max(0, lastY - startY));
        if (event.cancelable) event.preventDefault();
    }

    function resetSheetDrag() {
        clearPendingDismiss();
        detachGlobalListeners();
        pointerId = null;
        dragHandle = null;
        dragOffset.value = 0;
        isDragging.value = false;
        isClosing.value = false;
    }

    function clearPendingDismiss() {
        if (dismissTimer !== null) {
            clearTimeout(dismissTimer);
            dismissTimer = null;
        }

        if (dismissElement && dismissTransitionHandler) {
            dismissElement.removeEventListener('transitionend', dismissTransitionHandler);
        }

        dismissElement = null;
        dismissTransitionHandler = null;
    }

    function finishDismiss() {
        if (!isClosing.value) return;

        clearPendingDismiss();
        isClosing.value = false;
        onDismiss();
    }

    function animateDismiss() {
        const panel = dragHandle?.parentElement;
        const panelHeight = panel?.getBoundingClientRect().height;
        const maxOffset = panelHeight || window.innerHeight;
        const currentOffset = dragOffset.value;

        isClosing.value = true;
        dragOffset.value = maxOffset;

        if (currentOffset >= maxOffset - 1) {
            finishDismiss();
            return;
        }

        if (panel) {
            dismissElement = panel;
            dismissTransitionHandler = (event) => {
                if (event.target === panel && event.propertyName === 'transform') {
                    finishDismiss();
                }
            };
            panel.addEventListener('transitionend', dismissTransitionHandler);
        }

        dismissTimer = setTimeout(finishDismiss, DISMISS_TRANSITION_FALLBACK_MS);
    }

    function endSheetDrag(event) {
        if (!isDragging.value || event.pointerId !== pointerId) return;

        const distance = Math.max(0, event.clientY - startY);
        const elapsed = Math.max(performance.now() - lastMoveAt, 1);
        const velocity = Math.max(0, event.clientY - lastY) / elapsed;
        const shouldDismiss = distance >= threshold || (distance >= 36 && velocity >= 0.55);

        detachGlobalListeners();
        pointerId = null;
        isDragging.value = false;

        if (shouldDismiss) {
            dragOffset.value = Math.max(dragOffset.value, distance);
            animateDismiss();
            dragHandle = null;
            return;
        }

        dragHandle = null;
        dragOffset.value = 0;
    }

    function cancelSheetDrag() {
        resetSheetDrag();
    }

    onBeforeUnmount(resetSheetDrag);

    return {
        sheetDragStyle,
        isDraggingSheet: isDragging,
        startSheetDrag,
        moveSheetDrag,
        endSheetDrag,
        cancelSheetDrag,
        resetSheetDrag,
    };
}
