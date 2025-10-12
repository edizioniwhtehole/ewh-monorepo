-- =====================================================
-- ENTERPRISE API GATEWAY UPGRADE
-- Adds enterprise-grade features to the API Gateway
-- =====================================================

-- =====================================================
-- 1. SERVICE REGISTRY & DISCOVERY
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.service_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Service identity
  service_name VARCHAR(255) NOT NULL,
  instance_id VARCHAR(255) NOT NULL UNIQUE,
  version VARCHAR(50) NOT NULL,

  -- Network info
  host VARCHAR(255) NOT NULL,
  port INTEGER NOT NULL,
  protocol VARCHAR(20) DEFAULT 'http',          -- http, https, grpc, ws, wss
  base_path VARCHAR(500) DEFAULT '/',

  -- Health
  health_check_path VARCHAR(500),
  health_check_interval INTEGER DEFAULT 30000,  -- MS
  health_status VARCHAR(20) DEFAULT 'unknown',  -- healthy, unhealthy, unknown, starting
  last_health_check TIMESTAMP WITH TIME ZONE,
  consecutive_failures INTEGER DEFAULT 0,

  -- Metadata
  region VARCHAR(100),
  zone VARCHAR(100),
  datacenter VARCHAR(100),
  tags JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',

  -- Capabilities
  capabilities TEXT[] DEFAULT '{}',             -- graphql, grpc, websocket, etc.

  -- Weights for load balancing
  weight INTEGER DEFAULT 100,                   -- For weighted load balancing
  max_connections INTEGER,                      -- Connection limit
  current_connections INTEGER DEFAULT 0,

  -- Lifecycle
  status VARCHAR(20) DEFAULT 'active',          -- active, draining, disabled, maintenance
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_heartbeat TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deregistered_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (protocol IN ('http', 'https', 'grpc', 'ws', 'wss', 'tcp')),
  CHECK (health_status IN ('healthy', 'unhealthy', 'unknown', 'starting')),
  CHECK (status IN ('active', 'draining', 'disabled', 'maintenance'))
);

CREATE INDEX idx_service_instances_name ON workflow.service_instances(service_name);
CREATE INDEX idx_service_instances_status ON workflow.service_instances(status);
CREATE INDEX idx_service_instances_health ON workflow.service_instances(health_status);
CREATE INDEX idx_service_instances_region ON workflow.service_instances(region);

-- =====================================================
-- 2. ENHANCED ROUTING WITH TRAFFIC MANAGEMENT
-- =====================================================

-- Add enterprise columns to existing gateway_routes
ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  route_type VARCHAR(50) DEFAULT 'http';                    -- http, graphql, grpc, websocket

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  traffic_split JSONB DEFAULT '{}';                         -- For A/B testing, canary deploys

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  geo_routing JSONB DEFAULT '{}';                           -- Region-based routing rules

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  header_routing JSONB DEFAULT '{}';                        -- Route based on headers

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  query_routing JSONB DEFAULT '{}';                         -- Route based on query params

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  sticky_session_enabled BOOLEAN DEFAULT false;

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  sticky_session_cookie VARCHAR(100) DEFAULT 'GATEWAY_SESSION';

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  websocket_enabled BOOLEAN DEFAULT false;

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  grpc_enabled BOOLEAN DEFAULT false;

ALTER TABLE workflow.gateway_routes ADD COLUMN IF NOT EXISTS
  openapi_spec JSONB DEFAULT '{}';                          -- OpenAPI/Swagger spec

-- Traffic Split Deployments
CREATE TABLE IF NOT EXISTS workflow.traffic_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES workflow.gateway_routes(id) ON DELETE CASCADE,

  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Split configuration
  splits JSONB NOT NULL,                                    -- [{"target": "v1", "weight": 90}, {"target": "v2", "weight": 10}]

  -- Criteria
  match_criteria JSONB DEFAULT '{}',                        -- Headers, cookies, user segments

  -- Status
  enabled BOOLEAN DEFAULT true,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_traffic_splits_route ON workflow.traffic_splits(route_id);

-- =====================================================
-- 3. ADVANCED AUTHENTICATION & SECURITY
-- =====================================================

