#!/usr/bin/env node

/**
 * Simple Supabase Connection Test
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Parse .env file manually
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

  const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_KEY, {
    db: { schema: 'core' }
  });

  try {
    // Test 1: Raw SQL query
    console.log('\n1️⃣ Fetching tenants...');

    const { data, error } = await supabase
      .schema('core')
      .from('tenants')
      .select('slug, name, tier');

    if (error) {
      console.log('❌ Error:', error.message);
      return false;
    }

    console.log(`✅ Found ${data.length} tenant(s):`);
    data.forEach(t => console.log(`   - ${t.slug} (${t.name}) [${t.tier}]`));

    // Test 2: Check apps
    console.log('\n2️⃣ Fetching apps...');
    const { data: apps } = await supabase
      .schema('core')
      .from('apps_registry')
      .select('code, name');

    console.log(`✅ Found ${apps.length} app(s):`);
    apps.forEach(a => console.log(`   - ${a.code}: ${a.name}`));

    console.log(`\n✅ ${envName.toUpperCase()} is working!\n`);
    return true;

  } catch (error) {
    console.log('\n❌ Test failed:', error.message);
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
    console.log('\n🎉 All environments ready! Start developing!\n');
    process.exit(0);
  } else {
    console.log('\n⚠️  Some environments need attention\n');
    process.exit(1);
  }
}

main();
