# Multi-Function Sidebar - Architettura Completa

**Data**: 2025-10-15
**Status**: Specifiche Complete - Ready for Implementation
**Version**: 3.0 - Multi-Function

---

## 🎯 Obiettivo

Creare una **sidebar multifunzionale** integrata nella shell che permetta:
- **DAM**: Accesso rapido agli asset, drag-and-drop universale
- **Chat**: Comunicazione real-time con team
- **Bacheca**: Notifiche, annunci, feed attività
- **Altre funzioni**: Estendibile per nuove feature future
- Ogni funzione ha il suo megamenu con logiche specifiche

---

## 🏗️ Architettura Visuale

```
┌─────────────────────────────────────────────────────────┐
│  TopBar (64px height)                                   │
│  Logo | Categories | User Menu                          │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────┬───────────┐
│                                             │           │
│                                             │  DAM      │
│  Main Content Area                          │  Sidebar  │
│  (Shell content, iframes, apps)             │  (64px)   │
│                                             │           │
│  - Width: calc(100vw - 64px)                │  [Icon]   │
│  - Height: calc(100vh - 64px - 40px)        │           │
│                                             │  Static   │
│                                             │  Always   │
│                                             │  Visible  │
│                                             │           │
└─────────────────────────────────────────────┴───────────┘
┌─────────────────────────────────────────────────────────┐
│  BottomBar (40px height)                                │
│  Status | Notifications | Settings                      │
└─────────────────────────────────────────────────────────┘
```

### Layout con DAM MegaMenu Aperto

```
┌─────────────────────────────────────────────────────────┐
│  TopBar (64px height)                                   │
└─────────────────────────────────────────────────────────┘
┌──────────────────────────────┬──────────────┬───────────┐
│                              │  DAM         │           │
│  Main Content (dimmed)       │  MegaMenu    │  Sidebar  │
│                              │  (400px)     │  (64px)   │
│                              │              │           │
│                              │ ┌──────────┐ │  [Icon]   │
│                              │ │ Search   │ │  Active   │
│                              │ └──────────┘ │           │
│                              │              │           │
│                              │ ┌──────────┐ │           │
│                              │ │ Recent   │ │           │
│                              │ │ ▢ ▢ ▢ ▢  │ │           │
│                              │ └──────────┘ │           │
│                              │              │           │
│                              │ ┌──────────┐ │           │
│                              │ │ Folders  │ │           │
│                              │ │ 📁 Photos│ │           │
│                              │ │ 📁 Docs  │ │           │
│                              │ └──────────┘ │           │
└──────────────────────────────┴──────────────┴───────────┘
```

---

## 📐 Specifiche Tecniche

### 1. Multi-Function Sidebar (Statica)

**Layout**:
- **Posizione**: Fixed, right side
- **Width**: 64px (fissa, non espandibile)
- **Height**: `calc(100vh - 64px - 40px)` (escluso TopBar e BottomBar)
- **Top**: 64px (sotto TopBar)
- **Bottom**: 40px (sopra BottomBar)
- **Z-index**: 20

