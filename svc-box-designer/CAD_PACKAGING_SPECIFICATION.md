# 📦 CAD System - Packaging Industry Specialization

**Versione:** 2.0
**Data:** 16 Ottobre 2025
**Obiettivo:** CAD specializzato per cartotecnica (scatole, espositori, imballaggi)

---

## 🎯 FASE 2: CAD CARTOTECNICA

### Obiettivo
Sistema CAD 2D/3D specializzato per design imballaggi in cartone.

**Target Users:**
- Designer packaging
- Cartotech engineers
- Fustella makers
- Print technicians
- Production planners

**Benchmark:** ArtiosCAD (Esko), KASEMAKE (Kongsberg), Impact CAD

---

## 📋 FUNZIONALITÀ SPECIFICHE PACKAGING

### 1. **TEMPLATE LIBRARY - Libreria Fustelle**

#### 1.1 Scatole Standard

- [ ] **4-Corner Box** - Scatola americana
  - Parametri: L, W, H
  - Auto-calcolo falde
  - Glue tab automatico

- [ ] **Tray Box** - Vassoia
  - Opzioni: con/senza coperchio
  - Corner styles: square, rounded, interlocking

- [ ] **Sleeve Box** - Astuccio scorrevole
  - Box interno + sleeve esterno
  - Clearance automatico

- [ ] **Pillow Box** - Scatola a cuscino
  - Parametri: L, W
  - Curve automatiche

- [ ] **Display Box** - Espositore banco
  - Front opening
  - Reinforced back
  - Display hooks

- [ ] **Gable Top Box** - Scatola tipo latte
  - Handle integrato
  - Gable flaps

- [ ] **Pizza Box** - Scatola pizza
  - Ventilation holes
  - Corner locks

- [ ] **Mailer Box** - Scatola postale
  - Locking tabs
  - Crash-lock bottom

#### 1.2 Scatole Avanzate

- [ ] **Truncated Pyramid** - Piramide tronca
  - Base e top diverse
  - Calcolo facce trapezoidali

- [ ] **Hexagonal Box** - Scatola esagonale

- [ ] **Octagonal Box** - Scatola ottagonale

- [ ] **Conical Box** - Conica

- [ ] **Custom Polygon** - Poligono custom (3-12 lati)

#### 1.3 Accessori e Inserti

- [ ] **Divider** - Separatore interno
  - Grid pattern
  - Interlocking slots

- [ ] **Insert Tray** - Inserto sagomato
  - Custom cutouts
  - Multi-level

- [ ] **Reinforcement** - Rinforzi
  - Corner guards
  - Edge protectors

---

### 2. **LINE TYPES - Tipi Linea Cartotecnica**

Standard ECMA:

- [ ] **Cut Line** (Rosso) - Taglio fustella
  - Stroke: 0.5pt solid
  - Color: #FF0000

- [ ] **Crease Line** (Blu) - Cordonatura
  - Stroke: 0.25pt dashed
  - Color: #0000FF

- [ ] **Perforation** (Magenta) - Perforazione
  - Stroke: 0.25pt dotted
  - Color: #FF00FF
  - Pattern: 2mm on, 1mm off

- [ ] **Bleed Line** (Verde) - Bleed grafico
  - Stroke: 0.1pt solid
  - Color: #00FF00

- [ ] **Dimension Line** (Nero) - Quotatura
  - Stroke: 0.1pt solid
  - Color: #000000

- [ ] **Registration Mark** (Ciano) - Registro stampa
  - Color: #00FFFF

- [ ] **Safety Margin** (Arancione) - Margine sicurezza
  - Color: #FFA500

#### 2.1 Line Type Manager

- [ ] **Custom Line Types** - Tipi personalizzati
  - Define dash pattern
  - Assign color
  - Set print rules

---

### 3. **3D PREVIEW - Anteprima Tridimensionale**

#### 3.1 Folding Simulation

- [ ] **3D Fold** - Piega automatica da fustella
  - Input: fustella 2D + crease lines
  - Output: modello 3D piegato
  - Algorithm: fold along creases (180°, 90°, custom)

