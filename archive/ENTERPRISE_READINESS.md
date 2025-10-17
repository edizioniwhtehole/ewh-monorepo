# EWH Platform - Enterprise Readiness Checklist

> **Gap analysis e roadmap per trasformare EWH in una piattaforma Enterprise-Grade**

**Versione:** 1.0.0
**Target Audience:** CTO, Platform Team, Investors
**Ultima revisione:** 2025-10-04

---

## 📋 Executive Summary

**Stato Attuale:** MVP funzionante, adatto per SMB (Small-Medium Business)

**Gap Enterprise:** 12 aree critiche da completare

**Timeline:** 6-9 mesi per Enterprise-Grade completo

**Investimento stimato:** €120k-180k (1.5-2 FTE per 9 mesi)

---

## 🎯 Enterprise Requirements Matrix

| Capability | Current State | Enterprise Requirement | Priority | Effort |
|------------|---------------|------------------------|----------|--------|
| **Backup & Disaster Recovery** | Basic Scalingo backups | Multi-tier, PITR, cross-region | 🔴 Critical | 3 weeks |
| **High Availability (HA)** | Single instance | Multi-region, 99.99% SLA | 🔴 Critical | 6 weeks |
| **Security & Compliance** | Basic JWT auth | SOC2, ISO27001, HIPAA | 🔴 Critical | 8 weeks |
| **Monitoring & Observability** | Basic logs | Full stack, APM, alerting | 🟡 High | 4 weeks |
| **SLA & Support** | Best-effort | 99.9%+ SLA, 24/7 support | 🟡 High | Ongoing |
| **Data Residency & Sovereignty** | EU-West only | Multi-region, per-tenant | 🟡 High | 4 weeks |
| **API Rate Limiting & Quotas** | Basic gateway limits | Per-tenant, granular | 🟢 Medium | 2 weeks |
| **Audit Logging** | Application logs | Immutable audit trail | 🔴 Critical | 3 weeks |
| **Single Sign-On (SSO)** | Email/password | SAML, OAuth, LDAP | 🟡 High | 3 weeks |
| **Advanced RBAC** | Basic roles | Fine-grained, custom | 🟢 Medium | 4 weeks |
| **White-Label & Multi-Tenant** | Single brand | Custom domains, branding | 🟢 Medium | 4 weeks |
| **Performance & Scalability** | Vertical scaling | Auto-scaling, caching | 🟡 High | 6 weeks |

**Total Effort:** ~50 weeks = **9-12 months with 1 engineer**

**Recommended:** 2 engineers = **6 months to Enterprise-Grade**

---

## 🔴 CRITICAL #1: Backup & Disaster Recovery

### Current State ❌

```yaml
Backups:
  - Provider: Scalingo (automated)
  - Frequency: Daily
  - Retention: 7 days (starter plan)
  - Type: Full database dump
  - Recovery Time: Manual, 2-4 hours
  - Point-in-Time Recovery: ❌ No
  - Cross-Region: ❌ No
  - Testing: ❌ Never tested
```

**Risks:**
- ⚠️ Data loss window: 24 hours
- ⚠️ No point-in-time recovery (PITR)
- ⚠️ Manual restore process (human error)
- ⚠️ Single region (no geo-redundancy)
- ⚠️ Backups never tested (may be corrupt)

### Enterprise Requirements ✅

```yaml
Backup Strategy (3-2-1 Rule):
  - 3 copies of data
  - 2 different media types
  - 1 offsite/cloud copy

PostgreSQL:
  - Continuous WAL archiving
  - Point-in-Time Recovery (5-minute window)
  - Automated daily full backups
  - Retention:
      - Daily: 30 days
      - Weekly: 90 days
      - Monthly: 12 months
      - Yearly: 7 years (compliance)
  - Cross-region replication
  - Encrypted backups (AES-256)
  - Automated restore testing (monthly)

S3 Storage:
  - Versioning enabled
  - Cross-region replication (CRR)
  - Lifecycle policies (transition to Glacier)
  - Object lock (WORM - Write Once Read Many)

Recovery Objectives:
  - RPO (Recovery Point Objective): 5 minutes
  - RTO (Recovery Time Objective): 15 minutes
  - MTTR (Mean Time To Recover): < 1 hour
```

### Implementation Plan

#### Phase 1: Enhanced PostgreSQL Backups (2 weeks)

