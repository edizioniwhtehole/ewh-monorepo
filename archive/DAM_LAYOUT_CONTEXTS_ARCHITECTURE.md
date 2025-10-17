# 🎨 DAM Layout Contexts - Sistema Multi-Modalità

**Versione:** 2.0
**Data:** 12 Ottobre 2025
**Status:** Design Phase

---

## 🎯 Obiettivo

Implementare un sistema di layout multipli salvabili per supportare diversi contesti d'uso del DAM, ciascuno con la propria configurazione di pannelli ottimizzata.

---

## 📐 Layout Contexts Definiti

### 1. **Upload Mode** 🔼
**Use Case:** Importazione massiva di asset con metadata batch editing

**Layout Ottimale:**
```
┌─────────────────────────────────────────────────┐
│ Header: Upload Mode                             │
├────────────────┬────────────────────────────────┤
│                │                                │
│  Drop Zone     │  Upload Queue                  │
│  (Large)       │  - Progress bars               │
│                │  - Batch metadata edit         │
│  Drag & Drop   │  - Auto-tagging preview        │
│  Multiple      │  - Collection assignment       │
│  Files Here    │                                │
│                ├────────────────────────────────┤
│                │  Recent Uploads                │
│                │  - Thumbnails grid             │
└────────────────┴────────────────────────────────┘
```

**Widgets Essenziali:**
- `UploadDropZone` (main area, maximized)
- `UploadQueueWidget` (right sidebar)
- `BatchMetadataEditor` (right sidebar bottom)
- `RecentUploadsWidget` (bottom strip)

**Widgets Nascosti:**
- Preview (non necessario durante upload)
- Detailed metadata (troppo distrattivo)

---

### 2. **Culling Mode** 📸
**Use Case:** Photo selection (stile Lightroom), rating, tagging veloce

**Layout Ottimale:**
```
┌─────────────────────────────────────────────────┐
│ Header: Culling Mode | 1245 photos | 0 selected│
├─────────────────────────────────────────────────┤
│                                                 │
│            Full Screen Preview                  │
│            ← → Arrow Keys Navigation            │
│            1-5 Star Rating Hotkeys              │
│            X = Reject, P = Pick                 │
│                                                 │
├─────────────────────────────────────────────────┤
│ [★★★★★] [Flag] [Tags: ]  [Next] [←] [→] [Skip] │
└─────────────────────────────────────────────────┘
```

**Widgets Essenziali:**
- `FullScreenPreview` (maximized, no sidebar)
- `QuickRatingBar` (bottom overlay)
- `KeyboardShortcutsHelper` (top-right corner, collapsible)
- `CullingStatsWidget` (header integrated)

**Features:**
- **Hotkeys:** 1-5 stars, X reject, P pick, ← → navigate
- **Slideshow mode:** Auto-advance ogni 3 secondi
- **Compare mode:** Spacebar per confrontare 2 immagini side-by-side
- **Zoom:** Z per 100%, scroll per zoom variabile

---

### 3. **Overview Mode** 📊
**Use Case:** Navigazione libreria completa, ricerca, organizzazione

**Layout Ottimale:**
```
┌─────────────────────────────────────────────────┐
│ Header: Library Overview                        │
├─────┬───────────────────────────────────┬───────┤
│     │                                   │       │
│ Fol │  Asset Grid (Large)               │ Meta  │
│ der │  - Thumbnails 200px               │ data  │
│     │  - Multi-select                   │       │
│ Tree│  - Drag & drop                    │ Panel │
│     │  - Infinite scroll                │       │
│     │                                   │ ───── │
│     │                                   │       │
│ Fil │                                   │ Tags  │
│ ter │                                   │       │
│ s   │                                   │ ───── │
│     │                                   │       │
│     │                                   │ Quick │
│     │                                   │ Acts  │
└─────┴───────────────────────────────────┴───────┘
```

**Widgets Essenziali:**
- `FolderTreeWidget` (left sidebar, 280px)
- `FiltersPanel` (left sidebar, below tree)
- `AssetGridBrowser` (main area, maximized)
- `MetadataPanelWidget` (right sidebar, 320px)
- `TagManagerWidget` (right sidebar)
- `QuickActionsWidget` (right sidebar bottom)

**Questo è il layout "Default" attuale**

---

### 4. **Dashboard Mode** 📈
**Use Case:** Analytics, storage stats, team activity, approvals overview

**Layout Ottimale:**
```
┌─────────────────────────────────────────────────┐
│ Header: DAM Dashboard                           │
├──────────────┬──────────────┬───────────────────┤
│              │              │                   │
│  Storage     │  Recent      │  Pending          │
│  Stats       │  Activity    │  Approvals        │
│  - Used 45GB │  - Timeline  │  - 12 items       │
│  - Quota 100 │              │                   │
│              │              │                   │
├──────────────┴──────────────┴───────────────────┤
│                                                 │
│  Top Assets (Most Downloaded)                   │
│  [Preview Grid]                                 │
│                                                 │
├─────────────────────────────────────────────────┤
│  Team Activity Feed                             │
│  - User A uploaded 50 photos                    │
│  - User B approved "Brand Guidelines.pdf"       │
└─────────────────────────────────────────────────┘
```

**Widgets Essenziali:**
- `StorageStatsWidget` (top-left card)
- `ActivityTimelineWidget` (top-center card)
- `PendingApprovalsWidget` (top-right card)
- `TopAssetsWidget` (middle section)
- `TeamActivityFeedWidget` (bottom section)

---

### 5. **Embedded Mode** 🔌
**Use Case:** DAM ridotto integrato in progetti, CMS, altri sistemi

