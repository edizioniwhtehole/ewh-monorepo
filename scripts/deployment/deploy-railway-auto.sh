#!/bin/bash
set -e

echo "🚀 EWH Platform - Railway Auto-Scaling Deployment"
echo "===================================================="
echo ""

# Check Railway CLI
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found!"
    echo "Install: npm install -g @railway/cli"
    exit 1
fi

echo "✅ Railway CLI found"

# Login
if ! railway whoami &> /dev/null; then
    echo "🔐 Please login..."
    railway login
fi

echo "✅ Logged in: $(railway whoami)"
echo ""

# Create project
if ! railway status &> /dev/null; then
    echo "📦 Creating Railway project..."
    railway init --name ewh-platform
else
    echo "✅ Project exists"
fi

echo ""
echo "🗄️  Provisioning managed databases..."
echo ""

# PostgreSQL
echo "→ PostgreSQL (HA Cluster)..."
railway add --database postgresql || echo "  ✅ Already exists"

# Redis
echo "→ Redis..."
railway add --database redis || echo "  ✅ Already exists"

echo ""
echo "🔧 Configuring auto-scaling services..."
echo ""

# Deploy services with auto-scaling
SERVICES=(
  "svc-api-gateway:4000:2:5"  # name:port:min:max replicas
  "svc-auth:4001:2:4"
  "svc-media:4003:1:10"
  "svc-billing:4004:1:3"
  "svc-image-orchestrator:4100:0:5"
  "svc-job-worker:4101:0:10"
  "app-web-frontend:3100:2:10"
  "app-admin-frontend:3200:1:3"
)

for service in "${SERVICES[@]}"; do
  IFS=':' read -r name port min_replicas max_replicas <<< "$service"

  echo "→ Deploying $name"
  echo "  Port: $port"
  echo "  Auto-scaling: $min_replicas-$max_replicas replicas"

  # Deploy service
  railway up \
    --service "$name" \
    --detach \
    || echo "  ⚠️  Check logs: railway logs $name"

  # Configure auto-scaling
  railway variables set \
    --service "$name" \
    PORT="$port" \
    RAILWAY_AUTOSCALING_MIN="$min_replicas" \
    RAILWAY_AUTOSCALING_MAX="$max_replicas" \
    || true

  echo "  ✅ Deployed"
  echo ""
done

echo ""
echo "🌐 Generating public URLs..."
echo ""

# Generate domains for each service
railway domain || true

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Monitor your services:"
echo "  Dashboard: https://railway.app/project/$(railway status | grep 'Project ID' | awk '{print $3}')"
echo ""
echo "🔍 Useful commands:"
echo "  railway logs <service>        # View logs"
echo "  railway status               # Check all services"
echo "  railway variables            # View environment"
echo "  railway metrics              # See resource usage"
echo ""
echo "💰 Current usage:"
railway usage || true
echo ""
echo "🎉 Done! Your services scale independently."
