#!/bin/bash
# Health Check Script - Verifies all EWH services are running correctly

echo "🏥 EWH System Health Check"
echo "=========================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

total=0
healthy=0
unhealthy=0

# Function to check HTTP health
check_http() {
    local name=$1
    local url=$2
    local timeout=${3:-2}

    total=$((total + 1))

    if response=$(curl -s --max-time "$timeout" "$url" 2>&1); then
        if echo "$response" | grep -q '"status":"healthy"'; then
            echo -e "  ${GREEN}✓${NC} $name - healthy"
            healthy=$((healthy + 1))
            return 0
        else
            echo -e "  ${YELLOW}⚠${NC} $name - responding but not healthy"
            echo "    Response: $(echo $response | head -c 80)"
            unhealthy=$((unhealthy + 1))
            return 1
        fi
    else
        echo -e "  ${RED}✗${NC} $name - not responding"
        unhealthy=$((unhealthy + 1))
        return 1
    fi
}

# Infrastructure
echo -e "\n📦 Infrastructure:"
total=$((total + 1))
if docker exec ewh_postgres pg_isready -U ewh -d ewh_master > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} PostgreSQL - ready"
    healthy=$((healthy + 1))
else
    echo -e "  ${RED}✗${NC} PostgreSQL - not ready"
    unhealthy=$((unhealthy + 1))
fi

total=$((total + 1))
if docker exec ewh_redis redis-cli ping > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Redis - ready"
    healthy=$((healthy + 1))
else
    echo -e "  ${RED}✗${NC} Redis - not ready"
    unhealthy=$((unhealthy + 1))
fi

# Core Services
echo -e "\n🔐 Core Services:"
check_http "Auth Service" "http://localhost:4001/health"
check_http "API Gateway" "http://localhost:4000/health"

# Admin & Web
echo -e "\n💻 Frontend Applications:"
total=$((total + 1))
if curl -s --max-time 2 http://localhost:3200 > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Admin Frontend - accessible"
    healthy=$((healthy + 1))
else
    echo -e "  ${RED}✗${NC} Admin Frontend - not accessible"
    unhealthy=$((unhealthy + 1))
fi

# Sample Microservices (check a few representative ones)
echo -e "\n🔧 Sample Microservices:"
check_http "Billing" "http://localhost:4004/health"
check_http "CRM" "http://localhost:4005/health"
check_http "Products" "http://localhost:4007/health"
check_http "Content" "http://localhost:4006/health"

# Container Status
echo -e "\n🐳 Container Status:"
running=$(docker ps --format "{{.Names}}" | grep -E "^(svc_|app_|ewh_)" | wc -l)
echo "  Running containers: $running"

# Check for crashed processes
crashed=0
services=$(docker ps --format "{{.Names}}" | grep -E "^svc_" || true)
for service in $services; do
    node_count=$(docker exec "$service" sh -c 'ps aux | grep -v grep | grep "node.*src/index" | wc -l' 2>/dev/null || echo "0")
    if [ "$node_count" -eq "0" ]; then
        if [ $crashed -eq 0 ]; then
            echo -e "\n  ${RED}⚠ Crashed Services:${NC}"
        fi
        echo "    - $service (Node.js process not running)"
        crashed=$((crashed + 1))
    fi
done

if [ $crashed -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} No crashed processes detected"
fi

# Summary
echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📊 Summary:"
echo "  Total checks: $total"
echo -e "  ${GREEN}Healthy: $healthy${NC}"
echo -e "  ${RED}Unhealthy: $unhealthy${NC}"

percentage=$((healthy * 100 / total))
echo "  Health: $percentage%"

if [ $crashed -gt 0 ]; then
    echo -e "\n💡 Tip: Restart crashed services with:"
    echo "  docker restart [service_name]"
fi

if [ $percentage -eq 100 ]; then
    echo -e "\n${GREEN}✓ System is fully operational!${NC}"
    exit 0
elif [ $percentage -ge 80 ]; then
    echo -e "\n${YELLOW}⚠ System is mostly operational${NC}"
    exit 0
else
    echo -e "\n${RED}✗ System has significant issues${NC}"
    exit 1
fi
