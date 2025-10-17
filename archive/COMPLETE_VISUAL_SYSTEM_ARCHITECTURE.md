# Architettura Sistema Visuale Completo
## CMS + Page Builder + Widget Manager + i18n + Knowledge Base

**Created:** 2025-10-09
**Status:** 🎯 Architecture Design
**Scope:** Sistema completo no-code per gestione frontend

---

## 🎯 Obiettivo

**Sistema che permette di:**

1. ✅ Creare/modificare pagine frontend **senza codice** (Elementor-style)
2. ✅ Gestire menu, navigazione, dashboard via **CMS interno**
3. ✅ Widget editabili a **3 livelli** (sistema/utente/utilizzo)
4. ✅ **Multi-lingua** con file traduzione separati
5. ✅ **Knowledge Base** integrata (cassetto + infobox)
6. ✅ Tutto **database-driven** e modificabile runtime

---

## 🏗️ Architettura Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    FRONTEND LAYER                            │
│  ┌────────────────────┐      ┌────────────────────┐         │
│  │ app-admin-frontend │      │ app-web-frontend    │         │
│  │  - CMS Manager     │      │  - Dynamic Pages    │         │
│  │  - Page Builder    │      │  - Custom Dash      │         │
│  │  - Widget Studio   │      │  - User Widgets     │         │
│  └────────┬───────────┘      └─────────┬───────────┘         │
└───────────┼──────────────────────────────┼────────────────────┘
            │                              │
            │         ┌────────────────────┘
            │         │
