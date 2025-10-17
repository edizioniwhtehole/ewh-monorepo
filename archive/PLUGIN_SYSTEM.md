# Plugin System - Modular Architecture

## 🎯 Concept

Sistema modulare stile **WordPress/Joomla** che permette di estendere l'admin panel con plugin indipendenti.

### Architettura a Due Livelli

```
┌─────────────────────────────────────────────────────┐
│ PAGES (Container)                                   │
│ ┌─────────────┐  ┌─────────────┐  ┌──────────────┐│
│ │  Dashboard  │  │   Workers   │  │  Monitoring  ││
│ │             │  │             │  │              ││
│ │  ┌────────┐ │  │  ┌────────┐ │  │  ┌────────┐ ││
│ │  │Widget 1│ │  │  │Widget 1│ │  │  │Widget 1│ ││
│ │  └────────┘ │  │  └────────┘ │  │  └────────┘ ││
│ │  ┌────────┐ │  │  ┌────────┐ │  │  ┌────────┐ ││
│ │  │Widget 2│ │  │  │Widget 2│ │  │  │Widget 2│ ││
│ │  └────────┘ │  │  └────────┘ │  │  └────────┘ ││
│ └─────────────┘  └─────────────┘  └──────────────┘│
└─────────────────────────────────────────────────────┘
```

**Page** = Route nel menu (es. `/admin/workers`)
**Plugin/Widget** = Componenti modulari che vivono nelle pages

## 📂 Struttura

```
ewh/
├── migrations/
│   └── 013_create_plugin_system.sql    # Database schema
│
├── shared/
│   └── plugin-engine/                  # Core engine
│       ├── types/index.ts              # Type definitions
│       └── src/
│           ├── HookSystem.ts           # WordPress-style hooks
│           ├── EventBus.ts             # Pub/sub events
│           ├── PluginRegistry.ts       # Plugin registry
│           └── index.ts
│
├── svc-plugin-manager/                 # Backend service
│   └── src/
│       └── services/
│           └── PluginManager.ts        # Lifecycle management
│
├── app-admin-frontend/
│   └── lib/plugins/
│       ├── DynamicPageLoader.tsx       # Load pages from plugins
│       └── DynamicWidgetLoader.tsx     # Load widgets from plugins
│
└── plugins/                            # Plugin directory
    └── plugin-workers/                 # Example plugin
        ├── manifest.json               # Plugin metadata
        ├── backend/
        │   └── index.ts                # Backend logic
        ├── frontend/
        │   ├── widgets/                # Widget components
        │   │   └── WorkerStatusWidget.tsx
        │   └── pages/                  # Page components
        │       └── WorkersDashboard.tsx
        └── migrations/                 # Database migrations
            └── 001_create_workers_tables.sql
```

## 🔌 Creare un Nuovo Plugin

### 1. Manifest File

```json
{
  "id": "ewh-plugin-myfeature",
  "name": "My Feature",
  "slug": "myfeature",
  "version": "1.0.0",
  "description": "Description of what this plugin does",
  "author": { "name": "Your Name", "email": "you@example.com" },

  "capabilities": {
    "backend": true,
    "frontend": true,
    "widgets": true,
    "pages": true
  },

  "ui": {
    "menu": [
      {
        "id": "myfeature",
        "label": "My Feature",
        "route": "/admin/myfeature",
        "icon": "Star",
        "position": 25
      }
    ],
    "widgets": [
      {
        "id": "my-widget",
        "name": "My Widget",
        "component": "./frontend/widgets/MyWidget.tsx",
        "category": "monitoring",
        "defaultSize": { "w": 6, "h": 4 }
      }
    ],
    "pages": [
      {
        "id": "myfeature-dashboard",
        "name": "My Feature Dashboard",
        "slug": "/admin/myfeature",
        "component": "./frontend/pages/Dashboard.tsx"
      }
    ]
  }
}
```

### 2. Widget Component

```tsx
// plugins/plugin-myfeature/frontend/widgets/MyWidget.tsx

import { useState, useEffect } from 'react';
import type { WidgetProps } from '@ewh/plugin-engine';

export default function MyWidget({ instanceId, config, isEditMode }: WidgetProps) {
  const [data, setData] = useState(null);

  useEffect(() => {
    // Fetch data
    fetch('/api/myfeature/data')
      .then(r => r.json())
      .then(setData);
  }, []);

  return (
    <div className="h-full bg-slate-900 rounded-lg border border-slate-800 p-4">
      <h3 className="text-white font-semibold mb-4">My Widget</h3>
      {/* Your widget UI */}
    </div>
  );
}
```

### 3. Page Component

```tsx
// plugins/plugin-myfeature/frontend/pages/Dashboard.tsx

import { DynamicWidget } from '@/lib/plugins/DynamicWidgetLoader';

export default function MyFeatureDashboard() {
  return (
    <div className="min-h-screen bg-slate-950">
      <div className="p-8">
        <h1 className="text-3xl font-bold text-white mb-6">My Feature</h1>

        {/* Mount widgets */}
        <div className="grid grid-cols-12 gap-6">
          <div className="col-span-6">
            <DynamicWidget
              widgetId="my-widget"
              instanceId="1"
              config={{}}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
```

### 4. Backend Hooks (Optional)

