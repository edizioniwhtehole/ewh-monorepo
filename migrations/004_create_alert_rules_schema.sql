-- Migration: Create Alert Rules Schema
-- Version: 004
-- Created: 2025-10-06
-- Description: Alert rules management system

CREATE SCHEMA IF NOT EXISTS alerts;

-- =====================================================
-- Table: alert_rules
-- Configurable alert rules
-- =====================================================
CREATE TABLE IF NOT EXISTS alerts.rules (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Rule configuration
  metric_type VARCHAR(50) NOT NULL, -- cpu, memory, latency, error_rate, availability
  service_filter VARCHAR(255), -- null = all services, or specific service name
  condition VARCHAR(20) NOT NULL, -- gt, lt, gte, lte, eq
  threshold DECIMAL(10,2) NOT NULL,
  duration_seconds INT DEFAULT 300, -- How long condition must be true

  -- Severity
  severity VARCHAR(20) DEFAULT 'warning', -- critical, warning, info

  -- Status
  enabled BOOLEAN DEFAULT true,

  -- Notification
  notification_channels JSONB DEFAULT '[]'::jsonb, -- Array of channel IDs

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by VARCHAR(100),

  CONSTRAINT valid_metric_type CHECK (metric_type IN ('cpu', 'memory', 'latency', 'error_rate', 'availability', 'custom')),
  CONSTRAINT valid_condition CHECK (condition IN ('gt', 'lt', 'gte', 'lte', 'eq')),
  CONSTRAINT valid_severity CHECK (severity IN ('critical', 'warning', 'info'))
);

CREATE INDEX idx_rules_enabled ON alerts.rules(enabled) WHERE enabled = true;
CREATE INDEX idx_rules_service ON alerts.rules(service_filter) WHERE service_filter IS NOT NULL;

-- =====================================================
-- Table: notification_channels
-- Notification delivery channels
-- =====================================================
CREATE TABLE IF NOT EXISTS alerts.notification_channels (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- email, slack, webhook, pagerduty, discord
  enabled BOOLEAN DEFAULT true,

  -- Configuration (type-specific)
  config JSONB NOT NULL, -- email: {to: [...], from: ...}, slack: {webhook_url: ...}, etc

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,

  CONSTRAINT valid_channel_type CHECK (type IN ('email', 'slack', 'webhook', 'pagerduty', 'discord', 'teams'))
);

CREATE INDEX idx_channels_enabled ON alerts.notification_channels(enabled) WHERE enabled = true;

-- =====================================================
-- Table: alert_history
-- Historical alerts fired
-- =====================================================
CREATE TABLE IF NOT EXISTS alerts.history (
  id BIGSERIAL PRIMARY KEY,
  rule_id INT REFERENCES alerts.rules(id) ON DELETE SET NULL,

  -- Alert details
  service_name VARCHAR(255),
  metric_type VARCHAR(50),
  metric_value DECIMAL(10,2),
  threshold DECIMAL(10,2),
  severity VARCHAR(20),

  -- Status
  status VARCHAR(20) DEFAULT 'firing', -- firing, resolved, acknowledged
  fired_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  acknowledged_at TIMESTAMPTZ,
  acknowledged_by VARCHAR(100),

  -- Notification
  notifications_sent JSONB DEFAULT '[]'::jsonb, -- Array of {channel_id, sent_at, success}

  CONSTRAINT valid_alert_status CHECK (status IN ('firing', 'resolved', 'acknowledged'))
);

CREATE INDEX idx_history_rule ON alerts.history(rule_id);
CREATE INDEX idx_history_service ON alerts.history(service_name);
CREATE INDEX idx_history_status ON alerts.history(status);
CREATE INDEX idx_history_fired ON alerts.history(fired_at DESC);

-- =====================================================
-- Seed data: Default alert rules
-- =====================================================
INSERT INTO alerts.rules (name, description, metric_type, condition, threshold, severity, enabled) VALUES
  ('High CPU Usage', 'Alert when service CPU usage exceeds 80%', 'cpu', 'gt', 80, 'warning', true),
  ('Critical CPU Usage', 'Alert when service CPU usage exceeds 95%', 'cpu', 'gt', 95, 'critical', true),
  ('High Memory Usage', 'Alert when service memory usage exceeds 85%', 'memory', 'gt', 85, 'warning', true),
  ('Critical Memory Usage', 'Alert when service memory usage exceeds 95%', 'memory', 'gt', 95, 'critical', true),
  ('High Error Rate', 'Alert when error rate exceeds 5%', 'error_rate', 'gt', 5, 'warning', true),
  ('Service Down', 'Alert when service availability drops below 100%', 'availability', 'lt', 100, 'critical', true),
  ('High Latency', 'Alert when p95 latency exceeds 500ms', 'latency', 'gt', 500, 'warning', true)
ON CONFLICT DO NOTHING;

COMMENT ON SCHEMA alerts IS 'Alert rules and notification management system';
COMMENT ON TABLE alerts.rules IS 'Configurable alert rules for monitoring';
COMMENT ON TABLE alerts.notification_channels IS 'Notification delivery channels (email, slack, etc)';
COMMENT ON TABLE alerts.history IS 'Historical record of fired alerts';