-- API Keys management
CREATE TABLE IF NOT EXISTS workflow.api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Key identity
  key_hash VARCHAR(255) NOT NULL UNIQUE,                    -- bcrypt hash of actual key
  key_prefix VARCHAR(20) NOT NULL,                          -- First 8 chars for identification
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Ownership
  tenant_id UUID,
  user_id UUID,

  -- Permissions
  scopes TEXT[] DEFAULT '{}',
  allowed_routes TEXT[] DEFAULT '{}',                       -- Route IDs or patterns
  allowed_ips INET[] DEFAULT '{}',

  -- Rate limiting
  rate_limit_override JSONB,                                -- Custom rate limits for this key

  -- Quotas
  daily_quota INTEGER,
  monthly_quota INTEGER,
  total_quota INTEGER,

  -- Usage tracking
  request_count INTEGER DEFAULT 0,
  daily_request_count INTEGER DEFAULT 0,
  monthly_request_count INTEGER DEFAULT 0,
  last_used_at TIMESTAMP WITH TIME ZONE,
  last_used_ip INET,

  -- Lifecycle
  expires_at TIMESTAMP WITH TIME ZONE,
  revoked BOOLEAN DEFAULT false,
  revoked_at TIMESTAMP WITH TIME ZONE,
  revoked_reason TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_api_keys_hash ON workflow.api_keys(key_hash);
CREATE INDEX idx_api_keys_prefix ON workflow.api_keys(key_prefix);
CREATE INDEX idx_api_keys_tenant ON workflow.api_keys(tenant_id);
CREATE INDEX idx_api_keys_user ON workflow.api_keys(user_id);

-- OAuth2 Client Credentials
CREATE TABLE IF NOT EXISTS workflow.oauth2_clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  client_id VARCHAR(255) NOT NULL UNIQUE,
  client_secret_hash VARCHAR(255) NOT NULL,

  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Ownership
  tenant_id UUID,

  -- OAuth2 settings
  grant_types TEXT[] NOT NULL,                              -- client_credentials, authorization_code, etc.
  redirect_uris TEXT[] DEFAULT '{}',
  scopes TEXT[] DEFAULT '{}',

  -- Token settings
  access_token_ttl INTEGER DEFAULT 3600,                    -- Seconds
  refresh_token_ttl INTEGER DEFAULT 2592000,                -- 30 days

  -- Status
  enabled BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_oauth2_clients_client_id ON workflow.oauth2_clients(client_id);
CREATE INDEX idx_oauth2_clients_tenant ON workflow.oauth2_clients(tenant_id);

-- mTLS Configuration
CREATE TABLE IF NOT EXISTS workflow.mtls_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,

  -- Certificates
  ca_certificate TEXT NOT NULL,
  verify_client BOOLEAN DEFAULT true,
  verify_depth INTEGER DEFAULT 1,

  -- Allowed subjects
  allowed_subjects TEXT[] DEFAULT '{}',                     -- CN patterns
  allowed_issuers TEXT[] DEFAULT '{}',

  -- Applied to routes
  route_ids UUID[] DEFAULT '{}',

  enabled BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- WAF Rules (Web Application Firewall)
CREATE TABLE IF NOT EXISTS workflow.waf_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,

  -- Rule configuration
  rule_type VARCHAR(50) NOT NULL,                           -- sql_injection, xss, rate_limit, ip_block, geo_block
  pattern TEXT,                                             -- Regex pattern
  action VARCHAR(50) NOT NULL,                              -- block, allow, log, challenge

  -- Matching
  match_path TEXT,                                          -- Path pattern
  match_method VARCHAR(10),
  match_header JSONB,                                       -- {"User-Agent": "pattern"}

  -- Severity
  severity VARCHAR(20) DEFAULT 'medium',                    -- low, medium, high, critical

  -- Status
  enabled BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (rule_type IN ('sql_injection', 'xss', 'rate_limit', 'ip_block', 'geo_block', 'custom')),
  CHECK (action IN ('block', 'allow', 'log', 'challenge', 'rate_limit')),
  CHECK (severity IN ('low', 'medium', 'high', 'critical'))
);

