-- Incremental fixes for Telegram notifications.
-- Run in Supabase Dashboard > SQL Editor after the existing app migrations.

-- Lesson context is used by both the in-app notification list and Telegram queue.
alter table public.notifications
  add column if not exists lesson_id uuid references public.lessons (id) on delete set null,
  add column if not exists lesson_outcome text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'notifications_lesson_outcome_check'
      and conrelid = 'public.notifications'::regclass
  ) then
    alter table public.notifications
      add constraint notifications_lesson_outcome_check
      check (lesson_outcome in ('awaiting', 'rescheduled', 'cancelled'));
  end if;
end;
$$;

-- Some students are added by Telegram ID before they have linked a Mini App
-- profile. Keep the chat ID in the queue so those messages can still be sent
-- after the student has pressed Start in the bot.
create table if not exists public.telegram_message_queue (
  id uuid primary key default gen_random_uuid(),
  event_key text not null unique,
  recipient_profile_id uuid references public.profiles (id) on delete cascade,
  telegram_chat_id bigint,
  message text not null,
  status text not null default 'pending'
    check (status in ('pending', 'sending', 'sent', 'failed')),
  attempt_count integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  last_error text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sent_at timestamptz
);

alter table public.telegram_message_queue
  alter column recipient_profile_id drop not null,
  add column if not exists telegram_chat_id bigint;

update public.telegram_message_queue q
set telegram_chat_id = p.telegram_id
from public.profiles p
where q.recipient_profile_id = p.id
  and q.telegram_chat_id is null
  and p.telegram_id is not null;

update public.telegram_message_queue
set status = 'pending', next_attempt_at = now(), updated_at = now()
where status = 'failed'
  and telegram_chat_id is not null
  and (
    lower(last_error) like '%chat not found%'
    or lower(last_error) like '%can''t initiate conversation%'
    or lower(last_error) like '%bot was blocked%'
  );

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'telegram_message_queue_recipient_check'
      and conrelid = 'public.telegram_message_queue'::regclass
  ) then
    alter table public.telegram_message_queue
      add constraint telegram_message_queue_recipient_check
      check (recipient_profile_id is not null or telegram_chat_id is not null);
  end if;
end;
$$;

create index if not exists telegram_message_queue_pending_idx
  on public.telegram_message_queue (next_attempt_at, created_at)
  where status in ('pending', 'sending');

alter table public.telegram_message_queue enable row level security;
revoke all on public.telegram_message_queue from anon, authenticated;
grant all on public.telegram_message_queue to service_role;

