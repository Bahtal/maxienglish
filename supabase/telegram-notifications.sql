-- Telegram delivery queue and recurring lesson reminders.
-- Run once in Supabase Dashboard > SQL Editor after schema.sql and the other
-- existing application migrations have been applied.

create table if not exists public.telegram_message_queue (
  id uuid primary key default gen_random_uuid(),
  event_key text not null unique,
  recipient_profile_id uuid not null references public.profiles (id) on delete cascade,
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

create index if not exists telegram_message_queue_pending_idx
  on public.telegram_message_queue (next_attempt_at, created_at)
  where status in ('pending', 'sending');

alter table public.telegram_message_queue enable row level security;
revoke all on public.telegram_message_queue from anon, authenticated;
grant all on public.telegram_message_queue to service_role;

create or replace function public.enqueue_telegram_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.telegram_message_queue (event_key, recipient_profile_id, message)
  select
    'notification:' || new.id::text,
    new.recipient_profile_id,
    new.title || case when new.body = '' then '' else E'\n' || new.body end
  where exists (
    select 1 from public.profiles p
    where p.id = new.recipient_profile_id and p.telegram_id is not null
  )
  on conflict (event_key) do nothing;
  return new;
end;
$$;

revoke all on function public.enqueue_telegram_notification() from public, anon, authenticated;
drop trigger if exists telegram_queue_notification on public.notifications;
create trigger telegram_queue_notification
  after insert on public.notifications
  for each row execute function public.enqueue_telegram_notification();

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
    select l.id, l.teacher_id, l.student_id, l.title, l.starts_at, s.name as student_name,
           teacher.full_name as teacher_name, s.auth_user_id
    from public.lessons l
    join public.students s on s.id = l.student_id
    join public.profiles teacher on teacher.id = l.teacher_id
    where l.status = 'scheduled'
      and l.starts_at > now() + interval '57 minutes'
      and l.starts_at <= now() + interval '60 minutes'
  ), recipients as (
    select
      'lesson-1h:' || u.id::text || ':' || u.teacher_id::text as event_key,
      u.teacher_id as recipient_profile_id,
      'Напоминание: через час урок «' || u.title || '» с ' || u.student_name ||
        ', в ' || to_char(u.starts_at at time zone coalesce(teacher.timezone, 'Europe/Volgograd'), 'HH24:MI') || '.' as message
    from upcoming u
    join public.profiles teacher on teacher.id = u.teacher_id
    where teacher.telegram_id is not null

    union all

    select
      'lesson-1h:' || u.id::text || ':' || u.auth_user_id::text as event_key,
      u.auth_user_id as recipient_profile_id,
      'Напоминание: через час занятие «' || u.title || '» с ' ||
        coalesce(nullif(u.teacher_name, ''), 'преподавателем') || ', в ' ||
        to_char(u.starts_at at time zone coalesce(student.timezone, 'Europe/Volgograd'), 'HH24:MI') || '.' as message
    from upcoming u
    join public.profiles student on student.id = u.auth_user_id
    where u.auth_user_id is not null and student.telegram_id is not null
  )
  insert into public.telegram_message_queue (event_key, recipient_profile_id, message)
  select event_key, recipient_profile_id, message from recipients
  on conflict (event_key) do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

revoke all on function public.enqueue_telegram_lesson_reminders() from public, anon, authenticated;
grant execute on function public.enqueue_telegram_lesson_reminders() to service_role;

create or replace function public.claim_telegram_messages(p_limit integer default 50)
returns setof public.telegram_message_queue
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  with candidates as (
    select q.id
    from public.telegram_message_queue q
    where (q.status = 'pending' and q.next_attempt_at <= now())
       or (q.status = 'sending' and q.updated_at < now() - interval '5 minutes')
    order by q.created_at
    limit greatest(1, least(coalesce(p_limit, 50), 100))
    for update skip locked
  )
  update public.telegram_message_queue q
  set status = 'sending',
      attempt_count = q.attempt_count + 1,
      updated_at = now()
  from candidates c
  where q.id = c.id
  returning q.*;
end;
$$;

revoke all on function public.claim_telegram_messages(integer) from public, anon, authenticated;
grant execute on function public.claim_telegram_messages(integer) to service_role;

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
     or new.lessons_remaining not in (0, 1)
     or new.auth_user_id is null then
    return new;
  end if;

  if new.lessons_remaining = 0 then
    v_title := 'Нужна оплата занятий';
    v_body := 'Оплаченных занятий не осталось. Откройте приложение и отправьте заявку на абонемент.';
  else
    v_title := 'Осталось одно занятие';
    v_body := 'Скоро занятия закончатся. Откройте приложение, чтобы оплатить следующий абонемент.';
  end if;

  insert into public.notifications (recipient_profile_id, student_id, type, title, body)
  values (new.auth_user_id, new.id, 'payment_balance_low', v_title, v_body);
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

grant usage on schema public to service_role;
