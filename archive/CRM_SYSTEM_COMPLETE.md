# Complete CRM System Architecture

## Overview

Sistema CRM (Customer Relationship Management) completo integrato nativamente con:
- **Communications System**: Email, SMS, WhatsApp, Telegram, Discord
- **Project Management**: Deal tracking, pipeline management
- **E-commerce**: Orders, invoices, quotations
- **Support**: Tickets, knowledge base
- **Marketing**: Campaigns, lead scoring

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    app-crm-frontend                         │
│  Dashboard + Contacts + Deals + Pipeline + Activities       │
└──────────────────────┬──────────────────────────────────────┘
                       │ REST + WebSocket
┌──────────────────────┴──────────────────────────────────────┐
│                  svc-crm (Port 3300)                        │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  Contact Management │ Deal Pipeline │ Activities        ││
│  │  Lead Scoring       │ Sales Automation │ Reporting      ││
│  └─────────────────────────────────────────────────────────┘│
└──────────────────────┬──────────────────────────────────────┘
                       │
    ┌──────────────────┼──────────────────┐
    │                  │                  │
┌───▼──────┐  ┌────────▼───────┐  ┌──────▼──────┐
│ svc-comm │  │ svc-projects   │  │ svc-orders  │
│ (emails) │  │ (tasks)        │  │ (sales)     │
└──────────┘  └────────────────┘  └─────────────┘
```

## Core Features

### 1. Contact Management
- Contacts (people)
- Companies (organizations)
- Custom fields
- Tags and segments
- Contact scoring
- Duplicate detection
- Import/export (CSV, vCard)
- Social profiles integration

### 2. Deal Pipeline
- Multiple pipelines (Sales, Partnerships, etc.)
- Customizable stages
- Deal value tracking
- Probability/weighted forecast
- Drag-and-drop kanban
- Win/loss analysis
- Deal rotting alerts

### 3. Activities
- Tasks (to-dos)
- Meetings
- Calls
- Notes
- Timeline view
- Activity types customization
- Reminders
- Calendar sync

### 4. Lead Scoring
- Automatic scoring based on:
  - Email engagement (opens, clicks)
  - Website visits
  - Form submissions
  - Social engagement
- Custom scoring rules
- Score history

### 5. Sales Automation
- Workflows (if/then rules)
- Auto-assignment (round-robin, load balancing)
- Email sequences
- Task automation
- Deal stage automation

### 6. Reporting & Analytics
- Sales funnel
- Conversion rates
- Revenue forecasting
- Team performance
- Activity reports
- Custom dashboards

## Services

### 1. svc-crm (Backend)

**Port**: 3300
**WebSocket Port**: 3301

#### Directory Structure

```
svc-crm/
├── src/
│   ├── index.ts
│   ├── config/
│   │   ├── database.ts
│   │   ├── redis.ts
│   │   └── settings.ts             # Cascade config
│   │
│   ├── models/
│   │   ├── contact.ts
│   │   ├── company.ts
│   │   ├── deal.ts
│   │   ├── activity.ts
│   │   ├── pipeline.ts
│   │   └── custom-field.ts
│   │
│   ├── services/
│   │   ├── contact-service.ts      # CRUD contacts
│   │   ├── company-service.ts      # CRUD companies
│   │   ├── deal-service.ts         # Deal management
│   │   ├── activity-service.ts     # Activities
│   │   ├── scoring-service.ts      # Lead scoring
│   │   ├── automation-service.ts   # Workflows
│   │   ├── import-service.ts       # CSV import
│   │   ├── duplicate-service.ts    # Deduplication
│   │   └── analytics-service.ts    # Reports
│   │
│   ├── routes/
│   │   ├── contacts.ts             # Contact CRUD
│   │   ├── companies.ts            # Company CRUD
│   │   ├── deals.ts                # Deal CRUD
│   │   ├── activities.ts           # Activity CRUD
│   │   ├── pipelines.ts            # Pipeline config
│   │   ├── scoring.ts              # Scoring rules
│   │   ├── automations.ts          # Workflow config
│   │   ├── reports.ts              # Analytics
│   │   ├── settings.ts             # Cascade config
│   │   ├── webhooks.ts             # Webhook management
│   │   ├── dev.ts                  # API docs
│   │   └── health.ts               # Health check
│   │
│   ├── jobs/
│   │   ├── scoring-queue.ts        # Score calculation
│   │   ├── automation-queue.ts     # Workflow execution
│   │   ├── email-sync-queue.ts     # Sync with comm system
│   │   └── cleanup-queue.ts        # Data maintenance
│   │
│   ├── integrations/
│   │   ├── communications.ts       # Link to svc-communications
│   │   ├── projects.ts             # Link to svc-projects
│   │   ├── orders.ts               # Link to svc-orders
│   │   └── calendar.ts             # Google/Outlook calendar
│   │
│   ├── middleware/
│   │   ├── auth.ts
│   │   ├── tenant.ts
│   │   ├── rate-limit.ts
│   │   └── validation.ts
│   │
│   └── migrations/
│       ├── 001_create_tables.sql
│       ├── 002_settings_tables.sql
│       └── 003_webhook_tables.sql
│
├── package.json
├── tsconfig.json
└── .env.example
```

### 2. app-crm-frontend (Frontend)

#### Directory Structure

```
app-crm-frontend/
├── src/
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── DashboardView.tsx
│   │   │   ├── SalesMetrics.tsx
│   │   │   ├── RecentActivities.tsx
│   │   │   ├── UpcomingTasks.tsx
│   │   │   └── FunnelChart.tsx
│   │   │
│   │   ├── contacts/
│   │   │   ├── ContactList.tsx       # List/grid view
│   │   │   ├── ContactDetail.tsx     # Full profile
│   │   │   ├── ContactForm.tsx       # Create/edit
│   │   │   ├── ContactImport.tsx     # CSV import
│   │   │   ├── ContactMerge.tsx      # Duplicate merge
│   │   │   └── ContactTimeline.tsx   # Activity history
│   │   │
│   │   ├── companies/
│   │   │   ├── CompanyList.tsx
│   │   │   ├── CompanyDetail.tsx
│   │   │   ├── CompanyForm.tsx
│   │   │   └── CompanyHierarchy.tsx  # Parent/child
│   │   │
│   │   ├── deals/
│   │   │   ├── PipelineView.tsx      # Kanban board
│   │   │   ├── DealList.tsx          # Table view
│   │   │   ├── DealDetail.tsx        # Deal page
│   │   │   ├── DealForm.tsx          # Create/edit
│   │   │   └── ForecastView.tsx      # Revenue forecast
│   │   │
│   │   ├── activities/
│   │   │   ├── ActivityList.tsx
│   │   │   ├── ActivityCalendar.tsx  # Calendar view
│   │   │   ├── TaskForm.tsx
│   │   │   ├── MeetingForm.tsx
│   │   │   └── NoteEditor.tsx
│   │   │
│   │   ├── automation/
│   │   │   ├── WorkflowList.tsx
│   │   │   ├── WorkflowBuilder.tsx   # Visual builder
│   │   │   ├── ScoringRules.tsx
│   │   │   └── AssignmentRules.tsx
│   │   │
│   │   ├── reports/
│   │   │   ├── ReportsList.tsx
│   │   │   ├── SalesFunnel.tsx
│   │   │   ├── TeamPerformance.tsx
│   │   │   ├── ActivityReport.tsx
│   │   │   └── CustomReport.tsx
│   │   │
│   │   └── settings/
│   │       ├── AdminSettings.tsx     # Owner level
│   │       ├── TenantSettings.tsx    # Tenant level
│   │       ├── UserSettings.tsx      # User level
│   │       ├── PipelineConfig.tsx    # Pipelines
│   │       ├── CustomFields.tsx      # Field config
│   │       └── IntegrationConfig.tsx # External integrations
│   │
│   ├── components/
│   │   ├── ContactCard.tsx
│   │   ├── DealCard.tsx
│   │   ├── ActivityItem.tsx
│   │   ├── ScoreBadge.tsx
│   │   ├── PipelineKanban.tsx
│   │   └── TimelineView.tsx
│   │
│   ├── hooks/
│   │   ├── useContacts.ts
│   │   ├── useDeals.ts
│   │   ├── useActivities.ts
│   │   ├── usePipeline.ts
│   │   └── useWebSocket.ts
│   │
│   └── services/
│       ├── api.ts
│       └── websocket.ts
│
├── package.json
└── vite.config.ts
```

## Database Schema

```sql
-- Contacts (people)
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  -- Basic info
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  full_name VARCHAR(200) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
  email VARCHAR(500),
  phone VARCHAR(50),
  mobile VARCHAR(50),

  -- Company relationship
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  job_title VARCHAR(200),
  department VARCHAR(100),

  -- Additional
  avatar_url TEXT,
  timezone VARCHAR(50),
  language VARCHAR(10),
  website TEXT,

  -- Social
  linkedin_url TEXT,
  twitter_handle VARCHAR(100),
  facebook_url TEXT,

  -- Address
  address_line1 VARCHAR(200),
  address_line2 VARCHAR(200),
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100),

  -- Status
  lifecycle_stage VARCHAR(50) NOT NULL DEFAULT 'lead', -- lead, mql, sql, opportunity, customer, evangelist
  status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, inactive, bounced, unsubscribed

  -- Scoring
  score INT DEFAULT 0,
  score_last_updated TIMESTAMPTZ,

  -- Ownership
  owner_id UUID, -- Assigned sales rep
  created_by_id UUID,

  -- Tags
  tags TEXT[] DEFAULT '{}',

  -- Custom fields (JSONB for flexibility)
  custom_fields JSONB DEFAULT '{}',

  -- Tracking
  last_contacted_at TIMESTAMPTZ,
  last_activity_at TIMESTAMPTZ,

  -- Communication preferences
  email_opt_in BOOLEAN DEFAULT true,
  sms_opt_in BOOLEAN DEFAULT false,
  whatsapp_opt_in BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT contacts_email_unique UNIQUE (tenant_id, email)
);

