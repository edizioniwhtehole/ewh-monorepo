# 🏪 API Marketplace with Owner Approval System

**Version**: 1.0.0
**Last Updated**: 2025-10-11
**Status**: ✅ Complete Specification

---

## 🎯 Overview

Marketplace dove i tenant possono pubblicare API custom, con sistema di approvazione owner per controllo qualità e sicurezza.

**Flow**:
```
Tenant crea API → Submit for review → Owner approva → API pubblicata → Revenue share
```

---

## 📊 Database Schema

```sql
-- db_blogmaster_platform.api_marketplace

CREATE TABLE marketplace_apis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Ownership
  tenant_id UUID NOT NULL,
  created_by UUID NOT NULL,

  -- API Info
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  category VARCHAR(50), -- 'utility', 'ai', 'data', 'integration'

  -- Technical
  endpoint TEXT NOT NULL, -- '/api/marketplace/:slug/*'
  method VARCHAR(10)[], -- ['GET', 'POST']
  docs_url TEXT,
  openapi_spec JSONB,

  -- Status
  status VARCHAR(20) DEFAULT 'draft', -- draft, pending_review, approved, rejected, published, suspended
  visibility VARCHAR(20) DEFAULT 'private', -- private, public

  -- Review
  reviewed_by UUID,
  reviewed_at TIMESTAMP,
  review_notes TEXT,
  rejection_reason TEXT,

  -- Pricing
  pricing_model VARCHAR(20) DEFAULT 'free', -- free, per_call, subscription
  price_per_call_cents INT,
  subscription_monthly_cents INT,

  -- Revenue share
  revenue_share_percent INT DEFAULT 70, -- 70% to tenant, 30% to platform

  -- Stats
  install_count INT DEFAULT 0,
  call_count INT DEFAULT 0,
  revenue_total_cents BIGINT DEFAULT 0,

  -- Metadata
  icon_url TEXT,
  screenshots TEXT[],
  tags TEXT[],

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  published_at TIMESTAMP,

  INDEX idx_tenant (tenant_id),
  INDEX idx_status (status),
  INDEX idx_visibility (visibility),
  INDEX idx_category (category)
);

-- API installations (which tenants have installed which APIs)
CREATE TABLE marketplace_api_installations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_id UUID NOT NULL REFERENCES marketplace_apis(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL,

  -- Status
  status VARCHAR(20) DEFAULT 'active', -- active, suspended, cancelled

  -- Usage
  call_count INT DEFAULT 0,
  last_call_at TIMESTAMP,

  -- Billing
  subscription_status VARCHAR(20), -- active, cancelled, past_due
  subscription_started_at TIMESTAMP,
  subscription_ends_at TIMESTAMP,

  installed_at TIMESTAMP DEFAULT NOW(),

  UNIQUE (api_id, tenant_id),
  INDEX idx_api (api_id),
  INDEX idx_tenant (tenant_id)
);

-- API usage logs (for billing and analytics)
CREATE TABLE marketplace_api_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_id UUID NOT NULL,
  installation_id UUID NOT NULL REFERENCES marketplace_api_installations(id),
  tenant_id UUID NOT NULL,

  -- Request
  method VARCHAR(10) NOT NULL,
  path TEXT NOT NULL,
  status_code INT,
  response_time_ms INT,

  -- Billing
  charged_cents INT,

  created_at TIMESTAMP DEFAULT NOW(),

  INDEX idx_api (api_id),
  INDEX idx_installation (installation_id),
  INDEX idx_created (created_at DESC)
);
```

---

## 🔧 API Creation Flow

### 1. Tenant Creates API

```typescript
// POST /api/marketplace/apis

export async function createMarketplaceAPI(req, res) {
  const {
    name,
    slug,
    description,
    category,
    endpoint,
    methods,
    docs_url,
    pricing_model,
    price_per_call_cents,
    subscription_monthly_cents
  } = req.body;

  // Validate endpoint (must start with /api/marketplace/:slug/)
  if (!endpoint.startsWith(`/api/marketplace/${slug}/`)) {
    return res.status(400).json({
      error: 'Invalid endpoint',
      message: `Endpoint must start with /api/marketplace/${slug}/`
    });
  }

  // Create API (status: draft)
  const result = await platformDB.query(`
    INSERT INTO marketplace_apis (
      tenant_id, created_by,
      name, slug, description, category,
      endpoint, method, docs_url,
      pricing_model, price_per_call_cents, subscription_monthly_cents,
      status
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'draft')
    RETURNING id
  `, [
    req.tenant.id, req.user.id,
    name, slug, description, category,
    endpoint, methods, docs_url,
    pricing_model, price_per_call_cents, subscription_monthly_cents
  ]);

  res.json({
    id: result.rows[0].id,
    status: 'draft',
    message: 'API created. Submit for review when ready.'
  });
}
```

