# Backup Verification System

## Overview

Sistema automatizzato per verificare l'integrità dei backup PostgreSQL. Scarica l'ultimo backup, lo ripristina su un database di test, esegue controlli di integrità, e invia alert in caso di problemi.

## Features

✅ **Automated Download** - Scarica l'ultimo backup da S3
✅ **Full Restore** - Ripristina su database di test isolato
✅ **Integrity Checks** - Verifica tabelle, righe, foreign keys
✅ **Slack Alerts** - Notifiche real-time
✅ **PagerDuty Integration** - Alert critici per on-call
✅ **Automated Cleanup** - Rimuove file temporanei
✅ **Cron-Ready** - Schedulabile con cron/systemd

## Prerequisites

### 1. Test Database

Crea un database PostgreSQL separato per i test:

```bash
# Docker (recommended)
docker run -d \
  --name postgres-backup-test \
  -e POSTGRES_USER=ewh \
  -e POSTGRES_PASSWORD=ewhpass \
  -e POSTGRES_DB=ewh_backup_test \
  -p 5433:5432 \
  postgres:15

# O su PostgreSQL esistente
psql -U postgres -c "CREATE DATABASE ewh_backup_test"
```

### 2. Environment Variables

Crea `.env` file:

```bash
# Production database (source)
PROD_DB_HOST=db.scalingo.eu
PROD_DB_PORT=5432
PROD_DB_NAME=ewh_master
PROD_DB_USER=ewh_prod
PROD_DB_PASSWORD=xxx

# Test database (restore target)
TEST_DB_HOST=localhost
TEST_DB_PORT=5433
TEST_DB_NAME=ewh_backup_test
TEST_DB_USER=ewh
TEST_DB_PASSWORD=ewhpass

# S3 backup storage
BACKUP_S3_BUCKET=ewh-backups-prod
AWS_REGION=eu-west-1
AWS_ACCESS_KEY_ID=AKIAXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxx

# Alerts
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx
PAGERDUTY_INTEGRATION_KEY=xxx  # Optional, only for critical failures
```

### 3. Install Dependencies

```bash
npm install @aws-sdk/client-s3 pino pino-pretty
```

## Usage

### Manual Run

```bash
# Verify latest backup
npm run verify-backup

# Verify specific date
npm run verify-backup -- --date=2025-10-05

# With environment variables
PROD_DB_HOST=... npm run verify-backup
```

### Automated Schedule

#### Option A: Cron (Linux/macOS)

```bash
# Edit crontab
crontab -e

# Add daily verification at 3 AM
0 3 * * * cd /app/ewh && npm run verify-backup >> /var/log/backup-verify.log 2>&1
```

#### Option B: Systemd Timer (Linux)

```ini
# /etc/systemd/system/backup-verify.service
[Unit]
Description=Verify PostgreSQL Backup
After=network.target

[Service]
Type=oneshot
User=app
WorkingDirectory=/app/ewh
ExecStart=/usr/bin/npm run verify-backup
StandardOutput=journal
StandardError=journal
```

```ini
# /etc/systemd/system/backup-verify.timer
[Unit]
Description=Daily backup verification at 3 AM

[Timer]
OnCalendar=daily
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
# Enable and start
sudo systemctl enable backup-verify.timer
sudo systemctl start backup-verify.timer

# Check status
sudo systemctl status backup-verify.timer
sudo systemctl list-timers
```

#### Option C: GitHub Actions (CI/CD)

```yaml
# .github/workflows/backup-verify.yml
name: Daily Backup Verification

on:
  schedule:
    - cron: '0 3 * * *'  # 3 AM daily
  workflow_dispatch:  # Manual trigger

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm install

      - name: Verify backup
        env:
          PROD_DB_HOST: ${{ secrets.PROD_DB_HOST }}
          PROD_DB_PASSWORD: ${{ secrets.PROD_DB_PASSWORD }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        run: npm run verify-backup
```

## How It Works

### 1. Download Backup (S3)

```
s3://ewh-backups-prod/full/
  ├── backup-2025-10-01.sql.gz
  ├── backup-2025-10-02.sql.gz
  ├── backup-2025-10-03.sql.gz  ← Latest
  └── ...
```

Script scarica l'ultimo file `.sql.gz`

### 2. Restore Database

```sql
-- Drop test database
DROP DATABASE IF EXISTS ewh_backup_test;

-- Create fresh database
CREATE DATABASE ewh_backup_test;

-- Restore backup
gunzip -c backup.sql.gz | psql ewh_backup_test
```

### 3. Integrity Checks

```typescript
// A. Count tables
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public'

// B. Count rows
SELECT SUM(n_live_tup) FROM pg_stat_user_tables

// C. Verify critical tables
SELECT COUNT(*) FROM tenants
SELECT COUNT(*) FROM users
SELECT COUNT(*) FROM documents

// D. Check foreign keys
SELECT * FROM pg_constraint WHERE contype = 'f'

// E. Verify sequences
SELECT * FROM information_schema.sequences
```

### 4. Send Alerts

**Success (Slack):**
```
✅ Backup Verification Passed
Backup Date: 2025-10-06T02:00:00Z
Size: 2.5 GB
Restore Time: 45s
Tables: 87
Rows: 1,234,567
```

**Failure (Slack + PagerDuty):**
```
❌ Backup Verification Failed
Error: Table 'orders' missing
Backup Date: 2025-10-06T02:00:00Z

PagerDuty incident created: INC-12345
```

## Output Example

