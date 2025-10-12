-- ============================================================================
-- Widget Registry System Migration
-- ============================================================================
-- Description: Creates tables for widget registry system with system/tenant/user
--              widgets, configuration hierarchy, and permissions
-- Version: 2.0
-- Author: AI Agent
-- Date: 2025-10-10
-- ============================================================================

-- Create widgets schema if not exists
CREATE SCHEMA IF NOT EXISTS widgets;

-- ============================================================================
-- 1. WIDGET DEFINITIONS (System/Tenant/User widgets)
-- ============================================================================
CREATE TABLE IF NOT EXISTS widgets.widget_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identification
  code VARCHAR(100) UNIQUE NOT NULL,  -- 'connected-users', 'sales-dashboard'
  name VARCHAR(200) NOT NULL,
  description TEXT,

  -- Ownership & Permissions
  tenant_id VARCHAR(100),  -- NULL = system widget (tenant_id='1' for admin)
  created_by VARCHAR(100),  -- User ID who created it

  -- Type & Implementation
  type VARCHAR(50) NOT NULL DEFAULT 'react-component',
  -- Types: 'react-component', 'chart', 'table', 'form', 'custom'

  component_path VARCHAR(500),
  -- Path to React component: '/shared/widgets/ConnectedUsersWidget.tsx'

  -- Configuration
  default_config JSONB NOT NULL DEFAULT '{}',
  -- Level 1 (System) default configuration

  schema_definition JSONB,
  -- JSON Schema for config validation

  -- Data Binding (if applicable)
  data_source_type VARCHAR(50),
  -- 'database', 'api', 'workflow', 'static', 'none'

  query TEXT,
  -- SQL query or API endpoint

  query_params JSONB,
  -- Parameters for query

  -- Permissions & Visibility
  visibility VARCHAR(50) DEFAULT 'tenant',
  -- 'system' (all tenants), 'tenant' (single tenant), 'user' (private), 'public'

  allowed_roles TEXT[] DEFAULT ARRAY['TENANT_ADMIN', 'TENANT_USER'],
  -- Roles that can use this widget

  editable_by TEXT[] DEFAULT ARRAY['PLATFORM_ADMIN'],
  -- Roles that can edit widget definition

  -- Categorization
  category VARCHAR(100) DEFAULT 'Custom',
  -- 'Analytics', 'Content', 'Forms', 'Charts', 'Custom', 'System'

  tags TEXT[],
  icon VARCHAR(100),  -- Emoji or icon name
  preview_image VARCHAR(500),  -- Screenshot URL

  -- Status & Versioning
  status VARCHAR(50) DEFAULT 'active',
  -- 'active', 'draft', 'deprecated', 'archived'

  version VARCHAR(20) DEFAULT '1.0.0',

  -- Metadata
  metadata JSONB DEFAULT '{}',
  -- Additional metadata (dependencies, requirements, etc.)

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Indexes
  CONSTRAINT valid_visibility CHECK (visibility IN ('system', 'tenant', 'user', 'public')),
  CONSTRAINT valid_status CHECK (status IN ('active', 'draft', 'deprecated', 'archived'))
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_widgets_tenant_id ON widgets.widget_definitions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_widgets_status ON widgets.widget_definitions(status);
CREATE INDEX IF NOT EXISTS idx_widgets_category ON widgets.widget_definitions(category);
CREATE INDEX IF NOT EXISTS idx_widgets_visibility ON widgets.widget_definitions(visibility);
CREATE INDEX IF NOT EXISTS idx_widgets_created_by ON widgets.widget_definitions(created_by);

-- ============================================================================
-- 2. TENANT WIDGET CONFIGS (Level 2 overrides)
-- ============================================================================
CREATE TABLE IF NOT EXISTS widgets.tenant_widget_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  widget_id UUID REFERENCES widgets.widget_definitions(id) ON DELETE CASCADE,
  tenant_id VARCHAR(100) NOT NULL,

  -- Configuration overrides (Level 2)
  config_overrides JSONB NOT NULL DEFAULT '{}',
  -- Tenant-specific config (brand colors, custom titles, etc.)

  -- Status
  enabled BOOLEAN DEFAULT true,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(widget_id, tenant_id)
);

