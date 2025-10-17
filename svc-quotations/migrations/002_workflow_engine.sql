-- Workflow Engine for Dynamic Price Calculation

CREATE SCHEMA IF NOT EXISTS pricing;

-- Tipi di nodi disponibili
CREATE TABLE IF NOT EXISTS pricing.node_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_key VARCHAR(50) UNIQUE NOT NULL, -- 'machine', 'operator', 'material', 'fixed_cost', 'percentage', 'formula'
    type_name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- 'production', 'labor', 'material', 'overhead', 'calculation'
    icon VARCHAR(50),
    color VARCHAR(20),
    config_schema JSONB, -- Schema dei parametri configurabili
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Template workflow salvati
CREATE TABLE IF NOT EXISTS pricing.workflow_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    template_name VARCHAR(255) NOT NULL,
    category VARCHAR(100), -- 'printing', 'binding', 'packaging'
    description TEXT,
    workflow_definition JSONB NOT NULL, -- Nodi e connessioni
    is_active BOOLEAN DEFAULT true,
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workflow specifici per preventivi
CREATE TABLE IF NOT EXISTS pricing.quote_workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    quote_id UUID REFERENCES quotations.quotes(id) ON DELETE CASCADE,
    workflow_name VARCHAR(255),
    workflow_definition JSONB NOT NULL, -- Nodi con valori specifici
    calculated_cost DECIMAL(12,2),
    calculation_breakdown JSONB, -- Dettaglio di ogni nodo
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risorse di produzione (macchine, operatori)
CREATE TABLE IF NOT EXISTS pricing.production_resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    resource_type VARCHAR(50) NOT NULL, -- 'machine', 'operator', 'tool'
    resource_code VARCHAR(50) UNIQUE NOT NULL,
    resource_name VARCHAR(255) NOT NULL,
    
    -- Costi
    hourly_cost DECIMAL(10,2), -- Costo orario
    setup_cost DECIMAL(10,2), -- Costo avviamento
    power_consumption_kw DECIMAL(8,2), -- Consumo elettrico
    maintenance_cost_per_hour DECIMAL(10,2),
    
    -- Capacità
    production_speed_per_hour DECIMAL(10,2), -- Unità/ora
    efficiency_percentage DECIMAL(5,2) DEFAULT 100.00,
    
    -- Collegamenti
    mrp_machine_id UUID, -- Collegamento a MRP
    
    metadata JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_resources_tenant ON pricing.production_resources(tenant_id);
CREATE INDEX idx_resources_type ON pricing.production_resources(resource_type);

-- Materiali e listini
CREATE TABLE IF NOT EXISTS pricing.materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    material_code VARCHAR(50) UNIQUE NOT NULL,
    material_name VARCHAR(255) NOT NULL,
    material_type VARCHAR(100), -- 'paper', 'ink', 'glue', 'board'
    
    unit_of_measure VARCHAR(50), -- 'kg', 'liters', 'sheets', 'meters'
    cost_per_unit DECIMAL(10,4),
    
    waste_percentage DECIMAL(5,2) DEFAULT 5.00, -- Scarto standard
    
    -- Fornitori
    supplier_id UUID REFERENCES procurement.suppliers(id),
    lead_time_days INT,
    
    -- Inventario (collegamento futuro)
    inventory_item_id UUID,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_materials_tenant ON pricing.materials(tenant_id);
CREATE INDEX idx_materials_type ON pricing.materials(material_type);

-- Costi fissi e variabili
CREATE TABLE IF NOT EXISTS pricing.overhead_costs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    cost_name VARCHAR(255) NOT NULL,
    cost_type VARCHAR(50), -- 'electricity', 'rent', 'insurance', 'depreciation'
    
    calculation_method VARCHAR(50), -- 'fixed', 'per_hour', 'per_unit', 'percentage'
    amount DECIMAL(10,2),
    
    applies_to VARCHAR(50), -- 'all', 'printing', 'binding', etc.
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Storico calcoli
CREATE TABLE IF NOT EXISTS pricing.calculation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_workflow_id UUID REFERENCES pricing.quote_workflows(id) ON DELETE CASCADE,
    calculation_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    input_parameters JSONB,
    output_result JSONB,
    execution_time_ms INT
);

-- Insert nodi base
INSERT INTO pricing.node_types (type_key, type_name, category, icon, color, config_schema) VALUES
('machine', 'Macchina', 'production', '⚙️', '#3b82f6', '{"fields": ["machine_id", "hours", "setup_cost"]}'),
('operator', 'Operatore', 'labor', '👤', '#10b981', '{"fields": ["operator_type", "hours", "hourly_rate"]}'),
('material', 'Materiale', 'material', '📦', '#f59e0b', '{"fields": ["material_id", "quantity", "waste_percentage"]}'),
('fixed_cost', 'Costo Fisso', 'overhead', '💰', '#8b5cf6', '{"fields": ["amount", "description"]}'),
('percentage', 'Percentuale', 'calculation', '%', '#ec4899', '{"fields": ["percentage", "apply_to"]}'),
('electricity', 'Corrente', 'overhead', '⚡', '#eab308', '{"fields": ["kwh", "cost_per_kwh"]}'),
('waste', 'Scarto', 'calculation', '🗑️', '#ef4444', '{"fields": ["percentage"]}'),
('formula', 'Formula', 'calculation', '∑', '#6366f1', '{"fields": ["expression"]}'),
('sum', 'Somma', 'calculation', '+', '#14b8a6', '{"fields": ["inputs"]}'),
('multiply', 'Moltiplica', 'calculation', '×', '#a855f7', '{"fields": ["factor_a", "factor_b"]}')
ON CONFLICT (type_key) DO NOTHING;

