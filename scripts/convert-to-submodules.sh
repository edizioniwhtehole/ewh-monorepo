#!/bin/bash

# ============================================================================
# Convert Existing Folders to Git Submodules
# ============================================================================
# This script converts existing app/service folders to git submodules
# ============================================================================

set -e  # Exit on error

# Configuration
ORG="${GITHUB_ORG:-your-org}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Apps to convert
APPS=(
  "app-admin-frontend"
  "app-pm-frontend"
  "app-crm-frontend"
  "app-dam-frontend"
  "app-media-frontend"
  "app-web-frontend"
)

# Services to convert
SERVICES=(
  "svc-pm"
  "svc-crm"
  "svc-dam"
  "svc-auth"
  "svc-api-gateway"
  "svc-billing"
  "svc-media"
  "svc-storage"
  "svc-chat"
  "svc-kb"
)

# Combine all repos
ALL_REPOS=("${APPS[@]}" "${SERVICES[@]}")

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Converting Folders to Git Submodules${NC}"
echo -e "${BLUE}============================================================================${NC}\n"

# Check prerequisites
if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "${YELLOW}⚠️  GITHUB_TOKEN not set. You'll need to authenticate manually.${NC}"
  echo -e "${YELLOW}   Set it with: export GITHUB_TOKEN=your_token${NC}\n"
fi

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
  echo -e "${YELLOW}   Install it: brew install gh${NC}"
  exit 1
fi

# Authenticate with gh
if ! gh auth status &> /dev/null; then
  echo -e "${YELLOW}🔐 Authenticating with GitHub...${NC}"
  gh auth login
fi

echo -e "${GREEN}✅ Prerequisites checked\n${NC}"

# Backup
echo -e "${BLUE}📦 Creating backup...${NC}"
BACKUP_DIR="../ewh-backup-$(date +%Y%m%d_%H%M%S)"
cp -r . "$BACKUP_DIR"
echo -e "${GREEN}   ✅ Backup created: $BACKUP_DIR\n${NC}"

# Convert each repo
for repo in "${ALL_REPOS[@]}"; do
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Converting: $repo${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

  if [ ! -d "$repo" ]; then
    echo -e "${YELLOW}   ⚠️  Directory $repo not found, skipping...${NC}\n"
    continue
  fi

  # Check if already a git repo
  if [ -d "$repo/.git" ]; then
    echo -e "${YELLOW}   ⚠️  $repo already has .git, checking remote...${NC}"

    cd "$repo"
    if git remote get-url origin &> /dev/null; then
      REMOTE_URL=$(git remote get-url origin)
      echo -e "${GREEN}   ✅ Already a git repo with remote: $REMOTE_URL${NC}"

      # Check if it's already a submodule
      cd ..
      if git submodule status "$repo" &> /dev/null; then
        echo -e "${GREEN}   ✅ Already configured as submodule${NC}\n"
        continue
      fi

      # Add as submodule
      echo -e "${BLUE}   📎 Adding as submodule...${NC}"
      TEMP_DIR="${repo}_temp"
      mv "$repo" "$TEMP_DIR"
      git submodule add "$REMOTE_URL" "$repo"
      rm -rf "$TEMP_DIR"
      echo -e "${GREEN}   ✅ Added as submodule${NC}\n"
      continue
    fi
    cd ..
  fi

  # Initialize git if needed
  cd "$repo"
  if [ ! -d ".git" ]; then
    echo -e "${BLUE}   🔧 Initializing git...${NC}"
    git init
    git add .
    git commit -m "Initial commit: $repo"
  fi

  # Check if GitHub repo exists
  echo -e "${BLUE}   🔍 Checking if GitHub repo exists...${NC}"
  if gh repo view "$ORG/$repo" &> /dev/null; then
    echo -e "${GREEN}   ✅ GitHub repo exists: $ORG/$repo${NC}"

    # Add remote
    git remote add origin "https://github.com/$ORG/$repo.git" 2>/dev/null || true
  else
    echo -e "${YELLOW}   📝 Creating GitHub repo: $ORG/$repo${NC}"

    # Determine visibility
    VISIBILITY="--private"
    if [[ "$repo" == *"public"* ]]; then
      VISIBILITY="--public"
    fi

    # Create repo
    gh repo create "$ORG/$repo" $VISIBILITY --source=. --remote=origin --push

    echo -e "${GREEN}   ✅ GitHub repo created and pushed${NC}"
  fi

  # Push if needed
  if ! git ls-remote origin &> /dev/null; then
    echo -e "${BLUE}   📤 Pushing to GitHub...${NC}"
    git branch -M main
    git push -u origin main
    echo -e "${GREEN}   ✅ Pushed to origin${NC}"
  fi

  cd ..

  # Add as submodule
  echo -e "${BLUE}   📎 Converting to submodule...${NC}"

  # Backup folder
  TEMP_DIR="${repo}_temp"
  mv "$repo" "$TEMP_DIR"

  # Add as submodule
  git submodule add "https://github.com/$ORG/$repo.git" "$repo"

  # Remove temp
  rm -rf "$TEMP_DIR"

  echo -e "${GREEN}   ✅ Converted to submodule: $repo${NC}\n"
done

# Commit submodule changes
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Finalizing...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

git add .gitmodules
git add .
git commit -m "feat: convert all apps/services to git submodules

- Converted ${#ALL_REPOS[@]} repos to submodules
- Apps: ${#APPS[@]}
- Services: ${#SERVICES[@]}

Each service is now an independent repository for better CI/CD.
" || true

echo -e "${GREEN}✅ All done!${NC}\n"

echo -e "${BLUE}📊 Summary:${NC}"
echo -e "   - Total repos converted: ${#ALL_REPOS[@]}"
echo -e "   - Apps: ${#APPS[@]}"
echo -e "   - Services: ${#SERVICES[@]}"
echo -e "   - Backup location: $BACKUP_DIR"

echo -e "\n${BLUE}🔗 Next steps:${NC}"
echo -e "   1. git push origin main"
echo -e "   2. Verify submodules: git submodule status"
echo -e "   3. Clone test: git clone --recursive https://github.com/$ORG/ewh.git"

echo -e "\n${GREEN}✨ Conversion complete!${NC}"
