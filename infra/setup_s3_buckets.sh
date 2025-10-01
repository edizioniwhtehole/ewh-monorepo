#!/usr/bin/env bash
# Automates Wasabi bucket provisioning for staging and production.
# Usage: WASABI_ACCESS_KEY=... WASABI_SECRET_KEY=... ./setup_s3_buckets.sh
set -euo pipefail

# Configurable parameters
REGION=${WASABI_REGION:-eu-west-2}
ENDPOINT=${WASABI_ENDPOINT:-s3.eu-west-2.wasabisys.com}
STAGING_BUCKET=${WASABI_STAGING_BUCKET:-ewh-staging}
PRODUCTION_BUCKET=${WASABI_PRODUCTION_BUCKET:-ewh-prod}

if [[ -z "${WASABI_ACCESS_KEY:-}" || -z "${WASABI_SECRET_KEY:-}" ]]; then
  echo "Missing WASABI_ACCESS_KEY or WASABI_SECRET_KEY environment variables" >&2
  exit 1
fi

aws() {
  AWS_ACCESS_KEY_ID="$WASABI_ACCESS_KEY" \
  AWS_SECRET_ACCESS_KEY="$WASABI_SECRET_KEY" \
  AWS_REGION="$REGION" \
  command aws --endpoint-url "https://$ENDPOINT" "$@"
}

create_bucket() {
  local bucket=$1
  echo "Creating bucket $bucket (if absent)"
  set +e
  aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1
  local exists=$?
  set -e
  if [[ $exists -eq 0 ]]; then
    echo "Bucket $bucket already exists"
  else
    aws s3api create-bucket --bucket "$bucket" --create-bucket-configuration LocationConstraint="$REGION"
  fi
}

create_bucket "$STAGING_BUCKET"
create_bucket "$PRODUCTION_BUCKET"

# Ensure top-level prefixes for static assets (optional)
aws s3api put-object --bucket "$STAGING_BUCKET" --key "static/" >/dev/null || true
aws s3api put-object --bucket "$PRODUCTION_BUCKET" --key "static/" >/dev/null || true

echo "Wasabi buckets configured."
