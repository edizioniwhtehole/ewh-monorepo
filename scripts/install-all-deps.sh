#!/bin/bash
# Install dependencies for all services in parallel

echo "Installing dependencies for all services (this will take a few minutes)..."

# Core services (do first)
for svc in svc-api-gateway svc-auth svc-metrics-collector; do
  (cd "$svc" && pnpm install --prefer-offline > /dev/null 2>&1 && echo "✓ $svc") &
done

# All other services (parallel)
for svc in svc-*; do
  if [[ "$svc" != "svc-api-gateway" && "$svc" != "svc-auth" && "$svc" != "svc-metrics-collector" ]]; then
    (cd "$svc" && pnpm install --prefer-offline > /dev/null 2>&1 && echo "✓ $svc") &
  fi
done

# Wait for all background jobs
wait

echo ""
echo "✓ All dependencies installed!"
