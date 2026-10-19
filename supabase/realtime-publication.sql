-- Enable row-change events used by the app's live schedule and payment updates.
do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'payments',
    'lessons',
    'students',
    'homework',
    'notifications',
    'subscription_plans',
    'profiles',
    'teacher_settings'
  ] loop
    if to_regclass(format('public.%I', table_name)) is not null
       and not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = table_name
    ) then
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    end if;
  end loop;
end;
$$;
