#!/bin/bash
# EWH Health Check Script
# Checks the health of all running services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   EWH Services Health Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check HTTP endpoint
check_http() {
    local name=$1
    local url=$2
    local timeout=${3:-2}

    if curl -s -f --max-time $timeout "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name - ${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} $name - ${RED}DOWN${NC}"
        return 1
    fi
}

# Function to check TCP port
check_port() {
    local name=$1
    local host=$2
    local port=$3

    if nc -z -w 2 $host $port 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $name - ${GREEN}LISTENING${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} $name - ${RED}NOT LISTENING${NC}"
        return 1
    fi
}

# Check infrastructure services
echo -e "${BLUE}Infrastructure Services:${NC}"
check_port "PostgreSQL" "localhost" "5432"
check_port "Redis" "localhost" "6379"
check_port "MinIO" "localhost" "9000"
echo ""

# Check frontend apps
echo -e "${BLUE}Frontend Applications:${NC}"
check_http "Web Frontend (3100)" "http://localhost:3100" 3
check_http "Admin Frontend (3200)" "http://localhost:3200" 3
echo ""

# Check core services
echo -e "${BLUE}Core Services:${NC}"
check_http "API Gateway (4000)" "http://localhost:4000/health" 2
check_http "Auth Service (4001)" "http://localhost:4001/health" 2
check_port "Plugins Service (4002)" "localhost" "4002"
check_port "Media Service (4003)" "localhost" "4003"
check_port "Billing Service (4004)" "localhost" "4004"
echo ""

# Check monitoring
echo -e "${BLUE}Monitoring Services:${NC}"
check_http "Metrics Collector (4010)" "http://localhost:4010/health" 2
echo ""

# Check creative services (4100-4110)
echo -e "${BLUE}Creative Services:${NC}"
check_port "Image Orchestrator (4100)" "localhost" "4100"
check_port "Job Worker (4101)" "localhost" "4101"
check_port "Writer (4102)" "localhost" "4102"
check_port "Content (4103)" "localhost" "4103"
check_port "Layout (4104)" "localhost" "4104"
check_port "Prepress (4105)" "localhost" "4105"
check_port "Vector Lab (4106)" "localhost" "4106"
check_port "Mockup (4107)" "localhost" "4107"
check_port "Video Orchestrator (4108)" "localhost" "4108"
check_port "Video Runtime (4109)" "localhost" "4109"
check_port "Raster Runtime (4110)" "localhost" "4110"
echo ""

# Check publishing services (4200-4205)
echo -e "${BLUE}Publishing Services:${NC}"
check_port "Projects (4200)" "localhost" "4200"
check_port "Search (4201)" "localhost" "4201"
check_port "Site Builder (4202)" "localhost" "4202"
check_port "Site Renderer (4203)" "localhost" "4203"
check_port "Site Publisher (4204)" "localhost" "4204"
check_port "Connectors Web (4205)" "localhost" "4205"
echo ""

# Check ERP services (4300-4308)
echo -e "${BLUE}ERP Services:${NC}"
check_port "Products (4300)" "localhost" "4300"
check_port "Orders (4301)" "localhost" "4301"
check_port "Inventory (4302)" "localhost" "4302"
check_port "Channels (4303)" "localhost" "4303"
check_port "Quotation (4304)" "localhost" "4304"
check_port "Procurement (4305)" "localhost" "4305"
check_port "MRP (4306)" "localhost" "4306"
check_port "Shipping (4307)" "localhost" "4307"
check_port "CRM (4308)" "localhost" "4308"
echo ""

# Check collaboration services (4400-4410)
echo -e "${BLUE}Collaboration Services:${NC}"
check_port "Project Management (4400)" "localhost" "4400"
check_port "Support (4401)" "localhost" "4401"
check_port "Chat (4402)" "localhost" "4402"
check_port "Boards (4403)" "localhost" "4403"
check_port "Knowledge Base (4404)" "localhost" "4404"
check_port "Collab (4405)" "localhost" "4405"
check_port "DMS (4406)" "localhost" "4406"
check_port "Timesheet (4407)" "localhost" "4407"
check_port "Forms (4408)" "localhost" "4408"
check_port "Forum (4409)" "localhost" "4409"
check_port "Assistant (4410)" "localhost" "4410"
echo ""

# Check platform services (4500-4502)
echo -e "${BLUE}Platform Services:${NC}"
check_port "Communication (4500)" "localhost" "4500"
check_port "Enrichment (4501)" "localhost" "4501"
check_port "BI (4502)" "localhost" "4502"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Health check completed!${NC}"
echo -e "${BLUE}========================================${NC}"
