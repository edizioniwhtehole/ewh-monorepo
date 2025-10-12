-- ============================================================================
-- TENANT PLANS & DATA ISOLATION CONFIGURATION (FIXED)
-- Sistema flessibile per scegliere livello di isolamento dati per tenant
-- ============================================================================

-- Create tenants table if it doesn't exist
CREATE TABLE IF NOT EXISTS platform.tenants (
  tenant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SUBSCRIPTION PLANS
-- Definisce i piani disponibili con feature e prezzi
-- ============================================================================
CREATE TABLE platform.subscription_plans (
  plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Plan Identity
  slug TEXT UNIQUE NOT NULL, -- 'starter', 'professional', 'business', 'enterprise'
  name TEXT NOT NULL,
  description TEXT,

  -- Pricing
  price_monthly DECIMAL(10, 2),
  price_yearly DECIMAL(10, 2),
  currency TEXT DEFAULT 'USD',

  -- Data Isolation Level
  isolation_level TEXT NOT NULL CHECK (isolation_level IN ('shared', 'dedicated_schema', 'dedicated_database')),

  -- Quotas & Limits
  quotas JSONB DEFAULT '{
    "max_sites": 1,
    "max_users": 10,
    "max_pages": 100,
    "max_posts": 500,
    "max_storage_gb": 10,
    "max_bandwidth_gb": 100,
    "max_api_calls_per_day": 10000,
    "max_custom_domains": 1,
    "max_languages": 2
  }'::jsonb,

  -- Features
  features JSONB DEFAULT '{
    "custom_domains": false,
    "ssl_auto": false,
    "advanced_analytics": false,
    "priority_support": false,
    "white_labeling": false,
    "api_access": false,
    "webhooks": false,
    "custom_post_types": false,
    "multisite": false,
    "backup_daily": false,
    "backup_hourly": false,
    "cdn": false,
    "custom_code": false,
    "team_collaboration": false
  }'::jsonb,

  -- Technical Specs
  db_specs JSONB DEFAULT '{
    "connection_pool_size": 10,
    "backup_frequency": "daily",
    "backup_retention_days": 7,
    "replication": false,
    "point_in_time_recovery": false
  }'::jsonb,

  -- Display
  is_popular BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  display_order INT DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_subscription_plans_slug ON platform.subscription_plans(slug);
CREATE INDEX idx_subscription_plans_isolation ON platform.subscription_plans(isolation_level);

-- ============================================================================
-- TENANT SUBSCRIPTIONS
-- Collega tenants ai piani con possibilità di override
-- ============================================================================
CREATE TABLE platform.tenant_subscriptions (
  subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL UNIQUE REFERENCES platform.tenants(tenant_id), -- Un subscription per tenant

  -- Current Plan
  plan_id UUID NOT NULL REFERENCES platform.subscription_plans(plan_id),

  -- Billing
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'trial', 'suspended', 'cancelled', 'expired')),
  billing_cycle TEXT DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),

  -- Trial
  trial_ends_at TIMESTAMPTZ,
  is_trial BOOLEAN DEFAULT FALSE,

  -- Dates
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  current_period_start TIMESTAMPTZ DEFAULT NOW(),
  current_period_end TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,

  -- Quota Overrides (NULL = usa valori dal plan)
  quota_overrides JSONB,

  -- Feature Overrides (NULL = usa valori dal plan)
  feature_overrides JSONB,

  -- Custom Pricing (per enterprise deals)
  custom_price_monthly DECIMAL(10, 2),
  custom_price_yearly DECIMAL(10, 2),

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tenant_subscriptions_tenant ON platform.tenant_subscriptions(tenant_id);
CREATE INDEX idx_tenant_subscriptions_plan ON platform.tenant_subscriptions(plan_id);
CREATE INDEX idx_tenant_subscriptions_status ON platform.tenant_subscriptions(status);

