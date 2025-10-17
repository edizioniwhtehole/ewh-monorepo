#!/bin/bash

# 📊 Status Mac Studio Dev

REMOTE_HOST="fabio@192.168.1.47"

echo ""
echo "📊 EWH Mac Studio - Status"
echo "========================================"
echo ""

# Check se running localmente
if [ -f /tmp/ewh-mac-studio-running.pid ]; then
    MAIN_PID=$(cat /tmp/ewh-mac-studio-running.pid)
    echo "✅ Sistema attivo"
    echo ""
else
    echo "❌ Sistema non attivo"
    echo ""
    echo "Avvia con: ./start-mac-studio.sh"
    exit 0
fi

# Port forward
if [ -f /tmp/ewh-mac-studio-ssh.pid ]; then
    SSH_PID=$(cat /tmp/ewh-mac-studio-ssh.pid)
    if ps -p $SSH_PID > /dev/null 2>&1; then
        echo "✅ Port forwarding attivo (PID: $SSH_PID)"
    else
        echo "❌ Port forwarding non attivo"
    fi
else
    echo "❌ Port forwarding non attivo"
fi

# Sync
if [ -f /tmp/ewh-mac-studio-sync.pid ]; then
    SYNC_PID=$(cat /tmp/ewh-mac-studio-sync.pid)
    if ps -p $SYNC_PID > /dev/null 2>&1; then
        echo "✅ Sync automatico attivo (PID: $SYNC_PID)"
    else
        echo "❌ Sync automatico non attivo"
    fi
else
    echo "⚠️  Sync automatico non configurato"
fi

echo ""
echo "🖥️  Servizi su Mac Studio:"
echo ""

ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 list'

echo ""
echo "🌐 URL Accessibili:"
echo "   http://localhost:5400  ← PM Frontend"
echo "   http://localhost:4000  ← API Gateway"
echo "   http://localhost:5500  ← PM Service"
echo ""
echo "📜 Vedi log: ssh fabio@192.168.1.47 'export PATH=/usr/local/bin:\$PATH && pm2 logs'"
echo ""
