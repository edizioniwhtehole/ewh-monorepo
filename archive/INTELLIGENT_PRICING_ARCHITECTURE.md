# 🧠 Intelligent Pricing & Procurement Architecture

## Sistema Completo con AI e Reverse Engineering

---

## 📐 ARCHITETTURA MODULARE COMPLETA

```
┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 0: AI & INTELLIGENCE                                         │
├─────────────────────────────────────────────────────────────────────┤
│ svc-ai-pricing (6000)                                               │
│ ├─ Perplexity API Integration                                      │
│ │  └─ Market price research per prodotto                           │
│ ├─ Reverse Engineering Algorithm                                    │
│ │  ├─ Analisi quote ricevuti (multi-quantity)                     │
│ │  ├─ Estrazione curve di costo                                    │
│ │  ├─ Identificazione: costi fissi, variabili, breakpoint         │
│ │  └─ Proiezioni costo per quantità non quotate                   │
│ ├─ Margin Validation Engine                                        │
│ │  ├─ Regole configurabili margine minimo                         │
│ │  ├─ Alert se prezzo troppo basso                                │
│ │  └─ Suggerimenti automatici prezzo ottimale                     │
│ └─ Cost Structure Analysis                                          │
│    ├─ Pattern recognition fornitori                                │
│    ├─ Benchmark vs mercato                                         │
│    └─ Storico per ML predictions                                   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 1: CRM & CONTACTS                                            │
├─────────────────────────────────────────────────────────────────────┤
│ svc-crm-unified (6100)                                              │
│ ├─ Clienti, Fornitori, Lead, Partner, Dipendenti                  │
│ ├─ Rubrica contatti unificata                                      │
│ ├─ Indirizzi multipli (billing, shipping, warehouse)              │
│ ├─ Persone di riferimento                                          │
│ ├─ Attività e storico interazioni                                  │
│ └─ Rating e valutazioni (quality, reliability)                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 2: PROCUREMENT (ACQUISTI)                                    │
├─────────────────────────────────────────────────────────────────────┤
│ svc-procurement (5600) - ENHANCED                                   │
│ ├─ RFQ Request con AI Policy                                       │
│ │  ├─ Multi-Quantity Request automatica                           │
│ │  │  └─ Policy: [100, 500, 1000, 5000, 10000] pz               │
│ │  ├─ Template configurabili per tipo prodotto                    │
│ │  └─ Deadline tracking                                            │
│ ├─ Quote Received & Analysis                                        │
│ │  ├─ Import automatico quote                                      │
│ │  ├─ Parsing multi-quantity                                       │
│ │  ├─ → svc-ai-pricing per reverse engineering                    │
│ │  └─ Visualizzazione curve costo                                  │
│ ├─ Supplier Comparison Matrix                                       │
│ │  ├─ Confronto prezzi per quantità                               │
│ │  ├─ Best price highlighting                                      │
│ │  ├─ Total cost (price + shipping + lead time)                   │
│ │  └─ Quality score weighting                                      │
│ └─ Award & PO Creation                                              │
│    └─ → svc-orders-purchase                                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 3: ORDERS                                                     │
├─────────────────────────────────────────────────────────────────────┤
│ svc-orders-purchase (6200) - Ordini Fornitori                      │
│ ├─ Purchase Orders (PO)                                             │
│ │  ├─ Da RFQ awarded                                               │
│ │  ├─ Da MRP (fabbisogni)                                          │
│ │  └─ Da reorder point                                             │
│ ├─ PO Tracking                                                      │
│ │  ├─ Status: draft, sent, confirmed, partial, completed          │
│ │  ├─ Expected delivery date                                       │
│ │  └─ Collegamenti: shipments, invoices                            │
│ ├─ Goods Receipt                                                    │
│ │  ├─ Quality control                                              │
│ │  └─ → svc-inventory (carico)                                    │
│ └─ Supplier Performance                                             │
│    ├─ On-time delivery rate                                        │
│    ├─ Quality issues tracking                                      │
│    └─ → aggiorna crm.contacts.reliability_score                    │
│                                                                      │
│ svc-orders-sales (6300) - Ordini Clienti                           │
│ ├─ Sales Orders (SO)                                                │
│ │  ├─ Da quote accepted                                            │
│ │  ├─ Da ecommerce/API                                             │
│ │  └─ Manual entry                                                 │
│ ├─ Order Fulfillment                                                │
│ │  ├─ Check inventory availability                                 │
│ │  ├─ → svc-mrp se make-to-order                                  │
│ │  ├─ → svc-inventory (riserva stock)                             │
│ │  └─ Shipping management                                          │
│ ├─ Invoicing                                                        │
│ │  └─ → svc-billing                                                │
│ └─ Customer Stats                                                   │
│    ├─ Order frequency                                              │
│    ├─ Average order value                                          │
│    └─ → aggiorna CRM customer scoring                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 4: INVENTORY                                                  │
├─────────────────────────────────────────────────────────────────────┤
│ svc-inventory (6400)                                                │
│ ├─ Items/SKU Master                                                 │
│ │  ├─ Codice articolo, descrizione                                │
│ │  ├─ Categoria, tipo                                              │
│ │  ├─ UoM (unit of measure)                                        │
│ │  ├─ Peso, dimensioni                                             │
│ │  └─ → link svc-pricelists per prezzi                            │
│ ├─ Stock Management                                                 │
│ │  ├─ Giacenza per ubicazione                                     │
│ │  ├─ Stock disponibile, riservato, in transito                   │
│ │  ├─ Min/max stock levels                                         │
│ │  └─ Reorder point → trigger PO                                   │
│ ├─ Movements                                                        │
│ │  ├─ IN: PO receipt, production output, returns                  │
│ │  ├─ OUT: SO shipment, production consumption, scrap             │
│ │  └─ Transfer between locations                                   │
│ ├─ Lots & Serial Numbers                                            │
│ │  ├─ Tracciabilità lotto                                         │
│ │  ├─ Scadenze                                                     │
│ │  └─ FIFO/FEFO logic                                              │
│ ├─ Physical Inventory                                               │
│ │  ├─ Conteggi periodici                                          │
│ │  ├─ Cycle counting                                               │
│ │  └─ Adjustments                                                  │
│ └─ Locations                                                        │
│    ├─ Warehouse structure                                          │
│    ├─ Aisles, racks, bins                                          │
│    └─ Barcode/QR management                                        │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 5: PRICELISTS                                                │
├─────────────────────────────────────────────────────────────────────┤
│ svc-pricelists-purchase (6500) - Listini Acquisto                  │
│ ├─ Supplier Pricelists                                              │
│ │  ├─ Un fornitore → N listini                                    │
│ │  ├─ Validità temporale (from/to date)                           │
│ │  ├─ Currency                                                     │
│ │  └─ Status: draft, active, expired                              │
│ ├─ Price Breaks (quantity-based)                                    │
│ │  ├─ 1-99 pz: €10                                                │
│ │  ├─ 100-499 pz: €8.50                                           │
│ │  ├─ 500+ pz: €7.00                                              │
│ │  └─ Interpolazione per quantità intermedie                      │
│ ├─ Cost Analysis                                                    │
│ │  ├─ Storico prezzi per trending                                 │
│ │  ├─ → svc-ai-pricing per anomaly detection                      │
│ │  └─ Alert aumenti improvvisi                                     │
│ └─ Best Price Engine                                                │
│    ├─ Real-time comparison tra fornitori                          │
│    ├─ Considera: prezzo + lead time + quality                     │
│    └─ Suggerimenti acquisto ottimale                               │
│                                                                      │
│ svc-pricelists-sales (6600) - Listini Vendita                      │
│ ├─ Customer Pricelists                                              │
│ │  ├─ Listino base (standard)                                     │
│ │  ├─ Listino per categoria cliente (Gold, Silver, Bronze)       │
│ │  ├─ Listino personalizzato per cliente specifico               │
│ │  └─ Listino per canale (retail, wholesale, ecommerce)          │
│ ├─ Pricing Rules Engine                                             │
│ │  ├─ Base: costo interno + markup %                              │
│ │  ├─ Formula: (internal_cost * (1 + markup/100))                │
│ │  ├─ → svc-quotations per workflow pricing                       │
│ │  └─ → svc-ai-pricing per market validation                      │
│ ├─ Margin Protection                                                │
│ │  ├─ Margine minimo per categoria prodotto                       │
│ │  ├─ Alert se prezzo < soglia                                    │
│ │  ├─ Richiede approvazione manager                               │
│ │  └─ → svc-ai-pricing per suggest optimal price                  │
│ ├─ Promotions & Discounts                                           │
│ │  ├─ Sconti temporanei                                           │
│ │  ├─ Volume discounts                                             │
│ │  ├─ Bundle pricing                                               │
│ │  └─ Coupon codes                                                 │
│ └─ Competitive Intelligence                                         │
│    ├─ → svc-ai-pricing + Perplexity                               │
│    ├─ Market price research                                        │
│    ├─ Competitor pricing tracking                                  │
│    └─ Price positioning recommendations                            │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 6: QUOTATIONS (già esistente ma enhanced)                    │
├─────────────────────────────────────────────────────────────────────┤
│ svc-quotations (5800) - Preventivi OUT                              │
│ ├─ Internal Cost Calculation                                        │
│ │  ├─ Workflow editor con nodi                                    │
│ │  ├─ Calcolo costo interno dettagliato                           │
│ │  ├─ Machine time, operator, materials                           │
│ │  └─ → costo_interno                                             │
│ ├─ Margin Application                                               │
│ │  ├─ Applica markup configurabile                                │
│ │  ├─ costo_interno * (1 + margin%)                               │
│ │  ├─ → prezzo_listino_proposto                                   │
│ │  └─ Check vs svc-pricelists-sales margine minimo                │
│ ├─ AI Market Validation                                             │
│ │  ├─ → svc-ai-pricing                                            │
│ │  ├─ Perplexity API: ricerca prezzi mercato                      │
│ │  ├─ Competitor analysis                                          │
│ │  └─ Suggerimenti: "prezzo troppo alto/basso"                   │
│ ├─ Price Finalization                                               │
│ │  ├─ Modifica manuale prezzo finale                              │
│ │  ├─ Salva in svc-pricelists-sales se approvato                 │
│ │  └─ Invia quote al cliente                                      │
│ └─ Quote to Order                                                   │
│    ├─ Se accettato → svc-orders-sales                              │
│    └─ → svc-mrp se produzione                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ LAYER 7: MRP & PRODUCTION                                          │
├─────────────────────────────────────────────────────────────────────┤
│ svc-mrp (6700)                                                       │
│ ├─ Bill of Materials (BOM)                                          │
│ │  ├─ Distinta base prodotto                                      │
│ │  ├─ Component list con quantità                                 │
│ │  └─ Alternative components                                       │
│ ├─ MRP Calculation                                                  │
│ │  ├─ Input: sales orders, forecast                               │
│ │  ├─ Esplosione BOM                                               │
│ │  ├─ Check inventory availability                                 │
│ │  ├─ Calcolo fabbisogni netti                                    │
│ │  └─ → genera planned orders                                      │
│ ├─ Production Orders                                                │
│ │  ├─ Schedulazione su macchine                                   │
│ │  ├─ Capacità produttiva                                         │
│ │  ├─ Material reservation                                         │
│ │  └─ Work orders to shop floor                                    │
│ ├─ Material Consumption                                             │
│ │  ├─ Backflush o manual issue                                    │
│ │  └─ → svc-inventory (scarico)                                   │
│ ├─ Production Output                                                │
│ │  ├─ Finished goods                                               │
│ │  └─ → svc-inventory (carico)                                    │
│ └─ Procurement Trigger                                              │
│    ├─ Se manca materiale                                           │
│    └─ → svc-procurement (auto RFQ)                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 FLUSSO COMPLETO: DA PREVENTIVO A LISTINO

### Scenario: Cliente chiede preventivo per 1000 libretti A5

```
1. CALCOLO COSTO INTERNO
   ├─ svc-quotations/workflow-editor
   │  ├─ Nodo: Macchina (Heidelberg) → 2h × €150/h = €300
   │  ├─ Nodo: Operatore → 2h × €28/h = €56
   │  ├─ Nodo: Carta (500kg × €2.50/kg × 1.05 waste) = €1,312
   │  ├─ Nodo: Inchiostro → €200
   │  ├─ Nodo: Legatrice → 1h × €85/h = €85
   │  ├─ Nodo: Costi fissi (setup) = €150
   │  └─ TOTALE COSTO INTERNO = €2,103

