-- Purchase Orders Schema

-- Purchase Orders Header
CREATE TABLE IF NOT EXISTS purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  po_number VARCHAR(50) NOT NULL UNIQUE,
  
  -- Supplier
  supplier_id UUID NOT NULL,
  supplier_name VARCHAR(255),
  supplier_contact VARCHAR(255),
  supplier_email VARCHAR(255),
  
  -- Dates
  order_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expected_delivery_date DATE,
  delivery_date DATE,
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN 
    ('draft', 'sent', 'confirmed', 'partially_received', 'received', 'cancelled')),
  
  -- Addresses
  billing_address JSONB,
  shipping_address JSONB,
  
  -- Payment
  payment_terms VARCHAR(100),
  payment_method VARCHAR(50),
  currency VARCHAR(3) DEFAULT 'EUR',
  
  -- Totals
  subtotal NUMERIC(15,2) DEFAULT 0,
  tax_amount NUMERIC(15,2) DEFAULT 0,
  shipping_cost NUMERIC(15,2) DEFAULT 0,
  discount_amount NUMERIC(15,2) DEFAULT 0,
  total_amount NUMERIC(15,2) DEFAULT 0,
  
  -- Shipping
  shipping_method VARCHAR(100),
  tracking_number VARCHAR(100),
  carrier VARCHAR(100),
  
  -- Notes
  notes TEXT,
  internal_notes TEXT,
  terms_and_conditions TEXT,
  
  -- Workflow
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  sent_by UUID,
  sent_at TIMESTAMPTZ,
  
  -- Attachments
  attachments JSONB DEFAULT '[]',
  
  -- Audit
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_po_tenant ON purchase_orders(tenant_id);
CREATE INDEX idx_po_supplier ON purchase_orders(supplier_id);
CREATE INDEX idx_po_status ON purchase_orders(status);
CREATE INDEX idx_po_order_date ON purchase_orders(order_date);

-- Purchase Order Lines
CREATE TABLE IF NOT EXISTS purchase_order_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL,
  
  -- Item
  item_id UUID,
  item_sku VARCHAR(100),
  item_name VARCHAR(255) NOT NULL,
  item_description TEXT,
  
  -- Quantity
  quantity NUMERIC(15,2) NOT NULL,
  unit_of_measure VARCHAR(50) DEFAULT 'pcs',
  
  -- Received quantities
  quantity_received NUMERIC(15,2) DEFAULT 0,
  quantity_remaining NUMERIC(15,2) GENERATED ALWAYS AS (quantity - quantity_received) STORED,
  
  -- Pricing
  unit_price NUMERIC(15,2) NOT NULL,
  discount_percent NUMERIC(5,2) DEFAULT 0,
  discount_amount NUMERIC(15,2) DEFAULT 0,
  tax_percent NUMERIC(5,2) DEFAULT 0,
  tax_amount NUMERIC(15,2) DEFAULT 0,
  line_total NUMERIC(15,2) GENERATED ALWAYS AS (
    (quantity * unit_price) - discount_amount + tax_amount
  ) STORED,
  
  -- Delivery
  expected_delivery_date DATE,
  delivery_location_id UUID,
  
  -- Status
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN 
    ('pending', 'confirmed', 'partially_received', 'received', 'cancelled')),
  
  -- Notes
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(po_id, line_number)
);

CREATE INDEX idx_po_lines_po ON purchase_order_lines(po_id);
CREATE INDEX idx_po_lines_item ON purchase_order_lines(item_id);
CREATE INDEX idx_po_lines_status ON purchase_order_lines(status);

-- Purchase Order Receipts (linked to GRN)
CREATE TABLE IF NOT EXISTS purchase_order_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  po_id UUID NOT NULL REFERENCES purchase_orders(id),
  po_line_id UUID NOT NULL REFERENCES purchase_order_lines(id),
  
  grn_id UUID, -- Reference to inventory GRN
  grn_line_id UUID,
  
  received_quantity NUMERIC(15,2) NOT NULL,
  received_date TIMESTAMPTZ DEFAULT NOW(),
  received_by UUID,
  
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_po_receipts_po ON purchase_order_receipts(po_id);
CREATE INDEX idx_po_receipts_grn ON purchase_order_receipts(grn_id);

-- Purchase Order Comments/Activities
CREATE TABLE IF NOT EXISTS purchase_order_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  
  activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN 
    ('created', 'updated', 'sent', 'approved', 'confirmed', 'received', 'cancelled', 'comment')),
  
  user_id UUID,
  user_name VARCHAR(255),
  
  description TEXT,
  metadata JSONB,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_po_activities_po ON purchase_order_activities(po_id);
CREATE INDEX idx_po_activities_type ON purchase_order_activities(activity_type);
