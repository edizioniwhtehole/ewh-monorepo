# EWH Custom Workflow Engine - Specification

## 🎯 Obiettivo

Creare un workflow automation engine **proprietario e multi-tenant nativo** che sostituisca n8n per il sistema EWH.

## 📐 Vantaggi rispetto a n8n

| Feature | n8n | EWH Custom Engine |
|---------|-----|-------------------|
| Multi-tenant | ❌ No | ✅ Nativo |
| Request/Response matching | ⚠️ Manuale | ✅ Automatico (correlation_id) |
| Tenant isolation | ⚠️ Schema/Container | ✅ Row-level (tenant_id) |
| Customizzazione | ⚠️ Limitata | ✅ Totale |
| Integrazione EWH | ⚠️ Via API | ✅ Diretta |
| Costo | 💰 Self-host OK | ✅ Gratuito |
| Learning curve | ⚠️ Alta | ✅ Bassa (TUO) |

## 🏗️ Architettura

```
┌─────────────────────────────────────────────────────────┐
│                     Frontend                            │
│  - Visual workflow editor (React Flow)                  │
│  - Tenant-scoped workflow list                          │
│  - Execution history & logs                             │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│            svc-workflow-engine (Core)                   │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Trigger    │  │   Executor   │  │   Context    │ │
│  │   Handler    │  │   Engine     │  │   Manager    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
│  - Tenant isolation (tenant_id in ogni query)           │
│  - Correlation ID tracking                              │
│  - Step-by-step execution                               │
│  - Error handling & retry                               │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │PostgreSQL│    │  Redis   │    │ Services │
    │ (Persist)│    │ (Context)│    │ (Actions)│
    └──────────┘    └──────────┘    └──────────┘
```

## 📊 Database Schema

```sql
-- Workflow definitions
CREATE TABLE workflow.workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  created_by UUID NOT NULL REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  trigger_type VARCHAR(50) NOT NULL, -- webhook, schedule, event
  trigger_config JSONB NOT NULL,
  steps JSONB NOT NULL,
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Tenant isolation index
  CONSTRAINT workflows_tenant_idx UNIQUE(tenant_id, id)
);

-- Row-level security
ALTER TABLE workflow.workflows ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON workflow.workflows
  USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- Execution history
CREATE TABLE workflow.executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES workflow.workflows(id),
  tenant_id UUID NOT NULL, -- Denormalized for performance
  correlation_id UUID NOT NULL UNIQUE,
  status VARCHAR(20) NOT NULL, -- pending, running, success, failed
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  steps_completed JSONB, -- Track each step result
  error_message TEXT,
  context JSONB, -- Input data
  result JSONB -- Output data
);

CREATE INDEX executions_tenant_workflow_idx
  ON workflow.executions(tenant_id, workflow_id, started_at DESC);

CREATE INDEX executions_correlation_idx
  ON workflow.executions(correlation_id);

-- Triggers (webhook endpoints)
CREATE TABLE workflow.webhook_triggers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES workflow.workflows(id),
  tenant_id UUID NOT NULL,
  path VARCHAR(255) NOT NULL,
  method VARCHAR(10) DEFAULT 'POST',

  CONSTRAINT webhook_triggers_unique UNIQUE(tenant_id, path)
);
```

## 🎨 Workflow Definition Format

```typescript
interface Workflow {
  id: string;
  tenant_id: string;
  created_by: string;
  name: string;
  description?: string;
  enabled: boolean;

  trigger: Trigger;
  steps: Step[];
}

type Trigger =
  | WebhookTrigger
  | ScheduleTrigger
  | EventTrigger;

interface WebhookTrigger {
  type: 'webhook';
  path: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  auth_required: boolean;
}

interface ScheduleTrigger {
  type: 'schedule';
  cron: string; // "0 9 * * *"
  timezone: string;
}

interface EventTrigger {
  type: 'event';
  event_name: string; // "asset.uploaded", "user.created"
  filter?: Record<string, any>;
}

type Step =
  | HttpRequestStep
  | ConditionStep
  | TransformStep
  | NotificationStep
  | DatabaseQueryStep
  | DelayStep;

interface HttpRequestStep {
  type: 'http_request';
  id: string;
  name: string;
  url: string; // Supports templates: "{{trigger.asset_id}}"
  method: string;
  headers?: Record<string, string>;
  body?: any;
  timeout_ms?: number;
  retry?: {
    max_attempts: number;
    delay_ms: number;
  };
}

interface ConditionStep {
  type: 'condition';
  id: string;
  name: string;
  condition: string; // JavaScript expression
  then: Step[];
  else?: Step[];
}

interface TransformStep {
  type: 'transform';
  id: string;
  name: string;
  script: string; // JavaScript code
  output_variable: string;
}

interface NotificationStep {
  type: 'notification';
  id: string;
  name: string;
  service: 'email' | 'slack' | 'internal';
  template: string;
  recipients: string[]; // User IDs or emails
  data: Record<string, any>;
}
```

