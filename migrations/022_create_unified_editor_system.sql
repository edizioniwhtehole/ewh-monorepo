-- =====================================================
-- UNIFIED EDITOR SYSTEM
-- Sistema unificato di editing con scripting per nodi
-- =====================================================

-- =====================================================
-- 1. NODE FUNCTIONS & SCRIPTS
-- Script personalizzati eseguibili sui nodi workflow
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.node_functions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Function identity
  function_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Category
  category VARCHAR(100) NOT NULL,              -- transform|validation|enrichment|integration|custom
  tags TEXT[] DEFAULT '{}',

  -- Script content
  language VARCHAR(50) NOT NULL DEFAULT 'javascript',  -- javascript|typescript|python|lua
  source_code TEXT NOT NULL,

  -- Function signature
  input_schema JSONB,                          -- JSON Schema for input validation
  output_schema JSONB,                         -- JSON Schema for output validation

  -- Execution environment
  runtime VARCHAR(50) DEFAULT 'isolated',      -- isolated|shared|trusted
  timeout_ms INTEGER DEFAULT 5000,
  max_memory_mb INTEGER DEFAULT 128,

  -- Permissions
  allowed_modules TEXT[] DEFAULT '{}',         -- npm/pip modules allowed
  allowed_apis TEXT[] DEFAULT '{}',            -- API endpoints allowed to call
  requires_approval BOOLEAN DEFAULT true,

  -- Versioning
  version VARCHAR(50) NOT NULL DEFAULT '1.0.0',
  is_published BOOLEAN DEFAULT false,
  is_deprecated BOOLEAN DEFAULT false,

  -- Usage tracking
  usage_count INTEGER DEFAULT 0,
  last_used_at TIMESTAMPTZ,

  -- Metadata
  author_id UUID,
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE SET NULL,
  is_system_function BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (category IN ('transform', 'validation', 'enrichment', 'integration', 'custom', 'trigger', 'action')),
  CHECK (language IN ('javascript', 'typescript', 'python', 'lua', 'json')),
  CHECK (runtime IN ('isolated', 'shared', 'trusted'))
);

CREATE INDEX idx_node_functions_category ON workflow.node_functions(category);
CREATE INDEX idx_node_functions_language ON workflow.node_functions(language);
CREATE INDEX idx_node_functions_published ON workflow.node_functions(is_published) WHERE is_published = true;
CREATE INDEX idx_node_functions_plugin ON workflow.node_functions(plugin_id);

-- =====================================================
-- 2. NODE FUNCTION INSTANCES
-- Istanze di funzioni applicate a nodi specifici
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.node_function_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Association
  workflow_id UUID,                            -- Reference to workflow
  node_id VARCHAR(255) NOT NULL,               -- Node identifier in workflow
  function_id VARCHAR(255) REFERENCES workflow.node_functions(function_id) ON DELETE CASCADE,

  -- Execution config
  config JSONB DEFAULT '{}',                   -- Function-specific config
  execution_order INTEGER DEFAULT 0,           -- Order when multiple functions on same node
  enabled BOOLEAN DEFAULT true,

  -- Conditional execution
  condition_expression TEXT,                   -- JavaScript expression: "data.status === 'active'"

  -- Error handling
  on_error VARCHAR(50) DEFAULT 'throw',        -- throw|skip|fallback|retry
  retry_attempts INTEGER DEFAULT 0,
  retry_delay_ms INTEGER DEFAULT 1000,
  fallback_value JSONB,

  -- Performance
  avg_execution_time_ms INTEGER,
  max_execution_time_ms INTEGER,
  execution_count INTEGER DEFAULT 0,
  error_count INTEGER DEFAULT 0,
  last_error TEXT,
  last_error_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (on_error IN ('throw', 'skip', 'fallback', 'retry'))
);

CREATE INDEX idx_function_instances_workflow ON workflow.node_function_instances(workflow_id);
CREATE INDEX idx_function_instances_node ON workflow.node_function_instances(node_id);
CREATE INDEX idx_function_instances_function ON workflow.node_function_instances(function_id);

-- =====================================================
-- 3. FUNCTION LIBRARY (Pre-built Functions)
-- =====================================================

-- Insert common pre-built functions
INSERT INTO workflow.node_functions (
  function_id, name, description, category, language, source_code,
  input_schema, output_schema, is_system_function, is_published
) VALUES

-- Transform: Extract Field
(
  'transform-extract-field',
  'Extract Field',
  'Extract a specific field from input data',
  'transform',
  'javascript',
  'function execute(input, config) {
    const path = config.fieldPath || "";
    const keys = path.split(".");
    let result = input;
    for (const key of keys) {
      result = result?.[key];
    }
    return result;
  }',
  '{"type": "object"}',
  '{"type": "any"}',
  true,
  true
),

-- Transform: Map Array
(
  'transform-map-array',
  'Map Array',
  'Transform each item in an array',
  'transform',
  'javascript',
  'function execute(input, config) {
    if (!Array.isArray(input)) return input;
    const mapExpression = config.mapExpression || "item => item";
    const mapFn = new Function("item", "index", `return (${mapExpression})(item, index)`);
    return input.map(mapFn);
  }',
  '{"type": "array"}',
  '{"type": "array"}',
  true,
  true
),

