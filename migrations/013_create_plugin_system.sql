-- =====================================================
-- Plugin System - Modular Architecture
-- Enables WordPress/Joomla-style extensibility
-- =====================================================

CREATE SCHEMA IF NOT EXISTS plugins;

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Plugin Registry: All installed plugins
CREATE TABLE plugins.installed_plugins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) UNIQUE NOT NULL,  -- Unique identifier (e.g., "ewh-plugin-crm")
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,       -- URL-safe name
  version VARCHAR(50) NOT NULL,            -- Semver format
  description TEXT,
  author_name VARCHAR(255),
  author_email VARCHAR(255),
  author_url TEXT,

  -- Plugin metadata (full manifest)
  manifest JSONB NOT NULL,

  -- State management
  status VARCHAR(50) NOT NULL DEFAULT 'inactive',  -- active|inactive|error|updating|installing
  enabled BOOLEAN DEFAULT FALSE,

  -- Installation tracking
  installed_at TIMESTAMPTZ DEFAULT NOW(),
  installed_by VARCHAR(255),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  activated_at TIMESTAMPTZ,

  -- Health monitoring
  last_error TEXT,
  last_health_check TIMESTAMPTZ,
  health_status VARCHAR(50) DEFAULT 'unknown',  -- healthy|degraded|unhealthy

  -- Configuration (plugin-specific settings)
  config JSONB DEFAULT '{}',

  -- Licensing
  license VARCHAR(100),
  license_key VARCHAR(500),
  license_valid_until TIMESTAMPTZ,
  is_premium BOOLEAN DEFAULT FALSE,

  -- File paths
  install_path TEXT NOT NULL,

  CONSTRAINT valid_status CHECK (status IN ('active', 'inactive', 'error', 'updating', 'installing'))
);

-- Plugin Dependencies: Manages plugin requirements
CREATE TABLE plugins.plugin_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,
  depends_on VARCHAR(255) NOT NULL,        -- Plugin ID or "core"
  dependency_type VARCHAR(50) NOT NULL DEFAULT 'required',  -- required|optional|conflicting
  version_constraint VARCHAR(100),         -- Semver range: ">=1.0.0 <2.0.0"

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(plugin_id, depends_on),
  CONSTRAINT valid_dependency_type CHECK (dependency_type IN ('required', 'optional', 'conflicting'))
);

-- =====================================================
-- HOOK SYSTEM (WordPress-style)
-- =====================================================

-- Hook Registry: All available hooks in the system
CREATE TABLE plugins.hook_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hook_name VARCHAR(255) UNIQUE NOT NULL,  -- e.g., "user:created", "order:paid"
  hook_type VARCHAR(50) NOT NULL,          -- action|filter
  description TEXT,
  payload_schema JSONB,                    -- Expected payload structure

  -- Categorization
  category VARCHAR(100),                   -- user|order|system|etc

  -- Documentation
  example_usage TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_hook_type CHECK (hook_type IN ('action', 'filter'))
);

-- Plugin Hook Handlers: Plugin implementations of hooks
CREATE TABLE plugins.plugin_hooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,
  hook_name VARCHAR(255) NOT NULL,
  hook_type VARCHAR(50) NOT NULL,

  -- Handler information
  handler_function VARCHAR(255) NOT NULL,  -- Function name in plugin
  handler_file TEXT,                       -- File path relative to plugin

  -- Execution control
  priority INTEGER DEFAULT 10,             -- Lower = earlier execution
  enabled BOOLEAN DEFAULT TRUE,

  -- Metadata
  description TEXT,
  registered_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(plugin_id, hook_name, handler_function),
  CONSTRAINT valid_hook_type CHECK (hook_type IN ('action', 'filter'))
);

-- Hook Execution Log: Track hook executions for debugging
CREATE TABLE plugins.hook_execution_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hook_name VARCHAR(255) NOT NULL,
  plugin_id VARCHAR(255),

  -- Execution details
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  execution_time_ms INTEGER,
  success BOOLEAN,
  error_message TEXT,

  -- Context
  payload_sample JSONB,  -- Sample of the payload (truncated)

  -- Retention: only keep last 7 days
  CONSTRAINT retention_check CHECK (executed_at > NOW() - INTERVAL '7 days')
);