---

### 2. Submit for Review

```typescript
// POST /api/marketplace/apis/:id/submit

export async function submitForReview(req, res) {
  const { id } = req.params;

  // Check ownership
  const api = await platformDB.query(`
    SELECT * FROM marketplace_apis
    WHERE id = $1 AND tenant_id = $2
  `, [id, req.tenant.id]);

  if (!api.rows[0]) {
    return res.status(404).json({ error: 'API not found' });
  }

  if (api.rows[0].status !== 'draft') {
    return res.status(400).json({
      error: 'Invalid status',
      message: 'API must be in draft status to submit'
    });
  }

  // Update status
  await platformDB.query(`
    UPDATE marketplace_apis
    SET status = 'pending_review', updated_at = NOW()
    WHERE id = $1
  `, [id]);

  // Notify owner admins
  await notificationService.notifyOwners({
    type: 'api_review_requested',
    title: 'New API pending review',
    message: `${api.rows[0].name} by ${req.tenant.slug}`,
    api_id: id
  });

  res.json({
    status: 'pending_review',
    message: 'API submitted for review. You will be notified when reviewed.'
  });
}
```

---

### 3. Owner Reviews API

```typescript
// GET /api/owner/marketplace/apis/pending

export async function getPendingAPIs(req, res) {
  // Only platform owners
  if (req.user.platform_role !== 'OWNER') {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const apis = await platformDB.query(`
    SELECT
      a.*,
      t.slug as tenant_slug,
      t.tier as tenant_tier,
      u.email as creator_email
    FROM marketplace_apis a
    JOIN registry.tenants t ON t.id = a.tenant_id
    JOIN users u ON u.id = a.created_by
    WHERE a.status = 'pending_review'
    ORDER BY a.created_at ASC
  `);

  res.json(apis.rows);
}

// POST /api/owner/marketplace/apis/:id/approve

export async function approveAPI(req, res) {
  const { id } = req.params;
  const { review_notes } = req.body;

  await platformDB.query(`
    UPDATE marketplace_apis
    SET status = 'approved',
        reviewed_by = $1,
        reviewed_at = NOW(),
        review_notes = $2
    WHERE id = $3
  `, [req.user.id, review_notes, id]);

  // Notify tenant
  const api = await platformDB.query(`
    SELECT * FROM marketplace_apis WHERE id = $1
  `, [id]);

  await notificationService.notifyTenant(api.rows[0].tenant_id, {
    type: 'api_approved',
    title: 'Your API was approved!',
    message: `${api.rows[0].name} is now approved. You can publish it to the marketplace.`
  });

  res.json({ success: true, status: 'approved' });
}

// POST /api/owner/marketplace/apis/:id/reject

export async function rejectAPI(req, res) {
  const { id } = req.params;
  const { rejection_reason } = req.body;

  if (!rejection_reason) {
    return res.status(400).json({
      error: 'Rejection reason required'
    });
  }

  await platformDB.query(`
    UPDATE marketplace_apis
    SET status = 'rejected',
        reviewed_by = $1,
        reviewed_at = NOW(),
        rejection_reason = $2
    WHERE id = $3
  `, [req.user.id, rejection_reason, id]);

  // Notify tenant
  const api = await platformDB.query(`
    SELECT * FROM marketplace_apis WHERE id = $1
  `, [id]);

  await notificationService.notifyTenant(api.rows[0].tenant_id, {
    type: 'api_rejected',
    title: 'Your API needs changes',
    message: `${api.rows[0].name} was rejected. Reason: ${rejection_reason}`
  });

  res.json({ success: true, status: 'rejected' });
}
```

---

### 4. Publish API

