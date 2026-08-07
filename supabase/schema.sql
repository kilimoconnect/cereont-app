-- ============================================================================
-- Cereont — AI Chief of Staff · Supabase schema
-- ----------------------------------------------------------------------------
-- Safe to run in the Supabase SQL Editor. Idempotent: re-running updates in
-- place (guards on types, `create ... if not exists`, `drop policy if exists`).
--
-- Model: every business record belongs to a COMPANY. A user can belong to one
-- or more companies via `company_members`. Row Level Security ensures a user
-- only ever sees rows for companies they are a member of.
--
-- Order matters: enums → tables → functions → triggers → RLS → grants → indexes.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.priority as enum ('critical','high','medium','low');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.task_status as enum ('open','in_progress','done');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.email_kind as enum
    ('customer_inquiry','supplier_quote','purchase_order','contract',
     'invoice','meeting_request','general');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.timeline_kind as enum
    ('contract','purchase','new_customer','decision','milestone');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.member_role as enum ('owner','admin','manager','member');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- 2. Tables
-- ---------------------------------------------------------------------------

-- 2.1 Profiles (1:1 with auth.users)
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text,
  full_name   text,
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 2.2 Companies
create table if not exists public.companies (
  id                uuid primary key default gen_random_uuid(),
  owner_id          uuid not null references public.profiles (id) on delete cascade,
  name              text not null,
  industry          text,
  tagline           text,
  currency          text not null default '$',
  products_services text[] not null default '{}',
  departments       text[] not null default '{}',
  goals             text[] not null default '{}',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- 2.3 Company members (team)
create table if not exists public.company_members (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  role        public.member_role not null default 'member',
  created_at  timestamptz not null default now(),
  unique (company_id, user_id)
);

-- 2.4 Employees (staff records — not necessarily app users)
create table if not exists public.employees (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  name        text not null,
  role        text,
  department  text,
  email       text,
  phone       text,
  notes       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 2.5 Customers (primary contact stored inline; see `contacts` for more)
create table if not exists public.customers (
  id                 uuid primary key default gen_random_uuid(),
  company_id         uuid not null references public.companies (id) on delete cascade,
  name               text not null,
  segment            text,
  lifetime_value     numeric not null default 0,
  reorder_cycle_days integer not null default 30,
  last_order         date,
  last_contact       date,
  notes              text,
  tags               text[] not null default '{}',
  contact_name       text,
  contact_role       text,
  contact_email      text,
  contact_phone      text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- 2.6 Suppliers (primary contact stored inline; see `contacts` for more)
create table if not exists public.suppliers (
  id                uuid primary key default gen_random_uuid(),
  company_id        uuid not null references public.companies (id) on delete cascade,
  name              text not null,
  products_supplied text[] not null default '{}',
  payment_terms     text,
  on_time_rate      numeric not null default 1,      -- 0..1
  lead_time_days    integer not null default 0,
  notes             text,
  contact_name      text,
  contact_role      text,
  contact_email     text,
  contact_phone     text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- 2.7 Contacts (people at customers / suppliers)
create table if not exists public.contacts (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies (id) on delete cascade,
  name         text not null,
  role         text,
  email        text,
  phone        text,
  customer_id  uuid references public.customers (id) on delete cascade,
  supplier_id  uuid references public.suppliers (id) on delete cascade,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- 2.8 Products
create table if not exists public.products (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  name        text not null,
  category    text,
  price       numeric not null default 0,
  cost        numeric not null default 0,
  unit        text not null default 'unit',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 2.9 Projects
create table if not exists public.projects (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  name        text not null,
  status      text not null default 'Planning',
  deadline    date,
  progress    numeric not null default 0,           -- 0..1
  team        text[] not null default '{}',
  notes       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 2.10 Tasks
create table if not exists public.tasks (
  id                  uuid primary key default gen_random_uuid(),
  company_id          uuid not null references public.companies (id) on delete cascade,
  title               text not null,
  priority            public.priority not null default 'medium',
  status              public.task_status not null default 'open',
  due                 timestamptz,
  owner               text,
  source              text not null default 'Manual',
  notes               text,
  related_customer_id uuid references public.customers (id) on delete set null,
  related_supplier_id uuid references public.suppliers (id) on delete set null,
  related_project_id  uuid references public.projects (id) on delete set null,
  created_by          uuid references public.profiles (id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- 2.11 Calendar events
create table if not exists public.calendar_events (
  id               uuid primary key default gen_random_uuid(),
  company_id       uuid not null references public.companies (id) on delete cascade,
  title            text not null,
  start_at         timestamptz not null,
  duration_minutes integer not null default 60,
  location         text,
  kind             text not null default 'Meeting',   -- Meeting/Deadline/Renewal/Follow-up
  related_id       uuid,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- 2.12 Emails
create table if not exists public.emails (
  id                  uuid primary key default gen_random_uuid(),
  company_id          uuid not null references public.companies (id) on delete cascade,
  from_name           text,
  from_address        text,
  subject             text,
  body                text,
  received_at         timestamptz not null default now(),
  kind                public.email_kind not null default 'general',
  priority            public.priority not null default 'medium',
  ai_summary          text,
  ai_action           text,
  deadline            timestamptz,
  related_customer_id uuid references public.customers (id) on delete set null,
  related_supplier_id uuid references public.suppliers (id) on delete set null,
  read                boolean not null default false,
  handled             boolean not null default false,
  created_at          timestamptz not null default now()
);

-- 2.13 Meetings (decisions + action items stored inline)
create table if not exists public.meetings (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references public.companies (id) on delete cascade,
  title         text not null,
  meeting_date  timestamptz not null default now(),
  attendees     text[] not null default '{}',
  summary       text,
  decisions     text[] not null default '{}',
  action_items  jsonb not null default '[]',          -- [{ "text": "...", "done": false }]
  processed     boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 2.14 Notes
create table if not exists public.notes (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  title       text not null,
  body        text,
  tags        text[] not null default '{}',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 2.15 Documents (metadata; files live in Supabase Storage)
create table if not exists public.documents (
  id                  uuid primary key default gen_random_uuid(),
  company_id          uuid not null references public.companies (id) on delete cascade,
  name                text not null,
  storage_path        text,
  mime_type           text,
  size_bytes          bigint,
  related_customer_id uuid references public.customers (id) on delete set null,
  related_supplier_id uuid references public.suppliers (id) on delete set null,
  related_project_id  uuid references public.projects (id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- 2.16 Timeline events
create table if not exists public.timeline_events (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  kind        public.timeline_kind not null default 'milestone',
  title       text not null,
  detail      text,
  event_date  timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

-- 2.17 AI memory (structured facts the assistant learns / stores)
-- To enable semantic search later: `create extension vector;` then add an
-- `embedding vector(1536)` column and an ivfflat/hnsw index.
create table if not exists public.ai_memory (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  title       text,
  content     text not null,
  source      text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 2.18 Daily briefs
create table if not exists public.daily_briefs (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  brief_date  date not null default current_date,
  greeting    text,
  advice      text,
  sections    jsonb not null default '[]',
  created_at  timestamptz not null default now(),
  unique (company_id, brief_date)
);

-- 2.19 Chat messages (AI executive chat history)
create table if not exists public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  user_id     uuid references public.profiles (id) on delete set null,
  content     text not null,
  is_user     boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 3. Functions (defined after tables so SQL bodies validate)
-- ---------------------------------------------------------------------------

-- SECURITY DEFINER helpers bypass RLS on company_members to avoid recursion.
create or replace function public.is_company_member(cid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.company_members m
    where m.company_id = cid and m.user_id = auth.uid()
  );
$$;

create or replace function public.is_company_admin(cid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.company_members m
    where m.company_id = cid and m.user_id = auth.uid()
      and m.role in ('owner','admin')
  );
$$;

create or replace function public.shares_company_with(other uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.company_members a
    join public.company_members b on a.company_id = b.company_id
    where a.user_id = auth.uid() and b.user_id = other
  );
$$;

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- Create a profile row automatically when a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name')
  )
  on conflict (id) do nothing;
  return new;
end $$;

-- When a company is created, make its owner the first member.
create or replace function public.handle_new_company()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.company_members (company_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (company_id, user_id) do nothing;
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- 4. Triggers
-- ---------------------------------------------------------------------------
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop trigger if exists on_company_created on public.companies;
create trigger on_company_created
  after insert on public.companies
  for each row execute function public.handle_new_company();

-- updated_at maintenance for every table that has the column
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','companies','employees','customers','suppliers','contacts',
    'products','projects','tasks','calendar_events','meetings','notes',
    'documents','ai_memory'
  ] loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format(
      'create trigger set_updated_at before update on public.%I
         for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 5. Row Level Security
-- ---------------------------------------------------------------------------

-- 5.1 Profiles
alter table public.profiles enable row level security;
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using (id = auth.uid() or public.shares_company_with(id));
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles
  for insert with check (id = auth.uid());

-- 5.2 Companies
alter table public.companies enable row level security;
drop policy if exists companies_select on public.companies;
create policy companies_select on public.companies
  for select using (public.is_company_member(id));
drop policy if exists companies_insert on public.companies;
create policy companies_insert on public.companies
  for insert with check (owner_id = auth.uid());
drop policy if exists companies_update on public.companies;
create policy companies_update on public.companies
  for update using (public.is_company_admin(id)) with check (public.is_company_admin(id));
drop policy if exists companies_delete on public.companies;
create policy companies_delete on public.companies
  for delete using (owner_id = auth.uid());

-- 5.3 Company members
alter table public.company_members enable row level security;
drop policy if exists members_select on public.company_members;
create policy members_select on public.company_members
  for select using (public.is_company_member(company_id));
drop policy if exists members_modify on public.company_members;
create policy members_modify on public.company_members
  for all using (public.is_company_admin(company_id))
  with check (public.is_company_admin(company_id));

-- 5.4 All company-scoped tables: full access to company members
do $$
declare t text;
begin
  foreach t in array array[
    'employees','customers','suppliers','contacts','products','projects',
    'tasks','calendar_events','emails','meetings','notes','documents',
    'timeline_events','ai_memory','daily_briefs','chat_messages'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists company_rw on public.%I', t);
    execute format(
      'create policy company_rw on public.%I for all
         using (public.is_company_member(company_id))
         with check (public.is_company_member(company_id))', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 6. Grants (RLS still restricts rows; these grant table-level access)
-- ---------------------------------------------------------------------------
grant usage on schema public to authenticated, anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Indexes
-- ---------------------------------------------------------------------------
create index if not exists idx_members_user       on public.company_members (user_id);
create index if not exists idx_members_company     on public.company_members (company_id);
create index if not exists idx_employees_company   on public.employees (company_id);
create index if not exists idx_customers_company   on public.customers (company_id);
create index if not exists idx_customers_lastorder on public.customers (last_order);
create index if not exists idx_suppliers_company   on public.suppliers (company_id);
create index if not exists idx_contacts_company    on public.contacts (company_id);
create index if not exists idx_products_company    on public.products (company_id);
create index if not exists idx_projects_company    on public.projects (company_id);
create index if not exists idx_tasks_company       on public.tasks (company_id);
create index if not exists idx_tasks_status        on public.tasks (company_id, status);
create index if not exists idx_tasks_due           on public.tasks (company_id, due);
create index if not exists idx_events_company      on public.calendar_events (company_id, start_at);
create index if not exists idx_emails_company      on public.emails (company_id, received_at desc);
create index if not exists idx_meetings_company    on public.meetings (company_id, meeting_date desc);
create index if not exists idx_notes_company       on public.notes (company_id);
create index if not exists idx_documents_company   on public.documents (company_id);
create index if not exists idx_timeline_company    on public.timeline_events (company_id, event_date desc);
create index if not exists idx_aimemory_company    on public.ai_memory (company_id);
create index if not exists idx_briefs_company      on public.daily_briefs (company_id, brief_date desc);
create index if not exists idx_chat_company        on public.chat_messages (company_id, created_at);

-- ============================================================================
-- Done. Every signed-in user automatically gets a profile row. Create a
-- company (its creator becomes the owner member), then all other tables are
-- readable/writable only by that company's members.
-- ============================================================================