```typescript
// New service: svc-backup-manager
interface BackupStrategy {
  // WAL archiving to S3
  walArchiving: {
    enabled: true
    destination: 's3://ewh-backups-prod/wal-archives/'
    compression: 'gzip'
    encryption: 'AES-256'
  }

  // Full backups
  fullBackups: {
    schedule: 'daily at 02:00 UTC'
    retention: {
      daily: 30,
      weekly: 12,
      monthly: 12,
      yearly: 7
    }
    destination: 's3://ewh-backups-prod/full/'
  }

  // Cross-region replication
  replication: {
    enabled: true
    regions: ['eu-west-1', 'us-east-1']
    async: true
  }
}
```

**Tasks:**
- [ ] Setup WAL archiving to S3 (pg_basebackup + wal-g)
- [ ] Implement automated backup verification
- [ ] Setup cross-region replication (S3 CRR)
- [ ] Create restore scripts with PITR
- [ ] Document restore procedures (runbook)
- [ ] Test restore monthly (automated)

**Tools:**
- `wal-g` or `pgBackRest` for PostgreSQL backups
- S3 lifecycle policies for retention
- Lambda functions for backup verification

**Cost:** +€50-100/month (S3 storage + cross-region transfer)

#### Phase 2: Disaster Recovery Plan (1 week)

```yaml
# disaster-recovery.yml
Scenarios:
  1. Single Database Corruption:
     - Detection: Automated integrity checks
     - Action: PITR to 5 minutes before corruption
     - RTO: 15 minutes
     - Owner: Platform Team

  2. Region-Wide Outage (AWS EU-WEST):
     - Detection: Health checks fail for 5 minutes
     - Action: Failover to US-EAST replica
     - RTO: 30 minutes
     - Owner: DevOps + CTO approval

  3. Ransomware Attack:
     - Detection: Unusual deletion patterns
     - Action: Restore from immutable backup (S3 Object Lock)
     - RTO: 2 hours
     - Owner: Security Team + CTO

  4. Data Center Fire:
     - Detection: Manual report
     - Action: Full restore from offsite backup
     - RTO: 4 hours
     - Owner: Disaster Recovery Team

Testing Schedule:
  - Quarterly: Full DR drill (simulate region outage)
  - Monthly: Database restore test (automated)
  - Weekly: Backup integrity verification
```

**Deliverables:**
- [ ] Disaster Recovery Runbook (step-by-step)
- [ ] Automated DR testing scripts
- [ ] Incident response playbook
- [ ] Contact tree (on-call escalation)

---

## 🔴 CRITICAL #2: High Availability (HA)

### Current State ❌

```
Single Instance Architecture:
┌─────────────────────────────┐
│  svc-dms (single container) │  ← Single Point of Failure
└─────────────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  PostgreSQL (single node)   │  ← Single Point of Failure
└─────────────────────────────┘
```

**Availability:** ~99.5% (4 hours downtime/month)

**Risks:**
- ⚠️ Container crash = service down
- ⚠️ Database maintenance = downtime
- ⚠️ Deployment = brief outage
- ⚠️ No automatic failover

### Enterprise Requirements ✅

**SLA:** 99.99% uptime (52 minutes downtime/year)

```
High Availability Architecture:
┌──────────────────────────────────────────┐
│  Load Balancer (Cloudflare/AWS ALB)      │
└────────┬─────────────────────────┬───────┘
         │                         │
         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐
│  svc-dms-1      │       │  svc-dms-2      │  ← Redundancy
│  (EU-WEST-1a)   │       │  (EU-WEST-1b)   │
└────────┬────────┘       └────────┬────────┘
         │                         │
         └──────────┬──────────────┘
                    ▼
     ┌─────────────────────────────────┐
     │  PostgreSQL HA Cluster          │
     │  ┌──────────┐    ┌───────────┐  │
     │  │ Primary  │───▶│ Standby   │  │  ← Automatic Failover
     │  │ (leader) │    │ (replica) │  │
     │  └──────────┘    └───────────┘  │
     └─────────────────────────────────┘
```

### Implementation Plan

#### Phase 1: Multi-Container Deployment (2 weeks)

```yaml
# scalingo.yml
formation:
  web:
    amount: 2  # Minimum 2 containers
    size: M
    autoscaling:
      enabled: true
      min: 2
      max: 10
      metric: cpu
      threshold: 70%
```

