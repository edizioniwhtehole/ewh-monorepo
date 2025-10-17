# Librerie e Strumenti per Design Packaging

Risposta alla domanda: "Esistono librerie in grado di aiutare a fare lavori complessi?"

## 📚 Librerie JavaScript/TypeScript per Packaging

### 1. Geometric Libraries

#### **Paper.js** (Usata nel progetto)
```bash
npm install paper
```

**Utilizzo:**
- Manipolazione vettoriale avanzata
- Path operations (union, intersect, subtract)
- Generazione curve complesse
- Export SVG perfetto

**Esempio:**
```javascript
import paper from 'paper';

const path = new paper.Path();
path.add(new paper.Point(0, 0));
path.add(new paper.Point(100, 0));
// Operazioni booleane
const result = path1.unite(path2);
```

#### **Three.js + React Three Fiber** (Usata nel progetto)
```bash
npm install three @react-three/fiber @react-three/drei
```

**Utilizzo:**
- Rendering 3D scatole
- Preview realistico
- Simulazione piegatura
- Export modelli 3D

### 2. CAD/Technical Drawing

#### **Makerjs**
```bash
npm install makerjs
```

**Vantaggi:**
- Specifico per CAD 2D
- Generazione automatica di forme
- Path operations
- Export DXF, SVG, PDF

**Esempio:**
```javascript
import makerjs from 'makerjs';

const box = new makerjs.models.Rectangle(100, 50);
const rounded = makerjs.model.outline(box, 5); // Angoli arrotondati
const svg = makerjs.exporter.toSVG(rounded);
```

#### **OpenJSCAD**
```bash
npm install @jscad/modeling
```

**Utilizzo:**
- CAD 3D parametrico
- Generazione solidi complessi
- Export STL, OBJ, AMF
- Ideale per packaging 3D printed

### 3. PDF Generation

#### **jsPDF** (Usata nel progetto)
```bash
npm install jspdf
```

**Utilizzo:**
- Export fustelle in PDF
- Multi-page layouts
- Supporto vettoriale

#### **PDFKit**
```bash
npm install pdfkit
```

**Vantaggi:**
- Più avanzato di jsPDF
- Supporto annotazioni
- Livelli (layers)
- Metadata completi

### 4. Nesting/Bin Packing

#### **potpack** (Alternative nel progetto)
```bash
npm install potpack
```

**Utilizzo:**
- Bin packing 2D veloce
- Ottimizzazione materiale
- Algoritmo Skyline

#### **binpack**
```bash
npm install binpack
```

**Alternative:**
- `2d-bin-pack`
- `bin-packing`
- `guillotine-bin-pack`

### 5. Geometry Operations

#### **@turf/turf**
```bash
npm install @turf/turf
```

**Utilizzo:**
- Operazioni geometriche avanzate
- Buffer, offset, union
- Calcoli area, perimetro
- Intersezioni

**Esempio:**
```javascript
import * as turf from '@turf/turf';

const polygon = turf.polygon([coordinates]);
const buffered = turf.buffer(polygon, 5, {units: 'millimeters'});
const area = turf.area(polygon);
```

#### **polygon-clipping**
```bash
npm install polygon-clipping
```

**Utilizzo:**
- Operazioni booleane su poligoni
- Union, intersection, difference, xor
- Molto veloce
- Robusto per casi complessi

### 6. DXF Import/Export

#### **dxf-writer**
```bash
npm install dxf-writer
```

**Utilizzo:**
- Generazione DXF per AutoCAD
- Supporto layer
- Linee, poligoni, curve

#### **dxf-parser**
```bash
npm install dxf-parser
```

**Utilizzo:**
- Lettura file DXF
- Import template esistenti
- Conversione a JSON

### 7. SVG Advanced

#### **svg-pathdata**
```bash
npm install svg-pathdata
```

**Utilizzo:**
- Parse e manipolazione path SVG
- Transformazioni
- Normalizzazione

#### **roughjs**
```bash
npm install roughjs
```

**Utilizzo:**
- Rendering sketch-style
- Preview mockup
- Effetti hand-drawn

## 🏭 Strumenti Specifici Packaging

### **PackagingCalculator.js**
```bash
npm install packaging-calculator
```

**Funzioni:**
- Calcolo automatico dimensioni
- Ottimizzazione spessore materiale
- Resistenza strutturale
- Costi materiali

### **FEFCO Library**
```bash
npm install fefco-templates
```

**Contenuto:**
- Template FEFCO standard (200+ modelli)
- Parametrizzazione automatica
- Export multi-formato

### **DieLine Generator**
```bash
npm install dieline-gen
```

**Features:**
- Generazione automatica fustelle
- Supporto forme complesse
- Cordonature automatiche

## 🎨 Design e Mockup

### **Fabric.js**
```bash
npm install fabric
```

