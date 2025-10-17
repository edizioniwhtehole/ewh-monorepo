#!/bin/bash

# Audit and Create All Backend Services
# For each frontend, ensure backend exists and works

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 Backend Services Audit & Setup${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""

TEMPLATE_DIR="/Users/andromeda/dev/ewh/templates/express-health-service"

# Function to create backend service
create_backend() {
    local service_name=$1
    local port=$2
    local display_name=$3

    if [ -d "$service_name" ] && [ -f "$service_name/package.json" ]; then
        echo -e "${GREEN}✓${NC} $service_name already exists"
        return 0
    fi

    echo -e "${YELLOW}📦 Creating $service_name...${NC}"

    mkdir -p "$service_name/src"

    # Copy and customize package.json
    cat "$TEMPLATE_DIR/package.json" | \
        sed "s/SERVICE_NAME/$service_name/g" | \
        sed "s/PORT_NUMBER/$port/g" > "$service_name/package.json"

    # Copy source files
    cat "$TEMPLATE_DIR/src/index.ts" | \
        sed "s/SERVICE_NAME/$service_name/g" | \
        sed "s/SERVICE_DISPLAY_NAME/$display_name/g" | \
        sed "s/PORT_NUMBER/$port/g" > "$service_name/src/index.ts"

    # Copy config files
    cp "$TEMPLATE_DIR/tsconfig.json" "$service_name/"

    cat "$TEMPLATE_DIR/.env.example" | \
        sed "s/PORT_NUMBER/$port/g" > "$service_name/.env"

    echo -e "${GREEN}✅ $service_name created${NC}"
}

# Frontend -> Backend mapping
declare -A BACKENDS=(
    # Core services
    ["svc-pm"]="5401:Project Management Service"
    ["svc-media"]="5201:Media Service"
    ["svc-approvals"]="5501:Approvals Service"
    ["svc-previz"]="5800:Pre-visualization Service"

    # Design services
    ["svc-box-designer"]="3351:Box Designer Service"
    ["svc-photo-editor"]="5851:Photo Editor Service"
    ["svc-raster-runtime"]="5861:Raster Service"
    ["svc-video-orchestrator"]="5871:Video Orchestrator"
    ["svc-video-runtime"]="5872:Video Runtime"
    ["svc-layout"]="5331:Layout Service"

    # Content services
    ["svc-cms"]="5311:CMS Service"
    ["svc-site-builder"]="5321:Site Builder Service"
    ["svc-page-builder"]="5102:Page Builder Service"

    # Business services
    ["svc-inventory"]="5701:Inventory Service"
    ["svc-procurement"]="5751:Procurement Service"
    ["svc-orders-purchase"]="5901:Purchase Orders Service"
    ["svc-orders-sales"]="6001:Sales Orders Service"
    ["svc-quotations"]="6101:Quotations Service"

    # Communications
    ["svc-communications"]="5641:Communications Service"
    ["svc-voice"]="5642:Voice Service"
    ["svc-crm-unified"]="3311:CRM Service"

    # Workflow
    ["svc-workflow-tracker"]="5881:Workflow Tracker"
    ["svc-bi"]="5886:Business Intelligence Service"
    ["svc-api-orchestrator"]="5891:API Orchestrator"
)

echo -e "${BLUE}📋 Checking/Creating Backend Services...${NC}"
echo ""

for service in "${!BACKENDS[@]}"; do
    IFS=':' read -r port display_name <<< "${BACKENDS[$service]}"
    create_backend "$service" "$port" "$display_name"
done

echo ""
echo -e "${GREEN}✅ Backend audit complete!${NC}"
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo "Total backends checked: ${#BACKENDS[@]}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Install dependencies: ${GREEN}./scripts/install-all-backend-deps.sh${NC}"
echo "2. Start all backends: ${GREEN}./scripts/start-all-backends.sh${NC}"
echo ""
