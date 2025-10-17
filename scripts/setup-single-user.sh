#!/bin/bash

echo "🚀 PM System - Single User Mode Setup"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check if running from correct directory
if [ ! -f "package.json" ]; then
  echo "❌ Error: Please run this script from the project root directory"
  exit 1
fi

# 2. Create data directory
echo "${BLUE}📁 Creating data directory...${NC}"
mkdir -p pm-data
echo "${GREEN}✅ Created: pm-data/${NC}"
echo ""

# 3. Create backend .env
echo "${BLUE}⚙️  Configuring backend...${NC}"
cat > svc-pm/.env << 'EOF'
# Deployment mode: single-user | team | saas
DEPLOYMENT_MODE=single-user

# Database
DATABASE_URL=postgresql://ewh:password@localhost:5432/ewh_master

# Server
PORT=5500
NODE_ENV=development

# Single user config (only for single-user mode)
SINGLE_USER_TENANT_ID=00000000-0000-0000-0000-000000000001
SINGLE_USER_ID=00000000-0000-0000-0000-000000000001
SINGLE_USER_NAME=Me
SINGLE_USER_EMAIL=user@localhost
EOF
echo "${GREEN}✅ Created: svc-pm/.env${NC}"
echo ""

# 4. Install dependencies
echo "${BLUE}📦 Installing dependencies...${NC}"
echo "   This may take a few minutes..."
echo ""

cd svc-pm && npm install --silent > /dev/null 2>&1
echo "${GREEN}✅ Backend dependencies installed${NC}"

cd ../app-pm-frontend && npm install --silent > /dev/null 2>&1
echo "${GREEN}✅ Frontend dependencies installed${NC}"

cd ..
echo ""

# 5. Check database
echo "${BLUE}🗄️  Checking database...${NC}"
if psql -h localhost -U ewh -d ewh_master -c "SELECT 1" > /dev/null 2>&1; then
  echo "${GREEN}✅ Database connection OK${NC}"
else
  echo "${YELLOW}⚠️  Database not accessible. Make sure PostgreSQL is running.${NC}"
  echo "   Or run: ./scripts/setup-local-db.sh"
fi
echo ""

# 6. Start services
echo "${BLUE}🚀 Starting services...${NC}"
echo ""

# Stop any existing processes
pkill -f "tsx watch" > /dev/null 2>&1
pkill -f "vite" > /dev/null 2>&1
sleep 1

# Start backend
cd svc-pm
npm run dev > ../pm-data/backend.log 2>&1 &
BACKEND_PID=$!
echo "${GREEN}✅ Backend started (PID: $BACKEND_PID)${NC}"
cd ..

# Wait for backend to be ready
echo "   Waiting for backend to be ready..."
for i in {1..10}; do
  if curl -s http://localhost:5500/health > /dev/null 2>&1; then
    echo "${GREEN}   Backend is ready!${NC}"
    break
  fi
  sleep 1
done

# Start frontend
cd app-pm-frontend
npm run dev > ../pm-data/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "${GREEN}✅ Frontend started (PID: $FRONTEND_PID)${NC}"
cd ..

# Wait for frontend to be ready
echo "   Waiting for frontend to be ready..."
sleep 3

# Check if frontend is accessible
if curl -s http://localhost:5400 > /dev/null 2>&1; then
  echo "${GREEN}   Frontend is ready!${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${GREEN}🎉 PM System is ready!${NC}"
echo ""
echo "${BLUE}📍 URLs:${NC}"
echo "   Frontend: http://localhost:5400"
echo "   Backend:  http://localhost:5500"
echo "   Health:   http://localhost:5500/health"
echo ""
echo "${BLUE}📄 Logs:${NC}"
echo "   Backend:  tail -f pm-data/backend.log"
echo "   Frontend: tail -f pm-data/frontend.log"
echo ""
echo "${BLUE}👤 User:${NC}"
echo "   No login required! Auto-logged as 'Me'"
echo ""
echo "${BLUE}🛑 To stop:${NC}"
echo "   kill $BACKEND_PID $FRONTEND_PID"
echo "   or: pkill -f 'tsx watch'; pkill -f 'vite'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${YELLOW}💡 Tip: Your data is stored in the database.${NC}"
echo "${YELLOW}   To backup: pg_dump ewh_master > pm-data/backup.sql${NC}"
echo ""

# Save PIDs for later
echo "$BACKEND_PID" > pm-data/backend.pid
echo "$FRONTEND_PID" > pm-data/frontend.pid

# Open browser (optional)
if command -v open &> /dev/null; then
  sleep 2
  open http://localhost:5400
fi