CREATE INDEX IF NOT EXISTS idx_tenant_configs_widget ON widgets.tenant_widget_configs(widget_id);
CREATE INDEX IF NOT EXISTS idx_tenant_configs_tenant ON widgets.tenant_widget_configs(tenant_id);

-- ============================================================================
-- 3. USER WIDGET PREFERENCES (Level 3 overrides)
-- ============================================================================
CREATE TABLE IF NOT EXISTS widgets.user_widget_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  widget_id UUID REFERENCES widgets.widget_definitions(id) ON DELETE CASCADE,
  user_id VARCHAR(100) NOT NULL,

  -- Preference overrides (Level 3)
  preference_overrides JSONB NOT NULL DEFAULT '{}',
  -- User-specific preferences (sort order, view mode, etc.)

  -- Favorites
  is_favorite BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(widget_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_prefs_widget ON widgets.user_widget_preferences(widget_id);
CREATE INDEX IF NOT EXISTS idx_user_prefs_user ON widgets.user_widget_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_prefs_favorites ON widgets.user_widget_preferences(is_favorite) WHERE is_favorite = true;

-- ============================================================================
-- 4. WIDGET INSTANCES (Widget placements in pages)
-- ============================================================================
CREATE TABLE IF NOT EXISTS widgets.widget_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  widget_id UUID REFERENCES widgets.widget_definitions(id) ON DELETE CASCADE,
  page_id UUID REFERENCES pb_pages(id) ON DELETE CASCADE,

  -- Position in page
  container_id VARCHAR(100),  -- GrapesJS container ID
  position INT DEFAULT 0,

  -- Instance-specific config (Level 4 - highest priority)
  instance_config JSONB DEFAULT '{}',

  -- Grid layout (if applicable)
  grid_x INT,
  grid_y INT,
  grid_width INT,
  grid_height INT,

  -- Status
  visible BOOLEAN DEFAULT true,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_widget_instances_widget ON widgets.widget_instances(widget_id);
CREATE INDEX IF NOT EXISTS idx_widget_instances_page ON widgets.widget_instances(page_id);
CREATE INDEX IF NOT EXISTS idx_widget_instances_position ON widgets.widget_instances(page_id, position);

-- ============================================================================
-- 5. UPDATE TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION widgets.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_widget_definitions_timestamp
  BEFORE UPDATE ON widgets.widget_definitions
  FOR EACH ROW
  EXECUTE FUNCTION widgets.update_timestamp();

CREATE TRIGGER update_tenant_configs_timestamp
  BEFORE UPDATE ON widgets.tenant_widget_configs
  FOR EACH ROW
  EXECUTE FUNCTION widgets.update_timestamp();

CREATE TRIGGER update_user_prefs_timestamp
  BEFORE UPDATE ON widgets.user_widget_preferences
  FOR EACH ROW
  EXECUTE FUNCTION widgets.update_timestamp();

CREATE TRIGGER update_widget_instances_timestamp
  BEFORE UPDATE ON widgets.widget_instances
  FOR EACH ROW
  EXECUTE FUNCTION widgets.update_timestamp();

-- ============================================================================
-- 6. SEED DATA (System Widgets)
-- ============================================================================

-- Connected Users Widget (System Widget)
INSERT INTO widgets.widget_definitions (
  code,
  name,
  description,
  tenant_id,
  type,
  component_path,
  default_config,
  data_source_type,
  visibility,
  allowed_roles,
  editable_by,
  category,
  icon,
  status,
  version
) VALUES (
  'connected-users',
  'Connected Users',
  'Shows list of currently connected users with real-time status updates',
  '1',  -- System widget (admin tenant)
  'react-component',
  '@ewh/shared-widgets/ConnectedUsersWidget',
  '{
    "showAvatar": true,
    "maxUsers": 10,
    "refreshInterval": 30000,
    "showStatus": true,
    "sortBy": "lastActive"
  }'::jsonb,
  'api',
  'system',
  ARRAY['TENANT_ADMIN', 'TENANT_USER'],
  ARRAY['PLATFORM_ADMIN'],
  'Analytics',
  '👥',
  'active',
  '1.0.0'
) ON CONFLICT (code) DO NOTHING;

