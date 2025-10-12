-- Migration: Create Service Registry Schema
-- Version: 001
-- Created: 2025-10-06
-- Description: Centralized service registry for dynamic service discovery and health tracking

-- Create schema
CREATE SCHEMA IF NOT EXISTS registry;

-- =====================================================
-- Table: services
-- Static service definitions
-- =====================================================
CREATE TABLE IF NOT EXISTS registry.services (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  type VARCHAR(50) NOT NULL,
  description TEXT,
  port_default INT NOT NULL,
  health_endpoint VARCHAR(255) DEFAULT '/health',
  critical BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_services_name ON registry.services(name);
CREATE INDEX idx_services_type ON registry.services(type);
CREATE INDEX idx_services_critical ON registry.services(critical);

COMMENT ON TABLE registry.services IS 'Static service definitions and configurations';
COMMENT ON COLUMN registry.services.name IS 'Unique service identifier (e.g., svc-auth)';
COMMENT ON COLUMN registry.services.critical IS 'Whether service is critical for platform operation';

-- =====================================================
-- Table: service_instances
-- Dynamic service instance registrations
-- =====================================================
CREATE TABLE IF NOT EXISTS registry.service_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id INT NOT NULL REFERENCES registry.services(id) ON DELETE CASCADE,

  -- Instance identification
  instance_id VARCHAR(100) NOT NULL,
  version VARCHAR(50) NOT NULL,

  -- Network
  host VARCHAR(255) NOT NULL,
  port INT NOT NULL,
  protocol VARCHAR(10) DEFAULT 'http',

  -- Status
  status VARCHAR(20) DEFAULT 'starting',
  last_heartbeat TIMESTAMPTZ DEFAULT NOW(),

  -- Deployment context
  environment VARCHAR(50) DEFAULT 'development',
  region VARCHAR(50),
  datacenter VARCHAR(50),
  tenant_id VARCHAR(100),

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,
  capabilities JSONB DEFAULT '[]'::jsonb,

  -- Lifecycle
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  stopped_at TIMESTAMPTZ,

  CONSTRAINT unique_instance UNIQUE(service_id, instance_id, environment),
  CONSTRAINT valid_status CHECK (status IN ('starting', 'healthy', 'degraded', 'unhealthy', 'stopped')),
  CONSTRAINT valid_protocol CHECK (protocol IN ('http', 'https', 'grpc', 'tcp'))
);

CREATE INDEX idx_instances_service ON registry.service_instances(service_id);
CREATE INDEX idx_instances_status ON registry.service_instances(status);
CREATE INDEX idx_instances_heartbeat ON registry.service_instances(last_heartbeat);
CREATE INDEX idx_instances_env ON registry.service_instances(environment);
CREATE INDEX idx_instances_tenant ON registry.service_instances(tenant_id) WHERE tenant_id IS NOT NULL;
CREATE INDEX idx_instances_active ON registry.service_instances(service_id, status, environment)
  WHERE status IN ('healthy', 'degraded');

COMMENT ON TABLE registry.service_instances IS 'Dynamic service instance registrations for autoscaling and discovery';
COMMENT ON COLUMN registry.service_instances.tenant_id IS 'For tenant-isolated service instances';
COMMENT ON COLUMN registry.service_instances.capabilities IS 'Feature flags/capabilities array';

-- =====================================================
-- Table: service_health_checks
-- Health check history for SLO tracking
-- =====================================================
CREATE TABLE IF NOT EXISTS registry.service_health_checks (
  id BIGSERIAL PRIMARY KEY,
  instance_id UUID NOT NULL REFERENCES registry.service_instances(id) ON DELETE CASCADE,

  checked_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(20) NOT NULL,
  response_time_ms INT,

  -- Health details
  health_data JSONB DEFAULT '{}'::jsonb,
  error_message TEXT,

  -- Metrics snapshot
  cpu_percent DECIMAL(5,2),
  memory_percent DECIMAL(5,2),

  CONSTRAINT valid_health_status CHECK (status IN ('healthy', 'degraded', 'unhealthy'))
);

CREATE INDEX idx_health_instance_time ON registry.service_health_checks(instance_id, checked_at DESC);
CREATE INDEX idx_health_status_time ON registry.service_health_checks(status, checked_at DESC);
CREATE INDEX idx_health_recent ON registry.service_health_checks(checked_at DESC) WHERE checked_at > NOW() - INTERVAL '24 hours';

COMMENT ON TABLE registry.service_health_checks IS 'Health check history for analytics and SLO calculations';

-- =====================================================
-- Table: service_dependencies
-- Service dependency graph
-- =====================================================
CREATE TABLE IF NOT EXISTS registry.service_dependencies (
  id SERIAL PRIMARY KEY,
  service_id INT NOT NULL REFERENCES registry.services(id) ON DELETE CASCADE,
  depends_on_service_id INT NOT NULL REFERENCES registry.services(id) ON DELETE CASCADE,

  dependency_type VARCHAR(50) DEFAULT 'required',
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_dependency UNIQUE(service_id, depends_on_service_id),
  CONSTRAINT no_self_dependency CHECK (service_id != depends_on_service_id),
  CONSTRAINT valid_dep_type CHECK (dependency_type IN ('required', 'optional', 'runtime'))
);

CREATE INDEX idx_deps_service ON registry.service_dependencies(service_id);
CREATE INDEX idx_deps_reverse ON registry.service_dependencies(depends_on_service_id);

COMMENT ON TABLE registry.service_dependencies IS 'Service dependency graph for impact analysis';

