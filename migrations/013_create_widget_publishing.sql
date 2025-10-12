-- Widget Publishing System
-- Bridge between God Mode (admin) and Tenant Frontends

-- Widget Publications (versioned, immutable widget releases)
CREATE TABLE IF NOT EXISTS workflow.widget_publications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  widget_id UUID NOT NULL REFERENCES workflow.widget_definitions(id) ON DELETE CASCADE,

  -- Version info
  version VARCHAR(50) NOT NULL,                  -- 1.0.0, 1.0.1, etc.
  version_major INTEGER NOT NULL,
  version_minor INTEGER NOT NULL,
  version_patch INTEGER NOT NULL,

  -- Publishing info
  published_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  published_by UUID REFERENCES auth.users(id),
  changelog TEXT,
  release_notes TEXT,

  -- Targeting
  target_tenants UUID[],                         -- NULL = all tenants, [] = none, [id1, id2] = specific
  exclude_tenants UUID[],
  target_environments TEXT[] DEFAULT ARRAY['production'], -- production, staging, development

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_latest BOOLEAN DEFAULT false,               -- Only one can be latest per widget
  deprecated BOOLEAN DEFAULT false,
  deprecation_message TEXT,
  sunset_date TIMESTAMP WITH TIME ZONE,          -- When this version will be removed

  -- Code snapshot (immutable, cannot be changed after publish)
  component_code_snapshot TEXT NOT NULL,
  component_props_snapshot JSONB NOT NULL DEFAULT '{}',
  config_schema_snapshot JSONB NOT NULL DEFAULT '{}',
  default_config_snapshot JSONB NOT NULL DEFAULT '{}',
  default_styles_snapshot JSONB NOT NULL DEFAULT '{}',

  -- Metadata snapshot
  category_snapshot VARCHAR(100) NOT NULL,
  display_name_snapshot VARCHAR(255) NOT NULL,
  description_snapshot TEXT,

  -- Requirements
  required_permissions TEXT[] DEFAULT '{}',
  required_features TEXT[] DEFAULT '{}',         -- Features tenant must have enabled
  min_platform_version VARCHAR(50),              -- Minimum EWH platform version

  -- Statistics
  install_count INTEGER DEFAULT 0,
  active_install_count INTEGER DEFAULT 0,

  -- Security
  code_hash VARCHAR(64),                         -- SHA-256 of component_code
  signed_by UUID REFERENCES auth.users(id),
  signature TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE (widget_id, version),
  CHECK (version_major >= 0),
  CHECK (version_minor >= 0),
  CHECK (version_patch >= 0)
);

CREATE INDEX idx_widget_publications_widget ON workflow.widget_publications(widget_id);
CREATE INDEX idx_widget_publications_version ON workflow.widget_publications(version);
CREATE INDEX idx_widget_publications_active ON workflow.widget_publications(is_active);
CREATE INDEX idx_widget_publications_latest ON workflow.widget_publications(is_latest);
CREATE INDEX idx_widget_publications_published ON workflow.widget_publications(published_at DESC);

-- Tenant Widget Installations (which widgets are installed for which tenants)
CREATE TABLE IF NOT EXISTS workflow.tenant_widget_installations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,                       -- References tenant system
  publication_id UUID NOT NULL REFERENCES workflow.widget_publications(id) ON DELETE CASCADE,

  -- Installation info
  installed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  installed_by UUID REFERENCES auth.users(id),

  -- Instance configuration (tenant-specific overrides)
  instance_name VARCHAR(255),
  instance_config JSONB DEFAULT '{}',            -- Override default config
  instance_styles JSONB DEFAULT '{}',            -- Override default styles

  -- Positioning (if widget is placed on specific page/location)
  page_location VARCHAR(255),                    -- e.g., "dashboard", "sidebar", "header"
  position_config JSONB DEFAULT '{}',            -- { x, y, width, height }

  -- Status
  enabled BOOLEAN DEFAULT true,
  auto_update BOOLEAN DEFAULT true,              -- Auto-update to latest version

  -- Permissions (which roles/users can see this widget)
  visible_to_roles TEXT[] DEFAULT '{}',
  visible_to_users UUID[] DEFAULT '{}',

  -- Usage stats
  last_used_at TIMESTAMP WITH TIME ZONE,
  usage_count INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE (tenant_id, publication_id)
);

