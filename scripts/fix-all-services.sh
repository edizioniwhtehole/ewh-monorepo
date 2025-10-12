#!/bin/bash
# Fix dependencies for all services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Fixing All Services Dependencies${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# List of all services
SERVICES=(
  "svc-plugins"
  "svc-media"
  "svc-billing"
  "svc-image-orchestrator"
  "svc-job-worker"
  "svc-writer"
  "svc-content"
  "svc-layout"
  "svc-prepress"
  "svc-vector-lab"
  "svc-mockup"
  "svc-video-orchestrator"
  "svc-video-runtime"
  "svc-raster-runtime"
  "svc-projects"
  "svc-search"
  "svc-site-builder"
  "svc-site-renderer"
  "svc-site-publisher"
  "svc-connectors-web"
  "svc-products"
  "svc-orders"
  "svc-inventory"
  "svc-channels"
  "svc-quotation"
  "svc-procurement"
  "svc-mrp"
  "svc-shipping"
  "svc-crm"
  "svc-pm"
  "svc-support"
  "svc-chat"
  "svc-boards"
  "svc-kb"
  "svc-collab"
  "svc-dms"
  "svc-timesheet"
  "svc-forms"
  "svc-forum"
  "svc-assistant"
  "svc-comm"
  "svc-enrichment"
  "svc-bi"
)

total=${#SERVICES[@]}
fixed=0
failed=0

for svc in "${SERVICES[@]}"; do
  echo -e "${YELLOW}[$((fixed + failed + 1))/$total]${NC} Processing $svc..."

  if [ ! -d "$svc" ]; then
    echo -e "${RED}  ✗ Directory not found${NC}"
    ((failed++))
    continue
  fi

  cd "$svc"

  # Remove node_modules and reinstall
  rm -rf node_modules 2>/dev/null || true

  if PNPM_STORE_DIR=/tmp/pnpm-store pnpm install --prefer-offline --no-frozen-lockfile 2>&1 | grep -q "done"; then
    echo -e "${GREEN}  ✓ Fixed${NC}"
    ((fixed++))
  else
    echo -e "${RED}  ✗ Failed to install${NC}"
    ((failed++))
  fi

  cd ..
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Fixed: $fixed services${NC}"
if [ $failed -gt 0 ]; then
  echo -e "${RED}Failed: $failed services${NC}"
fi
echo -e "${BLUE}========================================${NC}"
