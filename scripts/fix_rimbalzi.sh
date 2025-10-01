#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/dev/ewh"
COMPOSE="$BASE/compose/docker-compose.dev.yml"

SERVICES=(
  svc-shipping
  svc-image-orchestrator
  svc-dms
  svc-mrp
  svc-projects
  svc-connectors-web
  svc-procurement
  svc-job-worker
  svc-crm
  svc-comm
  svc-prepress
  svc-n8n
)

tsconfig_json(){ cat > "$1/tsconfig.json" <<'JSON'
{ "compilerOptions": { "target":"ES2022","module":"ESNext","moduleResolution":"Bundler","strict":true,"esModuleInterop":true,"skipLibCheck":true,"outDir":"dist" }, "include":["src"] }
JSON
}

pkg_json(){ # $1 dir  $2 name
cat > "$1/package.json" <<JSON
{
  "name": "$2",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": { "dev": "tsx watch src/index.ts", "build": "tsc -p tsconfig.json", "start": "node dist/index.js" },
  "dependencies": { "fastify": "^4.28.1" },
  "devDependencies": { "tsx": "^4.16.2", "typescript": "^5.6.3" }
}
JSON
}

index_ts(){ # $1 filePath  $2 defaultPort
cat > "$1" <<TS
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.all("/*", async (req, rep) => rep.code(501).send({ error: "not implemented" }));
const port = Number(process.env.PORT ?? $2);
app.listen({ port, host: "0.0.0.0" });
TS
}

stop_services(){
  cd "$BASE/compose"
  docker compose -f "$COMPOSE" stop "${SERVICES[@]}" || true
}

bootstrap_repo(){
  local name="$1" dir="$BASE/$1"
  [[ "$name" == "svc-n8n" ]] && return 0
  [[ -d "$dir" ]] || mkdir -p "$dir"
  if [[ ! -f "$dir/package.json" ]]; then
    mkdir -p "$dir/src"
    pkg_json "$dir" "$name"
    tsconfig_json "$dir"
    # porta di default: prova a dedurla dal nome (fallback 5000)
    local port=5000
    case "$name" in
      svc-image-orchestrator) port=4100 ;;
      svc-job-worker)         port=4101 ;;
      svc-projects)           port=4200 ;;
      svc-connectors-web)     port=4205 ;;
      svc-prepress)           port=4105 ;;
      svc-comm)               port=4500 ;;
      svc-crm)                port=4308 ;;
      svc-mrp)                port=4306 ;;
      svc-shipping)           port=4307 ;;
      svc-dms)                port=4406 ;;
      svc-procurement)        port=4305 ;;
    esac
    index_ts "$dir/src/index.ts" "$port"
    ( cd "$dir" && git add . && git commit -m "chore: bootstrap skeleton (/health)" && git push ) || true
  fi
}

fix_n8n(){
  # rimuovi eventuale cartella locale che può interferire con l'immagine
  if [[ -d "$BASE/svc-n8n" ]]; then
    rm -rf "$BASE/svc-n8n"
  fi
}

start_services(){
  cd "$BASE/compose"
  docker compose -f "$COMPOSE" up -d "${SERVICES[@]}"
  docker compose -f "$COMPOSE" ps
}

main(){
  stop_services
  for s in "${SERVICES[@]}"; do bootstrap_repo "$s"; done
  fix_n8n
  start_services
}
main
