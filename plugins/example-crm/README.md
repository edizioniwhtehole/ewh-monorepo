# Example CRM Plugin

**Full-featured CRM plugin demonstrating zero-touch modular development**

## 🎯 What This Demonstrates

This plugin shows how to build a complete feature **without touching core code**:

✅ **Auto-registered routes** - Drop files in `routes/`, they auto-register
✅ **Auto-run migrations** - SQL files in `migrations/` auto-execute
✅ **Auto-mounted UI** - HTML/CSS/JS in `ui/` auto-served
✅ **Auto-registered permissions** - Defined in `plugin.json`
✅ **Event hooks** - Listen to system events
✅ **Plugin context** - Access to db, logger, settings, etc.

**Zero code changes to core needed!**

---

## 📦 Structure

```
example-crm/
├── plugin.json           # Plugin manifest
├── index.js              # Entry point (activate/deactivate)
├── routes/               # Auto-registered API routes
│   ├── leads.route.js          # GET /crm/leads
│   ├── leads-create.route.js   # POST /crm/leads
│   └── health.route.js         # GET /crm/health (public)
├── migrations/           # Auto-run SQL migrations
│   └── 001_create_schema.sql   # Creates crm.* schema
├── ui/                   # Auto-served frontend
│   ├── index.html              # CRM dashboard
│   ├── app.js                  # Frontend logic
│   └── style.css               # Styles
└── README.md             # This file
```

---

## 🚀 Usage

### Install Plugin

```bash
# Plugin is already in plugins/ directory
# Just activate it:

curl -X POST http://localhost:4000/api/plugins/activate \
  -H "Content-Type: application/json" \
  -d '{"name": "example-crm"}'
```

### What Happens on Activation

1. ✅ Plugin discovered from `plugins/example-crm/`
2. ✅ `plugin.json` loaded and validated
3. ✅ Migration `001_create_schema.sql` executes → Creates `crm.*` schema
4. ✅ Routes auto-registered:
   - `GET /crm/leads`
   - `POST /crm/leads`
   - `GET /crm/health`
5. ✅ UI auto-mounted at `/app/crm`
6. ✅ Permissions registered: `crm.admin`, `crm.sales`, `crm.view`
7. ✅ `index.js` `activate()` called → Hooks registered
8. ✅ Plugin active! ✨

### Test Routes

```bash
# Health check (public)
curl http://localhost:4000/crm/health

# Get leads (requires auth)
curl http://localhost:4000/crm/leads \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create lead (requires auth + permission)
curl -X POST http://localhost:4000/crm/leads \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "company": "Acme Inc",
    "source": "website"
  }'
```

### Access UI

Navigate to: `http://localhost:4000/app/crm`

You'll see:
- Dashboard with stats
- Recent leads table
- Create lead button
- All auto-loaded from `ui/` directory!

---

## 🔌 Route Auto-Registration

### Convention

**Every file in `routes/*.route.js` is auto-registered.**

### Example: `routes/leads.route.js`

```javascript
module.exports = {
  method: 'GET',
  path: '/leads',
  middleware: ['auth'],
  permissions: ['crm.view'],

  handler: async (req, res, ctx) => {
    const leads = await ctx.db.query('SELECT * FROM crm.leads');
    res.json(leads.rows);
  }
};
```

**Auto-registered as**: `GET /crm/leads`

**No manual registration needed!**

---

## 🗄️ Migration Auto-Run

### Convention

**All files in `migrations/*.sql` run in alphabetical order on activation.**

### Example: `migrations/001_create_schema.sql`

```sql
CREATE SCHEMA IF NOT EXISTS crm;

CREATE TABLE crm.leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name VARCHAR(100),
  email VARCHAR(255),
  -- ...
);
```

**Auto-executed on plugin activation.**

---

## 🎨 UI Auto-Mount

### Convention

**Everything in `ui/` is served at the path defined in `plugin.json`.**

**plugin.json**:
```json
{
  "ui": {
    "mount": "/app/crm"
  }
}
```

**Files**:
- `ui/index.html` → `http://localhost:4000/app/crm/`
- `ui/app.js` → `http://localhost:4000/app/crm/app.js`
- `ui/style.css` → `http://localhost:4000/app/crm/style.css`

**Auto-served. No build step required!**

---

## 🔐 Permissions

### Defined in `plugin.json`

