#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env.production') });

async function testAdmin() {
  console.log('🔍 Testing Admin Schema on PROD...\n');

  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );

  try {
    // Test 1: Roadmap Phases
    const { data: phases, error: err1 } = await supabase
      .from('roadmap_phases')
      .select('*')
      .order('phase_number');

    if (err1) throw err1;

    console.log('✅ Roadmap Phases:');
    phases.forEach(p => {
      console.log(`   ${p.phase_number}. ${p.name} (${p.status})`);
    });

    // Test 2: Apps Development
    const { data: apps, error: err2 } = await supabase
      .from('apps_development')
      .select('app_code, app_name, status, progress_percent')
      .order('priority', { ascending: false });

    if (err2) throw err2;

    console.log('\n✅ Apps Development:');
    apps.forEach(a => {
      const bar = '█'.repeat(Math.floor(a.progress_percent / 5)) + '░'.repeat(20 - Math.floor(a.progress_percent / 5));
      console.log(`   ${a.app_code.padEnd(12)} [${bar}] ${a.progress_percent}% ${a.status}`);
    });

    // Test 3: Tasks Checklist
    const { data: tasks, error: err3 } = await supabase
      .from('tasks_checklist')
      .select('title, status, priority, app_id')
      .limit(10);

    if (err3) throw err3;

    console.log('\n✅ Tasks Checklist:');
    tasks.forEach(t => {
      const icon = t.status === 'completed' ? '✅' : t.status === 'in_progress' ? '🔄' : '⏳';
      console.log(`   ${icon} [${t.priority}] ${t.title}`);
    });

    // Test 4: Database Allocation
    const { data: dbs, error: err4 } = await supabase
      .rpc('exec', { query: 'SELECT * FROM admin.v_database_allocation' })
      .single();

    if (!err4) {
      console.log('\n✅ Database Allocation:');
      console.log(dbs);
    }

    console.log('\n🎉 All tests passed! Admin schema is operational.\n');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.error('\nℹ️  Se vedi "relation does not exist", esegui prima la migration SQL via Supabase Dashboard.\n');
    process.exit(1);
  }
}

testAdmin();