CREATE INDEX idx_contacts_tenant ON contacts(tenant_id);
CREATE INDEX idx_contacts_company ON contacts(company_id);
CREATE INDEX idx_contacts_owner ON contacts(owner_id);
CREATE INDEX idx_contacts_email ON contacts(email);
CREATE INDEX idx_contacts_lifecycle ON contacts(lifecycle_stage);
CREATE INDEX idx_contacts_score ON contacts(score DESC);

-- Companies (organizations)
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  name VARCHAR(200) NOT NULL,
  domain VARCHAR(200),
  description TEXT,

  -- Industry
  industry VARCHAR(100),
  employee_count INT,
  annual_revenue DECIMAL(15,2),

  -- Address
  address_line1 VARCHAR(200),
  city VARCHAR(100),
  country VARCHAR(100),

  -- Contact
  phone VARCHAR(50),
  website TEXT,

  -- Social
  linkedin_url TEXT,
  twitter_handle VARCHAR(100),

  -- Relationship
  parent_company_id UUID REFERENCES companies(id) ON DELETE SET NULL,

  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, customer, partner, competitor, inactive

  -- Ownership
  owner_id UUID,

  -- Custom fields
  custom_fields JSONB DEFAULT '{}',

  -- Tags
  tags TEXT[] DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_companies_tenant ON companies(tenant_id);
