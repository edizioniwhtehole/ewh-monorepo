-- Communications Service Tables
-- Migration: 050_communications_tables.sql

-- Messages (unified across all channels)
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,

  channel_type VARCHAR(20) NOT NULL, -- email, sms, whatsapp, telegram, discord
  account_id UUID, -- Which account sent/received

  -- Direction
  direction VARCHAR(10) NOT NULL, -- inbound, outbound

  -- Participants
  from_address VARCHAR(500) NOT NULL,
  from_name VARCHAR(200),
  to_addresses TEXT[] NOT NULL,
  cc_addresses TEXT[],
  bcc_addresses TEXT[],

  -- Content
  subject VARCHAR(1000),
  body TEXT NOT NULL,
  body_html TEXT,

  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'queued', -- queued, sending, sent, delivered, read, failed, bounced
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  error_message TEXT,

  -- Tracking
  track_opens BOOLEAN DEFAULT false,
  track_clicks BOOLEAN DEFAULT false,
  opens_count INT DEFAULT 0,
  clicks_count INT DEFAULT 0,

  -- Threading
  thread_id UUID,
  reply_to_id UUID,

  -- Campaign
  campaign_id UUID,
  automation_id UUID,

  -- Provider
  provider_message_id VARCHAR(500),
  provider_data JSONB,

  -- CRM
  crm_contact_id UUID,
  crm_deal_id UUID,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_tenant ON messages(tenant_id);
CREATE INDEX idx_messages_thread ON messages(thread_id);
CREATE INDEX idx_messages_campaign ON messages(campaign_id);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_channel ON messages(channel_type);
CREATE INDEX idx_messages_direction ON messages(direction);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

-- Attachments
CREATE TABLE IF NOT EXISTS message_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  filename VARCHAR(500) NOT NULL,
  content_type VARCHAR(200) NOT NULL,
  size BIGINT NOT NULL,
  storage_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_message_attachments_message ON message_attachments(message_id);

-- Channel Accounts (connections)
CREATE TABLE IF NOT EXISTS channel_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID, -- NULL = shared tenant account

  channel_type VARCHAR(20) NOT NULL,
  account_name VARCHAR(200) NOT NULL,

  -- Authentication
  auth_type VARCHAR(20) NOT NULL, -- oauth2, api_key, password
  credentials JSONB NOT NULL, -- Encrypted

  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, paused, error
  last_sync_at TIMESTAMPTZ,
  error_message TEXT,

  -- Settings
  settings JSONB DEFAULT '{}',

  -- Usage (for cold email rotation)
  daily_sent_count INT DEFAULT 0,
  daily_limit INT,
  reputation_score DECIMAL(5,2) DEFAULT 100.0,
  warmup_phase INT DEFAULT 0, -- 0-100%

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_channel_accounts_tenant ON channel_accounts(tenant_id);
CREATE INDEX idx_channel_accounts_type ON channel_accounts(channel_type);
CREATE INDEX idx_channel_accounts_status ON channel_accounts(status);