-- =====================================================
-- Table: service_events
-- Audit log for service lifecycle events
-- =====================================================
CREATE TABLE IF NOT EXISTS registry.service_events (
  id BIGSERIAL PRIMARY KEY,
  instance_id UUID REFERENCES registry.service_instances(id) ON DELETE SET NULL,
  service_id INT REFERENCES registry.services(id) ON DELETE SET NULL,

  event_type VARCHAR(50) NOT NULL,
  severity VARCHAR(20) DEFAULT 'info',
  message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by VARCHAR(100),

  CONSTRAINT valid_severity CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical'))
);

CREATE INDEX idx_events_instance_time ON registry.service_events(instance_id, created_at DESC) WHERE instance_id IS NOT NULL;
CREATE INDEX idx_events_service_time ON registry.service_events(service_id, created_at DESC) WHERE service_id IS NOT NULL;
CREATE INDEX idx_events_type_time ON registry.service_events(event_type, created_at DESC);
CREATE INDEX idx_events_time ON registry.service_events(created_at DESC);
CREATE INDEX idx_events_severity ON registry.service_events(severity, created_at DESC) WHERE severity IN ('error', 'critical');

COMMENT ON TABLE registry.service_events IS 'Audit log for service lifecycle and operational events';

-- =====================================================
-- Functions
-- =====================================================

-- Function: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION registry.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update services.updated_at
CREATE TRIGGER trigger_services_updated_at
  BEFORE UPDATE ON registry.services
  FOR EACH ROW
  EXECUTE FUNCTION registry.update_updated_at_column();

-- Function: Get healthy instances for service discovery
CREATE OR REPLACE FUNCTION registry.get_healthy_instances(
  p_service_name VARCHAR,
  p_environment VARCHAR DEFAULT 'development',
  p_tenant_id VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  instance_id UUID,
  host VARCHAR,
  port INT,
  version VARCHAR,
  status VARCHAR,
  last_heartbeat TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    si.id,
    si.host,
    si.port,
    si.version,
    si.status,
    si.last_heartbeat
  FROM registry.service_instances si
  JOIN registry.services s ON si.service_id = s.id
  WHERE s.name = p_service_name
    AND si.environment = p_environment
    AND si.status IN ('healthy', 'degraded')
    AND si.last_heartbeat > NOW() - INTERVAL '2 minutes'
    AND (p_tenant_id IS NULL OR si.tenant_id = p_tenant_id)
  ORDER BY si.last_heartbeat DESC;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION registry.get_healthy_instances IS 'Service discovery: returns healthy instances for a service';

-- Function: Calculate service availability (SLO)
CREATE OR REPLACE FUNCTION registry.calculate_availability(
  p_service_name VARCHAR,
  p_hours INT DEFAULT 24
)
RETURNS DECIMAL AS $$
DECLARE
  v_availability DECIMAL;
BEGIN
  SELECT
    COALESCE(
      COUNT(CASE WHEN hc.status = 'healthy' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0),
      100.0
    ) INTO v_availability
  FROM registry.service_health_checks hc
  JOIN registry.service_instances si ON hc.instance_id = si.id
  JOIN registry.services s ON si.service_id = s.id
  WHERE s.name = p_service_name
    AND hc.checked_at > NOW() - (p_hours || ' hours')::INTERVAL;

  RETURN v_availability;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION registry.calculate_availability IS 'Calculate service availability percentage over time period';

-- =====================================================
-- Views
-- =====================================================

-- View: Active services with instance count
CREATE OR REPLACE VIEW registry.v_service_status AS
SELECT
  s.id as service_id,
  s.name,
  s.type,
  s.critical,
  COUNT(si.id) FILTER (WHERE si.status = 'healthy') as healthy_instances,
  COUNT(si.id) FILTER (WHERE si.status = 'degraded') as degraded_instances,
  COUNT(si.id) FILTER (WHERE si.status = 'unhealthy') as unhealthy_instances,
  COUNT(si.id) as total_instances,
  MAX(si.last_heartbeat) as last_seen
FROM registry.services s
LEFT JOIN registry.service_instances si ON s.id = si.service_id
  AND si.last_heartbeat > NOW() - INTERVAL '5 minutes'
GROUP BY s.id, s.name, s.type, s.critical;

COMMENT ON VIEW registry.v_service_status IS 'Current service status with instance counts';

-- View: Recent service events
CREATE OR REPLACE VIEW registry.v_recent_events AS
SELECT
  e.id,
  e.event_type,
  e.severity,
  e.message,
  s.name as service_name,
  si.instance_id,
  e.created_at
FROM registry.service_events e
LEFT JOIN registry.services s ON e.service_id = s.id
LEFT JOIN registry.service_instances si ON e.instance_id = si.id
WHERE e.created_at > NOW() - INTERVAL '24 hours'
ORDER BY e.created_at DESC;

COMMENT ON VIEW registry.v_recent_events IS 'Recent service events from last 24 hours';

-- =====================================================
-- Initial Grants
-- =====================================================

-- Grant access to application user
-- GRANT USAGE ON SCHEMA registry TO ewh_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA registry TO ewh_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA registry TO ewh_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA registry TO ewh_app;

-- =====================================================
-- Maintenance Job Recommendations
-- =====================================================

-- TODO: Create background job to:
-- 1. Mark instances as unhealthy if no heartbeat > 2 minutes
-- 2. Delete health_checks older than 30 days
-- 3. Archive stopped instances older than 7 days
-- 4. Send alerts for critical service degradation

COMMENT ON SCHEMA registry IS 'Centralized service registry for dynamic discovery, health tracking, and SLO monitoring';
