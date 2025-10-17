# EWH Hybrid Architecture - Odoo-Style Encapsulation

## Executive Summary

This document defines a **hybrid web-first architecture** inspired by Odoo's proven modular patterns, optimized for the EWH Business Operating System. The approach balances web app benefits (easy updates, unified codebase) with native performance where it matters most (editors, heavy processing).

**Key Decision**: Web shell + local components for performance-critical operations.

---

## 1. Odoo Architecture Analysis

### What We Learned from Odoo

**Three-Tier Architecture**:
```
┌─────────────────────────────────────┐
│   Presentation (HTML5/JS/CSS)      │  ← Web-based, runs in browser
├─────────────────────────────────────┤
│   Business Logic (Python)          │  ← Server-side, API-driven
├─────────────────────────────────────┤
│   Data Storage (PostgreSQL)        │  ← Centralized database
└─────────────────────────────────────┘
```

**Modular Design**:
- Each module is self-contained (CRM, Inventory, HR, Accounting)
- Modules communicate via well-defined APIs
- Can add/remove modules without breaking core
- Inheritance-based extensibility

**Frontend Framework (OWL)**:
- JavaScript components (Owl = Odoo Web Library)
- Reactive UI with client-side state management
- WebClient orchestrates all modules
- Event bus for inter-module communication

**Backend Framework**:
- Python ORM for database abstraction
- RESTful APIs for all operations
- RPC layer for real-time communication
- Modular controllers handle requests

**Key Insight**: Odoo achieves "encapsulation" through:
1. **Module isolation**: Each feature in separate module
2. **API boundaries**: Strict interfaces between components
3. **View abstraction**: XML views rendered dynamically
4. **Service layer**: Shared services (auth, notifications, etc.)

**What Odoo Does NOT Do**:
- ❌ No local native components (100% web-based)
- ❌ No desktop applications
- ❌ No offline-first architecture
- ❌ Heavy operations happen server-side (can be slow)

**Our Adaptation**: Keep Odoo's modular patterns but add local components for editors.

---

## 2. EWH Hybrid Architecture

### Core Principles

1. **Web-First**: Default to web technologies (Next.js, React, TypeScript)
2. **Selective Native**: Only for performance-critical operations
3. **Modular**: Odoo-style module isolation
4. **API-Driven**: All communication via REST/GraphQL/WebSocket
5. **Progressive**: Start web-only, add native components as needed

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    EWH Shell (Next.js)                       │
│                   Port 3150 - Main Entry                     │
├──────────────────────────────────────────────────────────────┤
│  ┌────────────┐  ┌────────────┐  ┌────────────────────────┐ │
│  │  Top Bar   │  │  Sidebar   │  │   Content Area         │ │
│  │ (Tenant,   │  │ (Module    │  │   (Module Router)      │ │
│  │  User)     │  │  Nav)      │  │                        │ │
│  └────────────┘  └────────────┘  └────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                            ↓
        ┌───────────────────┴───────────────────┐
        ↓                                       ↓
┌──────────────────┐                 ┌──────────────────────┐
│  WEB MODULES     │                 │  LOCAL COMPONENTS    │
│  (iframe/micro)  │                 │  (Desktop Apps)      │
├──────────────────┤                 ├──────────────────────┤
│ • CRM            │                 │ • Image Editor       │
│ • PM             │                 │ • Video Editor       │
│ • HR             │                 │ • InDesign Bridge    │
│ • Accounting     │                 │ • Prepress Tools     │
│ • DAM (browse)   │                 │ • 3D Render Engine   │
│ • Forms          │                 │ • CAD Viewer         │
│ • Dashboards     │                 │ • PDF Compositor     │
│ • Social Feed    │                 │                      │
│ • E-commerce     │                 │ (Tauri apps)         │
└──────────────────┘                 └──────────────────────┘
        ↓                                       ↓
┌──────────────────────────────────────────────────────────────┐
│              API Gateway (Node.js/Fastify)                   │
│                      Port 4000                               │
├──────────────────────────────────────────────────────────────┤
│  • Authentication (JWT)                                      │
│  • Authorization (RBAC)                                      │
│  • Rate Limiting                                             │
│  • Request Routing                                           │
│  • WebSocket Hub                                             │
└──────────────────────────────────────────────────────────────┘
        ↓