2. APPLICAZIONE MARGINE
   ├─ Margine target: 35%
   ├─ Calcolo: €2,103 × 1.35 = €2,839
   └─ PREZZO LISTINO PROPOSTO = €2,839

3. VALIDAZIONE AI (svc-ai-pricing + Perplexity)
   ├─ Query: "Prezzo mercato stampa 1000 libretti A5 Italia"
   ├─ Risultati:
   │  ├─ Range mercato: €2,500 - €3,200
   │  ├─ Media: €2,850
   │  └─ ✅ Il tuo prezzo €2,839 è competitivo
   └─ Suggerimento: "Prezzo in linea con mercato"

4. CONTROLLO MARGINE MINIMO
   ├─ svc-pricelists-sales: margine minimo = 25%
   ├─ Il tuo margine: 35% ✅
   └─ OK, nessun alert

5. APPROVAZIONE & SALVATAGGIO
   ├─ Manager approva prezzo finale: €2,850
   ├─ Salva in svc-pricelists-sales
   │  └─ Item: "Libretto A5 100 pagine"
   │      ├─ Qty 500-999: €3.20/pz
   │      ├─ Qty 1000-2999: €2.85/pz ← salvato
   │      └─ Qty 3000+: €2.50/pz
   └─ Invia quote al cliente