**Tasks:**
- [ ] Configure horizontal scaling (min 2 instances)
- [ ] Setup health checks (/health endpoint)
- [ ] Implement graceful shutdown (SIGTERM handling)
- [ ] Test rolling deployments (zero-downtime)

#### Phase 2: Database High Availability (3 weeks)

**Option A: Scalingo HA Addon** (Recommended)
```yaml
addons:
  - plan: postgresql:postgresql-business-ha-1024
    cost: €200/month
    features:
      - Automatic failover (30s)
      - Read replicas (2x)
      - 99.95% SLA
```

**Option B: AWS RDS Multi-AZ** (More control)
```yaml
rds_cluster:
  engine: postgres
  version: 15
  instance_class: db.r6g.large
  multi_az: true
  read_replicas: 2
  backup_retention: 30
  cost: €300-400/month
```

**Tasks:**
- [ ] Upgrade to HA database plan
- [ ] Configure automatic failover
- [ ] Setup read replicas for read-heavy queries
- [ ] Implement connection pooling (PgBouncer)
- [ ] Test failover (manual trigger)

#### Phase 3: Multi-Region (Optional - 4 weeks)

For 99.99%+ SLA and disaster recovery:

```
┌──────────────────────────────────────────────────┐
│  Cloudflare Load Balancer (Global)               │
│  • Health checks                                 │
│  • Automatic region failover                     │
└────────┬─────────────────────────────────┬───────┘
         │                                 │
         ▼                                 ▼
┌──────────────────┐             ┌──────────────────┐
│  EU-WEST Region  │             │  US-EAST Region  │
│  (Primary)       │◄───Replica──│  (Standby)       │
│  • App servers   │             │  • App servers   │
│  • PostgreSQL    │             │  • PostgreSQL    │
│  • Redis         │             │  • Redis         │
└──────────────────┘             └──────────────────┘
```

**Cost:** +€500-800/month (duplicate infrastructure)

---

## 🔴 CRITICAL #3: Security & Compliance

### Current State ❌

```yaml
Security Posture:
  - Authentication: ✅ JWT (RS256)
  - Authorization: ⚠️ Basic RBAC
  - Encryption in transit: ✅ TLS 1.3
  - Encryption at rest: ⚠️ Database only
  - Audit logging: ❌ Application logs only
  - Secrets management: ⚠️ Environment variables
  - Vulnerability scanning: ❌ None
  - Penetration testing: ❌ Never done
  - Compliance certifications: ❌ None
```

### Enterprise Requirements ✅

#### SOC 2 Type II Compliance (6-9 months)

```yaml
SOC 2 Requirements:
  Security:
    - Multi-factor authentication (MFA)
    - Password policies (complexity, rotation)
    - Encryption at rest and in transit
    - Network segmentation
    - Intrusion detection (IDS)

  Availability:
    - 99.9%+ uptime SLA
    - Incident response plan
    - Disaster recovery tested quarterly

  Processing Integrity:
    - Data validation (Zod schemas)
    - Transaction logging
    - Error handling

  Confidentiality:
    - Data classification
    - Access controls (least privilege)
    - Non-disclosure agreements (NDAs)

  Privacy:
    - GDPR compliance
    - Data retention policies
    - User consent management
    - Data export (right to access)
    - Data deletion (right to be forgotten)
```

#### Implementation Roadmap

**Month 1-2: Foundation**
- [ ] Implement MFA (TOTP, SMS, WebAuthn)
- [ ] Password policies (NIST 800-63B compliant)
- [ ] Secrets management (HashiCorp Vault or AWS Secrets Manager)
- [ ] Security headers (CSP, HSTS, X-Frame-Options)

**Month 3-4: Monitoring & Logging**
- [ ] Centralized audit logging (immutable)
- [ ] SIEM integration (Splunk, Datadog Security)
- [ ] Anomaly detection (unusual login patterns)
- [ ] Automated alerting (security events)

**Month 5-6: Compliance**
- [ ] Vulnerability scanning (Snyk, Dependabot)
- [ ] Container security scanning (Trivy)
- [ ] Penetration testing (external firm)
- [ ] SOC 2 audit preparation

**Month 7-9: Certification**
- [ ] Hire SOC 2 auditor
- [ ] Evidence collection (3-6 months)
- [ ] Remediation of findings
- [ ] SOC 2 Type II report

**Cost:**
- Auditor: €30k-50k
- Security tools: €500/month
- Consultant (optional): €20k
- **Total:** €50k-80k

#### HIPAA Compliance (Medical Vertical)