-- Stats Card Widget (System Widget)
INSERT INTO widgets.widget_definitions (
  code,
  name,
  description,
  tenant_id,
  type,
  component_path,
  default_config,
  data_source_type,
  visibility,
  allowed_roles,
  category,
  icon,
  status
) VALUES (
  'stats-card',
  'Stats Card',
  'Display a single statistic with label, value, and trend indicator',
  '1',
  'react-component',
  '@ewh/shared-widgets/StatsCard',
  '{
    "label": "Total Users",
    "value": 0,
    "format": "number",
    "showTrend": true,
    "trendDirection": "up",
    "trendValue": 0
  }'::jsonb,
  'api',
  'system',
  ARRAY['TENANT_ADMIN', 'TENANT_USER'],
  'Analytics',
  '📊',
  'active'
) ON CONFLICT (code) DO NOTHING;

-- Chart Widget (System Widget)
INSERT INTO widgets.widget_definitions (
  code,
  name,
  description,
  tenant_id,
  type,
  default_config,
  data_source_type,
  visibility,
  category,
  icon,
  status
) VALUES (
  'chart',
  'Chart',
  'Customizable chart widget (line, bar, pie, area)',
  '1',
  'chart',
  '{
    "chartType": "line",
    "title": "Chart Title",
    "xAxis": "date",
    "yAxis": "value",
    "showLegend": true,
    "showGrid": true
  }'::jsonb,
  'database',
  'system',
  'Analytics',
  '📈',
  'active'
) ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- 7. HELPER FUNCTIONS
-- ============================================================================

-- Function to get merged widget config (4-level hierarchy)
CREATE OR REPLACE FUNCTION widgets.get_merged_config(
  p_widget_id UUID,
  p_tenant_id VARCHAR(100),
  p_user_id VARCHAR(100),
  p_instance_config JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_config JSONB;
  v_tenant_config JSONB;
  v_user_config JSONB;
BEGIN
  -- Level 1: System default config
  SELECT default_config INTO v_config
  FROM widgets.widget_definitions
  WHERE id = p_widget_id;

  -- Level 2: Tenant overrides
  SELECT config_overrides INTO v_tenant_config
  FROM widgets.tenant_widget_configs
  WHERE widget_id = p_widget_id AND tenant_id = p_tenant_id;

  IF v_tenant_config IS NOT NULL THEN
    v_config := v_config || v_tenant_config;
  END IF;

  -- Level 3: User preferences
  SELECT preference_overrides INTO v_user_config
  FROM widgets.user_widget_preferences
  WHERE widget_id = p_widget_id AND user_id = p_user_id;

  IF v_user_config IS NOT NULL THEN
    v_config := v_config || v_user_config;
  END IF;

  -- Level 4: Instance config (highest priority)
  IF p_instance_config IS NOT NULL THEN
    v_config := v_config || p_instance_config;
  END IF;

  RETURN v_config;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user can use widget
CREATE OR REPLACE FUNCTION widgets.can_user_use_widget(
  p_widget_id UUID,
  p_tenant_id VARCHAR(100),
  p_user_role VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
  v_widget RECORD;
BEGIN
  SELECT * INTO v_widget
  FROM widgets.widget_definitions
  WHERE id = p_widget_id AND status = 'active';

  IF v_widget IS NULL THEN
    RETURN false;
  END IF;

  -- Check visibility
  IF v_widget.visibility = 'system' THEN
    RETURN true;
  ELSIF v_widget.visibility = 'tenant' AND v_widget.tenant_id = p_tenant_id THEN
    RETURN true;
  ELSIF v_widget.visibility = 'public' THEN
    RETURN true;
  END IF;

  -- Check role permissions
  IF p_user_role = ANY(v_widget.allowed_roles) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

COMMENT ON SCHEMA widgets IS 'Widget Registry System - manages system, tenant, and custom widgets';
COMMENT ON TABLE widgets.widget_definitions IS 'Widget definitions with code, config, and permissions';
COMMENT ON TABLE widgets.tenant_widget_configs IS 'Tenant-level widget configuration overrides';
COMMENT ON TABLE widgets.user_widget_preferences IS 'User-level widget preferences';
COMMENT ON TABLE widgets.widget_instances IS 'Widget instances placed in pages';
COMMENT ON FUNCTION widgets.get_merged_config IS 'Merges 4-level widget configuration hierarchy';
COMMENT ON FUNCTION widgets.can_user_use_widget IS 'Checks if user has permission to use widget';
