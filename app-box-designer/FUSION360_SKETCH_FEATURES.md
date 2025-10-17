# Fusion 360 Sketch Features - Implementation Reference

## 📐 CREATE Tools (7)

### 1. LINE
**Varianti**:
- 2-Point Line: Click start → Click end
- Length + Angle: Input numerico esatto
- Horizontal/Vertical: Con Ortho mode attivo

**Input Panel**:
- Length: 100mm
- Angle: 45°
- Relative/Absolute: Toggle

**Shortcut**: L

---

### 2. RECTANGLE
**Varianti**:
- 2-Point: Click angolo → Click angolo opposto
- 3-Point: Click angolo → Click larghezza → Click altezza
- Center Rectangle: Click centro → Click angolo

**Input Panel**:
- Width: 100mm
- Height: 80mm
- Center X, Y: 0, 0

**Shortcut**: R

---

### 3. CIRCLE
**Varianti**:
- Center-Radius: Click centro → Click punto su circonferenza
- 2-Point Diameter: Click primo punto → Click secondo punto
- 3-Point: Click 3 punti sulla circonferenza

**Input Panel**:
- Center X: 0mm
- Center Y: 0mm
- Radius: 50mm
- Diameter: 100mm (linked)

**Shortcut**: C

---

### 4. ARC
**Varianti**:
- 3-Point Arc: Start → End → Point on arc
- Tangent Arc: Tangente a linea esistente
- Center-Point Arc: Centro → Start → End

**Input Panel**:
- Start Angle: 0°
- End Angle: 90°
- Radius: 50mm

**Shortcut**: A

---

### 5. POLYGON
**Varianti**:
- Inscribed: Centro → Raggio cerchio inscritto → Lati
- Circumscribed: Centro → Raggio cerchio circoscritto → Lati

**Input Panel**:
- Sides: 6
- Radius: 50mm
- Type: Inscribed / Circumscribed

**Shortcut**: PG

---

### 6. SPLINE
**Varianti**:
- Fit Point Spline: Click più punti → Curva che passa per tutti
- Control Point Spline: Click control points → Curva Bezier

**Input Panel**:
- Degree: 3 (cubic)
- Closed: Yes/No
- Tangent handles: Show/Hide

**Shortcut**: S

---

### 7. POINT
**Varianti**:
- Single Point: Click posizione
- Point on Object: Click su linea/curva esistente
- Point at Intersection: Automatico alle intersezioni

**Input Panel**:
- X: 100mm
- Y: 50mm

**Shortcut**: PT

---

## ✂️ MODIFY Tools (9)

### 8. TRIM
**Funzione**: Taglia linee/archi alle intersezioni

**Workflow**:
1. Click TRIM tool
2. Click su parte di linea da rimuovere
3. Linea viene tagliata all'intersezione più vicina

**Opzioni**:
- Trim to object
- Trim to edge
- Extend to trim

**Shortcut**: TR

---

### 9. EXTEND
**Funzione**: Estende linea fino a intersecare altra geometria

**Workflow**:
1. Click EXTEND tool
2. Click su linea da estendere
3. Linea si estende fino a primo oggetto che incontra

**Shortcut**: EX

---

### 10. OFFSET
**Funzione**: Crea copia parallela a distanza specifica

**Workflow**:
1. Click OFFSET tool
2. Click su linea originale
3. Input distanza: 10mm
4. Click lato dove offsettare

**Input Panel**:
- Distance: 10mm
- Side: Inside/Outside
- Chain: Yes/No (offset catena di linee connesse)

**Shortcut**: O

---

### 11. FILLET
**Funzione**: Raccorda angoli con arco

**Workflow**:
1. Click FILLET tool
2. Input radius: 5mm
3. Click prima linea
4. Click seconda linea
5. Angolo viene raccordato

**Input Panel**:
- Radius: 5mm
- Trim: Yes/No

**Shortcut**: F

---

### 12. CHAMFER
**Funzione**: Smussa angoli con linea retta

**Workflow**:
1. Click CHAMFER tool
2. Input distance: 5mm
3. Click prima linea
4. Click seconda linea

