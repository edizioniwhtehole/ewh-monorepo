-- API Gateway Management System
-- Allows dynamic configuration of API routes without code changes

-- Gateway Routes (routing configuration)
CREATE TABLE IF NOT EXISTS workflow.gateway_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Route definition
  path VARCHAR(500) NOT NULL,                    -- /api/customers/:id
  method VARCHAR(10) NOT NULL,                   -- GET, POST, PUT, DELETE, PATCH, OPTIONS
  description TEXT,

  -- Target service
  target_service VARCHAR(255) NOT NULL,          -- svc-crm
  target_endpoint VARCHAR(500),                  -- /customers/:id (can be different from path)
  target_port INTEGER,                           -- 4020 (if different from registered)

  -- Middleware & Security
  requires_auth BOOLEAN DEFAULT true,
  required_roles TEXT[] DEFAULT '{}',
  required_permissions TEXT[] DEFAULT '{}',

  -- Rate limiting
  rate_limit_enabled BOOLEAN DEFAULT false,
  rate_limit_requests INTEGER,                   -- Max requests
  rate_limit_window INTEGER,                     -- Window in seconds
  rate_limit_scope VARCHAR(50) DEFAULT 'user',   -- user, ip, api-key, global

  -- Transformation
  request_transform JSONB DEFAULT '{}',          -- Modify request before forwarding
  response_transform JSONB DEFAULT '{}',         -- Modify response before returning
  request_validation_schema JSONB DEFAULT '{}',  -- JSON Schema for request validation

  -- Routing logic
  load_balancing VARCHAR(50) DEFAULT 'round-robin', -- round-robin, random, weighted, least-conn
  timeout_ms INTEGER DEFAULT 30000,
  retry_enabled BOOLEAN DEFAULT false,
  retry_attempts INTEGER DEFAULT 3,
  retry_delay_ms INTEGER DEFAULT 1000,

  -- Circuit breaker
  circuit_breaker_enabled BOOLEAN DEFAULT false,
  circuit_breaker_threshold INTEGER DEFAULT 5,   -- Failures before opening
  circuit_breaker_timeout INTEGER DEFAULT 60000, -- MS before trying again

  -- Caching
  cache_enabled BOOLEAN DEFAULT false,
  cache_ttl INTEGER,                             -- Seconds
  cache_key_pattern VARCHAR(500),                -- e.g., "user:{userId}:profile"

  -- Versioning
  api_version VARCHAR(50),                       -- v1, v2, etc.
  deprecated BOOLEAN DEFAULT false,
  deprecation_date TIMESTAMP WITH TIME ZONE,
  sunset_date TIMESTAMP WITH TIME ZONE,          -- When route will be removed

  -- Priority & Status
  enabled BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0,                    -- Higher priority routes matched first

  -- Analytics
  track_analytics BOOLEAN DEFAULT true,

  -- Metadata
  tags TEXT[] DEFAULT '{}',
  documentation_url VARCHAR(500),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),

  -- Constraints
  UNIQUE (method, path),
  CHECK (method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD', '*')),
  CHECK (rate_limit_scope IN ('user', 'ip', 'api-key', 'global')),
  CHECK (load_balancing IN ('round-robin', 'random', 'weighted', 'least-conn', 'ip-hash'))
);

CREATE INDEX idx_gateway_routes_path ON workflow.gateway_routes(path);
CREATE INDEX idx_gateway_routes_method ON workflow.gateway_routes(method);
CREATE INDEX idx_gateway_routes_service ON workflow.gateway_routes(target_service);
CREATE INDEX idx_gateway_routes_enabled ON workflow.gateway_routes(enabled);
CREATE INDEX idx_gateway_routes_priority ON workflow.gateway_routes(priority DESC);

-- Route Analytics (track route usage)
CREATE TABLE IF NOT EXISTS workflow.gateway_route_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES workflow.gateway_routes(id) ON DELETE CASCADE,

  -- Request info
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  method VARCHAR(10) NOT NULL,
  path VARCHAR(500) NOT NULL,

  -- Response info
  status_code INTEGER NOT NULL,
  response_time_ms INTEGER NOT NULL,

  -- Client info
  user_id UUID,
  ip_address INET,
  user_agent TEXT,

  -- Error info
  error_message TEXT,
  error_stack TEXT,

  -- Metadata
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_gateway_analytics_route ON workflow.gateway_route_analytics(route_id);
CREATE INDEX idx_gateway_analytics_timestamp ON workflow.gateway_route_analytics(timestamp DESC);
CREATE INDEX idx_gateway_analytics_status ON workflow.gateway_route_analytics(status_code);

