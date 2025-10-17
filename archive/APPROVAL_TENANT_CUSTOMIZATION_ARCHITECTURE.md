# Tenant-Customizable Approval System Architecture

## Overview

Sistema di approval **completamente modulare e tenant-customizable** che permette di:
- Creare widget personalizzati con page editor
- Definire route dedicate per flussi custom
- Mappare campi tra sistemi diversi
- Caricare script/plugin personalizzati senza deploy
- Personalizzare per tenant senza rilasciare nuove versioni

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Tenant Configuration                      │
│  (JSON/YAML config per tenant con widget, routes, scripts)  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Widget Registry System                     │
│        (Custom approval cards, forms, editors)               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Route Engine + Mapper                      │
│       (Dynamic routes, field mapping, transformations)       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Script Runner Sandbox                      │
│     (Isolated VM for tenant scripts with quota/limits)       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Core Approval Engine                       │
│            (Base approval logic, immutable)                  │
└─────────────────────────────────────────────────────────────┘
```

## 1. Tenant Configuration Schema

```typescript
// Stored in database: approvals.tenant_customizations
interface TenantCustomization {
  tenant_id: string;

  // Custom widgets
  widgets: WidgetDefinition[];

  // Custom routes
  routes: RouteDefinition[];

  // Field mappings
  field_mappings: FieldMappingDefinition[];

  // Custom scripts
  scripts: ScriptDefinition[];

  // Approval type overrides
  approval_type_overrides: Record<string, ApprovalTypeOverride>;

  // Feature flags
  features: Record<string, boolean>;

  version: string;
  updated_at: string;
}
```

### Database Schema

```sql
-- Tenant customization configurations
CREATE TABLE approvals.tenant_customizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL UNIQUE,
  config JSONB NOT NULL, -- Full configuration object
  version VARCHAR(20) NOT NULL DEFAULT '1.0.0',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_tenant_customizations_tenant ON approvals.tenant_customizations(tenant_id);

-- Widget definitions (referenceable across tenants)
CREATE TABLE approvals.widget_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID, -- NULL = global widget
  widget_key VARCHAR(100) NOT NULL,
  widget_type VARCHAR(50) NOT NULL, -- preview, editor, form, card
  component_source TEXT NOT NULL, -- React component code or page builder JSON
  props_schema JSONB NOT NULL, -- Zod schema as JSON
  metadata JSONB DEFAULT '{}',
  is_public BOOLEAN DEFAULT false, -- Can other tenants use it?
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_tenant_widget_key UNIQUE (tenant_id, widget_key)
);

CREATE INDEX idx_widget_definitions_tenant ON approvals.widget_definitions(tenant_id);
CREATE INDEX idx_widget_definitions_public ON approvals.widget_definitions(is_public) WHERE is_public = true;

-- Custom scripts (sandboxed execution)
CREATE TABLE approvals.tenant_scripts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  script_key VARCHAR(100) NOT NULL,
  script_type VARCHAR(50) NOT NULL, -- validation, transform, hook, lifecycle
  source_code TEXT NOT NULL,
  language VARCHAR(20) DEFAULT 'javascript', -- javascript, typescript, lua
  execution_quota JSONB DEFAULT '{"max_time_ms": 5000, "max_memory_mb": 128}',
  is_active BOOLEAN DEFAULT true,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_tenant_script_key UNIQUE (tenant_id, script_key)
);

CREATE INDEX idx_tenant_scripts_tenant ON approvals.tenant_scripts(tenant_id);
CREATE INDEX idx_tenant_scripts_active ON approvals.tenant_scripts(tenant_id, is_active);

-- Script execution logs (audit + debugging)
CREATE TABLE approvals.script_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  script_id UUID NOT NULL REFERENCES approvals.tenant_scripts(id),
  tenant_id UUID NOT NULL,
  approval_id UUID REFERENCES approvals.approval_items(id),
  input_data JSONB,
  output_data JSONB,
  execution_time_ms INTEGER,
  memory_used_mb DECIMAL(10,2),
  error TEXT,
  status VARCHAR(20) NOT NULL, -- success, error, timeout, quota_exceeded
  executed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_script_executions_script ON approvals.script_executions(script_id);
CREATE INDEX idx_script_executions_approval ON approvals.script_executions(approval_id);
CREATE INDEX idx_script_executions_tenant_time ON approvals.script_executions(tenant_id, executed_at DESC);

