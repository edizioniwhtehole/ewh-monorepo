import pg from 'pg';
const { Pool } = pg;
const TENANT = '00000000-0000-0000-0000-000000000001';

async function populate() {
  const pool = new Pool({
    host: 'localhost', port: 5432, database: 'ewh_master',
    user: 'ewh', password: 'password'
  });

  // Macchine
  const machines = [
    { code: 'MACH-001', name: 'Heidelberg Speedmaster XL 106', hourly: 150, setup: 500, power: 45, speed: 15000 },
    { code: 'MACH-002', name: 'KBA Rapida 106', hourly: 140, setup: 450, power: 42, speed: 14000 },
    { code: 'MACH-003', name: 'Legatrice Muller Martini', hourly: 85, setup: 200, power: 25, speed: 8000 },
    { code: 'MACH-004', name: 'Taglierina Polar 137', hourly: 45, setup: 50, power: 15, speed: 0 }
  ];

  for (const m of machines) {
    await pool.query(
      'INSERT INTO pricing.production_resources (tenant_id, resource_type, resource_code, resource_name, hourly_cost, setup_cost, power_consumption_kw, production_speed_per_hour, is_active) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)',
      [TENANT, 'machine', m.code, m.name, m.hourly, m.setup, m.power, m.speed]
    );
    console.log('✓ Macchina:', m.name);
  }

  // Materiali
  const materials = [
    { code: 'MAT-001', name: 'Carta patinata opaca 115g', type: 'paper', unit: 'kg', cost: 2.50, waste: 5 },
    { code: 'MAT-002', name: 'Carta patinata lucida 135g', type: 'paper', unit: 'kg', cost: 2.80, waste: 5 },
    { code: 'MAT-003', name: 'Cartoncino 300g', type: 'board', unit: 'kg', cost: 3.20, waste: 8 },
    { code: 'MAT-004', name: 'Inchiostro CMYK offset', type: 'ink', unit: 'kg', cost: 45.00, waste: 2 },
    { code: 'MAT-005', name: 'Colla hotmelt', type: 'glue', unit: 'kg', cost: 12.00, waste: 1 },
    { code: 'MAT-006', name: 'Film plastificazione', type: 'film', unit: 'm²', cost: 1.50, waste: 3 }
  ];

  for (const m of materials) {
    await pool.query(
      'INSERT INTO pricing.materials (tenant_id, material_code, material_name, material_type, unit_of_measure, cost_per_unit, waste_percentage, is_active) VALUES ($1, $2, $3, $4, $5, $6, $7, true)',
      [TENANT, m.code, m.name, m.type, m.unit, m.cost, m.waste]
    );
    console.log('✓ Materiale:', m.name);
  }

  // Operatori (come risorse)
  const operators = [
    { code: 'OP-001', name: 'Stampatore Senior', hourly: 28, setup: 0, power: 0, speed: 0 },
    { code: 'OP-002', name: 'Stampatore Junior', hourly: 20, setup: 0, power: 0, speed: 0 },
    { code: 'OP-003', name: 'Operatore Legatoria', hourly: 22, setup: 0, power: 0, speed: 0 },
    { code: 'OP-004', name: 'Operatore Taglio', hourly: 18, setup: 0, power: 0, speed: 0 }
  ];

  for (const o of operators) {
    await pool.query(
      'INSERT INTO pricing.production_resources (tenant_id, resource_type, resource_code, resource_name, hourly_cost, setup_cost, power_consumption_kw, production_speed_per_hour, is_active) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)',
      [TENANT, 'operator', o.code, o.name, o.hourly, o.setup, o.power, o.speed]
    );
    console.log('✓ Operatore:', o.name);
  }

  console.log('\n✅ Dati pricing popolati!');
  await pool.end();
}

populate();
