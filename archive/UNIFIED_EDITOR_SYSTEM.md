# Sistema Editor Unificato con Scripting per Nodi

**Status:** ✅ Ready for Implementation
**Created:** 2025-10-09
**Features:** Node scripting, unified editor, cross-app sharing, real-time collaboration

---

## 🎯 Overview

Sistema completo per editare **qualsiasi modulo** del sistema (workflow, rotte, funzioni, widget, plugin, pagine) con:

1. **Editor Monaco condiviso** tra admin e web frontend
2. **Scripting su nodi workflow** con JavaScript/TypeScript/Python/Lua
3. **Libreria funzioni pre-built** riutilizzabili
4. **Version control** integrato con history e rollback
5. **Real-time collaboration** con sessioni attive visibili
6. **Auto-save** e gestione conflitti

---

## 🗄️ Database Schema

**Migration:** [migrations/022_create_unified_editor_system.sql](migrations/022_create_unified_editor_system.sql)

### Tabelle Principali

#### 1. `workflow.node_functions` - Script per Nodi
```sql
- function_id: Identificatore unico
- name, description, category, tags
- language: javascript|typescript|python|lua
- source_code: Il codice della funzione
- input_schema, output_schema: JSON Schema validation
- runtime: isolated|shared|trusted
- timeout_ms, max_memory_mb: Limiti esecuzione
- is_published, is_system_function
```

**Funzioni Pre-built Incluse:**
- ✅ Extract Field (transform)
- ✅ Map Array (transform)
- ✅ Filter Data (transform)
- ✅ JSON Schema Validator (validation)
- ✅ Add Metadata (enrichment)
- ✅ HTTP Request (integration)

#### 2. `workflow.node_function_instances` - Funzioni Associate ai Nodi
```sql
- workflow_id, node_id: Riferimento nodo
- function_id: Funzione da eseguire
- config: Configurazione specifica
- execution_order: Ordine multi-funzione
- condition_expression: Esecuzione condizionale
- on_error: throw|skip|fallback|retry
- performance metrics
```

#### 3. `workflow.editable_entities` - Registry Entità Editabili
```sql
- entity_type: workflow|route|function|widget|plugin|page
- entity_id, entity_name
- content: Il contenuto editabile
- content_type: json|javascript|sql|markdown|html
- editor_mode: code|visual|hybrid
- validation_schema
- version control
```

#### 4. `workflow.editor_sessions` - Collaborazione Real-Time
```sql
- entity_type, entity_id
- user_id, user_name
- is_active, locked
- cursor_position, selection_range
- last_heartbeat
```

#### 5. `workflow.editor_history` - Version Control
```sql
- entity_type, entity_id
- version, content
- change_summary, changed_by
- diff: JSON diff per rollback efficiente
```

---

## 🎨 Unified Editor Component

**File:** [shared/components/UnifiedEditor.tsx](shared/components/UnifiedEditor.tsx)

### Features

✅ **Monaco Editor** - Stesso editor di VS Code
✅ **Syntax Highlighting** - JS, TS, SQL, JSON, Markdown, HTML, CSS, YAML
✅ **IntelliSense** - Autocomplete context-aware
✅ **Custom Snippets** - Template per funzioni comuni
✅ **Multi-language** - Supporto 8+ linguaggi
✅ **Theme Support** - Dark/Light/High Contrast
✅ **Toolbar Completo** - Save, Execute, Download, Copy, History
✅ **Version History UI** - Sidebar con rollback
✅ **Real-time Sessions** - Mostra chi sta editando
✅ **Status Bar** - Lines, chars, active users
✅ **Fullscreen Mode** - Editor espandibile
✅ **Auto-format** - Format on save/paste/type

### Usage

```typescript
import { UnifiedEditor } from '@/shared/components/UnifiedEditor';

<UnifiedEditor
  entityType="function"
  entityId="transform-user-data"
  entityName="Transform User Data"
  content={functionCode}
  contentType="javascript"
  showToolbar={true}
  showMinimap={true}
  height="600px"
  theme="vs-dark"
  onChange={(newContent) => console.log('Changed:', newContent)}
  onSave={async (content) => await saveToDB(content)}
  onExecute={(content) => runFunction(content)}
  onClose={() => closeEditor()}
/>
```

---

## 🔧 Integrazione nei Frontend

### app-admin-frontend

