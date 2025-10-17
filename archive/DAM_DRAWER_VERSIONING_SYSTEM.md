# DAM Drawer - Sistema Gestione Immagini Cross-App con Versioning

**Data**: 2025-10-15
**Status**: Architettura Completa
**Version**: 1.0

---

## 🎯 Obiettivo

Creare un **cassetto DAM intelligente** che permetta:
- **Drag & drop** di asset tra applicazioni diverse (Email, Docs, CMS, PM, ecc.)
- **Tracking automatico** degli asset utilizzati (dove, quando, da chi)
- **Gestione versioni**: ogni asset può avere versioni multiple
- **Riferimenti intelligenti**:
  - **Live reference**: si aggiorna automaticamente quando l'asset cambia
  - **Snapshot reference**: fissa l'immagine a una versione specifica (es. email già inviate)
- **Sincronizzazione**: quando un asset viene aggiornato, tutti i riferimenti "live" si aggiornano
- **Governance**: tracciamento completo dell'uso degli asset

---

## 🏗️ Architettura Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│  User Interface Layer                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Email Editor │  │ Doc Editor   │  │ CMS Page     │  ...    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                  │
│         └──────────────────┴──────────────────┘                 │
│                            │                                     │
│                    ┌───────▼────────┐                           │
│                    │  DAM Drawer    │                           │
│                    │  (Sidebar UI)  │                           │
│                    └───────┬────────┘                           │
└────────────────────────────┼──────────────────────────────────┘
                             │
┌────────────────────────────▼──────────────────────────────────┐
│  Business Logic Layer                                          │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Asset Reference Manager                                  │ │
│  │  - Track usage across apps                                │ │
│  │  - Version management                                     │ │
│  │  - Live vs Snapshot logic                                 │ │
│  └──────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Synchronization Engine                                   │ │
│  │  - Detect asset updates                                   │ │
│  │  - Update all live references                             │ │
│  │  - Notify affected apps                                   │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────┬──────────────────────────────────┘
                             │
┌────────────────────────────▼──────────────────────────────────┐
│  Data Layer                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Assets      │  │ Versions    │  │ Usage       │          │
│  │ Table       │  │ Table       │  │ Tracking    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  CDN / Storage (S3, MinIO)                               │ │
│  │  /assets/uuid/v1/image.jpg                               │ │
│  │  /assets/uuid/v2/image.jpg                               │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

---

## 📊 Database Schema

### 1. assets (tabella principale)

```sql
CREATE TABLE assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),

  -- Asset info
  original_filename VARCHAR(500) NOT NULL,
  file_type VARCHAR(100) NOT NULL, -- 'image/jpeg', 'image/png', etc
  file_size_bytes BIGINT NOT NULL,
  mime_type VARCHAR(100) NOT NULL,

  -- Metadata
  title VARCHAR(500),
  description TEXT,
  alt_text VARCHAR(500), -- Per accessibilità
  tags TEXT[], -- Array di tags

  -- Organization
  folder_id UUID REFERENCES asset_folders(id),

  -- Current version
  current_version_id UUID REFERENCES asset_versions(id),
  version_count INTEGER DEFAULT 1,

  -- Ownership
  created_by UUID NOT NULL REFERENCES users(id),
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Soft delete
  deleted_at TIMESTAMPTZ,

  CONSTRAINT assets_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX idx_assets_tenant_id ON assets(tenant_id);
CREATE INDEX idx_assets_folder_id ON assets(folder_id);
CREATE INDEX idx_assets_tags ON assets USING GIN(tags);
CREATE INDEX idx_assets_created_at ON assets(created_at DESC);
```

### 2. asset_versions (versioni multiple per ogni asset)

```sql
CREATE TABLE asset_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,

  -- Version info
  version_number INTEGER NOT NULL, -- 1, 2, 3, ...
  version_label VARCHAR(100), -- "v1.0", "Final", "Draft", etc

  -- File storage
  storage_path VARCHAR(1000) NOT NULL, -- Path nel CDN/S3
  cdn_url VARCHAR(1000) NOT NULL, -- URL pubblico
  thumbnail_url VARCHAR(1000), -- Preview URL

  -- File properties
  width INTEGER, -- Larghezza immagine
  height INTEGER, -- Altezza immagine
  file_size_bytes BIGINT NOT NULL,

  -- Metadata
  changelog TEXT, -- Cosa è cambiato in questa versione
  is_current BOOLEAN DEFAULT false, -- Se è la versione corrente

  -- Tracking
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT asset_versions_unique UNIQUE(asset_id, version_number)
);

CREATE INDEX idx_asset_versions_asset_id ON asset_versions(asset_id);
CREATE INDEX idx_asset_versions_is_current ON asset_versions(asset_id, is_current) WHERE is_current = true;
```

