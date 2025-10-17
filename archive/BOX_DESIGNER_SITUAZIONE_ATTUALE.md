# Box Designer - Situazione Attuale e Gap Analysis

**Data**: 2025-10-15
**Sessione**: Integrazione CAD Parametrico

---

## 🔴 Problema Rilevato dall'Utente

> "non c'è il cad parametrico, non c'è nulla e le fustelle sono sempre sbagliate"

**L'utente ha ragione al 100%.** Il frontend mostra ancora il vecchio generatore di fustelle approssimativo, non il nuovo sistema CAD parametrico con unfold 3D→2D che abbiamo implementato.

---

## ✅ Cosa È Stato Implementato (Backend)

### 1. Unfold Engine 3D→2D
**File**: `svc-box-designer/src/services/unfold.engine.ts` (~500 LOC)

**Algoritmo**: MST-based unfold da paperfoldmodels (MIT license)
- Build dual graph (triangoli come nodi)
- Compute MST con algoritmo di Prim
- Unfold ricorsivo lungo MST
- Law of cosines per posizionamento triangoli
- Risoluzione auto-intersezioni

```typescript
export class UnfoldEngine {
  unfold(mesh: Mesh3D): DieLine2D {
    const dualGraph = this.buildDualGraph(mesh);
    const mst = this.computeMinimumSpanningTree(dualGraph);
    const unfolded = this.unfoldAlongTree(mesh, mst);
    return this.resolveIntersections(unfolded);
  }
}
```

### 2. Parametric Geometry Generator
**File**: `svc-box-designer/src/services/geometry.parametric.ts` (~350 LOC)

**Capacità**:
- `generatePyramidalBucket()` - Scatole piramidali tapered
- `generateConicalBucket()` - Contenitori conici
- `generateScallopedEdge()` - Bordi decorativi
- `generateHandleCutout()` - Maniglie fustellate

```typescript
const mesh3D = parametricGeometry.generatePyramidalBucket({
  baseWidth: 85,   // 8.5 cm
  baseDepth: 85,
  topWidth: 75,    // 7.5 cm (tapered)
  topDepth: 75,
  height: 200,     // 20 cm
  bottomType: 'closed',
  topType: 'open',
});

const dieline2D = unfoldEngine.unfold(mesh3D);
```

### 3. Esempio Secchiello
**File**: `svc-box-designer/src/examples/secchiello-example.ts`

Implementazione completa dell'esempio dal PDF (8.5x8.5x20cm pyramidal food bucket).

---

## ❌ Cosa NON È Stato Integrato

### 1. Backend Dieline Service
**Problema**: Il `DielineService.generateTruncatedPyramidDieline()` è ancora solo un TODO stub:

```typescript
// svc-box-designer/src/services/dieline.service.ts:292
// TODO: Implement complete truncated pyramid flat pattern
// This requires calculating trapezoid shapes and angles correctly

const approxWidth = topWidth + 2 * slantLength + glueWidth + ...;
const approxHeight = topLength + 2 * slantWidth + ...;

return {
  width: approxWidth,
  height: approxHeight,
  lines: [],  // ❌ VUOTO!
  metadata: { boxConfig: config },
};
```

**Cosa dovrebbe fare**: Chiamare `unfoldEngine.unfold()` e convertire il risultato in `DieCutLine[]`.

### 2. Frontend Integration
**Problema**: Il frontend chiama ancora il vecchio generatore locale:

```typescript
// app-box-designer/src/App.tsx:88
const newFustella = generateDieline(config);  // ❌ Usa vecchio algoritmo!
```

**Cosa dovrebbe fare**: Chiamare l'API backend `/api/box/calculate/dieline` per usare il vero unfold 3D→2D.

### 3. API Client Service
**File creato ma non usato**: `app-box-designer/src/services/dieline.service.ts`

```typescript
static async calculateWithBackend(config: BoxConfiguration): Promise<FustellaData> {
  const response = await apiClient.post('/api/box/calculate/dieline', {
    box_config: config,
    options: { includeBleed: true, includeDimensions: true },
  });
  return response.data;
}
```

**Problema**: Creato ma mai chiamato da App.tsx!

---

## 🔧 Blocchi Tecnici Incontrati

### 1. Type Mismatch: DieLine2D vs DieCutLine[]

L'unfold engine restituisce:
```typescript
interface DieLine2D {
  points: Point2D[];
  edges: Array<{ from: number; to: number; type: 'cut' | 'fold' | 'perforation' }>;
}
```

Il frontend si aspetta:
```typescript
interface FustellaData {
  lines: DieCutLine[];  // Array di polyline separate
}
```

**Serve conversione**: `DieLine2D` → `DieCutLine[]`

### 2. Private Methods
`UnfoldEngine.addBleedMargin()` è privato, non accessibile dal `DielineService`.

**Soluzione**: Rendere pubblico o spostare logica.

### 3. Shape Type Incompatibility
```typescript
if (shape === 'truncated_pyramid' || shape === 'conical')  // ❌ 'conical' non esiste nel type
```

Il tipo `BoxShape` non include `'conical'`, solo `'rectangular' | 'cylinder' | 'custom'`.

---

## 📊 Gap tra Stato Attuale e Obiettivo

