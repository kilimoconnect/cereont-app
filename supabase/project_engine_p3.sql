-- ============================================================================
-- Cereont — Project Engine P3 (execution + advanced tasks) · run AFTER
-- project_engine_p2.sql. Adds task statuses, subtasks and dependencies.
--
-- NOTE: the ALTER TYPE ... ADD VALUE lines must NOT run inside a transaction
-- with statements that use the new value. Running this whole file in the
-- Supabase SQL editor is fine (the new values aren't used here). If you hit a
-- transaction error, run the three ALTER TYPE lines one at a time.
-- ============================================================================

alter type public.task_status add value if not exists 'blocked';
alter type public.task_status add value if not exists 'cancelled';

-- Subtasks (self-reference) and task-to-task dependency.
alter table public.tasks add column if not exists parent_task_id uuid;
alter table public.tasks add column if not exists depends_on uuid;

create index if not exists idx_tasks_parent on public.tasks (parent_task_id);
create index if not exists idx_tasks_depends on public.tasks (depends_on);

-- ============================================================================
-- Done.
-- ============================================================================
