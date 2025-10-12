-- Migration 028: Complete PM Core System with Template Overlay
-- Based on PROJECT_MANAGEMENT_SYSTEM.md specifications

-- Create PM schema if not exists
CREATE SCHEMA IF NOT EXISTS pm;

-- ============================================================================
-- FLEXIBLE ENTITY SYSTEM (Cliente, Progetto, Iniziativa)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.entity_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    type_key VARCHAR(50) NOT NULL, -- 'client', 'project', 'initiative', 'campaign'
    type_name VARCHAR(100) NOT NULL,
    icon VARCHAR(50), -- 'building', 'folder', 'target'
    color VARCHAR(20), -- '#4CAF50'

    -- Capabilities
    can_have_children BOOLEAN DEFAULT TRUE,
    can_have_tasks BOOLEAN DEFAULT TRUE,
    can_have_budget BOOLEAN DEFAULT TRUE,

    -- Custom fields schema
    custom_fields_schema JSONB, -- [{name: 'budget', type: 'number', required: true}]

    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, type_key)
);

CREATE TABLE IF NOT EXISTS pm.entities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- Type
    entity_type_id UUID NOT NULL REFERENCES pm.entity_types(id),

    -- Basic info
    name VARCHAR(200) NOT NULL,
    description TEXT,
    code VARCHAR(50), -- 'CLI-001', 'PRJ-2025-042'

    -- Status
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'completed', 'archived', 'cancelled'
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'

    -- Dates
    start_date DATE,
    end_date DATE,

    -- Budget
    budget DECIMAL(12,2),
    spent DECIMAL(12,2) DEFAULT 0,

    -- Custom fields
    custom_fields JSONB,

    -- Owner
    owner_id UUID REFERENCES users(id),

    -- Metadata
    tags TEXT[],
    metadata JSONB,

    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_entities_tenant ON pm.entities(tenant_id);
CREATE INDEX idx_entities_type ON pm.entities(entity_type_id);
CREATE INDEX idx_entities_status ON pm.entities(status);
CREATE INDEX idx_entities_owner ON pm.entities(owner_id);
CREATE INDEX idx_entities_code ON pm.entities(code);

-- Many-to-many relations between entities
CREATE TABLE IF NOT EXISTS pm.entity_relations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    parent_entity_id UUID NOT NULL REFERENCES pm.entities(id) ON DELETE CASCADE,
    child_entity_id UUID NOT NULL REFERENCES pm.entities(id) ON DELETE CASCADE,

    relation_type VARCHAR(50) DEFAULT 'contains', -- 'contains', 'depends_on', 'related_to'

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(parent_entity_id, child_entity_id)
);

CREATE INDEX idx_entity_relations_parent ON pm.entity_relations(parent_entity_id);
CREATE INDEX idx_entity_relations_child ON pm.entity_relations(child_entity_id);

-- ============================================================================
-- PROJECT TEMPLATES
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.project_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    template_name VARCHAR(200) NOT NULL,
    template_key VARCHAR(100) NOT NULL, -- 'book_publication', 'tourist_guide', 'gadget_production'
    category VARCHAR(100), -- 'editorial', 'marketing', 'product'

    description TEXT,

    -- Template configuration
    default_entity_type_id UUID REFERENCES pm.entity_types(id),
    estimated_duration_days INTEGER,

    -- Task templates
    task_templates JSONB, -- [{name: '', category: '', estimated_hours: 0, order: 1}]

    -- Milestone templates
    milestone_templates JSONB, -- [{name: '', days_from_start: 30}]

    -- Default assignees (by role)
    default_assignments JSONB, -- [{task_category: 'editing', role: 'editor'}]

    -- Metadata
    is_public BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,

    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, template_key)
);

CREATE INDEX idx_project_templates_tenant ON pm.project_templates(tenant_id);
CREATE INDEX idx_project_templates_category ON pm.project_templates(category);

-- ============================================================================
-- PROJECTS (core PM)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- Hierarchy
    parent_project_id UUID REFERENCES pm.projects(id) ON DELETE SET NULL,

    -- Template
    template_id UUID REFERENCES pm.project_templates(id),

    -- Entity link (optional - can link to client, initiative, etc)
    linked_entity_id UUID REFERENCES pm.entities(id),

    -- Basic info
    project_code VARCHAR(50) NOT NULL,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,

    -- Status
    status VARCHAR(50) DEFAULT 'planning', -- 'planning', 'active', 'on_hold', 'completed', 'cancelled'
    priority VARCHAR(20) DEFAULT 'medium',
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),

    -- Dates
    start_date DATE,
    end_date DATE,
    actual_start_date DATE,
    actual_end_date DATE,

    -- Budget
    budget DECIMAL(12,2),
    spent DECIMAL(12,2) DEFAULT 0,

    -- Team
    project_manager_id UUID REFERENCES users(id),
    team_members UUID[], -- Array of user IDs

    -- Files (cross-system aggregation will be in view)

    -- Custom fields
    custom_fields JSONB,

    -- Metadata
    tags TEXT[],
    color VARCHAR(20), -- For UI display

    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, project_code)
);

