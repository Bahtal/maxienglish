-- Updated Telegram notification copy. Apply after the existing MaxiEnglish SQL migrations.
-- Replaces function bodies only; existing triggers, delivery schedule, and queue behavior stay in place.

begin;

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
    'Новая заявка на оплату🦦',
    'Ученик „' || coalesce(v_student_name, 'Без имени') || '“ запросил абонемент на '
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
      'Оплата подтверждена вами🌼',
      'Вы подтвердили оплату ученика „' || coalesce(v_student_name, 'Без имени')
        || '“ на ' || new.lesson_count || ' ' || v_lesson_word || '🌼'
    );

    if v_student_user_id is not null then
      insert into public.notifications (recipient_profile_id, student_id, type, title, body)
      values (
        v_student_user_id,
        new.student_id,
        'payment_confirmed',
        'Оплата подтверждена🌼',
        'В абонемент добавлено ' || new.lesson_count || ' ' || v_lesson_word || '🌼'
      );
    else
      perform public.enqueue_telegram_direct_message(
        'payment-confirmed:' || new.id::text,
        v_student_telegram_id,
        'Оплата подтверждена🌼' || E'\n' || 'В абонемент добавлено '
          || new.lesson_count || ' ' || v_lesson_word || '🌼'
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
        'Заявка отклонена🌬️',
        coalesce(nullif(btrim(new.note), ''), 'Свяжитесь со мной, чтобы уточнить детали') || ' 🌬️'
      );
    else
      perform public.enqueue_telegram_direct_message(
        'payment-rejected:' || new.id::text,
        v_student_telegram_id,
        'Заявка отклонена🌬️' || E'\n' || coalesce(nullif(btrim(new.note), ''), 'Свяжитесь со мной, чтобы уточнить детали') || ' 🌬️'
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
    values (v_student_user_id, new.student_id, 'homework_created', '🌻Новое домашнее задание', new.title);
  else
    perform public.enqueue_telegram_direct_message(
      'homework-created:' || new.id::text,
      v_student_telegram_id,
      '🌻Новое домашнее задание' || E'\n' || new.title
    );
  end if;
  return new;
end;
$$;

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
    'Новое занятие добавлено✨',
    coalesce(v_student_name, 'Ученик') || ' · „' || new.title || '“ · ' || v_teacher_time || '✨'
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
      coalesce(v_teacher_name, 'Преподаватель') || ' добавил занятие „' || new.title || '“ на ' || v_student_time
    );
  else
    perform public.enqueue_telegram_direct_message(
      'lesson-created:' || new.id::text || ':student',
      v_student_telegram_id,
      'Новое занятие в расписании' || E'\n' || coalesce(v_teacher_name, 'Преподаватель')
        || ' добавил занятие „' || new.title || '“ на ' || v_student_time
    );
  end if;

  return new;
end;
$$;

create or replace function public.request_lesson_reschedule(p_lesson_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lesson public.lessons%rowtype;
  v_student_name text;
begin
  select l.* into v_lesson
  from public.lessons l
  join public.students s on s.id = l.student_id
  where l.id = p_lesson_id
    and s.auth_user_id = auth.uid()
    and l.status = 'scheduled'
    and l.starts_at > now()
  for update of l;

  if not found then
    raise exception 'Lesson not found or no longer available';
  end if;

  if exists (
    select 1 from public.notifications n
    where n.lesson_id = p_lesson_id
      and n.recipient_profile_id = v_lesson.teacher_id
      and n.type = 'lesson_reschedule_requested'
      and n.lesson_outcome = 'awaiting'
  ) then
    return false;
  end if;

  select s.name into v_student_name
  from public.students s where s.id = v_lesson.student_id;

  insert into public.notifications (
    recipient_profile_id, student_id, lesson_id, lesson_outcome, type, title, body
  ) values (
    v_lesson.teacher_id,
    v_lesson.student_id,
    v_lesson.id,
    'awaiting',
    'lesson_reschedule_requested',
    '🌜Запрос на перенос урока',
    '🌜' || coalesce(v_student_name, 'Ученик') || ' хочет обсудить перенос занятия.'
  );
  return true;
end;
$$;

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
    v_teacher_title := '🌚Вы перенесли урок';
    v_student_title := 'Урок перенесён';
    v_teacher_time := to_char(p_new_starts_at at time zone coalesce(v_teacher_timezone, 'Europe/Volgograd'), 'DD.MM.YYYY "в" HH24:MI');
    v_student_time := to_char(p_new_starts_at at time zone coalesce(v_student_timezone, 'Europe/Volgograd'), 'DD.MM.YYYY "в" HH24:MI');
    v_teacher_body := '🌚Новое время занятия с ' || coalesce(v_student_name, 'учеником') || ': ' || v_teacher_time || '.';
    v_student_body := 'Новое время занятия: ' || v_student_time || '✨';
  else
    update public.lessons set status = 'cancelled' where id = v_lesson.id;
    v_outcome := 'cancelled';
    v_teacher_title := 'Вы отменили урок🦥';
    v_student_title := 'Урок отменён🦥';
    v_teacher_body := 'Занятие с ' || coalesce(v_student_name, 'учеником') || ' отменено🦥. Оплаченное занятие сохранено на балансе ученика.';
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
      'Напоминание: через час урок „' || u.title || '“ с ' || u.student_name ||
        ', в ' || to_char(u.starts_at at time zone u.teacher_timezone, 'HH24:MI') || '💫' as message
    from upcoming u
    where u.teacher_telegram_id is not null

    union all

    select
      'lesson-1h:' || u.id::text || ':' || u.schedule_revision::text || ':student:' || coalesce(u.auth_user_id::text, 'telegram:' || u.student_telegram_id::text) as event_key,
      u.auth_user_id as recipient_profile_id,
      coalesce(u.linked_student_telegram_id, u.student_telegram_id) as telegram_chat_id,
      'Напоминание: через час занятие „' || u.title || '“ с ' ||
        coalesce(nullif(u.teacher_name, ''), 'преподавателем') || ', в ' ||
        to_char(u.starts_at at time zone u.student_timezone, 'HH24:MI') || '💫' as message
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
    v_title := 'Нужна оплата занятий☘️';
    v_body := 'Оплаченных занятий не осталось. Откройте приложение и отправьте заявку на абонемент☘️';
  else
    v_title := 'Осталось одно занятие💫';
    v_body := 'Скоро занятия закончатся. Откройте приложение, чтобы оплатить следующий абонемент🦦';
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
    'Добро пожаловать в MaxiEnglish' || E'\n'
      || 'Привет, ' || coalesce(nullif(new.name, ''), 'ученик')
      || '! Откройте @MaxiEnglish_bot и нажмите «Запустить» или отправьте /start, чтобы получать уведомления. '
      || 'После этого можно открыть приложение: https://maxienglish-33b6c.web.app ✨'
  );
  return new;
end;
$$;

commit;