┌───────────▼─────────▼──────────────────────────────────────┐
│                    API LAYER                                │
│  /api/cms/*          /api/pages/*        /api/widgets/*    │
│  /api/i18n/*         /api/kb/*                             │
└───────────┬────────────────────────────────────────────────┘
            │
┌───────────▼────────────────────────────────────────────────┐
│                  DATABASE LAYER                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │   CMS    │  │  Pages   │  │ Widgets  │  │  i18n    │  │
│  │ Registry │  │ Sections │  │ 3-Level  │  │   KB     │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└────────────────────────────────────────────────────────────┘
```

---

## 📦 Componenti Sistema

### 1. CMS Registry (Gestione Pagine/Menu)

```sql
-- Schema: cms

-- Pagine del sistema
CREATE TABLE cms.pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  page_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,

  -- Hierarchy
  parent_id UUID REFERENCES cms.pages(id),
  path VARCHAR(500) NOT NULL,              -- /admin/dashboard/overview

  -- Type
  page_type VARCHAR(50) NOT NULL,          -- dashboard|admin|settings|landing|custom
  template_id VARCHAR(255),                -- Template to use

  -- Access control
  requires_auth BOOLEAN DEFAULT true,
  allowed_roles TEXT[] DEFAULT '{}',
  permission_required VARCHAR(255),

  -- Frontend target
  frontend_app VARCHAR(50) NOT NULL,       -- admin|web|both

  -- Layout
  layout_type VARCHAR(50) DEFAULT 'default', -- default|fullwidth|sidebar|split

  -- Content
  builder_mode VARCHAR(50) DEFAULT 'visual', -- visual|widget|hybrid|code
  sections JSONB DEFAULT '[]',               -- Elementor sections
  widgets JSONB DEFAULT '[]',                -- Widget grid layout

  -- SEO
  title VARCHAR(255),
  meta_description TEXT,
  meta_keywords TEXT[],
  og_image TEXT,

  -- Status
  status VARCHAR(50) DEFAULT 'draft',        -- draft|published|archived
  published_at TIMESTAMPTZ,

  -- Metadata
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (page_type IN ('dashboard', 'admin', 'settings', 'landing', 'custom', 'workflow', 'report')),
  CHECK (frontend_app IN ('admin', 'web', 'both')),
  CHECK (status IN ('draft', 'published', 'archived'))
);

-- Menu items
CREATE TABLE cms.menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  menu_id VARCHAR(255) NOT NULL,           -- main-menu, admin-menu, user-menu
  item_id VARCHAR(255) NOT NULL,

  -- Hierarchy
  parent_id UUID REFERENCES cms.menu_items(id),
  order_index INTEGER DEFAULT 0,
  depth INTEGER DEFAULT 0,

  -- Display
  label VARCHAR(255) NOT NULL,
  label_i18n_key VARCHAR(255),             -- i18n.menu.dashboard
  icon VARCHAR(100),
  badge TEXT,                              -- "New", "3", "Beta"
  badge_color VARCHAR(50),

  -- Link
  link_type VARCHAR(50) DEFAULT 'page',    -- page|external|action|separator
  page_id UUID REFERENCES cms.pages(id),
  external_url TEXT,
  action_handler TEXT,                     -- JavaScript function name

  -- Behavior
  open_in_new_tab BOOLEAN DEFAULT false,
  requires_auth BOOLEAN DEFAULT true,
  allowed_roles TEXT[] DEFAULT '{}',

  -- Visibility
  visible BOOLEAN DEFAULT true,
  visible_condition TEXT,                  -- JavaScript expression

  -- Frontend target
  frontend_app VARCHAR(50) NOT NULL,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(menu_id, item_id),
  CHECK (link_type IN ('page', 'external', 'action', 'separator')),
  CHECK (frontend_app IN ('admin', 'web', 'both'))
);

-- Navigazione breadcrumb auto-generata
CREATE OR REPLACE FUNCTION cms.get_page_breadcrumbs(p_page_id UUID)
RETURNS TABLE(id UUID, name VARCHAR, slug VARCHAR, path VARCHAR) AS $$
  WITH RECURSIVE breadcrumb AS (
    SELECT id, parent_id, name, slug, path, 0 as level
    FROM cms.pages
    WHERE id = p_page_id

    UNION ALL

    SELECT p.id, p.parent_id, p.name, p.slug, p.path, b.level + 1
    FROM cms.pages p
    JOIN breadcrumb b ON p.id = b.parent_id
  )
  SELECT id, name, slug, path
  FROM breadcrumb
  ORDER BY level DESC;
$$ LANGUAGE SQL;
```

---

### 2. Visual Page Builder (Elementor-Style)

```sql
-- Schema: builder

-- Section definitions (Elementor sections)
CREATE TABLE builder.sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID REFERENCES cms.pages(id) ON DELETE CASCADE,

  -- Order
  section_order INTEGER DEFAULT 0,

  -- Type
  section_type VARCHAR(50) DEFAULT 'full-width', -- full-width|boxed|custom

  -- Layout
  columns_count INTEGER DEFAULT 1,
  columns_layout VARCHAR(50),                    -- 12|6-6|4-8|3-3-3-3|etc

  -- Styling
  background_type VARCHAR(50) DEFAULT 'color',   -- color|gradient|image|video
  background_value TEXT,
  background_overlay JSONB,

  padding_top INTEGER DEFAULT 20,
  padding_bottom INTEGER DEFAULT 20,
  padding_left INTEGER DEFAULT 0,
  padding_right INTEGER DEFAULT 0,

  margin_top INTEGER DEFAULT 0,
  margin_bottom INTEGER DEFAULT 0,

  -- Advanced
  custom_css TEXT,
  custom_classes TEXT[],
  custom_id VARCHAR(255),

  -- Animation
  animation VARCHAR(50),                         -- fade-in|slide-up|etc
  animation_delay INTEGER DEFAULT 0,

  -- Responsive
  hidden_mobile BOOLEAN DEFAULT false,
  hidden_tablet BOOLEAN DEFAULT false,
  hidden_desktop BOOLEAN DEFAULT false,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Columns within sections
CREATE TABLE builder.columns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID REFERENCES builder.sections(id) ON DELETE CASCADE,

  -- Order
  column_order INTEGER DEFAULT 0,

  -- Width (Bootstrap grid 1-12)
  width_desktop INTEGER DEFAULT 12,
  width_tablet INTEGER DEFAULT 12,
  width_mobile INTEGER DEFAULT 12,

  -- Styling
  background_color VARCHAR(50),
  padding JSONB DEFAULT '{"top": 0, "right": 0, "bottom": 0, "left": 0}',

  -- Alignment
  vertical_align VARCHAR(50) DEFAULT 'top',      -- top|middle|bottom|stretch
  horizontal_align VARCHAR(50) DEFAULT 'left',   -- left|center|right

  -- Advanced
  custom_css TEXT,
  custom_classes TEXT[],

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Elements within columns
CREATE TABLE builder.elements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  column_id UUID REFERENCES builder.columns(id) ON DELETE CASCADE,

  -- Order
  element_order INTEGER DEFAULT 0,

  -- Type
  element_type VARCHAR(100) NOT NULL,            -- heading|text|button|image|widget|form|etc

  -- Content
  content JSONB NOT NULL,                        -- Element-specific config

  -- Styling
  margin JSONB DEFAULT '{"top": 0, "right": 0, "bottom": 0, "left": 0}',
  padding JSONB DEFAULT '{"top": 0, "right": 0, "bottom": 0, "left": 0}',

  -- Behavior
  actions JSONB DEFAULT '[]',                    -- Click handlers, hover effects
  animations JSONB DEFAULT '{}',

  -- Visibility
  visible BOOLEAN DEFAULT true,
  visible_condition TEXT,

  -- Responsive
  responsive_config JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Element library (templates)
CREATE TABLE builder.element_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  element_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Type
  element_type VARCHAR(100) NOT NULL,            -- heading|text|button|etc
  category VARCHAR(100) NOT NULL,                -- basic|media|form|widget|advanced

  -- Icon
  icon VARCHAR(100),
  preview_image TEXT,

  -- Default config
  default_config JSONB NOT NULL,

  -- Schema for validation
  config_schema JSONB,

  -- Tags
  tags TEXT[] DEFAULT '{}',

  -- System
  is_system BOOLEAN DEFAULT false,
  is_pro BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 3. Widget System (3 Livelli)

```sql
-- Schema: widgets

-- Widget definitions (Level 1: System)
CREATE TABLE widgets.system_widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  widget_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Type
  category VARCHAR(100) NOT NULL,

  -- Component
  component_path TEXT NOT NULL,
  props_schema JSONB,

  -- Sizing
  default_width INTEGER DEFAULT 6,
  default_height INTEGER DEFAULT 4,
  min_width INTEGER DEFAULT 2,
  min_height INTEGER DEFAULT 2,
  resizable BOOLEAN DEFAULT true,

  -- Capabilities
  realtime_enabled BOOLEAN DEFAULT false,
  configurable BOOLEAN DEFAULT true,

  -- System
  is_system BOOLEAN DEFAULT true,
  version VARCHAR(50) DEFAULT '1.0.0',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User widget overrides (Level 2: User)
CREATE TABLE widgets.user_widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reference
  system_widget_id UUID REFERENCES widgets.system_widgets(id),
  user_id UUID NOT NULL,

  -- Override
  custom_name VARCHAR(255),
  custom_config JSONB DEFAULT '{}',
  custom_styling JSONB DEFAULT '{}',

  -- Defaults
  default_width INTEGER,
  default_height INTEGER,

  -- Favorites
  is_favorite BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(system_widget_id, user_id)
);

-- Widget instances (Level 3: Usage)
CREATE TABLE widgets.widget_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reference
  system_widget_id UUID REFERENCES widgets.system_widgets(id),
  user_widget_id UUID REFERENCES widgets.user_widgets(id),

  -- Location
  page_id UUID REFERENCES cms.pages(id) ON DELETE CASCADE,
  dashboard_id VARCHAR(255),

  -- Grid position
  grid_x INTEGER NOT NULL,
  grid_y INTEGER NOT NULL,
  grid_w INTEGER NOT NULL,
  grid_h INTEGER NOT NULL,

  -- Instance config
  instance_config JSONB DEFAULT '{}',
  instance_styling JSONB DEFAULT '{}',

  -- State
  enabled BOOLEAN DEFAULT true,
  collapsed BOOLEAN DEFAULT false,

  -- Ownership
  owner_user_id UUID,
  owner_tenant_id UUID,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Widget usage example:
-- 1. System defines "metrics-card" widget
-- 2. User John customizes it (blue theme, larger font)
-- 3. John places it on Dashboard page at position (0,0)
-- 4. John places another instance at (6,0) with different config
```

---

### 4. i18n System (Multi-Lingua)

```sql
-- Schema: i18n

-- Supported languages
CREATE TABLE i18n.languages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  language_code VARCHAR(10) UNIQUE NOT NULL,    -- en, it, fr, de, es
  language_name VARCHAR(100) NOT NULL,          -- English, Italiano
  native_name VARCHAR(100) NOT NULL,            -- English, Italiano

  -- Config
  is_default BOOLEAN DEFAULT false,
  is_enabled BOOLEAN DEFAULT true,
  direction VARCHAR(10) DEFAULT 'ltr',          -- ltr|rtl

  -- Metadata
  flag_emoji VARCHAR(10),
  locale VARCHAR(20),                           -- en-US, it-IT

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Translation keys
CREATE TABLE i18n.translation_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Key
  key_path VARCHAR(500) UNIQUE NOT NULL,        -- menu.dashboard, btn.save, error.required

  -- Context
  category VARCHAR(100),                        -- menu|button|error|label|message
  context TEXT,                                 -- Additional context for translators

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Translations
CREATE TABLE i18n.translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reference
  key_id UUID REFERENCES i18n.translation_keys(id) ON DELETE CASCADE,
  language_code VARCHAR(10) REFERENCES i18n.languages(language_code),

  -- Translation
  value TEXT NOT NULL,

  -- Plurals (for languages that need it)
  value_plural TEXT,
  plural_rule VARCHAR(50),                      -- one|few|many

  -- Status
  status VARCHAR(50) DEFAULT 'draft',           -- draft|translated|reviewed|approved
  translated_by UUID,
  reviewed_by UUID,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(key_id, language_code)
);

-- Translation file export/import
CREATE OR REPLACE FUNCTION i18n.export_language(p_language_code VARCHAR)
RETURNS JSONB AS $$
  SELECT jsonb_object_agg(
    tk.key_path,
    t.value
  )
  FROM i18n.translations t
  JOIN i18n.translation_keys tk ON t.key_id = tk.id
  WHERE t.language_code = p_language_code
    AND t.status = 'approved';
$$ LANGUAGE SQL;

-- Usage:
-- SELECT i18n.export_language('it');
-- Returns: {"menu.dashboard": "Cruscotto", "btn.save": "Salva", ...}
```

---

### 5. Knowledge Base System (KB + Infobox)

```sql
-- Schema: kb

-- KB Articles (Cassetto laterale)
CREATE TABLE kb.articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  article_id VARCHAR(255) UNIQUE NOT NULL,
  title VARCHAR(500) NOT NULL,
  slug VARCHAR(500) NOT NULL,

  -- Content
  content TEXT NOT NULL,                        -- Markdown
  content_format VARCHAR(50) DEFAULT 'markdown', -- markdown|html

  -- Hierarchy
  category VARCHAR(100),
  parent_id UUID REFERENCES kb.articles(id),
  order_index INTEGER DEFAULT 0,

  -- Context
  related_pages TEXT[],                         -- page_ids
  related_features TEXT[],
  keywords TEXT[],

  -- Media
  thumbnail TEXT,
  attachments JSONB DEFAULT '[]',

  -- i18n
  language_code VARCHAR(10) DEFAULT 'en',
  translations JSONB DEFAULT '{}',              -- {it: article_id, fr: article_id}

  -- Metadata
  author_id UUID,
  views_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  not_helpful_count INTEGER DEFAULT 0,

  -- Status
  status VARCHAR(50) DEFAULT 'draft',
  published_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Infobox (Tooltip/Help accanto ai pulsanti)
CREATE TABLE kb.infoboxes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identity
  infobox_id VARCHAR(255) UNIQUE NOT NULL,

  -- Target (dove appare)
  target_type VARCHAR(50) NOT NULL,             -- button|field|section|page
  target_element VARCHAR(255) NOT NULL,         -- CSS selector o element ID
  page_path VARCHAR(500),                       -- /admin/dashboard

  -- Content
  title VARCHAR(255),
  content TEXT NOT NULL,
  content_format VARCHAR(50) DEFAULT 'markdown',

  -- Style
  position VARCHAR(50) DEFAULT 'right',         -- top|right|bottom|left|auto
  trigger VARCHAR(50) DEFAULT 'hover',          -- hover|click|focus
  icon VARCHAR(100),
  variant VARCHAR(50) DEFAULT 'info',           -- info|warning|tip|video

  -- Link to full article
  kb_article_id UUID REFERENCES kb.articles(id),

  -- i18n
  language_code VARCHAR(10) DEFAULT 'en',
  translations JSONB DEFAULT '{}',

  -- Visibility
  visible BOOLEAN DEFAULT true,
  visible_for_roles TEXT[],
  show_once BOOLEAN DEFAULT false,              -- Mostra una sola volta per utente

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User interactions tracking
CREATE TABLE kb.user_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  user_id UUID NOT NULL,

  -- Article interactions
  article_id UUID REFERENCES kb.articles(id),
  interaction_type VARCHAR(50) NOT NULL,        -- view|helpful|not_helpful|bookmark

  -- Infobox interactions
  infobox_id UUID REFERENCES kb.infoboxes(id),
  dismissed BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🎨 UI Components

### Page Builder Interface

```
┌──────────────────────────────────────────────────────────────┐
│  📄 Page: Admin Dashboard                        [Save] [👁]  │
├─────────┬────────────────────────────────────────┬───────────┤
│         │                                        │           │
│ + Sect  │  ┌────────────────────────────────┐   │ Section   │
│ + Col   │  │ Section 1 (Full Width)      [⚙]│   │  Type:    │
│ + Elem  │  │  ├─ Column 1 (6/12)            │   │  □ Full   │
│ + Widget│  │  │  □ Heading: "Dashboard"     │   │  □ Boxed  │
│         │  │  │  □ Text: "Welcome back..."  │   │           │
│ Elements│  │  ├─ Column 2 (6/12)            │   │  BG:      │
│  □ Head │  │  │  ⊞ Widget: Metrics Cards    │   │  [#...]   │
│  □ Text │  │  └─                            │   │           │
│  □ Btn  │  └────────────────────────────────┘   │  Padding: │
│  □ Img  │                                        │  [20px]   │
│  □ Form │  ┌────────────────────────────────┐   │           │
│         │  │ Section 2 (Boxed)            [⚙]│   └───────────┘
│ Widgets │  │  ├─ Column 1 (12/12)           │
│  ⊞ Metr │  │  │  ⊞ Widget: Service Status   │
│  ⊞ Chart│  │  │  ⊞ Widget: Recent Activity  │
│  ⊞ Table│  │  └─                            │
│         │  └────────────────────────────────┘
│         │         [+ Add Section]
└─────────┴────────────────────────────────────────┴───────────┘
```

### CMS Menu Manager

```
┌──────────────────────────────────────────────────────────────┐
│  Menu: Admin Main Menu                       [+ Add Item]    │
├──────────────────────────────────────────────────────────────┤
│  □ Dashboard              [↑] [↓] [Edit] [Delete]            │
│  □ Monitoring             [↑] [↓] [Edit] [Delete]            │
│    ├─ Enterprise View                                        │
│    ├─ Services Health                                        │
│    └─ Metrics Config                                         │
│  □ Infrastructure         [↑] [↓] [Edit] [Delete]            │
│  □ Creative Studio        [↑] [↓] [Edit] [Delete]            │
│    ├─ Asset Management                                       │
│    ├─ Image Editor                                           │
│    └─ Video Studio                                           │
│                                                              │
│  [Drag to reorder]                                           │
└──────────────────────────────────────────────────────────────┘
```

### Widget Studio (3-Level)

```
┌──────────────────────────────────────────────────────────────┐
│  Widget: Metrics Card                                        │
├──────────────────────────────────────────────────────────────┤
│  Level 1: System (Read-only)                                │
│    Component: MetricsCardWidget.tsx                         │
│    Default size: 6x4                                         │
│    [View Source]                                             │
│                                                              │
│  Level 2: Your Customization                                │
│    Name: [My Custom Metrics      ]                          │
│    Theme: [Blue Gradient ▼]                                 │
│    Font Size: [16px]                                         │
│    Default Config:                                           │
│      { "showIcon": true, "animateValue": true }             │
│    [Save Customization]                                      │
│                                                              │
│  Level 3: Instances on Pages                                │
│    • Dashboard → (0,0) - Sales Metrics                      │
│    • Dashboard → (6,0) - User Growth                        │
│    • Analytics → (0,4) - Revenue                            │
│    [Manage Instances]                                        │
└──────────────────────────────────────────────────────────────┘
```

### Knowledge Base Drawer

```
┌──────────────────────────────────────────────────────────────┐
│  Admin Dashboard                            [?] [🌐 IT ▼]    │
├──────────────────────────────────────────────────────────────┤
│  [Your dashboard content here...]                            │
│                                                              │
│                                 ┌────────────────────────┐   │
│  [Button with (?) infobox] ──→  │ 💡 Quick Tip           │   │
│                                 │ This button saves your │   │
│                                 │ current configuration  │   │
│                                 │ [Learn More →]         │   │
│                                 └────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘

[Click ? to open drawer]

┌──────────────────────────────────────────────────────────────┐
│                                 │  📚 Help                   │
│                                 ├────────────────────────────┤
│  [Your content...]              │  🔍 [Search help...]       │
│                                 │                            │
│                                 │  Related to this page:     │
│                                 │  □ How to use Dashboard    │
│                                 │  □ Understanding Metrics   │
│                                 │  □ Customizing Widgets     │
│                                 │                            │
│                                 │  Popular articles:         │
│                                 │  □ Getting Started         │
│                                 │  □ User Management         │
│                                 │                            │
│                                 │  🎥 Video Tutorials        │
│                                 │  [▶ Dashboard Overview]    │
└─────────────────────────────────┴────────────────────────────┘
```

---

## 🚀 Implementation Roadmap

### Phase 1: CMS Foundation (Week 1-2)
- ✅ Migration: CMS tables
- ✅ API: CRUD pagine/menu
- ✅ UI: CMS Manager base

### Phase 2: Visual Page Builder (Week 3-4)
- ✅ Migration: Builder tables
- ✅ Component: Elementor-style builder
- ✅ Element library (10+ elementi base)

### Phase 3: Widget System (Week 5-6)
- ✅ Migration: 3-level widgets
- ✅ UI: Widget Studio
- ✅ Integration con Page Builder

### Phase 4: i18n System (Week 7)
- ✅ Migration: i18n tables
- ✅ Export/Import file traduzione
- ✅ UI: Translation Manager

### Phase 5: Knowledge Base (Week 8)
- ✅ Migration: KB tables
- ✅ Component: Drawer + Infobox
- ✅ UI: KB Editor

### Phase 6: Integration & Polish (Week 9-10)
- ✅ Connect tutto insieme
- ✅ Testing end-to-end
- ✅ Documentation

---

## 🎯 Deliverable Finale

**Sistema completo zero-code per:**

1. ✅ Creare pagine drag-and-drop (Elementor)
2. ✅ Gestire menu navigazione (CMS)
3. ✅ Personalizzare widget (3 livelli)
4. ✅ Tradurre in multiple lingue (i18n)
5. ✅ Documentare features (KB inline)

**Tutto database-driven, modificabile runtime, senza rebuild!**

---

Non ti faccio impazzire, mi **esalti**! 🚀 È un sistema complesso ma **estremamente potente** e ben architettato.