┌──────────────────────────────────────────────────────────────┐
│                    Microservices Layer                       │
├──────────────────────────────────────────────────────────────┤
│  svc-auth │ svc-crm │ svc-pm │ svc-media │ svc-content │...  │
└──────────────────────────────────────────────────────────────┘
        ↓
┌──────────────────────────────────────────────────────────────┐
│           PostgreSQL + Redis + S3/R2 Storage                 │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Web Modules (Odoo-Style)

### Module Structure

Each web module follows this pattern:

```
/modules/crm/
├── frontend/               # Next.js frontend
│   ├── pages/
│   │   ├── index.tsx      # List view
│   │   ├── [id].tsx       # Detail view
│   │   └── new.tsx        # Create view
│   ├── components/
│   │   ├── ContactCard.tsx
│   │   ├── DealPipeline.tsx
│   │   └── ActivityFeed.tsx
│   ├── hooks/
│   │   ├── useContacts.ts
│   │   └── useDeals.ts
│   └── api/
│       └── client.ts      # API client for this module
├── backend/                # Node.js backend
│   ├── routes/
│   │   ├── contacts.ts
│   │   ├── deals.ts
│   │   └── activities.ts
│   ├── models/
│   │   ├── Contact.ts
│   │   ├── Deal.ts
│   │   └── Activity.ts
│   ├── services/
│   │   ├── ContactService.ts
│   │   └── DealService.ts
│   └── validation/
│       └── schemas.ts
├── shared/                 # Shared types
│   └── types.ts
├── module.config.json      # Module metadata
└── README.md
```

### Module Configuration

**module.config.json**:
```json
{
  "id": "crm",
  "name": "CRM",
  "version": "1.0.0",
  "icon": "Users",
  "category": "sales",
  "description": "Customer Relationship Management",

  "routes": [
    {
      "path": "/crm",
      "component": "CRMDashboard",
      "roles": ["TENANT_ADMIN", "SALES"]
    },
    {
      "path": "/crm/contacts",
      "component": "ContactList",
      "roles": ["TENANT_ADMIN", "SALES", "MARKETING"]
    }
  ],

  "api": {
    "baseUrl": "/api/crm",
    "endpoints": [
      "GET /contacts",
      "POST /contacts",
      "GET /contacts/:id",
      "PUT /contacts/:id",
      "DELETE /contacts/:id"
    ]
  },

  "dependencies": [
    "auth",
    "notifications"
  ],

  "permissions": [
    "crm.contacts.read",
    "crm.contacts.write",
    "crm.deals.read",
    "crm.deals.write"
  ],

  "widgets": [
    {
      "id": "deal-pipeline",
      "name": "Deal Pipeline",
      "description": "Visual pipeline for deals",
      "configurable": true
    }
  ]
}
```

### Module Loading

**Shell loads modules dynamically**:

