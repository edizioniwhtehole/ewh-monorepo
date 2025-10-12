-- Migration 006: Create SLO Configuration Schema
-- This schema manages Service Level Objectives (SLOs) configuration and tracking

CREATE SCHEMA IF NOT EXISTS slo;

-- SLO Targets: Define service level objectives
CREATE TABLE slo.targets (
  id SERIAL PRIMARY KEY,
  service_name VARCHAR(100) NOT NULL,
  metric_name VARCHAR(50) NOT NULL, -- availability, latency_p95, latency_p99, error_rate, etc.
  target_value DECIMAL(10, 4) NOT NULL, -- e.g., 99.9 for availability, 200 for latency (ms), 1.0 for error rate (%)
  window_duration VARCHAR(10) NOT NULL, -- '7d', '30d', '90d'
  error_budget_total DECIMAL(10, 2) NOT NULL DEFAULT 100, -- Total error budget (percentage)
  enabled BOOLEAN NOT NULL DEFAULT true,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  UNIQUE(service_name, metric_name, window_duration)
);

-- SLO Compliance History: Track SLO compliance over time
CREATE TABLE slo.compliance_history (
  id SERIAL PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES slo.targets(id) ON DELETE CASCADE,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  current_compliance DECIMAL(10, 4) NOT NULL,
  error_budget_remaining DECIMAL(10, 2) NOT NULL,
  error_budget_consumed DECIMAL(10, 2) NOT NULL,
  burn_rate DECIMAL(10, 4),
  status VARCHAR(20) NOT NULL CHECK (status IN ('healthy', 'warning', 'critical')),
  violations_count INTEGER DEFAULT 0,
  metadata JSONB
);

-- SLO Violations: Track when SLOs are violated
CREATE TABLE slo.violations (
  id SERIAL PRIMARY KEY,
  target_id INTEGER NOT NULL REFERENCES slo.targets(id) ON DELETE CASCADE,
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  impact TEXT,
  root_cause TEXT,
  resolution TEXT,
  metadata JSONB
);

-- Indexes for performance
CREATE INDEX idx_slo_targets_service ON slo.targets(service_name);
CREATE INDEX idx_slo_targets_enabled ON slo.targets(enabled);
CREATE INDEX idx_slo_compliance_history_target ON slo.compliance_history(target_id, timestamp DESC);
CREATE INDEX idx_slo_violations_target ON slo.violations(target_id, started_at DESC);
CREATE INDEX idx_slo_violations_unresolved ON slo.violations(target_id, resolved_at) WHERE resolved_at IS NULL;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION slo.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER slo_targets_update_timestamp
BEFORE UPDATE ON slo.targets
FOR EACH ROW
EXECUTE FUNCTION slo.update_timestamp();

-- View: Active SLO Targets with Latest Compliance
CREATE VIEW slo.v_active_targets AS
SELECT
  t.id,
  t.service_name,
  t.metric_name,
  t.target_value,
  t.window_duration,
  t.error_budget_total,
  t.description,
  t.created_at,
  t.updated_at,
  (
    SELECT status
    FROM slo.compliance_history ch
    WHERE ch.target_id = t.id
    ORDER BY ch.timestamp DESC
    LIMIT 1
  ) as current_status,
  (
    SELECT current_compliance
    FROM slo.compliance_history ch
    WHERE ch.target_id = t.id
    ORDER BY ch.timestamp DESC
    LIMIT 1
  ) as current_compliance,
  (
    SELECT error_budget_remaining
    FROM slo.compliance_history ch
    WHERE ch.target_id = t.id
    ORDER BY ch.timestamp DESC
    LIMIT 1
  ) as error_budget_remaining,
  (
    SELECT COUNT(*)
    FROM slo.violations v
    WHERE v.target_id = t.id
    AND v.resolved_at IS NULL
  ) as active_violations
FROM slo.targets t
WHERE t.enabled = true;

-- View: SLO Violation Summary
CREATE VIEW slo.v_violation_summary AS
SELECT
  t.service_name,
  t.metric_name,
  t.window_duration,
  COUNT(*) as total_violations,
  COUNT(*) FILTER (WHERE v.resolved_at IS NULL) as active_violations,
  AVG(v.duration_minutes) FILTER (WHERE v.resolved_at IS NOT NULL) as avg_duration_minutes,
  MAX(v.started_at) as last_violation
FROM slo.targets t
LEFT JOIN slo.violations v ON v.target_id = t.id
WHERE t.enabled = true
GROUP BY t.id, t.service_name, t.metric_name, t.window_duration;

-- Seed default SLO targets for critical services
INSERT INTO slo.targets (service_name, metric_name, target_value, window_duration, description, created_by) VALUES
-- Frontend services
('app-admin-frontend', 'availability', 99.9, '30d', 'Admin dashboard availability SLO', 'system'),
('app-admin-frontend', 'latency_p95', 500, '30d', 'Admin dashboard p95 response time under 500ms', 'system'),
('app-web-frontend', 'availability', 99.9, '30d', 'Web frontend availability SLO', 'system'),
('app-web-frontend', 'latency_p95', 300, '30d', 'Web frontend p95 response time under 300ms', 'system'),

-- Core services
('svc-api-gateway', 'availability', 99.95, '30d', 'API Gateway availability - critical', 'system'),
('svc-api-gateway', 'latency_p95', 200, '30d', 'API Gateway p95 response time under 200ms', 'system'),
('svc-api-gateway', 'error_rate', 0.5, '30d', 'API Gateway error rate under 0.5%', 'system'),

('svc-auth', 'availability', 99.95, '30d', 'Authentication service availability - critical', 'system'),
('svc-auth', 'latency_p95', 150, '30d', 'Auth p95 response time under 150ms', 'system'),
('svc-auth', 'error_rate', 0.1, '30d', 'Auth error rate under 0.1%', 'system'),

-- Database
('postgres', 'availability', 99.99, '30d', 'PostgreSQL availability - critical', 'system'),

-- 90-day window for long-term tracking
('svc-api-gateway', 'availability', 99.9, '90d', 'API Gateway 90-day availability', 'system'),
('svc-auth', 'availability', 99.9, '90d', 'Auth service 90-day availability', 'system'),

-- 7-day window for short-term alerting
('svc-api-gateway', 'availability', 99.5, '7d', 'API Gateway weekly availability', 'system'),
('svc-auth', 'availability', 99.5, '7d', 'Auth service weekly availability', 'system');

COMMENT ON SCHEMA slo IS 'Service Level Objectives (SLO) configuration and tracking';
COMMENT ON TABLE slo.targets IS 'Define SLO targets for services';
COMMENT ON TABLE slo.compliance_history IS 'Historical SLO compliance data for trend analysis';
COMMENT ON TABLE slo.violations IS 'Track SLO violations and their resolution';
