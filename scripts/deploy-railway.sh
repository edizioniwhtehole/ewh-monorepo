#!/bin/bash
set -e

echo "🚀 EWH Platform - Railway Deployment"
echo "===================================="
echo ""

# Check if railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found!"
    echo "Install with: npm install -g @railway/cli"
    exit 1
fi

echo "✅ Railway CLI found"

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "🔐 Please login to Railway..."
    railway login
fi

echo "✅ Logged in to Railway"

# Create project if not exists
if ! railway status &> /dev/null; then
    echo "📦 Creating new Railway project..."
    railway init
else
    echo "✅ Railway project exists"
fi

echo ""
echo "🗄️  Provisioning services..."
echo ""

# Core datastores
echo "→ PostgreSQL..."
railway add --database postgres || echo "  (already exists)"

echo "→ Redis..."
railway add --database redis || echo "  (already exists)"

echo ""
echo "🔧 Setting environment variables..."
echo ""

# Set common env vars
railway variables set \
  NODE_ENV=production \
  LOG_LEVEL=info \
  DATABASE_URL='${{Postgres.DATABASE_URL}}' \
  REDIS_URL='${{Redis.REDIS_URL}}' \
  || true

echo ""
echo "📝 Deploying services..."
echo ""

# Deploy core services first
CORE_SERVICES=(
  "svc-api-gateway:4000"
  "svc-auth:4001"
  "svc-media:4003"
)

for service in "${CORE_SERVICES[@]}"; do
  IFS=':' read -r name port <<< "$service"
  echo "→ Deploying $name (port $port)..."

  railway up \
    --service "$name" \
    --detach \
    --environment production \
    || echo "  ⚠️  Failed to deploy $name (may need manual fix)"
done

echo ""
echo "✅ Core services deployed!"
echo ""
echo "🌐 Your services are live at:"
railway domain

echo ""
echo "📊 Monitor deployment:"
echo "  railway logs"
echo "  railway status"
echo ""
echo "🎉 Deployment complete!"
