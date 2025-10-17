#!/usr/bin/env node

/**
 * Final Supabase Connection Test
 * Uses public views and RPC functions
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

function loadEnv(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const env = {};
  content.split('\n').forEach(line => {
    line = line.trim();
    if (!line || line.startsWith('#')) return;
    const [key, ...values] = line.split('=');
    if (key && values.length) {
      env[key.trim()] = values.join('=').trim();
    }
  });
  return env;
}

async function testEnv(envName, envFile) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`🧪 Testing ${envName.toUpperCase()}`);
  console.log('='.repeat(60));

  const env = loadEnv(envFile);

  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_KEY) {
    console.log('❌ Missing configuration');
    return false;
  }

  console.log(`📡 URL: ${env.SUPABASE_URL}`);

  const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_KEY);

  try {
    // Test 1: Fetch tenants via public view
    console.log('\n1️⃣ Fetching tenants...');
    const { data: tenants, error: tenantsError } = await supabase
      .from('tenants')
      .select('slug, name, tier');

    if (tenantsError) {
      console.log('❌ Error:', tenantsError.message);
      return false;
    }

    console.log(`✅ Found ${tenants.length} tenant(s):`);
    tenants.forEach(t => console.log(`   - ${t.slug} (${t.name}) [${t.tier}]`));

    // Test 2: Fetch apps
    console.log('\n2️⃣ Fetching apps...');
    const { data: apps, error: appsError } = await supabase
      .from('apps_registry')
      .select('code, name');

    if (appsError) {
      console.log('❌ Error:', appsError.message);
      return false;
    }

    console.log(`✅ Found ${apps.length} app(s):`);
    apps.forEach(a => console.log(`   - ${a.code}: ${a.name}`));

    // Test 3: Fetch tenant data via RPC
    if (tenants.length > 0) {
      const firstTenant = tenants[0].slug;
      console.log(`\n3️⃣ Fetching data from tenant '${firstTenant}'...`);

      const { data: projects, error: projectsError } = await supabase
        .rpc('get_tenant_projects', { tenant_slug: firstTenant });

      if (projectsError) {
        console.log(`   ⚠️  Projects: ${projectsError.message}`);
      } else if (projects && projects.length > 0) {
        console.log(`✅ Found ${projects.length} project(s):`);
        projects.slice(0, 3).forEach(p => console.log(`   - ${p.name} [${p.status}]`));
      } else {
        console.log(`   ℹ️  No projects yet (empty tenant)`);
      }

      const { data: customers, error: customersError } = await supabase
        .rpc('get_tenant_customers', { tenant_slug: firstTenant });

      if (!customersError && customers && customers.length > 0) {
        console.log(`✅ Found ${customers.length} customer(s):`);
        customers.slice(0, 3).forEach(c => console.log(`   - ${c.company_name}`));
      }
    }

    console.log(`\n✅ ${envName.toUpperCase()} is working perfectly!\n`);
    return true;

  } catch (error) {
    console.log('\n❌ Test failed:', error.message);
    console.log('Stack:', error.stack);
    return false;
  }
}

async function main() {
  console.log('\n🏗️  EWH PLATFORM - SUPABASE CONNECTION TEST\n');

  const results = {
    dev: await testEnv('dev', '.env.development'),
    staging: await testEnv('staging', '.env.staging'),
    prod: await testEnv('prod', '.env.production')
  };

  console.log('='.repeat(60));
  console.log('📊 SUMMARY');
  console.log('='.repeat(60));
  console.log(`DEV:     ${results.dev ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`STAGING: ${results.staging ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`PROD:    ${results.prod ? '✅ PASS' : '❌ FAIL'}`);
  console.log('='.repeat(60));

  if (results.dev && results.staging && results.prod) {
    console.log('\n🎉 ALL ENVIRONMENTS READY! START DEVELOPING!\n');
    process.exit(0);
  } else {
    console.log('\n⚠️  Some environments need attention\n');
    process.exit(1);
  }
}

main();
