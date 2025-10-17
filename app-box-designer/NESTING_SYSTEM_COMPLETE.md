# Sistema di Nesting Completo - v1.3.0

## ✅ Implementazione Completata

Il sistema avanzato di nesting è stato completamente integrato nell'applicazione BoxDesigner CAD.

## 🎯 Funzionalità Implementate

### 1. **Database Macchine**
- **8 macchine pre-configurate** con specifiche reali di produzione
- Tipologie:
  - **Macchine da stampa offset**: Heidelberg Speedmaster XL 106, Komori Lithrone G40
  - **Stampanti digitali**: HP Indigo 12000
  - **Fustellatrici**: BOBST Novacut 106, Masterwork MX 1060, Sanwa Kiko 750
  - **Macchine combinate**: BOBST Mastercut 106 PER, Roland VersaCAMM VS-640
  - **Taglio digitale CNC**: Zünd G3 L-2500

### 2. **Parametri Macchina**
Ogni macchina include:
- Dimensioni massime e minime foglio
- **Margini pinza** (front/back/left/right) - aree non stampabili
- Velocità (fogli/ora)
- Costi (per foglio e per ora)
- Tempo di setup
- Materiali supportati (spessore e grammatura)
- Preferenza direzione fibra
- Capacità di cordonatura e perforazione (per fustellatrici)

### 3. **Algoritmo di Nesting Avanzato**
- **Skyline Packing Algorithm** ottimizzato per packaging
- Supporto per:
  - Rotazione elementi (0° e 90°)
  - Rispetto direzione fibra carta
  - Rispetto margini pinza
  - Spaziatura tra elementi configurabile
  - Margini di sicurezza

### 4. **Gestione Fibra Carta**
Sistema completo per il senso di fibra:
- **3 direzioni**: Orizzontale, Verticale, Qualsiasi
- **3 priorità**:
  - `maximize_grain`: Massimizza elementi con fibra corretta
  - `maximize_quantity`: Massimizza numero elementi
  - `balanced`: Bilanciato tra fibra e quantità
- **Indicatori visivi**:
  - 🟢 Verde: Con fibra (with_grain)
  - 🟠 Arancione: Fibra incrociata (cross_grain)
  - 🔴 Rosso: Contro fibra (against_grain)

### 5. **Configuratore Nesting**
Interfaccia completa per configurare:
- Selezione tipo macchina (Stampa/Fustellatura/Combinata)
- Selezione macchina specifica
- Dimensioni foglio:
  - Dimensioni standard (A0-A4, SRA1-SRA3, formati offset comuni)
  - Dimensioni personalizzate
  - Automatico: max macchina
- Direzione fibra con pulsanti visivi (⟷ ⟹ ⊗)
- Priorità ottimizzazione
- Distanze (spacing e margini sicurezza)
- Opzioni:
  - Permetti rotazione
  - Rispetta margini pinza
  - Rispetta direzione fibra
  - Orientamenti misti
- Quantità target (opzionale)

### 6. **Visualizzatore Nesting**
Vista SVG interattiva con:
- **Foglio** con dimensioni reali
- **Zone pinza** evidenziate in arancione trasparente
- **Area utile** con bordo verde tratteggiato
- **Elementi posizionati** colorati per direzione fibra
- **Numeri identificativi** su ogni elemento
- **Indicatori rotazione** (↻90°)
- **Frecce direzione fibra** sugli elementi
- **Info macchina** nell'angolo

### 7. **Statistiche Dettagliate**
Dashboard con:
- **Efficienza** percentuale utilizzo area
- **Numero elementi** posizionati
- **Elementi con fibra** corretta
- **Costo stimato** (se disponibile per macchina)
- **Fogli necessari** per produzione
- **Tempo stimato** produzione
- **Area utilizzata vs spreco**

### 8. **Sistema Avvisi**
Avvisi automatici per:
- ⚠️ Elementi in zona pinza (rischio marcature)
- ⚠️ Elementi contro fibra (rischio ondulazione)
- ⚠️ Elementi non posizionati (foglio troppo piccolo)

