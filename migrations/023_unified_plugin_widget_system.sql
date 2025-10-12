-- =====================================================
-- UNIFIED PLUGIN-WIDGET SYSTEM
-- Sistema unificato dove widget sono parte di plugin
-- Widget riutilizzabili in admin/tenant/user con configurazione 3-livelli
-- =====================================================

-- =====================================================
-- 1. PLUGIN SYSTEM ENHANCEMENT
-- Estensione del sistema plugin esistente
-- =====================================================

-- Plugin capabilities (cosa può fare un plugin)
CREATE TABLE IF NOT EXISTS plugins.plugin_capabilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,

  capability_type VARCHAR(100) NOT NULL,      -- widget|page|menu|workflow|api
  capability_id VARCHAR(255) NOT NULL,        -- ID specifico (widget_id, page_id, etc)

  -- Metadata
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(plugin_id, capability_type, capability_id),
  CHECK (capability_type IN ('widget', 'page', 'menu', 'workflow', 'api', 'hook', 'command'))
);

CREATE INDEX idx_plugin_capabilities_plugin ON plugins.plugin_capabilities(plugin_id);
CREATE INDEX idx_plugin_capabilities_type ON plugins.plugin_capabilities(capability_type);

COMMENT ON TABLE plugins.plugin_capabilities IS 'Tracks what each plugin provides (widgets, pages, etc)';

-- =====================================================
-- 2. UNIFIED WIDGET SYSTEM (3-Level Configuration)
-- =====================================================

-- Level 1: Widget Definitions (System Level) - Plugin-owned
DROP TABLE IF EXISTS widgets.system_widgets CASCADE;
CREATE TABLE widgets.widget_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  widget_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Plugin ownership
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,
  is_system BOOLEAN DEFAULT false,           -- System widgets (not part of plugin)

  -- Category & Tags
  category VARCHAR(100) NOT NULL,            -- dashboard|monitoring|analytics|user|content
  tags TEXT[] DEFAULT '{}',
  icon VARCHAR(100),
  preview_image TEXT,

  -- Component
  component_path TEXT NOT NULL,              -- Relative to plugin: ./widgets/ConnectedUsers.tsx
  component_type VARCHAR(50) DEFAULT 'react', -- react|vue|custom

  -- Configuration schema (for Level 2 & 3)
  config_schema JSONB DEFAULT '{}',          -- JSON Schema for widget config
  default_config JSONB DEFAULT '{}',

  -- Sizing
  default_width INTEGER DEFAULT 6,           -- Grid units (1-12)
  default_height INTEGER DEFAULT 4,          -- Grid units
  min_width INTEGER DEFAULT 2,
  min_height INTEGER DEFAULT 2,
  max_width INTEGER DEFAULT 12,
  max_height INTEGER DEFAULT 12,
  resizable BOOLEAN DEFAULT true,

  -- Data source
  data_source_type VARCHAR(50),              -- api|realtime|static|computed
  data_endpoint TEXT,                        -- API endpoint for data
  data_poll_interval INTEGER,                -- Milliseconds (for polling)
  supports_realtime BOOLEAN DEFAULT false,

  -- Context support (WHERE can it be used)
  context_support JSONB DEFAULT '{"admin": true, "tenant": true, "user": true}',

  -- Context behavior (HOW it behaves in different contexts)
  context_behavior JSONB DEFAULT '{
    "admin": {"scope": "global", "filters": []},
    "tenant": {"scope": "tenant", "filters": ["tenant_id"]},
    "user": {"scope": "user", "filters": ["user_id"]}
  }',

  -- Permissions required to use
  required_permissions TEXT[] DEFAULT '{}',
  required_roles TEXT[] DEFAULT '{}',

  -- Capabilities
  configurable BOOLEAN DEFAULT true,
  has_settings BOOLEAN DEFAULT true,
  supports_export BOOLEAN DEFAULT false,
  supports_refresh BOOLEAN DEFAULT true,

  -- Version
  version VARCHAR(50) DEFAULT '1.0.0',
  changelog TEXT,

  -- Status
  status VARCHAR(50) DEFAULT 'active',       -- active|deprecated|archived
  deprecated_at TIMESTAMPTZ,
  replacement_widget_id VARCHAR(255),

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (category IN ('dashboard', 'monitoring', 'analytics', 'user', 'content', 'form', 'media', 'custom')),
  CHECK (status IN ('active', 'deprecated', 'archived'))
);