CREATE INDEX idx_companies_domain ON companies(domain);
CREATE INDEX idx_companies_owner ON companies(owner_id);

-- Pipelines (multiple pipelines support)
CREATE TABLE pipelines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  name VARCHAR(100) NOT NULL,
  description TEXT,

  -- Configuration
  stages JSONB NOT NULL, -- Array of {name, probability, color}

  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example stages JSONB:
-- [
--   {"name": "New Lead", "probability": 10, "color": "#gray"},
--   {"name": "Qualified", "probability": 30, "color": "#blue"},
--   {"name": "Proposal", "probability": 60, "color": "#yellow"},
--   {"name": "Negotiation", "probability": 80, "color": "#orange"},
--   {"name": "Won", "probability": 100, "color": "#green"}
-- ]

CREATE INDEX idx_pipelines_tenant ON pipelines(tenant_id);

-- Deals (opportunities)
CREATE TABLE deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  name VARCHAR(200) NOT NULL,
  description TEXT,

  -- Pipeline
  pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE RESTRICT,
  stage_index INT NOT NULL DEFAULT 0, -- Index in pipeline.stages array

  -- Value
  value DECIMAL(15,2),
  currency VARCHAR(3) DEFAULT 'EUR',
  probability INT, -- Copied from stage or custom

  -- Relationships
  contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,

  -- Ownership
  owner_id UUID NOT NULL,

  -- Dates
  expected_close_date DATE,
  closed_at TIMESTAMPTZ,

  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'open', -- open, won, lost
  lost_reason VARCHAR(200),

  -- Tracking
  created_from VARCHAR(50), -- 'manual', 'automation', 'import', 'api'
  last_stage_change_at TIMESTAMPTZ,
  days_in_current_stage INT DEFAULT 0,

  -- Custom fields
  custom_fields JSONB DEFAULT '{}',

  -- Tags
  tags TEXT[] DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_deals_tenant ON deals(tenant_id);
