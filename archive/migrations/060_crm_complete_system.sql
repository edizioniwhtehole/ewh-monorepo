-- ============================================================================
-- CRM Complete System Migration
-- Version: 1.0
-- Date: 2025-10-15
-- Description: Sistema CRM completo con anagrafiche, contatti, note, custom fields
-- ============================================================================

-- ============================================================================
-- 1. COMPANIES (Anagrafiche Aziende)
-- ============================================================================

CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Basic Info
  name VARCHAR(255) NOT NULL,
  legal_name VARCHAR(255),
  type VARCHAR(50) NOT NULL DEFAULT 'client', -- 'client', 'supplier', 'stakeholder', 'partner'

  -- Tax & Legal
  vat_number VARCHAR(50),
  tax_code VARCHAR(50),
  sdi_code VARCHAR(7), -- Codice SDI per fatturazione elettronica Italia
  pec_email VARCHAR(255), -- PEC per Italia

  -- Contact Info
  email VARCHAR(255),
  phone VARCHAR(50),
  fax VARCHAR(50),
  website VARCHAR(255),

  -- Address
  billing_address JSONB, -- { street, city, state, zip, country }
  shipping_address JSONB,

  -- Business Info
  industry VARCHAR(100),
  size VARCHAR(50), -- 'micro' (1-9), 'small' (10-49), 'medium' (50-249), 'large' (250+), 'enterprise' (1000+)
  annual_revenue DECIMAL(15,2),
  employee_count INTEGER,

  -- Visual
  logo_url TEXT,
  cover_image_url TEXT,

  -- CRM Fields
  source VARCHAR(100), -- 'website', 'referral', 'cold_email', 'event', 'partner', 'other'
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'inactive', 'prospect', 'archived'
  rating INTEGER CHECK (rating >= 1 AND rating <= 5), -- 1-5 star rating

  -- Assignment
  assigned_to UUID, -- User responsible for this company

  -- Custom Fields (JSONB for flexibility)
  custom_fields JSONB DEFAULT '{}',

  -- Tags & Categories
  tags TEXT[],
  categories TEXT[],

  -- Social Media
  linkedin_url VARCHAR(255),
  facebook_url VARCHAR(255),
  twitter_url VARCHAR(255),

  -- Notes
  description TEXT,
  internal_notes TEXT,

  -- Metadata
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP -- Soft delete
);

