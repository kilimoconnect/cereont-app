-- ============================================================================
-- Cereont — Project Engine P2 (conversational creation) · run AFTER
-- project_engine.sql. Adds assumptions + scope/success-metric fields.
-- Idempotent.
-- ============================================================================

-- Assumptions the AI made, with a confidence level, monitored over time.
create table if not exists public.project_assumptions (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  statement   text not null,
  confidence  integer not null default 70,        -- 0..100
  status      text not null default 'holding',    -- holding / at_risk / broken
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.project_assumptions enable row level security;
drop policy if exists company_rw on public.project_assumptions;
create policy company_rw on public.project_assumptions for all
  using (public.is_company_member(company_id))
  with check (public.is_company_member(company_id));

grant select, insert, update, delete on public.project_assumptions to authenticated;

create index if not exists idx_passump_project
  on public.project_assumptions (project_id);

drop trigger if exists set_updated_at on public.project_assumptions;
create trigger set_updated_at before update on public.project_assumptions
  for each row execute function public.set_updated_at();

-- Structured understanding captured during discovery.
alter table public.projects add column if not exists success_metrics text[] not null default '{}';
alter table public.projects add column if not exists scope_included  text[] not null default '{}';
alter table public.projects add column if not exists scope_excluded  text[] not null default '{}';
alter table public.projects add column if not exists discovery       jsonb  not null default '[]';

-- ============================================================================
-- Done.
-- ============================================================================
