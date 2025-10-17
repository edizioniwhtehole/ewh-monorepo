# 🔄 Universal Approval Service - Technical Specification

**Version:** 1.0
**Service Name:** `svc-approvals`
**Port:** 4010
**Last Updated:** 2025-10-10
**Status:** Ready for Implementation
**Related:** [ENTERPRISE_DAM_ROADMAP.md](ENTERPRISE_DAM_ROADMAP.md), [DAM_APPROVAL_WORKFLOWS.md](DAM_APPROVAL_WORKFLOWS.md)

---

## 📋 TABLE OF CONTENTS

1. [Service Overview](#service-overview)
2. [Database Schema](#database-schema)
3. [API Specification](#api-specification)
4. [Integration Patterns](#integration-patterns)
5. [Implementation Guide](#implementation-guide)

---

## 🎯 SERVICE OVERVIEW

### Purpose

`svc-approvals` è un **servizio universale** per gestire workflow di approvazione multi-stage per qualsiasi tipo di risorsa nella piattaforma EWH.

### Supported Resource Types

| Resource Type | Service | Use Case | Example |
|--------------|---------|----------|---------|
| `dam_asset` | svc-media | Approve images/videos before publish | Product photo approval |
| `cms_page` | svc-cms | Approve page edits before going live | Homepage redesign approval |
| `cms_site` | svc-cms | Approve entire site before publish | New site launch approval |
| `text_document` | svc-content | Approve copywriting | Blog post approval |
| `mockup` | svc-mockup | Approve design mockups | Email template approval |
| `quotation` | svc-quotation | Approve pricing | Client quote approval |
| `order` | svc-orders | Approve order processing | Large order approval |
| `product` | svc-products | Approve catalog changes | New SKU approval |

### Key Features

- ✅ **Multi-stage pipelines** (sequential steps)
- ✅ **Parallel approval** (all must approve)
- ✅ **Conditional routing** (dynamic pipeline assignment)
- ✅ **Annotations** (comments, pins, markup)
- ✅ **SLA tracking** (deadline management)
- ✅ **Notifications** (email, Slack, Teams, webhooks)
- ✅ **Audit trail** (complete history)

---

## 🗄️ DATABASE SCHEMA

### Schema: `approvals`

#### Table: `approval_items`

```sql
CREATE TABLE approvals.approval_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.tenants(id) ON DELETE CASCADE,

  -- Resource Reference (Polymorphic)
  resource_type VARCHAR(50) NOT NULL, -- 'dam_asset', 'cms_page', 'cms_site', 'text_document', 'quotation', 'order', 'product', 'mockup'
  resource_id UUID NOT NULL,
  resource_url TEXT, -- Deep link to resource (e.g., /dam/assets/123)

  -- Display Info
  title TEXT NOT NULL,
  description TEXT,
  preview_url TEXT, -- Thumbnail or preview image URL
  preview_type VARCHAR(50), -- 'image', 'video', 'pdf', 'text', 'website'

  -- Submitter
  submitted_by UUID NOT NULL REFERENCES auth.users(id),
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'approved', 'rejected', 'cancelled')),

  -- Pipeline
  pipeline_id UUID REFERENCES approvals.pipelines(id) ON DELETE SET NULL,
  current_step_index INTEGER DEFAULT 0,

  -- Deadline & SLA
  deadline TIMESTAMPTZ,
  sla_breached BOOLEAN DEFAULT FALSE,

  -- Resolution
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,

  -- Metadata (extensible)
  metadata JSONB DEFAULT '{}', -- Custom fields per resource type

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_approval_items_tenant ON approvals.approval_items(tenant_id);
CREATE INDEX idx_approval_items_resource ON approvals.approval_items(resource_type, resource_id);
CREATE INDEX idx_approval_items_status_deadline ON approvals.approval_items(status, deadline NULLS LAST);
CREATE INDEX idx_approval_items_submitted_by ON approvals.approval_items(submitted_by);
CREATE INDEX idx_approval_items_pipeline ON approvals.approval_items(pipeline_id);

-- Unique constraint (one active approval per resource)
CREATE UNIQUE INDEX idx_approval_items_active_resource
  ON approvals.approval_items(resource_type, resource_id)
  WHERE status IN ('pending', 'in_review');

-- Updated at trigger
CREATE TRIGGER update_approval_items_updated_at
  BEFORE UPDATE ON approvals.approval_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

#### Table: `pipelines`

```sql
CREATE TABLE approvals.pipelines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.tenants(id) ON DELETE CASCADE,

  -- Pipeline Info
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Applicability
  resource_types VARCHAR(50)[] NOT NULL, -- ['dam_asset', 'cms_page', ...]
  conditions JSONB, -- Dynamic conditions for auto-assignment

  -- Steps Definition
  steps JSONB NOT NULL, -- Array of step definitions
  -- Example:
  -- [
  --   {
  --     "name": "Design Review",
  --     "approvers": ["user-id-1", "user-id-2"],
  --     "type": "any",  -- 'any' (one approver) or 'all' (all must approve)
  --     "sla_hours": 24,
  --     "skip_conditions": {"metadata.internal": true}
  --   },
  --   {
  --     "name": "Legal Review",
  --     "approvers": ["user-id-3"],
  --     "type": "all",
  --     "sla_hours": 48
  --   }
  -- ]

  -- Priority (for routing)
  priority INTEGER DEFAULT 0,
  enabled BOOLEAN DEFAULT TRUE,

  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_pipelines_tenant ON approvals.pipelines(tenant_id);
CREATE INDEX idx_pipelines_resource_types ON approvals.pipelines USING GIN(resource_types);
CREATE INDEX idx_pipelines_priority ON approvals.pipelines(tenant_id, priority DESC) WHERE enabled = TRUE;
```

#### Table: `step_executions`

```sql
CREATE TABLE approvals.step_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Parent Approval
  approval_item_id UUID NOT NULL REFERENCES approvals.approval_items(id) ON DELETE CASCADE,

  -- Step Info
  step_index INTEGER NOT NULL,
  step_name VARCHAR(255) NOT NULL,

  -- Approvers
  assigned_to UUID[] NOT NULL, -- Array of user IDs who can approve
  approved_by UUID[] DEFAULT '{}', -- Array of user IDs who approved
  rejected_by UUID REFERENCES auth.users(id),

  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'approved', 'rejected', 'skipped')),

  -- Timing
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  deadline TIMESTAMPTZ,

  -- Notes
  notes TEXT,
  rejection_reason TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_step_executions_approval ON approvals.step_executions(approval_item_id);
CREATE INDEX idx_step_executions_assigned ON approvals.step_executions USING GIN(assigned_to);
CREATE INDEX idx_step_executions_status_deadline ON approvals.step_executions(status, deadline NULLS LAST);

-- Unique constraint (one execution per approval per step)
CREATE UNIQUE INDEX idx_step_executions_unique
  ON approvals.step_executions(approval_item_id, step_index);
```

#### Table: `annotations`

```sql
CREATE TABLE approvals.annotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Parent Approval
  approval_item_id UUID NOT NULL REFERENCES approvals.approval_items(id) ON DELETE CASCADE,

  -- Author
  author_id UUID NOT NULL REFERENCES auth.users(id),

  -- Type
  annotation_type VARCHAR(50) NOT NULL CHECK (annotation_type IN ('comment', 'pin', 'arrow', 'rect', 'circle', 'freehand', 'text')),

  -- Content
  content TEXT, -- Text comment
  coordinates JSONB, -- {x: 100, y: 200} or path for shapes
  style JSONB, -- {color: "#FF0000", strokeWidth: 2, fontSize: 14}

  -- Thread (for nested comments)
  parent_id UUID REFERENCES approvals.annotations(id) ON DELETE CASCADE,
  thread_resolved BOOLEAN DEFAULT FALSE,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_annotations_approval ON approvals.annotations(approval_item_id);
CREATE INDEX idx_annotations_author ON approvals.annotations(author_id);
CREATE INDEX idx_annotations_parent ON approvals.annotations(parent_id);
CREATE INDEX idx_annotations_thread ON approvals.annotations(approval_item_id, parent_id NULLS FIRST);
```

#### Table: `routing_rules`

```sql
CREATE TABLE approvals.routing_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES auth.tenants(id) ON DELETE CASCADE,

  -- Rule Info
  name VARCHAR(255) NOT NULL,
  description TEXT,
  priority INTEGER DEFAULT 0, -- Higher priority rules checked first

  -- Conditions (JSON query language)
  conditions JSONB NOT NULL,
  -- Example:
  -- {
  --   "resource_type": "dam_asset",
  --   "metadata": {
  --     "asset_type": "image",
  --     "client_id": "coca-cola-uuid"
  --   },
  --   "tags": {"contains": ["brand", "logo"]},
  --   "file_size": {"gt": 10485760}
  -- }

  -- Target Pipeline
  target_pipeline_id UUID NOT NULL REFERENCES approvals.pipelines(id) ON DELETE CASCADE,

  -- Status
  enabled BOOLEAN DEFAULT TRUE,

  -- Audit
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_routing_rules_tenant_priority ON approvals.routing_rules(tenant_id, priority DESC) WHERE enabled = TRUE;
CREATE INDEX idx_routing_rules_pipeline ON approvals.routing_rules(target_pipeline_id);
```

#### Table: `notifications` (Optional - for tracking)

```sql
CREATE TABLE approvals.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Target
  approval_item_id UUID NOT NULL REFERENCES approvals.approval_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),

  -- Notification Type
  notification_type VARCHAR(50) NOT NULL, -- 'approval_requested', 'approved', 'rejected', 'comment_added', 'sla_warning', 'sla_breached'

  -- Channels
  channels VARCHAR(50)[] DEFAULT '{"email"}', -- ['email', 'slack', 'teams', 'webhook']

  -- Status
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  error_message TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_approval ON approvals.notifications(approval_item_id);
CREATE INDEX idx_notifications_user ON approvals.notifications(user_id, read_at NULLS FIRST);
CREATE INDEX idx_notifications_pending ON approvals.notifications(sent_at NULLS FIRST) WHERE failed_at IS NULL;
```

---

## 🔌 API SPECIFICATION

### Base URL

- **Development:** `http://localhost:4010/api`
- **Production:** `https://api.ewh.com/approvals/api`

### Authentication

All endpoints require JWT authentication via `Authorization: Bearer <token>` header.

---

### Endpoints

#### 1. Create Approval Request

```http
POST /api/approvals
Content-Type: application/json
Authorization: Bearer <token>

{
  "resourceType": "dam_asset",
  "resourceId": "asset-uuid-123",
  "resourceUrl": "/dam/assets/asset-uuid-123",
  "title": "Product Photo - Summer Campaign",
  "description": "High-res product photo for summer campaign",
  "previewUrl": "https://cdn.ewh.com/thumbnails/asset-uuid-123.jpg",
  "previewType": "image",
  "deadline": "2025-10-17T23:59:59Z",
  "metadata": {
    "asset_type": "image",
    "client_id": "coca-cola-uuid",
    "campaign": "summer-2025"
  }
}
```

**Response (201 Created):**
```json
{
  "id": "approval-uuid-456",
  "status": "pending",
  "pipelineId": "pipeline-uuid-789",
  "currentStepIndex": 0,
  "createdAt": "2025-10-10T10:00:00Z"
}
```

---

#### 2. Get Approval Queue

```http
GET /api/approvals?status=pending&assignedTo=me&resourceType=dam_asset&limit=50
Authorization: Bearer <token>
```

**Query Parameters:**
- `status` (optional): `pending`, `in_review`, `approved`, `rejected`
- `assignedTo` (optional): `me`, `user-uuid`, `all`
- `resourceType` (optional): Filter by resource type
- `submittedBy` (optional): Filter by submitter
- `deadline` (optional): `overdue`, `today`, `this-week`
- `limit` (optional): Default 50, max 200
- `offset` (optional): For pagination

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "approval-uuid-456",
      "resourceType": "dam_asset",
      "resourceId": "asset-uuid-123",
      "resourceUrl": "/dam/assets/asset-uuid-123",
      "title": "Product Photo - Summer Campaign",
      "description": "High-res product photo",
      "previewUrl": "https://cdn.ewh.com/thumbnails/asset-uuid-123.jpg",
      "previewType": "image",
      "status": "pending",
      "submittedBy": {
        "id": "user-uuid-111",
        "name": "John Doe",
        "email": "john@example.com"
      },
      "submittedAt": "2025-10-10T10:00:00Z",
      "deadline": "2025-10-17T23:59:59Z",
      "pipeline": {
        "id": "pipeline-uuid-789",
        "name": "Brand Review Pipeline",
        "currentStep": {
          "index": 0,
          "name": "Design Review",
          "assignedTo": ["user-uuid-222", "user-uuid-333"],
          "status": "pending"
        }
      }
    }
  ],
  "pagination": {
    "total": 42,
    "limit": 50,
    "offset": 0,
    "hasMore": false
  }
}
```

---

#### 3. Get Approval by ID

```http
GET /api/approvals/:id
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "id": "approval-uuid-456",
  "tenantId": "tenant-uuid",
  "resourceType": "dam_asset",
  "resourceId": "asset-uuid-123",
  "resourceUrl": "/dam/assets/asset-uuid-123",
  "title": "Product Photo - Summer Campaign",
  "description": "High-res product photo",
  "previewUrl": "https://cdn.ewh.com/thumbnails/asset-uuid-123.jpg",
  "previewType": "image",
  "status": "in_review",
  "submittedBy": {
    "id": "user-uuid-111",
    "name": "John Doe",
    "email": "john@example.com"
  },
  "submittedAt": "2025-10-10T10:00:00Z",
  "deadline": "2025-10-17T23:59:59Z",
  "slaBreached": false,
  "pipeline": {
    "id": "pipeline-uuid-789",
    "name": "Brand Review Pipeline",
    "steps": [
      {
        "index": 0,
        "name": "Design Review",
        "assignedTo": [
          {"id": "user-uuid-222", "name": "Alice Smith"},
          {"id": "user-uuid-333", "name": "Bob Johnson"}
        ],
        "approvedBy": [
          {"id": "user-uuid-222", "name": "Alice Smith", "approvedAt": "2025-10-10T11:00:00Z"}
        ],
        "status": "in_review",
        "startedAt": "2025-10-10T10:00:00Z",
        "deadline": "2025-10-11T10:00:00Z"
      },
      {
        "index": 1,
        "name": "Legal Review",
        "assignedTo": [
          {"id": "user-uuid-444", "name": "Legal Team"}
        ],
        "status": "pending"
      }
    ]
  },
  "annotations": {
    "count": 3,
    "unresolved": 1
  },
  "createdAt": "2025-10-10T10:00:00Z",
  "updatedAt": "2025-10-10T11:00:00Z"
}
```

---

#### 4. Approve Step

```http
POST /api/approvals/:id/steps/:stepIndex/approve
Content-Type: application/json
Authorization: Bearer <token>

