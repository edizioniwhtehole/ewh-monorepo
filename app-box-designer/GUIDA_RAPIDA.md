# 📦 Guida Rapida - BoxDesigner CAD

## Avvio Rapido

```bash
cd app-box-designer
npm install
npm run dev
```

L'applicazione sarà disponibile su: **http://localhost:5900**

## Come Usare il Sistema

### 1. Configurazione Base

Nel pannello sinistro puoi configurare:

#### Forma
- **Rettangolare**: scatola classica a parallelepipedo
- **Tronco di piramide**: base e top con dimensioni diverse (come il tuo esempio)

#### Dimensioni Interne (in millimetri)
Per il tuo esempio specifico:
- **Base - Larghezza**: 120mm (12cm)
- **Base - Lunghezza**: 120mm (12cm)
- **Top - Larghezza**: 140mm (14cm)
- **Top - Lunghezza**: 140mm (14cm)
- **Altezza**: 80mm (8cm)

#### Materiale
Scegli tra:
- Cartoncino 300g (0.3mm) - per scatole leggere
- **Cartone ondulato E (1.5mm)** - ideale per packaging medio
- Cartone ondulato B (3.0mm) - per scatole pesanti
- Microflauto (1.2mm) - equilibrato

#### Tipo Fondo
- **Semplice**: fondo piatto base
- **Ad incastro**: con linguette che si incastrano
- **Automatico**: si chiude automaticamente (consigliato)
- **Crash Lock**: montaggio ultra-rapido

#### Tipo Chiusura
- **Semplice**: alette standard
- **Con linguetta**: sistema tuck-in
- **Con maniglia**: per trasporto facile
- **A ribalta**: flip-top
- **Con finestra**: mostra il prodotto

### 2. Opzioni Avanzate

#### Bandelle di Incollaggio
- Abilita per aggiungere alette laterali per l'incollaggio
- Larghezza consigliata: **15mm**

#### Bleed (Abbondanza)
- Margine di sicurezza per la stampa
- Valore standard: **3mm**

#### Maniglia
- Puoi aggiungere una maniglia die-cut

### 3. Visualizzazioni

#### Vista 3D
- Mostra il modello 3D interattivo della scatola
- Puoi ruotare con il mouse per vedere tutti i lati
- Il modello ruota automaticamente

#### Fustella
- Mostra la sagoma da stampare/tagliare
- **Linee nere continue**: tagli
- **Linee blu tratteggiate**: cordonature (pieghe)
- **Linee rosse punteggiate**: perforazioni
- **Linee verdi sottili**: guide di sicurezza

#### Nesting
- Ottimizzazione per posizionare più scatole su un foglio
- Minimizza gli sprechi di materiale

### 4. Calcoli Automatici

Il pannello "Calcoli e Specifiche" mostra:

- **Volume interno**: spazio utilizzabile (in cm³ e litri)
  - Per il tuo esempio: ~1073 cm³ = 1.07 litri
- **Volume esterno**: considerando lo spessore del materiale
- **Area materiale**: superficie totale necessaria
- **Peso stimato**: in base al materiale scelto

### 5. Export

Puoi esportare la fustella in vari formati:

- **SVG**: per Adobe Illustrator, Inkscape, editor grafici
- **PDF**: per stampa e condivisione
- **DXF**: per AutoCAD e software CAD industriali
- **AI**: direttamente per Adobe Illustrator
- **PLT**: per macchine da taglio automatiche (plotter)

Ogni export include:
- Linee di taglio
- Cordonature
- Perforazioni
- Bleed (se abilitato)
- Dimensioni corrette in millimetri

## Esempio Pratico: Tua Scatola

### Input
```
Forma: Tronco di piramide
Base: 12×12 cm (120×120 mm)
Top: 14×14 cm (140×140 mm)
Altezza: 8 cm (80 mm)
Materiale: Cartone ondulato E
Fondo: Automatico
Chiusura: Semplice
Bandelle: Sì (15mm)
Bleed: Sì (3mm)
```

### Output Automatico
- ✅ Volume interno: ~1073 cm³
- ✅ Fustella completa con:
  - 4 facce trapezoidali
  - Base e top
  - Bandelle di incollaggio
  - Sistema di chiusura automatica del fondo
  - Bleed su tutti i lati
- ✅ Dimensioni fustella totale calcolate automaticamente
- ✅ Peso della scatola vuota
- ✅ Area materiale necessaria

### Workflow Completo

1. **Inserisci parametri** nel pannello sinistro
2. **Verifica in 3D** che la scatola sia corretta
3. **Controlla i calcoli** (volume, peso, area)
4. **Visualizza la fustella** per verificare le linee di taglio
5. **Esporta in PDF** per la stampa tipografica
6. **Esporta in DXF** per macchine da taglio CNC
7. **Esporta in PLT** per plotter industriali

## Formule Utilizzate

### Volume Tronco di Piramide
```
V = h/3 × (A₁ + A₂ + √(A₁×A₂))

dove:
- h = altezza
- A₁ = area base
- A₂ = area top
```

Per il tuo esempio:
```
A₁ = 12 × 12 = 144 cm²
A₂ = 14 × 14 = 196 cm²
h = 8 cm

V = 8/3 × (144 + 196 + √(144×196))
V = 8/3 × (144 + 196 + 168)
V = 8/3 × 508
V ≈ 1,073 cm³
```

### Altezza Inclinata (Slant Height)
```
s = √(h² + ((top - base)/2)²)
```

Serve per calcolare la lunghezza reale delle facce inclinate.

## Tips Professionali

### 🎯 Materiali
- **Cartoncino 300g**: scatole regalo, cosmetici
- **Ondulato E**: e-commerce, prodotti medi
- **Ondulato B**: elettrodomestici, prodotti pesanti
- **Microflauto**: compromesso leggero ma resistente

### 📏 Dimensioni
- Aggiungi sempre 2-3mm di tolleranza per prodotti rigidi
- Per prodotti morbidi, dimensioni esatte vanno bene
- Considera spessore eventuale imbottitura interna

### 🔧 Fondi
- **Automatico**: ideale per produzioni veloci
- **Ad incastro**: più resistente per prodotti pesanti
- **Semplice**: più economico

### 🖨️ Stampa
- Usa sempre il **bleed** (3mm minimo)
- Tieni testi/loghi ad almeno 5mm dai bordi
- Le cordonature non si stampano (sono solo pieghe)

### 📦 Export
- **PDF**: per tipografia tradizionale
- **DXF + PLT**: per taglio industriale
- **SVG**: per modifiche grafiche
- **AI**: workflow Adobe completo

## Troubleshooting

### Il 3D non si vede
- Controlla che il browser supporti WebGL
- Prova con Chrome o Firefox aggiornati

### I calcoli sembrano sbagliati
- Verifica che le dimensioni siano in millimetri
- Controlla che top sia >= base (per tronco piramide)

### L'export non funziona
- Controlla la console browser (F12)
- Alcuni browser bloccano i download automatici

## Prossimi Sviluppi

- [ ] Più forme (cilindri, esagonali)
- [ ] Import artwork per stampa
- [ ] Database materiali espanso
- [ ] Calcolo costi di produzione
- [ ] Template biblioteca
- [ ] Salvataggio progetti cloud

## Supporto

Per domande o problemi:
- Apri una issue su GitHub
- Consulta la documentazione completa nel README.md
- Controlla gli esempi nella cartella `examples/`

---

**BoxDesigner CAD** - Il tuo CAD per packaging, semplice e professionale.
