-- Settings Waterfall System
-- To be applied to ALL services

-- Platform-wide settings (admin level)
CREATE TABLE IF NOT EXISTS platform_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key VARCHAR(255) UNIQUE NOT NULL,
  setting_value JSONB NOT NULL,
  value_type VARCHAR(50),
  is_locked BOOLEAN DEFAULT false,
  lock_type VARCHAR(20) DEFAULT 'none' CHECK (lock_type IN ('none', 'hard', 'soft')),
  lock_message TEXT,
  category VARCHAR(100),
  description TEXT,
  updated_by UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_platform_settings_key ON platform_settings(setting_key);
CREATE INDEX idx_platform_settings_category ON platform_settings(category);

-- Tenant settings
CREATE TABLE IF NOT EXISTS tenant_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,
  inherits_from VARCHAR(50) DEFAULT 'platform',
  override_platform BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT false,
  lock_type VARCHAR(20) DEFAULT 'none' CHECK (lock_type IN ('none', 'hard', 'soft')),
  lock_message TEXT,
  category VARCHAR(100),
  updated_by UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, setting_key)
);

CREATE INDEX idx_tenant_settings_tenant ON tenant_settings(tenant_id);
CREATE INDEX idx_tenant_settings_key ON tenant_settings(setting_key);

-- User settings
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  tenant_id UUID NOT NULL,
  setting_key VARCHAR(255) NOT NULL,
  setting_value JSONB NOT NULL,
  inherits_from VARCHAR(50) DEFAULT 'tenant',
  override_tenant BOOLEAN DEFAULT false,
  override_platform BOOLEAN DEFAULT false,
  category VARCHAR(100),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, tenant_id, setting_key)
);

CREATE INDEX idx_user_settings_user ON user_settings(user_id);
CREATE INDEX idx_user_settings_tenant ON user_settings(tenant_id);

-- Default platform settings
INSERT INTO platform_settings (setting_key, setting_value, value_type, category, description, is_locked) VALUES
('language', '"it"', 'string', 'general', 'Default platform language', false),
('timezone', '"Europe/Rome"', 'string', 'general', 'Default timezone', false),
('currency', '"EUR"', 'string', 'general', 'Default currency', false),
('date_format', '"DD/MM/YYYY"', 'string', 'general', 'Default date format', false),
('theme', '"light"', 'string', 'appearance', 'Default theme', false),
('session_timeout_minutes', '60', 'number', 'security', 'Session timeout in minutes', true),
('password_min_length', '8', 'number', 'security', 'Minimum password length', true),
('require_2fa', 'false', 'boolean', 'security', 'Require two-factor authentication', false)
ON CONFLICT (setting_key) DO NOTHING;

COMMENT ON TABLE platform_settings IS 'Platform-wide settings managed by owner';
COMMENT ON TABLE tenant_settings IS 'Tenant/organization settings with inheritance from platform';
COMMENT ON TABLE user_settings IS 'User-specific settings with inheritance from tenant';