CREATE INDEX idx_tenant_installations_tenant ON workflow.tenant_widget_installations(tenant_id);
CREATE INDEX idx_tenant_installations_publication ON workflow.tenant_widget_installations(publication_id);
CREATE INDEX idx_tenant_installations_enabled ON workflow.tenant_widget_installations(enabled);

-- Widget Registry Cache (optimized read cache for frontend)
CREATE MATERIALIZED VIEW IF NOT EXISTS workflow.widget_registry AS
SELECT
  p.id as publication_id,
  p.widget_id,
  w.name as widget_name,
  p.display_name_snapshot as display_name,
  p.description_snapshot as description,
  p.category_snapshot as category,
  p.version,
  p.is_latest,
  p.is_active,
  p.deprecated,
  p.component_code_snapshot as component_code,
  p.config_schema_snapshot as config_schema,
  p.default_config_snapshot as default_config,
  p.default_styles_snapshot as default_styles,
  p.required_permissions,
  p.required_features,
  p.install_count,
  p.published_at,
  p.target_tenants,
  p.exclude_tenants,
  w.tags,
  w.version as widget_version
FROM workflow.widget_publications p
JOIN workflow.widget_definitions w ON w.id = p.widget_id
WHERE p.is_active = true
ORDER BY p.is_latest DESC, p.published_at DESC;

CREATE INDEX idx_widget_registry_category ON workflow.widget_registry(category);
CREATE INDEX idx_widget_registry_latest ON workflow.widget_registry(is_latest);

-- Widget Usage Analytics (track widget performance)
CREATE TABLE IF NOT EXISTS workflow.widget_usage_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installation_id UUID NOT NULL REFERENCES workflow.tenant_widget_installations(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL,

  -- Usage event
  event_type VARCHAR(50) NOT NULL,               -- render, interact, error, load, unload
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Performance
  load_time_ms INTEGER,
  render_time_ms INTEGER,

  -- Error info (if event_type = 'error')
  error_message TEXT,
  error_stack TEXT,

  -- User info
  user_id UUID,
  session_id VARCHAR(255),

  -- Context
  page_url VARCHAR(500),
  metadata JSONB DEFAULT '{}',

  CHECK (event_type IN ('render', 'interact', 'error', 'load', 'unload', 'click', 'submit'))
);

CREATE INDEX idx_widget_analytics_installation ON workflow.widget_usage_analytics(installation_id);
CREATE INDEX idx_widget_analytics_tenant ON workflow.widget_usage_analytics(tenant_id);
CREATE INDEX idx_widget_analytics_timestamp ON workflow.widget_usage_analytics(timestamp DESC);
CREATE INDEX idx_widget_analytics_event ON workflow.widget_usage_analytics(event_type);

-- Widget Update History (track version updates)
CREATE TABLE IF NOT EXISTS workflow.widget_update_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installation_id UUID NOT NULL REFERENCES workflow.tenant_widget_installations(id) ON DELETE CASCADE,

  -- Update info
  from_publication_id UUID REFERENCES workflow.widget_publications(id),
  to_publication_id UUID NOT NULL REFERENCES workflow.widget_publications(id),

  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id),
  update_type VARCHAR(50) NOT NULL,              -- auto, manual, rollback

  -- Result
  success BOOLEAN DEFAULT true,
  error_message TEXT,

  CHECK (update_type IN ('auto', 'manual', 'rollback', 'forced'))
);