**Layout Ottimale:**
```
┌─────────────────────────────────────────────────┐
│ Asset Picker | Search: [____________] [Filter]  │
├──────────────────┬──────────────────────────────┤
│                  │                              │
│  Asset Grid      │  Preview                     │
│  (Compact)       │  (Large)                     │
│  - Small thumbs  │                              │
│  - Click to pick │  [Select This Asset] Button  │
│                  │                              │
│                  │  Metadata (Readonly)         │
└──────────────────┴──────────────────────────────┘
```

**Widgets Essenziali:**
- `CompactAssetGrid` (left, 40% width)
- `AssetPreviewWidget` (right, 60% width)
- `ReadonlyMetadataWidget` (right, below preview)
- `AssetPickerActions` (bottom: Select button)

**Features:**
- **Callback:** `onAssetSelected(asset)` per passare asset al parent
- **Filters:** Tipo file, folder specifico, date range
- **No bulk actions** (solo single select)

---

### 6. **File Manager Mode** 📁
**Use Case:** Navigazione stile Finder/Explorer per aprire asset in editor esterni

**Layout Ottimale:**
```
┌─────────────────────────────────────────────────┐
│ Path: /Projects/Brand/Logos > [Open in...]      │
├──────────┬──────────────────────────────────────┤
│          │  Name          │ Size   │ Modified   │
│ Folders  ├──────────────────────────────────────┤
│ ├ Brand  │ ▶ logo-v1.ai  │ 2.4 MB │ 2 days ago │
│ ├ Photos │ ▶ logo-v2.ai  │ 2.6 MB │ 1 day ago  │
│ └ Videos │ □ draft.psd   │ 45 MB  │ 5 min ago  │
│          │ □ banner.png  │ 890 KB │ 1 hour ago │
│          │                                      │
│          │  [Right Click Context Menu]          │
│          │  - Open in Photoshop                 │
│          │  - Open in Illustrator               │
│          │  - Reveal in Finder                  │
│          │  - Copy Path                         │
└──────────┴──────────────────────────────────────┘
```

**Widgets Essenziali:**
- `FolderTreeWidget` (left sidebar, 240px)
- `FileListWidget` (main area, list view)
- `BreadcrumbNavigation` (top bar)
- `ContextMenuWidget` (overlay on right-click)

**Features:**
- **Double-click:** Download or open in default app
- **Right-click:** Context menu con "Open With..."
- **Integration:** Adobe CC, Figma, etc.

---

### 7. **Approval Mode** ✅
**Use Case:** Review & approval workflow, annotations, comments

**Layout Ottimale:**
```
┌─────────────────────────────────────────────────┐
│ Approval Queue: 12 pending | Due in 2 days      │
├──────────┬──────────────────────────┬───────────┤
│          │                          │           │
│ Queue    │  Asset Preview           │ Comments  │
│ List     │  (Annotatable)           │ Thread    │
│ ─────    │                          │ ─────     │
│ ☐ Item 1 │  [Annotation Tools]      │ @John:    │
│ ☐ Item 2 │  - Pin comments          │ "Change   │
│ ☑ Item 3 │  - Draw shapes           │  the logo"│
│ ☐ Item 4 │  - Highlight areas       │           │
│          │                          │ [Reply]   │
│          ├──────────────────────────┤           │
│          │ [Approve] [Reject]       │ ─────     │
│          │ [Request Changes]        │ Version   │
│          │                          │ History   │
└──────────┴──────────────────────────┴───────────┘
```

**Widgets Essenziali:**
- `ApprovalQueueWidget` (left sidebar)
- `AnnotatablePreview` (center, large)
- `CommentThreadWidget` (right sidebar)
- `VersionHistoryWidget` (right sidebar bottom)
- `ApprovalActionsBar` (bottom)

---

## 🏗️ Architettura Tecnica

### Database Schema

**Sistema a 3 Livelli: Core → Tenant → User**

```sql
-- Layout Contexts Table
CREATE TABLE dam_layout_contexts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(50) UNIQUE NOT NULL, -- 'upload', 'culling', 'overview', etc.
  name VARCHAR(100) NOT NULL,
  description TEXT,
  icon VARCHAR(50), -- lucide-react icon name
  is_system BOOLEAN DEFAULT true, -- System context vs user-created
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════
-- TIER 1: CORE PRESETS (System-wide, Immutable)
-- ════════════════════════════════════════════════════════════════
CREATE TABLE dam_core_presets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  context_key VARCHAR(50) NOT NULL REFERENCES dam_layout_contexts(key),
  preset_name VARCHAR(100) NOT NULL, -- 'Default Upload', 'Compact Upload', etc.
  preset_key VARCHAR(50) NOT NULL, -- 'upload_default', 'upload_compact'
  layout_data JSONB NOT NULL, -- Serialized rc-dock layout
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  version VARCHAR(20) DEFAULT '1.0.0',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(context_key, preset_key)
);

-- ════════════════════════════════════════════════════════════════
-- TIER 2: TENANT PRESETS (Per Organization)
-- ════════════════════════════════════════════════════════════════
CREATE TABLE dam_tenant_presets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  context_key VARCHAR(50) NOT NULL REFERENCES dam_layout_contexts(key),
  preset_name VARCHAR(100) NOT NULL, -- Nome personalizzato dal tenant
  layout_data JSONB NOT NULL,
  based_on_core_preset_id UUID REFERENCES dam_core_presets(id), -- Optional: quale core preset è stato customizzato
  is_default_for_tenant BOOLEAN DEFAULT false, -- Default per questo tenant
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(tenant_id, context_key, preset_name)
);

-- Index per trovare velocemente il default di un tenant
CREATE INDEX idx_tenant_presets_default
  ON dam_tenant_presets(tenant_id, context_key)
  WHERE is_default_for_tenant = true;

-- ════════════════════════════════════════════════════════════════
-- TIER 3: USER LAYOUTS (Personal Customizations)
-- ════════════════════════════════════════════════════════════════
CREATE TABLE dam_user_layouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  context_key VARCHAR(50) NOT NULL REFERENCES dam_layout_contexts(key),
  layout_data JSONB NOT NULL,
  based_on_preset_id UUID, -- Può essere core preset o tenant preset
  based_on_preset_type VARCHAR(20), -- 'core' o 'tenant'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, context_key)
);

-- Context Access Permissions
CREATE TABLE dam_context_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  context_key VARCHAR(50) NOT NULL REFERENCES dam_layout_contexts(key),
  role VARCHAR(50) NOT NULL, -- 'admin', 'editor', 'viewer', etc.
  can_access BOOLEAN DEFAULT true,
  can_customize BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(context_key, role)
);
```

