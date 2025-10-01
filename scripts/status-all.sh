#!/usr/bin/env bash
# Mostra lo stato di tutti i submodule

set -euo pipefail

echo "📊 Status of all submodules:"
echo ""

git submodule foreach '
  echo "=== $name ==="
  branch=$(git branch --show-current)
  echo "Branch: $branch"

  changes=$(git status --short | wc -l | tr -d " ")
  if [ "$changes" -gt 0 ]; then
    echo "⚠️  $changes uncommitted changes"
    git status --short
  else
    echo "✓ Clean working directory"
  fi

  # Check if ahead/behind remote
  if [ -n "$branch" ]; then
    git fetch origin "$branch" 2>/dev/null || true
    ahead=$(git rev-list --count origin/$branch..$branch 2>/dev/null || echo "0")
    behind=$(git rev-list --count $branch..origin/$branch 2>/dev/null || echo "0")

    if [ "$ahead" -gt 0 ]; then
      echo "↑ $ahead commits ahead of origin/$branch"
    fi
    if [ "$behind" -gt 0 ]; then
      echo "↓ $behind commits behind origin/$branch"
    fi
  fi

  echo ""
'
