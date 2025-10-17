# 🏗️ Architettura Unificata Widget/Module System

## 📋 Problema da Risolvere

Attualmente abbiamo:
- **app-admin-frontend**: Grafici e dashboard hardcoded
- **app-page-builder**: Widget React isolati con dati mock
- **Nessuna condivisione** tra admin e page builder
- **Duplicazione** di componenti (grafici, tabelle, cards)

**Obiettivo:** Sistema unificato dove **tutti i componenti** possono essere usati come:
1. Widget nel Page Builder (drag & drop)
2. Moduli nell'Admin Dashboard
3. Componenti nelle pagine pubbliche

---

## 🎯 Architettura Target

```
shared/widgets/                          # Package condiviso
├── src/
│   ├── registry/
│   │   └── index.ts                     # Widget Registry centrale
│   │
│   ├── widgets/                         # Widget atomici (riusabili)
│   │   ├── ConnectedUsersWidget/
│   │   │   ├── index.tsx                # Componente React
│   │   │   ├── config.schema.json      # JSON Schema per config
│   │   │   ├── default.config.json     # Configurazione di default
│   │   │   └── metadata.json           # Nome, icona, categoria, descrizione
│   │   │
│   │   ├── StatsCard/
│   │   │   ├── index.tsx
│   │   │   ├── config.schema.json
│   │   │   ├── default.config.json
│   │   │   └── metadata.json
│   │   │
│   │   ├── ChartWidget/
│   │   │   ├── index.tsx
│   │   │   ├── config.schema.json
│   │   │   ├── default.config.json
│   │   │   └── metadata.json
│   │   │
│   │   └── DataTable/
│   │       ├── index.tsx
│   │       ├── config.schema.json
│   │       ├── default.config.json
│   │       └── metadata.json
│   │
│   ├── modules/                         # Composizioni di widget (pagine)
│   │   ├── DashboardModule/             # Es: Dashboard completa
│   │   │   ├── index.tsx                # Layout + widget composition
│   │   │   ├── config.schema.json
│   │   │   └── metadata.json
│   │   │
│   │   └── AnalyticsModule/
│   │       ├── index.tsx
│   │       ├── config.schema.json
│   │       └── metadata.json
│   │
│   ├── adapters/                        # Adapter per framework
│   │   ├── grapesjs.adapter.ts         # GrapesJS (Page Builder)
│   │   ├── dashboard.adapter.ts         # Admin Dashboard
│   │   └── renderer.adapter.ts          # Pagine pubbliche
│   │
│   ├── data-sources/                    # Data fetching logic
│   │   ├── useWidgetData.ts            # Hook React per data fetching
│   │   ├── api-client.ts               # Client API centralizzato
│   │   └── mock-data.ts                # Dati mock per preview
│   │
│   └── types/
│       ├── widget.types.ts
│       ├── config.types.ts
│       └── data.types.ts
│
└── package.json
```

---

## 📦 Struttura di un Widget

### 1. **Widget Component** (`index.tsx`)

```typescript
import React from 'react';
import { useWidgetData } from '../../data-sources/useWidgetData';
import { StatsCardConfig } from './types';

export interface StatsCardProps {
  config: StatsCardConfig;
  mode: 'preview' | 'live';  // preview = mock, live = real data
  context?: {
    tenantId: string;
    userId?: string;
  };
}

export const StatsCard: React.FC<StatsCardProps> = ({ config, mode, context }) => {
  // Auto-fetch data se mode='live'
  const { data, loading, error } = useWidgetData({
    endpoint: config.dataEndpoint,
    params: config.dataParams,
    enabled: mode === 'live',
    fallback: config.mockData,  // Usa mock se preview
  });

  if (loading) return <Skeleton />;
  if (error) return <ErrorState error={error} />;

  return (
    <div className="stats-card">
      <div className="stats-card-icon">{config.icon}</div>
      <div className="stats-card-value">{data.value}</div>
      <div className="stats-card-label">{config.title}</div>
      <div className="stats-card-change">
        <span className={data.trend}>{data.change}</span>
      </div>
    </div>
  );
};
```

