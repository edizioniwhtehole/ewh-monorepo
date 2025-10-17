#!/bin/bash

# Stop sviluppo remoto su Mac Studio

echo "⛔ Stop Sviluppo Remoto - Mac Studio"
echo "========================================"
echo ""

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"

# Kill SSH tunnel
if [ -f /tmp/ewh-mac-studio-ssh.pid ]; then
    SSH_PID=$(cat /tmp/ewh-mac-studio-ssh.pid)
    if ps -p $SSH_PID > /dev/null 2>&1; then
        echo "🔌 Chiudo SSH tunnel (PID: $SSH_PID)..."
        kill $SSH_PID 2>/dev/null || true
        rm /tmp/ewh-mac-studio-ssh.pid
        echo "✅ SSH tunnel chiuso"
    else
        echo "ℹ️  SSH tunnel già chiuso"
        rm /tmp/ewh-mac-studio-ssh.pid
    fi
else
    echo "ℹ️  Nessun SSH tunnel attivo"
fi

# Kill eventuali altri port forward
pkill -f "ssh.*-L.*192.168.1.47" 2>/dev/null || true

# Kill fswatch (sync automatico)
if pgrep -f "fswatch.*ewh" > /dev/null; then
    echo "👁️  Fermo watch & sync..."
    pkill -f "fswatch.*ewh" || true
    echo "✅ Watch & sync fermato"
fi

# Cleanup file temporanei
rm -f /tmp/ewh-mac-studio-host.txt

echo ""
echo "✅ Cleanup locale completato"
echo ""
echo "🖥️  Gestione servizi sul Mac Studio:"
echo "   📊 Vedi status:  ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 list'"
echo "   ⛔ Stop tutti:   ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 stop all'"
echo "   🗑️  Rimuovi PM2:  ssh $REMOTE_HOST 'cd $REMOTE_PATH && npx pm2 delete all'"
echo ""

# Chiedi se fermare anche i servizi sul Mac Studio
read -p "Vuoi fermare anche i servizi sul Mac Studio? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "⛔ Fermo servizi sul Mac Studio..."
    ssh $REMOTE_HOST "cd $REMOTE_PATH && npx pm2 stop all 2>/dev/null || echo 'Nessun servizio PM2 attivo'"
    echo "✅ Servizi fermati"
fi

echo ""
echo "🎉 Tutto pulito!"
echo ""
