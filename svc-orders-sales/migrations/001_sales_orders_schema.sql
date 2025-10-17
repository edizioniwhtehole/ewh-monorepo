-- Sales Orders Schema Migration
-- Port: 6300
-- Similar to purchase orders but for customer sales

CREATE TABLE IF NOT EXISTS sales_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  so_number VARCHAR(50) NOT NULL UNIQUE,
  customer_id UUID NOT NULL,
  customer_name VARCHAR(255),
  order_date DATE NOT NULL DEFAULT CURRENT_DATE,
  requested_delivery_date DATE,
  promised_delivery_date DATE,
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN
    ('draft', 'confirmed', 'in_production', 'ready_to_ship', 'partially_shipped', 'shipped', 'delivered', 'cancelled')),
  billing_address JSONB,
  shipping_address JSONB,
  payment_terms VARCHAR(100),
  payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN
    ('pending', 'partial', 'paid', 'overdue', 'refunded')),
  currency VARCHAR(3) DEFAULT 'EUR',
  subtotal NUMERIC(15,2) DEFAULT 0,
  discount_amount NUMERIC(15,2) DEFAULT 0,
  tax_amount NUMERIC(15,2) DEFAULT 0,
  shipping_cost NUMERIC(15,2) DEFAULT 0,
  total_amount NUMERIC(15,2) DEFAULT 0,
  notes TEXT,
  internal_notes TEXT,
  priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  sales_rep_id UUID,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sales_orders_tenant ON sales_orders(tenant_id);
CREATE INDEX idx_sales_orders_customer ON sales_orders(customer_id);
CREATE INDEX idx_sales_orders_status ON sales_orders(status);
CREATE INDEX idx_sales_orders_order_date ON sales_orders(order_date DESC);

CREATE TABLE IF NOT EXISTS sales_order_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  so_id UUID NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL,
  item_id UUID,
  item_sku VARCHAR(100),
  item_name VARCHAR(255) NOT NULL,
  item_description TEXT,
  quantity NUMERIC(15,2) NOT NULL,
  unit_price NUMERIC(15,2) NOT NULL,
  discount_percent NUMERIC(5,2) DEFAULT 0,
  discount_amount NUMERIC(15,2) DEFAULT 0,
  quantity_shipped NUMERIC(15,2) DEFAULT 0,
  quantity_remaining NUMERIC(15,2) GENERATED ALWAYS AS (quantity - quantity_shipped) STORED,
  tax_percent NUMERIC(5,2) DEFAULT 0,
  tax_amount NUMERIC(15,2) DEFAULT 0,
  line_total NUMERIC(15,2) GENERATED ALWAYS AS ((quantity * unit_price) - discount_amount + tax_amount) STORED,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN
    ('pending', 'allocated', 'in_production', 'ready', 'partially_shipped', 'shipped', 'cancelled')),
  production_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(so_id, line_number)
);

CREATE INDEX idx_sales_order_lines_so ON sales_order_lines(so_id);
CREATE INDEX idx_sales_order_lines_item ON sales_order_lines(item_id);

CREATE TABLE IF NOT EXISTS sales_order_shipments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  so_id UUID NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
  shipment_number VARCHAR(50) NOT NULL UNIQUE,
  shipment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  carrier VARCHAR(100),
  tracking_number VARCHAR(100),
  shipping_method VARCHAR(100),
  shipping_cost NUMERIC(15,2) DEFAULT 0,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN
    ('pending', 'picked', 'packed', 'shipped', 'in_transit', 'delivered', 'cancelled')),
  notes TEXT,
  shipped_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sales_shipments_so ON sales_order_shipments(so_id);

CREATE TABLE IF NOT EXISTS sales_order_shipment_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shipment_id UUID NOT NULL REFERENCES sales_order_shipments(id) ON DELETE CASCADE,
  so_line_id UUID NOT NULL REFERENCES sales_order_lines(id) ON DELETE CASCADE,
  quantity_shipped NUMERIC(15,2) NOT NULL,
  lot_number VARCHAR(100),
  serial_numbers TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sales_order_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  so_id UUID NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
  activity_type VARCHAR(50) NOT NULL,
  user_id UUID,
  user_name VARCHAR(255),
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sales_activities_so ON sales_order_activities(so_id);
CREATE INDEX idx_sales_activities_created ON sales_order_activities(created_at DESC);
