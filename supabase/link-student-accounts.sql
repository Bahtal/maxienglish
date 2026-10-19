-- Link a verified Supabase account to the tutor's student card by email.
-- Run after schema.sql in Supabase SQL Editor.

create or replace function public.link_student_account(p_auth_user_id uuid, p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid;
begin
  if p_email is null or btrim(p_email) = '' then
    return;
  end if;

  select s.id into v_student_id
  from public.students s
  where lower(s.email) = lower(p_email)
    and s.auth_user_id is null
    and not exists (
      select 1 from public.students linked
      where linked.auth_user_id = p_auth_user_id
    )
  order by s.created_at, s.id
  limit 1;

  if v_student_id is not null then
    update public.students
    set auth_user_id = p_auth_user_id
    where id = v_student_id and auth_user_id is null;
  end if;
end;
$$;

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

  if new.email_confirmed_at is not null then
    perform public.link_student_account(new.id, new.email);
  end if;

  return new;
end;
$$;

create or replace function public.handle_confirmed_auth_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.email_confirmed_at is not null
     and old.email_confirmed_at is distinct from new.email_confirmed_at then
    perform public.link_student_account(new.id, new.email);
  end if;
  return new;
end;
$$;

create or replace function public.link_existing_student_account()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_auth_user_id uuid;
begin
  if new.email is null or btrim(new.email) = '' or new.auth_user_id is not null then
    return new;
  end if;

  select u.id into v_auth_user_id
  from auth.users u
  where lower(u.email) = lower(new.email)
    and u.email_confirmed_at is not null
    and not exists (
      select 1 from public.students linked
      where linked.auth_user_id = u.id
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
create trigger link_student_after_email_confirmation
  after update of email_confirmed_at on auth.users
  for each row execute function public.handle_confirmed_auth_email();

drop trigger if exists link_existing_student_account on public.students;
create trigger link_existing_student_account
  after insert or update of email on public.students
  for each row execute function public.link_existing_student_account();

revoke all on function public.link_student_account(uuid, text) from public, anon, authenticated;
revoke all on function public.handle_confirmed_auth_email() from public, anon, authenticated;
revoke all on function public.link_existing_student_account() from public, anon, authenticated;
