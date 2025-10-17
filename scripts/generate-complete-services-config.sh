#!/bin/bash

# Generate complete services config based on all existing frontend apps

echo "# Complete Frontend Apps Inventory"
echo ""
echo "| App Directory | Suggested Port | Category | Status |"
echo "|--------------|----------------|----------|--------|"

# List all app-* directories (excluding backups)
for app in $(ls -d app-* 2>/dev/null | grep -v ".backup" | grep -v ".DELETED" | sort); do
    # Check if has package.json
    if [ -f "$app/package.json" ]; then
        # Try to extract port from package.json or vite.config
        port=$(grep -o "port.*[0-9]\{4,5\}" "$app/package.json" "$app/vite.config.ts" "$app/vite.config.js" 2>/dev/null | grep -o "[0-9]\{4,5\}" | head -1)

        # Determine category based on name
        category="other"
        if [[ $app == *"pm"* ]]; then category="projects"
        elif [[ $app == *"dam"* ]] || [[ $app == *"media"* ]]; then category="media"
        elif [[ $app == *"cms"* ]] || [[ $app == *"web"* ]] || [[ $app == *"page"* ]]; then category="content"
        elif [[ $app == *"approval"* ]] || [[ $app == *"workflow"* ]]; then category="workflow"
        elif [[ $app == *"box"* ]] || [[ $app == *"previz"* ]] || [[ $app == *"photo"* ]] || [[ $app == *"video"* ]] || [[ $app == *"raster"* ]] || [[ $app == *"layout"* ]]; then category="design"
        elif [[ $app == *"inventory"* ]] || [[ $app == *"procurement"* ]] || [[ $app == *"order"* ]] || [[ $app == *"quotation"* ]]; then category="business"
        elif [[ $app == *"comm"* ]] || [[ $app == *"crm"* ]] || [[ $app == *"voice"* ]]; then category="communications"
        elif [[ $app == *"admin"* ]] || [[ $app == *"shell"* ]] || [[ $app == *"settings"* ]]; then category="admin"
        fi

        status="✅"
        [ -d "$app/node_modules" ] && status="✅ Ready" || status="⚠️  Needs npm install"

        echo "| $app | ${port:-TBD} | $category | $status |"
    fi
done

echo ""
echo "## Missing from services.config.ts"
echo ""

# Apps that should be added
echo "- app-photoediting (5850)"
echo "- app-raster-editor (5860)"
echo "- app-video-editor (5870)"
echo "- app-cms-frontend (5310)"
echo "- app-web-frontend (5320)"
echo "- app-layout-editor (5330)"
echo "- app-workflow-editor (5880)"
echo "- app-workflow-insights (5885)"
echo "- app-orchestrator-frontend (5890)"
echo "- app-settings-frontend (3650)"