-- Field mappings (transform data between systems)
CREATE TABLE approvals.field_mappings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  mapping_key VARCHAR(100) NOT NULL,
  source_schema JSONB NOT NULL, -- Source field definitions
  target_schema JSONB NOT NULL, -- Target field definitions
  transformation_rules JSONB NOT NULL, -- Array of transform rules
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_tenant_mapping_key UNIQUE (tenant_id, mapping_key)
);

CREATE INDEX idx_field_mappings_tenant ON approvals.field_mappings(tenant_id);

-- Custom routes
CREATE TABLE approvals.custom_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  route_key VARCHAR(100) NOT NULL,
  http_method VARCHAR(10) NOT NULL,
  path_pattern TEXT NOT NULL,
  handler_script_id UUID REFERENCES approvals.tenant_scripts(id),
  middleware_script_ids UUID[], -- Array of script IDs
  auth_required BOOLEAN DEFAULT true,
  rate_limit_per_hour INTEGER DEFAULT 1000,
  is_active BOOLEAN DEFAULT true,
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_tenant_route UNIQUE (tenant_id, http_method, path_pattern)
);

CREATE INDEX idx_custom_routes_tenant_active ON approvals.custom_routes(tenant_id, is_active);
```

## 2. Widget System (Page Builder Integration)

### Widget Definition Format

```typescript
// Widget created with page editor
interface WidgetDefinition {
  id: string;
  widget_key: string; // e.g., "acme_corp.expense_card"
  widget_type: 'preview' | 'editor' | 'form' | 'card' | 'detail';

  // Component source (2 options)
  component_source: {
    type: 'page_builder_json' | 'react_code' | 'remote_url';

    // Option 1: Page builder JSON (preferred)
    page_builder_json?: {
      version: '1.0',
      components: GrapesJSComponent[],
      styles: string,
      scripts: string
    };

    // Option 2: React component code (advanced)
    react_code?: string;

    // Option 3: Remote URL (lazy load)
    remote_url?: string;
  };

  // Props schema (validation)
  props_schema: {
    type: 'object',
    properties: Record<string, ZodSchema>;
    required: string[];
  };

  // Metadata
  metadata: {
    name: string;
    description: string;
    thumbnail_url?: string;
    category: string;
    tags: string[];
  };
}
```

### Example: Expense Widget with Page Builder

```json
{
  "id": "widget-uuid-123",
  "widget_key": "acme_corp.expense_preview",
  "widget_type": "preview",
  "component_source": {
    "type": "page_builder_json",
    "page_builder_json": {
      "version": "1.0",
      "components": [
        {
          "tagName": "div",
          "attributes": { "class": "expense-card p-4 border rounded-lg" },
          "components": [
            {
              "tagName": "h3",
              "attributes": { "class": "text-xl font-bold" },
              "content": "{{metadata.employee_name}}"
            },
            {
              "tagName": "div",
              "attributes": { "class": "grid grid-cols-2 gap-4 mt-4" },
              "components": [
                {
                  "tagName": "div",
                  "components": [
                    {
                      "tagName": "label",
                      "content": "Total Amount"
                    },
                    {
                      "tagName": "p",
                      "attributes": { "class": "text-2xl font-bold" },
                      "content": "{{metadata.total_amount | currency}}"
                    }
                  ]
                },
                {
                  "tagName": "div",
                  "components": [
                    {
                      "tagName": "label",
                      "content": "Receipts"
                    },
                    {
                      "tagName": "p",
                      "content": "{{metadata.receipts.length}} items"
                    }
                  ]
                }
              ]
            }
          ]
        }
      ],
      "styles": ".expense-card { background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }",
      "scripts": "/* Custom interactions if needed */"
    }
  },
  "props_schema": {
    "type": "object",
    "properties": {
      "approval": {
        "type": "object",
        "properties": {
          "metadata": {
            "type": "object",
            "properties": {
              "employee_name": { "type": "string" },
              "total_amount": { "type": "number" },
              "receipts": { "type": "array" }
            }
          }
        }
      }
    },
    "required": ["approval"]
  },
  "metadata": {
    "name": "Expense Preview Card",
    "description": "Custom expense approval preview for ACME Corp",
    "category": "finance",
    "tags": ["expense", "finance", "preview"]
  }
}
```

### Widget Renderer Component

```typescript
// app-approvals-frontend/src/components/WidgetRenderer.tsx
import React from 'react';
import { WidgetDefinition } from '@/types';

