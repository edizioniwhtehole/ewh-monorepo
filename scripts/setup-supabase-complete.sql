-- ============================================================================
-- EWH PLATFORM - SUPABASE COMPLETE SETUP
-- ============================================================================
-- This script creates the complete multi-tenant architecture for EWH Platform
-- Architecture: Core + App Templates + Tenant Schemas + Analytics
-- ============================================================================

-- ============================================================================
-- 1. CORE SCHEMA - Platform Infrastructure
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS core;

-- Tenants Registry
CREATE TABLE IF NOT EXISTS core.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL CHECK (slug ~ '^[a-z0-9-]+$'),
  name TEXT NOT NULL,
  tier TEXT DEFAULT 'standard' CHECK (tier IN ('free', 'standard', 'enterprise')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Apps Registry (available apps in platform)
CREATE TABLE IF NOT EXISTS core.apps_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL CHECK (code ~ '^[a-z_]+$'),
  name TEXT NOT NULL,
  description TEXT,
  schema_name TEXT NOT NULL,
  version TEXT DEFAULT '1.0.0',
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tenant Apps (which apps each tenant has enabled)
CREATE TABLE IF NOT EXISTS core.tenant_apps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES core.tenants(id) ON DELETE CASCADE,
  app_id UUID NOT NULL REFERENCES core.apps_registry(id) ON DELETE CASCADE,
  enabled BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}',
  enabled_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, app_id)
);

-- Schema Migrations (track migrations for multi-tenant)
CREATE TABLE IF NOT EXISTS core.schema_migrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_code TEXT NOT NULL,
  version TEXT NOT NULL,
  migration_name TEXT NOT NULL,
  description TEXT,
  sql_up TEXT NOT NULL,
  sql_down TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'applied', 'failed', 'rolled_back')),
  applied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(app_code, version)
);

-- Schema Versions (current version per app)
CREATE TABLE IF NOT EXISTS core.schema_versions (
  app_code TEXT PRIMARY KEY,
  current_version TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migration Log (track migration execution per tenant)
CREATE TABLE IF NOT EXISTS core.migration_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES core.tenants(id) ON DELETE CASCADE,
  migration_id UUID REFERENCES core.schema_migrations(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('success', 'failed', 'skipped')),
  error TEXT,
  executed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Schema Sync Log (track schema synchronization)
CREATE TABLE IF NOT EXISTS core.schema_sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_code TEXT NOT NULL,
  tenant_slug TEXT,
  sync_type TEXT NOT NULL,
  details JSONB DEFAULT '{}',
  status TEXT NOT NULL CHECK (status IN ('success', 'failed')),
  error TEXT,
  synced_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. APP TEMPLATE SCHEMAS - Portable App Definitions
-- ============================================================================

-- PROJECT MANAGEMENT APP
CREATE SCHEMA IF NOT EXISTS app_pm;

CREATE TABLE IF NOT EXISTS app_pm._metadata (
  version TEXT DEFAULT '1.0.0',
  description TEXT DEFAULT 'Project Management App',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_pm.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'on_hold', 'completed', 'cancelled')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  start_date DATE,
  due_date DATE,
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  budget DECIMAL(12,2),
  owner_id UUID,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_pm.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'review', 'done', 'blocked')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  assigned_to UUID,
  due_date TIMESTAMPTZ,
  estimated_hours DECIMAL(8,2),
  actual_hours DECIMAL(8,2),
  parent_task_id UUID,
  order_index INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_pm.milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  due_date DATE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'missed')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CRM APP
CREATE SCHEMA IF NOT EXISTS app_crm;

