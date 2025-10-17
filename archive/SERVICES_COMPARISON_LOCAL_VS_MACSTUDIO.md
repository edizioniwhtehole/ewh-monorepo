# Services Comparison: Local Mac vs Mac Studio

**Data**: 15 Ottobre 2025, ore 09:03

## 📊 Overview

| Metrica | Local Mac (andromeda) | Mac Studio (fabio) |
|---------|----------------------|-------------------|
| **Processi Node/npm** | 247 | 35 |
| **Server in ascolto** | 49 | 11 |
| **Load Average** | **178.98** 😱 | 1.43 ✅ |
| **CPU Idle** | ~9% | 91.15% ✅ |
| **RAM usata** | 31GB | 30GB |
| **Status** | ⚠️ SOVRACCARICO | ✅ NORMALE |

## 🖥️ LOCAL MAC (Andromeda) - PROBLEMA!

### Servizi Attivi (troppi!)

#### Frontend Apps (11+ attivi):
- ✅ app-pm-frontend (5400)
- ✅ app-box-designer (5900) - DA 6+ ORE!
- ✅ app-workflow-editor (7500 + 7501) - **DUPLICATO**
- ✅ app-previz-frontend (5801) - **DUPLICATO**
- ✅ app-communications-client (5700)
- ✅ app-orchestrator-frontend (7400)
- ✅ app-cms-frontend (5310)
- ✅ app-inventory-frontend (6800)
- ✅ app-page-builder (5101)
- ✅ app-settings-frontend (7100)
- ✅ app-orders-sales-frontend (7000)
- ✅ app-procurement-frontend (5700)
- ✅ app-quotations-frontend (5700)
- ✅ app-orders-purchase-frontend (6900)

#### Backend Services (35+ attivi):
TUTTI i servizi backend sono in esecuzione:
- svc-auth
- svc-pm (TRIPLO - 3 istanze!)
- svc-media (DOPPIO)
- svc-api-gateway
- svc-previz
- svc-video-orchestrator
- svc-shipping
- svc-timesheet
- svc-site-builder
- svc-products
- svc-site-publisher
- svc-search
- svc-vector-lab
- svc-video-runtime
- svc-raster-runtime
- svc-support
- svc-site-renderer
- svc-prepress
- svc-mockup
- svc-forum
- svc-dms
- svc-enrichment
- svc-connectors-web
- svc-mrp
- svc-projects
- svc-plugins
- svc-orders
- svc-quotation
- svc-layout
- svc-job-worker
- svc-content
- svc-image-orchestrator
- svc-comm
- svc-kb
- svc-collab
- svc-writer
- svc-chat
- svc-channels
- svc-bi
- svc-forms
- svc-boards
- svc-crm
- svc-assistant
- svc-billing

### 🚨 Problemi Identificati:
1. **Duplicati**: Molti servizi hanno 2-3 istanze attive
2. **Servizi vecchi**: app-box-designer attivo da 6+ ore
3. **Sovraccarico CPU**: Load average 178 (CRITICO!)
4. **Memoria**: 31GB utilizzati

## 🖥️ MAC STUDIO (Fabio) - OK ✅

### Servizi Attivi (essenziali):

#### Frontend Apps (2):
- ✅ app-pm-frontend (5400)
- ✅ app-communications-client (5700)

#### Backend Services (7):
- ✅ svc-auth (4001)
- ✅ svc-pm (4000)
- ✅ svc-media (3300)
- ✅ svc-api-gateway (4000)
- Altri servizi in porte 3150, 3200, 4003, 4640, 4641

### ✅ Stato Ottimale:
- Load average: 1.43 (normale)
- CPU idle: 91.15%
- Solo servizi essenziali attivi
- Nessun duplicato
- Sistema stabile

## 🎯 RACCOMANDAZIONI

### Opzione 1: FERMARE TUTTO sul Local Mac
```bash
# Ferma tutti i servizi Node
killall node

# O più gentile (raccomandato)
pkill -f "tsx watch"
pkill -f "vite"
```

### Opzione 2: FERMARE DUPLICATI
```bash
# Workflow editor duplicato
kill 41861  # Vecchia istanza porta 7500

# Previz duplicato
kill 57368  # Una delle due istanze

# PM duplicati
kill 35729 14596 36491  # Istanze extra di svc-pm

# Media duplicato
kill 36491  # Istanza extra
```