### 3. asset_usages (tracking dove viene usato ogni asset)

```sql
CREATE TABLE asset_usages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),

  -- Asset reference
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  version_id UUID REFERENCES asset_versions(id), -- NULL se live reference

  -- Reference type
  reference_type VARCHAR(50) NOT NULL, -- 'live' | 'snapshot'

  -- Usage location
  app_id VARCHAR(100) NOT NULL, -- 'email-client', 'cms', 'pm', 'docs', etc
  entity_type VARCHAR(100) NOT NULL, -- 'email', 'document', 'page', 'task', etc
  entity_id UUID NOT NULL, -- ID dell'entità (email_id, document_id, etc)
  field_name VARCHAR(200), -- Campo dove è usato (es. 'body', 'header_image')

  -- Context
  context JSONB, -- Metadata aggiuntivo specifico dell'app

  -- Tracking
  inserted_by UUID NOT NULL REFERENCES users(id),
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_accessed_at TIMESTAMPTZ, -- Ultima volta che è stato visto/usato
  access_count INTEGER DEFAULT 0,

  -- Stato
  is_active BOOLEAN DEFAULT true, -- False se l'entità è stata eliminata
  removed_at TIMESTAMPTZ,

  CONSTRAINT asset_usages_unique UNIQUE(asset_id, app_id, entity_type, entity_id, field_name)
);

CREATE INDEX idx_asset_usages_asset_id ON asset_usages(asset_id);
CREATE INDEX idx_asset_usages_entity ON asset_usages(app_id, entity_type, entity_id);
CREATE INDEX idx_asset_usages_tenant_id ON asset_usages(tenant_id);
CREATE INDEX idx_asset_usages_is_active ON asset_usages(is_active) WHERE is_active = true;
```

### 4. asset_update_logs (log degli aggiornamenti)

```sql
CREATE TABLE asset_update_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  version_id UUID NOT NULL REFERENCES asset_versions(id),

  -- Update info
  update_type VARCHAR(50) NOT NULL, -- 'version_upload', 'live_sync', 'manual_update'
  affected_usages INTEGER NOT NULL DEFAULT 0, -- Quante usage sono state aggiornate

  -- Details
  details JSONB, -- Info dettagliate sull'update

  -- Tracking
  triggered_by UUID REFERENCES users(id),
  triggered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_asset_update_logs_asset_id ON asset_update_logs(asset_id);
CREATE INDEX idx_asset_update_logs_triggered_at ON asset_update_logs(triggered_at DESC);
```

---

## 🎨 DAM Drawer UI

### Layout del Cassetto

```
┌────────────────────────────────────────────┐
│  🗂️  DAM - Media Library                   │ ← Header
├────────────────────────────────────────────┤
│  🔍 [Search assets...]            [↻][⚙️]  │ ← Search bar
├────────────────────────────────────────────┤
│  📁 Recent (10)                    [View→] │ ← Recent section
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐                  │
│  │ 1 │ │ 2 │ │ 3 │ │ 4 │  ← Draggable    │
│  └───┘ └───┘ └───┘ └───┘                  │
│  v2.1  v1.0  v3.0  v1.5  ← Version badge   │
├────────────────────────────────────────────┤
│  📂 Folders                                 │ ← Folders tree
│  ├─ 📷 Product Photos (45)                 │
│  ├─ 🎨 Marketing (23)                      │
│  ├─ 📄 Documents (12)                      │
│  └─ 🖼️  Templates (8)                      │
├────────────────────────────────────────────┤
│  🖼️  All Assets                            │ ← Asset grid
│  ┌────┐ ┌────┐ ┌────┐                     │
│  │ v2 │ │ v1 │ │ v3 │  ← Version badge    │
│  │ 📎 │ │ 📎 │ │ 📎 │  ← Usage indicator  │
│  └────┘ └────┘ └────┘                     │
│  photo  logo   banner                      │
│  ↑ Drag to use                             │
│                                             │
│  [Infinite scroll...]                      │
├────────────────────────────────────────────┤
│  [📤 Upload]  [🔗 Insert Link]            │ ← Actions
└────────────────────────────────────────────┘
```

### Thumbnail States

**1. Thumbnail Normale**:
```
┌────────────┐
│   [IMG]    │ ← Preview
│            │
│ photo.jpg  │ ← Nome
│ v2 📎 3    │ ← Version + Usage count
└────────────┘
```

