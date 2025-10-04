#!/bin/bash

# Install Git Hooks for EWH Platform

set -e

echo "📦 Installing EWH Platform Git Hooks..."

# Check if we're in a git repository
if [ ! -d .git ]; then
  echo "❌ Error: Not a git repository"
  echo "Run this script from the root of the EWH repository"
  exit 1
fi

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
echo "Installing pre-commit hook..."
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# EWH Platform Pre-Commit Hook
# Auto-generated - DO NOT EDIT MANUALLY

# Run the pre-commit check script
./scripts/pre-commit-check.sh

# Exit with the script's exit code
exit $?
EOF

# Make hook executable
chmod +x .git/hooks/pre-commit

echo "✅ Git hooks installed successfully!"
echo ""
echo "The following checks will run before EVERY commit:"
echo "  1. ✓ Documentation updated (PROJECT_STATUS.md)"
echo "  2. ✓ No console.log in TypeScript"
echo "  3. ✓ Multi-tenancy enforced (tenant_id in tables)"
echo "  4. ✓ TODOs have tracking references"
echo ""
echo "To bypass checks (NOT recommended):"
echo "  git commit --no-verify"
echo ""
echo "To uninstall hooks:"
echo "  rm .git/hooks/pre-commit"
echo ""
