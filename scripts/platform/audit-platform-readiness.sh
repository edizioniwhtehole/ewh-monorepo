#!/bin/bash

# Platform Readiness Audit Script
# Checks all apps and services for production readiness

set -e

echo "🔍 EWH Platform Readiness Audit"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_APPS=0
READY_APPS=0
MISSING_APPS=0
TOTAL_SERVICES=0
READY_SERVICES=0
MISSING_SERVICES=0

# Report file
REPORT_FILE="PLATFORM_AUDIT_REPORT.md"
echo "# Platform Readiness Audit Report" > "$REPORT_FILE"
echo "Generated: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

check_frontend_app() {
    local app=$1
    local port=$2
    TOTAL_APPS=$((TOTAL_APPS + 1))

    echo -n "📱 Checking $app (port $port)... "

    if [ ! -d "$app" ]; then
        echo -e "${RED}❌ Directory not found${NC}"
        echo "- ❌ $app: Directory not found (port $port)" >> "$REPORT_FILE"
        MISSING_APPS=$((MISSING_APPS + 1))
        return
    fi

    cd "$app"

    # Check package.json
    if [ ! -f "package.json" ]; then
        echo -e "${RED}❌ No package.json${NC}"
        echo "- ❌ $app: No package.json (port $port)" >> "$REPORT_FILE"
        cd ..
        MISSING_APPS=$((MISSING_APPS + 1))
        return
    fi

    # Check node_modules
    local has_deps="✓"
    if [ ! -d "node_modules" ]; then
        has_deps="⚠"
    fi

    # Check for auth integration (simplified - checks for common auth patterns)
    local has_auth="?"
    if grep -rq "auth\|Auth\|TOKEN\|token" src/ 2>/dev/null; then
        has_auth="✓"
    else
        has_auth="⚠"
    fi

    echo -e "${GREEN}✓${NC} deps:$has_deps auth:$has_auth"
    echo "- ✅ $app: deps=$has_deps, auth=$has_auth (port $port)" >> "$REPORT_FILE"
    READY_APPS=$((READY_APPS + 1))

    cd ..
}

check_backend_service() {
    local service=$1
    local port=$2
    TOTAL_SERVICES=$((TOTAL_SERVICES + 1))

    echo -n "⚙️  Checking $service (port $port)... "

    if [ ! -d "$service" ]; then
        echo -e "${RED}❌ Directory not found${NC}"
        echo "- ❌ $service: Directory not found (port $port)" >> "$REPORT_FILE"
        MISSING_SERVICES=$((MISSING_SERVICES + 1))
        return
    fi

    cd "$service"

    # Check package.json
    if [ ! -f "package.json" ]; then
        echo -e "${RED}❌ No package.json${NC}"
        echo "- ❌ $service: No package.json (port $port)" >> "$REPORT_FILE"
        cd ..
        MISSING_SERVICES=$((MISSING_SERVICES + 1))
        return
    fi

    # Check node_modules
    local has_deps="✓"
    if [ ! -d "node_modules" ]; then
        has_deps="⚠"
    fi

    # Check for health endpoint
    local has_health="?"
    if grep -rq "health\|/health\|healthCheck" src/ 2>/dev/null || grep -rq "health" *.ts *.js 2>/dev/null; then
        has_health="✓"
    else
        has_health="⚠"
    fi

    # Check for auth middleware
    local has_auth="?"
    if grep -rq "auth\|Auth\|JWT\|jwt\|authenticate" src/ 2>/dev/null; then
        has_auth="✓"
    else
        has_auth="⚠"
    fi

    echo -e "${GREEN}✓${NC} deps:$has_deps health:$has_health auth:$has_auth"
    echo "- ✅ $service: deps=$has_deps, health=$has_health, auth=$has_auth (port $port)" >> "$REPORT_FILE"
    READY_SERVICES=$((READY_SERVICES + 1))

    cd ..
}

echo "## Frontend Apps" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Check major frontend apps (based on services.config.ts)
check_frontend_app "app-shell-frontend" "3150"
check_frontend_app "app-admin-frontend" "3600"
check_frontend_app "app-pm-frontend" "5400"
check_frontend_app "app-dam" "3300"
check_frontend_app "app-approvals-frontend" "5500"
check_frontend_app "app-previz-frontend" "5801"
check_frontend_app "app-box-designer" "3350"
check_frontend_app "app-communications-client" "5640"
check_frontend_app "app-inventory-frontend" "5700"
check_frontend_app "app-procurement-frontend" "5800"
check_frontend_app "app-orders-purchase-frontend" "5900"
check_frontend_app "app-orders-sales-frontend" "6000"
check_frontend_app "app-quotations-frontend" "6100"

echo ""
echo "## Backend Services" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Check major backend services
check_backend_service "svc-auth" "4001"
check_backend_service "svc-pm" "5401"
check_backend_service "svc-media" "5201"
check_backend_service "svc-approvals" "5501"
check_backend_service "svc-previz" "5800"
check_backend_service "svc-inventory" "5701"
check_backend_service "svc-procurement" "5801"
check_backend_service "svc-orders-purchase" "5901"
check_backend_service "svc-orders-sales" "6001"
check_backend_service "svc-quotations" "6101"
check_backend_service "svc-communications" "5641"
check_backend_service "svc-voice" "5642"
check_backend_service "svc-crm-unified" "3311"

echo ""
echo "================================"
echo "📊 Summary"
echo "================================"
echo "Frontend Apps: $READY_APPS/$TOTAL_APPS ready"
echo "Backend Services: $READY_SERVICES/$TOTAL_SERVICES ready"
echo "Missing: $MISSING_APPS apps, $MISSING_SERVICES services"
echo ""
echo "Full report saved to: $REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "## Summary" >> "$REPORT_FILE"
echo "- Frontend Apps: $READY_APPS/$TOTAL_APPS ready" >> "$REPORT_FILE"
echo "- Backend Services: $READY_SERVICES/$TOTAL_SERVICES ready" >> "$REPORT_FILE"
echo "- Missing: $MISSING_APPS apps, $MISSING_SERVICES services" >> "$REPORT_FILE"