CREATE INDEX idx_widget_definitions_plugin ON widgets.widget_definitions(plugin_id);
CREATE INDEX idx_widget_definitions_category ON widgets.widget_definitions(category);
CREATE INDEX idx_widget_definitions_status ON widgets.widget_definitions(status);

COMMENT ON COLUMN widgets.widget_definitions.context_support IS
  'Defines where widget can be used: admin-frontend, tenant sites, user dashboards';
COMMENT ON COLUMN widgets.widget_definitions.context_behavior IS
  'Defines how widget behaves in each context: data scope, filters, permissions';

-- Level 2: Tenant Customizations (Tenant Level)
CREATE TABLE widgets.tenant_widget_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reference
  widget_definition_id UUID REFERENCES widgets.widget_definitions(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL,

  -- Customization
  custom_name VARCHAR(255),                  -- Override widget name
  custom_description TEXT,
  custom_icon VARCHAR(100),

  -- Configuration override
  config_override JSONB DEFAULT '{}',        -- Overrides default_config
  styling_override JSONB DEFAULT '{}',       -- Custom CSS/theme

  -- Size override
  default_width INTEGER,
  default_height INTEGER,

  -- Behavior
  enabled BOOLEAN DEFAULT true,
  visible_to_roles TEXT[],                   -- Which roles can see this widget

  -- Metadata
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(widget_definition_id, tenant_id)
);

CREATE INDEX idx_tenant_configs_widget ON widgets.tenant_widget_configs(widget_definition_id);
CREATE INDEX idx_tenant_configs_tenant ON widgets.tenant_widget_configs(tenant_id);

COMMENT ON TABLE widgets.tenant_widget_configs IS
  'Tenant-level customization of system widgets (Level 2)';

-- Level 3: User Preferences (User Level)
CREATE TABLE widgets.user_widget_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reference
  widget_definition_id UUID REFERENCES widgets.widget_definitions(id) ON DELETE CASCADE,
  tenant_widget_config_id UUID REFERENCES widgets.tenant_widget_configs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,

  -- User preferences
  custom_name VARCHAR(255),
  is_favorite BOOLEAN DEFAULT false,
  is_pinned BOOLEAN DEFAULT false,

  -- Configuration override (on top of tenant config)
  config_override JSONB DEFAULT '{}',
  styling_override JSONB DEFAULT '{}',

  -- Size preferences
  preferred_width INTEGER,
  preferred_height INTEGER,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(widget_definition_id, user_id)
);

CREATE INDEX idx_user_prefs_widget ON widgets.user_widget_preferences(widget_definition_id);
CREATE INDEX idx_user_prefs_user ON widgets.user_widget_preferences(user_id);

COMMENT ON TABLE widgets.user_widget_preferences IS
  'User-level preferences for widgets (Level 3)';

-- =====================================================
-- 3. WIDGET INSTANCES (Actual Usage)
-- =====================================================

-- Widget placements on pages/dashboards
DROP TABLE IF EXISTS widgets.widget_instances CASCADE;
CREATE TABLE widgets.widget_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Widget reference
  widget_definition_id UUID REFERENCES widgets.widget_definitions(id) ON DELETE CASCADE,

  -- Context
  context VARCHAR(50) NOT NULL,              -- admin|tenant|user
  tenant_id UUID,                            -- NULL for admin context
  user_id UUID,                              -- NULL for admin/tenant context

  -- Location
  page_id UUID REFERENCES cms.pages(id) ON DELETE CASCADE,
  dashboard_id VARCHAR(255),                 -- Alternative to page_id for dashboards

  -- Grid position
  grid_x INTEGER NOT NULL,
  grid_y INTEGER NOT NULL,
  grid_w INTEGER NOT NULL,
  grid_h INTEGER NOT NULL,

  -- Instance-specific config (overrides Level 1, 2, 3)
  instance_config JSONB DEFAULT '{}',
  instance_styling JSONB DEFAULT '{}',

  -- State
  enabled BOOLEAN DEFAULT true,
  visible BOOLEAN DEFAULT true,
  collapsed BOOLEAN DEFAULT false,
  locked BOOLEAN DEFAULT false,              -- Prevent user from moving/resizing

  -- Order (for non-grid layouts)
  display_order INTEGER DEFAULT 0,

  -- Metadata
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (context IN ('admin', 'tenant', 'user')),
  CHECK (grid_x >= 0 AND grid_y >= 0),
  CHECK (grid_w > 0 AND grid_h > 0)
);

