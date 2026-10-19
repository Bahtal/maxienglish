-- Student invitations: create pending student rows without requiring a name or Telegram ID.
-- Run after schema.sql, telegram-identity.sql, and telegram-notification-fixes.sql,
-- then run student-confirmation-and-history.sql for RLS, balance, and history support.

-- Keep invitations usable if the separate lesson-links migration was skipped.
alter table public.students
  add column if not exists board_link text not null default ''
    check (char_length(board_link) <= 500 and (board_link = '' or board_link ~* '^https://'));

alter table public.students
  add column if not exists is_confirmed boolean not null default true;

create table if not exists public.student_invitations (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  expires_at timestamptz not null,
  used_at timestamptz,
  used_by_telegram_id bigint,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists student_invitations_student_created_idx
  on public.student_invitations (student_id, created_at desc);

do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'students'
  ) then
    execute 'alter publication supabase_realtime add table public.students';
  end if;
end;
$$;

alter table public.student_invitations enable row level security;
revoke all on public.student_invitations from anon, authenticated;
grant all on public.student_invitations to service_role;

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
    select 1 from public.students s
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

revoke all on function public.create_student_invitation(text, text, text)
  from public, anon;
revoke all on function public.create_student_invitation_for_existing(uuid, text)
  from public, anon;
revoke all on function public.accept_student_invitation(text, bigint, text, text)
  from public, anon, authenticated;

grant execute on function public.create_student_invitation(text, text, text)
  to authenticated;
grant execute on function public.create_student_invitation_for_existing(uuid, text)
  to authenticated;
grant execute on function public.accept_student_invitation(text, bigint, text, text)
  to service_role;