```typescript
// POST /api/marketplace/apis/:id/publish

export async function publishAPI(req, res) {
  const { id } = req.params;

  const api = await platformDB.query(`
    SELECT * FROM marketplace_apis
    WHERE id = $1 AND tenant_id = $2
  `, [id, req.tenant.id]);

  if (!api.rows[0]) {
    return res.status(404).json({ error: 'API not found' });
  }

  if (api.rows[0].status !== 'approved') {
    return res.status(400).json({
      error: 'API must be approved before publishing'
    });
  }

  // Publish
  await platformDB.query(`
    UPDATE marketplace_apis
    SET status = 'published',
        visibility = 'public',
        published_at = NOW()
    WHERE id = $1
  `, [id]);

  res.json({
    success: true,
    status: 'published',
    marketplace_url: `/marketplace/api/${api.rows[0].slug}`
  });
}
```

---

## 🔍 Review Checklist (Owner)

### Security Review

```typescript
const SECURITY_CHECKLIST = [
  {
    id: 'auth',
    question: 'Does the API require authentication?',
    required: true
  },
  {
    id: 'rate_limit',
    question: 'Is rate limiting implemented?',
    required: true
  },
  {
    id: 'input_validation',
    question: 'Is input validation present?',
    required: true
  },
  {
    id: 'no_pii_leak',
    question: 'Does the API expose PII without consent?',
    required: false,
    fail_if_yes: true
  },
  {
    id: 'sql_injection',
    question: 'Is the API vulnerable to SQL injection?',
    required: false,
    fail_if_yes: true
  },
  {
    id: 'xss',
    question: 'Is the API vulnerable to XSS?',
    required: false,
    fail_if_yes: true
  }
];
```

### Quality Review

```typescript
const QUALITY_CHECKLIST = [
  {
    id: 'docs',
    question: 'Is documentation complete?',
    required: true
  },
  {
    id: 'examples',
    question: 'Are usage examples provided?',
    required: true
  },
  {
    id: 'error_handling',
    question: 'Are error messages clear?',
    required: true
  },
  {
    id: 'versioning',
    question: 'Is API versioned?',
    required: false
  },
  {
    id: 'openapi',
    question: 'Is OpenAPI spec provided?',
    required: false
  }
];
```

---

## 🏪 Marketplace Browsing

### Browse APIs

```typescript
// GET /api/marketplace/apis

export async function browseAPIs(req, res) {
  const { category, search, page = 1, limit = 20 } = req.query;

  let query = `
    SELECT
      a.id, a.name, a.slug, a.description, a.category,
      a.pricing_model, a.price_per_call_cents, a.subscription_monthly_cents,
      a.install_count, a.icon_url, a.tags,
      t.slug as tenant_slug
    FROM marketplace_apis a
    JOIN registry.tenants t ON t.id = a.tenant_id
    WHERE a.status = 'published' AND a.visibility = 'public'
  `;

  const params: any[] = [];

  if (category) {
    params.push(category);
    query += ` AND a.category = $${params.length}`;
  }

  if (search) {
    params.push(`%${search}%`);
    query += ` AND (a.name ILIKE $${params.length} OR a.description ILIKE $${params.length})`;
  }

  query += ` ORDER BY a.install_count DESC, a.created_at DESC`;
  query += ` LIMIT ${limit} OFFSET ${(page - 1) * limit}`;

  const apis = await platformDB.query(query, params);

  res.json({
    apis: apis.rows,
    page: parseInt(page),
    limit: parseInt(limit)
  });
}
```

---

## 💰 Revenue Share

### API Call Billing

