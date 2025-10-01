#!/usr/bin/env bash
# Merge di tutte le PR di sync "chore/sync-master-prompt" → main
set -euo pipefail
ORG="edizioniwhitehole"  # <-- cambia se diverso

REPOS=(
  ewh-master ops-infra
  svc-api-gateway svc-auth svc-media svc-image-orchestrator svc-job-worker svc-writer svc-content
  svc-layout svc-prepress svc-vector-lab svc-mockup svc-video-orchestrator svc-video-runtime svc-raster-runtime
  svc-projects svc-search svc-site-builder svc-site-renderer svc-site-publisher svc-connectors-web
  svc-products svc-orders svc-inventory svc-channels svc-quotation svc-procurement svc-mrp svc-shipping svc-crm
  svc-pm svc-support svc-chat svc-boards svc-kb svc-collab svc-dms svc-timesheet svc-forms svc-forum svc-assistant
  svc-comm svc-enrichment svc-billing svc-bi svc-plugins svc-n8n
  app-web-frontend app-admin-console app-raster-editor app-layout-editor app-video-editor
)

for r in "${REPOS[@]}"; do
  echo "== $ORG/$r =="
  PRN=$(gh pr list -R "$ORG/$r" \
        --state open \
        --search "sync master prompt" \
        --json number -q '.[0].number' || true)
  if [ -n "${PRN:-}" ]; then
    echo "→ Merge PR #$PRN in $r"
    gh pr merge -R "$ORG/$r" "$PRN" --squash --delete-branch || true
  else
    echo "ℹ️ Nessuna PR di sync aperta in $r"
  fi
done
echo "🎉 Finito: tutte le PR di sync mergiate."