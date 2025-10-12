#!/bin/bash
# Create missing GitHub repositories and add as submodules
# Usage: ./scripts/create-missing-repos.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🔍 DRY RUN MODE - No changes will be made"
fi

# Services that exist but are NOT in .gitmodules
MISSING_SERVICES=(
  # Critical - Production services
  "app-admin-frontend"
  "app-dam"
  "app-cms-frontend"
  "svc-approvals"
  "svc-metrics-collector"
  "svc-cms"

  # Frontend apps in development
  "app-photoediting"
  "app-pm-frontend"
  "app-page-builder"
  "app-shell-frontend"
  "app-media-frontend"
  "app-approvals-frontend"
  "app-workflow-insights"

  # Backend services in development
  "svc-page-builder"
  "svc-photo-editor"
  "svc-plugin-manager"
  "svc-print-pm"
  "svc-workflow-tracker"
)

# GitHub organization
GITHUB_ORG="edizioniwhtehole"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "========================================="
echo "  EWH - Missing Git Repos Setup"
echo "========================================="
echo ""
echo "Will create ${#MISSING_SERVICES[@]} repositories"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
  echo "Install with: brew install gh"
  exit 1
fi

# Check if logged in to GitHub
if ! gh auth status &> /dev/null; then
  echo -e "${RED}❌ Not logged in to GitHub${NC}"
  echo "Login with: gh auth login"
  exit 1
fi

echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
echo ""

# Function to create repo and setup git
create_repo() {
  local service=$1
  local service_type=""

  if [[ $service == app-* ]]; then
    service_type="Frontend Application"
  elif [[ $service == svc-* ]]; then
    service_type="Backend Service"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Processing: $service"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Check if directory exists
  if [[ ! -d "$service" ]]; then
    echo -e "${YELLOW}⚠️  Directory $service does not exist, skipping${NC}"
    return
  fi

  # Check if already has .git
  if [[ -d "$service/.git" ]]; then
    echo -e "${YELLOW}⚠️  $service already has .git directory, skipping${NC}"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "🔍 Would create GitHub repo: $GITHUB_ORG/$service"
    echo "🔍 Would initialize git in $service"
    echo "🔍 Would add as submodule"
    return
  fi

  # 1. Create GitHub repository
  echo "1️⃣  Creating GitHub repository..."
  if gh repo create "$GITHUB_ORG/$service" \
      --public \
      --description "EWH Platform - $service_type" \
      --add-readme=false; then
    echo -e "${GREEN}✅ Repository created: https://github.com/$GITHUB_ORG/$service${NC}"
  else
    echo -e "${RED}❌ Failed to create repository (may already exist)${NC}"
    # Continue anyway, maybe repo exists
  fi

  # 2. Initialize git in service directory
  echo "2️⃣  Initializing git repository..."
  cd "$service"

  git init
  git add .
  git commit -m "feat: initial commit - $service

EWH Platform service initial setup

- Imported from monorepo
- Ready for independent development
- Part of EWH microservices architecture"

  git branch -M main
  git remote add origin "https://github.com/$GITHUB_ORG/$service.git"

  # 3. Push to GitHub
  echo "3️⃣  Pushing to GitHub..."
  if git push -u origin main; then
    echo -e "${GREEN}✅ Pushed to GitHub${NC}"
  else
    echo -e "${RED}❌ Failed to push (may need to pull first if repo exists)${NC}"
  fi

  cd ..

  # 4. Remove directory (will be re-added as submodule)
  echo "4️⃣  Removing local directory (will be re-added as submodule)..."
  rm -rf "$service"

  # 5. Add as submodule
  echo "5️⃣  Adding as git submodule..."
  if git submodule add "https://github.com/$GITHUB_ORG/$service.git" "$service"; then
    echo -e "${GREEN}✅ Added as submodule${NC}"
  else
    echo -e "${RED}❌ Failed to add as submodule${NC}"
  fi

  echo -e "${GREEN}✅ Completed: $service${NC}"
}

# Process all services
SUCCESSFUL=0
FAILED=0

for service in "${MISSING_SERVICES[@]}"; do
  if create_repo "$service"; then
    ((SUCCESSFUL++))
  else
    ((FAILED++))
  fi
done

# Commit .gitmodules changes
if [[ "$DRY_RUN" == false ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📝 Committing .gitmodules changes"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  git add .gitmodules
  git commit -m "chore: add ${#MISSING_SERVICES[@]} missing services as submodules

Services added:
$(printf '%s\n' "${MISSING_SERVICES[@]}" | sed 's/^/- /')"

  echo ""
  echo -e "${GREEN}✅ Committed to monorepo${NC}"
  echo ""
  echo "Push changes with: git push origin main"
fi

# Summary
echo ""
echo "========================================="
echo "  Summary"
echo "========================================="
echo -e "Total services: ${#MISSING_SERVICES[@]}"
echo -e "${GREEN}Successful: $SUCCESSFUL${NC}"
if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}Failed: $FAILED${NC}"
fi
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "🔍 This was a dry run. Run without --dry-run to execute changes."
  echo ""
  echo "To execute:"
  echo "  ./scripts/create-missing-repos.sh"
else
  echo -e "${GREEN}✅ All repositories created and added as submodules${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. git push origin main"
  echo "  2. ./scripts/generate-scalingo-manifests.sh"
fi
echo ""
