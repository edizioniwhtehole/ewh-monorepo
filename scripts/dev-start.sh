#!/bin/bash
# EWH Local Development Startup Script
# Starts all services using PM2 for local development (no Docker)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   EWH Local Development Startup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}PM2 not found. Installing PM2 locally...${NC}"
    npm install pm2 --save-dev
    PM2_CMD="npx pm2"
else
    PM2_CMD="pm2"
fi

# Function to check if a service is running
check_service() {
    local service=$1
    local port=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}Warning: Port $port is already in use by $service${NC}"
        return 1
    fi
    return 0
}

# Function to check if PostgreSQL is running
check_postgres() {
    echo -e "${BLUE}Checking PostgreSQL...${NC}"
    if ! pg_isready -h localhost -p 5432 -U ewh >/dev/null 2>&1; then
        echo -e "${RED}Error: PostgreSQL is not running on localhost:5432${NC}"
        echo -e "${YELLOW}Start PostgreSQL with: brew services start postgresql@16${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
    return 0
}

# Function to check if Redis is running
check_redis() {
    echo -e "${BLUE}Checking Redis...${NC}"
    if ! redis-cli ping >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Redis is not running on localhost:6379${NC}"
        echo -e "${YELLOW}Start Redis with: brew services start redis${NC}"
        echo -e "${YELLOW}Continuing anyway (some services may fail)...${NC}"
    else
        echo -e "${GREEN}✓ Redis is running${NC}"
    fi
    return 0
}

# Function to check if MinIO is running
check_minio() {
    echo -e "${BLUE}Checking MinIO...${NC}"
    if ! curl -f http://localhost:9000/minio/health/live >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: MinIO is not running on localhost:9000${NC}"
        echo -e "${YELLOW}You can start MinIO with Docker: docker run -d -p 9000:9000 -p 9001:9001 minio/minio server /data --console-address \":9001\"${NC}"
        echo -e "${YELLOW}Continuing anyway (media services may fail)...${NC}"
    else
        echo -e "${GREEN}✓ MinIO is running${NC}"
    fi
    return 0
}

# Check dependencies
echo -e "${BLUE}Checking dependencies...${NC}"
if ! check_postgres; then
    exit 1
fi
check_redis
check_minio
echo ""

# Stop any existing PM2 processes
echo -e "${BLUE}Stopping existing PM2 processes...${NC}"
$PM2_CMD delete all 2>/dev/null || true
echo ""

# Start services based on profile
PROFILE=${1:-all}

case $PROFILE in
    core)
        echo -e "${BLUE}Starting CORE services only...${NC}"
        $PM2_CMD start ecosystem.config.cjs --only "svc-api-gateway,svc-auth,svc-plugins,svc-media,svc-billing"
        ;;

    frontend)
        echo -e "${BLUE}Starting FRONTEND apps only...${NC}"
        $PM2_CMD start ecosystem.config.cjs --only "app-web-frontend,app-admin-frontend"
        ;;

    monitoring)
        echo -e "${BLUE}Starting MONITORING services...${NC}"
        $PM2_CMD start ecosystem.config.cjs --only "svc-metrics-collector"
        ;;

    minimal)
        echo -e "${BLUE}Starting MINIMAL setup (frontend + core services)...${NC}"
        $PM2_CMD start ecosystem.config.cjs --only "app-web-frontend,app-admin-frontend,svc-api-gateway,svc-auth,svc-plugins,svc-media,svc-billing,svc-metrics-collector"
        ;;

    all)
        echo -e "${BLUE}Starting ALL services...${NC}"
        $PM2_CMD start ecosystem.config.cjs
        ;;

    *)
        echo -e "${RED}Unknown profile: $PROFILE${NC}"
        echo -e "${YELLOW}Available profiles: core, frontend, monitoring, minimal, all${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Services started successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  pm2 list              - List all running services"
echo -e "  pm2 logs              - View all logs (Ctrl+C to exit)"
echo -e "  pm2 logs [service]    - View logs for specific service"
echo -e "  pm2 monit             - Monitor all services"
echo -e "  pm2 restart all       - Restart all services"
echo -e "  pm2 stop all          - Stop all services"
echo -e "  pm2 delete all        - Stop and remove all services"
echo ""
echo -e "${BLUE}Application URLs:${NC}"
echo -e "  Web Frontend:    ${GREEN}http://localhost:3100${NC}"
echo -e "  Admin Frontend:  ${GREEN}http://localhost:3200${NC}"
echo -e "  API Gateway:     ${GREEN}http://localhost:4000${NC}"
echo -e "  Auth Service:    ${GREEN}http://localhost:4001${NC}"
echo ""
echo -e "${YELLOW}Tip: Run 'pm2 logs' to follow all service logs${NC}"
