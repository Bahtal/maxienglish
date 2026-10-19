-- Data-integrity fixes for the current MaxiEnglish schema.
-- Apply once in Supabase SQL Editor after student-invitations.sql,
-- student-confirmation-and-history.sql, teacher-profile-and-lesson-flow.sql,
-- lesson-links.sql, telegram-notifications.sql, and telegram-notification-fixes.sql.

begin;

-- Prevent concurrent requests from creating two pending payments for one student.
create or replace function public.guard_payment_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status <> 'awaiting' then
    return new;
  end if;

  perform 1
  from public.students s
  where s.id = new.student_id
    and s.teacher_id = new.teacher_id
  for update;

  if not found then
    raise exception 'student_teacher_mismatch';
  end if;

  if exists (
    select 1
    from public.payments p
    where p.student_id = new.student_id
      and p.status = 'awaiting'
      and p.id is distinct from new.id
  ) then
    raise exception 'payment_request_already_pending' using errcode = '23505';
  end if;

  return new;
end;
$$;

revoke all on function public.guard_payment_request() from public, anon, authenticated;
drop trigger if exists payment_request_guard on public.payments;
create trigger payment_request_guard
  before insert on public.payments
  for each row execute function public.guard_payment_request();

create or replace function public.request_student_payment(p_plan_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student public.students%rowtype;
  v_plan public.subscription_plans%rowtype;
  v_payment_id uuid;
begin
  if auth.uid() is null or public.is_teacher() then
    raise exception 'Only a linked student can request a subscription';
  end if;

  select * into v_student
  from public.students s
  where s.auth_user_id = auth.uid()
    and s.is_confirmed
  for update;

  if not found then
    raise exception 'Student profile is not linked';
  end if;

  select * into v_plan
  from public.subscription_plans p
  where p.id = p_plan_id
    and p.teacher_id = v_student.teacher_id
    and p.is_active;

  if not found then
    raise exception 'Subscription plan is unavailable';
  end if;

  select p.id into v_payment_id
  from public.payments p
  where p.student_id = v_student.id
    and p.status = 'awaiting'
  order by p.requested_at desc
  limit 1;

  if found then
    return jsonb_build_object('status', 'already_pending', 'payment_id', v_payment_id);
  end if;

  insert into public.payments (teacher_id, student_id, lesson_count, amount_rub, status)
  values (v_student.teacher_id, v_student.id, v_plan.lesson_count, v_plan.price_rub, 'awaiting')
  returning id into v_payment_id;

  return jsonb_build_object('status', 'created', 'payment_id', v_payment_id);
end;
$$;

revoke all on function public.request_student_payment(uuid) from public, anon;
grant execute on function public.request_student_payment(uuid) to authenticated;

-- A payment request can be reviewed once. Reconfirming a rejected request must
-- not credit the same lessons a second time.
create or replace function public.guard_payment_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if row(new.teacher_id, new.student_id, new.lesson_count, new.amount_rub, new.requested_at)
     is distinct from row(old.teacher_id, old.student_id, old.lesson_count, old.amount_rub, old.requested_at) then
    raise exception 'payment_request_details_are_immutable';
  end if;

  if old.status <> 'awaiting' and new.status is distinct from old.status then
    raise exception 'payment_status_is_final';
  end if;

  return new;
end;
$$;

revoke all on function public.guard_payment_update() from public, anon, authenticated;
drop trigger if exists payment_update_guard on public.payments;
create trigger payment_update_guard
  before update on public.payments
  for each row execute function public.guard_payment_update();

-- Track schedule edits so each appointment time gets its own reminder key.
alter table public.lessons
  add column if not exists schedule_revision integer not null default 0
    check (schedule_revision >= 0);

create or replace function public.guard_lesson_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.schedule_revision := 0;
  elsif new.starts_at is distinct from old.starts_at then
    new.schedule_revision := old.schedule_revision + 1;
  else
    new.schedule_revision := old.schedule_revision;
  end if;

  if new.attendance_status = 'attended' and new.starts_at >= now() then
    if tg_op = 'INSERT' then
      raise exception 'attended_lesson_must_be_in_past';
    elsif old.attendance_status is distinct from 'attended'
       or old.starts_at is distinct from new.starts_at then
      raise exception 'attended_lesson_must_be_in_past';
    end if;
  end if;

  if new.status = 'scheduled' then
    perform pg_advisory_xact_lock(hashtextextended(new.teacher_id::text, 0));

    if exists (
      select 1
      from public.lessons l
      where l.teacher_id = new.teacher_id
        and l.status = 'scheduled'
        and l.id is distinct from new.id
        and l.starts_at < new.starts_at + make_interval(mins => new.duration_minutes)
        and new.starts_at < l.starts_at + make_interval(mins => l.duration_minutes)
    ) then
      raise exception 'lesson_time_conflict';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.guard_lesson_write() from public, anon, authenticated;
drop trigger if exists lesson_write_guard on public.lessons;
create trigger lesson_write_guard
  before insert or update on public.lessons
  for each row execute function public.guard_lesson_write();

create or replace function public.clear_stale_lesson_reminders()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.starts_at is distinct from new.starts_at or old.status is distinct from new.status then
    delete from public.telegram_message_queue q
    where q.status = 'pending'
      and q.event_key like 'lesson-1h:' || new.id::text || ':%';
  end if;
  return new;
end;
$$;

revoke all on function public.clear_stale_lesson_reminders() from public, anon, authenticated;
drop trigger if exists lesson_clear_stale_reminders on public.lessons;
create trigger lesson_clear_stale_reminders
  after update of starts_at, status on public.lessons
  for each row execute function public.clear_stale_lesson_reminders();

-- Keep old reminder rows from being repeated when this migration is applied.
update public.telegram_message_queue q
set event_key = 'lesson-1h:' || l.id::text || ':0:teacher:' || l.teacher_id::text
from public.lessons l
where q.event_key = 'lesson-1h:' || l.id::text || ':' || l.teacher_id::text;

update public.telegram_message_queue q
set event_key = 'lesson-1h:' || l.id::text || ':0:student:' || coalesce(s.auth_user_id::text, 'telegram:' || s.telegram_id::text)
from public.lessons l
join public.students s on s.id = l.student_id
where q.event_key = 'lesson-1h:' || l.id::text || ':' || coalesce(s.auth_user_id::text, 'telegram:' || s.telegram_id::text);

create or replace function public.enqueue_telegram_lesson_reminders()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_inserted integer;
begin
  with upcoming as (
    select l.id, l.schedule_revision, l.teacher_id, l.student_id, l.title, l.starts_at,
           s.name as student_name, s.auth_user_id, s.telegram_id as student_telegram_id,
           coalesce(student.timezone, 'Europe/Volgograd') as student_timezone,
           teacher.full_name as teacher_name,
           coalesce(teacher.timezone, 'Europe/Volgograd') as teacher_timezone,
           teacher.telegram_id as teacher_telegram_id,
           student.telegram_id as linked_student_telegram_id
    from public.lessons l
    join public.students s on s.id = l.student_id
    join public.profiles teacher on teacher.id = l.teacher_id
    left join public.profiles student on student.id = s.auth_user_id
    where l.status = 'scheduled'
      and l.starts_at > now() + interval '57 minutes'
      and l.starts_at <= now() + interval '60 minutes'
  ), recipients as (
    select
      'lesson-1h:' || u.id::text || ':' || u.schedule_revision::text || ':teacher:' || u.teacher_id::text as event_key,
      u.teacher_id as recipient_profile_id,
      u.teacher_telegram_id as telegram_chat_id,
      'Напоминание: через час урок «' || u.title || '» с ' || u.student_name ||
        ', в ' || to_char(u.starts_at at time zone u.teacher_timezone, 'HH24:MI') || '.' as message
    from upcoming u
    where u.teacher_telegram_id is not null

    union all

    select
      'lesson-1h:' || u.id::text || ':' || u.schedule_revision::text || ':student:' || coalesce(u.auth_user_id::text, 'telegram:' || u.student_telegram_id::text) as event_key,
      u.auth_user_id as recipient_profile_id,
      coalesce(u.linked_student_telegram_id, u.student_telegram_id) as telegram_chat_id,
      'Напоминание: через час занятие «' || u.title || '» с ' ||
        coalesce(nullif(u.teacher_name, ''), 'преподавателем') || ', в ' ||
        to_char(u.starts_at at time zone u.student_timezone, 'HH24:MI') || '.' as message
    from upcoming u
    where coalesce(u.linked_student_telegram_id, u.student_telegram_id) is not null
  )
  insert into public.telegram_message_queue (event_key, recipient_profile_id, telegram_chat_id, message)
  select event_key, recipient_profile_id, telegram_chat_id, message from recipients
  on conflict (event_key) do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

revoke all on function public.enqueue_telegram_lesson_reminders() from public, anon, authenticated;
grant execute on function public.enqueue_telegram_lesson_reminders() to service_role;

-- Queue low-balance messages for Telegram-linked students who have not yet
-- linked a Mini App profile. Linked students continue through notifications.
create or replace function public.notify_low_lesson_balance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_title text;
  v_body text;
begin
  if new.lessons_remaining >= old.lessons_remaining
     or new.lessons_remaining not in (0, 1) then
    return new;
  end if;

  if new.lessons_remaining = 0 then
    v_title := 'Нужна оплата занятий';
    v_body := 'Оплаченных занятий не осталось. Откройте приложение и отправьте заявку на абонемент.';
  else
    v_title := 'Осталось одно занятие';
    v_body := 'Скоро закончатся оплаченные занятия. Можно заранее отправить заявку на абонемент в приложении.';
  end if;

  if new.auth_user_id is not null then
    insert into public.notifications (recipient_profile_id, student_id, type, title, body)
    values (new.auth_user_id, new.id, 'payment_balance_low', v_title, v_body);
  else
    perform public.enqueue_telegram_direct_message(
      'payment-balance-low:' || new.id::text || ':' || new.lessons_remaining::text || ':' || gen_random_uuid()::text,
      new.telegram_id,
      v_title || E'\n' || v_body
    );
  end if;

  return new;
end;
$$;

revoke all on function public.notify_low_lesson_balance() from public, anon, authenticated;
drop trigger if exists student_low_lesson_balance on public.students;
create trigger student_low_lesson_balance
  after update of lessons_remaining on public.students
  for each row
  when (new.lessons_remaining is distinct from old.lessons_remaining)
  execute function public.notify_low_lesson_balance();

-- Students can read the settings that appear in their teacher's profile.
drop policy if exists "Linked students can view teacher settings" on public.teacher_settings;
create policy "Linked students can view teacher settings"
  on public.teacher_settings for select to authenticated
  using (public.is_student_of_teacher(teacher_id));

-- Make teacher settings changes available to the app's Realtime subscription.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'teacher_settings'
     ) then
    alter publication supabase_realtime add table public.teacher_settings;
  end if;
