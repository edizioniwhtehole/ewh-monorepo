-- Migration 007: Seed SLO Targets for All Services
-- Creates comprehensive SLO targets for all 52 services in the registry

-- First, remove duplicate/sample data to avoid conflicts
TRUNCATE TABLE slo.targets RESTART IDENTITY CASCADE;

-- Insert SLO targets for ALL services from registry
-- Each service gets 3 SLO targets: availability (30d), latency_p95 (30d), error_rate (30d)

INSERT INTO slo.targets (service_name, metric_name, target_value, window_duration, error_budget_total, description, created_by)
SELECT
  s.name as service_name,
  'availability' as metric_name,
  CASE
    WHEN s.critical = true THEN 99.95  -- Critical services: 99.95%
    WHEN s.type IN ('frontend', 'gateway', 'core') THEN 99.9  -- Important services: 99.9%
    ELSE 99.5  -- Standard services: 99.5%
  END as target_value,
  '30d' as window_duration,
  100 as error_budget_total,
  s.name || ' availability SLO - ' ||
  CASE
    WHEN s.critical = true THEN 'Critical'
    WHEN s.type IN ('frontend', 'gateway', 'core') THEN 'High Priority'
    ELSE 'Standard'
  END as description,
  'system' as created_by
FROM registry.services s
WHERE s.name NOT IN ('postgres', 'redis', 'minio');  -- Skip infrastructure

-- Latency SLO targets
INSERT INTO slo.targets (service_name, metric_name, target_value, window_duration, error_budget_total, description, created_by)
SELECT
  s.name as service_name,
  'latency_p95' as metric_name,
  CASE
    WHEN s.type = 'frontend' THEN 300  -- Frontend: 300ms
    WHEN s.type = 'gateway' THEN 200   -- Gateway: 200ms
    WHEN s.type = 'core' THEN 250      -- Core: 250ms
    WHEN s.type IN ('platform', 'monitoring') THEN 400  -- Platform: 400ms
    ELSE 500  -- Others: 500ms
  END as target_value,
  '30d' as window_duration,
  100 as error_budget_total,
  s.name || ' p95 latency under ' ||
  CASE
    WHEN s.type = 'frontend' THEN '300ms'
    WHEN s.type = 'gateway' THEN '200ms'
    WHEN s.type = 'core' THEN '250ms'
    WHEN s.type IN ('platform', 'monitoring') THEN '400ms'
    ELSE '500ms'
  END as description,
  'system' as created_by
FROM registry.services s
WHERE s.name NOT IN ('postgres', 'redis', 'minio');

-- Error rate SLO targets
INSERT INTO slo.targets (service_name, metric_name, target_value, window_duration, error_budget_total, description, created_by)
SELECT
  s.name as service_name,
  'error_rate' as metric_name,
  CASE
    WHEN s.critical = true THEN 0.1    -- Critical: 0.1%
    WHEN s.type IN ('frontend', 'gateway', 'core') THEN 0.5  -- Important: 0.5%
    ELSE 1.0  -- Standard: 1.0%
  END as target_value,
  '30d' as window_duration,
  100 as error_budget_total,
  s.name || ' error rate under ' ||
  CASE
    WHEN s.critical = true THEN '0.1%'
    WHEN s.type IN ('frontend', 'gateway', 'core') THEN '0.5%'
    ELSE '1.0%'
  END as description,
  'system' as created_by
FROM registry.services s
WHERE s.name NOT IN ('postgres', 'redis', 'minio');

-- Add special SLO targets for infrastructure services
INSERT INTO slo.targets (service_name, metric_name, target_value, window_duration, error_budget_total, description, created_by) VALUES
('postgres', 'availability', 99.99, '30d', 100, 'PostgreSQL database availability - critical infrastructure', 'system'),
('redis', 'availability', 99.9, '30d', 100, 'Redis cache availability - critical infrastructure', 'system'),
('minio', 'availability', 99.9, '30d', 100, 'MinIO object storage availability - critical infrastructure', 'system');

-- Add 7-day window targets for critical services (faster alerting)
INSERT INTO slo.targets (service_name, metric_name, target_value, window_duration, error_budget_total, description, created_by)
SELECT
  s.name as service_name,
  'availability' as metric_name,
  99.5 as target_value,  -- Slightly lower for short window
  '7d' as window_duration,
  100 as error_budget_total,
  s.name || ' weekly availability SLO' as description,
  'system' as created_by
FROM registry.services s
WHERE s.critical = true;

-- Add 90-day window targets for trend analysis
INSERT INTO slo.targets (service_name, metric_name, target_value, window_duration, error_budget_total, description, created_by)
SELECT
  s.name as service_name,
  'availability' as metric_name,
  99.0 as target_value,  -- Lower target for long-term view
  '90d' as window_duration,
  100 as error_budget_total,
  s.name || ' quarterly availability SLO' as description,
  'system' as created_by
FROM registry.services s
WHERE s.type IN ('frontend', 'gateway', 'core') OR s.critical = true;

-- Verify counts
DO $$
DECLARE
  total_targets INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_targets FROM slo.targets;
  RAISE NOTICE 'Total SLO targets created: %', total_targets;
END $$;
