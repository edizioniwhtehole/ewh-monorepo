-- AI Providers Registry
CREATE TABLE IF NOT EXISTS workflow.ai_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL CHECK (type IN ('text', 'image', 'video', 'audio', 'embedding')),
  description TEXT,
  endpoint VARCHAR(500) NOT NULL,
  auth_type VARCHAR(50) NOT NULL CHECK (auth_type IN ('api_key', 'oauth', 'bearer', 'basic', 'none')),
  auth_config JSONB DEFAULT '{}',
  default_config JSONB DEFAULT '{}',
  enabled BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_ai_providers_type ON workflow.ai_providers(type);
CREATE INDEX idx_ai_providers_enabled ON workflow.ai_providers(enabled);

-- Custom Functions Library
CREATE TABLE IF NOT EXISTS workflow.custom_functions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  code TEXT NOT NULL,
  language VARCHAR(50) DEFAULT 'javascript' CHECK (language IN ('javascript', 'typescript', 'python')),
  input_schema JSONB DEFAULT '{}',
  output_schema JSONB DEFAULT '{}',
  enabled BOOLEAN DEFAULT true,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  tags TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_custom_functions_enabled ON workflow.custom_functions(enabled);
CREATE INDEX idx_custom_functions_tags ON workflow.custom_functions USING gin(tags);

-- Workflow Definitions (already partially in localStorage, now persisted)
CREATE TABLE IF NOT EXISTS workflow.workflow_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  trigger_config JSONB NOT NULL,
  actions JSONB NOT NULL,
  input_schema JSONB DEFAULT '{}',
  output_schema JSONB DEFAULT '{}',
  enabled BOOLEAN DEFAULT true,
  is_template BOOLEAN DEFAULT false,
  template_category VARCHAR(100),
  edge_from VARCHAR(255),
  edge_to VARCHAR(255),
  edge_from_endpoint VARCHAR(500),
  edge_to_endpoint VARCHAR(500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  tags TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_workflow_definitions_enabled ON workflow.workflow_definitions(enabled);
CREATE INDEX idx_workflow_definitions_template ON workflow.workflow_definitions(is_template);
CREATE INDEX idx_workflow_definitions_category ON workflow.workflow_definitions(template_category);

-- Workflow Executions (logging)
CREATE TABLE IF NOT EXISTS workflow.workflow_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID REFERENCES workflow.workflow_definitions(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'running', 'success', 'failed', 'cancelled', 'timeout')),
  input JSONB DEFAULT '{}',
  output JSONB,
  error TEXT,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  duration_ms INTEGER,
  triggered_by UUID REFERENCES auth.users(id),
  trigger_source VARCHAR(100),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_workflow_executions_workflow_id ON workflow.workflow_executions(workflow_id);
CREATE INDEX idx_workflow_executions_status ON workflow.workflow_executions(status);
CREATE INDEX idx_workflow_executions_started_at ON workflow.workflow_executions(started_at DESC);

-- Workflow Execution Steps (detailed logging per step)
CREATE TABLE IF NOT EXISTS workflow.workflow_execution_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id UUID REFERENCES workflow.workflow_executions(id) ON DELETE CASCADE,
  step_index INTEGER NOT NULL,
  step_type VARCHAR(100) NOT NULL,
  step_config JSONB DEFAULT '{}',
  status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'running', 'success', 'failed', 'skipped', 'timeout')),
  input JSONB DEFAULT '{}',
  output JSONB,
  error TEXT,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  duration_ms INTEGER,
  retry_count INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_workflow_execution_steps_execution_id ON workflow.workflow_execution_steps(execution_id);
CREATE INDEX idx_workflow_execution_steps_status ON workflow.workflow_execution_steps(status);

-- Function Execution Cache (optional, for expensive operations)
CREATE TABLE IF NOT EXISTS workflow.function_execution_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  function_id UUID REFERENCES workflow.custom_functions(id) ON DELETE CASCADE,
  input_hash VARCHAR(64) NOT NULL,
  input JSONB NOT NULL,
  output JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  hit_count INTEGER DEFAULT 0
);

CREATE INDEX idx_function_execution_cache_function_id ON workflow.function_execution_cache(function_id);
CREATE INDEX idx_function_execution_cache_hash ON workflow.function_execution_cache(input_hash);
CREATE INDEX idx_function_execution_cache_expires ON workflow.function_execution_cache(expires_at);

-- Update triggers for updated_at
CREATE OR REPLACE FUNCTION workflow.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_ai_providers_updated_at BEFORE UPDATE ON workflow.ai_providers
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_custom_functions_updated_at BEFORE UPDATE ON workflow.custom_functions
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_workflow_definitions_updated_at BEFORE UPDATE ON workflow.workflow_definitions
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- Seed some example AI providers
INSERT INTO workflow.ai_providers (name, type, description, endpoint, auth_type, auth_config, default_config, priority)
VALUES
  ('OpenAI GPT-4', 'text', 'OpenAI GPT-4 for text generation', 'https://api.openai.com/v1/chat/completions', 'bearer',
   '{"token_env": "OPENAI_API_KEY"}', '{"model": "gpt-4", "temperature": 0.7, "max_tokens": 2000}', 100),

  ('Claude Sonnet', 'text', 'Anthropic Claude for text generation', 'https://api.anthropic.com/v1/messages', 'api_key',
   '{"api_key_env": "ANTHROPIC_API_KEY"}', '{"model": "claude-3-5-sonnet-20241022", "temperature": 0.7, "max_tokens": 4000}', 90),

  ('Stable Diffusion', 'image', 'Stable Diffusion for image generation', 'http://localhost:7860/sdapi/v1/txt2img', 'none',
   '{}', '{"steps": 30, "cfg_scale": 7, "width": 1024, "height": 1024}', 80),

  ('DALL-E 3', 'image', 'OpenAI DALL-E 3 for image generation', 'https://api.openai.com/v1/images/generations', 'bearer',
   '{"token_env": "OPENAI_API_KEY"}', '{"model": "dall-e-3", "size": "1024x1024", "quality": "standard"}', 85)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE workflow.ai_providers IS 'Registry of AI service providers (text, image, video, audio)';
COMMENT ON TABLE workflow.custom_functions IS 'User-uploaded custom functions for workflows';
COMMENT ON TABLE workflow.workflow_definitions IS 'Workflow definitions created via the UI';
COMMENT ON TABLE workflow.workflow_executions IS 'History of workflow executions';
COMMENT ON TABLE workflow.workflow_execution_steps IS 'Detailed step-by-step execution logs';
COMMENT ON TABLE workflow.function_execution_cache IS 'Cache for expensive function executions';
