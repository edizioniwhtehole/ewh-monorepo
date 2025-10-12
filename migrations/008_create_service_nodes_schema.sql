-- Service Nodes (Dynamic Services)
CREATE TABLE IF NOT EXISTS workflow.service_nodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  port INTEGER NOT NULL,
  base_path VARCHAR(255) DEFAULT '/',
  status VARCHAR(50) DEFAULT 'stopped' CHECK (status IN ('stopped', 'starting', 'running', 'error', 'deploying')),
  deploy_target VARCHAR(50) DEFAULT 'docker' CHECK (deploy_target IN ('docker', 'inline', 'lambda', 'cloudrun')),
  health_endpoint VARCHAR(255) DEFAULT '/health',
  config JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  last_deployed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_service_nodes_status ON workflow.service_nodes(status);
CREATE INDEX idx_service_nodes_name ON workflow.service_nodes(name);

-- Service Scripts
CREATE TABLE IF NOT EXISTS workflow.service_scripts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  node_id UUID REFERENCES workflow.service_nodes(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  code TEXT NOT NULL,
  language VARCHAR(50) DEFAULT 'javascript' CHECK (language IN ('javascript', 'typescript', 'python')),
  enabled BOOLEAN DEFAULT true,
  version INTEGER DEFAULT 1,
  input_schema JSONB DEFAULT '{}',
  output_schema JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}',
  UNIQUE(node_id, name)
);

CREATE INDEX idx_service_scripts_node_id ON workflow.service_scripts(node_id);
CREATE INDEX idx_service_scripts_enabled ON workflow.service_scripts(enabled);

-- Service Endpoints
CREATE TABLE IF NOT EXISTS workflow.service_endpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  node_id UUID REFERENCES workflow.service_nodes(id) ON DELETE CASCADE,
  script_id UUID REFERENCES workflow.service_scripts(id) ON DELETE SET NULL,
  path VARCHAR(500) NOT NULL,
  method VARCHAR(10) NOT NULL CHECK (method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD')),
  description TEXT,
  enabled BOOLEAN DEFAULT true,
  auth_required BOOLEAN DEFAULT false,
  auth_type VARCHAR(50) CHECK (auth_type IN ('none', 'bearer', 'api_key', 'basic', 'oauth')),
  rate_limit INTEGER, -- requests per minute
  timeout INTEGER DEFAULT 30000, -- milliseconds
  validation_schema JSONB DEFAULT '{}',
  config JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}',
  UNIQUE(node_id, path, method)
);

CREATE INDEX idx_service_endpoints_node_id ON workflow.service_endpoints(node_id);
CREATE INDEX idx_service_endpoints_script_id ON workflow.service_endpoints(script_id);
CREATE INDEX idx_service_endpoints_enabled ON workflow.service_endpoints(enabled);

-- Service Execution Logs
CREATE TABLE IF NOT EXISTS workflow.service_execution_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  node_id UUID REFERENCES workflow.service_nodes(id) ON DELETE CASCADE,
  endpoint_id UUID REFERENCES workflow.service_endpoints(id) ON DELETE SET NULL,
  script_id UUID REFERENCES workflow.service_scripts(id) ON DELETE SET NULL,
  request_method VARCHAR(10),
  request_path VARCHAR(500),
  request_body JSONB,
  request_headers JSONB,
  response_status INTEGER,
  response_body JSONB,
  error TEXT,
  duration_ms INTEGER,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_service_execution_logs_node_id ON workflow.service_execution_logs(node_id);
CREATE INDEX idx_service_execution_logs_endpoint_id ON workflow.service_execution_logs(endpoint_id);
CREATE INDEX idx_service_execution_logs_executed_at ON workflow.service_execution_logs(executed_at DESC);
CREATE INDEX idx_service_execution_logs_response_status ON workflow.service_execution_logs(response_status);

-- Service Dependencies (for connecting nodes in workflows)
CREATE TABLE IF NOT EXISTS workflow.service_node_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_node_id UUID REFERENCES workflow.service_nodes(id) ON DELETE CASCADE,
  target_node_id UUID REFERENCES workflow.service_nodes(id) ON DELETE CASCADE,
  dependency_type VARCHAR(50) CHECK (dependency_type IN ('http', 'event', 'data')),
  config JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(source_node_id, target_node_id, dependency_type)
);

CREATE INDEX idx_service_node_dependencies_source ON workflow.service_node_dependencies(source_node_id);
CREATE INDEX idx_service_node_dependencies_target ON workflow.service_node_dependencies(target_node_id);

-- Update triggers
CREATE TRIGGER update_service_nodes_updated_at BEFORE UPDATE ON workflow.service_nodes
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_service_scripts_updated_at BEFORE UPDATE ON workflow.service_scripts
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_service_endpoints_updated_at BEFORE UPDATE ON workflow.service_endpoints
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- Seed example service node
INSERT INTO workflow.service_nodes (name, description, port, status, config)
VALUES
  ('svc-example-dynamic', 'Example dynamic service node', 3099, 'stopped',
   '{"auto_start": false, "max_memory": "512M", "replicas": 1}')
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE workflow.service_nodes IS 'Dynamic service nodes that can be created and deployed from UI';
COMMENT ON TABLE workflow.service_scripts IS 'JavaScript/Python scripts that handle endpoint logic';
COMMENT ON TABLE workflow.service_endpoints IS 'HTTP endpoints exposed by service nodes';
COMMENT ON TABLE workflow.service_execution_logs IS 'Execution history and logs for service endpoints';
COMMENT ON TABLE workflow.service_node_dependencies IS 'Dependencies between service nodes for workflow orchestration';
