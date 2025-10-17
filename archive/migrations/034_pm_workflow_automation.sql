-- Migration: Add Workflow Automation System
-- This enables automated task flows based on rules

CREATE TABLE IF NOT EXISTS pm.workflow_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  rule_name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Trigger conditions
  trigger_type VARCHAR(50) NOT NULL, -- 'task_status_change', 'task_completed', 'all_subtasks_done', 'deadline_approaching', 'manual'
  trigger_entity VARCHAR(50) NOT NULL, -- 'task', 'project'
  trigger_conditions JSONB, -- e.g., {"status": "done", "parent_task_id": {"$exists": true}}

  -- Actions to execute
  actions JSONB NOT NULL, -- Array of actions: [{"type": "update_task_status", "params": {"status": "done"}}, {"type": "notify_user", ...}]

  -- Scope
  project_id UUID, -- NULL = applies to all projects
  template_id UUID, -- NULL = applies to all templates

  -- Control
  enabled BOOLEAN DEFAULT TRUE,
  priority INTEGER DEFAULT 0, -- Higher priority rules run first

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID,

  CONSTRAINT fk_workflow_tenant FOREIGN KEY (tenant_id) REFERENCES pm.tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_workflow_rules_tenant ON pm.workflow_rules(tenant_id);
CREATE INDEX idx_workflow_rules_enabled ON pm.workflow_rules(enabled) WHERE enabled = TRUE;
CREATE INDEX idx_workflow_rules_project ON pm.workflow_rules(project_id);

-- Workflow execution log for debugging and auditing
CREATE TABLE IF NOT EXISTS pm.workflow_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  rule_id UUID NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID NOT NULL,

  trigger_data JSONB, -- Snapshot of data that triggered the rule
  actions_executed JSONB, -- Actions that were executed

  status VARCHAR(20) DEFAULT 'success', -- 'success', 'failed', 'partial'
  error_message TEXT,

  executed_at TIMESTAMPTZ DEFAULT NOW(),
  execution_time_ms INTEGER,

  CONSTRAINT fk_workflow_exec_tenant FOREIGN KEY (tenant_id) REFERENCES pm.tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_workflow_exec_rule FOREIGN KEY (rule_id) REFERENCES pm.workflow_rules(id) ON DELETE CASCADE
);

CREATE INDEX idx_workflow_exec_tenant ON pm.workflow_executions(tenant_id);
CREATE INDEX idx_workflow_exec_rule ON pm.workflow_executions(rule_id);
CREATE INDEX idx_workflow_exec_entity ON pm.workflow_executions(entity_type, entity_id);

-- Sample workflow rules for common scenarios
INSERT INTO pm.workflow_rules (tenant_id, rule_name, description, trigger_type, trigger_entity, trigger_conditions, actions, enabled, priority)
VALUES
-- Rule 1: Auto-complete parent task when all subtasks are done
('00000000-0000-0000-0000-000000000001',
 'Auto-complete parent task',
 'Automatically mark parent task as done when all subtasks are completed',
 'task_status_change',
 'task',
 '{"status": "done"}',
 '[
   {
     "type": "check_all_subtasks_done",
     "params": {}
   },
   {
     "type": "update_parent_task_status",
     "params": {"status": "done"}
   }
 ]',
 true,
 10),

-- Rule 2: Notify when task is overdue
('00000000-0000-0000-0000-000000000001',
 'Notify on overdue tasks',
 'Send notification when task deadline passes and task is not completed',
 'deadline_approaching',
 'task',
 '{"status": {"$ne": "done"}, "deadline_passed": true}',
 '[
   {
     "type": "create_notification",
     "params": {
       "title": "Task Overdue",
       "message": "Task {{task_name}} is overdue",
       "type": "warning"
     }
   }
 ]',
 true,
 5),

-- Rule 3: Auto-start dependent tasks
('00000000-0000-0000-0000-000000000001',
 'Auto-start dependent tasks',
 'Automatically change dependent tasks from todo to in_progress when their dependency is completed',
 'task_status_change',
 'task',
 '{"status": "done"}',
 '[
   {
     "type": "update_dependent_tasks",
     "params": {"status": "in_progress"}
   }
 ]',
 true,
 8),

-- Rule 4: Update project progress when task completes
('00000000-0000-0000-0000-000000000001',
 'Update project progress',
 'Recalculate project completion percentage when task status changes',
 'task_status_change',
 'task',
 '{}',
 '[
   {
     "type": "recalculate_project_progress",
     "params": {}
   }
 ]',
 true,
 1);

COMMENT ON TABLE pm.workflow_rules IS 'Automated workflow rules for tasks and projects';
COMMENT ON TABLE pm.workflow_executions IS 'Log of workflow rule executions for audit and debugging';
