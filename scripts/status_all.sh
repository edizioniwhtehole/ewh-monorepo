#!/usr/bin/env bash

# ~/dev/ewh/status_all.sh
# Scansiona tutti i repository nella cartella corrente e segnala gli stati git
# Script pensato per essere eseguito dalla root del workspace.

set -euo pipefail

shopt -s nullglob

found_dirty=false
errors=()

for d in */.git; do
  repo="${d%/.git}"
  (
    cd "$repo"
    if ! dirty=$(git status --porcelain 2>&1); then
      errors+=("$repo: $dirty")
      exit 0
    fi
    if [[ -n "$dirty" ]]; then
      found_dirty=true
      echo "⚠️  $repo ha modifiche locali"
      echo "$dirty"
    fi
  )
done

if [[ ${#errors[@]} -gt 0 ]]; then
  echo "❌ Errori durante la scansione:" >&2
  for err in "${errors[@]}"; do
    echo "   $err" >&2
  done
fi

if [[ "$found_dirty" == false ]]; then
  echo "✅ Nessuna modifica locale trovata."
else
  echo "🔎 Controllo completato con repo modificati."
fi