-- =====================================================
-- PAGE SYSTEM
-- =====================================================

-- Page Definitions: Admin pages that can host plugins
CREATE TABLE plugins.page_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id VARCHAR(255) UNIQUE NOT NULL,    -- e.g., "admin-workers"
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,       -- URL path: "/admin/workers"
  description TEXT,

  -- Navigation
  icon VARCHAR(100),                       -- Lucide icon name
  parent_page_id VARCHAR(255),             -- For nested menus
  menu_position INTEGER DEFAULT 100,

  -- Access control
  required_role VARCHAR(100)[] DEFAULT ARRAY['admin'],
  required_permissions VARCHAR(100)[],

  -- Layout configuration
  layout_type VARCHAR(50) DEFAULT 'grid',  -- grid|flex|custom
  layout_config JSONB DEFAULT '{"columns": 12, "gap": 16}',

  -- State
  is_active BOOLEAN DEFAULT TRUE,
  is_system_page BOOLEAN DEFAULT FALSE,    -- Cannot be deleted

  -- Ownership
  created_by_plugin VARCHAR(255),          -- NULL = core system
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_layout_type CHECK (layout_type IN ('grid', 'flex', 'custom', 'dashboard'))
);

-- Page Widgets: Widgets mounted on pages
CREATE TABLE plugins.page_widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id VARCHAR(255) REFERENCES plugins.page_definitions(page_id) ON DELETE CASCADE,
  widget_id VARCHAR(255) NOT NULL,         -- Reference to widget definition
  instance_id UUID UNIQUE DEFAULT gen_random_uuid(),

  -- Plugin ownership
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,

  -- Layout positioning (grid-based)
  grid_x INTEGER NOT NULL DEFAULT 0,
  grid_y INTEGER NOT NULL DEFAULT 0,
  grid_w INTEGER NOT NULL DEFAULT 6,       -- Width in grid columns
  grid_h INTEGER NOT NULL DEFAULT 4,       -- Height in grid rows

  -- Configuration
  widget_config JSONB DEFAULT '{}',

  -- State
  is_visible BOOLEAN DEFAULT TRUE,
  is_locked BOOLEAN DEFAULT FALSE,         -- Cannot be moved/resized

  -- Order/Priority
  z_index INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_grid_position CHECK (grid_x >= 0 AND grid_y >= 0),
  CONSTRAINT valid_grid_size CHECK (grid_w > 0 AND grid_h > 0)
);

-- =====================================================
-- WIDGET SYSTEM
-- =====================================================

-- Widget Definitions: Reusable UI components
CREATE TABLE plugins.widget_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  widget_id VARCHAR(255) UNIQUE NOT NULL,  -- e.g., "worker-status-widget"
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,

  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100),                   -- monitoring|analytics|content|etc

  -- UI metadata
  icon VARCHAR(100),
  preview_image TEXT,                      -- URL to preview screenshot

  -- Size constraints
  default_width INTEGER DEFAULT 6,
  default_height INTEGER DEFAULT 4,
  min_width INTEGER DEFAULT 2,
  min_height INTEGER DEFAULT 2,
  max_width INTEGER DEFAULT 12,
  max_height INTEGER DEFAULT 12,

  -- Component path
  component_path TEXT NOT NULL,            -- Relative to plugin directory

  -- Configuration
  config_schema JSONB,                     -- JSON Schema for validation
  default_config JSONB DEFAULT '{}',

  -- Capabilities
  has_settings BOOLEAN DEFAULT FALSE,
  is_resizable BOOLEAN DEFAULT TRUE,
  supports_realtime BOOLEAN DEFAULT FALSE,

  -- Data requirements
  data_source_type VARCHAR(50),            -- api|realtime|polling|static
  data_endpoint TEXT,
  poll_interval INTEGER,                   -- Milliseconds

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- PERMISSIONS & ACCESS CONTROL
-- =====================================================

