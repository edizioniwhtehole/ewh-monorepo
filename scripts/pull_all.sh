# ~/dev/ewh/pull_all.sh
#!/usr/bin/env bash
set -euo pipefail
for d in */.git; do
  repo="${d%/.git}"
  echo "== $repo =="
  (cd "$repo" && git fetch --all --prune && git pull --ff-only || true)
done
echo "✅ Pull completato."