-- Otbasy Capital: cloud tables for the five local models.
-- Run once in Supabase SQL Editor or DBeaver (Execute SQL Script).
-- No existing records are deleted by this script.
begin;

create table if not exists public.otbasy_families (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id text not null,
  name text not null check (length(trim(name)) > 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table if not exists public.otbasy_members (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id text not null,
  family_id text not null,
  name text not null check (length(trim(name)) > 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  unique (user_id, family_id, id),
  foreign key (user_id, family_id)
    references public.otbasy_families(user_id, id)
);

create table if not exists public.otbasy_entries (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id text not null,
  family_id text not null,
  owner_id text not null,
  title text not null check (length(trim(title)) > 0),
  amount bigint not null check (amount > 0),
  income boolean not null,
  category text not null,
  entry_date timestamptz not null,
  owner_name text not null,
  note text not null default '',
  shared boolean not null default true,
  favorite boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, family_id)
    references public.otbasy_families(user_id, id),
  foreign key (user_id, family_id, owner_id)
    references public.otbasy_members(user_id, family_id, id)
);

create table if not exists public.otbasy_goals (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id text not null,
  family_id text not null,
  owner_id text not null,
  title text not null check (length(trim(title)) > 0),
  target bigint not null check (target > 0),
  target_date timestamptz not null,
  owner_name text not null,
  shared boolean not null default true,
  contributions jsonb not null default '{}'::jsonb
    check (jsonb_typeof(contributions) = 'object'),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, family_id)
    references public.otbasy_families(user_id, id),
  foreign key (user_id, family_id, owner_id)
    references public.otbasy_members(user_id, family_id, id)
);

create table if not exists public.otbasy_reminders (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  id text not null,
  family_id text not null,
  title text not null check (length(trim(title)) > 0),
  reminder_date timestamptz not null,
  monthly boolean not null default false,
  done boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, family_id)
    references public.otbasy_families(user_id, id)
);

-- Each authenticated account can access only its own records.
-- "shared" is the local family display mode, not a permission grant.
do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'otbasy_families', 'otbasy_members', 'otbasy_entries',
    'otbasy_goals', 'otbasy_reminders'
  ] loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('revoke all on public.%I from anon', table_name);
    execute format('grant select, insert, update, delete on public.%I to authenticated', table_name);
    if not exists (
      select 1 from pg_policies p
      where p.schemaname = 'public' and p.tablename = table_name
        and p.policyname = 'account_owns_records'
    ) then
      execute format(
        'create policy account_owns_records on public.%I for all to authenticated '
        'using ((select auth.uid()) = user_id) '
        'with check ((select auth.uid()) = user_id)', table_name
      );
    end if;
  end loop;
end $$;

create index if not exists otbasy_entries_date_idx
  on public.otbasy_entries (user_id, entry_date desc);
create index if not exists otbasy_entries_category_idx
  on public.otbasy_entries (user_id, category);

commit;

-- Expected result: five rows, each with rls_enabled = true.
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
  and c.relname in (
    'otbasy_families', 'otbasy_members', 'otbasy_entries',
    'otbasy_goals', 'otbasy_reminders'
  )
order by c.relname;
