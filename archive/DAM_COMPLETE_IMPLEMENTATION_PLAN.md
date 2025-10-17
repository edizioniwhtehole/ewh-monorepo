# DAM - Piano Implementazione Completo

## Situazione Attuale

### Esiste Già:
1. **@ewh/shared-widgets** - Sistema widget condiviso
2. **app-dam** - Frontend DAM con sistema pannelli
3. **DockableWorkspace** - Sistema pannelli ridimensionabili
4. **LayoutSelector** - Selettore layout colonne

### Manca:
1. **Sistema griglia** nell'area centrale per affiancare pannelli
2. **Widget registry** per DAM specifico
3. **Webhook/automation** system
4. **Widget editor** per creare custom widgets
5. **Marketplace** per condividere widget

## Piano Completo - 3 Fasi

---

## FASE 1: Sistema Griglia Centrale (1-2 giorni)

### Obiettivo
Permettere di dividere l'area centrale in sezioni e affiancare i pannelli.

### Implementazione

#### 1.1 Estendi Store con Split System
```typescript
// src/store/dockablePanelsStore.ts

export type CenterLayout =
  | 'single'           // Un pannello full
  | 'horizontal'       // Due pannelli: top/bottom
  | 'vertical'         // Due pannelli: left/right
  | 'grid-2x2'         // 4 pannelli in griglia
  | 'focus-bottom'     // Top grande, bottom split
  | 'focus-right';     // Left grande, right split

interface LayoutConfig {
  centerLayout: CenterLayout;
  centerSplitRatio: number;  // 0.5 = 50/50, 0.7 = 70/30
}
```

#### 1.2 CenterLayoutSelector Component
```tsx
// src/components/dockable/CenterLayoutSelector.tsx

export function CenterLayoutSelector() {
  const layouts = [
    { id: 'single', icon: Square, label: 'Singolo' },
    { id: 'horizontal', icon: MinusSquare, label: 'Diviso Orizzontale' },
    { id: 'vertical', icon: Columns2, label: 'Diviso Verticale' },
    { id: 'grid-2x2', icon: LayoutGrid, label: 'Griglia 2x2' },
    { id: 'focus-bottom', icon: PanelTop, label: 'Focus Top' },
    { id: 'focus-right', icon: PanelLeft, label: 'Focus Left' }
  ];

  return (
    <div className="center-layout-selector">
      <span>Area Centrale:</span>
      {layouts.map(layout => (
        <button onClick={() => setCenterLayout(layout.id)}>
          <layout.icon />
          {layout.label}
        </button>
      ))}
    </div>
  );
}
```

#### 1.3 CenterGrid Component
```tsx
// src/components/dockable/CenterGrid.tsx

export function CenterGrid({ panels, layout }) {
  switch (layout) {
    case 'single':
      return <SinglePanel panel={panels[0]} />;

    case 'horizontal':
      return (
        <div className="flex flex-col h-full">
          <Resizable height={splitRatio}>
            <PanelSlot panels={panels.filter(p => p.slot === 'top')} />
          </Resizable>
          <PanelSlot panels={panels.filter(p => p.slot === 'bottom')} />
        </div>
      );

    case 'vertical':
      return (
        <div className="flex h-full">
          <Resizable width={splitRatio}>
            <PanelSlot panels={panels.filter(p => p.slot === 'left')} />
          </Resizable>
          <PanelSlot panels={panels.filter(p => p.slot === 'right')} />
        </div>
      );

    case 'grid-2x2':
      return (
        <div className="grid grid-cols-2 grid-rows-2 h-full gap-1">
          <PanelSlot panels={panels.filter(p => p.slot === 'top-left')} />
          <PanelSlot panels={panels.filter(p => p.slot === 'top-right')} />
          <PanelSlot panels={panels.filter(p => p.slot === 'bottom-left')} />
          <PanelSlot panels={panels.filter(p => p.slot === 'bottom-right')} />
        </div>
      );

    // ... altri layout
  }
}
```

