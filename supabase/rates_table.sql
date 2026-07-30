-- erd_rates: shared exchange rates for the Imperial Bank ledger.
-- Run in the Supabase SQL editor for this project, after
-- supabase/rls_policies.sql (or in any order, they're independent).
--
-- Previously exchange rates lived only in each browser's localStorage,
-- so a rate an admin set was invisible to every other visitor and even
-- to that same admin on a different device. This table makes rates a
-- shared, server-side source of truth like erd_notes already is.
--
-- Same prerequisite as erd_notes: an authenticated admin user tagged
-- app_metadata.role = "admin" (see supabase/rls_policies.sql for how
-- to create one).

create table if not exists public.erd_rates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  rate numeric not null check (rate > 0),
  is_anchor boolean not null default false,
  updated_at timestamptz not null default now()
);

-- Only one anchor (Diamond) row is allowed to exist at a time.
create unique index if not exists erd_rates_single_anchor
  on public.erd_rates (is_anchor)
  where is_anchor;

-- Seed the fixed Diamond anchor row if the table is empty.
insert into public.erd_rates (name, rate, is_anchor)
select 'Diamond', 1, true
where not exists (select 1 from public.erd_rates where is_anchor);

alter table public.erd_rates enable row level security;

drop policy if exists "Public can read rates" on public.erd_rates;
drop policy if exists "Admins can insert rates" on public.erd_rates;
drop policy if exists "Admins can update rates" on public.erd_rates;
drop policy if exists "Admins can delete rates" on public.erd_rates;

-- Rates are public information: anyone (including the anon key) may read them.
create policy "Public can read rates"
on public.erd_rates
for select
to anon, authenticated
using (true);

-- Only an authenticated admin may add a new market commodity.
-- Blocks inserting a second anchor row (the unique index would reject it
-- anyway, but this keeps admins from ever using the app to try).
create policy "Admins can insert rates"
on public.erd_rates
for insert
to authenticated
with check (
  (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  and is_anchor = false
);

-- Only an authenticated admin may update a rate (anchor or market).
create policy "Admins can update rates"
on public.erd_rates
for update
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

-- Only an authenticated admin may remove a market commodity.
-- The anchor row can never be deleted through this policy.
create policy "Admins can delete rates"
on public.erd_rates
for delete
to authenticated
using (
  (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  and is_anchor = false
);