-- ============================================================================
-- TENANT DATABASE CONFIGURATION
-- Configurazione tecnica del database/schema per tenant
-- ============================================================================
CREATE TABLE platform.tenant_database_config (
  config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL UNIQUE REFERENCES platform.tenants(tenant_id),

  -- Isolation Strategy (from subscription plan)
  isolation_level TEXT NOT NULL CHECK (isolation_level IN ('shared', 'dedicated_schema', 'dedicated_database')),

  -- For 'shared' isolation
  -- Data stored in: cms.* tables with tenant_id filtering

  -- For 'dedicated_schema' isolation
  schema_name TEXT, -- 'tenant_abc123'

  -- For 'dedicated_database' isolation
  db_host TEXT,
  db_port INT DEFAULT 5432,
  db_name TEXT,
  db_schema TEXT DEFAULT 'public',

  -- Encrypted credentials (for dedicated DB)
  db_user_encrypted TEXT,
  db_password_encrypted TEXT,
  encryption_key_id TEXT,

  -- Connection Pool Config
  pool_min INT DEFAULT 2,
  pool_max INT DEFAULT 10,
  pool_idle_timeout_ms INT DEFAULT 10000,

  -- Database Status
  provisioning_status TEXT DEFAULT 'pending' CHECK (provisioning_status IN ('pending', 'provisioning', 'active', 'migrating', 'failed')),
  provisioned_at TIMESTAMPTZ,
  last_migration_at TIMESTAMPTZ,

  -- Backup Configuration
  backup_enabled BOOLEAN DEFAULT TRUE,
  backup_frequency TEXT DEFAULT 'daily' CHECK (backup_frequency IN ('hourly', 'daily', 'weekly')),
  backup_retention_days INT DEFAULT 7,
  last_backup_at TIMESTAMPTZ,

  -- Storage Metrics
  db_size_bytes BIGINT DEFAULT 0,
  table_count INT DEFAULT 0,
  row_count_estimate BIGINT DEFAULT 0,

  -- Performance
  connection_count_current INT DEFAULT 0,
  query_performance_stats JSONB,

  -- Maintenance
  last_vacuum_at TIMESTAMPTZ,
  last_analyze_at TIMESTAMPTZ,

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tenant_db_config_tenant ON platform.tenant_database_config(tenant_id);
CREATE INDEX idx_tenant_db_config_isolation ON platform.tenant_database_config(isolation_level);
CREATE INDEX idx_tenant_db_config_status ON platform.tenant_database_config(provisioning_status);

-- ============================================================================
-- TENANT USAGE TRACKING
-- Traccia utilizzo per enforcement quotas e billing
-- ============================================================================
CREATE TABLE platform.tenant_usage (
  usage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES platform.tenants(tenant_id),

  -- Period
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,

  -- Resource Usage
  usage_metrics JSONB NOT NULL DEFAULT '{
    "sites_count": 0,
    "users_count": 0,
    "pages_count": 0,
    "posts_count": 0,
    "storage_bytes": 0,
    "bandwidth_bytes": 0,
    "api_calls": 0,
    "custom_domains": 0,
    "languages_count": 0
  }'::jsonb,

  -- Billing
  amount_due DECIMAL(10, 2) DEFAULT 0,
  is_billed BOOLEAN DEFAULT FALSE,
  billed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tenant_usage_tenant ON platform.tenant_usage(tenant_id);
CREATE INDEX idx_tenant_usage_period ON platform.tenant_usage(period_start, period_end);
CREATE INDEX idx_tenant_usage_billed ON platform.tenant_usage(is_billed);

-- ============================================================================
-- PLAN MIGRATION HISTORY
-- Track quando tenant cambia plan
-- ============================================================================
CREATE TABLE platform.plan_migrations (
  migration_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES platform.tenants(tenant_id),

  -- Migration Details
  from_plan_id UUID REFERENCES platform.subscription_plans(plan_id),
  to_plan_id UUID NOT NULL REFERENCES platform.subscription_plans(plan_id),

  -- Isolation Change
  from_isolation TEXT,
  to_isolation TEXT,

  -- Migration Process
  migration_type TEXT CHECK (migration_type IN ('upgrade', 'downgrade', 'change')),
  migration_status TEXT DEFAULT 'pending' CHECK (migration_status IN ('pending', 'in_progress', 'completed', 'failed', 'rolled_back')),

  -- Technical Migration (if isolation changes)
  requires_data_migration BOOLEAN DEFAULT FALSE,
  data_migration_started_at TIMESTAMPTZ,
  data_migration_completed_at TIMESTAMPTZ,
  data_migration_error TEXT,

  -- Timestamps
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  requested_by UUID,

  -- Metadata
  notes TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_plan_migrations_tenant ON platform.plan_migrations(tenant_id);
CREATE INDEX idx_plan_migrations_status ON platform.plan_migrations(migration_status);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Update updated_at timestamp
CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON platform.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION platform.update_updated_at_column();

CREATE TRIGGER update_tenant_subscriptions_updated_at BEFORE UPDATE ON platform.tenant_subscriptions
  FOR EACH ROW EXECUTE FUNCTION platform.update_updated_at_column();

CREATE TRIGGER update_tenant_db_config_updated_at BEFORE UPDATE ON platform.tenant_database_config
  FOR EACH ROW EXECUTE FUNCTION platform.update_updated_at_column();

-- Auto-create database config when subscription is created
CREATE OR REPLACE FUNCTION platform.create_tenant_database_config()
RETURNS TRIGGER AS $$
DECLARE
  plan_isolation TEXT;
BEGIN
  -- Get isolation level from plan
  SELECT isolation_level INTO plan_isolation
  FROM platform.subscription_plans
  WHERE plan_id = NEW.plan_id;

  -- Create database config
  INSERT INTO platform.tenant_database_config (
    tenant_id,
    isolation_level,
    schema_name,
    provisioning_status
  ) VALUES (
    NEW.tenant_id,
    plan_isolation,
    CASE
      WHEN plan_isolation = 'dedicated_schema' THEN 'tenant_' || REPLACE(NEW.tenant_id::TEXT, '-', '_')
      ELSE NULL
    END,
    'pending'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_tenant_db_config_trigger
  AFTER INSERT ON platform.tenant_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION platform.create_tenant_database_config();

-- Check quota limits
CREATE OR REPLACE FUNCTION platform.check_quota_limit(
  p_tenant_id UUID,
  p_quota_name TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  current_usage INT;
  quota_limit INT;
  quota_path TEXT;
BEGIN
  -- Get current usage
  quota_path := 'usage_metrics.' || p_quota_name;

  SELECT (usage_metrics->>p_quota_name)::INT INTO current_usage
  FROM platform.tenant_usage
  WHERE tenant_id = p_tenant_id
    AND period_end > NOW()
  ORDER BY period_start DESC
  LIMIT 1;

  -- Get quota limit from subscription (with overrides)
  SELECT COALESCE(
    (ts.quota_overrides->>p_quota_name)::INT,
    (sp.quotas->>p_quota_name)::INT
  ) INTO quota_limit
  FROM platform.tenant_subscriptions ts
  JOIN platform.subscription_plans sp ON ts.plan_id = sp.plan_id
  WHERE ts.tenant_id = p_tenant_id;

  -- Return true if under limit
  RETURN COALESCE(current_usage, 0) < COALESCE(quota_limit, 999999);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEED DATA - Default Plans
-- ============================================================================

INSERT INTO platform.subscription_plans (slug, name, description, price_monthly, price_yearly, isolation_level, quotas, features, is_popular) VALUES

-- STARTER (Shared Tables)
(
  'starter',
  'Starter',
  'Perfect for trying out the platform',
  9.99,
  99.99,
  'shared',
  '{
    "max_sites": 1,
    "max_users": 5,
    "max_pages": 50,
    "max_posts": 200,
    "max_storage_gb": 5,
    "max_bandwidth_gb": 50,
    "max_api_calls_per_day": 5000,
    "max_custom_domains": 0,
    "max_languages": 1
  }'::jsonb,
  '{
    "custom_domains": false,
    "ssl_auto": true,
    "advanced_analytics": false,
    "priority_support": false,
    "white_labeling": false,
    "api_access": false,
    "webhooks": false,
    "custom_post_types": false,
    "multisite": false,
    "backup_daily": true,
    "backup_hourly": false,
    "cdn": false,
    "custom_code": false,
    "team_collaboration": false
  }'::jsonb,
  FALSE
),

-- PROFESSIONAL (Dedicated Schema)
(
  'professional',
  'Professional',
  'For growing businesses',
  49.99,
  499.99,
  'dedicated_schema',
  '{
    "max_sites": 5,
    "max_users": 25,
    "max_pages": 500,
    "max_posts": 2000,
    "max_storage_gb": 50,
    "max_bandwidth_gb": 500,
    "max_api_calls_per_day": 50000,
    "max_custom_domains": 5,
    "max_languages": 5
  }'::jsonb,
  '{
    "custom_domains": true,
    "ssl_auto": true,
    "advanced_analytics": true,
    "priority_support": false,
    "white_labeling": false,
    "api_access": true,
    "webhooks": true,
    "custom_post_types": true,
    "multisite": true,
    "backup_daily": true,
    "backup_hourly": false,
    "cdn": true,
    "custom_code": false,
    "team_collaboration": true
  }'::jsonb,
  TRUE
),

