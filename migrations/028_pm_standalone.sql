-- Migration 028: PM Core System - Standalone Version
-- Includes mock users table for testing

-- Create UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create mock users table (temporary for testing)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert some test users
INSERT INTO users (id, email, name) VALUES
    ('00000000-0000-0000-0000-000000000001', 'admin@example.com', 'Admin User'),
    ('00000000-0000-0000-0000-000000000002', 'maria.rossi@example.com', 'Maria Rossi'),
    ('00000000-0000-0000-0000-000000000003', 'giovanni.bianchi@example.com', 'Giovanni Bianchi')
ON CONFLICT (email) DO NOTHING;

-- Create PM schema
CREATE SCHEMA IF NOT EXISTS pm;

-- ============================================================================
-- PROJECT TEMPLATES
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.project_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    template_key VARCHAR(100) NOT NULL,
    template_name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- 'editorial', 'marketing', 'software', 'custom'
    icon VARCHAR(50),

    estimated_duration_days INTEGER,
    default_priority VARCHAR(20) DEFAULT 'medium',

    task_templates JSONB, -- Array of task templates
    milestone_templates JSONB, -- Array of milestone templates

    usage_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, template_key)
);

-- ============================================================================
-- PROJECTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- Basic info
    project_code VARCHAR(50) UNIQUE,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,

    -- Template link
    template_id UUID REFERENCES pm.project_templates(id),

    -- Status
    status VARCHAR(50) DEFAULT 'planning',
    priority VARCHAR(20) DEFAULT 'medium',

    -- Dates
    start_date DATE,
    end_date DATE,
    actual_end_date DATE,

    -- Progress
    completion_percentage INTEGER DEFAULT 0,

    -- Team
    project_manager_id UUID REFERENCES users(id),

    -- Budget
    estimated_budget DECIMAL(12,2),
    actual_cost DECIMAL(12,2) DEFAULT 0,

    -- Custom fields for editorial
    custom_fields JSONB,

    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_projects_tenant ON pm.projects(tenant_id);
CREATE INDEX idx_projects_status ON pm.projects(status);
CREATE INDEX idx_projects_pm ON pm.projects(project_manager_id);
CREATE INDEX idx_projects_template ON pm.projects(template_id);

-- ============================================================================
-- TASKS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID NOT NULL REFERENCES pm.projects(id) ON DELETE CASCADE,

    -- Basic info
    task_name VARCHAR(200) NOT NULL,
    description TEXT,
    task_category VARCHAR(50), -- 'editing', 'layout', 'translation', 'printing'

    -- Assignment
    assigned_to UUID REFERENCES users(id),
    assigned_by UUID REFERENCES users(id),
    assignment_method VARCHAR(50), -- 'manual', 'ai_suggested', 'ai_accepted'
    ai_suggested_users UUID[],
    ai_assignment_reasoning JSONB,

    -- Status
    status VARCHAR(50) DEFAULT 'todo',
    priority VARCHAR(20) DEFAULT 'medium',

    -- Dates
    start_date DATE,
    due_date DATE,
    completed_at TIMESTAMPTZ,

    -- Time tracking
    estimated_hours DECIMAL(8,2),
    actual_hours DECIMAL(8,2) DEFAULT 0,

    -- Order
    task_order INTEGER DEFAULT 0,

    -- Dependencies
    depends_on UUID[], -- Array of task IDs

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_project ON pm.tasks(project_id);
CREATE INDEX idx_tasks_assigned ON pm.tasks(assigned_to);
CREATE INDEX idx_tasks_status ON pm.tasks(status);
CREATE INDEX idx_tasks_tenant ON pm.tasks(tenant_id);

