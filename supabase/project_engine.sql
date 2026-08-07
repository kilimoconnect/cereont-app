-- ============================================================================
-- Cereont — Universal Project Engine · run AFTER schema.sql
-- Extends `projects` into a full idea → planning → execution → learning engine.
-- Idempotent. Every child table carries company_id so RLS stays uniform.
-- ============================================================================

-- 1. Extend the existing projects table -------------------------------------
alter table public.projects add column if not exists owner_id uuid
  references public.profiles (id) on delete set null;
alter table public.projects add column if not exists description text;
alter table public.projects add column if not exists category text;
alter table public.projects add column if not exists priority public.priority
  not null default 'medium';
alter table public.projects add column if not exists start_date date;
alter table public.projects add column if not exists target_date date;
alter table public.projects add column if not exists project_type text;
alter table public.projects add column if not exists complexity text;
alter table public.projects add column if not exists objective text;
alter table public.projects add column if not exists health_score integer;
alter table public.projects add column if not exists budget_amount numeric;
alter table public.projects add column if not exists archived boolean
  not null default false;

-- tasks gain a milestone link (plain uuid; app maintains integrity)
alter table public.tasks add column if not exists milestone_id uuid;

-- ai_memory gains an optional project scope
alter table public.ai_memory add column if not exists project_id uuid;

-- 2. New tables --------------------------------------------------------------
create table if not exists public.project_categories (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  name        text not null,
  color       text,
  created_at  timestamptz not null default now()
);

create table if not exists public.project_members (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  name        text not null,
  role        text,
  user_id     uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now()
);

create table if not exists public.project_milestones (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies (id) on delete cascade,
  project_id   uuid not null references public.projects (id) on delete cascade,
  title        text not null,
  status       text not null default 'pending',   -- pending/in_progress/done
  due_date     date,
  order_index  integer not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table if not exists public.project_objectives (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  statement   text not null,
  metric      text,
  target      text,
  created_at  timestamptz not null default now()
);

create table if not exists public.project_resources (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  kind        text not null default 'person',  -- person/money/asset/information
  name        text not null,
  detail      text,
  created_at  timestamptz not null default now()
);

create table if not exists public.project_budget (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  label       text not null,
  amount      numeric not null default 0,
  type        text not null default 'expense',  -- budget/expense/funding
  incurred_on date,
  created_at  timestamptz not null default now()
);

create table if not exists public.project_risks (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  title       text not null,
  probability text not null default 'medium',   -- low/medium/high
  impact      text not null default 'medium',   -- low/medium/high
  mitigation  text,
  status      text not null default 'open',      -- open/mitigated/closed
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.project_dependencies (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  description text not null,
  blocked_by  text,
  status      text not null default 'open',
  created_at  timestamptz not null default now()
);

create table if not exists public.project_updates (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  note        text not null,
  author      text,
  created_at  timestamptz not null default now()
);

create table if not exists public.project_decisions (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid not null references public.projects (id) on delete cascade,
  decision    text not null,
  rationale   text,
  decided_on  date,
  created_at  timestamptz not null default now()
);

create table if not exists public.project_lessons (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  project_id  uuid references public.projects (id) on delete set null,
  lesson      text not null,
  category    text,
  created_at  timestamptz not null default now()
);

create table if not exists public.project_templates (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  name        text not null,
  category    text,
  structure   jsonb not null default '{}',  -- { milestones:[{title, tasks:[...]}] }
  created_at  timestamptz not null default now()
);

-- 3. Row Level Security (company-scoped, same pattern as schema.sql) ----------
do $$
declare t text;
begin
  foreach t in array array[
    'project_categories','project_members','project_milestones',
    'project_objectives','project_resources','project_budget','project_risks',
    'project_dependencies','project_updates','project_decisions',
    'project_lessons','project_templates'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists company_rw on public.%I', t);
    execute format('create policy company_rw on public.%I for all
      using (public.is_company_member(company_id))
      with check (public.is_company_member(company_id))', t);
  end loop;
end $$;

-- 4. updated_at triggers for tables that have the column ----------------------
do $$
declare t text;
begin
  foreach t in array array['project_milestones','project_risks'] loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format('create trigger set_updated_at before update on public.%I
      for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- 5. Grants + indexes --------------------------------------------------------
grant select, insert, update, delete on all tables in schema public to authenticated;

create index if not exists idx_pmilestones_project on public.project_milestones (project_id, order_index);
create index if not exists idx_presources_project  on public.project_resources (project_id);
create index if not exists idx_pbudget_project      on public.project_budget (project_id);
create index if not exists idx_prisks_project       on public.project_risks (project_id);
create index if not exists idx_pdeps_project        on public.project_dependencies (project_id);
create index if not exists idx_pupdates_project     on public.project_updates (project_id, created_at desc);
create index if not exists idx_pdecisions_project   on public.project_decisions (project_id);
create index if not exists idx_plessons_company     on public.project_lessons (company_id);
create index if not exists idx_pmembers_project     on public.project_members (project_id);
create index if not exists idx_tasks_milestone      on public.tasks (milestone_id);

-- ============================================================================
-- Done. Projects can now carry objectives, milestones, tasks, resources,
-- budget, risks, dependencies, updates, decisions, lessons and templates —
-- all company-scoped and RLS-protected.
-- ============================================================================