end;
$$;

-- Remove only unused placeholders whose invitation expired and has no newer
-- active invitation when the teacher creates a replacement invitation.
create or replace function public.create_student_invitation(
  p_name text,
  p_board_link text,
  p_token_hash text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid;
  v_expires_at timestamptz := now() + interval '7 days';
begin
  if not public.is_teacher() then
    raise exception 'Only teachers can invite students';
  end if;
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid invitation token';
  end if;

  delete from public.students s
  where s.teacher_id = auth.uid()
    and not s.is_confirmed
    and s.auth_user_id is null
    and s.telegram_id is null
    and exists (
      select 1 from public.student_invitations old_invitation
      where old_invitation.student_id = s.id
        and old_invitation.used_at is null
        and old_invitation.revoked_at is null
        and old_invitation.expires_at <= now()
    )
    and not exists (
      select 1 from public.student_invitations active_invitation
      where active_invitation.student_id = s.id
        and active_invitation.used_at is null
        and active_invitation.revoked_at is null
        and active_invitation.expires_at > now()
    );

  insert into public.students (
    teacher_id, name, board_link, lessons_remaining, payment_status, is_confirmed
  ) values (
    auth.uid(), 'Новый ученик', '', 0, 'unpaid', false
  ) returning id into v_student_id;

  insert into public.student_invitations (teacher_id, student_id, token_hash, expires_at)
  values (auth.uid(), v_student_id, p_token_hash, v_expires_at);

  return jsonb_build_object('student_id', v_student_id, 'expires_at', v_expires_at);
end;
$$;

revoke all on function public.create_student_invitation(text, text, text) from public, anon;
grant execute on function public.create_student_invitation(text, text, text) to authenticated;

commit;