```typescript
// plugins/plugin-myfeature/backend/index.ts

import { PluginContext } from '@ewh/plugin-engine';

export async function onActivate() {
  console.log('Plugin activated!');
}

export async function onDeactivate() {
  console.log('Plugin deactivated!');
}

// Listen to system hooks
export async function onUserCreated(user: any) {
  console.log('New user created:', user);
  // Do something with the event
}
```

## 🚀 Installare un Plugin

### Via CLI

```bash
# Navigate to plugin directory
cd /path/to/your/plugin

# Install via API
curl -X POST http://localhost:4000/api/plugins/install \
  -H "Content-Type: application/json" \
  -d '{"manifestPath": "./manifest.json"}'

# Activate
curl -X POST http://localhost:4000/api/plugins/activate/ewh-plugin-myfeature
```

### Via God Mode UI

1. Go to `/god-mode/plugins`
2. Click "Upload Plugin"
3. Select plugin directory or ZIP file
4. Click "Install"
5. Click "Activate"

## 🎨 Aggiungere una Nuova Pagina Admin

**Scenario:** Vuoi creare la pagina "Workers" in admin.

### Opzione 1: Plugin Dedicato (Consigliato)

```bash
# Create plugin structure
mkdir -p plugins/plugin-workers/{frontend/{pages,widgets},migrations}

# Create manifest.json
# Create page component
# Create widget components
# Install plugin
```

### Opzione 2: Aggiungere al Core

```sql
-- Add to page_definitions table
INSERT INTO plugins.page_definitions (
  page_id, name, slug, icon, menu_position, is_system_page
) VALUES (
  'admin-workers', 'Workers', '/admin/workers', 'Cpu', 17, TRUE
);
```

Poi crea il componente in `app-admin-frontend/pages/admin/workers.tsx`

## 🪝 Hook System

### Available Hooks

```typescript
// Action Hooks (no return value)
hookSystem.doAction('user:created', userData);
hookSystem.doAction('worker:task.completed', taskData);

// Filter Hooks (modify and return value)
const profile = await hookSystem.applyFilters('user:profile', baseProfile, userId);
const widgets = await hookSystem.applyFilters('dashboard:widgets', defaultWidgets);
```

### Register Hook Handler

```typescript
// In your plugin backend
hookSystem.addAction('user:created', async (user) => {
  // Do something when user is created
  await sendWelcomeEmail(user);
}, 'my-plugin-id', 10); // priority: 10
```

### Provided System Hooks

- `user:created` - After user creation
- `user:updated` - After user update
- `user:deleted` - Before user deletion
- `tenant:created` - After tenant creation
- `system:startup` - On system start
- `dashboard:loaded` - Dashboard page load
- `dashboard:widgets` - Filter available widgets

## 📊 Database Schema

### Core Tables

- `plugins.installed_plugins` - Plugin registry
- `plugins.plugin_dependencies` - Dependency tracking
- `plugins.plugin_hooks` - Hook registrations
- `plugins.page_definitions` - Admin pages
- `plugins.page_widgets` - Widget instances on pages
- `plugins.widget_definitions` - Available widgets
- `plugins.plugin_permissions` - Permission grants
- `plugins.plugin_events` - Audit log

## 🎯 Use Cases

### Scenario 1: New Feature Module

**Want:** Add "Email Marketing" feature

**Solution:** Create `plugin-email-marketing` with:
- Email campaign widgets
- Analytics widgets
- Campaign management page
- Template editor page

### Scenario 2: Custom Dashboard

**Want:** Create tenant-specific dashboard

**Solution:**
- Create custom page in plugin
- Mount different widgets based on tenant config
- Save layout per tenant in DB

### Scenario 3: Third-party Integration

**Want:** Integrate with Stripe for billing

**Solution:**
- Create `plugin-stripe-integration`
- Add webhook handlers
- Create billing widgets
- Add to billing page

## 🔐 Security

### Permission System

Plugins request permissions in manifest:

```json
{
  "permissions": [
    {
      "type": "database",
      "resource": "users",
      "action": "read",
      "reason": "Need to display user list"
    }
  ]
}
```

Admin must approve permissions before activation.

### Sandboxing

- Plugins run in isolated contexts
- Database access only through granted permissions
- API calls logged and rate-limited
- File system access restricted

## 📈 Roadmap

- [ ] Hot reload for development
- [ ] Plugin marketplace
- [ ] Visual dashboard builder (drag & drop)
- [ ] Plugin versioning and updates
- [ ] Automated testing framework
- [ ] Plugin analytics
- [ ] Multi-language support
- [ ] Theme system for widgets

## 🎓 Examples

See `plugins/plugin-workers/` for complete working example with:
- ✅ Multiple widgets
- ✅ Full page components
- ✅ Database migrations
- ✅ Hook integrations
- ✅ Real-time updates

## 🆘 Troubleshooting

### Plugin not appearing in menu
- Check `is_active` in `page_definitions` table
- Verify plugin is activated
- Check `showInMenu` in manifest

### Widget not loading
- Check browser console for errors
- Verify widget component path in manifest
- Check if plugin is activated

### Database errors
- Ensure migrations ran successfully
- Check `plugins.plugin_events` for errors
- Verify database permissions

## 📞 Support

For plugin development help:
- Check examples in `/plugins`
- Read type definitions in `shared/plugin-engine/types`
- Review hook system in `shared/plugin-engine/src/HookSystem.ts`
