# DAM - Sistema Workspace Personalizzabile (Adobe Bridge Style)

## 🎯 Obiettivo

Sistema dove **ogni utente** può:
- ✅ Organizzare widget/pannelli come preferisce
- ✅ Salvare workspace personalizzati (es: "4K Monitor", "Laptop", "Focus Mode")
- ✅ Condividere workspace con altri utenti
- ✅ Adattarsi a diverse dimensioni schermo/font
- ✅ Widget conformi a @ewh/shared-widgets

## 🏗️ Architettura

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Workspace System                         │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Widgets    │    │   Layouts    │    │  Workspaces  │
│   (@ewh/     │    │   (Grid)     │    │  (Saved)     │
│   shared)    │    │              │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
```

### 1. Widget System (Usa @ewh/shared-widgets)

```typescript
// Integration con sistema esistente
import { WidgetDefinition, WidgetProps } from '@ewh/shared-widgets/types';

// Widget DAM specifici che estendono il sistema
interface DAMWidget extends WidgetDefinition {
  // Compatibile con sistema esistente
  defaultSize?: {
    w: number;  // Grid units
    h: number;
    minW?: number;
    minH?: number;
  };

  // Categorie DAM
  category: 'browser' | 'preview' | 'metadata' | 'tools' | 'analytics';
}

// Widget disponibili
const DAM_WIDGETS: DAMWidget[] = [
  {
    id: 'asset-browser',
    name: 'Asset Browser',
    pluginId: 'dam-core',
    componentPath: '@/modules/dam/widgets/AssetBrowserWidget',
    category: 'browser',
    defaultSize: { w: 8, h: 6, minW: 4, minH: 4 },
    contextSupport: { admin: true, tenant: true, user: true }
  },
  {
    id: 'asset-preview',
    name: 'Asset Preview',
    category: 'preview',
    defaultSize: { w: 4, h: 6, minW: 3, minH: 3 }
  },
  {
    id: 'metadata-editor',
    name: 'Metadata Editor',
    category: 'metadata',
    defaultSize: { w: 4, h: 4, minW: 3, minH: 2 }
  },
  // ... altri widget
];
```

### 2. Workspace System

```typescript
interface Workspace {
  id: string;
  userId: string;
  name: string;
  description?: string;

  // Layout configuration
  layout: {
    type: 'grid';  // Future: 'flow', 'tabs'
    config: {
      cols: 12;  // Grid columns
      rowHeight: 60;  // px per row
      margin: [8, 8];  // [x, y] margin
      compactType: 'vertical' | 'horizontal' | null;
    };
  };

  // Widget instances in this workspace
  widgets: WorkspaceWidget[];

  // Sidebar/toolbar configuration
  ui: {
    showLeftSidebar: boolean;
    leftSidebarWidth: number;
    showTopToolbar: boolean;
    fontSize: 'small' | 'medium' | 'large';
    density: 'compact' | 'comfortable' | 'spacious';
  };

  // Screen optimization
  optimizedFor?: {
    screenSize: 'laptop' | 'desktop' | '4k' | 'ultrawide';
    resolution: string;
    notes?: string;
  };

  // Sharing
  isPublic: boolean;
  sharedWith?: string[];  // User IDs

  // Metadata
  createdAt: string;
  updatedAt: string;
  thumbnail?: string;  // Screenshot del workspace
}

interface WorkspaceWidget {
  id: string;
  widgetId: string;  // Reference to DAMWidget

  // Position in grid
  position: {
    x: number;  // Grid column
    y: number;  // Grid row
    w: number;  // Width in grid units
    h: number;  // Height in grid units
  };

  // Widget configuration (merged con defaults)
  config: Record<string, any>;

