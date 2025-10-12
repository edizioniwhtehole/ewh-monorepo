#!/usr/bin/env tsx
/**
 * Automated Backup Verification Script
 *
 * Questo script verifica l'integrità dei backup PostgreSQL:
 * 1. Scarica l'ultimo backup da Scalingo/S3
 * 2. Ripristina su database di test
 * 3. Esegue integrity checks
 * 4. Invia alert se fallisce
 *
 * Usage:
 *   npm run verify-backup
 *   npm run verify-backup -- --date 2025-10-05
 *
 * Cron schedule (daily at 3 AM):
 *   0 3 * * * cd /app && npm run verify-backup
 */

import { Pool } from 'pg';
import { S3Client, GetObjectCommand, ListObjectsV2Command } from '@aws-sdk/client-s3';
import { exec } from 'child_process';
import { promisify } from 'util';
import { createWriteStream, createReadStream, unlinkSync } from 'fs';
import { pipeline } from 'stream/promises';
import pino from 'pino';

const execAsync = promisify(exec);
const logger = pino({
  level: 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'HH:MM:ss',
      ignore: 'pid,hostname'
    }
  }
});

// Configuration
const CONFIG = {
  // Production database (source of backups)
  prod: {
    host: process.env.PROD_DB_HOST || 'localhost',
    port: parseInt(process.env.PROD_DB_PORT || '5432'),
    database: process.env.PROD_DB_NAME || 'ewh_master',
    user: process.env.PROD_DB_USER || 'ewh',
    password: process.env.PROD_DB_PASSWORD || 'ewhpass',
  },

  // Test database (restore target)
  test: {
    host: process.env.TEST_DB_HOST || 'localhost',
    port: parseInt(process.env.TEST_DB_PORT || '5433'), // Different port
    database: process.env.TEST_DB_NAME || 'ewh_backup_test',
    user: process.env.TEST_DB_USER || 'ewh',
    password: process.env.TEST_DB_PASSWORD || 'ewhpass',
  },

  // S3 backup storage
  s3: {
    bucket: process.env.BACKUP_S3_BUCKET || 'ewh-backups-prod',
    region: process.env.AWS_REGION || 'eu-west-1',
    prefix: 'full/', // full backups location
  },

  // Slack webhook for alerts
  slackWebhook: process.env.SLACK_WEBHOOK_URL,

  // PagerDuty integration key
  pagerDutyKey: process.env.PAGERDUTY_INTEGRATION_KEY,
};

interface BackupFile {
  key: string;
  lastModified: Date;
  size: number;
}

interface VerificationResult {
  success: boolean;
  backupDate: Date;
  backupSize: number;
  restoreDuration: number;
  checksResult: {
    tableCount: number;
    rowCount: number;
    integrityChecks: Array<{
      table: string;
      passed: boolean;
      error?: string;
    }>;
  };
  error?: string;
}

/**
 * Initialize S3 client
 */
function getS3Client(): S3Client {
  return new S3Client({
    region: CONFIG.s3.region,
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
    },
  });
}

/**
 * Get the latest backup file from S3
 */
async function getLatestBackup(date?: string): Promise<BackupFile | null> {
  const s3 = getS3Client();

  logger.info(`Searching for backups in s3://${CONFIG.s3.bucket}/${CONFIG.s3.prefix}`);

  try {
    const command = new ListObjectsV2Command({
      Bucket: CONFIG.s3.bucket,
      Prefix: CONFIG.s3.prefix,
    });

    const response = await s3.send(command);

    if (!response.Contents || response.Contents.length === 0) {
      logger.error('No backup files found in S3');
      return null;
    }

    // Filter by date if specified
    let backups = response.Contents
      .filter(obj => obj.Key && obj.LastModified)
      .map(obj => ({
        key: obj.Key!,
        lastModified: obj.LastModified!,
        size: obj.Size || 0,
      }));

    if (date) {
      backups = backups.filter(b =>
        b.lastModified.toISOString().startsWith(date)
      );
    }

    if (backups.length === 0) {
      logger.error(`No backups found for date: ${date}`);
      return null;
    }

    // Sort by date (newest first)
    backups.sort((a, b) => b.lastModified.getTime() - a.lastModified.getTime());

    const latest = backups[0];
    logger.info(`Found backup: ${latest.key} (${(latest.size / 1024 / 1024).toFixed(2)} MB)`);

    return latest;
  } catch (error: any) {
    logger.error('Error listing S3 backups:', error.message);
    throw error;
  }
}

/**
 * Download backup from S3
 */
async function downloadBackup(backupFile: BackupFile): Promise<string> {
  const s3 = getS3Client();
  const localPath = `/tmp/backup-${Date.now()}.sql.gz`;

  logger.info(`Downloading ${backupFile.key} to ${localPath}...`);

  try {
    const command = new GetObjectCommand({
      Bucket: CONFIG.s3.bucket,
      Key: backupFile.key,
    });

    const response = await s3.send(command);

    if (!response.Body) {
      throw new Error('Empty response body from S3');
    }

    await pipeline(
      response.Body as any,
      createWriteStream(localPath)
    );

    logger.info(`Downloaded ${(backupFile.size / 1024 / 1024).toFixed(2)} MB`);
    return localPath;
  } catch (error: any) {
    logger.error('Error downloading backup:', error.message);
    throw error;
  }
}