```yaml
HIPAA Requirements:
  Administrative Safeguards:
    - Security officer designated
    - Workforce training (annual)
    - Business Associate Agreements (BAA)
    - Risk assessment (annual)

  Physical Safeguards:
    - Facility access controls
    - Workstation security
    - Device encryption

  Technical Safeguards:
    - Unique user IDs
    - Automatic logoff (15 min idle)
    - Encryption at rest (AES-256)
    - Audit controls (all PHI access logged)
    - Integrity controls (checksums)
    - Transmission security (TLS 1.3)
```

**Implementation:**
- [ ] BAA with Scalingo (request HIPAA plan)
- [ ] PHI data classification & tagging
- [ ] Automatic PHI detection (regex + ML)
- [ ] Access controls (role-based + attributes)
- [ ] Breach notification workflow

**Cost:** +€20k legal + €10k/year compliance

---

## 🟡 HIGH PRIORITY #4: Monitoring & Observability

### Current State ❌

```
Limited Visibility:
- Application logs (Scalingo console)
- Basic metrics (CPU, memory)
- No distributed tracing
- No APM (Application Performance Monitoring)
- Manual log searching
```

**Problems:**
- ⚠️ Can't diagnose performance issues
- ⚠️ No visibility into inter-service calls
- ⚠️ Reactive (not proactive) debugging

### Enterprise Requirements ✅

```
Full Stack Observability:
┌─────────────────────────────────────────────────┐
│  Logs    Metrics    Traces    Profiles          │
│   │        │          │          │              │
│   └────────┴──────────┴──────────┘              │
│              ▼                                   │
│   ┌──────────────────────────┐                  │
│   │  Observability Platform  │                  │
│   │  (Datadog / New Relic)   │                  │
│   └──────────────────────────┘                  │
│              ▼                                   │
│   ┌──────────────────────────┐                  │
│   │  AI-Powered Insights     │                  │
│   │  • Anomaly detection     │                  │
│   │  • Root cause analysis   │                  │
│   │  • Predictive alerts     │                  │
│   └──────────────────────────┘                  │
└─────────────────────────────────────────────────┘
```

### Implementation Plan

#### Phase 1: Centralized Logging (1 week)

```typescript
// Add to all services
import pino from 'pino'
import { datadogLogs } from '@datadog/browser-logs'

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  // Datadog integration
  transport: {
    target: 'pino-datadog',
    options: {
      apiKey: process.env.DATADOG_API_KEY,
      service: process.env.SERVICE_NAME,
      tags: [
        `env:${process.env.NODE_ENV}`,
        `vertical:${process.env.VERTICAL}`,
        `version:${process.env.APP_VERSION}`
      ]
    }
  }
})

// Structured logging
logger.info({
  event: 'order.created',
  tenant_id: tenant.id,
  order_id: order.id,
  amount: order.total,
  duration_ms: Date.now() - startTime
}, 'Order created successfully')
```

**Tools:**
- **Datadog** (recommended): €45/host/month
- **New Relic**: €50/host/month
- **Elastic Stack** (self-hosted): €0 but maintenance cost

#### Phase 2: Distributed Tracing (2 weeks)

```typescript
// OpenTelemetry instrumentation
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node'
import { registerInstrumentations } from '@opentelemetry/instrumentation'
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http'
import { FastifyInstrumentation } from '@opentelemetry/instrumentation-fastify'

const provider = new NodeTracerProvider({
  serviceName: 'svc-orders',
  resource: {
    'deployment.environment': process.env.NODE_ENV,
    'service.version': process.env.APP_VERSION
  }
})

registerInstrumentations({
  instrumentations: [
    new HttpInstrumentation(),
    new FastifyInstrumentation(),
    new PgInstrumentation()  // PostgreSQL queries
  ]
})

// Traces show:
// Request → svc-orders → svc-products → svc-inventory
//   100ms     50ms         30ms           20ms
```

**Benefits:**
- See full request journey across services
- Identify slow database queries
- Find bottlenecks visually

#### Phase 3: Metrics & Dashboards (1 week)

```typescript
// Prometheus metrics
import { register, Counter, Histogram } from 'prom-client'

const httpRequestCounter = new Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'path', 'status', 'tenant_id']
})

const httpRequestDuration = new Histogram({
  name: 'http_request_duration_ms',
  help: 'HTTP request duration',
  labelNames: ['method', 'path'],
  buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000]
})

// Expose /metrics endpoint
app.get('/metrics', async (req, rep) => {
  rep.header('Content-Type', register.contentType)
  return register.metrics()
})
```