**Input Panel**:
- Distance 1: 5mm
- Distance 2: 5mm (può essere diversa)
- Angle: 45° (alternativa)

**Shortcut**: CH

---

### 13. MIRROR
**Funzione**: Specchia geometria rispetto a asse

**Workflow**:
1. Select oggetti da specchiare
2. Click MIRROR tool
3. Click start punto asse mirror
4. Click end punto asse mirror
5. Opzione: Keep original Yes/No

**Input Panel**:
- Mirror Line: Select existing line
- Keep Original: Yes/No

**Shortcut**: M

---

### 14. PATTERN - Linear
**Funzione**: Ripete geometria in pattern lineare

**Workflow**:
1. Select oggetti da patterizzare
2. Click PATTERN → Linear
3. Select direction (linea o asse)
4. Input distance: 20mm
5. Input quantity: 5

**Input Panel**:
- Direction: Vector or Line
- Distance: 20mm
- Quantity: 5
- Symmetric: Yes/No

---

### 15. PATTERN - Circular
**Funzione**: Ripete geometria in cerchio

**Workflow**:
1. Select oggetti
2. Click PATTERN → Circular
3. Select center point
4. Input quantity: 8
5. Input angle: 360° (full circle) o parziale

**Input Panel**:
- Center: X, Y
- Quantity: 8
- Angle: 360°
- Symmetric: Yes/No

---

### 16. SCALE
**Funzione**: Ridimensiona geometria

**Workflow**:
1. Select oggetti
2. Click SCALE
3. Select base point (pivot)
4. Input scale factor: 2.0 (200%)

**Input Panel**:
- Scale Factor: 2.0
- Base Point: X, Y
- Uniform: Yes / Non-uniform X, Y

**Shortcut**: SC

---

### 17. MOVE/COPY
**Funzione**: Sposta o copia geometria

**Workflow**:
1. Select oggetti
2. Click MOVE
3. Click start point
4. Click destination point
5. Toggle Copy mode per copiare invece di spostare

**Input Panel**:
- From Point: X, Y
- To Point: X, Y
- Copy: Yes/No
- Distance: Auto-calculated
- Angle: Auto-calculated

**Shortcut**: MV

---

## 🔗 CONSTRAINTS (6)

### 18. HORIZONTAL / VERTICAL
**Funzione**: Vincola linea ad essere esattamente H o V

**Workflow**:
1. Select line
2. Click HORIZONTAL o VERTICAL constraint
3. Linea diventa vincolata

**Icon**: H / V
**Auto-apply**: Durante disegno con Ortho mode

---

### 19. PARALLEL / PERPENDICULAR
**Funzione**: Vincola due linee parallele o perpendicolari

**Workflow**:
1. Select prima linea
2. Select seconda linea
3. Click PARALLEL o PERPENDICULAR
4. Linee diventano vincolate

**Icon**: // o ⊥

---

### 20. TANGENT
**Funzione**: Vincola linea/arco tangente a cerchio/arco

**Workflow**:
1. Select linea
2. Select cerchio/arco
3. Click TANGENT
4. Linea diventa tangente

**Icon**: ⌒─

---

### 21. COINCIDENT
**Funzione**: Vincola punto a stare su linea/punto

**Workflow**:
1. Select punto
2. Select linea o altro punto
3. Click COINCIDENT
4. Punto viene vincolato

**Icon**: •─

---

### 22. EQUAL
**Funzione**: Vincola lunghezze/raggi uguali

**Workflow**:
1. Select prima linea
2. Select seconda linea
3. Click EQUAL
4. Lunghezze diventano uguali

**Icon**: =

---

### 23. FIX/UNFIX
**Funzione**: Fissa geometria in posizione assoluta

**Workflow**:
1. Select oggetto
2. Click FIX
3. Oggetto non può più muoversi

**Icon**: 📌
**Shortcut**: X

---

## 📏 DIMENSIONS (3)

### 24. LINEAR DIMENSION
**Funzione**: Aggiunge dimensione lineare con quota

**Workflow**:
1. Click DIMENSION
2. Click primo punto
3. Click secondo punto
4. Click posizione testo
5. Input value: 100mm

