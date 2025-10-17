import pg from 'pg';
const { Pool } = pg;

async function createSchema() {
  const pool = new Pool({
    host: 'localhost',
    port: 5432,
    database: 'ewh_master',
    user: 'ewh',
    password: 'password'
  });

  const queries = [
    'CREATE SCHEMA IF NOT EXISTS pricing',
    
    `CREATE TABLE IF NOT EXISTS pricing.node_types (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      type_key VARCHAR(50) UNIQUE NOT NULL,
      type_name VARCHAR(100) NOT NULL,
      category VARCHAR(50),
      icon VARCHAR(50),
      color VARCHAR(20),
      config_schema JSONB,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    `CREATE TABLE IF NOT EXISTS pricing.production_resources (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tenant_id UUID NOT NULL,
      resource_type VARCHAR(50) NOT NULL,
      resource_code VARCHAR(50) NOT NULL,
      resource_name VARCHAR(255) NOT NULL,
      hourly_cost DECIMAL(10,2),
      setup_cost DECIMAL(10,2),
      power_consumption_kw DECIMAL(8,2),
      production_speed_per_hour DECIMAL(10,2),
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    `CREATE TABLE IF NOT EXISTS pricing.materials (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tenant_id UUID NOT NULL,
      material_code VARCHAR(50) NOT NULL,
      material_name VARCHAR(255) NOT NULL,
      material_type VARCHAR(100),
      unit_of_measure VARCHAR(50),
      cost_per_unit DECIMAL(10,4),
      waste_percentage DECIMAL(5,2) DEFAULT 5.00,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    `CREATE TABLE IF NOT EXISTS pricing.workflow_templates (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tenant_id UUID NOT NULL,
      template_name VARCHAR(255) NOT NULL,
      category VARCHAR(100),
      workflow_definition JSONB NOT NULL,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    `CREATE TABLE IF NOT EXISTS pricing.quote_workflows (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tenant_id UUID NOT NULL,
      quote_id UUID,
      workflow_name VARCHAR(255),
      workflow_definition JSONB NOT NULL,
      calculated_cost DECIMAL(12,2),
      calculation_breakdown JSONB,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,

    `INSERT INTO pricing.node_types (type_key, type_name, category, icon, color) VALUES
      ('machine', 'Macchina', 'production', '⚙️', '#3b82f6'),
      ('operator', 'Operatore', 'labor', '👤', '#10b981'),
      ('material', 'Materiale', 'material', '📦', '#f59e0b'),
      ('electricity', 'Corrente', 'overhead', '⚡', '#eab308'),
      ('waste', 'Scarto', 'calculation', '🗑️', '#ef4444'),
      ('fixed_cost', 'Costo Fisso', 'overhead', '💰', '#8b5cf6'),
      ('percentage', 'Percentuale', 'calculation', '%', '#ec4899'),
      ('sum', 'Somma', 'calculation', '+', '#14b8a6')
    ON CONFLICT (type_key) DO NOTHING`
  ];

  for (const q of queries) {
    try {
      await pool.query(q);
      console.log('✓ Executed');
    } catch (e: any) {
      if (e.message.includes('already exists')) {
        console.log('⊙ Already exists');
      } else {
        console.error('✗', e.message);
      }
    }
  }

  console.log('\n✅ Pricing schema created!');
  await pool.end();
}

createSchema();
