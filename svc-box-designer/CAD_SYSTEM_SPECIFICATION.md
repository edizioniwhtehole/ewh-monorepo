# 🎨 CAD System - Complete Specification

**Versione:** 2.0
**Data:** 16 Ottobre 2025
**Obiettivo:** Sistema CAD professionale completo, API-first, modulare

---

## 🎯 FASE 1: CAD GENERICO (Fusion 360 / OnShape Style)

### Obiettivo
Sistema CAD 2D parametrico professionale per disegno tecnico generale.

**Target Users:**
- Ingegneri meccanici
- Designer industriali
- Progettisti generici
- Tecnici

**Benchmark:** Fusion 360 (Autodesk), OnShape, SolidWorks Sketcher

---

## 📋 CATEGORIE FUNZIONALI

### 1. **CORE - Oggetti Base Geometrici**

#### 1.1 Linee e Polilinee
- [ ] **Line** - Linea tra due punti
  - Input: punto inizio, punto fine
  - Modalità: click-click, input coordinate dirette
  - Vincoli: lunghezza, angolo

- [ ] **Polyline** - Linea multipunto continua
  - Input: serie di click
  - Opzioni: chiudi forma automaticamente
  - Snap: to previous point, perpendicular, parallel

- [ ] **Rectangle** - Rettangolo
  - Modalità 1: 2 punti angoli opposti
  - Modalità 2: centro + dimensioni
  - Modalità 3: 3 punti (con rotazione)
  - Vincoli: lati paralleli, angoli retti

- [ ] **Circle** - Cerchio
  - Modalità 1: centro + raggio (click-drag)
  - Modalità 2: centro + raggio numerico
  - Modalità 3: 3 punti sulla circonferenza
  - Modalità 4: 2 punti diametro

- [ ] **Arc** - Arco
  - Modalità 1: 3 punti (start, point, end)
  - Modalità 2: centro + start + end
  - Modalità 3: tangente a linea
  - Parametri: raggio, angolo apertura, direzione

- [ ] **Ellipse** - Ellisse
  - Modalità 1: centro + 2 assi
  - Modalità 2: 3 punti
  - Parametri: asse maggiore, asse minore

- [ ] **Polygon** - Poligono regolare
  - Input: centro + raggio + numero lati
  - Opzioni: circoscritto/iscritto
  - Parametri: 3-100 lati

#### 1.2 Curve Avanzate

- [ ] **Spline** - Curva Bezier/B-spline
  - Input: punti di controllo
  - Opzioni: smooth, tangent handles
  - Editabile: move control points

- [ ] **Freehand** - Disegno a mano libera
  - Input: traccia mouse/pen
  - Auto-smooth
  - Conversione a spline

#### 1.3 Testo e Annotazioni

- [ ] **Text** - Testo singola linea
  - Input: punto inserimento + testo
  - Parametri: font, size, style (bold, italic)
  - Allineamento: left, center, right

- [ ] **Multiline Text** - Paragrafo
  - Input: area rettangolare + testo
  - Wrapping automatico
  - Formatting: font, color, alignment

---

### 2. **MODIFICA - Tools di Trasformazione**

#### 2.1 Operazioni Base

- [ ] **Select** - Selezione oggetti
  - Click singolo
  - Box selection (drag)
  - Multi-select (Shift+click)
  - Select all (Ctrl+A)
  - Deselect all (Esc)

- [ ] **Move** - Sposta oggetti
  - Drag & drop
  - Input coordinate relative/assolute
  - Opzione: copia mentre sposti

- [ ] **Copy** - Copia oggetti
  - Ctrl+C / Ctrl+V
  - Copy in place
  - Copy with offset

- [ ] **Rotate** - Ruota oggetti
  - Click centro rotazione + angolo
  - Input angolo diretto
  - Snap: 15°, 30°, 45°, 90°

- [ ] **Scale** - Scala oggetti
  - Uniforme (proporzionale)
  - Non-uniforme (X/Y separati)
  - Da punto di riferimento

- [ ] **Mirror** - Specchia oggetti
  - Specchia su asse X/Y
  - Specchia su linea custom
  - Opzione: mantieni originale

- [ ] **Delete** - Elimina
  - Canc / Backspace
  - Bulk delete

#### 2.2 Operazioni Avanzate