-- Plugin Permissions: Track what plugins can access
CREATE TABLE plugins.plugin_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,

  permission_type VARCHAR(50) NOT NULL,    -- database|api|filesystem|network|cron
  resource VARCHAR(255) NOT NULL,          -- Specific resource (table, endpoint, etc)
  action VARCHAR(50) NOT NULL,             -- read|write|delete|execute
  scope TEXT,                              -- Additional scope details

  -- Approval
  granted BOOLEAN DEFAULT FALSE,
  granted_at TIMESTAMPTZ,
  granted_by VARCHAR(255),
  revoked_at TIMESTAMPTZ,

  -- Audit
  reason TEXT,                             -- Why this permission is needed
  last_used_at TIMESTAMPTZ,
  usage_count INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(plugin_id, permission_type, resource, action),
  CONSTRAINT valid_permission_type CHECK (permission_type IN ('database', 'api', 'filesystem', 'network', 'cron', 'event'))
);

-- =====================================================
-- EVENT & AUDIT SYSTEM
-- =====================================================

-- Plugin Events: Audit log for plugin lifecycle
CREATE TABLE plugins.plugin_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,

  event_type VARCHAR(100) NOT NULL,        -- installed|activated|deactivated|updated|error|uninstalled
  event_data JSONB,
  error_details TEXT,

  -- Context
  triggered_by VARCHAR(255),               -- User or system
  ip_address INET,
  user_agent TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Retention: keep last 90 days
  CONSTRAINT retention_check CHECK (created_at > NOW() - INTERVAL '90 days')
);

-- API Call Log: Track plugin API usage
CREATE TABLE plugins.plugin_api_calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,

  endpoint TEXT NOT NULL,
  method VARCHAR(10) NOT NULL,
  status_code INTEGER,
  response_time_ms INTEGER,

  -- Rate limiting
  called_at TIMESTAMPTZ DEFAULT NOW(),

  -- Retention: keep last 24 hours
  CONSTRAINT retention_check CHECK (called_at > NOW() - INTERVAL '24 hours')
);

-- =====================================================
-- CONFIGURATION & SETTINGS
-- =====================================================

-- Plugin Settings: Key-value store for plugin config
CREATE TABLE plugins.plugin_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) REFERENCES plugins.installed_plugins(plugin_id) ON DELETE CASCADE,

  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,
  setting_type VARCHAR(50) NOT NULL,       -- string|number|boolean|object|array

  -- Metadata
  is_encrypted BOOLEAN DEFAULT FALSE,
  is_public BOOLEAN DEFAULT FALSE,         -- Can be exposed to frontend

  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by VARCHAR(255),

  UNIQUE(plugin_id, setting_key)
);

-- =====================================================
-- MARKETPLACE (Optional - for future)
-- =====================================================

-- Plugin Marketplace Listings
CREATE TABLE plugins.marketplace_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plugin_id VARCHAR(255) UNIQUE NOT NULL,

  -- Listing info
  name VARCHAR(255) NOT NULL,
  tagline VARCHAR(500),
  description TEXT,
  long_description TEXT,

  -- Media
  icon_url TEXT,
  banner_url TEXT,
  screenshots TEXT[],
  demo_url TEXT,

  -- Pricing
  pricing_model VARCHAR(50) DEFAULT 'free', -- free|one-time|subscription|freemium
  price DECIMAL(10, 2),
  currency VARCHAR(3) DEFAULT 'USD',

  -- Stats
  download_count INTEGER DEFAULT 0,
  active_installs INTEGER DEFAULT 0,
  rating DECIMAL(3, 2),
  review_count INTEGER DEFAULT 0,

  -- Publishing
  is_published BOOLEAN DEFAULT FALSE,
  is_featured BOOLEAN DEFAULT FALSE,
  published_at TIMESTAMPTZ,

  -- SEO
  seo_keywords TEXT[],

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Plugin indexes
CREATE INDEX idx_plugins_status ON plugins.installed_plugins(status);
CREATE INDEX idx_plugins_enabled ON plugins.installed_plugins(enabled);
CREATE INDEX idx_plugins_slug ON plugins.installed_plugins(slug);

