-- Voice/Phone System Database Schema
-- Complete VoIP, call management, voicemail, IVR, and transcription system

-- =====================================================
-- CALLS TABLE
-- Stores all call records (inbound and outbound)
-- =====================================================
CREATE TABLE IF NOT EXISTS calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Twilio integration
  twilio_call_sid VARCHAR(34) UNIQUE NOT NULL,
  twilio_parent_call_sid VARCHAR(34), -- For forwarded/transferred calls

  -- Call details
  direction VARCHAR(20) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  from_number VARCHAR(50) NOT NULL,
  to_number VARCHAR(50) NOT NULL,

  -- Status tracking
  status VARCHAR(20) NOT NULL DEFAULT 'initiated'
    CHECK (status IN ('initiated', 'ringing', 'in-progress', 'completed', 'failed', 'busy', 'no-answer', 'canceled')),

  -- Timing
  start_time TIMESTAMP,
  answer_time TIMESTAMP,
  end_time TIMESTAMP,
  duration_seconds INTEGER,

  -- Recording
  recording_url TEXT,
  recording_sid VARCHAR(34),
  recording_duration_seconds INTEGER,

  -- Transcription reference
  transcription_id UUID REFERENCES transcriptions(id) ON DELETE SET NULL,

  -- Cost tracking
  cost DECIMAL(10, 4),
  currency VARCHAR(3) DEFAULT 'USD',

  -- Additional info
  caller_name VARCHAR(200),
  notes TEXT,
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_calls_tenant ON calls(tenant_id);
CREATE INDEX idx_calls_user ON calls(user_id);
CREATE INDEX idx_calls_direction ON calls(direction);
CREATE INDEX idx_calls_status ON calls(status);
CREATE INDEX idx_calls_created ON calls(created_at DESC);
CREATE INDEX idx_calls_from_number ON calls(from_number);
CREATE INDEX idx_calls_to_number ON calls(to_number);
CREATE INDEX idx_calls_twilio_sid ON calls(twilio_call_sid);

-- =====================================================
-- PHONE NUMBERS TABLE
-- Manages purchased phone numbers
-- =====================================================
CREATE TABLE IF NOT EXISTS phone_numbers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Phone number details
  phone_number VARCHAR(50) UNIQUE NOT NULL,
  friendly_name VARCHAR(100),
  country_code VARCHAR(2) NOT NULL DEFAULT 'US',

  -- Twilio reference
  twilio_sid VARCHAR(34) UNIQUE NOT NULL,

  -- Capabilities
  capabilities JSONB DEFAULT '{"voice": true, "sms": false, "mms": false}',

  -- Configuration
  voice_url TEXT,
  status_callback_url TEXT,
  ivr_flow_id UUID REFERENCES ivr_flows(id) ON DELETE SET NULL,

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Metadata
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_phone_numbers_tenant ON phone_numbers(tenant_id);
CREATE INDEX idx_phone_numbers_number ON phone_numbers(phone_number);
CREATE INDEX idx_phone_numbers_active ON phone_numbers(is_active);

-- =====================================================
-- VOICEMAILS TABLE
-- Stores voicemail messages
-- =====================================================
CREATE TABLE IF NOT EXISTS voicemails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Call reference
  call_id UUID REFERENCES calls(id) ON DELETE CASCADE,

  -- Voicemail details
  from_number VARCHAR(50) NOT NULL,
  to_number VARCHAR(50) NOT NULL,

  -- Recording
  recording_url TEXT NOT NULL,
  recording_sid VARCHAR(34),
  duration_seconds INTEGER,

  -- Transcription
  transcription_id UUID REFERENCES transcriptions(id) ON DELETE SET NULL,

  -- Status
  is_read BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,

  -- Metadata
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_voicemails_tenant ON voicemails(tenant_id);
CREATE INDEX idx_voicemails_user ON voicemails(user_id);
CREATE INDEX idx_voicemails_is_read ON voicemails(is_read);
CREATE INDEX idx_voicemails_created ON voicemails(created_at DESC);

-- =====================================================
-- VOICEMAIL GREETINGS TABLE
-- Custom voicemail greetings
-- =====================================================
CREATE TABLE IF NOT EXISTS voicemail_greetings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  phone_number_id UUID REFERENCES phone_numbers(id) ON DELETE CASCADE,

  -- Greeting details
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) NOT NULL DEFAULT 'personal'
    CHECK (type IN ('personal', 'business', 'after-hours', 'holiday')),

  -- Audio
  audio_url TEXT,
  text_to_speech TEXT,
  voice VARCHAR(50) DEFAULT 'Polly.Joanna',

  -- Schedule (for after-hours, holiday greetings)
  schedule JSONB,

  -- Status
  is_active BOOLEAN DEFAULT false,
  is_default BOOLEAN DEFAULT false,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_voicemail_greetings_tenant ON voicemail_greetings(tenant_id);