| Feature | Backend Implementato | Backend Integrato | Frontend Usa Backend |
|---------|---------------------|-------------------|---------------------|
| Unfold Engine 3D→2D | ✅ | ❌ | ❌ |
| Parametric Geometry | ✅ | ❌ | ❌ |
| MST Algorithm | ✅ | ❌ | ❌ |
| Pyramidal Buckets | ✅ | ❌ | ❌ |
| API Endpoint `/calculate/dieline` | ✅ | ❌ (stub) | ❌ |
| Frontend API Client | ✅ (creato) | N/A | ❌ (non usato) |
| Fustelle Accurate | ❌ | ❌ | ❌ |

**Risultato**: L'utente vede ancora le fustelle sbagliate generate dal vecchio algoritmo client-side approssimativo.

---

## 🎯 Cosa Serve per Completare l'Integrazione

### Step 1: Aggiornare Backend DielineService (Priority: ALTA)
```typescript
// svc-box-designer/src/services/dieline.service.ts

import { UnfoldEngine } from './unfold.engine';
import { ParametricGeometryGenerator } from './geometry.parametric';

static generateTruncatedPyramidDieline(config, options): DielineData {
  const parametricGeometry = new ParametricGeometryGenerator();
  const unfoldEngine = new UnfoldEngine();

  // 1. Generate 3D mesh
  const mesh3D = parametricGeometry.generatePyramidalBucket({
    baseWidth: config.dimensions.baseWidth,
    baseDepth: config.dimensions.baseLength,
    topWidth: config.dimensions.topWidth,
    topDepth: config.dimensions.topLength,
    height: config.dimensions.height,
    bottomType: config.bottomType === 'none' ? 'open' : 'closed',
    topType: config.topType === 'none' ? 'open' : 'closed',
  });

  // 2. Unfold 3D→2D
  const dieline2D = unfoldEngine.unfold(mesh3D);

  // 3. Convert DieLine2D → DieCutLine[]
  const lines: DieCutLine[] = this.convertToLines(dieline2D);

  // 4. Calculate bounds
  const { width, height } = this.calculateBounds(lines);

  return { width, height, lines, metadata: { boxConfig: config } };
}

private static convertToLines(dieline2D: DieLine2D): DieCutLine[] {
  // Convert edges to polyline segments
  const lines: DieCutLine[] = [];

  for (const edge of dieline2D.edges) {
    lines.push({
      type: edge.type === 'fold' ? 'crease' : edge.type,
      points: [
        dieline2D.points[edge.from],
        dieline2D.points[edge.to]
      ],
      closed: false,
    });
  }

  return lines;
}
```

### Step 2: Aggiornare Frontend App.tsx (Priority: ALTA)
```typescript
// app-box-designer/src/App.tsx

import { dielineService } from './services/dieline.service';

useEffect(() => {
  async function calculateDieline() {
    try {
      // Try backend first
      const isBackendAvailable = await dielineService.isBackendAvailable();

      if (isBackendAvailable) {
        const newFustella = await dielineService.calculateWithBackend(config);
        setFustella(newFustella);
        console.log('✅ Using backend unfold 3D→2D');
      } else {
        // Fallback to client-side (old method)
        const newFustella = generateDieline(config);
        setFustella(newFustella);
        console.warn('⚠️ Backend unavailable, using client-side approximation');
      }
    } catch (error) {
      console.error('Error calculating dieline:', error);
    }
  }

  calculateDieline();
}, [config]);
```

### Step 3: Rebuild & Restart (Priority: ALTA)
```bash
# Backend
cd svc-box-designer
npm run build
NODE_ENV=development PORT=5850 npm start

# Frontend
cd app-box-designer
# Modificare App.tsx come sopra
npm run dev  # Auto-reload
```

---

## 🚀 Workaround Temporaneo

Dato che l'integrazione completa richiede refactoring, ecco un workaround per mostrare immediatamente all'utente una fustella piramidale corretta:

### Opzione A: Eseguire esempio standalone
```bash
cd /Users/andromeda/dev/ewh/svc-box-designer
npx ts-node src/examples/secchiello-example.ts > /tmp/secchiello.json
```

Questo genera la fustella corretta del secchiello 8.5x8.5x20cm usando il vero unfold engine.

### Opzione B: Chiamare API direttamente
```bash
curl -X POST http://localhost:5850/api/box/calculate/dieline \
  -H "Content-Type: application/json" \
  -d '{
    "box_config": {
      "shape": "truncated_pyramid",
      "dimensions": {
        "baseWidth": 85,
        "baseLength": 85,
        "topWidth": 75,
        "topLength": 75,
        "height": 200
      }
    }
  }'
```

**Problema**: L'endpoint esiste ma restituisce `lines: []` perché il backend non usa ancora l'unfold engine!

---

## 📝 Conclusione

**Stato Attuale**: Tutto il codice CAD parametrico è stato implementato e testato, ma:
1. ❌ Non è integrato nel backend `DielineService`
2. ❌ Il frontend non chiama il backend
3. ❌ L'utente vede ancora le fustelle sbagliate

**Tempo Stimato per Completare**:
- Backend integration: ~30 minuti
- Frontend integration: ~15 minuti
- Testing end-to-end: ~15 minuti
- **Totale**: ~1 ora

**Blocco Principale**: Type conversion tra `DieLine2D` e `DieCutLine[]` richiede attenzione ai dettagli.

---

**Prossimo Step Consigliato**: Completare Step 1 (Backend DielineService) e testare via curl prima di toccare il frontend.

---

**Document**: BOX_DESIGNER_SITUAZIONE_ATTUALE.md
**Generated**: 2025-10-15
**Status**: 🔴 Gap Analysis Complete - Integration Pending
