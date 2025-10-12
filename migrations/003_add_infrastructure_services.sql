-- Migration: Add Infrastructure Services
-- Version: 003
-- Created: 2025-10-06
-- Description: Add missing infrastructure services (postgres, redis, minio, n8n)

INSERT INTO registry.services (name, type, description, port_default, critical, health_endpoint) VALUES
  ('postgres', 'infrastructure', 'PostgreSQL database - primary datastore', 5432, true, NULL),
  ('redis', 'infrastructure', 'Redis cache and session store', 6379, false, NULL),
  ('minio', 'infrastructure', 'MinIO S3-compatible object storage', 9000, false, '/minio/health/live'),
  ('svc-n8n', 'platform', 'n8n workflow automation', 5678, false, '/healthz')
ON CONFLICT (name) DO NOTHING;

-- Log infrastructure services addition
INSERT INTO registry.service_events (service_id, event_type, severity, message, created_by)
SELECT id, 'service_registered', 'info', 'Infrastructure service added to registry', 'migration_003'
FROM registry.services
WHERE name IN ('postgres', 'redis', 'minio', 'svc-n8n');

SELECT
  COUNT(*) as total_services,
  COUNT(*) FILTER (WHERE type = 'infrastructure') as infrastructure_services
FROM registry.services;
