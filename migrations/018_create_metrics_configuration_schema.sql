-- Metrics Configuration System
-- Allows admins to configure custom application metrics collection from services

-- Metrics source definitions (services to scrape)
CREATE TABLE IF NOT EXISTS metrics.metrics_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Source identification
  service_name VARCHAR(255) NOT NULL,
  source_type VARCHAR(50) NOT NULL CHECK (source_type IN ('prometheus', 'http-json', 'database', 'custom')),
  enabled BOOLEAN DEFAULT true,

  -- Connection details
  endpoint_url VARCHAR(500) NOT NULL, -- e.g., http://service:port/metrics
  scrape_interval_seconds INTEGER DEFAULT 30, -- How often to scrape
  timeout_seconds INTEGER DEFAULT 10,

  -- Authentication
  auth_type VARCHAR(50) CHECK (auth_type IN ('none', 'basic', 'bearer', 'api-key', 'oauth2')),
  auth_config JSONB DEFAULT '{}', -- { username, password, token, etc. }

  -- Headers and options
  custom_headers JSONB DEFAULT '{}',
  query_params JSONB DEFAULT '{}',

  -- Metric mapping (for non-Prometheus sources)
  metric_mappings JSONB DEFAULT '{}', -- Map source fields to standard metrics

  -- Data transformation
  transform_script TEXT, -- Optional JS/Python script to transform data

  -- Health check
  health_check_endpoint VARCHAR(500),
  last_scrape_at TIMESTAMP WITH TIME ZONE,
  last_scrape_status VARCHAR(50), -- 'success', 'failed', 'timeout'
  last_error TEXT,

  -- Lifecycle
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_metrics_sources_service ON metrics.metrics_sources(service_name);
CREATE INDEX idx_metrics_sources_enabled ON metrics.metrics_sources(enabled);
CREATE INDEX idx_metrics_sources_type ON metrics.metrics_sources(source_type);

-- Custom metrics definitions (business/application metrics)
CREATE TABLE IF NOT EXISTS metrics.custom_metric_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Metric identification
  metric_name VARCHAR(255) NOT NULL UNIQUE,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) CHECK (category IN ('business', 'application', 'infrastructure', 'security', 'custom')),

  -- Metric type
  metric_type VARCHAR(50) NOT NULL CHECK (metric_type IN ('counter', 'gauge', 'histogram', 'summary', 'rate')),
  unit VARCHAR(50), -- 'requests', 'ms', 'bytes', '%', 'count', etc.

  -- Data source
  source_id UUID REFERENCES metrics.metrics_sources(id) ON DELETE CASCADE,
  source_path VARCHAR(500), -- JSONPath or field path in source data

  -- Aggregation
  aggregation_function VARCHAR(50) CHECK (aggregation_function IN ('sum', 'avg', 'min', 'max', 'p50', 'p95', 'p99', 'count')),
  aggregation_interval_seconds INTEGER DEFAULT 60,

  -- Labels/dimensions
  labels JSONB DEFAULT '{}', -- { service, environment, tenant, etc. }

  -- Thresholds for alerting
  warning_threshold NUMERIC,
  critical_threshold NUMERIC,
  threshold_operator VARCHAR(10) CHECK (threshold_operator IN ('>', '<', '>=', '<=', '==', '!=')),

  -- Visualization
  chart_type VARCHAR(50) CHECK (chart_type IN ('line', 'area', 'bar', 'gauge', 'counter', 'heatmap')),
  chart_color VARCHAR(50),
  display_format VARCHAR(100), -- e.g., '0.00', '0,0', '0.00%'

  -- Lifecycle
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_custom_metrics_name ON metrics.custom_metric_definitions(metric_name);
CREATE INDEX idx_custom_metrics_category ON metrics.custom_metric_definitions(category);
CREATE INDEX idx_custom_metrics_enabled ON metrics.custom_metric_definitions(enabled);
CREATE INDEX idx_custom_metrics_source ON metrics.custom_metric_definitions(source_id);

-- Collected custom metrics data
CREATE TABLE IF NOT EXISTS metrics.custom_metrics_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  metric_id UUID NOT NULL REFERENCES metrics.custom_metric_definitions(id) ON DELETE CASCADE,
  collected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Value
  value NUMERIC NOT NULL,

  -- Labels (for grouping/filtering)
  labels JSONB DEFAULT '{}',

  -- Source tracking
  source_id UUID REFERENCES metrics.metrics_sources(id),

  -- Partitioning
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_custom_metrics_data_metric ON metrics.custom_metrics_data(metric_id);
CREATE INDEX idx_custom_metrics_data_collected ON metrics.custom_metrics_data(collected_at DESC);
CREATE INDEX idx_custom_metrics_data_labels ON metrics.custom_metrics_data USING GIN(labels);