- [ ] **Fold Sequence** - Animazione piega
  - Step-by-step folding
  - Play/pause controls
  - Speed control

- [ ] **3D Viewer** - Visualizzatore 3D
  - Orbit, pan, zoom
  - Wireframe / shaded
  - Exploded view

#### 3.2 Material Simulation

- [ ] **Material Rendering** - Rendering materiali
  - Cartone ondulato (flutes visible)
  - Cartoncino
  - Microonda
  - Texture realistiche

- [ ] **Print Preview** - Anteprima stampa
  - Apply graphics to 3D
  - CMYK preview
  - Spot colors

---

### 4. **CALCULATIONS - Calcoli Tecnici**

#### 4.1 Geometric Calculations

- [ ] **Flat Size** - Dimensione sviluppo
  - Auto-calculate da 3D dimensions
  - Include thickness compensation

- [ ] **Material Area** - Area materiale
  - Excluding waste
  - Total sheet area

- [ ] **Weight Calculation** - Peso
  - Input: material weight (g/m²)
  - Output: piece weight

- [ ] **Volume Calculation** - Volume interno
  - From 3D model
  - Useful volume vs total

#### 4.2 Production Calculations

- [ ] **Nesting Layout** - Ottimizzazione taglio
  - Input: sheet size, quantity
  - Output: optimal layout
  - Algorithms: guillotine, nest, rotate

- [ ] **Material Waste** - Scarto materiale
  - Percentage
  - Cost impact

- [ ] **Yield Optimization** - Resa foglio
  - Multiple orientations
  - Best fit suggestion

#### 4.3 Costing

- [ ] **Cost Estimation** - Stima costi
  - Material cost (per m²)
  - Die cost (setup)
  - Print cost (colors, area)
  - Labor cost
  - Finishing cost (lamination, UV, etc.)

---

### 5. **CONSTRAINTS - Vincoli Produttivi**

#### 5.1 Manufacturing Constraints

- [ ] **Minimum Flap Width** - Larghezza minima falda
  - Default: 15mm
  - Warning se < min

- [ ] **Maximum Score Length** - Lunghezza max cordonatura
  - Per tipo macchina

- [ ] **Fiber Direction** - Direzione fibra
  - Indicatore visivo
  - Constraint: crease ⊥ fiber

- [ ] **Glue Tab Width** - Larghezza aletta incollaggio
  - Standard: 15-20mm
  - Auto-positioning

#### 5.2 Material Constraints

- [ ] **Board Thickness** - Spessore cartone
  - E-flute: 1.5mm
  - B-flute: 3mm
  - C-flute: 4mm
  - Custom

- [ ] **Minimum Radius** - Raggio minimo piega
  - Function of thickness
  - Prevent cracking

---

### 6. **ARTWORK - Gestione Grafica**

#### 6.1 Print Areas

- [ ] **Safe Print Area** - Area stampa sicura
  - Margin da creases: 5mm
  - Margin da edges: 3mm
  - Visual guide

- [ ] **Bleed Setup** - Impostazione bleed
  - Standard: 3mm
  - Auto-extend artwork

- [ ] **Color Separation** - Separazione colori
  - CMYK + Spot
  - Overprint preview

#### 6.2 Artwork Import

- [ ] **Import PDF** - Import artwork
  - Vector graphics
  - Embedded fonts
  - Layer per color

- [ ] **Import AI** - Adobe Illustrator
  - Artboards → panels
  - Preserve layers

- [ ] **Image Placement** - Immagini raster
  - Drag & drop
  - DPI check (min 300dpi)
  - Clipping mask

---

### 7. **DIELINE EXPORT - Export Fustella**

#### 7.1 Standard Formats

- [ ] **DXF Export** (Production)
  - Layers per line type
  - Unit: mm
  - Version: AutoCAD 2010+

- [ ] **PDF/X-4** (Print-ready)
  - Spot colors
  - Bleed included
  - Cut marks

- [ ] **AI/EPS** (Design)
  - Vector
  - Editable

- [ ] **STEP/IGES** (3D CAD)
  - For 3D modeling
  - Import in SolidWorks, etc.

#### 7.2 Specialized Formats