interface WidgetRendererProps {
  widget: WidgetDefinition;
  props: Record<string, any>;
}

export function WidgetRenderer({ widget, props }: WidgetRendererProps) {
  // Validate props against schema
  const validated = widget.props_schema.parse(props);

  switch (widget.component_source.type) {
    case 'page_builder_json':
      return <PageBuilderWidget definition={widget.component_source.page_builder_json} data={validated} />;

    case 'react_code':
      return <DynamicReactWidget code={widget.component_source.react_code} props={validated} />;

    case 'remote_url':
      return <RemoteWidget url={widget.component_source.remote_url} props={validated} />;

    default:
      throw new Error(`Unknown widget source type: ${widget.component_source.type}`);
  }
}

// Page builder JSON renderer
function PageBuilderWidget({ definition, data }) {
  const html = renderPageBuilderJSON(definition.components, data);

  return (
    <div
      dangerouslySetInnerHTML={{ __html: html }}
      className="widget-container"
    />
  );
}

// Template interpolation
function renderPageBuilderJSON(components, data) {
  return components.map(component => {
    let content = component.content || '';

    // Replace {{metadata.field}} with actual data
    content = content.replace(/\{\{([^}]+)\}\}/g, (match, path) => {
      const [field, ...filters] = path.split('|').map(s => s.trim());
      let value = getNestedValue(data, field);

      // Apply filters (e.g., currency, date)
      filters.forEach(filter => {
        value = applyFilter(value, filter);
      });

      return value;
    });

    return `<${component.tagName} ${renderAttributes(component.attributes)}>
      ${content}
      ${component.components ? renderPageBuilderJSON(component.components, data) : ''}
    </${component.tagName}>`;
  }).join('');
}
```

## 3. Custom Routes System

### Route Definition

```typescript
interface RouteDefinition {
  id: string;
  route_key: string; // e.g., "acme_corp.bulk_expense_approve"
  http_method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  path_pattern: string; // e.g., "/api/custom/expenses/bulk-approve"

  // Handler script
  handler_script_id: string;

  // Middleware stack
  middleware_script_ids: string[];

  // Auth & limits
  auth_required: boolean;
  required_permissions: string[];
  rate_limit_per_hour: number;

  // Request/response schemas
  request_schema?: ZodSchema;
  response_schema?: ZodSchema;
}
```

### Dynamic Route Registration

```typescript
// svc-approvals/src/plugins/custom-routes.ts
import { FastifyInstance } from 'fastify';
import { ScriptRunner } from '../services/script-runner';