-- ============================================================================
-- TASK COMPLETIONS (for AI skill detection - Patent #3)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.task_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    task_id UUID REFERENCES pm.tasks(id) ON DELETE CASCADE,
    assigned_to UUID NOT NULL REFERENCES users(id),
    task_category VARCHAR(50) NOT NULL,

    -- Time tracking
    estimated_hours DECIMAL(8,2),
    actual_hours DECIMAL(8,2),
    assigned_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Quality metrics
    approved_first_time BOOLEAN DEFAULT FALSE,
    revision_count INTEGER DEFAULT 0,
    quality_score DECIMAL(3,2), -- 0.00 to 1.00

    -- Time-of-day performance (Patent #4)
    hour_of_day INTEGER, -- 0-23
    day_of_week INTEGER, -- 0-6 (Sunday = 0)

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_completions_user ON pm.task_completions(assigned_to);
CREATE INDEX idx_completions_category ON pm.task_completions(task_category);
CREATE INDEX idx_completions_tenant ON pm.task_completions(tenant_id);

-- ============================================================================
-- MILESTONES
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES pm.projects(id) ON DELETE CASCADE,

    milestone_name VARCHAR(200) NOT NULL,
    description TEXT,
    due_date DATE,
    completed_at TIMESTAMPTZ,
    status VARCHAR(50) DEFAULT 'pending',

    milestone_order INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_milestones_project ON pm.milestones(project_id);

-- ============================================================================
-- COMMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    project_id UUID REFERENCES pm.projects(id) ON DELETE CASCADE,
    task_id UUID REFERENCES pm.tasks(id) ON DELETE CASCADE,

    comment_text TEXT NOT NULL,
    author_id UUID REFERENCES users(id),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comments_project ON pm.comments(project_id);
CREATE INDEX idx_comments_task ON pm.comments(task_id);

-- ============================================================================
-- SEED DATA: Editorial Templates
-- ============================================================================

INSERT INTO pm.project_templates (id, tenant_id, template_key, template_name, category, description, estimated_duration_days, task_templates, milestone_templates)
VALUES
-- Template 1: Book Publication
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'book_publication',
    'Pubblicazione Libro',
    'editorial',
    'Workflow completo per pubblicazione libro: editing, impaginazione, stampa',
    180,
    '[
        {"name": "Revisione Editoriale", "category": "editing", "estimated_hours": 80, "order": 1},
        {"name": "Impaginazione", "category": "layout", "estimated_hours": 40, "order": 2},
        {"name": "Correzione Bozze", "category": "editing", "estimated_hours": 24, "order": 3},
        {"name": "Progettazione Copertina", "category": "design", "estimated_hours": 16, "order": 4},
        {"name": "Stampa Prototipo", "category": "printing", "estimated_hours": 8, "order": 5},
        {"name": "Revisione Finale", "category": "editing", "estimated_hours": 16, "order": 6},
        {"name": "Stampa Tiratura", "category": "printing", "estimated_hours": 4, "order": 7},
        {"name": "Distribuzione", "category": "logistics", "estimated_hours": 8, "order": 8}
    ]'::jsonb,
    '[
        {"name": "Bozza Approvata", "due_days": 60},
        {"name": "Layout Completato", "due_days": 120},
        {"name": "Stampa Confermata", "due_days": 150},
        {"name": "Distribuzione Avviata", "due_days": 180}
    ]'::jsonb
),

-- Template 2: Tourist Guide
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'tourist_guide',
    'Guida Turistica',
    'editorial',
    'Creazione guida turistica con foto, mappe, traduzioni',
    120,
    '[
        {"name": "Ricerca e Sopralluoghi", "category": "research", "estimated_hours": 40, "order": 1},
        {"name": "Scrittura Contenuti", "category": "writing", "estimated_hours": 60, "order": 2},
        {"name": "Fotografia", "category": "photography", "estimated_hours": 24, "order": 3},
        {"name": "Traduzione", "category": "translation", "estimated_hours": 48, "order": 4},
        {"name": "Editing Multilingua", "category": "editing", "estimated_hours": 32, "order": 5},
        {"name": "Impaginazione", "category": "layout", "estimated_hours": 24, "order": 6},
        {"name": "Stampa", "category": "printing", "estimated_hours": 8, "order": 7}
    ]'::jsonb,
    '[
        {"name": "Contenuti Completati", "due_days": 45},
        {"name": "Traduzioni Approvate", "due_days": 75},
        {"name": "Pronta per Stampa", "due_days": 105}
    ]'::jsonb
),

-- Template 3: Gadget Production
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'gadget_production',
    'Gadget Promozionale',
    'editorial',
    'Produzione gadget turistici (magneti, segnalibri, ecc.)',
    60,
    '[
        {"name": "Concept Design", "category": "design", "estimated_hours": 16, "order": 1},
        {"name": "Prototipo", "category": "prototyping", "estimated_hours": 8, "order": 2},
        {"name": "Approvazione Cliente", "category": "approval", "estimated_hours": 4, "order": 3},
        {"name": "Ordine Materiali", "category": "procurement", "estimated_hours": 4, "order": 4},
        {"name": "Produzione", "category": "manufacturing", "estimated_hours": 16, "order": 5},
        {"name": "Controllo Qualità", "category": "qa", "estimated_hours": 8, "order": 6},
        {"name": "Confezionamento", "category": "packaging", "estimated_hours": 8, "order": 7}
    ]'::jsonb,
    '[
        {"name": "Design Approvato", "due_days": 14},
        {"name": "Materiali Arrivati", "due_days": 30},
        {"name": "Produzione Completata", "due_days": 52}
    ]'::jsonb
);

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

DO $$
DECLARE
    template_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO template_count FROM pm.project_templates;
    RAISE NOTICE '';
    RAISE NOTICE '✅ PM System Migration Complete!';
    RAISE NOTICE '📊 Created % templates', template_count;
    RAISE NOTICE '🏢 Ready for Editorial House';
    RAISE NOTICE '';
END $$;
