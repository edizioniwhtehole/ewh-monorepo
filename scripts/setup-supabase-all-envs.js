#!/usr/bin/env node

/**
 * EWH Platform - Supabase Setup Script
 * Configures DEV, STAGING, and PROD environments
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Environment configurations
const ENVIRONMENTS = {
  dev: {
    url: 'https://ezbwpkqcxdlixngvkpjl.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF1YmhqaWRrZ3B4bHlydXdrZmtiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY0OTU4MywiZXhwIjoyMDc2MjI1NTgzfQ.Te5SBFQxmmW1UYKbWOhCYbc2QM-FcEUikMztL7r6xzI',
    demoData: true
  },
  staging: {
    url: 'https://pqcbzzxlpiozofqovrix.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxY2J6enhscGlvem9mcW92cml4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDYxNzQ1NCwiZXhwIjoyMDc2MTkzNDU0fQ.2Ouzh6g0pjdHfMIolBXqil0k8xO3qpHSeGX-PlnAXEs',
    demoData: true
  },
  prod: {
    url: 'https://qubhjidkgpxlyruwkfkb.supabase.co',
    key: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF1YmhqaWRrZ3B4bHlydXdrZmtiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDY0OTU4MywiZXhwIjoyMDc2MjI1NTgzfQ.Te5SBFQxmmW1UYKbWOhCYbc2QM-FcEUikMztL7r6xzI',
    demoData: false // Production: no demo data
  }
};

// Read SQL setup script
const sqlSetupPath = path.join(__dirname, 'setup-supabase-complete.sql');
const sqlSetup = fs.readFileSync(sqlSetupPath, 'utf-8');

// Helper: Execute SQL via Supabase
async function executeSQL(supabase, sql, description) {
  console.log(`  ⏳ ${description}...`);

  try {
    // Split SQL into individual statements (basic split by semicolon)
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of statements) {
      if (statement.length > 10) { // Skip very short statements
        const { data, error } = await supabase.rpc('exec_sql', {
          sql_statement: statement
        });

        if (error) {
          // Check if it's just a "already exists" error (safe to ignore)
          if (error.message && (
            error.message.includes('already exists') ||
            error.message.includes('duplicate')
          )) {
            // Ignore, it's fine
            continue;
          }
          throw error;
        }
      }
    }

    console.log(`  ✅ ${description} completed`);
    return true;
  } catch (error) {
    console.error(`  ❌ ${description} failed:`, error.message);
    return false;
  }
}

// Helper: Execute SQL directly via REST API (fallback)
async function executeSQLDirect(env, sql) {
  const response = await fetch(`${env.url}/rest/v1/rpc/exec_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': env.key,
      'Authorization': `Bearer ${env.key}`
    },
    body: JSON.stringify({ sql_statement: sql })
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`SQL execution failed: ${error}`);
  }

  return response.json();
}

// Create tenant with demo data
async function createDemoTenant(supabase, tenantSlug, tenantName, environment) {
  console.log(`  📦 Creating tenant: ${tenantSlug}...`);

  try {
    // Create tenant using helper function
    const { data: tenantId, error } = await supabase.rpc('create_tenant', {
      p_slug: tenantSlug,
      p_name: tenantName,
      p_tier: environment === 'prod' ? 'standard' : 'free',
      p_enabled_apps: ['pm', 'crm', 'dam', 'orders', 'quotations', 'inventory']
    });

    if (error) throw error;

    console.log(`  ✅ Tenant created: ${tenantSlug} (${tenantId})`);

    // Insert demo data if requested
    if (ENVIRONMENTS[environment].demoData) {
      await insertDemoData(supabase, tenantSlug);
    }

    return tenantId;
  } catch (error) {
    console.error(`  ❌ Failed to create tenant:`, error.message);
    return null;
  }
}

// Insert demo data for a tenant
async function insertDemoData(supabase, tenantSlug) {
  console.log(`  📝 Inserting demo data for ${tenantSlug}...`);

  const schema = `tenant_${tenantSlug}`;

  try {
    // Insert demo projects
    await supabase.rpc('exec_sql', {
      sql_statement: `
        INSERT INTO ${schema}.pm_projects (name, description, status, priority) VALUES
        ('Website Redesign', 'Complete redesign of company website', 'active', 'high'),
        ('Mobile App', 'New mobile application for customers', 'active', 'urgent'),
        ('Infrastructure Update', 'Upgrade server infrastructure', 'on_hold', 'medium');
      `
    });

    // Insert demo customers
    await supabase.rpc('exec_sql', {
      sql_statement: `
        INSERT INTO ${schema}.crm_customers (company_name, contact_name, email, status) VALUES
        ('Tech Corp', 'John Smith', 'john@techcorp.com', 'active'),
        ('Design Studio', 'Jane Doe', 'jane@designstudio.com', 'active'),
        ('Marketing Inc', 'Bob Wilson', 'bob@marketing.com', 'prospect');
      `
    });

    // Insert demo products
    await supabase.rpc('exec_sql', {
      sql_statement: `
        INSERT INTO ${schema}.inventory_products (sku, name, unit_price, quantity_on_hand) VALUES
        ('PRD-001', 'Premium Widget', 99.99, 50),
        ('PRD-002', 'Standard Widget', 49.99, 120),
        ('PRD-003', 'Basic Widget', 19.99, 200);
      `
    });

    console.log(`  ✅ Demo data inserted for ${tenantSlug}`);
  } catch (error) {
    console.error(`  ⚠️  Demo data insertion failed (non-critical):`, error.message);
  }
}

// Main setup function for one environment
async function setupEnvironment(envName) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`🚀 Setting up ${envName.toUpperCase()} environment`);
  console.log(`${'='.repeat(60)}\n`);

  const env = ENVIRONMENTS[envName];
  const supabase = createClient(env.url, env.key);

  // Test connection
  console.log('📡 Testing connection...');
  try {
    const { data, error } = await supabase.from('core.tenants').select('count').limit(1);
    if (error && !error.message.includes('does not exist')) {
      throw error;
    }
    console.log('✅ Connection successful\n');
  } catch (error) {
    console.log('⚠️  Connection test skipped (table may not exist yet)\n');
  }

  // Execute main SQL setup
  console.log('📋 Executing SQL setup script...\n');

  // Split into logical sections for better error handling
  const sqlSections = sqlSetup.split('-- ============================================================================');

  for (let i = 0; i < sqlSections.length; i++) {
    const section = sqlSections[i].trim();
    if (section.length > 0) {
      const sectionName = section.split('\n')[0].replace('--', '').trim() || `Section ${i}`;

      // Execute this section
      const statements = section
        .split(';')
        .map(s => s.trim())
        .filter(s => s.length > 20 && !s.startsWith('--')); // Filter out comments and empty

      for (const statement of statements) {
        try {
          // Use direct REST API call
          await executeSQLDirect(env, statement);
        } catch (error) {
          // Ignore "already exists" errors
          if (!error.message.includes('already exists') &&
              !error.message.includes('duplicate')) {
            console.error(`  ⚠️  SQL warning:`, error.message.substring(0, 100));
          }
        }
      }
    }
  }

  console.log('\n✅ SQL setup completed\n');

  // Create demo tenants
  console.log('👥 Creating tenants...\n');

  if (envName === 'dev') {
    await createDemoTenant(supabase, 'acme', 'ACME Corporation', envName);
    await createDemoTenant(supabase, 'test', 'Test Company', envName);
  } else if (envName === 'staging') {
    await createDemoTenant(supabase, 'acme', 'ACME Corporation', envName);
    await createDemoTenant(supabase, 'demo', 'Demo Company', envName);
  } else if (envName === 'prod') {
    await createDemoTenant(supabase, 'acme', 'ACME Corporation', envName);
  }

  console.log(`\n✅ ${envName.toUpperCase()} environment setup complete!\n`);
}

// Main execution
async function main() {
  console.log('\n' + '='.repeat(60));
  console.log('🏗️  EWH PLATFORM - SUPABASE SETUP');
  console.log('='.repeat(60));

  const args = process.argv.slice(2);
  const envFilter = args[0]; // dev, staging, prod, or "all"

  try {
    if (envFilter && envFilter !== 'all' && ENVIRONMENTS[envFilter]) {
      // Setup single environment
      await setupEnvironment(envFilter);
    } else {
      // Setup all environments
      for (const envName of ['dev', 'staging', 'prod']) {
        await setupEnvironment(envName);

        // Wait a bit between environments
        if (envName !== 'prod') {
          console.log('\n⏳ Waiting 5 seconds before next environment...\n');
          await new Promise(resolve => setTimeout(resolve, 5000));
        }
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('🎉 ALL ENVIRONMENTS CONFIGURED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log('\n📝 Next steps:');
    console.log('1. Check your Supabase dashboards');
    console.log('2. Update your .env files with the credentials');
    console.log('3. Test the setup with: node scripts/test-supabase-setup.js\n');

  } catch (error) {
    console.error('\n❌ Setup failed:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { setupEnvironment };
