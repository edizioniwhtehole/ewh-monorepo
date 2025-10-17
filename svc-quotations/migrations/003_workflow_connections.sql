-- Add support for node connections and custom nodes

-- Add connections support to workflow definitions
-- Each connection links two nodes with a math operator

-- Custom node types created by users
CREATE TABLE IF NOT EXISTS pricing.custom_node_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  type_key VARCHAR(50) NOT NULL,
  type_name VARCHAR(100) NOT NULL,
  category VARCHAR(50) NOT NULL,
  icon VARCHAR(50) DEFAULT '🔧',
  color VARCHAR(20) DEFAULT '#6366f1',
  formula TEXT, -- Formula per calcolo custom: es. "(input1 + input2) * markup"
  input_ports JSONB DEFAULT '[]', -- Array di input: [{"id": "input1", "label": "Base Cost"}]
  output_ports JSONB DEFAULT '[]', -- Array di output
  config_schema JSONB, -- Schema configurazione
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tenant_id, type_key)
);

CREATE INDEX idx_custom_node_types_tenant ON pricing.custom_node_types(tenant_id);

-- Add metadata to existing workflows
ALTER TABLE pricing.workflow_templates 
ADD COLUMN IF NOT EXISTS connections JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS viewport JSONB DEFAULT '{"x": 0, "y": 0, "zoom": 1}',
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

ALTER TABLE pricing.quote_workflows
ADD COLUMN IF NOT EXISTS connections JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS viewport JSONB DEFAULT '{"x": 0, "y": 0, "zoom": 1}',
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- Sample custom node type
INSERT INTO pricing.custom_node_types (tenant_id, type_key, type_name, category, icon, color, formula, input_ports, output_ports)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'markup',
  'Margine %',
  'calculation',
  '📈',
  '#8b5cf6',
  'input * (1 + percentage/100)',
  '[{"id": "input", "label": "Costo Base", "type": "number"}]',
  '[{"id": "output", "label": "Costo Finale", "type": "number"}]'
) ON CONFLICT DO NOTHING;

INSERT INTO pricing.custom_node_types (tenant_id, type_key, type_name, category, icon, color, formula, input_ports, output_ports)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'discount',
  'Sconto %',
  'calculation',
  '🏷️',
  '#ef4444',
  'input * (1 - percentage/100)',
  '[{"id": "input", "label": "Prezzo", "type": "number"}]',
  '[{"id": "output", "label": "Prezzo Scontato", "type": "number"}]'
) ON CONFLICT DO NOTHING;

COMMENT ON TABLE pricing.custom_node_types IS 'Tipi di nodi personalizzati creati dagli utenti';
COMMENT ON COLUMN pricing.workflow_templates.connections IS 'Array di connessioni tra nodi: [{"id", "source", "sourceHandle", "target", "targetHandle", "operator": "+"}]';