CREATE INDEX idx_projects_tenant ON pm.projects(tenant_id);
CREATE INDEX idx_projects_parent ON pm.projects(parent_project_id);
CREATE INDEX idx_projects_entity ON pm.projects(linked_entity_id);
CREATE INDEX idx_projects_status ON pm.projects(status);
CREATE INDEX idx_projects_manager ON pm.projects(project_manager_id);
CREATE INDEX idx_projects_template ON pm.projects(template_id);

-- ============================================================================
-- TASKS (with AI assignment integration)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES pm.projects(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,

    -- Task info
    task_name VARCHAR(200) NOT NULL,
    task_category VARCHAR(100), -- Links to resource_skills for AI assignment
    description TEXT,

    -- Hierarchy
    parent_task_id UUID REFERENCES pm.tasks(id) ON DELETE CASCADE,
    task_order INTEGER DEFAULT 0,

    -- Assignment
    assigned_to UUID REFERENCES users(id),
    assigned_at TIMESTAMPTZ,
    assigned_by UUID REFERENCES users(id),

    -- AI assignment metadata (Patent #3 & #4)
    ai_suggested_users UUID[], -- Top 5 AI recommendations
    ai_assignment_reasoning JSONB, -- {userId: {skillScore: 85, timeBonus: 15, ...}}
    assignment_method VARCHAR(20) DEFAULT 'manual', -- 'manual', 'ai_accepted', 'ai_modified'

    -- Status
    status VARCHAR(50) DEFAULT 'todo', -- 'todo', 'in_progress', 'review', 'done', 'blocked'
    priority VARCHAR(20) DEFAULT 'medium',
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),

    -- Time tracking
    estimated_hours DECIMAL(6,2),
    actual_hours DECIMAL(6,2) DEFAULT 0,

    -- Dates
    scheduled_start TIMESTAMPTZ,
    scheduled_end TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,
    due_date TIMESTAMPTZ,

    -- Dependencies
    depends_on UUID[], -- Task IDs that must complete first
    blocks UUID[], -- Task IDs that are blocked by this

    -- Quality tracking (for AI skill detection)
    quality_score DECIMAL(3,2), -- 0.00-1.00
    approved_first_time BOOLEAN,
    revision_count INTEGER DEFAULT 0,

    -- Files
    attachments JSONB,

    -- Checklist
    checklist JSONB, -- [{text: '', completed: false}]

    -- Custom fields
    custom_fields JSONB,

    -- Workflow recording link (Patent #1)
    workflow_recording_id UUID REFERENCES pm.workflow_recordings(id),

    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_project ON pm.tasks(project_id);
CREATE INDEX idx_tasks_assigned ON pm.tasks(assigned_to);
CREATE INDEX idx_tasks_status ON pm.tasks(status);
CREATE INDEX idx_tasks_category ON pm.tasks(task_category);
CREATE INDEX idx_tasks_parent ON pm.tasks(parent_task_id);
CREATE INDEX idx_tasks_due ON pm.tasks(due_date);

-- ============================================================================
-- RESOURCE SKILLS & PERFORMANCE (Patent #3 - AI Auto-Skill Detection)
-- ============================================================================

-- Already exists from previous migration, but ensure compatibility
CREATE TABLE IF NOT EXISTS pm.task_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES pm.tasks(id) ON DELETE CASCADE,
    assigned_to UUID NOT NULL REFERENCES users(id),
    tenant_id UUID NOT NULL,

    -- Task classification
    task_category VARCHAR(100) NOT NULL,
    task_type VARCHAR(50),

    -- Time tracking
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    assigned_at TIMESTAMPTZ NOT NULL,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ NOT NULL,

    -- Quality metrics
    approved_first_time BOOLEAN DEFAULT FALSE,
    revision_count INTEGER DEFAULT 0,
    rejection_count INTEGER DEFAULT 0,
    quality_score DECIMAL(3,2) CHECK (quality_score BETWEEN 0 AND 1),

    -- Time patterns (generated columns)
    hour_of_day INTEGER GENERATED ALWAYS AS (
        EXTRACT(HOUR FROM completed_at)
    ) STORED,
    day_of_week INTEGER GENERATED ALWAYS AS (
        EXTRACT(ISODOW FROM completed_at)
    ) STORED,

    -- Performance metric (generated column)
    time_efficiency DECIMAL(4,2) GENERATED ALWAYS AS (
        CASE
            WHEN estimated_hours > 0 THEN actual_hours / estimated_hours
            ELSE 1.0
        END
    ) STORED,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_task_completions_user_category ON pm.task_completions(assigned_to, task_category);
CREATE INDEX idx_task_completions_time ON pm.task_completions(completed_at DESC);

-- ============================================================================
-- TIME TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id),

    -- Link to task
    task_id UUID REFERENCES pm.tasks(id) ON DELETE SET NULL,
    project_id UUID REFERENCES pm.projects(id) ON DELETE SET NULL,

    -- Time
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_hours DECIMAL(6,2),

    -- Billing
    billable BOOLEAN DEFAULT TRUE,
    hourly_rate DECIMAL(10,2),

    -- Description
    description TEXT,

    -- Auto-detected from workflow learning
    workflow_recording_id UUID REFERENCES pm.workflow_recordings(id),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_time_entries_user ON pm.time_entries(user_id, start_time DESC);
CREATE INDEX idx_time_entries_task ON pm.time_entries(task_id);
CREATE INDEX idx_time_entries_project ON pm.time_entries(project_id);

-- ============================================================================
-- MILESTONES
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES pm.projects(id) ON DELETE CASCADE,

    milestone_name VARCHAR(200) NOT NULL,
    description TEXT,

    -- Date
    due_date DATE NOT NULL,
    completed_date DATE,

    -- Status
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'completed', 'missed'

    -- Criteria
    completion_criteria JSONB, -- [{description: '', completed: false}]

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_milestones_project ON pm.milestones(project_id);
CREATE INDEX idx_milestones_due ON pm.milestones(due_date);

-- ============================================================================
-- COMMENTS & ACTIVITY
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Can comment on project or task
    project_id UUID REFERENCES pm.projects(id) ON DELETE CASCADE,
    task_id UUID REFERENCES pm.tasks(id) ON DELETE CASCADE,

    -- Comment
    user_id UUID NOT NULL REFERENCES users(id),
    comment_text TEXT NOT NULL,

    -- Threading
    parent_comment_id UUID REFERENCES pm.comments(id) ON DELETE CASCADE,

    -- Mentions
    mentioned_users UUID[],

    -- Attachments
    attachments JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comments_project ON pm.comments(project_id, created_at DESC);
CREATE INDEX idx_comments_task ON pm.comments(task_id, created_at DESC);
CREATE INDEX idx_comments_user ON pm.comments(user_id);

-- ============================================================================
-- WORKFLOW AUTOMATION (table-based, legally safe)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.workflow_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    rule_name VARCHAR(200) NOT NULL,
    rule_key VARCHAR(100) NOT NULL,

    -- Trigger
    trigger_type VARCHAR(50) NOT NULL, -- 'task_created', 'task_completed', 'status_changed', 'due_date_approaching'
    trigger_conditions JSONB, -- {status: 'completed', category: 'editing'}

    -- Actions
    actions JSONB NOT NULL, -- [{type: 'assign_task', params: {...}}, {type: 'send_notification', ...}]

    -- External webhooks (n8n/Zapier)
    webhook_url TEXT,
    webhook_method VARCHAR(10) DEFAULT 'POST',
    webhook_headers JSONB,

    -- Status
    enabled BOOLEAN DEFAULT TRUE,

    -- Stats
    execution_count INTEGER DEFAULT 0,
    last_executed_at TIMESTAMPTZ,

    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, rule_key)
);

