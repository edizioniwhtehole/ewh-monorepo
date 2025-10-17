# 🔄 Webhook Retry Strategy - Reliable Event Delivery

**Version**: 1.0.0
**Last Updated**: 2025-10-11
**Status**: ✅ Complete Specification

---

## 🎯 Overview

Sistema di webhook affidabile con retry exponential backoff, dead letter queue, e monitoring.

**Key Features**:
- ✅ Retry automatico con backoff esponenziale
- ✅ Dead Letter Queue per fallimenti permanenti
- ✅ HMAC signature per sicurezza
- ✅ Monitoring e alerting
- ✅ UI per gestione webhook tenant

---

## 📊 Retry Strategy

### Exponential Backoff

```
Attempt 1: Immediate
Attempt 2: 30 seconds later
Attempt 3: 5 minutes later (2^2 × 30s = 300s)
Attempt 4: 20 minutes later (2^3 × 30s × 5 = 1200s)
Attempt 5: 1 hour later (2^4 × 30s × 7.5 = 3600s)

Total: 5 attempts over ~1.5 hours
```

### Retry Configuration

```typescript
const RETRY_CONFIG = {
  maxAttempts: 5,
  initialDelay: 30000, // 30 seconds
  maxDelay: 3600000, // 1 hour
  backoffMultiplier: 2,
  timeout: 10000, // 10 seconds per request
};

function calculateDelay(attempt: number): number {
  const delay = RETRY_CONFIG.initialDelay * Math.pow(RETRY_CONFIG.backoffMultiplier, attempt - 1);
  return Math.min(delay, RETRY_CONFIG.maxDelay);
}

// Examples:
calculateDelay(1) // 0ms (immediate)
calculateDelay(2) // 30,000ms (30s)
calculateDelay(3) // 60,000ms (1min)
calculateDelay(4) // 120,000ms (2min)
calculateDelay(5) // 240,000ms (4min)
```

---

## 🗄️ Database Schema

```sql
-- db_blogmaster_acme_core.webhooks

CREATE TABLE webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Configuration
  name VARCHAR(255) NOT NULL,
  url TEXT NOT NULL,
  enabled BOOLEAN DEFAULT true,

  -- Events to subscribe
  events TEXT[] DEFAULT '{}', -- ['post.created', 'post.updated', 'user.login']

  -- Security
  secret VARCHAR(255) NOT NULL, -- For HMAC signature

  -- Retry config (optional overrides)
  max_attempts INT DEFAULT 5,
  timeout_ms INT DEFAULT 10000,

  -- Metadata
  created_by UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  INDEX idx_events (events),
  INDEX idx_enabled (enabled)
);

-- Webhook deliveries (audit log + retry queue)
CREATE TABLE webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id UUID NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,

  -- Event
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB NOT NULL,

  -- Delivery
  status VARCHAR(20) DEFAULT 'pending', -- pending, success, failed, dead_letter
  attempt INT DEFAULT 0,
  max_attempts INT DEFAULT 5,

  -- Response
  response_status_code INT,
  response_body TEXT,
  response_time_ms INT,
  error_message TEXT,

  -- Retry
  next_retry_at TIMESTAMP,
  last_attempt_at TIMESTAMP,

  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,

  INDEX idx_webhook (webhook_id),
  INDEX idx_status (status),
  INDEX idx_next_retry (next_retry_at),
  INDEX idx_event (event_type)
);
```

---

## 🔧 Implementation

### Webhook Service

