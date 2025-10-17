# 🎨 app-box-designer - Frontend Standards

**App Name:** app-box-designer
**Port:** 5800 (frontend)
**Version:** 2.0.0
**Follows:** [DEVELOPMENT_STANDARDS_2025.md](../DEVELOPMENT_STANDARDS_2025.md)

---

## 📁 STRUTTURA CARTELLE STANDARD

```
app-box-designer/
├── src/
│   ├── main.tsx                    # Entry point
│   ├── App.tsx                     # Root component
│   │
│   ├── components/                 # Componenti riutilizzabili
│   │   ├── Layout.tsx             # Layout principale
│   │   ├── ui/                    # UI primitives (Button, Input, etc.)
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   ├── Modal.tsx
│   │   │   ├── Tabs.tsx
│   │   │   └── Tooltip.tsx
│   │   │
│   │   ├── cad/                   # CAD-specific components
│   │   │   ├── CADCanvas.tsx     # Main canvas
│   │   │   ├── CADToolbar.tsx    # Toolbar with tools
│   │   │   ├── CADStatusBar.tsx  # Status bar bottom
│   │   │   ├── CADCommandLine.tsx # Command input
│   │   │   ├── CADPropertiesPanel.tsx
│   │   │   ├── CADLayersPanel.tsx
│   │   │   └── CADLibraryPanel.tsx
│   │   │
│   │   ├── packaging/             # Packaging-specific
│   │   │   ├── TemplateGallery.tsx
│   │   │   ├── Dieline3DViewer.tsx
│   │   │   ├── NestingViewer.tsx
│   │   │   ├── MaterialSelector.tsx
│   │   │   └── CostCalculator.tsx
│   │   │
│   │   └── shared/                # Shared across app
│   │       ├── Header.tsx
│   │       ├── Sidebar.tsx
│   │       └── Footer.tsx
│   │
│   ├── features/                  # Feature-based organization
│   │   ├── drawings/             # Drawings management
│   │   │   ├── DrawingsList.tsx
│   │   │   ├── DrawingDetail.tsx
│   │   │   ├── DrawingForm.tsx
│   │   │   └── useDrawings.ts   # Custom hook
│   │   │
│   │   ├── templates/            # Templates
│   │   │   ├── TemplatesList.tsx
│   │   │   ├── TemplateCard.tsx
│   │   │   └── useTemplates.ts
│   │   │
│   │   ├── export/               # Export feature
│   │   │   ├── ExportDialog.tsx
│   │   │   ├── ExportOptions.tsx
│   │   │   └── useExport.ts
│   │   │
│   │   └── settings/             # Settings
│   │       ├── TenantSettings.tsx
│   │       ├── UserSettings.tsx
│   │       └── AdminSettings.tsx
│   │
│   ├── cad-engine/               # CAD Engine (separato)
│   │   ├── core/
│   │   │   ├── CADEngine.ts     # Main engine class
│   │   │   ├── Canvas.ts        # Canvas abstraction
│   │   │   ├── Renderer.ts      # Rendering engine
│   │   │   ├── History.ts       # Undo/redo
│   │   │   └── Selection.ts     # Selection manager
│   │   │
│   │   ├── tools/               # CAD Tools
│   │   │   ├── Tool.ts          # Base tool class
│   │   │   ├── SelectTool.ts
│   │   │   ├── LineTool.ts
│   │   │   ├── RectangleTool.ts
│   │   │   ├── CircleTool.ts
│   │   │   ├── ArcTool.ts
│   │   │   ├── TrimTool.ts
│   │   │   ├── OffsetTool.ts
│   │   │   └── ...
│   │   │
│   │   ├── objects/             # CAD Objects
│   │   │   ├── CADObject.ts     # Base object
│   │   │   ├── Line.ts
│   │   │   ├── Circle.ts
│   │   │   ├── Arc.ts
│   │   │   ├── Rectangle.ts
│   │   │   └── ...
│   │   │
│   │   ├── geometry/            # Geometry algorithms
│   │   │   ├── intersections.ts
│   │   │   ├── offset.ts
│   │   │   ├── fillet.ts
│   │   │   ├── transforms.ts
│   │   │   └── measurements.ts
│   │   │
│   │   ├── constraints/         # Parametric constraints
│   │   │   ├── Constraint.ts
│   │   │   ├── ParallelConstraint.ts
│   │   │   ├── PerpendicularConstraint.ts
│   │   │   └── ...
│   │   │
│   │   └── utils/
│   │       ├── snap.ts          # Snap system
│   │       ├── grid.ts          # Grid drawing
│   │       └── helpers.ts
│   │
│   ├── services/                 # API clients
│   │   ├── api.ts               # Base API client (axios)
│   │   ├── drawingsApi.ts       # Drawings endpoints
│   │   ├── templatesApi.ts      # Templates endpoints
│   │   ├── exportApi.ts         # Export endpoints
│   │   ├── nestingApi.ts        # Nesting endpoints
│   │   └── settingsApi.ts       # Settings endpoints
│   │
│   ├── hooks/                   # Custom React hooks
│   │   ├── useAuth.ts
│   │   ├── useDrawings.ts
│   │   ├── useTemplates.ts
│   │   ├── useExport.ts
│   │   ├── useCADEngine.ts
│   │   └── useKeyboardShortcuts.ts
│   │
│   ├── stores/                  # Zustand stores
│   │   ├── cadStore.ts          # CAD state (current tool, etc.)
│   │   ├── drawingStore.ts      # Drawing data
│   │   ├── uiStore.ts           # UI state (panels visibility)
│   │   └── settingsStore.ts     # Settings cache
│   │
│   ├── lib/                     # Utilities
│   │   ├── constants.ts         # App constants
│   │   ├── utils.ts             # Helper functions
│   │   ├── validation.ts        # Zod schemas
│   │   └── formatters.ts        # Format numbers, dates
│   │
│   ├── types/                   # TypeScript types
│   │   ├── cad.types.ts
│   │   ├── packaging.types.ts
│   │   ├── api.types.ts
│   │   └── index.ts
│   │
│   ├── assets/                  # Static assets
│   │   ├── icons/
│   │   ├── images/
│   │   └── fonts/
│   │
│   ├── styles/                  # Global styles
│   │   ├── index.css           # Tailwind imports + global
│   │   └── variables.css       # CSS variables
│   │
│   └── locales/                # i18n translations
│       ├── it.json
│       ├── en.json
│       ├── fr.json
│       └── de.json
│
├── public/
│   ├── index.html
│   └── favicon.ico
│
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.js
├── postcss.config.js
├── .env.example
└── README.md
```