- [ ] **Trim** - Taglia alle intersezioni
  - Click su porzione da eliminare
  - Auto-detect intersezioni
  - Multi-trim

- [ ] **Extend** - Estendi fino a oggetto
  - Click linea da estendere
  - Click boundary
  - Auto-extend

- [ ] **Offset** - Offset parallelo
  - Input distanza
  - Direzione (interno/esterno)
  - Multiple offset

- [ ] **Fillet** - Raccordo angoli
  - Input raggio
  - Click 2 linee
  - Preview dinamico

- [ ] **Chamfer** - Smusso angoli
  - Input distanze
  - Click 2 linee
  - Simmetrico/asimmetrico

- [ ] **Array** - Pattern lineare
  - Rettangolare (righe x colonne)
  - Polare (circolare)
  - Path-based (lungo curva)
  - Parametri: count, spacing

- [ ] **Stretch** - Allunga/accorcia
  - Seleziona area
  - Drag point
  - Mantieni geometria

---

### 3. **CONSTRAINTS - Vincoli Parametrici**

#### 3.1 Vincoli Geometrici

- [ ] **Coincident** - Punto su punto/linea
- [ ] **Parallel** - Linee parallele
- [ ] **Perpendicular** - Linee perpendicolari
- [ ] **Tangent** - Tangenza cerchio-linea
- [ ] **Concentric** - Centri coincidenti
- [ ] **Collinear** - Punti su stessa linea
- [ ] **Horizontal** - Linea orizzontale
- [ ] **Vertical** - Linea verticale
- [ ] **Equal** - Lunghezze/raggi uguali
- [ ] **Symmetric** - Simmetria rispetto asse
- [ ] **Fix** - Blocca posizione

#### 3.2 Vincoli Dimensionali

- [ ] **Linear Dimension** - Quota lineare
  - Orizzontale, verticale, allineata
  - Driving (parametrica) / Driven (riferimento)
  - Edit: double-click modifica valore

- [ ] **Angular Dimension** - Quota angolare
  - Tra 2 linee
  - Arco
  - Edit: parametrica

- [ ] **Radial Dimension** - Raggio
  - Cerchi, archi

- [ ] **Diameter Dimension** - Diametro
  - Cerchi

#### 3.3 Equazioni Parametriche

- [ ] **Parameters** - Variabili globali
  - Esempio: `width = 100`, `height = width * 2`
  - Uso nelle quote: `d1 = width / 2`
  - Formula editor

- [ ] **Relationships** - Relazioni tra oggetti
  - Esempio: `line1.length = line2.length * 1.5`

---

### 4. **LAYERS & ORGANIZATION - Organizzazione**

#### 4.1 Layer System

- [ ] **Layers** - Livelli disegno
  - Create/delete/rename layers
  - Layer properties:
    - Name
    - Color
    - Line type (solid, dashed, dotted)
    - Line weight (0.1mm - 2mm)
    - Visibility (show/hide)
    - Lock (prevent edit)
    - Print (printable yes/no)

- [ ] **Layer Manager** - Gestione layers
  - List view con drag&drop riordino
  - Bulk operations
  - Layer states (saved configurations)

#### 4.2 Groups e Blocks

- [ ] **Group** - Raggruppa oggetti
  - Seleziona più oggetti → Group
  - Muovi come singola unità
  - Ungroup

- [ ] **Block / Component** - Componente riutilizzabile
  - Crea da selezione
  - Insert block (instance)
  - Edit block (tutti instance aggiornati)
  - Block library

---

### 5. **SNAP & GRID - Precisione**

#### 5.1 Snap System

- [ ] **Snap to Grid** - Snap griglia
  - Griglia configurable (1mm, 5mm, 10mm, custom)
  - Toggle on/off (F9)

- [ ] **Snap to Points** - Snap punti notevoli
  - Endpoint
  - Midpoint
  - Center
  - Quadrant (cerchio: 0°, 90°, 180°, 270°)
  - Intersection
  - Perpendicular foot
  - Tangent point
  - Nearest (point on curve)

- [ ] **Object Snap Tracking** - Tracking
  - Snap temporaneo con linee guida
  - Snap angolare (0°, 45°, 90°)
  - Distance tracking

#### 5.2 Grid Settings

- [ ] **Grid** - Griglia visibile
  - Major grid (10mm)
  - Minor grid (1mm)
  - Dots o lines
  - Adaptive (zoom-based)