export async function registerCustomRoutes(app: FastifyInstance, tenantId: string) {
  // Load tenant's custom routes from DB
  const routes = await db.query(`
    SELECT r.*, s.source_code, s.language
    FROM approvals.custom_routes r
    JOIN approvals.tenant_scripts s ON r.handler_script_id = s.id
    WHERE r.tenant_id = $1 AND r.is_active = true
  `, [tenantId]);

  for (const route of routes.rows) {
    const method = route.http_method.toLowerCase();
    const path = `/api/tenants/${tenantId}${route.path_pattern}`;

    app[method](path, {
      schema: {
        body: route.request_schema,
        response: { 200: route.response_schema }
      },
      preHandler: route.auth_required ? [app.authenticate] : [],
      handler: async (request, reply) => {
        // Rate limiting check
        await checkRateLimit(tenantId, route.id, route.rate_limit_per_hour);

        // Execute handler script
        const scriptRunner = new ScriptRunner({
          tenantId,
          scriptId: route.handler_script_id,
          language: route.language,
          sourceCode: route.source_code
        });

        try {
          const result = await scriptRunner.execute({
            request: {
              params: request.params,
              query: request.query,
              body: request.body,
              headers: request.headers,
              user: request.user
            }
          });

          reply.code(result.statusCode || 200).send(result.body);
        } catch (error) {
          app.log.error({ error, route: route.route_key }, 'Custom route execution failed');
          reply.code(500).send({ error: 'Script execution failed' });
        }
      }
    });

    app.log.info({ path, method }, `Registered custom route: ${route.route_key}`);
  }
}
```

### Example: Bulk Expense Approval Route

```typescript
// Stored in approvals.tenant_scripts
const bulkExpenseApproveScript = `
// Handler script for bulk expense approval
export async function handler({ request, context }) {
  const { expense_ids, approval_decision } = request.body;

  // Validate user has bulk approval permission
  if (!context.user.permissions.includes('expense.bulk_approve')) {
    return {
      statusCode: 403,
      body: { error: 'Insufficient permissions' }
    };
  }

  // Custom business logic
  const results = [];
  for (const expenseId of expense_ids) {
    // Check expense amount threshold
    const expense = await context.db.query(
      'SELECT metadata FROM approvals.approval_items WHERE id = $1',
      [expenseId]
    );

    const amount = expense.rows[0].metadata.total_amount;

    // Custom rule: amounts > $5000 require CFO approval
    if (amount > 5000 && context.user.role !== 'cfo') {
      results.push({
        expense_id: expenseId,
        status: 'escalated',
        reason: 'Amount exceeds manager approval limit'
      });

      // Auto-escalate to CFO
      await context.services.approvals.escalate(expenseId, {
        escalate_to_role: 'cfo',
        reason: 'Amount > $5000'
      });

      continue;
    }

    // Approve expense
    await context.services.approvals.approve(expenseId, {
      approved_by: context.user.id,
      decision: approval_decision,
      notes: 'Bulk approved'
    });

    results.push({
      expense_id: expenseId,
      status: 'approved'
    });
  }

  return {
    statusCode: 200,
    body: {
      total: expense_ids.length,
      approved: results.filter(r => r.status === 'approved').length,
      escalated: results.filter(r => r.status === 'escalated').length,
      results
    }
  };
}
`;
```

## 4. Field Mapping System

### Mapping Definition

```typescript
interface FieldMappingDefinition {
  id: string;
  mapping_key: string; // e.g., "sap_to_dam_asset"

  source_schema: {
    system: string; // e.g., "SAP", "Salesforce", "DAM"
    fields: FieldDefinition[];
  };

  target_schema: {
    system: string;
    fields: FieldDefinition[];
  };

  transformation_rules: TransformRule[];
}

interface TransformRule {
  source_field: string;
  target_field: string;
  transform_type: 'direct' | 'computed' | 'conditional' | 'script';

  // For computed
  expression?: string; // e.g., "source.price * 1.22" (add VAT)

  // For conditional
  conditions?: Array<{
    if: string; // e.g., "source.country === 'US'"
    then: any;
    else?: any;
  }>;

  // For script
  script_id?: string;
}
```

### Example: SAP → DAM Asset Mapping

```json
{
  "mapping_key": "sap_product_to_dam_asset",
  "source_schema": {
    "system": "SAP",
    "fields": [
      { "name": "MATNR", "type": "string", "label": "Material Number" },
      { "name": "MAKTX", "type": "string", "label": "Material Description" },
      { "name": "MTART", "type": "string", "label": "Material Type" },
      { "name": "BRGEW", "type": "number", "label": "Gross Weight" },
      { "name": "GEWEI", "type": "string", "label": "Weight Unit" }
    ]
  },
  "target_schema": {
    "system": "DAM",
    "fields": [
      { "name": "title", "type": "string" },
      { "name": "sku", "type": "string" },
      { "name": "category", "type": "string" },
      { "name": "metadata", "type": "object" }
    ]
  },
  "transformation_rules": [
    {
      "source_field": "MAKTX",
      "target_field": "title",
      "transform_type": "direct"
    },
    {
      "source_field": "MATNR",
      "target_field": "sku",
      "transform_type": "direct"
    },
    {
      "source_field": "MTART",
      "target_field": "category",
      "transform_type": "conditional",
      "conditions": [
        { "if": "source.MTART === 'FERT'", "then": "finished_goods" },
        { "if": "source.MTART === 'ROH'", "then": "raw_materials" },
        { "else": "other" }
      ]
    },
    {
      "source_field": ["BRGEW", "GEWEI"],
      "target_field": "metadata.weight",
      "transform_type": "computed",
      "expression": "{ value: source.BRGEW, unit: source.GEWEI }"
    }
  ]
}
```

### Field Mapper Engine

```typescript
// svc-approvals/src/services/field-mapper.ts
export class FieldMapper {
  async transform(
    mappingKey: string,
    sourceData: Record<string, any>,
    tenantId: string
  ): Promise<Record<string, any>> {
    // Load mapping definition
    const mapping = await this.loadMapping(mappingKey, tenantId);

    const result: Record<string, any> = {};

    for (const rule of mapping.transformation_rules) {
      const value = await this.applyRule(rule, sourceData, tenantId);
      this.setNestedValue(result, rule.target_field, value);
    }

    // Validate against target schema
    await this.validateAgainstSchema(result, mapping.target_schema);

    return result;
  }