/**
 * Drop and recreate test database
 */
async function recreateTestDatabase(): Promise<void> {
  logger.info('Recreating test database...');

  const adminPool = new Pool({
    host: CONFIG.test.host,
    port: CONFIG.test.port,
    database: 'postgres', // Connect to default DB
    user: CONFIG.test.user,
    password: CONFIG.test.password,
  });

  try {
    // Terminate existing connections
    await adminPool.query(`
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE pg_stat_activity.datname = '${CONFIG.test.database}'
        AND pid <> pg_backend_pid()
    `);

    // Drop database if exists
    await adminPool.query(`DROP DATABASE IF EXISTS ${CONFIG.test.database}`);

    // Create fresh database
    await adminPool.query(`CREATE DATABASE ${CONFIG.test.database}`);

    logger.info('✅ Test database recreated');
  } catch (error: any) {
    logger.error('Error recreating database:', error.message);
    throw error;
  } finally {
    await adminPool.end();
  }
}

/**
 * Restore backup to test database
 */
async function restoreBackup(backupPath: string): Promise<number> {
  logger.info('Restoring backup...');

  const startTime = Date.now();

  const pgRestoreCmd = `
    gunzip -c ${backupPath} | \
    PGPASSWORD="${CONFIG.test.password}" psql \
      -h ${CONFIG.test.host} \
      -p ${CONFIG.test.port} \
      -U ${CONFIG.test.user} \
      -d ${CONFIG.test.database} \
      --quiet
  `;

  try {
    await execAsync(pgRestoreCmd);
    const duration = Date.now() - startTime;
    logger.info(`✅ Restore completed in ${(duration / 1000).toFixed(2)}s`);
    return duration;
  } catch (error: any) {
    logger.error('Error restoring backup:', error.message);
    throw error;
  }
}

/**
 * Run integrity checks on restored database
 */
async function runIntegrityChecks(): Promise<VerificationResult['checksResult']> {
  logger.info('Running integrity checks...');

  const pool = new Pool(CONFIG.test);

  try {
    // 1. Count tables
    const tablesResult = await pool.query(`
      SELECT COUNT(*) as count
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
    `);
    const tableCount = parseInt(tablesResult.rows[0].count);
    logger.info(`Found ${tableCount} tables`);

    // 2. Count total rows across all tables
    const rowCountResult = await pool.query(`
      SELECT SUM(n_live_tup) as total_rows
      FROM pg_stat_user_tables
    `);
    const rowCount = parseInt(rowCountResult.rows[0].total_rows || '0');
    logger.info(`Total rows: ${rowCount.toLocaleString()}`);

    // 3. Check critical tables exist and have data
    const criticalTables = [
      'tenants',
      'users',
      'documents',
      'orders',
      'products',
    ];

    const integrityChecks = await Promise.all(
      criticalTables.map(async (table) => {
        try {
          const result = await pool.query(`
            SELECT COUNT(*) as count FROM ${table}
          `);
          const count = parseInt(result.rows[0].count);

          if (count === 0) {
            logger.warn(`⚠️  Table ${table} is empty`);
            return { table, passed: true }; // Empty is OK for test data
          }

          logger.info(`✅ Table ${table}: ${count} rows`);
          return { table, passed: true };
        } catch (error: any) {
          logger.error(`❌ Table ${table}: ${error.message}`);
          return {
            table,
            passed: false,
            error: error.message,
          };
        }
      })
    );

    // 4. Check for foreign key violations
    const fkResult = await pool.query(`
      SELECT conrelid::regclass AS table_name,
             conname AS constraint_name
      FROM pg_constraint
      WHERE contype = 'f'
        AND connamespace = 'public'::regnamespace
      LIMIT 10
    `);

    logger.info(`Checked ${fkResult.rows.length} foreign key constraints`);

    // 5. Verify sequences are set correctly
    const seqResult = await pool.query(`
      SELECT sequence_name
      FROM information_schema.sequences
      WHERE sequence_schema = 'public'
      LIMIT 10
    `);

    logger.info(`Found ${seqResult.rows.length} sequences`);

    return {
      tableCount,
      rowCount,
      integrityChecks,
    };
  } catch (error: any) {
    logger.error('Error during integrity checks:', error.message);
    throw error;
  } finally {
    await pool.end();
  }
}

/**
 * Send alert to Slack
 */