-- Campaigns
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,

  name VARCHAR(200) NOT NULL,
  type VARCHAR(20) NOT NULL, -- cold_email, newsletter, drip, broadcast
  channel_type VARCHAR(20) NOT NULL,

  status VARCHAR(20) NOT NULL DEFAULT 'draft', -- draft, active, paused, completed

  -- Recipients
  recipient_source VARCHAR(20) NOT NULL, -- csv, crm_filter, manual, list
  recipient_data JSONB,
  total_recipients INT DEFAULT 0,

  -- Sequence (for multi-step campaigns)
  sequence JSONB NOT NULL, -- Array of steps

  -- Sending settings
  sending_settings JSONB DEFAULT '{}',

  -- Stats
  stats JSONB DEFAULT '{"sent":0,"delivered":0,"opened":0,"clicked":0,"replied":0,"bounced":0,"unsubscribed":0}',

  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_campaigns_tenant ON campaigns(tenant_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_type ON campaigns(type);

-- Campaign Recipients (tracking)
CREATE TABLE IF NOT EXISTS campaign_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,

  email VARCHAR(500),
  phone VARCHAR(50),
  username VARCHAR(200),

  variables JSONB DEFAULT '{}', -- {{firstName}}, etc.

  -- Progress
  current_step INT DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, bounced, unsubscribed

  -- Stats
  sent_count INT DEFAULT 0,
  opened_count INT DEFAULT 0,
  clicked_count INT DEFAULT 0,
  replied BOOLEAN DEFAULT false,

  last_sent_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_campaign_recipients_campaign ON campaign_recipients(campaign_id);
CREATE INDEX idx_campaign_recipients_status ON campaign_recipients(status);

-- Threads (conversation grouping)
CREATE TABLE IF NOT EXISTS comm_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  channel_type VARCHAR(20) NOT NULL,

  -- Participants
  participants TEXT[] NOT NULL,

  subject VARCHAR(1000),

  -- Stats
  message_count INT DEFAULT 0,
  unread_count INT DEFAULT 0,

  last_message_at TIMESTAMPTZ,

  -- CRM
  crm_contact_id UUID,
  crm_deal_id UUID,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comm_threads_tenant ON comm_threads(tenant_id);
CREATE INDEX idx_comm_threads_crm_contact ON comm_threads(crm_contact_id);
CREATE INDEX idx_comm_threads_last_message ON comm_threads(last_message_at DESC);

-- Cascade Settings Tables
CREATE TABLE IF NOT EXISTS communications_platform_settings (
  key VARCHAR(100) PRIMARY KEY,
  value JSONB NOT NULL,
  lock_type VARCHAR(20) DEFAULT 'unlocked', -- hard, soft, unlocked
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS communications_tenant_settings (
  key VARCHAR(100) NOT NULL,
  tenant_id UUID NOT NULL,
  value JSONB NOT NULL,
  lock_type VARCHAR(20) DEFAULT 'unlocked',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (key, tenant_id)
);

CREATE TABLE IF NOT EXISTS communications_user_settings (
  key VARCHAR(100) NOT NULL,
  user_id UUID NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (key, user_id)
);

-- Webhooks
CREATE TABLE IF NOT EXISTS comm_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  url TEXT NOT NULL,
  events TEXT[] NOT NULL, -- ['message.sent', 'message.delivered', etc.]
  secret VARCHAR(64) NOT NULL, -- For HMAC signature

  status VARCHAR(20) DEFAULT 'active', -- active, paused, disabled

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comm_webhooks_tenant ON comm_webhooks(tenant_id);

CREATE TABLE IF NOT EXISTS comm_webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id UUID NOT NULL REFERENCES comm_webhooks(id) ON DELETE CASCADE,

  event VARCHAR(100) NOT NULL,
  payload JSONB NOT NULL,

  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, delivered, failed
  attempts INT DEFAULT 0,
  max_attempts INT DEFAULT 5,

  next_retry_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,

  response_status INT,
  response_body TEXT,
  error_message TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comm_webhook_deliveries_status ON comm_webhook_deliveries(status);
CREATE INDEX idx_comm_webhook_deliveries_next_retry ON comm_webhook_deliveries(next_retry_at);
CREATE INDEX idx_comm_webhook_deliveries_webhook ON comm_webhook_deliveries(webhook_id);

-- Insert default platform settings
INSERT INTO communications_platform_settings (key, value, lock_type) VALUES
  ('email.sending.daily_limit', '10000', 'hard'),
  ('email.sending.rate_limit_per_hour', '500', 'unlocked'),
  ('email.attachment.max_size_mb', '25', 'unlocked'),
  ('email.features.cold_email_enabled', 'true', 'unlocked'),
  ('email.features.newsletter_enabled', 'true', 'unlocked'),
  ('email.features.tracking_enabled', 'true', 'unlocked'),
  ('email.cold.daily_limit_per_account', '500', 'soft'),
  ('email.cold.warmup_enabled', 'true', 'unlocked'),
  ('sms.sending.rate_per_second', '10', 'unlocked'),
  ('sms.international_enabled', 'true', 'unlocked')
ON CONFLICT (key) DO NOTHING;
