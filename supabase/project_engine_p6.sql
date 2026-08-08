-- ============================================================================
-- Cereont — Project Engine P6 (feeds) · run AFTER project_engine_p3.sql.
-- Links meetings to a project so they can feed it. Idempotent.
-- (Emails are matched to projects client-side; documents use the existing
--  `documents` table + a paste-to-extract flow — no schema change needed.)
-- ============================================================================

alter table public.meetings add column if not exists project_id uuid;
create index if not exists idx_meetings_project
  on public.meetings (project_id);

-- ============================================================================
-- Done.
-- ============================================================================
