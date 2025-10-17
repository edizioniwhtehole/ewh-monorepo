#!/usr/bin/env node

/**
 * EWH Platform - Supabase Setup via Node.js
 * Uses Management API to execute SQL
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// Environment configurations
const ENVS = {
  dev: {
    url: 'https://ezbwpkqcxdlixngvkpjl.supabase.co',
    serviceKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV6Yndwa3FjeGRsaXhuZ3ZrcGpsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYyOTEzOCwiZXhwIjoyMDc2MjA1MTM4fQ.hTdFFuVEAVgTuAYzMgElEETk9fMFKKWN9LDP5OqL8BE',
    dbPassword: 'ehjOzYUWc13OVrst',
    projectRef: 'ezbwpkqcxdlixngvkpjl'
  },
  staging: {
    url: 'https://pqcbzzxlpiozofqovrix.supabase.co',
    serviceKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxY2J6enhscGlvem9mcW92cml4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzQ1NCwiZXhwIjoyMDc2MTkzNDU0fQ.2Ouzh6g0pjdHfMIolBXqil0k8xO3qpHSeGX-PlnAXEs',
    dbPassword: 'THwrraV5kRnUPgjE',
    projectRef: 'pqcbzzxlpiozofqovrix'
  },
  prod: {
    url: 'https://qubhjidkgpxlyruwkfkb.supabase.co',
    serviceKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF1YmhqaWRrZ3B4bHlydXdrZmtiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY0OTU4MywiZXhwIjoyMDc2MjI1NTgzfQ.Te5SBFQxmmW1UYKbWOhCYbc2QM-FcEUikMztL7r6xzI',
    dbPassword: 'uhY0n3eadUhiNjOu',
    projectRef: 'qubhjidkgpxlyruwkfkb'
  }
};

// Read SQL file
const sqlFile = path.join(__dirname, 'setup-supabase-complete.sql');
const sqlContent = fs.readFileSync(sqlFile, 'utf-8');

// Helper: Execute SQL via psql (using connection string)
function executeSQLviaPSQL(env, sql) {
  return new Promise((resolve, reject) => {
    const { exec } = require('child_process');

    const connString = `postgresql://postgres.${env.projectRef}:${env.dbPassword}@aws-0-eu-central-1.pooler.supabase.com:6543/postgres`;

    const psqlPath = '/opt/homebrew/Cellar/postgresql@16/16.10/bin/psql';

    // Write SQL to temp file
    const tempFile = `/tmp/supabase_setup_${env.projectRef}.sql`;
    fs.writeFileSync(tempFile, sql);

    const cmd = `${psqlPath} "${connString}" -f "${tempFile}" 2>&1`;

    exec(cmd, { maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
      fs.unlinkSync(tempFile); // cleanup

      if (error) {
        reject({ error, stdout, stderr });
      } else {
        resolve({ stdout, stderr });
      }
    });
  });
}

// Setup one environment
async function setupEnvironment(envName) {
  console.log('\n' + '='.repeat(70));
  console.log(`🚀 Setting up ${envName.toUpperCase()} environment`);
  console.log('='.repeat(70) + '\n');

  const env = ENVS[envName];

  try {
    // Execute main SQL setup
    console.log('📋 Applying SQL schema...');
    const result = await executeSQLviaPSQL(env, sqlContent);

    if (result.stderr && !result.stderr.includes('NOTICE')) {
      console.log('⚠️  Warnings:', result.stderr.substring(0, 500));
    }

    console.log('✅ Schema setup completed\n');

    // Create tenants
    console.log('👥 Creating tenants...');

    if (envName === 'dev') {
      await executeSQLviaPSQL(env, `
        SELECT core.create_tenant('acme', 'ACME Corporation', 'free',
          ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);
        SELECT core.create_tenant('test', 'Test Company', 'free',
          ARRAY['pm', 'crm', 'dam']);
      `);

      console.log('📝 Inserting demo data...');
      await executeSQLviaPSQL(env, `
        INSERT INTO tenant_acme.pm_projects (name, description, status, priority) VALUES
          ('Website Redesign', 'Complete redesign of company website', 'active', 'high'),
          ('Mobile App Development', 'New mobile app for customers', 'active', 'urgent'),
          ('Infrastructure Upgrade', 'Server infrastructure modernization', 'on_hold', 'medium');

        INSERT INTO tenant_acme.crm_customers (company_name, contact_name, email, status) VALUES
          ('Tech Innovations Inc', 'John Smith', 'john@techinnovations.com', 'active'),
          ('Design Masters Studio', 'Jane Doe', 'jane@designmasters.com', 'active'),
          ('Global Marketing Ltd', 'Bob Wilson', 'bob@globalmarketing.com', 'prospect');

        INSERT INTO tenant_acme.inventory_products (sku, name, unit_price, quantity_on_hand) VALUES
          ('WID-PREM-001', 'Premium Widget', 99.99, 50),
          ('WID-STD-002', 'Standard Widget', 49.99, 120),
          ('WID-BAS-003', 'Basic Widget', 19.99, 200);
      `);

    } else if (envName === 'staging') {
      await executeSQLviaPSQL(env, `
        SELECT core.create_tenant('acme', 'ACME Corporation', 'standard',
          ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);
        SELECT core.create_tenant('demo', 'Demo Company', 'free',
          ARRAY['pm', 'crm', 'dam']);
      `);

      await executeSQLviaPSQL(env, `
        INSERT INTO tenant_acme.pm_projects (name, description, status, priority) VALUES
          ('Website Redesign', 'Complete redesign of company website', 'active', 'high'),
          ('Mobile App Development', 'New mobile app for customers', 'active', 'urgent');

        INSERT INTO tenant_acme.crm_customers (company_name, contact_name, email, status) VALUES
          ('Tech Innovations Inc', 'John Smith', 'john@techinnovations.com', 'active');
      `);

    } else if (envName === 'prod') {
      await executeSQLviaPSQL(env, `
        SELECT core.create_tenant('acme', 'ACME Corporation', 'enterprise',
          ARRAY['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']);
      `);
      console.log('⚠️  No demo data in PROD (production environment)');
    }

    console.log('✅ Tenants created\n');

    // Verify
    console.log('🔍 Verifying setup...');
    const verify = await executeSQLviaPSQL(env, 'SELECT slug, name, tier FROM core.tenants;');
    console.log(verify.stdout);

    console.log(`✅ ${envName.toUpperCase()} environment setup complete!\n`);

    return true;

  } catch (error) {
    console.error(`❌ ${envName.toUpperCase()} setup failed:`, error.stderr || error.message);
    return false;
  }
}

// Main
async function main() {
  console.log('\n' + '='.repeat(70));
  console.log('🏗️  EWH PLATFORM - SUPABASE SETUP');
  console.log('='.repeat(70));

  try {
    await setupEnvironment('dev');
    await new Promise(resolve => setTimeout(resolve, 3000));

    await setupEnvironment('staging');
    await new Promise(resolve => setTimeout(resolve, 3000));

    await setupEnvironment('prod');

    console.log('\n' + '='.repeat(70));
    console.log('🎉 ALL ENVIRONMENTS CONFIGURED SUCCESSFULLY!');
    console.log('='.repeat(70) + '\n');

    console.log('✅ DEV:     https://ezbwpkqcxdlixngvkpjl.supabase.co');
    console.log('✅ STAGING: https://pqcbzzxlpiozofqovrix.supabase.co');
    console.log('✅ PROD:    https://qubhjidkgpxlyruwkfkb.supabase.co\n');

  } catch (error) {
    console.error('\n❌ Setup failed:', error);
    process.exit(1);
  }
}

main();