CREATE INDEX idx_waf_rules_type ON workflow.waf_rules(rule_type);
CREATE INDEX idx_waf_rules_enabled ON workflow.waf_rules(enabled);

-- =====================================================
-- 4. DISTRIBUTED TRACING & OBSERVABILITY
-- =====================================================

-- Trace spans
CREATE TABLE IF NOT EXISTS workflow.trace_spans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Trace identity
  trace_id VARCHAR(255) NOT NULL,
  span_id VARCHAR(255) NOT NULL UNIQUE,
  parent_span_id VARCHAR(255),

  -- Span details
  operation_name VARCHAR(255) NOT NULL,
  service_name VARCHAR(255) NOT NULL,

  -- Timing
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  duration_ms INTEGER,

  -- Request info
  http_method VARCHAR(10),
  http_url TEXT,
  http_status_code INTEGER,

  -- Tags & logs
  tags JSONB DEFAULT '{}',
  logs JSONB DEFAULT '[]',

  -- Baggage (context propagation)
  baggage JSONB DEFAULT '{}',

  -- Error
  error BOOLEAN DEFAULT false,
  error_message TEXT,
  error_stack TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_trace_spans_trace_id ON workflow.trace_spans(trace_id);
CREATE INDEX idx_trace_spans_parent ON workflow.trace_spans(parent_span_id);
CREATE INDEX idx_trace_spans_service ON workflow.trace_spans(service_name);
CREATE INDEX idx_trace_spans_start_time ON workflow.trace_spans(start_time DESC);

-- Metrics aggregation
CREATE TABLE IF NOT EXISTS workflow.gateway_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Time bucket
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  bucket_interval VARCHAR(20) NOT NULL,                     -- 1m, 5m, 1h, 1d

  -- Dimensions
  route_id UUID REFERENCES workflow.gateway_routes(id),
  service_name VARCHAR(255),
  method VARCHAR(10),
  status_code INTEGER,
  region VARCHAR(100),

  -- Metrics
  request_count INTEGER NOT NULL DEFAULT 0,
  error_count INTEGER NOT NULL DEFAULT 0,

  -- Latency percentiles
  avg_latency_ms DECIMAL(10,2),
  p50_latency_ms INTEGER,
  p90_latency_ms INTEGER,
  p95_latency_ms INTEGER,
  p99_latency_ms INTEGER,
  max_latency_ms INTEGER,

  -- Throughput
  bytes_sent BIGINT DEFAULT 0,
  bytes_received BIGINT DEFAULT 0,

  -- Additional metrics
  cache_hits INTEGER DEFAULT 0,
  cache_misses INTEGER DEFAULT 0,
  circuit_breaker_opens INTEGER DEFAULT 0,
  rate_limit_hits INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (bucket_interval IN ('1m', '5m', '15m', '1h', '6h', '1d'))
);

CREATE INDEX idx_gateway_metrics_timestamp ON workflow.gateway_metrics(timestamp DESC);
CREATE INDEX idx_gateway_metrics_route ON workflow.gateway_metrics(route_id);
CREATE INDEX idx_gateway_metrics_service ON workflow.gateway_metrics(service_name);
CREATE INDEX idx_gateway_metrics_bucket ON workflow.gateway_metrics(bucket_interval, timestamp DESC);

-- Alerts
CREATE TABLE IF NOT EXISTS workflow.gateway_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Alert conditions
  metric_name VARCHAR(100) NOT NULL,                        -- error_rate, latency_p99, request_count, etc.
  threshold_operator VARCHAR(10) NOT NULL,                  -- gt, lt, gte, lte, eq
  threshold_value DECIMAL(10,2) NOT NULL,
  evaluation_window INTEGER NOT NULL,                       -- Seconds

  -- Scope
  route_id UUID REFERENCES workflow.gateway_routes(id),
  service_name VARCHAR(255),

  -- Notification
  notification_channels JSONB NOT NULL,                     -- [{"type": "email", "to": "..."}, {"type": "slack", "webhook": "..."}]

  -- Status
  enabled BOOLEAN DEFAULT true,
  last_triggered_at TIMESTAMP WITH TIME ZONE,
  trigger_count INTEGER DEFAULT 0,

  -- Cooldown to prevent alert spam
  cooldown_period INTEGER DEFAULT 300,                      -- Seconds

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (threshold_operator IN ('gt', 'lt', 'gte', 'lte', 'eq', 'ne'))
);

