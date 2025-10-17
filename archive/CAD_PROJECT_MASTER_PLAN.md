# 📐 CAD System - Master Plan & Index

**Created:** 16 Ottobre 2025
**Version:** 2.0
**Status:** Specifications Complete - Implementation Ready

---

## 🎯 PROGETTO OVERVIEW

### Obiettivo
Creare un **sistema CAD completo e professionale** in 2 fasi:

1. **CAD Generico** - Fusion 360 / OnShape style (disegno tecnico 2D parametrico)
2. **CAD Cartotecnica** - Specializzazione per packaging (scatole, espositori, fustelle)

### Principi Guida
- ✅ **API-First** - Backend espone API REST, frontend thin client
- ✅ **Sincerità Brutale** - Track reale progress, problemi evidenti
- ✅ **Standard EWH** - Segue architettura platform (multi-tenant, i18n, webhooks)
- ✅ **Testing Continuo** - Test dopo ogni funzione implementata

---

## 📚 DOCUMENTAZIONE CREATA

### 1. Specifiche Tecniche

#### [svc-box-designer/CAD_SYSTEM_SPECIFICATION.md](svc-box-designer/CAD_SYSTEM_SPECIFICATION.md)
**CAD Generico - Fusion 360 Style**

Contenuto:
- 12 categorie funzionali (Oggetti Base, Modifica, Constraints, Layers, Snap, View, Measurements, Import/Export, History, UI/UX, Collaboration, Settings)
- 200+ funzioni dettagliate
- 3 TIER implementazione (MVP Base, Professional, Expert)
- Stima: 50-65 giorni full-time
- Tech stack completo

**Sezioni principali:**
- CORE - Oggetti Base (Line, Rectangle, Circle, Arc, Polygon, Ellipse, Spline)
- MODIFICA - Tools (Select, Move, Copy, Rotate, Scale, Mirror, Trim, Offset, Fillet, Array)
- CONSTRAINTS - Parametrici (Parallel, Perpendicular, Tangent, Dimensions, Equations)
- LAYERS & ORGANIZATION
- SNAP & GRID - Precisione
- VIEW & NAVIGATION
- MEASUREMENTS - Analisi
- IMPORT/EXPORT - DXF, SVG, PDF, JSON
- HISTORY & UNDO
- UI & UX
- COLLABORATION
- SETTINGS

---

#### [svc-box-designer/CAD_PACKAGING_SPECIFICATION.md](svc-box-designer/CAD_PACKAGING_SPECIFICATION.md)
**CAD Cartotecnica Specializzato**

Contenuto:
- 12 categorie specifiche packaging
- Template library (20+ scatole FEFCO)
- Line types cartotecnica (cut, crease, perforation, bleed)
- 3D folding & preview
- Calcoli tecnici (flat size, weight, cost, nesting)
- Constraints produttivi
- Artwork integration
- Export formati industry (DXF, CF2, PDF/X-4)
- Stima: 65-80 giorni full-time

**Sezioni principali:**
- TEMPLATE LIBRARY - 20+ scatole standard (4-corner, tray, sleeve, pillow, display, etc.)
- LINE TYPES - Standard ECMA (cut, crease, perforation, bleed, dimension)
- 3D PREVIEW - Fold simulation, animation, material rendering
- CALCULATIONS - Flat size, weight, volume, nesting, cost
- CONSTRAINTS - Manufacturing (min flap, max score, fiber direction)
- ARTWORK - Print areas, bleed, color separation
- DIELINE EXPORT - DXF, CF2, PDF/X-4, AI/EPS, STEP/IGES
- LIBRARY MANAGEMENT - Template database, cloud sync
- MACHINE DATABASE - Die cutters, folder-gluers, materials
- QUALITY CONTROL - DRC, printability check, structural integrity
- PROTOTYPING - Print & fold, 3D PDF
- SPECIAL FEATURES - Handles, windows, locking, perforation

---

#### [svc-box-designer/CAD_IMPLEMENTATION_CHECKLIST.md](svc-box-designer/CAD_IMPLEMENTATION_CHECKLIST.md)
**Checklist Dettagliata Implementazione**

Contenuto:
- Checklist completa tutte le funzioni (⬜ TODO, 🟨 IN PROGRESS, ✅ DONE, ❌ FAILED, 🔧 REFACTOR NEEDED)
- Assessment sincero stato attuale (~7% completato)
- Problemi critici identificati (algoritmi mancanti, UI incompleta, zero tests)
- Next steps prioritizzati
- Update log giornaliero

**Struttura:**
- **TIER 1 - MVP Base** (9 fasi, 25 giorni)
  - Canvas & View
  - Tools Base (Line, Rect, Circle, Arc)
  - Selection & Manipulation
  - Snap System
  - Layers
  - Undo/Redo
  - Save/Load
  - Export (SVG, PNG)
  - Properties Panel

