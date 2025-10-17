# Aggiornamento v1.2 - Layout Realistico e Quotatura

## 🎯 Modifiche Principali

### 1. Sviluppo Planare Corretto (Flat Pattern Realistico)

#### ❌ Vecchio Layout (Errato)
Il precedente layout aveva i pannelli disposti a "croce" con i lati laterali attaccati in modo non realistico:

```
        [Top]
    [L] [Front] [R]
        [Base]
        [Back]
```

**Problema:** Questo non si piega correttamente nella vita reale!

#### ✅ Nuovo Layout (Corretto)

Ora i 4 lati trapezoidali sono disposti in sequenza orizzontale, come nella realtà del packaging professionale:

```
      [Flap T1] [Flap T2] [Flap T3] [Flap T4]
   [Side1] [Front] [Side2] [Back] [Gluing]
      [Flap B1] [Flap B2]
```

**Vantaggi:**
- ✅ Si piega correttamente in 3D
- ✅ Le cordonature sono nelle posizioni giuste
- ✅ Compatibile con macchine piegatrici reali
- ✅ Standard industriale FEFCO

#### Dettagli Tecnici

**4 Lati in Sequenza:**
1. **Side 1** (sinistro) - Trapezio (da topWidth a baseWidth)
2. **Front** (frontale) - Trapezio (da topLength a baseLength)
3. **Side 2** (destro) - Trapezio (da topWidth a baseWidth)
4. **Back** (posteriore) - Trapezio (da topLength a baseLength)

**Chiusure:**
- **Top flaps**: Alette sopra ogni lato (configurabili)
- **Bottom flaps**: Alette sotto Front e Back (configurabili)
- **Gluing flap**: Bandella di incollaggio finale

**Cordonature:**
- Verticali: Tra ogni coppia di pannelli
- Orizzontali: Tra pannelli e flaps

### 2. Sistema di Quotatura Automatica

#### Funzionalità

**Quote Orizzontali** (sopra la fustella):
- Larghezza Side 1 (topWidth)
- Larghezza Front (topLength)
- Larghezza Side 2 (topWidth)
- Larghezza Back (topLength)

**Quote Verticali** (sinistra della fustella):
- Altezza Top Flap
- Altezza corpo (slant height) con riferimento altezza box
- Altezza Bottom Flap

**Quote Riferimento** (sotto la fustella):
- Dimensioni base (baseWidth e baseLength)

#### Rendering Quote