CREATE INDEX idx_gateway_alerts_enabled ON workflow.gateway_alerts(enabled);
CREATE INDEX idx_gateway_alerts_route ON workflow.gateway_alerts(route_id);

-- =====================================================
-- 5. CACHING LAYER
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.cache_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Cache key
  cache_key VARCHAR(500) NOT NULL UNIQUE,
  cache_namespace VARCHAR(100),

  -- Route
  route_id UUID REFERENCES workflow.gateway_routes(id) ON DELETE CASCADE,

  -- Cached data
  response_body TEXT,
  response_headers JSONB,
  status_code INTEGER,

  -- Cache metadata
  etag VARCHAR(255),
  content_type VARCHAR(255),
  content_length INTEGER,

  -- TTL
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Statistics
  hit_count INTEGER DEFAULT 0,

  -- Tags for cache invalidation
  tags TEXT[] DEFAULT '{}'
);

CREATE INDEX idx_cache_entries_key ON workflow.cache_entries(cache_key);
CREATE INDEX idx_cache_entries_route ON workflow.cache_entries(route_id);
CREATE INDEX idx_cache_entries_expires ON workflow.cache_entries(expires_at);
CREATE INDEX idx_cache_entries_tags ON workflow.cache_entries USING GIN(tags);

-- =====================================================
-- 6. GRAPHQL GATEWAY
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.graphql_schemas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,

  -- Schema
  schema_sdl TEXT NOT NULL,                                 -- GraphQL SDL
  schema_version VARCHAR(50) NOT NULL,

  -- Upstream services
  service_mappings JSONB NOT NULL,                          -- Maps types/fields to services

  -- Federation
  is_federated BOOLEAN DEFAULT false,
  subgraphs JSONB DEFAULT '[]',

  -- Status
  active BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 7. QUOTA & BILLING
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.api_quotas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Subject
  tenant_id UUID,
  user_id UUID,
  api_key_id UUID REFERENCES workflow.api_keys(id),

  -- Quota definition
  quota_type VARCHAR(50) NOT NULL,                          -- requests, bandwidth, compute_time
  quota_period VARCHAR(20) NOT NULL,                        -- hourly, daily, monthly
  quota_limit BIGINT NOT NULL,

  -- Current usage
  current_usage BIGINT DEFAULT 0,

  -- Period
  period_start TIMESTAMP WITH TIME ZONE NOT NULL,
  period_end TIMESTAMP WITH TIME ZONE NOT NULL,

  -- Actions on limit
  action_on_limit VARCHAR(50) DEFAULT 'block',              -- block, throttle, alert, upgrade_prompt

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (quota_type IN ('requests', 'bandwidth', 'compute_time', 'storage')),
  CHECK (quota_period IN ('hourly', 'daily', 'monthly', 'yearly')),
  CHECK (action_on_limit IN ('block', 'throttle', 'alert', 'upgrade_prompt'))
);

CREATE INDEX idx_api_quotas_tenant ON workflow.api_quotas(tenant_id);
CREATE INDEX idx_api_quotas_user ON workflow.api_quotas(user_id);
CREATE INDEX idx_api_quotas_api_key ON workflow.api_quotas(api_key_id);
CREATE INDEX idx_api_quotas_period ON workflow.api_quotas(period_start, period_end);

-- =====================================================
-- 8. REQUEST/RESPONSE TRANSFORMATION
-- =====================================================

CREATE TABLE IF NOT EXISTS workflow.transformations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,

  -- Type
  transform_type VARCHAR(50) NOT NULL,                      -- request, response
  transform_stage VARCHAR(50) NOT NULL,                     -- pre_auth, post_auth, pre_route, post_route

  -- Transformation code
  language VARCHAR(50) NOT NULL DEFAULT 'javascript',       -- javascript, lua, wasm
  code TEXT NOT NULL,

  -- Applied to
  route_ids UUID[] DEFAULT '{}',

  -- Execution
  timeout_ms INTEGER DEFAULT 5000,

  enabled BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (transform_type IN ('request', 'response', 'both')),
  CHECK (transform_stage IN ('pre_auth', 'post_auth', 'pre_route', 'post_route')),
  CHECK (language IN ('javascript', 'lua', 'wasm', 'python'))
);

