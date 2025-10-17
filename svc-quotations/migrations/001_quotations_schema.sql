-- Quotations Module Schema
-- Gestione preventivi in USCITA per clienti

CREATE SCHEMA IF NOT EXISTS quotations;

-- Clienti (può anche usare tabella users/contacts esistente)
CREATE TABLE IF NOT EXISTS quotations.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    vat_number VARCHAR(50),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    contact_person VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_tenant ON quotations.customers(tenant_id);

-- Template preventivi
CREATE TABLE IF NOT EXISTS quotations.quote_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    template_name VARCHAR(255) NOT NULL,
    category VARCHAR(100), -- 'printing', 'publishing', 'design', 'editorial'
    description TEXT,
    line_items JSONB, -- Template items
    terms_and_conditions TEXT,
    validity_days INT DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Preventivi clienti
CREATE TABLE IF NOT EXISTS quotations.quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    quote_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES quotations.customers(id),
    template_id UUID REFERENCES quotations.quote_templates(id),
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    quote_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 22.00, -- IVA 22%
    tax_amount DECIMAL(12,2) DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'EUR',
    
    status VARCHAR(50) DEFAULT 'draft', -- 'draft', 'sent', 'viewed', 'accepted', 'rejected', 'expired'
    
    notes TEXT,
    terms_and_conditions TEXT,
    payment_terms VARCHAR(255),
    
    -- Tracking
    sent_at TIMESTAMP,
    viewed_at TIMESTAMP,
    accepted_at TIMESTAMP,
    rejected_at TIMESTAMP,
    rejection_reason TEXT,
    
    -- Conversion
    converted_to_project BOOLEAN DEFAULT false,
    project_id UUID, -- Link to PM project if accepted
    
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_quotes_tenant ON quotations.quotes(tenant_id);
CREATE INDEX idx_quotes_customer ON quotations.quotes(customer_id);
CREATE INDEX idx_quotes_status ON quotations.quotes(status);
CREATE INDEX idx_quotes_project ON quotations.quotes(project_id);

-- Line items preventivo
CREATE TABLE IF NOT EXISTS quotations.quote_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID NOT NULL REFERENCES quotations.quotes(id) ON DELETE CASCADE,
    line_number INT NOT NULL,
    item_type VARCHAR(50), -- 'product', 'service', 'discount', 'text'
    description TEXT NOT NULL,
    quantity DECIMAL(12,2) NOT NULL DEFAULT 1,
    unit_of_measure VARCHAR(50),
    unit_price DECIMAL(12,2) NOT NULL,
    total_price DECIMAL(12,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Storico revisioni preventivo
CREATE TABLE IF NOT EXISTS quotations.quote_revisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID NOT NULL REFERENCES quotations.quotes(id) ON DELETE CASCADE,
    revision_number INT NOT NULL,
    changes JSONB, -- What changed
    total_amount DECIMAL(12,2),
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attività su preventivo (email inviata, visualizzato, ecc)
CREATE TABLE IF NOT EXISTS quotations.quote_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID NOT NULL REFERENCES quotations.quotes(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL, -- 'created', 'sent', 'viewed', 'downloaded', 'accepted', 'rejected'
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Triggers
CREATE OR REPLACE FUNCTION quotations.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON quotations.customers
    FOR EACH ROW EXECUTE FUNCTION quotations.update_updated_at();
CREATE TRIGGER trg_templates_updated_at BEFORE UPDATE ON quotations.quote_templates
    FOR EACH ROW EXECUTE FUNCTION quotations.update_updated_at();
CREATE TRIGGER trg_quotes_updated_at BEFORE UPDATE ON quotations.quotes
    FOR EACH ROW EXECUTE FUNCTION quotations.update_updated_at();
