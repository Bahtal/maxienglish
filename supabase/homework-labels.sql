-- Add reusable teacher labels to existing homework rows.
-- Run in Supabase Dashboard > SQL Editor before deploying the app update.

alter table public.homework
  add column if not exists label text not null default '';

create index if not exists homework_teacher_label_idx
  on public.homework (teacher_id, label)
  where label <> '';
