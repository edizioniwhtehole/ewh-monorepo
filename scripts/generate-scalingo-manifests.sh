#!/bin/bash
# Generate Procfile and scalingo.json for all services
# Usage: ./scripts/generate-scalingo-manifests.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🔍 DRY RUN MODE - No files will be created"
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "========================================="
echo "  Scalingo Manifests Generator"
echo "========================================="
echo ""

# Get list of all services
SERVICES=($(ls -d svc-* app-* 2>/dev/null | grep -v node_modules | sort))

echo "Found ${#SERVICES[@]} services"
echo ""

CREATED=0
SKIPPED=0
FAILED=0

for service in "${SERVICES[@]}"; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 $service"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Check if package.json exists (Node.js service)
  if [[ ! -f "$service/package.json" ]]; then
    echo -e "${YELLOW}⚠️  No package.json, skipping${NC}"
    ((SKIPPED++))
    continue
  fi

  # Check if Procfile already exists
  if [[ -f "$service/Procfile" ]] && [[ "$DRY_RUN" == false ]]; then
    echo -e "${YELLOW}⚠️  Procfile already exists, skipping${NC}"
    ((SKIPPED++))
    continue
  fi

  # Detect port from ecosystem.config.cjs
  PORT=$(grep -A 10 "name: '$service'" ecosystem.config.cjs 2>/dev/null | grep -E "PORT" | head -1 | sed -E "s/.*['\":]([0-9]+).*/\1/")

  if [[ -z "$PORT" ]]; then
    # Fallback: Try to find in package.json or default
    PORT="3000"
    echo -e "${YELLOW}⚠️  Could not detect port, using default: $PORT${NC}"
  else
    echo "✅ Detected port: $PORT"
  fi

  # Generate app name for Scalingo (replace underscores)
  APP_NAME="ewh-prod-$(echo $service | sed 's/_/-/g')"

  # Detect if service has migrations
  HAS_MIGRATIONS=false
  if grep -q "migrate" "$service/package.json" 2>/dev/null; then
    HAS_MIGRATIONS=true
  fi

  # Detect service category for database addon strategy
  CATEGORY="shared"
  if [[ $service == svc-auth ]] || [[ $service == svc-api-gateway ]]; then
    CATEGORY="core-dedicated"
  elif [[ $service == svc-media ]] || [[ $service == app-dam ]]; then
    CATEGORY="core-dedicated"
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "🔍 Would create Procfile with PORT=$PORT"
    echo "🔍 Would create scalingo.json with name=$APP_NAME"
    if [[ "$HAS_MIGRATIONS" == true ]]; then
      echo "🔍 Would include migration command"
    fi
    ((CREATED++))
    continue
  fi

  # 1. Generate Procfile
  echo "1️⃣  Creating Procfile..."

  cat > "$service/Procfile" <<EOF
# Scalingo Procfile for $service
web: node --no-warnings dist/index.js
EOF

  # Add release command if migrations exist
  if [[ "$HAS_MIGRATIONS" == true ]]; then
    echo "release: npm run migrate:prod || echo 'No migrations to run'" >> "$service/Procfile"
  fi

  echo -e "${GREEN}✅ Procfile created${NC}"

  # 2. Generate scalingo.json
  echo "2️⃣  Creating scalingo.json..."

  # Determine formation size and count based on category
  if [[ "$CATEGORY" == "core-dedicated" ]]; then
    FORMATION_SIZE="M"
    FORMATION_COUNT="2"
  else
    FORMATION_SIZE="S"
    FORMATION_COUNT="1"
  fi

  # Generate database addon config
  DB_ADDON=""
  if [[ "$CATEGORY" == "core-dedicated" ]]; then
    DB_ADDON="    { \"plan\": \"postgresql:postgresql-starter-1024\" }"
  fi

  cat > "$service/scalingo.json" <<EOF
{
  "name": "$APP_NAME",
  "region": "osc-fr1",
  "stack": "scalingo-22",
  "formation": {
    "web": {
      "amount": $FORMATION_COUNT,
      "size": "$FORMATION_SIZE"
    }
  },
  "env": {
    "NODE_ENV": {
      "value": "production"
    },
    "NPM_CONFIG_PRODUCTION": {
      "value": "false"
    },
    "LOG_LEVEL": {
      "value": "info"
    },
    "PORT": {
      "value": "$PORT"
    }
  },
  "addons": [
EOF

  # Add database addon if dedicated
  if [[ -n "$DB_ADDON" ]]; then
    echo "$DB_ADDON" >> "$service/scalingo.json"
  fi

  cat >> "$service/scalingo.json" <<EOF
  ],
  "scripts": {
    "postdeploy": "echo 'Deployment successful'"
  }
}
EOF

  echo -e "${GREEN}✅ scalingo.json created${NC}"

  # 3. Create .buildpacks if needed (multi-buildpack)
  # Most services only need Node.js, skip for now

  # 4. Commit to git (if in a git repo)
  if [[ -d "$service/.git" ]]; then
    echo "3️⃣  Committing to git..."
    cd "$service"
    git add Procfile scalingo.json
    if git commit -m "chore(deploy): add Scalingo deployment manifests

- Add Procfile for service startup
- Add scalingo.json for configuration
- Port: $PORT
- Formation: ${FORMATION_COUNT}x${FORMATION_SIZE}
$(if [[ \"$HAS_MIGRATIONS\" == true ]]; then echo \"- Includes migration release command\"; fi)

Ready for deployment to Scalingo."; then
      echo -e "${GREEN}✅ Committed to git${NC}"

      # Push to remote (optional, ask user first)
      # Uncomment to auto-push:
      # git push origin main
    else
      echo -e "${YELLOW}⚠️  No changes to commit (files may already exist)${NC}"
    fi
    cd ..
  else
    echo -e "${YELLOW}⚠️  Not a git repository, skipping commit${NC}"
  fi

  ((CREATED++))
  echo -e "${GREEN}✅ Completed: $service${NC}"
  echo ""
done

# Summary
echo ""
echo "========================================="
echo "  Summary"
echo "========================================="
echo "Total services: ${#SERVICES[@]}"
echo -e "${GREEN}Created: $CREATED${NC}"
echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}Failed: $FAILED${NC}"
fi
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "🔍 This was a dry run. Run without --dry-run to create files."
  echo ""
  echo "To execute:"
  echo "  ./scripts/generate-scalingo-manifests.sh"
else
  echo -e "${GREEN}✅ Manifests generated for all services${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Review generated files (Procfile, scalingo.json)"
  echo "  2. Test deployment to staging:"
  echo "     cd svc-auth"
  echo "     scalingo create ewh-stg-svc-auth"
  echo "     git push scalingo main"
  echo "  3. Setup environment variables on Scalingo"
  echo "  4. Deploy remaining services"
fi
echo ""