**2. Durante Drag**:
```
┌────────────┐
│   [IMG]    │ ← Ghost image (opacity 0.7)
│            │
│ photo.jpg  │
│            │
│ [Live] or  │ ← Mostra opzioni
│ [Snapshot] │
└────────────┘
```

**3. Hover Tooltip**:
```
┌─────────────────────────────┐
│ photo.jpg                   │
│ Version 2 (current)         │
│ 1920x1080 • 450KB          │
│                             │
│ Used in:                    │
│ • Email Campaign #45        │
│ • Homepage Banner           │
│ • Product Page              │
│                             │
│ [View Details →]            │
└─────────────────────────────┘
```

---

## 🔄 Sistema di Riferimenti (Live vs Snapshot)

### Live Reference (Dinamico)

**Quando usare**:
- Homepage / Landing pages
- Template documenti
- Product pages
- Contenuti che devono sempre mostrare la versione più recente

**Comportamento**:
```typescript
{
  type: 'live',
  asset_id: 'uuid-123',
  version_id: null, // NULL = sempre ultima versione
  url: '/api/dam/assets/uuid-123/current', // Proxy dinamico
}
```

**Rendering**:
- L'URL punta a un endpoint proxy: `/api/dam/assets/:id/current`
- Il proxy restituisce sempre la versione corrente
- Quando l'asset viene aggiornato, tutte le pagine vedono la nuova versione **automaticamente**

**Esempio**:
```html
<!-- Live reference -->
<img src="/api/dam/assets/uuid-123/current" alt="Product" />

<!-- Quando l'asset viene aggiornato da v1 → v2,
     questo tag mostra automaticamente v2 senza modifiche -->
```

### Snapshot Reference (Fisso)

**Quando usare**:
- Email già inviate
- PDF generati e salvati
- Report esportati
- Documenti firmati digitalmente
- Qualsiasi contenuto "immutabile" o "storico"

**Comportamento**:
```typescript
{
  type: 'snapshot',
  asset_id: 'uuid-123',
  version_id: 'version-uuid-456', // Versione specifica
  url: 'https://cdn.../assets/uuid-123/v2/image.jpg', // URL diretto
}
```

**Rendering**:
- L'URL punta direttamente al file su CDN
- La versione è **fissa** e non cambierà mai
- Anche se l'asset viene aggiornato, questa istanza mostra sempre v2

**Esempio**:
```html
<!-- Snapshot reference -->
<img src="https://cdn.../assets/uuid-123/v2/image.jpg" alt="Product" />

<!-- Quando l'asset viene aggiornato da v2 → v3,
     questo tag continua a mostrare v2 -->
```

---

## 🎬 Workflow Completo

### Scenario 1: Drag & Drop in Email (Snapshot)

```
1. User apre email composer
2. User clicca icona DAM nella sidebar → si apre drawer
3. User cerca/naviga a "product-photo.jpg" (current: v2)
4. User inizia drag della thumbnail

   → Durante drag, mostra popup:
     ┌────────────────────────────┐
     │ Insert as:                 │
     │ ● Snapshot (recommended)   │ ← Default per email
     │ ○ Live reference           │
     │                            │
     │ Version: v2 (current)      │
     └────────────────────────────┘

5. User fa drop nell'editor email

   → Sistema:
     a) Inserisce <img src="cdn_url_v2" /> nell'editor
     b) Crea record in asset_usages:
        {
          asset_id: 'uuid-123',
          version_id: 'version-uuid-456', // v2
          reference_type: 'snapshot',
          app_id: 'email-client',
          entity_type: 'email',
          entity_id: 'email-uuid-789',
          field_name: 'body',
          inserted_by: 'user-uuid',
          inserted_at: now()
        }
     c) Email mostra immagine v2

6. Una settimana dopo, user carica v3 dell'asset
   → Email già inviata continua a mostrare v2 (snapshot)
```

### Scenario 2: Drag & Drop in Homepage CMS (Live)

