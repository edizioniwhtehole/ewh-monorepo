# ~/dev/ewh/push_all.sh
#!/usr/bin/env bash
set -euo pipefail
for d in */.git; do
  repo="${d%/.git}"
  echo "== $repo =="
  (cd "$repo" && \
    branch=$(git rev-parse --abbrev-ref HEAD) && \
    git pull --ff-only || true; \
    [[ -z "$(git status --porcelain)" ]] || git add -A && git commit -m "chore: sync local changes" || true; \
    git push origin "$branch" || true)
done
echo "✅ Push all done."