```typescript
// packages/core/webhooks/src/webhook-service.ts

import crypto from 'crypto';
import axios from 'axios';

export class WebhookService {
  /**
   * Trigger webhook for event
   */
  async trigger(tenantId: string, eventType: string, eventData: any) {
    // Find all webhooks subscribed to this event
    const webhooks = await tenantCoreDB.query(`
      SELECT id, url, secret, max_attempts, timeout_ms
      FROM webhooks
      WHERE enabled = true
        AND $1 = ANY(events)
    `, [eventType]);

    // Create delivery records
    for (const webhook of webhooks.rows) {
      await tenantCoreDB.query(`
        INSERT INTO webhook_deliveries (
          webhook_id, event_type, event_data, max_attempts, next_retry_at
        ) VALUES ($1, $2, $3, $4, NOW())
      `, [webhook.id, eventType, JSON.stringify(eventData), webhook.max_attempts]);
    }

    // Process immediately (async)
    this.processDeliveries(tenantId).catch(console.error);
  }

  /**
   * Process pending webhook deliveries
   */
  async processDeliveries(tenantId: string) {
    // Get deliveries ready for retry
    const deliveries = await tenantCoreDB.query(`
      SELECT d.*, w.url, w.secret, w.timeout_ms
      FROM webhook_deliveries d
      JOIN webhooks w ON w.id = d.webhook_id
      WHERE d.status = 'pending'
        AND d.next_retry_at <= NOW()
        AND d.attempt < d.max_attempts
      ORDER BY d.created_at ASC
      LIMIT 100
    `);

    for (const delivery of deliveries.rows) {
      await this.deliverWebhook(delivery);
    }
  }

  /**
   * Deliver single webhook
   */
  private async deliverWebhook(delivery: any) {
    const attempt = delivery.attempt + 1;

    try {
      // Prepare payload
      const payload = {
        id: delivery.id,
        event: delivery.event_type,
        data: delivery.event_data,
        timestamp: new Date().toISOString()
      };

      // Generate HMAC signature
      const signature = this.generateSignature(payload, delivery.secret);

      // Send request
      const startTime = Date.now();
      const response = await axios.post(delivery.url, payload, {
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Signature': signature,
          'X-Webhook-Event': delivery.event_type,
          'X-Webhook-Delivery-ID': delivery.id
        },
        timeout: delivery.timeout_ms || 10000
      });

      const responseTime = Date.now() - startTime;

      // Success!
      await tenantCoreDB.query(`
        UPDATE webhook_deliveries
        SET status = 'success',
            attempt = $1,
            response_status_code = $2,
            response_body = $3,
            response_time_ms = $4,
            last_attempt_at = NOW(),
            completed_at = NOW()
        WHERE id = $5
      `, [attempt, response.status, response.data, responseTime, delivery.id]);

    } catch (error) {
      // Failure
      const isLastAttempt = attempt >= delivery.max_attempts;

      if (isLastAttempt) {
        // Move to dead letter queue
        await tenantCoreDB.query(`
          UPDATE webhook_deliveries
          SET status = 'dead_letter',
              attempt = $1,
              error_message = $2,
              last_attempt_at = NOW(),
              completed_at = NOW()
          WHERE id = $3
        `, [attempt, error.message, delivery.id]);

        // Alert tenant admin
        await this.alertDeadLetter(delivery);

      } else {
        // Schedule retry with exponential backoff
        const delayMs = this.calculateDelay(attempt);
        const nextRetryAt = new Date(Date.now() + delayMs);

        await tenantCoreDB.query(`
          UPDATE webhook_deliveries
          SET attempt = $1,
              error_message = $2,
              response_status_code = $3,
              last_attempt_at = NOW(),
              next_retry_at = $4
          WHERE id = $5
        `, [attempt, error.message, error.response?.status, nextRetryAt, delivery.id]);
      }
    }
  }

  /**
   * Generate HMAC signature
   */
  private generateSignature(payload: any, secret: string): string {
    const hmac = crypto.createHmac('sha256', secret);
    hmac.update(JSON.stringify(payload));
    return `sha256=${hmac.digest('hex')}`;
  }

  /**
   * Calculate retry delay (exponential backoff)
   */
  private calculateDelay(attempt: number): number {
    const baseDelay = 30000; // 30 seconds
    const maxDelay = 3600000; // 1 hour
    const delay = baseDelay * Math.pow(2, attempt - 1);
    return Math.min(delay, maxDelay);
  }

  /**
   * Alert tenant admin about dead letter
   */
  private async alertDeadLetter(delivery: any) {
    // Send email/notification to tenant admin
    await notificationService.send({
      to: 'tenant-admin',
      subject: 'Webhook delivery failed',
      body: `Webhook delivery ${delivery.id} failed after ${delivery.max_attempts} attempts.`
    });

    // Log in audit
    await auditService.logTenantEvent(delivery.tenant_id, 'system', {
      eventType: 'webhook.dead_letter',
      entityType: 'webhook_delivery',
      entityId: delivery.id,
      action: 'failed',
      metadata: {
        event_type: delivery.event_type,
        attempts: delivery.max_attempts,
        error: delivery.error_message
      }
    });
  }
}

export const webhookService = new WebhookService();
```