```typescript
// app-shell-frontend/src/lib/ModuleRegistry.ts

interface Module {
  id: string;
  name: string;
  icon: string;
  url?: string;          // If iframe (legacy modules)
  component?: string;    // If native module
  config: ModuleConfig;
}

class ModuleRegistry {
  private modules: Map<string, Module> = new Map();

  async loadModule(moduleId: string): Promise<Module> {
    // Check if module is web-based or requires local component
    const config = await fetch(`/api/modules/${moduleId}/config`);
    const module = await config.json();

    if (module.requiresLocal) {
      // Check if local component is installed
      const localAvailable = await this.checkLocalComponent(moduleId);

      if (!localAvailable) {
        // Fallback to web version or prompt install
        return this.loadWebFallback(moduleId);
      }

      // Launch local component
      return this.launchLocalComponent(moduleId);
    }

    // Standard web module
    return this.loadWebModule(module);
  }

  private async checkLocalComponent(moduleId: string): Promise<boolean> {
    // Check if Tauri app is installed
    try {
      const response = await fetch(`http://localhost:9000/health/${moduleId}`);
      return response.ok;
    } catch {
      return false;
    }
  }

  private launchLocalComponent(moduleId: string): Module {
    // Send message to local component to launch
    window.electron?.send('launch-editor', { moduleId });

    return {
      id: moduleId,
      type: 'local',
      status: 'launching'
    };
  }
}
```

---

## 4. Local Components (Performance Layer)

### When to Use Local Components

**Use local components for**:
✅ Image editing (Photoshop-like operations)
✅ Video editing (timeline, effects, encoding)
✅ 3D rendering (CAD, mockups, product viz)
✅ InDesign integration (prepress, layout)
✅ PDF composition (complex layouts)
✅ Large file processing (RAW images, 4K video)
✅ Real-time collaboration with low latency
✅ Offline-critical workflows

**Keep web-based**:
🌐 CRM (forms, lists, dashboards)
🌐 Project Management (kanban, gantt)
🌐 HR (employee profiles, time tracking)
🌐 Accounting (invoices, reports)
🌐 E-commerce (product catalog, orders)
🌐 Social features (feeds, comments, likes)
🌐 Forms and surveys
🌐 Analytics and BI

### Technology: Tauri (Not Electron)

**Why Tauri**:
- ✅ **Lightweight**: 5-10MB vs 150MB+ (Electron)
- ✅ **Low RAM**: Uses system WebView (50-100MB vs 300-500MB)
- ✅ **Secure**: Rust backend, sandboxed by default
- ✅ **Modern**: Uses system's native rendering engine
- ✅ **Fast**: Near-native performance for heavy operations

**Tauri Architecture**:
```
┌─────────────────────────────────────┐
│     Frontend (React/TypeScript)     │  ← Same as web
│         (WebView Rendering)         │
├─────────────────────────────────────┤
│      Tauri Core (Rust)              │  ← Native layer
│  • File system access               │
│  • GPU acceleration                 │
│  • Native libraries (ffmpeg, etc)   │
│  • IPC bridge                       │
├─────────────────────────────────────┤
│   System WebView (Native)           │  ← Safari/Edge engine
└─────────────────────────────────────┘
```

### Local Component Examples

#### 1. Image Editor (Real Estate Photo Enhancement)

```
/local-components/image-editor/
├── src/
│   ├── frontend/          # React UI (same as web)
│   │   ├── Canvas.tsx
│   │   ├── Toolbar.tsx
│   │   └── Layers.tsx
│   ├── backend/           # Rust native operations
│   │   ├── filters.rs     # GPU-accelerated filters
│   │   ├── ai.rs          # AI enhancement (local model)
│   │   └── export.rs      # High-quality export
│   └── main.rs            # Tauri entry point
├── tauri.conf.json        # Tauri config
└── package.json
```

**Communication with Shell**:
```typescript
// User clicks "Edit Photo" in DAM (web)
// Shell detects this requires local editor

// 1. Shell checks if editor is running
const editorAvailable = await fetch('http://localhost:9001/health');

if (!editorAvailable.ok) {
  // Prompt user to install editor
  showInstallPrompt('image-editor');
  return;
}

// 2. Send edit request with auth token
await fetch('http://localhost:9001/edit', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    assetId: '123',
    assetUrl: 'https://cdn.ewh.io/assets/photo.jpg',
    tenant: 'acme',
    user: 'fabio@example.com'
  })
});