#### 1. Node Function Editor
```typescript
// pages/god-mode/node-functions.tsx
import { UnifiedEditor } from '@/shared/components/UnifiedEditor';

export default function NodeFunctionsPage() {
  const [selectedFunction, setSelectedFunction] = useState(null);

  return (
    <div className="grid grid-cols-12 gap-4">
      {/* Sidebar: Function Library */}
      <div className="col-span-3">
        <FunctionLibrary onSelect={setSelectedFunction} />
      </div>

      {/* Main: Editor */}
      <div className="col-span-9">
        {selectedFunction && (
          <UnifiedEditor
            entityType="function"
            entityId={selectedFunction.function_id}
            entityName={selectedFunction.name}
            content={selectedFunction.source_code}
            contentType={selectedFunction.language}
            onSave={handleSaveFunction}
            onExecute={handleTestFunction}
          />
        )}
      </div>
    </div>
  );
}
```

#### 2. Workflow Builder con Node Scripting
```typescript
// pages/workflow-builder.tsx (aggiornato)

function WorkflowNode({ node }) {
  const [showFunctionEditor, setShowFunctionEditor] = useState(false);

  return (
    <div className="workflow-node">
      <div className="node-header">{node.name}</div>

      {/* Add Function Button */}
      <button onClick={() => setShowFunctionEditor(true)}>
        Add Script
      </button>

      {/* Function Editor Modal */}
      {showFunctionEditor && (
        <div className="modal">
          <FunctionPicker
            onSelect={(funcId) => attachFunctionToNode(node.id, funcId)}
          />

          <UnifiedEditor
            entityType="function"
            entityId="new-function"
            entityName="New Node Function"
            content="function execute(input, config) {\n  return input;\n}"
            contentType="javascript"
            onSave={(code) => createAndAttachFunction(node.id, code)}
          />
        </div>
      )}
    </div>
  );
}
```

#### 3. Route Editor
```typescript
// pages/gateway-manager.tsx (aggiornato)

function RouteConfigEditor({ route }) {
  const [editingTransform, setEditingTransform] = useState(false);

  return (
    <div>
      {/* Request Transform */}
      <button onClick={() => setEditingTransform('request')}>
        Edit Request Transform
      </button>

      {editingTransform === 'request' && (
        <UnifiedEditor
          entityType="route"
          entityId={route.id}
          entityName={`${route.method} ${route.path} - Request Transform`}
          content={JSON.stringify(route.request_transform, null, 2)}
          contentType="json"
          onSave={(content) => updateRouteTransform(route.id, 'request', content)}
        />
      )}
    </div>
  );
}
```

### app-web-frontend

#### 4. User Custom Workflows
```typescript
// pages/dashboard/workflows/custom.tsx

export default function CustomWorkflowsPage() {
  return (
    <AdminLayout>
      <h1>My Custom Workflows</h1>

      <UnifiedEditor
        entityType="workflow"
        entityId="my-workflow-1"
        entityName="Data Processing Pipeline"
        content={workflowConfig}
        contentType="json"
        readOnly={!canEdit}
        onSave={saveWorkflow}
      />
    </AdminLayout>
  );
}
```

---

## 🚀 Node Scripting System

### Creazione Funzione

**UI: God Mode → Node Functions → Create New**

```typescript
// POST /api/node-functions

{
  "function_id": "custom-email-validator",
  "name": "Custom Email Validator",
  "description": "Validates email with custom rules",
  "category": "validation",
  "language": "javascript",
  "source_code": `
    function execute(input, config) {
      const emailRegex = config.regex || /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/;

      if (!emailRegex.test(input.email)) {
        throw new Error('Invalid email format');
      }

      // Check domain blacklist
      const domain = input.email.split('@')[1];
      if (config.blacklistedDomains?.includes(domain)) {
        throw new Error('Domain not allowed');
      }

      return { ...input, emailValidated: true };
    }
  `,
  "input_schema": {
    "type": "object",
    "properties": {
      "email": { "type": "string" }
    },
    "required": ["email"]
  },
  "output_schema": {
    "type": "object",
    "properties": {
      "email": { "type": "string" },
      "emailValidated": { "type": "boolean" }
    }
  },
  "runtime": "isolated",
  "timeout_ms": 3000
}
```

### Associazione a Nodo

**UI: Workflow Builder → Click Node → Add Function**

