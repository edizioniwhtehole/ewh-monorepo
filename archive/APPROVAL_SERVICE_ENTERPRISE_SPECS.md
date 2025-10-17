# 🏢 Approval Service - Enterprise-Grade Specifications

**Version:** 1.0
**Target Tier:** Enterprise (Tier 4)
**Last Updated:** 2025-10-10
**Status:** 📋 Specification (to be implemented after DAM)
**Related:** [APPROVAL_SERVICE_SPEC.md](APPROVAL_SERVICE_SPEC.md), [ENTERPRISE_DAM_ROADMAP.md](ENTERPRISE_DAM_ROADMAP.md)

---

## 📋 TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [Enterprise Requirements Checklist](#enterprise-requirements-checklist)
3. [Audit Log System (Immutable)](#audit-log-system-immutable)
4. [RBAC & Authorization](#rbac--authorization)
5. [SLA Management & Escalation](#sla-management--escalation)
6. [Webhook System (Signed)](#webhook-system-signed)
7. [Idempotency & Reliability](#idempotency--reliability)
8. [Rate Limiting & Quotas](#rate-limiting--quotas)
9. [Observability & Monitoring](#observability--monitoring)
10. [Security Hardening](#security-hardening)
11. [High Availability & Disaster Recovery](#high-availability--disaster-recovery)
12. [Performance Targets](#performance-targets)
13. [Database Schema Extensions](#database-schema-extensions)
14. [Implementation Roadmap](#implementation-roadmap)

---

## 🎯 EXECUTIVE SUMMARY

### Why Enterprise-Grade?

Il sistema di approvazioni è **business-critical**:
- ✅ Gestisce decisioni legali (chi ha approvato cosa quando)
- ✅ Compliance requirement (GDPR, SOC2, ISO27001)
- ✅ Revenue-blocking se down (ordini, pubblicazioni, quotazioni)
- ✅ Multi-tenant ad alta scala (1000+ concurrent users)

### Current vs Enterprise

| Feature | Base (MVP) | Enterprise | Gap |
|---------|-----------|------------|-----|
| **Audit Trail** | Basic logs | Immutable + hash chain | 🔴 Critical |
| **RBAC** | Simple roles | Attribute-based (ABAC) | 🔴 Critical |
| **SLA Enforcement** | Deadline tracking | Auto-escalation + alerts | 🔴 Critical |
| **Webhooks** | None | Signed + retry + DLQ | 🔴 Critical |
| **Idempotency** | None | Request deduplication | 🟠 High |
| **Rate Limiting** | None | Per-tenant quotas | 🟠 High |
| **Monitoring** | Basic logs | Prometheus + Grafana + Tracing | 🟠 High |
| **HA/DR** | Single instance | Multi-region + backup | 🟡 Medium |

---

## ✅ ENTERPRISE REQUIREMENTS CHECKLIST

### 🔴 P0 - Critical (Must Have)

- [ ] **Audit Log Immutabile**
  - [ ] Append-only log table
  - [ ] Hash chain per integrity verification
  - [ ] Retention policy (7+ years)
  - [ ] Export API (CSV, JSON)
  - [ ] Tamper detection

- [ ] **RBAC Granulare**
  - [ ] Permission model (view, approve, reject, manage)
  - [ ] Resource-level permissions (per approval item)
  - [ ] Role inheritance
  - [ ] Dynamic permission evaluation

- [ ] **SLA Management**
  - [ ] Deadline calculation (business hours aware)
  - [ ] Escalation rules (auto-reassign after X hours)
  - [ ] Notification cascade (email → Slack → SMS)
  - [ ] SLA breach alerts
  - [ ] Dashboard con SLA compliance

- [ ] **Webhook System**
  - [ ] Event-driven notifications
  - [ ] HMAC signature verification
  - [ ] Retry with exponential backoff (3 attempts)
  - [ ] Dead Letter Queue (DLQ) per failed webhooks
  - [ ] Webhook logs table

- [ ] **Idempotency**
  - [ ] Idempotency keys (header: `Idempotency-Key`)
  - [ ] Request deduplication (24h window)
  - [ ] Idempotent response cache

- [ ] **Rate Limiting**
  - [ ] Per-tenant quotas (e.g., 1000 req/min)
  - [ ] Per-user quotas (e.g., 100 req/min)
  - [ ] 429 Too Many Requests response
  - [ ] Rate limit headers (`X-RateLimit-*`)

### 🟠 P1 - High Priority (Should Have)

- [ ] **Observability**
  - [ ] Prometheus metrics (latency, throughput, errors)
  - [ ] Grafana dashboards
  - [ ] Distributed tracing (OpenTelemetry)
  - [ ] Structured logging (JSON)
  - [ ] Error tracking (Sentry)

- [ ] **Error Handling**
  - [ ] Retry logic with exponential backoff
  - [ ] Circuit breaker pattern
  - [ ] Graceful degradation
  - [ ] Health checks (liveness, readiness)

- [ ] **Security**
  - [ ] Input validation (Zod schemas)
  - [ ] SQL injection prevention (parameterized queries)
  - [ ] XSS prevention
  - [ ] CSRF protection
  - [ ] Secrets management (Vault, AWS Secrets Manager)

- [ ] **Testing**
  - [ ] Unit tests (80%+ coverage)
  - [ ] Integration tests
  - [ ] Load tests (k6)
  - [ ] Chaos engineering (simulate failures)

### 🟡 P2 - Medium Priority (Nice to Have)

- [ ] **High Availability**
  - [ ] Multi-region deployment
  - [ ] Database replication (read replicas)
  - [ ] Load balancing
  - [ ] Auto-scaling

- [ ] **Disaster Recovery**
  - [ ] Automated backups (daily)
  - [ ] Point-in-time recovery
  - [ ] Backup verification (automated restore test)
  - [ ] RTO < 1h, RPO < 15min

- [ ] **Advanced Features**
  - [ ] Approval delegation (temporary reassignment)
  - [ ] Out-of-office auto-forwarding
  - [ ] Bulk approval operations
  - [ ] Approval templates
  - [ ] Custom approval workflows (visual builder)

---

## 📜 AUDIT LOG SYSTEM (IMMUTABLE)

### Requirements

- **Immutable**: Once written, cannot be modified or deleted
- **Tamper-proof**: Hash chain ensures integrity
- **Long retention**: 7+ years (compliance requirement)
- **Queryable**: Fast search and filtering
- **Exportable**: CSV, JSON, PDF reports

### Database Schema

```sql
-- Audit Log Table (Append-Only)
CREATE TABLE approvals.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Event Info
  event_type VARCHAR(50) NOT NULL, -- 'approval.created', 'approval.approved', 'approval.rejected', 'step.approved', etc.
  event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Actor (who performed the action)
  actor_id UUID NOT NULL REFERENCES auth.users(id),
  actor_ip_address INET,
  actor_user_agent TEXT,

  -- Resource (what was affected)
  resource_type VARCHAR(50) NOT NULL, -- 'approval_item', 'pipeline', 'step_execution', etc.
  resource_id UUID NOT NULL,

  -- Changes (before/after state)
  old_state JSONB, -- State before action
  new_state JSONB, -- State after action
  changes JSONB,   -- Diff between old and new

  -- Context
  metadata JSONB DEFAULT '{}', -- Additional context (e.g., approval notes, rejection reason)

  -- Integrity (Hash Chain)
  previous_hash VARCHAR(64), -- SHA-256 hash of previous log entry
  current_hash VARCHAR(64),  -- SHA-256 hash of this entry (computed on insert)

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_audit_log_tenant_time ON approvals.audit_log(tenant_id, event_timestamp DESC);
CREATE INDEX idx_audit_log_actor ON approvals.audit_log(actor_id, event_timestamp DESC);
CREATE INDEX idx_audit_log_resource ON approvals.audit_log(resource_type, resource_id);
CREATE INDEX idx_audit_log_event_type ON approvals.audit_log(event_type, event_timestamp DESC);

-- Prevent updates and deletes (immutability)
CREATE OR REPLACE RULE audit_log_no_update AS
  ON UPDATE TO approvals.audit_log DO INSTEAD NOTHING;

CREATE OR REPLACE RULE audit_log_no_delete AS
  ON DELETE TO approvals.audit_log DO INSTEAD NOTHING;

-- Trigger to compute hash chain
CREATE OR REPLACE FUNCTION compute_audit_log_hash()
RETURNS TRIGGER AS $$
DECLARE
  prev_hash VARCHAR(64);
  content TEXT;
BEGIN
  -- Get hash of previous entry
  SELECT current_hash INTO prev_hash
  FROM approvals.audit_log
  WHERE tenant_id = NEW.tenant_id
  ORDER BY event_timestamp DESC, created_at DESC
  LIMIT 1;

  NEW.previous_hash := COALESCE(prev_hash, '0000000000000000000000000000000000000000000000000000000000000000');

  -- Compute hash of current entry
  content := NEW.id::TEXT || NEW.tenant_id::TEXT || NEW.event_type ||
             NEW.event_timestamp::TEXT || NEW.actor_id::TEXT ||
             NEW.resource_type || NEW.resource_id::TEXT ||
             COALESCE(NEW.old_state::TEXT, '') ||
             COALESCE(NEW.new_state::TEXT, '') ||
             NEW.previous_hash;

  NEW.current_hash := encode(digest(content, 'sha256'), 'hex');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER compute_audit_log_hash_trigger
  BEFORE INSERT ON approvals.audit_log
  FOR EACH ROW
  EXECUTE FUNCTION compute_audit_log_hash();
```

### API Endpoints

```typescript
// Get audit log
GET /api/approvals/audit-log?tenantId=xxx&startDate=2025-01-01&endDate=2025-12-31&actorId=xxx&eventType=approval.approved&limit=100&offset=0

Response:
{
  "items": [
    {
      "id": "log-uuid-123",
      "eventType": "approval.approved",
      "eventTimestamp": "2025-10-10T12:00:00Z",
      "actor": {
        "id": "user-uuid",
        "name": "Alice Smith",
        "ipAddress": "192.168.1.100"
      },
      "resource": {
        "type": "approval_item",
        "id": "approval-uuid-456"
      },
      "changes": {
        "status": {"from": "pending", "to": "approved"}
      },
      "hash": "abc123...",
      "previousHash": "def456..."
    }
  ],
  "pagination": {...}
}

// Verify audit log integrity
GET /api/approvals/audit-log/verify?tenantId=xxx&startDate=xxx&endDate=xxx

Response:
{
  "valid": true,
  "entriesChecked": 1234,
  "firstEntry": "2025-01-01T00:00:00Z",
  "lastEntry": "2025-10-10T23:59:59Z"
}

// Export audit log
GET /api/approvals/audit-log/export?tenantId=xxx&format=csv&startDate=xxx&endDate=xxx

Response: CSV file download
```

### Implementation Example

```typescript
// services/audit.ts
import crypto from 'crypto';
import { db } from '../db';

export interface AuditLogEntry {
  tenantId: string;
  eventType: string;
  actorId: string;
  actorIpAddress?: string;
  actorUserAgent?: string;
  resourceType: string;
  resourceId: string;
  oldState?: unknown;
  newState?: unknown;
  changes?: unknown;
  metadata?: Record<string, unknown>;
}

export async function logAuditEvent(entry: AuditLogEntry): Promise<void> {
  await db.query(`
    INSERT INTO approvals.audit_log
    (tenant_id, event_type, actor_id, actor_ip_address, actor_user_agent,
     resource_type, resource_id, old_state, new_state, changes, metadata)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
  `, [
    entry.tenantId,
    entry.eventType,
    entry.actorId,
    entry.actorIpAddress,
    entry.actorUserAgent,
    entry.resourceType,
    entry.resourceId,
    entry.oldState ? JSON.stringify(entry.oldState) : null,
    entry.newState ? JSON.stringify(entry.newState) : null,
    entry.changes ? JSON.stringify(entry.changes) : null,
    entry.metadata ? JSON.stringify(entry.metadata) : null,
  ]);
}

export async function verifyAuditLogIntegrity(
  tenantId: string,
  startDate: Date,
  endDate: Date
): Promise<{ valid: boolean; entriesChecked: number }> {
  const entries = await db.query(`
    SELECT id, previous_hash, current_hash,
           tenant_id, event_type, event_timestamp, actor_id,
           resource_type, resource_id, old_state, new_state
    FROM approvals.audit_log
    WHERE tenant_id = $1
      AND event_timestamp BETWEEN $2 AND $3
    ORDER BY event_timestamp ASC, created_at ASC
  `, [tenantId, startDate, endDate]);

  let previousHash = '0000000000000000000000000000000000000000000000000000000000000000';

  for (const entry of entries.rows) {
    // Verify previous_hash matches
    if (entry.previous_hash !== previousHash) {
      return { valid: false, entriesChecked: entries.rows.indexOf(entry) };
    }

    // Recompute current_hash
    const content = `${entry.id}${entry.tenant_id}${entry.event_type}${entry.event_timestamp}${entry.actor_id}${entry.resource_type}${entry.resource_id}${entry.old_state || ''}${entry.new_state || ''}${entry.previous_hash}`;
    const computedHash = crypto.createHash('sha256').update(content).digest('hex');

    if (computedHash !== entry.current_hash) {
      return { valid: false, entriesChecked: entries.rows.indexOf(entry) };
    }

    previousHash = entry.current_hash;
  }

  return { valid: true, entriesChecked: entries.rows.length };
}
```

---

## 🔒 RBAC & AUTHORIZATION

### Permission Model

```typescript
// Permissions
type Permission =
  | 'approval.view'        // View approval items
  | 'approval.create'      // Submit for approval
  | 'approval.approve'     // Approve steps
  | 'approval.reject'      // Reject steps
  | 'approval.cancel'      // Cancel approval
  | 'approval.comment'     // Add annotations
  | 'pipeline.view'        // View pipelines
  | 'pipeline.create'      // Create pipelines
  | 'pipeline.edit'        // Edit pipelines
  | 'pipeline.delete'      // Delete pipelines
  | 'audit.view'           // View audit logs
  | 'audit.export';        // Export audit logs

// Roles (predefined)
type Role =
  | 'admin'                // Full access
  | 'manager'              // Manage pipelines + approve
  | 'approver'             // Approve/reject only
  | 'submitter'            // Submit for approval
  | 'viewer';              // Read-only

// Role-Permission Mapping
const rolePermissions: Record<Role, Permission[]> = {
  admin: ['*'], // All permissions
  manager: [
    'approval.view', 'approval.create', 'approval.approve', 'approval.reject', 'approval.cancel', 'approval.comment',
    'pipeline.view', 'pipeline.create', 'pipeline.edit', 'pipeline.delete',
    'audit.view', 'audit.export'
  ],
  approver: [
    'approval.view', 'approval.approve', 'approval.reject', 'approval.comment'
  ],
  submitter: [
    'approval.view', 'approval.create', 'approval.comment'
  ],
  viewer: [
    'approval.view'
  ],
};
```

### Database Schema

```sql
-- User Roles (per tenant)
CREATE TABLE approvals.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.tenants(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  role VARCHAR(50) NOT NULL, -- 'admin', 'manager', 'approver', 'submitter', 'viewer'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  UNIQUE (tenant_id, user_id)
);

-- Resource-Level Permissions (override role defaults)
CREATE TABLE approvals.resource_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  resource_type VARCHAR(50) NOT NULL, -- 'approval_item', 'pipeline'
  resource_id UUID NOT NULL,
  subject_type VARCHAR(50) NOT NULL, -- 'user', 'team', 'role'
  subject_id VARCHAR(255) NOT NULL, -- user_id, team_id, or role name
  permissions VARCHAR(50)[] NOT NULL, -- ['approval.approve', 'approval.reject']
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id)
);

CREATE INDEX idx_resource_permissions_resource ON approvals.resource_permissions(resource_type, resource_id);
CREATE INDEX idx_resource_permissions_subject ON approvals.resource_permissions(subject_type, subject_id);
```

### Authorization Middleware

```typescript
// middleware/authorize.ts
import { FastifyRequest, FastifyReply } from 'fastify';

export async function authorize(permission: Permission) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const userId = request.user.id; // From JWT
    const tenantId = request.user.tenantId;

    // Get user role
    const userRole = await getUserRole(tenantId, userId);

    // Check if role has permission
    const rolePerms = rolePermissions[userRole];
    if (!rolePerms.includes('*') && !rolePerms.includes(permission)) {
      reply.code(403).send({
        error: {
          code: 'FORBIDDEN',
          message: `Missing permission: ${permission}`,
        },
      });
      return;
    }

    // Check resource-level permissions (if applicable)
    if (request.params.id) {
      const resourceId = request.params.id;
      const resourceType = 'approval_item'; // Or 'pipeline'

      const hasResourcePermission = await checkResourcePermission(
        tenantId,
        userId,
        resourceType,
        resourceId,
        permission
      );

      if (!hasResourcePermission) {
        reply.code(403).send({
          error: {
            code: 'FORBIDDEN',
            message: 'Access denied to this resource',
          },
        });
        return;
      }
    }
  };
}

// Usage in routes
server.post('/:id/steps/:stepIndex/approve', {
  preHandler: authorize('approval.approve'),
  handler: async (request, reply) => {
    // Implementation
  },
});
```

---

## ⏰ SLA MANAGEMENT & ESCALATION

### Requirements

- ✅ Business hours aware (skip weekends/holidays)
- ✅ Auto-escalation after deadline
- ✅ Notification cascade (email → Slack → SMS)
- ✅ SLA breach tracking and reporting

### Database Schema

```sql
-- SLA Configuration (per pipeline)
CREATE TABLE approvals.sla_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pipeline_id UUID NOT NULL REFERENCES approvals.pipelines(id) ON DELETE CASCADE,
  step_index INTEGER NOT NULL,

  -- SLA Duration
  sla_hours INTEGER NOT NULL, -- Business hours

  -- Escalation Rules
  escalation_rules JSONB NOT NULL,
  -- Example:
  -- [
  --   {"afterHours": 24, "action": "notify", "recipients": ["manager@example.com"]},
  --   {"afterHours": 48, "action": "reassign", "to": "backup-approver-id"}
  -- ]

  -- Business Hours
  business_hours JSONB DEFAULT '{"start": "09:00", "end": "17:00", "timezone": "America/New_York"}',
  exclude_weekends BOOLEAN DEFAULT TRUE,
  exclude_holidays BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (pipeline_id, step_index)
);

-- SLA Breaches (tracking)
CREATE TABLE approvals.sla_breaches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  approval_item_id UUID NOT NULL REFERENCES approvals.approval_items(id) ON DELETE CASCADE,
  step_execution_id UUID NOT NULL REFERENCES approvals.step_executions(id) ON DELETE CASCADE,

  -- Breach Info
  deadline TIMESTAMPTZ NOT NULL,
  breached_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  breach_duration_hours INTEGER, -- How many hours overdue

  -- Actions Taken
  escalation_actions JSONB, -- Log of escalation actions taken

  -- Resolution
  resolved_at TIMESTAMPTZ,
  resolution_type VARCHAR(50), -- 'approved', 'rejected', 'cancelled', 'force_closed'

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sla_breaches_approval ON approvals.sla_breaches(approval_item_id);
CREATE INDEX idx_sla_breaches_unresolved ON approvals.sla_breaches(breached_at DESC) WHERE resolved_at IS NULL;
```

### SLA Calculation (Business Hours)

```typescript
// services/sla.ts
import { addBusinessDays, isWeekend, isHoliday } from 'date-fns';

export interface SLAConfig {
  slaHours: number;
  businessHours: {
    start: string; // '09:00'
    end: string;   // '17:00'
    timezone: string;
  };
  excludeWeekends: boolean;
  excludeHolidays: boolean;
}

export function calculateDeadline(
  startDate: Date,
  slaConfig: SLAConfig
): Date {
  const { slaHours, businessHours, excludeWeekends, excludeHolidays } = slaConfig;

  let remainingHours = slaHours;
  let currentDate = new Date(startDate);

  while (remainingHours > 0) {
    // Skip weekends
    if (excludeWeekends && isWeekend(currentDate)) {
      currentDate = addBusinessDays(currentDate, 1);
      continue;
    }

    // Skip holidays
    if (excludeHolidays && isHoliday(currentDate)) {
      currentDate = addBusinessDays(currentDate, 1);
      continue;
    }

    // Add business hours
    const hoursInDay = calculateBusinessHoursInDay(currentDate, businessHours);
    const hoursToAdd = Math.min(remainingHours, hoursInDay);

    currentDate = addHours(currentDate, hoursToAdd);
    remainingHours -= hoursToAdd;

    if (remainingHours > 0) {
      currentDate = addBusinessDays(currentDate, 1);
      currentDate = setBusinessHourStart(currentDate, businessHours);
    }
  }

  return currentDate;
}
```

### Escalation Job (Cron)

```typescript
// jobs/escalation.ts
import cron from 'node-cron';

// Run every 15 minutes
cron.schedule('*/15 * * * *', async () => {
  console.log('Running SLA escalation check...');

  // Find overdue approvals
  const overdueApprovals = await db.query(`
    SELECT ai.id, ai.title, se.deadline, se.assigned_to, sc.escalation_rules
    FROM approvals.approval_items ai
    JOIN approvals.step_executions se ON se.approval_item_id = ai.id
    JOIN approvals.sla_configs sc ON sc.pipeline_id = ai.pipeline_id AND sc.step_index = se.step_index
    WHERE ai.status IN ('pending', 'in_review')
      AND se.status = 'in_review'
      AND se.deadline < NOW()
      AND NOT EXISTS (
        SELECT 1 FROM approvals.sla_breaches sb
        WHERE sb.step_execution_id = se.id AND sb.resolved_at IS NULL
      )
  `);

  for (const approval of overdueApprovals.rows) {
    const hoursOverdue = Math.floor((Date.now() - new Date(approval.deadline).getTime()) / (1000 * 60 * 60));

    // Log SLA breach
    await db.query(`
      INSERT INTO approvals.sla_breaches
      (approval_item_id, step_execution_id, deadline, breach_duration_hours)
      VALUES ($1, $2, $3, $4)
    `, [approval.id, approval.step_execution_id, approval.deadline, hoursOverdue]);

    // Execute escalation rules
    const rules = approval.escalation_rules as EscalationRule[];
    for (const rule of rules) {
      if (hoursOverdue >= rule.afterHours) {
        await executeEscalation(approval, rule);
      }
    }
  }

  console.log(`Processed ${overdueApprovals.rows.length} overdue approvals`);
});

async function executeEscalation(approval: any, rule: EscalationRule): Promise<void> {
  if (rule.action === 'notify') {
    // Send notification to recipients
    await sendNotification({
      type: 'sla_breach',
      recipients: rule.recipients,
      subject: `SLA Breach: ${approval.title}`,
      body: `Approval "${approval.title}" is ${rule.afterHours} hours overdue.`,
    });
  } else if (rule.action === 'reassign') {
    // Reassign to backup approver
    await reassignApproval(approval.id, rule.to);
    await sendNotification({
      type: 'reassignment',
      recipients: [rule.to],
      subject: `Approval Reassigned: ${approval.title}`,
      body: `You have been assigned approval "${approval.title}" due to SLA breach.`,
    });
  }
}
```

---

## 🔔 WEBHOOK SYSTEM (SIGNED)

### Requirements

- ✅ Event-driven notifications
- ✅ HMAC signature for verification
- ✅ Retry with exponential backoff
- ✅ Dead Letter Queue (DLQ)
- ✅ Webhook logs for debugging

### Database Schema

```sql
-- Webhook Subscriptions
CREATE TABLE approvals.webhook_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.tenants(id),

  -- Webhook Info
  name VARCHAR(255) NOT NULL,
  url VARCHAR(1000) NOT NULL,
  secret_key VARCHAR(255) NOT NULL, -- For HMAC signature

  -- Events to subscribe
  events VARCHAR(50)[] NOT NULL, -- ['approval.created', 'approval.approved', 'approval.rejected', ...]

  -- Retry Config
  max_retries INTEGER DEFAULT 3,
  retry_backoff_seconds INTEGER DEFAULT 60, -- Exponential: 60s, 120s, 240s

  -- Status
  enabled BOOLEAN DEFAULT TRUE,
  last_success_at TIMESTAMPTZ,
  last_failure_at TIMESTAMPTZ,
  consecutive_failures INTEGER DEFAULT 0,

  -- Auto-disable after N failures
  auto_disable_after_failures INTEGER DEFAULT 10,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id)
);

CREATE INDEX idx_webhook_subscriptions_tenant ON approvals.webhook_subscriptions(tenant_id);
CREATE INDEX idx_webhook_subscriptions_enabled ON approvals.webhook_subscriptions(enabled) WHERE enabled = TRUE;

-- Webhook Delivery Logs
CREATE TABLE approvals.webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES approvals.webhook_subscriptions(id) ON DELETE CASCADE,

  -- Event Info
  event_type VARCHAR(50) NOT NULL,
  event_id UUID NOT NULL, -- ID of approval_item or other resource
  payload JSONB NOT NULL,

  -- Delivery Info
  attempt_number INTEGER DEFAULT 1,
  response_status INTEGER,
  response_body TEXT,
  response_time_ms INTEGER,

  -- Error Info
  error_message TEXT,

  -- Status
  status VARCHAR(50) NOT NULL, -- 'pending', 'success', 'failed', 'dlq'

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivered_at TIMESTAMPTZ
);

CREATE INDEX idx_webhook_deliveries_subscription ON approvals.webhook_deliveries(subscription_id, created_at DESC);
CREATE INDEX idx_webhook_deliveries_status ON approvals.webhook_deliveries(status, created_at DESC);
CREATE INDEX idx_webhook_deliveries_event ON approvals.webhook_deliveries(event_type, event_id);
```

### Webhook Service

```typescript
// services/webhook.ts
import crypto from 'crypto';
import axios from 'axios';

export interface WebhookEvent {
  type: string;
  timestamp: string;
  data: unknown;
}

export async function sendWebhook(
  subscriptionId: string,
  event: WebhookEvent,
  attemptNumber = 1
): Promise<void> {
  // Get subscription
  const subscription = await db.query(`
    SELECT * FROM approvals.webhook_subscriptions
    WHERE id = $1 AND enabled = TRUE
  `, [subscriptionId]);

  if (subscription.rows.length === 0) {
    console.log(`Webhook subscription ${subscriptionId} not found or disabled`);
    return;
  }

  const sub = subscription.rows[0];

  // Check if event is subscribed
  if (!sub.events.includes(event.type)) {
    return;
  }

  // Prepare payload
  const payload = JSON.stringify(event);

  // Compute HMAC signature
  const signature = crypto
    .createHmac('sha256', sub.secret_key)
    .update(payload)
    .digest('hex');

  // Send webhook
  const startTime = Date.now();
  let status = 'success';
  let responseStatus: number | undefined;
  let responseBody: string | undefined;
  let errorMessage: string | undefined;

  try {
    const response = await axios.post(sub.url, event, {
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Signature': signature,
        'X-Webhook-Event': event.type,
        'X-Webhook-Timestamp': event.timestamp,
      },
      timeout: 30000, // 30s timeout
    });

    responseStatus = response.status;
    responseBody = JSON.stringify(response.data);

    // Update subscription (success)
    await db.query(`
      UPDATE approvals.webhook_subscriptions
      SET last_success_at = NOW(), consecutive_failures = 0
      WHERE id = $1
    `, [subscriptionId]);

  } catch (error: any) {
    status = 'failed';
    responseStatus = error.response?.status;
    responseBody = JSON.stringify(error.response?.data);
    errorMessage = error.message;

    // Update subscription (failure)
    await db.query(`
      UPDATE approvals.webhook_subscriptions
      SET last_failure_at = NOW(), consecutive_failures = consecutive_failures + 1
      WHERE id = $1
    `, [subscriptionId]);

    // Auto-disable after threshold
    if (sub.consecutive_failures + 1 >= sub.auto_disable_after_failures) {
      await db.query(`
        UPDATE approvals.webhook_subscriptions
        SET enabled = FALSE
        WHERE id = $1
      `, [subscriptionId]);

      console.log(`Webhook subscription ${subscriptionId} auto-disabled after ${sub.consecutive_failures + 1} failures`);
    }

    // Retry with exponential backoff
    if (attemptNumber < sub.max_retries) {
      const delaySeconds = sub.retry_backoff_seconds * Math.pow(2, attemptNumber - 1);
      setTimeout(() => {
        sendWebhook(subscriptionId, event, attemptNumber + 1);
      }, delaySeconds * 1000);
    } else {
      // Move to DLQ
      status = 'dlq';
      console.log(`Webhook delivery failed after ${attemptNumber} attempts, moved to DLQ`);
    }
  }

  const responseTimeMs = Date.now() - startTime;

  // Log delivery
  await db.query(`
    INSERT INTO approvals.webhook_deliveries
    (subscription_id, event_type, event_id, payload, attempt_number,
     response_status, response_body, response_time_ms, error_message, status, delivered_at)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
  `, [
    subscriptionId,
    event.type,
    (event.data as any).id,
    payload,
    attemptNumber,
    responseStatus,
    responseBody,
    responseTimeMs,
    errorMessage,
    status,
    status === 'success' ? new Date() : null,
  ]);
}

// Trigger webhook on approval event
export async function triggerWebhook(eventType: string, data: unknown): Promise<void> {
  const tenantId = (data as any).tenantId;

  // Get all subscriptions for this event
  const subscriptions = await db.query(`
    SELECT id FROM approvals.webhook_subscriptions
    WHERE tenant_id = $1 AND enabled = TRUE AND $2 = ANY(events)
  `, [tenantId, eventType]);

  // Send webhooks in parallel
  const promises = subscriptions.rows.map((sub) =>
    sendWebhook(sub.id, {
      type: eventType,
      timestamp: new Date().toISOString(),
      data,
    })
  );

  await Promise.allSettled(promises);
}
```

### Webhook Verification (Client Side)

```typescript
// Example: How clients verify webhook signature
function verifyWebhookSignature(
  payload: string,
  signature: string,
  secretKey: string
): boolean {
  const computedSignature = crypto
    .createHmac('sha256', secretKey)
    .update(payload)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(computedSignature)
  );
}

// Express middleware example
app.post('/webhooks/approvals', (req, res) => {
  const signature = req.headers['x-webhook-signature'] as string;
  const payload = JSON.stringify(req.body);

  if (!verifyWebhookSignature(payload, signature, WEBHOOK_SECRET)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  // Process webhook
  console.log('Webhook received:', req.body);
  res.status(200).json({ received: true });
});
```

---

## 🔄 IDEMPOTENCY & RELIABILITY

### Idempotency Keys

```sql
-- Idempotency Keys Table
CREATE TABLE approvals.idempotency_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Key
  idempotency_key VARCHAR(255) NOT NULL,

  -- Request Info
  endpoint VARCHAR(255) NOT NULL, -- '/api/approvals'
  method VARCHAR(10) NOT NULL,    -- 'POST'
  request_body JSONB,

  -- Response Cache
  response_status INTEGER,
  response_body JSONB,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),

  UNIQUE (tenant_id, idempotency_key)
);

CREATE INDEX idx_idempotency_keys_tenant_key ON approvals.idempotency_keys(tenant_id, idempotency_key);
CREATE INDEX idx_idempotency_keys_expires ON approvals.idempotency_keys(expires_at) WHERE expires_at < NOW();

-- Cleanup job (delete expired keys)
CREATE OR REPLACE FUNCTION cleanup_expired_idempotency_keys()
RETURNS void AS $$
BEGIN
  DELETE FROM approvals.idempotency_keys
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (every hour)
-- Note: Requires pg_cron extension
-- SELECT cron.schedule('cleanup-idempotency-keys', '0 * * * *', 'SELECT cleanup_expired_idempotency_keys()');
```

### Idempotency Middleware

```typescript
// middleware/idempotency.ts
import { FastifyRequest, FastifyReply } from 'fastify';

export async function idempotency(
  request: FastifyRequest,
  reply: FastifyReply
) {
  const idempotencyKey = request.headers['idempotency-key'] as string;

  if (!idempotencyKey) {
    // Idempotency key not provided, skip
    return;
  }

  const tenantId = request.user.tenantId;

  // Check if key exists
  const existing = await db.query(`
    SELECT response_status, response_body
    FROM approvals.idempotency_keys
    WHERE tenant_id = $1 AND idempotency_key = $2
  `, [tenantId, idempotencyKey]);

  if (existing.rows.length > 0) {
    // Return cached response
    const cached = existing.rows[0];
    reply.code(cached.response_status).send(cached.response_body);
    return reply;
  }

  // Store idempotency key (will be updated with response after handler)
  await db.query(`
    INSERT INTO approvals.idempotency_keys
    (tenant_id, idempotency_key, endpoint, method, request_body)
    VALUES ($1, $2, $3, $4, $5)
    ON CONFLICT (tenant_id, idempotency_key) DO NOTHING
  `, [tenantId, idempotencyKey, request.url, request.method, request.body]);

  // Attach hook to save response
  reply.addHook('onSend', async (request, reply, payload) => {
    await db.query(`
      UPDATE approvals.idempotency_keys
      SET response_status = $1, response_body = $2
      WHERE tenant_id = $3 AND idempotency_key = $4
    `, [reply.statusCode, payload, tenantId, idempotencyKey]);
  });
}

// Usage in routes
server.post('/api/approvals', {
  preHandler: [authenticate, idempotency],
  handler: async (request, reply) => {
    // Implementation
  },
});
```

---

## 🚦 RATE LIMITING & QUOTAS

### Rate Limit Configuration

```typescript
// config/rate-limits.ts
export const rateLimits = {
  global: {
    maxRequests: 10000,
    windowMs: 60000, // 1 minute
  },
  perTenant: {
    maxRequests: 1000,
    windowMs: 60000, // 1 minute
  },
  perUser: {
    maxRequests: 100,
    windowMs: 60000, // 1 minute
  },
  perEndpoint: {
    'POST /api/approvals': {
      maxRequests: 50,
      windowMs: 60000,
    },
    'POST /api/approvals/:id/steps/:index/approve': {
      maxRequests: 100,
      windowMs: 60000,
    },
  },
};
```

### Rate Limiting Middleware (Redis)

```typescript
// middleware/rate-limit.ts
import Redis from 'ioredis';
import { FastifyRequest, FastifyReply } from 'fastify';

const redis = new Redis(process.env.REDIS_URL);

export async function rateLimit(
  request: FastifyRequest,
  reply: FastifyReply
) {
  const tenantId = request.user.tenantId;
  const userId = request.user.id;
  const endpoint = `${request.method} ${request.routerPath}`;

  // Check tenant limit
  const tenantKey = `rate-limit:tenant:${tenantId}`;
  const tenantCount = await redis.incr(tenantKey);
  if (tenantCount === 1) {
    await redis.expire(tenantKey, 60); // 1 minute
  }

  if (tenantCount > rateLimits.perTenant.maxRequests) {
    reply.code(429).send({
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Tenant rate limit exceeded',
        retryAfter: await redis.ttl(tenantKey),
      },
    });
    return reply;
  }

  // Check user limit
  const userKey = `rate-limit:user:${userId}`;
  const userCount = await redis.incr(userKey);
  if (userCount === 1) {
    await redis.expire(userKey, 60);
  }

  if (userCount > rateLimits.perUser.maxRequests) {
    reply.code(429).send({
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'User rate limit exceeded',
        retryAfter: await redis.ttl(userKey),
      },
    });
    return reply;
  }

  // Set rate limit headers
  reply.header('X-RateLimit-Limit', rateLimits.perUser.maxRequests.toString());
  reply.header('X-RateLimit-Remaining', (rateLimits.perUser.maxRequests - userCount).toString());
  reply.header('X-RateLimit-Reset', (Math.floor(Date.now() / 1000) + await redis.ttl(userKey)).toString());
}
```

---

## 📊 OBSERVABILITY & MONITORING

### Prometheus Metrics

```typescript
// middleware/metrics.ts
import promClient from 'prom-client';

// Create registry
const register = new promClient.Registry();

// Default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics({ register });

// Custom metrics
export const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
  registers: [register],
});

export const httpRequestTotal = new promClient.Counter({
  name: 'http_request_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

export const approvalsDuration = new promClient.Histogram({
  name: 'approvals_duration_hours',
  help: 'Time from submission to resolution',
  labelNames: ['status', 'pipeline'],
  buckets: [1, 6, 12, 24, 48, 72, 168], // hours
  registers: [register],
});

export const approvalsTotal = new promClient.Counter({
  name: 'approvals_total',
  help: 'Total approvals',
  labelNames: ['status', 'resource_type'],
  registers: [register],
});

export const slaBreachesTotal = new promClient.Counter({
  name: 'sla_breaches_total',
  help: 'Total SLA breaches',
  labelNames: ['pipeline'],
  registers: [register],
});

// Metrics endpoint
server.get('/metrics', async (request, reply) => {
  reply.type('text/plain').send(await register.metrics());
});

// Metrics middleware
export function metricsMiddleware(
  request: FastifyRequest,
  reply: FastifyReply,
  done: () => void
) {
  const startTime = Date.now();

  reply.addHook('onSend', async () => {
    const duration = (Date.now() - startTime) / 1000;
    const labels = {
      method: request.method,
      route: request.routerPath,
      status_code: reply.statusCode.toString(),
    };

    httpRequestDuration.observe(labels, duration);
    httpRequestTotal.inc(labels);
  });

  done();
}
```

### Grafana Dashboard (JSON)

```json
{
  "dashboard": {
    "title": "Approval Service Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_request_total[5m])"
          }
        ]
      },
      {
        "title": "Request Duration (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "Approval Duration",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(approvals_duration_hours_bucket[1h]))"
          }
        ]
      },
      {
        "title": "SLA Breaches",
        "targets": [
          {
            "expr": "rate(sla_breaches_total[1h])"
          }
        ]
      }
    ]
  }
}
```

### Distributed Tracing (OpenTelemetry)

```typescript
// tracing.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';

const sdk = new NodeSDK({
  traceExporter: new JaegerExporter({
    endpoint: 'http://localhost:14268/api/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

// Usage: Traces are automatically generated for HTTP requests, DB queries, etc.
```

---

## 🔐 SECURITY HARDENING

### Input Validation (Zod)

```typescript
// schemas/approvals.ts
import { z } from 'zod';

export const CreateApprovalSchema = z.object({
  resourceType: z.enum(['dam_asset', 'cms_page', 'cms_site', 'text_document', 'quotation', 'order', 'product', 'mockup']),
  resourceId: z.string().uuid(),
  resourceUrl: z.string().url().optional(),
  title: z.string().min(1).max(255),
  description: z.string().max(1000).optional(),
  previewUrl: z.string().url().optional(),
  previewType: z.enum(['image', 'video', 'pdf', 'text', 'website']).optional(),
  deadline: z.string().datetime().optional(),
  metadata: z.record(z.unknown()).optional(),
});

// Usage in routes
server.post('/api/approvals', {
  handler: async (request, reply) => {
    const result = CreateApprovalSchema.safeParse(request.body);
    if (!result.success) {
      reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request body',
          details: result.error.issues,
        },
      });
      return;
    }

    const data = result.data;
    // Implementation
  },
});
```

### SQL Injection Prevention

```typescript
// ✅ GOOD: Parameterized queries
await db.query(`
  SELECT * FROM approvals.approval_items
  WHERE tenant_id = $1 AND status = $2
`, [tenantId, status]);

// ❌ BAD: String concatenation (vulnerable!)
await db.query(`
  SELECT * FROM approvals.approval_items
  WHERE tenant_id = '${tenantId}' AND status = '${status}'
`);
```

### Secrets Management

```typescript
// config/secrets.ts
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const client = new SecretsManagerClient({ region: 'us-east-1' });

export async function getSecret(secretName: string): Promise<string> {
  const command = new GetSecretValueCommand({ SecretId: secretName });
  const response = await client.send(command);
  return response.SecretString || '';
}

// Usage
const jwtSecret = await getSecret('approval-service/jwt-secret');
const webhookSecret = await getSecret('approval-service/webhook-secret');
```

---

## 🎯 PERFORMANCE TARGETS

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| **API Latency (p50)** | < 100ms | Prometheus histogram |
| **API Latency (p95)** | < 300ms | Prometheus histogram |
| **API Latency (p99)** | < 500ms | Prometheus histogram |
| **Database Query Time (p95)** | < 50ms | Query logging |
| **Throughput** | 1000 req/s | Load test (k6) |
| **Concurrent Users** | 10,000 | Load test |
| **Uptime** | 99.9% | UptimeRobot |
| **Error Rate** | < 0.1% | Error tracking (Sentry) |
| **TTFB (Time to First Byte)** | < 200ms | Frontend monitoring |

---

## 📅 IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Weeks 1-2)
- [ ] Audit log system (immutable + hash chain)
- [ ] RBAC implementation
- [ ] Rate limiting (Redis)
- [ ] Idempotency keys

### Phase 2: SLA & Webhooks (Weeks 3-4)
- [ ] SLA calculation (business hours)
- [ ] Escalation job (cron)
- [ ] Webhook system (signed)
- [ ] Dead Letter Queue

### Phase 3: Observability (Weeks 5-6)
- [ ] Prometheus metrics
- [ ] Grafana dashboards
- [ ] Distributed tracing (OpenTelemetry)
- [ ] Error tracking (Sentry)

### Phase 4: Testing & Hardening (Weeks 7-8)
- [ ] Unit tests (80%+ coverage)
- [ ] Integration tests
- [ ] Load tests (k6)
- [ ] Security audit
- [ ] Penetration testing

---

## ✅ SUCCESS CRITERIA

- [ ] All audit log queries return results in < 1s
- [ ] RBAC checks complete in < 10ms
- [ ] SLA breaches detected within 5 minutes
- [ ] Webhooks delivered with 99%+ success rate
- [ ] Rate limiting prevents abuse
- [ ] Idempotency prevents duplicate operations
- [ ] Metrics visible in Grafana
- [ ] Test coverage > 80%
- [ ] Load test passes (1000 req/s sustained for 10 minutes)
- [ ] Security scan passes (OWASP ZAP, no critical vulnerabilities)

---

**Document Owner:** Platform Team
**Review Cycle:** Monthly
**Next Review:** After DAM MVP completion

---

## 📎 APPENDIX

### Useful Commands

```bash
# Start service with metrics
pnpm dev

# Run load test
k6 run tests/load/approval-flow.js

# Check metrics
curl http://localhost:4010/metrics

# Verify audit log integrity
psql -h localhost -U ewh -d ewh_master -c "SELECT approvals.verify_audit_log_integrity('tenant-uuid', '2025-01-01', '2025-12-31')"

# Export audit log
curl "http://localhost:4010/api/approvals/audit-log/export?tenantId=xxx&format=csv&startDate=2025-01-01&endDate=2025-12-31" > audit.csv
```

### Related Documentation

- [APPROVAL_SERVICE_SPEC.md](APPROVAL_SERVICE_SPEC.md) - Base specification
- [ENTERPRISE_DAM_ROADMAP.md](ENTERPRISE_DAM_ROADMAP.md) - Overall roadmap
- [DAM_APPROVAL_WORKFLOWS.md](DAM_APPROVAL_WORKFLOWS.md) - Workflow patterns