#### 1.4 Drop Zones per Center Grid
Quando trascini un pannello nell'area centrale, mostra zone per assegnarlo a uno slot specifico.

```tsx
<div className="drop-zone top-slot" />
<div className="drop-zone bottom-slot" />
<div className="drop-zone left-slot" />
<div className="drop-zone right-slot" />
```

---

## FASE 2: Widget System + Webhooks (2-3 giorni)

### Obiettivo
Integrare @ewh/shared-widgets con DAM e aggiungere webhooks.

### Implementazione

#### 2.1 Estendi Shared Widgets Types
```typescript
// shared/packages/widgets/src/types.ts

export interface WidgetDefinition {
  // ... esistente ...

  // Aggiungi:
  events?: WidgetEvent[];
  webhooks?: WebhookConfig[];
  customizable?: boolean;
  marketplace?: {
    price?: number;
    rating?: number;
    downloads?: number;
  };
}

export interface WidgetEvent {
  name: string;
  description: string;
  payload: Record<string, any>;
}

export interface WebhookConfig {
  id: string;
  event: string;
  url: string;
  method: 'GET' | 'POST' | 'PUT';
  headers?: Record<string, string>;
  enabled: boolean;
  transform?: string;  // JS code
}
```

#### 2.2 Widget Registry per DAM
```typescript
// app-dam/src/widgets/DAMWidgetRegistry.ts

export const DAM_WIDGETS: Record<string, WidgetDefinition> = {
  'asset-browser': {
    id: 'asset-browser',
    name: 'Asset Browser',
    componentPath: '@/modules/dam/widgets/AssetBrowserWidget',
    events: [
      {
        name: 'onAssetSelect',
        payload: { assetId: 'string', asset: 'Asset' }
      },
      {
        name: 'onAssetOpen',
        payload: { assetId: 'string' }
      }
    ],
    defaultConfig: {
      viewMode: 'grid',
      itemsPerPage: 50
    }
  },

  'asset-preview': {
    id: 'asset-preview',
    name: 'Asset Preview',
    componentPath: '@/modules/dam/widgets/AssetPreviewWidget',
    events: [
      {
        name: 'onDownload',
        payload: { assetId: 'string', format: 'string' }
      }
    ]
  },

  // ... altri widget
};
```

#### 2.3 Webhook Manager
```typescript
// app-dam/src/core/WebhookManager.ts

export class WebhookManager {
  async trigger(widgetId: string, eventName: string, payload: any) {
    const widget = getWidget(widgetId);
    const webhooks = widget.webhooks?.filter(w =>
      w.event === eventName && w.enabled
    );

    for (const webhook of webhooks) {
      try {
        // Transform data if needed
        let data = payload;
        if (webhook.transform) {
          const transformFn = new Function('data', webhook.transform);
          data = transformFn(payload);
        }

        // Send webhook
        const response = await fetch(webhook.url, {
          method: webhook.method,
          headers: {
            'Content-Type': 'application/json',
            ...webhook.headers
          },
          body: JSON.stringify(data)
        });

        // Log success
        await logWebhook(webhook.id, 'success', response);
      } catch (error) {
        // Log error and retry
        await logWebhook(webhook.id, 'error', error);
      }
    }
  }
}
```

#### 2.4 Widget con Webhook Example
```tsx
// Esempio: Asset Browser che trigghera webhook quando selezioni asset

export function AssetBrowserWidget({ config, onEvent }) {
  const handleAssetSelect = async (asset) => {
    // Trigger evento
    await onEvent('onAssetSelect', {
      assetId: asset.id,
      asset: asset,
      timestamp: Date.now()
    });

    // Il WebhookManager intercetta l'evento e invia ai webhook configurati
  };

  return <div onClick={handleAssetSelect}>...</div>;
}
```

---

## FASE 3: Widget Editor + Marketplace (3-4 giorni)

### Obiettivo
Permettere agli utenti di creare widget custom e condividerli.

### Implementazione

