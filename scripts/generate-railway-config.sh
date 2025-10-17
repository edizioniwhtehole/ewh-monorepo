#!/bin/bash
set -e

echo "🔧 Generating Railway config for ALL services..."
echo "================================================"
echo ""

# Output file
OUTPUT_FILE="railway-full.json"

# Start JSON
cat > $OUTPUT_FILE << 'EOF'
{
  "$schema": "https://railway.app/railway.schema.json",
  "version": 2,
  "services": [
EOF

# Find all services
SERVICES=($(find . -maxdepth 1 -type d \( -name "svc-*" -o -name "app-*" \) ! -name "*.backup" | sort))

echo "Found ${#SERVICES[@]} services"
echo ""

# Generate service configs
FIRST=true
for SERVICE_PATH in "${SERVICES[@]}"; do
  SERVICE=$(basename "$SERVICE_PATH")

  # Skip backup folders
  if [[ "$SERVICE" == *".backup" ]]; then
    continue
  fi

  echo "→ Adding $SERVICE"

  # Determine port based on service type
  if [[ "$SERVICE" == "svc-api-gateway" ]]; then
    PORT="4000"
  elif [[ "$SERVICE" == "svc-auth" ]]; then
    PORT="4001"
  elif [[ "$SERVICE" == "svc-plugins" ]]; then
    PORT="4002"
  elif [[ "$SERVICE" == "svc-media" ]]; then
    PORT="4003"
  elif [[ "$SERVICE" == "svc-billing" ]]; then
    PORT="4004"
  elif [[ "$SERVICE" == svc-image-* ]] || [[ "$SERVICE" == svc-job-* ]] || [[ "$SERVICE" == svc-writer* ]] || [[ "$SERVICE" == svc-content* ]]; then
    PORT="41$(printf '%02d' $((RANDOM % 50)))"  # 4100-4150 range
  elif [[ "$SERVICE" == svc-project* ]] || [[ "$SERVICE" == svc-s* ]]; then
    PORT="42$(printf '%02d' $((RANDOM % 50)))"  # 4200-4250 range
  elif [[ "$SERVICE" == svc-product* ]] || [[ "$SERVICE" == svc-order* ]] || [[ "$SERVICE" == svc-inventory* ]]; then
    PORT="43$(printf '%02d' $((RANDOM % 50)))"  # 4300-4350 range
  elif [[ "$SERVICE" == svc-pm* ]] || [[ "$SERVICE" == svc-support* ]] || [[ "$SERVICE" == svc-chat* ]]; then
    PORT="44$(printf '%02d' $((RANDOM % 50)))"  # 4400-4450 range
  elif [[ "$SERVICE" == app-web-* ]]; then
    PORT="3100"
  elif [[ "$SERVICE" == app-admin-* ]]; then
    PORT="3200"
  elif [[ "$SERVICE" == app-dam* ]]; then
    PORT="3300"
  else
    PORT="45$(printf '%02d' $((RANDOM % 99)))"  # Default
  fi

  # Add comma if not first service
  if [ "$FIRST" = false ]; then
    echo "," >> $OUTPUT_FILE
  fi
  FIRST=false

  # Generate service JSON
  cat >> $OUTPUT_FILE << EOF
    {
      "name": "$SERVICE",
      "source": {
        "directory": "$SERVICE"
      },
      "build": {
        "command": "pnpm install --frozen-lockfile"
      },
      "start": {
        "command": "pnpm start"
      },
      "variables": {
        "PORT": "$PORT",
        "NODE_ENV": "production",
        "DATABASE_URL": "\${{Postgres.DATABASE_URL}}",
        "REDIS_URL": "\${{Redis.REDIS_URL}}"
      },
      "healthcheck": {
        "path": "/health",
        "interval": 10,
        "timeout": 5
      },
      "autoscaling": {
        "enabled": true,
        "min": 1,
        "max": 3
      },
      "resources": {
        "memory": 512,
        "cpu": 0.5
      }
    }
EOF
done

# Close services array and add databases
cat >> $OUTPUT_FILE << 'EOF'
  ],
  "databases": [
    {
      "type": "postgresql",
      "name": "postgres",
      "plan": "hobby"
    },
    {
      "type": "redis",
      "name": "redis",
      "plan": "hobby"
    }
  ],
  "env": {
    "NODE_ENV": "production",
    "LOG_LEVEL": "info",
    "S3_ENDPOINT": "${S3_ENDPOINT}",
    "S3_ACCESS_KEY": "${S3_ACCESS_KEY}",
    "S3_SECRET_KEY": "${S3_SECRET_KEY}",
    "S3_BUCKET": "ewh-prod"
  }
}
EOF

echo ""
echo "✅ Generated $OUTPUT_FILE with ${#SERVICES[@]} services"
echo ""
echo "📝 Next steps:"
echo "  1. Review: cat $OUTPUT_FILE"
echo "  2. Deploy: railway up --config $OUTPUT_FILE"
echo ""
echo "⚠️  Note: Railway may have limits on services per project."
echo "   Consider grouping services by domain (core, creative, erp, etc.)"
