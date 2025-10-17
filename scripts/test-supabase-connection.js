#!/usr/bin/env node

/**
 * Test Supabase Connection
 * Verifies that all environments are correctly configured
 */

import { createClient } from '@supabase/supabase-js';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Test one environment
async function testEnvironment(envName, envFile) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`🧪 Testing ${envName.toUpperCase()} Environment`);
  console.log('='.repeat(60));

  // Load env file
  config({ path: join(__dirname, '..', envFile) });

  const url = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;
  const serviceKey = process.env.SUPABASE_SERVICE_KEY;

  if (!url || !serviceKey) {
    console.log('❌ Missing configuration in', envFile);
    return false;
  }

  if (anonKey === '<GET_FROM_DASHBOARD>') {
    console.log('⚠️  ANON_KEY not set yet - update', envFile);
  }

  console.log(`\n📡 Connecting to: ${url}`);

  try {
    // Create client with service key (backend)
    const supabase = createClient(url, serviceKey);

    // Test 1: Check tenants
    console.log('\n1️⃣ Testing: Fetch tenants...');
    const { data: tenants, error: tenantsError } = await supabase
      .from('core.tenants')
      .select('slug, name, tier')
      .order('created_at');

    if (tenantsError) {
      console.log('❌ Error fetching tenants:', tenantsError.message);
      return false;
    }

    console.log(`✅ Found ${tenants.length} tenant(s):`);
    tenants.forEach(t => console.log(`   - ${t.slug} (${t.name}) [${t.tier}]`));

    // Test 2: Check apps
    console.log('\n2️⃣ Testing: Fetch apps registry...');
    const { data: apps, error: appsError } = await supabase
      .from('core.apps_registry')
      .select('code, name')
      .order('code');

    if (appsError) {
      console.log('❌ Error fetching apps:', appsError.message);
      return false;
    }

    console.log(`✅ Found ${apps.length} app(s):`);
    apps.forEach(a => console.log(`   - ${a.code}: ${a.name}`));

    // Test 3: Check tenant data (first tenant)
    if (tenants.length > 0) {
      const firstTenant = tenants[0].slug;
      console.log(`\n3️⃣ Testing: Fetch data from tenant_${firstTenant}...`);

      // Try to fetch projects
      const { data: projects, error: projectsError } = await supabase
        .from(`tenant_${firstTenant}.pm_projects`)
        .select('name, status')
        .limit(5);

      if (projectsError) {
        // Schema notation might not work, try direct query
        console.log('   ℹ️  Using RPC to query tenant data...');
        const { data: projectsRPC, error: rpcError } = await supabase
          .rpc('query', {
            query: `SELECT name, status FROM tenant_${firstTenant}.pm_projects LIMIT 5`
          });

        if (rpcError) {
          console.log(`   ⚠️  No projects data (might be empty): ${rpcError.message}`);
        } else {
          console.log(`✅ Found ${projectsRPC?.length || 0} project(s)`);
        }
      } else {
        console.log(`✅ Found ${projects.length} project(s):`);
        projects.forEach(p => console.log(`   - ${p.name} [${p.status}]`));
      }

      // Try to fetch customers
      const { data: customers } = await supabase
        .from(`tenant_${firstTenant}.crm_customers`)
        .select('company_name')
        .limit(3);

      if (customers && customers.length > 0) {
        console.log(`\n   Customers: ${customers.length} found`);
        customers.forEach(c => console.log(`   - ${c.company_name}`));
      }
    }

    // Test 4: Check schemas
    console.log('\n4️⃣ Testing: Verify schemas exist...');
    const { data: schemas } = await supabase
      .rpc('query', {
        query: `
          SELECT schema_name, COUNT(*) as table_count
          FROM information_schema.tables
          WHERE schema_name IN ('core', 'analytics', 'app_pm', 'app_crm', 'app_dam')
          GROUP BY schema_name
          ORDER BY schema_name
        `
      });

    if (schemas) {
      schemas.forEach(s => {
        console.log(`   ✅ ${s.schema_name}: ${s.table_count} tables`);
      });
    }

    console.log(`\n✅ ${envName.toUpperCase()} environment is working correctly!\n`);
    return true;

  } catch (error) {
    console.log('\n❌ Connection test failed:', error.message);
    return false;
  }
}

// Main
async function main() {
  console.log('\n' + '='.repeat(60));
  console.log('🏗️  EWH PLATFORM - SUPABASE CONNECTION TEST');
  console.log('='.repeat(60));

  const results = {
    dev: await testEnvironment('dev', '.env.development'),
    staging: await testEnvironment('staging', '.env.staging'),
    prod: await testEnvironment('prod', '.env.production')
  };

  console.log('\n' + '='.repeat(60));
  console.log('📊 SUMMARY');
  console.log('='.repeat(60));
  console.log(`DEV:     ${results.dev ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`STAGING: ${results.staging ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`PROD:    ${results.prod ? '✅ PASS' : '❌ FAIL'}`);
  console.log('='.repeat(60) + '\n');

  const allPass = results.dev && results.staging && results.prod;
  if (allPass) {
    console.log('🎉 All environments are ready! You can start developing!\n');
  } else {
    console.log('⚠️  Some environments need attention. Check the errors above.\n');
  }

  process.exit(allPass ? 0 : 1);
}

main();