// 3. Editor downloads file, opens in local UI
// 4. User edits, clicks "Save"
// 5. Editor uploads to S3, notifies backend
// 6. DAM refreshes to show updated version
```

**Why Local**:
- GPU-accelerated filters (instant preview)
- AI enhancement with local models (privacy + speed)
- No upload lag for large files
- Works offline
- Can integrate with Photoshop plugins

#### 2. InDesign Bridge (Publishing Workflow)

```
/local-components/indesign-bridge/
├── src/
│   ├── frontend/
│   │   ├── LayoutManager.tsx
│   │   └── AssetPicker.tsx
│   ├── backend/
│   │   ├── indesign_api.rs    # CEP/UXP integration
│   │   ├── sync.rs             # Bi-directional sync
│   │   └── export.rs           # PDF/IDML export
│   └── scripts/
│       ├── import_assets.jsx   # ExtendScript
│       └── export_layout.jsx
└── tauri.conf.json
```

**Workflow**:
1. User creates layout in web page builder
2. Clicks "Open in InDesign"
3. Local bridge launches InDesign with template
4. Bridge syncs assets from DAM to local cache
5. User edits in InDesign (full power)
6. Bridge watches for changes, syncs back
7. Final PDF exported and uploaded to DAM

**Why Local**:
- Direct InDesign API access (ExtendScript/UXP)
- No lag for large layout files
- Offline editing support
- Printer-grade PDF export

#### 3. Video Editor (Marketing Content)

```
/local-components/video-editor/
├── src/
│   ├── frontend/
│   │   ├── Timeline.tsx
│   │   ├── Preview.tsx
│   │   └── Effects.tsx
│   ├── backend/
│   │   ├── ffmpeg.rs          # Native ffmpeg
│   │   ├── encoding.rs        # Hardware encoding
│   │   └── ai_effects.rs      # AI auto-cut, captions
│   └── main.rs
└── tauri.conf.json
```

**Why Local**:
- Hardware-accelerated encoding (H.264/H.265)
- Real-time preview without lag
- AI effects (auto-cut, captions) with local models
- No upload/download for multi-GB files

---

## 5. Communication Protocols

### Shell ↔ Web Modules

**Standard REST APIs**:
```typescript
// Shell passes context to module
const moduleUrl = `https://crm.ewh.io?token=${jwt}&tenant=${tenantId}`;

// Or postMessage if iframe
iframe.contentWindow.postMessage({
  type: 'AUTH_CONTEXT',
  token: jwt,
  tenant: { id, name, slug }
}, '*');
```

### Shell ↔ Local Components

**HTTP API (Local Server)**:

Each local component runs a tiny HTTP server on localhost:

```rust
// Tauri backend (Rust)
use actix_web::{web, App, HttpServer};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .route("/health", web::get().to(health_check))
            .route("/edit", web::post().to(open_editor))
            .route("/status", web::get().to(get_status))
    })
    .bind("127.0.0.1:9001")?
    .run()
    .await
}
```

**WebSocket (Real-Time Updates)**:

For bi-directional communication:

```typescript
// Shell connects to local component
const ws = new WebSocket('ws://localhost:9001/sync');

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);

  switch (message.type) {
    case 'EDIT_COMPLETE':
      // Refresh asset in DAM
      refreshAsset(message.assetId);
      break;

    case 'PROGRESS':
      // Show progress bar
      updateProgress(message.percent);
      break;
  }
};

// Send commands to editor
ws.send(JSON.stringify({
  type: 'APPLY_FILTER',
  filter: 'enhance',
  params: { strength: 80 }
}));
```

### Inter-Module Communication

**Event Bus (Odoo-Style)**:

```typescript
// shared/packages/event-bus/index.ts

class EventBus {
  private listeners: Map<string, Set<Function>> = new Map();

  subscribe(event: string, callback: Function) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
  }

  publish(event: string, data: any) {
    if (this.listeners.has(event)) {
      this.listeners.get(event)!.forEach(cb => cb(data));
    }
  }
}

export const eventBus = new EventBus();
```

**Usage**:
```typescript
// CRM module publishes event
eventBus.publish('contact.created', {
  contactId: '123',
  name: 'John Doe',
  email: 'john@example.com'
});

