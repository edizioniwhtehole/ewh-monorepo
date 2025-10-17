#!/usr/bin/env bash
set -euo pipefail

# === Config ===
ORG="edizioniwhtehole"
BASE_DIR="$HOME/dev/ewh"   # cartella madre dove clonare i repo

# Crea la cartella se non esiste
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# Lista completa dei repo
REPOS=(
  ewh-master
  ops-infra

  svc-api-gateway
  svc-auth

  svc-media
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
  svc-billing
  svc-bi
  svc-plugins
  svc-n8n

  app-web-frontend
  app-admin-console
  app-raster-editor
  app-layout-editor
  app-video-editor
)

# Clone di tutti i repo
for repo in "${REPOS[@]}"; do
  if [ -d "$repo" ]; then
    echo "🔄 $repo già esiste, faccio git pull"
    (cd "$repo" && git pull)
  else
    echo "⬇️ Clonazione $repo"
    gh repo clone "$ORG/$repo" "$repo"
  fi
done

echo "✅ Tutti i repo clonati in $BASE_DIR"
