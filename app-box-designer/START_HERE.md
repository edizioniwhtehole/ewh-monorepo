# 🚀 Inizia Subito - BoxDesigner CAD

## Quick Start (30 secondi)

```bash
# 1. Vai nella cartella
cd app-box-designer

# 2. Il server è già avviato!
# Apri nel browser: http://localhost:5900
```

## 🎯 Primo Utilizzo - Tutorial 2 Minuti

### Passo 1: Configura la Scatola (Pannello Sinistro)

**Dimensioni per il tuo esempio:**
- Base - Larghezza: `120` mm
- Base - Lunghezza: `120` mm
- Top - Larghezza: `140` mm
- Top - Lunghezza: `140` mm
- Altezza: `80` mm

**Materiale:**
- Seleziona "Cartone ondulato E (1.5mm, 450g/m²)"

**Tipo fondo:**
- Seleziona "Automatico"

**Opzioni avanzate:**
- ✅ Bandelle di incollaggio: `15` mm
- ✅ Bleed: `3` mm

### Passo 2: Verifica i Calcoli

Guarda il pannello "Calcoli e Specifiche":
- Volume interno: **~1073 cm³** ✓
- Area materiale: calcolata automaticamente
- Peso: in base al materiale

### Passo 3: Visualizza in 3D

- Clicca tab "Vista 3D"
- Ruota con il mouse per vedere tutti i lati
- La scatola ruota automaticamente

### Passo 4: Vedi la Fustella

- Clicca tab "Fustella"
- **NOVITÀ:** Ora puoi:
  - **Zoom**: Rotella mouse
  - **Pan**: Trascina con mouse
  - **Controlli**: Pulsanti + / − / ⟲ in alto a destra

**Legenda colori:**
- Nero continuo = Taglio
- Blu tratteggiato = Cordonature (pieghe)
- Rosso punteggiato = Perforazioni
- Verde = Guide sicurezza

### Passo 5: Esporta

Clicca sui pulsanti export:
- **SVG** → per Illustrator/Inkscape
- **PDF** → per stampare
- **DXF** → per AutoCAD
- **PLT** → per plotter

## 🎨 Esempi Rapidi

### Scatola Regalo Piccola
```
Base: 80×80 mm
Top: 85×85 mm
Altezza: 60 mm
Materiale: Cartoncino 300g
Fondo: Semplice
```

### Scatola E-commerce Media
```
Base: 200×150 mm
Top: 200×150 mm (rettangolare)
Altezza: 120 mm
Materiale: Ondulato E
Fondo: Automatico
```

### Scatola Pizza (rettangolare)
```
Forma: Rettangolare
Base: 300×300 mm
Altezza: 40 mm
Materiale: Ondulato E
Fondo: Semplice
```

## 🔍 Nuove Funzionalità Zoom

### Ispezione Dettagli

1. Vai su tab "Fustella"
2. Passa mouse sulla zona da ispezionare
3. **Rotella UP** = Zoom In
4. **Rotella DOWN** = Zoom Out
5. **Trascina** = Sposta vista
6. **Pulsante ⟲** = Reset

### Verifica Qualità

**Zoom su angoli** (500%):
- Controlla che le linee si incontrino perfettamente
- Verifica cordonature a 1-2mm dal bordo

**Zoom su bandelle** (300%):
- Controlla larghezza (15mm standard)
- Verifica perforazioni

**Zoom su fondo** (400%):
- Sistema automatico con linguette
- Verifica incastri

## 📁 File Importanti

```
app-box-designer/
├── README.md              ← Documentazione completa
├── GUIDA_RAPIDA.md       ← Guida in italiano
├── ZOOM_NAVIGATION.md    ← Guida controlli zoom
├── CHANGELOG.md          ← Novità versioni
└── examples/             ← Esempi pronti
    └── example-truncated-pyramid.json
```

## ⚡ Scorciatoie

### Modifiche Rapide
- Cambia dimensioni → Calcoli si aggiornano automaticamente
- Cambia materiale → Peso si ricalcola
- Abilita/disabilita opzioni → Fustella si aggiorna

### Export Rapido
1. Configura scatola
2. Verifica in 3D
3. Click su "PDF"
4. File scaricato!

## 🐛 Risoluzione Problemi Comuni

### Il 3D non si vede
```
✓ Usa Chrome o Firefox
✓ Verifica WebGL: chrome://gpu
```

### L'export non funziona
```
✓ Controlla console (F12)
✓ Abilita download nel browser
```

### La fustella è fuori vista
```
✓ Click pulsante ⟲ (reset)
✓ Controlla che dimensioni siano > 0
```

### Zoom troppo veloce/lento
```
✓ Usa pulsanti + / − invece della rotella
✓ Ogni click = zoom 30%
```

## 📚 Prossimi Passi

### Impara di più
1. Leggi [GUIDA_RAPIDA.md](GUIDA_RAPIDA.md) per tutti i dettagli
2. Guarda [ZOOM_NAVIGATION.md](ZOOM_NAVIGATION.md) per controlli avanzati
3. Esplora [examples/](examples/) per configurazioni pronte

### Personalizza
1. Prova diversi materiali
2. Sperimenta con fondi diversi
3. Aggiungi maniglie e finestre

### Esporta
1. Genera più varianti
2. Esporta in tutti i formati
3. Invia a tipografia/plotter

## 🎓 Tips Pro

### 💡 Workflow Professionale

**Fase 1 - Design**
1. Inserisci dimensioni prodotto + 2mm tolleranza
2. Scegli materiale in base a peso prodotto
3. Seleziona tipo fondo (automatico per produzione veloce)

**Fase 2 - Verifica**
1. Controlla volume: deve contenere il prodotto
2. Vista 3D: verifica proporzioni
3. Zoom fustella: ispeziona dettagli

**Fase 3 - Export**
1. PDF per approvazione cliente
2. DXF per plotter industriale
3. SVG per grafica/stampa

### 🎯 Ottimizzazioni

**Risparmio materiale:**
- Riduci bleed se possibile (2mm invece di 3mm)
- Usa fondo semplice invece di automatico (meno materiale)

**Velocità produzione:**
- Fondo automatico = montaggio veloce
- Crash lock = ideale per grandi volumi

**Resistenza:**
- Ondulato B per prodotti pesanti
- Bandelle larghe (20mm) per maggior tenuta

## 🌟 Caratteristiche Uniche

✨ **Calcolo automatico** - Volume preciso con formula matematica
✨ **Zoom infinito** - Ispeziona ogni millimetro
✨ **Export multi-formato** - Compatibile con tutti gli strumenti
✨ **3D real-time** - Vedi subito il risultato
✨ **Nessuna installazione** - Tutto nel browser

## 💬 Supporto

Problemi o domande?
1. Controlla [GUIDA_RAPIDA.md](GUIDA_RAPIDA.md)
2. Leggi [ZOOM_NAVIGATION.md](ZOOM_NAVIGATION.md)
3. Apri issue su GitHub

---

**Buon lavoro con BoxDesigner CAD!** 📦✨

*Progetta. Ispeziona. Esporta. Tutto in un'app.*
