-- Migration 028: PM Core System - FULLY GENERIC
-- Universal project management system that works for ANY industry
-- No industry-specific templates included (add them via separate migrations)

-- Create UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create mock users table (temporary for testing - remove in production)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert test users (remove in production)
INSERT INTO users (id, email, name) VALUES
    ('00000000-0000-0000-0000-000000000001', 'admin@example.com', 'Admin User'),
    ('00000000-0000-0000-0000-000000000002', 'user1@example.com', 'User One'),
    ('00000000-0000-0000-0000-000000000003', 'user2@example.com', 'User Two')
ON CONFLICT (email) DO NOTHING;

-- Create PM schema
CREATE SCHEMA IF NOT EXISTS pm;

-- ============================================================================
-- PROJECT TEMPLATES (Generic)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.project_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    template_key VARCHAR(100) NOT NULL,
    template_name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- User-defined: 'software', 'construction', 'marketing', etc.
    icon VARCHAR(50),

    estimated_duration_days INTEGER,
    default_priority VARCHAR(20) DEFAULT 'medium',

    -- Template configuration (flexible JSON)
    task_templates JSONB, -- [{name, category, estimated_hours, order, dependencies}]
    milestone_templates JSONB, -- [{name, due_days, description}]
    custom_fields_schema JSONB, -- Define custom fields for this template

    usage_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, template_key)
);

CREATE INDEX idx_templates_tenant ON pm.project_templates(tenant_id);
CREATE INDEX idx_templates_category ON pm.project_templates(category);

-- ============================================================================
-- PROJECTS (Generic)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- Basic info
    project_code VARCHAR(50) UNIQUE,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,

    -- Template link (optional - projects can be created without template)
    template_id UUID REFERENCES pm.project_templates(id),

    -- Status (customizable per tenant)
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

    -- Budget (optional)
    estimated_budget DECIMAL(12,2),
    actual_cost DECIMAL(12,2) DEFAULT 0,

    -- Flexible custom fields (industry-specific data goes here)
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
-- TASKS (Generic)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    project_id UUID NOT NULL REFERENCES pm.projects(id) ON DELETE CASCADE,

    -- Basic info
    task_name VARCHAR(200) NOT NULL,
    description TEXT,
    task_category VARCHAR(50), -- User-defined categories

    -- Assignment (AI-ready)
    assigned_to UUID REFERENCES users(id),
    assigned_by UUID REFERENCES users(id),
    assignment_method VARCHAR(50), -- 'manual', 'ai_suggested', 'ai_accepted'
    ai_suggested_users UUID[],
    ai_assignment_reasoning JSONB,

    -- Status (customizable)
    status VARCHAR(50) DEFAULT 'todo',
    priority VARCHAR(20) DEFAULT 'medium',

    -- Dates
    start_date DATE,
    due_date DATE,
    completed_at TIMESTAMPTZ,

    -- Time tracking
    estimated_hours DECIMAL(8,2),
    actual_hours DECIMAL(8,2) DEFAULT 0,

    -- Order & dependencies
    task_order INTEGER DEFAULT 0,
    depends_on UUID[], -- Array of task IDs this task depends on

    -- Flexible custom fields
    custom_fields JSONB,

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

    -- Quality metrics (for AI learning)
    approved_first_time BOOLEAN DEFAULT FALSE,
    revision_count INTEGER DEFAULT 0,
    quality_score DECIMAL(3,2), -- 0.00 to 1.00

    -- Time-of-day performance (Patent #4 - AI time-optimized assignment)
    hour_of_day INTEGER, -- 0-23
    day_of_week INTEGER, -- 0-6 (Sunday = 0)

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_completions_user ON pm.task_completions(assigned_to);
CREATE INDEX idx_completions_category ON pm.task_completions(task_category);
CREATE INDEX idx_completions_tenant ON pm.task_completions(tenant_id);

-- ============================================================================
-- MILESTONES (Generic)
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
-- COMMENTS / DISCUSSIONS (Generic)
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
-- TIME ENTRIES (optional - for detailed time tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    task_id UUID NOT NULL REFERENCES pm.tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),

    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_minutes INTEGER,

    description TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_time_entries_task ON pm.time_entries(task_id);
CREATE INDEX idx_time_entries_user ON pm.time_entries(user_id);

-- ============================================================================
-- HELPER FUNCTION: Generate Project Code
-- ============================================================================

CREATE OR REPLACE FUNCTION pm.generate_project_code(p_tenant_id UUID)
RETURNS VARCHAR AS $$
DECLARE
    project_count INTEGER;
    new_code VARCHAR;
BEGIN
    SELECT COUNT(*) INTO project_count
    FROM pm.projects
    WHERE tenant_id = p_tenant_id;

    new_code := 'PRJ-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD((project_count + 1)::TEXT, 4, '0');

    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGER: Update completion percentage when tasks complete
-- ============================================================================

CREATE OR REPLACE FUNCTION pm.update_project_completion()
RETURNS TRIGGER AS $$
DECLARE
    total_tasks INTEGER;
    completed_tasks INTEGER;
    new_percentage INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_tasks
    FROM pm.tasks
    WHERE project_id = NEW.project_id;

    SELECT COUNT(*) INTO completed_tasks
    FROM pm.tasks
    WHERE project_id = NEW.project_id AND status = 'done';

    IF total_tasks > 0 THEN
        new_percentage := ROUND((completed_tasks::DECIMAL / total_tasks) * 100);

        UPDATE pm.projects
        SET completion_percentage = new_percentage,
            updated_at = NOW()
        WHERE id = NEW.project_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_completion
    AFTER UPDATE OF status ON pm.tasks
    FOR EACH ROW
    WHEN (NEW.status = 'done' OR OLD.status = 'done')
    EXECUTE FUNCTION pm.update_project_completion();

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ PM Core System Installed!';
    RAISE NOTICE '📊 Generic, Universal, Industry-Agnostic';
    RAISE NOTICE '🎯 Ready for ANY business vertical';
    RAISE NOTICE '';
    RAISE NOTICE '💡 Next: Install industry-specific templates';
    RAISE NOTICE '   - 029_pm_editorial_templates.sql (publishing)';
    RAISE NOTICE '   - 030_pm_software_templates.sql (software dev)';
    RAISE NOTICE '   - 031_pm_construction_templates.sql (construction)';
    RAISE NOTICE '   - Or create your own!';
    RAISE NOTICE '';
END $$;
