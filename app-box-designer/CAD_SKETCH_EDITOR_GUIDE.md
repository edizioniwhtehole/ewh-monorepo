# 📐 CAD Sketch Editor - Guida Utente

## Panoramica

Il CAD Sketch Editor è un editor grafico professionale per disegnare fustelle a mano libera. Permette di creare die-lines personalizzate con precisione millimetrica, utilizzando linee di taglio, piega, perforazione e bleed.

## Accesso

**URL**: http://localhost:3350/cad-sketch.html

L'editor è un file HTML standalone che funziona direttamente nel browser senza necessità di compilazione React/TypeScript.

## Interfaccia Utente

### Toolbar (Barra degli Strumenti)

| Controllo | Descrizione |
|-----------|-------------|
| **Tipo Linea** | Selettore per scegliere il tipo di linea: Taglio (🔴), Piega (🔵), Perforazione (🟣), Bleed (🟢) |
| **Snap Grid** | Checkbox per attivare/disattivare lo snap alla griglia (10mm) |
| **Mostra Griglia** | Checkbox per mostrare/nascondere la griglia |
| **✔️ Fine Linea** | Termina la linea corrente e la aggiunge al disegno |
| **🔄 Chiudi Forma** | Chiude la forma corrente collegando l'ultimo punto al primo |
| **⬅️ Undo** | Rimuove l'ultima linea disegnata |
| **🗑️ Cancella Tutto** | Cancella l'intero disegno (con conferma) |
| **💾 Salva Template** | Salva il disegno come template nel database |
| **📥 Export JSON** | Esporta il disegno in formato JSON |

### Canvas (Area di Disegno)

- **Dimensioni**: 1200×800 px
- **Griglia**:
  - Linee sottili ogni 10mm (snap grid)
  - Linee spesse ogni 100mm (riferimento)
  - Assi X/Y in grassetto all'origine
- **Cursore**: Crosshair per precisione di disegno
- **Offset**: Margine di 50px dall'origine

### Sidebar (Pannello Statistiche)

Mostra informazioni in tempo reale sul disegno:

- **Totale Linee**: Numero di linee completate
- **Punti Attuali**: Numero di punti nella linea in corso
- **Dimensioni (mm)**: Larghezza × Altezza del bounding box
- **Area (cm²)**: Area totale del disegno

#### Legenda Linee

- 🔴 **Taglio (Cut)**: Rosso solido, 2px - Linea di taglio principale
- 🔵 **Piega (Crease)**: Blu tratteggiato (5,5), 1px - Linea di piega
- 🟣 **Perforazione**: Magenta tratteggiato (2,3), 1px - Linea di perforazione
- 🟢 **Bleed**: Verde solido, 0.5px - Linea di bleed/smarginatura

## Workflow di Disegno

### 1. Disegnare una Polilinea

```
1. Seleziona il tipo di linea dal menu a tendina
2. Click sulla griglia per aggiungere il primo punto
3. Click per aggiungere punti successivi
4. Click su "Fine Linea" per completare la polilinea
```

**Esempio**: Disegnare un rettangolo di taglio 200×100mm

```
1. Seleziona "🔴 Taglio (Cut)"
2. Assicurati che "Snap Grid" sia attivo
3. Click su (0,0)
4. Click su (200,0)
5. Click su (200,100)
6. Click su (0,100)
7. Click su "🔄 Chiudi Forma" per chiudere il rettangolo
```

### 2. Disegnare Linee di Piega

```
1. Seleziona "🔵 Piega (Crease)"
2. Disegna la linea di piega all'interno della forma
3. Click su "Fine Linea"
```

### 3. Salvare il Template

```
1. Click su "💾 Salva Template"
2. Inserisci il nome del template (es: "Secchiello Piramidale Custom")
3. Il sistema salva il template nel database con:
   - Configurazione delle linee
   - Dimensioni calcolate automaticamente
   - Preview SVG generato automaticamente
   - Metadati (data, versione, unità)
```

**Output del salvataggio**:
```json
{
  "name": "Custom Dieline 15/10/2025",
  "description": "Disegno CAD manuale",
  "category": "custom",
  "base_config": {
    "type": "custom",
    "dimensions": {
      "width": 200,
      "height": 100,
      "minX": 0,
      "minY": 0,
      "maxX": 200,
      "maxY": 100
    }
  },
  "dieline": {
    "lines": [...],
    "version": "1.0",
    "units": "mm"
  },
  "preview_svg": "<svg>...</svg>",
  "is_public": false
}
```