-- Route Health (circuit breaker state)
CREATE TABLE IF NOT EXISTS workflow.gateway_route_health (
  route_id UUID PRIMARY KEY REFERENCES workflow.gateway_routes(id) ON DELETE CASCADE,

  -- Circuit breaker state
  state VARCHAR(20) NOT NULL DEFAULT 'closed',   -- closed, open, half-open
  failure_count INTEGER DEFAULT 0,
  last_failure_at TIMESTAMP WITH TIME ZONE,
  opened_at TIMESTAMP WITH TIME ZONE,

  -- Health metrics
  success_rate DECIMAL(5,2),                     -- Last 100 requests
  avg_response_time_ms INTEGER,
  p95_response_time_ms INTEGER,
  p99_response_time_ms INTEGER,

  -- Last health check
  last_health_check TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  health_status VARCHAR(20) DEFAULT 'unknown',   -- healthy, degraded, unhealthy, unknown

  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (state IN ('closed', 'open', 'half-open')),
  CHECK (health_status IN ('healthy', 'degraded', 'unhealthy', 'unknown'))
);

-- Middleware Configuration (custom middleware chains)
CREATE TABLE IF NOT EXISTS workflow.gateway_middleware (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,

  -- Middleware type
  type VARCHAR(50) NOT NULL,                     -- auth, logging, transform, validate, rate-limit, cors, custom

  -- Configuration
  config JSONB NOT NULL DEFAULT '{}',

  -- Execution order
  execution_order INTEGER DEFAULT 0,

  -- Code (for custom middleware)
  code TEXT,                                     -- JavaScript/TypeScript code

  -- Status
  enabled BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CHECK (type IN ('auth', 'logging', 'transform', 'validate', 'rate-limit', 'cors', 'custom', 'cache', 'compress'))
);

-- Route-Middleware mapping (many-to-many)
CREATE TABLE IF NOT EXISTS workflow.gateway_route_middleware (
  route_id UUID NOT NULL REFERENCES workflow.gateway_routes(id) ON DELETE CASCADE,
  middleware_id UUID NOT NULL REFERENCES workflow.gateway_middleware(id) ON DELETE CASCADE,
  execution_order INTEGER DEFAULT 0,

  PRIMARY KEY (route_id, middleware_id)
);

-- Update trigger
CREATE TRIGGER update_gateway_routes_updated_at BEFORE UPDATE ON workflow.gateway_routes
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- Seed some common routes
INSERT INTO workflow.gateway_routes (path, method, target_service, target_endpoint, description, requires_auth, tags)
VALUES
  ('/api/health', 'GET', 'svc-api-gateway', '/health', 'API Gateway health check', false, ARRAY['system', 'monitoring']),
  ('/api/auth/login', 'POST', 'svc-auth', '/login', 'User login', false, ARRAY['auth']),
  ('/api/auth/logout', 'POST', 'svc-auth', '/logout', 'User logout', true, ARRAY['auth']),
  ('/api/auth/refresh', 'POST', 'svc-auth', '/refresh', 'Refresh JWT token', false, ARRAY['auth']),
  ('/api/customers', 'GET', 'svc-crm', '/customers', 'List customers', true, ARRAY['crm']),
  ('/api/customers/:id', 'GET', 'svc-crm', '/customers/:id', 'Get customer by ID', true, ARRAY['crm']),
  ('/api/products', 'GET', 'svc-products', '/products', 'List products', true, ARRAY['products']),
  ('/api/orders', 'POST', 'svc-orders', '/orders', 'Create order', true, ARRAY['orders']),
  ('/api/invoices', 'GET', 'svc-billing', '/invoices', 'List invoices', true, ARRAY['billing'])
ON CONFLICT (method, path) DO NOTHING;

-- Seed common middleware
INSERT INTO workflow.gateway_middleware (name, type, description, config, execution_order)
VALUES
  ('CORS Handler', 'cors', 'Handle CORS preflight and headers', '{"origins": ["*"], "methods": ["GET", "POST", "PUT", "DELETE"], "allowedHeaders": ["Content-Type", "Authorization"]}', 1),
  ('Request Logger', 'logging', 'Log all incoming requests', '{"level": "info", "includeBody": false}', 2),
  ('JWT Authentication', 'auth', 'Validate JWT tokens', '{"tokenHeader": "Authorization", "tokenPrefix": "Bearer"}', 3),
  ('Response Compressor', 'compress', 'Compress responses with gzip', '{"threshold": 1024}', 99)
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE workflow.gateway_routes IS 'Dynamic API Gateway route configuration';
COMMENT ON TABLE workflow.gateway_route_analytics IS 'Route usage analytics and metrics';
COMMENT ON TABLE workflow.gateway_route_health IS 'Route health and circuit breaker state';
COMMENT ON TABLE workflow.gateway_middleware IS 'Reusable middleware components';
COMMENT ON TABLE workflow.gateway_route_middleware IS 'Route-specific middleware chains';