- [ ] **CF2 (Common File Format)** - Industry standard
  - Esko ArtiosCAD format
  - Include metadata (materials, costs)

- [ ] **ARD (Artios Design)** - Esko native

- [ ] **CFF3 (Corrugated Fiberboard Format)** - FEFCO

---

### 8. **LIBRARY MANAGEMENT - Gestione Template**

#### 8.1 Template Database

- [ ] **Save Template** - Salva template
  - Parametri variabili
  - Thumbnail preview
  - Tags (category, style, industry)

- [ ] **Load Template** - Carica template
  - Search by tags
  - Filter (dimensions, style)
  - Recent templates

- [ ] **Template Families** - Famiglie parametriche
  - Master template + variations
  - Auto-update instances

#### 8.2 Custom Library

- [ ] **Company Templates** - Template aziendali
  - Private library
  - Share with team

- [ ] **Cloud Sync** - Sincronizzazione
  - Backup automatico
  - Version control

---

### 9. **MACHINE DATABASE - Database Macchine**

#### 9.1 Machine Profiles

- [ ] **Die Cutter** - Fustellatrice
  - Sheet size max (1050x750mm standard)
  - Gripper margin (10mm)
  - Registration tolerance

- [ ] **Folder-Gluer** - Piegatrice-incollatrice
  - Box size range (min/max)
  - Speed (boxes/min)

- [ ] **Digital Cutter** - Plotter da taglio
  - Kongsberg, Zünd, etc.
  - Job file export

- [ ] **Printer** - Macchina stampa
  - Print area
  - Color capability
  - Resolution

#### 9.2 Material Database

- [ ] **Board Types** - Tipi cartone
  - Solid Bleached Sulfate (SBS)
  - Coated Unbleached Kraft (CUK)
  - Corrugated (E, B, C, BC, EB)
  - Micro-flute
  - Custom materials

- [ ] **Properties** - Proprietà materiali
  - Thickness
  - Weight (g/m²)
  - Strength (ECT, BCT)
  - Cost (€/m²)

---

### 10. **QUALITY CONTROL - Controllo Qualità**

#### 10.1 Design Validation

- [ ] **Design Rules Check (DRC)** - Verifica regole
  - Minimum flap width
  - Clearance tabs-edges
  - Score line proximity
  - Sharp angles (< 15° warning)
  - Report with fixes

- [ ] **Printability Check** - Verifica stampabilità
  - DPI images (min 300)
  - Bleed presence
  - Color out of gamut
  - Small text (< 6pt warning)

- [ ] **Structural Integrity** - Integrità strutturale
  - Load simulation (top load)
  - Stacking strength
  - Edge crush test simulation

#### 10.2 Testing

- [ ] **Drop Test Simulation** - Test caduta
  - Virtual drop test
  - Weak point identification

- [ ] **Compression Test** - Test compressione
  - BCT calculator (Box Compression Test)
  - Stack height max

---

### 11. **PROTOTYPING - Prototipazione**

#### 11.1 Flat Pattern

- [ ] **Print & Fold Template** - Stampa e piega
  - Export PDF con:
    - Fold lines dotted
    - Cut lines solid
    - Glue tabs marked
    - Assembly instructions

- [ ] **Scoring Guide** - Guida cordonatura
  - Print with measurements
  - Tool selection

#### 11.2 Digital Mockup

- [ ] **3D PDF Export** - PDF interattivo
  - Rotate 3D model
  - Exploded view
  - Measure tools

- [ ] **VR Preview** - Anteprima VR (future)
  - View in virtual shelf
  - Scale perception

---

### 12. **SPECIAL FEATURES - Funzioni Speciali**

#### 12.1 Handles

- [ ] **Die-Cut Handle** - Manico fustellato
  - Rounded edges
  - Size standards
  - Reinforcement options

- [ ] **Rope Handle** - Manico con corda
  - Eyelet positions
  - Diameter holes

#### 12.2 Windows

- [ ] **Window Cutout** - Finestra
  - Shape: rectangle, circle, custom
  - Margin da edges (min 10mm)
  - PET film overlay option

#### 12.3 Locking Mechanisms

