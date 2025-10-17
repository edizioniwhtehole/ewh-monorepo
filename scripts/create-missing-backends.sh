#!/bin/bash

# Create Missing Backend Services - Simple Version

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔍 Creating Missing Backend Services${NC}"
echo ""

TEMPLATE_DIR="/Users/andromeda/dev/ewh/templates/express-health-service"

# Function to create backend
create_backend() {
    local service_name=$1
    local port=$2
    local display_name=$3

    if [ -f "$service_name/package.json" ]; then
        echo -e "${GREEN}✓${NC} $service_name exists"
        return 0
    fi

    echo -e "${YELLOW}📦 Creating $service_name (port $port)...${NC}"

    mkdir -p "$service_name/src"

    cat "$TEMPLATE_DIR/package.json" | \
        sed "s/SERVICE_NAME/$service_name/g" | \
        sed "s/PORT_NUMBER/$port/g" > "$service_name/package.json"

    cat "$TEMPLATE_DIR/src/index.ts" | \
        sed "s/SERVICE_NAME/$service_name/g" | \
        sed "s/SERVICE_DISPLAY_NAME/$display_name/g" | \
        sed "s/PORT_NUMBER/$port/g" > "$service_name/src/index.ts"

    cp "$TEMPLATE_DIR/tsconfig.json" "$service_name/"
    echo "PORT=$port" > "$service_name/.env"

    echo -e "${GREEN}✅${NC} Created $service_name"
}

# Create each backend
create_backend "svc-photo-editor" "5851" "Photo Editor Service"
create_backend "svc-layout" "5331" "Layout Service"
create_backend "svc-bi" "5886" "Business Intelligence Service"

echo ""
echo -e "${GREEN}✅ Done!${NC}"