6. CLIENTE ACCETTA
   ├─ Quote status: accepted
   ├─ → svc-orders-sales (crea SO)
   └─ → svc-mrp (pianifica produzione)
```

---

## 🧮 REVERSE ENGINEERING RFQ (Preventivi IN)

### Scenario: Chiediamo quote a 3 fornitori carta

```
1. RFQ MULTI-QUANTITY (Policy Auto)
   ├─ svc-procurement: crea RFQ
   ├─ Item: "Carta patinata 115g"
   ├─ Quantità richieste (auto-policy):
   │  ├─ 100 kg
   │  ├─ 500 kg
   │  ├─ 1,000 kg
   │  ├─ 5,000 kg
   │  └─ 10,000 kg
   └─ Invia a 3 fornitori

2. RICEZIONE QUOTE
   Fornitore A:
   ├─ 100kg: €350 (€3.50/kg)
   ├─ 500kg: €1,375 (€2.75/kg)
   ├─ 1,000kg: €2,500 (€2.50/kg)
   ├─ 5,000kg: €11,000 (€2.20/kg)
   └─ 10,000kg: €20,000 (€2.00/kg)

   Fornitore B:
   ├─ 100kg: €380 (€3.80/kg)
   ├─ 500kg: €1,450 (€2.90/kg)
   ├─ 1,000kg: €2,600 (€2.60/kg)
   └─ ... (missing data)

   Fornitore C:
   └─ Flat rate: €2.80/kg (qualsiasi quantità)

