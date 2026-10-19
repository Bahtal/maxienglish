-- Optional per-student lesson price and subscription packages.
-- Apply after project-integrity-fixes.sql in Supabase SQL Editor.

begin;

alter table public.students
  add column if not exists custom_single_lesson_price_rub numeric(10, 2)
    check (custom_single_lesson_price_rub is null or custom_single_lesson_price_rub >= 0);

create table if not exists public.student_subscription_plans (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid not null,
  lesson_count integer not null check (lesson_count between 1 and 100),
  price_rub numeric(10, 2) not null check (price_rub >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (student_id, lesson_count),
  foreign key (student_id, teacher_id)
    references public.students (id, teacher_id) on delete cascade
);

create index if not exists student_subscription_plans_teacher_idx
  on public.student_subscription_plans (teacher_id, student_id, sort_order);

alter table public.student_subscription_plans enable row level security;
revoke all on public.student_subscription_plans from anon, authenticated;
grant select on public.student_subscription_plans to authenticated;

drop policy if exists "Teachers manage individual student plans" on public.student_subscription_plans;
create policy "Teachers manage individual student plans"
  on public.student_subscription_plans for all to authenticated
  using (
    teacher_id = auth.uid()
    and public.is_teacher()
    and public.can_manage_student(student_id)
  )
  with check (
    teacher_id = auth.uid()
    and public.is_teacher()
    and public.can_manage_student(student_id)
  );

drop policy if exists "Linked students can view their individual plans" on public.student_subscription_plans;
create policy "Linked students can view their individual plans"
  on public.student_subscription_plans for select to authenticated
  using (public.is_linked_student(student_id));

create or replace function public.teacher_update_student_profile(
  p_student_id uuid,
  p_board_link text,
  p_additional_lessons integer,
  p_custom_single_lesson_price_rub numeric,
  p_custom_plans jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student public.students%rowtype;
  v_board_link text := btrim(coalesce(p_board_link, ''));
  v_additional_lessons integer := coalesce(p_additional_lessons, 0);
  v_custom_price numeric(10, 2) := p_custom_single_lesson_price_rub;
  v_plan jsonb;
  v_lesson_count integer;
  v_price numeric(10, 2);
  v_sort_order integer := 0;
  v_seen_counts integer[] := '{}'::integer[];
  v_lessons_remaining integer;
begin
  if not public.is_teacher() then
    raise exception 'Only teachers can update student setup';
  end if;

  select * into v_student
  from public.students s
  where s.id = p_student_id
    and s.teacher_id = auth.uid()
    and s.is_confirmed
  for update;

  if not found then
    raise exception 'Student not found or invitation not confirmed';
  end if;

  if v_additional_lessons not between 0 and 100 then
    raise exception 'Количество занятий должно быть от 0 до 100';
  end if;
  if char_length(v_board_link) > 500
     or (v_board_link <> '' and v_board_link !~* '^https://[^[:space:]]+$') then
    raise exception 'Ссылка должна начинаться с https://';
  end if;
  if v_custom_price is not null and (v_custom_price < 0 or v_custom_price > 99999999) then
    raise exception 'Индивидуальная цена должна быть от 0 до 99 999 999';
  end if;
  if jsonb_typeof(coalesce(p_custom_plans, '[]'::jsonb)) <> 'array' then
    raise exception 'Индивидуальные абонементы должны быть списком';
  end if;

  for v_plan in select value from jsonb_array_elements(coalesce(p_custom_plans, '[]'::jsonb)) loop
    v_lesson_count := (v_plan ->> 'lesson_count')::integer;
    v_price := (v_plan ->> 'price_rub')::numeric(10, 2);

    if v_lesson_count is null or v_lesson_count not between 1 and 100
       or v_price is null or v_price < 0 or v_price > 99999999 then
      raise exception 'Проверьте индивидуальные абонементы';
    end if;
    if v_lesson_count = any(v_seen_counts) then
      raise exception 'Количество занятий в индивидуальных абонементах должно быть уникальным';
    end if;

    v_seen_counts := array_append(v_seen_counts, v_lesson_count);
  end loop;

  update public.students
  set board_link = v_board_link,
      custom_single_lesson_price_rub = v_custom_price,
      lessons_remaining = lessons_remaining + v_additional_lessons,
      payment_status = case
        when lessons_remaining + v_additional_lessons > 0 then 'paid'
        else 'unpaid'
      end
  where id = p_student_id
  returning lessons_remaining into v_lessons_remaining;

  delete from public.student_subscription_plans
  where student_id = p_student_id
    and teacher_id = auth.uid();

  for v_plan in select value from jsonb_array_elements(coalesce(p_custom_plans, '[]'::jsonb)) loop
    v_sort_order := v_sort_order + 1;
    insert into public.student_subscription_plans (
      teacher_id,
      student_id,
      lesson_count,
      price_rub,
      is_active,
      sort_order
    ) values (
      auth.uid(),
      p_student_id,
      (v_plan ->> 'lesson_count')::integer,
      (v_plan ->> 'price_rub')::numeric(10, 2),
      coalesce((v_plan ->> 'is_active')::boolean, true),
      v_sort_order
    );
  end loop;

  return jsonb_build_object('lessons_remaining', v_lessons_remaining);
end;
$$;

revoke all on function public.teacher_update_student_profile(uuid, text, integer, numeric, jsonb) from public, anon;
grant execute on function public.teacher_update_student_profile(uuid, text, integer, numeric, jsonb) to authenticated;

-- The selected package is resolved on the server for the authenticated student.
-- Individual packages replace teacher defaults only when at least one exists.
create or replace function public.request_student_payment(p_plan_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student public.students%rowtype;
  v_lesson_count integer;
  v_price numeric(10, 2);
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

  if exists (
    select 1
    from public.student_subscription_plans sp
    where sp.student_id = v_student.id
  ) then
    select sp.lesson_count, sp.price_rub
    into v_lesson_count, v_price
    from public.student_subscription_plans sp
    where sp.id = p_plan_id
      and sp.student_id = v_student.id
      and sp.teacher_id = v_student.teacher_id
      and sp.is_active;
  else
    select p.lesson_count, p.price_rub
    into v_lesson_count, v_price
    from public.subscription_plans p
    where p.id = p_plan_id
      and p.teacher_id = v_student.teacher_id
      and p.is_active;
  end if;

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
  values (v_student.teacher_id, v_student.id, v_lesson_count, v_price, 'awaiting')
  returning id into v_payment_id;

  return jsonb_build_object('status', 'created', 'payment_id', v_payment_id);
end;
$$;

revoke all on function public.request_student_payment(uuid) from public, anon;
grant execute on function public.request_student_payment(uuid) to authenticated;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = 'student_subscription_plans'
     ) then
    alter publication supabase_realtime add table public.student_subscription_plans;
  end if;
end;
$$;

commit;
