-- MaxiEnglish: initial Supabase schema.
-- Run once in Supabase Dashboard > SQL Editor.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'student' check (role in ('teacher', 'student')),
  full_name text not null default '',
  telegram_id bigint unique,
  telegram_username text,
  theme_id text not null default 'default',
  avatar_url text,
  avatar_path text,
  timezone text not null default 'Europe/Volgograd',
  created_at timestamptz not null default now()
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id),
  auth_user_id uuid unique references public.profiles (id) on delete set null,
  name text not null,
  email text,
  phone text,
  telegram_username text,
  color text not null default 'blue',
  lessons_remaining integer not null default 0 check (lessons_remaining >= 0),
  payment_status text not null default 'unpaid'
    check (payment_status in ('paid', 'awaiting', 'unpaid')),
  last_payment_at date,
  next_payment_at date,
  created_at timestamptz not null default now(),
  unique (id, teacher_id)
);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id),
  student_id uuid not null,
  starts_at timestamptz not null,
  duration_minutes integer not null default 60 check (duration_minutes between 15 and 240),
  title text not null default 'Английский',
  status text not null default 'scheduled'
    check (status in ('scheduled', 'completed', 'cancelled')),
  payment_status text not null default 'unpaid'
    check (payment_status in ('paid', 'awaiting', 'unpaid')),
  attendance_status text
    check (attendance_status in ('attended', 'missed', 'rescheduled')),
  schedule_revision integer not null default 0 check (schedule_revision >= 0),
  notes text not null default '',
  created_at timestamptz not null default now(),
  foreign key (student_id, teacher_id)
    references public.students (id, teacher_id) on delete cascade
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id),
  student_id uuid not null,
  lesson_count integer not null check (lesson_count between 1 and 100),
  amount_rub numeric(10, 2) not null default 0 check (amount_rub >= 0),
  status text not null default 'awaiting'
    check (status in ('awaiting', 'confirmed', 'rejected')),
  requested_at timestamptz not null default now(),
  confirmed_at timestamptz,
  note text not null default '',
  foreign key (student_id, teacher_id)
    references public.students (id, teacher_id) on delete cascade
);

create table public.homework (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id),
  student_id uuid not null,
  title text not null,
  description text not null default '',
  due_at date,
  label text not null default '' check (char_length(label) <= 40),
  file_path text,
  file_name text,
  status text not null default 'new' check (status in ('new', 'done')),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (student_id, teacher_id)
    references public.students (id, teacher_id) on delete cascade
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_profile_id uuid not null references public.profiles (id) on delete cascade,
  student_id uuid references public.students (id) on delete cascade,
  type text not null,
  title text not null,
  body text not null default '',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index students_teacher_id_idx on public.students (teacher_id);
create index lessons_teacher_starts_at_idx on public.lessons (teacher_id, starts_at);
create index lessons_student_starts_at_idx on public.lessons (student_id, starts_at);
create index payments_student_requested_at_idx on public.payments (student_id, requested_at desc);
create index homework_student_due_at_idx on public.homework (student_id, due_at);
create index homework_teacher_label_idx on public.homework (teacher_id, label) where label <> '';
create index notifications_recipient_created_at_idx
  on public.notifications (recipient_profile_id, created_at desc);

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

create or replace function public.is_teacher()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'teacher'
  );
$$;