- **TIER 2 - Professional** (8 fasi, 25 giorni)
  - Advanced Tools (Polyline, Polygon, Ellipse, Spline)
  - Modify Tools (Trim, Extend, Offset, Fillet, Mirror, Rotate, Scale, Array)
  - Dimensions (Linear, Angular, Radial)
  - Constraints (Parallel, Perpendicular, Tangent)
  - Import/Export DXF
  - Measure Tools
  - Command Line
  - Blocks

- **TIER 3 - Expert** (3 fasi, 20 giorni)
  - Parametric
  - Collaboration
  - Performance (5000+ oggetti)

- **Packaging TIER 1-3** (65 giorni)

**Acceptance Criteria:** Definiti per ogni TIER con test specifici

---

### 2. Standards Backend

#### [svc-box-designer/API_STANDARDS.md](svc-box-designer/API_STANDARDS.md)
**Backend API Specification**

Contenuto:
- 50+ endpoint REST API documentati
- Data models TypeScript
- Authentication & authorization
- Rate limiting
- Webhooks system
- i18n support
- Health checks
- Error codes

**API Groups:**
- `/api/cad/drawings` - Drawings CRUD
- `/api/packaging/templates` - Template library
- `/api/cad/3d/fold` - 3D preview
- `/api/packaging/calculate/*` - Calcoli (flat size, weight, cost)
- `/api/cad/export/*` - Export (DXF, SVG, PDF)
- `/api/packaging/nesting/*` - Nesting optimizer
- `/api/packaging/materials` - Materials database
- `/api/packaging/machines` - Machines database
- `/api/settings/*` - Settings (tenant, user, admin)

**Segue:** [API_FIRST_ARCHITECTURE.md](API_FIRST_ARCHITECTURE.md)

---

### 3. Standards Frontend

#### [app-box-designer/FRONTEND_STANDARDS.md](app-box-designer/FRONTEND_STANDARDS.md)
**Frontend Architecture & Standards**

Contenuto:
- Struttura cartelle completa
- Component patterns (React + TypeScript)
- State management (Zustand + Tanstack Query)
- CAD Engine architecture
- Styling guidelines (Tailwind CSS)
- API integration
- Keyboard shortcuts
- i18n setup
- Performance optimization
- Testing guidelines

**Tech Stack:**
- React 18 + TypeScript + Vite
- Tailwind CSS 3
- Zustand (global state) + Tanstack Query (API cache)
- Fabric.js / Konva.js (2D canvas)
- Three.js (3D preview)
- React Hook Form + Zod (forms)
- Radix UI (primitives)
- i18next (i18n)

**Struttura:**
```
src/
├── components/      # UI components
├── features/        # Feature modules
├── cad-engine/      # CAD Engine
│   ├── core/
│   ├── tools/
│   ├── objects/
│   ├── geometry/
│   └── constraints/
├── services/        # API clients
├── hooks/           # Custom hooks
├── stores/          # Zustand stores
├── lib/             # Utils
├── types/           # TypeScript
└── locales/         # i18n
```

**Segue:** [DEVELOPMENT_STANDARDS_2025.md](DEVELOPMENT_STANDARDS_2025.md)

---

## 📊 STATO ATTUALE (Sincerità Brutale)

### CAD Generico
- **TIER 1:** 🟨 15% completato
  - ✅ Canvas base exists
  - ✅ Zoom esiste (parziale)
  - 🔧 CADEngine.js esiste ma incompleto
  - 🔧 10 tools files esistono ma non funzionanti
  - ❌ Rendering solo linee, mancano altri oggetti
  - ❌ Nessuna UI completa (toolbar minimale)
  - ❌ Zero tests

- **TIER 2:** ⬜ 5% completato
  - 🔧 Files esistono ma algoritmi errati (trim, offset, fillet, mirror, array)
  - ⬜ DXF import/export non esiste
  - ⬜ Command line non esiste
  - ⬜ Blocks non esiste

- **TIER 3:** ⬜ 0% completato

### CAD Packaging
- **TIER 1-3:** ⬜ 0% completato
  - Prerequisito: CAD Generico TIER 1 completato

### **TOTALE PROGETTO: ~7% completato**

### Problemi Critici Identificati
1. **CADEngine incompleto** - `drawObject()` supporta solo linee
2. **Tools non funzionanti** - Algoritmi geometrici errati/mancanti
3. **Nessuna integrazione backend** - API non esistono
4. **UI incompleta** - Mancano panels (properties, layers, library)
5. **Zero testing** - Nessun test automatico o utente
6. **Performance non testata** - Lag potenziale con 500+ oggetti

