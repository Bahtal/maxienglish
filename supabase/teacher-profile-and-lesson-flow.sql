-- Teacher profile/settings, adjustable subscription plans, and lesson reschedule flow.
-- Run once in Supabase Dashboard > SQL Editor after schema.sql.

alter table public.profiles
  add column if not exists teacher_bio text not null default '',
  add column if not exists teacher_experience text not null default '',
  add column if not exists teacher_specialization text not null default '',
  add column if not exists lesson_format text not null default '',
  add column if not exists lesson_rules text not null default '';

alter table public.notifications
  add column if not exists lesson_id uuid references public.lessons (id) on delete set null,
  add column if not exists lesson_outcome text
    check (lesson_outcome in ('awaiting', 'rescheduled', 'cancelled'));

create index if not exists notifications_lesson_id_idx
  on public.notifications (lesson_id, type, lesson_outcome);

create table if not exists public.teacher_settings (
  teacher_id uuid primary key references public.profiles (id) on delete cascade,
  lesson_duration_minutes integer not null default 60
    check (lesson_duration_minutes between 15 and 240),
  single_lesson_price_rub numeric(10, 2) not null default 1200
    check (single_lesson_price_rub >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  lesson_count integer not null check (lesson_count between 1 and 100),
  price_rub numeric(10, 2) not null check (price_rub >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (teacher_id, lesson_count)
);

create index if not exists subscription_plans_teacher_active_idx
  on public.subscription_plans (teacher_id, is_active, sort_order);

alter table public.teacher_settings enable row level security;
alter table public.subscription_plans enable row level security;

revoke all on public.teacher_settings, public.subscription_plans from anon, authenticated;
grant select, insert, update on public.teacher_settings to authenticated;
grant select, insert, update, delete on public.subscription_plans to authenticated;
grant update (
  teacher_bio,
  teacher_experience,
  teacher_specialization,
  lesson_format,
  lesson_rules
) on public.profiles to authenticated;

create or replace function public.is_student_of_teacher(p_teacher_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.students s
    where s.teacher_id = p_teacher_id
      and s.auth_user_id = auth.uid()
  );
$$;

revoke all on function public.is_student_of_teacher(uuid) from public, anon;
grant execute on function public.is_student_of_teacher(uuid) to authenticated;

drop policy if exists "Teacher manages own settings" on public.teacher_settings;
create policy "Teacher manages own settings"
  on public.teacher_settings for all to authenticated
  using (teacher_id = auth.uid() and public.is_teacher())
  with check (teacher_id = auth.uid() and public.is_teacher());

drop policy if exists "Linked students can view teacher settings" on public.teacher_settings;
create policy "Linked students can view teacher settings"
  on public.teacher_settings for select to authenticated
  using (public.is_student_of_teacher(teacher_id));

drop policy if exists "Teacher manages plans and linked students view active plans" on public.subscription_plans;
create policy "Teacher manages plans and linked students view active plans"
  on public.subscription_plans for select to authenticated
  using (
    (teacher_id = auth.uid() and public.is_teacher())
    or (is_active and public.is_student_of_teacher(teacher_id))
  );

drop policy if exists "Teacher adds own plans" on public.subscription_plans;
create policy "Teacher adds own plans"
  on public.subscription_plans for insert to authenticated
  with check (teacher_id = auth.uid() and public.is_teacher());

drop policy if exists "Teacher updates own plans" on public.subscription_plans;
create policy "Teacher updates own plans"
  on public.subscription_plans for update to authenticated
  using (teacher_id = auth.uid() and public.is_teacher())
  with check (teacher_id = auth.uid() and public.is_teacher());

drop policy if exists "Teacher deletes own plans" on public.subscription_plans;
create policy "Teacher deletes own plans"
  on public.subscription_plans for delete to authenticated
  using (teacher_id = auth.uid() and public.is_teacher());

create or replace function public.ensure_teacher_defaults()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role = 'teacher' then
    insert into public.teacher_settings (teacher_id)
    values (new.id)
    on conflict (teacher_id) do nothing;

    if not exists (
      select 1 from public.subscription_plans sp where sp.teacher_id = new.id
    ) then
      insert into public.subscription_plans (teacher_id, lesson_count, price_rub, sort_order)
      values
        (new.id, 4, 4800, 1),
        (new.id, 8, 8800, 2),
        (new.id, 12, 12000, 3)
      on conflict (teacher_id, lesson_count) do nothing;
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.ensure_teacher_defaults() from public, anon, authenticated;
drop trigger if exists teacher_defaults_after_profile_change on public.profiles;
drop trigger if exists teacher_defaults_after_profile_insert on public.profiles;
drop trigger if exists teacher_defaults_after_role_change on public.profiles;
create trigger teacher_defaults_after_profile_insert
  after insert on public.profiles
  for each row
  when (new.role = 'teacher')
  execute function public.ensure_teacher_defaults();
create trigger teacher_defaults_after_role_change
  after update of role on public.profiles
  for each row
  when (new.role = 'teacher' and old.role is distinct from new.role)
  execute function public.ensure_teacher_defaults();

insert into public.teacher_settings (teacher_id)
select p.id from public.profiles p where p.role = 'teacher'
on conflict (teacher_id) do nothing;

insert into public.subscription_plans (teacher_id, lesson_count, price_rub, sort_order)
select p.id, defaults.lesson_count, defaults.price_rub, defaults.sort_order
from public.profiles p
cross join (values (4, 4800::numeric, 1), (8, 8800::numeric, 2), (12, 12000::numeric, 3))
  as defaults(lesson_count, price_rub, sort_order)
where p.role = 'teacher'
  and not exists (
    select 1 from public.subscription_plans existing where existing.teacher_id = p.id
  )
on conflict (teacher_id, lesson_count) do nothing;

create or replace function public.save_teacher_setup(
  p_profile jsonb,
  p_settings jsonb,
  p_plans jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan jsonb;
  v_lesson_count integer;
  v_price numeric(10, 2);
  v_sort_order integer := 0;
begin
  if not public.is_teacher() then
    raise exception 'Only teachers can change teacher settings';
  end if;
  if jsonb_typeof(coalesce(p_plans, '[]'::jsonb)) <> 'array' then
    raise exception 'Plans must be a list';
  end if;

  update public.profiles
  set teacher_bio = left(coalesce(p_profile ->> 'teacher_bio', ''), 2000),
      teacher_experience = left(coalesce(p_profile ->> 'teacher_experience', ''), 120),
      teacher_specialization = left(coalesce(p_profile ->> 'teacher_specialization', ''), 160),
      lesson_format = left(coalesce(p_profile ->> 'lesson_format', ''), 160),
      lesson_rules = left(coalesce(p_profile ->> 'lesson_rules', ''), 1000)
  where id = auth.uid();

  insert into public.teacher_settings (teacher_id, lesson_duration_minutes, single_lesson_price_rub, updated_at)
  values (
    auth.uid(),
    coalesce((p_settings ->> 'lesson_duration_minutes')::integer, 60),
    coalesce((p_settings ->> 'single_lesson_price_rub')::numeric, 1200),
    now()
  )
  on conflict (teacher_id) do update
  set lesson_duration_minutes = excluded.lesson_duration_minutes,
      single_lesson_price_rub = excluded.single_lesson_price_rub,
      updated_at = now();

  delete from public.subscription_plans where teacher_id = auth.uid();
  for v_plan in select value from jsonb_array_elements(coalesce(p_plans, '[]'::jsonb)) loop
    v_lesson_count := (v_plan ->> 'lesson_count')::integer;
    v_price := (v_plan ->> 'price_rub')::numeric;
    if v_lesson_count < 1 or v_lesson_count > 100 or v_price < 0 then
      raise exception 'Plan values are outside allowed limits';
    end if;
    v_sort_order := v_sort_order + 1;
    insert into public.subscription_plans (teacher_id, lesson_count, price_rub, is_active, sort_order)
    values (
      auth.uid(),
      v_lesson_count,
      v_price,
      coalesce((v_plan ->> 'is_active')::boolean, true),
      v_sort_order
    );
  end loop;
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
    'Запрос на перенос урока',
    coalesce(v_student_name, 'Ученик') || ' хочет обсудить перенос занятия.'
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
  v_timezone text;
  v_local_time text;
  v_title text;
  v_body text;
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
    v_title := 'Урок перенесён';
    select coalesce(p.timezone, 'Europe/Volgograd') into v_timezone
    from public.profiles p where p.id = auth.uid();
    v_local_time := to_char(p_new_starts_at at time zone coalesce(v_timezone, 'Europe/Volgograd'), 'DD.MM.YYYY')
      || ' в ' || to_char(p_new_starts_at at time zone coalesce(v_timezone, 'Europe/Volgograd'), 'HH24:MI');
    v_body := 'Новое время занятия: ' || v_local_time || '.';
  else
    update public.lessons set status = 'cancelled' where id = v_lesson.id;
    v_title := 'Урок отменён';
    v_body := 'Оплаченное занятие сохранено на балансе. Напишите преподавателю, чтобы договориться о новой записи.';
  end if;

  update public.notifications
  set lesson_outcome = case when p_action = 'reschedule' then 'rescheduled' else 'cancelled' end
  where lesson_id = v_lesson.id
    and type = 'lesson_reschedule_requested'
    and lesson_outcome = 'awaiting';

  select s.auth_user_id into v_student_user_id
  from public.students s where s.id = v_lesson.student_id;

  if v_student_user_id is not null then
    insert into public.notifications (
      recipient_profile_id, student_id, lesson_id, lesson_outcome, type, title, body
    ) values (
      v_student_user_id,
      v_lesson.student_id,
      v_lesson.id,
      case when p_action = 'reschedule' then 'rescheduled' else 'cancelled' end,
      case when p_action = 'reschedule' then 'lesson_rescheduled' else 'lesson_cancelled' end,
      v_title,
      v_body
    );
  end if;
end;
$$;

revoke all on function public.save_teacher_setup(jsonb, jsonb, jsonb) from public, anon;
revoke all on function public.request_lesson_reschedule(uuid) from public, anon;
revoke all on function public.teacher_change_lesson(uuid, text, timestamptz) from public, anon;
revoke all on function public.ensure_teacher_defaults() from public, anon, authenticated;
grant execute on function public.save_teacher_setup(jsonb, jsonb, jsonb) to authenticated;
grant execute on function public.request_lesson_reschedule(uuid) to authenticated;
grant execute on function public.teacher_change_lesson(uuid, text, timestamptz) to authenticated;

-- Enable live notifications alongside the existing live schedule/payment feeds.
do $$
declare
  v_table text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    return;
  end if;
  foreach v_table in array array['notifications', 'homework', 'subscription_plans', 'profiles', 'teacher_settings'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = v_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', v_table);
    end if;
  end loop;
end;
$$;
