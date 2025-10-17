#!/bin/bash

# Monitor EWH services status

echo "=== EWH Services Monitor ==="
echo ""

echo "📦 Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(NAMES|ewh_|svc_|app_)"
echo ""

echo "🔍 Service Health Checks:"
echo -n "Auth (4001): "
curl -s http://localhost:4001/health >/dev/null 2>&1 && echo "✅ UP" || echo "❌ DOWN"

echo -n "API Gateway (4000): "
curl -s http://localhost:4000/health >/dev/null 2>&1 && echo "✅ UP" || echo "❌ DOWN"

echo -n "Media (4003): "
curl -s http://localhost:4003/health >/dev/null 2>&1 && echo "✅ UP" || echo "❌ DOWN"

echo -n "DAM Frontend (3300): "
curl -s http://localhost:3300 >/dev/null 2>&1 && echo "✅ UP" || echo "❌ DOWN"

echo ""
echo "📋 Quick Commands:"
echo "  - View logs: docker logs <service-name>"
echo "  - Stop all: docker compose -f compose/docker-compose.dev.yml down"
echo "  - Restart: docker compose -f compose/docker-compose.dev.yml restart <service>"