### Opzione 3: TENERE SOLO ESSENZIALI

**Servizi da tenere** (esempio per sviluppo workflow):
- app-workflow-editor (1 istanza - porta 7501)
- svc-api-gateway (1 istanza)
- svc-auth (1 istanza)
- app-pm-frontend (se serve)

**Fermare tutto il resto**:
```bash
# Script personalizzato
cat > /tmp/stop-extra-services.sh << 'EOF'
#!/bin/bash

# Tieni solo questi PID
KEEP="32003"  # workflow-editor 7501

# Ferma tutti tranne quelli da tenere
ps aux | grep -E "(vite|tsx watch)" | grep -v grep | while read line; do
  PID=$(echo $line | awk '{print $2}')
  if [[ ! " $KEEP " =~ " $PID " ]]; then
    echo "Stopping PID $PID"
    kill $PID
  fi
done
EOF

chmod +x /tmp/stop-extra-services.sh
/tmp/stop-extra-services.sh
```

### Opzione 4: USARE MAC STUDIO per tutto
**Miglior soluzione**:
- Sviluppa sul Mac Studio via SSH/Remote
- Lascia il Local Mac libero
- Performance migliori
- Meno consumo batteria (se laptop)

```bash
# Connetti VSCode al Mac Studio
code --remote ssh-remote+fabio@192.168.1.47 /Users/fabio/dev/ewh
```

## 📈 Performance Comparison

### Build Time (stimato):
- **Local Mac**: Lento (CPU sovraccarica)
- **Mac Studio**: Veloce (CPU libera al 91%)

### Memory Pressure:
- **Local Mac**: ALTA (31GB/32GB)
- **Mac Studio**: BASSA (30GB/32GB ma con meno processi)

### Responsiveness:
- **Local Mac**: Lenta (Load 178!)
- **Mac Studio**: Normale (Load 1.43)

## 🔧 Script di Cleanup Consigliato

```bash
#!/bin/bash
# cleanup-local-services.sh

echo "🧹 Cleaning up local services..."

# 1. Ferma tutti i servizi tsx watch
echo "Stopping tsx watch processes..."
pkill -f "tsx watch"

# 2. Ferma tutti i vite servers
echo "Stopping vite servers..."
pkill -f "vite"

# 3. Aspetta che si fermino
sleep 3

# 4. Forza chiusura se ancora attivi
echo "Force killing remaining node processes..."
killall -9 node 2>/dev/null

# 5. Verifica
echo "Remaining node processes:"
ps aux | grep -E "(node|npm)" | grep -v grep | wc -l

echo "✅ Cleanup complete!"
```

## 💡 Best Practices

### Per Sviluppo:
1. **Usa Mac Studio** per servizi pesanti
2. **Usa Local Mac** solo per frontend in sviluppo attivo
3. **Non avviare** tutti i servizi insieme
4. **Monitora** con `top` o Activity Monitor

### Per Testing:
1. Avvia solo i servizi necessari per il test
2. Usa Docker Compose con profili (se disponibile)
3. Ferma i servizi dopo il test

### Per Production:
1. Usa orchestrazione (Kubernetes, Docker Swarm)
2. Deploy su Mac Studio o server dedicato
3. Non sviluppare su macchina di produzione

## 🎯 Azione Immediata Consigliata

**Cosa fare ORA**:

1. **Ferma TUTTO sul Local Mac**:
   ```bash
   killall node
   ```

2. **Riavvia SOLO workflow editor**:
   ```bash
   cd /Users/andromeda/dev/ewh/app-workflow-editor
   npm run dev
   ```

3. **Verifica**:
   ```bash
   # Dovrebbe mostrare solo 1-2 processi
   ps aux | grep node | grep -v grep | wc -l
   ```

4. **Usa Mac Studio** per gli altri servizi se necessario

---

**Risultato atteso**:
- Load average: Da 178 → ~2-5
- Processi Node: Da 247 → ~5-10
- CPU Idle: Da ~9% → ~80%+
- Sistema: Responsivo e veloce