  // Instance-specific settings
  settings: {
    title?: string;  // Custom title
    collapsed?: boolean;
    locked?: boolean;  // Lock position
  };
}
```

### 3. Workspace Manager UI

```
┌────────────────────────────────────────────────────────────────┐
│ DAM                    [Workspace: My 4K Setup ▼]   [@user]    │
├────────────────────────────────────────────────────────────────┤
│ [📁] [🔍] [⬆] [⚙]            [Save] [+ Widget] [⚙ Settings]  │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────┬────────────────────┐        │
│  │                              │                    │        │
│  │   Asset Browser (8x6)        │  Preview (4x6)     │        │
│  │                              │                    │        │
│  │                              │                    │        │
│  └──────────────────────────────┴────────────────────┘        │
│  ┌────────────────┬────────────────┬────────────────┐         │
│  │  Filters (4x4) │ Metadata (4x4) │ Details (4x4)  │         │
│  │                │                │                │         │
│  └────────────────┴────────────────┴────────────────┘         │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### 4. Workspace Selector

```tsx
// Dropdown per cambiare workspace velocemente
<WorkspaceSelector>
  <WorkspaceItem active>
    📐 My 4K Setup
    <span>4K Monitor, Small fonts</span>
  </WorkspaceItem>

  <WorkspaceItem>
    💻 Laptop Mode
    <span>1920x1080, Large fonts</span>
  </WorkspaceItem>

  <WorkspaceItem>
    🎯 Focus Mode
    <span>Only browser + preview</span>
  </WorkspaceItem>

  <Divider />

  <WorkspaceItem shared>
    👥 Team Default (by @admin)
  </WorkspaceItem>

  <Divider />

  <MenuItem onClick={createNew}>
    + New Workspace
  </MenuItem>

  <MenuItem onClick={openGallery}>
    🌐 Browse Templates
  </MenuItem>
</WorkspaceSelector>
```

### 5. Widget Palette

```tsx
// Pannello laterale per aggiungere widget
<WidgetPalette>
  <SearchBar placeholder="Search widgets..." />

  <CategoryGroup label="Browser">
    <WidgetCard
      widget={assetBrowser}
      draggable
      onAdd={() => addWidget('asset-browser')}
    />
    <WidgetCard widget={folderTree} draggable />
  </CategoryGroup>

  <CategoryGroup label="Preview & Edit">
    <WidgetCard widget={assetPreview} draggable />
    <WidgetCard widget={imageEditor} draggable />
  </CategoryGroup>

  <CategoryGroup label="Metadata">
    <WidgetCard widget={metadataEditor} draggable />
    <WidgetCard widget={tagManager} draggable />
  </CategoryGroup>

  <CategoryGroup label="Tools">
    <WidgetCard widget={batchOperations} draggable />
    <WidgetCard widget={exportManager} draggable />
  </CategoryGroup>
</WidgetPalette>
```

## 🎨 User Experience

### Scenario 1: Utente con 4K Monitor
```typescript
const workspace4K: Workspace = {
  name: "4K Workstation",
  ui: {
    fontSize: 'small',
    density: 'comfortable',
    showLeftSidebar: true,
    leftSidebarWidth: 250
  },
  widgets: [
    { widgetId: 'asset-browser', position: { x: 0, y: 0, w: 6, h: 8 } },
    { widgetId: 'preview', position: { x: 6, y: 0, w: 6, h: 8 } },
    { widgetId: 'metadata', position: { x: 0, y: 8, w: 4, h: 4 } },
    { widgetId: 'details', position: { x: 4, y: 8, w: 4, h: 4 } },
    { widgetId: 'timeline', position: { x: 8, y: 8, w: 4, h: 4 } }
  ]
};
```

### Scenario 2: Utente con Laptop + Font Grandi
```typescript
const workspaceLaptop: Workspace = {
  name: "Laptop - Large Fonts",
  ui: {
    fontSize: 'large',
    density: 'spacious',
    showLeftSidebar: false  // Più spazio
  },
  widgets: [
    // Meno widget, più grandi
    { widgetId: 'asset-browser', position: { x: 0, y: 0, w: 8, h: 10 } },
    { widgetId: 'preview', position: { x: 8, y: 0, w: 4, h: 10 } }
  ]
};
```

### Scenario 3: Focus Mode
```typescript
const workspaceFocus: Workspace = {
  name: "Focus Mode",
  ui: {
    showLeftSidebar: false,
    showTopToolbar: false  // Full screen
  },
  widgets: [
    { widgetId: 'asset-browser', position: { x: 0, y: 0, w: 12, h: 12 } }
  ]
};
```

## 🔧 Implementation Plan

