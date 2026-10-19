-- Store profile photos privately so Mini Apps do not depend on Telegram's
-- image host being reachable from the user's device.
alter table public.profiles
  add column if not exists avatar_url text;

alter table public.profiles
  add column if not exists avatar_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-avatars',
  'profile-avatars',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Related users can view profile avatars" on storage.objects;
create policy "Related users can view profile avatars"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'profile-avatars'
    and public.can_view_profile(
      case
        when split_part(name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          then split_part(name, '/', 1)::uuid
        else null
      end
    )
  );