CREATE INDEX idx_widget_instances_widget ON widgets.widget_instances(widget_definition_id);
CREATE INDEX idx_widget_instances_context ON widgets.widget_instances(context);
CREATE INDEX idx_widget_instances_tenant ON widgets.widget_instances(tenant_id) WHERE tenant_id IS NOT NULL;
CREATE INDEX idx_widget_instances_user ON widgets.widget_instances(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_widget_instances_page ON widgets.widget_instances(page_id);

COMMENT ON TABLE widgets.widget_instances IS
  'Actual widget placements on pages/dashboards with instance-specific config';

-- =====================================================
-- 4. WIDGET DATA CACHE (Performance)
-- =====================================================

CREATE TABLE widgets.widget_data_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Widget instance reference
  widget_instance_id UUID REFERENCES widgets.widget_instances(id) ON DELETE CASCADE,

  -- Context for scoping
  context VARCHAR(50) NOT NULL,
  tenant_id UUID,
  user_id UUID,

  -- Cached data
  data JSONB NOT NULL,

  -- Cache metadata
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  cache_key VARCHAR(500) NOT NULL,

  -- Stats
  hit_count INTEGER DEFAULT 0,
  last_hit_at TIMESTAMPTZ,

  UNIQUE(cache_key, context, tenant_id, user_id)
);

CREATE INDEX idx_widget_cache_instance ON widgets.widget_data_cache(widget_instance_id);
CREATE INDEX idx_widget_cache_expires ON widgets.widget_data_cache(expires_at);
CREATE INDEX idx_widget_cache_key ON widgets.widget_data_cache(cache_key);

COMMENT ON TABLE widgets.widget_data_cache IS
  'Caches widget data for performance, scoped by context/tenant/user';

-- Auto-cleanup expired cache
CREATE OR REPLACE FUNCTION widgets.cleanup_expired_cache()
RETURNS void AS $$
BEGIN
  DELETE FROM widgets.widget_data_cache
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. CONFIGURATION RESOLUTION FUNCTION
-- =====================================================

-- Function to resolve final config for a widget instance
CREATE OR REPLACE FUNCTION widgets.resolve_widget_config(
  p_widget_definition_id UUID,
  p_context VARCHAR,
  p_tenant_id UUID DEFAULT NULL,
  p_user_id UUID DEFAULT NULL,
  p_instance_config JSONB DEFAULT '{}'
)
RETURNS JSONB AS $$
DECLARE
  v_final_config JSONB;
  v_level1_config JSONB;
  v_level2_config JSONB;
  v_level3_config JSONB;
BEGIN
  -- Level 1: Widget definition default
  SELECT default_config INTO v_level1_config
  FROM widgets.widget_definitions
  WHERE id = p_widget_definition_id;

  v_final_config := COALESCE(v_level1_config, '{}');

  -- Level 2: Tenant override (if applicable)
  IF p_tenant_id IS NOT NULL THEN
    SELECT config_override INTO v_level2_config
    FROM widgets.tenant_widget_configs
    WHERE widget_definition_id = p_widget_definition_id
      AND tenant_id = p_tenant_id;

    v_final_config := v_final_config || COALESCE(v_level2_config, '{}');
  END IF;

  -- Level 3: User preferences (if applicable)
  IF p_user_id IS NOT NULL THEN
    SELECT config_override INTO v_level3_config
    FROM widgets.user_widget_preferences
    WHERE widget_definition_id = p_widget_definition_id
      AND user_id = p_user_id;

    v_final_config := v_final_config || COALESCE(v_level3_config, '{}');
  END IF;

  -- Level 4: Instance-specific config (highest priority)
  v_final_config := v_final_config || COALESCE(p_instance_config, '{}');

  RETURN v_final_config;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION widgets.resolve_widget_config IS
  'Resolves final config by merging Level 1 (system) → 2 (tenant) → 3 (user) → 4 (instance)';

