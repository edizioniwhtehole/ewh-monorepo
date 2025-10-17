-- ============================================================================
-- ADMIN: ROADMAP & CHECKLIST INTERATTIVE
-- ============================================================================
-- Questo schema gestisce:
-- 1. Roadmap evolutiva dell'architettura (fasi, decisioni, split DB, etc.)
-- 2. Checklist task per ogni app/servizio (sviluppo operativo)
-- ============================================================================

-- Schema per dati admin
CREATE SCHEMA IF NOT EXISTS admin;

-- ============================================================================
-- 1. ROADMAP INTERATTIVA
-- ============================================================================

-- Fasi della roadmap architetturale
CREATE TABLE admin.roadmap_phases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
  start_date DATE,
  end_date DATE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(phase_number)
);

-- Decisioni architetturali per fase
CREATE TABLE admin.roadmap_decisions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_id UUID REFERENCES admin.roadmap_phases(id) ON DELETE CASCADE,
  decision_type TEXT NOT NULL CHECK (decision_type IN (
    'db_split',           -- Split database per servizio
    'service_migration',  -- Migrazione servizio
    'tier_change',        -- Cambio tier tenant
    'infrastructure',     -- Cambio infrastruttura
    'optimization',       -- Ottimizzazione
    'other'
  )),
  title TEXT NOT NULL,
  description TEXT,
  reason TEXT,              -- Perché questa decisione?
  metrics JSONB,            -- Metriche che hanno portato alla decisione
  status TEXT NOT NULL DEFAULT 'proposed' CHECK (status IN ('proposed', 'approved', 'implemented', 'rejected')),
  decided_at TIMESTAMPTZ,
  decided_by TEXT,
  implemented_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Database tracking (per roadmap split)
CREATE TABLE admin.roadmap_databases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  db_identifier TEXT NOT NULL UNIQUE,  -- 'database_main', 'database_pm', 'database_dam'
  db_purpose TEXT NOT NULL,             -- 'main', 'service_dedicated', 'tenant_dedicated'
  services TEXT[],                      -- Quali servizi ospita: ['pm', 'dam']
  max_schemas INTEGER DEFAULT 500,
  current_schemas INTEGER DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'provisioning', 'active', 'migrating', 'deprecated')),

  -- Connection info (populated when active)
  db_host TEXT,
  db_port INTEGER DEFAULT 5432,
  db_name TEXT,

  -- Metriche
  total_size_gb NUMERIC(10,2) DEFAULT 0,
  avg_query_time_ms NUMERIC(10,2),
  total_tenants INTEGER DEFAULT 0,

  -- Replica info (quando disponibile)
  has_replica BOOLEAN DEFAULT false,
  replica_host TEXT,
  backup_ftp_enabled BOOLEAN DEFAULT false,
  backup_schedule TEXT,  -- Cron expression

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Service allocation per database
CREATE TABLE admin.roadmap_service_allocation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_code TEXT NOT NULL,           -- 'pm', 'crm', 'dam', etc.
  db_id UUID REFERENCES admin.roadmap_databases(id) ON DELETE CASCADE,
  allocation_type TEXT NOT NULL CHECK (allocation_type IN ('shared_schema', 'dedicated_schema_per_tenant')),
  schema_prefix TEXT,                   -- 'svc_pm' per shared, 'tenant_{slug}_pm' per dedicated

  -- Metriche servizio
  total_tenants INTEGER DEFAULT 0,
  total_revenue_monthly NUMERIC(12,2) DEFAULT 0,
  avg_db_size_per_tenant_gb NUMERIC(10,2) DEFAULT 0,
  avg_query_time_ms NUMERIC(10,2),
  growth_rate_percent NUMERIC(5,2),     -- % crescita mese/mese

  -- Split decision
  should_split BOOLEAN DEFAULT false,
  split_reason TEXT,
  split_scheduled_at DATE,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(service_code, db_id)
);

-- ============================================================================
-- 2. CHECKLIST INTERATTIVA PER APP
-- ============================================================================