CREATE INDEX idx_deals_pipeline ON deals(pipeline_id);
CREATE INDEX idx_deals_contact ON deals(contact_id);
CREATE INDEX idx_deals_company ON deals(company_id);
CREATE INDEX idx_deals_owner ON deals(owner_id);
CREATE INDEX idx_deals_status ON deals(status);
CREATE INDEX idx_deals_close_date ON deals(expected_close_date);

-- Activities (tasks, meetings, calls, notes)
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  type VARCHAR(50) NOT NULL, -- task, meeting, call, note, email
  subject VARCHAR(500) NOT NULL,
  description TEXT,

  -- Status (for tasks)
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, cancelled

  -- Scheduling
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  duration_minutes INT,

  -- Priority
  priority VARCHAR(20) DEFAULT 'normal', -- low, normal, high, urgent

  -- Relationships
  contact_id UUID REFERENCES contacts(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  deal_id UUID REFERENCES deals(id) ON DELETE CASCADE,

  -- Ownership
  owner_id UUID NOT NULL,
  assigned_to_id UUID,

  -- Linked to communications
  message_id UUID, -- Link to svc-communications message

  -- Metadata
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activities_tenant ON activities(tenant_id);
CREATE INDEX idx_activities_contact ON activities(contact_id);
CREATE INDEX idx_activities_company ON activities(company_id);
CREATE INDEX idx_activities_deal ON activities(deal_id);
CREATE INDEX idx_activities_owner ON activities(owner_id);
CREATE INDEX idx_activities_assigned ON activities(assigned_to_id);
CREATE INDEX idx_activities_due ON activities(due_date);
CREATE INDEX idx_activities_status ON activities(status);

-- Lead Scoring Rules
CREATE TABLE scoring_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  name VARCHAR(100) NOT NULL,
  description TEXT,

  event_type VARCHAR(50) NOT NULL, -- email_opened, email_clicked, page_viewed, form_submitted
  points INT NOT NULL,

  -- Conditions (optional)
  conditions JSONB, -- e.g., {"email_subject_contains": "pricing"}

  is_active BOOLEAN DEFAULT true,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_scoring_rules_tenant ON scoring_rules(tenant_id);

-- Score History
CREATE TABLE contact_scores_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,

  scoring_rule_id UUID REFERENCES scoring_rules(id) ON DELETE SET NULL,
  points INT NOT NULL,
  reason VARCHAR(200),

  old_score INT NOT NULL,
  new_score INT NOT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_score_history_contact ON contact_scores_history(contact_id);

-- Automation Workflows
CREATE TABLE workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  name VARCHAR(100) NOT NULL,
  description TEXT,

  -- Trigger
  trigger_type VARCHAR(50) NOT NULL, -- contact_created, deal_stage_changed, email_opened, etc.
  trigger_conditions JSONB, -- Additional filters

  -- Actions
  actions JSONB NOT NULL, -- Array of {type, config}

  is_active BOOLEAN DEFAULT true,

  -- Stats
  executions_count INT DEFAULT 0,
  last_executed_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example actions JSONB:
-- [
--   {"type": "send_email", "config": {"template_id": "uuid", "delay_hours": 0}},
--   {"type": "create_task", "config": {"subject": "Follow up", "due_days": 3}},
--   {"type": "update_field", "config": {"field": "lifecycle_stage", "value": "mql"}},
--   {"type": "assign_owner", "config": {"assignment_type": "round_robin"}},
--   {"type": "webhook", "config": {"url": "https://...", "method": "POST"}}
-- ]

CREATE INDEX idx_workflows_tenant ON workflows(tenant_id);

-- Workflow Execution Log
CREATE TABLE workflow_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,

  contact_id UUID,
  deal_id UUID,

  status VARCHAR(20) NOT NULL, -- success, failed, partial
  actions_completed INT DEFAULT 0,
  actions_failed INT DEFAULT 0,

  error_message TEXT,

  executed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workflow_executions_workflow ON workflow_executions(workflow_id);

-- Custom Fields Definitions
CREATE TABLE custom_field_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  entity_type VARCHAR(50) NOT NULL, -- contact, company, deal
  field_name VARCHAR(100) NOT NULL,
  field_type VARCHAR(50) NOT NULL, -- text, number, date, boolean, select, multi_select

  -- Configuration
  label VARCHAR(200) NOT NULL,
  description TEXT,
  options JSONB, -- For select/multi_select: ["Option 1", "Option 2"]

  is_required BOOLEAN DEFAULT false,
  is_searchable BOOLEAN DEFAULT true,
  is_visible BOOLEAN DEFAULT true,

  display_order INT DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (tenant_id, entity_type, field_name)
);

