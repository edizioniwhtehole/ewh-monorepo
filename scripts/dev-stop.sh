#!/bin/bash
# EWH Development Stop Script
# Stops all PM2 managed services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Stopping EWH Services${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if PM2 is available
if ! command -v pm2 &> /dev/null; then
    if [ -f "node_modules/.bin/pm2" ]; then
        PM2_CMD="npx pm2"
    else
        echo -e "${RED}PM2 not found!${NC}"
        exit 1
    fi
else
    PM2_CMD="pm2"
fi

# Show current status
echo -e "${BLUE}Current services:${NC}"
$PM2_CMD list
echo ""

# Ask for confirmation if services are running
if $PM2_CMD list | grep -q "online"; then
    echo -e "${YELLOW}This will stop all running services.${NC}"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi
fi

# Stop and delete all PM2 processes
echo -e "${BLUE}Stopping all services...${NC}"
$PM2_CMD delete all

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   All services stopped${NC}"
echo -e "${GREEN}========================================${NC}"
