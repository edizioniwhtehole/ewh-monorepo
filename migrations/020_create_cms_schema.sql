-- ============================================================================
-- CMS Schema - Unified Modular System
-- Manages pages composed of widgets
-- ============================================================================

-- Create CMS schema
CREATE SCHEMA IF NOT EXISTS cms;

-- ============================================================================
-- Templates Table
-- Pre-built page layouts with default widget compositions
-- ============================================================================
CREATE TABLE cms.templates (
  template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  preview_image TEXT,
  category TEXT NOT NULL, -- 'admin', 'public', 'landing', 'email'
  layout JSONB NOT NULL, -- Widget composition structure
  is_system BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_templates_category ON cms.templates(category);
CREATE INDEX idx_templates_is_system ON cms.templates(is_system);

-- ============================================================================
-- Pages Table
-- Main table for all pages (admin dashboards, public pages, landing pages)
-- ============================================================================
CREATE TABLE cms.pages (
  page_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  page_type TEXT NOT NULL CHECK (page_type IN ('admin', 'public', 'landing', 'email')),
  template_id UUID REFERENCES cms.templates(template_id) ON DELETE SET NULL,
  layout JSONB NOT NULL, -- Current widget composition
  meta_data JSONB, -- SEO, OpenGraph, etc.
  styles JSONB, -- Custom CSS/theme overrides
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'review', 'published', 'archived')),
  published_version INT,
  published_at TIMESTAMPTZ,
  scheduled_publish_at TIMESTAMPTZ,
  
  -- Permissions & Multi-tenancy
  tenant_id UUID, -- NULL = global/platform page
  required_roles TEXT[], -- Required user roles to view
  required_permissions TEXT[], -- Required permissions
  
  -- Audit
  created_by UUID NOT NULL,
  updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pages_slug ON cms.pages(slug);
CREATE INDEX idx_pages_page_type ON cms.pages(page_type);
CREATE INDEX idx_pages_status ON cms.pages(status);
CREATE INDEX idx_pages_tenant_id ON cms.pages(tenant_id);
CREATE INDEX idx_pages_published_at ON cms.pages(published_at);

-- ============================================================================
-- Page Versions Table
-- Version history for rollback capability
-- ============================================================================
CREATE TABLE cms.page_versions (
  version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES cms.pages(page_id) ON DELETE CASCADE,
  version_number INT NOT NULL,
  layout JSONB NOT NULL,
  meta_data JSONB,
  styles JSONB,
  changes_summary TEXT,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(page_id, version_number)
);

CREATE INDEX idx_page_versions_page_id ON cms.page_versions(page_id);
CREATE INDEX idx_page_versions_version_number ON cms.page_versions(page_id, version_number DESC);

-- ============================================================================
-- Page Widget Configs Table
-- Individual widget configurations per page instance
-- ============================================================================
CREATE TABLE cms.page_widget_configs (
  config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES cms.pages(page_id) ON DELETE CASCADE,
  widget_id TEXT NOT NULL, -- Reference to widget in registry (e.g. 'metrics-cards')
  instance_id TEXT NOT NULL, -- Unique instance ID on page (e.g. 'metrics-1')
  position JSONB NOT NULL, -- {row, col, width, height}
  config JSONB NOT NULL, -- Widget-specific configuration
  conditions JSONB, -- Display conditions (roles, device, date range)
  is_visible BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(page_id, instance_id)
);

CREATE INDEX idx_page_widget_configs_page_id ON cms.page_widget_configs(page_id);
CREATE INDEX idx_page_widget_configs_widget_id ON cms.page_widget_configs(widget_id);

-- ============================================================================
-- Page Analytics Table
-- Track page views and interactions
-- ============================================================================
CREATE TABLE cms.page_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES cms.pages(page_id) ON DELETE CASCADE,
  event_type TEXT NOT NULL, -- 'view', 'widget_interaction', 'error'
  user_id UUID,
  tenant_id UUID,
  session_id TEXT,
  widget_id TEXT, -- If event is widget-specific
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_page_analytics_page_id ON cms.page_analytics(page_id);
CREATE INDEX idx_page_analytics_created_at ON cms.page_analytics(created_at);
CREATE INDEX idx_page_analytics_event_type ON cms.page_analytics(event_type);

