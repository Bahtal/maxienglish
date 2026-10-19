-- Store one selected theme on each student's or teacher's own profile.
alter table public.profiles
  add column if not exists theme_id text not null default 'default';

-- Existing profile RLS only allows users to update their own row. Grant access
-- to this additional preference column without widening other profile fields.
grant update (theme_id) on public.profiles to authenticated;