```typescript
// POST /api/node-functions/attach

{
  "workflow_id": "order-processing",
  "node_id": "validate-customer",
  "function_id": "custom-email-validator",
  "config": {
    "blacklistedDomains": ["tempmail.com", "throwaway.email"]
  },
  "execution_order": 1,
  "on_error": "throw"
}
```

### Esecuzione Runtime

```typescript
// Nel gateway/workflow engine

async function executeNodeFunctions(nodeId: string, data: any) {
  // Get attached functions
  const functions = await db.query(`
    SELECT nf.*, nfi.config, nfi.execution_order
    FROM workflow.node_function_instances nfi
    JOIN workflow.node_functions nf ON nfi.function_id = nf.function_id
    WHERE nfi.node_id = $1 AND nfi.enabled = true
    ORDER BY nfi.execution_order ASC
  `, [nodeId]);

  let result = data;

  for (const func of functions.rows) {
    try {
      // Execute in sandbox
      result = await executeSandboxed(
        func.source_code,
        result,
        func.config,
        {
          timeout: func.timeout_ms,
          memory: func.max_memory_mb,
          runtime: func.runtime
        }
      );
    } catch (error) {
      // Handle based on on_error config
      if (func.on_error === 'throw') throw error;
      if (func.on_error === 'skip') continue;
      if (func.on_error === 'fallback') result = func.fallback_value;
    }
  }

  return result;
}
```

---

## 📊 API Endpoints

### Node Functions
```typescript
GET    /api/node-functions              // List all functions
GET    /api/node-functions/:id          // Get function details
POST   /api/node-functions              // Create function
PUT    /api/node-functions/:id          // Update function
DELETE /api/node-functions/:id          // Delete function
POST   /api/node-functions/:id/test     // Test function execution
POST   /api/node-functions/attach       // Attach to node
POST   /api/node-functions/detach       // Detach from node
```

### Editor
```typescript
GET    /api/editor/entity               // Get editable entity
PUT    /api/editor/entity               // Update entity
GET    /api/editor/sessions             // Active sessions
POST   /api/editor/sessions             // Start session
DELETE /api/editor/sessions/:id         // End session
GET    /api/editor/history              // Version history
POST   /api/editor/history/restore      // Restore version
GET    /api/editor/preferences          // User preferences
PUT    /api/editor/preferences          // Update preferences
```

---

## 🎯 Use Cases

### 1. Transform Node - Data Mapping
```javascript
function execute(input, config) {
  return {
    userId: input.user_id,
    fullName: `${input.first_name} ${input.last_name}`,
    email: input.email.toLowerCase(),
    createdAt: new Date(input.created).toISOString()
  };
}
```

### 2. Validation Node - Business Rules
```javascript
function execute(input, config) {
  if (input.order_total < config.minOrderValue) {
    throw new Error(`Order must be at least ${config.minOrderValue}`);
  }

  if (input.items.length > config.maxItems) {
    throw new Error(`Max ${config.maxItems} items allowed`);
  }

  return input;
}
```

### 3. Enrichment Node - External API Call
```javascript
async function execute(input, config) {
  const geoData = await fetch(
    `${config.geoApiUrl}/locate?ip=${input.ip_address}`
  ).then(r => r.json());

  return {
    ...input,
    location: {
      country: geoData.country,
      city: geoData.city,
      timezone: geoData.timezone
    }
  };
}
```

### 4. Conditional Node - Branching Logic
```javascript
function execute(input, config) {
  if (input.customer_type === 'premium') {
    return { ...input, discount: 0.15, priority: 'high' };
  } else if (input.order_total > 1000) {
    return { ...input, discount: 0.10, priority: 'medium' };
  } else {
    return { ...input, discount: 0, priority: 'normal' };
  }
}
```

---

## 🔐 Security & Sandboxing

### Execution Runtime

```typescript
// Isolated runtime con VM2 o QuickJS
import { VM } from 'vm2';

async function executeSandboxed(
  code: string,
  input: any,
  config: any,
  options: ExecutionOptions
) {
  const vm = new VM({
    timeout: options.timeout,
    sandbox: {
      input,
      config,
      console: {
        log: (...args) => logger.info('Function log:', args)
      },
      // Whitelist safe globals
      JSON,
      Date,
      Math,
      // Block dangerous globals
      require: undefined,
      process: undefined,
      __dirname: undefined,
      __filename: undefined
    },
    eval: false,
    wasm: false
  });

  const result = await vm.run(`
    ${code}
    execute(input, config);
  `);

  return result;
}
```