-- Indexes for performance
CREATE INDEX idx_companies_tenant ON companies(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_companies_type ON companies(type) WHERE deleted_at IS NULL;
CREATE INDEX idx_companies_status ON companies(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_companies_assigned ON companies(assigned_to) WHERE deleted_at IS NULL;
CREATE INDEX idx_companies_name ON companies(name) WHERE deleted_at IS NULL;
CREATE INDEX idx_companies_tags ON companies USING GIN(tags);
CREATE INDEX idx_companies_custom_fields ON companies USING GIN(custom_fields);

-- Full-text search
CREATE INDEX idx_companies_search ON companies USING GIN(
  to_tsvector('simple',
    COALESCE(name, '') || ' ' ||
    COALESCE(legal_name, '') || ' ' ||
    COALESCE(email, '') || ' ' ||
    COALESCE(description, '')
  )
);

-- ============================================================================
-- 2. CONTACTS (Persone di Contatto - 1:N con Companies)
-- ============================================================================

CREATE TABLE IF NOT EXISTS contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

  -- Personal Info
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100),
  title VARCHAR(50), -- 'Mr', 'Mrs', 'Ms', 'Dr', 'Prof'

  -- Contact Info
  email VARCHAR(255),
  phone VARCHAR(50),
  mobile VARCHAR(50),
  fax VARCHAR(50),

  -- Work Info
  job_title VARCHAR(100),
  department VARCHAR(100),
  role VARCHAR(100), -- 'CEO', 'CFO', 'CTO', 'Buyer', 'Technical Contact', 'Decision Maker'

  -- Flags
  is_primary BOOLEAN DEFAULT false, -- Contatto principale dell'azienda
  is_billing_contact BOOLEAN DEFAULT false,
  is_technical_contact BOOLEAN DEFAULT false,
  is_decision_maker BOOLEAN DEFAULT false,

  -- Address (if different from company)
  address JSONB,

  -- Personal
  birthday DATE,
  gender VARCHAR(20),
  preferred_language VARCHAR(10) DEFAULT 'it',
  timezone VARCHAR(50),

  -- Visual
  avatar_url TEXT,

  -- Social Media
  linkedin_url VARCHAR(255),
  twitter_url VARCHAR(255),

  -- CRM Fields
  source VARCHAR(100),
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'inactive', 'bounced', 'unsubscribed'

  -- Communication Preferences
  email_opt_in BOOLEAN DEFAULT true,
  sms_opt_in BOOLEAN DEFAULT false,
  phone_opt_in BOOLEAN DEFAULT true,

  -- Custom Fields
  custom_fields JSONB DEFAULT '{}',

  -- Tags
  tags TEXT[],

  -- Notes
  notes TEXT,
  internal_notes TEXT,

  -- Metadata
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_contacts_tenant ON contacts(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_contacts_company ON contacts(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_contacts_email ON contacts(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_contacts_primary ON contacts(company_id, is_primary) WHERE is_primary = true AND deleted_at IS NULL;
CREATE INDEX idx_contacts_name ON contacts(first_name, last_name) WHERE deleted_at IS NULL;
CREATE INDEX idx_contacts_tags ON contacts USING GIN(tags);

-- Full-text search
CREATE INDEX idx_contacts_search ON contacts USING GIN(
  to_tsvector('simple',
    COALESCE(first_name, '') || ' ' ||
    COALESCE(last_name, '') || ' ' ||
    COALESCE(email, '') || ' ' ||
    COALESCE(job_title, '') || ' ' ||
    COALESCE(notes, '')
  )
);

-- Ensure only one primary contact per company
CREATE UNIQUE INDEX idx_contacts_one_primary_per_company
  ON contacts(company_id)
  WHERE is_primary = true AND deleted_at IS NULL;

-- ============================================================================
-- 3. NOTES (Note Multi-Utente con Timeline)
-- ============================================================================

CREATE TABLE IF NOT EXISTS crm_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Entity Reference (polymorphic)
  entity_type VARCHAR(50) NOT NULL, -- 'company', 'contact', 'deal', 'activity'
  entity_id UUID NOT NULL,

  -- Note Content
  title VARCHAR(255),
  content TEXT NOT NULL,

  -- Note Type/Category
  note_type VARCHAR(50) DEFAULT 'general', -- 'general', 'call', 'meeting', 'email', 'production', 'accounting', 'finance', 'support'

  -- Visibility & Priority
  is_pinned BOOLEAN DEFAULT false,
  is_private BOOLEAN DEFAULT false, -- Se true, visibile solo al creatore
  priority VARCHAR(20), -- 'low', 'medium', 'high', 'urgent'

  -- Mentions (array di user IDs)
  mentions UUID[],

  -- Attachments
  attachments JSONB, -- [{ filename, url, size, type }]

  -- Related Entities (optional links)
  related_entities JSONB, -- [{ type: 'deal', id: 'xxx' }, { type: 'project', id: 'yyy' }]

  -- Metadata
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_crm_notes_tenant ON crm_notes(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_crm_notes_entity ON crm_notes(entity_type, entity_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_crm_notes_type ON crm_notes(note_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_crm_notes_pinned ON crm_notes(is_pinned) WHERE is_pinned = true AND deleted_at IS NULL;
CREATE INDEX idx_crm_notes_created_by ON crm_notes(created_by) WHERE deleted_at IS NULL;
CREATE INDEX idx_crm_notes_mentions ON crm_notes USING GIN(mentions);

-- Full-text search
CREATE INDEX idx_crm_notes_search ON crm_notes USING GIN(
  to_tsvector('simple', COALESCE(title, '') || ' ' || COALESCE(content, ''))
);

-- ============================================================================
-- 4. ACTIVITIES (Timeline / Activity Feed - Auto-Generated)
-- ============================================================================

CREATE TABLE IF NOT EXISTS crm_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Entity Reference
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID NOT NULL,

  -- Activity Info
  activity_type VARCHAR(50) NOT NULL, -- 'note_added', 'email_sent', 'call_made', 'meeting_scheduled', 'deal_updated', 'document_uploaded', 'status_changed'
  title VARCHAR(255) NOT NULL,
  description TEXT,

  -- Icon/Color for UI
  icon VARCHAR(50), -- 'mail', 'phone', 'video', 'file', 'edit', etc.
  color VARCHAR(20), -- 'blue', 'green', 'red', 'yellow'

  -- Metadata (store additional data as JSON)
  metadata JSONB, -- { old_value, new_value, email_subject, etc. }

  -- Related User
  user_id UUID, -- User who performed the action (can be null for system actions)

  -- Timestamp
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_crm_activities_tenant ON crm_activities(tenant_id);
CREATE INDEX idx_crm_activities_entity ON crm_activities(entity_type, entity_id);
CREATE INDEX idx_crm_activities_type ON crm_activities(activity_type);
CREATE INDEX idx_crm_activities_user ON crm_activities(user_id);
CREATE INDEX idx_crm_activities_created ON crm_activities(created_at DESC);

-- ============================================================================
-- 5. CUSTOM FIELDS CONFIGURATION (per Tenant)
-- ============================================================================

CREATE TABLE IF NOT EXISTS crm_custom_fields_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Applicable Entity
  entity_type VARCHAR(50) NOT NULL, -- 'company', 'contact', 'deal'

  -- Field Definition
  field_name VARCHAR(100) NOT NULL, -- snake_case key per JSONB
  field_label VARCHAR(255) NOT NULL, -- UI display name
  field_type VARCHAR(50) NOT NULL, -- 'text', 'number', 'date', 'datetime', 'select', 'multiselect', 'boolean', 'url', 'email', 'phone', 'textarea'

  -- Validation
  is_required BOOLEAN DEFAULT false,
  default_value TEXT,

  -- Options for select/multiselect
  field_options JSONB, -- [{ value: 'option1', label: 'Option 1' }, ...]

  -- Validation Rules
  validation_rules JSONB, -- { min, max, pattern, etc. }

  -- UI
  placeholder VARCHAR(255),
  help_text TEXT,
  display_order INTEGER DEFAULT 0,

  -- Visibility
  is_active BOOLEAN DEFAULT true,

  -- Metadata
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(tenant_id, entity_type, field_name)
);

-- Indexes
CREATE INDEX idx_custom_fields_tenant ON crm_custom_fields_config(tenant_id);
CREATE INDEX idx_custom_fields_entity ON crm_custom_fields_config(entity_type);
CREATE INDEX idx_custom_fields_active ON crm_custom_fields_config(is_active) WHERE is_active = true;

-- ============================================================================
-- 6. DEALS (Pipeline / Opportunità)
-- ============================================================================

CREATE TABLE IF NOT EXISTS crm_deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Related Company/Contact
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,

  -- Deal Info
  title VARCHAR(255) NOT NULL,
  description TEXT,

  -- Financial
  value DECIMAL(15,2),
  currency VARCHAR(3) DEFAULT 'EUR',

  -- Pipeline Stage
  stage VARCHAR(50) NOT NULL DEFAULT 'lead', -- 'lead', 'qualified', 'proposal', 'negotiation', 'won', 'lost'
  probability INTEGER CHECK (probability >= 0 AND probability <= 100), -- 0-100%

  -- Dates
  expected_close_date DATE,
  actual_close_date DATE,

  -- Source
  source VARCHAR(100), -- 'website', 'referral', 'cold_email', 'event', 'partner'

  -- Lost Reason (if stage = 'lost')
  lost_reason VARCHAR(255),

  -- Assignment
  assigned_to UUID,

  -- Custom Fields
  custom_fields JSONB DEFAULT '{}',

  -- Tags
  tags TEXT[],

  -- Metadata
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_deals_tenant ON crm_deals(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_company ON crm_deals(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_contact ON crm_deals(contact_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_stage ON crm_deals(stage) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_assigned ON crm_deals(assigned_to) WHERE deleted_at IS NULL;
CREATE INDEX idx_deals_close_date ON crm_deals(expected_close_date) WHERE deleted_at IS NULL;

-- ============================================================================
-- 7. DOCUMENTS (Attachments for Companies/Contacts/Deals)
-- ============================================================================

CREATE TABLE IF NOT EXISTS crm_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Entity Reference
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID NOT NULL,

  -- File Info
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(100), -- MIME type
  file_size BIGINT, -- bytes
  file_url TEXT NOT NULL, -- S3/storage URL

  -- Categorization
  category VARCHAR(50), -- 'contract', 'invoice', 'presentation', 'photo', 'other'

  -- Metadata
  description TEXT,
  tags TEXT[],

  -- Upload Info
  uploaded_by UUID NOT NULL,
  uploaded_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_documents_tenant ON crm_documents(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_entity ON crm_documents(entity_type, entity_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_category ON crm_documents(category) WHERE deleted_at IS NULL;

-- ============================================================================
-- 8. TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at
  BEFORE UPDATE ON contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_crm_notes_updated_at
  BEFORE UPDATE ON crm_notes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_crm_deals_updated_at
  BEFORE UPDATE ON crm_deals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_crm_custom_fields_config_updated_at
  BEFORE UPDATE ON crm_custom_fields_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-create activity on note creation
CREATE OR REPLACE FUNCTION create_activity_on_note()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO crm_activities (
    tenant_id,
    entity_type,
    entity_id,
    activity_type,
    title,
    description,
    icon,
    color,
    metadata,
    user_id
  ) VALUES (
    NEW.tenant_id,
    NEW.entity_type,
    NEW.entity_id,
    'note_added',
    COALESCE(NEW.title, 'Note added'),
    LEFT(NEW.content, 200),
    'sticky-note',
    'blue',
    jsonb_build_object('note_id', NEW.id, 'note_type', NEW.note_type),
    NEW.created_by
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_activity_on_note
  AFTER INSERT ON crm_notes
  FOR EACH ROW
  EXECUTE FUNCTION create_activity_on_note();

-- Auto-create activity on deal stage change
CREATE OR REPLACE FUNCTION create_activity_on_deal_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'UPDATE' AND OLD.stage IS DISTINCT FROM NEW.stage) THEN
    INSERT INTO crm_activities (
      tenant_id,
      entity_type,
      entity_id,
      activity_type,
      title,
      description,
      icon,
      color,
      metadata,
      user_id
    ) VALUES (
      NEW.tenant_id,
      'deal',
      NEW.id,
      'deal_stage_changed',
      'Deal stage changed',
      'Stage moved from ' || OLD.stage || ' to ' || NEW.stage,
      'trending-up',
      CASE
        WHEN NEW.stage = 'won' THEN 'green'
        WHEN NEW.stage = 'lost' THEN 'red'
        ELSE 'blue'
      END,
      jsonb_build_object('old_stage', OLD.stage, 'new_stage', NEW.stage),
      NEW.created_by
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_activity_on_deal_change
  AFTER UPDATE ON crm_deals
  FOR EACH ROW
  EXECUTE FUNCTION create_activity_on_deal_change();

-- ============================================================================
-- 9. SAMPLE DATA (Optional - for development)
-- ============================================================================

-- Insert some sample custom fields config
INSERT INTO crm_custom_fields_config (tenant_id, entity_type, field_name, field_label, field_type, created_by)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'company', 'payment_terms', 'Payment Terms', 'select', '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000001', 'company', 'credit_limit', 'Credit Limit', 'number', '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000001', 'company', 'preferred_delivery_time', 'Preferred Delivery Time', 'text', '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000001', 'contact', 'birthday_reminder', 'Send Birthday Reminder', 'boolean', '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000001', 'contact', 'preferred_communication', 'Preferred Communication', 'select', '00000000-0000-0000-0000-000000000001')
ON CONFLICT (tenant_id, entity_type, field_name) DO NOTHING;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Add comments for documentation
COMMENT ON TABLE companies IS 'Anagrafiche aziende (clienti, fornitori, stakeholders)';
COMMENT ON TABLE contacts IS 'Persone di contatto associate alle aziende (1:N)';
COMMENT ON TABLE crm_notes IS 'Note multi-utente con timeline, collegate a qualsiasi entità';
COMMENT ON TABLE crm_activities IS 'Timeline attività auto-generata per tracking cambiamenti';
COMMENT ON TABLE crm_custom_fields_config IS 'Configurazione campi personalizzati per tenant';
COMMENT ON TABLE crm_deals IS 'Pipeline opportunità di vendita';
COMMENT ON TABLE crm_documents IS 'Documenti e allegati per entità CRM';
