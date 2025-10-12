-- =====================================================
-- OAuth 2.0 Providers System
-- Manages third-party OAuth providers (Google, GitHub, Microsoft, etc.)
-- Includes infrastructure for future SMS/Email providers
-- =====================================================

-- OAuth Provider Configurations (Platform-wide)
CREATE TABLE IF NOT EXISTS auth.oauth_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Provider identity
  provider_key VARCHAR(50) NOT NULL UNIQUE,      -- google, github, microsoft, linkedin, facebook, apple
  provider_name VARCHAR(255) NOT NULL,
  provider_type VARCHAR(50) NOT NULL,            -- oauth2, saml, oidc

  -- OAuth configuration
  authorization_url TEXT,
  token_url TEXT,
  userinfo_url TEXT,
  jwks_url TEXT,                                 -- For OIDC
  revoke_url TEXT,

  -- Scopes
  default_scopes TEXT[] DEFAULT '{}',
  available_scopes TEXT[] DEFAULT '{}',

  -- Profile mapping (maps provider fields to our user fields)
  profile_mapping JSONB DEFAULT '{}',            -- {"email": "email", "name": "name", "picture": "avatar_url"}

  -- Icon & branding
  icon_url TEXT,
  button_text VARCHAR(100),                      -- "Continue with Google"
  primary_color VARCHAR(10),                     -- Hex color for button

  -- Status
  enabled BOOLEAN DEFAULT true,
  system_default BOOLEAN DEFAULT false,          -- Pre-configured providers (Google, GitHub)

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (provider_key ~ '^[a-z0-9_-]+$'),
  CHECK (provider_type IN ('oauth2', 'oidc', 'saml'))
);

CREATE UNIQUE INDEX idx_oauth_providers_key ON auth.oauth_providers(provider_key);
CREATE INDEX idx_oauth_providers_enabled ON auth.oauth_providers(enabled);

-- OAuth Provider Credentials (Per-Tenant or Platform-level)
CREATE TABLE IF NOT EXISTS auth.oauth_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  provider_id UUID NOT NULL REFERENCES auth.oauth_providers(id) ON DELETE CASCADE,

  -- Ownership (NULL tenant_id = platform-wide)
  tenant_id UUID,

  -- Credentials (encrypted in production)
  client_id VARCHAR(500) NOT NULL,
  client_secret VARCHAR(500) NOT NULL,           -- Should be encrypted at rest

  -- OAuth settings
  redirect_uri TEXT NOT NULL,
  scopes TEXT[] DEFAULT '{}',

  -- Status
  enabled BOOLEAN DEFAULT true,
  verified BOOLEAN DEFAULT false,                -- Admin must verify it works
  last_verified_at TIMESTAMP WITH TIME ZONE,

  -- Usage tracking
  total_logins INTEGER DEFAULT 0,
  last_used_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_oauth_credentials_provider ON auth.oauth_credentials(provider_id);
CREATE INDEX idx_oauth_credentials_tenant ON auth.oauth_credentials(tenant_id);
CREATE UNIQUE INDEX idx_oauth_credentials_tenant_provider ON auth.oauth_credentials(tenant_id, provider_id);

-- Linked OAuth accounts (users who logged in via OAuth)
CREATE TABLE IF NOT EXISTS auth.user_oauth_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id UUID NOT NULL,
  tenant_id UUID NOT NULL,

  provider_id UUID NOT NULL REFERENCES auth.oauth_providers(id) ON DELETE CASCADE,

  -- Provider user identity
  provider_user_id VARCHAR(500) NOT NULL,        -- ID from OAuth provider
  provider_username VARCHAR(255),
  provider_email VARCHAR(500),

  -- Profile data from provider
  profile_data JSONB DEFAULT '{}',

  -- Tokens (encrypted in production)
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMP WITH TIME ZONE,

  -- Status
  linked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE,
  login_count INTEGER DEFAULT 0,

  -- Primary OAuth account (if user has multiple)
  is_primary BOOLEAN DEFAULT false,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_oauth_accounts_user ON auth.user_oauth_accounts(user_id);