**Display**:
- Frecce alle estremità
- Linee di estensione
- Testo con valore
- Modificabile (parametric)

**Shortcut**: D

---

### 25. ANGULAR DIMENSION
**Funzione**: Misura angolo tra due linee

**Workflow**:
1. Click DIMENSION
2. Click prima linea
3. Click seconda linea
4. Click posizione testo
5. Mostra angolo: 45°

**Shortcut**: DA

---

### 26. RADIAL / DIAMETER DIMENSION
**Funzione**: Dimensione raggio o diametro cerchio

**Workflow**:
1. Click DIMENSION
2. Click su cerchio/arco
3. Click posizione testo
4. Mostra R=50mm o Ø100mm

**Toggle**: R ↔ Ø

---

## 🔄 PROJECT Tools (2)

### 27. PROJECT
**Funzione**: Proietta geometria da altro sketch o faccia

**Workflow**:
1. Click PROJECT
2. Select geometria da proiettare
3. Geometria viene copiata come riferimento

**Opzioni**:
- Project as Construction
- Include hidden geometry

---

### 28. INTERSECT
**Funzione**: Crea geometria alle intersezioni

**Workflow**:
1. Click INTERSECT
2. Select due oggetti
3. Punto/linea di intersezione viene creato

---

## 🏗️ CONSTRUCTION Mode

**Funzione**: Crea geometria di costruzione (non verrà estrusa)

**Toggle**: Click Construction button
**Visual**: Linee tratteggiate grigie
**Uso**: Guide, assi di simmetria, riferimenti

---

## 🎯 Implementation Priority

### Phase 1 - Essential (Week 1)
✅ 1. Line (2-point, input)
✅ 2. Rectangle (2-point, input)
✅ 3. Circle (center-radius, input)
⬜ 4. Trim
⬜ 5. Offset
⬜ 6. Linear Dimension
⬜ 7. Horizontal/Vertical constraints

### Phase 2 - Important (Week 2)
⬜ 8. Arc (3-point)
⬜ 9. Fillet
⬜ 10. Mirror
⬜ 11. Move/Copy
⬜ 12. Parallel/Perpendicular constraints
⬜ 13. Tangent constraint
⬜ 14. Angular dimension

### Phase 3 - Advanced (Week 3)
⬜ 15. Polygon
⬜ 16. Spline
⬜ 17. Pattern (Linear, Circular)
⬜ 18. Chamfer
⬜ 19. Equal constraint
⬜ 20. Radial dimension

### Phase 4 - Professional (Week 4)
⬜ 21. Extend
⬜ 22. Scale
⬜ 23. Project
⬜ 24. Intersect
⬜ 25. Construction mode
⬜ 26. Coincident/Midpoint
⬜ 27. Fix/Unfix
⬜ 28. Point tool

---

## 📊 Technical Specifications

### Precision
- **Coordinate precision**: 0.001mm (3 decimali)
- **Angle precision**: 0.01° (2 decimali)
- **Snap tolerance**: 0.1mm in world space

### Performance
- **Max objects**: 10,000 per sketch
- **Max constraints**: 5,000 per sketch
- **Undo levels**: 100

### File Format
- **Internal**: JSON con coordinate world
- **Export DXF**: R14 compatible
- **Export SVG**: mm units, precision 3 decimals

---

## 🔧 Implementation Notes

### Constraint Solver
- Usa algoritmo **iterativo** (Newton-Raphson)
- Risolve sistema di equazioni in real-time
- Max 100 iterazioni per convergenza
- Fallback: mostra warning se non converge

### Dimension System
- **Parametric**: Modifichi dimensione → geometria si aggiorna
- **Driven**: Dimensione segue geometria (read-only)
- **Variables**: Nome variabili tipo `length1`, `radius2`

### Snap System
**Priorità snap**:
1. Grid points (se snap grid attivo)
2. Endpoint (punti finali linee)
3. Midpoint (punti medi)
4. Center (centri cerchi/archi)
5. Intersection (intersezioni calcolate)
6. On curve (punto più vicino su curva)

---

Questo documento serve come **blueprint completo** per implementare un CAD sketch engine professionale tipo Fusion 360 per packaging design.