-- =====================================================
-- 6. WIDGET ANALYTICS
-- =====================================================

CREATE TABLE widgets.widget_usage_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Widget reference
  widget_definition_id UUID REFERENCES widgets.widget_definitions(id) ON DELETE CASCADE,
  widget_instance_id UUID REFERENCES widgets.widget_instances(id) ON DELETE SET NULL,

  -- Context
  context VARCHAR(50) NOT NULL,
  tenant_id UUID,
  user_id UUID,

  -- Event
  event_type VARCHAR(50) NOT NULL,          -- view|interact|refresh|configure|error
  event_data JSONB DEFAULT '{}',

  -- Performance
  load_time_ms INTEGER,
  data_fetch_time_ms INTEGER,

  -- Metadata
  timestamp TIMESTAMPTZ DEFAULT NOW(),

  CHECK (event_type IN ('view', 'interact', 'refresh', 'configure', 'error', 'export'))
);

CREATE INDEX idx_widget_analytics_widget ON widgets.widget_usage_analytics(widget_definition_id);
CREATE INDEX idx_widget_analytics_instance ON widgets.widget_usage_analytics(widget_instance_id);
CREATE INDEX idx_widget_analytics_timestamp ON widgets.widget_usage_analytics(timestamp DESC);

-- Partition by month for performance
-- CREATE TABLE widgets.widget_usage_analytics_2025_01 PARTITION OF widgets.widget_usage_analytics
--   FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- =====================================================
-- 7. VIEWS FOR EASY QUERYING
-- =====================================================

-- View: Widget with full hierarchy
CREATE OR REPLACE VIEW widgets.widget_full_info AS
SELECT
  wd.id,
  wd.widget_id,
  wd.name,
  wd.description,
  wd.category,
  wd.plugin_id,
  p.name as plugin_name,
  wd.component_path,
  wd.default_config,
  wd.context_support,
  wd.context_behavior,
  wd.status,

  -- Count instances
  COUNT(DISTINCT wi.id) as instance_count,

  -- Count tenants using it
  COUNT(DISTINCT wi.tenant_id) as tenant_count,

  -- Count users using it
  COUNT(DISTINCT wi.user_id) as user_count

FROM widgets.widget_definitions wd
LEFT JOIN plugins.installed_plugins p ON wd.plugin_id = p.plugin_id
LEFT JOIN widgets.widget_instances wi ON wd.id = wi.widget_definition_id
WHERE wd.status = 'active'
GROUP BY wd.id, p.name;

-- View: Widget instances with resolved config
CREATE OR REPLACE VIEW widgets.widget_instances_resolved AS
SELECT
  wi.*,
  wd.widget_id,
  wd.name as widget_name,
  wd.category,
  wd.plugin_id,

  -- Resolved config
  widgets.resolve_widget_config(
    wi.widget_definition_id,
    wi.context,
    wi.tenant_id,
    wi.user_id,
    wi.instance_config
  ) as resolved_config

FROM widgets.widget_instances wi
JOIN widgets.widget_definitions wd ON wi.widget_definition_id = wd.id;

-- =====================================================
-- 8. TRIGGERS
-- =====================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION widgets.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER widget_definitions_updated
  BEFORE UPDATE ON widgets.widget_definitions
  FOR EACH ROW
  EXECUTE FUNCTION widgets.update_updated_at();

CREATE TRIGGER tenant_configs_updated
  BEFORE UPDATE ON widgets.tenant_widget_configs
  FOR EACH ROW
  EXECUTE FUNCTION widgets.update_updated_at();

CREATE TRIGGER user_prefs_updated
  BEFORE UPDATE ON widgets.user_widget_preferences
  FOR EACH ROW
  EXECUTE FUNCTION widgets.update_updated_at();

CREATE TRIGGER widget_instances_updated
  BEFORE UPDATE ON widgets.widget_instances
  FOR EACH ROW
  EXECUTE FUNCTION widgets.update_updated_at();