create or replace function public.enqueue_telegram_direct_message(
  p_event_key text,
  p_telegram_chat_id bigint,
  p_message text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_telegram_chat_id is null then
    return;
  end if;

  insert into public.telegram_message_queue (
    event_key, telegram_chat_id, message
  ) values (
    p_event_key, p_telegram_chat_id, p_message
  )
  on conflict (event_key) do nothing;
end;
$$;

revoke all on function public.enqueue_telegram_direct_message(text, bigint, text)
  from public, anon, authenticated;

create or replace function public.enqueue_telegram_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.telegram_message_queue (
    event_key, recipient_profile_id, telegram_chat_id, message
  )
  select
    'notification:' || new.id::text,
    new.recipient_profile_id,
    coalesce(p.telegram_id, s.telegram_id),
    new.title || case when new.body = '' then '' else E'\n' || new.body end
  from public.profiles p
  left join public.students s on s.id = new.student_id
  where p.id = new.recipient_profile_id
    and coalesce(p.telegram_id, s.telegram_id) is not null
  on conflict (event_key) do nothing;
  return new;
end;
$$;

revoke all on function public.enqueue_telegram_notification() from public, anon, authenticated;
drop trigger if exists telegram_queue_notification on public.notifications;
create trigger telegram_queue_notification
  after insert on public.notifications
  for each row execute function public.enqueue_telegram_notification();

create or replace function public.lesson_count_word(p_count integer)
returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when abs(coalesce(p_count, 0)) % 100 between 11 and 14 then 'занятий'
    when abs(coalesce(p_count, 0)) % 10 = 1 then 'занятие'
    when abs(coalesce(p_count, 0)) % 10 between 2 and 4 then 'занятия'
    else 'занятий'
  end;
$$;

create or replace function public.handle_payment_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_name text;
begin
  update public.students
  set payment_status = 'awaiting'
  where id = new.student_id;

  select s.name into v_student_name
  from public.students s
  where s.id = new.student_id;

  insert into public.notifications (recipient_profile_id, student_id, type, title, body)
  values (
    new.teacher_id,
    new.student_id,
    'payment_requested',
    'Новая заявка на оплату',
    'Ученик «' || coalesce(v_student_name, 'Без имени') || '» запросил абонемент на '
      || new.lesson_count || ' ' || public.lesson_count_word(new.lesson_count) || '.'
  );

  return new;
end;
$$;

create or replace function public.handle_payment_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_user_id uuid;
  v_student_telegram_id bigint;
  v_student_name text;
  v_lesson_word text;
begin
  if old.status is not distinct from new.status then
    return new;
  end if;

  select s.auth_user_id, s.telegram_id, s.name
  into v_student_user_id, v_student_telegram_id, v_student_name
  from public.students s
  where s.id = new.student_id;

  v_lesson_word := public.lesson_count_word(new.lesson_count);

  if new.status = 'confirmed' then
    update public.students
    set lessons_remaining = lessons_remaining + new.lesson_count,
        payment_status = 'paid',
        last_payment_at = current_date
    where id = new.student_id;

    insert into public.notifications (recipient_profile_id, student_id, type, title, body)
    values (
      new.teacher_id,
      new.student_id,
      'payment_confirmed_by_teacher',
      'Оплата подтверждена вами',
      'Вы подтвердили оплату ученика «' || coalesce(v_student_name, 'Без имени')
        || '» на ' || new.lesson_count || ' ' || v_lesson_word || '.'
    );

    if v_student_user_id is not null then
      insert into public.notifications (recipient_profile_id, student_id, type, title, body)
      values (
        v_student_user_id,
        new.student_id,
        'payment_confirmed',
        'Оплата подтверждена',
        'В абонемент добавлено ' || new.lesson_count || ' ' || v_lesson_word || '.'
      );
    else
      perform public.enqueue_telegram_direct_message(
        'payment-confirmed:' || new.id::text,
        v_student_telegram_id,
        'Оплата подтверждена' || E'\n' || 'В абонемент добавлено '
          || new.lesson_count || ' ' || v_lesson_word || '.'
      );
    end if;
  elsif new.status = 'rejected' then
    update public.students
    set payment_status = case when lessons_remaining > 0 then 'paid' else 'unpaid' end
    where id = new.student_id;

    if v_student_user_id is not null then
      insert into public.notifications (recipient_profile_id, student_id, type, title, body)
      values (
        v_student_user_id,
        new.student_id,
        'payment_rejected',
        'Заявка отклонена',
        coalesce(nullif(new.note, ''), 'Свяжитесь с преподавателем, чтобы уточнить детали.')
      );
    else
      perform public.enqueue_telegram_direct_message(
        'payment-rejected:' || new.id::text,
        v_student_telegram_id,
        'Заявка отклонена' || E'\n' || coalesce(nullif(new.note, ''), 'Свяжитесь с преподавателем, чтобы уточнить детали.')
      );
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.notify_new_homework()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_user_id uuid;
  v_student_telegram_id bigint;
begin
  select s.auth_user_id, s.telegram_id
  into v_student_user_id, v_student_telegram_id
  from public.students s
  where s.id = new.student_id;

  if v_student_user_id is not null then
    insert into public.notifications (recipient_profile_id, student_id, type, title, body)
    values (v_student_user_id, new.student_id, 'homework_created', 'Новое домашнее задание', new.title);
  else
    perform public.enqueue_telegram_direct_message(
      'homework-created:' || new.id::text,
      v_student_telegram_id,
      'Новое домашнее задание' || E'\n' || new.title
    );
  end if;
  return new;
end;
$$;

drop trigger if exists homework_created on public.homework;
create trigger homework_created
  after insert on public.homework
  for each row execute function public.notify_new_homework();

create or replace function public.notify_new_lesson()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_name text;
  v_student_user_id uuid;
  v_student_telegram_id bigint;
  v_teacher_name text;
  v_teacher_timezone text;
  v_student_timezone text;
  v_teacher_time text;
  v_student_time text;
begin
  if new.status <> 'scheduled' then
    return new;
  end if;

  select s.name, s.auth_user_id, s.telegram_id,
         coalesce(student_profile.timezone, 'Europe/Volgograd')
  into v_student_name, v_student_user_id, v_student_telegram_id, v_student_timezone
  from public.students s
  left join public.profiles student_profile on student_profile.id = s.auth_user_id
  where s.id = new.student_id;

  select coalesce(p.full_name, 'Преподаватель'), coalesce(p.timezone, 'Europe/Volgograd')
  into v_teacher_name, v_teacher_timezone
  from public.profiles p
  where p.id = new.teacher_id;

  v_teacher_time := to_char(new.starts_at at time zone coalesce(v_teacher_timezone, 'Europe/Volgograd'), 'DD.MM.YYYY "в" HH24:MI');
  v_student_time := to_char(new.starts_at at time zone coalesce(v_student_timezone, 'Europe/Volgograd'), 'DD.MM.YYYY "в" HH24:MI');

  insert into public.notifications (
    recipient_profile_id, student_id, lesson_id, type, title, body
  ) values (
    new.teacher_id,
    new.student_id,
    new.id,
    'lesson_created',
    'Новое занятие добавлено',
    coalesce(v_student_name, 'Ученик') || ' · «' || new.title || '» · ' || v_teacher_time
  );

  if v_student_user_id is not null then
    insert into public.notifications (
      recipient_profile_id, student_id, lesson_id, type, title, body
    ) values (
      v_student_user_id,
      new.student_id,
      new.id,
      'lesson_created',
      'Новое занятие в расписании',
      coalesce(v_teacher_name, 'Преподаватель') || ' добавил занятие «' || new.title || '» на ' || v_student_time || '.'
    );
  else
    perform public.enqueue_telegram_direct_message(
      'lesson-created:' || new.id::text || ':student',
      v_student_telegram_id,
      'Новое занятие в расписании' || E'\n' || coalesce(v_teacher_name, 'Преподаватель')
        || ' добавил занятие «' || new.title || '» на ' || v_student_time || '.'
    );
  end if;

  return new;
end;
$$;

revoke all on function public.notify_new_lesson() from public, anon, authenticated;
drop trigger if exists lesson_created_telegram_notification on public.lessons;
create trigger lesson_created_telegram_notification
  after insert on public.lessons
  for each row execute function public.notify_new_lesson();

create or replace function public.teacher_change_lesson(
  p_lesson_id uuid,
  p_action text,
  p_new_starts_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lesson public.lessons%rowtype;
  v_student_user_id uuid;
  v_student_telegram_id bigint;
  v_student_name text;
  v_teacher_timezone text;
  v_student_timezone text;
  v_teacher_time text;
  v_student_time text;
  v_teacher_title text;
  v_student_title text;
  v_teacher_body text;
  v_student_body text;
  v_outcome text;
begin
  if not public.is_teacher() then
    raise exception 'Only teachers can change lessons';
  end if;
  if p_action is null or p_action not in ('reschedule', 'cancel') then
    raise exception 'Unknown lesson action';
  end if;

  select l.* into v_lesson
  from public.lessons l
  where l.id = p_lesson_id
    and l.teacher_id = auth.uid()
    and l.status = 'scheduled'
    and l.starts_at > now()
  for update;

  if not found then
    raise exception 'Lesson not found or no longer available';
  end if;

  select s.name, s.auth_user_id, s.telegram_id,
         coalesce(student_profile.timezone, 'Europe/Volgograd')
  into v_student_name, v_student_user_id, v_student_telegram_id, v_student_timezone
  from public.students s
  left join public.profiles student_profile on student_profile.id = s.auth_user_id
  where s.id = v_lesson.student_id;

  select coalesce(p.timezone, 'Europe/Volgograd') into v_teacher_timezone
  from public.profiles p where p.id = auth.uid();

  if p_action = 'reschedule' then
    if p_new_starts_at is null or p_new_starts_at <= now() then
      raise exception 'Выберите время в будущем';
    end if;

    if exists (
      select 1 from public.lessons l
      where l.teacher_id = auth.uid()
        and l.id <> v_lesson.id
        and l.status = 'scheduled'
        and tstzrange(
          l.starts_at,
          l.starts_at + make_interval(mins => l.duration_minutes),
          '[)'
        ) && tstzrange(
          p_new_starts_at,
          p_new_starts_at + make_interval(mins => v_lesson.duration_minutes),
          '[)'
        )
    ) then
      raise exception 'На это время уже назначено занятие';
    end if;

    update public.lessons set starts_at = p_new_starts_at where id = v_lesson.id;
    v_outcome := 'rescheduled';
    v_teacher_title := 'Вы перенесли урок';
    v_student_title := 'Урок перенесён';
    v_teacher_time := to_char(p_new_starts_at at time zone coalesce(v_teacher_timezone, 'Europe/Volgograd'), 'DD.MM.YYYY "в" HH24:MI');
    v_student_time := to_char(p_new_starts_at at time zone coalesce(v_student_timezone, 'Europe/Volgograd'), 'DD.MM.YYYY "в" HH24:MI');
    v_teacher_body := 'Новое время занятия с ' || coalesce(v_student_name, 'учеником') || ': ' || v_teacher_time || '.';
    v_student_body := 'Новое время занятия: ' || v_student_time || '.';
  else
    update public.lessons set status = 'cancelled' where id = v_lesson.id;
    v_outcome := 'cancelled';
    v_teacher_title := 'Вы отменили урок';
    v_student_title := 'Урок отменён';
    v_teacher_body := 'Занятие с ' || coalesce(v_student_name, 'учеником') || ' отменено. Оплаченное занятие сохранено на балансе ученика.';
    v_student_body := 'Оплаченное занятие сохранено на балансе. Напишите преподавателю, чтобы договориться о новой записи.';
  end if;

  update public.notifications
  set lesson_outcome = v_outcome
  where lesson_id = v_lesson.id
    and type = 'lesson_reschedule_requested'
    and lesson_outcome = 'awaiting';

  insert into public.notifications (
    recipient_profile_id, student_id, lesson_id, lesson_outcome, type, title, body
  ) values (
    auth.uid(),
    v_lesson.student_id,
    v_lesson.id,
    v_outcome,
    case when p_action = 'reschedule' then 'lesson_rescheduled_by_teacher' else 'lesson_cancelled_by_teacher' end,
    v_teacher_title,
    v_teacher_body
  );

  if v_student_user_id is not null then
    insert into public.notifications (
      recipient_profile_id, student_id, lesson_id, lesson_outcome, type, title, body
    ) values (
      v_student_user_id,
      v_lesson.student_id,
      v_lesson.id,
      v_outcome,
      case when p_action = 'reschedule' then 'lesson_rescheduled' else 'lesson_cancelled' end,
      v_student_title,
      v_student_body
    );
  else
    perform public.enqueue_telegram_direct_message(
      'lesson-change:' || v_lesson.id::text || ':' || v_outcome || ':student:' || gen_random_uuid()::text,
      v_student_telegram_id,
      v_student_title || E'\n' || v_student_body
    );
  end if;
end;
$$;

revoke all on function public.teacher_change_lesson(uuid, text, timestamptz) from public, anon;
grant execute on function public.teacher_change_lesson(uuid, text, timestamptz) to authenticated;

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
    select l.id, l.teacher_id, l.student_id, l.title, l.starts_at,
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
      'lesson-1h:' || u.id::text || ':' || u.teacher_id::text as event_key,
      u.teacher_id as recipient_profile_id,
      u.teacher_telegram_id as telegram_chat_id,
      'Напоминание: через час урок «' || u.title || '» с ' || u.student_name ||
        ', в ' || to_char(u.starts_at at time zone u.teacher_timezone, 'HH24:MI') || '.' as message
    from upcoming u
    where u.teacher_telegram_id is not null

    union all

    select
      'lesson-1h:' || u.id::text || ':' || coalesce(u.auth_user_id::text, 'telegram:' || u.student_telegram_id::text) as event_key,
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

create or replace function public.notify_new_student_telegram_welcome()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_teacher_name text;
begin
  if new.telegram_id is null then
    return new;
  end if;

  select coalesce(p.full_name, 'Преподаватель') into v_teacher_name
  from public.profiles p
  where p.id = new.teacher_id;

  perform public.enqueue_telegram_direct_message(
    'student-welcome:' || new.id::text,
    new.telegram_id,
    'Привет, ' || new.name || '! 👋' || E'\n'
      || coalesce(v_teacher_name, 'Преподаватель') || ' добавил вас в MaxiEnglish.' || E'\n'
      || 'Для уведомлений откройте @MaxiEnglish_bot и нажмите «Запустить» или отправьте /start. Если вы уже это сделали, всё готово.' || E'\n'
      || 'Открыть приложение: https://maxienglish-33b6c.web.app'
  );
  return new;
end;
$$;

revoke all on function public.notify_new_student_telegram_welcome() from public, anon, authenticated;
drop trigger if exists student_telegram_welcome on public.students;
create trigger student_telegram_welcome
  after insert on public.students
  for each row execute function public.notify_new_student_telegram_welcome();

