-- =====================================================
-- MFA (Multi-Factor Authentication) System
-- Implements TOTP-based 2FA without SMS dependency
-- =====================================================

-- TOTP Secrets storage
CREATE TABLE IF NOT EXISTS auth.mfa_secrets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- User identity
  user_id UUID NOT NULL UNIQUE,
  tenant_id UUID NOT NULL,

  -- TOTP configuration
  secret_key VARCHAR(255) NOT NULL,              -- Base32 encoded secret
  algorithm VARCHAR(20) DEFAULT 'SHA1',          -- SHA1, SHA256, SHA512
  digits INTEGER DEFAULT 6,                      -- 6 or 8 digit codes
  period INTEGER DEFAULT 30,                     -- Time step in seconds

  -- QR code data (for initial setup)
  issuer VARCHAR(255) DEFAULT 'EWH Platform',
  account_name VARCHAR(255) NOT NULL,            -- Usually email

  -- Status
  enabled BOOLEAN DEFAULT false,
  verified BOOLEAN DEFAULT false,                -- User must verify first code
  verified_at TIMESTAMP WITH TIME ZONE,

  -- Recovery
  backup_codes_generated BOOLEAN DEFAULT false,

  -- Security
  failed_attempts INTEGER DEFAULT 0,
  last_failed_attempt TIMESTAMP WITH TIME ZONE,
  locked_until TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (algorithm IN ('SHA1', 'SHA256', 'SHA512')),
  CHECK (digits IN (6, 8)),
  CHECK (period IN (30, 60))
);

CREATE INDEX idx_mfa_secrets_user ON auth.mfa_secrets(user_id);
CREATE INDEX idx_mfa_secrets_tenant ON auth.mfa_secrets(tenant_id);
CREATE INDEX idx_mfa_secrets_enabled ON auth.mfa_secrets(enabled);

-- Backup/Recovery codes
CREATE TABLE IF NOT EXISTS auth.mfa_backup_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id UUID NOT NULL REFERENCES auth.mfa_secrets(user_id) ON DELETE CASCADE,

  -- Code (hashed)
  code_hash VARCHAR(255) NOT NULL UNIQUE,
  code_prefix VARCHAR(10) NOT NULL,              -- First 4 chars for display

  -- Usage
  used BOOLEAN DEFAULT false,
  used_at TIMESTAMP WITH TIME ZONE,
  used_from_ip INET,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (code_prefix ~ '^[A-Z0-9]{4}$')
);

CREATE INDEX idx_mfa_backup_codes_user ON auth.mfa_backup_codes(user_id);
CREATE INDEX idx_mfa_backup_codes_hash ON auth.mfa_backup_codes(code_hash);
CREATE INDEX idx_mfa_backup_codes_unused ON auth.mfa_backup_codes(user_id, used) WHERE NOT used;

-- MFA events log
CREATE TABLE IF NOT EXISTS auth.mfa_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id UUID NOT NULL,
  event_type VARCHAR(50) NOT NULL,               -- enabled, disabled, verified, failed, backup_used, locked

  -- Details
  ip_address INET,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (event_type IN (
    'mfa_enabled', 'mfa_disabled', 'mfa_verified',
    'mfa_failed', 'backup_code_used', 'backup_codes_regenerated',
    'account_locked', 'account_unlocked'
  ))
);

CREATE INDEX idx_mfa_events_user ON auth.mfa_events(user_id);
CREATE INDEX idx_mfa_events_type ON auth.mfa_events(event_type);
CREATE INDEX idx_mfa_events_created ON auth.mfa_events(created_at DESC);

-- Add MFA columns to users table (if not exists)
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS mfa_enabled BOOLEAN DEFAULT false;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS mfa_required BOOLEAN DEFAULT false;  -- Tenant admin can enforce

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to generate backup codes (returns count)
CREATE OR REPLACE FUNCTION auth.generate_backup_codes(
  p_user_id UUID,
  p_count INTEGER DEFAULT 10
)
RETURNS INTEGER AS $$
DECLARE
  v_code_plain TEXT;
  v_code_hash TEXT;
  v_code_prefix TEXT;
  v_generated INTEGER := 0;