---

### 6. **VIEW & NAVIGATION - Visualizzazione**

#### 6.1 View Controls

- [ ] **Pan** - Sposta vista
  - Middle mouse drag
  - Space + drag
  - Arrow keys

- [ ] **Zoom** - Zoom in/out
  - Mouse wheel
  - Zoom window (area)
  - Zoom extents (fit all)
  - Zoom selected
  - Zoom previous
  - Zoom levels: 10%, 25%, 50%, 100%, 200%, 400%

- [ ] **View Presets** - Viste predefinite
  - Top (XY)
  - Front (XZ)
  - Right (YZ)
  - Isometric

#### 6.2 Display Options

- [ ] **Show/Hide** - Visibilità elementi
  - Grid
  - Snap points
  - Dimensions
  - Constraints symbols
  - Origin axes
  - Bounding boxes

- [ ] **Display Modes** - Modalità rendering
  - Wireframe
  - Shaded (2D with fills)
  - X-ray (see through)

---

### 7. **MEASUREMENTS - Misure e Analisi**

#### 7.1 Measurement Tools

- [ ] **Measure Distance** - Misura distanza
  - Punto-punto
  - Punto-linea
  - Display live

- [ ] **Measure Angle** - Misura angolo
  - Tra 2 linee
  - Arco

- [ ] **Measure Area** - Area
  - Forma chiusa
  - Multiple areas (sum)

- [ ] **Measure Perimeter** - Perimetro
  - Forma chiusa

- [ ] **Inspect** - Info oggetto
  - Click oggetto → mostra proprietà
  - Coordinate, dimensioni, layer

---

### 8. **IMPORT / EXPORT - Interoperabilità**

#### 8.1 Import

- [ ] **DXF Import** - AutoCAD DXF
  - R12, R14, 2000, 2004, 2007, 2010+
  - Mantieni layers
  - Conversione unità

- [ ] **SVG Import** - Scalable Vector Graphics
  - Paths → polylines
  - Curves → splines
  - Text import

- [ ] **PDF Import** (vettoriale)
  - Extract vector graphics
  - Layer per pagina

#### 8.2 Export

- [ ] **DXF Export** - AutoCAD DXF
  - Selezione versione
  - Layer preservation
  - Export selected o all

- [ ] **SVG Export** - Web-ready
  - Configurabile stroke/fill
  - Embed fonts

- [ ] **PDF Export** - Stampa
  - Page setup
  - Scale (1:1, 1:2, 1:5, custom)
  - Multi-page

- [ ] **PNG/JPG Export** - Raster
  - DPI configurable (72, 150, 300)
  - Background (white, transparent)

- [ ] **JSON Export** - Formato nativo
  - Salva tutto (oggetti, layers, constraints)
  - Versioning

---

### 9. **HISTORY & UNDO - Gestione Storia**

#### 9.1 Undo/Redo System

- [ ] **Undo** - Annulla (Ctrl+Z)
  - Stack: 50 operazioni
  - Visual history tree

- [ ] **Redo** - Ripeti (Ctrl+Y)

- [ ] **History Panel** - Pannello storia
  - Lista operazioni
  - Click to jump
  - Branchable (undo tree)

---

### 10. **UI & UX - Interfaccia Utente**

#### 10.1 Toolbars & Panels

- [ ] **Main Toolbar** - Strumenti principali
  - Icone tool categorizzati
  - Tooltips
  - Keyboard shortcuts

- [ ] **Properties Panel** - Proprietà oggetto selezionato
  - Edit inline
  - Lock/unlock properties

- [ ] **Layers Panel** - Gestione layers
  - Tree view
  - Drag & drop

- [ ] **Library Panel** - Blocchi e componenti
  - Thumbnail preview
  - Search
  - Drag to insert

#### 10.2 Command Line

- [ ] **Command Input** - Input comandi testuale
  - Esempio: `LINE` Enter → attiva tool linea
  - Autocomplete
  - History (arrow up/down)
  - Aliases: `L` → `LINE`, `C` → `CIRCLE`

#### 10.3 Shortcuts

- [ ] **Keyboard Shortcuts** - Tasti rapidi
  - Standard: Ctrl+C, Ctrl+V, Ctrl+Z, Del
  - Tools: L (line), C (circle), R (rectangle), T (trim)
  - View: Z (zoom), P (pan), F (fit)
  - Custom shortcuts editor