- [ ] **Auto-Lock Bottom** - Fondo automatico
  - 1-2-3 bottom
  - Crash-lock

- [ ] **Tuck-In Flap** - Aletta a incastro
  - Thumb notch
  - Lock tab

- [ ] **Snap Lock** - Chiusura a scatto

#### 12.4 Perforation

- [ ] **Tear Strip** - Striscia strappo
  - Easy-open feature
  - Perforation pattern
  - Tab

- [ ] **Perforation Line** - Linea perforazione
  - Custom pattern (2mm cut, 1mm gap)

---

## 🎯 PRIORITÀ IMPLEMENTAZIONE PACKAGING

### **TIER 1 - MVP PACKAGING** (3-4 settimane)

**MUST HAVE:**
- [ ] CAD generico TIER 1 (prerequisito)
- [ ] Line types: cut, crease, perforation
- [ ] Template library: 5 scatole base
- [ ] 3D preview (basic fold)
- [ ] Flat size calculation
- [ ] Export: DXF (layers per tipo linea)
- [ ] Material database (5 cartoni)

**Tempo:** 20-25 giorni

---

### **TIER 2 - PROFESSIONAL PACKAGING** (4-5 settimane)

**SHOULD HAVE:**
- [ ] CAD generico TIER 2 (prerequisito)
- [ ] Template library completa (20+ scatole)
- [ ] 3D fold animation
- [ ] Nesting layout optimizer
- [ ] Cost calculation
- [ ] Design rules check
- [ ] Export: CF2, PDF/X-4
- [ ] Machine profiles (3-5 macchine)

**Tempo:** 25-30 giorni

---

### **TIER 3 - ENTERPRISE PACKAGING** (3-4 settimane)

**NICE TO HAVE:**
- [ ] CAD generico TIER 3 (prerequisito)
- [ ] Parametric templates (edit & auto-update)
- [ ] Advanced 3D rendering (materials)
- [ ] Structural testing (BCT, drop test)
- [ ] Custom library sync
- [ ] Artwork integration (PDF import)
- [ ] 3D PDF export
- [ ] VR preview (WebXR)

**Tempo:** 20-25 giorni

---

## 📊 TOTALE STIMA PACKAGING

**MVP Completo Packaging (TIER 1 + 2 + 3):**
- **Tempo:** 65-80 giorni full-time
- **Complessità:** Molto Alta
- **Prerequisito:** CAD Generico completato

**TOTALE (CAD Generico + Packaging):**
- **115-145 giorni full-time** (4-5 mesi)

---

## 🔗 TECNOLOGIE SPECIFICHE PACKAGING

### 3D Folding
- **Three.js** - Rendering 3D
- **Fold algorithm:** Custom (crease lines → faces → rotate)
- **Physics:** Ammo.js (collision, constraints)

### Nesting
- **SVGNest** - JS library per nesting
- **Genetic algorithm** - Ottimizzazione
- **ClipperLib** - Boolean operations

### Export
- **DXF-Writer** - Export DXF
- **jsPDF** - PDF generation
- **CF2 Exporter** - Custom (XML format)

### Structural Testing
- **McKee Formula** - BCT calculation
- **FEA Simulation** (future) - Finite Element Analysis

---

## 📐 STANDARD INDUSTRIA

### FEFCO Codes
Implementare 50+ codici FEFCO standard:
- 0201: Slotted box
- 0215: Telescope box
- 0427: Display box
- Etc.

### ECMA Standards
- Line types colors
- Stroke widths
- Export formats

---

## 🎯 ROADMAP CONSIGLIATA

### **Mese 1-2: CAD Generico TIER 1**
Focus su base solida 2D.

### **Mese 2-3: CAD Generico TIER 2 + Packaging TIER 1**
Aggiungi funzioni avanzate 2D + specializzazione packaging base.

### **Mese 4: Packaging TIER 2**
3D, nesting, cost calculation.

### **Mese 5: CAD Generico TIER 3 + Packaging TIER 3**
Parametric, collaboration, enterprise features.

---

**Documento:** `CAD_PACKAGING_SPECIFICATION.md`
**Next:** Checklist implementazione dettagliata