#!/bin/bash

# Stop di tutti i processi remoti e cleanup

echo "⛔ Stop sviluppo remoto EWH"
echo "========================================"
echo ""

# Kill SSH tunnel
if [ -f /tmp/ewh-remote-ssh.pid ]; then
    SSH_PID=$(cat /tmp/ewh-remote-ssh.pid)
    if ps -p $SSH_PID > /dev/null 2>&1; then
        echo "🔌 Chiudo SSH tunnel (PID: $SSH_PID)..."
        kill $SSH_PID 2>/dev/null || true
        rm /tmp/ewh-remote-ssh.pid
        echo "✅ SSH tunnel chiuso"
    else
        echo "ℹ️  SSH tunnel già chiuso"
        rm /tmp/ewh-remote-ssh.pid
    fi
else
    echo "ℹ️  Nessun SSH tunnel attivo"
fi

# Kill eventuali altri port forward
pkill -f "ssh.*-L.*192.168" 2>/dev/null || true

# Kill fswatch (sync automatico)
if pgrep -f "fswatch.*ewh" > /dev/null; then
    echo "👁️  Fermo watch & sync..."
    pkill -f "fswatch.*ewh" || true
    echo "✅ Watch & sync fermato"
fi

echo ""
echo "✅ Cleanup locale completato"
echo ""
echo "Per fermare i servizi sul server remoto:"
echo "  ssh REMOTE_HOST 'cd /path/to/ewh && npx pm2 stop all'"
echo "  # oppure"
echo "  ssh REMOTE_HOST 'cd /path/to/ewh && docker compose down'"
echo ""