---

## 🎨 TECH STACK

### Core
- **React:** 18.2+
- **TypeScript:** 5.0+
- **Vite:** 5.0+
- **React Router:** 6.x (routing)

### Styling
- **Tailwind CSS:** 3.x (utility-first)
- **PostCSS:** Autoprefixer

### State Management
- **Zustand:** 4.x (global state)
- **Tanstack Query:** 5.x (server state / API cache)
- **Immer:** (immutable state)

### Canvas / Graphics
- **Fabric.js:** 5.x (2D canvas library) o **Konva.js** 9.x
- **Three.js:** 0.160+ (3D preview)
- **@react-three/fiber:** React wrapper per Three.js

### Forms & Validation
- **React Hook Form:** 7.x
- **Zod:** 3.x (validation schema)

### UI Components
- **Radix UI:** Primitives headless (Dialog, Dropdown, Tooltip, etc.)
- **Lucide React:** Icons

### Utils
- **clsx + tailwind-merge:** Conditional classes
- **date-fns:** Date formatting
- **i18next:** Internationalization

---

## 🎯 COMPONENT PATTERNS

### Component Naming
```tsx
// ✅ PascalCase, descriptive
components/CADCanvas.tsx
components/ui/Button.tsx
features/drawings/DrawingsList.tsx

// ❌ Wrong
components/cad-canvas.tsx  // kebab-case
components/canvas.tsx      // too generic
```

