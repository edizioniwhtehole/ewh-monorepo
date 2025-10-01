#!/usr/bin/env bash
set -euo pipefail

# name|url   (nessun allineamento con spazi)
checks=(
  "Core/gateway|http://localhost:4000/health"
  "Core/auth|http://localhost:4001/health"
  "Core/plugins|http://localhost:4002/health"
  "Core/media|http://localhost:4003/health"
  "Core/billing|http://localhost:4004/health"
  "App/frontend|http://localhost:3100/api/health"
  "svc/shipping|http://localhost:4307/health"
  "svc/img-orch|http://localhost:4100/health"
  "svc/dms|http://localhost:4406/health"
  "svc/mrp|http://localhost:4306/health"
  "svc/projects|http://localhost:4200/health"
  "svc/connectors|http://localhost:4205/health"
  "svc/job-worker|http://localhost:4101/health"
  "svc/crm|http://localhost:4308/health"
  "svc/comm|http://localhost:4500/health"
  "svc/prepress|http://localhost:4105/health"
)

trim() { awk '{$1=$1;print}'; }

ok=0; ko=0
for entry in "${checks[@]}"; do
  name="${entry%%|*}"
  url_raw="${entry#*|}"
  # rimuovi CR, fai trim
  url="$(printf '%s' "$url_raw" | tr -d '\r' | trim)"
  out="$(curl -sS --max-time 2 "$url" || true)"
  if printf '%s' "$out" | grep -q '"status" *: *"ok"'; then
    printf "✅ %-14s %s\n" "$name" "$url"
    ok=$((ok+1))
  else
    printf "❌ %-14s %s  →  %s\n" "$name" "$url" "${out:-"(no response)"}"
    ko=$((ko+1))
  fi
done
echo "-----"
echo "OK: $ok   KO: $ko"
exit $ko
