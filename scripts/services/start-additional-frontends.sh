#!/bin/bash

# 🚀 Avvia Frontend Aggiuntivi
# CMS, Media Frontend, Box Designer

REMOTE_HOST="fabio@192.168.1.47"

echo ""
echo "🚀 Avvio Frontend Aggiuntivi"
echo "============================="
echo ""

echo "Servizi da avviare:"
echo "  • app-cms-frontend (porta 3600)"
echo "  • app-media-frontend (porta 3700)"
echo "  • app-box-designer (porta 3350)"
echo ""

# Avvia i 3 servizi usando ecosystem config
ssh $REMOTE_HOST 'bash -s' << 'ENDSSH'
export PATH=/usr/local/bin:$PATH
cd /Users/fabio/dev/ewh

echo "► Caricamento ecosystem config..."

# Avvia i 3 nuovi servizi
echo "► Avvio app-cms-frontend..."
pm2 start ecosystem.macstudio.config.cjs --only app-cms-frontend 2>&1 | tail -3

sleep 3

echo "► Avvio app-media-frontend..."
pm2 start ecosystem.macstudio.config.cjs --only app-media-frontend 2>&1 | tail -3

sleep 3

echo "► Avvio app-box-designer..."
pm2 start ecosystem.macstudio.config.cjs --only app-box-designer 2>&1 | tail -3

sleep 2

# Salva stato PM2
pm2 save

echo ""
echo "✓ Servizi avviati!"
echo ""
echo "Status:"
pm2 list | grep -E "app-cms-frontend|app-media-frontend|app-box-designer"

ENDSSH

echo ""
echo "═══════════════════════════════════════"
echo "  ✓ FRONTEND AGGIUNTIVI AVVIATI"
echo "═══════════════════════════════════════"
echo ""
echo "Accedi ai servizi:"
echo "  • CMS Frontend:   http://192.168.1.47:3600"
echo "  • Media Frontend: http://192.168.1.47:3700"
echo "  • Box Designer:   http://192.168.1.47:3350"
echo ""
echo "Comandi utili:"
echo "  ssh $REMOTE_HOST 'pm2 logs app-cms-frontend'"
echo "  ssh $REMOTE_HOST 'pm2 logs app-media-frontend'"
echo "  ssh $REMOTE_HOST 'pm2 logs app-box-designer'"
echo ""