```
[03:00:01] INFO: 🔍 Starting backup verification...
[03:00:01] INFO: Searching for backups in s3://ewh-backups-prod/full/
[03:00:02] INFO: Found backup: full/backup-2025-10-06.sql.gz (2,456 MB)
[03:00:02] INFO: Downloading to /tmp/backup-1728183602.sql.gz...
[03:00:45] INFO: Downloaded 2,456 MB
[03:00:45] INFO: Recreating test database...
[03:00:46] INFO: ✅ Test database recreated
[03:00:46] INFO: Restoring backup...
[03:01:32] INFO: ✅ Restore completed in 46.2s
[03:01:32] INFO: Running integrity checks...
[03:01:33] INFO: Found 87 tables
[03:01:33] INFO: Total rows: 1,234,567
[03:01:33] INFO: ✅ Table tenants: 12 rows
[03:01:33] INFO: ✅ Table users: 145 rows
[03:01:34] INFO: ✅ Table documents: 8,432 rows
[03:01:34] INFO: ✅ Table orders: 3,245 rows
[03:01:34] INFO: ✅ Table products: 876 rows
[03:01:34] INFO: Checked 45 foreign key constraints
[03:01:34] INFO: Found 23 sequences
[03:01:35] INFO: ✅ Slack alert sent
[03:01:35] INFO: Backup verification passed, no PagerDuty alert needed
[03:01:35] INFO: Cleaned up temporary backup file
[03:01:35] INFO: ✅ Backup verification PASSED
```

## Monitoring Dashboard

Crea un dashboard Grafana/Datadog per tracciare:

```sql
CREATE TABLE backup_verification_history (
  id SERIAL PRIMARY KEY,
  verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  backup_date TIMESTAMPTZ NOT NULL,
  success BOOLEAN NOT NULL,
  backup_size_mb NUMERIC,
  restore_duration_seconds INTEGER,
  table_count INTEGER,
  row_count BIGINT,
  error_message TEXT
);
```

Query per dashboard:
```sql
-- Success rate (last 30 days)
SELECT
  DATE(verified_at) as date,
  COUNT(*) as total_checks,
  SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful,
  AVG(restore_duration_seconds) as avg_restore_time
FROM backup_verification_history
WHERE verified_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(verified_at)
ORDER BY date DESC;

-- Last verification status
SELECT * FROM backup_verification_history
ORDER BY verified_at DESC
LIMIT 1;
```

## Troubleshooting

### Error: "No backup files found in S3"

Verifica credentials AWS e bucket name:
```bash
aws s3 ls s3://ewh-backups-prod/full/
```

### Error: "Connection refused" (database)

Verifica che il test database sia running:
```bash
docker ps | grep postgres-backup-test
psql -h localhost -p 5433 -U ewh -d ewh_backup_test
```

### Error: "Out of disk space"

Backup compressi sono grandi. Assicurati di avere spazio:
```bash
df -h /tmp
# Deve avere almeno 2x la dimensione del backup
```

### Restore Too Slow

Usa database più potente per test o disabilita alcuni indici durante restore:
```sql
-- Prima del restore
ALTER TABLE large_table SET (autovacuum_enabled = false);

-- Dopo il restore
ALTER TABLE large_table SET (autovacuum_enabled = true);
VACUUM ANALYZE large_table;
```

## Security Considerations

### 1. Credentials

**❌ NON fare:**
```bash
# Hardcoded in script
const password = 'mypassword123';
```

**✅ Fare:**
```bash
# Environment variables
const password = process.env.PROD_DB_PASSWORD;

# O AWS Secrets Manager
const secret = await secretsManager.getSecretValue({
  SecretId: 'ewh/prod/db'
});
```

### 2. Network Access

Test database deve essere isolato:
```yaml
# Docker network isolation
networks:
  backup_test:
    driver: bridge
    internal: true  # No internet access
```

### 3. Data Sanitization

Se backup contiene dati sensibili, sanitizza prima dei test:
```sql
-- Anonimizza dati personali
UPDATE users SET
  email = CONCAT('user', id, '@example.com'),
  first_name = 'Test',
  last_name = CONCAT('User', id);

-- Rimuovi dati finanziari
DELETE FROM payment_methods;
DELETE FROM credit_cards;
```

## Cost Optimization

### S3 Storage Classes

```typescript
// Lifecycle policy per ridurre costi
{
  "Rules": [{
    "Id": "archive-old-backups",
    "Status": "Enabled",
    "Transitions": [
      {
        "Days": 30,
        "StorageClass": "STANDARD_IA"  // Infrequent Access
      },
      {
        "Days": 90,
        "StorageClass": "GLACIER"  // Long-term archive
      }
    ],
    "Expiration": {
      "Days": 2555  // 7 years (compliance)
    }
  }]
}
```

### Incremental Verification

Non verificare tutti i giorni, alterna:
```bash
# Full verification: Lunedì
0 3 * * 1 npm run verify-backup

# Quick check: Martedì-Venerdì (solo integrity, no restore)
0 3 * * 2-5 npm run verify-backup -- --quick

# Monthly deep check: Primo del mese
0 3 1 * * npm run verify-backup -- --deep
```

## Next Steps

1. ✅ Script creato
2. 🔲 Testare su backup reale
3. 🔲 Configurare Slack webhook
4. 🔲 Setup cron job
5. 🔲 Creare dashboard monitoring
6. 🔲 Documentare recovery procedures
7. 🔲 Training team su disaster recovery

## References

- [PostgreSQL Backup Best Practices](https://www.postgresql.org/docs/current/backup.html)
- [AWS S3 Lifecycle Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [3-2-1 Backup Rule](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/)

---

**Created:** 2025-10-06
**Version:** 1.0.0
**Owner:** Platform Team
