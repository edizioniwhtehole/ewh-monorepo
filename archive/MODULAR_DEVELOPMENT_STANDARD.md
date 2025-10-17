# 🏗️ MODULAR DEVELOPMENT STANDARD

**Zero-Touch Codebase Plugin Architecture**

## 🎯 Obiettivo

Sviluppare nuove feature **senza mai toccare la codebase core**. Ogni componente è un plugin auto-registrante con route, UI, database migrations, e permessi propri.

---

## 📐 Standard Architetturale

### Principi Fondamentali

1. **Zero-Touch Core** - Il core non si modifica mai
2. **Auto-Discovery** - Plugin scoperti automaticamente
3. **Hot-Reload** - Carica/scarica plugin runtime
4. **Self-Contained** - Ogni plugin porta tutto (DB, UI, API)
5. **Convention over Configuration** - Struttura standard = funziona

---

## 🗂️ Plugin Structure (Standard)

```
plugins/
  my-feature/
    plugin.json              # Manifest (REQUIRED)

    # Backend
    index.js                 # Entry point (activate/deactivate)
    routes/                  # Auto-registered API routes
      *.route.js             # Convention: exports { path, handler, method }

    # Database
    migrations/              # Auto-run migrations
      001_create_tables.sql
      002_add_columns.sql

    # Frontend
    ui/                      # Auto-mounted frontend
      index.html
      app.js
      style.css

    # Permissions & Config
    permissions.json         # RBAC permissions
    config.json              # Default configuration

    # Optional
    services/                # Business logic
    hooks/                   # Event listeners
    locales/                 # i18n translations
      en.json
      it.json
    tests/                   # Unit tests
    docs/                    # Plugin documentation
```

---

## 📋 plugin.json Schema

```json
{
  "$schema": "https://ewh.io/schemas/plugin-v1.json",

  "name": "my-feature",
  "version": "1.0.0",
  "displayName": "My Feature",
  "description": "Feature description",

  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://example.com"
  },

  "capabilities": {
    "backend": true,        // Has backend routes/logic
    "frontend": true,       // Has UI components
    "database": true,       // Needs database tables
    "worker": false         // Background jobs
  },

  "permissions": {
    "requires": [           // Permissions this plugin needs
      "database.read",
      "database.write",
      "api.register"
    ],
    "provides": [           // Permissions this plugin grants
      "my-feature.admin",
      "my-feature.view"
    ]
  },

  "routes": {
    "prefix": "/my-feature",      // Route prefix
    "public": ["/info"],          // Public routes (no auth)
    "protected": ["/admin/*"]     // Protected routes
  },

  "ui": {
    "mount": "/app/my-feature",   // Frontend mount point
    "menu": {                     // Admin menu entry
      "label": "My Feature",
      "icon": "feature-icon",
      "position": 100
    }
  },

  "dependencies": {
    "plugins": {                  // Other plugins required
      "core-auth": "^1.0.0"
    },
    "npm": {                      // NPM dependencies
      "axios": "^1.6.0"
    }
  },

  "hooks": {                      // Event hooks
    "post.publish": "onPostPublish",
    "user.login": "onUserLogin"
  }
}
```

---

## 🔌 Auto-Registration System

### 1. Route Auto-Discovery

**Convention**: Tutti i file in `routes/*.route.js` vengono auto-registrati.

**File**: `plugins/my-feature/routes/items.route.js`

```javascript
// Auto-registered as: POST /my-feature/items
module.exports = {
  method: 'POST',
  path: '/items',

  // Optional middleware
  middleware: ['auth', 'validate'],

  // Handler
  handler: async (req, res, ctx) => {
    const { name, description } = req.body;

    // ctx = plugin context (db, logger, settings, etc.)
    const result = await ctx.db.query(
      'INSERT INTO my_feature_items (name, description) VALUES ($1, $2) RETURNING *',
      [name, description]
    );

    res.json(result.rows[0]);
  },

  // Optional validation schema (Zod, Joi, etc.)
  schema: {
    body: {
      name: { type: 'string', required: true },
      description: { type: 'string' }
    }
  }
};
```

### 2. Migration Auto-Run

**Convention**: Files in `migrations/` run in alphabetical order.

**File**: `plugins/my-feature/migrations/001_create_tables.sql`

