# 📦 Fustelle FEFCO Implementate - Scatole Professionali Montabili

## ✅ Implementazione Completata

Ho implementato **3 tipologie di scatole professionali** basate sugli standard FEFCO internazionali, con fustelle **effettivamente montabili** nella realtà.

---

## 🎯 Tipologie Implementate

### 1. **FEFCO 0201 - Regular Slotted Container (RSC)**
La scatola più comune al mondo per imballaggio e spedizione.

**Caratteristiche:**
- 4 pannelli: Lato1 → Fronte → Lato2 → Retro
- Alette superiori e inferiori che si incontrano al centro
- Bandella di incollaggio laterale (25-38mm standard)
- Layout classico per scatole da spedizione

**Formula Dimensioni:**
```
Lunghezza sviluppo = 2×L + 2×W + bandellaIncollaggio + trim
Altezza sviluppo = W/2 + H + W/2 + larghezzaAlette
Compensazione spessore = aggiunta per ogni pannello
```

**Quando viene usata:**
- Chiusura superiore: `simple` (semplice)
- Fondo: `simple` (semplice)
- Forma: `rectangular` (rettangolare)

**Layout:**
```
     [Aletta1] [Aletta2] [Aletta3] [Aletta4]
     ___________________________________________
    |         |          |         |         |
    | Lato1   |  Fronte  | Lato2   |  Retro  | Bandella
    |  (H)    |   (H)    |  (H)    |   (H)   | Incollaggio
    |_________|__________|_________|_________|____
     [Aletta1] [Aletta2] [Aletta3] [Aletta4]
```

---

### 2. **Straight Tuck End Box (STE)**
Scatola con linguette di chiusura sullo **stesso lato** (retro).

**Caratteristiche:**
- Linguetta superiore sul pannello posteriore
- Linguetta inferiore sul pannello posteriore
- Dust flaps (alette di tenuta) sul pannello frontale
- Profondità linguetta = 80% dell'altezza
- Bandella incollaggio ridotta (15mm)

**Quando viene usata:**
- Chiusura superiore: `flip_top` o `tuck`
- Fondo: `automatic` o `crash_lock`
- Forma: `rectangular`

**Vantaggi:**
- Aspetto pulito e professionale
- Chiusura sicura
- Ideale per prodotti retail

**Layout:**
```
              [Dust]    [Top Tuck]
         _________________________________________
        |         |          |         |         |
        |  Dust   | Top Tuck |  Dust   |         |
        |_________|__________|_________|         |
        |         |          |         |         |
        |  Lato1  |  Fronte  |  Lato2  |  Retro  | Bandella
        |   (H)   |   (H)    |   (H)   |   (H)   | Incoll.
        |_________|__________|_________|_________|____
        |         |          |         |         |
        |  Dust   | Bot Tuck |  Dust   |         |
        |_________|__________|_________|         |
```

---

### 3. **Reverse Tuck End Box (RTE)**
Scatola con linguette di chiusura su **lati opposti**.

**Caratteristiche:**
- Linguetta superiore sul pannello FRONTALE
- Linguetta inferiore sul pannello POSTERIORE
- Dust flaps posizionate in modo complementare
- **Più economica** della STE (meno spreco di materiale)
- Profondità linguetta = 80% dell'altezza

**Quando viene usata:**
- Chiusura superiore: `tuck`
- Fondo: `simple`
- Forma: `rectangular`

**Vantaggi:**
- Massima efficienza di materiale
- Meno scarti durante il taglio
- Chiusura affidabile
- Standard industria per packaging retail

**Layout:**
```
     [Top Tuck]   [Dust]
         _________________________________________
        |         |          |         |         |
        | Top Tuck|   Dust   | Top Tuck|  Dust   |
        |_________|__________|_________|_________|
        |         |          |         |         |
        |  Lato1  |  Fronte  |  Lato2  |  Retro  | Bandella
        |   (H)   |   (H)    |   (H)   |   (H)   | Incoll.
        |_________|__________|_________|_________|____
        |         |          |         |         |
        |  Dust   | Bot Tuck |  Dust   | Bot Tuck|
        |_________|__________|_________|_________|
```

---

## 🎨 Come Selezionare le Tipologie

### Nell'Interfaccia BoxDesigner:

1. **Tab "Vista 3D"**
2. Seleziona **Forma: Rettangolare**
3. Configura dimensioni (L × W × H)
4. Scegli tipo di chiusura:

#### Per ottenere FEFCO 0201 (RSC):
```
Chiusura superiore: Semplice
Tipo fondo: Semplice
```

