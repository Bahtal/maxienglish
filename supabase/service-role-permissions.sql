-- The Telegram sign-in Edge Function uses the service role to look up and
-- refresh a profile after validating Telegram initData.
grant select, update on table public.profiles to service_role;
