import pg from 'pg';
import fs from 'fs';

const {Pool} = pg;

async function migrate() {
  const pool = new Pool({
    host: 'localhost',
    port: 5432,
    database: 'ewh_master',
    user: 'ewh',
    password: 'password'
  });

  const sql = fs.readFileSync('migrations/001_quotations_schema.sql', 'utf8');

  try {
    await pool.query(sql);
    console.log('✅ Migration completed successfully');
  } catch (e: any) {
    console.log('❌ Error:', e.message);
  }

  await pool.end();
}

migrate();