```sql
-- Auto-run on plugin activation

CREATE SCHEMA IF NOT EXISTS my_feature;

CREATE TABLE IF NOT EXISTS my_feature.items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_items_name ON my_feature.items(name);
```

### 3. UI Auto-Mount

**Convention**: `ui/` directory served at route defined in plugin.json

**File**: `plugins/my-feature/ui/index.html`

```html
<!DOCTYPE html>
<html>
<head>
  <title>My Feature</title>
  <link rel="stylesheet" href="./style.css">
</head>
<body>
  <div id="app"></div>
  <script src="./app.js"></script>
</body>
</html>
```

**Auto-mounted at**: `http://localhost:4000/app/my-feature`

### 4. Permission Auto-Registration

**File**: `plugins/my-feature/permissions.json`

```json
{
  "permissions": [
    {
      "key": "my-feature.admin",
      "label": "My Feature Admin",
      "description": "Full access to My Feature",
      "scope": "tenant"
    },
    {
      "key": "my-feature.view",
      "label": "View My Feature",
      "description": "Read-only access",
      "scope": "tenant"
    }
  ],

  "roles": [
    {
      "key": "my-feature-manager",
      "label": "My Feature Manager",
      "permissions": ["my-feature.admin", "my-feature.view"]
    }
  ]
}
```

---

## 🚀 Plugin Lifecycle

### Activation Flow

```
1. Plugin Discovered (scan plugins/ directory)
   ↓
2. Load plugin.json (validate schema)
   ↓
3. Check Dependencies (plugins + npm)
   ↓
4. Run Migrations (migrations/*.sql in order)
   ↓
5. Register Routes (routes/*.route.js)
   ↓
6. Register Permissions (permissions.json)
   ↓
7. Mount UI (ui/ directory)
   ↓
8. Call activate() (index.js export)
   ↓
9. Register Hooks (hooks defined in plugin.json)
   ↓
10. Plugin Active ✅
```

### index.js Entry Point

```javascript
/**
 * Plugin activation
 * @param {PluginContext} ctx - Plugin context
 */
exports.activate = async function(ctx) {
  ctx.logger.info('My Feature plugin activated');

  // Initialize services
  const myService = new MyService(ctx);

  // Register event hooks
  ctx.addAction('post.publish', async (post) => {
    await myService.processPost(post);
  });

  // Store plugin state
  await ctx.storage.set('initialized', true);

  // Schedule background jobs
  if (ctx.capabilities.worker) {
    ctx.scheduler.every('1 hour', () => {
      myService.syncData();
    });
  }
};

/**
 * Plugin deactivation
 * @param {PluginContext} ctx
 */
exports.deactivate = async function(ctx) {
  ctx.logger.info('My Feature plugin deactivated');

  // Cleanup
  ctx.scheduler.clear();
  await ctx.storage.clear();
};

/**
 * Plugin upgrade
 * @param {PluginContext} ctx
 * @param {string} fromVersion
 * @param {string} toVersion
 */
exports.upgrade = async function(ctx, fromVersion, toVersion) {
  ctx.logger.info(`Upgrading from ${fromVersion} to ${toVersion}`);

  // Run upgrade logic
  if (fromVersion === '1.0.0' && toVersion === '2.0.0') {
    await ctx.db.query('ALTER TABLE my_feature.items ADD COLUMN new_field TEXT');
  }
};
```

---

## 🎨 Frontend Integration

### Auto-Injected Assets

Il plugin manager inietta automaticamente:

1. **Plugin Registry** - Lista plugin attivi
2. **API Base URL** - Endpoint del plugin
3. **Auth Token** - JWT per chiamate autenticate
4. **Permissions** - Permessi utente corrente

**Auto-injected in UI**:

```html
<script>
  // Injected by plugin system
  window.PLUGIN_CONFIG = {
    name: 'my-feature',
    apiUrl: '/my-feature',
    token: 'eyJ...',
    permissions: ['my-feature.admin'],
    settings: { /* plugin settings */ }
  };
</script>
```

### React/Vue Component (Optional)

Se il plugin usa React/Vue, usa build tools:

```javascript
// plugins/my-feature/ui/src/App.jsx
import React from 'react';

export default function App() {
  const { apiUrl, token } = window.PLUGIN_CONFIG;

  const fetchItems = async () => {
    const res = await fetch(`${apiUrl}/items`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    return res.json();
  };

  return <div>My Feature UI</div>;
}
```

