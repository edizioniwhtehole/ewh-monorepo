# DAM - Sistema Layout a Colonne ✅

## Problema Risolto
I pannelli si sovrapponevano e l'Asset Browser occupava sempre tutta la pagina, anche quando doveva stare in una colonna specifica.

## Soluzione: Layout Presets con Colonne

Ora hai un **selettore di layout** in alto che ti permette di organizzare l'interfaccia in diverse configurazioni:

### 🎨 Layout Disponibili

#### 1. **Singola Colonna** (□)
- Solo l'area centrale visibile
- Asset Browser occupa tutta la larghezza
- Ideale per focus totale sul contenuto

#### 2. **2 Colonne (Sinistra)** (|□)
- Sidebar sinistra + Centro
- Filters a sinistra, Asset Browser al centro
- Preview e Details nascosti

#### 3. **2 Colonne (Destra)** (□|)
- Centro + Sidebar destra  
- Asset Browser al centro, Preview/Details a destra
- Filters nascosto

#### 4. **3 Colonne** (|□|) - **DEFAULT**
- Sidebar Sx + Centro + Sidebar Dx
- Filters a sinistra, Asset Browser al centro, Preview/Details a destra
- Massima organizzazione

## Come Funziona

### Selettore Layout
- Barra in alto con 4 pulsanti
- Click su un layout per applicarlo istantaneamente
- Layout selezionato evidenziato in blu
- Icone intuitive per ogni configurazione

### Aree di Ancoraggio

#### **Left** (Sidebar Sinistra)
- Pannelli verticali impilati
- Larghezza ridimensionabile (150-800px)
- Ideale per: Filters, Tools, Navigation

#### **Center** (Area Centrale)
- Pannelli che occupano tutto lo spazio centrale
- Si espande automaticamente in base alle colonne visibili
- Ideale per: Asset Browser, Main Content, Editor

#### **Right** (Sidebar Destra)
- Pannelli verticali impilati
- Larghezza ridimensionabile (150-800px)
- Ideale per: Preview, Details, Properties

### Comportamento Pannelli

#### Pannelli nell'area Center
- **Si espandono solo nell'area centrale**
- Non si sovrappongono alle sidebar
- La larghezza si adatta automaticamente quando nascondi/mostri le colonne
- Esempio: Asset Browser in layout "Singola" = full width, in "3 Colonne" = solo centro

#### Pannelli nelle Sidebar
- Restano sempre nelle loro colonne
- Non invadono l'area centrale
- Si impilano verticalmente se multipli

## Implementazione Tecnica

### Nuovi Types
```typescript
type PanelPosition = 'floating' | 'left' | 'right' | 'top' | 'bottom' | 'center';
type LayoutPreset = 'single' | 'two-column-left' | 'two-column-right' | 'three-column' | 'custom';

interface LayoutConfig {
  preset: LayoutPreset;
  showLeft: boolean;
  showRight: boolean;
  showTop: boolean;
  showBottom: boolean;
}
```

### Componenti Creati

#### 1. **LayoutSelector** 
File: [src/components/dockable/LayoutSelector.tsx](app-dam/src/components/dockable/LayoutSelector.tsx)
- Barra di selezione layout
- 4 pulsanti preset
- Icone Lucide (Square, Columns2, Columns3, LayoutGrid)
- Connesso allo store Zustand

#### 2. **DockableWorkspace (Updated)**
File: [src/components/dockable/DockableWorkspace.tsx](app-dam/src/components/dockable/DockableWorkspace.tsx)
- Supporto per area `center`
- Visibilità colonne basata su `layoutConfig`
- Pannelli center che si espandono solo nella loro area
- Pannelli floating ancora supportati

#### 3. **Store (Updated)**
File: [src/store/dockablePanelsStore.ts](app-dam/src/store/dockablePanelsStore.ts)
- Nuovo campo `center` in `dockedPanels`
- Nuovo campo `layoutConfig` in layout
- Azioni `setLayoutPreset(preset)` e `toggleColumn(column)`
- Default: 3 colonne con Asset Browser al centro

### Default Configuration
```typescript
{
  preset: 'three-column',
  showLeft: true,
  showRight: true,
  dockedPanels: {
    left: ['filters'],
    center: ['asset-browser'],  // ← NOVITÀ!
    right: ['preview', 'details']
  }
}
```

## Vantaggi

✅ **Nessuna sovrapposizione**: Ogni pannello sta nella sua area
✅ **Espansione intelligente**: I pannelli center occupano solo lo spazio disponibile
✅ **Flessibilità**: 4 layout predefiniti + possibilità di personalizzare
✅ **Persistenza**: La configurazione viene salvata
✅ **UX ottimale**: Selettore visivo e intuitivo

## Come Usare

1. **Seleziona un layout** dalla barra in alto
2. **Trascina i pannelli** per spostarli tra le colonne
3. **Ridimensiona** le sidebar trascinando i bordi
4. **Ricarica la pagina** - tutto viene mantenuto!

## Test
Apri http://localhost:3300/library-v2 e prova:

1. Click su "Singola" → Solo Asset Browser full width
2. Click su "2 Colonne (Sx)" → Filters + Asset Browser
3. Click su "2 Colonne (Dx)" → Asset Browser + Preview/Details
4. Click su "3 Colonne" → Layout completo
5. Trascina Asset Browser dalla colonna center → diventa floating
6. Trascina un pannello dalla sidebar alla colonna center → si espande

## Roadmap Future (Optional)
- [ ] Layout "4 colonne" con doppia sidebar
- [ ] Layout "griglia" per multiple preview
- [ ] Salvataggio di layout personalizzati con nome
- [ ] Hotkeys per cambiare layout velocemente
- [ ] Drag and drop tra colonne con zone highlight
