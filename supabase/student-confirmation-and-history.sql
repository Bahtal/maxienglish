-- Hide invited students until they accept the Telegram invitation, and support
-- initial paid balances plus historical attended lessons.
-- Run in Supabase SQL Editor after student-invitations.sql.

begin;

alter table public.students
  add column if not exists is_confirmed boolean not null default true;

alter table public.students
  add column if not exists board_link text not null default ''
    check (char_length(board_link) <= 500 and (board_link = '' or board_link ~* '^https://'));

-- Invitations made before this migration also stay out of the roster until Start.
update public.students s
set is_confirmed = false
where s.telegram_id is null
  and s.auth_user_id is null
  and exists (
    select 1
    from public.student_invitations i
    where i.student_id = s.id
      and i.used_at is null
      and i.revoked_at is null
  );

create index if not exists students_teacher_confirmed_name_idx
  on public.students (teacher_id, is_confirmed, name);

-- Confirmation and balance changes go through the protected RPCs below.
-- Clients must not be able to mark an invitation confirmed directly.
revoke insert, update on public.students from authenticated;
grant select on public.students to authenticated;
grant all on public.students to service_role;

create or replace function public.can_access_student(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_linked_student(p_student_id)
    or exists (
      select 1
      from public.students s
      where s.id = p_student_id
        and s.teacher_id = auth.uid()
        and s.is_confirmed
        and public.is_teacher()
    );
$$;

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

  insert into public.students (
    teacher_id, name, board_link, lessons_remaining, payment_status, is_confirmed
  ) values (
    auth.uid(), 'Новый ученик', '', 0, 'unpaid', false
  ) returning id into v_student_id;

  insert into public.student_invitations (
    teacher_id, student_id, token_hash, expires_at
  ) values (
    auth.uid(), v_student_id, p_token_hash, v_expires_at
  );

  return jsonb_build_object('student_id', v_student_id, 'expires_at', v_expires_at);
end;
$$;

create or replace function public.create_student_invitation_for_existing(
  p_student_id uuid,
  p_token_hash text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_expires_at timestamptz := now() + interval '7 days';
begin
  if not public.is_teacher() then
    raise exception 'Only teachers can invite students';
  end if;
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid invitation token';
  end if;
  if not exists (
    select 1
    from public.students s
    where s.id = p_student_id
      and s.teacher_id = auth.uid()
      and s.telegram_id is null
      and s.auth_user_id is null
  ) then
    raise exception 'Ученик уже подключён или не найден';
  end if;

  update public.student_invitations
  set revoked_at = now()
  where student_id = p_student_id
    and used_at is null
    and revoked_at is null;

  update public.students
  set is_confirmed = false
  where id = p_student_id;

  insert into public.student_invitations (
    teacher_id, student_id, token_hash, expires_at
  ) values (
    auth.uid(), p_student_id, p_token_hash, v_expires_at
  );

  return jsonb_build_object('expires_at', v_expires_at);
end;
$$;

drop function if exists public.accept_student_invitation(text, bigint, text);

create or replace function public.accept_student_invitation(
  p_token_hash text,
  p_telegram_user_id bigint,
  p_telegram_username text default null,
  p_telegram_full_name text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_invitation public.student_invitations%rowtype;
  v_student public.students%rowtype;
  v_student_name text;
  v_teacher_name text;
  v_profile_id uuid;
  v_profile_role text;
begin
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$'
     or p_telegram_user_id is null
     or p_telegram_user_id <= 0 then
    return jsonb_build_object('status', 'invalid');
  end if;

  v_student_name := nullif(
    left(
      regexp_replace(btrim(coalesce(p_telegram_full_name, '')), '[[:space:]]+', ' ', 'g'),
      120
    ),
    ''
  );
  v_student_name := coalesce(v_student_name, 'Ученик');

  select * into v_invitation
  from public.student_invitations i
  where i.token_hash = p_token_hash
  for update;

  if not found then
    return jsonb_build_object('status', 'invalid');
  end if;

  if v_invitation.used_at is not null then
    if v_invitation.used_by_telegram_id = p_telegram_user_id then
      select s.name into v_student_name
      from public.students s where s.id = v_invitation.student_id;
      return jsonb_build_object('status', 'already_linked', 'student_name', v_student_name);
    end if;
    return jsonb_build_object('status', 'invalid');
  end if;

  if v_invitation.revoked_at is not null or v_invitation.expires_at <= now() then
    return jsonb_build_object('status', 'invalid');
  end if;

  select * into v_student
  from public.students s
  where s.id = v_invitation.student_id
    and s.teacher_id = v_invitation.teacher_id
  for update;

  if not found or v_student.telegram_id is not null or v_student.auth_user_id is not null then
    return jsonb_build_object('status', 'invalid');
  end if;

  select p.id, p.role into v_profile_id, v_profile_role
  from public.profiles p
  where p.telegram_id = p_telegram_user_id;

  if v_profile_role = 'teacher' then
    return jsonb_build_object('status', 'wrong_account_type');
  end if;

  if exists (
    select 1 from public.students other_student
    where other_student.id <> v_student.id
      and (other_student.telegram_id = p_telegram_user_id
        or (v_profile_id is not null and other_student.auth_user_id = v_profile_id))
  ) then
    return jsonb_build_object('status', 'account_already_linked');
  end if;

  update public.students
  set name = v_student_name,
      telegram_id = p_telegram_user_id,
      telegram_username = nullif(left(btrim(coalesce(p_telegram_username, '')), 32), ''),
      auth_user_id = v_profile_id,
      is_confirmed = true
  where id = v_student.id;

  update public.student_invitations
  set used_at = now(), used_by_telegram_id = p_telegram_user_id
  where id = v_invitation.id;

  select p.full_name into v_teacher_name
  from public.profiles p where p.id = v_invitation.teacher_id;

  insert into public.notifications (recipient_profile_id, student_id, type, title, body)
  values (
    v_invitation.teacher_id,
    v_student.id,
    'student_invitation_accepted',
    'Ученик подключился',
    v_student_name || ' принял приглашение в MaxiEnglish.'
  );

  return jsonb_build_object(
    'status', 'accepted',
    'student_name', v_student_name,
    'teacher_name', coalesce(v_teacher_name, 'преподаватель')
  );
end;
$$;

create or replace function public.teacher_update_student_setup(
  p_student_id uuid,
  p_board_link text,
  p_additional_lessons integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_board_link text := btrim(coalesce(p_board_link, ''));
  v_additional_lessons integer := coalesce(p_additional_lessons, 0);
  v_lessons_remaining integer;
begin
  if not public.is_teacher() then
    raise exception 'Only teachers can update student setup';
  end if;
  if v_additional_lessons not between 0 and 100 then
    raise exception 'Количество занятий должно быть от 0 до 100';
  end if;
  if char_length(v_board_link) > 500
     or (v_board_link <> '' and v_board_link !~* '^https://[^[:space:]]+$') then
    raise exception 'Ссылка должна начинаться с https://';
  end if;

  update public.students
  set board_link = v_board_link,
      lessons_remaining = lessons_remaining + v_additional_lessons,
      payment_status = case
        when lessons_remaining + v_additional_lessons > 0 then 'paid'
        else 'unpaid'
      end
  where id = p_student_id
    and teacher_id = auth.uid()
    and is_confirmed
  returning lessons_remaining into v_lessons_remaining;

  if not found then
    raise exception 'Ученик не найден или ещё не подтвердил приглашение';
  end if;

  return jsonb_build_object('lessons_remaining', v_lessons_remaining);
end;
$$;

create or replace function public.handle_lesson_attendance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.attendance_status = 'attended' then
      update public.students
      set lessons_remaining = greatest(lessons_remaining - 1, 0),
          payment_status = case when lessons_remaining > 1 then 'paid' else 'unpaid' end
      where id = new.student_id;
    end if;
    return new;
  end if;

  if old.attendance_status is distinct from 'attended'
     and new.attendance_status = 'attended' then
    update public.students
    set lessons_remaining = greatest(lessons_remaining - 1, 0),
        payment_status = case when lessons_remaining > 1 then 'paid' else 'unpaid' end
    where id = new.student_id;
  elsif old.attendance_status = 'attended'
     and new.attendance_status is distinct from 'attended' then
    update public.students
    set lessons_remaining = lessons_remaining + 1,
        payment_status = 'paid'
    where id = new.student_id;
  end if;
  return new;
end;
$$;

drop trigger if exists lesson_attendance_changed on public.lessons;
create trigger lesson_attendance_changed
  after insert or update on public.lessons
  for each row execute function public.handle_lesson_attendance();

revoke all on function public.create_student_invitation(text, text, text)
  from public, anon;
revoke all on function public.create_student_invitation_for_existing(uuid, text)
  from public, anon;
revoke all on function public.accept_student_invitation(text, bigint, text, text)
  from public, anon, authenticated;
revoke all on function public.teacher_update_student_setup(uuid, text, integer)
  from public, anon;
revoke all on function public.handle_lesson_attendance()
  from public, anon, authenticated;

grant execute on function public.create_student_invitation(text, text, text)
  to authenticated;
grant execute on function public.create_student_invitation_for_existing(uuid, text)
  to authenticated;
grant execute on function public.accept_student_invitation(text, bigint, text, text)
  to service_role;
grant execute on function public.teacher_update_student_setup(uuid, text, integer)
  to authenticated;

commit;
