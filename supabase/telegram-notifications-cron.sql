-- Run after deploying the telegram-notifications Edge Function and after
-- adding TELEGRAM_CRON_SECRET to Edge Function Secrets.
-- Replace the two placeholders below before running this file.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- Store the public project URL, publishable key, and the same random value
-- used for the Edge Function secret TELEGRAM_CRON_SECRET.
select vault.create_secret('https://gxcpnixtjqpjgonpidix.supabase.co', 'telegram_project_url');
select vault.create_secret('REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY', 'telegram_publishable_key');
select vault.create_secret('REPLACE_WITH_TELEGRAM_CRON_SECRET', 'telegram_cron_secret');

select cron.unschedule(jobid)
from cron.job
where jobname = 'telegram-notifications-every-minute';

select cron.schedule(
  'telegram-notifications-every-minute',
  '* * * * *',
  $$
    select net.http_post(
      url := (select decrypted_secret from vault.decrypted_secrets where name = 'telegram_project_url')
        || '/functions/v1/telegram-notifications',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', (select decrypted_secret from vault.decrypted_secrets where name = 'telegram_publishable_key'),
        'x-telegram-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'telegram_cron_secret')
      ),
      body := '{}'::jsonb
    );
  $$
);
