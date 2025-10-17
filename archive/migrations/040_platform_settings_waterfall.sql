-- =====================================================
-- SETTINGS WATERFALL SYSTEM
-- 3-Tier: Platform (Owner) → Tenant → User
-- =====================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS platform;

-- =====================================================
-- PLATFORM SETTINGS (Owner Level)
-- =====================================================

CREATE TABLE IF NOT EXISTS platform.settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Setting identification
  setting_key VARCHAR(255) UNIQUE NOT NULL,
  setting_value JSONB NOT NULL,
  value_type VARCHAR(50) NOT NULL,  -- 'string', 'number', 'boolean', 'object', 'array'

  -- Locking mechanism
  is_locked BOOLEAN DEFAULT false,
  lock_type VARCHAR(20) DEFAULT 'none',  -- 'none', 'hard', 'soft'
  lock_message TEXT,

  -- Categorization
  category VARCHAR(100) NOT NULL,  -- 'security', 'features', 'branding', 'limits', 'billing'
  service_name VARCHAR(100),  -- NULL = platform-wide, else specific service

  -- Metadata
  description TEXT,
  default_value JSONB,
  validation_schema JSONB,  -- JSON Schema for validation

  -- Audit
  created_by UUID,
  updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_platform_settings_key ON platform.settings(setting_key);
CREATE INDEX idx_platform_settings_category ON platform.settings(category);
CREATE INDEX idx_platform_settings_service ON platform.settings(service_name) WHERE service_name IS NOT NULL;

-- =====================================================
-- TENANT SETTINGS (Organization Level)
-- =====================================================

CREATE TABLE IF NOT EXISTS platform.tenant_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Tenant reference
  tenant_id UUID NOT NULL,

  -- Setting identification
  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,

  -- Inheritance
  inherits_from VARCHAR(50) DEFAULT 'platform',  -- 'platform', 'none'
  override_platform BOOLEAN DEFAULT false,

  -- Locking for users
  is_locked BOOLEAN DEFAULT false,
  lock_type VARCHAR(20) DEFAULT 'none',
  lock_message TEXT,

  -- Categorization
  category VARCHAR(100),
  service_name VARCHAR(100),

  -- Audit
  updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, setting_key)
);

CREATE INDEX idx_tenant_settings_tenant ON platform.tenant_settings(tenant_id);
CREATE INDEX idx_tenant_settings_key ON platform.tenant_settings(setting_key);
CREATE INDEX idx_tenant_settings_service ON platform.tenant_settings(service_name) WHERE service_name IS NOT NULL;

-- =====================================================
-- USER SETTINGS (Individual Level)
-- =====================================================

CREATE TABLE IF NOT EXISTS platform.user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- User reference
  user_id UUID NOT NULL,
  tenant_id UUID NOT NULL,

  -- Setting identification
  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,

  -- Inheritance
  inherits_from VARCHAR(50) DEFAULT 'tenant',  -- 'tenant', 'platform', 'none'
  override_tenant BOOLEAN DEFAULT false,
  override_platform BOOLEAN DEFAULT false,

  -- Categorization
  category VARCHAR(100),
  service_name VARCHAR(100),

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, tenant_id, setting_key)
);

CREATE INDEX idx_user_settings_user ON platform.user_settings(user_id);
CREATE INDEX idx_user_settings_tenant ON platform.user_settings(tenant_id);
CREATE INDEX idx_user_settings_key ON platform.user_settings(setting_key);

-- =====================================================
-- SETTINGS RESOLUTION FUNCTION (Waterfall Algorithm)
-- =====================================================