-- =====================================================
-- 9. MATERIALIZED VIEWS FOR PERFORMANCE
-- =====================================================

-- Active healthy service instances view
CREATE MATERIALIZED VIEW workflow.healthy_service_instances AS
SELECT
  si.*,
  COUNT(*) OVER (PARTITION BY si.service_name) as instance_count
FROM workflow.service_instances si
WHERE si.status = 'active'
  AND si.health_status = 'healthy'
  AND si.last_heartbeat > NOW() - INTERVAL '2 minutes';

CREATE UNIQUE INDEX idx_healthy_instances_id ON workflow.healthy_service_instances(id);
CREATE INDEX idx_healthy_instances_service ON workflow.healthy_service_instances(service_name);

-- Route performance view
CREATE MATERIALIZED VIEW workflow.route_performance_summary AS
SELECT
  route_id,
  COUNT(*) as total_requests,
  AVG(response_time_ms) as avg_response_time,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms) as p95_response_time,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time_ms) as p99_response_time,
  SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) as error_count,
  SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100 as error_rate
FROM workflow.gateway_route_analytics
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY route_id;

CREATE UNIQUE INDEX idx_route_performance_route ON workflow.route_performance_summary(route_id);

-- =====================================================
-- 10. HELPER FUNCTIONS
-- =====================================================

-- Function to refresh service instances
CREATE OR REPLACE FUNCTION workflow.refresh_healthy_instances()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY workflow.healthy_service_instances;
END;
$$ LANGUAGE plpgsql;

-- Function to refresh route performance
CREATE OR REPLACE FUNCTION workflow.refresh_route_performance()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY workflow.route_performance_summary;
END;
$$ LANGUAGE plpgsql;

-- Function to get next service instance (load balancing)
CREATE OR REPLACE FUNCTION workflow.get_next_service_instance(
  p_service_name VARCHAR,
  p_strategy VARCHAR DEFAULT 'round-robin'
)
RETURNS TABLE (
  instance_id UUID,
  host VARCHAR,
  port INTEGER,
  protocol VARCHAR
) AS $$
BEGIN
  IF p_strategy = 'round-robin' THEN
    RETURN QUERY
    SELECT si.id, si.host, si.port, si.protocol
    FROM workflow.healthy_service_instances si
    WHERE si.service_name = p_service_name
    ORDER BY si.last_heartbeat
    LIMIT 1;

  ELSIF p_strategy = 'least-conn' THEN
    RETURN QUERY
    SELECT si.id, si.host, si.port, si.protocol
    FROM workflow.healthy_service_instances si
    WHERE si.service_name = p_service_name
    ORDER BY si.current_connections, si.last_heartbeat
    LIMIT 1;

  ELSIF p_strategy = 'weighted' THEN
    RETURN QUERY
    SELECT si.id, si.host, si.port, si.protocol
    FROM workflow.healthy_service_instances si
    WHERE si.service_name = p_service_name
    ORDER BY RANDOM() * si.weight DESC
    LIMIT 1;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to record API key usage
CREATE OR REPLACE FUNCTION workflow.record_api_key_usage(
  p_key_hash VARCHAR,
  p_ip INET
)
RETURNS BOOLEAN AS $$
DECLARE
  v_key_id UUID;
  v_daily_quota INTEGER;
  v_monthly_quota INTEGER;
  v_daily_count INTEGER;
  v_monthly_count INTEGER;