### Logica di Fallback (Inheritance Chain)

```typescript
/**
 * Ordine di priorità per caricare il layout:
 *
 * 1. User Layout (personalizzazione individuale)
 *    └─ Se non esiste ↓
 *
 * 2. Tenant Default Preset (default organizzazione)
 *    └─ Se non esiste ↓
 *
 * 3. Core Preset (default di sistema)
 *    └─ Sempre disponibile (garantito)
 */

async function getLayoutForUser(
  userId: string,
  tenantId: string,
  contextKey: string
) {
  // TIER 3: Check user personal layout
  const userLayout = await db.query(
    'SELECT layout_data FROM dam_user_layouts WHERE user_id = $1 AND context_key = $2 AND is_active = true',
    [userId, contextKey]
  );

  if (userLayout.rows.length > 0) {
    return {
      layout: userLayout.rows[0].layout_data,
      source: 'user',
      isCustomized: true
    };
  }

  // TIER 2: Check tenant default preset
  const tenantPreset = await db.query(
    'SELECT layout_data FROM dam_tenant_presets WHERE tenant_id = $1 AND context_key = $2 AND is_default_for_tenant = true',
    [tenantId, contextKey]
  );

  if (tenantPreset.rows.length > 0) {
    return {
      layout: tenantPreset.rows[0].layout_data,
      source: 'tenant',
      isCustomized: false
    };
  }

  // TIER 1: Fallback to core preset
  const corePreset = await db.query(
    'SELECT layout_data FROM dam_core_presets WHERE context_key = $1 AND is_active = true ORDER BY created_at DESC LIMIT 1',
    [contextKey]
  );

  return {
    layout: corePreset.rows[0].layout_data,
    source: 'core',
    isCustomized: false
  };
}
```

### API Endpoints

```typescript
// ════════════════════════════════════════════════════════════════
// CONTEXTS
// ════════════════════════════════════════════════════════════════

// Get available contexts for user
GET /api/dam/layouts/contexts
Response: {
  contexts: [
    { key: 'upload', name: 'Upload Mode', icon: 'upload', canAccess: true },
    { key: 'culling', name: 'Culling Mode', icon: 'image', canAccess: true },
    ...
  ]
}

// ════════════════════════════════════════════════════════════════
// TIER 1: CORE PRESETS (Read-only per utenti)
// ════════════════════════════════════════════════════════════════

// Get all core presets for a context
GET /api/dam/layouts/core-presets/:contextKey
Response: {
  presets: [
    {
      id: 'uuid',
      presetKey: 'upload_default',
      presetName: 'Default Upload',
      description: 'Standard upload layout with all panels',
      version: '1.0.0'
    },
    {
      id: 'uuid',
      presetKey: 'upload_compact',
      presetName: 'Compact Upload',
      description: 'Minimal upload layout for small screens',
      version: '1.0.0'
    }
  ]
}

// Get specific core preset layout data
GET /api/dam/layouts/core-presets/:contextKey/:presetKey
Response: {
  preset: {
    id: 'uuid',
    presetKey: 'upload_default',
    presetName: 'Default Upload',
    layout: { dockbox: {...}, floatbox: {...} }
  }
}

// ════════════════════════════════════════════════════════════════
// TIER 2: TENANT PRESETS (Admin-only write)
// ════════════════════════════════════════════════════════════════

// Get all tenant presets for a context
GET /api/dam/layouts/tenant-presets/:contextKey
Response: {
  presets: [
    {
      id: 'uuid',
      presetName: 'Marketing Team Upload',
      isDefault: true,
      basedOnCorePreset: 'upload_default',
      createdBy: { id: 'uuid', name: 'Admin User' },
      createdAt: '2025-10-01T10:00:00Z'
    }
  ]
}

// Create tenant preset (TENANT_ADMIN only)
POST /api/dam/layouts/tenant-presets/:contextKey
Body: {
  presetName: 'Marketing Team Upload',
  layout: { dockbox: {...}, floatbox: {...} },
  basedOnCorePresetId?: 'uuid',
  isDefaultForTenant: true
}
Response: {
  preset: { id: 'uuid', presetName: '...' }
}

// Update tenant preset (TENANT_ADMIN only)
PUT /api/dam/layouts/tenant-presets/:presetId
Body: {
  presetName?: 'New Name',
  layout?: { dockbox: {...} },
  isDefaultForTenant?: true
}

// Delete tenant preset (TENANT_ADMIN only)
DELETE /api/dam/layouts/tenant-presets/:presetId

// ════════════════════════════════════════════════════════════════
// TIER 3: USER LAYOUTS (Personal customizations)
// ════════════════════════════════════════════════════════════════

// Get user's layout for specific context (with fallback logic)
GET /api/dam/layouts/:contextKey
Response: {
  context: { key: 'upload', name: 'Upload Mode' },
  layout: { dockbox: {...}, floatbox: {...} },
  source: 'user' | 'tenant' | 'core', // Quale tier ha fornito il layout
  sourceDetails: {
    id?: 'uuid',
    name?: 'Marketing Team Upload' // Se tenant/core preset
  },
  isCustomized: true // true se user layout, false se tenant/core
}

// Save/Update user's personal layout
POST /api/dam/layouts/:contextKey
Body: {
  layout: { dockbox: {...}, floatbox: {...} },
  basedOnPresetId?: 'uuid', // Optional: track quale preset è stato customizzato
  basedOnPresetType?: 'core' | 'tenant'
}
Response: {
  success: true,
  message: 'Personal layout saved for Upload Mode'
}

// Reset user layout (torna a tenant/core default)
DELETE /api/dam/layouts/:contextKey
Response: {
  success: true,
  message: 'Personal layout deleted, using tenant default'
}

// Get available presets for user (core + tenant)
GET /api/dam/layouts/:contextKey/available-presets
Response: {
  corePresets: [
    { id: 'uuid', key: 'upload_default', name: 'Default Upload', source: 'core' }
  ],
  tenantPresets: [
    { id: 'uuid', name: 'Marketing Team Upload', source: 'tenant', isDefault: true }
  ]
}
```