CREATE OR REPLACE FUNCTION platform.resolve_setting(
  p_setting_key VARCHAR,
  p_user_id UUID DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_platform_setting RECORD;
  v_tenant_setting RECORD;
  v_user_setting RECORD;
  v_value JSONB;
  v_source VARCHAR(20);
  v_is_locked BOOLEAN := false;
  v_can_override BOOLEAN := true;
BEGIN
  -- Step 1: Get platform default
  SELECT
    setting_value,
    is_locked,
    lock_type
  INTO v_platform_setting
  FROM platform.settings
  WHERE setting_key = p_setting_key;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'found', false,
      'error', 'Setting not found'
    );
  END IF;

  v_value := v_platform_setting.setting_value;
  v_source := 'platform';
  v_is_locked := v_platform_setting.is_locked;

  -- Step 2: Apply tenant override (if not locked)
  IF p_tenant_id IS NOT NULL AND NOT v_is_locked THEN
    SELECT
      setting_value,
      override_platform,
      is_locked,
      lock_type
    INTO v_tenant_setting
    FROM platform.tenant_settings
    WHERE tenant_id = p_tenant_id
      AND setting_key = p_setting_key;

    IF FOUND AND v_tenant_setting.override_platform THEN
      v_value := v_tenant_setting.setting_value;
      v_source := 'tenant';
      v_is_locked := v_tenant_setting.is_locked;
    END IF;
  END IF;

  -- Step 3: Apply user override (if not locked)
  IF p_user_id IS NOT NULL AND NOT v_is_locked THEN
    SELECT
      setting_value,
      override_tenant
    INTO v_user_setting
    FROM platform.user_settings
    WHERE user_id = p_user_id
      AND tenant_id = p_tenant_id
      AND setting_key = p_setting_key;

    IF FOUND AND v_user_setting.override_tenant THEN
      v_value := v_user_setting.setting_value;
      v_source := 'user';
    END IF;
  END IF;

  -- Determine if can override
  v_can_override := NOT v_is_locked OR
                    (v_is_locked AND
                     COALESCE(v_platform_setting.lock_type,
                              v_tenant_setting.lock_type,
                              'hard') = 'soft');

  -- Build result
  v_result := jsonb_build_object(
    'found', true,
    'value', v_value,
    'source', v_source,
    'is_locked', v_is_locked,
    'can_override', v_can_override
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEED DEFAULT PLATFORM SETTINGS
-- =====================================================

INSERT INTO platform.settings (setting_key, setting_value, value_type, category, description, is_locked, lock_type) VALUES
  -- Security Settings
  ('security.require_2fa', 'false', 'boolean', 'security', 'Require 2FA for all users', false, 'none'),
  ('security.password_min_length', '8', 'number', 'security', 'Minimum password length', true, 'hard'),
  ('security.session_timeout_minutes', '60', 'number', 'security', 'Session timeout in minutes', false, 'soft'),
  ('security.max_login_attempts', '5', 'number', 'security', 'Maximum failed login attempts before lockout', true, 'hard'),

  -- Platform Limits
  ('limits.max_users_per_tenant', '50', 'number', 'limits', 'Maximum users per tenant', true, 'hard'),
  ('limits.max_projects_per_tenant', '1000', 'number', 'limits', 'Maximum projects per tenant', true, 'hard'),
  ('limits.max_storage_gb', '100', 'number', 'limits', 'Maximum storage per tenant (GB)', true, 'hard'),
  ('limits.api_rate_limit_per_hour', '1000', 'number', 'limits', 'API rate limit per hour', true, 'hard'),

  -- Features
  ('features.pm_enabled', 'true', 'boolean', 'features', 'Enable Project Management', false, 'none'),
  ('features.crm_enabled', 'true', 'boolean', 'features', 'Enable CRM', false, 'none'),
  ('features.inventory_enabled', 'true', 'boolean', 'features', 'Enable Inventory Management', false, 'none'),
  ('features.ai_assistant_enabled', 'true', 'boolean', 'features', 'Enable AI Assistant', false, 'soft'),

  -- Branding
  ('branding.platform_name', '"EWH Platform"', 'string', 'branding', 'Platform name', false, 'none'),
  ('branding.primary_color', '"#1f6feb"', 'string', 'branding', 'Primary brand color', false, 'none'),
  ('branding.allow_tenant_branding', 'true', 'boolean', 'branding', 'Allow tenants to customize branding', false, 'none'),

  -- Defaults
  ('defaults.language', '"en"', 'string', 'defaults', 'Default language', false, 'none'),
  ('defaults.timezone', '"UTC"', 'string', 'defaults', 'Default timezone', false, 'none'),
  ('defaults.currency', '"USD"', 'string', 'defaults', 'Default currency', false, 'none'),
  ('defaults.date_format', '"YYYY-MM-DD"', 'string', 'defaults', 'Default date format', false, 'none')
ON CONFLICT (setting_key) DO NOTHING;

-- =====================================================
-- VIEWS FOR EASY ACCESS
-- =====================================================

-- View: All platform settings by category
CREATE OR REPLACE VIEW platform.v_settings_by_category AS
SELECT
  category,
  COUNT(*) as setting_count,
  COUNT(*) FILTER (WHERE is_locked = true) as locked_count,
  jsonb_agg(
    jsonb_build_object(
      'key', setting_key,
      'value', setting_value,
      'is_locked', is_locked,
      'description', description
    )
  ) as settings
FROM platform.settings
GROUP BY category;

-- View: Tenant settings with inheritance
CREATE OR REPLACE VIEW platform.v_tenant_settings_resolved AS
SELECT
  ts.tenant_id,
  ts.setting_key,
  COALESCE(ts.setting_value, ps.setting_value) as resolved_value,
  CASE
    WHEN ts.override_platform THEN 'tenant'
    ELSE 'platform'
  END as value_source,
  COALESCE(ts.is_locked, ps.is_locked, false) as is_locked,
  ps.category,
  ps.service_name
FROM platform.settings ps
LEFT JOIN platform.tenant_settings ts ON ps.setting_key = ts.setting_key
WHERE ts.tenant_id IS NOT NULL;

COMMENT ON TABLE platform.settings IS 'Platform-wide settings (owner level)';
COMMENT ON TABLE platform.tenant_settings IS 'Tenant-specific settings with inheritance';
COMMENT ON TABLE platform.user_settings IS 'User-specific settings with inheritance';
COMMENT ON FUNCTION platform.resolve_setting IS 'Resolves setting value with waterfall inheritance';
