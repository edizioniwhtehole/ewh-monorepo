#!/bin/bash

# 🎨 Frontend Manager per Mac Studio
# Gestisci tutti i frontend facilmente

REMOTE_HOST="fabio@192.168.1.47"

# Colori
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Frontend Manager                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Menu
echo "Cosa vuoi fare?"
echo ""
echo "  1) Visualizza status di tutti i frontend"
echo "  2) Avvia tutti i frontend"
echo "  3) Riavvia tutti i frontend"
echo "  4) Stop tutti i frontend"
echo "  5) Logs di tutti i frontend"
echo "  6) Visualizza URLs"
echo ""
read -p "Scegli opzione (1-6): " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}► Status Frontend${NC}"
        echo ""
        ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 list | grep "^│" | grep "app-"'
        ;;

    2)
        echo ""
        echo -e "${BLUE}► Avvio Tutti i Frontend${NC}"
        echo ""
        ssh $REMOTE_HOST 'bash -s' << 'ENDSSH'
export PATH=/usr/local/bin:$PATH
cd /Users/fabio/dev/ewh

# Lista frontend da avviare
FRONTENDS=(
    "app-admin-frontend"
    "app-pm-frontend"
    "app-dam"
    "app-inventory-frontend"
    "app-cms-frontend"
    "app-media-frontend"
    "app-box-designer"
)

for frontend in "${FRONTENDS[@]}"; do
    if [ -d "$frontend" ]; then
        echo "► Avvio $frontend..."
        pm2 start ecosystem.macstudio.config.cjs --only "$frontend" 2>&1 | tail -2
        sleep 2
    fi
done

pm2 save
echo ""
echo "✓ Avvio completato!"
ENDSSH
        ;;

    3)
        echo ""
        echo -e "${BLUE}► Riavvio Tutti i Frontend${NC}"
        echo ""
        ssh $REMOTE_HOST 'bash -s' << 'ENDSSH'
export PATH=/usr/local/bin:$PATH

# Riavvia tutti i frontend
pm2 restart all | grep "app-" || pm2 list | grep "app-"

echo ""
echo "✓ Riavvio completato!"
ENDSSH
        ;;

    4)
        echo ""
        echo -e "${YELLOW}► Stop Tutti i Frontend${NC}"
        echo ""
        read -p "Sei sicuro? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh $REMOTE_HOST 'bash -s' << 'ENDSSH'
export PATH=/usr/local/bin:$PATH

# Stop tutti i processi che iniziano con app-
pm2 list | grep "app-" | awk '{print $4}' | xargs -I {} pm2 stop {}

echo ""
echo "✓ Tutti i frontend fermati"
ENDSSH
        fi
        ;;

    5)
        echo ""
        echo -e "${BLUE}► Logs Frontend (Ctrl+C per uscire)${NC}"
        echo ""
        ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 logs --lines 50 | grep "app-"'
        ;;

    6)
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║       URLs Servizi Frontend            ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "  🌐 Admin Panel:      http://192.168.1.47:3200"
        echo "  🌐 PM Frontend:      http://192.168.1.47:3300"
        echo "  🌐 Box Designer:     http://192.168.1.47:3350"
        echo "  🌐 DAM:              http://192.168.1.47:3400"
        echo "  🌐 Inventory:        http://192.168.1.47:3500"
        echo "  🌐 CMS Frontend:     http://192.168.1.47:3600"
        echo "  🌐 Media Frontend:   http://192.168.1.47:3700"
        echo ""
        ;;

    *)
        echo -e "${RED}Opzione non valida${NC}"
        exit 1
        ;;
esac

echo ""
