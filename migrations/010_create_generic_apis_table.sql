-- Generic External APIs Registry
CREATE TABLE IF NOT EXISTS workflow.external_apis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  api_type VARCHAR(50) NOT NULL CHECK (api_type IN ('rest', 'graphql', 'soap', 'webhook', 'grpc', 'custom')),
  base_url VARCHAR(500) NOT NULL,

  -- Authentication
  auth_type VARCHAR(50) NOT NULL CHECK (auth_type IN ('none', 'api_key', 'bearer', 'basic', 'oauth2', 'custom')),
  auth_config JSONB DEFAULT '{}', -- { api_key, header_name, username, password, token, oauth_config }

  -- Request defaults
  default_headers JSONB DEFAULT '{}',
  default_timeout INTEGER DEFAULT 30000, -- milliseconds
  retry_config JSONB DEFAULT '{"max_retries": 3, "retry_delay": 1000}',

  -- Rate limiting
  rate_limit_enabled BOOLEAN DEFAULT false,
  rate_limit_requests INTEGER, -- max requests
  rate_limit_window INTEGER, -- time window in seconds

  -- SSL/TLS
  verify_ssl BOOLEAN DEFAULT true,
  custom_ca_cert TEXT,

  -- Status
  enabled BOOLEAN DEFAULT true,
  health_check_url VARCHAR(500),
  last_health_check TIMESTAMP WITH TIME ZONE,
  health_status VARCHAR(20) CHECK (health_status IN ('healthy', 'degraded', 'down', 'unknown')),

  -- Metadata
  tags TEXT[] DEFAULT '{}',
  documentation_url VARCHAR(500),
  contact_email VARCHAR(255),
  environment VARCHAR(50) CHECK (environment IN ('production', 'staging', 'development', 'test')),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_external_apis_enabled ON workflow.external_apis(enabled);
CREATE INDEX idx_external_apis_type ON workflow.external_apis(api_type);
CREATE INDEX idx_external_apis_tags ON workflow.external_apis USING gin(tags);
CREATE INDEX idx_external_apis_health ON workflow.external_apis(health_status);

-- API Endpoints Registry (for REST APIs)
CREATE TABLE IF NOT EXISTS workflow.external_api_endpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_id UUID REFERENCES workflow.external_apis(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  path VARCHAR(500) NOT NULL, -- e.g., /users/{id}
  method VARCHAR(10) NOT NULL CHECK (method IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS')),

  -- Request spec
  path_params JSONB DEFAULT '[]', -- [{ name, type, required, description }]
  query_params JSONB DEFAULT '[]',
  headers JSONB DEFAULT '{}',
  body_schema JSONB DEFAULT '{}', -- JSON schema for request body

  -- Response spec
  response_schema JSONB DEFAULT '{}', -- JSON schema for response
  success_codes INTEGER[] DEFAULT '{200}',

  -- Behavior
  requires_auth BOOLEAN DEFAULT true,
  cache_enabled BOOLEAN DEFAULT false,
  cache_ttl INTEGER, -- seconds

  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_external_api_endpoints_api_id ON workflow.external_api_endpoints(api_id);
CREATE INDEX idx_external_api_endpoints_enabled ON workflow.external_api_endpoints(enabled);

-- API Call Logs
CREATE TABLE IF NOT EXISTS workflow.external_api_calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_id UUID REFERENCES workflow.external_apis(id) ON DELETE CASCADE,
  endpoint_id UUID REFERENCES workflow.external_api_endpoints(id) ON DELETE SET NULL,

  -- Request
  method VARCHAR(10) NOT NULL,
  url TEXT NOT NULL,
  request_headers JSONB DEFAULT '{}',
  request_body JSONB,

  -- Response
  status_code INTEGER,
  response_headers JSONB DEFAULT '{}',
  response_body JSONB,
  error TEXT,

  -- Timing
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  duration_ms INTEGER,

  -- Context
  triggered_by UUID REFERENCES auth.users(id),
  workflow_execution_id UUID REFERENCES workflow.workflow_executions(id) ON DELETE CASCADE,

  -- Flags
  success BOOLEAN,
  cached BOOLEAN DEFAULT false,
  retried BOOLEAN DEFAULT false,
  retry_count INTEGER DEFAULT 0,

  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_external_api_calls_api_id ON workflow.external_api_calls(api_id);
CREATE INDEX idx_external_api_calls_endpoint_id ON workflow.external_api_calls(endpoint_id);
CREATE INDEX idx_external_api_calls_started_at ON workflow.external_api_calls(started_at DESC);
CREATE INDEX idx_external_api_calls_success ON workflow.external_api_calls(success);
CREATE INDEX idx_external_api_calls_workflow ON workflow.external_api_calls(workflow_execution_id);

-- Update trigger for updated_at
CREATE TRIGGER update_external_apis_updated_at BEFORE UPDATE ON workflow.external_apis
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_external_api_endpoints_updated_at BEFORE UPDATE ON workflow.external_api_endpoints
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- Seed some example APIs
INSERT INTO workflow.external_apis (name, description, api_type, base_url, auth_type, auth_config, enabled, environment, tags)
VALUES
  ('Stripe API', 'Payment processing API', 'rest', 'https://api.stripe.com/v1', 'bearer',
   '{"header_name": "Authorization", "token_prefix": "Bearer"}', false, 'production',
   ARRAY['payment', 'billing', 'finance']),

  ('SendGrid Email API', 'Email delivery service', 'rest', 'https://api.sendgrid.com/v3', 'api_key',
   '{"header_name": "Authorization", "token_prefix": "Bearer"}', false, 'production',
   ARRAY['email', 'communication']),

  ('Slack Webhook', 'Slack notifications', 'webhook', 'https://hooks.slack.com/services', 'none',
   '{}', false, 'production', ARRAY['notification', 'communication']),

  ('GitHub API', 'GitHub repository management', 'rest', 'https://api.github.com', 'bearer',
   '{"header_name": "Authorization", "token_prefix": "Bearer"}', false, 'production',
   ARRAY['version-control', 'development']),

  ('Google Maps API', 'Geocoding and mapping services', 'rest', 'https://maps.googleapis.com/maps/api', 'api_key',
   '{"param_name": "key"}', false, 'production', ARRAY['maps', 'location'])
ON CONFLICT DO NOTHING;

COMMENT ON TABLE workflow.external_apis IS 'Registry of external API integrations';
COMMENT ON TABLE workflow.external_api_endpoints IS 'Specific endpoints within external APIs';
COMMENT ON TABLE workflow.external_api_calls IS 'Log of all external API calls made by the system';