Build e output in `ui/dist/` (auto-servito).

---

## 🔐 Security & Sandboxing

### Permission Enforcement

```javascript
// routes/admin.route.js
module.exports = {
  method: 'GET',
  path: '/admin/settings',

  // Require permission
  permissions: ['my-feature.admin'],

  handler: async (req, res, ctx) => {
    // Only users with 'my-feature.admin' can access
    res.json({ settings: await ctx.getSettings() });
  }
};
```

### Database Sandboxing

```javascript
// Plugin can only access its own schema
exports.activate = async function(ctx) {
  // ✅ Allowed: Access my_feature schema
  await ctx.db.query('SELECT * FROM my_feature.items');

  // ❌ Blocked: Access other schemas (auto-rejected)
  await ctx.db.query('SELECT * FROM cms.posts'); // Error: Permission denied
};
```

### Resource Limits

```json
{
  "limits": {
    "maxMemory": "512MB",        // Memory limit
    "maxCpu": "50%",             // CPU limit
    "maxStorage": "1GB",         // Storage limit
    "maxRequests": 1000          // Requests/min
  }
}
```

---

## 📊 Plugin Context API

### Complete PluginContext Interface

```typescript
interface PluginContext {
  // Plugin info
  plugin: {
    name: string;
    version: string;
    config: any;
  };

  // Database (sandboxed to plugin schema)
  db: {
    query(sql: string, params?: any[]): Promise<any>;
    transaction(callback: (tx) => Promise<void>): Promise<void>;
  };

  // Storage (key-value per plugin)
  storage: {
    get(key: string): Promise<any>;
    set(key: string, value: any): Promise<void>;
    delete(key: string): Promise<void>;
    clear(): Promise<void>;
  };

  // Settings (persistent config)
  settings: {
    get(key: string, defaultValue?: any): Promise<any>;
    set(key: string, value: any): Promise<void>;
    getAll(): Promise<object>;
  };

  // Hooks system
  hooks: {
    addAction(tag: string, callback: Function, priority?: number): void;
    removeAction(tag: string, callback: Function): void;
    doAction(tag: string, ...args: any[]): Promise<void>;

    addFilter(tag: string, callback: Function, priority?: number): void;
    removeFilter(tag: string, callback: Function): void;
    applyFilters(tag: string, value: any, ...args: any[]): Promise<any>;
  };

  // Logger
  logger: {
    info(message: string, meta?: object): void;
    error(message: string, meta?: object): void;
    warn(message: string, meta?: object): void;
    debug(message: string, meta?: object): void;
  };

  // HTTP client (for external APIs)
  http: {
    get(url: string, options?: object): Promise<any>;
    post(url: string, data: any, options?: object): Promise<any>;
    put(url: string, data: any, options?: object): Promise<any>;
    delete(url: string, options?: object): Promise<any>;
  };

  // Cache
  cache: {
    get(key: string): Promise<any>;
    set(key: string, value: any, ttl?: number): Promise<void>;
    delete(key: string): Promise<void>;
    flush(): Promise<void>;
  };

  // Scheduler (cron jobs)
  scheduler: {
    every(interval: string, callback: Function): string; // returns job id
    at(cron: string, callback: Function): string;
    cancel(jobId: string): void;
    clear(): void;
  };

  // Events (real-time)
  events: {
    emit(event: string, data: any): void;
    on(event: string, callback: Function): void;
    off(event: string, callback: Function): void;
  };

  // Services (access core services)
  services: {
    users: UserService;
    auth: AuthService;
    files: FileService;
    // ... altri core services
  };
}
```

---

## 🧪 Testing

### Plugin Test Structure

```
plugins/my-feature/
  tests/
    unit/
      services.test.js
    integration/
      routes.test.js
    e2e/
      workflow.test.js
```

### Example Test

```javascript
// tests/integration/routes.test.js
const { createTestContext } = require('@ewh/plugin-testing');

describe('My Feature Routes', () => {
  let ctx;

  beforeEach(async () => {
    ctx = await createTestContext('my-feature');
  });

  it('should create item', async () => {
    const response = await ctx.request
      .post('/items')
      .send({ name: 'Test Item' })
      .expect(201);

    expect(response.body).toHaveProperty('id');
  });

  afterEach(async () => {
    await ctx.cleanup();
  });
});
```