  private async applyRule(
    rule: TransformRule,
    sourceData: Record<string, any>,
    tenantId: string
  ): Promise<any> {
    switch (rule.transform_type) {
      case 'direct':
        return this.getNestedValue(sourceData, rule.source_field);

      case 'computed':
        return this.evaluateExpression(rule.expression, sourceData);

      case 'conditional':
        return this.evaluateConditions(rule.conditions, sourceData);

      case 'script':
        return await this.executeTransformScript(rule.script_id, sourceData, tenantId);

      default:
        throw new Error(`Unknown transform type: ${rule.transform_type}`);
    }
  }

  private evaluateExpression(expression: string, data: Record<string, any>): any {
    // Safe expression evaluation (use a sandboxed evaluator)
    const sandbox = {
      source: data,
      Math,
      Date,
      // Whitelist safe functions
    };

    return new Function('sandbox', `with(sandbox) { return ${expression}; }`)(sandbox);
  }
}
```

## 5. Script Runner (Sandboxed Execution)

### Script Execution Environment

```typescript
// svc-approvals/src/services/script-runner.ts
import { VM } from 'vm2';
import { createHash } from 'crypto';

export class ScriptRunner {
  private vm: VM;
  private tenantId: string;
  private scriptId: string;

  constructor(config: {
    tenantId: string;
    scriptId: string;
    language: string;
    sourceCode: string;
  }) {
    this.tenantId = config.tenantId;
    this.scriptId = config.scriptId;

    // Create sandboxed VM
    this.vm = new VM({
      timeout: 5000, // 5 seconds max
      sandbox: this.createSandbox(),
      eval: false,
      wasm: false
    });

    // Load script
    this.vm.run(config.sourceCode);
  }

  private createSandbox() {
    return {
      // Safe globals
      console: {
        log: (...args) => this.log('info', args),
        error: (...args) => this.log('error', args),
        warn: (...args) => this.log('warn', args)
      },

      // Context API
      context: {
        tenantId: this.tenantId,
        user: null, // Set at execution time

        // Database access (limited queries)
        db: {
          query: async (sql, params) => this.safeDbQuery(sql, params),
          findOne: async (table, id) => this.findOne(table, id)
        },

        // Service integrations
        services: {
          approvals: {
            get: async (id) => this.getApproval(id),
            approve: async (id, data) => this.approveApproval(id, data),
            reject: async (id, data) => this.rejectApproval(id, data),
            escalate: async (id, data) => this.escalateApproval(id, data)
          },
          dam: {
            getAsset: async (id) => this.callService('svc-media', '/assets/' + id),
            updateMetadata: async (id, metadata) => this.callService('svc-media', '/assets/' + id, 'PATCH', { metadata })
          },
          notifications: {
            send: async (userId, notification) => this.callService('svc-comm', '/notifications', 'POST', { userId, ...notification })
          }
        },

        // Utility functions
        utils: {
          hash: (data) => createHash('sha256').update(JSON.stringify(data)).digest('hex'),
          sleep: (ms) => new Promise(resolve => setTimeout(resolve, Math.min(ms, 5000)))
        }
      },

      // Whitelisted libraries
      lodash: require('lodash'),
      dayjs: require('dayjs')
    };
  }