CREATE INDEX idx_workflow_rules_tenant ON pm.workflow_rules(tenant_id);
CREATE INDEX idx_workflow_rules_trigger ON pm.workflow_rules(trigger_type) WHERE enabled = TRUE;

-- ============================================================================
-- VIEWS (Cross-System File Aggregation)
-- ============================================================================

-- Unified file view from DAM + Accounting + MRP + PIM
CREATE OR REPLACE VIEW pm.v_project_files AS
SELECT
    p.id as project_id,
    'dam' as source_system,
    a.id as file_id,
    a.file_name,
    a.file_url,
    a.mime_type,
    a.file_size,
    a.created_at,
    u.name as uploaded_by_name
FROM pm.projects p
LEFT JOIN dam.assets a ON a.project_id::TEXT = p.id::TEXT
LEFT JOIN users u ON a.uploaded_by = u.id
WHERE a.id IS NOT NULL

UNION ALL

SELECT
    p.id as project_id,
    'accounting' as source_system,
    d.id as file_id,
    d.document_name as file_name,
    d.document_url as file_url,
    'application/pdf' as mime_type,
    NULL as file_size,
    d.created_at,
    u.name as uploaded_by_name
FROM pm.projects p
LEFT JOIN accounting.documents d ON d.project_id = p.id
LEFT JOIN users u ON d.created_by = u.id
WHERE d.id IS NOT NULL

