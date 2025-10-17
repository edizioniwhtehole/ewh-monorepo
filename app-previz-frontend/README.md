# Pre-visualization Frontend (app-previz-frontend)

Applicazione React per la pre-visualizzazione 3D, storyboarding e planning di scene.

## Quick Start

### 1. Installazione

```bash
cd app-previz-frontend
npm install
```

### 2. Avvio

```bash
npm run dev
```

L'applicazione sarà disponibile su: http://localhost:5801

## Features

### Scene Editor
- Viewport 3D interattivo (Three.js)
- Drag & drop oggetti
- Transform controls
- Wireframe/Shaded/Textured/Realistic modes

### Storyboard
- Gestione shots
- Sequencing
- Thumbnail preview
- Export PDF/video

### Library
- Catalogo props
- AI generation
- Categorizzazione
- Import/Upload

### Settings
- Configurazione render
- Units preference
- Webhook management

## Tech Stack

- **React 18** - UI framework
- **Vite** - Build tool
- **TypeScript** - Type safety
- **Three.js** - 3D rendering
- **React Three Fiber** - React renderer per Three.js
- **@react-three/drei** - Helpers 3D
- **Zustand** - State management
- **TanStack Query** - Data fetching
- **Tailwind CSS** - Styling
- **Lucide React** - Icons

## Struttura

```
app-previz-frontend/
├── src/
│   ├── components/      # UI components
│   │   └── Layout.tsx
│   ├── pages/          # Page components
│   │   ├── ScenesPage.tsx
│   │   ├── SceneEditorPage.tsx
│   │   ├── StoryboardsPage.tsx
│   │   ├── StoryboardEditorPage.tsx
│   │   ├── LibraryPage.tsx
│   │   └── SettingsPage.tsx
│   ├── services/       # API clients
│   ├── hooks/          # Custom hooks
│   ├── types/          # TypeScript types
│   ├── utils/          # Utilities
│   ├── App.tsx         # Main app
│   └── main.tsx        # Entry point
├── index.html
├── package.json
├── vite.config.ts
└── tailwind.config.js
```

## Prossimi Step

### Phase 1: 3D Viewport
- [ ] Implementare Three.js scene
- [ ] Camera controls (OrbitControls)
- [ ] Grid system
- [ ] Transform gizmos
- [ ] Object selection

### Phase 2: Scene Objects
- [ ] Character loader
- [ ] Props loader
- [ ] Lights visualization
- [ ] Camera frustum preview

### Phase 3: Tools
- [ ] Properties panel
- [ ] Object hierarchy
- [ ] Asset browser
- [ ] AI generation UI

### Phase 4: Storyboard
- [ ] Shot thumbnail generator
- [ ] Timeline editor
- [ ] Export dialog

## Sviluppo

L'applicazione è attualmente in fase di sviluppo con UI placeholder. Per implementare le funzionalità:

1. Implementare Three.js scene in SceneEditorPage
2. Creare API client services
3. Aggiungere state management con Zustand
4. Implementare drag & drop
5. Aggiungere form validation
6. Implementare export functionality

## Build

```bash
npm run build
```

L'output sarà in `dist/`

## License

Proprietario - EWH Platform