---

## 🎯 Real-World Examples

### Example 1: CRM Plugin

```
plugins/crm/
  plugin.json              # CRM metadata
  routes/
    leads.route.js         # GET/POST /crm/leads
    contacts.route.js      # GET/POST /crm/contacts
    deals.route.js         # GET/POST /crm/deals
  migrations/
    001_create_schema.sql  # CRM database tables
  ui/
    index.html             # CRM dashboard
  permissions.json         # crm.admin, crm.sales, crm.view
```

**Routes auto-mounted**:
- `POST /crm/leads` → `routes/leads.route.js`
- `GET /crm/contacts` → `routes/contacts.route.js`

**UI auto-served**: `http://localhost:4000/app/crm`

**Zero code changes to core!**

### Example 2: Analytics Plugin

```
plugins/analytics/
  plugin.json
  routes/
    events.route.js        # POST /analytics/track
    reports.route.js       # GET /analytics/reports
  index.js                 # Hook into all requests
  migrations/
    001_create_events.sql
  ui/
    dashboard.html         # Analytics dashboard
```

**index.js**:

```javascript
exports.activate = async function(ctx) {
  // Track all API calls
  ctx.addAction('api.request', async (req) => {
    await ctx.db.query(
      'INSERT INTO analytics.events (user_id, endpoint, method) VALUES ($1, $2, $3)',
      [req.user?.id, req.path, req.method]
    );
  });
};
```

**Zero instrumentation in core!** Analytics plugin intercepts tutto.

---

## 🏭 Plugin Marketplace

### Publishing a Plugin

```bash
# Package plugin
npm run plugin:package my-feature

# Output: my-feature-1.0.0.zip
```

### Installing from Marketplace

```bash
# CLI install
ewh plugin:install crm@1.2.0

# Or via UI
# Navigate to Admin → Plugins → Marketplace → Install
```

### Versioning

Segue **Semantic Versioning**:
- `1.0.0` → Major.Minor.Patch
- Breaking changes → Bump major
- New features → Bump minor
- Bug fixes → Bump patch

---

## 📈 Benefits Summary

| Aspect | Traditional | Modular Standard |
|--------|-------------|------------------|
| Add feature | Edit core code | Drop plugin folder |
| Database changes | Manual migrations | Auto-run SQL files |
| API routes | Edit route files | Auto-discovered |
| UI integration | Edit main app | Auto-mounted |
| Permissions | Edit RBAC files | Auto-registered |
| Testing | Mock entire app | Isolated tests |
| Deployment | Full redeploy | Plugin hot-reload |
| Team collaboration | Merge conflicts | Parallel dev |

---

## 🚦 Quick Start

### Create New Plugin

```bash
# Generate plugin scaffold
npx create-ewh-plugin my-feature

# Output:
# plugins/my-feature/
#   plugin.json
#   index.js
#   routes/example.route.js
#   migrations/001_init.sql
#   ui/index.html
#   README.md
```

### Activate Plugin

```bash
# Via CLI
ewh plugin:activate my-feature

# Or via API
POST /api/plugins/activate
{ "name": "my-feature" }
```

### Verify Plugin Active

```bash
curl http://localhost:4000/my-feature/health
# { "status": "ok", "plugin": "my-feature", "version": "1.0.0" }
```

---

## 🎉 Result

**ZERO-TOUCH DEVELOPMENT ENABLED!**

✅ Drop plugin folder → Everything auto-wires
✅ Routes auto-register
✅ Migrations auto-run
✅ UI auto-mounts
✅ Permissions auto-add
✅ No core changes ever needed

**WORDPRESS-LEVEL MODULARITY, ENTERPRISE-LEVEL SECURITY!**

---

## 📚 Next Steps

1. Read [PLUGIN_DEVELOPMENT_GUIDE.md](./PLUGIN_DEVELOPMENT_GUIDE.md)
2. Study example plugins in `plugins/examples/`
3. Use `create-ewh-plugin` to scaffold
4. Join plugin developer community

---

**Standard Version**: 1.0.0
**Last Updated**: 2025-10-11
**Status**: ✅ Production-Ready