BEGIN
  SELECT id, daily_quota, monthly_quota, daily_request_count, monthly_request_count
  INTO v_key_id, v_daily_quota, v_monthly_quota, v_daily_count, v_monthly_count
  FROM workflow.api_keys
  WHERE key_hash = p_key_hash
    AND (expires_at IS NULL OR expires_at > NOW())
    AND NOT revoked;

  IF v_key_id IS NULL THEN
    RETURN false;
  END IF;

  -- Check quotas
  IF v_daily_quota IS NOT NULL AND v_daily_count >= v_daily_quota THEN
    RETURN false;
  END IF;

  IF v_monthly_quota IS NOT NULL AND v_monthly_count >= v_monthly_quota THEN
    RETURN false;
  END IF;

  -- Update usage
  UPDATE workflow.api_keys
  SET
    request_count = request_count + 1,
    daily_request_count = daily_request_count + 1,
    monthly_request_count = monthly_request_count + 1,
    last_used_at = NOW(),
    last_used_ip = p_ip
  WHERE id = v_key_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 11. UPDATE TRIGGERS
-- =====================================================

CREATE TRIGGER update_service_instances_updated_at
  BEFORE UPDATE ON workflow.service_instances
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_traffic_splits_updated_at
  BEFORE UPDATE ON workflow.traffic_splits
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at
  BEFORE UPDATE ON workflow.api_keys
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_oauth2_clients_updated_at
  BEFORE UPDATE ON workflow.oauth2_clients
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_mtls_configs_updated_at
  BEFORE UPDATE ON workflow.mtls_configs
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_waf_rules_updated_at
  BEFORE UPDATE ON workflow.waf_rules
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_gateway_alerts_updated_at
  BEFORE UPDATE ON workflow.gateway_alerts
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_graphql_schemas_updated_at
  BEFORE UPDATE ON workflow.graphql_schemas
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_api_quotas_updated_at
  BEFORE UPDATE ON workflow.api_quotas
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_transformations_updated_at
  BEFORE UPDATE ON workflow.transformations
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- =====================================================
-- 12. SEED DATA
-- =====================================================

-- Seed common WAF rules
INSERT INTO workflow.waf_rules (name, description, rule_type, pattern, action, severity, priority)
VALUES
  ('Block SQL Injection', 'Detects common SQL injection patterns', 'sql_injection',
   '(?i)(union.*select|insert.*into|delete.*from|drop.*table|exec.*\()', 'block', 'critical', 100),
  ('Block XSS', 'Detects cross-site scripting attempts', 'xss',
   '(?i)(<script|javascript:|onerror=|onload=)', 'block', 'high', 90),
  ('Rate Limit Aggressive', 'Block excessive requests from single IP', 'rate_limit',
   NULL, 'rate_limit', 'medium', 50)
ON CONFLICT (name) DO NOTHING;

-- Seed default alert
INSERT INTO workflow.gateway_alerts (name, description, metric_name, threshold_operator, threshold_value, evaluation_window, notification_channels)
VALUES
  ('High Error Rate', 'Alert when error rate exceeds 5%', 'error_rate', 'gt', 5.0, 300,
   '[{"type": "console", "enabled": true}]'::jsonb),
  ('High Latency P99', 'Alert when P99 latency exceeds 2000ms', 'latency_p99', 'gt', 2000.0, 300,
   '[{"type": "console", "enabled": true}]'::jsonb)
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE workflow.service_instances IS 'Service registry for dynamic service discovery';
COMMENT ON TABLE workflow.traffic_splits IS 'A/B testing and canary deployment configurations';
COMMENT ON TABLE workflow.api_keys IS 'API key management for external clients';
COMMENT ON TABLE workflow.oauth2_clients IS 'OAuth2 client credentials for M2M authentication';
COMMENT ON TABLE workflow.mtls_configs IS 'Mutual TLS configuration for service-to-service auth';
COMMENT ON TABLE workflow.waf_rules IS 'Web Application Firewall rules for security';
COMMENT ON TABLE workflow.trace_spans IS 'Distributed tracing spans (OpenTelemetry compatible)';
COMMENT ON TABLE workflow.gateway_metrics IS 'Time-series metrics for observability';
COMMENT ON TABLE workflow.gateway_alerts IS 'Alert definitions for monitoring';
COMMENT ON TABLE workflow.cache_entries IS 'Response cache for improved performance';
COMMENT ON TABLE workflow.graphql_schemas IS 'GraphQL schema registry for unified API';
COMMENT ON TABLE workflow.api_quotas IS 'Usage quotas for billing and rate limiting';
COMMENT ON TABLE workflow.transformations IS 'Request/response transformation rules';
