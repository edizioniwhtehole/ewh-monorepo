#!/usr/bin/env bash
# Aggiorna i riferimenti dei submodule nel monorepo

set -euo pipefail

echo "🔄 Updating submodule references..."

# Aggiorna tutti i submodule ai loro latest commit
git submodule update --remote --merge

# Mostra cosa è cambiato
git status

echo ""
echo "✅ Submodule references updated"
echo ""
echo "Ora puoi committare le modifiche con:"
echo "  git add -A"
echo "  git commit -m 'Update submodule references'"
echo "  git push"
