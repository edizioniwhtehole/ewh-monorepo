#!/bin/bash
# Setup PostgreSQL and Redis locally for EWH development

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   EWH Local Database Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew is not installed${NC}"
    echo -e "${YELLOW}Install Homebrew from: https://brew.sh${NC}"
    exit 1
fi

# Install PostgreSQL
echo -e "${BLUE}Checking PostgreSQL...${NC}"
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}PostgreSQL not found. Installing...${NC}"
    brew install postgresql@16
    brew services start postgresql@16

    # Add to PATH
    echo -e "${YELLOW}Add to your ~/.zshrc or ~/.bashrc:${NC}"
    echo -e "${GREEN}export PATH=\"/opt/homebrew/opt/postgresql@16/bin:\$PATH\"${NC}"
    echo ""
else
    echo -e "${GREEN}✓ PostgreSQL is installed${NC}"

    # Start if not running
    if ! brew services list | grep "postgresql@16.*started" &> /dev/null; then
        echo -e "${YELLOW}Starting PostgreSQL...${NC}"
        brew services start postgresql@16
        sleep 3
    else
        echo -e "${GREEN}✓ PostgreSQL is running${NC}"
    fi
fi

# Install Redis
echo -e "${BLUE}Checking Redis...${NC}"
if ! command -v redis-cli &> /dev/null; then
    echo -e "${YELLOW}Redis not found. Installing...${NC}"
    brew install redis
    brew services start redis
else
    echo -e "${GREEN}✓ Redis is installed${NC}"

    # Start if not running
    if ! brew services list | grep "redis.*started" &> /dev/null; then
        echo -e "${YELLOW}Starting Redis...${NC}"
        brew services start redis
        sleep 2
    else
        echo -e "${GREEN}✓ Redis is running${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Setting up EWH database...${NC}"

# Wait for PostgreSQL to be ready
sleep 3

# Try to find psql
PSQL_BIN=$(which psql 2>/dev/null || echo "/opt/homebrew/opt/postgresql@16/bin/psql")

if [ ! -f "$PSQL_BIN" ]; then
    echo -e "${RED}Error: psql binary not found${NC}"
    echo -e "${YELLOW}You may need to restart your terminal or add PostgreSQL to PATH${NC}"
    exit 1
fi

# Create user and database
echo -e "${YELLOW}Creating database user 'ewh'...${NC}"
$PSQL_BIN postgres -c "CREATE USER ewh WITH PASSWORD 'ewhpass';" 2>/dev/null || echo "User 'ewh' already exists"

echo -e "${YELLOW}Creating database 'ewh_master'...${NC}"
$PSQL_BIN postgres -c "CREATE DATABASE ewh_master OWNER ewh;" 2>/dev/null || echo "Database 'ewh_master' already exists"

echo -e "${YELLOW}Creating database 'ewh_timesheet'...${NC}"
$PSQL_BIN postgres -c "CREATE DATABASE ewh_timesheet OWNER ewh;" 2>/dev/null || echo "Database 'ewh_timesheet' already exists"

echo -e "${YELLOW}Granting privileges...${NC}"
$PSQL_BIN postgres -c "ALTER USER ewh CREATEDB;" 2>/dev/null || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Setup completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Connection details:${NC}"
echo -e "  PostgreSQL: ${GREEN}postgres://ewh:ewhpass@localhost:5432/ewh_master${NC}"
echo -e "  Redis:      ${GREEN}redis://localhost:6379/0${NC}"
echo ""
echo -e "${YELLOW}Note: You still need MinIO for S3 storage.${NC}"
echo -e "${YELLOW}Run this to start MinIO with Docker:${NC}"
echo -e "${GREEN}docker run -d -p 9000:9000 -p 9001:9001 \\${NC}"
echo -e "${GREEN}  -e MINIO_ROOT_USER=ewh \\${NC}"
echo -e "${GREEN}  -e MINIO_ROOT_PASSWORD=ewhminio \\${NC}"
echo -e "${GREEN}  --name ewh-minio \\${NC}"
echo -e "${GREEN}  minio/minio server /data --console-address \":9001\"${NC}"
echo ""
echo -e "${BLUE}Next step: Run ./scripts/dev-start.sh minimal${NC}"
