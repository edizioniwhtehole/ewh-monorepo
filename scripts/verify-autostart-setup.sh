#!/bin/bash

# 🔍 Verifica Setup Auto-Start System
# Controlla che tutto sia configurato correttamente

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local name="$1"
    local command="$2"
    local required="${3:-true}"

    echo -n "  Checking $name... "

    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        PASS=$((PASS + 1))
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC}"
            FAIL=$((FAIL + 1))
        else
            echo -e "${YELLOW}⚠${NC} (optional)"
            WARN=$((WARN + 1))
        fi
        return 1
    fi
}

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  EWH Auto-Start Verification          ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 1. Connessione
echo "${BLUE}[1/7]${NC} Connessione Mac Studio"
check "SSH Connection" "ssh -o ConnectTimeout=5 $REMOTE_HOST 'echo OK'" || {
    echo ""
    echo "${RED}ERRORE:${NC} Mac Studio non raggiungibile"
    echo "Verifica che sia acceso e sulla stessa rete"
    exit 1
}
echo ""

# 2. Script esistenti
echo "${BLUE}[2/7]${NC} Script Auto-Start"
check "auto-startup-macstudio.sh" "ssh $REMOTE_HOST '[ -f $REMOTE_PATH/auto-startup-macstudio.sh ]'"
check "auto-healing-macstudio.sh" "ssh $REMOTE_HOST '[ -f $REMOTE_PATH/auto-healing-macstudio.sh ]'"
check "startup-local.sh" "ssh $REMOTE_HOST '[ -f $REMOTE_PATH/startup-local.sh ]'" false
check "ecosystem.macstudio.config.cjs" "ssh $REMOTE_HOST '[ -f $REMOTE_PATH/ecosystem.macstudio.config.cjs ]'"
echo ""

# 3. Executable permissions
echo "${BLUE}[3/7]${NC} Permessi Esecuzione"
check "auto-startup executable" "ssh $REMOTE_HOST '[ -x $REMOTE_PATH/auto-startup-macstudio.sh ]'"
check "auto-healing executable" "ssh $REMOTE_HOST '[ -x $REMOTE_PATH/auto-healing-macstudio.sh ]'"
check "startup-local executable" "ssh $REMOTE_HOST '[ -x $REMOTE_PATH/startup-local.sh ]'" false
echo ""

# 4. Databases
echo "${BLUE}[4/7]${NC} Datastores"
check "PostgreSQL" "ssh $REMOTE_HOST 'PGPASSWORD=ewhpass psql -h localhost -U ewh -d ewh_master -c \"SELECT 1\" 2>&1 | grep -q \"1 row\"'"
check "Redis" "ssh $REMOTE_HOST 'redis-cli ping 2>&1 | grep -q PONG'"
echo ""

# 5. PM2
echo "${BLUE}[5/7]${NC} PM2 Setup"
check "PM2 installed" "ssh $REMOTE_HOST 'command -v pm2'"
check "PM2 running services" "ssh $REMOTE_HOST 'pm2 list | grep -q online'" false
echo ""

# 6. LaunchAgent
echo "${BLUE}[6/7]${NC} Auto-Start Configuration"
check "LaunchAgent file" "ssh $REMOTE_HOST '[ -f ~/Library/LaunchAgents/com.ewh.startup.plist ]'" false

if check "LaunchAgent loaded" "ssh $REMOTE_HOST 'launchctl list | grep -q com.ewh.startup'" false; then
    echo -e "    ${GREEN}→${NC} Auto-start all'accensione: ENABLED"
else
    echo -e "    ${YELLOW}→${NC} Auto-start all'accensione: DISABLED"
    echo "    Run: ./scripts/install-autostart-macstudio.sh"
fi
echo ""

# 7. Logs directory
echo "${BLUE}[7/7]${NC} Logging"
check "Logs directory" "ssh $REMOTE_HOST '[ -d $REMOTE_PATH/logs ]'"

# Count log files
LOG_COUNT=$(ssh $REMOTE_HOST "ls -1 $REMOTE_PATH/logs/*.log 2>/dev/null | wc -l" | tr -d ' ')
if [ "$LOG_COUNT" -gt 0 ]; then
    echo -e "    ${GREEN}→${NC} Found $LOG_COUNT log files"
else
    echo -e "    ${YELLOW}→${NC} No log files yet (normal on first run)"
fi
echo ""

# Summary
echo "╔════════════════════════════════════════╗"
echo "║  SUMMARY                               ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $PASS"
echo -e "  ${RED}Failed:${NC}  $FAIL"
echo -e "  ${YELLOW}Warning:${NC} $WARN"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ System ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Start system: ./scripts/master-startup-macstudio.sh"
    echo "  2. Check status: ssh $REMOTE_HOST 'pm2 list'"
    echo ""

    if [ $WARN -gt 0 ]; then
        echo "Optional improvements:"
        echo "  • Run: ./scripts/install-autostart-macstudio.sh"
        echo "    (enables auto-start on boot)"
    fi
else
    echo -e "${RED}✗ Setup incomplete${NC}"
    echo ""
    echo "To fix issues:"
    echo "  1. Ensure Mac Studio is on and accessible"
    echo "  2. Run: ./scripts/master-startup-macstudio.sh"
    echo "  3. For auto-start: ./scripts/install-autostart-macstudio.sh"
fi

echo ""
exit $FAIL
