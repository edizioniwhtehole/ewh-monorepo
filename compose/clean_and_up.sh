#!/usr/bin/env bash
set -euo pipefail
COMPOSE="docker-compose.dev.yml"
NET=$(docker network ls --format '{{.Name}}' | grep 'ewh_net' | head -n1 || true)

cd "$(dirname "$0")"
docker compose -f "$COMPOSE" down --remove-orphans || true
if [ -n "${NET:-}" ]; then
  for c in $(docker ps -q --filter network="$NET"); do docker network disconnect -f "$NET" "$c" || true; done
  docker network rm "$NET" || true
fi
for n in $(docker ps -a --format '{{.Names}}' | grep -E '^(app_|svc_|ewh_)'); do docker rm -f "$n" || true; done
docker container prune -f || true
docker network prune -f || true

docker compose -f "$COMPOSE" up -d postgres redis minio
export COMPOSE_PROFILES=core,creative,publishing,erp,collab,platform,apps
docker compose -f "$COMPOSE" up -d
docker compose -f "$COMPOSE" ps
