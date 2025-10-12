-- Migration: Create Deployments Schema
-- Version: 005
-- Created: 2025-10-06
-- Description: Deployment tracking and management system

CREATE SCHEMA IF NOT EXISTS deployments;

-- =====================================================
-- Table: deployments
-- Deployment history tracking
-- =====================================================
CREATE TABLE IF NOT EXISTS deployments.deployments (
  id BIGSERIAL PRIMARY KEY,
  service_id INT REFERENCES registry.services(id) ON DELETE CASCADE,

  -- Deployment info
  version VARCHAR(100) NOT NULL,
  environment VARCHAR(50) DEFAULT 'development',
  status VARCHAR(50) DEFAULT 'in_progress',

  -- Deployment metadata
  commit_sha VARCHAR(64),
  commit_message TEXT,
  branch VARCHAR(255),
  tag VARCHAR(255),

  -- Deployment strategy
  strategy VARCHAR(50) DEFAULT 'rolling', -- rolling, blue-green, canary, recreate
  rollout_percent INT DEFAULT 100,

  -- Timing
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  duration_seconds INT,

  -- Who triggered
  triggered_by VARCHAR(100),
  trigger_type VARCHAR(50) DEFAULT 'manual', -- manual, webhook, scheduled

  -- Rollback info
  rollback_from_deployment_id BIGINT REFERENCES deployments.deployments(id),
  can_rollback BOOLEAN DEFAULT true,

  -- Health check
  health_check_passed BOOLEAN,
  health_check_details JSONB,

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  CONSTRAINT valid_status CHECK (status IN ('in_progress', 'success', 'failed', 'rolled_back', 'cancelled')),
  CONSTRAINT valid_strategy CHECK (strategy IN ('rolling', 'blue-green', 'canary', 'recreate')),
  CONSTRAINT valid_environment CHECK (environment IN ('development', 'staging', 'production'))
);

CREATE INDEX idx_deployments_service ON deployments.deployments(service_id);
CREATE INDEX idx_deployments_status ON deployments.deployments(status);
CREATE INDEX idx_deployments_env ON deployments.deployments(environment);
CREATE INDEX idx_deployments_started ON deployments.deployments(started_at DESC);
CREATE INDEX idx_deployments_version ON deployments.deployments(service_id, version);

-- =====================================================
-- Table: deployment_events
-- Detailed deployment event log
-- =====================================================
CREATE TABLE IF NOT EXISTS deployments.events (
  id BIGSERIAL PRIMARY KEY,
  deployment_id BIGINT NOT NULL REFERENCES deployments.deployments(id) ON DELETE CASCADE,

  event_type VARCHAR(50) NOT NULL,
  message TEXT,
  severity VARCHAR(20) DEFAULT 'info',
  timestamp TIMESTAMPTZ DEFAULT NOW(),

  -- Event details
  details JSONB DEFAULT '{}'::jsonb,

  CONSTRAINT valid_event_severity CHECK (severity IN ('debug', 'info', 'warning', 'error'))
);

CREATE INDEX idx_deployment_events_deployment ON deployments.events(deployment_id);
CREATE INDEX idx_deployment_events_time ON deployments.events(timestamp DESC);

-- =====================================================
-- Table: deployment_instances
-- Track individual instance deployments (for rolling updates)
-- =====================================================
CREATE TABLE IF NOT EXISTS deployments.instances (
  id BIGSERIAL PRIMARY KEY,
  deployment_id BIGINT NOT NULL REFERENCES deployments.deployments(id) ON DELETE CASCADE,
  instance_id UUID REFERENCES registry.service_instances(id) ON DELETE SET NULL,

  instance_name VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',

  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,

  health_check_passed BOOLEAN,
  error_message TEXT,

  CONSTRAINT valid_instance_status CHECK (status IN ('pending', 'deploying', 'success', 'failed'))
);

CREATE INDEX idx_deployment_instances_deployment ON deployments.instances(deployment_id);
CREATE INDEX idx_deployment_instances_status ON deployments.instances(status);

-- =====================================================
-- Views
-- =====================================================

-- View: Recent deployments with service info
CREATE OR REPLACE VIEW deployments.v_recent_deployments AS
SELECT
  d.id,
  s.name as service_name,
  s.type as service_type,
  d.version,
  d.environment,
  d.status,
  d.strategy,
  d.started_at,
  d.completed_at,
  d.duration_seconds,
  d.triggered_by,
  d.commit_sha,
  d.health_check_passed,
  COUNT(di.id) FILTER (WHERE di.status = 'success') as instances_success,
  COUNT(di.id) FILTER (WHERE di.status = 'failed') as instances_failed,
  COUNT(di.id) as instances_total