**Dashboards to create:**
- Service health (uptime, error rate, latency)
- Business metrics (orders/day, revenue, active users)
- Infrastructure (CPU, memory, disk, network)
- Database (query performance, connection pool, locks)
- Vertical-specific (tenants per vertical, storage usage)

**Cost:** €200-400/month (depends on data volume)

---

## 🟡 HIGH PRIORITY #5: Audit Logging (Immutable)

### Current State ❌

```typescript
// Current logging
req.log.info({ user_id, action: 'document.deleted' }, 'Document deleted')
```

**Problems:**
- ⚠️ Logs can be modified/deleted
- ⚠️ No centralized audit trail
- ⚠️ Can't prove compliance
- ⚠️ No alerting on suspicious activity

### Enterprise Requirements ✅

```typescript
// Immutable audit log
interface AuditEvent {
  id: string                    // UUID
  timestamp: string             // ISO 8601
  tenant_id: string
  user_id: string
  ip_address: string
  user_agent: string
  action: string                // CRUD operation
  resource_type: string         // 'document', 'order', 'user'
  resource_id: string
  changes: {                    // What changed
    before: object
    after: object
  }
  result: 'success' | 'failure'
  reason?: string               // If failed
  metadata: Record<string, any>
  signature: string             // HMAC for integrity
}
```

### Implementation

```typescript
// svc-audit-log (new service)
import crypto from 'crypto'

class AuditLogger {
  async log(event: AuditEvent): Promise<void> {
    // 1. Add signature (integrity check)
    event.signature = this.sign(event)

    // 2. Write to append-only storage
    await this.appendToLog(event)

    // 3. Optional: Stream to SIEM
    await this.streamToSIEM(event)
  }

  private sign(event: AuditEvent): string {
    const payload = JSON.stringify({
      timestamp: event.timestamp,
      tenant_id: event.tenant_id,
      action: event.action,
      resource_id: event.resource_id
    })

    return crypto
      .createHmac('sha256', process.env.AUDIT_SECRET)
      .update(payload)
      .digest('hex')
  }

  private async appendToLog(event: AuditEvent): Promise<void> {
    // Write to PostgreSQL with append-only constraint
    await db.query(
      `INSERT INTO audit_logs (
        id, timestamp, tenant_id, user_id, action,
        resource_type, resource_id, changes, signature
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [event.id, event.timestamp, event.tenant_id, ...]
    )

    // Also write to S3 for long-term retention
    await s3.putObject({
      Bucket: 'ewh-audit-logs',
      Key: `${event.tenant_id}/${year}/${month}/${day}/${event.id}.json`,
      Body: JSON.stringify(event),
      ServerSideEncryption: 'AES256',
      ObjectLockMode: 'GOVERNANCE',  // Prevent deletion
      ObjectLockRetainUntilDate: addYears(new Date(), 7)  // 7 years
    })
  }
}
```

**Database schema:**
```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  timestamp TIMESTAMPTZ NOT NULL,
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL,
  ip_address INET,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID NOT NULL,
  changes JSONB,
  result TEXT NOT NULL,
  signature TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prevent updates/deletes
CREATE POLICY audit_append_only ON audit_logs
  FOR DELETE USING (false);

CREATE POLICY audit_no_update ON audit_logs
  FOR UPDATE USING (false);

-- Time-series partitioning (performance)
CREATE TABLE audit_logs_2025_10 PARTITION OF audit_logs
  FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
```

**Alerting rules:**
```yaml
alerts:
  - name: suspicious_bulk_deletion
    condition: >
      count(action='delete') > 100 in 5 minutes
      by same user
    severity: critical
    action: notify_security_team

  - name: privilege_escalation
    condition: >
      action='role.changed'
      AND changes.after.role IN ('ADMIN', 'SUPER_ADMIN')
    severity: high
    action: notify_security_team

  - name: after_hours_access
    condition: >
      timestamp.hour NOT IN (8..18)
      AND action IN ('export', 'download')
    severity: medium
    action: log_for_review