{
  "notes": "Looks good! Approved for next stage."
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "approval": {
    "id": "approval-uuid-456",
    "status": "in_review",
    "currentStepIndex": 1,
    "updatedAt": "2025-10-10T12:00:00Z"
  },
  "step": {
    "index": 0,
    "status": "approved",
    "completedAt": "2025-10-10T12:00:00Z"
  },
  "nextStep": {
    "index": 1,
    "name": "Legal Review",
    "assignedTo": ["user-uuid-444"]
  }
}
```

---

#### 5. Reject Step

```http
POST /api/approvals/:id/steps/:stepIndex/reject
Content-Type: application/json
Authorization: Bearer <token>

{
  "reason": "Color scheme doesn't match brand guidelines. Please revise.",
  "requestChanges": true
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "approval": {
    "id": "approval-uuid-456",
    "status": "rejected",
    "resolvedBy": "user-uuid-333",
    "resolvedAt": "2025-10-10T12:00:00Z",
    "resolutionNotes": "Color scheme doesn't match brand guidelines."
  },
  "step": {
    "index": 0,
    "status": "rejected",
    "rejectedBy": "user-uuid-333",
    "completedAt": "2025-10-10T12:00:00Z"
  }
}
```

---

#### 6. Add Annotation

```http
POST /api/approvals/:id/annotations
Content-Type: application/json
Authorization: Bearer <token>