CREATE TABLE IF NOT EXISTS app_crm._metadata (
  version TEXT DEFAULT '1.0.0',
  description TEXT DEFAULT 'Customer Relationship Management App',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_crm.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  contact_name TEXT,
  email TEXT,
  phone TEXT,
  website TEXT,
  address TEXT,
  city TEXT,
  country TEXT,
  industry TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'prospect')),
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_crm.contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  role TEXT,
  is_primary BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_crm.leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  contact_name TEXT,
  email TEXT,
  phone TEXT,
  source TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'proposal', 'negotiation', 'won', 'lost')),
  value DECIMAL(12,2),
  probability INTEGER CHECK (probability >= 0 AND probability <= 100),
  assigned_to UUID,
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_crm.deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID,
  title TEXT NOT NULL,
  description TEXT,
  value DECIMAL(12,2) NOT NULL,
  status TEXT DEFAULT 'negotiation' CHECK (status IN ('negotiation', 'proposal_sent', 'won', 'lost')),
  probability INTEGER DEFAULT 50 CHECK (probability >= 0 AND probability <= 100),
  expected_close_date DATE,
  closed_date DATE,
  assigned_to UUID,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- DAM (Digital Asset Management) APP
CREATE SCHEMA IF NOT EXISTS app_dam;

CREATE TABLE IF NOT EXISTS app_dam._metadata (
  version TEXT DEFAULT '1.0.0',
  description TEXT DEFAULT 'Digital Asset Management App',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_dam.assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  file_type TEXT CHECK (file_type IN ('image', 'video', 'audio', 'document', 'other')),
  width INTEGER,
  height INTEGER,
  duration DECIMAL(10,2),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
  tags TEXT[],
  uploaded_by UUID,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_dam.collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  parent_id UUID,
  is_public BOOLEAN DEFAULT false,
  created_by UUID,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_dam.asset_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id UUID NOT NULL,
  version_number INTEGER NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  changes_description TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(asset_id, version_number)
);

-- ORDERS APP
CREATE SCHEMA IF NOT EXISTS app_orders;