### Component Structure
```tsx
// CADCanvas.tsx
import React, { useRef, useEffect } from 'react';
import { useCADEngine } from '@/hooks/useCADEngine';
import { CADToolbar } from './CADToolbar';

interface CADCanvasProps {
  drawingId?: string;
  onSave?: (data: any) => void;
}

export function CADCanvas({ drawingId, onSave }: CADCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const { engine, initEngine } = useCADEngine();

  useEffect(() => {
    if (canvasRef.current) {
      initEngine(canvasRef.current);
    }
  }, []);

  return (
    <div className="flex flex-col h-full">
      <CADToolbar engine={engine} />

      <div className="flex-1 relative overflow-hidden">
        <canvas
          ref={canvasRef}
          className="w-full h-full cursor-crosshair"
        />
      </div>

      <div className="bg-gray-800 text-white px-4 py-2 text-sm">
        Status: Ready | Tool: Line | Snap: Grid
      </div>
    </div>
  );
}
```

### Custom Hooks Pattern
```tsx
// hooks/useDrawings.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { drawingsApi } from '@/services/drawingsApi';

export function useDrawings() {
  const queryClient = useQueryClient();

  const { data: drawings, isLoading } = useQuery({
    queryKey: ['drawings'],
    queryFn: () => drawingsApi.list()
  });

  const createMutation = useMutation({
    mutationFn: drawingsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['drawings'] });
    }
  });

  return {
    drawings: drawings?.data || [],
    isLoading,
    createDrawing: createMutation.mutate,
    isCreating: createMutation.isPending
  };
}
```

### Zustand Store Pattern
```tsx
// stores/cadStore.ts
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface CADState {
  currentTool: string;
  snapToGrid: boolean;
  showGrid: boolean;
  zoom: number;
  selectedObjects: string[];

  // Actions
  setCurrentTool: (tool: string) => void;
  toggleSnapToGrid: () => void;
  toggleGrid: () => void;
  setZoom: (zoom: number) => void;
  selectObject: (id: string) => void;
  deselectAll: () => void;
}

export const useCADStore = create<CADState>()(
  immer((set) => ({
    currentTool: 'select',
    snapToGrid: true,
    showGrid: true,
    zoom: 1,
    selectedObjects: [],

    setCurrentTool: (tool) => set((state) => {
      state.currentTool = tool;
    }),

    toggleSnapToGrid: () => set((state) => {
      state.snapToGrid = !state.snapToGrid;
    }),

    toggleGrid: () => set((state) => {
      state.showGrid = !state.showGrid;
    }),

    setZoom: (zoom) => set((state) => {
      state.zoom = Math.max(0.1, Math.min(10, zoom));
    }),

    selectObject: (id) => set((state) => {
      if (!state.selectedObjects.includes(id)) {
        state.selectedObjects.push(id);
      }
    }),

    deselectAll: () => set((state) => {
      state.selectedObjects = [];
    })
  }))
);
```

---

## 🎨 STYLING GUIDELINES

### Tailwind Usage
```tsx
// ✅ Good - Tailwind classes
<button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition">
  Save
</button>

// ✅ Good - Conditional classes with clsx
<div className={clsx(
  'panel',
  isActive && 'border-blue-500',
  isLocked && 'opacity-50 cursor-not-allowed'
)}>
  Content
</div>

// ❌ Bad - Inline styles
<button style={{ backgroundColor: 'blue', padding: '8px 16px' }}>
  Save
</button>
```

