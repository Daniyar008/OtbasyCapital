-- Read-only queries for DBeaver or Supabase SQL Editor.
-- Account creation is handled by Supabase Auth, not an INSERT from Flutter.
select id, email, raw_user_meta_data ->> 'name' as name, created_at
from auth.users
order by created_at desc
limit 20;

-- The most recently inserted or changed operations from the application.
select e.id, u.email, e.title, e.amount, e.income, e.category,
       e.owner_name, e.favorite, e.entry_date, e.updated_at
from public.otbasy_entries e
join auth.users u on u.id = e.user_id
order by e.updated_at desc
limit 50;

select user_id, id, name, updated_at
from public.otbasy_families
order by updated_at desc;

-- Relationships: each operation points to a member in the same family/account.
select e.title, e.amount, f.name as family_name, m.name as member_name
from public.otbasy_entries e
join public.otbasy_families f
  on f.user_id = e.user_id and f.id = e.family_id
join public.otbasy_members m
  on m.user_id = e.user_id and m.family_id = e.family_id and m.id = e.owner_id;