**Contenuto - Icone Multiple** (verticali, dall'alto):
```
┌───────┐
│  📁   │ ← DAM (Digital Asset Management)
├───────┤
│  💬   │ ← Chat (Team communication)
├───────┤
│  📢   │ ← Bacheca (Feed, notifiche, annunci)
├───────┤
│  📊   │ ← Analytics (Dashboard rapido)
├───────┤
│  🔔   │ ← Notifiche (Badge con count)
├───────┤
│  ...  │ ← Altre funzioni future
└───────┘
```

**Comportamento**:
- Sempre visibile (non si nasconde)
- Non overlappa TopBar o BottomBar
- Riduce larghezza main content: `width: calc(100vw - 64px)`
- Click su icona → apre/chiude il rispettivo MegaMenu
- Solo un MegaMenu aperto alla volta (toggle)
- Active state sull'icona con megamenu aperto

**Ogni Icona**:
- Size: 40x40px
- Padding: 12px (totale 64px)
- Hover effect: background change
- Active state: background blue + border-left blu
- Badge notifiche (top-right, se count > 0)

---

### 2. DAM MegaMenu (Pannello Laterale)

**Layout**:
- **Posizione**: Fixed, right side, accanto alla sidebar
- **Width**: 400px (fisso)
- **Height**: `calc(100vh - 64px - 40px)`
- **Top**: 64px
- **Bottom**: 40px
- **Right**: 64px (accanto alla sidebar)
- **Z-index**: 30

**Animazione**:
- Slide-in da destra: `transform: translateX(100%)` → `translateX(0)`
- Durata: 300ms
- Easing: cubic-bezier

**Sezioni**:

#### A. Search Bar (top, fixed)
```
┌────────────────────────────────┐
│ 🔍 Search assets...            │
│ [Filters ▾]                    │
└────────────────────────────────┘
```
- Input con debounce (500ms)
- Filtri: Type, Date, Tags, Folder
- Clear button

#### B. Recent Assets
```
┌────────────────────────────────┐
│ 📌 Recent (Last 10)            │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐           │
│ │▢1│ │▢2│ │▢3│ │▢4│           │
│ └──┘ └──┘ └──┘ └──┘           │
│ [Show all →]                   │
└────────────────────────────────┘
```
- Grid: 4 columns
- Thumbnail: 80x80px
- Hover: preview overlay
- Click: select asset

#### C. Folder Navigation
```
┌────────────────────────────────┐
│ 📁 Folders                     │
│ ├─ 📷 Photos (125)             │
│ ├─ 🎬 Videos (42)              │
│ ├─ 📄 Documents (89)           │
│ ├─ 🎨 Design (67)              │
│ └─ 📦 Archives (23)            │
└────────────────────────────────┘
```
- Tree view collapsible
- Badge con count
- Click: filtra per folder

#### D. Asset Grid (scrollable)
```
┌────────────────────────────────┐
│ All Assets (Grid View)         │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐           │
│ │▢ │ │▢ │ │▢ │ │▢ │           │
│ └──┘ └──┘ └──┘ └──┘           │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐           │
│ │▢ │ │▢ │ │▢ │ │▢ │           │
│ └──┘ └──┘ └──┘ └──┘           │
│ [Infinite scroll...]           │
└────────────────────────────────┘
```
- Infinite scroll
- Lazy loading
- Thumbnails: 90x90px
- Hover: actions (copy URL, insert, download)

#### E. Footer Actions
```
┌────────────────────────────────┐
│ [Upload Files] [Browse Full →]│
└────────────────────────────────┘
```

---

### 3. Drag & Drop System

**Draggable Assets**:
- Ogni thumbnail nel megamenu è draggabile
- Visual feedback: ghost image durante drag
- Cursor: grabbing

**Drop Zones** (globali):
- Email composer (editor body)
- Document editor (CKEditor, TinyMCE, Quill)
- Form file inputs
- Custom drop zones (marcate con `data-dam-drop-zone="true"`)

**Comportamento**:
1. User clicca e trascina thumbnail
2. Sistema crea ghost image (120x120px, opacity 0.7)
3. Durante drag, evidenzia drop zones valide (border blue pulse)
4. On drop:
   - Email/Editor: inserisce `<img src="asset_url" />`
   - File input: popola con file reference
   - Custom: emette evento `dam:asset-dropped`

**Data Transfer**:
```typescript
{
  type: 'dam-asset',
  asset_id: 'uuid',
  asset_url: 'https://cdn.../image.jpg',
  asset_name: 'photo.jpg',
  asset_type: 'image/jpeg',
  thumbnail_url: 'https://cdn.../thumb.jpg'
}
```

---

### 4. Global Asset Insertion API

**Context Provider**:
```typescript
<DAMProvider>
  {/* Shell app */}
</DAMProvider>
```

**Hook per componenti**:
```typescript
const { openDAMPicker, insertAsset } = useDAM();

// In email composer
<button onClick={() => openDAMPicker({
  onSelect: (asset) => insertAsset(asset, 'email-body')
})}>
  Insert Image
</button>
```

**Eventi**:
```typescript
// Emessi da DAM
window.addEventListener('dam:asset-selected', (e) => {
  const { asset, targetId } = e.detail;
  // Insert asset in target
});

// Richiesti da componenti
window.dispatchEvent(new CustomEvent('dam:request-picker', {
  detail: { targetId: 'editor-123', allowedTypes: ['image', 'video'] }
}));
```

---

## 🎨 UI/UX Details

### Visual Design

**Colors**:
- Sidebar BG: `bg-white dark:bg-gray-900`
- Sidebar Border: `border-gray-200 dark:border-gray-700`
- MegaMenu BG: `bg-white dark:bg-gray-900`
- Hover: `bg-gray-50 dark:bg-gray-800`
- Active: `bg-blue-50 dark:bg-blue-900/20`

**Typography**:
- Section titles: 12px, font-semibold, uppercase, text-gray-500
- Asset names: 11px, text-gray-700
- Counts: 10px, text-gray-400

**Spacing**:
- Padding interno megamenu: 16px
- Gap tra sezioni: 24px
- Gap tra thumbnails: 8px

**Shadows**:
- Sidebar: `shadow-lg` (left side)
- MegaMenu: `shadow-2xl`
- Thumbnails hover: `shadow-md`

---

## 🔧 Implementazione Tecnica

### File Structure

```
app-shell-frontend/
├── src/
│   ├── components/
│   │   ├── DAM/
│   │   │   ├── DAMSidebar.tsx          # Icona fissa
│   │   │   ├── DAMMegaMenu.tsx         # Pannello laterale
│   │   │   ├── DAMSearchBar.tsx        # Ricerca
│   │   │   ├── DAMRecentAssets.tsx     # Recent grid
│   │   │   ├── DAMFolderTree.tsx       # Navigazione folders
│   │   │   ├── DAMAssetGrid.tsx        # Grid infinito
│   │   │   ├── DAMAssetThumbnail.tsx   # Singola thumbnail draggable
│   │   │   └── DAMDropZone.tsx         # Drop zone HOC
│   │   └── ShellLayout.tsx             # Layout update
│   ├── context/
│   │   └── DAMContext.tsx              # Global state & API
│   ├── hooks/
│   │   ├── useDAM.ts                   # Hook per accesso DAM
│   │   └── useAssetDrop.ts             # Hook per drop zones
│   └── lib/
│       ├── dam-api.ts                  # API calls a svc-media
│       └── dam-dnd.ts                  # Drag & drop logic
```

### API Endpoints (svc-media - 4003)

```typescript
// Get recent assets
GET /api/dam/recent?limit=10

// Search assets
GET /api/dam/search?q=photo&type=image&folder_id=123

// Get folders tree
GET /api/dam/folders

// Get assets by folder
GET /api/dam/assets?folder_id=123&page=1&limit=20

// Get asset details
GET /api/dam/assets/:id
```

---

## 📊 State Management

### DAMContext State

```typescript
interface DAMState {
  // Sidebar
  isSidebarVisible: boolean;

  // MegaMenu
  isMegaMenuOpen: boolean;

  // Data
  recentAssets: Asset[];
  folders: Folder[];
  assets: Asset[];
  selectedAsset: Asset | null;

  // Search
  searchQuery: string;
  searchFilters: SearchFilters;

  // Loading
  isLoading: boolean;

  // Actions
  toggleMegaMenu: () => void;
  selectAsset: (asset: Asset) => void;
  searchAssets: (query: string) => void;
  insertAsset: (asset: Asset, targetId: string) => void;
}
```

---

## 🚀 Fasi di Implementazione

### Phase 1: Basic Structure ✅
- [x] DAMSidebar component (icona fissa)
- [x] DAMMegaMenu component (pannello slide-in)
- [x] ShellLayout integration
- [x] Basic open/close animation

### Phase 2: Asset Browser
- [ ] DAMSearchBar with filters
- [ ] DAMRecentAssets grid
- [ ] DAMFolderTree navigation
- [ ] DAMAssetGrid with infinite scroll
- [ ] API integration con svc-media

### Phase 3: Drag & Drop
- [ ] Make thumbnails draggable
- [ ] Ghost image during drag
- [ ] Drop zone highlighting
- [ ] Insert asset on drop

### Phase 4: Global Integration
- [ ] DAMContext provider
- [ ] useDAM hook
- [ ] Event system (dam:asset-selected)
- [ ] Integration con email, docs, forms

### Phase 5: Advanced Features
- [ ] Asset preview modal
- [ ] Upload from megamenu
- [ ] Favorites system
- [ ] Tags & collections

---

## 🎯 User Stories

1. **As a user**, voglio vedere un'icona DAM sempre visibile sulla destra per accedere rapidamente agli asset
2. **As a user**, voglio cliccare l'icona e vedere un pannello con asset recenti e ricerca
3. **As a user**, voglio trascinare un'immagine dal DAM in un'email e vederla inserita
4. **As a user**, voglio cercare asset per nome, tipo o folder
5. **As a user**, voglio navigare tra folders per trovare asset organizzati
6. **As a developer**, voglio un hook useDAM per integrare il picker in qualsiasi componente

---

## ✅ Success Criteria

- ✅ Sidebar sempre visibile, non overlappa TopBar/BottomBar
- ✅ Main content width ridotto di 64px
- ✅ MegaMenu si apre/chiude smoothly
- ✅ Asset draggabili da megamenu a qualsiasi drop zone
- ✅ Inserimento asset funziona in email, docs, form
- ✅ Ricerca asset real-time con debounce
- ✅ Performance: megamenu apre in <300ms
- ✅ Accessibilità: keyboard navigation, screen reader support

---

**Created**: 2025-10-15
**Version**: 2.0 - Complete Specifications
**Next Steps**: Implement Phase 1 (Basic Structure)

---

### 3. Chat MegaMenu

**Layout**:
- Width: 400px
- Same height as DAM megamenu
- Same position logic

**Sezioni**:

#### A. Search & Filter
```
┌────────────────────────────────┐
│ 🔍 Search conversations...     │
│ [All] [Unread] [Starred]      │
└────────────────────────────────┘
```

#### B. Conversations List
```
┌────────────────────────────────┐
│ 💬 Recent Conversations        │
│ ┌────────────────────────────┐ │
│ │ [Avatar] John Doe          │ │
│ │ Hey, about the project...  │ │
│ │ 2m ago • 2 unread          │ │
│ └────────────────────────────┘ │
│ ┌────────────────────────────┐ │
│ │ [Avatar] Team Design       │ │
│ │ New mockups are ready      │ │
│ │ 15m ago                    │ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

#### C. Quick Actions
```
┌────────────────────────────────┐
│ [New Chat] [New Group]         │
└────────────────────────────────┘
```

**Features**:
- Real-time updates via WebSocket
- Unread badge count
- Typing indicators
- Click conversation → open full chat modal
- Drag conversation → pin to top

---

### 4. Bacheca MegaMenu

**Layout**:
- Width: 450px (più largo per feed)
- Same height and position

**Sezioni**:

#### A. Tabs
```
┌────────────────────────────────┐
│ [Feed] [Notifiche] [Annunci]  │
└────────────────────────────────┘
```

#### B. Feed Tab (default)
```
┌────────────────────────────────┐
│ 📰 Activity Feed               │
│ ┌────────────────────────────┐ │
│ │ [Avatar] John created      │ │
│ │ "New Project Alpha"        │ │
│ │ 5 minutes ago              │ │
│ │ [View Project →]           │ │
│ └────────────────────────────┘ │
│ ┌────────────────────────────┐ │
│ │ [Avatar] Sarah uploaded    │ │
│ │ 15 new images to DAM       │ │
│ │ [📁 View Images →]         │ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

#### C. Notifiche Tab
```
┌────────────────────────────────┐
│ 🔔 Notifications (3 new)       │
│ ┌────────────────────────────┐ │
│ │ ⚠️  Task "Design Review"   │ │
│ │    due in 2 hours          │ │
│ │    [Mark as done]          │ │
│ └────────────────────────────┘ │
│ ┌────────────────────────────┐ │
│ │ ✅ Approval request         │ │
│ │    approved by John        │ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

#### D. Annunci Tab
```
┌────────────────────────────────┐
│ 📢 Company Announcements       │
│ ┌────────────────────────────┐ │
│ │ 🎉 New Feature Release     │ │
│ │ DAM 2.0 is now available!  │ │
│ │ Oct 15, 2025               │ │
│ │ [Read more →]              │ │
│ └────────────────────────────┘ │
└────────────────────────────────┘
```

**Features**:
- Infinite scroll feed
- Mark all as read
- Filter by type (mentions, tasks, approvals)
- Drag notification → create task

---

### 5. Analytics MegaMenu (Opzionale)

**Layout**: 500px width

**Sezioni**:
- Quick metrics dashboard
- Charts (mini versions)
- Recent reports
- Quick filters

---

## 🔧 Implementazione Tecnica - Updated

### File Structure

```
app-shell-frontend/
├── src/
│   ├── components/
│   │   ├── Sidebar/
│   │   │   ├── MultiSidebar.tsx           # Sidebar principale con icone
│   │   │   ├── SidebarIcon.tsx            # Singola icona con badge
│   │   │   └── index.ts
│   │   ├── MegaMenus/
│   │   │   ├── DAMMegaMenu/
│   │   │   │   ├── index.tsx
│   │   │   │   ├── DAMSearchBar.tsx
│   │   │   │   ├── DAMRecentAssets.tsx
│   │   │   │   ├── DAMFolderTree.tsx
│   │   │   │   ├── DAMAssetGrid.tsx
│   │   │   │   └── DAMAssetThumbnail.tsx
│   │   │   ├── ChatMegaMenu/
│   │   │   │   ├── index.tsx
│   │   │   │   ├── ConversationList.tsx
│   │   │   │   ├── ConversationItem.tsx
│   │   │   │   └── ChatActions.tsx
│   │   │   ├── BachecaMegaMenu/
│   │   │   │   ├── index.tsx
│   │   │   │   ├── FeedTab.tsx
│   │   │   │   ├── NotificheTab.tsx
│   │   │   │   ├── AnnunciTab.tsx
│   │   │   │   └── FeedItem.tsx
│   │   │   └── BaseMegaMenu.tsx       # Base component shared
│   │   └── ShellLayout.tsx
│   ├── context/
│   │   ├── SidebarContext.tsx         # Global sidebar state
│   │   ├── DAMContext.tsx
│   │   ├── ChatContext.tsx
│   │   └── BachecaContext.tsx
│   └── hooks/
│       ├── useSidebar.ts
│       ├── useDAM.ts
│       ├── useChat.ts
│       └── useBacheca.ts
```

### SidebarContext State

```typescript
interface SidebarState {
  // Active menu
  activeMegaMenu: 'dam' | 'chat' | 'bacheca' | 'analytics' | null;

  // Badges/Counts
  unreadMessages: number;
  unreadNotifications: number;
  
  // Actions
  openMegaMenu: (menu: string) => void;
  closeMegaMenu: () => void;
  toggleMegaMenu: (menu: string) => void;
}

interface SidebarIcon {
  id: string;
  icon: LucideIcon | string;
  label: string;
  badge?: number;
  megaMenuComponent: React.ComponentType;
  megaMenuWidth?: number; // default 400px
}
```

### Registrazione Dinamica MegaMenus

```typescript
// In MultiSidebar.tsx
const SIDEBAR_ITEMS: SidebarIcon[] = [
  {
    id: 'dam',
    icon: Image,
    label: 'Media Library',
    megaMenuComponent: DAMMegaMenu,
    megaMenuWidth: 400,
  },
  {
    id: 'chat',
    icon: MessageCircle,
    label: 'Chat',
    badge: unreadMessages,
    megaMenuComponent: ChatMegaMenu,
    megaMenuWidth: 400,
  },
  {
    id: 'bacheca',
    icon: Bell,
    label: 'Feed & Notifiche',
    badge: unreadNotifications,
    megaMenuComponent: BachecaMegaMenu,
    megaMenuWidth: 450,
  },
  {
    id: 'analytics',
    icon: BarChart3,
    label: 'Analytics',
    megaMenuComponent: AnalyticsMegaMenu,
    megaMenuWidth: 500,
  },
];
```

---

## 🎨 Visual Design - Multi-Function

### Sidebar Icone States

**Normal**:
- Background: transparent
- Icon color: gray-600
- Border-left: transparent

**Hover**:
- Background: gray-100
- Icon color: gray-900
- Transition: 150ms

**Active** (megamenu aperto):
- Background: blue-50
- Icon color: blue-600
- Border-left: 3px solid blue-600

**With Badge**:
- Badge position: top-right (-4px, -4px)
- Badge size: 18px diameter
- Badge color: red-500
- Badge text: white, 10px, bold
- Max display: 99+ (se > 99)

---

## 📊 State Management Pattern

### Singleton Pattern per MegaMenus

Solo un megamenu può essere aperto alla volta:

```typescript
const openMegaMenu = (menuId: string) => {
  if (activeMegaMenu === menuId) {
    // Chiudi se già aperto
    setActiveMegaMenu(null);
  } else {
    // Chiudi precedente, apri nuovo
    setActiveMegaMenu(menuId);
  }
};
```

### Auto-close on Outside Click

```typescript
useEffect(() => {
  const handleClick = (e: MouseEvent) => {
    if (!sidebarRef.current?.contains(e.target as Node) &&
        !megaMenuRef.current?.contains(e.target as Node)) {
      closeMegaMenu();
    }
  };
  document.addEventListener('click', handleClick);
  return () => document.removeEventListener('click', handleClick);
}, []);
```

---

## 🚀 Fasi di Implementazione - Updated

### Phase 1: Multi-Function Structure
- [ ] MultiSidebar component con icone multiple
- [ ] SidebarIcon component con badge
- [ ] SidebarContext per stato globale
- [ ] BaseMegaMenu shared component
- [ ] Toggle logic (solo uno aperto)

### Phase 2: DAM MegaMenu
- [ ] DAM megamenu completo (già spec. sopra)
- [ ] Drag & drop assets
- [ ] Integration con svc-media

### Phase 3: Chat MegaMenu
- [ ] Chat megamenu layout
- [ ] Conversation list
- [ ] Real-time updates (WebSocket)
- [ ] Integration con svc-chat

### Phase 4: Bacheca MegaMenu
- [ ] Bacheca tabs (Feed, Notifiche, Annunci)
- [ ] Activity feed
- [ ] Notifications system
- [ ] Integration con svc-notifications

### Phase 5: Analytics MegaMenu (Optional)
- [ ] Quick metrics dashboard
- [ ] Mini charts
- [ ] Recent reports

---

## ✅ Success Criteria - Updated

- ✅ Sidebar con icone multiple sempre visibile
- ✅ Ogni icona ha il suo megamenu dedicato
- ✅ Solo un megamenu aperto alla volta
- ✅ Badge con count su icone (chat, notifiche)
- ✅ Main content ridotto di 64px
- ✅ Smooth transitions tra megamenu
- ✅ Click outside chiude megamenu
- ✅ DAM: drag & drop funziona ovunque
- ✅ Chat: real-time updates
- ✅ Bacheca: feed activity aggregato

---

**Updated**: 2025-10-15
**Version**: 3.0 - Multi-Function Architecture
**Next Steps**: Implement Phase 1 (Multi-Function Structure)
