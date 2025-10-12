# EWH Enterprise Workspace - Design System

## 📐 Overview

Questo design system garantisce coerenza visiva tra tutte le app dell'Enterprise Workspace:
- **Shell** (app-shell-frontend)
- **DAM** (app-dam)
- **CMS** (app-cms-frontend)
- **Page Builder** (app-page-builder)

## 🎨 Palette Colori

### Light Mode (Day)
```css
--primary: 221.2 83.2% 53.3%        /* Blue - main brand */
--secondary: 210 40% 96.1%          /* Light gray */
--accent: 262.1 83.3% 57.8%         /* Purple - accents */
--success: 142.1 76.2% 36.3%        /* Green */
--warning: 32.1 94.6% 43.7%         /* Orange */
--error: 0 84.2% 60.2%              /* Red */
--info: 199.1 89.5% 48.4%           /* Cyan */
```

### Dark Mode (Night)
```css
--background: 222.2 84% 4.9%        /* Very dark blue-gray */
--primary: 217.2 91.2% 59.8%        /* Lighter blue */
--accent: 263.4 70% 50.4%           /* Adjusted purple */
```

## 🔧 Come Usare

### 1. Import del Design System

In ogni app, importa il design system nel file CSS principale:

```css
/* src/styles/globals.css o src/index.css */
@import url('../../shared/styles/design-system.css');
```

### 2. Tailwind Configuration

Usa la configurazione base condivisa:

```javascript
// tailwind.config.js
const baseConfig = require('../shared/tailwind/tailwind.config.base');

module.exports = {
  ...baseConfig,
  content: [
    './src/**/*.{js,ts,jsx,tsx}',
  ],
};
```

### 3. Utilizzo Classi Tailwind

```tsx
// Background colors
<div className="bg-background">          {/* Main background */}
<div className="bg-background-secondary"> {/* Secondary bg */}

// Text colors
<p className="text-foreground">           {/* Main text */}
<p className="text-foreground-secondary"> {/* Muted text */}

// Brand colors
<button className="bg-primary text-primary-foreground">
<div className="bg-accent text-accent-foreground">

// Semantic colors
<div className="bg-success">  {/* Green */}
<div className="bg-warning">  {/* Orange */}
<div className="bg-error">    {/* Red */}
```

## 🎯 Componenti Pre-stilizzati

### Buttons
```tsx
<button className="btn btn-primary">Primary</button>
<button className="btn btn-secondary">Secondary</button>
<button className="btn btn-ghost">Ghost</button>
<button className="btn btn-outline">Outline</button>
```

### Cards
```tsx
<div className="card">
  <div className="card-header">
    <h3 className="card-title">Title</h3>
    <p className="card-description">Description</p>
  </div>
  <div className="card-content">
    Content here
  </div>
</div>
```

### Inputs
```tsx
<input className="input" type="text" placeholder="Enter text..." />
```

## 🌓 Dark Mode

Il dark mode è gestito tramite classe `dark` sull'elemento `<html>`:

```typescript
// Toggle dark mode
if (theme === 'dark') {
  document.documentElement.classList.add('dark');
} else {
  document.documentElement.classList.remove('dark');
}
```

### Sincronizzazione Tra App

Usa il componente `ShellThemeSync` per sincronizzare il tema dall'app shell:

```tsx
// src/components/ShellThemeSync.tsx
import { ShellThemeSync } from './components/ShellThemeSync';

function App() {
  return (
    <>
      <ShellThemeSync />
      {/* rest of app */}
    </>
  );
}
```

## 📏 Spacing & Radius

### Border Radius
```css
--radius-sm: 0.375rem   /* 6px */
--radius: 0.5rem        /* 8px */
--radius-lg: 0.75rem    /* 12px */
--radius-xl: 1rem       /* 16px */
```

### Shadows
```css
--shadow-sm   /* Subtle */
--shadow      /* Default */
--shadow-md   /* Medium */
--shadow-lg   /* Large */
--shadow-xl   /* Extra large */
```

## 🔍 Utility Classes

### Text Gradient
```tsx
<h1 className="text-gradient">Gradient Text</h1>
```

### Glass Effect
```tsx
<div className="glass">Glass morphism</div>
```

### Elevated (with shadow)
```tsx
<div className="elevated">Elevated card</div>
```

### Custom Scrollbar
```tsx
<div className="scrollbar-thin overflow-auto">
  Long content...
</div>
```

## 📝 Typography

### Font Families
- **Sans**: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, etc.
- **Mono**: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas

### Font Sizes (Tailwind)
- `text-xs`: 0.75rem (12px)
- `text-sm`: 0.875rem (14px)
- `text-base`: 1rem (16px)
- `text-lg`: 1.125rem (18px)
- `text-xl`: 1.25rem (20px)
- `text-2xl`: 1.5rem (24px)
- `text-3xl`: 1.875rem (30px)
- `text-4xl`: 2.25rem (36px)

## 🎬 Animations

```tsx
<div className="animate-fade-in">Fade in</div>
<div className="animate-slide-in">Slide in</div>
<div className="animate-slide-up">Slide up</div>
```

## ✅ Checklist per Nuova App

- [ ] Import `design-system.css` nel CSS principale
- [ ] Estendi `tailwind.config.base.js` in tailwind.config
- [ ] Aggiungi `ShellThemeSync` component
- [ ] Usa classi semantiche (`bg-primary`, `text-foreground`, etc.)
- [ ] Testa dark mode funziona correttamente
- [ ] Verifica coerenza visiva con altre app

## 🔗 File Importanti

- `/shared/styles/design-system.css` - Stili CSS unificati
- `/shared/tailwind/tailwind.config.base.js` - Config Tailwind base
- `/shared/DESIGN_SYSTEM.md` - Questa documentazione

## 🎨 Esempi Visivi

### Layout Tipico
```tsx
<div className="min-h-screen bg-background">
  <header className="border-b border-border bg-card">
    <nav className="container mx-auto p-4">
      {/* Navigation */}
    </nav>
  </header>

  <main className="container mx-auto p-8">
    <div className="card elevated">
      <div className="card-header">
        <h1 className="card-title text-4xl">Title</h1>
        <p className="card-description">Description</p>
      </div>
      <div className="card-content">
        {/* Content */}
      </div>
    </div>
  </main>
</div>
```

### Form Esempio
```tsx
<form className="space-y-4">
  <div>
    <label className="text-sm font-medium text-foreground">Name</label>
    <input className="input mt-1" type="text" />
  </div>

  <div>
    <label className="text-sm font-medium text-foreground">Email</label>
    <input className="input mt-1" type="email" />
  </div>

  <button className="btn btn-primary">Submit</button>
</form>
```

---

**Maintained by**: EWH Development Team
**Last Updated**: 2025-10-10
**Version**: 1.0.0
