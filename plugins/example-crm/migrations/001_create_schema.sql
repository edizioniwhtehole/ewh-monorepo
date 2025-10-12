-- AUTO-RUN MIGRATION
-- This file is automatically executed when the plugin is activated

-- Create CRM schema
CREATE SCHEMA IF NOT EXISTS crm;

-- Create leads table
CREATE TABLE IF NOT EXISTS crm.leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Contact info
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(50),
  company VARCHAR(255),

  -- Lead details
  source VARCHAR(50) CHECK (source IN ('website', 'referral', 'social', 'advertisement', 'other')),
  status VARCHAR(50) DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'converted', 'lost')),
  notes TEXT,

  -- Metadata
  created_by UUID NOT NULL,
  assigned_to UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  converted_at TIMESTAMP
);

-- Create contacts table
CREATE TABLE IF NOT EXISTS crm.contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Contact info
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(50),
  mobile VARCHAR(50),
  company_id UUID,
  job_title VARCHAR(100),

  -- Metadata
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create deals table
CREATE TABLE IF NOT EXISTS crm.deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Deal info
  title VARCHAR(255) NOT NULL,
  description TEXT,
  amount DECIMAL(12, 2),
  currency VARCHAR(3) DEFAULT 'USD',

  -- Relationships
  contact_id UUID REFERENCES crm.contacts(id),
  lead_id UUID REFERENCES crm.leads(id),

  -- Deal status
  stage VARCHAR(50) DEFAULT 'prospecting' CHECK (stage IN (
    'prospecting', 'qualification', 'proposal',
    'negotiation', 'closed_won', 'closed_lost'
  )),
  probability INTEGER CHECK (probability >= 0 AND probability <= 100),
  expected_close_date DATE,
  actual_close_date DATE,

  -- Metadata
  created_by UUID NOT NULL,
  assigned_to UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_leads_email ON crm.leads(email);
CREATE INDEX idx_leads_status ON crm.leads(status);
CREATE INDEX idx_leads_created_at ON crm.leads(created_at);
CREATE INDEX idx_leads_assigned_to ON crm.leads(assigned_to);

CREATE INDEX idx_contacts_email ON crm.contacts(email);
CREATE INDEX idx_contacts_company ON crm.contacts(company_id);

CREATE INDEX idx_deals_contact ON crm.deals(contact_id);
CREATE INDEX idx_deals_lead ON crm.deals(lead_id);
CREATE INDEX idx_deals_stage ON crm.deals(stage);
CREATE INDEX idx_deals_assigned_to ON crm.deals(assigned_to);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION crm.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers
CREATE TRIGGER update_leads_updated_at
  BEFORE UPDATE ON crm.leads
  FOR EACH ROW
  EXECUTE FUNCTION crm.update_updated_at();

CREATE TRIGGER update_contacts_updated_at
  BEFORE UPDATE ON crm.contacts
  FOR EACH ROW
  EXECUTE FUNCTION crm.update_updated_at();

CREATE TRIGGER update_deals_updated_at
  BEFORE UPDATE ON crm.deals
  FOR EACH ROW
  EXECUTE FUNCTION crm.update_updated_at();

-- Grant permissions (plugin-specific)
-- These will be created automatically by the plugin system
COMMENT ON SCHEMA crm IS 'CRM plugin schema - auto-created';