#### 3.1 Widget Editor UI
```tsx
// app-dam/src/pages/widgets/editor.tsx

export default function WidgetEditorPage() {
  return (
    <div className="widget-editor">
      <Sidebar>
        <ComponentLibrary />  {/* Drag & drop components */}
      </Sidebar>

      <Canvas>
        <WidgetPreview />  {/* Live preview */}
      </Canvas>

      <PropertiesPanel>
        <PropertyEditor />
        <EventEditor />
        <WebhookEditor />
      </PropertiesPanel>
    </div>
  );
}
```

#### 3.2 Webhook Editor
```tsx
// app-dam/src/components/widgets/WebhookEditor.tsx

export function WebhookEditor({ webhooks, onChange }) {
  return (
    <div>
      <h3>Webhooks & Automazioni</h3>
      {webhooks.map(webhook => (
        <div key={webhook.id} className="webhook-config">
          <select value={webhook.event}>
            <option>onAssetSelect</option>
            <option>onAssetUpload</option>
            <option>onFilter</option>
          </select>

          <input
            value={webhook.url}
            placeholder="https://api.example.com/hook"
          />

          <select value={webhook.method}>
            <option>POST</option>
            <option>GET</option>
            <option>PUT</option>
          </select>

          <CodeEditor
            label="Transform Data"
            value={webhook.transform}
            language="javascript"
          />

          <button onClick={() => testWebhook(webhook)}>
            Test
          </button>
        </div>
      ))}

      <button onClick={addWebhook}>+ Aggiungi Webhook</button>
    </div>
  );
}
```

#### 3.3 Widget Marketplace
```tsx
// app-dam/src/pages/widgets/marketplace.tsx

export default function WidgetMarketplacePage() {
  return (
    <div className="marketplace">
      <SearchBar />
      <FilterSidebar categories={['Browser', 'Viewer', 'Editor', 'Automation']} />

      <WidgetGrid>
        {widgets.map(widget => (
          <WidgetCard
            key={widget.id}
            widget={widget}
            onInstall={() => installWidget(widget.id)}
          />
        ))}
      </WidgetGrid>
    </div>
  );
}
```

---

## File Structure Finale

```
app-dam/
├── src/
│   ├── components/
│   │   └── dockable/
│   │       ├── DockableWorkspace.tsx
│   │       ├── LayoutSelector.tsx
│   │       ├── CenterLayoutSelector.tsx  ← NUOVO
│   │       └── CenterGrid.tsx            ← NUOVO
│   ├── core/
│   │   └── WebhookManager.ts             ← NUOVO
│   ├── pages/
│   │   └── widgets/
│   │       ├── editor.tsx                ← NUOVO
│   │       └── marketplace.tsx           ← NUOVO
│   └── widgets/
│       ├── DAMWidgetRegistry.ts          ← NUOVO
│       └── built-in/
│           ├── AssetBrowserWidget/
│           └── AssetPreviewWidget/

shared/
└── packages/
    └── widgets/
        └── src/
            ├── types.ts                  ← ESTENDI
            └── WidgetRegistry.ts
```

---

## Roadmap

### Sprint 1 (Week 1)
- [x] Sistema pannelli base
- [x] Layout selector colonne
- [ ] Centro grid system
- [ ] Drop zones per center slots

### Sprint 2 (Week 2)
- [ ] Estendi shared widgets types
- [ ] DAM Widget Registry
- [ ] Webhook Manager
- [ ] Test integrazione eventi/webhook

### Sprint 3 (Week 3)
- [ ] Widget Editor UI base
- [ ] Property Editor
- [ ] Webhook Editor
- [ ] Live Preview

### Sprint 4 (Week 4)
- [ ] Widget Marketplace UI
- [ ] Widget Installation system
- [ ] Widget Permissions
- [ ] Documentation

---

## Cosa Implemento Ora?

Scegli una priorità:

1. **Centro Grid System** (oggi) - Finire il sistema griglia per affiancare pannelli
2. **Webhook Integration** (domani) - Sistema webhooks per automazioni
3. **Widget Editor** (prossima settimana) - Editor visuale per creare widget

Quale partiamo?
