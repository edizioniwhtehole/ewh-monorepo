#!/usr/bin/env bash
set -euo pipefail

ORG="edizioniwhtehole"

cd ~/dev/ewh || exit 1

# Assicurati di essere loggato su gh
gh auth status || gh auth login

# Legge tutti i repo reali dell'org
gh repo list "$ORG" --limit 200 --json name -q '.[].name' | sort | while IFS= read -r r; do
  [ -z "$r" ] && continue
  echo "────────────────────────────────────────"
  echo "▶ $ORG/$r"

  # Se esiste ma non è git → nuke
  if [ -d "$r" ] && [ ! -d "$r/.git" ]; then
    echo "  ⚠ Cartella $r senza .git → cancello"
    rm -rf "$r"
  fi

  # Se non c'è → clone
  if [ ! -d "$r" ]; then
    echo "  ⇣ Clono $ORG/$r"
    gh repo clone "$ORG/$r" "$r" \
      || git clone "https://github.com/$ORG/$r.git" "$r" \
      || { echo "  ❌ Skip $r (permessi o repo inesistente)"; continue; }
  fi

  # Se c'è .git → aggiorno
  if [ -d "$r/.git" ]; then
    (
      cd "$r"
      git remote set-url origin "https://github.com/$ORG/$r.git" >/dev/null 2>&1 || true
      echo "  ↻ fetch + pull"
      git fetch --all --prune
      DEFBR=$(git remote show origin | awk '/HEAD branch/ {print $NF}')
      [ -z "$DEFBR" ] && DEFBR="main"
      git switch -C "$DEFBR" "origin/$DEFBR" || true
      git pull --ff-only || true
      echo "  ✔ OK: $r ($DEFBR)"
    )
  fi
done