-- BUSINESS (Dedicated Schema + Enhanced Features)
(
  'business',
  'Business',
  'For established companies',
  149.99,
  1499.99,
  'dedicated_schema',
  '{
    "max_sites": 20,
    "max_users": 100,
    "max_pages": 2000,
    "max_posts": 10000,
    "max_storage_gb": 200,
    "max_bandwidth_gb": 2000,
    "max_api_calls_per_day": 200000,
    "max_custom_domains": 20,
    "max_languages": -1
  }'::jsonb,
  '{
    "custom_domains": true,
    "ssl_auto": true,
    "advanced_analytics": true,
    "priority_support": true,
    "white_labeling": true,
    "api_access": true,
    "webhooks": true,
    "custom_post_types": true,
    "multisite": true,
    "backup_daily": true,
    "backup_hourly": true,
    "cdn": true,
    "custom_code": true,
    "team_collaboration": true
  }'::jsonb,
  FALSE
),

-- ENTERPRISE (Dedicated Database)
(
  'enterprise',
  'Enterprise',
  'For large organizations with dedicated infrastructure',
  NULL, -- Custom pricing
  NULL,
  'dedicated_database',
  '{
    "max_sites": -1,
    "max_users": -1,
    "max_pages": -1,
    "max_posts": -1,
    "max_storage_gb": -1,
    "max_bandwidth_gb": -1,
    "max_api_calls_per_day": -1,
    "max_custom_domains": -1,
    "max_languages": -1
  }'::jsonb,
  '{
    "custom_domains": true,
    "ssl_auto": true,
    "advanced_analytics": true,
    "priority_support": true,
    "white_labeling": true,
    "api_access": true,
    "webhooks": true,
    "custom_post_types": true,
    "multisite": true,
    "backup_daily": true,
    "backup_hourly": true,
    "cdn": true,
    "custom_code": true,
    "team_collaboration": true
  }'::jsonb,
  FALSE
);