UNION ALL

SELECT
    p.id as project_id,
    'mrp' as source_system,
    po.id as file_id,
    po.order_number as file_name,
    po.attachment_url as file_url,
    'application/pdf' as mime_type,
    NULL as file_size,
    po.created_at,
    u.name as uploaded_by_name
FROM pm.projects p
LEFT JOIN mrp.production_orders po ON po.project_id = p.id
LEFT JOIN users u ON po.created_by = u.id
WHERE po.id IS NOT NULL;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Auto-generate project code
CREATE OR REPLACE FUNCTION pm.generate_project_code(tenant_id UUID)
RETURNS VARCHAR AS $$
DECLARE
    year_str VARCHAR := TO_CHAR(CURRENT_DATE, 'YYYY');
    next_number INTEGER;
BEGIN
    SELECT COALESCE(MAX(CAST(SUBSTRING(project_code FROM '[0-9]+$') AS INTEGER)), 0) + 1
    INTO next_number
    FROM pm.projects
    WHERE pm.projects.tenant_id = $1
      AND project_code LIKE 'PRJ-' || year_str || '-%';

    RETURN 'PRJ-' || year_str || '-' || LPAD(next_number::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Calculate project completion
CREATE OR REPLACE FUNCTION pm.calculate_project_completion(project_id UUID)
RETURNS INTEGER AS $$
DECLARE
    total_tasks INTEGER;
    completed_tasks INTEGER;
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE status = 'done')
    INTO total_tasks, completed_tasks
    FROM pm.tasks
    WHERE pm.tasks.project_id = $1;

    IF total_tasks = 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND((completed_tasks::DECIMAL / total_tasks) * 100);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update project completion on task status change
CREATE OR REPLACE FUNCTION pm.update_project_completion()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE pm.projects
    SET completion_percentage = pm.calculate_project_completion(NEW.project_id),
        updated_at = NOW()
    WHERE id = NEW.project_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_project_completion
    AFTER INSERT OR UPDATE OF status ON pm.tasks
    FOR EACH ROW
    EXECUTE FUNCTION pm.update_project_completion();

-- Record task completion for AI skill detection
CREATE OR REPLACE FUNCTION pm.record_task_completion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'done' AND OLD.status != 'done' THEN
        INSERT INTO pm.task_completions (
            task_id,
            assigned_to,
            tenant_id,
            task_category,
            estimated_hours,
            actual_hours,
            assigned_at,
            started_at,
            completed_at,
            approved_first_time,
            revision_count,
            quality_score
        ) VALUES (
            NEW.id,
            NEW.assigned_to,
            NEW.tenant_id,
            NEW.task_category,
            NEW.estimated_hours,
            NEW.actual_hours,
            NEW.assigned_at,
            NEW.actual_start,
            NOW(),
            NEW.approved_first_time,
            NEW.revision_count,
            NEW.quality_score
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_record_task_completion
    AFTER UPDATE OF status ON pm.tasks
    FOR EACH ROW
    WHEN (NEW.assigned_to IS NOT NULL)
    EXECUTE FUNCTION pm.record_task_completion();

-- Grant permissions
GRANT ALL ON SCHEMA pm TO ewh;
GRANT ALL ON ALL TABLES IN SCHEMA pm TO ewh;
GRANT ALL ON ALL SEQUENCES IN SCHEMA pm TO ewh;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pm TO ewh;

-- Sample data: Entity types
INSERT INTO pm.entity_types (tenant_id, type_key, type_name, icon, color, can_have_children, can_have_tasks, can_have_budget, custom_fields_schema)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'client', 'Cliente', 'building', '#2196F3', TRUE, FALSE, TRUE, '[]'::jsonb),
    ('00000000-0000-0000-0000-000000000001', 'initiative', 'Iniziativa', 'target', '#9C27B0', TRUE, TRUE, TRUE, '[{"name":"budget_code","type":"text","label":"Codice Budget","required":true}]'::jsonb),
    ('00000000-0000-0000-0000-000000000001', 'campaign', 'Campagna Marketing', 'megaphone', '#FF9800', TRUE, TRUE, TRUE, '[]'::jsonb)