### 2. **Config Schema** (`config.schema.json`)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "title": {
      "type": "string",
      "description": "Card title"
    },
    "icon": {
      "type": "string",
      "description": "Icon emoji or unicode"
    },
    "dataEndpoint": {
      "type": "string",
      "format": "uri",
      "description": "API endpoint for real data"
    },
    "dataParams": {
      "type": "object",
      "description": "Query parameters for API"
    },
    "mockData": {
      "type": "object",
      "description": "Fallback data for preview mode"
    },
    "refreshInterval": {
      "type": "number",
      "minimum": 0,
      "description": "Auto-refresh interval in ms (0 = disabled)"
    }
  },
  "required": ["title", "icon"]
}
```

### 3. **Default Config** (`default.config.json`)

```json
{
  "title": "Total Users",
  "icon": "👥",
  "dataEndpoint": "/api/stats/users/total",
  "dataParams": {},
  "mockData": {
    "value": "1,234",
    "change": "+12%",
    "trend": "up"
  },
  "refreshInterval": 30000
}
```

### 4. **Metadata** (`metadata.json`)

```json
{
  "id": "stats-card",
  "name": "Stats Card",
  "description": "Display a single metric with trend indicator",
  "category": "analytics",
  "icon": "📊",
  "version": "1.0.0",
  "author": "EWH Platform",
  "tags": ["stats", "analytics", "card", "metrics"],
  "preview": "/previews/stats-card.png",
  "supports": {
    "pageBuilder": true,
    "dashboard": true,
    "public": true
  }
}
```

---

## 🔌 Adapter Pattern

### **GrapesJS Adapter** (Page Builder)

```typescript
// shared/widgets/src/adapters/grapesjs.adapter.ts

import { Editor } from 'grapesjs';
import { WidgetRegistry } from '../registry';
import { createElement } from 'react';
import { createRoot } from 'react-dom/client';

export function registerWidgetsInGrapesJS(editor: Editor) {
  const widgets = WidgetRegistry.getAll();

  widgets.forEach(widget => {
    // Register as GrapesJS block
    editor.BlockManager.add(`widget-${widget.metadata.id}`, {
      label: widget.metadata.name,
      media: widget.metadata.icon,
      category: {
        id: `widgets-${widget.metadata.category}`,
        label: `Widgets: ${widget.metadata.category}`,
      },
      content: {
        type: 'shared-widget',
        attributes: {
          'data-widget-id': widget.metadata.id,
          'data-widget-config': JSON.stringify(widget.defaultConfig),
        },
      },
    });
  });

  // Register component type
  editor.DomComponents.addType('shared-widget', {
    model: {
      defaults: {
        tagName: 'div',
        draggable: true,
        resizable: true,
      },
    },
    view: {
      onRender() {
        const widgetId = this.model.getAttributes()['data-widget-id'];
        const config = JSON.parse(this.model.getAttributes()['data-widget-config'] || '{}');

        const widget = WidgetRegistry.get(widgetId);
        const root = createRoot(this.el);

        root.render(
          createElement(widget.Component, {
            config,
            mode: 'preview',  // Preview mode nel page builder
          })
        );
      },
    },
  });
}
```

### **Dashboard Adapter** (Admin Frontend)

```typescript
// shared/widgets/src/adapters/dashboard.adapter.ts

import { WidgetRegistry } from '../registry';
import { createElement } from 'react';

export interface DashboardLayout {
  widgets: Array<{
    id: string;
    position: { x: number; y: number; w: number; h: number };
    config: any;
  }>;
}

export function renderDashboard(layout: DashboardLayout, container: HTMLElement) {
  layout.widgets.forEach(({ id, position, config }) => {
    const widget = WidgetRegistry.get(id);

    const widgetContainer = document.createElement('div');
    widgetContainer.style.gridColumn = `${position.x} / span ${position.w}`;
    widgetContainer.style.gridRow = `${position.y} / span ${position.h}`;

    container.appendChild(widgetContainer);

    const root = createRoot(widgetContainer);
    root.render(
      createElement(widget.Component, {
        config,
        mode: 'live',  // Live mode in dashboard
        context: {
          tenantId: getCurrentTenantId(),
          userId: getCurrentUserId(),
        },
      })
    );
  });
}
```

---

## 🔄 Data Flow

### **Preview Mode** (Page Builder / Design)
```
Widget Component
  ↓
useWidgetData(mode='preview')
  ↓
Mock Data (da default.config.json)
  ↓
Render con dati fake
```

### **Live Mode** (Dashboard / Pagine Pubbliche)
```
Widget Component
  ↓
useWidgetData(mode='live')
  ↓
API Gateway (/api/stats/users/total)
  ↓
Backend Microservice
  ↓
Database
  ↓
Real Data
  ↓
Render con dati reali
```

---

## 📊 Widget Registry

```typescript
// shared/widgets/src/registry/index.ts

import { ConnectedUsersWidget } from '../widgets/ConnectedUsersWidget';
import { StatsCard } from '../widgets/StatsCard';
import { ChartWidget } from '../widgets/ChartWidget';

