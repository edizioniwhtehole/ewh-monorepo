-- Page Builder System Migration
-- Elementor-style visual page builder with database-driven pages

-- Create schema
CREATE SCHEMA IF NOT EXISTS cms;

-- Pages table
CREATE TABLE cms.pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,

  -- Context: where this page is used
  context VARCHAR(50) NOT NULL DEFAULT 'internal', -- 'admin' | 'tenant' | 'public'
  tenant_id UUID REFERENCES auth.tenants(id),

  -- Page structure (Elementor elements)
  elements JSONB DEFAULT '[]',

  -- Page settings
  settings JSONB DEFAULT '{"layout": "full-width"}',

  -- Metadata
  published BOOLEAN DEFAULT FALSE,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),

  UNIQUE(slug, context, tenant_id)
);

CREATE INDEX idx_pages_context ON cms.pages(context);
CREATE INDEX idx_pages_tenant ON cms.pages(tenant_id);
CREATE INDEX idx_pages_slug ON cms.pages(slug);

-- Page versions (history)
CREATE TABLE cms.page_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID REFERENCES cms.pages(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  elements JSONB NOT NULL,
  settings JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX idx_page_versions_page ON cms.page_versions(page_id);

-- Menus table
CREATE TABLE cms.menus (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  location VARCHAR(100) NOT NULL, -- 'header' | 'footer' | 'sidebar'
  context VARCHAR(50) NOT NULL,
  tenant_id UUID REFERENCES auth.tenants(id),
  items JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(location, context, tenant_id)
);

CREATE INDEX idx_menus_context ON cms.menus(context);

COMMENT ON TABLE cms.pages IS 'Database-driven pages with Elementor-style builder';
COMMENT ON TABLE cms.page_versions IS 'Version history for pages';
COMMENT ON TABLE cms.menus IS 'Navigation menus';
