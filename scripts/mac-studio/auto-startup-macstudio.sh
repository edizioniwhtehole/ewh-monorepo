#!/bin/bash

# 🚀 EWH Auto-Startup System per Mac Studio
# Sistema intelligente di avvio con health check e auto-healing
#
# Features:
# - Health check pre-startup
# - Retry automatico con backoff
# - Avvio sequenziale dipendenze
# - Auto-healing processi morti
# - Logging centralizzato

set -e

REMOTE_HOST="fabio@192.168.1.47"
REMOTE_PATH="/Users/fabio/dev/ewh"
LOG_FILE="/tmp/ewh-startup-$(date +%Y%m%d-%H%M%S).log"

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

# Health check per Postgres
check_postgres() {
    log_info "Verifico PostgreSQL..."
    if ssh $REMOTE_HOST "PGPASSWORD=ewhpass psql -h localhost -U ewh -d ewh_master -c 'SELECT 1' >/dev/null 2>&1"; then
        log_success "PostgreSQL: RUNNING"
        return 0
    else
        log_error "PostgreSQL: NOT RUNNING"
        return 1
    fi
}

# Health check per Redis
check_redis() {
    log_info "Verifico Redis..."
    if ssh $REMOTE_HOST "redis-cli ping >/dev/null 2>&1"; then
        log_success "Redis: RUNNING"
        return 0
    else
        log_error "Redis: NOT RUNNING"
        return 1
    fi
}

# Avvia Postgres se necessario
start_postgres() {
    log_info "Avvio PostgreSQL..."
    ssh $REMOTE_HOST "brew services start postgresql@16" 2>&1 | tee -a "$LOG_FILE"

    # Retry con backoff
    for i in {1..10}; do
        sleep 2
        if check_postgres; then
            return 0
        fi
        log_warning "PostgreSQL non pronto, retry $i/10..."
    done

    log_error "PostgreSQL non avviato dopo 10 tentativi"
    return 1
}

# Avvia Redis se necessario
start_redis() {
    log_info "Avvio Redis..."
    ssh $REMOTE_HOST "brew services start redis" 2>&1 | tee -a "$LOG_FILE"

    # Retry con backoff
    for i in {1..10}; do
        sleep 1
        if check_redis; then
            return 0
        fi
        log_warning "Redis non pronto, retry $i/10..."
    done

    log_error "Redis non avviato dopo 10 tentativi"
    return 1
}

# Health check per un servizio PM2
check_service_health() {
    local service_name=$1
    local port=$2
    local max_retries=${3:-30}

    log_info "Health check $service_name su porta $port..."

    for i in $(seq 1 $max_retries); do
        if ssh $REMOTE_HOST "curl -s http://localhost:$port/health >/dev/null 2>&1 || curl -s http://localhost:$port >/dev/null 2>&1"; then
            log_success "$service_name: HEALTHY (${i}s)"
            return 0
        fi

        if [ $((i % 5)) -eq 0 ]; then
            log_warning "$service_name: waiting ${i}/${max_retries}s..."
        fi
        sleep 1
    done

    log_error "$service_name: TIMEOUT dopo ${max_retries}s"
    return 1
}

# Avvia servizio con retry
start_service_with_retry() {
    local service_name=$1
    local service_path=$2
    local start_cmd=$3
    local port=$4
    local max_attempts=${5:-3}

    log_info "Avvio $service_name..."

    for attempt in $(seq 1 $max_attempts); do
        # Ferma servizio se esiste
        ssh $REMOTE_HOST "export PATH=/usr/local/bin:\$PATH && pm2 delete $service_name 2>/dev/null || true"

        # Avvia servizio
        if ssh $REMOTE_HOST "cd $REMOTE_PATH/$service_path && export PATH=/usr/local/bin:\$PATH && $start_cmd" 2>&1 | tee -a "$LOG_FILE"; then

            # Verifica health
            sleep 3
            if check_service_health "$service_name" "$port" 30; then
                log_success "$service_name: STARTED (attempt $attempt/$max_attempts)"
                return 0
            fi
        fi

        log_warning "$service_name: tentativo $attempt/$max_attempts fallito, riprovo..."
        sleep 2
    done

    log_error "$service_name: FAILED dopo $max_attempts tentativi"
    return 1
}

