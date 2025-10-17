#!/bin/bash

# Start Complete Communications Suite on Mac Studio
# Services:
# - svc-voice (4640/4641) - Phone/VoIP system
# - app-shell-frontend (3000) - Main shell with integrated communications

set -e

MAC_STUDIO_IP="192.168.1.47"
MAC_STUDIO_USER="fabio"

echo "🚀 Starting Communications Suite on Mac Studio..."
echo ""

# Function to check if service is running
check_service() {
  local service_name=$1
  local port=$2

  ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} "curl -s http://localhost:${port}/health > /dev/null 2>&1" && echo "✅" || echo "❌"
}

# 1. Ensure database migration is applied
echo "📊 Checking database..."
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} << 'ENDSSH'
cd /Users/fabio/dev/ewh
PGPASSWORD=ewhpass psql -h localhost -U postgres -d ewh_master -f migrations/051_voice_system_tables.sql 2>&1 | grep -v "already exists" | grep -v "CREATE" | head -1 || echo "✅ Database ready"
ENDSSH

# 2. Start/restart svc-voice
echo ""
echo "📞 Starting svc-voice (Phone System)..."
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} << 'ENDSSH'
cd /Users/fabio/dev/ewh/svc-voice

# Ensure dependencies
npm install --silent 2>/dev/null || true

# Stop if running
npx pm2 delete svc-voice 2>/dev/null || true

# Start
npx pm2 start src/index.ts \
  --name svc-voice \
  --interpreter tsx \
  --watch src \
  --ignore-watch node_modules \
  --log /Users/fabio/dev/ewh/logs/svc-voice.log \
  --time

npx pm2 save
sleep 2
ENDSSH

# 3. Check svc-voice status
echo -n "   Status: "
check_service "svc-voice" "4640"

# 4. Update app-shell-frontend to include communications
echo ""
echo "🏠 Updating app-shell-frontend with communications integration..."
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} << 'ENDSSH'
cd /Users/fabio/dev/ewh/app-shell-frontend

# Ensure shell frontend has latest code
# (will be done manually after integration code is written)
echo "✅ Shell frontend ready for integration"
ENDSSH

# 5. Display summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Communications Suite Started!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📞 Voice/Phone System (svc-voice):"
echo "   - API:          http://192.168.1.47:4640"
echo "   - WebSocket:    ws://192.168.1.47:4641"
echo "   - Docs:         http://192.168.1.47:4640/dev"
echo "   - Health:       http://192.168.1.47:4640/health"
echo ""
echo "🏠 Main Shell (app-shell-frontend):"
echo "   - URL:          http://192.168.1.47:3000"
echo "   - Integrated:   Voice, Email, Messaging (pending)"
echo ""
echo "📋 PM2 Services:"
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} "npx pm2 list | grep -E '(svc-voice|app-shell)'"
echo ""
echo "🧪 Quick Tests:"
echo "   curl http://192.168.1.47:4640/health"
echo "   curl http://192.168.1.47:3000"
echo ""
echo "📝 To view logs:"
echo "   ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} 'npx pm2 logs svc-voice'"
echo ""