3. AI REVERSE ENGINEERING (svc-ai-pricing)
   ├─ Analisi Fornitore A:
   │  ├─ Costi fissi stimati: €150
   │  ├─ Costo variabile base: €1.90/kg
   │  ├─ Curve: y = 150 + (1.90 + 0.60/√qty) × qty
   │  └─ Proiezione per 2,000kg: €4,780 (~€2.39/kg)
   │
   ├─ Analisi Fornitore B:
   │  ├─ Dati incompleti
   │  ├─ Interpola: 5,000kg stimato ~€11,500
   │  └─ Meno affidabile per grosse quantità
   │
   └─ Analisi Fornitore C:
   │  ├─ Nessuna economia di scala
   │  ├─ Conveniente solo per piccoli ordini
   │  └─ Break-even vs A: 180kg

4. DECISION SUPPORT
   ├─ Visualizzazione grafici curve costo
   ├─ Tabella comparison:
   │   Qty    | Forn.A  | Forn.B  | Forn.C  | Best
   │   ─────────────────────────────────────────────
   │   100    | €350    | €380    | €280    | C ✓
   │   500    | €1,375  | €1,450  | €1,400  | A ✓
   │   2,000  | €4,780* | €5,100* | €5,600  | A ✓
   │   10,000 | €20,000 | €23,000*| €28,000 | A ✓
   │
   └─ * = proiezione AI