### Color Scheme
```css
/* styles/variables.css */
:root {
  /* Background */
  --bg-canvas: #1e1e1e;
  --bg-panel: #2d2d2d;
  --bg-toolbar: #3c3c3c;

  /* Text */
  --text-primary: #ffffff;
  --text-secondary: #b0b0b0;
  --text-muted: #808080;

  /* UI */
  --border: #404040;
  --accent: #3b82f6;
  --success: #10b981;
  --warning: #f59e0b;
  --error: #ef4444;

  /* CAD specific */
  --line-cut: #ff0000;
  --line-crease: #0000ff;
  --line-perforation: #ff00ff;
  --line-bleed: #00ff00;
  --line-dimension: #000000;
}
```

### Dark Mode (default)
```tsx
// Usa Tailwind dark: prefix per light mode (se implementi)
<div className="bg-gray-900 dark:bg-white text-white dark:text-black">
  Content
</div>
```

---

## 🔌 API INTEGRATION

### API Client Setup
```typescript
// services/api.ts
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3800';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor (add token)
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor (handle errors)
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Redirect to login
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

### Service Layer
```typescript
// services/drawingsApi.ts
import { apiClient } from './api';
import type { Drawing, CreateDrawingRequest } from '@/types/api.types';

export const drawingsApi = {
  list: async (params?: { limit?: number; offset?: number }) => {
    const { data } = await apiClient.get<{ success: boolean; data: Drawing[] }>(
      '/api/cad/drawings',
      { params }
    );
    return data;
  },

  get: async (id: string) => {
    const { data } = await apiClient.get<{ success: boolean; data: Drawing }>(
      `/api/cad/drawings/${id}`
    );
    return data.data;
  },

  create: async (request: CreateDrawingRequest) => {
    const { data } = await apiClient.post<{ success: boolean; data: Drawing }>(
      '/api/cad/drawings',
      request
    );
    return data.data;
  },

  update: async (id: string, request: Partial<CreateDrawingRequest>) => {
    const { data } = await apiClient.put<{ success: boolean; data: Drawing }>(
      `/api/cad/drawings/${id}`,
      request
    );
    return data.data;
  },

  delete: async (id: string) => {
    await apiClient.delete(`/api/cad/drawings/${id}`);
  }
};
```

---

## ⌨️ KEYBOARD SHORTCUTS

### Implementation
```tsx
// hooks/useKeyboardShortcuts.ts
import { useEffect } from 'react';
import { useCADStore } from '@/stores/cadStore';

export function useKeyboardShortcuts() {
  const { setCurrentTool, toggleSnapToGrid, toggleGrid } = useCADStore();

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore if typing in input
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
        return;
      }

      // Tool shortcuts
      if (e.key === 'l') setCurrentTool('line');
      if (e.key === 'c') setCurrentTool('circle');
      if (e.key === 'r') setCurrentTool('rectangle');
      if (e.key === 'a') setCurrentTool('arc');
      if (e.key === 't') setCurrentTool('trim');

      // View shortcuts
      if (e.key === 'F9') toggleSnapToGrid();
      if (e.key === 'F7') toggleGrid();

      // Undo/Redo
      if (e.ctrlKey || e.metaKey) {
        if (e.key === 'z') {
          e.preventDefault();
          // Call undo
        }
        if (e.key === 'y') {
          e.preventDefault();
          // Call redo
        }
      }

      // Escape = cancel operation
      if (e.key === 'Escape') {
        setCurrentTool('select');
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);
}
```

### Shortcuts List
```
Tools:
  L - Line
  R - Rectangle
  C - Circle
  A - Arc
  T - Trim
  O - Offset
  F - Fillet
  M - Mirror
  Esc - Select (cancel)

View:
  F7 - Toggle Grid
  F9 - Toggle Snap
  Z - Zoom window
  E - Zoom extents
  Mouse Wheel - Zoom in/out
  Space+Drag - Pan

Edit:
  Ctrl+C - Copy
  Ctrl+V - Paste
  Ctrl+Z - Undo
  Ctrl+Y - Redo
  Ctrl+A - Select All
  Del - Delete
