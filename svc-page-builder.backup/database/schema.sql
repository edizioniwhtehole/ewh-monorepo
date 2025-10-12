-- EWH Page Builder Database Schema
-- Multi-tenant page storage with JSON components

-- Pages table - stores GrapesJS JSON
CREATE TABLE IF NOT EXISTS pb_pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Page identity
  slug VARCHAR(255) NOT NULL,
  title VARCHAR(500),
  description TEXT,

  -- GrapesJS JSON storage
  components JSONB NOT NULL DEFAULT '[]'::jsonb,  -- Component tree
  styles TEXT,                                      -- Generated CSS
  assets JSONB DEFAULT '[]'::jsonb,                -- Images, fonts, etc

  -- Data binding configuration
  data_bindings JSONB DEFAULT '{}'::jsonb,         -- {{cms.field}} mappings

  -- Publishing workflow
  status VARCHAR(20) DEFAULT 'draft',              -- draft|review|published|archived
  published_at TIMESTAMP,
  published_by UUID,

  -- Versioning
  version INTEGER DEFAULT 1,
  parent_version_id UUID REFERENCES pb_pages(id),

  -- SEO
  meta_title VARCHAR(255),
  meta_description TEXT,
  meta_keywords TEXT[],
  og_image VARCHAR(500),

  -- Audit
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  created_by UUID,
  updated_by UUID,

  -- Constraints
  UNIQUE(tenant_id, slug, version)
);

-- Templates library - reusable page templates
CREATE TABLE IF NOT EXISTS pb_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100),                           -- landing|blog|ecommerce|etc

  -- Template content (same as page)
  components JSONB NOT NULL,
  styles TEXT,

  -- Thumbnail for template gallery
  thumbnail_url VARCHAR(500),

  -- Access control
  is_public BOOLEAN DEFAULT false,                 -- Available to all tenants
  created_by UUID,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Custom blocks - tenant-specific block library
CREATE TABLE IF NOT EXISTS pb_custom_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  name VARCHAR(255) NOT NULL,
  label VARCHAR(255),
  category VARCHAR(100),

  -- Block definition (GrapesJS component)
  component_json JSONB NOT NULL,
  icon_svg TEXT,

  -- Reusability
  is_reusable BOOLEAN DEFAULT true,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(tenant_id, name)
);

-- Page publish history - audit trail
CREATE TABLE IF NOT EXISTS pb_publish_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID REFERENCES pb_pages(id) ON DELETE CASCADE,

  published_by UUID,
  published_at TIMESTAMP DEFAULT NOW(),

  -- Snapshot at publish time
  components_snapshot JSONB,
  version_number INTEGER,

  -- Deployment info
  deploy_url VARCHAR(500),
  deploy_status VARCHAR(50)                        -- pending|success|failed
);

-- Indexes for performance
CREATE INDEX idx_pb_pages_tenant_slug ON pb_pages(tenant_id, slug);
CREATE INDEX idx_pb_pages_status ON pb_pages(status);
CREATE INDEX idx_pb_pages_published ON pb_pages(published_at) WHERE status = 'published';
CREATE INDEX idx_pb_pages_components_gin ON pb_pages USING gin(components);
CREATE INDEX idx_pb_templates_category ON pb_templates(category);
CREATE INDEX idx_pb_custom_blocks_tenant ON pb_custom_blocks(tenant_id);

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_pb_pages_updated_at BEFORE UPDATE ON pb_pages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pb_templates_updated_at BEFORE UPDATE ON pb_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pb_custom_blocks_updated_at BEFORE UPDATE ON pb_custom_blocks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE pb_pages IS 'Stores page content as GrapesJS JSON with versioning';
COMMENT ON COLUMN pb_pages.components IS 'GrapesJS component tree (JSONB for queryability)';
COMMENT ON COLUMN pb_pages.data_bindings IS 'Maps {{variable}} placeholders to data sources';
COMMENT ON TABLE pb_templates IS 'Reusable page templates for quick page creation';
COMMENT ON TABLE pb_custom_blocks IS 'Tenant-specific custom block library';