-- Cascade Settings Tables
CREATE TABLE crm_platform_settings (
  key VARCHAR(100) PRIMARY KEY,
  value JSONB NOT NULL,
  lock_type VARCHAR(20) DEFAULT 'unlocked',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE crm_tenant_settings (
  key VARCHAR(100) NOT NULL,
  tenant_id UUID NOT NULL,
  value JSONB NOT NULL,
  lock_type VARCHAR(20) DEFAULT 'unlocked',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (key, tenant_id)
);

CREATE TABLE crm_user_settings (
  key VARCHAR(100) NOT NULL,
  user_id UUID NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (key, user_id)
);

-- Webhooks (following WEBHOOK_RETRY_STRATEGY.md)
CREATE TABLE crm_webhooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  url TEXT NOT NULL,
  events TEXT[] NOT NULL,
  secret VARCHAR(64) NOT NULL,

  status VARCHAR(20) DEFAULT 'active',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE crm_webhook_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_id UUID NOT NULL REFERENCES crm_webhooks(id) ON DELETE CASCADE,

  event VARCHAR(100) NOT NULL,
  payload JSONB NOT NULL,

  status VARCHAR(20) NOT NULL,
  attempts INT DEFAULT 0,
  max_attempts INT DEFAULT 5,

  next_retry_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,

  response_status INT,
  response_body TEXT,
  error_message TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_crm_webhook_deliveries_status ON crm_webhook_deliveries(status);
CREATE INDEX idx_crm_webhook_deliveries_next_retry ON crm_webhook_deliveries(next_retry_at);
```

## API Endpoints

### Base URL
```
http://localhost:3300/api
```

### Contacts

```http
GET    /api/contacts              # List contacts (with filters)
POST   /api/contacts              # Create contact
GET    /api/contacts/:id          # Get contact details
PUT    /api/contacts/:id          # Update contact
DELETE /api/contacts/:id          # Delete contact

GET    /api/contacts/:id/activities  # Contact activities
GET    /api/contacts/:id/deals       # Contact deals
GET    /api/contacts/:id/timeline    # Full timeline
POST   /api/contacts/:id/score       # Manual score adjustment

POST   /api/contacts/import       # CSV import
POST   /api/contacts/merge        # Merge duplicates
GET    /api/contacts/duplicates   # Find duplicates
```

### Companies

```http
GET    /api/companies             # List companies
POST   /api/companies             # Create company
GET    /api/companies/:id         # Get company
PUT    /api/companies/:id         # Update company
DELETE /api/companies/:id         # Delete company

GET    /api/companies/:id/contacts   # Company contacts
GET    /api/companies/:id/deals      # Company deals
```

### Deals

```http
GET    /api/deals                 # List deals
POST   /api/deals                 # Create deal
GET    /api/deals/:id             # Get deal
PUT    /api/deals/:id             # Update deal
DELETE /api/deals/:id             # Delete deal

PATCH  /api/deals/:id/stage       # Move to different stage
POST   /api/deals/:id/win         # Mark as won
POST   /api/deals/:id/lose        # Mark as lost

GET    /api/deals/forecast        # Revenue forecast
```

### Activities

```http
GET    /api/activities            # List activities
POST   /api/activities            # Create activity
GET    /api/activities/:id        # Get activity
PUT    /api/activities/:id        # Update activity
DELETE /api/activities/:id        # Delete activity

PATCH  /api/activities/:id/complete # Mark as completed
```

### Pipelines

```http
GET    /api/pipelines             # List pipelines
POST   /api/pipelines             # Create pipeline
PUT    /api/pipelines/:id         # Update pipeline
DELETE /api/pipelines/:id         # Delete pipeline

GET    /api/pipelines/:id/deals   # Deals in pipeline (kanban)
```

### Automation

```http
GET    /api/scoring-rules         # List scoring rules
POST   /api/scoring-rules         # Create rule
PUT    /api/scoring-rules/:id     # Update rule
DELETE /api/scoring-rules/:id     # Delete rule

GET    /api/workflows             # List workflows
POST   /api/workflows             # Create workflow
PUT    /api/workflows/:id         # Update workflow
DELETE /api/workflows/:id         # Delete workflow

GET    /api/workflows/:id/executions # Execution history
POST   /api/workflows/:id/test    # Test workflow
```

### Reports

```http
GET    /api/reports/funnel        # Sales funnel
GET    /api/reports/conversion    # Conversion rates
GET    /api/reports/forecast      # Revenue forecast
GET    /api/reports/team          # Team performance
GET    /api/reports/activities    # Activity report
```

### Settings

```http
GET    /api/admin/settings        # Platform settings
PUT    /api/admin/settings/:key   # Update platform setting

GET    /api/settings              # Tenant settings
PUT    /api/settings/:key         # Update tenant setting

GET    /api/user/settings         # User settings
PUT    /api/user/settings/:key    # Update user setting

GET    /api/custom-fields         # List custom fields
POST   /api/custom-fields         # Create custom field
PUT    /api/custom-fields/:id     # Update custom field
DELETE /api/custom-fields/:id     # Delete custom field
```

### Webhooks

```http
GET    /api/webhooks              # List webhooks
POST   /api/webhooks              # Create webhook
PUT    /api/webhooks/:id          # Update webhook
DELETE /api/webhooks/:id          # Delete webhook

GET    /api/webhooks/:id/deliveries
POST   /api/webhooks/deliveries/:id/retry
POST   /api/webhooks/:id/test
```

### System

```http
GET    /health                    # Health check
GET    /dev                       # API documentation
GET    /dev/openapi.json          # OpenAPI spec
```

## Webhook Events

Events emitted by svc-crm:

### Contact Events
- `contact.created`
- `contact.updated`
- `contact.deleted`
- `contact.score_changed`
- `contact.lifecycle_changed`

### Deal Events
- `deal.created`
- `deal.updated`
- `deal.deleted`
- `deal.stage_changed`
- `deal.won`
- `deal.lost`

### Activity Events
- `activity.created`
- `activity.completed`
- `activity.overdue`

### Automation Events
- `workflow.executed`
- `workflow.failed`

## Integration with Other Services

### With svc-communications

When email/SMS/WhatsApp message sent/received:
```typescript
// In svc-communications webhook handler
POST http://localhost:3300/api/integrations/message-event
{
  "event": "message.sent",
  "message_id": "uuid",
  "contact_email": "john@acme.com",
  "subject": "Proposal sent",
  "channel": "email"
}

// svc-crm response:
// - Find contact by email
// - Create activity (email sent)
// - Update contact.last_contacted_at
// - Calculate score if email opened
// - Trigger workflows
```

### With svc-pm (Project Management)

When deal won, create project:
```typescript
// Workflow action: create_project
POST http://localhost:5500/api/pm/projects
{
  "name": "Project for {{company.name}}",
  "client_id": "{{company.id}}",
  "deal_id": "{{deal.id}}",
  "value": "{{deal.value}}"
}
```

### With svc-orders (E-commerce)

Link orders to deals:
```typescript
// When order created
GET http://localhost:3300/api/contacts/search?email={{order.customer_email}}

// Create deal if not exists
POST http://localhost:3300/api/deals
{
  "name": "Order #{{order.number}}",
  "contact_id": "{{contact.id}}",
  "value": "{{order.total}}",
  "status": "won"
}
```

## Settings Cascade Examples

### CRM Settings

```typescript
// Platform settings
{
  "crm.features.scoring_enabled": true, // HARD LOCK
  "crm.limits.max_contacts": 100000,
  "crm.limits.max_pipelines": 10,
  "crm.automation.max_workflows": 50,
}

// Tenant settings
{
  "crm.default_pipeline_id": "uuid",
  "crm.duplicate_detection_fields": ["email", "phone"],
  "crm.deal_required_fields": ["value", "expected_close_date"],
}

// User settings
{
  "crm.view.default_contacts_view": "list", // list, grid, timeline
  "crm.notifications.deal_stage_changed": true,
  "crm.calendar.default_duration": 30, // minutes
}
```

## Lead Scoring Example

### Scoring Rules

```json
[
  {
    "name": "Email opened",
    "event_type": "email_opened",
    "points": 5
  },
  {
    "name": "Email link clicked",
    "event_type": "email_clicked",
    "points": 10
  },
  {
    "name": "Pricing page viewed",
    "event_type": "page_viewed",
    "conditions": {"url_contains": "/pricing"},
    "points": 20
  },
  {
    "name": "Demo requested",
    "event_type": "form_submitted",
    "conditions": {"form_id": "demo-request"},
    "points": 50
  },
  {
    "name": "Email replied",
    "event_type": "email_replied",
    "points": 30
  }
]
```

### Score Calculation

```
Initial score: 0

Day 1:
- Email opened (+5) = 5
- Link clicked (+10) = 15

Day 3:
- Pricing page viewed (+20) = 35
- Email opened again (+5) = 40

Day 5:
- Demo form submitted (+50) = 90
- Lifecycle stage: lead → mql (Marketing Qualified Lead)

Day 7:
- Email replied (+30) = 120
- Lifecycle stage: mql → sql (Sales Qualified Lead)
- Workflow triggered: Assign to sales rep
```

## Workflow Example

### Workflow: New Lead Nurture

```json
{
  "name": "New Lead Nurture Sequence",
  "trigger_type": "contact_created",
  "trigger_conditions": {
    "lifecycle_stage": "lead"
  },
  "actions": [
    {
      "type": "send_email",
      "config": {
        "template_id": "welcome-email",
        "delay_hours": 0
      }
    },
    {
      "type": "create_task",
      "config": {
        "subject": "Review new lead: {{contact.name}}",
        "assigned_to": "owner",
        "due_days": 1
      }
    },
    {
      "type": "send_email",
      "config": {
        "template_id": "education-email-1",
        "delay_hours": 48
      }
    },
    {
      "type": "send_email",
      "config": {
        "template_id": "education-email-2",
        "delay_hours": 120,
        "condition": "score < 50"
      }
    },
    {
      "type": "update_field",
      "config": {
        "field": "lifecycle_stage",
        "value": "mql",
        "condition": "score >= 50"
      }
    },
    {
      "type": "assign_owner",
      "config": {
        "assignment_type": "round_robin",
        "condition": "lifecycle_stage == 'mql'"
      }
    },
    {
      "type": "webhook",
      "config": {
        "url": "https://slack.com/webhook",
        "method": "POST",
        "payload": {
          "text": "New MQL: {{contact.name}} (Score: {{contact.score}})"
        }
      }
    }
  ]
}
```

## Frontend UI Examples

### Dashboard

```typescript
function DashboardView() {
  return (
    <div className="grid grid-cols-4 gap-4">
      {/* Metrics */}
      <MetricCard
        title="Total Contacts"
        value="1,247"
        change="+12%"
        trend="up"
      />
      <MetricCard
        title="Active Deals"
        value="42"
        change="-3%"
        trend="down"
      />
      <MetricCard
        title="Weighted Pipeline"
        value="€450K"
        change="+8%"
        trend="up"
      />
      <MetricCard
        title="This Month's Revenue"
        value="€120K"
        change="+23%"
        trend="up"
      />

      {/* Charts */}
      <div className="col-span-2">
        <SalesFunnelChart />
      </div>
      <div className="col-span-2">
        <RevenueForecastChart />
      </div>

      {/* Recent activities */}
      <div className="col-span-2">
        <RecentActivities />
      </div>

      {/* Upcoming tasks */}
      <div className="col-span-2">
        <UpcomingTasks />
      </div>
    </div>
  );
}
```

### Pipeline Kanban

```typescript
function PipelineView() {
  const { deals, moveD deal } = useDeals();
  const { stages } = usePipeline();

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      <div className="flex gap-4 overflow-x-auto">
        {stages.map(stage => (
          <Droppable key={stage.id} droppableId={stage.id}>
            {(provided) => (
              <div
                ref={provided.innerRef}
                className="min-w-[300px] bg-gray-100 p-4 rounded"
              >
                <h3>{stage.name}</h3>
                <p>€{calculateStageValue(stage)} ({stage.probability}%)</p>

                {deals
                  .filter(d => d.stage_index === stage.index)
                  .map((deal, index) => (
                    <Draggable key={deal.id} draggableId={deal.id} index={index}>
                      {(provided) => (
                        <DealCard
                          ref={provided.innerRef}
                          {...provided.draggableProps}
                          {...provided.dragHandleProps}
                          deal={deal}
                        />
                      )}
                    </Draggable>
                  ))}

                {provided.placeholder}
              </div>
            )}
          </Droppable>
        ))}
      </div>
    </DragDropContext>
  );
}
```

### Contact Timeline

```typescript
function ContactTimeline({ contactId }: Props) {
  const { activities } = useActivities(contactId);

  return (
    <div className="relative">
      <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-gray-300" />

      {activities.map(activity => (
        <div key={activity.id} className="relative pl-10 pb-8">
          <div className="absolute left-2 w-4 h-4 rounded-full bg-blue-500" />

          <div className="bg-white p-4 rounded shadow">
            <div className="flex justify-between">
              <span className="font-medium">{activity.subject}</span>
              <time>{formatRelative(activity.created_at)}</time>
            </div>

            <p className="text-gray-600">{activity.description}</p>

            {activity.type === 'email' && (
              <EmailPreview messageId={activity.message_id} />
            )}
          </div>
        </div>
      ))}
    </div>
  );
}
```

## Security

- JWT authentication
- Row-level security (tenant isolation)
- Encrypted custom fields (optional)
- Audit logs for sensitive operations
- GDPR compliance (data export/deletion)

## Performance

- Database indexes on all foreign keys
- Redis caching for frequently accessed data
- Pagination for large lists
- Background jobs for scoring/automation
- WebSocket for real-time updates

## Monitoring

Health check returns:
```json
{
  "status": "healthy",
  "service": "svc-crm",
  "version": "1.0.0",
  "dependencies": {
    "database": "healthy",
    "redis": "healthy",
    "svc-communications": "healthy"
  },
  "stats": {
    "total_contacts": 1247,
    "active_deals": 42,
    "pending_activities": 89
  }
}
```

---

**Status**: Architecture complete, ready for implementation
**Last Updated**: 2025-10-14
**Author**: EWH Platform Team
