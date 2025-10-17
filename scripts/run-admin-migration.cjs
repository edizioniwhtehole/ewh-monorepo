#!/usr/bin/env node

/**
 * Esegue migration admin (roadmap + checklist) su Supabase PROD
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env.production') });

async function runMigration() {
  console.log('🚀 Starting admin migration on PROD...\n');

  // Supabase client con service key (admin permissions)
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
  );

  // Leggi migration SQL
  const migrationPath = path.join(__dirname, '..', 'migrations', '100_admin_roadmap_checklist.sql');
  const sql = fs.readFileSync(migrationPath, 'utf8');

  console.log('📄 Migration file:', migrationPath);
  console.log('📊 SQL size:', sql.length, 'bytes\n');

  try {
    // Esegui via RPC (Supabase SQL Editor simulation)
    console.log('⏳ Executing migration...');

    // Split in statements (per evitare timeout)
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    console.log(`📝 Total statements: ${statements.length}\n`);

    let executed = 0;
    for (const statement of statements) {
      // Skip comments and empty
      if (statement.startsWith('--') || statement.length < 10) continue;

      try {
        await supabase.rpc('exec_sql', { sql_query: statement + ';' });
        executed++;

        if (executed % 10 === 0) {
          console.log(`   ✓ Executed ${executed}/${statements.length} statements...`);
        }
      } catch (err) {
        // Ignora errori "already exists" (re-run migration)
        if (err.message?.includes('already exists')) {
          // OK, skip
        } else {
          console.error(`   ❌ Error on statement:`, statement.substring(0, 100));
          throw err;
        }
      }
    }

    console.log(`\n✅ Migration completed! ${executed} statements executed.\n`);

    // Verifica
    console.log('🔍 Verifying migration...\n');

    const { data: phases, error: err1 } = await supabase
      .from('roadmap_phases')
      .select('*')
      .order('phase_number');

    if (err1) {
      console.error('❌ Error fetching roadmap_phases:', err1.message);
    } else {
      console.log('📋 Roadmap Phases:');
      phases.forEach(p => {
        console.log(`   ${p.phase_number}. ${p.name} (${p.status})`);
      });
    }

    const { data: apps, error: err2 } = await supabase
      .from('apps_development')
      .select('app_code, app_name, status, progress_percent')
      .order('priority', { ascending: false });

    if (err2) {
      console.error('\n❌ Error fetching apps_development:', err2.message);
    } else {
      console.log('\n🎯 Apps Development:');
      apps.forEach(a => {
        console.log(`   ${a.app_code.padEnd(12)} ${a.app_name.padEnd(30)} ${a.status.padEnd(12)} ${a.progress_percent}%`);
      });
    }

    const { data: tasks, error: err3 } = await supabase
      .from('tasks_checklist')
      .select('title, status, priority')
      .limit(5);

    if (err3) {
      console.error('\n❌ Error fetching tasks:', err3.message);
    } else {
      console.log('\n✅ Sample Tasks:');
      tasks.forEach(t => {
        console.log(`   [${t.priority}] ${t.title} (${t.status})`);
      });
    }

    console.log('\n🎉 All done! Admin schema is ready.\n');

  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    process.exit(1);
  }
}

runMigration();
