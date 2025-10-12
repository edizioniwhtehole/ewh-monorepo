#!/bin/bash

# Setup script for shared widgets implementation

set -e

echo "🚀 Setting up shared widgets system..."
echo ""

# 1. Install dependencies
echo "📦 Installing dependencies with pnpm..."
pnpm install

# 2. Verify symlinks
echo ""
echo "🔗 Verifying workspace symlinks..."

if [ -L "app-admin-frontend/node_modules/@ewh/shared-widgets" ]; then
  echo "✅ Admin frontend: @ewh/shared-widgets linked"
else
  echo "❌ Admin frontend: @ewh/shared-widgets NOT linked"
  echo "   Run: pnpm install"
fi

if [ -L "app-web-frontend/node_modules/@ewh/shared-widgets" ]; then
  echo "✅ Web frontend: @ewh/shared-widgets linked"
else
  echo "❌ Web frontend: @ewh/shared-widgets NOT linked"
  echo "   Run: pnpm install"
fi

# 3. Verify Next.js config
echo ""
echo "⚙️  Verifying Next.js configuration..."

if grep -q "transpilePackages.*@ewh/shared-widgets" app-admin-frontend/next.config.js; then
  echo "✅ Admin frontend: transpilePackages configured"
else
  echo "❌ Admin frontend: transpilePackages NOT configured"
fi

if grep -q "transpilePackages.*@ewh/shared-widgets" app-web-frontend/next.config.js; then
  echo "✅ Web frontend: transpilePackages configured"
else
  echo "❌ Web frontend: transpilePackages NOT configured"
fi

# 4. Test imports
echo ""
echo "🧪 Testing TypeScript resolution..."

cat > /tmp/test-import.ts << 'EOF'
import { ConnectedUsersWidget, WidgetRegistry } from '@ewh/shared-widgets';
console.log('Import successful!');
EOF

if cd app-admin-frontend && npx tsc --noEmit /tmp/test-import.ts 2>/dev/null; then
  echo "✅ TypeScript import resolution works"
else
  echo "⚠️  TypeScript import may have issues"
fi

cd ..

# 5. Summary
echo ""
echo "✨ Setup complete!"
echo ""
echo "📖 Next steps:"
echo ""
echo "1. Run the database migration:"
echo "   psql -h localhost -U ewh -d ewh_master -f migrations/023_unified_plugin_widget_system.sql"
echo ""
echo "2. Start admin frontend:"
echo "   cd app-admin-frontend && pnpm dev"
echo ""
echo "3. Start web frontend (in another terminal):"
echo "   cd app-web-frontend && pnpm dev"
echo ""
echo "4. Test admin context:"
echo "   http://localhost:3200/admin/monitoring/users"
echo ""
echo "5. Test tenant context:"
echo "   http://localhost:3100/dashboard/team"
echo ""
echo "📚 Documentation:"
echo "   - SHARED_WIDGETS_IMPLEMENTATION.md (complete guide)"
echo "   - shared/packages/widgets/README.md (package docs)"
echo "   - WIDGET_PLUGIN_SYSTEM_GUIDE.md (plugin integration)"
echo ""