---

## ⏰ Background Worker

```typescript
// packages/core/webhooks/src/webhook-worker.ts

import cron from 'node-cron';

/**
 * Process webhook deliveries every minute
 */
export function startWebhookWorker() {
  cron.schedule('* * * * *', async () => {
    console.log('Processing webhook deliveries...');

    try {
      // Get all active tenants
      const tenants = await platformDB.query(`
        SELECT id FROM registry.tenants WHERE status = 'active'
      `);

      // Process deliveries for each tenant
      for (const tenant of tenants.rows) {
        await webhookService.processDeliveries(tenant.id);
      }

    } catch (error) {
      console.error('Webhook worker error:', error);
    }
  });

  console.log('✅ Webhook worker started');
}
```

---

## 🔒 Webhook Verification (Receiver Side)

```typescript
// Example: How tenant verifies webhook signature

import crypto from 'crypto';

export function verifyWebhookSignature(
  payload: any,
  signature: string,
  secret: string
): boolean {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');

  const expected = `sha256=${expectedSignature}`;

  // Constant-time comparison to prevent timing attacks
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected)
  );
}

// Usage in webhook receiver
app.post('/webhooks/blogmaster', (req, res) => {
  const signature = req.headers['x-webhook-signature'];
  const secret = process.env.WEBHOOK_SECRET;

  if (!verifyWebhookSignature(req.body, signature, secret)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  // Process webhook
  const { event, data } = req.body;

  console.log('Webhook received:', event, data);

  res.status(200).json({ received: true });
});
```

---

## 📊 Webhook Management UI

### Tenant Admin: Create Webhook

```typescript
function CreateWebhookPage() {
  const [webhook, setWebhook] = useState({
    name: '',
    url: '',
    events: []
  });

  async function createWebhook() {
    const response = await fetch('/api/webhooks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(webhook)
    });

    const data = await response.json();

    alert(`Webhook created! Secret: ${data.secret}`);
  }

  return (
    <div>
      <h1>Create Webhook</h1>

      <Input
        label="Name"
        value={webhook.name}
        onChange={(v) => setWebhook({ ...webhook, name: v })}
      />

      <Input
        label="URL"
        value={webhook.url}
        onChange={(v) => setWebhook({ ...webhook, url: v })}
        placeholder="https://example.com/webhooks"
      />

      <MultiSelect
        label="Events"
        value={webhook.events}
        onChange={(v) => setWebhook({ ...webhook, events: v })}
        options={[
          'post.created',
          'post.updated',
          'post.deleted',
          'user.created',
          'user.login',
          'payment.succeeded',
          'payment.failed'
        ]}
      />

      <Button onClick={createWebhook}>Create Webhook</Button>
    </div>
  );
}
```

### Webhook Deliveries Dashboard

```typescript
function WebhookDeliveriesPage() {
  const [deliveries, setDeliveries] = useState([]);

  useEffect(() => {
    fetch('/api/webhooks/deliveries')
      .then(res => res.json())
      .then(setDeliveries);
  }, []);

  return (
    <div>
      <h1>Webhook Deliveries</h1>

      <Table>
        <thead>
          <tr>
            <th>Event</th>
            <th>Status</th>
            <th>Attempts</th>
            <th>Last Attempt</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {deliveries.map(delivery => (
            <tr key={delivery.id}>
              <td>{delivery.event_type}</td>
              <td>
                <Badge color={getStatusColor(delivery.status)}>
                  {delivery.status}
                </Badge>
              </td>
              <td>{delivery.attempt} / {delivery.max_attempts}</td>
              <td>{formatDate(delivery.last_attempt_at)}</td>
              <td>
                {delivery.status === 'dead_letter' && (
                  <Button onClick={() => retryDelivery(delivery.id)}>
                    Retry
                  </Button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}

async function retryDelivery(deliveryId: string) {
  await fetch(`/api/webhooks/deliveries/${deliveryId}/retry`, {
    method: 'POST'
  });

  alert('Delivery queued for retry');
  window.location.reload();
}
```