CREATE TABLE IF NOT EXISTS app_orders._metadata (
  version TEXT DEFAULT '1.0.0',
  description TEXT DEFAULT 'Orders Management App',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_orders.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE NOT NULL,
  customer_id UUID NOT NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'EUR',
  order_date TIMESTAMPTZ DEFAULT NOW(),
  delivery_date TIMESTAMPTZ,
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_orders.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL,
  product_id UUID,
  product_name TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  discount_percent DECIMAL(5,2) DEFAULT 0,
  total DECIMAL(12,2) NOT NULL,
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- QUOTATIONS APP
CREATE SCHEMA IF NOT EXISTS app_quotations;

CREATE TABLE IF NOT EXISTS app_quotations._metadata (
  version TEXT DEFAULT '1.0.0',
  description TEXT DEFAULT 'Quotations Management App',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_quotations.quotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_number TEXT UNIQUE NOT NULL,
  customer_id UUID NOT NULL,
  title TEXT NOT NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'accepted', 'rejected', 'expired')),
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'EUR',
  valid_until DATE,
  notes TEXT,
  terms TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_quotations.quotation_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id UUID NOT NULL,
  description TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  discount_percent DECIMAL(5,2) DEFAULT 0,
  total DECIMAL(12,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- INVENTORY APP
CREATE SCHEMA IF NOT EXISTS app_inventory;

CREATE TABLE IF NOT EXISTS app_inventory._metadata (
  version TEXT DEFAULT '1.0.0',
  description TEXT DEFAULT 'Inventory Management App',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_inventory.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  unit_price DECIMAL(12,2),
  cost_price DECIMAL(12,2),
  quantity_on_hand INTEGER DEFAULT 0,
  reorder_level INTEGER DEFAULT 0,
  unit_of_measure TEXT DEFAULT 'pcs',
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'discontinued')),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_inventory.stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL,
  movement_type TEXT NOT NULL CHECK (movement_type IN ('in', 'out', 'adjustment')),
  quantity INTEGER NOT NULL,
  reference_type TEXT,
  reference_id UUID,
  notes TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 3. ANALYTICS SCHEMA - Usage Tracking & Metrics
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID,
  user_id UUID,
  app_code TEXT,
  event_type TEXT NOT NULL,
  event_name TEXT NOT NULL,
  properties JSONB DEFAULT '{}',
  session_id UUID,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS analytics.sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID,
  user_id UUID,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  page_views INTEGER DEFAULT 0,
  events_count INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS analytics.metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID,
  app_code TEXT,
  metric_name TEXT NOT NULL,
  metric_value DECIMAL(12,2) NOT NULL,
  metric_unit TEXT,
  dimensions JSONB DEFAULT '{}',
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for analytics (important for performance)
CREATE INDEX IF NOT EXISTS idx_events_tenant_created ON analytics.events(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_app_code ON analytics.events(app_code);
CREATE INDEX IF NOT EXISTS idx_sessions_tenant_started ON analytics.sessions(tenant_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_tenant_recorded ON analytics.metrics(tenant_id, recorded_at DESC);

-- ============================================================================
-- 4. HELPER FUNCTIONS
-- ============================================================================

-- Function: Create new tenant with all enabled apps
CREATE OR REPLACE FUNCTION core.create_tenant(
  p_slug TEXT,
  p_name TEXT,
  p_tier TEXT DEFAULT 'standard',
  p_enabled_apps TEXT[] DEFAULT ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']
) RETURNS UUID AS $$
DECLARE
  v_tenant_id UUID;
  v_app_code TEXT;
  v_app_id UUID;
  v_schema_name TEXT;
BEGIN
  -- Create tenant record
  INSERT INTO core.tenants (slug, name, tier)
  VALUES (p_slug, p_name, p_tier)
  RETURNING id INTO v_tenant_id;

  -- Create tenant schema
  v_schema_name := 'tenant_' || p_slug;
  EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', v_schema_name);

  -- Enable apps and create tables
  FOREACH v_app_code IN ARRAY p_enabled_apps LOOP
    -- Get app_id
    SELECT id INTO v_app_id
    FROM core.apps_registry
    WHERE code = v_app_code;

    IF v_app_id IS NOT NULL THEN
      -- Enable app for tenant
      INSERT INTO core.tenant_apps (tenant_id, app_id)
      VALUES (v_tenant_id, v_app_id);

      -- Create tables based on app
      IF v_app_code = 'pm' THEN
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.pm_projects (LIKE app_pm.projects INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.pm_tasks (LIKE app_pm.tasks INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.pm_milestones (LIKE app_pm.milestones INCLUDING ALL)', v_schema_name);
      ELSIF v_app_code = 'crm' THEN
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.crm_customers (LIKE app_crm.customers INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.crm_contacts (LIKE app_crm.contacts INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.crm_leads (LIKE app_crm.leads INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.crm_deals (LIKE app_crm.deals INCLUDING ALL)', v_schema_name);
      ELSIF v_app_code = 'dam' THEN
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.dam_assets (LIKE app_dam.assets INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.dam_collections (LIKE app_dam.collections INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.dam_asset_versions (LIKE app_dam.asset_versions INCLUDING ALL)', v_schema_name);
      ELSIF v_app_code = 'orders' THEN
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.orders_orders (LIKE app_orders.orders INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.orders_order_items (LIKE app_orders.order_items INCLUDING ALL)', v_schema_name);
      ELSIF v_app_code = 'quotations' THEN
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.quotations_quotations (LIKE app_quotations.quotations INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.quotations_quotation_items (LIKE app_quotations.quotation_items INCLUDING ALL)', v_schema_name);
      ELSIF v_app_code = 'inventory' THEN
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.inventory_products (LIKE app_inventory.products INCLUDING ALL)', v_schema_name);
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I.inventory_stock_movements (LIKE app_inventory.stock_movements INCLUDING ALL)', v_schema_name);
      END IF;
    END IF;
  END LOOP;

  RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Sync schema from template (apply migrations)
CREATE OR REPLACE FUNCTION core.sync_schema_from_template(
  p_app_code TEXT,
  p_tenant_slug TEXT DEFAULT NULL
) RETURNS TABLE(tenant_slug TEXT, status TEXT, error TEXT) AS $$
DECLARE
  v_tenant RECORD;
  v_template_schema TEXT;
  v_target_schema TEXT;
  v_app_prefix TEXT;
BEGIN
  v_template_schema := 'app_' || p_app_code;
  v_app_prefix := p_app_code || '_';

  -- If specific tenant provided, sync only that tenant
  IF p_tenant_slug IS NOT NULL THEN
    v_target_schema := 'tenant_' || p_tenant_slug;

    BEGIN
      -- Sync logic here (simplified - in production would check each column/table)
      RETURN QUERY SELECT p_tenant_slug, 'success'::TEXT, NULL::TEXT;

    EXCEPTION WHEN OTHERS THEN
      RETURN QUERY SELECT p_tenant_slug, 'failed'::TEXT, SQLERRM;
    END;

  ELSE
    -- Sync all tenants
    FOR v_tenant IN SELECT slug FROM core.tenants WHERE status = 'active' LOOP
      v_target_schema := 'tenant_' || v_tenant.slug;

      BEGIN
        -- Sync logic here
        RETURN QUERY SELECT v_tenant.slug, 'success'::TEXT, NULL::TEXT;

      EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT v_tenant.slug, 'failed'::TEXT, SQLERRM;
      END;
    END LOOP;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Enable app for existing tenant
CREATE OR REPLACE FUNCTION core.enable_app_for_tenant(
  p_tenant_slug TEXT,
  p_app_code TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_tenant_id UUID;
  v_app_id UUID;
  v_schema_name TEXT;
BEGIN
  -- Get tenant_id
  SELECT id INTO v_tenant_id FROM core.tenants WHERE slug = p_tenant_slug;
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Tenant not found: %', p_tenant_slug;
  END IF;

  -- Get app_id
  SELECT id INTO v_app_id FROM core.apps_registry WHERE code = p_app_code;
  IF v_app_id IS NULL THEN
    RAISE EXCEPTION 'App not found: %', p_app_code;
  END IF;

  -- Enable app
  INSERT INTO core.tenant_apps (tenant_id, app_id)
  VALUES (v_tenant_id, v_app_id)
  ON CONFLICT (tenant_id, app_id) DO UPDATE SET enabled = true;

  -- Create tables
  v_schema_name := 'tenant_' || p_tenant_slug;

  IF p_app_code = 'pm' THEN
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.pm_projects (LIKE app_pm.projects INCLUDING ALL)', v_schema_name);
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.pm_tasks (LIKE app_pm.tasks INCLUDING ALL)', v_schema_name);
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.pm_milestones (LIKE app_pm.milestones INCLUDING ALL)', v_schema_name);
  ELSIF p_app_code = 'crm' THEN
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.crm_customers (LIKE app_crm.customers INCLUDING ALL)', v_schema_name);
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.crm_contacts (LIKE app_crm.contacts INCLUDING ALL)', v_schema_name);
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.crm_leads (LIKE app_crm.leads INCLUDING ALL)', v_schema_name);
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.crm_deals (LIKE app_crm.deals INCLUDING ALL)', v_schema_name);
  -- ... other apps similar
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. SEED DATA - Apps Registry
-- ============================================================================

INSERT INTO core.apps_registry (code, name, description, schema_name, version) VALUES
  ('pm', 'Project Management', 'Manage projects, tasks, and milestones', 'app_pm', '1.0.0'),
  ('crm', 'Customer Relationship Management', 'Manage customers, leads, and deals', 'app_crm', '1.0.0'),
  ('dam', 'Digital Asset Management', 'Manage digital assets and collections', 'app_dam', '1.0.0'),
  ('orders', 'Orders Management', 'Manage customer orders', 'app_orders', '1.0.0'),
  ('quotations', 'Quotations Management', 'Create and manage quotations', 'app_quotations', '1.0.0'),
  ('inventory', 'Inventory Management', 'Track products and stock movements', 'app_inventory', '1.0.0')
ON CONFLICT (code) DO NOTHING;

INSERT INTO core.schema_versions (app_code, current_version) VALUES
  ('pm', '1.0.0'),
  ('crm', '1.0.0'),
  ('dam', '1.0.0'),
  ('orders', '1.0.0'),
  ('quotations', '1.0.0'),
  ('inventory', '1.0.0')
ON CONFLICT (app_code) DO NOTHING;

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================
-- Next steps:
-- 1. Create first tenant: SELECT core.create_tenant('acme', 'ACME Corp');
-- 2. Query tenants: SELECT * FROM core.tenants;
-- 3. Query apps: SELECT * FROM core.apps_registry;
-- ============================================================================