BEGIN
  -- Delete old unused backup codes
  DELETE FROM auth.mfa_backup_codes
  WHERE user_id = p_user_id AND NOT used;

  -- Generate new codes
  FOR i IN 1..p_count LOOP
    -- Generate 12-character alphanumeric code (format: XXXX-XXXX-XXXX)
    v_code_plain := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 12));

    -- Hash the code for storage (using sha256)
    v_code_hash := encode(digest(v_code_plain, 'sha256'), 'hex');

    -- Get prefix (first 4 chars)
    v_code_prefix := substring(v_code_plain from 1 for 4);

    -- Insert backup code
    INSERT INTO auth.mfa_backup_codes (user_id, code_hash, code_prefix)
    VALUES (p_user_id, v_code_hash, v_code_prefix);

    v_generated := v_generated + 1;
  END LOOP;

  -- Update secrets table
  UPDATE auth.mfa_secrets
  SET backup_codes_generated = true, updated_at = NOW()
  WHERE user_id = p_user_id;

  RETURN v_generated;
END;
$$ LANGUAGE plpgsql;

-- Function to verify backup code
CREATE OR REPLACE FUNCTION auth.verify_backup_code(
  p_user_id UUID,
  p_code TEXT,
  p_ip INET DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_code_hash TEXT;
  v_backup_id UUID;
BEGIN
  -- Hash the provided code
  v_code_hash := encode(digest(upper(p_code), 'sha256'), 'hex');

  -- Find and use the backup code
  UPDATE auth.mfa_backup_codes
  SET
    used = true,
    used_at = NOW(),
    used_from_ip = p_ip
  WHERE user_id = p_user_id
    AND code_hash = v_code_hash
    AND NOT used
  RETURNING id INTO v_backup_id;

  IF v_backup_id IS NOT NULL THEN
    -- Log the event
    INSERT INTO auth.mfa_events (user_id, event_type, ip_address)
    VALUES (p_user_id, 'backup_code_used', p_ip);

    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE plpgsql;

-- Function to lock MFA account after failed attempts
CREATE OR REPLACE FUNCTION auth.record_mfa_failure(
  p_user_id UUID,
  p_ip INET DEFAULT NULL,
  p_max_attempts INTEGER DEFAULT 5,
  p_lockout_minutes INTEGER DEFAULT 15
)
RETURNS BOOLEAN AS $$
DECLARE
  v_failed_attempts INTEGER;
  v_should_lock BOOLEAN := false;
BEGIN
  -- Increment failed attempts
  UPDATE auth.mfa_secrets
  SET
    failed_attempts = failed_attempts + 1,
    last_failed_attempt = NOW(),
    updated_at = NOW()
  WHERE user_id = p_user_id
  RETURNING failed_attempts INTO v_failed_attempts;

  -- Check if should lock
  IF v_failed_attempts >= p_max_attempts THEN
    UPDATE auth.mfa_secrets
    SET locked_until = NOW() + (p_lockout_minutes || ' minutes')::INTERVAL
    WHERE user_id = p_user_id;

    v_should_lock := true;

    -- Log lock event
    INSERT INTO auth.mfa_events (user_id, event_type, ip_address, metadata)
    VALUES (p_user_id, 'account_locked', p_ip, jsonb_build_object(
      'reason', 'max_failed_attempts',
      'attempts', v_failed_attempts,
      'lockout_minutes', p_lockout_minutes
    ));
  ELSE
    -- Log failed attempt
    INSERT INTO auth.mfa_events (user_id, event_type, ip_address, metadata)
    VALUES (p_user_id, 'mfa_failed', p_ip, jsonb_build_object(
      'attempts', v_failed_attempts
    ));
  END IF;

  RETURN v_should_lock;
END;
$$ LANGUAGE plpgsql;

-- Function to reset MFA failures on success
CREATE OR REPLACE FUNCTION auth.reset_mfa_failures(
  p_user_id UUID
)
RETURNS void AS $$
BEGIN
  UPDATE auth.mfa_secrets
  SET
    failed_attempts = 0,
    last_failed_attempt = NULL,
    locked_until = NULL,
    updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

CREATE TRIGGER update_mfa_secrets_updated_at
  BEFORE UPDATE ON auth.mfa_secrets
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE auth.mfa_secrets IS 'TOTP-based MFA secrets for users (Google Authenticator compatible)';
COMMENT ON TABLE auth.mfa_backup_codes IS 'One-time backup codes for MFA recovery';
COMMENT ON TABLE auth.mfa_events IS 'Audit log for MFA-related events';
COMMENT ON FUNCTION auth.generate_backup_codes IS 'Generates new backup codes for user MFA recovery';
COMMENT ON FUNCTION auth.verify_backup_code IS 'Verifies and marks backup code as used';
COMMENT ON FUNCTION auth.record_mfa_failure IS 'Records MFA verification failure and locks account if needed';
COMMENT ON FUNCTION auth.reset_mfa_failures IS 'Resets failed attempt counter on successful verification';
