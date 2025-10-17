-- ============================================================================
-- CREATE PUBLIC VIEWS FOR API ACCESS
-- ============================================================================
-- Supabase API only exposes 'public' schema by default
-- We create views in public that point to our core tables
-- ============================================================================

-- Core tables views
CREATE OR REPLACE VIEW public.tenants AS SELECT * FROM core.tenants;
CREATE OR REPLACE VIEW public.apps_registry AS SELECT * FROM core.apps_registry;
CREATE OR REPLACE VIEW public.tenant_apps AS SELECT * FROM core.tenant_apps;
CREATE OR REPLACE VIEW public.schema_migrations AS SELECT * FROM core.schema_migrations;
CREATE OR REPLACE VIEW public.schema_versions AS SELECT * FROM core.schema_versions;

-- Analytics views (optional, for reading)
CREATE OR REPLACE VIEW public.analytics_events AS SELECT * FROM analytics.events;
CREATE OR REPLACE VIEW public.analytics_sessions AS SELECT * FROM analytics.sessions;
CREATE OR REPLACE VIEW public.analytics_metrics AS SELECT * FROM analytics.metrics;

-- Grant access to views
GRANT SELECT ON public.tenants TO anon, authenticated;
GRANT SELECT ON public.apps_registry TO anon, authenticated;
GRANT SELECT ON public.tenant_apps TO anon, authenticated;
GRANT SELECT ON public.schema_migrations TO anon, authenticated;
GRANT SELECT ON public.schema_versions TO anon, authenticated;
GRANT SELECT ON public.analytics_events TO anon, authenticated;
GRANT SELECT ON public.analytics_sessions TO anon, authenticated;
GRANT SELECT ON public.analytics_metrics TO anon, authenticated;

-- For tenant data, we'll use direct schema access or RPC functions
-- Create helper RPC function to query any schema
CREATE OR REPLACE FUNCTION public.query_tenant(
  tenant_slug TEXT,
  table_name TEXT,
  query_select TEXT DEFAULT '*',
  query_filter JSONB DEFAULT '{}'
) RETURNS JSONB AS $$
DECLARE
  result JSONB;
  sql_query TEXT;
BEGIN
  -- Build dynamic query
  sql_query := format('SELECT jsonb_agg(row_to_json(t)) FROM tenant_%s.%I t', tenant_slug, table_name);

  -- Execute and return
  EXECUTE sql_query INTO result;

  RETURN COALESCE(result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.query_tenant TO authenticated;

-- Helper to get tenant projects
CREATE OR REPLACE FUNCTION public.get_tenant_projects(tenant_slug TEXT)
RETURNS TABLE(id UUID, name TEXT, description TEXT, status TEXT, priority TEXT) AS $$
BEGIN
  RETURN QUERY EXECUTE format('SELECT id, name, description, status, priority FROM tenant_%s.pm_projects ORDER BY created_at DESC', tenant_slug);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_tenant_projects TO authenticated;

-- Helper to get tenant customers
CREATE OR REPLACE FUNCTION public.get_tenant_customers(tenant_slug TEXT)
RETURNS TABLE(id UUID, company_name TEXT, contact_name TEXT, email TEXT, status TEXT) AS $$
BEGIN
  RETURN QUERY EXECUTE format('SELECT id, company_name, contact_name, email, status FROM tenant_%s.crm_customers ORDER BY created_at DESC', tenant_slug);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_tenant_customers TO authenticated;

-- Success message
SELECT 'Public views and RPC functions created successfully!' as status;
