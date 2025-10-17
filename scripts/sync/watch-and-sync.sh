#!/bin/bash

# Watch per cambiamenti locali e sync automatico a server remoto
# Esegui questo sulla macchina LOCALE in un terminale separato

set -e

# ========================================
# CONFIGURAZIONE
# ========================================

REMOTE_HOST="${1:-user@192.168.1.100}"
REMOTE_PATH="${2:-/home/user/ewh}"
LOCAL_PATH="/Users/andromeda/dev/ewh"

# Escludi questi pattern dal sync
EXCLUDE_PATTERNS=(
  "node_modules"
  ".git"
  "dist"
  "build"
  "*.log"
  ".DS_Store"
  "postgres_data"
  "redis_data"
  ".next"
  "coverage"
)

# ========================================
# SCRIPT
# ========================================

echo "👁️  Watch & Sync Automatico - EWH"
echo "========================================"
echo "Locale:  $LOCAL_PATH"
echo "Remoto:  $REMOTE_HOST:$REMOTE_PATH"
echo ""

# Verifica se fswatch è installato
if ! command -v fswatch &> /dev/null; then
    echo "❌ fswatch non trovato!"
    echo ""
    echo "Installa fswatch:"
    echo "  macOS:  brew install fswatch"
    echo "  Linux:  sudo apt install fswatch"
    exit 1
fi

# Verifica connessione
if ! ssh -o ConnectTimeout=5 $REMOTE_HOST "echo 'OK'" &>/dev/null; then
    echo "❌ Impossibile connettersi a $REMOTE_HOST"
    exit 1
fi

echo "✅ Connessione verificata"
echo "👁️  Watching per cambiamenti in $LOCAL_PATH"
echo ""
echo "⚡ Sync veloce al primo salvataggio rilevato"
echo "📦 Esclusi: ${EXCLUDE_PATTERNS[*]}"
echo ""
echo "Premi Ctrl+C per fermare"
echo ""

# Contatore per evitare troppi sync rapidi
LAST_SYNC=0
DEBOUNCE_SECONDS=2

# Costruisci exclude flags per rsync
RSYNC_EXCLUDES=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    RSYNC_EXCLUDES="$RSYNC_EXCLUDES --exclude='$pattern'"
done

# Funzione di sync
do_sync() {
    local current_time=$(date +%s)
    local time_since_last=$((current_time - LAST_SYNC))

    # Debounce: evita sync troppo ravvicinati
    if [ $time_since_last -lt $DEBOUNCE_SECONDS ]; then
        return
    fi

    LAST_SYNC=$current_time

    echo "🔄 $(date '+%H:%M:%S') Sincronizzazione in corso..."

    # Sync con rsync
    eval rsync -az --delete $RSYNC_EXCLUDES \
        $LOCAL_PATH/ $REMOTE_HOST:$REMOTE_PATH/ 2>&1 | grep -v "^building file list" | grep -v "^sending incremental" || true

    echo "✅ $(date '+%H:%M:%S') Sync completato"

    # Notifica (opzionale, richiede terminal-notifier: brew install terminal-notifier)
    if command -v terminal-notifier &> /dev/null; then
        terminal-notifier -title "EWH Sync" -message "Codice sincronizzato" -sound default &>/dev/null || true
    fi
}

# Sync iniziale
echo "📦 Sync iniziale..."
do_sync
echo ""

# Watch per cambiamenti
fswatch -o \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='dist' \
    --exclude='build' \
    --exclude='.next' \
    --exclude='*.log' \
    "$LOCAL_PATH" | while read event; do
    do_sync
done