  async execute(input: Record<string, any>): Promise<any> {
    const startTime = Date.now();
    const startMemory = process.memoryUsage().heapUsed;

    try {
      // Set user context
      this.vm.sandbox.context.user = input.request?.user;

      // Execute handler function
      const handler = this.vm.run('handler');
      const result = await handler(input);

      const executionTime = Date.now() - startTime;
      const memoryUsed = (process.memoryUsage().heapUsed - startMemory) / 1024 / 1024;

      // Log execution
      await this.logExecution({
        script_id: this.scriptId,
        tenant_id: this.tenantId,
        input_data: input,
        output_data: result,
        execution_time_ms: executionTime,
        memory_used_mb: memoryUsed,
        status: 'success'
      });

      return result;
    } catch (error) {
      // Log error
      await this.logExecution({
        script_id: this.scriptId,
        tenant_id: this.tenantId,
        input_data: input,
        error: error.message,
        status: error.name === 'VMTimeout' ? 'timeout' : 'error'
      });

      throw error;
    }
  }

  private async safeDbQuery(sql: string, params: any[]) {
    // Whitelist only SELECT queries
    if (!sql.trim().toLowerCase().startsWith('select')) {
      throw new Error('Only SELECT queries are allowed in scripts');
    }

    // Enforce row limit
    sql = sql.replace(/;?\s*$/i, ' LIMIT 1000');

    // Execute with tenant isolation
    return await db.query(sql, params);
  }

