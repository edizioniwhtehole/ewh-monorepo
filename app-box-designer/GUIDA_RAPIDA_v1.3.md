# 🚀 Guida Rapida - BoxDesigner CAD v1.3.0

## ✅ Sistema Completo e Funzionante

Il sistema di nesting avanzato è stato **completamente integrato** nell'applicazione BoxDesigner CAD.

## 🌐 Avviare l'Applicazione

```bash
cd app-box-designer
npm run dev
```

**URL**: [http://localhost:5901/](http://localhost:5901/)

## 📱 Interfaccia Utente

L'applicazione è divisa in 3 tab principali:

### 1️⃣ Tab "Vista 3D"
Configura la tua scatola:
- Forma (rettangolare, tronco piramide)
- Dimensioni base, top, altezza
- Materiale (cartoncino, cartone ondulato)
- Tipo fondo (semplice, automatico, crash-lock)
- Tipo chiusura (semplice, con linguetta, con finestra)
- Bandelle incollaggio
- Bleed (abbondanza stampa)

Visualizza il rendering 3D interattivo della scatola.

### 2️⃣ Tab "Fustella"
Visualizza lo sviluppo piano (die-line) con:
- ✂️ Linee di taglio (nero)
- 📏 Linee di piega/cordonatura (verde tratteggiato)
- 📐 Quote automatiche (arancione) - ON/OFF con pulsante
- 🔍 Zoom/Pan interattivo:
  - **Rotella mouse**: Zoom in/out
  - **Drag**: Pan (spostamento)
  - **Pulsanti**: Zoom +/−/Reset

Esporta in 5 formati:
- **SVG** → per editing grafico
- **PDF** → per stampa
- **DXF** → per AutoCAD
- **AI** → per Adobe Illustrator
- **PLT** → per plotter/taglio

### 3️⃣ Tab "Nesting" ⭐ NUOVO v1.3
**Sistema avanzato di ottimizzazione produzione**

#### Pannello Sinistro - Configurazione
1. **Tipo Macchina**
   - 🖨️ Stampa (offset printer)
   - ✂️ Fustellatura (die-cutter)
   - 🔧 Combinata (print+die)

2. **Selezione Macchina**
   Database 8 macchine reali:
   - Heidelberg Speedmaster XL 106
   - Komori Lithrone G40
   - HP Indigo 12000 (digitale)
   - BOBST Novacut 106
   - Masterwork MX 1060
   - Sanwa Kiko 750
   - BOBST Mastercut 106 PER (combinata)
   - Zünd G3 L-2500 (CNC)

3. **Dimensioni Foglio**
   - Standard: A0-A4, SRA1-SRA3, formati offset
   - Personalizzate: inserisci larghezza × altezza
   - Max macchina: usa dimensioni massime

4. **Senso Fibra Carta**
   - ⟷ Orizzontale
   - ⟹ Verticale
   - ⊗ Qualsiasi

   **Priorità:**
   - Massimizza rispetto fibra (qualità)
   - Massimizza quantità (produttività)
   - Bilanciato (compromesso)

5. **Distanze**
   - Spazio tra elementi (mm)
   - Margine sicurezza (mm)

6. **Opzioni**
   - ☑️ Permetti rotazione elementi
   - ☑️ Rispetta margini pinza
   - ☑️ Rispetta direzione fibra
   - ☑️ Orientamenti misti sullo stesso foglio

#### Pannello Destro - Risultati

**Visualizzazione Grafica:**
- 📊 Foglio con dimensioni reali
- 🟧 Zone pinza evidenziate (non stampabili)
- 🟩 Area utile con bordo verde
- 📦 Elementi posizionati colorati:
  - 🟢 Verde = Con fibra (ottimo)
  - 🟠 Arancione = Fibra incrociata
  - 🔴 Rosso = Contro fibra (sconsigliato)
- 🔢 Numeri identificativi su ogni elemento
- ↻ Indicatori rotazione
- ➡️ Frecce direzione fibra

**Statistiche in Tempo Reale:**
- 📈 **Efficienza**: % utilizzo area utile
- 📦 **Elementi**: numero posizionati
- ✅ **Con fibra**: elementi posizionati correttamente
- 💰 **Costo stimato**: basato su macchina selezionata
- 📄 **Fogli necessari**: per produzione completa
- ⏱️ **Tempo stimato**: minuti produzione
- ♻️ **Spreco materiale**: m² e percentuale

**Avvisi Intelligenti:**
- ⚠️ Elementi in zona pinza (rischio marcature)
- ⚠️ Elementi contro fibra (rischio ondulazione)
- ⚠️ Elementi non posizionati (foglio troppo piccolo)

**Legenda Completa:**
- Colori direzione fibra
- Zone pinza
- Area utile
- Simboli e indicatori

## 🎯 Workflow Completo

### Scenario 1: Prototipo Rapido
```
1. Tab "Vista 3D"
   → Configura scatola: base 120mm, top 140mm, h 80mm
   → Materiale: Cartoncino 300g
   → Fondo automatico

2. Tab "Fustella"
   → Visualizza sviluppo
   → Attiva quote
   → Zoom per dettagli
   → Esporta PDF

3. Tab "Nesting"
   → Macchina: HP Indigo 12000 (digitale)
   → Foglio: 750×530mm
   → Fibra: Qualsiasi
   → Priorità: Massimizza quantità
   → Analizza efficienza: ~65%
   → Elementi: 4 per foglio
```

### Scenario 2: Produzione Serie
```
1. Tab "Vista 3D"
   → Configura scatola con specifiche cliente
   → Materiale: Cartone ondulato E
   → Fondo crash-lock

2. Tab "Fustella"
   → Verifica sviluppo corretto
   → Controlla quote

3. Tab "Nesting"
   → Macchina: BOBST Novacut 106 (fustellatrice)
   → Foglio: 1060×760mm (standard)
   → Fibra: Orizzontale
   → Priorità: Bilanciato
   → Rispetta pinza: ✓
   → Rispetta fibra: ✓
   → Analizza:
     - Efficienza: ~78%
     - Elementi: 8 per foglio
     - Costo: €0.64 per foglio
     - Tempo: 45min setup + 7.5 fogli/minuto
     - Con fibra: 7/8 (87%)
```

### Scenario 3: Preventivazione Comparativa
```
1. Configura scatola nel tab "Vista 3D"

2. Tab "Nesting" - Prova diverse macchine:

   A) Heidelberg Speedmaster XL 106 (offset)
      → 1060×760mm
      → Efficienza: 82%
      → Costo: €1.35/foglio
      → 9 elementi per foglio

   B) HP Indigo 12000 (digitale)
      → 750×530mm
      → Efficienza: 68%
      → Costo: €1.25/foglio
      → 5 elementi per foglio
      → Più costoso ma no setup

   C) Zünd G3 (CNC)
      → 2500×3200mm
      → Efficienza: 75%
      → Costo: €2.40/foglio
      → 24 elementi per foglio
      → Ideale per prototipi/piccole serie

3. Scegli soluzione ottimale per tiratura
```

## 💡 Suggerimenti Professionali

### Direzione Fibra
- ✅ **SEMPRE con fibra** per scatole con pieghe
- La fibra deve correre **parallela** alle linee di piega
- Contro fibra → rischio rotture e ondulazione
- Per prototipi/campioni: fibra meno critica

### Zone Pinza
- Evitare posizionamento elementi in zona pinza
- Rischio marcature/sbavature
- Margini tipici: 10-15mm anteriore, 5-8mm altri lati

### Efficienza Target
- **>80%**: Ottimo - produzione efficiente
- **60-80%**: Buono - accettabile
- **<60%**: Da ottimizzare - considerare:
  - Rotazione elementi
  - Foglio diverso
  - Macchina diversa

### Scelta Macchina
- **Offset** (Heidelberg, Komori): grandi tirature (>1000)
- **Digitale** (HP Indigo): piccole tirature, prototipi
- **Fustellatrici**: post-stampa, solo taglio
- **Combinate**: stampa+taglio integrati
- **CNC** (Zünd): prototipazione, forme complesse

## 📚 Documentazione Completa

Per maggiori dettagli tecnici e architettura del sistema:

📖 **[NESTING_SYSTEM_COMPLETE.md](./NESTING_SYSTEM_COMPLETE.md)**
- Database macchine completo
- Algoritmi implementati
- API e struttura codice
- Esempi avanzati

📖 **[AGGIORNAMENTO_v1.2.md](./AGGIORNAMENTO_v1.2.md)**
- Fix sviluppo tronco piramide
- Sistema quotatura
- Confronto prima/dopo

📖 **[ZOOM_NAVIGATION.md](./ZOOM_NAVIGATION.md)**
- Controlli zoom/pan dettagliati

## 🐛 Troubleshooting

### Errore: "Port 5901 is in use"
```bash
lsof -ti:5901 | xargs kill -9
npm run dev
```

### Fustella non si genera
- Verifica che tutte le dimensioni siano > 0
- Controlla console browser per errori (F12)

### Nesting non calcola
- Verifica che la fustella sia generata (tab "Fustella")
- Controlla che dimensioni foglio > dimensioni fustella

### Performance lenta
- Ridurre numero elementi
- Disabilitare rotazione se non necessaria
- Usare foglio più piccolo per test

## ✨ Novità v1.3.0

### Cosa è Nuovo
- ✅ Database 8 macchine reali di produzione
- ✅ Algoritmo nesting avanzato (Skyline Packing)
- ✅ Gestione completa direzione fibra carta
- ✅ Rispetto automatico margini pinza
- ✅ Calcolo costi e tempi produzione
- ✅ Visualizzazione interattiva risultati
- ✅ Sistema avvisi intelligente
- ✅ Statistiche dettagliate real-time

### Cosa Funziona Adesso
1. ✅ Design parametrico scatole (v1.0)
2. ✅ Calcolo volumi automatico (v1.0)
3. ✅ Generazione fustella CORRETTA (v1.2)
4. ✅ Sistema quotatura (v1.2)
5. ✅ Zoom/pan fustella (v1.1)
6. ✅ Export multi-formato (v1.0)
7. ✅ **Nesting con macchine reali (v1.3)** ⭐ NUOVO
8. ✅ **Ottimizzazione fibra (v1.3)** ⭐ NUOVO
9. ✅ **Calcolo costi (v1.3)** ⭐ NUOVO

## 🎉 Pronto per l'Uso!

Il sistema è **completo e funzionante** per:
- ✅ Progettazione packaging
- ✅ Prototipazione rapida
- ✅ Preventivazione lavori
- ✅ Ottimizzazione produzione
- ✅ Formazione operatori
- ✅ Presentazioni clienti

---

**Buon lavoro con BoxDesigner CAD!** 📦✨

Per supporto o domande, consulta la documentazione completa o apri una issue su GitHub.

**Versione**: 1.3.0
**Data**: 15 Ottobre 2025
