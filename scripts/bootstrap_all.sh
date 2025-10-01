# ~/dev/ewh/bootstrap_all.sh
#!/usr/bin/env bash
set -euo pipefail
ORG="edizioniwhitehole"   # <-- correggi se diverso
read -r -d '' REPOS <<'EOF'
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
EOF

cd "$(dirname "$0")"
while read -r r; do
  [[ -z "$r" ]] && continue
  echo "== $r =="
  if [[ -d "$r/.git" ]]; then
    (cd "$r" && git remote -v || git remote add origin "git@github.com:${ORG}/${r}.git" && git remote -v; git fetch --all --prune)
  else
    if [[ -d "$r" ]]; then
      (cd "$r" && git init && git remote add origin "git@github.com:${ORG}/${r}.git" && git fetch origin && git checkout -B main origin/main || true)
    else
      gh repo clone "${ORG}/${r}" "$r" || git clone "git@github.com:${ORG}/${r}.git" "$r"
    fi
  fi
done <<< "$REPOS"
echo "✅ Bootstrap completato."