- **Colore**: Arancione (#FF6B00)
- **Stile**: Linee con frecce alle estremità
- **Testo**: Dimensioni in millimetri
- **Formato**: `XXX mm` o `XXX mm (h=YYY mm)` per slant height

#### Controlli

- **Pulsante 📏**: Toggle on/off delle quote
- **Legenda**: Icona arancione con frecce
- **Default**: Quote attive alla prima visualizzazione

### 3. Calcoli Aggiornati

#### Slant Heights

Per scatole a tronco di piramide, il calcolo della "slant height" (altezza inclinata) è fondamentale:

```typescript
slantHeight = √(h² + ((topDim - baseDim)/2)²)
```

Dove:
- `h` = altezza verticale del box
- `topDim` = dimensione superiore (top)
- `baseDim` = dimensione inferiore (base)

**Due slant heights diversi:**
- `slantHeight1`: Per Front e Back (basato su Length)
- `slantHeight2`: Per Side1 e Side2 (basato su Width)

#### Dimensioni Totali Fustella

```typescript
Width = (2 × topWidth) + (2 × topLength) + gluingWidth + (2 × bleed)
Height = topFlapHeight + slantHeight + bottomFlapHeight + (2 × bleed)
```

## 📊 Esempio Pratico

### Input
```
Base: 120 × 120 mm (quadrata)
Top: 140 × 140 mm (quadrata)
Altezza: 80 mm
```

### Output Fustella

**Dimensioni Pannelli:**
- Side 1: 140mm (top) → 120mm (base), h = 83.2mm (slant)
- Front: 140mm (top) → 120mm (base), h = 83.2mm (slant)
- Side 2: 140mm (top) → 120mm (base), h = 83.2mm (slant)
- Back: 140mm (top) → 120mm (base), h = 83.2mm (slant)

**Flaps:**
- Top: 70mm (50% di topLength)
- Bottom: 48mm (40% di baseLength)

**Dimensioni Totali Fustella:**
- Larghezza: ~566mm
- Altezza: ~204mm

### Quote Visualizzate

```
[140] [140] [140] [140]  ← Larghezze top
  │     │     │     │
[70mm] ← Top flap
  │
[83mm (h=80mm)] ← Slant height
  │
[48mm] ← Bottom flap

Base: 120 mm × 120 mm  ← Riferimento
```

## 🎨 UI/UX

### Controlli Zoom (Esistenti)
- **+**: Zoom in
- **−**: Zoom out
- **⟲**: Reset vista
- **%**: Percentuale zoom

### Nuovo Controllo Quote
- **📏**: Toggle quotatura on/off
- Stato evidenziato: Arancione quando attivo, grigio quando off

### Legenda Aggiornata

```
━━━━━ Taglio (nero)
╌╌╌╌╌ Cordonatura (blu)
┈┈┈┈┈ Perforazione (rosso)
───── Guida sicurezza (verde)
←──→  Quotatura (arancione) [NUOVO]
```

## 🔧 Modifiche Codice

### File Modificati

1. **[dieline.generator.ts](src/utils/dieline.generator.ts)**
   - Riscritto completamente `generateTruncatedPyramidDieline()`
   - 4 pannelli in sequenza orizzontale
   - Generazione automatica quote
   - Calcolo corretto slant heights

2. **[box.types.ts](src/types/box.types.ts)**
   - Aggiunto type `Dimension`
   - Aggiunto campo opzionale `dimensions` in `FustellaData`

3. **[DielineViewer.tsx](src/components/DielineViewer.tsx)**
   - Rendering quote con frecce e testo
   - Toggle button per mostrare/nascondere
   - Legenda aggiornata
   - Marker SVG per frecce

### Nuove Strutture Dati

```typescript
interface Dimension {
  type: 'horizontal' | 'vertical' | 'diagonal';
  start: { x: number; y: number };
  end: { x: number; y: number };
  value: number; // mm
  label: string; // "120 mm"
  offset: number; // Distance from geometry
}
```

## 📐 Formule Matematiche

### Volume Tronco Piramide

```
V = h/3 × (A₁ + A₂ + √(A₁ × A₂))
```

Dove:
- `h` = altezza
- `A₁` = area base
- `A₂` = area top

### Slant Height

```
s = √(h² + Δ²)
```

Dove:
- `h` = altezza verticale
- `Δ` = (dimensione_top - dimensione_base) / 2

### Trapezoid Points

```typescript
// Trapezio che si restringe da top a base
points = [
  { x: x0, y: y0 },                           // Top left
  { x: x0 + topWidth, y: y0 },               // Top right
  { x: x0 + offset + baseWidth, y: y0 + h }, // Bottom right
  { x: x0 + offset, y: y0 + h },             // Bottom left
]

offset = (topWidth - baseWidth) / 2  // Centra il restringimento
```

## 🚀 Come Testare

### Test Layout Planare

1. Apri http://localhost:5900
2. Configura scatola tronco piramide:
   - Base: 120×120mm
   - Top: 140×140mm
   - Altezza: 80mm
3. Vai su tab "Fustella"
4. **Verifica:**
   - 4 pannelli in sequenza orizzontale
   - Chiusure sopra e sotto
   - Cordonature verticali tra pannelli

### Test Quotatura

1. Nella vista fustella, clicca pulsante **📏**
2. **Verifica:**
   - Quote arancioni con frecce
   - Dimensioni corrette in mm
   - Testo leggibile

3. Zoom 200-300%
4. **Verifica:**
   - Quote scalano correttamente
   - Testo rimane leggibile
   - Frecce proporzionate

### Test Esportazione

1. Esporta in SVG
2. Apri con Illustrator/Inkscape
3. **Verifica:**
   - Quote esportate correttamente
   - Layer separati per quote
   - Colori corretti

## 📚 Riferimenti Tecnici

### Standard Packaging

- **FEFCO**: Standard internazionale per scatole corrugate
- **ECMA**: Standard europeo per fustelle
- **ISO 5636**: Standard dimensionamento packaging

### Terminologia

- **Flat Pattern**: Sviluppo piano della scatola
- **Die-line**: Fustella con linee di taglio e piega
- **Slant Height**: Altezza inclinata (lato obliquo)
- **Quotatura**: Sistema di dimensionamento tecnico
- **Crease**: Cordonatura (linea di piega)
- **Perforation**: Linea tratteggiata per strappo

## 🎓 Best Practices

### Design Scatole

1. **Tolleranze**: Aggiungi 2-3mm per prodotti rigidi
2. **Spessore carta**: Considera nello sviluppo
3. **Direzione fibra**: Importante per piegatura
4. **Cordonature**: Distanza minima 5mm da bordi

### Quote

1. **Visibilità**: Offset 20mm da geometria
2. **Chiarezza**: Font 10pt minimo
3. **Colore**: Usa colori che contrastano (arancione su bianco)
4. **Riferimenti**: Indica sempre dimensioni base

### Export

1. **SVG**: Per editing grafico
2. **DXF**: Per macchine CNC
3. **PDF**: Per approvazione cliente
4. **PLT**: Per plotter da taglio

## 🐛 Bug Fixes

### Risolti in v1.2

- ✅ Layout planare non realistico
- ✅ Pannelli laterali mal posizionati
- ✅ Cordonature in posizioni sbagliate
- ✅ Impossibilità di vedere dimensioni esatte
- ✅ Calcolo slant height impreciso

## 🔮 Prossimi Step

### v1.3 - Miglioramenti Quotatura

- [ ] Quote diagonali per slant edges
- [ ] Quote per angoli trapezoidali
- [ ] Quote per bandelle incollaggio
- [ ] Toggle quote per singola categoria
- [ ] Export quote in layer separato

### v1.4 - Templates Avanzati

- [ ] Template FEFCO standard
- [ ] Database box patterns
- [ ] Importazione template esistenti
- [ ] Salvataggio configurazioni personalizzate

### v1.5 - Simulazione 3D Realistica

- [ ] Animazione piegatura
- [ ] Test resistenza virtuale
- [ ] Simulazione montaggio
- [ ] Preview prodotto finale nel box

---

**BoxDesigner CAD v1.2** - Layout professionale, quote automatiche, standard industriale.

*Aggiornato: 15 Ottobre 2025*