### Esempi di Flussi

**Scenario 1: Nuovo utente, nessuna customizzazione**
```
GET /api/dam/layouts/upload
→ Nessun user layout
→ Nessun tenant preset
→ Ritorna core preset 'upload_default'
```

**Scenario 2: Tenant ha configurato default**
```
GET /api/dam/layouts/culling
→ Nessun user layout
→ Trova tenant preset 'Photo Team Culling' (is_default=true)
→ Ritorna tenant preset
```

**Scenario 3: Utente ha personalizzato**
```
GET /api/dam/layouts/overview
→ Trova user layout per questo user + context
→ Ritorna user layout (ignora tenant/core)
```

**Scenario 4: Utente resetta a default**
```
DELETE /api/dam/layouts/upload
→ Cancella user layout
→ Prossimo GET ritorna tenant preset (o core se tenant non esiste)
```

---

## 🎨 UI/UX Design

### Header Layout con 3-Tier System

```
┌────────────────────────────────────────────────────────────────────┐
│ [📊 Library ▼]  [Preset: My Custom Layout ▼]  [Save] [Reset]      │
└────────────────────────────────────────────────────────────────────┘
         │                        │
         │                        └─ Preset Selector (mostra tutti i 3 tier)
         └─ Context Switcher
```

### Context Switcher Component

```tsx
// Location: Top-left header
<ContextSwitcher
  currentContext="overview"
  availableContexts={[
    { key: 'overview', name: 'Library', icon: 'layout-grid' },
    { key: 'upload', name: 'Upload', icon: 'upload' },
    { key: 'culling', name: 'Culling', icon: 'image' },
    { key: 'dashboard', name: 'Dashboard', icon: 'bar-chart' },
    { key: 'approvals', name: 'Approvals', icon: 'check-circle' },
  ]}
  onContextChange={(key) => router.push(`/dam/${key}`)}
/>
```

**Visual del Context Switcher:**
```
┌──────────────────────────────────────────┐
│ [📊 Library ▼]                           │
│                                          │
│ Dropdown opens:                          │
│ ┌────────────────────────┐              │
│ │ 📊 Library      (active)│              │
│ │ 🔼 Upload               │              │
│ │ 📸 Culling              │              │
│ │ 📈 Dashboard            │              │
│ │ ✅ Approvals            │              │
│ │ ───────────────────────│              │
│ │ 📁 File Manager         │              │
│ │ 🔌 Embedded Mode        │              │
│ └────────────────────────┘              │
└──────────────────────────────────────────┘
```

### Preset Selector Component (3-Tier)

```tsx
// Location: Header, accanto al context switcher
<PresetSelector
  currentContext="upload"
  currentSource="user" // 'core' | 'tenant' | 'user'
  availablePresets={{
    core: [
      { id: 'uuid1', key: 'upload_default', name: 'Default Upload', icon: '🔧' },
      { id: 'uuid2', key: 'upload_compact', name: 'Compact Upload', icon: '🔧' },
    ],
    tenant: [
      { id: 'uuid3', name: 'Marketing Team', icon: '🏢', isDefault: true },
      { id: 'uuid4', name: 'Photo Team', icon: '🏢' },
    ],
    user: { id: 'uuid5', name: 'My Custom Layout', icon: '👤' }
  }}
  onPresetSelect={(presetId, source) => {
    // Load preset layout
  }}
  onSave={() => {
    // Save current layout as user customization
  }}
  onReset={() => {
    // Delete user layout, fallback to tenant/core
  }}
/>
```

**Visual del Preset Selector:**
```
┌────────────────────────────────────────────────────┐
│ Preset: [My Custom Layout ▼]   [Save] [Reset]     │
│                                                    │
│ Dropdown opens:                                    │
│ ┌──────────────────────────────────────────────┐  │
│ │ 👤 MY LAYOUT                                 │  │
│ │ ──────────────────────────────────────────── │  │
│ │ ✓ My Custom Layout              (current)    │  │
│ │                                              │  │
│ │ 🏢 TEAM PRESETS (Your Organization)          │  │
│ │ ──────────────────────────────────────────── │  │
│ │   Marketing Team                  (default)  │  │
│ │   Photo Team                                 │  │
│ │                                              │  │
│ │ 🔧 SYSTEM PRESETS (Built-in)                 │  │
│ │ ──────────────────────────────────────────── │  │
│ │   Default Upload                             │  │
│ │   Compact Upload                             │  │
│ │                                              │  │
│ │ ╔════════════════════════════════════════╗  │  │
│ │ ║ [+ Create Tenant Preset] (Admin only)  ║  │  │
│ │ ╚════════════════════════════════════════╝  │  │
│ └──────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘
```

### Behavior Logic