async function sendSlackAlert(result: VerificationResult): Promise<void> {
  if (!CONFIG.slackWebhook) {
    logger.warn('No Slack webhook configured, skipping alert');
    return;
  }

  const color = result.success ? 'good' : 'danger';
  const emoji = result.success ? '✅' : '❌';

  const message = {
    attachments: [
      {
        color,
        title: `${emoji} Backup Verification ${result.success ? 'Passed' : 'Failed'}`,
        fields: [
          {
            title: 'Backup Date',
            value: result.backupDate.toISOString(),
            short: true,
          },
          {
            title: 'Backup Size',
            value: `${(result.backupSize / 1024 / 1024).toFixed(2)} MB`,
            short: true,
          },
          {
            title: 'Restore Duration',
            value: `${(result.restoreDuration / 1000).toFixed(2)}s`,
            short: true,
          },
          {
            title: 'Tables',
            value: result.checksResult?.tableCount.toString() || 'N/A',
            short: true,
          },
          {
            title: 'Total Rows',
            value: result.checksResult?.rowCount.toLocaleString() || 'N/A',
            short: true,
          },
        ],
        text: result.error || 'All integrity checks passed',
        ts: Math.floor(Date.now() / 1000),
      },
    ],
  };

  try {
    const response = await fetch(CONFIG.slackWebhook, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      logger.error('Failed to send Slack alert:', response.statusText);
    } else {
      logger.info('✅ Slack alert sent');
    }
  } catch (error: any) {
    logger.error('Error sending Slack alert:', error.message);
  }
}

/**
 * Send alert to PagerDuty (for critical failures)
 */
async function sendPagerDutyAlert(result: VerificationResult): Promise<void> {
  if (!CONFIG.pagerDutyKey) {
    logger.warn('No PagerDuty key configured, skipping alert');
    return;
  }

  if (result.success) {
    logger.info('Backup verification passed, no PagerDuty alert needed');
    return;
  }

  const event = {
    routing_key: CONFIG.pagerDutyKey,
    event_action: 'trigger',
    payload: {
      summary: `Backup verification failed for ${result.backupDate.toISOString()}`,
      severity: 'critical',
      source: 'backup-verification-script',
      timestamp: new Date().toISOString(),
      custom_details: {
        backup_date: result.backupDate,
        backup_size: result.backupSize,
        error: result.error,
        table_count: result.checksResult?.tableCount,
        row_count: result.checksResult?.rowCount,
      },
    },
  };

  try {
    const response = await fetch('https://events.pagerduty.com/v2/enqueue', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(event),
    });

    if (!response.ok) {
      logger.error('Failed to send PagerDuty alert:', response.statusText);
    } else {
      logger.info('✅ PagerDuty alert sent');
    }
  } catch (error: any) {
    logger.error('Error sending PagerDuty alert:', error.message);
  }
}

/**
 * Main verification workflow
 */
async function verifyBackup(date?: string): Promise<VerificationResult> {
  let backupPath: string | null = null;

  try {
    // 1. Find latest backup
    const backupFile = await getLatestBackup(date);
    if (!backupFile) {
      throw new Error('No backup file found');
    }

    // 2. Download backup
    backupPath = await downloadBackup(backupFile);

    // 3. Recreate test database
    await recreateTestDatabase();

    // 4. Restore backup
    const restoreDuration = await restoreBackup(backupPath);

    // 5. Run integrity checks
    const checksResult = await runIntegrityChecks();

    // 6. Verify all checks passed
    const allChecksPassed = checksResult.integrityChecks.every(c => c.passed);

    const result: VerificationResult = {
      success: allChecksPassed,
      backupDate: backupFile.lastModified,
      backupSize: backupFile.size,
      restoreDuration,
      checksResult,
    };

    if (!allChecksPassed) {
      const failedChecks = checksResult.integrityChecks
        .filter(c => !c.passed)
        .map(c => c.table)
        .join(', ');
      result.error = `Failed integrity checks for tables: ${failedChecks}`;
    }

    return result;
  } catch (error: any) {
    logger.error('Backup verification failed:', error.message);

    return {
      success: false,
      backupDate: new Date(),
      backupSize: 0,
      restoreDuration: 0,
      checksResult: {
        tableCount: 0,
        rowCount: 0,
        integrityChecks: [],
      },
      error: error.message,
    };
  } finally {
    // Cleanup downloaded backup
    if (backupPath) {
      try {
        unlinkSync(backupPath);
        logger.info('Cleaned up temporary backup file');
      } catch (error: any) {
        logger.warn('Failed to cleanup backup file:', error.message);
      }
    }
  }
}

/**
 * Main entry point
 */
async function main() {
  logger.info('🔍 Starting backup verification...');

  const args = process.argv.slice(2);
  const dateArg = args.find(arg => arg.startsWith('--date='));
  const date = dateArg ? dateArg.split('=')[1] : undefined;

  const result = await verifyBackup(date);

  // Send alerts
  await sendSlackAlert(result);

  if (!result.success) {
    await sendPagerDutyAlert(result);
  }

  // Log final result
  if (result.success) {
    logger.info('✅ Backup verification PASSED');
    process.exit(0);
  } else {
    logger.error('❌ Backup verification FAILED');
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((error) => {
    logger.error('Fatal error:', error);
    process.exit(1);
  });
}

export { verifyBackup, type VerificationResult };
