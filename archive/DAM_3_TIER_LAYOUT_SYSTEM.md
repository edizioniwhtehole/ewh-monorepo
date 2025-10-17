# 🎯 DAM 3-Tier Layout System - Implementation Summary

**Data:** 12 Ottobre 2025
**Versione:** 2.0 (Updated with 3-Tier Architecture)
**Status:** Architecture Completed, Ready for Implementation

---

## 📋 Quick Summary

Implementato sistema di layout salvabili a **3 livelli di priorità** per il DAM:

```
┌─────────────────────────────────────────────┐
│  TIER 3: User Layouts (Personal)           │
│  └─ Personalizzazione individuale          │
│     Se non esiste ↓                         │
├─────────────────────────────────────────────┤
│  TIER 2: Tenant Presets (Organization)     │
│  └─ Default per team/organizzazione        │
│     Se non esiste ↓                         │
├─────────────────────────────────────────────┤
│  TIER 1: Core Presets (System)             │
│  └─ Default di sistema (garantito)         │
└─────────────────────────────────────────────┘
```

---

## 🎯 Obiettivo Raggiunto

✅ Sistema che soddisfa tutti i requisiti:
- **Multiple operational modes:** Upload, Culling, Overview, Dashboard, Approvals, File Manager, Embedded
- **3-tier preset system:** Core (DB) → Tenant → User
- **Inheritance logic:** Fallback automatico tra i 3 livelli
- **Server-side persistence:** Niente localStorage (evita crash loop)
- **Permission-based:** Chi può vedere/modificare cosa

---

## 🗄️ Database Schema

### 4 Tabelle Principali

#### 1. `dam_layout_contexts`
Definisce i contesti disponibili (upload, culling, overview, etc.)

#### 2. `dam_core_presets` (TIER 1)
- **Scopo:** Default di sistema, immutabili
- **Gestione:** Solo platform admin
- **Esempi:**
  - Upload: `upload_default`, `upload_compact`
  - Culling: `culling_fullscreen`, `culling_compare`
  - Overview: `overview_complete`, `overview_minimal`

#### 3. `dam_tenant_presets` (TIER 2)
- **Scopo:** Default per organizzazione
- **Gestione:** Tenant admin
- **Features:**
  - `is_default_for_tenant` flag
  - `based_on_core_preset_id` per tracciare origine
  - Nuovi membri ereditano automaticamente

#### 4. `dam_user_layouts` (TIER 3)
- **Scopo:** Personalizzazione individuale
- **Gestione:** Ogni utente
- **Features:**
  - Override completo di tenant/core
  - Reset sempre possibile
  - Track `based_on_preset_id` per analytics

---

## 🔄 Logica di Fallback

```typescript
async function getLayoutForUser(userId, tenantId, contextKey) {
  // 1️⃣ Try user personal layout
  const userLayout = await db.query(
    'SELECT layout_data FROM dam_user_layouts WHERE user_id = $1 AND context_key = $2',
    [userId, contextKey]
  );
  if (userLayout) return { layout: userLayout, source: 'user' };

  // 2️⃣ Try tenant default preset
  const tenantPreset = await db.query(
    'SELECT layout_data FROM dam_tenant_presets WHERE tenant_id = $1 AND context_key = $2 AND is_default_for_tenant = true',
    [tenantId, contextKey]
  );
  if (tenantPreset) return { layout: tenantPreset, source: 'tenant' };

  // 3️⃣ Fallback to core preset (always exists)
  const corePreset = await db.query(
    'SELECT layout_data FROM dam_core_presets WHERE context_key = $1 AND is_active = true',
    [contextKey]
  );
  return { layout: corePreset, source: 'core' };
}
```

---

## 🎨 UI Design

### Header con Context Switcher + Preset Selector

```
┌──────────────────────────────────────────────────────────────┐
│ [📊 Library ▼]  [Preset: My Custom Layout ▼]  [Save] [Reset]│
└──────────────────────────────────────────────────────────────┘
```

### Preset Selector Dropdown (3-Tier)

```
┌──────────────────────────────────────────────┐
│ 👤 MY LAYOUT                                 │
│ ──────────────────────────────────────────── │
│ ✓ My Custom Layout              (current)    │
│                                              │
│ 🏢 TEAM PRESETS (Your Organization)          │
│ ──────────────────────────────────────────── │
│   Marketing Team                  (default)  │
│   Photo Team                                 │
│                                              │
│ 🔧 SYSTEM PRESETS (Built-in)                 │
│ ──────────────────────────────────────────── │
│   Default Upload                             │
│   Compact Upload                             │
│                                              │
│ ╔════════════════════════════════════════╗  │
│ ║ [+ Create Tenant Preset] (Admin only)  ║  │
│ ╚════════════════════════════════════════╝  │
└──────────────────────────────────────────────┘
```

---

## 🛠️ API Endpoints

### Core Presets (Read-Only)
- `GET /api/dam/layouts/core-presets/:contextKey`
- `GET /api/dam/layouts/core-presets/:contextKey/:presetKey`

