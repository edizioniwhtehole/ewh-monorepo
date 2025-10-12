-- Workflow System Migration
-- N8N-style workflow automation system

CREATE SCHEMA IF NOT EXISTS workflows;

-- Workflow definitions
CREATE TABLE workflows.workflow_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Workflow structure
  nodes JSONB DEFAULT '[]',
  connections JSONB DEFAULT '[]',

  -- Trigger configuration
  trigger_type VARCHAR(50), -- 'manual' | 'schedule' | 'webhook' | 'event'
  trigger_config JSONB DEFAULT '{}',

  -- Settings
  settings JSONB DEFAULT '{}',

  -- Metadata
  active BOOLEAN DEFAULT FALSE,
  execution_count INTEGER DEFAULT 0,
  last_execution TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  tenant_id UUID REFERENCES auth.tenants(id)
);

CREATE INDEX idx_workflows_active ON workflows.workflow_definitions(active);
CREATE INDEX idx_workflows_tenant ON workflows.workflow_definitions(tenant_id);

-- Workflow executions
CREATE TABLE workflows.workflow_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID REFERENCES workflows.workflow_definitions(id) ON DELETE CASCADE,

  status VARCHAR(50) NOT NULL, -- 'running' | 'success' | 'error' | 'cancelled'

  -- Execution data
  input_data JSONB,
  output_data JSONB,
  error_message TEXT,

  -- Timing
  started_at TIMESTAMPTZ DEFAULT NOW(),
  finished_at TIMESTAMPTZ,
  duration_ms INTEGER,

  -- Node execution details
  node_executions JSONB DEFAULT '[]',

  triggered_by VARCHAR(50) -- 'manual' | 'schedule' | 'webhook' | 'event'
);

CREATE INDEX idx_executions_workflow ON workflows.workflow_executions(workflow_id);
CREATE INDEX idx_executions_status ON workflows.workflow_executions(status);
CREATE INDEX idx_executions_started ON workflows.workflow_executions(started_at DESC);

-- Node types catalog
CREATE TABLE workflows.node_types (
  type VARCHAR(100) PRIMARY KEY,
  category VARCHAR(50) NOT NULL, -- 'trigger' | 'action' | 'transform' | 'control' | 'integration'
  label VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  color VARCHAR(20),
  inputs INTEGER DEFAULT 1,
  outputs INTEGER DEFAULT 1,
  config_schema JSONB DEFAULT '{}',
  code TEXT, -- Optional custom code for the node
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default node types
INSERT INTO workflows.node_types (type, category, label, description, icon, color) VALUES
('trigger.manual', 'trigger', 'Manual Trigger', 'Start workflow manually', 'play', '#10b981'),
('trigger.webhook', 'trigger', 'Webhook', 'Trigger on HTTP request', 'webhook', '#10b981'),
('trigger.schedule', 'trigger', 'Schedule', 'Run on schedule', 'clock', '#10b981'),
('action.http', 'action', 'HTTP Request', 'Make HTTP request', 'globe', '#3b82f6'),
('action.database', 'action', 'Database Query', 'Execute database query', 'database', '#3b82f6'),
('action.email', 'action', 'Send Email', 'Send email notification', 'mail', '#3b82f6'),
('transform.json', 'transform', 'JSON Transform', 'Transform JSON data', 'braces', '#f59e0b'),
('transform.filter', 'transform', 'Filter', 'Filter items', 'filter', '#f59e0b'),
('control.if', 'control', 'IF Condition', 'Conditional branching', 'git-branch', '#8b5cf6'),
('control.loop', 'control', 'Loop', 'Iterate over items', 'repeat', '#8b5cf6');

COMMENT ON TABLE workflows.workflow_definitions IS 'N8N-style workflow definitions';
COMMENT ON TABLE workflows.workflow_executions IS 'Workflow execution history';
COMMENT ON TABLE workflows.node_types IS 'Available node types catalog';
