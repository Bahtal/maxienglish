-- Keep lesson removal teacher-owned and balance-neutral. Removing a lesson also
-- removes its in-app notices and any queued Telegram notifications.
begin;

create or replace function public.teacher_delete_lesson(p_lesson_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lesson public.lessons%rowtype;
begin
  if auth.uid() is null or public.is_teacher() is distinct from true then
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

revoke all on function public.teacher_delete_lesson(uuid) from public, anon;
grant execute on function public.teacher_delete_lesson(uuid) to authenticated;

-- Payment quantity is provided by the app, but its upper limit and price are
-- resolved from the authenticated student's own active plans and teacher rate.
create or replace function public.request_student_payment_quantity(p_lesson_count integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student public.students%rowtype;
  v_has_individual_plans boolean;
  v_lesson_count_limit integer;
  v_unit_price numeric(10, 2);
  v_amount numeric(10, 2);
  v_payment_id uuid;
begin
  if auth.uid() is null or public.is_teacher() then
    raise exception 'Only a linked student can request a subscription';
  end if;

  if p_lesson_count is null or p_lesson_count not between 1 and 100 then
    raise exception 'Lesson count must be between 1 and 100';
  end if;

  select * into v_student
  from public.students s
  where s.auth_user_id = auth.uid()
    and s.is_confirmed
  for update;

  if not found then
    raise exception 'Student profile is not linked';
  end if;

  select exists (
    select 1
    from public.student_subscription_plans sp
    where sp.student_id = v_student.id
  ) into v_has_individual_plans;

  if v_has_individual_plans then
    select max(sp.lesson_count)
    into v_lesson_count_limit
    from public.student_subscription_plans sp
    where sp.student_id = v_student.id
      and sp.teacher_id = v_student.teacher_id
      and sp.is_active;

    if v_student.custom_single_lesson_price_rub is not null then
      v_unit_price := v_student.custom_single_lesson_price_rub;
    else
      select round(sp.price_rub / sp.lesson_count, 2)
      into v_unit_price
      from public.student_subscription_plans sp
      where sp.student_id = v_student.id
        and sp.teacher_id = v_student.teacher_id
        and sp.is_active
      order by sp.lesson_count, sp.sort_order
      limit 1;
    end if;
  else
    select max(p.lesson_count)
    into v_lesson_count_limit
    from public.subscription_plans p
    where p.teacher_id = v_student.teacher_id
      and p.is_active;

    select ts.single_lesson_price_rub
    into v_unit_price
    from public.teacher_settings ts
    where ts.teacher_id = v_student.teacher_id;

    if v_unit_price is null then
      v_unit_price := 1200;
    end if;
  end if;

  if v_lesson_count_limit is null or p_lesson_count > v_lesson_count_limit then
    raise exception 'Selected lesson count is not available';
  end if;

  if v_unit_price is null then
    raise exception 'Lesson price is not configured';
  end if;

  if v_has_individual_plans then
    select sp.price_rub
    into v_amount
    from public.student_subscription_plans sp
    where sp.student_id = v_student.id
      and sp.teacher_id = v_student.teacher_id
      and sp.lesson_count = p_lesson_count
      and sp.is_active;
  else
    select p.price_rub
    into v_amount
    from public.subscription_plans p
    where p.teacher_id = v_student.teacher_id
      and p.lesson_count = p_lesson_count
      and p.is_active;
  end if;

  if v_amount is null then
    v_amount := round(v_unit_price * p_lesson_count, 2);
  else
    v_amount := round(v_amount, 2);
  end if;
  if v_amount > 99999999.99 then
    raise exception 'Payment amount is too large';
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
  values (v_student.teacher_id, v_student.id, p_lesson_count, v_amount, 'awaiting')
  returning id into v_payment_id;

  return jsonb_build_object('status', 'created', 'payment_id', v_payment_id);
end;
$$;

revoke all on function public.request_student_payment_quantity(integer) from public, anon;
grant execute on function public.request_student_payment_quantity(integer) to authenticated;

commit;