  private async callService(serviceName: string, path: string, method = 'GET', body = null) {
    // Internal service-to-service call with tenant context
    const serviceUrl = config.services[serviceName];

    const response = await fetch(`${serviceUrl}${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'X-Tenant-ID': this.tenantId,
        'X-Internal-Call': 'true'
      },
      body: body ? JSON.stringify(body) : undefined
    });

    return response.json();
  }
}
```

### Script Lifecycle Hooks

```typescript
// Tenant can define lifecycle hooks
const lifecycleHooks = {
  // Before approval creation
  'approval.before_create': async ({ approval, context }) => {
    // Custom validation
    if (approval.metadata.amount > 10000 && !context.user.permissions.includes('high_value_approval')) {
      throw new Error('Cannot create high-value approval without permission');
    }

    // Enrich metadata
    approval.metadata.created_via = 'script';
    approval.metadata.risk_score = calculateRiskScore(approval);

    return approval;
  },

  // After approval step approved
  'approval.after_step_approved': async ({ approval, step, context }) => {
    // Send custom notification
    if (step.index === 0) {
      await context.services.notifications.send(approval.requester_id, {
        title: 'First approval received',
        body: `Your ${approval.resource_type} has been approved by ${context.user.name}`
      });
    }

    // Sync to external system
    if (approval.metadata.sync_to_sap) {
      await syncToSAP(approval);
    }
  },

  // Before final approval
  'approval.before_complete': async ({ approval, context }) => {
    // Final checks
    const hasAllDocuments = await verifyDocuments(approval);
    if (!hasAllDocuments) {
      throw new Error('Missing required documents');
    }
  }
};
```

## 6. Tenant Customization UI

### Page Builder Integration for Widgets

```typescript
// app-approvals-frontend/src/app/admin/widgets/create/page.tsx
'use client';

import { GrapesJSEditor } from '@/components/GrapesJSEditor';
import { useState } from 'react';

export default function CreateWidgetPage() {
  const [widgetConfig, setWidgetConfig] = useState({
    widget_key: '',
    widget_type: 'preview',
    metadata: {
      name: '',
      description: ''
    }
  });

  const handleSave = async (editorData) => {
    // Save widget to database
    await fetch('/api/admin/widgets', {
      method: 'POST',
      body: JSON.stringify({
        ...widgetConfig,
        component_source: {
          type: 'page_builder_json',
          page_builder_json: {
            version: '1.0',
            components: editorData.components,
            styles: editorData.styles,
            scripts: editorData.scripts
          }
        }
      })
    });
  };

  return (
    <div className="flex flex-col h-screen">
      <header className="border-b p-4">
        <h1 className="text-2xl font-bold">Create Custom Widget</h1>
      </header>

      <div className="flex-1">
        <GrapesJSEditor
          onSave={handleSave}
          initialData={{
            // Provide approval data structure for preview
            approval: {
              id: 'preview-id',
              metadata: {
                employee_name: 'John Doe',
                total_amount: 1250.00,
                receipts: [
                  { merchant: 'Hotel', amount: 500 },
                  { merchant: 'Taxi', amount: 75 }
                ]
              }
            }
          }}
        />
      </div>
    </div>
  );
}
```

### Script Editor

```typescript
// app-approvals-frontend/src/app/admin/scripts/create/page.tsx
'use client';

import { MonacoEditor } from '@/components/MonacoEditor';
import { useState } from 'react';

export default function CreateScriptPage() {
  const [scriptConfig, setScriptConfig] = useState({
    script_key: '',
    script_type: 'validation',
    language: 'javascript'
  });

  const [sourceCode, setSourceCode] = useState(`
export async function handler({ request, context }) {
  // Your custom logic here
  const { approval } = request.body;

  // Example: Validate expense amount
  if (approval.metadata.total_amount > 5000) {
    // Require additional documentation
    if (!approval.metadata.receipts || approval.metadata.receipts.length === 0) {
      return {
        statusCode: 400,
        body: {
          error: 'Expenses over $5000 require receipts'
        }
      };
    }
  }

  return {
    statusCode: 200,
    body: { valid: true }
  };
}
  `.trim());

  const handleTest = async () => {
    // Test script execution
    const result = await fetch('/api/admin/scripts/test', {
      method: 'POST',
      body: JSON.stringify({
        source_code: sourceCode,
        test_input: {
          request: {
            body: {
              approval: {
                metadata: {
                  total_amount: 6000,
                  receipts: []
                }
              }
            }
          }
        }
      })
    });

    const data = await result.json();
    console.log('Test result:', data);
  };

  return (
    <div className="flex flex-col h-screen">
      <header className="border-b p-4 flex justify-between">
        <h1 className="text-2xl font-bold">Create Custom Script</h1>
        <div className="space-x-2">
          <Button onClick={handleTest} variant="outline">Test Script</Button>
          <Button onClick={handleSave}>Save Script</Button>
        </div>
      </header>

      <div className="flex-1">
        <MonacoEditor
          language="typescript"
          value={sourceCode}
          onChange={setSourceCode}
          options={{
            minimap: { enabled: false },
            fontSize: 14
          }}
        />
      </div>
    </div>
  );
}
```

## 7. Security & Quota Management

### Script Execution Limits

```typescript
interface ScriptQuota {
  max_time_ms: number; // 5000 default
  max_memory_mb: number; // 128 default
  max_db_queries: number; // 10 default
  max_http_calls: number; // 5 default
  max_executions_per_hour: number; // 1000 default
}

// Enforce quotas
class QuotaEnforcer {
  async checkQuota(tenantId: string, scriptId: string): Promise<void> {
    const usage = await this.getHourlyUsage(tenantId, scriptId);
    const limits = await this.getScriptLimits(scriptId);

    if (usage.executions >= limits.max_executions_per_hour) {
      throw new QuotaExceededError('Hourly execution limit reached');
    }
  }

  async trackExecution(tenantId: string, scriptId: string, metrics: ExecutionMetrics): Promise<void> {
    await redis.hincrby(`quota:${tenantId}:${scriptId}:${getCurrentHour()}`, 'executions', 1);
    await redis.hincrby(`quota:${tenantId}:${scriptId}:${getCurrentHour()}`, 'total_time_ms', metrics.execution_time_ms);
  }
}
```

### Sandbox Security

```typescript
// Prevent malicious code
const securityChecks = {
  // AST analysis before execution
  analyzeScript(sourceCode: string): SecurityIssue[] {
    const ast = parse(sourceCode);
    const issues: SecurityIssue[] = [];

    // Check for forbidden patterns
    traverse(ast, {
      CallExpression(path) {
        // Forbid process.exit, process.env access
        if (path.node.callee.object?.name === 'process') {
          issues.push({
            type: 'forbidden_api',
            message: 'Access to process object is not allowed',
            line: path.node.loc.start.line
          });
        }

        // Forbid require() of unlisted modules
        if (path.node.callee.name === 'require') {
          const module = path.node.arguments[0].value;
          if (!WHITELISTED_MODULES.includes(module)) {
            issues.push({
              type: 'forbidden_module',
              message: `Module "${module}" is not whitelisted`,
              line: path.node.loc.start.line
            });
          }
        }
      }
    });

    return issues;
  }
};
```

## 8. Example: Complete Custom Approval Flow

### Scenario: ACME Corp Travel Approval

1. **Custom Widget** (Page Builder)
2. **Custom Route** (Bulk actions)
3. **Field Mapping** (Integrate with Concur)
4. **Lifecycle Scripts** (Auto-deny if policy violation)

```typescript
// 1. Widget: Travel Request Preview
const travelWidgetJSON = {
  components: [
    {
      tagName: 'div',
      attributes: { class: 'travel-card' },
      components: [
        { tagName: 'h3', content: '{{metadata.employee_name}}' },
        { tagName: 'p', content: 'Destination: {{metadata.destination}}' },
        { tagName: 'p', content: 'Dates: {{metadata.start_date}} - {{metadata.end_date}}' },
        { tagName: 'p', content: 'Estimated Cost: {{metadata.estimated_cost | currency}}' },
        {
          tagName: 'div',
          attributes: { class: 'policy-check' },
          content: '{{metadata.policy_compliant ? "✓ Policy Compliant" : "⚠ Policy Violation"}}'
        }
      ]
    }
  ]
};

// 2. Custom Route: Bulk Travel Approval
const bulkTravelApproveScript = `
export async function handler({ request, context }) {
  const { travel_ids } = request.body;

  const results = [];
  for (const travelId of travel_ids) {
    const approval = await context.services.approvals.get(travelId);

    // Check policy compliance
    if (!approval.metadata.policy_compliant) {
      // Auto-escalate to VP
      await context.services.approvals.escalate(travelId, {
        escalate_to_role: 'vp_operations',
        reason: 'Policy violation - requires VP approval'
      });
      results.push({ travel_id: travelId, status: 'escalated' });
      continue;
    }

    // Approve
    await context.services.approvals.approve(travelId, {
      approved_by: context.user.id
    });
    results.push({ travel_id: travelId, status: 'approved' });
  }

  return { statusCode: 200, body: { results } };
}
`;

// 3. Field Mapping: Concur → Internal
const concurMapping = {
  transformation_rules: [
    { source_field: 'TripName', target_field: 'metadata.trip_name', transform_type: 'direct' },
    { source_field: 'Destination', target_field: 'metadata.destination', transform_type: 'direct' },
    { source_field: 'TotalEstimatedCost', target_field: 'metadata.estimated_cost', transform_type: 'computed', expression: 'source.TotalEstimatedCost / 100' }
  ]
};

// 4. Lifecycle Script: Policy Validation
const policyValidationScript = `
export async function handler({ approval, context }) {
  const { estimated_cost, destination, duration_days } = approval.metadata;

  // Load company travel policy
  const policy = await context.db.query(
    'SELECT * FROM company_policies WHERE type = \\'travel\\' AND tenant_id = $1',
    [context.tenantId]
  );

  const policyRules = policy.rows[0].rules;

  // Check cost limits
  if (estimated_cost > policyRules.max_cost_per_trip) {
    approval.metadata.policy_compliant = false;
    approval.metadata.policy_violations = [
      \`Estimated cost ($\${estimated_cost}) exceeds limit ($\${policyRules.max_cost_per_trip})\`
    ];
  }

  // Check destination restrictions
  if (policyRules.restricted_destinations.includes(destination)) {
    approval.metadata.policy_compliant = false;
    approval.metadata.policy_violations.push(\`Destination "\${destination}" requires special approval\`);
  }

  return approval;
}
`;
```

## Implementation Roadmap

### Phase 1: Foundation (2 weeks)
- [ ] Database schema for customizations
- [ ] Basic widget registry + renderer
- [ ] Script runner with VM2 sandbox
- [ ] Admin UI for widget creation (page builder integration)

### Phase 2: Advanced Features (2 weeks)
- [ ] Custom routes system
- [ ] Field mapping engine
- [ ] Lifecycle hooks
- [ ] Quota enforcement

### Phase 3: UI & Testing (1 week)
- [ ] Script editor with Monaco
- [ ] Widget gallery
- [ ] Testing tools (script playground)
- [ ] Documentation

### Phase 4: Enterprise Features (1 week)
- [ ] Script versioning & rollback
- [ ] A/B testing for widgets
- [ ] Performance monitoring
- [ ] Security audits

## Benefits

1. **Zero-downtime customization**: Tenants customize without waiting for deploys
2. **Flexible**: Supports any approval type, any workflow
3. **Safe**: Sandboxed execution with quotas
4. **Visual**: Page builder for widgets (no code required)
5. **Powerful**: Full scripting capability for advanced users
6. **Scalable**: Per-tenant isolation, resource limits
7. **Auditable**: All executions logged

---

**Ready to implement?** Start with Phase 1 foundation.