create or replace function public.can_manage_student(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_teacher() and exists (
    select 1 from public.students s
    where s.id = p_student_id and s.teacher_id = auth.uid()
  );
$$;

create or replace function public.is_linked_student(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.students s
    where s.id = p_student_id and s.auth_user_id = auth.uid()
  );
$$;

create or replace function public.can_access_student(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.can_manage_student(p_student_id) or public.is_linked_student(p_student_id);
$$;

create or replace function public.can_view_profile(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_profile_id = auth.uid() or exists (
    select 1 from public.students s
    where (s.teacher_id = auth.uid() and s.auth_user_id = p_profile_id and public.is_teacher())
       or (s.auth_user_id = auth.uid() and s.teacher_id = p_profile_id)
  );
$$;

create or replace function public.is_student_for_teacher(
  p_student_id uuid,
  p_teacher_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.students s
    where s.id = p_student_id
      and s.teacher_id = p_teacher_id
      and s.auth_user_id = auth.uid()
  );
$$;

create or replace function public.handle_payment_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.students
  set payment_status = 'awaiting'
  where id = new.student_id;

  insert into public.notifications (recipient_profile_id, student_id, type, title, body)
  values (
    new.teacher_id,
    new.student_id,
    'payment_requested',
    'Новая заявка на оплату',
    'Ученик запросил абонемент на ' || new.lesson_count || ' занятий.'
  );

  return new;
end;
$$;

create trigger payment_requested
  after insert on public.payments
  for each row when (new.status = 'awaiting')
  execute function public.handle_payment_request();

create or replace function public.set_payment_confirmation_time()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'confirmed' and old.status is distinct from 'confirmed' then
    new.confirmed_at = coalesce(new.confirmed_at, now());
  end if;
  return new;
end;
$$;

create trigger payment_confirmation_time
  before update of status on public.payments
  for each row execute function public.set_payment_confirmation_time();

create or replace function public.handle_payment_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_user_id uuid;
begin
  if old.status is distinct from new.status and new.status = 'confirmed' then
    update public.students
    set lessons_remaining = lessons_remaining + new.lesson_count,
        payment_status = 'paid',
        last_payment_at = current_date
    where id = new.student_id
    returning auth_user_id into v_student_user_id;

    if v_student_user_id is not null then
      insert into public.notifications (recipient_profile_id, student_id, type, title, body)
      values (
        v_student_user_id,
        new.student_id,
        'payment_confirmed',
        'Оплата подтверждена',
        'В абонемент добавлено ' || new.lesson_count || ' занятий.'
      );
    end if;
  elsif old.status is distinct from new.status and new.status = 'rejected' then
    update public.students
    set payment_status = case when lessons_remaining > 0 then 'paid' else 'unpaid' end
    where id = new.student_id;

    select auth_user_id into v_student_user_id
    from public.students where id = new.student_id;

    if v_student_user_id is not null then
      insert into public.notifications (recipient_profile_id, student_id, type, title, body)
      values (v_student_user_id, new.student_id, 'payment_rejected', 'Заявка отклонена', new.note);
    end if;
  end if;
  return new;
end;
$$;

create trigger payment_status_changed
  after update of status on public.payments
  for each row execute function public.handle_payment_status_change();

create or replace function public.handle_lesson_attendance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
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

create trigger lesson_attendance_changed
  after update of attendance_status on public.lessons
  for each row execute function public.handle_lesson_attendance();

create or replace function public.notify_new_homework()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_user_id uuid;
begin
  select auth_user_id into v_student_user_id
  from public.students where id = new.student_id;

  if v_student_user_id is not null then
    insert into public.notifications (recipient_profile_id, student_id, type, title, body)
    values (v_student_user_id, new.student_id, 'homework_created', 'Новое домашнее задание', new.title);
  end if;
  return new;
end;
$$;

create trigger homework_created
  after insert on public.homework
  for each row execute function public.notify_new_homework();

create or replace function public.complete_homework(p_homework_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.homework h
  set status = 'done', completed_at = now()
  where h.id = p_homework_id
    and exists (
      select 1 from public.students s
      where s.id = h.student_id and s.auth_user_id = auth.uid()
    );

  if not found then
    raise exception 'Homework not found or not assigned to this student';
  end if;
end;
$$;

alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.lessons enable row level security;
alter table public.payments enable row level security;
alter table public.homework enable row level security;
alter table public.notifications enable row level security;

revoke all on public.profiles, public.students, public.lessons,
  public.payments, public.homework, public.notifications from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (full_name, telegram_username, theme_id) on public.profiles to authenticated;
grant select on public.students to authenticated;
grant select, insert, update on public.lessons to authenticated;
grant select, insert, update on public.payments to authenticated;
grant select, insert, update on public.homework to authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

create policy "Users can view related profiles"
  on public.profiles for select to authenticated
  using (public.can_view_profile(id));

create policy "Users can update their own profile details"
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Teacher can view assigned students and student can view self"
  on public.students for select to authenticated
  using (public.can_access_student(id));

create policy "Teacher can add students"
  on public.students for insert to authenticated
  with check (teacher_id = auth.uid() and public.is_teacher());

create policy "Teacher can update assigned students"
  on public.students for update to authenticated
  using (public.can_manage_student(id))
  with check (public.can_manage_student(id));

create policy "Teacher and student can view related lessons"
  on public.lessons for select to authenticated
  using (public.can_access_student(student_id));

create policy "Teacher can add lessons"
  on public.lessons for insert to authenticated
  with check (teacher_id = auth.uid() and public.can_manage_student(student_id));

create policy "Teacher can update lessons"
  on public.lessons for update to authenticated
  using (teacher_id = auth.uid() and public.can_manage_student(student_id))
  with check (teacher_id = auth.uid() and public.can_manage_student(student_id));

create policy "Teacher and student can view related payments"
  on public.payments for select to authenticated
  using (public.can_access_student(student_id));

create policy "Student can request own payment"
  on public.payments for insert to authenticated
  with check (
    status = 'awaiting'
    and public.is_student_for_teacher(student_id, teacher_id)
  );

create policy "Teacher can review payment requests"
  on public.payments for update to authenticated
  using (teacher_id = auth.uid() and public.can_manage_student(student_id))
  with check (teacher_id = auth.uid() and public.can_manage_student(student_id));

create policy "Teacher and student can view related homework"
  on public.homework for select to authenticated
  using (public.can_access_student(student_id));

create policy "Teacher can assign homework"
  on public.homework for insert to authenticated
  with check (teacher_id = auth.uid() and public.can_manage_student(student_id));

create policy "Teacher can update homework"
  on public.homework for update to authenticated
  using (teacher_id = auth.uid() and public.can_manage_student(student_id))
  with check (teacher_id = auth.uid() and public.can_manage_student(student_id));

create policy "Users can view their own notifications"
  on public.notifications for select to authenticated
  using (recipient_profile_id = auth.uid());

create policy "Users can mark their own notifications read"
  on public.notifications for update to authenticated
  using (recipient_profile_id = auth.uid())
  with check (recipient_profile_id = auth.uid());

revoke all on function public.is_teacher() from public, anon;
revoke all on function public.can_manage_student(uuid) from public, anon;
revoke all on function public.is_linked_student(uuid) from public, anon;
revoke all on function public.can_access_student(uuid) from public, anon;
revoke all on function public.can_view_profile(uuid) from public, anon;
revoke all on function public.is_student_for_teacher(uuid, uuid) from public, anon;
revoke all on function public.complete_homework(uuid) from public, anon;
revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
revoke all on function public.handle_payment_request() from public, anon, authenticated;
revoke all on function public.set_payment_confirmation_time() from public, anon, authenticated;
revoke all on function public.handle_payment_status_change() from public, anon, authenticated;
revoke all on function public.handle_lesson_attendance() from public, anon, authenticated;
revoke all on function public.notify_new_homework() from public, anon, authenticated;

grant execute on function public.is_teacher() to authenticated;
grant execute on function public.can_manage_student(uuid) to authenticated;
grant execute on function public.is_linked_student(uuid) to authenticated;
grant execute on function public.can_access_student(uuid) to authenticated;
grant execute on function public.can_view_profile(uuid) to authenticated;
grant execute on function public.is_student_for_teacher(uuid, uuid) to authenticated;
grant execute on function public.complete_homework(uuid) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'homework-files',
  'homework-files',
  false,
  10485760,
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'image/jpeg',
    'image/png',
    'audio/mpeg',
    'audio/mp4'
  ]
)
on conflict (id) do nothing;

create policy "Teacher can upload homework files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'homework-files'
    and public.can_manage_student((storage.foldername(name))[1]::uuid)
  );

create policy "Assigned student and teacher can read homework files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'homework-files'
    and public.can_access_student((storage.foldername(name))[1]::uuid)
  );

create policy "Teacher can update homework files"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'homework-files'
    and public.can_manage_student((storage.foldername(name))[1]::uuid)
  )
  with check (
    bucket_id = 'homework-files'
    and public.can_manage_student((storage.foldername(name))[1]::uuid)
  );

create policy "Teacher can delete homework files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'homework-files'
    and public.can_manage_student((storage.foldername(name))[1]::uuid)
  );

-- After creating the tutor account in Supabase Auth, promote it once from SQL Editor:
-- update public.profiles set role = 'teacher' where id = '<tutor-auth-user-uuid>';
-- Then students can register and the teacher can link them to student records.