### 4. Esportare il Disegno

```
1. Click su "📥 Export JSON"
2. Il browser scarica un file JSON con tutte le linee
3. Formato file: dieline-{timestamp}.json
```

**Struttura JSON esportato**:
```json
[
  {
    "id": "line-1634567890123",
    "type": "cut",
    "points": [
      { "x": 0, "y": 0 },
      { "x": 200, "y": 0 },
      { "x": 200, "y": 100 },
      { "x": 0, "y": 100 }
    ],
    "closed": true
  },
  {
    "id": "line-1634567890456",
    "type": "crease",
    "points": [
      { "x": 100, "y": 0 },
      { "x": 100, "y": 100 }
    ],
    "closed": false
  }
]
```

## Funzionalità Avanzate

### Snap to Grid

Lo snap alla griglia (10mm) garantisce precisione industriale:

- **Attivo (default)**: I punti si allineano automaticamente alla griglia 10mm
- **Disattivo**: Precisione pixel-perfect (1px ≈ 0.26mm)

**Consiglio**: Lascia attivo lo snap per progetti reali, disattivalo solo per sketch concettuali.

### Griglia Multi-Scala

Il sistema di griglia è ottimizzato per lavorare su diverse scale:

- **10mm**: Griglia fine per precisione millimetrica
- **100mm**: Griglia spessa per riferimento centimetrico
- **Assi**: Evidenziati per identificare l'origine

### Calcolo Automatico Dimensioni

Il sistema calcola in tempo reale:

- **Bounding Box**: Min/Max X/Y di tutti i punti
- **Dimensioni**: Larghezza × Altezza
- **Area**: In cm² per calcoli di materiale

### Generazione Preview SVG

Al momento del salvataggio, il sistema genera automaticamente un preview SVG:

- Scala automatica per fit nel viewport
- Margine di 50px per visualizzazione
- Colori e stili fedeli al tipo di linea
- Compatibile con tutti i renderer SVG

## Integrazione Backend

### API Endpoint: POST /api/box/templates

Il CAD editor si integra con il backend Box Designer per salvare i template:

**Request**:
```http
POST http://localhost:5850/api/box/templates
Content-Type: application/json
Authorization: Bearer dev-token

{
  "name": "Custom Dieline",
  "description": "Disegno CAD manuale",
  "category": "custom",
  "base_config": { ... },
  "dieline": { ... },
  "preview_svg": "<svg>...</svg>",
  "is_public": false
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Custom Dieline",
    "created_at": "2025-10-15T10:30:00Z",
    ...
  }
}
```

### Fallback Locale

Se il backend non è disponibile:

1. Il sistema mostra un alert: "❌ Errore nel salvare il template. Salvato solo localmente."
2. I dati vengono loggati nella console browser
3. L'utente può copiarli manualmente per uso futuro

## Casi d'Uso

### 1. Secchiello Alimentare Piramidale

**Obiettivo**: Disegnare la fustella per un secchiello 8.5×8.5×20cm

**Procedura**:
```
1. Disegna la base quadrata 85×85mm (taglio rosso, forma chiusa)
2. Disegna i 4 pannelli laterali trapezoidali (taglio rosso)
3. Aggiungi linee di piega tra base e pannelli (piega blu)
4. Aggiungi linguette di incollaggio (taglio rosso + piega blu)
5. Aggiungi perforazioni per apertura (perforazione magenta)
6. Aggiungi bleed 3mm esterno (bleed verde)
7. Salva come "Secchiello Alimentare 85x85x200"
```

### 2. Scatola Astucci con Coperchio

**Obiettivo**: Fustella per astuccio 100×50×30mm

**Procedura**:
```
1. Disegna corpo principale con 4 pannelli + base (taglio + piega)
2. Disegna coperchio separato con alette (taglio + piega)
3. Aggiungi linguette di chiusura (taglio + perforazione)
4. Aggiungi fessure per inserimento (taglio)
5. Aggiungi bleed 3mm (bleed verde)
6. Salva come "Astuccio 100x50x30 con Coperchio"
```

### 3. Box Complesso con Finestra

**Obiettivo**: Scatola con finestra trasparente

**Procedura**:
```
1. Disegna corpo scatola standard
2. Disegna area finestra interna con taglio
3. Aggiungi margine interno 5mm per incollaggio plastica (crease)
4. Aggiungi rinforzi angolari (crease)
5. Salva come "Box con Finestra Custom"
```