# Main startup sequence
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  EWH Auto-Startup System              ║"
    echo "║  Mac Studio Edition                    ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    log_info "Log file: $LOG_FILE"
    echo ""

    # 1. Verifica connessione
    log_info "STEP 1/5: Verifica connessione Mac Studio..."
    if ! ssh -o ConnectTimeout=5 $REMOTE_HOST "echo 'OK'" &>/dev/null; then
        log_error "Mac Studio non raggiungibile!"
        echo ""
        echo "Verifica:"
        echo "  1. Mac Studio acceso"
        echo "  2. Stessa rete WiFi"
        echo "  3. Remote Login abilitato"
        exit 1
    fi
    log_success "Connessione OK"
    echo ""

    # 2. Avvia datastores
    log_info "STEP 2/5: Avvio datastores..."

    if ! check_postgres; then
        if ! start_postgres; then
            log_error "Impossibile avviare PostgreSQL"
            exit 1
        fi
    fi

    if ! check_redis; then
        if ! start_redis; then
            log_error "Impossibile avviare Redis"
            exit 1
        fi
    fi

    log_success "Datastores pronti"
    echo ""

    # 3. Installa dipendenze se necessario
    log_info "STEP 3/5: Verifica dipendenze..."

    # Array servizi core
    declare -a CORE_SERVICES=(
        "svc-auth"
        "svc-api-gateway"
        "svc-media"
        "svc-pm"
    )

    for service in "${CORE_SERVICES[@]}"; do
        if ! ssh $REMOTE_HOST "[ -d $REMOTE_PATH/$service/node_modules ]"; then
            log_warning "$service: node_modules mancante, installo dipendenze..."
            ssh $REMOTE_HOST "cd $REMOTE_PATH/$service && npm install" 2>&1 | tee -a "$LOG_FILE"
        fi
    done

    log_success "Dipendenze verificate"
    echo ""

    # 4. Avvia servizi core in sequenza
    log_info "STEP 4/5: Avvio servizi core..."

    # Ferma tutti i servizi PM2 esistenti
    log_info "Pulizia processi esistenti..."
    ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 delete all 2>/dev/null || true'
    sleep 2

    # Configura PM2 con PATH corretto
    log_info "Configurazione PM2 environment..."
    ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 set pm2:env-path /usr/local/bin:$PATH'

    # Auth service (dipendenza di tutti)
    start_service_with_retry "svc-auth" "svc-auth" \
        "pm2 start npm --name svc-auth -- run dev" \
        "4001" 3 || exit 1

    # Media service
    start_service_with_retry "svc-media" "svc-media" \
        "pm2 start npm --name svc-media -- run dev" \
        "4003" 3 || exit 1

    # API Gateway (dipende da auth)
    start_service_with_retry "svc-api-gateway" "svc-api-gateway" \
        "pm2 start npm --name svc-api-gateway -- run dev" \
        "4000" 3 || exit 1

    # PM Service
    start_service_with_retry "svc-pm" "svc-pm" \
        "pm2 start npx --name svc-pm -- tsx watch src/index.ts" \
        "5500" 3 || exit 1

    # Salva configurazione PM2
    ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 save'

    log_success "Servizi core avviati"
    echo ""

    # 5. Avvia frontend apps
    log_info "STEP 5/5: Avvio frontend apps..."

    # Admin Frontend
    if ssh $REMOTE_HOST "[ -d $REMOTE_PATH/app-admin-frontend ]"; then
        start_service_with_retry "app-admin-frontend" "app-admin-frontend" \
            "pm2 start npm --name app-admin-frontend -- run dev" \
            "3200" 2 || log_warning "app-admin-frontend fallito (non bloccante)"
    fi

    # PM Frontend
    if ssh $REMOTE_HOST "[ -d $REMOTE_PATH/app-pm-frontend ]"; then
        start_service_with_retry "app-pm-frontend" "app-pm-frontend" \
            "pm2 start npm --name app-pm-frontend -- run dev" \
            "3300" 2 || log_warning "app-pm-frontend fallito (non bloccante)"
    fi

    # DAM
    if ssh $REMOTE_HOST "[ -d $REMOTE_PATH/app-dam ]"; then
        start_service_with_retry "app-dam" "app-dam" \
            "pm2 start npm --name app-dam -- run dev" \
            "3400" 2 || log_warning "app-dam fallito (non bloccante)"
    fi

    # CMS Frontend
    if ssh $REMOTE_HOST "[ -d $REMOTE_PATH/app-cms-frontend ]"; then
        start_service_with_retry "app-cms-frontend" "app-cms-frontend" \
            "pm2 start npm --name app-cms-frontend -- run dev" \
            "3600" 2 || log_warning "app-cms-frontend fallito (non bloccante)"
    fi

    # Media Frontend
    if ssh $REMOTE_HOST "[ -d $REMOTE_PATH/app-media-frontend ]"; then
        start_service_with_retry "app-media-frontend" "app-media-frontend" \
            "pm2 start npm --name app-media-frontend -- run dev" \
            "3700" 2 || log_warning "app-media-frontend fallito (non bloccante)"
    fi

    # Box Designer
    if ssh $REMOTE_HOST "[ -d $REMOTE_PATH/app-box-designer ]"; then
        start_service_with_retry "app-box-designer" "app-box-designer" \
            "pm2 start npm --name app-box-designer -- run dev" \
            "3350" 2 || log_warning "app-box-designer fallito (non bloccante)"
    fi

    log_success "Frontend apps avviati"
    echo ""

    # 6. Status finale
    echo "╔════════════════════════════════════════╗"
    echo "║  STARTUP COMPLETATO                    ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    log_info "Status servizi PM2:"
    ssh $REMOTE_HOST 'export PATH=/usr/local/bin:$PATH && pm2 list'

    echo ""
    log_success "Sistema pronto!"
    echo ""
    echo "🌐 Endpoints disponibili:"
    echo "   http://localhost:4000  - API Gateway"
    echo "   http://localhost:4001  - Auth Service"
    echo "   http://localhost:4003  - Media Service"
    echo "   http://localhost:5500  - PM Service"
    echo "   http://localhost:3200  - Admin Frontend"
    echo "   http://localhost:3300  - PM Frontend"
    echo "   http://localhost:3400  - DAM"
    echo "   http://localhost:3600  - CMS Frontend"
    echo "   http://localhost:3700  - Media Frontend"
    echo "   http://localhost:3350  - Box Designer"
    echo ""
    echo "📊 Comandi utili:"
    echo "   ssh $REMOTE_HOST 'pm2 list'           - Status servizi"
    echo "   ssh $REMOTE_HOST 'pm2 logs'           - Logs tutti servizi"
    echo "   ssh $REMOTE_HOST 'pm2 logs svc-auth'  - Logs servizio specifico"
    echo "   ssh $REMOTE_HOST 'pm2 restart all'    - Restart tutti"
    echo ""
    echo "📝 Log completo: $LOG_FILE"
    echo ""
}

# Run main
main "$@"