{
  "type": "pin",
  "content": "This logo placement seems off",
  "coordinates": {"x": 150, "y": 200},
  "style": {"color": "#FF0000"}
}
```

**Response (201 Created):**
```json
{
  "id": "annotation-uuid-789",
  "approvalItemId": "approval-uuid-456",
  "type": "pin",
  "content": "This logo placement seems off",
  "coordinates": {"x": 150, "y": 200},
  "style": {"color": "#FF0000"},
  "author": {
    "id": "user-uuid-333",
    "name": "Bob Johnson"
  },
  "createdAt": "2025-10-10T12:30:00Z"
}
```

---

#### 7. Get Annotations

```http
GET /api/approvals/:id/annotations
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "annotation-uuid-789",
      "type": "pin",
      "content": "This logo placement seems off",
      "coordinates": {"x": 150, "y": 200},
      "style": {"color": "#FF0000"},
      "author": {
        "id": "user-uuid-333",
        "name": "Bob Johnson",
        "avatar": "https://cdn.ewh.com/avatars/bob.jpg"
      },
      "threadResolved": false,
      "replies": [],
      "createdAt": "2025-10-10T12:30:00Z"
    }
  ],
  "count": 1
}
```

---

### Pipeline Management Endpoints

#### 8. Create Pipeline

```http
POST /api/approvals/pipelines
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "Brand Review Pipeline",
  "description": "Multi-stage approval for brand assets",
  "resourceTypes": ["dam_asset"],
  "steps": [
    {
      "name": "Design Review",
      "approvers": ["user-uuid-222", "user-uuid-333"],
      "type": "any",
      "slaHours": 24
    },
    {
      "name": "Legal Review",
      "approvers": ["user-uuid-444"],
      "type": "all",
      "slaHours": 48
    },
    {
      "name": "Final Approval",
      "approvers": ["user-uuid-555"],
      "type": "any",
      "slaHours": 12
    }
  ],
  "conditions": {
    "metadata.client_id": "coca-cola-uuid",
    "metadata.asset_type": "image"
  },
  "priority": 10
}
```

**Response (201 Created):**
```json
{
  "id": "pipeline-uuid-789",
  "name": "Brand Review Pipeline",
  "enabled": true,
  "createdAt": "2025-10-10T09:00:00Z"
}
```

---

## 🔗 INTEGRATION PATTERNS

### Pattern 1: Submit Resource for Approval (from svc-media)

```typescript
// In svc-media (DAM)
import { createApprovalRequest } from '@ewh/svc-approvals-client';