-- Hook indexes
CREATE INDEX idx_hooks_name ON plugins.plugin_hooks(hook_name);
CREATE INDEX idx_hooks_plugin ON plugins.plugin_hooks(plugin_id);
CREATE INDEX idx_hooks_enabled ON plugins.plugin_hooks(enabled);
CREATE INDEX idx_hook_execution_time ON plugins.hook_execution_log(executed_at);

-- Page indexes
CREATE INDEX idx_pages_slug ON plugins.page_definitions(slug);
CREATE INDEX idx_pages_active ON plugins.page_definitions(is_active);
CREATE INDEX idx_page_widgets_page ON plugins.page_widgets(page_id);
CREATE INDEX idx_page_widgets_plugin ON plugins.page_widgets(plugin_id);

-- Widget indexes
CREATE INDEX idx_widgets_plugin ON plugins.widget_definitions(plugin_id);
CREATE INDEX idx_widgets_category ON plugins.widget_definitions(category);

-- Permission indexes
CREATE INDEX idx_permissions_plugin ON plugins.plugin_permissions(plugin_id);
CREATE INDEX idx_permissions_granted ON plugins.plugin_permissions(granted);

-- Event indexes
CREATE INDEX idx_events_plugin ON plugins.plugin_events(plugin_id);
CREATE INDEX idx_events_type ON plugins.plugin_events(event_type);
CREATE INDEX idx_events_time ON plugins.plugin_events(created_at);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Update timestamp on plugin changes
CREATE OR REPLACE FUNCTION plugins.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_plugin_timestamp
  BEFORE UPDATE ON plugins.installed_plugins
  FOR EACH ROW
  EXECUTE FUNCTION plugins.update_updated_at();

CREATE TRIGGER update_page_timestamp
  BEFORE UPDATE ON plugins.page_definitions
  FOR EACH ROW
  EXECUTE FUNCTION plugins.update_updated_at();

CREATE TRIGGER update_widget_timestamp
  BEFORE UPDATE ON plugins.widget_definitions
  FOR EACH ROW
  EXECUTE FUNCTION plugins.update_updated_at();