CREATE INDEX idx_user_oauth_accounts_provider ON auth.user_oauth_accounts(provider_id);
CREATE UNIQUE INDEX idx_user_oauth_accounts_provider_user ON auth.user_oauth_accounts(provider_id, provider_user_id);
CREATE INDEX idx_user_oauth_accounts_primary ON auth.user_oauth_accounts(user_id, is_primary) WHERE is_primary = true;

-- OAuth state tokens (for CSRF protection during OAuth flow)
CREATE TABLE IF NOT EXISTS auth.oauth_state_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  state_token VARCHAR(255) NOT NULL UNIQUE,
  provider_id UUID NOT NULL REFERENCES auth.oauth_providers(id) ON DELETE CASCADE,

  -- Original request context
  tenant_id UUID,
  redirect_after_login TEXT,                     -- Where to send user after OAuth
  metadata JSONB DEFAULT '{}',

  -- Security
  ip_address INET,
  user_agent TEXT,

  -- Expiration (OAuth states are short-lived)
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '15 minutes',
  used BOOLEAN DEFAULT false,
  used_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_oauth_state_tokens_state ON auth.oauth_state_tokens(state_token);
CREATE INDEX idx_oauth_state_tokens_expires ON auth.oauth_state_tokens(expires_at);
CREATE INDEX idx_oauth_state_tokens_unused ON auth.oauth_state_tokens(used) WHERE NOT used;

-- =====================================================
-- COMMUNICATION PROVIDERS (for future SMS/Email MFA)
-- =====================================================

-- Communication Provider Configurations
CREATE TABLE IF NOT EXISTS auth.communication_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  provider_key VARCHAR(50) NOT NULL UNIQUE,      -- sendgrid, twilio, aws_ses, mailgun, vonage
  provider_name VARCHAR(255) NOT NULL,
  provider_type VARCHAR(50) NOT NULL,            -- email, sms, both

  -- API configuration
  api_base_url TEXT,
  api_version VARCHAR(50),

  -- Status
  enabled BOOLEAN DEFAULT true,
  system_default BOOLEAN DEFAULT false,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (provider_key ~ '^[a-z0-9_-]+$'),
  CHECK (provider_type IN ('email', 'sms', 'both', 'push'))
);

CREATE UNIQUE INDEX idx_comm_providers_key ON auth.communication_providers(provider_key);
CREATE INDEX idx_comm_providers_type ON auth.communication_providers(provider_type);

-- Communication Provider Credentials (Per-Tenant or Platform-level)
CREATE TABLE IF NOT EXISTS auth.communication_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  provider_id UUID NOT NULL REFERENCES auth.communication_providers(id) ON DELETE CASCADE,

  -- Ownership (NULL tenant_id = platform-wide)
  tenant_id UUID,

  -- Credentials (encrypted in production)
  api_key VARCHAR(500),
  api_secret VARCHAR(500),
  account_sid VARCHAR(500),                      -- Twilio specific
  from_email VARCHAR(255),                       -- For email providers
  from_phone VARCHAR(50),                        -- For SMS providers
  from_name VARCHAR(255),

  -- Configuration
  metadata JSONB DEFAULT '{}',                   -- Provider-specific settings

  -- Status
  enabled BOOLEAN DEFAULT true,
  verified BOOLEAN DEFAULT false,
  last_verified_at TIMESTAMP WITH TIME ZONE,

  -- Usage tracking
  total_messages_sent INTEGER DEFAULT 0,
  last_used_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_comm_credentials_provider ON auth.communication_credentials(provider_id);
CREATE INDEX idx_comm_credentials_tenant ON auth.communication_credentials(tenant_id);
CREATE UNIQUE INDEX idx_comm_credentials_tenant_provider ON auth.communication_credentials(tenant_id, provider_id);

-- MFA delivery methods (links users to their preferred MFA method)
CREATE TABLE IF NOT EXISTS auth.user_mfa_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id UUID NOT NULL,
  tenant_id UUID NOT NULL,

  -- Method type
  method_type VARCHAR(50) NOT NULL,              -- totp, sms, email, backup_codes
  method_status VARCHAR(50) DEFAULT 'inactive',  -- active, inactive, pending_verification

  -- Delivery target (for sms/email)
  delivery_target VARCHAR(500),                  -- Phone number or email address
  delivery_target_verified BOOLEAN DEFAULT false,

  -- Priority (1 = primary method)
  priority INTEGER DEFAULT 99,

  -- Usage stats
  last_used_at TIMESTAMP WITH TIME ZONE,
  use_count INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (method_type IN ('totp', 'sms', 'email', 'backup_codes', 'webauthn', 'push')),
  CHECK (method_status IN ('active', 'inactive', 'pending_verification', 'disabled'))
);