#### 10.4 Themes

- [ ] **Dark Mode** / Light Mode
  - Canvas background
  - UI colors
  - Grid colors

---

### 11. **COLLABORATION - Collaborazione**

#### 11.1 Versioning

- [ ] **Save As** - Salva versione
  - Versioning automatico (v1, v2, v3...)
  - Comments per versione

- [ ] **Version Compare** - Confronta versioni
  - Side-by-side view
  - Diff highlighting

#### 11.2 Sharing

- [ ] **Share Link** - Link condivisibile
  - Read-only view
  - Public/private

- [ ] **Comments** - Annotazioni
  - Pin comment su posizione
  - Thread discussions

---

### 12. **SETTINGS - Configurazione**

#### 12.1 Drawing Settings

- [ ] **Units** - Unità misura
  - Metric (mm, cm, m)
  - Imperial (in, ft)
  - Precision (decimali)

- [ ] **Default Layer** - Layer default
  - Per nuovi oggetti

- [ ] **Default Colors** - Colori default
  - Per tipo oggetto

#### 12.2 Performance

- [ ] **Anti-aliasing** - Smoothing
- [ ] **Hardware Acceleration** - GPU
- [ ] **Auto-save** - Salvataggio automatico (ogni N min)

---

## 🎯 PRIORITÀ IMPLEMENTAZIONE

### **TIER 1 - MVP BASE** (2-3 settimane)
Core minimo funzionante per disegno 2D base.

**MUST HAVE:**
- [x] Canvas + Grid + Zoom/Pan
- [ ] Tools: Line, Rectangle, Circle, Arc
- [ ] Select, Move, Delete, Copy
- [ ] Snap to Grid + Snap to Points
- [ ] Layers (create, visibility, lock)
- [ ] Undo/Redo (50 steps)
- [ ] Save/Load (JSON format)
- [ ] Export: SVG, PNG
- [ ] Properties Panel (edit coordinates)

**Tempo:** 15-20 giorni full-time

---

### **TIER 2 - PROFESSIONAL** (3-4 settimane)
Funzioni avanzate per uso professionale.

**SHOULD HAVE:**
- [ ] Tools: Polyline, Polygon, Ellipse, Spline
- [ ] Trim, Extend, Offset, Fillet
- [ ] Mirror, Rotate, Scale, Array
- [ ] Dimensions (linear, angular, radial)
- [ ] Constraints (parallel, perpendicular, tangent)
- [ ] Import/Export: DXF
- [ ] Measure tools
- [ ] Command line
- [ ] Blocks/Components
- [ ] Advanced snap (tracking, perpendicular)

**Tempo:** 20-25 giorni full-time

---

### **TIER 3 - EXPERT** (2-3 settimane)
Funzioni enterprise e collaborazione.

**NICE TO HAVE:**
- [ ] Parametric constraints (driving dimensions)
- [ ] Parameters & equations
- [ ] PDF Import/Export
- [ ] Version control
- [ ] Collaboration (comments, sharing)
- [ ] Custom shortcuts editor
- [ ] Advanced layer management (states)
- [ ] Performance optimization (large drawings)

**Tempo:** 15-20 giorni full-time

---

## 📊 TOTALE STIMA

**MVP Completo (TIER 1 + 2 + 3):**
- **Tempo:** 50-65 giorni full-time
- **Complessità:** Alta
- **Rischio:** Medio (tecnologie mature)

---

## 🔗 TECNOLOGIE

### Frontend
- **Canvas:** Fabric.js o Konva.js (2D canvas library)
- **UI:** React 18 + TypeScript
- **State:** Zustand (local) + Immer (immutable)
- **Shortcuts:** react-hotkeys-hook

### Backend (API-First)
- **Framework:** Express/Fastify
- **Database:** PostgreSQL (save drawings as JSONB)
- **Export:** svg2pdf, pdfkit (PDF), node-canvas (PNG)
- **DXF:** dxf-parser, dxf-writer

### Algoritmi
- **Intersezioni:** Turf.js (geometry)
- **Offset:** ClipperLib
- **Spline:** bezier-js
- **Constraints solver:** cassowary.js (parametric)

---

**Documento:** `CAD_SYSTEM_SPECIFICATION.md`
**Prossimo step:** `CAD_PACKAGING_SPECIFICATION.md` (specialized)