ON CONFLICT (tenant_id, type_key) DO NOTHING;

-- Sample templates for editorial house
INSERT INTO pm.project_templates (tenant_id, template_name, template_key, category, description, estimated_duration_days, task_templates, milestone_templates)
VALUES
    (
        '00000000-0000-0000-0000-000000000001',
        'Pubblicazione Libro',
        'book_publication',
        'editorial',
        'Template completo per la pubblicazione di un libro: dall''editing alla stampa',
        180,
        '[
            {"name":"Revisione Editoriale","category":"editing","estimated_hours":80,"order":1},
            {"name":"Impaginazione","category":"layout","estimated_hours":40,"order":2},
            {"name":"Correzione Bozze","category":"proofreading","estimated_hours":30,"order":3},
            {"name":"Progettazione Copertina","category":"design","estimated_hours":24,"order":4},
            {"name":"Stampa Prototipo","category":"printing","estimated_hours":8,"order":5},
            {"name":"Revisione Finale","category":"review","estimated_hours":16,"order":6},
            {"name":"Stampa Tiratura","category":"printing","estimated_hours":40,"order":7},
            {"name":"Distribuzione","category":"logistics","estimated_hours":16,"order":8}
        ]'::jsonb,
        '[
            {"name":"Editing Completato","days_from_start":60},
            {"name":"Bozze Approvate","days_from_start":120},
            {"name":"Stampa Avviata","days_from_start":150},
            {"name":"Libri Consegnati","days_from_start":180}
        ]'::jsonb
    ),
    (
        '00000000-0000-0000-0000-000000000001',
        'Guida Turistica',
        'tourist_guide',
        'editorial',
        'Template per guide turistiche con ricerca sul campo',
        120,
        '[
            {"name":"Ricerca e Sopralluoghi","category":"research","estimated_hours":60,"order":1},
            {"name":"Scrittura Contenuti","category":"writing","estimated_hours":80,"order":2},
            {"name":"Fotografia","category":"photography","estimated_hours":40,"order":3},
            {"name":"Traduzione","category":"translation","estimated_hours":60,"order":4},
            {"name":"Editing Multilingua","category":"editing","estimated_hours":40,"order":5},
            {"name":"Impaginazione","category":"layout","estimated_hours":30,"order":6},
            {"name":"Stampa","category":"printing","estimated_hours":24,"order":7}
        ]'::jsonb,
        '[
            {"name":"Ricerca Completata","days_from_start":30},
            {"name":"Contenuti Scritti","days_from_start":60},
            {"name":"Traduzioni Pronte","days_from_start":90},
            {"name":"Guide Stampate","days_from_start":120}
        ]'::jsonb
    ),
    (
        '00000000-0000-0000-0000-000000000001',
        'Gadget Promozionale',
        'gadget_production',
        'product',
        'Template per produzione gadget turistici',
        60,
        '[
            {"name":"Concept Design","category":"design","estimated_hours":16,"order":1},
            {"name":"Prototipo","category":"prototyping","estimated_hours":24,"order":2},
            {"name":"Approvazione Cliente","category":"review","estimated_hours":4,"order":3},
            {"name":"Ordine Materiali","category":"procurement","estimated_hours":8,"order":4},
            {"name":"Produzione","category":"manufacturing","estimated_hours":80,"order":5},
            {"name":"Controllo Qualità","category":"quality_check","estimated_hours":16,"order":6},
            {"name":"Confezionamento","category":"packaging","estimated_hours":20,"order":7}
        ]'::jsonb,
        '[
            {"name":"Design Approvato","days_from_start":14},
            {"name":"Produzione Avviata","days_from_start":30},
            {"name":"Gadget Pronti","days_from_start":60}
        ]'::jsonb
    )
ON CONFLICT (tenant_id, template_key) DO NOTHING;

COMMENT ON TABLE pm.entities IS 'Flexible entity system: can be client, initiative, campaign, etc';
COMMENT ON TABLE pm.entity_relations IS 'Many-to-many relations between entities (flexible hierarchy)';
COMMENT ON TABLE pm.project_templates IS 'Reusable project templates with predefined tasks';
COMMENT ON TABLE pm.projects IS 'Core projects table with template support';
COMMENT ON TABLE pm.tasks IS 'Tasks with AI assignment integration (Patent #3 & #4)';
COMMENT ON TABLE pm.task_completions IS 'Historical task data for AI skill detection (Patent #3)';
COMMENT ON TABLE pm.workflow_rules IS 'Automation rules for workflow (n8n/Zapier integration)';
COMMENT ON VIEW pm.v_project_files IS 'Unified view of files from DAM + Accounting + MRP + PIM';