**Quando utente fa modifiche:**
```
1. Utente trascina/ridimensiona pannelli
   ↓
2. Layout diventa "modified" (mostra asterisco *)
   ↓
3. Button [Save] si evidenzia (primary color)
   ↓
4. Mostra indicator: "Preset: My Custom Layout *"
```

**Quando utente clicca Save:**
```
1. Se è la prima volta:
   → Crea nuovo user layout
   → Preset selector mostra "My Custom Layout"

2. Se già esiste user layout:
   → Aggiorna user layout esistente
   → Toast: "Layout saved"
```

**Quando utente clicca Reset:**
```
1. Conferma: "Reset to tenant/system default?"
   ↓
2. Se confermato:
   → Cancella user layout
   → Ricarica tenant preset (o core se non esiste)
   → Toast: "Layout reset to [Nome Preset]"
```

**Quando utente seleziona preset diverso:**
```
1. Se ci sono modifiche non salvate:
   → Mostra conferma: "You have unsaved changes. Continue?"

2. Se confermato o nessuna modifica:
   → Carica preset selezionato
   → Se è core/tenant preset: mostra come "using [Nome]"
   → Se è user layout: mostra come "My Custom Layout"
```

### Routes Structure

```
/dam/library          → Overview Mode (default)
/dam/upload           → Upload Mode
/dam/culling          → Culling Mode
/dam/dashboard        → Dashboard Mode
/dam/approvals        → Approval Mode
/dam/files            → File Manager Mode
/dam/embed            → Embedded Mode (for iframe usage)

/dam/settings/layouts → Layout customization page
```

---

## 🔄 Layout Save/Load Flow

### Save Flow (User Layout)
```
1. User drags/resizes panels
   ↓
2. rc-dock onLayoutChange fires
   ↓
3. Serialize layout (remove React components, keep IDs)
   ↓
4. Debounce 2 seconds (evita troppe richieste)
   ↓
5. POST /api/dam/layouts/:contextKey
   Body: { layout: {...}, basedOnPresetId: 'uuid', basedOnPresetType: 'tenant' }
   ↓
6. Backend saves to dam_user_layouts
   ↓
7. Success toast: "Personal layout saved for Upload Mode"
```

### Load Flow (3-Tier Fallback)
```
1. User navigates to /dam/culling
   ↓
2. GET /api/dam/layouts/culling
   ↓
3. Backend logic (getLayoutForUser):

   TIER 3 CHECK:
   ├─ Query dam_user_layouts WHERE user_id = $1 AND context_key = 'culling'
   ├─ If found:
   │  └─ Return { layout: {...}, source: 'user', isCustomized: true }
   └─ Else: ↓

   TIER 2 CHECK:
   ├─ Query dam_tenant_presets WHERE tenant_id = $1 AND context_key = 'culling' AND is_default_for_tenant = true
   ├─ If found:
   │  └─ Return { layout: {...}, source: 'tenant', isCustomized: false }
   └─ Else: ↓

   TIER 1 FALLBACK:
   └─ Query dam_core_presets WHERE context_key = 'culling' AND is_active = true
      └─ Return { layout: {...}, source: 'core', isCustomized: false }

   ↓
4. Frontend receives layout + source info
   ↓
5. Deserialize & hydrate components from PANEL_REGISTRY
   ↓
6. Pass layout to DamDockLayout component
   ↓
7. rc-dock renders layout
   ↓
8. Update UI indicators:
   - Se source='user': "Preset: My Custom Layout"
   - Se source='tenant': "Preset: Marketing Team (Team Default)"
   - Se source='core': "Preset: Default Upload (System)"
```

### Admin Save Flow (Tenant Preset)
```
1. TENANT_ADMIN customizes layout
   ↓
2. Clicks "Save as Tenant Preset"
   ↓
3. Modal: "Preset Name: [Marketing Team Upload]"
            "Set as default for organization? [✓]"
   ↓
4. POST /api/dam/layouts/tenant-presets/upload
   Body: {
     presetName: 'Marketing Team Upload',
     layout: {...},
     basedOnCorePresetId: 'uuid',
     isDefaultForTenant: true
   }
   ↓
5. Backend:
   - Validates user is TENANT_ADMIN
   - Saves to dam_tenant_presets
   - If isDefaultForTenant=true:
     → Sets previous default to false (UNIQUE constraint)
   ↓
6. Success toast: "Tenant preset created and set as default"
   ↓
7. All team members now inherit this layout (unless they have user layout)
```

---

## 🌱 Core Presets Seed Data

### Upload Context Presets

```sql
-- Default Upload Layout
INSERT INTO dam_core_presets (context_key, preset_name, preset_key, layout_data, description, version)
VALUES (
  'upload',
  'Default Upload',
  'upload_default',
  '{
    "dockbox": {
      "mode": "horizontal",
      "children": [
        {
          "mode": "vertical",
          "size": 600,
          "tabs": [{"id": "upload-dropzone", "title": "Drop Zone"}]
        },
        {
          "mode": "vertical",
          "tabs": [
            {"id": "upload-queue", "title": "Queue"},
            {"id": "batch-metadata", "title": "Batch Edit"}
          ]
        }
      ]
    }
  }'::jsonb,
  'Standard upload layout with large drop zone and upload queue',
  '1.0.0'
);

-- Compact Upload Layout
INSERT INTO dam_core_presets (context_key, preset_name, preset_key, layout_data, description, version)
VALUES (
  'upload',
  'Compact Upload',
  'upload_compact',
  '{
    "dockbox": {
      "mode": "vertical",
      "children": [
        {"tabs": [{"id": "upload-dropzone", "title": "Drop Zone"}]},
        {"tabs": [{"id": "upload-queue", "title": "Queue"}]}
      ]
    }
  }'::jsonb,
  'Minimal upload layout for small screens',
  '1.0.0'
);
```

