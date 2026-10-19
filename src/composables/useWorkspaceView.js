const workspaceActions = [
    'addMonth',
    'addPlan',
    'authenticateTelegram',
    'changeLesson',
    'changeRole',
    'closeModal',
    'closeThemes',
    'confirmPayment',
    'copyText',
    'createHomework',
    'createLesson',
    'createStudent',
    'createStudentInvitation',
    'deletePastLesson',
    'go',
    'markAttendance',
    'markHomeworkDone',
    'markLessonPaid',
    'markNotificationsRead',
    'openChat',
    'openHomework',
    'openHomeworkForm',
    'openLesson',
    'openLessonForm',
    'openModal',
    'openNotification',
    'openPayment',
    'openPaymentHistory',
    'openProfileNextLesson',
    'openReschedule',
    'openStudent',
    'openStudentForm',
    'openTeacherSettings',
    'openThemes',
    'requestPayment',
    'requestReschedule',
    'removePlan',
    'saveTeacherSettings',
    'setTheme',
    'submitReschedule',
    'toggleNotifications',
    'updateSelectedDay',
    'updateTeacherSettings',
    'updateStudentSetup',
    'resetDemo',
    'setSelectedFilter',
];

export function useWorkspaceView(props, emit) {
    const view = {};

    // Read through the prop so a replacement workspace reaches every component.
    Object.keys(props.workspace).forEach((key) => {
        if (workspaceActions.includes(key)) return;

        Object.defineProperty(view, key, {
            enumerable: true,
            get: () => props.workspace[key],
        });
    });

    Object.defineProperty(view, 'workspace', {
        enumerable: true,
        get: () => props.workspace,
    });

    workspaceActions.forEach((name) => {
        view[name] = (...args) => {
            const actionArgs = args.filter((argument) => (
                typeof Event === 'undefined' || !(argument instanceof Event)
            ));

            emit('workspace-action', { name, args: actionArgs });
        };
    });

    view.submitWorkspaceForm = (event, actionName, extraPayload = {}) => {
        const form = new FormData(event.currentTarget);
        const payload = { ...Object.fromEntries(form.entries()), ...extraPayload };

        emit('workspace-action', { name: actionName, args: [payload] });
    };

    view.setTeacherSetting = (key, value) => {
        emit('workspace-action', {
            name: 'updateTeacherSettings',
            args: [{ [key]: value }],
        });
    };

    view.setTeacherPlan = (index, key, value) => {
        const plans = props.workspace.profileForm.plans.map((plan, planIndex) => (
            planIndex === index
                ? { ...plan, [key]: key === 'active' ? Boolean(value) : Number(value) }
                : { ...plan }
        ));

        emit('workspace-action', {
            name: 'updateTeacherSettings',
            args: [{ plans }],
        });
    };

    return view;
}
