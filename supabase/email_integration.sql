-- ============================================================================
-- Cereont — Email integration (Gmail) · run AFTER schema.sql
-- Adds connected-mailbox tracking and dedup columns so synced emails aren't
-- inserted twice. Idempotent.
-- ============================================================================

-- Connected mailboxes (address + last sync; the live provider access token is
-- passed from the app per-sync, so no long-lived token is stored here yet).
create table if not exists public.email_accounts (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references public.companies (id) on delete cascade,
  user_id       uuid references public.profiles (id) on delete set null,
  provider      text not null default 'gmail',
  email_address text,
  last_synced   timestamptz,
  created_at    timestamptz not null default now(),
  unique (company_id, provider, email_address)
);

alter table public.email_accounts enable row level security;
drop policy if exists company_rw on public.email_accounts;
create policy company_rw on public.email_accounts for all
  using (public.is_company_member(company_id))
  with check (public.is_company_member(company_id));

grant select, insert, update, delete on public.email_accounts to authenticated;

create index if not exists idx_email_accounts_company
  on public.email_accounts (company_id);

-- Dedup: remember which provider message each row came from.
alter table public.emails add column if not exists provider text;
alter table public.emails add column if not exists provider_message_id text;

create unique index if not exists uq_emails_provider_msg
  on public.emails (company_id, provider_message_id)
  where provider_message_id is not null;