CREATE INDEX idx_widget_updates_installation ON workflow.widget_update_history(installation_id);
CREATE INDEX idx_widget_updates_timestamp ON workflow.widget_update_history(updated_at DESC);

-- Update triggers
CREATE TRIGGER update_tenant_installations_updated_at BEFORE UPDATE ON workflow.tenant_widget_installations
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- Function to refresh widget registry cache
CREATE OR REPLACE FUNCTION workflow.refresh_widget_registry()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY workflow.widget_registry;
END;
$$ LANGUAGE plpgsql;

-- Function to publish widget
CREATE OR REPLACE FUNCTION workflow.publish_widget(
  p_widget_id UUID,
  p_version VARCHAR(50),
  p_changelog TEXT,
  p_published_by UUID
)
RETURNS UUID AS $$
DECLARE
  v_publication_id UUID;
  v_widget_record RECORD;
  v_version_parts TEXT[];
BEGIN
  -- Get widget data
  SELECT * INTO v_widget_record FROM workflow.widget_definitions WHERE id = p_widget_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Widget not found: %', p_widget_id;
  END IF;

  -- Parse version (e.g., "1.2.3" -> [1, 2, 3])
  v_version_parts := string_to_array(p_version, '.');

  -- Create publication
  INSERT INTO workflow.widget_publications (
    widget_id,
    version,
    version_major,
    version_minor,
    version_patch,
    published_by,
    changelog,
    component_code_snapshot,
    component_props_snapshot,
    config_schema_snapshot,
    default_config_snapshot,
    default_styles_snapshot,
    category_snapshot,
    display_name_snapshot,
    description_snapshot,
    code_hash
  ) VALUES (
    p_widget_id,
    p_version,
    v_version_parts[1]::INTEGER,
    v_version_parts[2]::INTEGER,
    v_version_parts[3]::INTEGER,
    p_published_by,
    p_changelog,
    v_widget_record.component_code,
    v_widget_record.component_props,
    v_widget_record.config_schema,
    v_widget_record.default_config,
    v_widget_record.default_styles,
    v_widget_record.category,
    v_widget_record.display_name,
    v_widget_record.description,
    encode(sha256(v_widget_record.component_code::bytea), 'hex')
  )
  RETURNING id INTO v_publication_id;

  -- Refresh registry cache
  PERFORM workflow.refresh_widget_registry();

  RETURN v_publication_id;
END;
$$ LANGUAGE plpgsql;

-- Function to install widget for tenant
CREATE OR REPLACE FUNCTION workflow.install_widget_for_tenant(
  p_tenant_id UUID,
  p_publication_id UUID,
  p_installed_by UUID,
  p_config JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_installation_id UUID;
BEGIN
  INSERT INTO workflow.tenant_widget_installations (
    tenant_id,
    publication_id,
    installed_by,
    instance_config
  ) VALUES (
    p_tenant_id,
    p_publication_id,
    p_installed_by,
    p_config
  )
  ON CONFLICT (tenant_id, publication_id) DO UPDATE
  SET enabled = true, updated_at = NOW()
  RETURNING id INTO v_installation_id;

  -- Update install count
  UPDATE workflow.widget_publications
  SET install_count = install_count + 1,
      active_install_count = active_install_count + 1
  WHERE id = p_publication_id;

  RETURN v_installation_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE workflow.widget_publications IS 'Published, versioned widget releases';
COMMENT ON TABLE workflow.tenant_widget_installations IS 'Widgets installed for each tenant';
COMMENT ON TABLE workflow.widget_usage_analytics IS 'Widget usage and performance metrics';
COMMENT ON TABLE workflow.widget_update_history IS 'Widget version update history';
COMMENT ON FUNCTION workflow.publish_widget IS 'Publish a widget as a new immutable version';
COMMENT ON FUNCTION workflow.install_widget_for_tenant IS 'Install a widget for a specific tenant';