```

**Cost:** +€50/month (S3 storage for 7 years retention)

---

## 🟡 HIGH PRIORITY #6: Single Sign-On (SSO)

### Current State ❌

```
Authentication Methods:
- Email + Password only
- No SSO
- No social login
```

**Enterprise Requirement:**
- SAML 2.0 (Okta, Azure AD, Google Workspace)
- OAuth 2.0 / OpenID Connect
- LDAP / Active Directory

### Implementation

```typescript
// svc-auth: Add SSO providers
import { Strategy as SAMLStrategy } from 'passport-saml'

// SAML configuration per tenant
interface TenantSSOConfig {
  tenant_id: string
  provider: 'okta' | 'azure_ad' | 'google'
  enabled: boolean

  // SAML settings
  saml: {
    entryPoint: string        // IdP login URL
    issuer: string            // SP entity ID
    cert: string              // IdP certificate
    callbackUrl: string       // ACS URL
  }

  // Attribute mapping
  attributeMapping: {
    email: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'
    firstName: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'
    lastName: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname'
    role: 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'
  }
}

// SSO flow
app.post('/auth/saml/login', async (req, rep) => {
  const { tenant_id } = req.body

  // 1. Lookup tenant SSO config
  const config = await getTenantSSOConfig(tenant_id)

  // 2. Generate SAML request
  const strategy = new SAMLStrategy(config.saml, async (profile, done) => {
    // 3. Create or update user
    const user = await findOrCreateUser({
      email: profile[config.attributeMapping.email],
      firstName: profile[config.attributeMapping.firstName],
      lastName: profile[config.attributeMapping.lastName],
      role: profile[config.attributeMapping.role]
    })

    done(null, user)
  })

  // 4. Redirect to IdP
  return strategy.redirect(req, rep)
})

// SSO callback (ACS - Assertion Consumer Service)
app.post('/auth/saml/callback', async (req, rep) => {
  // 5. Validate SAML response
  const user = await validateSAMLResponse(req.body)

  // 6. Generate JWT
  const token = await generateJWT(user)

  // 7. Redirect to app with token
  return rep.redirect(`https://app.polosaas.it/auth/callback?token=${token}`)
})
```

**Admin UI:**
```tsx
// app-admin-console: SSO Configuration
<SSOSetup tenantId={tenant.id}>
  <Select label="Provider">
    <Option value="okta">Okta</Option>
    <Option value="azure_ad">Azure AD</Option>
    <Option value="google">Google Workspace</Option>
  </Select>

  <Input label="Entity ID" value={config.saml.issuer} />
  <Input label="ACS URL" value={config.saml.callbackUrl} readonly />
  <Input label="IdP Login URL" value={config.saml.entryPoint} />
  <Textarea label="IdP Certificate" value={config.saml.cert} />

  <Button onClick={testConnection}>Test Connection</Button>
  <Button onClick={save}>Save Configuration</Button>
</SSOSetup>
```

**Testing checklist:**
- [ ] Okta integration (free developer account)
- [ ] Azure AD integration
- [ ] Google Workspace integration
- [ ] Just-in-Time (JIT) provisioning
- [ ] Role mapping from IdP to EWH

**Effort:** 3 weeks

---

## 🟢 MEDIUM PRIORITY #7: Advanced RBAC

### Current State ❌

```typescript
// Basic role check
if (user.role !== 'ADMIN') {
  return rep.code(403).send({ error: 'Forbidden' })
}
```

**Limitations:**
- Only 3-4 predefined roles
- No custom permissions
- No resource-level permissions
- No attribute-based access control

### Enterprise Requirements ✅

**Fine-Grained RBAC:**
```typescript
// Permission system
interface Permission {
  resource: string      // 'documents', 'orders', 'users'
  action: string        // 'create', 'read', 'update', 'delete', 'approve'
  conditions?: {        // Attribute-based rules
    'document.status': 'draft'
    'order.amount': { $lt: 10000 }
    'user.department': 'sales'
  }
}

interface Role {
  id: string
  name: string
  permissions: Permission[]
}

// Example: Custom role
const salesManager: Role = {
  id: 'role-sales-manager',
  name: 'Sales Manager',
  permissions: [
    {
      resource: 'orders',
      action: 'read',
      conditions: { 'order.department': 'sales' }
    },
    {
      resource: 'orders',
      action: 'approve',
      conditions: { 'order.amount': { $lt: 50000 } }
    },
    {
      resource: 'documents',
      action: '*',  // All actions
      conditions: { 'document.owner_id': '{{user.id}}' }  // Own documents only
    }
  ]
}
```

**Authorization middleware:**
```typescript
// Declarative permission check
app.get('/api/v1/orders/:id',
  requirePermission('orders', 'read'),
  async (req, rep) => {
    // ...
  }
)

