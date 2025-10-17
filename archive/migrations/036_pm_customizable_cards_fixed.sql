-- Migration: Customizable Todo Cards & Hierarchical Tasks

-- Card templates (layout e campi personalizzabili)
CREATE TABLE IF NOT EXISTS pm.card_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  template_name VARCHAR(100) NOT NULL,
  description TEXT,

  -- Visual customization
  color VARCHAR(7) DEFAULT '#3B82F6',
  icon VARCHAR(50), -- lucide icon name
  layout VARCHAR(20) DEFAULT 'standard', -- 'standard', 'compact', 'detailed'

  -- Custom fields schema
  custom_fields JSONB DEFAULT '[]'::jsonb,
  -- Example: [
  --   {"name": "priority", "type": "select", "options": ["low", "medium", "high"], "required": true},
  --   {"name": "effort", "type": "number", "unit": "story points"},
  --   {"name": "tags", "type": "multi-select", "options": ["frontend", "backend", "design"]}
  -- ]

  -- Automation rules for this card type
  auto_rules JSONB DEFAULT '[]'::jsonb,

  is_system BOOLEAN DEFAULT FALSE,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  
  UNIQUE(tenant_id, template_name)
);

-- Add card template to tasks
ALTER TABLE pm.tasks ADD COLUMN IF NOT EXISTS card_template_id UUID;
ALTER TABLE pm.tasks ADD COLUMN IF NOT EXISTS card_custom_data JSONB DEFAULT '{}'::jsonb;

-- Task hierarchy levels: task -> subtask -> checklist item
ALTER TABLE pm.tasks ADD COLUMN IF NOT EXISTS task_level INTEGER DEFAULT 0; -- 0=task, 1=subtask, 2=checklist
ALTER TABLE pm.tasks ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;

-- Checklist items (level 2 in hierarchy)
CREATE TABLE IF NOT EXISTS pm.checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL, -- Parent task or subtask
  tenant_id UUID NOT NULL,

  item_text TEXT NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  completed_by UUID,

  display_order INTEGER DEFAULT 0,

  -- Optional fields
  assigned_to UUID,
  due_date DATE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fk_checklist_task FOREIGN KEY (task_id) REFERENCES pm.tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_checklist_tenant FOREIGN KEY (tenant_id) REFERENCES pm.tenants(id) ON DELETE CASCADE
);

-- User task views (personalized board layouts)
CREATE TABLE IF NOT EXISTS pm.user_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,
  view_name VARCHAR(100) NOT NULL,

  -- View type: 'board', 'list', 'calendar', 'timeline'
  view_type VARCHAR(20) DEFAULT 'board',

  -- Filters
  filters JSONB DEFAULT '{}'::jsonb,
  -- Example: {"status": ["todo", "in_progress"], "assigned_to": ["user_id"], "priority": ["high"]}

  -- Grouping: 'status', 'assignee', 'priority', 'project', 'due_date', 'custom_field'
  group_by VARCHAR(50) DEFAULT 'status',

  -- Sorting
  sort_by VARCHAR(50) DEFAULT 'created_at',
  sort_order VARCHAR(4) DEFAULT 'DESC',

  -- Column visibility for list view
  visible_columns JSONB DEFAULT '["taskName", "status", "assignedTo", "dueDate"]'::jsonb,

  -- Card display preferences
  card_size VARCHAR(20) DEFAULT 'medium', -- 'small', 'medium', 'large'
  show_subtasks BOOLEAN DEFAULT TRUE,
  show_checklist BOOLEAN DEFAULT TRUE,
  show_attachments BOOLEAN DEFAULT TRUE,

  is_default BOOLEAN DEFAULT FALSE,
  is_shared BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  
  UNIQUE(tenant_id, user_id, view_name)
);

-- Task labels/tags
CREATE TABLE IF NOT EXISTS pm.task_labels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  label_name VARCHAR(50) NOT NULL,
  color VARCHAR(7) NOT NULL,
  description TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  
  UNIQUE(tenant_id, label_name)
);