### Permissions

- **Isolated:** Sandbox completo, no network, no filesystem
- **Shared:** Accesso a moduli npm whitelisted
- **Trusted:** Full access (solo per admin)

---

## 🎨 UI Screenshots (Mockup)

### Node Function Library
```
┌──────────────────────────────────────────────────────────┐
│  Node Functions Library                    [+ Create New] │
├──────────────────────────────────────────────────────────┤
│  📂 Transform (12)                                        │
│    ▸ Extract Field              ⭐ System                 │
│    ▸ Map Array                  ⭐ System                 │
│    ▸ Custom User Transform      👤 Custom   [Edit] [Run] │
│                                                           │
│  ✓ Validation (8)                                         │
│    ▸ JSON Schema Validator      ⭐ System                 │
│    ▸ Email Validator            👤 Custom   [Edit] [Run] │
│                                                           │
│  🔗 Integration (5)                                       │
│    ▸ HTTP Request               ⭐ System                 │
│    ▸ Stripe Payment             👤 Custom   [Edit] [Run] │
└──────────────────────────────────────────────────────────┘
```

### Function Editor
```
┌──────────────────────────────────────────────────────────┐
│  📝 Custom Email Validator  function · javascript        │
│  [Copy] [Download] [History] [▶ Run] [Save]        [✕]  │
├──────────────────────────────────────────────────────────┤
│   1  function execute(input, config) {                   │
│   2    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/; │
│   3                                                       │
│   4    if (!emailRegex.test(input.email)) {             │
│   5      throw new Error('Invalid email format');       │
│   6    }                                                 │
│   7                                                       │
│   8    return { ...input, emailValidated: true };       │
│   9  }                                                   │
│                                                           │
│                                                           │
├──────────────────────────────────────────────────────────┤
│  Lines: 9  Chars: 245       👤 John Doe  👤 Jane Smith  │
└──────────────────────────────────────────────────────────┘
```

### Workflow Builder con Script
```
┌──────────────────────────────────────────────────────────┐
│  Order Processing Workflow                               │
├──────────────────────────────────────────────────────────┤
│                                                           │
│    [Trigger]                                             │
│       ↓                                                  │
│    [Validate Customer] ← 📝 2 functions attached         │
│       │                    ∟ Email Validator             │
│       │                    ∟ Fraud Check                 │
│       ↓                                                  │
│    [Calculate Total]                                     │
│       ↓                                                  │
│    [Process Payment]                                     │
│                                                           │
│  Click node to add/edit functions →                      │
└──────────────────────────────────────────────────────────┘
```

---

## 🚀 Deployment

### 1. Run Migration
```bash
psql -U ewh -d ewh_master -f migrations/022_create_unified_editor_system.sql
```

### 2. Install Monaco Editor
```bash
# In both app-admin-frontend and app-web-frontend
pnpm add monaco-editor
pnpm add -D @monaco-editor/react
```

### 3. Setup Shared Component
```bash
# Link shared components
ln -s ../../shared/components shared
```

### 4. API Endpoints
```typescript
// Implement API routes in both apps
/api/node-functions/*
/api/editor/*
```

### 5. Sandboxing (Production)
```bash
pnpm add vm2  # For Node.js sandboxing
# OR
pnpm add isolated-vm  # More secure alternative
```

---

## 📈 Benefits

✅ **Modularità** - Funzioni riutilizzabili su qualsiasi nodo
✅ **No Code Changes** - Logica modificabile runtime via UI
✅ **Version Control** - History completa con rollback
✅ **Collaboration** - Vedi chi sta editando cosa
✅ **Security** - Sandbox isolato con limiti risorse
✅ **Performance** - Funzioni cachable e ottimizzabili
✅ **Testing** - Test runner integrato nell'editor
✅ **Portability** - Stesso editor per admin e web frontend
✅ **Developer Experience** - IntelliSense, snippets, format

---

## 🔄 Next Steps

1. ✅ Migration database completata
2. ✅ UnifiedEditor component creato
3. ⏳ Implementare API endpoints
4. ⏳ Integrare in workflow-builder.tsx
5. ⏳ Integrare in gateway-manager.tsx
6. ⏳ Creare Function Library UI
7. ⏳ Setup sandboxing runtime
8. ⏳ Testing end-to-end

---

**Ready to implement!** 🚀