#### Per ottenere Straight Tuck End:
```
Chiusura superiore: A ribalta (flip_top)
Tipo fondo: Automatico o Crash Lock
```

#### Per ottenere Reverse Tuck End:
```
Chiusura superiore: Con linguetta (tuck)
Tipo fondo: Semplice
```

---

## 📐 Formule e Calcoli

### Compensazione Spessore Materiale

Ogni pannello verticale aggiunge lo spessore del materiale:
```typescript
panelWidth = dimensioneNominale + thickness
```

**Esempio:**
- Cartoncino 300g = 0.3mm spessore
- Cartone ondulato E = 1.5mm spessore
- Cartone ondulato B = 3.0mm spessore

### Bandella di Incollaggio

**FEFCO 0201:** 25-38mm (standard industria)
**Tuck End Boxes:** 15mm (ridotta perché meno sollecitazione)

### Profondità Linguette (Tuck Boxes)

```
tuckDepth = H × 0.8  (80% dell'altezza della scatola)
```

Questo garantisce una chiusura sicura ma facile da aprire.

### Dust Flaps (Alette di Tenuta)

```
dustFlapWidth = W × 0.4  (40% della larghezza)
```

Le dust flaps aiutano a mantenere il contenuto all'interno durante la chiusura.

---

## 🔍 Dettagli Tecnici

### Linee di Taglio (Cut Lines)
- **Colore:** Nero
- **Tipo:** Linea continua
- **Funzione:** Definiscono il perimetro da tagliare

### Linee di Piega (Crease Lines)
- **Colore:** Verde
- **Tipo:** Linea tratteggiata (2,2)
- **Funzione:** Indicano dove piegare il materiale

### Linee di Perforazione (Perforation)
- **Colore:** Rosso
- **Tipo:** Linea punteggiata (1,2)
- **Funzione:** Linee di strappo controllato

---

## 🎯 Montaggio

### FEFCO 0201 - Sequenza Montaggio:
1. Applicare colla sulla bandella di incollaggio
2. Piegare lungo le linee verticali
3. Unire il primo e l'ultimo pannello
4. La scatola è pronta per essere riempita
5. Chiudere le alette inferiori
6. Riempire
7. Chiudere le alette superiori

### Tuck End Boxes - Sequenza Montaggio:
1. Applicare colla sulla bandella di incollaggio
2. Piegare lungo le linee verticali
3. Formare il tubo
4. Chiudere il fondo: piegare le dust flaps verso l'interno, poi inserire la linguetta
5. Riempire il prodotto
6. Chiudere il top: piegare le dust flaps verso l'interno, poi inserire la linguetta

---

## ✅ Verifiche di Montabilità

Tutte le fustelle sono state progettate seguendo gli standard FEFCO internazionali:

✅ **Compensazione spessore:** Aggiunta per ogni pannello
✅ **Bandelle corrette:** Dimensioni standard industria
✅ **Linee di piega:** Posizionate correttamente
✅ **Sequenza pannelli:** Layout realistico e montabile
✅ **Proporzioni:** Rispettano le best practice del packaging

---

## 🚀 Prossimi Passi

### Tipologie da Aggiungere:
- [ ] **FEFCO 0427** - Crash Lock Bottom (fondo autobloccante)
- [ ] **FEFCO 0215** - Full Overlap Slotted Container
- [ ] **FEFCO 0421** - Tray with Separate Lid
- [ ] **Pillow Pack** - Scatola a cuscino
- [ ] **Gable Top Box** - Scatola con manico a capanna

---

## 📚 Risorse e Standard

**FEFCO (European Federation of Corrugated Board Manufacturers)**
- Standard internazionale per codifica scatole
- Oltre 100 stili codificati
- Usato in tutto il mondo

**Formula Base FEFCO 0201:**
Basata su ricerche industriali e best practice documentate:
- Mathematics Stack Exchange - Box calculations
- IPS Packaging - Manufacturer's joint specifications
- GEG Calculators - RSC blank size calculator

---

## 💡 Suggerimenti Professionali

### Scelta del Tipo di Scatola:

**Usa FEFCO 0201 quando:**
- Spedizioni e logistica
- Grande volume di produzione
- Costo minimo prioritario
- Non serve aspetto premium

**Usa Reverse Tuck End quando:**
- Packaging retail
- Prodotti da scaffale
- Massima efficienza materiale
- Budget contenuto

**Usa Straight Tuck End quando:**
- Prodotti premium
- Aspetto professionale importante
- Chiusura più sicura necessaria
- Branding sul pannello frontale

---

**Versione:** 1.4.0
**Data:** 15 Ottobre 2025
**Standard:** FEFCO International
**Stato:** ✅ Produzione Ready