---

## 🎯 ROADMAP CONSIGLIATA

### **Fase 1: Foundation (Settimane 1-4)**
**Obiettivo:** CAD Generico TIER 1 completato

**Week 1:**
- [ ] Fix CADEngine.drawObject() → supporta tutti i tipi
- [ ] LineTool 100% funzionante + tests
- [ ] RectangleTool 100% funzionante + tests
- [ ] SelectTool 100% funzionante + tests
- [ ] Move/Copy/Delete funzionanti

**Week 2:**
- [ ] CircleTool + ArcTool fix + tests
- [ ] Snap to points (endpoint, midpoint, center, intersection)
- [ ] Layers UI + manager
- [ ] Properties panel

**Week 3:**
- [ ] Undo/Redo completo (tutte operazioni)
- [ ] Save/Load JSON via API
- [ ] Backend API: drawings CRUD
- [ ] Export SVG + PNG

**Week 4:**
- [ ] Performance test (500+ oggetti)
- [ ] User test #1
- [ ] Fix critici
- [ ] Cleanup + docs

**Acceptance:** TIER 1 DONE ✅ → Designer esterno disegna rettangolo+cerchio in <2min senza aiuto

---

### **Fase 2: Professional Tools (Settimane 5-8)**
**Obiettivo:** CAD Generico TIER 2 completato

**Week 5-6:**
- [ ] Advanced tools (Polyline, Polygon, Ellipse, Spline)
- [ ] Modify tools (Trim, Extend, Offset, Fillet fix)
- [ ] Mirror, Rotate, Scale
- [ ] Array (linear, polar)

**Week 7:**
- [ ] Dimensions (linear, angular, radial)
- [ ] Constraints base (parallel, perpendicular, tangent)
- [ ] Measure tools
- [ ] Command line

**Week 8:**
- [ ] DXF import/export
- [ ] Blocks system
- [ ] Performance test (1000+ oggetti)
- [ ] User test #2

**Acceptance:** TIER 2 DONE ✅ → Designer esperto valuta 7/10

---

### **Fase 3: Packaging MVP (Settimane 9-12)**
**Obiettivo:** Packaging TIER 1 completato

**Week 9:**
- [ ] Line types (cut, crease, perforation, bleed)
- [ ] Template library (5 scatole base)
- [ ] Template generator API

**Week 10:**
- [ ] 3D fold basic algorithm
- [ ] 3D viewer (Three.js)
- [ ] Flat size calculation

**Week 11:**
- [ ] DXF export con layers per tipo linea
- [ ] Material database (5 cartoni)
- [ ] Backend API: templates, materials

**Week 12:**
- [ ] Integration test
- [ ] User test #3 (packaging designer)
- [ ] Fix + docs

**Acceptance:** Packaging TIER 1 DONE ✅ → Designer packaging crea scatola custom in <10min

---

### **Fase 4: Professional Packaging (Settimane 13-16)**
**Obiettivo:** Packaging TIER 2 completato

**Week 13-14:**
- [ ] Template library completa (20+ scatole FEFCO)
- [ ] 3D fold animation
- [ ] Advanced 3D rendering (materials)

**Week 15:**
- [ ] Nesting optimizer
- [ ] Cost calculation
- [ ] Design rules check

**Week 16:**
- [ ] Export CF2, PDF/X-4
- [ ] Machine profiles
- [ ] User test #4

**Acceptance:** Packaging TIER 2 DONE ✅ → Production-ready output

---

### **Fase 5: Enterprise Features (Settimane 17-20)**
**Obiettivo:** CAD Generico TIER 3 + Packaging TIER 3

**Week 17-18:**
- [ ] Parametric constraints (driving dimensions)
- [ ] Parameters & equations
- [ ] Parametric templates

**Week 19:**
- [ ] Collaboration (version control, comments, sharing)
- [ ] Structural testing (BCT, drop test)
- [ ] Artwork integration

**Week 20:**
- [ ] Performance optimization (5000+ oggetti <60fps)
- [ ] 3D PDF export
- [ ] Final user test #5

**Acceptance:** TIER 3 DONE ✅ → Beat Fusion 360 performance, 9/10 rating

---

## 📊 STIMA TOTALE

### Tempo
- **CAD Generico:** 50-65 giorni full-time
- **CAD Packaging:** 65-80 giorni full-time
- **TOTALE:** 115-145 giorni full-time (4-5 mesi)

### Team Consigliato
- **1 Senior Full-Stack** (CAD algorithms + API)
- **1 Frontend Specialist** (Canvas + UI)
- **1 Designer** (UX + testing)
- **Part-time:** Packaging expert (consulenza)

