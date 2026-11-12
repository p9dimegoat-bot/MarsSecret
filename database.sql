create table public.owners (
  user_id uuid primary key references auth.users(id)
);

alter table public.owners enable row level security;

create policy read_own_role on public.owners
for select to authenticated
using (user_id = auth.uid());

create function public.is_owner()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.owners where user_id = auth.uid()
  )
$$;

create table public.listings (
  id bigint generated always as identity primary key,
  title text not null check(length(title) between 1 and 100),
  url text not null check(url ~ '^https?://'),
  category text not null check(category in ('Game','Website'))
);

create table public.announcements (
  id bigint generated always as identity primary key,
  body text not null check(length(body) between 1 and 2000)
);

create table public.messages (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id),
  body text not null check(length(trim(body)) between 1 and 1000),
  created_at timestamptz not null default now()
);

alter table public.listings enable row level security;
alter table public.announcements enable row level security;
alter table public.messages enable row level security;

create policy read_listings on public.listings
for select using (true);

create policy manage_listings on public.listings
for all to authenticated
using (public.is_owner()) with check (public.is_owner());

create policy read_announcements on public.announcements
for select using (true);

create policy manage_announcements on public.announcements
for all to authenticated
using (public.is_owner()) with check (public.is_owner());

create policy read_messages on public.messages
for select using (true);

create policy send_messages on public.messages
for insert to authenticated
with check (user_id = auth.uid());

create policy moderate_messages on public.messages
for delete to authenticated using (public.is_owner());

insert into public.listings(title,url,category) values
('Original MarsSecret Games',
 'https://mellow-marzipan-857941.netlify.app/', 'Game'),
('DuckDuckGo','https://duckduckgo.com/','Website');
