#!/bin/bash

# Deploy EWH su Mac Studio M2
# Configurato per: fabio@192.168.1.47

set -e

# ========================================
# CONFIGURAZIONE - Personalizzata per te
# ========================================

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"
LOCAL_PATH="/Users/andromeda/dev/ewh"
PROFILE="${1:-pm}"  # Profilo da avviare (default: pm)

# Port forwarding
PORTS=(
  "8080:8080"   # API Gateway
  "3000:3000"   # Auth
  "3001:3001"   # Shell Frontend
  "5432:5432"   # PostgreSQL
  "6379:6379"   # Redis
  "5400:5400"   # PM Frontend (se diverso)
  "5500:5500"   # Altro servizio
)

# ========================================
# SCRIPT
# ========================================

echo "🚀 Deploy EWH su Mac Studio"
echo "========================================"
echo "MacBook:     $LOCAL_PATH"
echo "Mac Studio:  $REMOTE_HOST:$REMOTE_PATH"
echo "Profilo:     $PROFILE"
echo ""

# Verifica connessione
echo "🔍 Verifico connessione a Mac Studio..."
if ! ssh -o ConnectTimeout=5 $REMOTE_HOST "echo '✅ Connesso a Mac Studio!'" 2>/dev/null; then
    echo "❌ Impossibile connettersi a $REMOTE_HOST"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "1. Verifica Remote Login sia abilitato sul Mac Studio"
    echo "   System Settings → General → Sharing → Remote Login (ON)"
    echo ""
    echo "2. Copia la chiave SSH:"
    echo "   ssh-copy-id $REMOTE_HOST"
    echo ""
    echo "3. Testa manualmente:"
    echo "   ssh $REMOTE_HOST"
    exit 1
fi

echo ""

# Crea directory remota
echo "📁 Creo directory su Mac Studio..."
ssh $REMOTE_HOST "mkdir -p $REMOTE_PATH"

# Sync codice (escludendo node_modules e file pesanti)
echo "📦 Sincronizzazione codice..."
echo "⏳ Questo può richiedere qualche minuto la prima volta..."
echo ""

rsync -avz --progress \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'dist' \
  --exclude 'build' \
  --exclude '*.log' \
  --exclude '.DS_Store' \
  --exclude 'postgres_data' \
  --exclude 'redis_data' \
  --exclude '.next' \
  --exclude 'coverage' \
  $LOCAL_PATH/ $REMOTE_HOST:$REMOTE_PATH/

echo ""
echo "✅ Codice sincronizzato!"
echo ""

# Verifica Node.js sul remoto
echo "📦 Verifico ambiente Node.js su Mac Studio..."
NODE_VERSION=$(ssh $REMOTE_HOST "node --version 2>/dev/null || echo 'non installato'")
echo "   Node.js: $NODE_VERSION"

if [ "$NODE_VERSION" == "non installato" ]; then
    echo "⚠️  Node.js non trovato sul Mac Studio!"
    echo ""
    echo "Installa Node.js sul Mac Studio:"
    echo "1. Apri Terminal sul Mac Studio"
    echo "2. Installa Homebrew (se non ce l'hai):"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo "3. Installa Node.js:"
    echo "   brew install node"
    echo ""
    exit 1
fi

# Installa PM2 se non c'è
echo "📦 Verifico PM2..."
if ! ssh $REMOTE_HOST "command -v pm2 &> /dev/null"; then
    echo "   Installo PM2 globalmente..."
    ssh $REMOTE_HOST "npm install -g pm2"
fi
echo "✅ PM2 pronto"
echo ""

# Avvia servizi con profilo selezionato
echo "🚀 Avvio profilo '$PROFILE' sul Mac Studio..."
echo ""

# Verifica se start-profiles.sh esiste
if ssh $REMOTE_HOST "test -f $REMOTE_PATH/start-profiles.sh"; then
    # Usa lo script di profili
    ssh $REMOTE_HOST "cd $REMOTE_PATH && chmod +x start-profiles.sh && ./start-profiles.sh $PROFILE"
else
    echo "⚠️  start-profiles.sh non trovato, avvio manuale..."

    # Avvia servizi base manualmente
    ssh $REMOTE_HOST "cd $REMOTE_PATH/svc-auth && npm install && npx pm2 start npm --name svc-auth -- run dev" || true
    ssh $REMOTE_HOST "cd $REMOTE_PATH/svc-api-gateway && npm install && npx pm2 start npm --name svc-api-gateway -- run dev" || true
    ssh $REMOTE_HOST "cd $REMOTE_PATH/svc-pm && npm install && npx pm2 start npm --name svc-pm -- run dev" || true
    ssh $REMOTE_HOST "cd $REMOTE_PATH/app-pm-frontend && npm install && npx pm2 start npm --name app-pm-frontend -- run dev" || true
fi

echo ""
echo "✅ Servizi avviati!"
echo ""

# Port forwarding
echo "🌐 Setup port forwarding..."
echo ""

# Kill eventuali port forward esistenti
pkill -f "ssh.*-L.*192.168.1.47" 2>/dev/null || true

# Costruisci comando SSH con tutti i port forward
SSH_PORTS=""
for port in "${PORTS[@]}"; do
    SSH_PORTS="$SSH_PORTS -L $port"
    LOCAL_PORT=$(echo $port | cut -d: -f1)
done

echo "Port forward attivi:"
for port in "${PORTS[@]}"; do
    LOCAL_PORT=$(echo $port | cut -d: -f1)
    echo "  ✅ http://localhost:$LOCAL_PORT → Mac Studio:$LOCAL_PORT"
done

# Avvia SSH tunnel in background
ssh -N $SSH_PORTS $REMOTE_HOST &
SSH_PID=$!

echo ""
echo "✅ Port forwarding attivo (PID: $SSH_PID)"

# Salva PID per cleanup
echo $SSH_PID > /tmp/ewh-mac-studio-ssh.pid
echo "$REMOTE_HOST" > /tmp/ewh-mac-studio-host.txt

echo ""
echo "======================================"
echo "🎉 Deploy completato!"
echo "======================================"
echo ""
echo "🌐 Accesso servizi (girano su Mac Studio):"
echo "   🏠 Shell:       http://localhost:3001"
echo "   🔐 Auth:        http://localhost:3000"
echo "   🌐 Gateway:     http://localhost:8080"
echo "   📋 PM:          http://localhost:5400"
echo "   🗄️  PostgreSQL:  localhost:5432"
echo "   💾 Redis:       localhost:6379"
echo ""
echo "🔧 Gestione servizi remoti:"
echo "   📊 Status:   ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 list'"
echo "   📜 Logs:     ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 logs'"
echo "   🔄 Restart:  ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 restart all'"
echo "   ⛔ Stop:     ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 stop all'"
echo ""
echo "🔄 Sync automatico:"
echo "   ./scripts/watch-and-sync-mac-studio.sh"
echo ""
echo "⛔ Stop tutto:"
echo "   ./scripts/stop-mac-studio-dev.sh"
echo ""