## 🔄 Execution Flow con Correlation ID

```typescript
// 1. Trigger riceve richiesta
app.post('/webhook/:tenant_id/:path', async (req, res) => {
  // Genera correlation ID unico
  const correlationId = crypto.randomUUID();

  // Salva context in Redis (TTL 24h)
  await redis.setex(`correlation:${correlationId}`, 86400, JSON.stringify({
    tenant_id: req.params.tenant_id,
    user_id: req.user?.id,
    triggered_at: Date.now(),
    trigger_data: req.body
  }));

  // Crea execution record
  const execution = await db.query(`
    INSERT INTO workflow.executions (
      workflow_id, tenant_id, correlation_id, status, context
    ) VALUES ($1, $2, $3, 'pending', $4)
    RETURNING id
  `, [workflowId, tenantId, correlationId, req.body]);

  // Ritorna subito (async processing)
  res.json({
    correlation_id: correlationId,
    execution_id: execution.id,
    status: 'pending'
  });

  // Esegui workflow in background
  executeWorkflow(workflowId, correlationId);
});

// 2. Executor processa step
async function executeWorkflow(workflowId: string, correlationId: string) {
  // Recupera context
  const context = await redis.get(`correlation:${correlationId}`);
  const { tenant_id, trigger_data } = JSON.parse(context);

  // Set tenant context per RLS
  await db.query(`SET LOCAL app.tenant_id = '${tenant_id}'`);

  // Get workflow (automaticamente filtrato per tenant grazie a RLS)
  const workflow = await db.query(`
    SELECT * FROM workflow.workflows WHERE id = $1
  `, [workflowId]);

  // Esegui steps
  let stepResults = {};
  for (const step of workflow.steps) {
    try {
      const result = await executeStep(step, {
        ...context,
        previous_steps: stepResults
      });

      stepResults[step.id] = result;

      // Update execution record
      await db.query(`
        UPDATE workflow.executions
        SET steps_completed = steps_completed || $1::jsonb
        WHERE correlation_id = $2
      `, [JSON.stringify({ [step.id]: result }), correlationId]);

    } catch (error) {
      // Log error e continua o ferma
      await db.query(`
        UPDATE workflow.executions
        SET status = 'failed', error_message = $1
        WHERE correlation_id = $2
      `, [error.message, correlationId]);
      break;
    }
  }

  // Mark as completed
  await db.query(`
    UPDATE workflow.executions
    SET status = 'success', completed_at = NOW(), result = $1
    WHERE correlation_id = $2
  `, [JSON.stringify(stepResults), correlationId]);
}

// 3. Risposta viene matchata automaticamente
app.get('/workflow/status/:correlation_id', async (req, res) => {
  const { correlation_id } = req.params;

  // Recupera execution (tenant_id automaticamente verificato via JWT)
  const execution = await db.query(`
    SELECT * FROM workflow.executions
    WHERE correlation_id = $1 AND tenant_id = $2
  `, [correlation_id, req.tenant_id]);

  // Garantito: risposta va solo al tenant corretto!
  res.json(execution);
});
```

## 🎨 Visual Editor (Frontend)

```typescript
// Using React Flow for visual workflow builder
import ReactFlow, { Node, Edge } from 'reactflow';

const WorkflowEditor = () => {
  const [nodes, setNodes] = useState<Node[]>([
    {
      id: 'trigger',
      type: 'trigger',
      data: { type: 'webhook', path: '/asset-uploaded' },
      position: { x: 0, y: 0 }
    },
    {
      id: 'step1',
      type: 'http',
      data: { url: 'http://svc-media:4003/assets/{{id}}' },
      position: { x: 0, y: 100 }
    },
    {
      id: 'step2',
      type: 'condition',
      data: { condition: '{{step1.type}} === "image"' },
      position: { x: 0, y: 200 }
    }
  ]);

  const [edges, setEdges] = useState<Edge[]>([
    { id: 'e1', source: 'trigger', target: 'step1' },
    { id: 'e2', source: 'step1', target: 'step2' }
  ]);

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      onNodesChange={onNodesChange}
      onEdgesChange={onEdgesChange}
    />
  );
};
```

## 🔐 Sicurezza Multi-Tenant

### 1. Row-Level Security (PostgreSQL)

```sql
-- Ogni query automaticamente filtrata per tenant
SET app.tenant_id = 'tenant-123';

-- Questa query vede solo workflow del tenant
SELECT * FROM workflow.workflows;
-- Internamente diventa:
-- SELECT * FROM workflow.workflows WHERE tenant_id = 'tenant-123';
```

### 2. Correlation ID Validation

```typescript
// Impossibile accedere execution di altro tenant
const execution = await getExecution(correlationId, req.tenant_id);
// Se correlation_id appartiene a tenant diverso → 404
```