### Rischi
- **Alto:** Complessità algoritmi geometrici (trim, offset, fillet)
- **Medio:** Performance con 5000+ oggetti
- **Basso:** Tech stack maturo, precedenti esistenti (Fusion, OnShape)

---

## 🔄 PROCESSO SVILUPPO

### Daily Workflow
1. **Morning:** Standup (15min) + update checklist
2. **Dev:** TDD (test → code → refactor)
3. **Afternoon:** Code review + integration test
4. **EOD:** Update [CAD_IMPLEMENTATION_CHECKLIST.md](svc-box-designer/CAD_IMPLEMENTATION_CHECKLIST.md) con sincerità brutale

### Weekly Workflow
- **Monday:** Sprint planning, priorità settimana
- **Wednesday:** Mid-week sync, blockers
- **Friday:** Demo + user test + retrospective

### Testing Strategy
- **Unit tests:** Vitest (ogni funzione)
- **Integration tests:** API endpoints + Canvas operations
- **E2E tests:** Playwright (user flows)
- **Performance tests:** Lighthouse + custom metrics
- **User tests:** 1 designer esterno ogni week

### Definition of Done
Per ogni funzione:
- ✅ Code scritto + TypeScript types
- ✅ Unit tests (coverage >80%)
- ✅ Integration test
- ✅ Docs aggiornate (JSDoc + user guide)
- ✅ User test passed
- ✅ Performance OK (no lag)
- ✅ Checklist aggiornata

---

## 📝 NEXT STEPS IMMEDIATI

### Questa Settimana (Week 1)
1. ✅ **Specifiche complete** - DONE (questo documento)
2. ⬜ **Setup progetto**
   - Backend: svc-box-designer structure secondo standards
   - Frontend: app-box-designer structure secondo standards
   - Database: migrations per drawings table

3. ⬜ **Fix CADEngine**
   - Implementa `drawObject()` per tutti i tipi (circle, arc, rectangle)
   - Refactor rendering architecture
   - Add performance profiling

4. ⬜ **LineTool MVP**
   - Click-click basic
   - Snap to grid
   - Preview rubberband
   - Test: 100 linee senza lag

5. ⬜ **RectangleTool MVP**
   - 2-points mode
   - Preview real-time
   - Test: tutti size

### Prossima Settimana (Week 2)
- SelectTool + Move/Copy/Delete
- CircleTool + ArcTool fix
- Snap to points
- Layers UI

---

## 📚 RISORSE & REFERENCES

### Benchmark Software
- **Fusion 360** (Autodesk) - Sketcher parametrico
- **OnShape** - Cloud CAD
- **SolidWorks** - Sketcher 2D
- **ArtiosCAD** (Esko) - Packaging CAD leader
- **KASEMAKE** (Kongsberg) - Packaging design
- **Impact CAD** - Die design

### Libraries da Usare
- **Fabric.js** o **Konva.js** - 2D canvas
- **Three.js** - 3D rendering
- **ClipperLib** - Boolean operations, offset
- **Turf.js** - Geometry algorithms
- **bezier-js** - Spline/Bezier
- **cassowary.js** - Constraint solver (parametric)
- **dxf-parser** + **dxf-writer** - DXF import/export
- **SVGNest** - Nesting optimizer

### Standards Industria
- **FEFCO Codes** - Box standards (0201, 0215, 0427, etc.)
- **ECMA** - Line type colors
- **DXF AutoCAD** - R12, R14, 2000, 2010+
- **CF2 (Common File Format)** - Esko standard
- **PDF/X-4** - Print-ready PDF

---

## 🎉 CONCLUSIONE

### Documento Completo ✅
Hai ora:
1. ✅ Specifiche complete CAD generico (200+ funzioni)
2. ✅ Specifiche complete CAD packaging (12 categorie)
3. ✅ Checklist implementazione dettagliata (tracking brutalmente sincero)
4. ✅ API standards (50+ endpoints)
5. ✅ Frontend standards (architettura completa)
6. ✅ Roadmap 20 settimane
7. ✅ Stima realistica (115-145 giorni)

### Prossimo Step
**Inizia Week 1** → Setup + Fix CADEngine + LineTool MVP

### Regola d'Oro
**NO FAKE PROGRESS. NO BULLSHIT.**

Aggiorna la checklist OGNI GIORNO con sincerità:
- ⬜ = Non fatto
- 🟨 = In progress
- ✅ = Done E testato
- ❌ = Fallito (spiega problema)
- 🔧 = Funziona ma brutto (refactor needed)

---

**Ready to build something amazing! 🚀**

**Master Plan Version:** 2.0
**Created:** 2025-10-16
**Owner:** EWH Platform Team
**Status:** ✅ Specifications Complete - Ready to Code
