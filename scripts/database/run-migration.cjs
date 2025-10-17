#!/usr/bin/env node

/**
 * Migration Runner
 * Runs SQL migrations without requiring psql client
 */

const fs = require('fs');
const { Client } = require('pg');

const DATABASE_URL = process.env.DATABASE_URL || 'postgres://ewh:ewhpass@localhost:5432/ewh_master';
const MIGRATION_FILE = process.argv[2];

if (!MIGRATION_FILE) {
  console.error('❌ Usage: node run-migration.js <migration-file.sql>');
  process.exit(1);
}

if (!fs.existsSync(MIGRATION_FILE)) {
  console.error(`❌ Migration file not found: ${MIGRATION_FILE}`);
  process.exit(1);
}

async function runMigration() {
  const client = new Client({ connectionString: DATABASE_URL });

  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected');

    console.log(`📄 Reading migration: ${MIGRATION_FILE}`);
    const sql = fs.readFileSync(MIGRATION_FILE, 'utf8');

    console.log('🚀 Executing migration...');
    const result = await client.query(sql);

    console.log('✅ Migration completed successfully');
    console.log(`   Rows affected: ${result.rowCount || 'N/A'}`);
  } catch (error) {
    console.error('❌ Migration failed:');
    console.error(error.message);
    if (error.position) {
      console.error(`   Position: ${error.position}`);
    }
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigration();