FROM deployments.deployments d
JOIN registry.services s ON d.service_id = s.id
LEFT JOIN deployments.instances di ON d.id = di.deployment_id
WHERE d.started_at > NOW() - INTERVAL '7 days'
GROUP BY d.id, s.name, s.type
ORDER BY d.started_at DESC;

-- View: Deployment success rate by service
CREATE OR REPLACE VIEW deployments.v_deployment_stats AS
SELECT
  s.name as service_name,
  s.type as service_type,
  COUNT(*) as total_deployments,
  COUNT(*) FILTER (WHERE d.status = 'success') as successful_deployments,
  COUNT(*) FILTER (WHERE d.status = 'failed') as failed_deployments,
  COUNT(*) FILTER (WHERE d.status = 'rolled_back') as rolled_back_deployments,
  ROUND(
    COUNT(*) FILTER (WHERE d.status = 'success') * 100.0 / NULLIF(COUNT(*), 0),
    2
  ) as success_rate,
  AVG(d.duration_seconds) FILTER (WHERE d.status = 'success') as avg_duration_seconds,
  MAX(d.started_at) as last_deployment_at
FROM registry.services s
LEFT JOIN deployments.deployments d ON s.id = d.service_id
GROUP BY s.id, s.name, s.type
ORDER BY total_deployments DESC;

-- =====================================================
-- Functions
-- =====================================================

-- Function: Trigger rollback
CREATE OR REPLACE FUNCTION deployments.trigger_rollback(
  p_deployment_id BIGINT,
  p_triggered_by VARCHAR DEFAULT 'system'
)
RETURNS BIGINT AS $$
DECLARE
  v_service_id INT;
  v_previous_version VARCHAR;
  v_environment VARCHAR;
  v_new_deployment_id BIGINT;
BEGIN
  -- Get deployment info
  SELECT service_id, environment INTO v_service_id, v_environment
  FROM deployments.deployments
  WHERE id = p_deployment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Deployment % not found', p_deployment_id;
  END IF;

  -- Get previous successful deployment
  SELECT version INTO v_previous_version
  FROM deployments.deployments
  WHERE service_id = v_service_id
    AND environment = v_environment
    AND status = 'success'
    AND id < p_deployment_id
  ORDER BY started_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No previous successful deployment found for rollback';
  END IF;

  -- Create rollback deployment
  INSERT INTO deployments.deployments (
    service_id,
    version,
    environment,
    status,
    strategy,
    triggered_by,
    trigger_type,
    rollback_from_deployment_id
  ) VALUES (
    v_service_id,
    v_previous_version,
    v_environment,
    'in_progress',
    'rolling',
    p_triggered_by,
    'rollback',
    p_deployment_id
  ) RETURNING id INTO v_new_deployment_id;

  -- Mark original deployment as rolled back
  UPDATE deployments.deployments
  SET status = 'rolled_back'
  WHERE id = p_deployment_id;

  -- Log event
  INSERT INTO deployments.events (deployment_id, event_type, message, severity)
  VALUES (
    v_new_deployment_id,
    'rollback_initiated',
    format('Rollback initiated from deployment %s to version %s', p_deployment_id, v_previous_version),
    'warning'
  );

  RETURN v_new_deployment_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Seed data: Example deployments
-- =====================================================
INSERT INTO deployments.deployments (
  service_id,
  version,
  environment,
  status,
  strategy,
  started_at,
  completed_at,
  duration_seconds,
  triggered_by,
  commit_sha,
  commit_message,
  health_check_passed
)
SELECT
  s.id,
  '1.0.' || (random() * 100)::int,
  (ARRAY['development', 'staging', 'production'])[1 + floor(random() * 3)],
  (ARRAY['success', 'success', 'success', 'failed'])[1 + floor(random() * 4)],
  'rolling',
  NOW() - (random() * INTERVAL '7 days'),
  NOW() - (random() * INTERVAL '7 days') + (random() * INTERVAL '5 minutes'),
  60 + (random() * 300)::int,
  'ci-cd-bot',
  substr(md5(random()::text), 1, 40),
  'Deploy version update',
  random() > 0.1
FROM registry.services s
WHERE s.type NOT IN ('infrastructure')
ORDER BY random()
LIMIT 20;

COMMENT ON SCHEMA deployments IS 'Deployment tracking and management system';
COMMENT ON TABLE deployments.deployments IS 'Deployment history and status';
COMMENT ON TABLE deployments.events IS 'Detailed deployment event log';
COMMENT ON TABLE deployments.instances IS 'Instance-level deployment tracking for rolling updates';
