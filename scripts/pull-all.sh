#!/usr/bin/env bash
# Pull tutti i submodule del monorepo EWH

set -euo pipefail

echo "🔄 Pulling all submodules..."
git submodule foreach 'git pull origin $(git branch --show-current) || git pull origin main'

echo "✅ All submodules pulled successfully"