```typescript
// Middleware: Track API usage and charge
export function marketplaceAPIMiddleware() {
  return async (req, res, next) => {
    // Extract API slug from path
    const match = req.path.match(/^\/api\/marketplace\/([^/]+)/);
    if (!match) return next();

    const apiSlug = match[1];

    // Get API info
    const api = await platformDB.query(`
      SELECT * FROM marketplace_apis WHERE slug = $1 AND status = 'published'
    `, [apiSlug]);

    if (!api.rows[0]) {
      return res.status(404).json({ error: 'API not found' });
    }

    // Check installation
    const installation = await platformDB.query(`
      SELECT * FROM marketplace_api_installations
      WHERE api_id = $1 AND tenant_id = $2 AND status = 'active'
    `, [api.rows[0].id, req.tenant.id]);

    if (!installation.rows[0]) {
      return res.status(403).json({
        error: 'API not installed',
        message: 'Install this API from the marketplace first'
      });
    }

    // Calculate charge
    let charge = 0;
    if (api.rows[0].pricing_model === 'per_call') {
      charge = api.rows[0].price_per_call_cents;
    }

    // Track usage (async, don't block)
    const startTime = Date.now();

    res.on('finish', async () => {
      const responseTime = Date.now() - startTime;

      await platformDB.query(`
        INSERT INTO marketplace_api_usage (
          api_id, installation_id, tenant_id,
          method, path, status_code, response_time_ms, charged_cents
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, [
        api.rows[0].id,
        installation.rows[0].id,
        req.tenant.id,
        req.method,
        req.path,
        res.statusCode,
        responseTime,
        charge
      ]);

      // Update counters
      await platformDB.query(`
        UPDATE marketplace_apis
        SET call_count = call_count + 1,
            revenue_total_cents = revenue_total_cents + $1
        WHERE id = $2
      `, [charge, api.rows[0].id]);

      await platformDB.query(`
        UPDATE marketplace_api_installations
        SET call_count = call_count + 1,
            last_call_at = NOW()
        WHERE id = $1
      `, [installation.rows[0].id]);
    });

    // Forward request to tenant's API
    next();
  };
}
```

### Monthly Payout

```typescript
// Calculate revenue share payouts (run monthly)
export async function calculatePayouts() {
  const payouts = await platformDB.query(`
    SELECT
      a.tenant_id,
      a.id as api_id,
      a.name as api_name,
      a.revenue_total_cents as total_revenue,
      a.revenue_share_percent,
      (a.revenue_total_cents * a.revenue_share_percent / 100) as tenant_payout,
      (a.revenue_total_cents * (100 - a.revenue_share_percent) / 100) as platform_payout
    FROM marketplace_apis a
    WHERE a.status = 'published'
      AND a.revenue_total_cents > 0
  `);

  for (const payout of payouts.rows) {
    // Create payout record
    await platformDB.query(`
      INSERT INTO marketplace_payouts (
        tenant_id, api_id, period_start, period_end,
        total_revenue_cents, tenant_payout_cents, platform_payout_cents,
        status
      ) VALUES ($1, $2, DATE_TRUNC('month', NOW() - INTERVAL '1 month'), DATE_TRUNC('month', NOW()), $3, $4, $5, 'pending')
    `, [
      payout.tenant_id,
      payout.api_id,
      payout.total_revenue,
      payout.tenant_payout,
      payout.platform_payout
    ]);

    // Reset revenue counter
    await platformDB.query(`
      UPDATE marketplace_apis
      SET revenue_total_cents = 0
      WHERE id = $1
    `, [payout.api_id]);
  }
}
```

---

## 📊 Analytics Dashboard

### API Provider Dashboard

```typescript
function APIProviderDashboard() {
  const { apis } = useMyAPIs();

  return (
    <div>
      <h1>My Published APIs</h1>

      {apis.map(api => (
        <Card key={api.id}>
          <h3>{api.name}</h3>
          <p>{api.description}</p>

          <Stats>
            <Stat label="Installs" value={api.install_count} />
            <Stat label="API Calls" value={api.call_count.toLocaleString()} />
            <Stat label="Revenue" value={`€${(api.revenue_total_cents / 100).toFixed(2)}`} />
          </Stats>

          <Badge color={getStatusColor(api.status)}>
            {api.status}
          </Badge>

          {api.status === 'rejected' && (
            <Alert type="error">
              Rejected: {api.rejection_reason}
            </Alert>
          )}
        </Card>
      ))}
    </div>
  );
}
```

---

## ✅ Summary

**Approval Flow**:
- ✅ Tenant creates API (draft)
- ✅ Submit for review (pending_review)
- ✅ Owner reviews (security + quality checklist)
- ✅ Owner approves/rejects (approved/rejected)
- ✅ Tenant publishes (published)

**Revenue Share**:
- ✅ 70% tenant, 30% platform (configurable)
- ✅ Per-call or subscription pricing
- ✅ Automatic tracking and billing
- ✅ Monthly payouts

**Why Approval is Essential**:
- ✅ **Security**: Prevent malicious/vulnerable APIs
- ✅ **Quality**: Ensure good documentation and UX
- ✅ **Brand**: Protect platform reputation
- ✅ **Legal**: Avoid liability for tenant APIs
- ✅ **Revenue**: Curate valuable marketplace

**Owner Dashboard Features**:
- ✅ Queue of pending reviews
- ✅ Security + quality checklists
- ✅ Approve/reject with notes
- ✅ Monitor all published APIs
- ✅ Suspend problematic APIs

---

**Next**: VERSIONING_SYSTEM.md 🚀