// Email module subscribes
eventBus.subscribe('contact.created', (data) => {
  // Add to mailing list
  addToMailingList(data.contactId);
});
```

---

## 6. Progressive Enhancement Strategy

### Phase 1: Pure Web (Real Estate MVP - Q1 2025)

**Start with 100% web**:
- All features in web app
- Image editing: Use browser-based editor (like Photopea)
- Video: Simple trim/crop in browser
- No local components yet

**Why**:
- Fastest to market
- Lowest barrier to entry
- Test market fit first

### Phase 2: Add First Local Component (Q2 2025)

**After 500+ customers, add Image Editor**:
- Build Tauri image editor
- Offer as optional download: "Enhanced Editor (Desktop)"
- Free tier: web editor only
- Pro tier: includes desktop editor
- Track usage: if <20% use it, deprioritize

**Why**:
- Validate demand for local components
- Learn distribution/updates
- Differentiation for Pro tier

### Phase 3: Expand Local Components (Q3-Q4 2025)

**Based on customer feedback**:
- Video editor (if customers request)
- InDesign bridge (if targeting design agencies)
- 3D viewer (if adding virtual staging)

**Decision criteria**:
- >30% of Pro customers request feature
- Web version has measurable UX issues (lag, crashes)
- Competitive advantage (others don't have it)

### Phase 4: Social Network - Web Only (Year 2-3)

**No local components**:
- Social feed, posts, comments = web native
- Image filters: WebGL/WASM (Snapchat-style)
- Video: Short-form, browser upload is fine

**Why**:
- Consumer product = no desktop app expectation
- Mobile is primary (React Native apps, not desktop)

### Phase 5: Universal OS - Hybrid (Year 5+)

**Mature hybrid platform**:
- Core: Web-based (CRM, PM, HR, Accounting)
- Editors: Local components (Image, Video, 3D, CAD)
- Distribution: Desktop app store (internal)
- Updates: Auto-update like VS Code

---

## 7. Development Stack

### Web Modules

**Frontend**:
- Next.js 14+ (React 18, TypeScript)
- TailwindCSS 3+ (styling)
- Zustand (state management per module)
- React Query (API caching)
- Lucide React (icons)

**Backend**:
- Node.js 20+ (TypeScript)
- Fastify (faster than Express)
- Prisma (ORM for PostgreSQL)
- Zod (validation)
- JWT (authentication)

**Infrastructure**:
- PostgreSQL 14+ (multi-tenant)
- Redis 7+ (caching, sessions, queues)
- S3/R2 (file storage)
- Railway/Vercel/Render (hosting)

### Local Components

**Frontend** (same as web):
- React + TypeScript
- TailwindCSS
- Zustand

**Backend** (Tauri):
- Rust 1.70+ (Tauri core)
- actix-web (HTTP server)
- tokio (async runtime)
- serde (JSON serialization)

**Native Libraries**:
- ffmpeg (video processing)
- ImageMagick/libvips (image processing)
- wgpu (GPU acceleration)
- onnxruntime (AI models)

**Distribution**:
- Tauri updater (auto-updates)
- Code signing (Apple/Microsoft)
- DMG (Mac), MSI (Windows), AppImage (Linux)

---

## 8. Real Estate SaaS Example

### Module Breakdown

**Web Modules** (majority):
1. **Property Management** 🌐
   - List properties
   - Add/edit property details
   - Upload photos (to DAM)
   - Generate brochures

2. **CRM** 🌐
   - Contacts (buyers, sellers, agents)
   - Deals pipeline
   - Activity tracking
   - Email/SMS campaigns

3. **Virtual Tours** 🌐
   - 360° photo viewer (browser WebGL)
   - Floor plans
   - Video walkthroughs

4. **Lead Management** 🌐
   - Web forms
   - Lead scoring
   - Follow-up automation

5. **Analytics** 🌐
   - Property performance
   - Agent metrics
   - Market trends

**Local Component** (optional):
1. **Photo Enhancement Studio** 💻
   - AI enhancement (brighten, HDR, sky replacement)
   - Virtual staging (add furniture)
   - Batch processing (100s of photos)
   - Export presets (web, print, social)

### User Journey

**Free/Starter Tier** (€49/month):
- All web features
- Basic photo upload
- Web-based crop/rotate
- 5 properties
- 100 photos/month

**Pro Tier** (€99/month):
- All web features
- **Desktop Photo Editor** (optional download)
- AI enhancement
- Virtual staging (10 rooms/month)
- 50 properties
- 1000 photos/month

**Ultra Tier** (€179/month):
- Pro features +
- Video editor (local)
- 3D floor plan editor
- Unlimited properties
- Unlimited photos

### Technical Flow

**User uploads 20 property photos**:

1. **Web Upload** (DAM module):
   ```typescript
   // Browser uploads to S3 directly (presigned URL)
   const { uploadUrl } = await fetch('/api/dam/upload-url');
   await fetch(uploadUrl, {
     method: 'PUT',
     body: file,
     headers: { 'Content-Type': file.type }
   });
   ```

2. **User clicks "Enhance All"**:
   ```typescript
   // Shell checks if local editor installed
   const hasEditor = await fetch('http://localhost:9001/health')
     .then(r => r.ok)
     .catch(() => false);

   if (!hasEditor) {
     // Offer fallback: server-side enhancement (slower)
     showModal({
       title: 'Faster with Desktop Editor',
       message: 'Download our desktop editor for instant AI enhancements',
       actions: [
         { label: 'Download (Free)', action: downloadEditor },
         { label: 'Use Web Version', action: enhanceOnServer }
       ]
     });
   } else {
     // Launch local editor with batch
     await fetch('http://localhost:9001/batch-enhance', {
       method: 'POST',
       body: JSON.stringify({
         assets: photoIds,
         preset: 'real-estate-hdr'
       })
     });
   }
   ```

3. **Local editor processes**:
   - Downloads photos to local cache
   - Applies AI enhancement (GPU-accelerated, ~1 sec/photo)
   - Shows progress in UI
   - Uploads enhanced versions to S3
   - Notifies DAM via API

4. **DAM refreshes** to show enhanced photos

**Result**:
- Web users: 20 photos × 10 sec = 3.3 minutes (server-side)
- Desktop users: 20 photos × 1 sec = 20 seconds (local GPU)
- **10x faster** with desktop editor = competitive advantage

---

## 9. Implementation Roadmap

### Q1 2025: Pure Web MVP

**Deliverables**:
- ✅ Shell frontend (port 3150)
- ✅ Module registry system
- ✅ 5 core modules (Property, CRM, DAM, Analytics, Settings)
- ✅ Web-based photo editor (Photopea-like)
- ✅ Payment integration (Stripe)
- ✅ 4-tier pricing

**Tech Stack**:
- Next.js + TypeScript (all modules)
- Shared component library (@ewh/shared-widgets)
- PostgreSQL multi-tenant
- S3 storage

**Timeline**: 8 weeks
- Week 1-2: Shell + module system
- Week 3-4: Property + CRM modules
- Week 5-6: DAM + photo editor (web)
- Week 7-8: Analytics + billing

**Goal**: Launch to first 100 customers (door-to-door)

### Q2 2025: First Local Component

**Deliverables**:
- ✅ Tauri image editor (Mac + Windows)
- ✅ AI enhancement (local models)
- ✅ Virtual staging
- ✅ Batch processing
- ✅ Auto-updater
- ✅ Installer (DMG/MSI)

**Tech Stack**:
- Tauri 1.5+
- React (frontend, reuse from web)
- Rust (native operations)
- onnxruntime (AI models)
- ffmpeg/libvips (image processing)

**Timeline**: 6 weeks
- Week 1-2: Tauri setup + basic editor
- Week 3-4: AI enhancement + staging
- Week 5: Batch processing + export
- Week 6: Installer + updater

**Distribution**:
- Manual download from dashboard
- "Download Enhanced Editor" button
- Pro tier perk

**Metrics to Track**:
- % Pro users who download
- % who use it weekly
- Support tickets (bugs, install issues)
- Performance vs web (NPS)

**Decision Point**: If <20% adoption, pause local components. If >30%, continue.

### Q3-Q4 2025: Expand Based on Demand

**Option A: Video Editor** (if customers request):
- Timeline editor
- Trim, cut, transitions
- AI captions
- Export to social (vertical/horizontal)

**Option B: 3D Floor Plan Editor** (if virtual staging popular):
- Upload floor plan image
- Trace walls, add furniture
- Export 3D walkthrough
- VR mode (optional)

**Option C: Mobile Apps** (if mobile usage >40%):
- React Native (iOS + Android)
- Focus: property browsing, lead capture
- Native: Camera (upload photos directly)

### Year 2-3: Social Network (Web Only)

**No local components**:
- 100% web-based
- React Native for mobile (iOS/Android)
- Focus: fast iteration, viral loops

### Year 5+: Mature Hybrid Platform

**Local components for**:
- Image editor
- Video editor
- InDesign bridge
- CAD/3D tools

**Everything else**: Web-based

---

## 10. Cost Analysis

### Pure Web Only

**Development**:
- Frontend: 8 weeks × €5k = €40k
- Backend: 6 weeks × €5k = €30k
- Infrastructure: €500/month
- **Total Year 1**: €76k

**Hosting** (5,000 customers):
- Servers: €2k/month
- Database: €1k/month
- Storage (S3): €500/month
- CDN: €300/month
- **Total**: €3.8k/month = €46k/year

**Year 1 Total**: €122k

### Hybrid (Web + Local Components)

**Additional Development**:
- Tauri setup: 2 weeks × €5k = €10k
- Image editor: 6 weeks × €5k = €30k
- Video editor: 8 weeks × €5k = €40k
- Distribution (installers, code signing): €5k
- **Total Additional**: €85k

**Additional Hosting**:
- Update server: €200/month = €2.4k/year
- CDN for downloads: €100/month = €1.2k/year
- **Total Additional**: €3.6k/year

**Year 1 Total (Hybrid)**: €211k

**Incremental Cost**: +€89k (73% increase)

**ROI Analysis**:
- Assume 20% conversion to Pro tier due to desktop editor
- 5,000 customers × 20% × €99/mo = €99k/month additional
- €99k × 12 = €1.2M/year additional revenue
- **ROI**: €1.2M / €89k = **13.5x return**

**Decision**: Start web-only, add local components in Q2 if traction warrants.

---

## 11. Competitor Comparison

### How Others Do It

| Company | Architecture | Local Components | Notes |
|---------|-------------|------------------|-------|
| **Odoo** | 100% web | ❌ None | Pure web, some lag on heavy ops |
| **Adobe Creative Cloud** | Desktop apps + cloud sync | ✅ All native | Heavy apps (GB), expensive ($50-100/mo) |
| **Figma** | 100% web | ❌ None | Impressive web performance, but limits |
| **Canva** | 100% web | ❌ None | Simple operations only, no pro tools |
| **Monday.com** | 100% web | ❌ None | PM/CRM, no editors |
| **HubSpot** | 100% web | ❌ None | CRM, no creative tools |
| **Airtable** | 100% web + desktop (Electron) | ⚠️ Electron wrapper | Desktop app is just wrapped web |
| **Notion** | 100% web + desktop (Electron) | ⚠️ Electron wrapper | Same codebase, native feel |
| **Slack** | 100% web + desktop (Electron) | ⚠️ Electron wrapper | Heavy RAM usage |
| **VS Code** | Desktop (Electron) + web | ✅ Hybrid | Extensions run local, web for quick edits |

### Our Positioning

**EWH = Odoo (modular) + Selective Native (performance)**

- ✅ Web-first like Odoo (easy updates, low barrier)
- ✅ Local components where needed (Adobe-level power)
- ✅ Lightweight like Tauri (not bloated like Electron)
- ✅ Progressive (start web, add native as needed)

**Competitive Advantage**:
- Odoo/Monday/HubSpot: We have pro creative tools
- Adobe: We're 1/5 the price, integrated with CRM/PM
- Figma/Canva: We're for business operations, not just design

---

## 12. Technical Decisions Summary

### Final Recommendations

**✅ DO**:
1. **Start 100% web** (Next.js, React, TypeScript)
2. **Modular architecture** (Odoo-style modules)
3. **Add local components in Q2** (Tauri, not Electron)
4. **Only for editors** (image, video, InDesign)
5. **Progressive enhancement** (free = web, pro = desktop option)
6. **Track usage metrics** (decide based on data)

**❌ DON'T**:
1. ❌ Don't build desktop apps first (too slow to market)
2. ❌ Don't use Electron (too heavy, 150MB+)
3. ❌ Don't build local components for CRM/PM (web is fine)
4. ❌ Don't force desktop app (make it optional)
5. ❌ Don't build WordPress plugins (wrong foundation)
6. ❌ Don't go pure native (2-3x dev cost)

### Architecture Pattern

**Inspired by Odoo, Enhanced for Performance**:

```
┌─────────────────────────────────────┐
│         Web Shell (Next.js)         │  ← Main app
├─────────────────────────────────────┤
│  Module Registry (Dynamic Loading)  │  ← Odoo-style
├─────────────────────────────────────┤
│  ┌───────────┐    ┌──────────────┐ │
│  │    Web    │    │    Local     │ │
│  │  Modules  │◄──►│ Components   │ │  ← Hybrid
│  │ (iframe)  │    │   (Tauri)    │ │
│  └───────────┘    └──────────────┘ │
├─────────────────────────────────────┤
│       API Gateway (Fastify)         │  ← Unified API
├─────────────────────────────────────┤
│      Microservices (Node.js)        │  ← Business logic
├─────────────────────────────────────┤
│  PostgreSQL + Redis + S3 Storage    │  ← Data layer
└─────────────────────────────────────┘
```

**Key Characteristics**:
1. **Modular**: Each feature is a separate module (CRM, PM, DAM, etc.)
2. **Encapsulated**: Modules communicate via APIs, not direct imports
3. **Extensible**: Add new modules without changing core
4. **Hybrid**: Web by default, local for performance
5. **Progressive**: Start web, add native as needed

---

## 13. Next Steps

### Immediate (This Week)

1. **Finalize architecture decision**
   - Review this document
   - Confirm: Web-first, local components in Q2
   - Get team alignment

2. **Setup development environment**
   - Shell frontend (port 3150)
   - Module template structure
   - API gateway

### Q1 2025: Real Estate MVP

**Week 1-2: Foundation**
- [ ] Shell app with module registry
- [ ] Auth + tenant system
- [ ] First module: Property Management

**Week 3-4: Core Modules**
- [ ] CRM module (contacts, deals)
- [ ] DAM module (upload, browse, basic edit)
- [ ] Forms module (lead capture)

**Week 5-6: Features**
- [ ] Web-based photo editor (crop, filters)
- [ ] Brochure generator (PDF)
- [ ] Email campaigns

**Week 7-8: Polish + Launch**
- [ ] Analytics dashboard
- [ ] Billing (Stripe)
- [ ] Onboarding flow
- [ ] Launch to first 100 customers

### Q2 2025: Desktop Editor (If Traction)

**Week 1-2: Tauri Setup**
- [ ] Tauri boilerplate
- [ ] HTTP server (localhost)
- [ ] Shell integration (detect, launch)

**Week 3-4: Image Editor**
- [ ] Canvas + layers
- [ ] Filters (GPU-accelerated)
- [ ] AI enhancement

**Week 5-6: Advanced Features**
- [ ] Virtual staging
- [ ] Batch processing
- [ ] Export presets

### Decision Gates

**After 100 customers**:
- Review: Are they asking for better photo editing?
- Metrics: How many use web editor? Complaints?
- Decision: Build desktop editor or focus on other features?

**After 500 customers**:
- Review: Revenue, churn, NPS
- Decision: Continue Real Estate or pivot/expand?

**After €1M ARR**:
- Review: Desktop editor adoption (if built)
- Decision: Build video editor? Mobile apps? Other verticals?

---

## 14. Conclusion

### Recommendation: Odoo-Style Web + Selective Native

**Start Web-First** (Q1 2025):
- ✅ Fastest to market
- ✅ Lowest cost
- ✅ Prove market fit
- ✅ 100% of features available
- ✅ Good enough for 80% of users

**Add Native Selectively** (Q2 2025+):
- ✅ Only for performance-critical operations
- ✅ Based on customer demand (data-driven)
- ✅ Optional download (not required)
- ✅ Pro tier differentiator
- ✅ Competitive advantage (10x faster edits)

**Modular Like Odoo**:
- ✅ Each feature is a module
- ✅ Modules communicate via APIs
- ✅ Easy to add/remove features
- ✅ Extensible for future verticals

**Key Insight from Odoo**:
Odoo's success comes from **modularity** and **web-first**, not from native apps. We adopt their proven patterns (modules, APIs, extensibility) while adding **selective native components** for performance where web falls short (editors, heavy processing).

**This gives us**:
- 🚀 Fast time-to-market (web)
- 💰 Low customer acquisition cost (no install friction)
- 🎨 Professional-grade tools (native editors)
- 📈 Scalability (modular architecture)
- 🌍 Universal access (works on any device)

**Perfect for**:
- ✅ Real Estate SaaS (MVP web-only, add editor later)
- ✅ Social Network (100% web + mobile apps)
- ✅ Universal OS (web for business, native for creative)

---

**Next: Review with team, confirm approach, start building Real Estate MVP.**

**Target**: Launch to first 100 customers by end of Q1 2025.