```

---

## 🌍 INTERNATIONALIZATION

### Setup
```typescript
// src/i18n.ts
import i18next from 'i18next';
import { initReactI18next } from 'react-i18next';

import en from './locales/en.json';
import it from './locales/it.json';

i18next
  .use(initReactI18next)
  .init({
    resources: {
      en: { translation: en },
      it: { translation: it }
    },
    lng: localStorage.getItem('language') || 'it',
    fallbackLng: 'en',
    interpolation: {
      escapeValue: false
    }
  });

export default i18next;
```

### Translation Files
```json
// locales/it.json
{
  "common": {
    "save": "Salva",
    "cancel": "Annulla",
    "delete": "Elimina",
    "loading": "Caricamento..."
  },
  "cad": {
    "tools": {
      "line": "Linea",
      "rectangle": "Rettangolo",
      "circle": "Cerchio",
      "select": "Seleziona"
    },
    "status": {
      "ready": "Pronto",
      "drawing": "Disegno in corso"
    }
  },
  "drawings": {
    "list_title": "I miei disegni",
    "create_new": "Crea nuovo disegno",
    "delete_confirm": "Eliminare questo disegno?"
  }
}
```

### Usage
```tsx
import { useTranslation } from 'react-i18next';

function ToolButton() {
  const { t } = useTranslation();

  return (
    <button>
      {t('cad.tools.line')}
    </button>
  );
}
```

---

## 📦 ENVIRONMENT VARIABLES

### `.env.example`
```bash
# API
VITE_API_URL=http://localhost:3800
VITE_API_GATEWAY_URL=http://localhost:5000

# Features
VITE_ENABLE_3D_PREVIEW=true
VITE_ENABLE_NESTING=true
VITE_ENABLE_COST_CALC=true

# Debug
VITE_DEBUG=false
```

### Usage
```typescript
const API_URL = import.meta.env.VITE_API_URL;
const ENABLE_3D = import.meta.env.VITE_ENABLE_3D_PREVIEW === 'true';
```

---

## 🧪 TESTING

### Component Tests (Vitest + Testing Library)
```typescript
// components/ui/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { Button } from './Button';

describe('Button', () => {
  it('renders correctly', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    fireEvent.click(screen.getByText('Click me'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

---

## 📊 PERFORMANCE

### Code Splitting
```tsx
// Lazy load routes
import { lazy, Suspense } from 'react';

const DrawingsList = lazy(() => import('@/features/drawings/DrawingsList'));
const CADCanvas = lazy(() => import('@/components/cad/CADCanvas'));

function App() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <Routes>
        <Route path="/drawings" element={<DrawingsList />} />
        <Route path="/editor/:id" element={<CADCanvas />} />
      </Routes>
    </Suspense>
  );
}
```

### Memoization
```tsx
import { memo, useMemo, useCallback } from 'react';

// Memoize component
export const CADObject = memo(({ object }: { object: any }) => {
  return <div>{object.type}</div>;
});

// Memoize expensive computation
const expensiveValue = useMemo(() => {
  return computeExpensiveThing(data);
}, [data]);

// Memoize callback
const handleClick = useCallback(() => {
  doSomething(data);
}, [data]);
```

---

## ✅ CHECKLIST NUOVO COMPONENTE

- [ ] Segue naming conventions (PascalCase)
- [ ] TypeScript props interface definito
- [ ] Usa Tailwind per styling
- [ ] Responsive (mobile-friendly)
- [ ] Accessible (ARIA labels)
- [ ] i18n per testi (useTranslation)
- [ ] Test scritto (Vitest)
- [ ] Performance OK (memo se necessario)

---

**Documento:** `FRONTEND_STANDARDS.md`
**Seguire:** [DEVELOPMENT_STANDARDS_2025.md](../DEVELOPMENT_STANDARDS_2025.md)
