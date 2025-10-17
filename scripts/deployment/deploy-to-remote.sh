#!/bin/bash

# Deploy codice EWH su server remoto e avvia servizi
# Esegui questo sulla macchina LOCALE

set -e

# ========================================
# CONFIGURAZIONE - Modifica questi valori
# ========================================

REMOTE_HOST="${REMOTE_HOST:-user@192.168.1.100}"  # Cambia con il tuo server
REMOTE_PATH="${REMOTE_PATH:-/home/user/ewh}"
LOCAL_PATH="/Users/andromeda/dev/ewh"
PROFILE="${1:-dam}"  # Profilo da avviare (default: dam)

# Port forwarding - aggiungi le porte che ti servono
PORTS=(
  "8080:8080"   # API Gateway
  "3000:3000"   # Auth
  "3001:3001"   # Shell Frontend
  "5432:5432"   # PostgreSQL
  "6379:6379"   # Redis
)

# ========================================
# SCRIPT
# ========================================

echo "🚀 Deploy EWH su Server Remoto"
echo "========================================"
echo "Locale:  $LOCAL_PATH"
echo "Remoto:  $REMOTE_HOST:$REMOTE_PATH"
echo "Profilo: $PROFILE"
echo ""

# Verifica connessione
echo "🔍 Verifico connessione al server..."
if ! ssh -o ConnectTimeout=5 $REMOTE_HOST "echo '✅ Connessione OK'" 2>/dev/null; then
    echo "❌ Impossibile connettersi a $REMOTE_HOST"
    echo ""
    echo "Verifica:"
    echo "  1. Il server è acceso e raggiungibile"
    echo "  2. SSH è configurato correttamente"
    echo "  3. Hai le chiavi SSH configurate"
    echo ""
    echo "Setup SSH veloce:"
    echo "  ssh-keygen -t rsa -b 4096"
    echo "  ssh-copy-id $REMOTE_HOST"
    exit 1
fi

# Crea directory remota
echo "📁 Creo directory remota..."
ssh $REMOTE_HOST "mkdir -p $REMOTE_PATH"

# Sync codice (escludendo node_modules e file pesanti)
echo "📦 Sincronizzazione codice..."
rsync -avz --progress \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'dist' \
  --exclude 'build' \
  --exclude '*.log' \
  --exclude '.DS_Store' \
  --exclude 'postgres_data' \
  --exclude 'redis_data' \
  $LOCAL_PATH/ $REMOTE_HOST:$REMOTE_PATH/

echo "✅ Codice sincronizzato"
echo ""

# Installa dipendenze se necessario
echo "📦 Verifico dipendenze..."
ssh $REMOTE_HOST "cd $REMOTE_PATH && if [ ! -d 'node_modules' ]; then npm install; fi"

# Avvia servizi con profilo selezionato
echo "🚀 Avvio profilo '$PROFILE' sul server remoto..."

# Verifica se start-profiles.sh esiste
if ssh $REMOTE_HOST "test -f $REMOTE_PATH/start-profiles.sh"; then
    ssh $REMOTE_HOST "cd $REMOTE_PATH && ./start-profiles.sh $PROFILE"
else
    echo "⚠️  start-profiles.sh non trovato, uso docker-compose..."
    ssh $REMOTE_HOST "cd $REMOTE_PATH && docker compose -f compose/docker-compose.dev.yml up -d"
fi

echo "✅ Servizi avviati"
echo ""

# Port forwarding
echo "🌐 Setup port forwarding..."
echo "Le seguenti porte saranno accessibili su localhost:"

# Kill eventuali port forward esistenti
pkill -f "ssh.*-L.*$REMOTE_HOST" 2>/dev/null || true

# Costruisci comando SSH con tutti i port forward
SSH_PORTS=""
for port in "${PORTS[@]}"; do
    SSH_PORTS="$SSH_PORTS -L $port"
    LOCAL_PORT=$(echo $port | cut -d: -f1)
    echo "  http://localhost:$LOCAL_PORT"
done

# Avvia SSH tunnel in background
ssh -N $SSH_PORTS $REMOTE_HOST &
SSH_PID=$!

echo ""
echo "✅ Port forwarding attivo (PID: $SSH_PID)"
echo ""

# Salva PID per cleanup
echo $SSH_PID > /tmp/ewh-remote-ssh.pid

echo "======================================"
echo "🎉 Deploy completato!"
echo "======================================"
echo ""
echo "Accesso servizi (girano su $REMOTE_HOST):"
echo "  🏠 Shell:       http://localhost:3001"
echo "  🔐 Auth:        http://localhost:3000"
echo "  🌐 Gateway:     http://localhost:8080"
echo "  🗄️  PostgreSQL:  localhost:5432"
echo "  💾 Redis:       localhost:6379"
echo ""
echo "Gestione servizi remoti:"
echo "  📊 Status:   ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 list'"
echo "  📜 Logs:     ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 logs'"
echo "  🔄 Restart:  ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 restart all'"
echo "  ⛔ Stop:     ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 stop all'"
echo ""
echo "Sync automatico:"
echo "  ./scripts/watch-and-sync.sh $REMOTE_HOST $REMOTE_PATH"
echo ""
echo "Stop port forwarding:"
echo "  kill $SSH_PID"
echo "  # oppure"
echo "  ./scripts/stop-remote-dev.sh"
echo ""
