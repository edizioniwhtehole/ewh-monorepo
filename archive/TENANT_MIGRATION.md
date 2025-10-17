# Tenant Migration & Vertical Management

> **Gestione tenant lifecycle, migrazione tra isolation tiers, e provisioning verticali tramite Scalingo API**

**Versione:** 1.0.0
**Target:** Platform admins, DevOps, AI Agents
**Ultima revisione:** 2025-10-04

---

## 📋 Indice

- [Overview](#overview)
- [Isolation Tiers](#isolation-tiers)
- [Migration Scenarios](#migration-scenarios)
- [Scalingo API Integration](#scalingo-api-integration)
- [Admin Control Panel](#admin-control-panel)
- [Migration Workflows](#migration-workflows)
- [Rollback & Recovery](#rollback--recovery)
- [Monitoring & Alerts](#monitoring--alerts)

---

## Overview

EWH Platform supporta **multi-tier data isolation** per tenant con diversi requisiti di compliance, performance e billing:

```
┌─────────────────────────────────────────────┐
│  Tier 1: Schema Separation                 │
│  └─ Shared DB, dedicated schema            │
│     Cost: €0/month extra                   │
│     Use case: Standard tenants             │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Tier 2: Database Separation               │
│  └─ Dedicated DB per vertical              │
│     Cost: €30-50/month per vertical        │
│     Use case: Vertical-specific features   │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Tier 3: Tenant-Dedicated Infrastructure   │
│  └─ Dedicated DB + Storage per tenant      │
│     Cost: €100-500/month per tenant        │
│     Use case: Enterprise, HIPAA, SOC2      │
└─────────────────────────────────────────────┘
```

### Key Capabilities

- ✅ **Zero-downtime migrations** tra tiers
- ✅ **Automated provisioning** via Scalingo API
- ✅ **Visual control panel** per platform admins
- ✅ **Rollback automatico** in caso di errori
- ✅ **Audit logging** completo di tutte le operazioni
- ✅ **Cost estimation** prima di migrazione

---

## Isolation Tiers

### Tier 1: Schema Separation

**Architecture:**
```sql
-- Shared database, multiple schemas
CREATE SCHEMA core_dms;
CREATE SCHEMA realestate_dms;
CREATE SCHEMA medical_dms;

-- Tenant data in dedicated schema
CREATE TABLE realestate_dms.documents (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  -- ...
);

-- Switch context per tenant
SET search_path TO realestate_dms;
```

**Features:**
- ✅ Zero extra cost
- ✅ Rapido provisioning (<1 min)
- ✅ Sufficiente per GDPR base
- ❌ Shared compute resources
- ❌ No physical isolation

**Use cases:**
- Tenant standard senza requisiti compliance specifici
- Startup/small business
- Development/staging environments

### Tier 2: Database Separation

**Architecture:**
```yaml
# Scalingo addons
addons:
  - plan: postgresql:postgresql-starter-1024
    name: db-realestate
    cost: €30/month

  - plan: postgresql:postgresql-starter-1024
    name: db-medical
    cost: €30/month
```

**Connection Routing:**
```typescript
const verticalDbMap = {
  'realestate': process.env.DATABASE_URL_REALESTATE,
  'medical': process.env.DATABASE_URL_MEDICAL,
  'ecommerce': process.env.DATABASE_URL_ECOMMERCE,
}

function getDbUrl(tenant: Tenant): string {
  return verticalDbMap[tenant.vertical] || process.env.DATABASE_URL_CORE
}
```

**Features:**
- ✅ Physical database isolation
- ✅ Independent scaling per vertical
- ✅ Independent backup/restore
- ✅ Performance isolation
- ⚠️ Moderate cost (~€30/month per vertical)

**Use cases:**
- Vertical-specific features (Real Estate, Medical, E-commerce)
- Compliance tier 1 (GDPR, basic data residency)
- High-volume verticals che beneficiano di scaling dedicato

### Tier 3: Tenant-Dedicated Infrastructure

**Architecture:**
```yaml
# Enterprise tenant: Acme Medical
scalingo_apps:
  - name: ewh-tenant-acme-svc-dms
    plan: M (1GB RAM)
    addons:
      - plan: postgresql:postgresql-business-1024
        encryption: true
        backup_retention: 365
        cost: €150/month

      - plan: redis:redis-business-256
        cost: €30/month

storage:
  bucket: ewh-tenant-acme-medical
  encryption: AES-256
  region: eu-west-1
  cost: €20/month
```

**Features:**
- ✅ Complete isolation (compute + data + storage)
- ✅ HIPAA / SOC2 / ISO27001 ready
- ✅ Custom SLA & support tier
- ✅ White-label deployment capability
- ✅ Custom data residency
- ⚠️ High cost (€200-500/month per tenant)

**Use cases:**
- Healthcare tenants (HIPAA)
- Financial services (PCI-DSS)
- Enterprise contracts (SLA-based)
- Government clients (data sovereignty)

---

## Migration Scenarios

### Scenario 1: Core → Vertical (Tier 1 → Tier 2)

**Trigger:**
- Tenant activates vertical-specific features
- Business rule: "Real Estate features → migrate to realestate vertical"

**Example:**
```typescript
// User enables Real Estate module
await enableVerticalFeatures(tenantId, 'realestate')

// Auto-trigger migration
await migrateTenantToVertical({
  tenantId,
  sourceVertical: 'core',
  targetVertical: 'realestate',
  isolationTier: 'database'
})
```

**Process:**
1. ✅ Provision `db-realestate` addon (if not exists) via Scalingo API
2. ✅ Create schema in new database
3. ✅ Copy tenant data (core DB → realestate DB)
4. ✅ Verify data integrity (row counts, checksums)
5. ✅ Update tenant metadata: `vertical = 'realestate'`
6. ✅ Switch routing (zero-downtime)
7. ✅ Monitor for 24h, cleanup source if successful

**Downtime:** 0 seconds (read replica cutover)

### Scenario 2: Vertical → Dedicated (Tier 2 → Tier 3)

**Trigger:**
- Enterprise contract signed
- Compliance requirement (HIPAA)
- Manual admin action

**Process:**
1. ✅ Create dedicated Scalingo app: `ewh-tenant-{id}-svc-*`
2. ✅ Provision addons (PostgreSQL Business, Redis, etc)
3. ✅ Create S3 bucket: `ewh-tenant-{id}-{vertical}`
4. ✅ Deploy service instances with tenant-specific config
5. ✅ Migrate data (vertical DB → dedicated DB)
6. ✅ Migrate storage (vertical bucket → dedicated bucket)
7. ✅ Update DNS/routing
8. ✅ Switch traffic (blue-green deployment)
9. ✅ Monitor for 7 days, decommission source

**Downtime:** <5 minutes (DNS propagation)

### Scenario 3: Downgrade (Tier 3 → Tier 2 or Tier 1)

**Trigger:**
- Contract downgrade
- Cost optimization
- Compliance requirement removed

**Process:**
1. ⚠️ **Risk warning**: Manual admin approval required
2. ✅ Backup tenant data (full snapshot)
3. ✅ Copy data to target tier
4. ✅ Verify data integrity
5. ✅ Switch routing
6. ✅ Keep source online for 30 days (safety window)
7. ✅ Decommission dedicated infrastructure
8. ✅ Refund prorated billing

**Downtime:** 0 seconds (cutover with replica)

---

## Scalingo API Integration

### API Authentication

```typescript
// Scalingo API client
import { ScalingoClient } from '@scalingo/client'

const scalingo = new ScalingoClient({
  apiToken: process.env.SCALINGO_API_TOKEN, // Securely stored
  region: 'osc-fr1' // EU-WEST
})
```

### Key Operations

#### 1. Provision Database Addon

```typescript
async function provisionDatabaseAddon(
  vertical: string,
  plan: 'starter' | 'business' = 'starter'
): Promise<AddonInfo> {
  const appName = `ewh-prod-svc-${vertical}`

  const addon = await scalingo.addons.create(appName, {
    addon_provider: 'postgresql',
    plan: `postgresql:postgresql-${plan}-1024`,
    options: {
      version: '15',
      encryption: plan === 'business'
    }
  })

  // Wait for provisioning (async)
  await waitForAddonProvisioned(addon.id)

  // Get connection string
  const config = await scalingo.addons.getConfig(appName, addon.id)

  return {
    id: addon.id,
    databaseUrl: config.DATABASE_URL,
    status: 'provisioned'
  }
}
```

#### 2. Create Dedicated Tenant App

```typescript
async function createDedicatedTenantApp(
  tenant: Tenant
): Promise<TenantInfrastructure> {
  const appName = `ewh-tenant-${tenant.id}-svc-dms`

  // 1. Create Scalingo app
  const app = await scalingo.apps.create({
    name: appName,
    stack: 'scalingo-22',
    region: tenant.data_residency_region || 'osc-fr1'
  })

  // 2. Provision database addon
  const dbAddon = await scalingo.addons.create(appName, {
    addon_provider: 'postgresql',
    plan: 'postgresql:postgresql-business-1024',
    options: {
      version: '15',
      encryption: true,
      backup_retention: 365
    }
  })

  // 3. Provision Redis addon
  const redisAddon = await scalingo.addons.create(appName, {
    addon_provider: 'redis',
    plan: 'redis:redis-starter-256'
  })

  // 4. Set environment variables
  await scalingo.apps.setEnv(appName, {
    TENANT_ID: tenant.id,
    VERTICAL: tenant.vertical,
    ISOLATION_TIER: 'dedicated',
    S3_BUCKET: `ewh-tenant-${tenant.id}-${tenant.vertical}`,
    NODE_ENV: 'production'
  })

  // 5. Deploy code
  await scalingo.deployments.create(appName, {
    git_ref: 'main',
    source_url: 'https://github.com/edizioniwhitehole/svc-dms'
  })

  return {
    appName,
    databaseUrl: dbAddon.config.DATABASE_URL,
    redisUrl: redisAddon.config.REDIS_URL,
    appUrl: `https://${appName}.osc-fr1.scalingo.io`,
    status: 'deployed'
  }
}
```

#### 3. Migrate Tenant Data

```typescript
async function migrateTenantData(
  tenantId: string,
  sourceDb: string,
  targetDb: string
): Promise<MigrationResult> {
  const migration = {
    id: generateId(),
    tenantId,
    startTime: new Date(),
    status: 'in_progress'
  }

  try {
    // 1. Create read replica on source (for zero-downtime)
    const replica = await createReadReplica(sourceDb)

    // 2. Export tenant data
    const dumpFile = await pg_dump(replica, {
      schema: 'public',
      where: `tenant_id = '${tenantId}'`
    })

    // 3. Import to target database
    await pg_restore(targetDb, dumpFile)

    // 4. Verify data integrity
    const sourceCount = await countRows(replica, tenantId)
    const targetCount = await countRows(targetDb, tenantId)

    if (sourceCount !== targetCount) {
      throw new Error(`Row count mismatch: ${sourceCount} vs ${targetCount}`)
    }

    // 5. Verify checksums
    const sourceChecksum = await computeChecksum(replica, tenantId)
    const targetChecksum = await computeChecksum(targetDb, tenantId)

    if (sourceChecksum !== targetChecksum) {
      throw new Error('Data checksum mismatch')
    }

    migration.status = 'completed'
    migration.endTime = new Date()
    migration.rowsMigrated = sourceCount

  } catch (error) {
    migration.status = 'failed'
    migration.error = error.message

    // Auto-rollback
    await rollbackMigration(migration)
    throw error
  }

  return migration
}
```

#### 4. Switch Routing (Zero-Downtime Cutover)

```typescript
async function switchTenantRouting(
  tenantId: string,
  targetDb: string
): Promise<void> {
  // 1. Enable read-only mode on source (optional safety)
  await setReadOnlyMode(tenantId, true)

  // 2. Update tenant metadata atomically
  await db.query(
    `UPDATE auth.organizations
     SET
       vertical = $1,
       isolation_tier = $2,
       database_url = $3,
       updated_at = NOW()
     WHERE id = $4`,
    ['realestate', 'database', targetDb, tenantId]
  )

  // 3. Flush cache (tenant routing cache)
  await redis.del(`tenant:${tenantId}:routing`)

  // 4. Wait for cache propagation (100ms)
  await sleep(100)

  // 5. Verify new routing works
  const testQuery = await executeQuery(tenantId, 'SELECT 1')
  if (!testQuery.success) {
    // Rollback
    await rollbackRoutingSwitch(tenantId)
    throw new Error('Routing switch verification failed')
  }

  // 6. Disable read-only mode
  await setReadOnlyMode(tenantId, false)

  console.log(`Tenant ${tenantId} routing switched successfully (0s downtime)`)
}
```

---

## Admin Control Panel

### UI Requirements: Tenant Migration Management

**Location:** `app-admin-console/src/pages/platform/tenant-migrations.tsx`

#### Dashboard View

```typescript
interface MigrationDashboard {
  // Overview cards
  stats: {
    activeMigrations: number
    completedToday: number
    failedLast7Days: number
    averageDuration: string // "12m 34s"
  }

  // Active migrations table
  activeMigrations: Migration[]

  // Quick actions
  quickActions: {
    label: string
    action: () => void
  }[]
}
```

**UI Mockup:**
```
┌─────────────────────────────────────────────────────────────┐
│  Tenant Migrations                             [+ New]  [⚙️] │
├─────────────────────────────────────────────────────────────┤
│  📊 Active: 2   ✅ Today: 15   ❌ Failed (7d): 0   ⏱️ Avg: 8m │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🔄 Active Migrations                                       │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ Tenant            From    →  To         Progress      │ │
│  ├───────────────────────────────────────────────────────┤ │
│  │ Acme Corp         Core    →  Real Est.  ████████░ 80% │ │
│  │ City Hospital     Vertical→  Dedicated  ███░░░░░░ 30% │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  📋 Recent Migrations                                       │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ Tenant          Migration Type      Status   Duration │ │
│  ├───────────────────────────────────────────────────────┤ │
│  │ Tech Startup    Core → Vertical     ✅ Done   12m 34s │ │
│  │ Law Firm LLC    Vertical → Dedic.   ✅ Done   45m 12s │ │
│  │ Medical Group   Core → Vertical     ❌ Failed  5m 01s │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Migration Wizard (Multi-Step)

**Step 1: Select Tenant & Target**
```tsx
<MigrationWizard>
  <Step1_SelectTenant>
    <TenantSelector
      filter={{ vertical: 'core' }} // Only tenants eligible for migration
      onSelect={(tenant) => setSelectedTenant(tenant)}
    />

    <TargetSelector>
      <Radio value="vertical">Migrate to Vertical (Tier 2)</Radio>
      <Radio value="dedicated">Migrate to Dedicated (Tier 3)</Radio>
      <Radio value="downgrade">Downgrade Tier ⚠️</Radio>
    </TargetSelector>
  </Step1_SelectTenant>

  <Step2_Configuration>
    {target === 'vertical' && (
      <VerticalSelector
        options={['realestate', 'medical', 'ecommerce']}
        selected={targetVertical}
      />
    )}

    {target === 'dedicated' && (
      <DedicatedConfig>
        <RegionSelector default="osc-fr1" />
        <DatabasePlanSelector plans={['starter', 'business']} />
        <BackupRetention default={90} />
      </DedicatedConfig>
    )}
  </Step2_Configuration>

  <Step3_Review>
    <CostEstimate>
      Current cost: €0/month (Tier 1)
      New cost: €30/month (Tier 2 - Database Separation)
      Delta: +€30/month

      Estimated migration time: 8-15 minutes
      Expected downtime: 0 seconds
    </CostEstimate>

    <DataSummary>
      Rows to migrate: 152,342
      Storage to migrate: 2.4 GB
      Estimated duration: 12m 30s
    </DataSummary>

    <RiskAssessment level="low">
      ✅ Automatic rollback enabled
      ✅ Zero-downtime migration
      ✅ Data integrity verification
      ⚠️ Requires Scalingo API access
    </RiskAssessment>
  </Step3_Review>

  <Step4_Execute>
    <Button onClick={startMigration}>
      Start Migration
    </Button>
  </Step4_Execute>
</MigrationWizard>
```

#### Real-Time Migration Monitor

```tsx
<MigrationMonitor migrationId={migration.id}>
  {/* Progress bar */}
  <ProgressBar value={progress} max={100} />

  {/* Step-by-step status */}
  <MigrationSteps>
    <Step status="completed" duration="32s">
      ✅ Provision database addon
    </Step>
    <Step status="in_progress" current>
      🔄 Migrate tenant data (80% - 122k/152k rows)
    </Step>
    <Step status="pending">
      ⏳ Verify data integrity
    </Step>
    <Step status="pending">
      ⏳ Switch routing
    </Step>
  </MigrationSteps>

  {/* Live logs */}
  <LogStream>
    [14:23:45] Connecting to source database...
    [14:23:46] Creating read replica...
    [14:23:48] Starting pg_dump for tenant acme-corp...
    [14:25:12] Dumped 122,341 rows (80%)
    [14:25:45] Restoring to target database...
  </LogStream>

  {/* Actions */}
  <Actions>
    <Button variant="danger" onClick={cancelMigration}>
      Cancel & Rollback
    </Button>
    <Button variant="secondary" onClick={pauseMigration}>
      Pause
    </Button>
  </Actions>
</MigrationMonitor>
```

### API Endpoints for Control Panel

```typescript
// GET /api/platform/migrations
app.get('/api/platform/migrations', async (req, rep) => {
  const { status, limit = 50 } = req.query

  return await db.query(
    `SELECT * FROM platform.tenant_migrations
     WHERE status = COALESCE($1, status)
     ORDER BY created_at DESC
     LIMIT $2`,
    [status, limit]
  )
})

// POST /api/platform/migrations
app.post('/api/platform/migrations', async (req, rep) => {
  const schema = z.object({
    tenantId: z.string().uuid(),
    targetVertical: z.enum(['realestate', 'medical', 'ecommerce']),
    targetTier: z.enum(['schema', 'database', 'dedicated'])
  })

  const data = schema.parse(req.body)

  // Start migration (async job)
  const migration = await startMigration(data)

  return rep.code(202).send(migration)
})

// GET /api/platform/migrations/:id/progress
app.get('/api/platform/migrations/:id/progress', async (req, rep) => {
  const { id } = req.params

  return await getMigrationProgress(id)
})

// POST /api/platform/migrations/:id/rollback
app.post('/api/platform/migrations/:id/rollback', async (req, rep) => {
  const { id } = req.params

  await rollbackMigration(id)

  return rep.code(200).send({ success: true })
})

// GET /api/platform/migrations/cost-estimate
app.get('/api/platform/migrations/cost-estimate', async (req, rep) => {
  const { tenantId, targetTier } = req.query

  return await estimateMigrationCost(tenantId, targetTier)
})
```

---

## Migration Workflows

### Workflow 1: Automated Vertical Migration

**Trigger:** User enables vertical-specific feature

```typescript
// In svc-billing or feature flag service
async function enableVerticalFeature(
  tenantId: string,
  feature: 'realestate_mls' | 'medical_ehr' | 'ecommerce_inventory'
) {
  const vertical = getVerticalFromFeature(feature)
  const tenant = await getTenant(tenantId)

  // Check if migration needed
  if (tenant.vertical === 'core' && vertical !== 'core') {
    // Auto-trigger migration
    await queueMigration({
      tenantId,
      targetVertical: vertical,
      targetTier: 'database', // Default: Tier 2
      reason: `Feature enabled: ${feature}`,
      autoApprove: true // If within policy
    })

    // Notify tenant admin
    await sendNotification(tenantId, {
      type: 'migration_scheduled',
      message: `Your account is being upgraded to ${vertical} vertical`,
      eta: '10-15 minutes'
    })
  }

  // Enable feature flag
  await enableFeatureFlag(tenantId, feature)
}
```

### Workflow 2: Manual Admin Migration

**Trigger:** Platform admin action from control panel

```typescript
// In app-admin-console
async function onMigrationFormSubmit(data: MigrationForm) {
  // Step 1: Validate
  const validation = await validateMigration(data)
  if (!validation.valid) {
    showError(validation.errors)
    return
  }

  // Step 2: Show cost & risk summary
  const estimate = await estimateMigrationCost(data)
  const confirmed = await showConfirmDialog({
    title: 'Confirm Migration',
    cost: estimate.monthlyCost,
    duration: estimate.duration,
    downtime: estimate.downtime
  })

  if (!confirmed) return

  // Step 3: Queue migration
  const migration = await api.post('/platform/migrations', data)

  // Step 4: Navigate to monitor page
  router.push(`/platform/migrations/${migration.id}`)
}
```

### Workflow 3: Scheduled Maintenance Migration

**Trigger:** Cron job during low-traffic window

```typescript
// In svc-job-worker
async function scheduledMigrationJob() {
  // Find tenants queued for migration
  const queued = await db.query(
    `SELECT * FROM platform.tenant_migrations
     WHERE status = 'queued'
     AND scheduled_at <= NOW()
     ORDER BY priority DESC
     LIMIT 5` // Max 5 concurrent migrations
  )

  for (const migration of queued.rows) {
    // Execute migration
    await executeMigration(migration)
  }
}

// Cron: Every hour during low-traffic (02:00-06:00 UTC)
schedule('0 2-6 * * *', scheduledMigrationJob)
```

---

## Rollback & Recovery

### Automatic Rollback Triggers

```typescript
const ROLLBACK_TRIGGERS = {
  // Data integrity check fails
  data_integrity_failed: async (migration) => {
    console.error('Data integrity check failed, rolling back')
    await rollbackMigration(migration.id)
  },

  // Migration timeout (2 hours)
  migration_timeout: async (migration) => {
    console.error('Migration timeout, rolling back')
    await rollbackMigration(migration.id)
  },

  // Target database unreachable
  target_db_unreachable: async (migration) => {
    console.error('Cannot connect to target database, rolling back')
    await rollbackMigration(migration.id)
  },

  // Post-migration error rate spike
  error_rate_spike: async (migration) => {
    console.error('Error rate spike detected post-migration, rolling back')
    await rollbackMigration(migration.id)
  }
}
```

### Rollback Process

```typescript
async function rollbackMigration(migrationId: string) {
  const migration = await getMigration(migrationId)

  console.log(`Rolling back migration ${migrationId}...`)

  // 1. Switch routing back to source
  await switchTenantRouting(
    migration.tenantId,
    migration.sourceDatabase
  )

  // 2. Mark migration as rolled back
  await db.query(
    `UPDATE platform.tenant_migrations
     SET status = 'rolled_back', rolled_back_at = NOW()
     WHERE id = $1`,
    [migrationId]
  )

  // 3. Keep target database for 24h (for debugging)
  await scheduleCleanup(migration.targetDatabase, { delay: '24 hours' })

  // 4. Notify admins
  await sendAlert({
    severity: 'high',
    message: `Migration ${migrationId} rolled back`,
    tenant: migration.tenantId
  })

  // 5. Refund prorated charges (if applicable)
  if (migration.billingImpact) {
    await refundCharges(migration.tenantId, migration.billingImpact)
  }

  console.log(`Rollback complete for migration ${migrationId}`)
}
```

### Manual Recovery Procedures

**Scenario: Migration stuck at 50%**

```bash
# 1. Check migration status
curl https://api.polosaas.it/platform/migrations/{id}

# 2. Check logs
scalingo -a ewh-prod-svc-migrations logs --lines 100

# 3. Force rollback via admin panel
# OR via CLI:
curl -X POST https://api.polosaas.it/platform/migrations/{id}/rollback \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"

# 4. Verify tenant routing restored
psql $DATABASE_URL -c "SELECT vertical, isolation_tier FROM auth.organizations WHERE id = '{tenant_id}'"
```

---

## Monitoring & Alerts

### Metrics to Track

```typescript
interface MigrationMetrics {
  // Performance
  averageDuration: number // milliseconds
  p95Duration: number
  p99Duration: number

  // Reliability
  successRate: number // percentage
  rollbackRate: number
  dataIntegrityFailures: number

  // Volume
  migrationsPerDay: number
  activeC concurrentMigrations: number
  queuedMigrations: number

  // Cost
  totalInfrastructureCost: number // monthly
  costPerMigration: number
}
```

### Alert Conditions

```yaml
alerts:
  - name: migration_failure_rate_high
    condition: failure_rate > 5% in last 24h
    severity: high
    notify: [platform-team, on-call]

  - name: migration_duration_anomaly
    condition: duration > 2x average
    severity: medium
    notify: [platform-team]

  - name: data_integrity_check_failed
    condition: any failure
    severity: critical
    notify: [platform-team, on-call, security-team]
    action: auto_rollback

  - name: concurrent_migrations_limit
    condition: active_migrations > 10
    severity: medium
    notify: [platform-team]
    action: pause_new_migrations
```

### Monitoring Dashboard

**Location:** `app-admin-console/src/pages/platform/migration-monitoring.tsx`

```
┌─────────────────────────────────────────────────────────────┐
│  Migration Monitoring                             [Refresh] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Success Rate (24h)         Data Integrity      Avg Durat. │
│  ██████████████████░ 95%    ✅ 100% passed      12m 34s    │
│                                                             │
│  📈 Migration Volume (Last 7 Days)                          │
│     ┌─────────────────────────────────────┐                │
│   30│             ╭─╮                     │                │
│   20│       ╭─╮   │ │   ╭─╮               │                │
│   10│   ╭─╮ │ │   │ │   │ │               │                │
│    0└───┴─┴─┴─┴───┴─┴───┴─┴───────────────┘                │
│       Mon Tue Wed Thu Fri Sat Sun                           │
│                                                             │
│  ⚠️ Active Alerts                                           │
│  • Migration #12345 duration anomaly (32 minutes)          │
│  • Queue depth high (15 pending)                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Next Steps

### Implementation Checklist

- [ ] **Phase 1: Core Migration Engine** (2 weeks)
  - [ ] Implement `migrateTenantData()` function
  - [ ] Implement `switchTenantRouting()` with zero-downtime
  - [ ] Implement rollback mechanism
  - [ ] Add data integrity verification

- [ ] **Phase 2: Scalingo API Integration** (1 week)
  - [ ] Implement `provisionDatabaseAddon()`
  - [ ] Implement `createDedicatedTenantApp()`
  - [ ] Test addon provisioning on staging
  - [ ] Implement cost estimation API

- [ ] **Phase 3: Admin Control Panel** (2 weeks)
  - [ ] Build migration wizard UI
  - [ ] Build real-time monitoring dashboard
  - [ ] Implement WebSocket for live progress
  - [ ] Add rollback button with confirmation

- [ ] **Phase 4: Automation & Monitoring** (1 week)
  - [ ] Implement automatic vertical migration triggers
  - [ ] Setup alerting rules (PagerDuty/Slack)
  - [ ] Build metrics dashboard (Grafana)
  - [ ] Document runbook procedures

- [ ] **Phase 5: Testing & Launch** (1 week)
  - [ ] Test full migration flow on staging
  - [ ] Load testing (concurrent migrations)
  - [ ] Rollback testing (failure scenarios)
  - [ ] Documentation for support team
  - [ ] Soft launch with 3-5 pilot tenants

**Total Estimated Time:** 7 weeks

---

## Reference Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall system architecture
- [MASTER_PROMPT.md](MASTER_PROMPT.md) - Development guidelines
- [Scalingo API Docs](https://developers.scalingo.com/) - API reference
- [PostgreSQL Logical Replication](https://www.postgresql.org/docs/current/logical-replication.html) - Zero-downtime migrations

---

**Maintainer:** Platform Team
**Review Schedule:** Monthly
**Last Updated:** 2025-10-04
