-- Row Level Security for erd_notes
-- Run in the Supabase SQL editor for this project.
--
-- Prerequisite: an admin identity must exist in Supabase Auth (not just the
-- app's local passphrase check), and that user's app_metadata must contain
-- {"role": "admin"}. The anon/publishable key used by the static page has
-- no identity, so it can never satisfy these policies for writes.
--
-- To create the admin:
--   1. Supabase dashboard > Authentication > Users > Add user (email + password,
--      with "Auto Confirm User" checked).
--   2. Run:  update auth.users set raw_app_meta_data =
--              raw_app_meta_data || '{"role":"admin"}'::jsonb
--            where email = 'your-admin@example.com';
-- The app already signs in via supabase.auth.signInWithPassword.

alter table public.erd_notes enable row level security;

-- Drop old policies if re-running this script.
drop policy if exists "Public can read notes" on public.erd_notes;
drop policy if exists "Admins can insert notes" on public.erd_notes;
drop policy if exists "Admins can update notes" on public.erd_notes;
drop policy if exists "Admins can delete notes" on public.erd_notes;

-- The ledger is public information: anyone (including the anon key) may read it.
create policy "Public can read notes"
on public.erd_notes
for select
to anon, authenticated
using (true);

-- Only an authenticated user flagged as admin may mint new notes.
create policy "Admins can insert notes"
on public.erd_notes
for insert
to authenticated
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

-- Only an authenticated admin may update notes (e.g. void).
create policy "Admins can update notes"
on public.erd_notes
for update
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

-- Only an authenticated admin may delete notes (Reset All Data).
create policy "Admins can delete notes"
on public.erd_notes
for delete
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