### 3. Sandbox per JavaScript

```typescript
import { VM } from 'vm2';

// Esegui user code in sandbox sicuro
const vm = new VM({
  timeout: 5000,
  sandbox: {
    // Solo variabili safe
    trigger: triggerData,
    steps: stepResults,
    // NO access a: process, require, filesystem
  }
});

const result = vm.run(step.script);
```

## 📊 Monitoring & Observability

```typescript
// Ogni execution tracciata
interface ExecutionMetrics {
  tenant_id: string;
  workflow_id: string;
  correlation_id: string;
  duration_ms: number;
  steps_executed: number;
  status: 'success' | 'failed';
  error?: string;
}

// Dashboard per tenant
app.get('/workflows/:workflow_id/metrics', async (req, res) => {
  const metrics = await db.query(`
    SELECT
      DATE_TRUNC('day', started_at) as date,
      COUNT(*) as total_executions,
      AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_duration_sec,
      COUNT(*) FILTER (WHERE status = 'success') as successes,
      COUNT(*) FILTER (WHERE status = 'failed') as failures
    FROM workflow.executions
    WHERE workflow_id = $1 AND tenant_id = $2
    GROUP BY date
    ORDER BY date DESC
  `, [req.params.workflow_id, req.tenant_id]);

  res.json(metrics);
});
```

## 🚀 Implementazione Steps

### Phase 1: Core Engine (1-2 settimane)
- [ ] Database schema
- [ ] Basic workflow executor
- [ ] HTTP request step
- [ ] Webhook triggers
- [ ] Correlation ID system

### Phase 2: Visual Editor (1-2 settimane)
- [ ] React Flow integration
- [ ] Drag & drop workflow builder
- [ ] Step configuration UI
- [ ] Test execution UI

### Phase 3: Advanced Steps (2 settimane)
- [ ] Condition step
- [ ] Transform step (JavaScript sandbox)
- [ ] Database query step
- [ ] Notification step
- [ ] Scheduled triggers

### Phase 4: Production Ready (1 settimana)
- [ ] Error handling & retry
- [ ] Rate limiting
- [ ] Monitoring dashboard
- [ ] API documentation
- [ ] Performance optimization

## 💡 Esempi Workflow

### Esempio 1: Asset Upload Notification

```json
{
  "name": "Notifica upload asset",
  "trigger": {
    "type": "webhook",
    "path": "/asset-uploaded"
  },
  "steps": [
    {
      "type": "http_request",
      "name": "Get asset details",
      "url": "http://svc-media:4003/assets/{{trigger.asset_id}}",
      "method": "GET"
    },
    {
      "type": "condition",
      "name": "Check if image",
      "condition": "{{step1.response.type}} === 'image'",
      "then": [
        {
          "type": "notification",
          "name": "Notify user",
          "service": "internal",
          "recipients": ["{{trigger.user_id}}"],
          "template": "asset_ready",
          "data": {
            "asset_name": "{{step1.response.name}}",
            "asset_url": "{{step1.response.url}}"
          }
        }
      ]
    }
  ]
}
```

### Esempio 2: Daily Report

```json
{
  "name": "Report giornaliero asset",
  "trigger": {
    "type": "schedule",
    "cron": "0 9 * * *",
    "timezone": "Europe/Rome"
  },
  "steps": [
    {
      "type": "database_query",
      "name": "Count new assets",
      "query": "SELECT COUNT(*) FROM assets WHERE created_at > NOW() - INTERVAL '1 day'"
    },
    {
      "type": "notification",
      "name": "Send report",
      "service": "email",
      "recipients": ["admin@example.com"],
      "template": "daily_report",
      "data": {
        "new_assets": "{{step1.result[0].count}}"
      }
    }
  ]
}
```

## 🎓 Vantaggi Finali

1. **Multi-tenant nativo** ✅
2. **Request/Response matching garantito** ✅ (correlation_id)
3. **Sicurezza forte** ✅ (RLS + tenant_id)
4. **Personalizzabile** ✅ (codice tuo)
5. **Performance** ✅ (nessun overhead n8n)
6. **Cost-effective** ✅ (no licenze)
7. **Integration** ✅ (accesso diretto DB e servizi)

## 🤔 Quando usare questo vs n8n?

**Usa Custom Engine se:**
- Multi-tenancy è critico
- Vuoi controllo totale
- Hai team di sviluppo
- Workflow semplici (HTTP, DB, notifiche)

**Usa n8n se:**
- Hai bisogno di 300+ integrazioni prebuilt
- Team non-tecnico crea workflow
- Deployment single-tenant OK

## 📚 Librerie Consigliate

- **Executor**: `node-cron`, `bull` (job queue)
- **Sandbox**: `vm2`, `isolated-vm`
- **Visual Editor**: `react-flow`, `rete.js`
- **Template Engine**: `handlebars`, `liquidjs`
- **Validation**: `zod`, `ajv`