// Import metadata
import connectedUsersMetadata from '../widgets/ConnectedUsersWidget/metadata.json';
import statsCardMetadata from '../widgets/StatsCard/metadata.json';
import chartWidgetMetadata from '../widgets/ChartWidget/metadata.json';

// Import configs
import connectedUsersConfig from '../widgets/ConnectedUsersWidget/default.config.json';
import statsCardConfig from '../widgets/StatsCard/default.config.json';
import chartWidgetConfig from '../widgets/ChartWidget/default.config.json';

export interface WidgetDefinition {
  metadata: WidgetMetadata;
  Component: React.ComponentType<any>;
  defaultConfig: any;
  configSchema: any;
}

class WidgetRegistryClass {
  private widgets = new Map<string, WidgetDefinition>();

  register(widget: WidgetDefinition) {
    this.widgets.set(widget.metadata.id, widget);
  }

  get(id: string): WidgetDefinition | undefined {
    return this.widgets.get(id);
  }

  getAll(): WidgetDefinition[] {
    return Array.from(this.widgets.values());
  }

  getByCategory(category: string): WidgetDefinition[] {
    return this.getAll().filter(w => w.metadata.category === category);
  }
}

export const WidgetRegistry = new WidgetRegistryClass();

// Auto-register widgets
WidgetRegistry.register({
  metadata: connectedUsersMetadata,
  Component: ConnectedUsersWidget,
  defaultConfig: connectedUsersConfig,
  configSchema: {}, // TODO: import schema
});

WidgetRegistry.register({
  metadata: statsCardMetadata,
  Component: StatsCard,
  defaultConfig: statsCardConfig,
  configSchema: {},
});

WidgetRegistry.register({
  metadata: chartWidgetMetadata,
  Component: ChartWidget,
  defaultConfig: chartWidgetConfig,
  configSchema: {},
});
```

---

## 🗄️ Database Schema Integration

```sql
-- widgets.widget_definitions (già esistente)
-- Aggiungiamo solo un campo per il metadata
ALTER TABLE widgets.widget_definitions
ADD COLUMN metadata_json JSONB DEFAULT '{}';

-- Popolamento esempio
UPDATE widgets.widget_definitions
SET metadata_json = jsonb_build_object(
  'supports', jsonb_build_object(
    'pageBuilder', true,
    'dashboard', true,
    'public', true
  ),
  'tags', ARRAY['analytics', 'users', 'stats']
)
WHERE widget_id = 'connected-users';
```

---

## 🚀 Piano di Migrazione

### **Fase 1: Preparazione** (1-2 giorni)
- [ ] Creare package `shared/widgets` con struttura
- [ ] Migrare 3 widget esistenti nella nuova struttura
- [ ] Creare `WidgetRegistry` centralizzato
- [ ] Implementare `useWidgetData` hook

### **Fase 2: Page Builder** (1 giorno)
- [ ] Creare `grapesjs.adapter.ts`
- [ ] Integrare nuovo registry in `app-page-builder`
- [ ] Testare drag & drop con nuovi widget
- [ ] Verificare preview mode

### **Fase 3: Admin Dashboard** (2-3 giorni)
- [ ] Analizzare grafici esistenti in `app-admin-frontend`
- [ ] Creare `dashboard.adapter.ts`
- [ ] Migrare grafici dashboard come widget
- [ ] Implementare layout grid system
- [ ] Testare live mode con API reali

### **Fase 4: Data Integration** (2 giorni)
- [ ] Implementare API endpoints per ogni widget
- [ ] Configurare `dataEndpoint` in widget configs
- [ ] Testare switch preview → live mode
- [ ] Implementare caching e refresh logic

### **Fase 5: Documentation** (1 giorno)
- [ ] Documentare come creare nuovo widget
- [ ] Guide per sviluppatori
- [ ] Esempi di uso in diverse modalità

---

## 💡 Vantaggi

✅ **DRY (Don't Repeat Yourself)**: Un widget, multipli usi
✅ **Type Safety**: TypeScript + JSON Schema
✅ **Hot Reload**: Sviluppo rapido
✅ **Testabilità**: Preview mode con mock data
✅ **Scalabilità**: Facile aggiungere nuovi widget
✅ **Manutenibilità**: Struttura chiara e organizzata
✅ **Performance**: Lazy loading e code splitting
✅ **Sicurezza**: Data flow attraverso API Gateway

---

## 📝 Prossimi Step

Vuoi che inizi con:
1. **Fase 1**: Creare la struttura base del package shared/widgets?
2. **Fase 3**: Analizzare i grafici esistenti nell'admin frontend per identificarli?
3. **Documento tecnico**: Specifiche dettagliate per ogni widget?

Dimmi da dove vuoi partire!
