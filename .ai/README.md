# .ai/ Directory - AI Agent Context Caching

> **Directory per ottimizzazione token e caching context per AI agents**

## 📋 Scopo

Questa directory contiene file di cache che permettono agli AI agents di:
1. **Ridurre token usage** - Leggere JSON compatto invece di migliaia di righe di documentazione
2. **Velocizzare analisi** - Capire stato progetto in secondi invece di minuti
3. **Evitare re-letture** - Usare cache invece di ri-analizzare codebase ogni volta

## 📁 File

### context.json (PRIMARY CACHE)

**Contenuto:**
- Stato di tutti i 51 servizi (complete/in_progress/scaffolding)
- Dipendenze tra servizi
- Priorità implementazione
- Tech stack e convenzioni
- Link a documentazione rilevante
- Metriche progetto

**Quando usare:**
- ✅ **SEMPRE come primo file da leggere**
- ✅ Per verificare se servizio è implementato
- ✅ Per capire dipendenze
- ✅ Per trovare esempi di codice

**Quando NON usare:**
- ❌ Per dettagli implementativi (usare PROJECT_STATUS.md)
- ❌ Per regole di coordinamento (usare GUARDRAILS.md)
- ❌ Per istruzioni coding (usare MASTER_PROMPT.md)

**Formato:**
```json
{
  "services": {
    "complete": [...],    // Servizi pronti per uso
    "in_progress": [...], // Servizi parzialmente implementati
    "scaffolding": {...}  // Servizi solo con health check
  },
  "dependencies": {
    "implemented": {...},      // Dipendenze funzionanti
    "missing_blockers": {...}  // Dipendenze che bloccano feature
  },
  "priority_queue": {...}  // Roadmap implementazione
}
```

## 🔄 Workflow Ottimizzato per Token

### ❌ VECCHIO MODO (Token-Heavy)

```typescript
// Agent legge tutto subito:
1. Read ARCHITECTURE.md (5000+ righe, ~15k tokens)
2. Read PROJECT_STATUS.md (3000+ righe, ~10k tokens)
3. Read GUARDRAILS.md (2000+ righe, ~7k tokens)
4. Read MASTER_PROMPT.md (2000+ righe, ~7k tokens)
5. Read {service}/PROMPT.md (200+ righe, ~1k tokens)

// TOTALE: ~40k tokens solo per capire stato progetto
```

### ✅ NUOVO MODO (Token-Efficient)

```typescript
// Agent usa cache strategicamente:
1. Read .ai/context.json (500 righe, ~2k tokens) ← CACHE HIT
   → Capisce stato servizio in 30 secondi

2. IF servizio = "scaffolding":
   → Non leggere implementazione (non esiste!)
   → Vai diretto a implementazione

3. IF servizio = "complete":
   → Leggi solo {service}/PROMPT.md per dettagli
   → Skip documentazione generale

4. IF dubbi su regole:
   → Leggi GUARDRAILS.md (solo quando serve)

// TOTALE: ~2-5k tokens (risparmio 80-90%)
```

## 📊 Esempio: Task "Implementare endpoint orders"

### Workflow Ottimizzato

```typescript
// Step 1: Quick Check (30 secondi, 2k tokens)
const context = await readJSON('.ai/context.json')

// Trovare servizio
const service = 'svc-orders'
const status = context.services.scaffolding.erp.includes(service)
  ? 'scaffolding'
  : 'unknown'

// Verificare dipendenze
const deps = context.dependencies.missing_blockers.order_flow
// → Missing: svc-products, svc-inventory, svc-billing

console.log(`
  Service: ${service}
  Status: SCAFFOLDING (non implementato)
  Dipendenze: BLOCCANTI (svc-products, svc-inventory, svc-billing non pronti)
  Decisione: BLOCCARE o usare mock data
`)

// Step 2: Se decido di procedere con mock (1 min, 1k tokens)
// Leggo solo template da MASTER_PROMPT.md → "Pattern 1: Endpoint CRUD"

// Step 3: Implemento (30 min, coding)

// Step 4: Aggiorno cache (1 min)
// Modifico context.json: svc-orders da "scaffolding" a "in_progress"

// TOTALE: ~3k tokens vs 40k tokens (risparmio 92%)
```

## 🔧 Manutenzione Cache

### Quando Aggiornare context.json

**SEMPRE dopo:**
- ✅ Completamento servizio (da "scaffolding" → "complete")
- ✅ Aggiunta feature maggiore (incrementare completion %)
- ✅ Cambio dipendenze (aggiungere/rimuovere blockers)
- ✅ Aggiornamento priorità roadmap

**OGNI settimana:**
- ✅ Sincronizzare con PROJECT_STATUS.md
- ✅ Verificare "last_change" dates
- ✅ Aggiornare metriche (completion %)

**Script di aggiornamento:**
```bash
# Generare context.json da PROJECT_STATUS.md
./scripts/generate-context.sh

# O manualmente:
# 1. Leggere PROJECT_STATUS.md
# 2. Aggiornare sezione "services" in context.json
# 3. Aggiornare "last_updated" timestamp
# 4. Commit: docs: update .ai/context.json
```

### Validazione Cache

```bash
# Controllare che cache sia sincronizzata
npm run validate-context

# Output:
# ✅ context.json is up to date
# ⚠️ context.json is 5 days old, consider updating
# ❌ context.json has mismatches with PROJECT_STATUS.md
```

## 📈 Token Savings Metrics

**Scenario: 10 tasks al giorno per 30 giorni**

**Senza cache:**
- 40k tokens/task × 10 tasks × 30 giorni = 12M tokens/mese
- Costo (GPT-4): ~$240/mese

**Con cache:**
- 3k tokens/task × 10 tasks × 30 giorni = 900k tokens/mese
- Costo (GPT-4): ~$18/mese

**Risparmio:** $222/mese (92.5%)

## 🎯 Best Practices

### ✅ DO

- Leggere context.json SEMPRE come primo file
- Aggiornare context.json dopo modifiche maggiori
- Usare context.json per decisioni rapide (è servizio implementato?)
- Riferirsi a documentazione completa solo quando servono dettagli

### ❌ DON'T

- Non usare context.json come unica fonte di verità (può essere outdated)
- Non saltare lettura PROJECT_STATUS.md se cache ha > 2 settimane
- Non implementare features basandosi solo su cache (verificare sempre codice)
- Non dimenticare di aggiornare cache dopo modifiche

## 🔗 Riferimenti

**Documentazione Completa:**
- [CONTEXT_INDEX.md](../CONTEXT_INDEX.md) - Indice rapido
- [PROJECT_STATUS.md](../PROJECT_STATUS.md) - Stato dettagliato (source of truth)
- [MASTER_PROMPT.md](../MASTER_PROMPT.md) - Istruzioni universali
- [GUARDRAILS.md](../GUARDRAILS.md) - Regole coordinamento

**Cache Files:**
- `context.json` - Project state cache (questo file)

**Future Expansion:**
- `service-stats.json` - Per-service metrics cache (TODO)
- `dependency-graph.json` - Visual dependency graph (TODO)
- `test-coverage.json` - Coverage metrics cache (TODO)

---

**Versione:** 1.0.0
**Ultima generazione:** 2025-10-04
**Prossima rigenerazione:** 2025-10-18 (bi-weekly)
**Maintainer:** Tech Lead Team