-- Transform: Filter
(
  'transform-filter',
  'Filter Data',
  'Filter data based on condition',
  'transform',
  'javascript',
  'function execute(input, config) {
    if (Array.isArray(input)) {
      const condition = config.condition || "item => true";
      const filterFn = new Function("item", "index", `return (${condition})(item, index)`);
      return input.filter(filterFn);
    }
    return input;
  }',
  '{"type": "array"}',
  '{"type": "array"}',
  true,
  true
),

-- Validation: Schema Validator
(
  'validation-json-schema',
  'JSON Schema Validator',
  'Validate data against JSON Schema',
  'validation',
  'javascript',
  'function execute(input, config) {
    const schema = config.schema || {};
    // Simplified validation (in real impl, use ajv or similar)
    if (schema.type && typeof input !== schema.type) {
      throw new Error(`Expected type ${schema.type}, got ${typeof input}`);
    }
    if (schema.required && Array.isArray(schema.required)) {
      for (const field of schema.required) {
        if (!(field in input)) {
          throw new Error(`Missing required field: ${field}`);
        }
      }
    }
    return input;
  }',
  '{"type": "object"}',
  '{"type": "object"}',
  true,
  true
),

-- Enrichment: Add Metadata
(
  'enrichment-add-metadata',
  'Add Metadata',
  'Add timestamp and tracking metadata',
  'enrichment',
  'javascript',
  'function execute(input, config) {
    return {
      ...input,
      _metadata: {
        processedAt: new Date().toISOString(),
        processedBy: config.processedBy || "system",
        version: config.version || "1.0.0"
      }
    };
  }',
  '{"type": "object"}',
  '{"type": "object"}',
  true,
  true
),

-- Integration: HTTP Request
(
  'integration-http-request',
  'HTTP Request',
  'Make HTTP request to external API',
  'integration',
  'javascript',
  'async function execute(input, config) {
    const url = config.url || "";
    const method = config.method || "GET";
    const headers = config.headers || {};
    const body = config.includeBody ? JSON.stringify(input) : undefined;

    const response = await fetch(url, { method, headers, body });
    return await response.json();
  }',
  '{"type": "object"}',
  '{"type": "object"}',
  true,
  true
);

-- =====================================================
-- 4. EDITABLE ENTITIES REGISTRY
-- Registry di tutti i moduli/entità editabili
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.editable_entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Entity identity
  entity_type VARCHAR(100) NOT NULL,           -- workflow|route|function|widget|plugin|page
  entity_id VARCHAR(255) NOT NULL,
  entity_name VARCHAR(255) NOT NULL,

  -- Content
  content_type VARCHAR(50) NOT NULL,           -- json|javascript|typescript|sql|markdown|html
  content TEXT NOT NULL,

  -- Schema for validation
  validation_schema JSONB,

  -- Editor configuration
  editor_mode VARCHAR(50) DEFAULT 'code',      -- code|visual|hybrid
  syntax_highlighting VARCHAR(50),             -- javascript|sql|json|markdown

  -- Permissions
  read_only BOOLEAN DEFAULT false,
  requires_approval BOOLEAN DEFAULT false,
  allowed_roles TEXT[] DEFAULT '{"admin"}',

  -- Version control
  version INTEGER DEFAULT 1,
  parent_version INTEGER,

  -- Metadata
  created_by UUID,
  updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(entity_type, entity_id),
  CHECK (entity_type IN ('workflow', 'route', 'function', 'widget', 'plugin', 'page', 'template', 'middleware')),
  CHECK (content_type IN ('json', 'javascript', 'typescript', 'sql', 'markdown', 'html', 'css', 'yaml')),
  CHECK (editor_mode IN ('code', 'visual', 'hybrid'))
);

CREATE INDEX idx_editable_entities_type ON workflow.editable_entities(entity_type);
CREATE INDEX idx_editable_entities_content_type ON workflow.editable_entities(content_type);
CREATE INDEX idx_editable_entities_updated ON workflow.editable_entities(updated_at DESC);

-- =====================================================
-- 5. EDITOR SESSIONS
-- Track active editing sessions for collaboration
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.editor_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Session info
  entity_type VARCHAR(100) NOT NULL,
  entity_id VARCHAR(255) NOT NULL,

  -- User
  user_id UUID NOT NULL,
  user_name VARCHAR(255),

  -- Session state
  is_active BOOLEAN DEFAULT true,
  cursor_position INTEGER,
  selection_range JSONB,                       -- {start, end}

  -- Collaboration
  locked BOOLEAN DEFAULT false,                -- Exclusive edit lock
  last_heartbeat TIMESTAMPTZ DEFAULT NOW(),

  -- Metadata
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,

  FOREIGN KEY (entity_type, entity_id) REFERENCES workflow.editable_entities(entity_type, entity_id) ON DELETE CASCADE
);