// Permission checker
async function requirePermission(resource: string, action: string) {
  return async (req: FastifyRequest, rep: FastifyReply) => {
    const { user, authContext } = req

    // 1. Get user roles
    const roles = await getUserRoles(user.id, authContext.tenant_id)

    // 2. Check if any role grants permission
    const hasPermission = roles.some(role =>
      role.permissions.some(perm =>
        perm.resource === resource &&
        (perm.action === action || perm.action === '*') &&
        evaluateConditions(perm.conditions, req)
      )
    )

    if (!hasPermission) {
      throw new ForbiddenError(`Missing permission: ${resource}.${action}`)
    }
  }
}

// Condition evaluation
function evaluateConditions(
  conditions: Record<string, any>,
  req: FastifyRequest
): boolean {
  // Fetch resource data
  const resource = await fetchResource(req.params.id)

  // Evaluate each condition
  return Object.entries(conditions).every(([key, value]) => {
    const actualValue = get(resource, key)

    if (typeof value === 'object') {
      // Handle operators: $lt, $gt, $eq, $in, etc.
      return evaluateOperator(actualValue, value)
    }

    return actualValue === value
  })
}
```

**Admin UI: Role Builder**
```tsx
<RoleBuilder>
  <Input label="Role Name" placeholder="Sales Manager" />

  <PermissionList>
    <Permission>
      <Select label="Resource" value="orders" />
      <Select label="Action" value="approve" />
      <Conditions>
        <Condition field="order.amount" operator="<" value="50000" />
        <Condition field="order.status" operator="=" value="pending" />
      </Conditions>
    </Permission>

    <Button onClick={addPermission}>+ Add Permission</Button>
  </PermissionList>

  <Button onClick={save}>Create Role</Button>
