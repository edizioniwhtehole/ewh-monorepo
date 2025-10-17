#!/bin/bash

# 🎯 EWH Master Startup - Mac Studio
# Script unificato per avvio completo sistema
#
# Combina:
# 1. Auto-startup (health check + retry)
# 2. Auto-healing (monitoring continuo)
# 3. Logging centralizzato
# 4. Notifiche

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_HOST="fabio@192.168.1.47"

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo ""
echo "${MAGENTA}╔══════════════════════════════════════════════╗${NC}"
echo "${MAGENTA}║                                              ║${NC}"
echo "${MAGENTA}║         EWH Master Startup System            ║${NC}"
echo "${MAGENTA}║              Mac Studio Edition              ║${NC}"
echo "${MAGENTA}║                                              ║${NC}"
echo "${MAGENTA}╚══════════════════════════════════════════════╝${NC}"
echo ""

# 1. Sync script al Mac Studio
echo -e "${BLUE}►${NC} Sync script di startup al Mac Studio..."
rsync -az \
  "$SCRIPT_DIR/auto-startup-macstudio.sh" \
  "$SCRIPT_DIR/auto-healing-macstudio.sh" \
  "$SCRIPT_DIR/../ecosystem.macstudio.config.cjs" \
  $REMOTE_HOST:/Users/fabio/dev/ewh/

# Rendi eseguibili
ssh $REMOTE_HOST "chmod +x /Users/fabio/dev/ewh/auto-startup-macstudio.sh"
ssh $REMOTE_HOST "chmod +x /Users/fabio/dev/ewh/auto-healing-macstudio.sh"

echo -e "${GREEN}✓${NC} Script sincronizzati"
echo ""

# 2. Esegui auto-startup
echo -e "${BLUE}►${NC} Avvio sistema..."
echo ""

if ssh $REMOTE_HOST "cd /Users/fabio/dev/ewh && ./auto-startup-macstudio.sh"; then
    echo ""
    echo -e "${GREEN}✓${NC} Sistema avviato con successo!"
else
    echo ""
    echo -e "${RED}✗${NC} Errore durante avvio sistema"
    echo ""
    echo "Cosa fare:"
    echo "  1. Controlla i log: ssh $REMOTE_HOST 'tail /tmp/ewh-startup-*.log'"
    echo "  2. Verifica servizi: ssh $REMOTE_HOST 'pm2 list'"
    echo "  3. Riprova: ./scripts/master-startup-macstudio.sh"
    exit 1
fi

echo ""
echo -e "${YELLOW}?${NC} Vuoi avviare il monitoring automatico? (consigliato)"
echo "   Il sistema controllerà ogni 30s lo stato dei servizi"
echo "   e li riavvierà automaticamente se necessario."
echo ""
read -p "Avvia auto-healing? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}►${NC} Avvio auto-healing in background..."

    # Avvia auto-healing in background su Mac Studio
    ssh $REMOTE_HOST "cd /Users/fabio/dev/ewh && nohup ./auto-healing-macstudio.sh > /tmp/ewh-autohealing-bg.log 2>&1 & echo \$! > /tmp/ewh-autohealing.pid"

    sleep 2

    if ssh $REMOTE_HOST "[ -f /tmp/ewh-autohealing.pid ]"; then
        HEALING_PID=$(ssh $REMOTE_HOST "cat /tmp/ewh-autohealing.pid")
        echo -e "${GREEN}✓${NC} Auto-healing avviato (PID: $HEALING_PID)"
        echo ""
        echo "Per vedere i log:"
        echo "  ssh $REMOTE_HOST 'tail -f /tmp/ewh-autohealing-bg.log'"
        echo ""
        echo "Per fermare:"
        echo "  ssh $REMOTE_HOST 'kill \$(cat /tmp/ewh-autohealing.pid)'"
    else
        echo -e "${YELLOW}⚠${NC} Auto-healing potrebbe non essere partito"
    fi
fi

echo ""
echo "${MAGENTA}╔══════════════════════════════════════════════╗${NC}"
echo "${MAGENTA}║                                              ║${NC}"
echo "${MAGENTA}║            SISTEMA PRONTO! 🚀                ║${NC}"
echo "${MAGENTA}║                                              ║${NC}"
echo "${MAGENTA}╚══════════════════════════════════════════════╝${NC}"
echo ""

echo "🌐 ${GREEN}Servizi disponibili:${NC}"
echo ""
echo "   ${BLUE}Backend Services:${NC}"
echo "   • http://192.168.1.47:4000  - API Gateway"
echo "   • http://192.168.1.47:4001  - Auth Service"
echo "   • http://192.168.1.47:4003  - Media Service"
echo "   • http://192.168.1.47:5500  - PM Service"
echo ""
echo "   ${BLUE}Frontend Apps:${NC}"
echo "   • http://192.168.1.47:3200  - Admin Panel"
echo "   • http://192.168.1.47:3300  - PM Frontend"
echo "   • http://192.168.1.47:3400  - DAM"
echo "   • http://192.168.1.47:3500  - Inventory"
echo ""

echo "📊 ${GREEN}Comandi utili:${NC}"
echo ""
echo "   ${BLUE}Gestione servizi:${NC}"
echo "   • ssh $REMOTE_HOST 'pm2 list'           - Lista servizi"
echo "   • ssh $REMOTE_HOST 'pm2 logs'           - Tutti i log"
echo "   • ssh $REMOTE_HOST 'pm2 logs svc-auth'  - Log specifico"
echo "   • ssh $REMOTE_HOST 'pm2 restart all'    - Restart tutti"
echo "   • ssh $REMOTE_HOST 'pm2 stop all'       - Ferma tutti"
echo ""
echo "   ${BLUE}Monitoring:${NC}"
echo "   • ssh $REMOTE_HOST 'tail -f /tmp/ewh-autohealing-*.log'  - Log auto-healing"
echo "   • ssh $REMOTE_HOST 'htop'                                - System resources"
echo ""
echo "   ${BLUE}Database:${NC}"
echo "   • ssh $REMOTE_HOST 'PGPASSWORD=ewhpass psql -h localhost -U ewh -d ewh_master'"
echo ""

echo "💡 ${YELLOW}Pro Tips:${NC}"
echo "   • I servizi si riavviano automaticamente in caso di crash"
echo "   • Log persistenti in ./logs/ su Mac Studio"
echo "   • Memory limit automatici per evitare OOM"
echo "   • Health check ogni 30s con auto-restart"
echo ""

echo "${GREEN}Tutto pronto! Buon lavoro! 🎉${NC}"
echo ""
