#!/bin/bash

# 🏥 EWH Auto-Healing System per Mac Studio
# Monitora e riavvia automaticamente servizi morti
#
# Features:
# - Health check continuo
# - Auto-restart servizi morti
# - Notifiche problemi
# - Metriche uptime

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"
CHECK_INTERVAL=30  # secondi tra ogni check
LOG_FILE="/tmp/ewh-autohealing-$(date +%Y%m%d).log"

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Definizione servizi da monitorare
declare -A SERVICES=(
    ["svc-auth"]="4001"
    ["svc-api-gateway"]="4000"
    ["svc-media"]="4003"
    ["svc-pm"]="5500"
)

# Check singolo servizio
check_service() {
    local name=$1
    local port=$2

    # Check se processo PM2 è running
    if ! ssh $REMOTE_HOST "export PATH=/usr/local/bin:\$PATH && pm2 describe $name 2>/dev/null | grep -q 'status.*online'"; then
        echo "PM2_DOWN"
        return 1
    fi

    # Check se porta risponde
    if ! ssh $REMOTE_HOST "curl -s --max-time 5 http://localhost:$port/health >/dev/null 2>&1 || curl -s --max-time 5 http://localhost:$port >/dev/null 2>&1"; then
        echo "PORT_DOWN"
        return 2
    fi

    echo "OK"
    return 0
}

# Riavvia servizio
restart_service() {
    local name=$1

    log "${YELLOW}⚠${NC} Riavvio $name..."

    if ssh $REMOTE_HOST "export PATH=/usr/local/bin:\$PATH && pm2 restart $name" 2>&1 | tee -a "$LOG_FILE"; then
        # Aspetta che sia pronto
        sleep 5

        local port=${SERVICES[$name]}
        local status=$(check_service "$name" "$port")

        if [ "$status" = "OK" ]; then
            log "${GREEN}✓${NC} $name riavviato con successo"
            # Notifica macOS
            osascript -e "display notification \"$name riavviato\" with title \"EWH Auto-Healing\"" 2>/dev/null || true
            return 0
        else
            log "${RED}✗${NC} $name ancora down dopo restart"
            return 1
        fi
    else
        log "${RED}✗${NC} Errore riavvio $name"
        return 1
    fi
}

# Main monitoring loop
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  EWH Auto-Healing Monitor             ║"
    echo "║  Mac Studio Edition                    ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    log "${BLUE}ℹ${NC} Avvio monitoring... (intervallo: ${CHECK_INTERVAL}s)"
    log "${BLUE}ℹ${NC} Log file: $LOG_FILE"
    echo ""

    # Contatori
    declare -A restart_count
    declare -A last_restart
    local check_count=0

    while true; do
        check_count=$((check_count + 1))

        # Header ogni 10 check
        if [ $((check_count % 10)) -eq 1 ]; then
            echo ""
            log "${BLUE}═══${NC} Health Check #$check_count"
        fi

        local all_ok=true
        local status_line=""

        for service in "${!SERVICES[@]}"; do
            port=${SERVICES[$service]}
            status=$(check_service "$service" "$port")

            if [ "$status" = "OK" ]; then
                status_line+="${GREEN}●${NC} $service  "
            else
                all_ok=false
                status_line+="${RED}●${NC} $service  "

                # Incrementa contatore restart
                restart_count[$service]=$((${restart_count[$service]:-0} + 1))
                now=$(date +%s)
                last_restart_time=${last_restart[$service]:-0}
                time_since_last=$((now - last_restart_time))

                # Non riavviare se già riavviato negli ultimi 60 secondi
                if [ $time_since_last -gt 60 ]; then
                    log "${RED}✗${NC} $service DOWN (status: $status, restarts: ${restart_count[$service]})"

                    # Max 5 restart per servizio
                    if [ ${restart_count[$service]} -le 5 ]; then
                        restart_service "$service"
                        last_restart[$service]=$(date +%s)
                    else
                        log "${RED}✗${NC} $service raggiunto max restart (5), skip auto-restart"
                        # Notifica problema critico
                        osascript -e "display notification \"$service ha fallito troppi restart!\" with title \"EWH Auto-Healing\" sound name \"Basso\"" 2>/dev/null || true
                    fi
                else
                    log "${YELLOW}⚠${NC} $service DOWN ma riavviato di recente (${time_since_last}s fa), skip"
                fi
            fi
        done

        # Mostra status compatto
        if [ $((check_count % 10)) -eq 1 ] || [ "$all_ok" = false ]; then
            echo -e "   $status_line"
        fi

        # Reset contatori se tutto ok per 5 minuti
        if [ "$all_ok" = true ] && [ $((check_count % 10)) -eq 0 ]; then
            for service in "${!SERVICES[@]}"; do
                restart_count[$service]=0
            done
        fi

        sleep $CHECK_INTERVAL
    done
}

# Gestione segnali
trap 'echo ""; log "${BLUE}ℹ${NC} Auto-Healing fermato"; exit 0' SIGINT SIGTERM

# Run
main "$@"
