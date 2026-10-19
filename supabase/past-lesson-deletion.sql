-- Allow a teacher to permanently remove only a past lesson from their schedule.
-- The student's remaining balance is intentionally not changed.
-- Apply in Supabase SQL Editor after the current app migrations.

begin;

create or replace function public.teacher_delete_past_lesson(p_lesson_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lesson public.lessons%rowtype;
begin
  if not public.is_teacher() then
    raise exception 'Only teachers can delete lessons';
  end if;

  select l.* into v_lesson
  from public.lessons l
  where l.id = p_lesson_id
    and l.teacher_id = auth.uid()
  for update;

  if not found then
    raise exception 'Lesson not found';
  end if;

  if v_lesson.starts_at >= now() then
    raise exception 'Only past lessons can be deleted';
  end if;

  delete from public.telegram_message_queue q
  where q.status = 'pending'
    and (
      q.event_key like 'lesson-1h:' || v_lesson.id::text || ':%'
      or exists (
        select 1
        from public.notifications n
        where n.lesson_id = v_lesson.id
          and q.event_key = 'notification:' || n.id::text
      )
    );

  delete from public.notifications
  where lesson_id = v_lesson.id;

  delete from public.lessons
  where id = v_lesson.id
    and teacher_id = auth.uid();
end;
$$;

revoke all on function public.teacher_delete_past_lesson(uuid) from public, anon;
grant execute on function public.teacher_delete_past_lesson(uuid) to authenticated;

commit;