-- ============================================================================
-- VIEWS - Consolidated tenant info
-- ============================================================================

CREATE VIEW platform.v_tenant_info AS
SELECT
  t.tenant_id,
  t.name as tenant_name,

  -- Subscription
  ts.subscription_id,
  sp.slug as plan_slug,
  sp.name as plan_name,
  ts.status as subscription_status,
  ts.is_trial,
  ts.trial_ends_at,

  -- Isolation
  tdc.isolation_level,
  tdc.schema_name,
  tdc.db_name,
  tdc.provisioning_status,

  -- Quotas (merged with overrides)
  COALESCE(ts.quota_overrides, sp.quotas) as quotas,

  -- Features (merged with overrides)
  COALESCE(ts.feature_overrides, sp.features) as features,

  -- Usage
  tu.usage_metrics as current_usage,

  -- Dates
  ts.current_period_start,
  ts.current_period_end

FROM platform.tenants t
LEFT JOIN platform.tenant_subscriptions ts ON t.tenant_id = ts.tenant_id
LEFT JOIN platform.subscription_plans sp ON ts.plan_id = sp.plan_id
LEFT JOIN platform.tenant_database_config tdc ON t.tenant_id = tdc.tenant_id
LEFT JOIN LATERAL (
  SELECT usage_metrics
  FROM platform.tenant_usage
  WHERE tenant_id = t.tenant_id
    AND period_end > NOW()
  ORDER BY period_start DESC
  LIMIT 1
) tu ON TRUE;

COMMENT ON VIEW platform.v_tenant_info IS 'Consolidated view of tenant subscription, quotas, and usage';

-- ============================================================================
-- GRANTS
-- ============================================================================
GRANT ALL ON ALL TABLES IN SCHEMA platform TO ewh;
GRANT ALL ON ALL SEQUENCES IN SCHEMA platform TO ewh;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA platform TO ewh;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE platform.subscription_plans IS 'Definisce i piani con feature, quotas e livello di isolamento';
COMMENT ON TABLE platform.tenant_subscriptions IS 'Collega tenants ai piani con possibilità di override personalizzati';
COMMENT ON TABLE platform.tenant_database_config IS 'Configurazione tecnica database/schema per tenant';
COMMENT ON TABLE platform.tenant_usage IS 'Tracciamento utilizzo risorse per enforcement quotas';
COMMENT ON TABLE platform.plan_migrations IS 'Storia migrazioni tra piani (incluso cambio isolamento)';

COMMENT ON COLUMN platform.tenant_subscriptions.quota_overrides IS 'Override personalizzati delle quota (NULL = usa valori dal plan)';
COMMENT ON COLUMN platform.tenant_subscriptions.feature_overrides IS 'Override personalizzati delle features (NULL = usa valori dal plan)';
COMMENT ON COLUMN platform.tenant_database_config.isolation_level IS 'shared = tabelle condivise | dedicated_schema = schema dedicato | dedicated_database = database dedicato';