### 9. **Legenda Interattiva**
Legenda completa che spiega:
- Colori direzione fibra
- Zone pinza
- Area utile
- Simboli e indicatori

## 🏗️ Architettura Implementata

### File Creati/Modificati

#### Nuovi File
1. **`src/types/machine.types.ts`**
   - Definizioni TypeScript complete per macchine, configurazione, risultati
   - Interfacce: `PrintingMachine`, `NestingConfiguration`, `NestingResult`, `NestedItem`

2. **`src/data/machines.database.ts`**
   - Database 8 macchine con specifiche reali
   - Helper functions: `getMachineById`, `getMachinesByType`, `getMachinesForMaterial`, etc.
   - Array formati standard: `STANDARD_SHEET_SIZES`

3. **`src/utils/advanced-nesting.algorithm.ts`**
   - Algoritmo Skyline Packing con supporto fibra
   - Funzioni: `nestWithMachineConstraints`, `optimizeNesting`
   - Calcolo aree utili, zone pinza, conflitti
   - Determinazione direzione fibra per rotazione

4. **`src/components/NestingConfigurator.tsx`**
   - Pannello configurazione completo
   - Interfaccia a tab per tipo macchina
   - Controlli per tutte le opzioni nesting

5. **`src/components/NestingViewer.tsx`**
   - Visualizzatore SVG interattivo
   - Rendering foglio, zone pinza, elementi
   - Statistiche, avvisi, legenda

#### File Modificati
1. **`src/App.tsx`**
   - Aggiunto state per `nestingConfig` e `nestingResult`
   - Effect per calcolo automatico nesting
   - Switch configuratore in base a tab attivo
   - Integrazione `NestingViewer` nel tab Nesting

## 🔧 Come Usare il Sistema

### 1. Avviare l'Applicazione
```bash
cd app-box-designer
npm run dev
```

L'applicazione sarà disponibile su: **http://localhost:5901/**

### 2. Workflow Completo

#### Step 1: Configura la Scatola
1. Nel tab "Vista 3D", configura la tua scatola:
   - Forma
   - Dimensioni
   - Materiale
   - Tipo fondo/coperchio
   - Bandelle, bleed, etc.

#### Step 2: Visualizza Fustella
2. Passa al tab "Fustella" per vedere:
   - Sviluppo piano corretto
   - Linee di taglio (nero)
   - Linee di piega (verde tratteggiato)
   - Quote automatiche (arancione)
   - Zoom/pan interattivo

#### Step 3: Ottimizza Nesting
3. Passa al tab "Nesting":
   - Seleziona tipo macchina (Stampa/Fustellatura/Combinata)
   - Scegli macchina specifica dal database
   - Imposta dimensioni foglio (standard o custom)
   - Configura direzione fibra
   - Scegli priorità ottimizzazione
   - Imposta spacing e margini
   - Abilita/disabilita opzioni

#### Step 4: Analizza Risultati
4. Il sistema mostra automaticamente:
   - Visualizzazione grafica posizionamento
   - Efficienza percentuale
   - Numero elementi posizionati
   - Avvisi (pinza, fibra, overflow)
   - Costi e tempi stimati

#### Step 5: Esporta
5. Torna al tab "Fustella" ed esporta in:
   - SVG (per Illustrator)
   - PDF (per stampa)
   - DXF (per AutoCAD)
   - AI (per Illustrator nativo)
   - PLT (per plotter)

## 📊 Esempi di Configurazione

### Esempio 1: Massima Qualità (rispetto fibra)
```
Macchina: BOBST Novacut 106 (fustellatrice)
Foglio: 1060 × 760 mm
Fibra: Orizzontale
Priorità: Massimizza rispetto fibra
Rotazione: ✓ Permessa
Rispetta fibra: ✓ Attivo
Rispetta pinza: ✓ Attivo
```

