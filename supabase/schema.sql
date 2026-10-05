create table if not exists public.shopping_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  store_name text not null,
  items jsonb not null check (jsonb_typeof(items) = 'array'),
  total numeric(12, 2) not null check (total >= 0),
  created_at timestamptz not null default now()
);

alter table public.shopping_receipts enable row level security;

grant select, insert on public.shopping_receipts to authenticated;

drop policy if exists "Users can read their own receipts"
  on public.shopping_receipts;

create policy "Users can read their own receipts"
  on public.shopping_receipts
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own receipts"
  on public.shopping_receipts;

create policy "Users can create their own receipts"
  on public.shopping_receipts
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);