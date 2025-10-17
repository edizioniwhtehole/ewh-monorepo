#!/bin/bash
set -e

echo "🚀 EWH Platform - Smart Deployment by Priority"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check Railway CLI
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found!"
    echo "Install: npm install -g @railway/cli"
    exit 1
fi

# Login check
if ! railway whoami &> /dev/null; then
    echo "🔐 Please login to Railway..."
    railway login
fi

print_success "Logged in as: $(railway whoami)"
echo ""

# ============================================
# PRIORITY 1: CORE SERVICES (Critical)
# ============================================
echo "📦 PRIORITY 1: Core Services (Critical)"
echo "========================================"
echo ""

CORE_SERVICES=(
  "svc-api-gateway:4000"
  "svc-auth:4001"
  "svc-media:4003"
  "svc-billing:4004"
  "app-web-frontend:3100"
  "app-admin-frontend:3200"
)

echo "Deploy ${#CORE_SERVICES[@]} core services?"
echo "  - svc-api-gateway (Gateway + routing)"
echo "  - svc-auth (Authentication)"
echo "  - svc-media (File uploads)"
echo "  - svc-billing (Payments)"
echo "  - app-web-frontend (Public site)"
echo "  - app-admin-frontend (Admin panel)"
echo ""
read -p "Deploy core services? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Create/select core project
  echo "→ Setting up Railway project: ewh-core"
  railway link ewh-core || railway init --name ewh-core

  # Add databases
  echo "→ Provisioning PostgreSQL..."
  railway add --database postgresql || true

  echo "→ Provisioning Redis..."
  railway add --database redis || true

  # Deploy core services
  for service in "${CORE_SERVICES[@]}"; do
    IFS=':' read -r name port <<< "$service"
    echo ""
    echo "→ Deploying $name..."

    cd "$name" || continue

    railway up --service "$name" --detach || print_warning "Failed to deploy $name"

    railway variables set --service "$name" \
      PORT="$port" \
      NODE_ENV="production" \
      DATABASE_URL='${{Postgres.DATABASE_URL}}' \
      REDIS_URL='${{Redis.REDIS_URL}}' \
      || true

    cd ..
    print_success "$name deployed"
  done

  print_success "Core services deployed!"
else
  print_warning "Skipped core services"
fi

echo ""
echo ""

# ============================================
# PRIORITY 2: CREATIVE SERVICES (Important)
# ============================================
echo "📦 PRIORITY 2: Creative Services (Important)"
echo "============================================="
echo ""

CREATIVE_SERVICES=(
  "svc-image-orchestrator:4100"
  "svc-job-worker:4101"
  "svc-video-orchestrator:4108"
  "app-dam:3300"
)

echo "Deploy ${#CREATIVE_SERVICES[@]} creative services?"
echo "  - Image/video processing"
  - DAM frontend"
echo ""
read -p "Deploy creative services? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "→ Setting up Railway project: ewh-creative"
  railway link ewh-creative || railway init --name ewh-creative

  # Get DATABASE_URL from core project
  echo "→ Connecting to core database..."
  print_warning "You'll need to copy DATABASE_URL from ewh-core project"

  for service in "${CREATIVE_SERVICES[@]}"; do
    IFS=':' read -r name port <<< "$service"
    echo ""
    echo "→ Deploying $name..."

    cd "$name" || continue
    railway up --service "$name" --detach || print_warning "Failed"
    cd ..

    print_success "$name deployed"
  done

  print_success "Creative services deployed!"
else
  print_warning "Skipped creative services"
fi

echo ""
echo ""

# ============================================
# PRIORITY 3: ERP & COLLAB (Optional)
# ============================================
echo "📦 PRIORITY 3: ERP & Collaboration (Optional)"
echo "=============================================="
echo ""

ERP_SERVICES=(
  "svc-pm:4400"
  "svc-crm:4308"
  "svc-orders:4301"
  "svc-chat:4402"
)

echo "Deploy ${#ERP_SERVICES[@]} ERP/Collab services?"
echo "  - PM, CRM, Orders, Chat..."
echo "  (Can deploy later when needed)"
echo ""
read -p "Deploy ERP services? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "→ Setting up Railway project: ewh-erp"
  railway link ewh-erp || railway init --name ewh-erp

  for service in "${ERP_SERVICES[@]}"; do
    IFS=':' read -r name port <<< "$service"
    echo "→ Deploying $name..."

    cd "$name" || continue
    railway up --service "$name" --detach || print_warning "Failed"
    cd ..

    print_success "$name deployed"
  done

  print_success "ERP services deployed!"
else
  print_warning "Skipped ERP services (deploy later)"
fi

echo ""
echo ""

# ============================================
# SUMMARY
# ============================================
echo "🎉 Deployment Summary"
echo "====================="
echo ""
echo "✅ Projects created:"
echo "  - ewh-core (critical services)"
echo "  - ewh-creative (media processing)"
echo "  - ewh-erp (business services)"
echo ""
echo "📊 View deployments:"
echo "  railway status --project ewh-core"
echo "  railway status --project ewh-creative"
echo "  railway status --project ewh-erp"
echo ""
echo "🔍 Monitor logs:"
echo "  railway logs --project ewh-core"
echo ""
echo "💰 Check usage:"
echo "  railway usage"
echo ""
print_success "Deployment complete!"
