#!/bin/bash
# Stable EWH Startup Script
# Starts services in waves with health checks between each wave

set -e

COMPOSE_FILE="/Users/andromeda/dev/ewh/compose/docker-compose.dev.yml"
PROJECT_NAME="ewh"

echo "🚀 Starting EWH Development Environment (Stable Mode)"
echo "=================================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a service is healthy
check_health() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=0

    echo -n "Waiting for $service on port $port... "

    while [ $attempt -lt $max_attempts ]; do
        if curl -s --max-time 2 "http://localhost:$port/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done

    echo -e "${RED}✗ (timeout)${NC}"
    return 1
}

# Function to check database health
check_db() {
    echo -n "Checking PostgreSQL... "
    if docker exec ewh_postgres pg_isready -U ewh -d ewh_master > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Function to start services
start_services() {
    local services="$@"
    echo -e "\n${YELLOW}Starting:${NC} $services"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d $services
}

# Function to restart crashed services
restart_crashed() {
    echo -e "\n${YELLOW}Checking for crashed services...${NC}"

    # Get list of all service containers
    local services=$(docker ps --format "{{.Names}}" | grep -E "^(svc_|app_)" || true)

    for service in $services; do
        # Check if main node process is running
        local node_count=$(docker exec "$service" sh -c 'ps aux | grep -v grep | grep "node.*src/index" | wc -l' 2>/dev/null || echo "0")

        if [ "$node_count" -eq "0" ]; then
            echo -e "${YELLOW}↻${NC} Restarting crashed service: $service"
            docker restart "$service" > /dev/null 2>&1 &
        fi
    done

    # Wait for background restarts
    wait
    sleep 3
}

# Step 1: Infrastructure (Databases, Cache, Storage)
echo -e "\n${YELLOW}━━━ Wave 1: Infrastructure ━━━${NC}"
start_services postgres redis minio

echo "Waiting for infrastructure to be ready..."
sleep 5

if ! check_db; then
    echo -e "${RED}Failed to start PostgreSQL!${NC}"
    exit 1
fi

# Step 2: Core Services (Auth, API Gateway)
echo -e "\n${YELLOW}━━━ Wave 2: Core Services ━━━${NC}"
start_services svc-auth svc-api-gateway svc-metrics-collector

sleep 10
check_health "svc-auth" 4001 || true
check_health "svc-api-gateway" 4000 || true

# Step 3: Admin Frontend
echo -e "\n${YELLOW}━━━ Wave 3: Admin Panel ━━━${NC}"
start_services app-admin-frontend

sleep 5

# Step 4: All Microservices
echo -e "\n${YELLOW}━━━ Wave 4: All Microservices ━━━${NC}"
start_services \
    svc-billing svc-crm svc-content svc-products svc-orders \
    svc-inventory svc-shipping svc-quotation svc-projects \
    svc-pm svc-timesheet svc-chat svc-channels svc-collab \
    svc-boards svc-kb svc-forms svc-forum svc-support \
    svc-media svc-dms svc-search svc-enrichment \
    svc-connectors-web svc-comm svc-bi svc-job-worker \
    svc-layout svc-site-builder svc-site-renderer svc-site-publisher \
    svc-mockup svc-prepress svc-writer \
    svc-image-orchestrator svc-video-orchestrator \
    svc-raster-runtime svc-video-runtime svc-vector-lab \
    svc-plugins svc-assistant svc-procurement svc-mrp

echo "Waiting for microservices to initialize..."
sleep 15

# Step 5: Restart any crashed services
restart_crashed

# Step 6: n8n (optional workflow engine)
echo -e "\n${YELLOW}━━━ Wave 5: n8n Workflow Engine ━━━${NC}"
start_services svc-n8n

# Final status
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ EWH Development Environment Started${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n📊 Service URLs:"
echo "  • Admin Panel:     http://localhost:3200"
echo "  • Web Frontend:    http://localhost:3100"
echo "  • API Gateway:     http://localhost:4000"
echo "  • Auth Service:    http://localhost:4001"
echo "  • PostgreSQL:      localhost:5432 (ewh/ewhpass)"
echo "  • n8n:             http://localhost:5678"

echo -e "\n🔧 Useful Commands:"
echo "  • Check status:    docker ps"
echo "  • View logs:       docker logs -f [container_name]"
echo "  • Restart service: docker restart [container_name]"
echo "  • Stop all:        docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down"

echo -e "\n💡 Run './scripts/health-check.sh' to verify all services"