CREATE INDEX idx_voicemail_greetings_user ON voicemail_greetings(user_id);
CREATE INDEX idx_voicemail_greetings_phone ON voicemail_greetings(phone_number_id);
CREATE INDEX idx_voicemail_greetings_type ON voicemail_greetings(type);

-- =====================================================
-- TRANSCRIPTIONS TABLE
-- AI transcriptions of calls and voicemails
-- =====================================================
CREATE TABLE IF NOT EXISTS transcriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Source
  source_type VARCHAR(20) NOT NULL CHECK (source_type IN ('call', 'voicemail', 'recording')),
  source_id UUID NOT NULL,

  -- Audio reference
  audio_url TEXT NOT NULL,
  audio_duration_seconds INTEGER,

  -- Transcription
  text TEXT NOT NULL,
  language VARCHAR(10) DEFAULT 'en-US',
  confidence DECIMAL(3, 2),

  -- AI Analysis (optional)
  sentiment VARCHAR(20) CHECK (sentiment IN ('positive', 'negative', 'neutral')),
  summary TEXT,
  action_items JSONB,
  key_points JSONB,

  -- Provider info
  provider VARCHAR(50) DEFAULT 'openai-whisper',
  model VARCHAR(50),

  -- Cost tracking
  cost DECIMAL(10, 4),

  -- Processing status
  status VARCHAR(20) DEFAULT 'completed'
    CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  error_message TEXT,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_transcriptions_tenant ON transcriptions(tenant_id);
CREATE INDEX idx_transcriptions_source ON transcriptions(source_type, source_id);
CREATE INDEX idx_transcriptions_status ON transcriptions(status);
CREATE INDEX idx_transcriptions_created ON transcriptions(created_at DESC);

-- =====================================================
-- IVR FLOWS TABLE
-- Interactive Voice Response flow definitions
-- =====================================================
CREATE TABLE IF NOT EXISTS ivr_flows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Flow details
  name VARCHAR(100) NOT NULL,
  description TEXT,

  -- Phone number assignment
  phone_number_id UUID REFERENCES phone_numbers(id) ON DELETE SET NULL,

  -- Flow definition (visual flow chart stored as JSON)
  flow_definition JSONB NOT NULL,
  -- Example structure:
  -- {
  --   "nodes": [
  --     {"id": "start", "type": "start", "data": {}},
  --     {"id": "menu1", "type": "menu", "data": {"message": "Press 1 for...", "options": {...}}},
  --     {"id": "dial1", "type": "dial", "data": {"number": "+1234567890"}}
  --   ],
  --   "edges": [
  --     {"id": "e1", "source": "start", "target": "menu1"},
  --     {"id": "e2", "source": "menu1", "target": "dial1", "label": "1"}
  --   ]
  -- }

  -- Generated TwiML (cached)
  twiml_cache TEXT,

  -- Version tracking
  version INTEGER DEFAULT 1,

  -- Status
  is_active BOOLEAN DEFAULT false,

  -- Statistics
  total_calls INTEGER DEFAULT 0,
  last_used_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ivr_flows_tenant ON ivr_flows(tenant_id);
CREATE INDEX idx_ivr_flows_phone ON ivr_flows(phone_number_id);
CREATE INDEX idx_ivr_flows_active ON ivr_flows(is_active);
CREATE INDEX idx_ivr_flows_created ON ivr_flows(created_at DESC);

-- =====================================================
-- MOBILE DEVICES TABLE
-- Registered mobile devices for VoIP calling
-- =====================================================
CREATE TABLE IF NOT EXISTS mobile_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Device details
  device_name VARCHAR(100) NOT NULL,
  device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('ios', 'android')),
  device_id VARCHAR(200) UNIQUE NOT NULL, -- Device unique identifier

  -- Push notifications
  push_token TEXT,
  push_provider VARCHAR(20) CHECK (push_provider IN ('fcm', 'apns')),

  -- Twilio registration
  twilio_identity VARCHAR(100) UNIQUE NOT NULL,

  -- Status
  is_active BOOLEAN DEFAULT true,
  last_seen_at TIMESTAMP,

  -- App info
  app_version VARCHAR(20),
  os_version VARCHAR(20),

  -- Metadata
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_mobile_devices_tenant ON mobile_devices(tenant_id);
CREATE INDEX idx_mobile_devices_user ON mobile_devices(user_id);
CREATE INDEX idx_mobile_devices_device_id ON mobile_devices(device_id);
CREATE INDEX idx_mobile_devices_active ON mobile_devices(is_active);

