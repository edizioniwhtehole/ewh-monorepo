-- Communications System Tables

-- Messages (unified across all channels)
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,
  
  -- Channel info
  channel_type VARCHAR(20) NOT NULL CHECK (channel_type IN ('email', 'sms', 'whatsapp', 'telegram', 'discord')),
  channel_account_id UUID, -- Which account sent/received
  direction VARCHAR(10) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  
  -- Addressing
  "from" VARCHAR(500),
  from_name VARCHAR(255),
  "to" JSONB NOT NULL, -- Array of recipients
  cc JSONB,
  bcc JSONB,
  
  -- Content
  subject VARCHAR(998),
  body TEXT NOT NULL,
  body_html TEXT,
  
  -- Metadata
  external_id VARCHAR(255), -- Provider's message ID
  status VARCHAR(20) DEFAULT 'queued' CHECK (status IN ('queued', 'scheduled', 'sending', 'sent', 'delivered', 'failed', 'bounced', 'opened', 'clicked')),
  error_message TEXT,
  
  -- Tracking
  track_opens BOOLEAN DEFAULT true,
  track_clicks BOOLEAN DEFAULT true,
  opened_at TIMESTAMP,
  clicked_at TIMESTAMP,
  delivered_at TIMESTAMP,
  failed_at TIMESTAMP,
  
  -- Scheduling
  scheduled_at TIMESTAMP,
  sent_at TIMESTAMP,
  
  -- Relations
  campaign_id UUID,
  thread_id UUID,
  in_reply_to_id UUID,
  crm_contact_id UUID,
  crm_deal_id UUID,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_tenant ON messages(tenant_id);
CREATE INDEX IF NOT EXISTS idx_messages_channel_type ON messages(channel_type);
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_campaign ON messages(campaign_id);
CREATE INDEX IF NOT EXISTS idx_messages_thread ON messages(thread_id);

-- Message Attachments
CREATE TABLE IF NOT EXISTS message_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  
  filename VARCHAR(255) NOT NULL,
  content_type VARCHAR(100),
  size_bytes INTEGER,
  url TEXT,
  
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attachments_message ON message_attachments(message_id);

-- Channel Accounts (connected email/SMS/WhatsApp accounts)
CREATE TABLE IF NOT EXISTS channel_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,
  
  channel_type VARCHAR(20) NOT NULL,
  provider VARCHAR(50) NOT NULL, -- 'sendgrid', 'gmail', 'twilio', etc.
  
  name VARCHAR(255),
  email VARCHAR(255),
  phone_number VARCHAR(50),
  
  -- OAuth tokens
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMP,
  
  -- Provider config
  config JSONB,
  
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'error')),
  last_error TEXT,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_channel_accounts_tenant ON channel_accounts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_channel_accounts_type ON channel_accounts(channel_type);

-- Campaigns
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,
  
  name VARCHAR(255) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('cold_email', 'newsletter', 'transactional', 'sms_blast', 'whatsapp_broadcast')),
  channel_type VARCHAR(20) NOT NULL,
  
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'running', 'paused', 'completed', 'cancelled')),
  
  -- Sequence steps
  sequence JSONB,
  
  -- Sending settings
  sending_settings JSONB,
  
  -- Stats
  total_recipients INTEGER DEFAULT 0,
  sent_count INTEGER DEFAULT 0,
  delivered_count INTEGER DEFAULT 0,
  opened_count INTEGER DEFAULT 0,
  clicked_count INTEGER DEFAULT 0,
  bounced_count INTEGER DEFAULT 0,
  
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campaigns_tenant ON campaigns(tenant_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status);

-- Campaign Recipients
CREATE TABLE IF NOT EXISTS campaign_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  
  contact_email VARCHAR(255),
  contact_phone VARCHAR(50),
  contact_name VARCHAR(255),
  
  variables JSONB, -- Template variables
  
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'opened', 'clicked', 'bounced', 'unsubscribed')),
  current_step INTEGER DEFAULT 1,
  
  last_message_id UUID,
  last_sent_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campaign_recipients_campaign ON campaign_recipients(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_recipients_status ON campaign_recipients(status);

-- Threads (conversation grouping)
CREATE TABLE IF NOT EXISTS threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  
  channel_type VARCHAR(20) NOT NULL,
  subject VARCHAR(998),
  
  participant_emails JSONB,
  participant_phones JSONB,
  
  last_message_at TIMESTAMP,
  message_count INTEGER DEFAULT 0,
  
  crm_contact_id UUID,
  crm_deal_id UUID,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_threads_tenant ON threads(tenant_id);

-- Platform Settings
CREATE TABLE IF NOT EXISTS communications_platform_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(255) NOT NULL UNIQUE,
  value JSONB NOT NULL,
  lock_level VARCHAR(20) CHECK (lock_level IN ('UNLOCKED', 'SOFT_LOCK', 'HARD_LOCK')),
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tenant Settings
CREATE TABLE IF NOT EXISTS communications_tenant_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  key VARCHAR(255) NOT NULL,
  value JSONB NOT NULL,
  lock_level VARCHAR(20) CHECK (lock_level IN ('UNLOCKED', 'SOFT_LOCK', 'HARD_LOCK')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, key)
);

CREATE INDEX IF NOT EXISTS idx_comm_tenant_settings ON communications_tenant_settings(tenant_id);

-- User Settings
CREATE TABLE IF NOT EXISTS communications_user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  key VARCHAR(255) NOT NULL,
  value JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, key)
);

CREATE INDEX IF NOT EXISTS idx_comm_user_settings ON communications_user_settings(user_id);

-- Webhooks
CREATE TABLE IF NOT EXISTS webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  
  url TEXT NOT NULL,
  events JSONB NOT NULL, -- Array of event types
  secret VARCHAR(255),
  
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhooks_tenant ON webhooks(tenant_id);

-- Webhook Deliveries
CREATE TABLE IF NOT EXISTS webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id UUID NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
  
  event_type VARCHAR(100) NOT NULL,
  payload JSONB NOT NULL,
  
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed')),
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  
  response_code INTEGER,
  response_body TEXT,
  error_message TEXT,
  
  next_retry_at TIMESTAMP,
  delivered_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_webhook ON webhook_deliveries(webhook_id);
CREATE INDEX IF NOT EXISTS idx_webhook_deliveries_status ON webhook_deliveries(status);
