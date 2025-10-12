-- N8N Webhooks Integration
CREATE TABLE IF NOT EXISTS workflow.n8n_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  webhook_url VARCHAR(500) NOT NULL,
  method VARCHAR(10) NOT NULL CHECK (method IN ('GET', 'POST', 'PUT', 'DELETE')),
  enabled BOOLEAN DEFAULT true,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_n8n_webhooks_enabled ON workflow.n8n_webhooks(enabled);
CREATE INDEX idx_n8n_webhooks_created_at ON workflow.n8n_webhooks(created_at DESC);

-- Update trigger for updated_at
CREATE TRIGGER update_n8n_webhooks_updated_at BEFORE UPDATE ON workflow.n8n_webhooks
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- Seed some example webhooks
INSERT INTO workflow.n8n_webhooks (name, webhook_url, method, enabled, description)
VALUES
  ('Example Invoice Processing', 'https://your-n8n-instance.com/webhook/process-invoice', 'POST', false,
   'Example webhook for processing invoices through n8n'),
  ('Example Email Sender', 'https://your-n8n-instance.com/webhook/send-email', 'POST', false,
   'Example webhook for sending emails via n8n'),
  ('Example Data Sync', 'https://your-n8n-instance.com/webhook/sync-data', 'POST', false,
   'Example webhook for syncing data between systems')
ON CONFLICT DO NOTHING;

COMMENT ON TABLE workflow.n8n_webhooks IS 'N8N webhook integrations for external workflow automation';
