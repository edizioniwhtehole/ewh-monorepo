#!/bin/bash

# EWH Platform Master Setup Script
# Configures, installs dependencies, and starts all services

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 EWH Platform Master Setup${NC}"
echo -e "${BLUE}==============================${NC}"
echo ""

# Function to check if service needs setup
needs_setup() {
    local dir=$1
    if [ ! -f "$dir/package.json" ]; then
        return 0  # true - needs setup
    fi
    return 1  # false - already has package.json
}

# Function to apply frontend template
apply_frontend_template() {
    local app_dir=$1
    local app_name=$2
    local display_name=$3
    local port=$4
    local api_port=$5

    echo -e "${YELLOW}📦 Setting up $app_name...${NC}"

    mkdir -p "$app_dir/src"

    # Copy and customize package.json
    cat templates/vite-react-hello-world/package.json | \
        sed "s/APP_NAME/$app_name/g" | \
        sed "s/PORT_NUMBER/$port/g" > "$app_dir/package.json"

    # Copy source files
    cat templates/vite-react-hello-world/src/App.tsx | \
        sed "s/APP_DISPLAY_NAME/$display_name/g" | \
        sed "s/API_PORT/$api_port/g" > "$app_dir/src/App.tsx"

    cp templates/vite-react-hello-world/src/main.tsx "$app_dir/src/"
    cp templates/vite-react-hello-world/src/index.css "$app_dir/src/"

    # Copy config files
    cat templates/vite-react-hello-world/vite.config.ts | \
        sed "s/PORT_NUMBER/$port/g" > "$app_dir/vite.config.ts"

    cat templates/vite-react-hello-world/index.html | \
        sed "s/APP_DISPLAY_NAME/$display_name/g" > "$app_dir/index.html"

    cp templates/vite-react-hello-world/tailwind.config.js "$app_dir/"
    cp templates/vite-react-hello-world/tsconfig.json "$app_dir/"

    echo -e "${GREEN}✅ $app_name setup complete${NC}"
}

# Function to apply backend template
apply_backend_template() {
    local service_dir=$1
    local service_name=$2
    local display_name=$3
    local port=$4

    echo -e "${YELLOW}⚙️  Setting up $service_name...${NC}"

    mkdir -p "$service_dir/src"

    # Copy and customize package.json
    cat templates/express-health-service/package.json | \
        sed "s/SERVICE_NAME/$service_name/g" | \
        sed "s/PORT_NUMBER/$port/g" > "$service_dir/package.json"

    # Copy source files
    cat templates/express-health-service/src/index.ts | \
        sed "s/SERVICE_NAME/$service_name/g" | \
        sed "s/SERVICE_DISPLAY_NAME/$display_name/g" | \
        sed "s/PORT_NUMBER/$port/g" > "$service_dir/src/index.ts"

    # Copy config files
    cp templates/express-health-service/tsconfig.json "$service_dir/"

    cat templates/express-health-service/.env.example | \
        sed "s/PORT_NUMBER/$port/g" > "$service_dir/.env"

    echo -e "${GREEN}✅ $service_name setup complete${NC}"
}

# Setup missing frontend apps
echo -e "${BLUE}📱 Checking Frontend Apps...${NC}"

# CRM Frontend
if needs_setup "app-crm-frontend"; then
    apply_frontend_template "app-crm-frontend" "app-crm-frontend" "CRM" "3310" "3311"
fi

# Photo Editor
if needs_setup "app-photoediting"; then
    apply_frontend_template "app-photoediting" "app-photoediting" "Photo Editor" "5850" "5851"
fi

# Raster Editor
if needs_setup "app-raster-editor"; then
    apply_frontend_template "app-raster-editor" "app-raster-editor" "Raster Editor" "5860" "5861"
fi

# Video Editor
if needs_setup "app-video-editor"; then
    apply_frontend_template "app-video-editor" "app-video-editor" "Video Editor" "5870" "5871"
fi

echo ""
echo -e "${BLUE}⚙️  Checking Backend Services...${NC}"

# CMS Service
if needs_setup "svc-cms"; then
    apply_backend_template "svc-cms" "svc-cms" "CMS Service" "5311"
fi

# Photo Editor Service
if needs_setup "svc-photo-editor"; then
    apply_backend_template "svc-photo-editor" "svc-photo-editor" "Photo Editor Service" "5851"
fi

# Raster Runtime
if needs_setup "svc-raster-runtime"; then
    apply_backend_template "svc-raster-runtime" "svc-raster-runtime" "Raster Service" "5861"
fi

# Video Services
if needs_setup "svc-video-orchestrator"; then
    apply_backend_template "svc-video-orchestrator" "svc-video-orchestrator" "Video Orchestrator" "5871"
fi

if needs_setup "svc-video-runtime"; then
    apply_backend_template "svc-video-runtime" "svc-video-runtime" "Video Runtime" "5872"
fi

echo ""
echo -e "${GREEN}✅ Platform setup complete!${NC}"
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo "- All templates applied"
echo "- Check PORT_ALLOCATION.md for complete port mapping"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run: ${GREEN}npm install${NC} in each app/service directory"
echo "2. Or use: ${GREEN}./scripts/install-all-deps.sh${NC} to install all at once"
echo "3. Start services with: ${GREEN}./scripts/start-all-services.sh${NC}"
echo ""