export async function submitAssetForApproval(
  assetId: string,
  userId: string
): Promise<void> {
  const asset = await fetchAsset(assetId);

  // Create approval request
  const approval = await createApprovalRequest({
    resourceType: 'dam_asset',
    resourceId: assetId,
    resourceUrl: `/dam/assets/${assetId}`,
    title: asset.name,
    description: `${asset.type} - ${asset.format}`,
    previewUrl: asset.thumbnail_url,
    previewType: 'image',
    tenantId: asset.tenant_id,
    submittedBy: userId,
    deadline: addDays(new Date(), 7),
    metadata: {
      asset_type: asset.type,
      client_id: asset.client?.id,
      tags: asset.tags
    }
  });

  // Update asset status
  await db.query(`
    UPDATE dam_assets
    SET status = 'pending_approval', approval_id = $1
    WHERE id = $2
  `, [approval.id, assetId]);

  console.log(`Asset ${assetId} submitted for approval: ${approval.id}`);
}
```

### Pattern 2: Listen for Approval Events (webhook)

```typescript
// In svc-media - handle approval completed
export async function handleApprovalCompleted(event: ApprovalEvent): Promise<void> {
  if (event.resourceType !== 'dam_asset') return;

  const { resourceId, status, resolvedBy, resolvedAt } = event;

  if (status === 'approved') {
    // Update asset status
    await db.query(`
      UPDATE dam_assets
      SET status = 'approved', approved_by = $1, approved_at = $2
      WHERE id = $3
    `, [resolvedBy, resolvedAt, resourceId]);

    // Trigger post-approval actions
    await publishAsset(resourceId);
  } else if (status === 'rejected') {
    await db.query(`
      UPDATE dam_assets
      SET status = 'rejected'
      WHERE id = $1
    `, [resourceId]);

    // Notify submitter
    await notifyRejection(resourceId, event.resolutionNotes);
  }
}
```

---

## 🛠️ IMPLEMENTATION GUIDE

### Step 1: Create Service Structure

```bash
cd /Users/andromeda/dev/ewh
mkdir svc-approvals
cd svc-approvals

