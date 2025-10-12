#!/bin/bash
# Create Git repositories for 18 confirmed services
# Usage: ./scripts/create-final-repos.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🔍 DRY RUN MODE - No changes will be made"
fi

# All 18 services confirmed
SERVICES=(
  # Priority 1 - Critical (Production)
  "app-admin-frontend"
  "app-dam"
  "svc-cms"
  "svc-metrics-collector"
  "svc-approvals"

  # Priority 2 - Active Development
  "app-cms-frontend"
  "app-page-builder"
  "app-photoediting"
  "svc-page-builder"
  "svc-photo-editor"

  # Priority 3 - Additional Services
  "app-media-frontend"
  "app-approvals-frontend"
  "app-pm-frontend"
  "app-shell-frontend"
  "app-workflow-insights"
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
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EWH - Final Git Repos Creation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Will create ${#SERVICES[@]} repositories"
echo ""

# Check prerequisites
if ! command -v gh &> /dev/null; then
  echo -e "${RED}❌ GitHub CLI (gh) not installed${NC}"
  echo "Install with: brew install gh"
  exit 1
fi

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
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 Processing: $service"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Check if directory exists
  if [[ ! -d "$service" ]]; then
    echo -e "${YELLOW}⚠️  Directory $service does not exist, skipping${NC}"
    return 1
  fi

  # Check if already has .git
  if [[ -d "$service/.git" ]]; then
    echo -e "${YELLOW}⚠️  $service already has .git directory, skipping${NC}"
    return 1
  fi

  # Check if has content
  if [[ ! -f "$service/package.json" ]]; then
    echo -e "${YELLOW}⚠️  $service has no package.json, skipping${NC}"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "🔍 Would create GitHub repo: $GITHUB_ORG/$service"
    echo "🔍 Would initialize git in $service"
    echo "🔍 Would add as submodule"
    return 0
  fi

  # 1. Create GitHub repository
  echo "1️⃣  Creating GitHub repository..."
  if gh repo create "$GITHUB_ORG/$service" \
      --public \
      --description "EWH Platform - $service_type" \
      --add-readme=false 2>&1; then
    echo -e "${GREEN}✅ Repository created: https://github.com/$GITHUB_ORG/$service${NC}"
  else
    echo -e "${YELLOW}⚠️  Repository may already exist, continuing...${NC}"
  fi

  # 2. Initialize git in service directory
  echo "2️⃣  Initializing git repository..."
  cd "$service"

  git init
  git add .

  # Create comprehensive commit message
  git commit -m "feat: initial commit - $service

EWH Platform service initial setup

Service: $service
Type: $service_type
Status: Active Development

Features:
$(cat package.json 2>/dev/null | grep '"description"' || echo '- Core functionality')

Part of EWH microservices architecture
- Imported from monorepo
- Ready for independent development
- Integrated with platform services

Generated: $(date '+%Y-%m-%d %H:%M:%S')" || true

  git branch -M main
  git remote add origin "https://github.com/$GITHUB_ORG/$service.git"

  # 3. Push to GitHub
  echo "3️⃣  Pushing to GitHub..."
  if git push -u origin main 2>&1; then
    echo -e "${GREEN}✅ Pushed to GitHub${NC}"
  else
    echo -e "${RED}❌ Failed to push - may need to pull first${NC}"
    echo "    Try manually: cd $service && git pull origin main --allow-unrelated-histories"
  fi

  cd ..

  # 4. Remove directory (will be re-added as submodule)
  echo "4️⃣  Preparing for submodule conversion..."
  echo "    Creating backup: ${service}.backup"
  cp -r "$service" "${service}.backup"
  rm -rf "$service"

  # 5. Add as submodule
  echo "5️⃣  Adding as git submodule..."
  if git submodule add "https://github.com/$GITHUB_ORG/$service.git" "$service" 2>&1; then
    echo -e "${GREEN}✅ Added as submodule${NC}"
    # Remove backup on success
    rm -rf "${service}.backup"
  else
    echo -e "${RED}❌ Failed to add as submodule${NC}"
    echo "    Restoring from backup..."
    rm -rf "$service"
    mv "${service}.backup" "$service"
    return 1
  fi

  echo -e "${GREEN}✅ Completed: $service${NC}"
  return 0
}

# Process all services
SUCCESSFUL=0
FAILED=0
SKIPPED=0

for service in "${SERVICES[@]}"; do
  if create_repo "$service"; then
    ((SUCCESSFUL++))
  else
    if [[ -d "$service/.git" ]]; then
      ((SKIPPED++))
    else
      ((FAILED++))
    fi
  fi
done

# Commit .gitmodules changes
if [[ "$DRY_RUN" == false ]] && [[ $SUCCESSFUL -gt 0 ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📝 Committing .gitmodules changes"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  git add .gitmodules .git/config 2>/dev/null || true
  git add */  2>/dev/null || true

  git commit -m "chore: add ${SUCCESSFUL} services as git submodules

Services added:
$(printf '%s\n' "${SERVICES[@]}" | sed 's/^/- /')

Details:
- Total services: ${#SERVICES[@]}
- Successfully added: $SUCCESSFUL
- Skipped (already exist): $SKIPPED
- Failed: $FAILED

All services are now independent git repositories
and integrated as submodules in the monorepo.

Generated: $(date '+%Y-%m-%d %H:%M:%S')" || echo "No changes to commit"

  echo ""
  echo -e "${GREEN}✅ Changes committed to monorepo${NC}"
  echo ""
  echo "📤 Push changes with:"
  echo "   git push origin main"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total services: ${#SERVICES[@]}"
echo -e "${GREEN}✅ Successful: $SUCCESSFUL${NC}"
echo -e "${YELLOW}⏭️  Skipped: $SKIPPED${NC}"
if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}❌ Failed: $FAILED${NC}"
fi
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "🔍 This was a dry run. Run without --dry-run to execute."
  echo ""
  echo "To execute:"
  echo "  ./scripts/create-final-repos.sh"
else
  echo -e "${GREEN}✅ Git repositories created and configured${NC}"
  echo ""
  echo "📋 Next steps:"
  echo "  1. git push origin main"
  echo "  2. ./scripts/generate-scalingo-manifests.sh"
  echo "  3. Review new submodules: git submodule status"
  echo ""
  echo "🎯 New total submodules: $(git submodule status | wc -l)"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