### Culling Context Presets

```sql
-- Full Screen Culling
INSERT INTO dam_core_presets (context_key, preset_name, preset_key, layout_data, description, version)
VALUES (
  'culling',
  'Full Screen Culling',
  'culling_fullscreen',
  '{
    "dockbox": {
      "mode": "vertical",
      "children": [
        {"tabs": [{"id": "fullscreen-preview", "title": "Preview"}], "size": -1},
        {"tabs": [{"id": "quick-rating", "title": "Rating"}], "size": 80}
      ]
    }
  }'::jsonb,
  'Immersive full-screen photo culling like Lightroom',
  '1.0.0'
);

-- Compare Mode Culling
INSERT INTO dam_core_presets (context_key, preset_name, preset_key, layout_data, description, version)
VALUES (
  'culling',
  'Compare Mode',
  'culling_compare',
  '{
    "dockbox": {
      "mode": "horizontal",
      "children": [
        {"tabs": [{"id": "preview-left", "title": "Image A"}]},
        {"tabs": [{"id": "preview-right", "title": "Image B"}]}
      ]
    }
  }'::jsonb,
  'Side-by-side comparison for selecting best shots',
  '1.0.0'
);
```

### Overview Context Presets

```sql
-- Complete Library Browser
INSERT INTO dam_core_presets (context_key, preset_name, preset_key, layout_data, description, version)
VALUES (
  'overview',
  'Complete Library',
  'overview_complete',
  '{
    "dockbox": {
      "mode": "horizontal",
      "children": [
        {
          "mode": "vertical",
          "size": 280,
          "tabs": [
            {"id": "folder-tree", "title": "Folders"},
            {"id": "filters", "title": "Filters"}
          ]
        },
        {
          "tabs": [{"id": "asset-grid", "title": "Assets"}],
          "size": -1
        },
        {
          "mode": "vertical",
          "size": 320,
          "tabs": [
            {"id": "metadata", "title": "Details"},
            {"id": "tags", "title": "Tags"},
            {"id": "quick-actions", "title": "Actions"}
          ]
        }
      ]
    }
  }'::jsonb,
  'Full-featured library browser with all panels',
  '1.0.0'
);

-- Minimal Grid View
INSERT INTO dam_core_presets (context_key, preset_name, preset_key, layout_data, description, version)
VALUES (
  'overview',
  'Minimal Grid',
  'overview_minimal',
  '{
    "dockbox": {
      "mode": "horizontal",
      "children": [
        {"tabs": [{"id": "folder-tree", "title": "Folders"}], "size": 240},
        {"tabs": [{"id": "asset-grid", "title": "Assets"}], "size": -1}
      ]
    }
  }'::jsonb,
  'Clean grid view with just folders and assets',
  '1.0.0'
);
```

### Dashboard Context Presets

```sql
-- Executive Dashboard
INSERT INTO dam_core_presets (context_key, preset_name, preset_key, layout_data, description, version)
VALUES (
  'dashboard',
  'Executive Dashboard',
  'dashboard_executive',
  '{
    "dockbox": {
      "mode": "vertical",
      "children": [
        {
          "mode": "horizontal",
          "size": 300,
          "tabs": [
            {"id": "storage-stats", "title": "Storage"},
            {"id": "activity", "title": "Activity"},
            {"id": "approvals", "title": "Pending"}
          ]
        },
        {"tabs": [{"id": "top-assets", "title": "Top Assets"}], "size": 400},
        {"tabs": [{"id": "team-feed", "title": "Team Activity"}], "size": -1}
      ]
    }
  }'::jsonb,
  'High-level overview for managers and executives',
  '1.0.0'
);
```

### Seed Data Migration

```sql
-- Complete migration file: 026_dam_layout_contexts.sql

-- Step 1: Insert Contexts
INSERT INTO dam_layout_contexts (key, name, description, icon, is_system)
VALUES
  ('overview', 'Library Overview', 'Browse and organize your complete asset library', 'layout-grid', true),
  ('upload', 'Upload Mode', 'Import and process new assets with batch editing', 'upload', true),
  ('culling', 'Culling Mode', 'Quickly review and rate photos like Lightroom', 'image', true),
  ('dashboard', 'Dashboard', 'Analytics, stats, and team activity overview', 'bar-chart', true),
  ('approvals', 'Approval Mode', 'Review and approve assets with annotations', 'check-circle', true),
  ('files', 'File Manager', 'Browse assets in traditional file explorer style', 'folder', true),
  ('embed', 'Embedded Picker', 'Lightweight asset picker for external integrations', 'minimize-2', true);

-- Step 2: Insert Core Presets (examples above)
-- ... (tutti i core presets per ogni context)

-- Step 3: Set Default Permissions
INSERT INTO dam_context_permissions (context_key, role, can_access, can_customize)
VALUES
  -- Everyone can access overview
  ('overview', 'VIEWER', true, false),
  ('overview', 'EDITOR', true, true),
  ('overview', 'ADMIN', true, true),

  -- Upload restricted to editors+
  ('upload', 'VIEWER', false, false),
  ('upload', 'EDITOR', true, true),
  ('upload', 'ADMIN', true, true),

  -- Dashboard restricted to admins
  ('dashboard', 'VIEWER', false, false),
  ('dashboard', 'EDITOR', false, false),
  ('dashboard', 'ADMIN', true, true);
```

---

## 🛠️ Implementation Plan

### Phase 1: Database & Backend (Week 1)
**Obiettivo:** Setup completo 3-tier system nel database

- [ ] **1.1** Create migration `026_dam_layout_contexts.sql`:
  - [ ] Table `dam_layout_contexts`
  - [ ] Table `dam_core_presets` (TIER 1)
  - [ ] Table `dam_tenant_presets` (TIER 2)
  - [ ] Table `dam_user_layouts` (TIER 3)
  - [ ] Table `dam_context_permissions`
  - [ ] Indexes per performance