```
1. User edita homepage in CMS
2. User apre DAM drawer
3. User trascina "hero-banner.jpg" (current: v1)

   → Durante drag, mostra popup:
     ┌────────────────────────────┐
     │ Insert as:                 │
     │ ○ Snapshot                 │
     │ ● Live reference (rec.)    │ ← Default per CMS
     │                            │
     │ Version: v1 (current)      │
     │ ℹ️  Will auto-update       │
     └────────────────────────────┘

4. User fa drop nel page builder

   → Sistema:
     a) Inserisce <img src="/api/dam/assets/uuid-456/current" />
     b) Crea record in asset_usages:
        {
          asset_id: 'uuid-456',
          version_id: null, // NULL = live
          reference_type: 'live',
          app_id: 'cms',
          entity_type: 'page',
          entity_id: 'page-uuid-999',
          field_name: 'hero_section',
          ...
        }
     c) Homepage mostra banner v1

5. Marketing carica v2 del banner (nuovo design)
   → Sistema:
     a) Salva v2 in asset_versions
     b) Aggiorna asset.current_version_id → v2
     c) Cerca tutti asset_usages dove:
        - asset_id = 'uuid-456'
        - reference_type = 'live'
     d) Crea notifica:
        "Banner updated: Homepage will show v2"
     e) Homepage mostra automaticamente v2 senza modifiche!

6. Marketing team vede impact:
   "Asset uuid-456 updated to v2
    → 3 pages will auto-update:
      • Homepage (live)
      • About Us (live)
      • Contact Page (live)"
```

### Scenario 3: Aggiornamento Manuale da Live → Snapshot

```
1. User vede che homepage usa hero-banner v2 (live)
2. User decide di "congelare" la versione per evitare cambi futuri
3. User apre "Asset Usage Panel" in CMS
   → Vede lista di tutte le immagini nella pagina:
     ┌────────────────────────────────────────┐
     │ Assets in this page:                   │
     │                                        │
     │ hero-banner.jpg                        │
     │ Type: Live reference                   │
     │ Current: v2                            │
     │ [Convert to Snapshot →]                │
     │                                        │
     │ product-photo.jpg                      │
     │ Type: Snapshot                         │
     │ Version: v1 (frozen)                   │
     │ [Update to v2] [Keep v1]              │
     └────────────────────────────────────────┘

4. User clicca "Convert to Snapshot"
   → Sistema:
     a) Aggiorna asset_usages:
        reference_type: 'live' → 'snapshot'
        version_id: null → 'version-uuid-of-v2'
     b) Sostituisce URL in page:
        '/api/dam/assets/uuid/current' → 'cdn_url_v2'
     c) Homepage ora mostra sempre v2, anche se v3 viene caricato
```

---

## 🔔 Sistema di Notifiche

### Notifiche su Aggiornamento Asset

Quando un asset viene aggiornato (v2 → v3), il sistema:

1. **Identifica impatti**:
```sql
SELECT
  u.app_id,
  u.entity_type,
  u.entity_id,
  u.reference_type,
  COUNT(*) as usage_count
FROM asset_usages u
WHERE u.asset_id = 'uuid-123'
  AND u.is_active = true
GROUP BY u.app_id, u.entity_type, u.reference_type;
```

2. **Crea notifica**:
```typescript
{
  type: 'asset_updated',
  asset_id: 'uuid-123',
  old_version: 'v2',
  new_version: 'v3',
  impact: {
    live_references: 15, // Si aggiorneranno automaticamente
    snapshot_references: 8, // Rimarranno su v2
    affected_apps: ['cms', 'email-templates', 'pm']
  },
  actions: [
    {
      label: 'View Impact Report',
      url: '/dam/assets/uuid-123/impact'
    },
    {
      label: 'Revert to v2',
      action: 'revert_version'
    }
  ]
}
```

3. **Mostra in Bacheca**:
```
┌─────────────────────────────────────────┐
│ 📢 Asset Updated                        │
│                                         │
│ hero-banner.jpg → v3                    │
│ by Sarah Marketing                      │
│ 5 minutes ago                           │
│                                         │
│ Impact:                                 │
│ • 15 live references updated            │
│ • 8 snapshots unchanged                 │
│                                         │
│ Affected:                               │
│ • Homepage (auto-updated)               │
│ • Product Page (auto-updated)           │
│ • Email Campaign #45 (unchanged)        │
│                                         │
│ [View Details] [Undo]                   │
└─────────────────────────────────────────┘
```

---

## 🛠️ API Endpoints

### 1. Get Asset (con proxy dinamico)

```typescript
// Live reference proxy
GET /api/dam/assets/:asset_id/current

Response:
- Se live: restituisce sempre la versione corrente
- Redirect 302 al CDN URL della versione corrente
- Header: X-DAM-Version: v2
```

### 2. Insert Asset (registra usage)

```typescript
POST /api/dam/assets/:asset_id/usage

Body: {
  reference_type: 'live' | 'snapshot',
  version_id?: string, // Required se snapshot
  app_id: string,
  entity_type: string,
  entity_id: string,
  field_name?: string,
  context?: object
}

Response: {
  usage_id: string,
  url: string, // URL da usare (proxy o CDN)
  version: {
    number: 2,
    label: 'v2.0',
    cdn_url: string
  }
}
```

### 3. Track Asset Version Upload

