#!/bin/bash

# Watch & Sync automatico per Mac Studio
# Ogni volta che salvi un file, viene sincronizzato automaticamente

set -e

# ========================================
# CONFIGURAZIONE
# ========================================

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"
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

echo "👁️  Watch & Sync Automatico → Mac Studio"
echo "========================================"
echo "MacBook:     $LOCAL_PATH"
echo "Mac Studio:  $REMOTE_HOST:$REMOTE_PATH"
echo ""

# Verifica se fswatch è installato
if ! command -v fswatch &> /dev/null; then
    echo "❌ fswatch non trovato!"
    echo ""
    echo "Installa fswatch:"
    echo "  brew install fswatch"
    echo ""
    read -p "Vuoi installarlo ora? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew install fswatch
    else
        exit 1
    fi
fi

# Verifica connessione
if ! ssh -o ConnectTimeout=5 $REMOTE_HOST "echo 'OK'" &>/dev/null; then
    echo "❌ Impossibile connettersi a Mac Studio"
    echo ""
    echo "Verifica:"
    echo "  1. Mac Studio è acceso"
    echo "  2. Remote Login è abilitato"
    echo "  3. SSH funziona: ssh $REMOTE_HOST"
    exit 1
fi

echo "✅ Connessione verificata"
echo "👁️  Watching per cambiamenti..."
echo ""
echo "⚡ Sync veloce al salvataggio"
echo "📦 Esclusi: ${EXCLUDE_PATTERNS[*]}"
echo ""
echo "💡 Ogni volta che salvi un file in VS Code, verrà sincronizzato!"
echo "   Premi Ctrl+C per fermare"
echo ""

# Contatore per evitare troppi sync rapidi
LAST_SYNC=0
DEBOUNCE_SECONDS=1

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

    echo "🔄 $(date '+%H:%M:%S') Sincronizzazione..."

    # Sync con rsync
    eval rsync -az --delete $RSYNC_EXCLUDES \
        $LOCAL_PATH/ $REMOTE_HOST:$REMOTE_PATH/ 2>&1 | \
        grep -v "^building file list" | \
        grep -v "^sending incremental" | \
        grep -v "^sent.*bytes" | \
        grep -v "^total size" || true

    echo "✅ $(date '+%H:%M:%S') Sync completato"

    # Notifica macOS (opzionale)
    if command -v osascript &> /dev/null; then
        osascript -e 'display notification "Codice sincronizzato su Mac Studio" with title "EWH Sync" sound name "default"' 2>/dev/null || true
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
