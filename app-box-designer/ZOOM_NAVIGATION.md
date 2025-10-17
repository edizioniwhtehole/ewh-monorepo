# 🔍 Navigazione e Zoom della Fustella

## Funzionalità Implementate

La visualizzazione della fustella ora supporta **zoom e pan interattivi** per ispezionare ogni dettaglio del design.

## Controlli Disponibili

### 🖱️ Con il Mouse

#### Zoom
- **Rotella del mouse**: Scorri avanti/indietro per zoomare in/out
- Lo zoom è centrato sulla posizione del cursore
- Range zoom: 10% - 1000%

#### Pan (Spostamento)
- **Click e trascina**: Clicca col tasto sinistro e trascina per spostare la vista
- Il cursore cambia da "grab" (mano aperta) a "grabbing" (mano chiusa) quando trascini

### 🎮 Controlli UI

In alto a destra della fustella trovi i pulsanti:

1. **+** (Plus) - Zoom In del 30%
2. **−** (Minus) - Zoom Out del 30%
3. **⟲** (Reset) - Ripristina vista originale (100%)
4. **Percentuale** - Mostra il livello di zoom corrente

## Casi d'Uso

### Ispezionare Dettagli Piccoli

```
1. Passa il mouse sulla zona da ispezionare
2. Usa la rotella per zoomare
3. Trascina per centrare la zona di interesse
4. Continua a zoomare fino al dettaglio desiderato
```

### Verificare Cordonature

```
1. Zoom su una zona con linee blu tratteggiate
2. Controlla che le cordonature siano posizionate correttamente
3. Verifica la distanza dai bordi
```

### Controllare Bandelle di Incollaggio

```
1. Zoom sui bordi laterali della fustella
2. Verifica larghezza delle bandelle (di solito 15mm)
3. Controlla che le perforazioni siano presenti
```

### Misurare Bleed

```
1. Zoom agli angoli della fustella
2. Controlla la linea verde di sicurezza (bleed)
3. Verifica che sia consistente su tutti i lati (di solito 3mm)
```

## Tips Professionali

### 🎯 Workflow Ottimale

1. **Vista generale** (100%) - Controlla layout complessivo
2. **Zoom medio** (200-300%) - Verifica proporzioni e allineamenti
3. **Zoom dettaglio** (500-800%) - Ispeziona angoli e giunzioni
4. **Reset** - Torna alla vista generale

### 📏 Verifica Dimensioni

- Zoom sulle zone critiche (angoli, giunzioni)
- Controlla sovrapposizioni tra linee di taglio e cordonature
- Verifica che le perforazioni non interferiscano con le cordonature

### 🔍 Ispezione Pre-Export

Prima di esportare per la produzione:

1. ✅ Zoom su ogni angolo - verifica chiusure
2. ✅ Zoom sulle bandelle - controlla incollaggio
3. ✅ Zoom sul fondo - verifica sistema di chiusura
4. ✅ Zoom sulla chiusura superiore - controlla linguette
5. ✅ Vista generale - verifica simmetria

## Scorciatoie da Tastiera (Future)

Pianificate per versioni future:
- `+` / `=` - Zoom In
- `-` - Zoom Out
- `0` - Reset vista
- `Spazio + Trascina` - Pan temporaneo
- `Ctrl + Rotella` - Zoom veloce

## Limitazioni Tecniche

- **Zoom minimo**: 10% (0.1x) - per vedere l'intera fustella anche su fogli molto grandi
- **Zoom massimo**: 1000% (10x) - per ispezionare dettagli millimetrici
- **Performance**: Ottimizzato per fustelle fino a 2000mm x 2000mm

## Risoluzione Problemi

### Lo zoom è troppo lento
- Usa i pulsanti **+** e **−** per incrementi fissi del 30%
- Ogni click zoom del 30% invece dello scroll graduale

### Non riesco a centrare un'area specifica
1. Clicca sul pulsante **⟲** per resettare
2. Posiziona il mouse sull'area di interesse
3. Usa la rotella per zoomare direttamente su quella zona

### La fustella è uscita dallo schermo
- Clicca il pulsante **⟲** (reset) per tornare alla vista completa
- Oppure trascina in direzione opposta per ricentrare

### Il cursore non cambia quando trascino
- Verifica che il browser supporti CSS cursor personalizzati
- Prova con Chrome o Firefox aggiornati

## Compatibilità Browser

Funziona su:
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

Richiede supporto per:
- SVG interattivi
- Mouse events (wheel, drag)
- CSS transforms

## Esempi Pratici

### Esempio 1: Verifica Angolo Scatola Tronco Piramide

La scatola a tronco di piramide ha angoli complessi dove le facce inclinate si incontrano:

```
1. Zoom 400% sull'angolo in basso a sinistra
2. Verifica che le linee di taglio si incontrino perfettamente
3. Controlla che la cordonatura sia a 1-2mm dal bordo
4. Pan verso l'angolo successivo senza cambiare zoom
5. Ripeti la verifica
```

### Esempio 2: Controllo Fondo Automatico

I fondi automatici hanno linguette ad incastro complesse:

```
1. Localizza il fondo nella fustella (parte centrale bassa)
2. Zoom 500% sulla zona delle linguette
3. Verifica le tacche di incastro (perforate o tagliate)
4. Controlla la larghezza delle alette (dovrebbero essere 40% della larghezza base)
5. Verifica simmetria tra lato sinistro e destro
```

### Esempio 3: Ispezione Bandelle Incollaggio

```
1. Identifica la bandella (bordo destro della fustella)
2. Zoom 300%
3. Verifica larghezza: dovrebbe essere 15mm standard
4. Controlla la linea di perforazione (rossa tratteggiata)
5. Verifica che ci siano piccole tacche triangolari agli angoli
```

## Aggiornamenti Futuri

Funzionalità in sviluppo:
- [ ] Zoom su selezione rettangolare
- [ ] Righello virtuale per misurazioni
- [ ] Snap to grid durante il pan
- [ ] Mini-map per navigazione veloce
- [ ] Bookmarks per zone di interesse
- [ ] Confronto side-by-side di diverse versioni

---

**BoxDesigner CAD** - Ispezione professionale delle fustelle con zoom illimitato.