### Phase 1: Core Workspace System (Week 1)
```typescript
// 1. Workspace Store
interface WorkspaceStore {
  workspaces: Workspace[];
  activeWorkspaceId: string;

  // Actions
  createWorkspace: (name: string) => void;
  loadWorkspace: (id: string) => void;
  saveWorkspace: () => void;
  deleteWorkspace: (id: string) => void;
  duplicateWorkspace: (id: string) => void;
}

// 2. Grid System (react-grid-layout)
import GridLayout from 'react-grid-layout';

<GridLayout
  layout={workspace.widgets}
  cols={12}
  rowHeight={60}
  onLayoutChange={handleLayoutChange}
  draggableHandle=".widget-header"
  resizeHandles={['se', 'sw', 'ne', 'nw']}
>
  {workspace.widgets.map(widget => (
    <div key={widget.id} className="widget-container">
      <WidgetRenderer widget={widget} />
    </div>
  ))}
</GridLayout>

// 3. Widget Renderer (compatibile con @ewh/shared-widgets)
<WidgetRenderer
  widgetId={widget.widgetId}
  config={mergedConfig}
  context={userContext}
  onConfigChange={handleConfigChange}
/>
```

### Phase 2: Widget Integration (Week 2)
- Migra widget DAM esistenti a @ewh/shared-widgets format
- Crea widget palette UI
- Drag & drop da palette a grid
- Widget settings panel

### Phase 3: Workspace Management (Week 3)
- Workspace selector UI
- Save/Load workspace
- Share workspace
- Workspace templates gallery
- Import/Export workspace JSON

### Phase 4: Screen Optimization (Week 4)
- Screen size detection
- Font size preferences
- Density modes (compact/comfortable/spacious)
- Workspace recommendations per screen size
- Workspace auto-switch per breakpoint

## 📦 File Structure

```
app-dam/
├── src/
│   ├── store/
│   │   └── workspaceStore.ts           ← NEW: Zustand store
│   │
│   ├── components/
│   │   ├── workspace/
│   │   │   ├── WorkspaceSelector.tsx   ← NEW
│   │   │   ├── WorkspaceGrid.tsx       ← NEW: Grid layout
│   │   │   ├── WidgetPalette.tsx       ← NEW: Widget library
│   │   │   ├── WidgetRenderer.tsx      ← NEW: Widget wrapper
│   │   │   └── WidgetSettings.tsx      ← NEW: Config panel
│   │   │
│   │   └── dockable/                    ← DEPRECATE (migrate to workspace)
│   │
│   ├── widgets/
│   │   ├── registry.ts                  ← NEW: DAM widgets registry
│   │   └── built-in/
│   │       ├── AssetBrowserWidget/      ← Migrate to @ewh/shared-widgets
│   │       ├── AssetPreviewWidget/
│   │       └── MetadataEditorWidget/
│   │
│   ├── pages/
│   │   ├── library.tsx                  ← Update: Use WorkspaceGrid
│   │   └── workspace/
│   │       ├── editor.tsx               ← NEW: Workspace editor
│   │       └── gallery.tsx              ← NEW: Template gallery
│   │
│   └── lib/
│       └── workspace-utils.ts           ← NEW: Helper functions
```

## 🚀 Next Steps

### Immediate (Today)
1. ✅ Install react-grid-layout
2. ✅ Create workspaceStore.ts
3. ✅ Build WorkspaceGrid component
4. ✅ Migrate 1-2 widgets to test

### Short-term (This Week)
- Widget Palette UI
- Workspace Selector
- Save/Load functionality
- Widget settings panel

### Medium-term (Next 2 Weeks)
- Template gallery
- Share workspaces
- Screen optimization
- Widget migration complete

## 📊 Benefits

✅ **Personalizzazione Totale**: Ogni utente organizza come vuole
✅ **Multi-Screen**: Workspace diversi per schermi diversi
✅ **Accessibilità**: Font e densità regolabili
✅ **Condivisione**: Team può condividere setup ottimali
✅ **Compatibilità**: Usa @ewh/shared-widgets esistente
✅ **Scalabile**: Aggiungi widget senza limiti

---

Vuoi che inizio con **Phase 1** (Core Workspace System)?
