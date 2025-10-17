-- CRM Leads and Deals Migration
-- Create tables for lead management and sales pipeline

-- Leads table
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  
  -- Lead information
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  mobile VARCHAR(50),
  company_name VARCHAR(255),
  job_title VARCHAR(100),
  
  -- Lead source and status
  source VARCHAR(50), -- website, referral, event, social, cold_call, etc
  status VARCHAR(50) NOT NULL DEFAULT 'new', -- new, contacted, qualified, converted, lost
  rating VARCHAR(20), -- hot, warm, cold
  
  -- Lead scoring
  score INTEGER DEFAULT 0,
  score_last_calculated_at TIMESTAMP,
  
  -- Assignment
  assigned_to UUID,
  
  -- Additional data
  website VARCHAR(255),
  industry VARCHAR(100),
  employee_count VARCHAR(50),
  annual_revenue DECIMAL(15,2),
  address JSONB,
  
  -- Custom fields
  custom_fields JSONB DEFAULT '{}',
  
  -- Conversion tracking
  converted BOOLEAN DEFAULT FALSE,
  converted_at TIMESTAMP,
  converted_to_company_id UUID,
  converted_to_contact_id UUID,
  
  -- Metadata
  tags TEXT[],
  notes TEXT,
  internal_notes TEXT,
  
  -- Audit
  created_by UUID NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP
);

CREATE INDEX idx_leads_tenant ON leads(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_leads_status ON leads(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_leads_assigned ON leads(assigned_to) WHERE deleted_at IS NULL;
CREATE INDEX idx_leads_score ON leads(score DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_leads_email ON leads(email) WHERE deleted_at IS NULL;

-- Pipeline stages (customizable sales stages)
CREATE TABLE IF NOT EXISTS crm_pipeline_stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  
  name VARCHAR(100) NOT NULL,
  description TEXT,
  color VARCHAR(20),
  
  -- Stage positioning
  position INTEGER NOT NULL,
  is_closed BOOLEAN DEFAULT FALSE,
  is_won BOOLEAN DEFAULT FALSE,
  
  -- Probability for forecasting
  probability INTEGER DEFAULT 0, -- 0-100
  
  -- Audit
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP,
  
  UNIQUE(tenant_id, position)
);

CREATE INDEX idx_pipeline_stages_tenant ON crm_pipeline_stages(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pipeline_stages_position ON crm_pipeline_stages(position) WHERE deleted_at IS NULL;

-- Deals (opportunities)
CREATE TABLE IF NOT EXISTS crm_deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  
  -- Deal information
  name VARCHAR(255) NOT NULL,
  description TEXT,
  amount DECIMAL(15,2),
  currency VARCHAR(3) DEFAULT 'EUR',
  
  -- Relationships
  company_id UUID,
  contact_id UUID,
  lead_id UUID, -- if converted from lead
  
  -- Pipeline
  stage_id UUID NOT NULL,
  probability INTEGER DEFAULT 0, -- 0-100
  expected_close_date DATE,
  actual_close_date DATE,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'open', -- open, won, lost
  lost_reason TEXT,
  
  -- Assignment
  assigned_to UUID,
  
  -- Custom fields
  custom_fields JSONB DEFAULT '{}',
  tags TEXT[],
  
  -- Products/services
  line_items JSONB DEFAULT '[]',
  
  -- Metadata
  source VARCHAR(50),
  notes TEXT,
  internal_notes TEXT,
  
  -- Audit
  created_by UUID NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP,
  
  FOREIGN KEY (stage_id) REFERENCES crm_pipeline_stages(id)
);

CREATE INDEX idx_deals_tenant ON crm_deals(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_stage ON crm_deals(stage_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_company ON crm_deals(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_contact ON crm_deals(contact_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_assigned ON crm_deals(assigned_to) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_status ON crm_deals(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_amount ON crm_deals(amount DESC) WHERE deleted_at IS NULL;

-- Deal stage history (track movements through pipeline)
CREATE TABLE IF NOT EXISTS crm_deal_stage_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  deal_id UUID NOT NULL,
  
  from_stage_id UUID,
  to_stage_id UUID NOT NULL,
  
  duration_seconds INTEGER,
  changed_by UUID NOT NULL,
  changed_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  FOREIGN KEY (deal_id) REFERENCES crm_deals(id) ON DELETE CASCADE,
  FOREIGN KEY (to_stage_id) REFERENCES crm_pipeline_stages(id)
);

CREATE INDEX idx_deal_stage_history_deal ON crm_deal_stage_history(deal_id);
CREATE INDEX idx_deal_stage_history_tenant ON crm_deal_stage_history(tenant_id);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_leads_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER leads_updated_at BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_leads_updated_at();

CREATE TRIGGER deals_updated_at BEFORE UPDATE ON crm_deals
  FOR EACH ROW EXECUTE FUNCTION update_leads_updated_at();

CREATE TRIGGER pipeline_stages_updated_at BEFORE UPDATE ON crm_pipeline_stages
  FOR EACH ROW EXECUTE FUNCTION update_leads_updated_at();

-- Insert default pipeline stages for new tenants
INSERT INTO crm_pipeline_stages (tenant_id, name, position, probability, color)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'Qualification', 1, 10, '#94a3b8'),
  ('00000000-0000-0000-0000-000000000001', 'Needs Analysis', 2, 25, '#60a5fa'),
  ('00000000-0000-0000-0000-000000000001', 'Proposal', 3, 50, '#a78bfa'),
  ('00000000-0000-0000-0000-000000000001', 'Negotiation', 4, 75, '#fb923c'),
  ('00000000-0000-0000-0000-000000000001', 'Closed Won', 5, 100, '#10b981'),
  ('00000000-0000-0000-0000-000000000001', 'Closed Lost', 6, 0, '#ef4444')
ON CONFLICT DO NOTHING;

COMMENT ON TABLE leads IS 'Lead management for CRM - potential customers before qualification';
COMMENT ON TABLE crm_deals IS 'Sales opportunities and deals pipeline';
COMMENT ON TABLE crm_pipeline_stages IS 'Customizable pipeline stages for sales process';
COMMENT ON TABLE crm_deal_stage_history IS 'Audit trail for deal movements through pipeline';