CREATE INDEX idx_user_mfa_methods_user ON auth.user_mfa_methods(user_id);
CREATE INDEX idx_user_mfa_methods_type ON auth.user_mfa_methods(method_type);
CREATE INDEX idx_user_mfa_methods_status ON auth.user_mfa_methods(method_status);
CREATE UNIQUE INDEX idx_user_mfa_methods_user_type ON auth.user_mfa_methods(user_id, method_type);

-- Add OAuth columns to users table
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS oauth_provider_id UUID REFERENCES auth.oauth_providers(id);
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS oauth_linked BOOLEAN DEFAULT false;

-- =====================================================
-- SEED DEFAULT PROVIDERS
-- =====================================================

-- Seed OAuth providers
INSERT INTO auth.oauth_providers (
  provider_key, provider_name, provider_type,
  authorization_url, token_url, userinfo_url, jwks_url,
  default_scopes, profile_mapping,
  button_text, primary_color, system_default
) VALUES
  (
    'google',
    'Google',
    'oidc',
    'https://accounts.google.com/o/oauth2/v2/auth',
    'https://oauth2.googleapis.com/token',
    'https://www.googleapis.com/oauth2/v3/userinfo',
    'https://www.googleapis.com/oauth2/v3/certs',
    ARRAY['openid', 'email', 'profile'],
    '{"email": "email", "name": "name", "picture": "avatar_url", "given_name": "first_name", "family_name": "last_name"}'::jsonb,
    'Continue with Google',
    '#4285F4',
    true
  ),
  (
    'github',
    'GitHub',
    'oauth2',
    'https://github.com/login/oauth/authorize',
    'https://github.com/login/oauth/access_token',
    'https://api.github.com/user',
    NULL,
    ARRAY['user:email', 'read:user'],
    '{"email": "email", "name": "name", "avatar_url": "avatar_url", "login": "username"}'::jsonb,
    'Continue with GitHub',
    '#24292e',
    true
  ),
  (
    'microsoft',
    'Microsoft',
    'oidc',
    'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
    'https://login.microsoftonline.com/common/oauth2/v2.0/token',
    'https://graph.microsoft.com/v1.0/me',
    'https://login.microsoftonline.com/common/discovery/v2.0/keys',
    ARRAY['openid', 'email', 'profile'],
    '{"mail": "email", "displayName": "name", "givenName": "first_name", "surname": "last_name"}'::jsonb,
    'Continue with Microsoft',
    '#00A4EF',
    true
  ),
  (
    'linkedin',
    'LinkedIn',
    'oauth2',
    'https://www.linkedin.com/oauth/v2/authorization',
    'https://www.linkedin.com/oauth/v2/accessToken',
    'https://api.linkedin.com/v2/me',
    NULL,
    ARRAY['r_liteprofile', 'r_emailaddress'],
    '{"localizedFirstName": "first_name", "localizedLastName": "last_name"}'::jsonb,
    'Continue with LinkedIn',
    '#0077B5',
    true
  )
ON CONFLICT (provider_key) DO NOTHING;

-- Seed communication providers (for future use)
INSERT INTO auth.communication_providers (
  provider_key, provider_name, provider_type,
  api_base_url, system_default
) VALUES
  ('sendgrid', 'SendGrid', 'email', 'https://api.sendgrid.com/v3', true),
  ('twilio', 'Twilio', 'both', 'https://api.twilio.com/2010-04-01', true),
  ('aws_ses', 'AWS SES', 'email', 'https://email.us-east-1.amazonaws.com', true),
  ('mailgun', 'Mailgun', 'email', 'https://api.mailgun.net/v3', true),
  ('vonage', 'Vonage (Nexmo)', 'sms', 'https://rest.nexmo.com', true)
