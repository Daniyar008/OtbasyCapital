-- Отбасы чаты: хабарлар Supabase Realtime (WebSocket) арқылы тарайды.
create table if not exists public.otbasy_family_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  family_id text not null default 'family-main',
  author_name text not null check (length(trim(author_name)) > 0),
  message text not null check (length(trim(message)) between 1 and 1000),
  is_assistant boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.otbasy_family_messages enable row level security;
revoke all on public.otbasy_family_messages from anon;
grant select, insert on public.otbasy_family_messages to authenticated;

drop policy if exists chat_owner_access on public.otbasy_family_messages;
create policy chat_owner_access on public.otbasy_family_messages
for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create index if not exists otbasy_family_messages_date_idx
  on public.otbasy_family_messages (user_id, family_id, created_at);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'otbasy_family_messages'
  ) then
    alter publication supabase_realtime add table public.otbasy_family_messages;
  end if;
end $$;