```typescript
POST /api/dam/assets/:asset_id/versions

Body: {
  file: File,
  version_label?: string,
  changelog?: string,
  make_current: boolean // Se true, diventa versione corrente
}

Response: {
  version_id: string,
  version_number: 3,
  cdn_url: string,
  affected_usages: {
    live_count: 15,
    snapshot_count: 8
  }
}
```

### 4. Get Asset Usage Report

```typescript
GET /api/dam/assets/:asset_id/usage-report

Response: {
  asset: { id, name, current_version },
  total_usages: 23,
  by_type: {
    live: 15,
    snapshot: 8
  },
  by_app: {
    'cms': 10,
    'email-client': 8,
    'pm': 5
  },
  usage_details: [
    {
      app_id: 'cms',
      entity_type: 'page',
      entity_name: 'Homepage',
      reference_type: 'live',
      inserted_at: '2025-10-15T...',
      url: '/cms/pages/...'
    },
    // ...
  ]
}
```

### 5. Convert Reference Type

```typescript
PATCH /api/dam/usage/:usage_id/convert

Body: {
  new_type: 'live' | 'snapshot',
  target_version_id?: string // Required se snapshot
}

Response: {
  usage_id: string,
  old_type: 'live',
  new_type: 'snapshot',
  new_url: string
}
```

---

## 🎯 React Components

### DAMDrawer (main component)

```typescript
<DAMDrawer
  isOpen={isDrawerOpen}
  onClose={() => setIsDrawerOpen(false)}
  onAssetSelect={(asset, options) => {
    // options: { referenceType: 'live' | 'snapshot' }
  }}
/>
```

### DAMAssetThumbnail (draggable)

```typescript
<DAMAssetThumbnail
  asset={asset}
  onDragStart={(asset) => {
    // Setup drag data
    event.dataTransfer.setData('dam-asset', JSON.stringify({
      asset_id: asset.id,
      current_version: asset.current_version,
      // ...
    }));
  }}
  showUsageCount={true}
  showVersionBadge={true}
/>
```

### DAMDropZone (drop target)

```typescript
<DAMDropZone
  onAssetDrop={async (asset, options) => {
    const { referenceType } = options;

    // 1. Call API to register usage
    const usage = await api.insertAssetUsage({
      asset_id: asset.id,
      reference_type: referenceType,
      version_id: referenceType === 'snapshot' ? asset.current_version.id : null,
      app_id: 'email-client',
      entity_type: 'email',
      entity_id: currentEmailId,
      field_name: 'body'
    });

    // 2. Insert in editor
    const imgTag = `<img src="${usage.url}" alt="${asset.title}" />`;
    insertIntoEditor(imgTag);
  }}
  acceptedTypes={['image/*']}
  defaultReferenceType="snapshot" // Per email
>
  {/* Email editor content */}
</DAMDropZone>
```

---

## 🚀 Implementazione Fasi

### Phase 1: Database & API
- [ ] Create tables (assets, versions, usages, logs)
- [ ] API endpoints per asset management
- [ ] Proxy endpoint `/current` per live references
- [ ] Usage tracking API

### Phase 2: DAM Drawer UI
- [ ] DAMDrawer component
- [ ] Asset grid con thumbnails
- [ ] Search & filter
- [ ] Version badges & usage indicators

### Phase 3: Drag & Drop
- [ ] Draggable thumbnails
- [ ] Reference type selector (popup durante drag)
- [ ] Drop zones universali
- [ ] Asset insertion logic

### Phase 4: Versioning System
- [ ] Upload new version UI
- [ ] Version history viewer
- [ ] Impact report (chi usa cosa)
- [ ] Auto-update live references

### Phase 5: Notifications & Sync
- [ ] Real-time notifications su asset updates
- [ ] Impact alerts in Bacheca
- [ ] Undo/revert mechanism
- [ ] Usage analytics dashboard

---

## ✅ Success Criteria

- ✅ User può trascinare asset dal drawer in email/docs/cms
- ✅ Sistema traccia automaticamente dove viene usato ogni asset
- ✅ Live references si aggiornano automaticamente a nuove versioni
- ✅ Snapshot references rimangono fissi
- ✅ User può vedere "impact report" prima di aggiornare un asset
- ✅ Notifiche real-time quando asset usati vengono aggiornati
- ✅ User può convertire live → snapshot e viceversa
- ✅ Performance: drawer si apre in <200ms
- ✅ Drag & drop funziona in tutte le app (email, CMS, docs, PM)

---

**Created**: 2025-10-15
**Version**: 1.0 - Complete Versioning System
**Next Steps**: Start Phase 1 (Database Schema + API)