-- Log plugin status changes
CREATE OR REPLACE FUNCTION plugins.log_plugin_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status OR OLD.enabled IS DISTINCT FROM NEW.enabled THEN
    INSERT INTO plugins.plugin_events (plugin_id, event_type, event_data)
    VALUES (
      NEW.plugin_id,
      CASE
        WHEN NEW.status = 'active' AND OLD.status != 'active' THEN 'activated'
        WHEN NEW.status = 'inactive' AND OLD.status = 'active' THEN 'deactivated'
        WHEN NEW.status = 'error' THEN 'error'
        ELSE 'status_changed'
      END,
      jsonb_build_object(
        'old_status', OLD.status,
        'new_status', NEW.status,
        'old_enabled', OLD.enabled,
        'new_enabled', NEW.enabled
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER log_plugin_status
  AFTER UPDATE ON plugins.installed_plugins
  FOR EACH ROW
  EXECUTE FUNCTION plugins.log_plugin_status_change();

-- =====================================================
-- SEED DATA: Core System Pages
-- =====================================================

INSERT INTO plugins.page_definitions (page_id, name, slug, description, icon, menu_position, is_system_page, required_role) VALUES
  ('admin-dashboard', 'Dashboard', '/admin/dashboard', 'Main admin dashboard overview', 'LayoutDashboard', 1, TRUE, ARRAY['admin']),
  ('admin-tenants', 'Tenants', '/admin/tenants', 'Manage tenant accounts', 'Users', 2, TRUE, ARRAY['super_admin']),
  ('admin-monitoring', 'Monitoring', '/admin/monitoring', 'System health and performance monitoring', 'Activity', 3, TRUE, ARRAY['admin']),
  ('admin-logs', 'Logs', '/logs', 'System log viewer', 'FileText', 4, TRUE, ARRAY['admin']),
  ('admin-deployments', 'Deployments', '/deployments', 'Deployment management', 'Rocket', 5, TRUE, ARRAY['admin']),
  ('admin-infrastructure', 'Infrastructure', '/infrastructure-map', 'Infrastructure topology map', 'Map', 6, TRUE, ARRAY['admin']),
  ('admin-workflows', 'Workflows', '/workflow-builder', 'Visual workflow builder', 'Zap', 7, TRUE, ARRAY['admin']),
  ('admin-service-nodes', 'Service Nodes', '/service-nodes', 'N8N service node management', 'Box', 8, TRUE, ARRAY['admin']),
  ('admin-api-integrations', 'API Integrations', '/api-integrations', 'External API configuration', 'Plug', 9, TRUE, ARRAY['admin']),
  ('admin-gateway', 'API Gateway', '/gateway-enterprise', 'Enterprise API gateway management', 'Router', 10, TRUE, ARRAY['admin']),
  ('admin-god-mode', 'God Mode', '/god-mode', 'Advanced system configuration', 'Wand2', 11, TRUE, ARRAY['super_admin']),
  ('admin-packages', 'Packages', '/admin/packages', 'Package management', 'Package', 12, TRUE, ARRAY['admin']),
  ('admin-billing', 'Billing', '/admin/billing', 'Billing and invoicing', 'DollarSign', 13, TRUE, ARRAY['admin']),
  ('admin-landing-pages', 'Landing Pages', '/admin/landing-pages', 'Landing page builder', 'Layout', 14, TRUE, ARRAY['admin']),
  ('admin-services', 'Services', '/admin/services', 'Microservice management', 'Server', 15, TRUE, ARRAY['admin']),
  ('admin-settings', 'Settings', '/admin/settings', 'System settings', 'Settings', 16, TRUE, ARRAY['admin']);

-- =====================================================
-- SEED DATA: Core System Hooks
-- =====================================================

INSERT INTO plugins.hook_definitions (hook_name, hook_type, category, description, example_usage) VALUES
  -- User hooks
  ('user:created', 'action', 'user', 'Fired after a new user is created', 'Create CRM contact, send welcome email'),
  ('user:updated', 'action', 'user', 'Fired after user profile is updated', 'Sync to external systems'),
  ('user:deleted', 'action', 'user', 'Fired before user is deleted', 'Cleanup related data'),
  ('user:profile', 'filter', 'user', 'Modify user profile data before display', 'Add computed fields, enrich data'),

  -- Tenant hooks
  ('tenant:created', 'action', 'tenant', 'Fired after new tenant is created', 'Provision resources, setup defaults'),
  ('tenant:activated', 'action', 'tenant', 'Fired when tenant subscription activates', 'Enable features, send notification'),
  ('tenant:suspended', 'action', 'tenant', 'Fired when tenant is suspended', 'Disable access, preserve data'),

  -- Dashboard hooks
  ('dashboard:widgets', 'filter', 'dashboard', 'Modify available widgets for dashboard', 'Add custom widgets'),
  ('dashboard:loaded', 'action', 'dashboard', 'Fired when dashboard page loads', 'Track analytics, load data'),

  -- System hooks
  ('system:startup', 'action', 'system', 'Fired on system initialization', 'Initialize plugin resources'),
  ('system:shutdown', 'action', 'system', 'Fired before system shutdown', 'Cleanup, save state'),
  ('system:error', 'action', 'system', 'Fired when system error occurs', 'Log to external service, alert admins');

COMMENT ON SCHEMA plugins IS 'Plugin system for modular extensibility - WordPress/Joomla style architecture';
COMMENT ON TABLE plugins.installed_plugins IS 'Registry of all installed plugins with metadata and state';
COMMENT ON TABLE plugins.page_definitions IS 'Admin page definitions that can host plugin widgets';
COMMENT ON TABLE plugins.page_widgets IS 'Widget instances mounted on pages with positioning';
COMMENT ON TABLE plugins.widget_definitions IS 'Reusable widget components provided by plugins';
COMMENT ON TABLE plugins.plugin_hooks IS 'Plugin implementations of system hooks';
COMMENT ON TABLE plugins.hook_definitions IS 'Available hooks in the system';