CREATE INDEX idx_editor_sessions_entity ON workflow.editor_sessions(entity_type, entity_id);
CREATE INDEX idx_editor_sessions_active ON workflow.editor_sessions(is_active) WHERE is_active = true;
CREATE INDEX idx_editor_sessions_user ON workflow.editor_sessions(user_id);

-- =====================================================
-- 6. EDITOR HISTORY (Version Control)
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.editor_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Entity reference
  entity_type VARCHAR(100) NOT NULL,
  entity_id VARCHAR(255) NOT NULL,

  -- Version
  version INTEGER NOT NULL,
  content TEXT NOT NULL,

  -- Change tracking
  change_summary TEXT,
  changed_by UUID,
  change_type VARCHAR(50) DEFAULT 'edit',      -- edit|create|delete|restore

  -- Diff
  diff JSONB,                                  -- Store diff for efficient rollback

  created_at TIMESTAMPTZ DEFAULT NOW(),

  FOREIGN KEY (entity_type, entity_id) REFERENCES workflow.editable_entities(entity_type, entity_id) ON DELETE CASCADE,
  CHECK (change_type IN ('edit', 'create', 'delete', 'restore'))
);

CREATE INDEX idx_editor_history_entity ON workflow.editor_history(entity_type, entity_id);
CREATE INDEX idx_editor_history_version ON workflow.editor_history(version DESC);
CREATE INDEX idx_editor_history_created ON workflow.editor_history(created_at DESC);

-- =====================================================
-- 7. EDITOR PREFERENCES
-- User-specific editor preferences
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.editor_preferences (
  user_id UUID PRIMARY KEY,

  -- Editor settings
  theme VARCHAR(50) DEFAULT 'dark',            -- dark|light|auto
  font_size INTEGER DEFAULT 14,
  font_family VARCHAR(100) DEFAULT 'monospace',
  line_numbers BOOLEAN DEFAULT true,
  word_wrap BOOLEAN DEFAULT false,
  minimap BOOLEAN DEFAULT true,

  -- Behavior
  auto_save BOOLEAN DEFAULT true,
  auto_save_delay_ms INTEGER DEFAULT 2000,
  vim_mode BOOLEAN DEFAULT false,

  -- Layout
  sidebar_visible BOOLEAN DEFAULT true,
  panel_visible BOOLEAN DEFAULT true,

  -- Advanced
  custom_keybindings JSONB DEFAULT '{}',
  custom_snippets JSONB DEFAULT '{}',

  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 8. FUNCTIONS & TRIGGERS
-- =====================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION workflow.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER editable_entities_updated_at
  BEFORE UPDATE ON workflow.editable_entities
  FOR EACH ROW
  EXECUTE FUNCTION workflow.update_updated_at();

CREATE TRIGGER node_functions_updated_at
  BEFORE UPDATE ON workflow.node_functions
  FOR EACH ROW
  EXECUTE FUNCTION workflow.update_updated_at();

-- Auto-save history on update
CREATE OR REPLACE FUNCTION workflow.save_editor_history()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.content IS DISTINCT FROM NEW.content THEN
    INSERT INTO workflow.editor_history (
      entity_type, entity_id, version, content,
      changed_by, change_type
    ) VALUES (
      OLD.entity_type, OLD.entity_id, OLD.version, OLD.content,
      NEW.updated_by, 'edit'
    );

    NEW.version = OLD.version + 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER editable_entities_history
  BEFORE UPDATE ON workflow.editable_entities
  FOR EACH ROW
  EXECUTE FUNCTION workflow.save_editor_history();

-- =====================================================
-- 9. VIEWS
-- =====================================================

-- Active editor sessions
CREATE OR REPLACE VIEW workflow.active_editor_sessions AS
SELECT
  es.*,
  ee.entity_name,
  ee.content_type,
  (NOW() - es.last_heartbeat) < INTERVAL '5 minutes' as is_online
FROM workflow.editor_sessions es
JOIN workflow.editable_entities ee
  ON es.entity_type = ee.entity_type
  AND es.entity_id = ee.entity_id
WHERE es.is_active = true;

-- Popular functions
CREATE OR REPLACE VIEW workflow.popular_node_functions AS
SELECT
  nf.*,
  COUNT(nfi.id) as instance_count,
  MAX(nfi.updated_at) as last_used
FROM workflow.node_functions nf
LEFT JOIN workflow.node_function_instances nfi ON nf.function_id = nfi.function_id
WHERE nf.is_published = true
GROUP BY nf.id
ORDER BY instance_count DESC, nf.usage_count DESC;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE workflow.node_functions IS 'Script functions that can be attached to workflow nodes';
COMMENT ON TABLE workflow.editable_entities IS 'Registry of all editable entities in the system';
COMMENT ON TABLE workflow.editor_sessions IS 'Active editing sessions for real-time collaboration';
COMMENT ON TABLE workflow.editor_history IS 'Version history for all edited entities';
COMMENT ON COLUMN workflow.node_functions.runtime IS 'isolated: sandboxed, shared: normal, trusted: full access';