-- Apps/Servizi da sviluppare
CREATE TABLE admin.apps_development (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_code TEXT NOT NULL UNIQUE,        -- 'pm', 'crm', 'dam', etc.
  app_name TEXT NOT NULL,               -- 'Project Management', 'CRM', etc.
  description TEXT,
  category TEXT,                        -- 'core', 'commerce', 'content', 'collaboration'
  priority INTEGER DEFAULT 50,          -- 0-100 (higher = more important)
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'on_hold', 'cancelled')),

  -- Progress tracking
  total_tasks INTEGER DEFAULT 0,
  completed_tasks INTEGER DEFAULT 0,
  progress_percent NUMERIC(5,2) GENERATED ALWAYS AS (
    CASE WHEN total_tasks > 0 THEN (completed_tasks::NUMERIC / total_tasks * 100) ELSE 0 END
  ) STORED,

  -- Timeline
  start_date DATE,
  target_date DATE,
  completed_at TIMESTAMPTZ,

  -- Team
  assigned_to TEXT[],                   -- Array di developer emails

  -- Links
  repo_url TEXT,
  design_url TEXT,
  docs_url TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Task categories per app
CREATE TABLE admin.task_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id UUID REFERENCES admin.apps_development(id) ON DELETE CASCADE,
  name TEXT NOT NULL,                   -- 'Database', 'API', 'Frontend', 'Testing', 'Deploy'
  order_index INTEGER DEFAULT 0,
  icon TEXT,                            -- Emoji o icon name
  color TEXT,                           -- Hex color per UI
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Task checklist per app
CREATE TABLE admin.tasks_checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id UUID REFERENCES admin.apps_development(id) ON DELETE CASCADE,
  category_id UUID REFERENCES admin.task_categories(id) ON DELETE SET NULL,

  title TEXT NOT NULL,
  description TEXT,

  -- Task details
  task_type TEXT CHECK (task_type IN ('feature', 'bug', 'optimization', 'documentation', 'test', 'deploy')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  complexity TEXT CHECK (complexity IN ('trivial', 'easy', 'medium', 'hard', 'expert')),
  estimated_hours NUMERIC(5,1),
  actual_hours NUMERIC(5,1),

  -- Status
  status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'blocked', 'review', 'completed', 'cancelled')),
  blocked_reason TEXT,

  -- Dependencies
  depends_on UUID[],                    -- Array di task_id che devono essere completati prima
  blocks UUID[],                        -- Array di task_id che vengono bloccati da questo

  -- Assignment
  assigned_to TEXT,                     -- Developer email
  reviewed_by TEXT,

  -- Timeline
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  due_date DATE,

  -- Code tracking
  branch_name TEXT,
  pr_url TEXT,
  commit_hash TEXT,

  -- Notes
  notes TEXT,
  tags TEXT[],

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Subtasks (per task complessi)
CREATE TABLE admin.tasks_subtasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_task_id UUID REFERENCES admin.tasks_checklist(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  completed BOOLEAN DEFAULT false,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Comments/Activity per task
CREATE TABLE admin.tasks_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES admin.tasks_checklist(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('comment', 'status_change', 'assignment', 'completed', 'blocked', 'unblocked')),
  user_email TEXT NOT NULL,
  content TEXT,
  metadata JSONB,                       -- Extra info (old_status, new_status, etc.)
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 3. VIEWS PER UI
-- ============================================================================

-- Roadmap overview
CREATE OR REPLACE VIEW admin.v_roadmap_overview AS
SELECT
  p.id,
  p.phase_number,
  p.name,
  p.description,
  p.status,
  p.start_date,
  p.end_date,
  p.completed_at,
  COUNT(DISTINCT d.id) AS total_decisions,
  COUNT(DISTINCT d.id) FILTER (WHERE d.status = 'implemented') AS implemented_decisions,
  COUNT(DISTINCT db.id) AS total_databases,
  COUNT(DISTINCT db.id) FILTER (WHERE db.status = 'active') AS active_databases
FROM admin.roadmap_phases p
LEFT JOIN admin.roadmap_decisions d ON d.phase_id = p.id
LEFT JOIN admin.roadmap_databases db ON true  -- All databases
GROUP BY p.id
ORDER BY p.phase_number;

-- Apps progress dashboard
CREATE OR REPLACE VIEW admin.v_apps_progress AS
SELECT
  a.id,
  a.app_code,
  a.app_name,
  a.category,
  a.priority,
  a.status,
  a.total_tasks,
  a.completed_tasks,
  a.progress_percent,
  a.start_date,
  a.target_date,
  CASE
    WHEN a.target_date < CURRENT_DATE AND a.status != 'completed' THEN 'overdue'
    WHEN a.target_date <= CURRENT_DATE + INTERVAL '7 days' AND a.status != 'completed' THEN 'due_soon'
    ELSE 'on_track'
  END AS timeline_status,
  COUNT(DISTINCT t.id) FILTER (WHERE t.status = 'blocked') AS blocked_tasks,
  COUNT(DISTINCT t.id) FILTER (WHERE t.priority = 'critical') AS critical_tasks
FROM admin.apps_development a
LEFT JOIN admin.tasks_checklist t ON t.app_id = a.id
GROUP BY a.id
ORDER BY a.priority DESC, a.app_code;

-- Task list per app (con dipendenze)
CREATE OR REPLACE VIEW admin.v_tasks_with_dependencies AS
SELECT
  t.id,
  t.app_id,
  a.app_code,
  a.app_name,
  c.name AS category,
  c.color AS category_color,
  t.title,
  t.description,
  t.task_type,
  t.priority,
  t.complexity,
  t.status,
  t.assigned_to,
  t.due_date,
  t.estimated_hours,
  t.actual_hours,
  COALESCE(array_length(t.depends_on, 1), 0) AS dependencies_count,
  COALESCE(array_length(t.blocks, 1), 0) AS blocks_count,
  COUNT(st.id) AS subtasks_total,
  COUNT(st.id) FILTER (WHERE st.completed = true) AS subtasks_completed,
  CASE
    WHEN t.due_date < CURRENT_DATE AND t.status NOT IN ('completed', 'cancelled') THEN 'overdue'
    WHEN t.due_date <= CURRENT_DATE + INTERVAL '3 days' AND t.status NOT IN ('completed', 'cancelled') THEN 'due_soon'
    ELSE 'normal'
  END AS urgency
FROM admin.tasks_checklist t
JOIN admin.apps_development a ON a.id = t.app_id
LEFT JOIN admin.task_categories c ON c.id = t.category_id
LEFT JOIN admin.tasks_subtasks st ON st.parent_task_id = t.id
GROUP BY t.id, a.id, a.app_code, a.app_name, c.name, c.color
ORDER BY
  CASE t.status WHEN 'blocked' THEN 1 WHEN 'in_progress' THEN 2 WHEN 'todo' THEN 3 ELSE 4 END,
  CASE t.priority WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4 END,
  t.due_date NULLS LAST;

-- Database allocation overview
CREATE OR REPLACE VIEW admin.v_database_allocation AS
SELECT
  db.id,
  db.db_identifier,
  db.db_purpose,
  db.status,
  db.max_schemas,
  db.current_schemas,
  ROUND((db.current_schemas::NUMERIC / db.max_schemas * 100), 1) AS schema_usage_percent,
  db.total_size_gb,
  db.total_tenants,
  db.has_replica,
  db.backup_ftp_enabled,
  array_agg(DISTINCT sa.service_code) FILTER (WHERE sa.service_code IS NOT NULL) AS services,
  COUNT(DISTINCT sa.id) AS service_count,
  SUM(sa.total_tenants) AS total_service_tenants,
  SUM(sa.total_revenue_monthly) AS total_revenue
FROM admin.roadmap_databases db
LEFT JOIN admin.roadmap_service_allocation sa ON sa.db_id = db.id
GROUP BY db.id
ORDER BY db.status, db.db_identifier;

-- ============================================================================
-- 4. FUNCTIONS
-- ============================================================================

-- Update app task counters
CREATE OR REPLACE FUNCTION admin.update_app_task_counters()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE admin.apps_development
  SET
    total_tasks = (SELECT COUNT(*) FROM admin.tasks_checklist WHERE app_id = COALESCE(NEW.app_id, OLD.app_id)),
    completed_tasks = (SELECT COUNT(*) FROM admin.tasks_checklist WHERE app_id = COALESCE(NEW.app_id, OLD.app_id) AND status = 'completed'),
    updated_at = now()
  WHERE id = COALESCE(NEW.app_id, OLD.app_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_app_counters_on_task_change
AFTER INSERT OR UPDATE OR DELETE ON admin.tasks_checklist
FOR EACH ROW
EXECUTE FUNCTION admin.update_app_task_counters();

-- Log task activity automatically
CREATE OR REPLACE FUNCTION admin.log_task_activity()
RETURNS TRIGGER AS $$
BEGIN
  -- Status change
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    INSERT INTO admin.tasks_activity (task_id, activity_type, user_email, content, metadata)
    VALUES (
      NEW.id,
      'status_change',
      COALESCE(NEW.assigned_to, 'system'),
      'Status changed from ' || OLD.status || ' to ' || NEW.status,
      jsonb_build_object('old_status', OLD.status, 'new_status', NEW.status)
    );
  END IF;

  -- Assignment change
  IF TG_OP = 'UPDATE' AND COALESCE(OLD.assigned_to, '') != COALESCE(NEW.assigned_to, '') THEN
    INSERT INTO admin.tasks_activity (task_id, activity_type, user_email, content, metadata)
    VALUES (
      NEW.id,
      'assignment',
      COALESCE(NEW.assigned_to, 'system'),
      'Task assigned to ' || COALESCE(NEW.assigned_to, 'unassigned'),
      jsonb_build_object('old_assignee', OLD.assigned_to, 'new_assignee', NEW.assigned_to)
    );
  END IF;

  -- Completed
  IF TG_OP = 'UPDATE' AND NEW.status = 'completed' AND OLD.status != 'completed' THEN
    INSERT INTO admin.tasks_activity (task_id, activity_type, user_email, content)
    VALUES (NEW.id, 'completed', COALESCE(NEW.assigned_to, 'system'), 'Task completed');

    UPDATE admin.tasks_checklist SET completed_at = now() WHERE id = NEW.id;
  END IF;

  -- Blocked
  IF TG_OP = 'UPDATE' AND NEW.status = 'blocked' AND OLD.status != 'blocked' THEN
    INSERT INTO admin.tasks_activity (task_id, activity_type, user_email, content)
    VALUES (NEW.id, 'blocked', COALESCE(NEW.assigned_to, 'system'), COALESCE(NEW.blocked_reason, 'Task blocked'));
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_task_activity_trigger
AFTER UPDATE ON admin.tasks_checklist
FOR EACH ROW
EXECUTE FUNCTION admin.log_task_activity();

-- Update database schema counter
CREATE OR REPLACE FUNCTION admin.update_db_schema_counter()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE admin.roadmap_databases
  SET
    current_schemas = (SELECT COUNT(*) FROM admin.roadmap_service_allocation WHERE db_id = COALESCE(NEW.db_id, OLD.db_id)),
    updated_at = now()
  WHERE id = COALESCE(NEW.db_id, OLD.db_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_db_counters_on_allocation_change
AFTER INSERT OR UPDATE OR DELETE ON admin.roadmap_service_allocation
FOR EACH ROW
EXECUTE FUNCTION admin.update_db_schema_counter();

-- ============================================================================
-- 5. INITIAL DATA - ROADMAP
-- ============================================================================

-- Fase 1: Setup iniziale (1 DB per tutto)
INSERT INTO admin.roadmap_phases (phase_number, name, description, status, start_date) VALUES
(1, 'Setup Iniziale - Single Database',
 'Configurazione database unico per DEV, PROD e 3 tenant test (azienda + 2 clienti beta)',
 'in_progress',
 CURRENT_DATE);

-- Database iniziale
INSERT INTO admin.roadmap_databases (db_identifier, db_purpose, services, status, db_host, db_name) VALUES
('database_main', 'main', ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory', 'billing', 'media', 'chat', 'kb'],
 'active', 'qubhjidkgpxlyruwkfkb.supabase.co', 'postgres');

-- Allocazione servizi iniziali
INSERT INTO admin.roadmap_service_allocation (service_code, db_id, allocation_type, schema_prefix)
SELECT s.code, db.id, 'shared_schema', 'svc_' || s.code
FROM (VALUES
  ('pm'), ('crm'), ('dam'), ('orders'), ('quotations'),
  ('inventory'), ('billing'), ('media'), ('chat'), ('kb')
) AS s(code)
CROSS JOIN admin.roadmap_databases db
WHERE db.db_identifier = 'database_main';

-- Fase 2: Crescita e monitoring
INSERT INTO admin.roadmap_phases (phase_number, name, description, status) VALUES
(2, 'Crescita & Monitoring',
 'Monitoring servizi per identificare quando fare split. Aggiunta clienti trial/single.',
 'planned');

-- Fase 3: Split servizi HOT
INSERT INTO admin.roadmap_phases (phase_number, name, description, status) VALUES
(3, 'Split Servizi HOT',
 'Separazione PM e DAM in database dedicati quando raggiungono soglie (revenue/tenants/performance)',
 'planned');

-- Decisione esempio: Split PM
INSERT INTO admin.roadmap_decisions (phase_id, decision_type, title, description, reason, status)
SELECT p.id, 'db_split',
  'Split PM in database dedicato',
  'Creare database_pm dedicato per servizio Project Management',
  'PM ha superato €50k/mese revenue e 100+ tenant. Performance degradata su database_main.',
  'proposed'
FROM admin.roadmap_phases p WHERE p.phase_number = 3;

-- Fase 4: Replica (quando Supabase la renderà disponibile)
INSERT INTO admin.roadmap_phases (phase_number, name, description, status) VALUES
(4, 'Multi-Region Replica',
 'Attivazione replica EU-West-1 quando Supabase rilascerà la feature',
 'planned');

-- Fase 5: Enterprise tier
INSERT INTO admin.roadmap_phases (phase_number, name, description, status) VALUES
(5, 'Enterprise Tier',
 'Database dedicati per tenant enterprise. Backup FTP orario.',
 'planned');

-- ============================================================================
-- 6. INITIAL DATA - APPS CHECKLIST
-- ============================================================================

-- Apps core da sviluppare
INSERT INTO admin.apps_development (app_code, app_name, description, category, priority, status) VALUES
('pm', 'Project Management', 'Gestione progetti, task, timeline, team collaboration', 'core', 100, 'in_progress'),
('crm', 'CRM', 'Customer Relationship Management, leads, deals, pipeline', 'core', 90, 'planned'),
('dam', 'Digital Asset Management', 'Media library, versioning, approval workflow', 'content', 85, 'planned'),
('orders', 'Order Management', 'Sales & purchase orders, invoicing', 'commerce', 80, 'planned'),
('quotations', 'Quotation System', 'Quote generation, approval, conversion to orders', 'commerce', 75, 'planned'),
('inventory', 'Inventory Management', 'Stock tracking, warehouses, movements', 'commerce', 70, 'planned'),
('billing', 'Billing & Subscriptions', 'Invoicing, payments, subscription management', 'core', 65, 'planned'),
('chat', 'Team Chat', 'Real-time messaging, channels, threads', 'collaboration', 60, 'planned'),
('kb', 'Knowledge Base', 'Documentation, wiki, search', 'collaboration', 55, 'planned'),
('media', 'Media Processing', 'Image/video processing, thumbnails, CDN', 'content', 50, 'planned');

-- Task categories template (si applicano a tutte le app)
DO $$
DECLARE
  app RECORD;
BEGIN
  FOR app IN SELECT id, app_code FROM admin.apps_development LOOP
    INSERT INTO admin.task_categories (app_id, name, order_index, icon, color) VALUES
    (app.id, 'Database', 1, '🗄️', '#3B82F6'),
    (app.id, 'Backend API', 2, '⚙️', '#10B981'),
    (app.id, 'Frontend UI', 3, '🎨', '#8B5CF6'),
    (app.id, 'Testing', 4, '🧪', '#F59E0B'),
    (app.id, 'Documentation', 5, '📚', '#6B7280'),
    (app.id, 'Deployment', 6, '🚀', '#EF4444');
  END FOR;
END $$;

-- Task esempio per PM (già in progress)
DO $$
DECLARE
  pm_id UUID;
  cat_db UUID;
  cat_api UUID;
  cat_ui UUID;
BEGIN
  SELECT id INTO pm_id FROM admin.apps_development WHERE app_code = 'pm';
  SELECT id INTO cat_db FROM admin.task_categories WHERE app_id = pm_id AND name = 'Database';
  SELECT id INTO cat_api FROM admin.task_categories WHERE app_id = pm_id AND name = 'Backend API';
  SELECT id INTO cat_ui FROM admin.task_categories WHERE app_id = pm_id AND name = 'Frontend UI';

  -- Database tasks
  INSERT INTO admin.tasks_checklist (app_id, category_id, title, description, task_type, priority, complexity, status, estimated_hours) VALUES
  (pm_id, cat_db, 'Create schema svc_pm', 'Setup database schema for Project Management service', 'feature', 'critical', 'easy', 'completed', 2),
  (pm_id, cat_db, 'Create projects table', 'Table for projects with tenant isolation', 'feature', 'critical', 'medium', 'completed', 4),
  (pm_id, cat_db, 'Create tasks table', 'Table for tasks with dependencies', 'feature', 'high', 'medium', 'in_progress', 6),
  (pm_id, cat_db, 'Add RLS policies', 'Row Level Security for tenant isolation', 'feature', 'critical', 'hard', 'todo', 8);

  -- API tasks
  INSERT INTO admin.tasks_checklist (app_id, category_id, title, description, task_type, priority, complexity, status, estimated_hours) VALUES
  (pm_id, cat_api, 'CRUD projects API', 'REST API for projects management', 'feature', 'high', 'medium', 'todo', 8),
  (pm_id, cat_api, 'CRUD tasks API', 'REST API for tasks with dependencies', 'feature', 'high', 'hard', 'todo', 12),
  (pm_id, cat_api, 'WebSocket real-time updates', 'Real-time task updates via WebSocket', 'feature', 'medium', 'expert', 'todo', 16);

  -- UI tasks
  INSERT INTO admin.tasks_checklist (app_id, category_id, title, description, task_type, priority, complexity, status, estimated_hours) VALUES
  (pm_id, cat_ui, 'Projects dashboard', 'Overview of all projects with filters', 'feature', 'high', 'medium', 'todo', 12),
  (pm_id, cat_ui, 'Kanban board', 'Drag & drop kanban for task management', 'feature', 'high', 'hard', 'todo', 20),
  (pm_id, cat_ui, 'Gantt chart view', 'Timeline view with dependencies', 'feature', 'medium', 'expert', 'todo', 24);
END $$;

-- ============================================================================
-- 7. GRANTS
-- ============================================================================

GRANT USAGE ON SCHEMA admin TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA admin TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA admin TO anon;

-- ============================================================================
-- DONE!
-- ============================================================================

COMMENT ON SCHEMA admin IS 'Admin panel: roadmap interattiva e checklist task per app';
COMMENT ON TABLE admin.roadmap_phases IS 'Fasi evolutive architettura (setup, growth, split, replica, etc.)';
COMMENT ON TABLE admin.roadmap_decisions IS 'Decisioni architetturali per fase (split DB, migrations, etc.)';
COMMENT ON TABLE admin.roadmap_databases IS 'Tracking database (main, service-specific, tenant-dedicated)';
COMMENT ON TABLE admin.roadmap_service_allocation IS 'Allocazione servizi per database con metriche per split decision';
COMMENT ON TABLE admin.apps_development IS 'Apps/Servizi in sviluppo con progress tracking';
COMMENT ON TABLE admin.tasks_checklist IS 'Task checklist interattiva per app con dependencies';
COMMENT ON TABLE admin.tasks_activity IS 'Activity log per task (comments, status changes, etc.)';