</RoleBuilder>
```

**Effort:** 4 weeks

---

## 📊 Cost Summary (Year 1)

| Category | Current | Enterprise | Delta | Priority |
|----------|---------|------------|-------|----------|
| **Infrastructure** | €500/mo | €1,200/mo | +€700 | 🔴 |
| - Database HA | €30 | €200 | +€170 | |
| - Multi-region | €0 | €400 | +€400 | |
| - Backups (enhanced) | €0 | €100 | +€100 | |
| - Load balancers | €0 | €50 | +€50 | |
| **Monitoring & Observability** | €0 | €400/mo | +€400 | 🟡 |
| - Datadog/New Relic | - | €300 | +€300 | |
| - Uptime monitoring | - | €50 | +€50 | |
| - PagerDuty | - | €50 | +€50 | |
| **Security & Compliance** | €0 | €100/mo | +€100 | 🔴 |
| - Vulnerability scanning | - | €50 | +€50 | |
| - Secrets management | - | €50 | +€50 | |
| **One-Time Costs** | | | | |
| - SOC 2 audit | - | €50k | - | 🔴 |
| - Penetration testing | - | €10k | - | 🔴 |
| - Security consultant | - | €20k | - | 🟡 |
| **Personnel** | | | | |
| - DevOps engineer | - | €70k/yr | - | 🔴 |
| - Security engineer | - | €80k/yr | - | 🟡 |
| **Total Monthly** | €500 | €1,700 | +€1,200 | |
| **Total Year 1** | €6k | €240k | +€234k | |

**ROI Justification:**
- Enterprise clients pay €299-999/month (vs €29 SMB)
- 10 enterprise clients = €36k-120k/year revenue
- 50 enterprise clients = €180k-600k/year revenue
- Break-even: ~40 enterprise clients

---

## 🗓️ Implementation Timeline (6-Month Fast Track)

### Month 1-2: Foundation (Critical Path)
- ✅ Enhanced backups & disaster recovery
- ✅ High availability (multi-container + DB HA)
- ✅ Monitoring & observability stack
- ✅ Audit logging infrastructure

**Deliverables:**
- 99.9% uptime SLA
- PITR backups (5-minute RPO)
- Full stack observability
- Immutable audit logs

**Team:** 1 DevOps + 1 Backend Engineer

### Month 3-4: Security & Compliance
- ✅ MFA implementation
- ✅ SSO (SAML, OAuth)
- ✅ Secrets management
- ✅ Vulnerability scanning
- ✅ Penetration testing

**Deliverables:**
- SOC 2 audit readiness
- Security documentation
- Incident response plan

**Team:** 1 Security Engineer + 1 Backend Engineer

### Month 5-6: Enterprise Features
- ✅ Advanced RBAC
- ✅ White-label/multi-brand
- ✅ Data residency options
- ✅ Advanced analytics

**Deliverables:**
- Enterprise feature parity
- Customer-facing documentation
- Sales enablement materials

**Team:** 2 Full-Stack Engineers

### Month 7-9: Certification & Launch
- ✅ SOC 2 audit (3-6 month evidence period)
- ✅ HIPAA compliance (for medical vertical)
- ✅ Performance optimization
- ✅ Enterprise beta program (5-10 customers)

**Deliverables:**
- SOC 2 Type II report
- HIPAA compliance documentation
- Enterprise pricing tier
- Case studies

**Team:** Full team + external auditors

---

## ✅ Enterprise Readiness Scorecard

### Current State (MVP)

| Pillar | Score | Status |
|--------|-------|--------|
| Availability | 3/10 | ❌ Single instance, no HA |
| Reliability | 4/10 | ⚠️ Basic backups, no DR plan |
| Security | 5/10 | ⚠️ Basic auth, no audit logs |
| Compliance | 2/10 | ❌ No certifications |
| Observability | 3/10 | ❌ Basic logs, no tracing |
| Performance | 6/10 | ⚠️ Works but not optimized |
| Scalability | 5/10 | ⚠️ Manual scaling |
| Support | 4/10 | ⚠️ Best effort, no SLA |
| **TOTAL** | **4.0/10** | **Not Enterprise Ready** |

### Target State (Enterprise-Grade)

| Pillar | Target | Requirements Met |
|--------|--------|------------------|
| Availability | 9/10 | ✅ Multi-AZ, 99.99% SLA |
| Reliability | 9/10 | ✅ PITR, DR tested quarterly |
| Security | 9/10 | ✅ MFA, SSO, Audit logs |
| Compliance | 8/10 | ✅ SOC 2, HIPAA ready |
| Observability | 9/10 | ✅ Full stack, APM, alerting |
| Performance | 8/10 | ✅ Auto-scaling, caching |
| Scalability | 9/10 | ✅ Horizontal + vertical |
| Support | 8/10 | ✅ 24/7 on-call, SLA |
| **TOTAL** | **8.6/10** | **Enterprise Ready** ✅ |

---

## 🎯 Quick Wins (Month 1)

**High impact, low effort improvements to do NOW:**

1. **Enable automated backups verification** (1 day)
   - Script to restore daily backup to staging
   - Alert if restore fails

2. **Add health check endpoints** (1 day)
   ```typescript
   app.get('/health', async () => ({
     status: 'ok',
     database: await checkDatabase(),
     redis: await checkRedis(),
     uptime: process.uptime()
   }))
   ```

3. **Setup uptime monitoring** (1 hour)
   - UptimeRobot (free tier)
   - Monitor all production services
   - Alert via Slack/email

4. **Enable Scalingo horizontal scaling** (1 hour)
   ```yaml
   formation:
     web:
       amount: 2  # min 2 containers
   ```

5. **Add structured logging** (2 days)
   - Replace console.log with pino
   - Add correlation IDs
   - Add business event tracking

**Total effort:** 1 week, massive improvement in reliability

---

## 📚 Reference Documentation

**Industry Standards:**
- [SOC 2 Compliance Guide](https://www.aicpa.org/soc4so)
- [HIPAA Technical Safeguards](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [ISO 27001 Standard](https://www.iso.org/isoiec-27001-information-security.html)

**Tools & Vendors:**
- [Datadog](https://www.datadoghq.com/) - Monitoring
- [Vanta](https://www.vanta.com/) - Compliance automation
- [HashiCorp Vault](https://www.vaultproject.io/) - Secrets management
- [PagerDuty](https://www.pagerduty.com/) - Incident response

---

**Conclusion:** EWH Platform is a solid MVP. With 6-9 months of focused effort and €240k investment, it can be transformed into an enterprise-grade SaaS platform capable of serving Fortune 500 clients and passing SOC 2 audits.

**Next Step:** Prioritize based on target customers. If targeting healthcare → HIPAA first. If targeting enterprise SaaS → SOC 2 first.

---

**Maintainer:** Platform Team
**Review Schedule:** Quarterly
**Last Updated:** 2025-10-04