-- =====================================================
-- RECORDINGS TABLE
-- Standalone call recordings (not tied to specific calls)
-- =====================================================
CREATE TABLE IF NOT EXISTS recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  -- Call reference (optional)
  call_id UUID REFERENCES calls(id) ON DELETE CASCADE,

  -- Recording details
  recording_url TEXT NOT NULL,
  recording_sid VARCHAR(34) UNIQUE,
  duration_seconds INTEGER,

  -- Transcription
  transcription_id UUID REFERENCES transcriptions(id) ON DELETE SET NULL,

  -- Metadata
  name VARCHAR(200),
  description TEXT,
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_recordings_tenant ON recordings(tenant_id);
CREATE INDEX idx_recordings_call ON recordings(call_id);
CREATE INDEX idx_recordings_created ON recordings(created_at DESC);

-- =====================================================
-- CALL TAGS TABLE
-- Tags for organizing and filtering calls
-- =====================================================
CREATE TABLE IF NOT EXISTS call_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
  tag VARCHAR(50) NOT NULL,

  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_call_tags_call ON call_tags(call_id);
CREATE INDEX idx_call_tags_tag ON call_tags(tag);

-- =====================================================
-- CASCADE SETTINGS TABLES
-- Platform, Tenant, and User level settings
-- =====================================================

-- Platform settings (admin only)
CREATE TABLE IF NOT EXISTS voice_platform_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(100) UNIQUE NOT NULL,
  value TEXT,
  value_type VARCHAR(20) DEFAULT 'string' CHECK (value_type IN ('string', 'number', 'boolean', 'json')),
  description TEXT,
  lock_type VARCHAR(20) DEFAULT 'unlocked' CHECK (lock_type IN ('hard', 'soft', 'unlocked')),

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tenant settings
CREATE TABLE IF NOT EXISTS voice_tenant_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  key VARCHAR(100) NOT NULL,
  value TEXT,
  value_type VARCHAR(20) DEFAULT 'string' CHECK (value_type IN ('string', 'number', 'boolean', 'json')),

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(tenant_id, key)
);

-- User settings
CREATE TABLE IF NOT EXISTS voice_user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  key VARCHAR(100) NOT NULL,
  value TEXT,
  value_type VARCHAR(20) DEFAULT 'string' CHECK (value_type IN ('string', 'number', 'boolean', 'json')),

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(user_id, key)
);

CREATE INDEX idx_voice_tenant_settings ON voice_tenant_settings(tenant_id, key);
CREATE INDEX idx_voice_user_settings ON voice_user_settings(user_id, key);

-- =====================================================
-- DEFAULT PLATFORM SETTINGS
-- =====================================================
INSERT INTO voice_platform_settings (key, value, value_type, description, lock_type) VALUES
  ('auto_record_calls', 'true', 'boolean', 'Automatically record all calls', 'soft'),
  ('auto_transcribe_calls', 'false', 'boolean', 'Automatically transcribe recorded calls', 'soft'),
  ('auto_transcribe_voicemails', 'true', 'boolean', 'Automatically transcribe voicemails', 'soft'),
  ('max_call_duration_seconds', '3600', 'number', 'Maximum call duration in seconds', 'soft'),
  ('enable_call_recording', 'true', 'boolean', 'Enable call recording feature', 'soft'),
  ('enable_voicemail', 'true', 'boolean', 'Enable voicemail feature', 'soft'),
  ('enable_ivr', 'true', 'boolean', 'Enable IVR builder', 'soft'),
  ('enable_ai_transcription', 'true', 'boolean', 'Enable AI transcription', 'soft'),
  ('transcription_provider', 'openai-whisper', 'string', 'Transcription provider', 'soft'),
  ('default_voicemail_greeting', 'You have reached {name}. Please leave a message after the beep.', 'string', 'Default voicemail greeting', 'unlocked'),
  ('call_retention_days', '90', 'number', 'Days to retain call records', 'soft'),
  ('recording_retention_days', '90', 'number', 'Days to retain recordings', 'soft'),
  ('voicemail_retention_days', '30', 'number', 'Days to retain voicemails', 'soft')
ON CONFLICT (key) DO NOTHING;

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE calls IS 'Call records for inbound and outbound calls';
COMMENT ON TABLE phone_numbers IS 'Purchased and managed phone numbers';
COMMENT ON TABLE voicemails IS 'Voicemail messages';
COMMENT ON TABLE voicemail_greetings IS 'Custom voicemail greetings';
COMMENT ON TABLE transcriptions IS 'AI transcriptions of calls and voicemails';
COMMENT ON TABLE ivr_flows IS 'IVR (Interactive Voice Response) flow definitions';
COMMENT ON TABLE mobile_devices IS 'Registered mobile devices for VoIP';
COMMENT ON TABLE recordings IS 'Call recordings';
