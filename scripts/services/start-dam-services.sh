#!/bin/bash

# Start essential services for DAM testing
# Only starts what's needed for app-dam to work

echo "🧹 Cleaning up old PM2 processes..."
pm2 delete all 2>/dev/null || true
pm2 kill 2>/dev/null || true
sleep 2

echo "🚀 Starting core services..."

# Core services (essential)
pm2 start ecosystem.config.cjs --only svc-api-gateway
pm2 start ecosystem.config.cjs --only svc-auth
pm2 start ecosystem.config.cjs --only svc-media
pm2 start ecosystem.config.cjs --only svc-plugins

echo "⏳ Waiting for core services to be ready..."
sleep 5

# Start DAM frontend
echo "🎨 Starting DAM frontend..."
pm2 start ecosystem.config.cjs --only app-dam

echo "✅ DAM services started!"
echo ""
echo "📊 Service status:"
pm2 status

echo ""
echo "📝 Logs available with: pm2 logs [service-name]"
echo "🔍 Monitor with: pm2 monit"
echo "🛑 Stop all with: pm2 delete all"