ON CONFLICT (provider_key) DO NOTHING;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get OAuth provider by key
CREATE OR REPLACE FUNCTION auth.get_oauth_provider(
  p_provider_key VARCHAR,
  p_tenant_id UUID DEFAULT NULL
)
RETURNS TABLE (
  provider_id UUID,
  provider_name VARCHAR,
  authorization_url TEXT,
  token_url TEXT,
  userinfo_url TEXT,
  client_id VARCHAR,
  client_secret VARCHAR,
  redirect_uri TEXT,
  scopes TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.provider_name,
    p.authorization_url,
    p.token_url,
    p.userinfo_url,
    c.client_id,
    c.client_secret,
    c.redirect_uri,
    COALESCE(c.scopes, p.default_scopes)
  FROM auth.oauth_providers p
  LEFT JOIN auth.oauth_credentials c ON c.provider_id = p.id
    AND (c.tenant_id = p_tenant_id OR c.tenant_id IS NULL)
    AND c.enabled = true
  WHERE p.provider_key = p_provider_key
    AND p.enabled = true
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to link OAuth account to user
CREATE OR REPLACE FUNCTION auth.link_oauth_account(
  p_user_id UUID,
  p_tenant_id UUID,
  p_provider_key VARCHAR,
  p_provider_user_id VARCHAR,
  p_provider_email VARCHAR,
  p_profile_data JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_provider_id UUID;
  v_oauth_account_id UUID;
BEGIN
  -- Get provider ID
  SELECT id INTO v_provider_id
  FROM auth.oauth_providers
  WHERE provider_key = p_provider_key;

  IF v_provider_id IS NULL THEN
    RAISE EXCEPTION 'OAuth provider not found: %', p_provider_key;
  END IF;

  -- Insert or update OAuth account
  INSERT INTO auth.user_oauth_accounts (
    user_id, tenant_id, provider_id,
    provider_user_id, provider_email, profile_data,
    last_login_at, login_count
  ) VALUES (
    p_user_id, p_tenant_id, v_provider_id,
    p_provider_user_id, p_provider_email, p_profile_data,
    NOW(), 1
  )
  ON CONFLICT (provider_id, provider_user_id)
  DO UPDATE SET
    last_login_at = NOW(),
    login_count = auth.user_oauth_accounts.login_count + 1,
    profile_data = p_profile_data,
    updated_at = NOW()
  RETURNING id INTO v_oauth_account_id;

  -- Update user OAuth flag
  UPDATE auth.users
  SET oauth_linked = true, oauth_provider_id = v_provider_id
  WHERE id = p_user_id;

  -- Update credential usage
  UPDATE auth.oauth_credentials
  SET
    total_logins = total_logins + 1,
    last_used_at = NOW()
  WHERE provider_id = v_provider_id
    AND (tenant_id = p_tenant_id OR tenant_id IS NULL);

  RETURN v_oauth_account_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_oauth_providers_updated_at
  BEFORE UPDATE ON auth.oauth_providers
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_oauth_credentials_updated_at
  BEFORE UPDATE ON auth.oauth_credentials
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_user_oauth_accounts_updated_at
  BEFORE UPDATE ON auth.user_oauth_accounts
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_comm_providers_updated_at
  BEFORE UPDATE ON auth.communication_providers
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_comm_credentials_updated_at
  BEFORE UPDATE ON auth.communication_credentials
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_user_mfa_methods_updated_at
  BEFORE UPDATE ON auth.user_mfa_methods
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE auth.oauth_providers IS 'Third-party OAuth provider configurations (Google, GitHub, Microsoft, etc.)';
COMMENT ON TABLE auth.oauth_credentials IS 'OAuth client credentials per tenant (client_id, client_secret)';
COMMENT ON TABLE auth.user_oauth_accounts IS 'Users who authenticated via OAuth providers';
COMMENT ON TABLE auth.oauth_state_tokens IS 'CSRF protection tokens for OAuth flows (short-lived)';
COMMENT ON TABLE auth.communication_providers IS 'Email/SMS provider configurations (SendGrid, Twilio, etc.)';
COMMENT ON TABLE auth.communication_credentials IS 'Communication provider credentials per tenant';
COMMENT ON TABLE auth.user_mfa_methods IS 'User MFA method preferences (TOTP, SMS, Email, etc.)';