## Tips & Best Practices

### ✅ Consigli

1. **Inizia sempre con la vista planare**: Disegna la fustella come se fosse appiattita
2. **Usa colori standard**: Rosso=taglio, Blu=piega - rispetta gli standard industriali
3. **Snap attivo per produzione**: Sempre attivo per progetti reali
4. **Salva frequentemente**: Usa "Salva Template" ogni 5-10 minuti
5. **Esporta JSON come backup**: Mantieni copie locali dei progetti importanti

### ❌ Errori Comuni

1. **Non chiudere le forme**: Forme aperte causano errori di produzione
2. **Dimenticare le linee di piega**: Senza pieghe, la scatola non si monta
3. **Bleed insufficiente**: Minimo 3mm per stampa professionale
4. **Punti sovrapposti**: Usa snap per evitare punti quasi coincidenti
5. **Dimensioni non realistiche**: Verifica area e dimensioni nella sidebar

## Risoluzione Problemi

### La griglia non si vede

**Soluzione**: Verifica che "Mostra Griglia" sia attivo nella toolbar

### I punti non si allineano

**Soluzione**: Attiva "Snap Grid (10mm)" nella toolbar

### Il salvataggio fallisce

**Cause possibili**:
- Backend non in esecuzione (verifica http://localhost:5850/health)
- Database non disponibile
- Autenticazione fallita

**Soluzione temporanea**: I dati sono nella console browser (F12), copia manualmente

### Le linee non sono visibili

**Cause possibili**:
- Colore troppo chiaro
- Linee fuori dal canvas
- Browser cache

**Soluzione**: Hard refresh (Cmd+Shift+R), verifica offset e dimensioni

## Sviluppi Futuri

### Prossime Feature Pianificate

- [ ] **Tool Rettangolo/Cerchio**: Disegno forme geometriche rapide
- [ ] **Tool Selezione**: Selezionare e modificare linee esistenti
- [ ] **Zoom e Pan**: Navigare canvas di grandi dimensioni
- [ ] **Dimensioni dinamiche**: Misure in tempo reale durante il disegno
- [ ] **Snap punti**: Snap a punti esistenti, non solo griglia
- [ ] **Layer system**: Organizzare linee su layer separati
- [ ] **Import DXF**: Importare die-lines da AutoCAD
- [ ] **Export DXF/PDF**: Esportare in formati standard industria
- [ ] **Template library**: Galleria templates salvati
- [ ] **Collaborative editing**: Editing in tempo reale multi-utente

## Riferimenti Tecnici

### Tecnologie Utilizzate

- **HTML5 Canvas API**: Rendering 2D ad alte prestazioni
- **Vanilla JavaScript**: Zero dipendenze, massima compatibilità
- **Fetch API**: Integrazione REST con backend
- **Blob API**: Export file JSON
- **localStorage**: Persistenza locale (future feature)

### Compatibilità Browser

| Browser | Versione Minima | Note |
|---------|----------------|------|
| Chrome | 90+ | ✅ Pieno supporto |
| Firefox | 88+ | ✅ Pieno supporto |
| Safari | 14+ | ✅ Pieno supporto |
| Edge | 90+ | ✅ Pieno supporto |

### Performance

- **Max Points**: ~10,000 punti (limite pratico per mantenere 60fps)
- **Max Lines**: ~1,000 linee
- **Canvas Size**: 1200×800px (ridimensionabile)
- **Grid Extent**: 2000×2000mm (2 metri)

## Citazioni e Riconoscimenti

Questo editor è stato sviluppato ispirandosi a:

- **ArtiosCAD** (Esko): Industry standard per packaging design
- **Pacdora**: Online box designer con funzionalità CAD
- **Adobe Illustrator**: Tool path e Bezier curves
- **AutoCAD**: Sistema griglia e snap

L'algoritmo di unfold 3D→2D è basato su:

**[paperfoldmodels](https://github.com/peppercat/paperfoldmodels)** by peppercat (MIT License)
> Python script for unfolding 3D meshes using minimum spanning tree algorithm

## Supporto

Per problemi o domande:

1. Verifica questa documentazione
2. Controlla la console browser (F12) per errori JavaScript
3. Verifica che backend sia in esecuzione
4. Controlla i log del backend: `docker logs box-designer`

---

**Versione**: 1.0
**Ultimo Aggiornamento**: 15 Ottobre 2025
**Autore**: Enterprise Work Hub - Box Designer Team