**Utilizzo:**
- Canvas interattivo
- Manipolazione oggetti
- Export alta qualità
- Editing artwork su packaging

### **Konva**
```bash
npm install konva react-konva
```

**Utilizzo:**
- Canvas 2D performante
- Drag & drop elementi
- Preview interattivo packaging

## 📐 Calcoli Tecnici

### **mathjs**
```bash
npm install mathjs
```

**Utilizzo:**
- Calcoli matematici avanzati
- Formule packaging complesse
- Unità di misura
- Matrici per transformazioni

**Esempio:**
```javascript
import math from 'mathjs';

// Calcolo volume tronco piramide
const volume = math.evaluate('h/3 * (A1 + A2 + sqrt(A1*A2))', {
  h: 80,
  A1: 144, // base area
  A2: 196  // top area
});
```

### **units-converter**
```bash
npm install units-converter
```

**Utilizzo:**
- Conversioni mm ↔ inches ↔ cm
- Compatibilità standard internazionali

## 🔧 Strumenti Professionali

### **OpenSCAD** (via CLI)
```bash
# Installazione system-wide
brew install openscad  # macOS
apt install openscad   # Linux
```

**Utilizzo:**
- CAD 3D parametrico
- Scripting avanzato
- Export produzione

### **Inkscape** (via CLI)
```bash
npm install inkscape-cli
```

**Utilizzo:**
- Batch processing SVG
- Conversioni automatiche
- Ottimizzazioni vettoriali

## 💡 Raccomandazioni per BoxDesigner

### Attualmente Usate ✅
- Three.js + React Three Fiber → 3D preview
- jsPDF → Export PDF
- Paper.js → Manipolazione vettoriale (opzionale)

### Da Aggiungere 🎯

#### Priorità Alta
1. **@turf/turf** → Operazioni geometriche avanzate
   - Offset per bleed automatico
   - Buffer per margini
   - Intersezioni per validazione

2. **makerjs** → CAD operations
   - Operazioni booleane su path
   - Generazione automatica forme
   - Export DXF migliorato

3. **mathjs** → Calcoli complessi
   - Formule packaging standardizzate
   - Conversioni unità
   - Calcoli resistenza

#### Priorità Media
4. **polygon-clipping** → Operazioni poligoni
   - Merge di parti multiple
   - Risoluzione intersezioni

5. **fefco-templates** → Template standard
   - Libreria forme FEFCO
   - Rapid prototyping

#### Priorità Bassa
6. **fabric.js** → Artwork editor
   - Posizionamento grafica
   - Preview stampa

## 📖 Esempi Pratici

### Esempio 1: Offset automatico con Turf

```javascript
import * as turf from '@turf/turf';

// Crea poligono fustella
const dieline = turf.polygon([[
  [0, 0], [100, 0], [100, 50], [0, 50], [0, 0]
]]);

// Bleed automatico 3mm
const withBleed = turf.buffer(dieline, 3, {units: 'millimeters'});

// Calcola area materiale
const area = turf.area(withBleed);
```

### Esempio 2: Nesting con potpack

```javascript
import potpack from 'potpack';

const boxes = [
  { w: 100, h: 150 },
  { w: 120, h: 80 },
  { w: 90, h: 90 }
];

const result = potpack(boxes);
console.log(result.w, result.h); // Sheet dimensions
console.log(result.fill); // Efficiency %
```

### Esempio 3: DXF export con makerjs

```javascript
import makerjs from 'makerjs';

const box = {
  models: {
    side1: new makerjs.models.Rectangle(100, 80),
    side2: new makerjs.models.Rectangle(120, 80)
  }
};

const dxf = makerjs.exporter.toDXF(box);
// Download DXF file
```

## 🔮 Future Libraries

### In Sviluppo
- **packaging-optimizer** → AI-powered optimization
- **structural-sim** → Simulazione resistenza
- **cost-calculator** → Calcolo costi produzione

### Emergenti
- **webgl-packaging** → Rendering WebGL ultra-veloce
- **ar-preview** → Preview AR mobile
- **blockchain-tracking** → Tracciabilità materiali

## 📚 Risorse

### Documentazione
- [Paper.js Tutorials](http://paperjs.org/tutorials/)
- [Three.js Journey](https://threejs-journey.com/)
- [Makerjs Documentation](https://maker.js.org/)

### Community
- [Stack Overflow - packaging-design](https://stackoverflow.com/questions/tagged/packaging-design)
- [Reddit r/packaging](https://reddit.com/r/packaging)
- [FEFCO Official](https://www.fefco.org/)

### Standards
- ISO 5636: Packaging dimensions
- ECMA: European standards
- FEFCO: Corrugated board standards

---

**Conclusione:** Sì, esistono moltissime librerie! La chiave è combinarle nel modo giusto per il tuo use case specifico. BoxDesigner usa già le librerie principali, e può essere esteso con quelle suggerite sopra per funzionalità avanzate.
