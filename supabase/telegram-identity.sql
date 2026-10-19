-- Run after schema.sql and link-student-accounts.sql.
-- Students and teachers are matched to Telegram by the stable numeric user ID.

alter table public.students
  add column if not exists telegram_id bigint;

create unique index if not exists students_telegram_id_unique_idx
  on public.students (telegram_id)
  where telegram_id is not null;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, telegram_id, telegram_username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''),
    nullif(new.raw_user_meta_data ->> 'telegram_id', '')::bigint,
    nullif(new.raw_user_meta_data ->> 'telegram_username', '')
  );
  return new;
end;
$$;

create or replace function public.link_student_to_telegram_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.telegram_id is not null then
    update public.students s
    set auth_user_id = new.id
    where s.telegram_id = new.telegram_id
      and s.auth_user_id is null
      and not exists (
        select 1 from public.students linked
        where linked.auth_user_id = new.id
      );
  end if;
  return new;
end;
$$;

create or replace function public.link_telegram_profile_to_student()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_auth_user_id uuid;
begin
  if new.telegram_id is null or new.auth_user_id is not null then
    return new;
  end if;

  select p.id into v_auth_user_id
  from public.profiles p
  where p.telegram_id = new.telegram_id
    and not exists (
      select 1 from public.students linked
      where linked.auth_user_id = p.id
    )
  limit 1;

  if v_auth_user_id is not null then
    update public.students
    set auth_user_id = v_auth_user_id
    where id = new.id and auth_user_id is null;
  end if;
  return new;
end;
$$;

drop trigger if exists link_student_after_email_confirmation on auth.users;
drop trigger if exists link_existing_student_account on public.students;
drop function if exists public.link_student_account(uuid, text);
drop function if exists public.handle_confirmed_auth_email();
drop function if exists public.link_existing_student_account();
drop trigger if exists link_student_telegram_profile on public.profiles;
drop trigger if exists link_telegram_profile_student on public.students;

create trigger link_student_telegram_profile
  after insert or update of telegram_id on public.profiles
  for each row execute function public.link_student_to_telegram_profile();

create trigger link_telegram_profile_student
  after insert or update of telegram_id on public.students
  for each row execute function public.link_telegram_profile_to_student();

revoke all on function public.link_student_to_telegram_profile() from public, anon, authenticated;
revoke all on function public.link_telegram_profile_to_student() from public, anon, authenticated;
revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