### Tenant Presets (Admin-Only Write)
- `GET /api/dam/layouts/tenant-presets/:contextKey`
- `POST /api/dam/layouts/tenant-presets/:contextKey` (create)
- `PUT /api/dam/layouts/tenant-presets/:presetId` (update)
- `DELETE /api/dam/layouts/tenant-presets/:presetId`

### User Layouts (All Users)
- `GET /api/dam/layouts/:contextKey` (with 3-tier fallback)
- `POST /api/dam/layouts/:contextKey` (save personal)
- `DELETE /api/dam/layouts/:contextKey` (reset to tenant/core)
- `GET /api/dam/layouts/:contextKey/available-presets`

---

## 📊 Layout Contexts

### 7 Contesti Operativi

| Context | Icon | Use Case | Key Widgets |
|---------|------|----------|-------------|
| **Upload** | 🔼 | Importazione massiva | DropZone, Queue, BatchEdit |
| **Culling** | 📸 | Photo selection (Lightroom-style) | FullScreenPreview, QuickRating |
| **Overview** | 📊 | Libreria completa | Grid, Folders, Metadata |
| **Dashboard** | 📈 | Analytics & stats | Storage, Activity, Approvals |
| **Approvals** | ✅ | Review workflow | Queue, Preview, Comments |
| **Files** | 📁 | File manager style | Tree, List, ContextMenu |
| **Embed** | 🔌 | Asset picker (iframe) | CompactGrid, Preview, Select |

---

## 🎁 Vantaggi del Sistema

### TIER 1: Core Presets
- ✅ Sempre disponibili (zero config)
- ✅ Versionati e testati
- ✅ Aggiornabili con deploy
- ✅ Multi-tenant safe

### TIER 2: Tenant Presets
- ✅ Personalizzazione per industry
- ✅ Standardizzazione team
- ✅ Onboarding più facile
- ✅ Branding specifico

### TIER 3: User Layouts
- ✅ Flessibilità massima
- ✅ Power users ottimizzano
- ✅ Sperimentazione safe
- ✅ Reset sempre possibile

---

## 🔐 Permission Matrix

| Action | Viewer | Editor | Admin |
|--------|--------|--------|-------|
| Use core/tenant presets | ✅ | ✅ | ✅ |
| Save personal layouts | ✅* | ✅ | ✅ |
| Create tenant presets | ❌ | ❌ | ✅ |
| Edit tenant presets | ❌ | ❌ | ✅ |

\* Se `can_customize = true` nel context

---

## 📈 Analytics Tracciabili

1. **Adoption Rate:** Quanti customizzano vs usano default
2. **Preset Effectiveness:** Quali presets funzionano meglio
3. **Widget Usage:** Quali vengono nascosti/mostrati
4. **Team Patterns:** Training effectiveness
5. **Context Popularity:** Quali vengono più usati

---

## 🚀 Implementation Plan

### Phase 1: Database & Backend (Week 1)
- [ ] Migration `026_dam_layout_contexts.sql`
- [ ] Seed 7 contexts + core presets
- [ ] API endpoints (core, tenant, user)

### Phase 2: Frontend Infrastructure (Week 2)
- [ ] Context switcher component
- [ ] Preset selector (3-tier dropdown)
- [ ] Save/Reset buttons

### Phase 3: Context Presets & Widgets (Week 3)
- [ ] Upload mode widgets
- [ ] Culling mode + hotkeys
- [ ] Dashboard widgets

### Phase 4: Persistence & Sync (Week 4)
- [ ] Auto-save debounced
- [ ] Tenant preset creation (admin)
- [ ] Conflict resolution

### Phase 5: Testing & Polish (Week 5)
- [ ] Unit tests (fallback logic)
- [ ] E2E tests (context switching)
- [ ] Performance optimization

---

## 📝 Example Use Cases

### Scenario 1: New User
```
1. User logs in for first time
2. No user layout exists
3. No tenant preset exists
4. Loads core preset 'overview_complete'
5. User sees full-featured library browser
```

### Scenario 2: Marketing Agency
```
1. Tenant admin creates 'Marketing Team Upload'
2. Sets as default for organization
3. All team members now see optimized upload layout
4. New hires automatically inherit it
```

### Scenario 3: Power User
```
1. User customizes overview layout
2. Hides widgets they don't need
3. Saves personal layout
4. Next login: their custom layout loads
5. Can reset anytime to team default
```

---

## 📄 Related Documentation

- **Full Architecture:** [DAM_LAYOUT_CONTEXTS_ARCHITECTURE.md](./DAM_LAYOUT_CONTEXTS_ARCHITECTURE.md)
- **Crash Fix:** [DAM_FIX_SUMMARY.md](./DAM_FIX_SUMMARY.md)
- **Current Status:** DAM interface is stable and loading assets correctly

---

## ✅ Current Status

**Completed:**
- ✅ Fixed layout crash loop (disabled Zustand store)
- ✅ DAM interface loading successfully
- ✅ Assets displaying correctly
- ✅ Architecture designed with 3-tier system

**Next Steps:**
- Implement Phase 1 (Database migration)
- Build backend API endpoints
- Create frontend components

---

**Document Owner:** Development Team
**Last Updated:** 12 Ottobre 2025
**Architecture Version:** 2.0 (3-Tier)