- [ ] **1.2** Seed core presets:
  - [ ] Upload: default + compact
  - [ ] Culling: fullscreen + compare
  - [ ] Overview: complete + minimal
  - [ ] Dashboard: executive
  - [ ] Altri contexts base

- [ ] **1.3** Seed contexts + permissions
  - [ ] 7 context definitions
  - [ ] Role-based access control

### Phase 2: Backend API (Week 1-2)
**Obiettivo:** Implement 3-tier fallback logic

- [ ] **2.1** Core Presets API (read-only):
  - [ ] `GET /api/dam/layouts/core-presets/:contextKey`
  - [ ] `GET /api/dam/layouts/core-presets/:contextKey/:presetKey`

- [ ] **2.2** Tenant Presets API (admin-only write):
  - [ ] `GET /api/dam/layouts/tenant-presets/:contextKey`
  - [ ] `POST /api/dam/layouts/tenant-presets/:contextKey`
  - [ ] `PUT /api/dam/layouts/tenant-presets/:presetId`
  - [ ] `DELETE /api/dam/layouts/tenant-presets/:presetId`
  - [ ] Validation: only TENANT_ADMIN can write

- [ ] **2.3** User Layouts API (all users):
  - [ ] `GET /api/dam/layouts/:contextKey` (with 3-tier fallback)
  - [ ] `POST /api/dam/layouts/:contextKey` (save user layout)
  - [ ] `DELETE /api/dam/layouts/:contextKey` (reset to tenant/core)
  - [ ] `GET /api/dam/layouts/:contextKey/available-presets`

- [ ] **2.4** Implement `getLayoutForUser()` fallback logic:
  ```typescript
  User Layout → Tenant Preset → Core Preset
  ```

### Phase 3: Frontend Infrastructure (Week 2)
**Obiettivo:** Context switching + preset selector UI

- [ ] **3.1** Context System:
  - [ ] Create `LayoutContextProvider` React context
  - [ ] Implement `useLayoutContext` hook
  - [ ] Build `ContextSwitcher` component
  - [ ] Update routing for `/dam/:context`

- [ ] **3.2** Preset Selector (3-Tier):
  - [ ] Build `PresetSelector` component
  - [ ] Visual sections: My Layout | Team Presets | System Presets
  - [ ] Dropdown with grouped presets
  - [ ] Show current source (user/tenant/core)
  - [ ] "Create Tenant Preset" button (admin only)

- [ ] **3.3** Layout Actions:
  - [ ] [Save] button → Save user layout
  - [ ] [Reset] button → Delete user layout
  - [ ] Unsaved changes indicator (asterisk *)
  - [ ] Confirmation modals

### Phase 4: Context Presets & Widgets (Week 3)
**Obiettivo:** Build specialized layouts per context

- [ ] **4.1** Upload Mode:
  - [ ] `UploadDropZone` widget
  - [ ] `UploadQueueWidget` widget
  - [ ] `BatchMetadataEditor` widget
  - [ ] `RecentUploadsWidget` widget

- [ ] **4.2** Culling Mode:
  - [ ] `FullScreenPreview` widget
  - [ ] `QuickRatingBar` widget
  - [ ] Implement keyboard hotkeys (1-5 stars, ← → navigation)
  - [ ] Compare mode (side-by-side)

- [ ] **4.3** Dashboard Mode:
  - [ ] `StorageStatsWidget`
  - [ ] `ActivityTimelineWidget`
  - [ ] `PendingApprovalsWidget`
  - [ ] `TopAssetsWidget`
  - [ ] `TeamActivityFeedWidget`

- [ ] **4.4** Define `CONTEXT_PRESETS` in code:
  - [ ] Map context_key → default layout structure
  - [ ] Fallback for when DB not available

### Phase 5: Persistence & Sync (Week 4)
**Obiettivo:** Auto-save + conflict resolution

- [ ] **5.1** User Layout Auto-Save:
  - [ ] Debounced save (2 seconds after layout change)
  - [ ] Loading state while saving
  - [ ] Success/error toast notifications
  - [ ] Track `basedOnPresetId` for traceability

- [ ] **5.2** Tenant Preset Creation (Admin):
  - [ ] "Save as Tenant Preset" modal
  - [ ] Input: preset name
  - [ ] Checkbox: "Set as default for organization"
  - [ ] Preview: show which users will be affected

- [ ] **5.3** Conflict Resolution:
  - [ ] Handle race conditions (optimistic updates)
  - [ ] Version tracking per layout
  - [ ] Warn if tenant default changes while user is editing

### Phase 6: Testing & Polish (Week 5)
**Obiettivo:** Production-ready

- [ ] **6.1** Unit Tests:
  - [ ] Test `getLayoutForUser()` fallback logic
  - [ ] Test serialization/deserialization
  - [ ] Test permission checks

- [ ] **6.2** E2E Tests:
  - [ ] Test context switching
  - [ ] Test save → reset → load flow
  - [ ] Test admin creating tenant preset
  - [ ] Test multi-user scenarios

- [ ] **6.3** Performance:
  - [ ] Benchmark layout load time (target < 200ms)
  - [ ] Optimize JSONB queries
  - [ ] Add Redis cache per layout endpoint

- [ ] **6.4** Documentation:
  - [ ] Admin guide: "How to create tenant presets"
  - [ ] User guide: "Customizing your workspace"
  - [ ] Developer guide: "Adding new contexts"

### Phase 7: Advanced Features (Future)
**Obiettivo:** Nice-to-have features

- [ ] Layout preview thumbnails
- [ ] Export/Import layouts (JSON download)
- [ ] Layout sharing between users
- [ ] A/B testing different layouts
- [ ] Analytics: which layouts are most used
- [ ] Layout templates marketplace