```json
{
  "permissions": {
    "requires": ["database.read", "database.write"],
    "provides": ["crm.admin", "crm.sales", "crm.view"]
  }
}
```

### Usage in Routes

```javascript
module.exports = {
  method: 'POST',
  path: '/leads',
  permissions: ['crm.admin', 'crm.sales'], // Only these roles can access

  handler: async (req, res, ctx) => {
    // Handler code
  }
};
```

**Auto-enforced by plugin system.**

---

## 🪝 Event Hooks

### Register in `index.js`

```javascript
exports.activate = async function(ctx) {
  // Listen to events
  ctx.hooks.addAction('lead.created', async (lead) => {
    console.log('New lead:', lead);
    // Send notification, etc.
  });

  // Modify data with filters
  ctx.hooks.addFilter('lead.before_save', async (lead) => {
    lead.email = lead.email.toLowerCase();
    return lead;
  });
};
```

### Trigger in Routes

```javascript
// In your route handler
const lead = await createLead(data);

// Trigger event
await ctx.hooks.doAction('lead.created', lead, req.user);
```

---

## 📊 Plugin Context API

Every route handler and `activate()` receives a `ctx` object:

```javascript
handler: async (req, res, ctx) => {
  // Database (sandboxed to crm schema)
  await ctx.db.query('SELECT * FROM crm.leads');

  // Logger
  ctx.logger.info('Lead created', { id: lead.id });

  // Settings
  const value = await ctx.settings.get('key');
  await ctx.settings.set('key', 'value');

  // Storage (key-value)
  await ctx.storage.set('cache_key', data);
  const cached = await ctx.storage.get('cache_key');

  // Hooks
  await ctx.hooks.doAction('event', data);
  const filtered = await ctx.hooks.applyFilters('filter', value);

  // HTTP client
  const response = await ctx.http.post('https://api.example.com', data);

  // Events
  ctx.events.emit('analytics.track', event);
}
```

---

## 🧪 Testing

### Unit Tests

Test individual functions:

```javascript
const { activate } = require('./index.js');
const { createTestContext } = require('@ewh/plugin-testing');

test('plugin activates successfully', async () => {
  const ctx = createTestContext();
  await activate(ctx);

  expect(ctx.hooks.hasAction('lead.created')).toBe(true);
});
```

### Integration Tests

Test routes:

```javascript
const request = require('supertest');

test('GET /crm/leads returns leads', async () => {
  const res = await request(app)
    .get('/crm/leads')
    .set('Authorization', `Bearer ${token}`)
    .expect(200);

  expect(res.body.data).toBeArray();
});
```

---

## 🎯 Benefits

### For Developers

✅ **No core changes** - Drop plugin, it works
✅ **Auto-wiring** - Routes, migrations, UI all auto-registered
✅ **Isolated** - Plugin code doesn't affect core
✅ **Hot-reload** - Deactivate/activate to update
✅ **Full-featured** - Access to db, logger, hooks, etc.

### For Product

✅ **Faster development** - No coordination with core team
✅ **A/B testing** - Enable/disable features per tenant
✅ **Marketplace** - Plugins can be distributed
✅ **Customization** - Tenants can add custom features

### For Operations

✅ **Zero downtime** - Activate plugins without restart
✅ **Versioning** - Each plugin has its own version
✅ **Rollback** - Deactivate bad plugin instantly
✅ **Isolation** - Plugin bugs don't crash system

---

## 📚 Learn More

- [MODULAR_DEVELOPMENT_STANDARD.md](../../MODULAR_DEVELOPMENT_STANDARD.md) - Full modular standard
- [PLUGIN_SYSTEM_COMPLETE.md](../../PLUGIN_SYSTEM_COMPLETE.md) - Plugin system architecture
- [AGENTS.md](../../AGENTS.md) - AI navigation guide

---

## 🎉 Summary

**This plugin demonstrates:**

1. ✅ Zero-touch development (no core changes)
2. ✅ Auto-registration (routes, migrations, UI, permissions)
3. ✅ Full backend (database, API, business logic)
4. ✅ Full frontend (HTML, CSS, JS auto-served)
5. ✅ Event system (hooks and filters)
6. ✅ Plugin context (db, logger, settings, etc.)

**Drop this plugin in `plugins/` directory → It just works!**

---

**Version**: 1.0.0
**Author**: EWH Platform Team
**License**: MIT
