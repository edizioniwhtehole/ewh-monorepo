-- CRM Unificato: Clienti, Fornitori, Rubrica
CREATE SCHEMA IF NOT EXISTS crm;

-- Contatti principali (clienti, fornitori, lead, partner, dipendenti)
CREATE TABLE IF NOT EXISTS crm.contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Tipo contatto
  contact_type VARCHAR(50) NOT NULL CHECK (contact_type IN ('customer', 'supplier', 'lead', 'partner', 'employee', 'other')),

  -- Dati azienda
  company_name VARCHAR(255),
  business_name VARCHAR(255), -- ragione sociale
  tax_code VARCHAR(50), -- codice fiscale
  vat_number VARCHAR(50), -- partita IVA
  sdi_code VARCHAR(20), -- codice SDI per fatturazione elettronica
  pec_email VARCHAR(255), -- PEC

  -- Persona principale
  primary_contact_name VARCHAR(255),
  primary_contact_role VARCHAR(100),
  primary_contact_email VARCHAR(255),
  primary_contact_phone VARCHAR(50),
  primary_contact_mobile VARCHAR(50),

  -- Contatti generici
  website VARCHAR(255),
  linkedin_url VARCHAR(255),

  -- Indirizzo principale (denormalizzato per velocità)
  address_line_1 VARCHAR(255),
  address_line_2 VARCHAR(255),
  city VARCHAR(100),
  state_province VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100) DEFAULT 'Italia',

  -- Business info
  industry VARCHAR(100), -- settore
  employee_count VARCHAR(50), -- dimensione azienda
  annual_revenue DECIMAL(15,2),

  -- Valutazione
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  quality_score DECIMAL(3,2), -- per fornitori
  reliability_score DECIMAL(3,2), -- puntualità consegne

  -- Status
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'prospect', 'blocked')),
  tags TEXT[], -- array di tag
  notes TEXT,

  -- Payment terms (per clienti)
  payment_terms VARCHAR(100), -- es: "30 gg data fattura"
  credit_limit DECIMAL(15,2),

  -- Supplier info
  lead_time_days INTEGER, -- tempo di consegna medio
  min_order_amount DECIMAL(15,2),

  -- Metadata
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Indexes
  CONSTRAINT unique_tenant_vat UNIQUE(tenant_id, vat_number)
);

CREATE INDEX idx_contacts_tenant ON crm.contacts(tenant_id);
CREATE INDEX idx_contacts_type ON crm.contacts(contact_type);
CREATE INDEX idx_contacts_company ON crm.contacts(company_name);
CREATE INDEX idx_contacts_email ON crm.contacts(primary_contact_email);

-- Indirizzi multipli
CREATE TABLE IF NOT EXISTS crm.contact_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES crm.contacts(id) ON DELETE CASCADE,

  address_type VARCHAR(50) NOT NULL CHECK (address_type IN ('billing', 'shipping', 'office', 'warehouse', 'home', 'other')),
  address_name VARCHAR(100), -- es: "Sede Milano", "Magazzino Nord"

  address_line_1 VARCHAR(255) NOT NULL,
  address_line_2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state_province VARCHAR(100),
  postal_code VARCHAR(20) NOT NULL,
  country VARCHAR(100) DEFAULT 'Italia',

  coordinates JSONB, -- {lat, lng} per mappa
  is_default BOOLEAN DEFAULT false,

  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_addresses_contact ON crm.contact_addresses(contact_id);
CREATE INDEX idx_addresses_type ON crm.contact_addresses(address_type);

-- Persone di contatto multiple
CREATE TABLE IF NOT EXISTS crm.contact_persons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES crm.contacts(id) ON DELETE CASCADE,

  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(100), -- ruolo in azienda
  department VARCHAR(100), -- reparto

  email VARCHAR(255),
  phone VARCHAR(50),
  mobile VARCHAR(50),
  linkedin_url VARCHAR(255),

  is_primary BOOLEAN DEFAULT false,
  is_decision_maker BOOLEAN DEFAULT false,

  birthday DATE,
  notes TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_persons_contact ON crm.contact_persons(contact_id);
CREATE INDEX idx_persons_email ON crm.contact_persons(email);

-- Relazioni tra contatti (es: parent company, filiali)
CREATE TABLE IF NOT EXISTS crm.contact_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES crm.contacts(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES crm.contacts(id) ON DELETE CASCADE,

  relationship_type VARCHAR(50) CHECK (relationship_type IN ('parent', 'subsidiary', 'partner', 'competitor', 'referral')),

  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT unique_relationship UNIQUE(parent_id, child_id)
);

-- Attività/interazioni
CREATE TABLE IF NOT EXISTS crm.activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES crm.contacts(id) ON DELETE CASCADE,

  activity_type VARCHAR(50) CHECK (activity_type IN ('call', 'email', 'meeting', 'note', 'quote_sent', 'order_received', 'payment', 'complaint')),
  subject VARCHAR(255),
  description TEXT,

  activity_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  duration_minutes INTEGER,

  related_quote_id UUID,
  related_order_id UUID,
  related_project_id UUID,

  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activities_contact ON crm.activities(contact_id);
CREATE INDEX idx_activities_date ON crm.activities(activity_date);
CREATE INDEX idx_activities_type ON crm.activities(activity_type);

-- Documenti allegati
CREATE TABLE IF NOT EXISTS crm.contact_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES crm.contacts(id) ON DELETE CASCADE,

  document_type VARCHAR(50) CHECK (document_type IN ('contract', 'certificate', 'catalog', 'price_list', 'other')),
  document_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(500),
  file_url VARCHAR(500),
  file_size BIGINT,
  mime_type VARCHAR(100),

  uploaded_by UUID,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_documents_contact ON crm.contact_documents(contact_id);

COMMENT ON TABLE crm.contacts IS 'Rubrica unificata: clienti, fornitori, lead, partner, dipendenti';
COMMENT ON COLUMN crm.contacts.contact_type IS 'Tipo: customer/supplier/lead/partner/employee';
COMMENT ON TABLE crm.contact_addresses IS 'Indirizzi multipli per ogni contatto (fatturazione, spedizione, uffici)';
COMMENT ON TABLE crm.contact_persons IS 'Persone di riferimento per ogni contatto';
COMMENT ON TABLE crm.activities IS 'Storico interazioni: chiamate, email, preventivi, ordini';