-- Task-Label many-to-many
CREATE TABLE IF NOT EXISTS pm.task_label_assignments (
  task_id UUID NOT NULL,
  label_id UUID NOT NULL,

  assigned_at TIMESTAMPTZ DEFAULT NOW(),

  PRIMARY KEY (task_id, label_id),
  CONSTRAINT fk_task_label_task FOREIGN KEY (task_id) REFERENCES pm.tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_task_label_label FOREIGN KEY (label_id) REFERENCES pm.task_labels(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_tasks_card_template ON pm.tasks(card_template_id);
CREATE INDEX idx_tasks_level ON pm.tasks(task_level);
CREATE INDEX idx_tasks_display_order ON pm.tasks(parent_task_id, display_order);
CREATE INDEX idx_checklist_task ON pm.checklist_items(task_id);
CREATE INDEX idx_user_views_user ON pm.user_views(tenant_id, user_id);
CREATE INDEX idx_task_labels_tenant ON pm.task_labels(tenant_id);

-- Insert default card templates
INSERT INTO pm.card_templates (tenant_id, template_name, description, color, icon, custom_fields, is_system) VALUES
('00000000-0000-0000-0000-000000000001', 'Standard Task', 'Template standard per task generici', '#3B82F6', 'CheckSquare', '[
  {"name": "priority", "type": "select", "label": "Priorità", "options": ["low", "medium", "high", "urgent"], "default": "medium"},
  {"name": "effort", "type": "number", "label": "Sforzo", "unit": "ore", "min": 0},
  {"name": "tags", "type": "tags", "label": "Etichette"}
]'::jsonb, TRUE),

('00000000-0000-0000-0000-000000000001', 'Bug Fix', 'Template per segnalazione e fix di bug', '#EF4444', 'Bug', '[
  {"name": "severity", "type": "select", "label": "Gravità", "options": ["critical", "high", "medium", "low"], "required": true},
  {"name": "reproducible", "type": "boolean", "label": "Riproducibile"},
  {"name": "affected_version", "type": "text", "label": "Versione Affetta"},
  {"name": "browser", "type": "select", "label": "Browser", "options": ["Chrome", "Firefox", "Safari", "Edge"]}
]'::jsonb, TRUE),

('00000000-0000-0000-0000-000000000001', 'Design Task', 'Template per task di design', '#EC4899', 'Palette', '[
  {"name": "design_type", "type": "select", "label": "Tipo Design", "options": ["UI", "UX", "Branding", "Illustration"], "required": true},
  {"name": "mockup_url", "type": "url", "label": "Link Mockup"},
  {"name": "feedback_rounds", "type": "number", "label": "Round di Feedback", "default": 2}
]'::jsonb, TRUE),

('00000000-0000-0000-0000-000000000001', 'Content Writing', 'Template per contenuti editoriali', '#F59E0B', 'FileText', '[
  {"name": "word_count", "type": "number", "label": "Parole Target", "min": 0},
  {"name": "content_type", "type": "select", "label": "Tipo Contenuto", "options": ["Article", "Blog Post", "Documentation", "Marketing Copy"]},
  {"name": "seo_keywords", "type": "tags", "label": "Parole Chiave SEO"},
  {"name": "target_audience", "type": "text", "label": "Pubblico Target"}
]'::jsonb, TRUE),

('00000000-0000-0000-0000-000000000001', 'Review/Approval', 'Template per revisioni e approvazioni', '#8B5CF6', 'CheckCircle', '[
  {"name": "reviewers", "type": "multi-user", "label": "Revisori", "required": true},
  {"name": "approval_status", "type": "select", "label": "Stato", "options": ["pending", "changes_requested", "approved"], "default": "pending"},
  {"name": "deadline_type", "type": "select", "label": "Urgenza", "options": ["standard", "urgent", "critical"]}
]'::jsonb, TRUE);

-- Insert default labels
INSERT INTO pm.task_labels (tenant_id, label_name, color) VALUES
('00000000-0000-0000-0000-000000000001', 'Frontend', '#3B82F6'),
('00000000-0000-0000-0000-000000000001', 'Backend', '#10B981'),
('00000000-0000-0000-0000-000000000001', 'Design', '#EC4899'),
('00000000-0000-0000-0000-000000000001', 'Bug', '#EF4444'),
('00000000-0000-0000-0000-000000000001', 'Enhancement', '#F59E0B'),
('00000000-0000-0000-0000-000000000001', 'Documentation', '#6B7280'),
('00000000-0000-0000-0000-000000000001', 'Urgent', '#DC2626'),
('00000000-0000-0000-0000-000000000001', 'Ready for Review', '#8B5CF6');

-- Function to calculate checklist completion
CREATE OR REPLACE FUNCTION pm.update_checklist_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_total INTEGER;
  v_completed INTEGER;
  v_percentage INTEGER;
BEGIN
  -- Count total and completed checklist items
  SELECT
    COUNT(*),
    SUM(CASE WHEN completed THEN 1 ELSE 0 END)
  INTO v_total, v_completed
  FROM pm.checklist_items
  WHERE task_id = NEW.task_id;

  -- Update task completion percentage based on checklist
  IF v_total > 0 THEN
    v_percentage := (v_completed * 100) / v_total;

    UPDATE pm.tasks
    SET
      completion_percentage = v_percentage,
      status = CASE
        WHEN v_percentage = 100 THEN 'done'
        WHEN v_percentage > 0 THEN 'in_progress'
        ELSE status
      END,
      updated_at = NOW()
    WHERE id = NEW.task_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_checklist_completion
  AFTER INSERT OR UPDATE ON pm.checklist_items
  FOR EACH ROW
  EXECUTE FUNCTION pm.update_checklist_completion();

COMMENT ON TABLE pm.card_templates IS 'Customizable card templates with custom fields';
COMMENT ON TABLE pm.checklist_items IS 'Checklist items for tasks (level 2 hierarchy)';
COMMENT ON TABLE pm.user_views IS 'Personalized board/list views per user';
COMMENT ON TABLE pm.task_labels IS 'Labels/tags for task categorization';