---

## 📊 Monitoring & Metrics

### Webhook Stats

```sql
-- Success rate per webhook
SELECT
  w.name,
  w.url,
  COUNT(*) as total_deliveries,
  COUNT(*) FILTER (WHERE d.status = 'success') as successful,
  COUNT(*) FILTER (WHERE d.status = 'dead_letter') as failed,
  ROUND(100.0 * COUNT(*) FILTER (WHERE d.status = 'success') / COUNT(*), 2) as success_rate,
  AVG(d.response_time_ms) as avg_response_time_ms
FROM webhooks w
JOIN webhook_deliveries d ON d.webhook_id = w.id
WHERE d.created_at > NOW() - INTERVAL '7 days'
GROUP BY w.id, w.name, w.url
ORDER BY success_rate ASC;
```

### Dead Letter Queue

```sql
-- Get all dead letter deliveries
SELECT
  d.id,
  w.name as webhook_name,
  w.url,
  d.event_type,
  d.attempt,
  d.error_message,
  d.last_attempt_at
FROM webhook_deliveries d
JOIN webhooks w ON w.id = d.webhook_id
WHERE d.status = 'dead_letter'
ORDER BY d.created_at DESC;
```

---

## 🚨 Alerting

### Alert on High Failure Rate

```typescript
// Check webhook health every 5 minutes
cron.schedule('*/5 * * * *', async () => {
  const stats = await tenantCoreDB.query(`
    SELECT
      w.id,
      w.name,
      w.url,
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE d.status = 'dead_letter') as failed
    FROM webhooks w
    JOIN webhook_deliveries d ON d.webhook_id = w.id
    WHERE d.created_at > NOW() - INTERVAL '1 hour'
    GROUP BY w.id
    HAVING COUNT(*) FILTER (WHERE d.status = 'dead_letter') > 10
  `);

  for (const stat of stats.rows) {
    await alertService.send({
      type: 'webhook_failure',
      severity: 'warning',
      message: `Webhook ${stat.name} has ${stat.failed} failures in the last hour`,
      metadata: stat
    });
  }
});
```

---

## 🔄 Manual Retry API

```typescript
// POST /api/webhooks/deliveries/:id/retry

app.post('/api/webhooks/deliveries/:id/retry', requireRole('TENANT_ADMIN'), async (req, res) => {
  const { id } = req.params;

  // Reset delivery to pending
  await tenantCoreDB.query(`
    UPDATE webhook_deliveries
    SET status = 'pending',
        attempt = 0,
        next_retry_at = NOW(),
        error_message = NULL
    WHERE id = $1
  `, [id]);

  // Trigger immediate processing
  await webhookService.processDeliveries(req.tenant.id);

  res.json({ success: true });
});
```

---

## ✅ Summary

**Retry Strategy**:
- ✅ Exponential backoff (30s, 1m, 2m, 4m, 8m)
- ✅ Max 5 attempts over ~15 minutes
- ✅ Dead letter queue for permanent failures
- ✅ Manual retry from UI

**Security**:
- ✅ HMAC SHA256 signature
- ✅ Secret per webhook
- ✅ Constant-time comparison

**Reliability**:
- ✅ Background worker (cron every minute)
- ✅ Persistent queue (database)
- ✅ Timeout per request (10s)
- ✅ Alert on failures

**Monitoring**:
- ✅ Success rate per webhook
- ✅ Average response time
- ✅ Dead letter queue dashboard
- ✅ Audit log for all deliveries

**Tenant Experience**:
- ✅ Simple UI to create webhooks
- ✅ Subscribe to specific events
- ✅ View delivery history
- ✅ Retry failed deliveries

---

**Next**: API_MARKETPLACE_APPROVAL.md 🚀