-- ============================================================================
-- Functions & Triggers
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION cms.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_templates_updated_at BEFORE UPDATE ON cms.templates
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

CREATE TRIGGER update_pages_updated_at BEFORE UPDATE ON cms.pages
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

CREATE TRIGGER update_page_widget_configs_updated_at BEFORE UPDATE ON cms.page_widget_configs
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

-- Auto-create version on page update
CREATE OR REPLACE FUNCTION cms.create_page_version()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create version if layout actually changed
  IF OLD.layout IS DISTINCT FROM NEW.layout THEN
    INSERT INTO cms.page_versions (
      page_id,
      version_number,
      layout,
      meta_data,
      styles,
      changes_summary,
      created_by
    ) VALUES (
      NEW.page_id,
      COALESCE((SELECT MAX(version_number) + 1 FROM cms.page_versions WHERE page_id = NEW.page_id), 1),
      OLD.layout,
      OLD.meta_data,
      OLD.styles,
      'Auto-saved version before update',
      NEW.updated_by
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_page_version_trigger BEFORE UPDATE ON cms.pages
  FOR EACH ROW EXECUTE FUNCTION cms.create_page_version();

-- ============================================================================
-- Seed Data - Default Templates
-- ============================================================================

-- Admin Dashboard Template
INSERT INTO cms.templates (name, description, category, layout, is_system) VALUES
(
  'Admin Dashboard',
  'Standard admin dashboard with metrics, service status, and recent activity',
  'admin',
  '{
    "version": "1.0",
    "grid": {
      "type": "grid",
      "columns": 12,
      "gap": 24,
      "responsive": {
        "mobile": {"columns": 1},
        "tablet": {"columns": 6},
        "desktop": {"columns": 12}
      }
    },
    "widgets": [
      {
        "instanceId": "metrics-1",
        "widgetId": "metrics-cards",
        "position": {"row": 0, "col": 0, "width": 12, "height": 1}
      },
      {
        "instanceId": "services-1",
        "widgetId": "service-status",
        "position": {"row": 1, "col": 0, "width": 6, "height": 2}
      },
      {
        "instanceId": "activity-1",
        "widgetId": "recent-activity",
        "position": {"row": 1, "col": 6, "width": 6, "height": 2}
      }
    ]
  }'::jsonb,
  TRUE
),
(
  'Monitoring Dashboard',
  'Full monitoring dashboard with service health and alerts',
  'admin',
  '{
    "version": "1.0",
    "grid": {
      "type": "grid",
      "columns": 12,
      "gap": 24
    },
    "widgets": [
      {
        "instanceId": "health-1",
        "widgetId": "service-health",
        "position": {"row": 0, "col": 0, "width": 12, "height": 2}
      }
    ]
  }'::jsonb,
  TRUE
);

-- ============================================================================
-- Grants
-- ============================================================================
GRANT USAGE ON SCHEMA cms TO ewh;
GRANT ALL ON ALL TABLES IN SCHEMA cms TO ewh;
GRANT ALL ON ALL SEQUENCES IN SCHEMA cms TO ewh;

-- ============================================================================
-- Comments
-- ============================================================================
COMMENT ON SCHEMA cms IS 'Content Management System for modular page composition';
COMMENT ON TABLE cms.pages IS 'All pages (admin dashboards, public pages, landing pages)';
COMMENT ON TABLE cms.templates IS 'Pre-built page templates with widget compositions';
COMMENT ON TABLE cms.page_versions IS 'Version history for pages (rollback support)';
COMMENT ON TABLE cms.page_widget_configs IS 'Individual widget configurations per page instance';
COMMENT ON TABLE cms.page_analytics IS 'Page views and interaction tracking';