# Initialize package
pnpm init

# Install dependencies
pnpm add fastify @fastify/cors @fastify/swagger @fastify/jwt
pnpm add pg zod pino
pnpm add -D typescript @types/node @types/pg tsx
```

### Step 2: Create Database Migration

```sql
-- database/migrations/001_create_approvals_schema.sql
CREATE SCHEMA IF NOT EXISTS approvals;

-- [Copy tables from Database Schema section above]
```

### Step 3: Create Service Entry Point

```typescript
// src/index.ts
import Fastify from 'fastify';
import cors from '@fastify/cors';
import { approvalsRoutes } from './routes/approvals';
import { pipelinesRoutes } from './routes/pipelines';

const server = Fastify({
  logger: {
    level: 'info',
    transport: {
      target: 'pino-pretty'
    }
  }
});

// Plugins
server.register(cors, {
  origin: true,
  credentials: true
});

// Routes
server.register(approvalsRoutes, { prefix: '/api/approvals' });
server.register(pipelinesRoutes, { prefix: '/api/approvals/pipelines' });

// Health check
server.get('/health', async () => ({
  status: 'ok',
  timestamp: new Date().toISOString()
}));

// Start server
const start = async () => {
  try {
    await server.listen({ port: 4010, host: '0.0.0.0' });
    console.log('✅ svc-approvals running on http://localhost:4010');
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();
```

### Step 4: Run Database Migration

```bash
# Apply migration
psql -h localhost -U ewh -d ewh_master -f database/migrations/001_create_approvals_schema.sql

# Verify
psql -h localhost -U ewh -d ewh_master -c "\dt approvals.*"
```

### Step 5: Start Service

```bash
# Development mode with auto-reload
pnpm tsx watch src/index.ts

# Verify health check
curl http://localhost:4010/health
```

---

## ✅ VERIFICATION CHECKLIST

- [ ] Service starts on port 4010
- [ ] Health check returns 200 OK
- [ ] Database schema created (5 tables in `approvals` schema)
- [ ] Can create approval request (POST /api/approvals)
- [ ] Can list approval queue (GET /api/approvals)
- [ ] Can approve step (POST /api/approvals/:id/steps/:index/approve)
- [ ] Can reject step (POST /api/approvals/:id/steps/:index/reject)
- [ ] Can add annotations (POST /api/approvals/:id/annotations)
- [ ] Pipeline routing works (auto-assigns pipeline)
- [ ] SLA tracking works (deadline enforcement)

---

**Document Owner:** Platform Team
**Next Steps:** See [ENTERPRISE_DAM_ROADMAP.md](ENTERPRISE_DAM_ROADMAP.md) Phase 1
