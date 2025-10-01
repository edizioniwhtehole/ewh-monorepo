#!/usr/bin/env bash
# Registra tutti i repository esistenti come submodule

set -euo pipefail

cd /Users/andromeda/dev/ewh

REPOS=(
  ewh-master
  ops-infra
  app-web-frontend
  app-admin-console
  app-raster-editor
  app-layout-editor
  app-video-editor
  svc-api-gateway
  svc-auth
  svc-plugins
  svc-media
  svc-billing
  svc-image-orchestrator
  svc-job-worker
  svc-writer
  svc-content
  svc-layout
  svc-prepress
  svc-vector-lab
  svc-mockup
  svc-video-orchestrator
  svc-video-runtime
  svc-raster-runtime
  svc-projects
  svc-search
  svc-site-builder
  svc-site-renderer
  svc-site-publisher
  svc-connectors-web
  svc-products
  svc-orders
  svc-inventory
  svc-channels
  svc-quotation
  svc-procurement
  svc-mrp
  svc-shipping
  svc-crm
  svc-pm
  svc-support
  svc-chat
  svc-boards
  svc-kb
  svc-collab
  svc-dms
  svc-timesheet
  svc-forms
  svc-forum
  svc-assistant
  svc-comm
  svc-enrichment
  svc-bi
  svc-n8n
)

for repo in "${REPOS[@]}"; do
  if [ -d "$repo/.git" ]; then
    echo "Adding $repo as submodule..."
    url="https://github.com/edizioniwhtehole/$repo.git"
    git submodule add --force "$url" "$repo" 2>&1 | grep -v "Cloning" || true
  else
    echo "⚠️  $repo not found or not a git repository"
  fi
done

echo ""
echo "✅ All submodules registered"
echo "Run: git submodule status | wc -l"
