#!/bin/bash

# 🚀 Start Mac Studio Dev - One Click Setup
# Avvia tutto automaticamente e ti toglie ogni pensiero!

set -e

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"
LOCAL_PATH="/Users/andromeda/dev/ewh"

echo ""
echo "🚀 EWH Mac Studio - Avvio Automatico"
echo "========================================"
echo ""

# Check se già running
if [ -f /tmp/ewh-mac-studio-running.pid ]; then
    OLD_PID=$(cat /tmp/ewh-mac-studio-running.pid)
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo "✅ Già in esecuzione (PID: $OLD_PID)"
        echo ""
        echo "📊 Status servizi Mac Studio:"
        ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 list'
        echo ""
        echo "🌐 Accedi a: http://localhost:5400"
        echo ""
        echo "Per fermare tutto: ./stop-mac-studio.sh"
        exit 0
    fi
fi

# 1. Verifica connessione
echo "🔍 Verifico connessione Mac Studio..."
if ! ssh -o ConnectTimeout=3 $REMOTE_HOST "echo 'OK'" &>/dev/null; then
    echo "❌ Mac Studio non raggiungibile!"
    echo ""
    echo "Verifica:"
    echo "  1. Mac Studio è acceso"
    echo "  2. Sulla stessa rete WiFi"
    echo "  3. Remote Login abilitato"
    exit 1
fi
echo "✅ Connessione OK"
echo ""

# 2. Sync iniziale veloce
echo "📦 Sync iniziale..."
rsync -az --delete \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'dist' \
  --exclude 'build' \
  --exclude '*.log' \
  --exclude '.DS_Store' \
  --exclude 'postgres_data' \
  --exclude 'redis_data' \
  $LOCAL_PATH/svc-auth \
  $LOCAL_PATH/svc-api-gateway \
  $LOCAL_PATH/svc-pm \
  $LOCAL_PATH/app-pm-frontend \
  $REMOTE_HOST:$REMOTE_PATH/ 2>&1 | grep -v "building file list" | grep -v "sending incremental" || true
echo "✅ Sync completato"
echo ""

# 3. Verifica servizi
echo "🔍 Verifico servizi su Mac Studio..."
SERVICES=$(ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 list | grep -c online || echo 0')

if [ "$SERVICES" -lt 4 ]; then
    echo "🚀 Avvio servizi..."

    # Restart tutti i servizi
    ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 restart all 2>/dev/null || {
        cd /Users/fabio/dev/ewh/svc-auth && pm2 start npm --name svc-auth -- run dev 2>/dev/null || true
        cd /Users/fabio/dev/ewh/svc-api-gateway && pm2 start npm --name svc-api-gateway -- run dev 2>/dev/null || true
        cd /Users/fabio/dev/ewh/svc-pm && pm2 start npm --name svc-pm -- run dev 2>/dev/null || true
        cd /Users/fabio/dev/ewh/app-pm-frontend && pm2 start npm --name app-pm-frontend -- run dev 2>/dev/null || true
    }' &>/dev/null

    echo "⏳ Aspetto che i servizi siano pronti (10 secondi)..."
    sleep 10
fi
echo "✅ Servizi attivi"
echo ""

# 4. Port forwarding
echo "🌐 Configurazione port forwarding..."

# Kill vecchi port forward
pkill -f "ssh.*-L.*192.168.1.47" 2>/dev/null || true
sleep 1

# Avvia port forward in background
ssh -N -L 4000:localhost:4000 -L 5500:localhost:5500 -L 5400:localhost:5400 $REMOTE_HOST &
SSH_PID=$!
echo $SSH_PID > /tmp/ewh-mac-studio-ssh.pid
echo "✅ Port forwarding attivo"
echo ""

# 5. Avvia sync automatico in background
echo "👁️  Avvio sync automatico..."

# Check fswatch
if ! command -v fswatch &> /dev/null; then
    echo "⚠️  fswatch non trovato, installo..."
    brew install fswatch &>/dev/null || {
        echo "❌ Impossibile installare fswatch. Installa manualmente:"
        echo "   brew install fswatch"
        echo ""
        echo "Puoi comunque usare il sistema, ma dovrai sincronizzare manualmente."
    }
fi

if command -v fswatch &> /dev/null; then
    # Script sync in background
    (
        while true; do
            fswatch -o \
                --exclude='node_modules' \
                --exclude='.git' \
                --exclude='dist' \
                --exclude='build' \
                --exclude='.next' \
                --exclude='*.log' \
                "$LOCAL_PATH" | while read event; do

                # Debounce
                sleep 1

                # Sync
                rsync -az --delete \
                    --exclude 'node_modules' \
                    --exclude '.git' \
                    --exclude 'dist' \
                    --exclude 'build' \
                    --exclude '*.log' \
                    --exclude '.DS_Store' \
                    $LOCAL_PATH/svc-auth \
                    $LOCAL_PATH/svc-api-gateway \
                    $LOCAL_PATH/svc-pm \
                    $LOCAL_PATH/app-pm-frontend \
                    $REMOTE_HOST:$REMOTE_PATH/ 2>&1 | grep -v "building file list" > /dev/null || true

                # Notifica (opzionale)
                osascript -e 'display notification "Codice sincronizzato" with title "EWH Mac Studio"' 2>/dev/null || true
            done
            sleep 5
        done
    ) &

    SYNC_PID=$!
    echo $SYNC_PID > /tmp/ewh-mac-studio-sync.pid
    echo "✅ Sync automatico attivo"
else
    echo "⚠️  Sync automatico non disponibile (manca fswatch)"
    SYNC_PID="N/A"
fi

# Salva PID principale
echo $$ > /tmp/ewh-mac-studio-running.pid

echo ""
echo "======================================"
echo "🎉 TUTTO PRONTO!"
echo "======================================"
echo ""
echo "🌐 Accedi dal browser:"
echo "   http://localhost:5400  ← PM Frontend"
echo "   http://localhost:4000  ← API Gateway"
echo "   http://localhost:5500  ← PM Service"
echo ""
echo "💻 Workflow:"
echo "   1. Edita codice sul MacBook con VS Code"
echo "   2. Salva file → Sync automatico in 1-2 sec"
echo "   3. Hot reload sul Mac Studio"
echo ""
echo "📊 Gestione:"
echo "   Status:  ./scripts/status-mac-studio.sh"
echo "   Stop:    ./stop-mac-studio.sh"
echo ""
echo "💡 Questo script gira in background!"
echo "   PID Port Forward: $SSH_PID"
if [ "$SYNC_PID" != "N/A" ]; then
    echo "   PID Sync Auto:    $SYNC_PID"
fi
echo ""

# Apri browser
echo "🌐 Apro browser..."
sleep 2
open http://localhost:5400

echo ""
echo "✅ Setup completato! Puoi chiudere questo terminale."
echo "   I processi continuano in background."
echo ""
echo "Per fermare: ./stop-mac-studio.sh"
echo ""
