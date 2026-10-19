import { supabase } from '../supabase.js';
import { isDoneHomework } from '../utils/appConfig.js';
import { readFileAsDataUrl } from '../utils/readFileAsDataUrl.js';

export function useWorkspaceHomework(workspace) {
    const { state, auth, modal } = workspace;
    const { persist, showToast, closeModal, loadRemoteWorkspace } = workspace;


    async function markHomeworkDone(item) {
        if (isDoneHomework(item)) {
            return;
        }

        modal.busy = true;
        if (auth.user) {
            const { error } = await supabase.rpc('complete_homework', { p_homework_id: item.id });
            if (error) {
                modal.busy = false; showToast(error.message || 'Не удалось отметить задание выполненным.');
                return;
            }
        }
        item.status = 'done';
        modal.busy = false;
        persist();
        showToast('Домашнее задание отмечено выполненным');

        if (auth.user) {
            await loadRemoteWorkspace();
        }
    }

    async function createHomework(payload) {
        if (modal.busy) return;

        const studentId = String(payload.studentId || '');
        const file = payload.attachment;
        const maxFileSize = auth.user ? 10 * 1024 * 1024 : 1024 * 1024;
        if (file?.size > maxFileSize) {
            showToast(auth.user ? 'Файл должен быть меньше 10 МБ.' : 'В локальном демо файл должен быть меньше 1 МБ.');
            return;
        }
        const item = { id: `hw-${Date.now()}`, studentId, title: String(payload.title || '').trim(), description: String(payload.description || '').trim(), dueDate: String(payload.dueDate || ''), label: String(payload.label || '').trim().replace(/\s+/g, ' ').slice(0, 40), filename: file?.name || '', status: 'new', createdAt: new Date().toISOString() };
        if (!item.title) {
            showToast('Введите название задания.');
            return;
        }

        modal.busy = true;
        let filePath = null;
        let fileUploaded = false;
        let fileAttached = false;
        let fileDefinitelyUnattached = false;
        try {
            if (auth.user) {
                if (file?.size) {
                    filePath = `${studentId}/${Date.now()}-${file.name.replace(/[^a-zA-Z0-9._-]/g, '_')}`;
                    const { error: uploadError } = await supabase.storage.from('homework-files').upload(filePath, file);
                    if (uploadError) {
                        showToast(uploadError.message || 'Не удалось загрузить файл.');
                        return;
                    }
                    fileUploaded = true;
                }

                const { error } = await supabase.from('homework').insert({ teacher_id: auth.user.id, student_id: studentId, title: item.title, description: item.description, due_at: item.dueDate || null, label: item.label, file_name: item.filename || null, file_path: filePath, status: 'new' });
                if (error) {
                    fileDefinitelyUnattached = true;
                    showToast(error.message || 'Не удалось создать домашнее задание.');
                    return;
                }
                fileAttached = true;
                closeModal();
                showToast('Домашнее задание добавлено');
                try {
                    await loadRemoteWorkspace();
                } catch (loadError) {
                    workspace.handleRemoteError(loadError);
                }
            } else {
                state.homework.unshift(item);
                if (file?.size) {
                    item.fileData = await readFileAsDataUrl(file);
                }
                closeModal();
                persist();
                showToast('Домашнее задание добавлено');
            }
        } catch (error) {
            showToast(error?.message || 'Не удалось создать домашнее задание.');
        } finally {
            if (fileUploaded && fileDefinitelyUnattached && !fileAttached) {
                try {
                    const { error } = await supabase.storage.from('homework-files').remove([filePath]);
                    if (error) console.warn('Could not remove an unused homework upload:', error.message);
                } catch (cleanupError) {
                    console.warn('Could not remove an unused homework upload:', cleanupError);
                }
            }
            modal.busy = false;
        }
    }

    return {
        markHomeworkDone,
        createHomework,
    };
}
