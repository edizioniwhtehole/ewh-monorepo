#!/bin/bash

# Comprehensive audit of all svc-* directories

echo "🔍 Auditing All Backend Services"
echo "================================="
echo ""

REPORT="SERVICE_AUDIT_DETAILED.md"

echo "# Backend Services Detailed Audit" > $REPORT
echo "Generated: $(date)" >> $REPORT
echo "" >> $REPORT

for dir in svc-*/; do
    if [ -d "$dir" ]; then
        service=${dir%/}

        echo "## $service" >> $REPORT
        echo "" >> $REPORT

        # Check package.json
        if [ -f "$dir/package.json" ]; then
            echo "- ✅ Has package.json" >> $REPORT

            # Check for dependencies
            if [ -d "$dir/node_modules" ]; then
                echo "- ✅ Dependencies installed" >> $REPORT
            else
                echo "- ⚠️  No node_modules (needs npm install)" >> $REPORT
            fi

            # Check for src directory
            if [ -d "$dir/src" ]; then
                file_count=$(find "$dir/src" -type f -name "*.ts" -o -name "*.js" | wc -l)
                echo "- ✅ Has src/ with $file_count files" >> $REPORT

                # Check for health endpoint
                if grep -rq "health\|/health" "$dir/src" 2>/dev/null; then
                    echo "- ✅ Has health endpoint" >> $REPORT
                else
                    echo "- ⚠️  No health endpoint found" >> $REPORT
                fi
            else
                echo "- ❌ No src/ directory" >> $REPORT
            fi

            # Check for .env
            if [ -f "$dir/.env" ]; then
                echo "- ✅ Has .env file" >> $REPORT
            else
                echo "- ⚠️  No .env file" >> $REPORT
            fi

        else
            echo "- ❌ No package.json (empty service)" >> $REPORT
        fi

        echo "" >> $REPORT
    fi
done

echo ""
echo "✅ Audit complete!"
echo "📄 Report saved to: $REPORT"

# Count services
total=$(ls -d svc-*/ 2>/dev/null | wc -l)
with_pkg=$(find svc-* -maxdepth 1 -name "package.json" 2>/dev/null | wc -l)
empty=$((total - with_pkg))

echo ""
echo "📊 Summary:"
echo "   Total services: $total"
echo "   With content: $with_pkg"
echo "   Empty: $empty"
