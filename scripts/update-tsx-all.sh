#!/bin/bash
# Update tsx to latest version in all services

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Updating tsx in all services...${NC}"

# Find all package.json files that have tsx
for pkg in svc-*/package.json; do
  dir=$(dirname "$pkg")

  if grep -q '"tsx"' "$pkg"; then
    echo -e "${YELLOW}Updating $dir...${NC}"
    (cd "$dir" && pnpm add -D tsx@latest esbuild@latest 2>&1 | tail -1)
  fi
done

echo -e "${GREEN}✓ Done updating tsx${NC}"
