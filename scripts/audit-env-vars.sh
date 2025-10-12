#!/bin/bash
# Audit all environment variables across services
# Generates a comprehensive ENV_AUDIT.md document

set -e

OUTPUT_FILE="ENV_AUDIT.md"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "========================================="
echo "  Environment Variables Audit"
echo "========================================="
echo ""

# Start output file
cat > "$OUTPUT_FILE" <<EOF
# EWH Platform - Environment Variables Audit

> Comprehensive audit of all environment variables across services
> Generated: $(date '+%Y-%m-%d %H:%M:%S')

## 📋 Table of Contents

- [Overview](#overview)
- [Core Services](#core-services)
- [Creative Services](#creative-services)
- [Publishing Services](#publishing-services)
- [ERP Services](#erp-services)
- [Collaboration Services](#collaboration-services)
- [Platform Services](#platform-services)
- [Frontend Applications](#frontend-applications)
- [Shared Environment Variables](#shared-environment-variables)
- [Secrets Management](#secrets-management)

---

## Overview

This document lists all environment variables used across the EWH platform.

**Legend:**
- 🔒 **Secret** - Sensitive value, must be encrypted
- ⚙️ **Config** - Configuration value, can be public
- 🔗 **URL** - Connection string or endpoint
- 📝 **Optional** - Has default value

---

EOF

echo "📝 Generating audit document..."

# Function to categorize variable type
categorize_var() {
  local var=$1
  if [[ $var == *"SECRET"* ]] || [[ $var == *"KEY"* ]] || [[ $var == *"PASSWORD"* ]] || [[ $var == *"TOKEN"* ]]; then
    echo "🔒 SECRET"
  elif [[ $var == *"URL"* ]] || [[ $var == *"URI"* ]] || [[ $var == *"ENDPOINT"* ]]; then
    echo "🔗 URL"
  else
    echo "⚙️ CONFIG"
  fi
}

# Process each service
CATEGORIES=(
  "svc-api-gateway svc-auth svc-plugins svc-media svc-billing:Core Services"
  "svc-image-orchestrator svc-job-worker svc-writer svc-content svc-layout svc-prepress svc-vector-lab svc-mockup svc-video-orchestrator svc-video-runtime svc-raster-runtime:Creative Services"
  "svc-projects svc-search svc-site-builder svc-site-renderer svc-site-publisher svc-connectors-web:Publishing Services"
  "svc-products svc-orders svc-inventory svc-channels svc-quotation svc-procurement svc-mrp svc-shipping svc-crm:ERP Services"
  "svc-pm svc-support svc-chat svc-boards svc-kb svc-collab svc-dms svc-timesheet svc-forms svc-forum svc-assistant:Collaboration Services"
  "svc-comm svc-enrichment svc-bi:Platform Services"
  "app-web-frontend app-admin-frontend app-admin-console app-dam app-cms-frontend:Frontend Applications"
)

for category_data in "${CATEGORIES[@]}"; do
  IFS=':' read -r services category <<< "$category_data"

  echo "" >> "$OUTPUT_FILE"
  echo "## $category" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  echo "Processing: $category"

  for service in $services; do
    if [[ ! -d "$service" ]]; then
      continue
    fi

    echo "  - $service"

    echo "### $service" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Check for .env.example
    if [[ -f "$service/.env.example" ]]; then
      echo "**Environment Variables:**" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      echo "| Variable | Type | Description | Example |" >> "$OUTPUT_FILE"
      echo "|----------|------|-------------|---------|" >> "$OUTPUT_FILE"

      while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
          continue
        fi

        # Extract variable name and value
        if [[ "$line" =~ ^([A-Z_]+)=(.*)$ ]]; then
          var_name="${BASH_REMATCH[1]}"
          var_value="${BASH_REMATCH[2]}"
          var_type=$(categorize_var "$var_name")

          # Redact sensitive values
          if [[ "$var_type" == "🔒 SECRET" ]]; then
            var_value="***REDACTED***"
          fi

          echo "| \`$var_name\` | $var_type | - | \`$var_value\` |" >> "$OUTPUT_FILE"
        fi
      done < "$service/.env.example"

      echo "" >> "$OUTPUT_FILE"
    else
      echo "**No .env.example found** ⚠️" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      echo "*This service should have an .env.example file documenting required environment variables.*" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
    fi
  done
done

# Add shared variables section
cat >> "$OUTPUT_FILE" <<EOF

---

## Shared Environment Variables

Variables used across multiple services:

### Database

| Variable | Type | Description | Services |
|----------|------|-------------|----------|
| \`DATABASE_URL\` | 🔗 URL | PostgreSQL connection string | All backend services |
| \`DB_HOST\` | ⚙️ CONFIG | Database host | Alternative to DATABASE_URL |
| \`DB_PORT\` | ⚙️ CONFIG | Database port (default: 5432) | Alternative to DATABASE_URL |
| \`DB_NAME\` | ⚙️ CONFIG | Database name | Alternative to DATABASE_URL |
| \`DB_USER\` | ⚙️ CONFIG | Database username | Alternative to DATABASE_URL |
| \`DB_PASSWORD\` | 🔒 SECRET | Database password | Alternative to DATABASE_URL |
| \`DB_SCHEMA\` | ⚙️ CONFIG | PostgreSQL schema name | Service-specific |

### Redis

| Variable | Type | Description | Services |
|----------|------|-------------|----------|
| \`REDIS_URL\` | 🔗 URL | Redis connection string | Caching, sessions, job queue |
| \`REDIS_HOST\` | ⚙️ CONFIG | Redis host | Alternative to REDIS_URL |
| \`REDIS_PORT\` | ⚙️ CONFIG | Redis port (default: 6379) | Alternative to REDIS_URL |
| \`REDIS_PASSWORD\` | 🔒 SECRET | Redis password | Alternative to REDIS_URL |

### S3 Storage

| Variable | Type | Description | Services |
|----------|------|-------------|----------|
| \`S3_ENDPOINT\` | 🔗 URL | S3-compatible endpoint (Wasabi) | Media, DAM, exports |
| \`S3_ACCESS_KEY\` | 🔒 SECRET | S3 access key ID | Media services |
| \`S3_SECRET_KEY\` | 🔒 SECRET | S3 secret access key | Media services |
| \`S3_BUCKET\` | ⚙️ CONFIG | S3 bucket name | Media services |
| \`S3_REGION\` | ⚙️ CONFIG | S3 region (e.g., eu-central-1) | Media services |

### Authentication

| Variable | Type | Description | Services |
|----------|------|-------------|----------|
| \`JWT_ISSUER\` | 🔗 URL | JWT issuer URL | svc-auth, svc-api-gateway |
| \`JWT_AUDIENCE\` | ⚙️ CONFIG | JWT audience (e.g., ewh-saas) | All services |
| \`JWT_KID\` | ⚙️ CONFIG | JWT key ID | svc-auth |
| \`JWT_PRIVATE_KEY\` | 🔒 SECRET | JWT signing private key (RS256) | svc-auth only |
| \`JWT_PUBLIC_KEY\` | 📝 Optional | JWT public key for verification | All services (or fetch via JWKS) |
| \`JWT_PRIVATE_KEY_FILE\` | 📝 Optional | Path to private key file | svc-auth |
| \`JWT_PUBLIC_KEY_FILE\` | 📝 Optional | Path to public key file | svc-auth |
| \`AUTH_SERVICE_URL\` | 🔗 URL | svc-auth internal URL | svc-api-gateway |
| \`AUTH_JWKS_URL\` | 🔗 URL | JWKS endpoint for key verification | All services |

### Application

| Variable | Type | Description | Services |
|----------|------|-------------|----------|
| \`NODE_ENV\` | ⚙️ CONFIG | Environment (development/staging/production) | All services |
| \`PORT\` | ⚙️ CONFIG | HTTP port to listen on | All backend services |
| \`LOG_LEVEL\` | ⚙️ CONFIG | Logging level (debug/info/warn/error) | All services |
| \`ALLOWED_ORIGINS\` | ⚙️ CONFIG | CORS allowed origins (comma-separated) | API services |
| \`API_BASE_URL\` | 🔗 URL | API gateway base URL | Frontend apps |

### Third-Party Services

| Variable | Type | Description | Services |
|----------|------|-------------|----------|
| \`STRIPE_SECRET_KEY\` | 🔒 SECRET | Stripe API key | svc-billing |
| \`STRIPE_WEBHOOK_SECRET\` | 🔒 SECRET | Stripe webhook signing secret | svc-billing |
| \`OPENAI_API_KEY\` | 🔒 SECRET | OpenAI API key | svc-writer, svc-assistant |
| \`SENDGRID_API_KEY\` | 🔒 SECRET | SendGrid email API key | svc-comm |

---

## Secrets Management

### Current Strategy

**Development:**
- Secrets stored in \`.env\` files (gitignored)
- Copy from \`.env.example\` and fill in values

**Staging/Production:**
- Secrets stored as Scalingo environment variables
- Set via Scalingo dashboard or CLI:
  \`\`\`bash
  scalingo -a ewh-prod-svc-auth env-set JWT_PRIVATE_KEY="\$(cat jwk_private.pem)"
  \`\`\`

### Security Best Practices

1. **Never commit secrets to git**
   - Check \`.gitignore\` includes \`.env\`, \`*.pem\`, \`*.key\`

2. **Rotate secrets regularly**
   - JWT keys: Every 90 days
   - Database passwords: Every 180 days
   - API keys: Yearly or on security incident

3. **Use environment-specific secrets**
   - Separate keys for dev/staging/production
   - Never use production secrets in development

4. **Audit secret access**
   - Log when secrets are accessed
   - Monitor for unauthorized access

5. **Encrypt secrets at rest**
   - Scalingo encrypts environment variables
   - Use Vault for additional layer (v2.5)

### Secret Rotation Checklist

- [ ] Generate new secret
- [ ] Test in staging first
- [ ] Deploy to production (zero-downtime)
- [ ] Keep old secret valid for grace period (e.g., 7 days for JWT)
- [ ] Monitor for errors
- [ ] Revoke old secret

---

## Missing .env.example Files

The following services are missing \`.env.example\`:

EOF

# Find services without .env.example
for service in svc-* app-*; do
  if [[ -d "$service" ]] && [[ ! -f "$service/.env.example" ]]; then
    echo "- $service" >> "$OUTPUT_FILE"
  fi
done

cat >> "$OUTPUT_FILE" <<EOF

**Action Required:** Create \`.env.example\` files for these services documenting all required environment variables.

---

**Last Updated:** $(date '+%Y-%m-%d %H:%M:%S')
**Maintainer:** DevOps Team
**Next Audit:** $(date -v+1m '+%Y-%m-%d' 2>/dev/null || date -d '+1 month' '+%Y-%m-%d')
EOF

echo ""
echo -e "${GREEN}✅ Audit complete${NC}"
echo ""
echo "Report generated: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Review $OUTPUT_FILE"
echo "  2. Create missing .env.example files"
echo "  3. Setup secrets in Scalingo"
echo "  4. Document secret rotation schedule"
echo ""