-- Pre-aggregated custom metrics (for performance)
CREATE TABLE IF NOT EXISTS metrics.custom_metrics_aggregated (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  metric_id UUID NOT NULL REFERENCES metrics.custom_metric_definitions(id) ON DELETE CASCADE,
  bucket_start TIMESTAMP WITH TIME ZONE NOT NULL,
  resolution_seconds INTEGER NOT NULL, -- 60, 300, 3600, etc.

  -- Aggregated values
  avg_value NUMERIC,
  min_value NUMERIC,
  max_value NUMERIC,
  sum_value NUMERIC,
  count_value INTEGER,
  p50_value NUMERIC,
  p95_value NUMERIC,
  p99_value NUMERIC,

  -- Labels
  labels JSONB DEFAULT '{}',

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(metric_id, bucket_start, resolution_seconds, labels)
);

CREATE INDEX idx_custom_metrics_agg_metric ON metrics.custom_metrics_aggregated(metric_id);
CREATE INDEX idx_custom_metrics_agg_bucket ON metrics.custom_metrics_aggregated(bucket_start DESC);
CREATE INDEX idx_custom_metrics_agg_resolution ON metrics.custom_metrics_aggregated(resolution_seconds);

-- Metrics dashboards configuration
CREATE TABLE IF NOT EXISTS metrics.dashboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Layout configuration
  layout JSONB NOT NULL DEFAULT '{}', -- Grid layout with widget positions

  -- Widgets on dashboard
  widgets JSONB NOT NULL DEFAULT '[]', -- [{ type, config, position, metrics[] }]

  -- Filters
  default_filters JSONB DEFAULT '{}', -- { timeRange, services, labels }

  -- Sharing
  is_public BOOLEAN DEFAULT false,
  share_token VARCHAR(100) UNIQUE,

  -- Permissions
  visible_to_roles TEXT[] DEFAULT '{}',
  owner_id UUID,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_metrics_dashboards_owner ON metrics.dashboards(owner_id);
CREATE INDEX idx_metrics_dashboards_public ON metrics.dashboards(is_public);

-- Seed default metrics sources for existing services
INSERT INTO metrics.metrics_sources (service_name, source_type, endpoint_url, scrape_interval_seconds, enabled)
VALUES
  ('svc-api-gateway', 'http-json', 'http://svc-api-gateway:4000/health', 30, true),
  ('svc-auth', 'http-json', 'http://svc-auth:4001/health', 30, true),
  ('svc-billing', 'http-json', 'http://svc-billing:4002/health', 30, true),
  ('svc-boards', 'http-json', 'http://svc-boards:4003/health', 30, true),
  ('svc-channels', 'http-json', 'http://svc-channels:4004/health', 30, true),
  ('svc-chat', 'http-json', 'http://svc-chat:4005/health', 30, true)
ON CONFLICT DO NOTHING;

-- Seed common custom metrics
INSERT INTO metrics.custom_metric_definitions (metric_name, display_name, description, category, metric_type, unit, chart_type)
VALUES
  ('api_request_count', 'API Request Count', 'Total number of API requests', 'application', 'counter', 'requests', 'line'),
  ('api_error_rate', 'API Error Rate', 'Percentage of failed requests', 'application', 'gauge', '%', 'area'),
  ('api_response_time', 'API Response Time', 'Average response time', 'application', 'histogram', 'ms', 'line'),
  ('active_users', 'Active Users', 'Number of active users', 'business', 'gauge', 'count', 'counter'),
  ('database_connections', 'Database Connections', 'Active database connections', 'infrastructure', 'gauge', 'count', 'line'),
  ('cache_hit_rate', 'Cache Hit Rate', 'Percentage of cache hits', 'application', 'gauge', '%', 'gauge'),
  ('queue_length', 'Queue Length', 'Number of items in processing queue', 'application', 'gauge', 'count', 'bar'),
  ('throughput', 'Throughput', 'Requests per second', 'application', 'rate', 'req/s', 'area')
ON CONFLICT (metric_name) DO NOTHING;

COMMENT ON TABLE metrics.metrics_sources IS 'Configuration for scraping metrics from various sources';
COMMENT ON TABLE metrics.custom_metric_definitions IS 'Definitions for custom business and application metrics';
COMMENT ON TABLE metrics.custom_metrics_data IS 'Raw collected custom metrics data';
COMMENT ON TABLE metrics.custom_metrics_aggregated IS 'Pre-aggregated custom metrics for fast queries';
COMMENT ON TABLE metrics.dashboards IS 'User-defined metrics dashboards';
