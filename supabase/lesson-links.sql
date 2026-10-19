-- Add the teacher's shared Zoom URL and each student's personal lesson board URL.
-- Run in Supabase Dashboard > SQL Editor after teacher-profile-and-lesson-flow.sql.

alter table public.profiles
  add column if not exists zoom_link text not null default ''
    check (char_length(zoom_link) <= 500 and (zoom_link = '' or zoom_link ~* '^https://'));

alter table public.students
  add column if not exists board_link text not null default ''
    check (char_length(board_link) <= 500 and (board_link = '' or board_link ~* '^https://'));

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
      lesson_rules = left(coalesce(p_profile ->> 'lesson_rules', ''), 1000),
      zoom_link = left(coalesce(p_profile ->> 'zoom_link', ''), 500)
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
