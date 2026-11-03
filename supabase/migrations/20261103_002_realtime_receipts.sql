-- КМ07 ПО 7-сабақ: операциялар Realtime арқылы жаңарады,
-- ал чек суреттері жеке receipts bucket-інде сақталады.

alter table public.otbasy_entries
  add column if not exists receipt_path text;

-- Existing projects can run this file in Supabase SQL Editor once.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'otbasy_entries'
  ) then
    alter publication supabase_realtime add table public.otbasy_entries;
  end if;
end $$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'receipts',
  'receipts',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- A photo path starts with auth.uid(), for example: user-uuid/entry-42.jpg.
drop policy if exists receipt_owner_select on storage.objects;
create policy receipt_owner_select on storage.objects
for select to authenticated
using (
  bucket_id = 'receipts'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists receipt_owner_insert on storage.objects;
create policy receipt_owner_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'receipts'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists receipt_owner_update on storage.objects;
create policy receipt_owner_update on storage.objects
for update to authenticated
using (
  bucket_id = 'receipts'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'receipts'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists receipt_owner_delete on storage.objects;
create policy receipt_owner_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'receipts'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