-- Track widget capability when widget is created
CREATE OR REPLACE FUNCTION widgets.register_widget_capability()
RETURNS TRIGGER AS $$
BEGIN
  -- Register widget as plugin capability
  INSERT INTO plugins.plugin_capabilities (plugin_id, capability_type, capability_id, metadata)
  VALUES (
    NEW.plugin_id,
    'widget',
    NEW.widget_id,
    jsonb_build_object(
      'name', NEW.name,
      'category', NEW.category,
      'version', NEW.version
    )
  )
  ON CONFLICT (plugin_id, capability_type, capability_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER widget_capability_register
  AFTER INSERT ON widgets.widget_definitions
  FOR EACH ROW
  WHEN (NEW.plugin_id IS NOT NULL)
  EXECUTE FUNCTION widgets.register_widget_capability();

-- =====================================================
-- 9. SEED DATA - Example Plugin with Widget
-- =====================================================

-- Example: User Management Plugin with Connected Users Widget
INSERT INTO plugins.installed_plugins (
  plugin_id, name, slug, version, description, manifest, status, enabled, install_path, is_system
) VALUES (
  'user-management',
  'User Management',
  'user-management',
  '1.0.0',
  'User management plugin with connected users widget',
  '{
    "plugin_id": "user-management",
    "version": "1.0.0",
    "widgets": ["connected-users-widget"],
    "permissions": ["users.read", "users.manage"]
  }',
  'active',
  true,
  '/plugins/user-management',
  true
) ON CONFLICT (plugin_id) DO NOTHING;

-- Connected Users Widget Definition (Level 1)
INSERT INTO widgets.widget_definitions (
  widget_id,
  name,
  description,
  plugin_id,
  category,
  component_path,
  config_schema,
  default_config,
  context_support,
  context_behavior,
  default_width,
  default_height,
  data_source_type,
  data_endpoint,
  supports_realtime,
  is_system
) VALUES (
  'connected-users-widget',
  'Connected Users',
  'Shows currently connected users in the system',
  'user-management',
  'user',
  './widgets/ConnectedUsersWidget.tsx',
  '{
    "type": "object",
    "properties": {
      "showAvatar": {"type": "boolean", "default": true},
      "maxUsers": {"type": "number", "default": 10, "min": 1, "max": 50},
      "refreshInterval": {"type": "number", "default": 30000},
      "showStatus": {"type": "boolean", "default": true},
      "sortBy": {"type": "string", "enum": ["name", "lastActive"], "default": "lastActive"}
    }
  }',
  '{
    "showAvatar": true,
    "maxUsers": 10,
    "refreshInterval": 30000,
    "showStatus": true,
    "sortBy": "lastActive"
  }',
  '{"admin": true, "tenant": true, "user": true}',
  '{
    "admin": {
      "scope": "global",
      "description": "Shows all users across all tenants",
      "filters": [],
      "permissions": ["users.read.all"]
    },
    "tenant": {
      "scope": "tenant",
      "description": "Shows only users in current tenant",
      "filters": ["tenant_id"],
      "permissions": ["users.read.tenant"]
    },
    "user": {
      "scope": "user",
      "description": "Shows only user info and their team members",
      "filters": ["tenant_id", "team_id"],
      "permissions": ["users.read.own"]
    }
  }',
  6,
  4,
  'realtime',
  '/api/users/connected',
  true,
  true
) ON CONFLICT (widget_id) DO NOTHING;

-- =====================================================
-- COMMENTS & DOCUMENTATION
-- =====================================================

COMMENT ON SCHEMA widgets IS 'Unified widget system with 3-level configuration (System/Tenant/User)';

COMMENT ON TABLE widgets.widget_definitions IS
  'Level 1: System-level widget definitions owned by plugins';

COMMENT ON TABLE widgets.tenant_widget_configs IS
  'Level 2: Tenant-specific customizations of widgets';

COMMENT ON TABLE widgets.user_widget_preferences IS
  'Level 3: User-specific preferences for widgets';

COMMENT ON TABLE widgets.widget_instances IS
  'Actual widget placements on pages with instance-specific config (Level 4)';

-- =====================================================
-- EXAMPLE QUERIES
-- =====================================================

-- Get all widgets for a tenant
-- SELECT * FROM widgets.widget_definitions
-- WHERE context_support->>'tenant' = 'true';

-- Get resolved config for a widget instance
-- SELECT * FROM widgets.widget_instances_resolved
-- WHERE id = '<instance_id>';

-- Get widget usage stats
-- SELECT widget_id, name, instance_count, tenant_count, user_count
-- FROM widgets.widget_full_info
-- ORDER BY instance_count DESC;
