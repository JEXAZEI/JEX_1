-- Enable realtime broadcasts for erd_notes and erd_rates so open tabs
-- pick up changes made elsewhere without a manual refresh. Safe to re-run.
--
-- Realtime respects each table's RLS select policy, so anon (public)
-- clients only receive the same rows they could already SELECT.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'erd_notes'
  ) then
    alter publication supabase_realtime add table public.erd_notes;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'erd_rates'
  ) then
    alter publication supabase_realtime add table public.erd_rates;
  end if;
end $$;
