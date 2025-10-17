#!/bin/bash

# Add missing .env files to all services

echo "📝 Adding Missing .env Files"
echo "============================="
echo ""

count=0

for dir in svc-*/; do
    if [ -f "$dir/package.json" ] && [ ! -f "$dir/.env" ]; then
        service=${dir%/}

        # Try to extract port from package.json
        port=$(grep -o '"dev".*--port [0-9]\+' "$dir/package.json" 2>/dev/null | grep -o '[0-9]\+' | head -1)

        if [ -z "$port" ]; then
            # Try to find in src/index.ts
            port=$(grep -o 'PORT.*[0-9]\{4,5\}' "$dir/src/index.ts" 2>/dev/null | grep -o '[0-9]\{4,5\}' | head -1)
        fi

        if [ -z "$port" ]; then
            port="TBD"
        fi

        echo "NODE_ENV=development" > "$dir/.env"
        echo "PORT=$port" >> "$dir/.env"

        echo "✅ Created .env for $service (port: $port)"
        ((count++))
    fi
done

echo ""
echo "✅ Created $count .env files"
