-- Data integrity constraints for erd_notes and erd_rates.
-- Run after rls_policies.sql and rates_table.sql have been applied.
--
-- Right now nothing stops a null player name, two notes sharing a serial,
-- a status outside 'active'/'voided', a denom outside the app's menu, or
-- two rates with the same commodity name -- the app's JS never sends that,
-- but nothing at the database level prevents it either (e.g. a row edited
-- by hand in the table editor, or written directly via the API).
--
-- NOTE: if any existing row already violates one of these, its ALTER TABLE
-- will fail with an error naming the offending column/rows. Fix or delete
-- those rows first, then re-run.

-- erd_notes
alter table public.erd_notes alter column serial set not null;
alter table public.erd_notes alter column player set not null;
alter table public.erd_notes alter column denom set not null;
alter table public.erd_notes alter column status set not null;

alter table public.erd_notes drop constraint if exists erd_notes_serial_unique;
alter table public.erd_notes add constraint erd_notes_serial_unique unique (serial);

alter table public.erd_notes drop constraint if exists erd_notes_status_check;
alter table public.erd_notes add constraint erd_notes_status_check check (status in ('active','voided'));

alter table public.erd_notes drop constraint if exists erd_notes_denom_check;
alter table public.erd_notes add constraint erd_notes_denom_check check (denom in (1,2,4,8,16,32,64));

-- erd_rates
alter table public.erd_rates drop constraint if exists erd_rates_name_unique;
alter table public.erd_rates add constraint erd_rates_name_unique unique (name);