---

## 📊 Context Priority

**Must Have (MVP):**
1. ✅ Overview Mode (già implementato)
2. 🔼 Upload Mode (alto valore)
3. 📸 Culling Mode (differenziatore chiave)

**Should Have (v1.1):**
4. 📈 Dashboard Mode
5. ✅ Approval Mode

**Nice to Have (v1.2+):**
6. 📁 File Manager Mode
7. 🔌 Embedded Mode

---

## 🎯 Success Metrics

### Technical
- Layout save latency < 500ms
- Layout load latency < 200ms
- Context switch < 1s
- Zero crashes on layout deserialization

### User Experience
- Users customize >= 1 context in first week
- Context switches per session: avg 3+
- Layout satisfaction score: >= 4/5

---

## 📝 Notes

### Why Server-Side Instead of LocalStorage?
1. **Multi-device sync** - User accede da desktop/laptop/tablet
2. **Team consistency** - Admin può impostare default per team
3. **Backup & recovery** - Nessuna perdita dati se browser cleared
4. **Audit trail** - Tracking di chi cambia layout quando

### Why Context-Based Instead of Page-Based?
1. **Semantic clarity** - "Culling Mode" è più chiaro di "Layout 3"
2. **Smart defaults** - Ogni context ha default ottimizzato
3. **Permissions** - Alcuni ruoli vedono solo certi contexts
4. **Analytics** - Tracking quale context viene più usato

---

## 🎁 Vantaggi del Sistema a 3-Tier

### TIER 1: Core Presets (Sistema)
**Vantaggi:**
- ✅ Sempre disponibili (fallback garantito)
- ✅ Versionati e testati
- ✅ Aggiornabili con deploy (nuove feature)
- ✅ Immutabili per utenti (no corruzioni)
- ✅ Multi-tenant safe (stesso preset per tutti)

**Use Cases:**
- Nuove installazioni hanno subito layout funzionanti
- Updates del prodotto possono migliorare layout di default
- Demo e marketing usano sempre layout perfetti

### TIER 2: Tenant Presets (Organizzazione)
**Vantaggi:**
- ✅ Personalizzazione per industry/team
- ✅ Branding e workflow specifici
- ✅ Admin può standardizzare per team
- ✅ Nuovi membri ereditano configurazione giusta
- ✅ Training più facile (tutti vedono stesso layout)

**Use Cases:**
- **Marketing agency:** Layout ottimizzato per campagne e creativi
- **Photo studio:** Layout culling-focused per fotografi
- **E-commerce:** Layout con focus su product tagging
- **Publishing house:** Layout con metadati editoriali

### TIER 3: User Layouts (Personale)
**Vantaggi:**
- ✅ Massima flessibilità individuale
- ✅ Power users possono ottimizzare workflow
- ✅ Sperimentazione senza impatto su altri
- ✅ Reset sempre possibile a tenant/core
- ✅ Tracking di cosa customizzano (analytics)

**Use Cases:**
- Designer preferisce più preview space
- Editor preferisce più metadata space
- Manager preferisce dashboard compatta
- Photographer preferisce culling fullscreen

---

## 🔐 Sicurezza e Governance

### Permission Matrix

| Action | Viewer | Editor | Admin | Platform Admin |
|--------|--------|--------|-------|----------------|
| View core presets | ✅ | ✅ | ✅ | ✅ |
| Use core presets | ✅ | ✅ | ✅ | ✅ |
| View tenant presets | ✅ | ✅ | ✅ | ✅ |
| Use tenant presets | ✅ | ✅ | ✅ | ✅ |
| Create tenant presets | ❌ | ❌ | ✅ | ✅ |
| Edit tenant presets | ❌ | ❌ | ✅ | ✅ |
| Delete tenant presets | ❌ | ❌ | ✅ | ✅ |
| Save user layouts | ✅* | ✅ | ✅ | ✅ |
| Modify own user layout | ✅* | ✅ | ✅ | ✅ |
| View other user layouts | ❌ | ❌ | ❌** | ✅ |

\* Se `can_customize = true` in `dam_context_permissions`
\*\* Tranne per analytics aggregati

---

## 📈 Analytics Opportunities

Con il sistema a 3-tier possiamo tracciare:

1. **Adoption Rate:**
   - Quanti utenti customizzano vs usano default?
   - Quale tier viene più usato?

2. **Preset Effectiveness:**
   - Quale core preset viene più customizzato? (segno che non è ottimale)
   - Tenant presets riducono user customizations?

3. **Feature Usage:**
   - Quali widgets vengono nascosti più spesso? (non servono)
   - Quali widgets vengono sempre mostrati? (essenziali)

4. **Team Patterns:**
   - Tenant con alto customization rate → training problem?
   - Tenant che crea molti tenant presets → power users

5. **Context Usage:**
   - Quali context vengono più usati?
   - Quale context ha più customizations?

---

## 🚀 Future Enhancements

### Version 2.0: Smart Recommendations
```
"Hey, we noticed you always hide the Tags panel in Upload mode.
 Would you like to switch to the 'Compact Upload' preset?"
```

### Version 2.1: AI-Optimized Layouts
```
Machine learning analizza usage patterns e suggerisce:
- Layout ottimali per role
- Widget placement based on workflow
- Auto-resize basato su screen resolution
```

### Version 2.2: Collaborative Layouts
```
Team members possono:
- Share user layouts con colleghi
- Vote on tenant presets
- Suggest improvements to core presets
```

### Version 2.3: Industry Templates
```
Marketplace di layout templates:
- "Photography Studio Pack"
- "E-commerce Catalog Management"
- "Marketing Agency Creative Suite"
```

---

**Prossimo Step:** Implementare Phase 1 (Database & API)