5. STRATEGIC INSIGHTS
   ├─ Suggerimento: "Fornitore A migliore per ordini >500kg"
   ├─ Alert: "Fornitore B dati incompleti, richiedi quote complete"
   ├─ Tip: "Negozia flat rate con A per 10,000+ kg"
   └─ Salva analisi per future RFQ
```

---

## 🤖 AI-POWERED FEATURES

### 1. **Perplexity Integration** (Market Research)
```typescript
// svc-ai-pricing/perplexity.ts
async function getMarketPrice(product: string, quantity: number) {
  const query = `
    Qual è il prezzo medio di mercato in Italia per:
    - Prodotto: ${product}
    - Quantità: ${quantity}
    - Includi: range prezzi, fornitori tipici, fattori che influenzano il prezzo
  `;

  const response = await perplexity.ask(query);

  return {
    priceRange: { min: 2500, max: 3200 },
    average: 2850,
    sources: [...],
    insights: [...]
  };
}
```

### 2. **RFQ Reverse Engineering Algorithm**
```typescript
// svc-ai-pricing/reverse-engineer.ts
function analyzeSupplierCostStructure(quotes: Quote[]) {
  // Ordina per quantità
  const sorted = quotes.sort((a, b) => a.quantity - b.quantity);

  // Calcola cost per unit
  const pricePerUnit = quotes.map(q => ({
    qty: q.quantity,
    unitPrice: q.total_price / q.quantity
  }));

  // Identifica breakpoints
  const breakpoints = findBreakpoints(pricePerUnit);

  // Estrai costi fissi e variabili
  const fixedCost = estimateFixedCost(pricePerUnit);
  const variableCost = estimateVariableCost(pricePerUnit, fixedCost);

  // Crea modello predittivo
  const model = fitCurve(pricePerUnit, fixedCost, variableCost);

  // Proietta prezzi per quantità non quotate
  const projections = projectPrices(model, [200, 750, 2000, 7500]);

  return {
    fixedCost,
    variableCost,
    breakpoints,
    model,
    projections,
    confidence: calculateConfidence(quotes)
  };
}
```

### 3. **Margin Protection Rules**
```typescript
// svc-pricelists-sales/margin-rules.ts
interface MarginRule {
  productCategory: string;
  minMarginPercent: number;
  targetMarginPercent: number;
  approvalRequired: boolean;
  alertThreshold: number;
}

const rules: MarginRule[] = [
  {
    productCategory: 'stampa_offset',
    minMarginPercent: 25,
    targetMarginPercent: 35,
    approvalRequired: true, // se < 25%
    alertThreshold: 30 // avvisa se < 30%
  },
  {
    productCategory: 'legatoria',
    minMarginPercent: 30,
    targetMarginPercent: 40,
    approvalRequired: true,
    alertThreshold: 35
  }
];

function validatePrice(internalCost: number, proposedPrice: number, category: string) {
  const rule = rules.find(r => r.productCategory === category);
  const actualMargin = ((proposedPrice - internalCost) / internalCost) * 100;

  if (actualMargin < rule.minMarginPercent) {
    return {
      status: 'blocked',
      message: `Margine ${actualMargin}% < minimo ${rule.minMarginPercent}%`,
      requiresApproval: true
    };
  }

  if (actualMargin < rule.alertThreshold) {
    return {
      status: 'warning',
      message: `Margine basso: ${actualMargin}%`,
      suggestedPrice: internalCost * (1 + rule.targetMarginPercent / 100)
    };
  }

  return { status: 'ok', margin: actualMargin };
}
```

---

## 🎯 PROSSIMI PASSI

Vuoi che proceda a creare:

1. **svc-inventory** (magazzino completo)
2. **svc-orders-purchase** (ordini fornitori)
3. **svc-orders-sales** (ordini clienti)
4. **svc-pricelists-purchase** (listini acquisto con AI)
5. **svc-pricelists-sales** (listini vendita con margin rules)
6. **svc-ai-pricing** (core AI engine + Perplexity)
7. **Frontend unificato per gestione**

Oppure preferisci che dettagli meglio qualche parte specifica?

La cosa più potente è che ogni modulo comunica con gli altri ma è indipendente!