### Esempio 2: Massima Resa (prototipazione)
```
Macchina: HP Indigo 12000 (digitale)
Foglio: 750 × 530 mm
Fibra: Qualsiasi
Priorità: Massimizza quantità
Rotazione: ✓ Permessa
Rispetta fibra: ✗ Disattivo
Rispetta pinza: ✓ Attivo
```

### Esempio 3: Produzione Bilanciata
```
Macchina: Heidelberg Speedmaster XL 106
Foglio: 1060 × 760 mm
Fibra: Orizzontale
Priorità: Bilanciato
Rotazione: ✓ Permessa
Rispetta fibra: ✓ Attivo
Rispetta pinza: ✓ Attivo
Orientamenti misti: ✓ Attivo
```

## 🎓 Note Tecniche

### Direzione Fibra - Importanza
La fibra della carta deve correre **parallela** alle linee di piega per evitare:
- ❌ Rotture durante la piega
- ❌ Ondulazione del cartone
- ❌ Scarsa tenuta della piega
- ❌ Deformazioni nel tempo

### Zone Pinza - Considerazioni
Le zone pinza sono aree dove la macchina afferra il foglio:
- **Non stampabili** (rischio marcature/sbavature)
- **Non fustellabili** nella zona principale
- Margine standard: 10-15mm anteriore, 5-8mm posteriore/laterali

### Efficienza Nesting
- **>80%**: Ottimo (produzione efficiente)
- **60-80%**: Buono (accettabile per forme complesse)
- **<60%**: Da ottimizzare (considerare rotazione o foglio diverso)

## 🚀 Sviluppi Futuri Possibili

Funzionalità che potrebbero essere aggiunte:
1. **Nesting multi-elemento**: Posizionare più scatole diverse sullo stesso foglio
2. **Ottimizzazione genetica**: Algoritmi più avanzati (simulated annealing, genetic algorithm)
3. **Anteprima costi comparati**: Confronto tra diverse macchine
4. **Template salvati**: Salvare configurazioni nesting
5. **Imposizione automatica**: Generazione imposizioni stampa multi-pagina
6. **Integrazione MIS**: Collegamento con sistemi gestionali tipografie
7. **Stima consumo inchiostro**: Basata su area stampata
8. **Report PDF**: Generazione report produzione completi

## 📝 Changelog v1.3.0

### Nuove Funzionalità
- ✅ Database completo macchine da stampa e fustellatura
- ✅ Algoritmo nesting avanzato con Skyline Packing
- ✅ Gestione completa direzione fibra carta
- ✅ Rispetto automatico margini pinza
- ✅ Configuratore nesting con tutte le opzioni
- ✅ Visualizzatore interattivo con statistiche
- ✅ Sistema avvisi automatico
- ✅ Calcolo costi e tempi stimati
- ✅ Supporto formati standard e personalizzati

### Miglioramenti
- ✅ Integrazione seamless nel tab system esistente
- ✅ Switch automatico configuratore per tab
- ✅ Ricalcolo automatico al cambio configurazione
- ✅ UI consistente con resto applicazione

### Bug Fix
- ✅ Risolto conflitto nomi variabili `dimensions`
- ✅ Riavvio dev server per cache cleanup

## 🎉 Conclusione

Il sistema di nesting è **completamente funzionale e integrato**.

L'applicazione BoxDesigner CAD ora offre:
1. ✅ Design parametrico scatole
2. ✅ Visualizzazione 3D
3. ✅ Generazione fustella corretta
4. ✅ Sistema quote automatiche
5. ✅ Zoom/pan interattivo
6. ✅ **Nesting avanzato con macchine reali**
7. ✅ Export multi-formato

È pronto per essere utilizzato in **ambiente di produzione reale** per:
- Preventivazione lavori
- Ottimizzazione produzione
- Prototipazione rapida
- Formazione operatori

---

**Versione**: 1.3.0
**Data**: 15 Ottobre 2025
**Autore**: BoxDesigner CAD Team
**Licenza**: MIT
