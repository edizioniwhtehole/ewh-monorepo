#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/dev/ewh"
cd "$BASE" || exit 1

# set di repo
FRONTENDS=("app-web-frontend" "app-admin-console" "app-raster-editor" "app-layout-editor" "app-video-editor")
CORES=("svc-api-gateway" "svc-auth" "svc-plugins" "svc-media" "svc-billing")

is_in() {
  local x="$1"; shift
  for e in "$@"; do [[ "$e" == "$x" ]] && return 0; done
  return 1
}

create_tsconfig() {
  local dir="$1"
  cat > "$dir/tsconfig.json" <<'EOF'
{ "compilerOptions": { "target":"ES2022", "module":"ESNext", "moduleResolution":"Bundler", "strict":true, "esModuleInterop":true, "skipLibCheck":true } }
EOF
}

create_fastify_pkg() {
  local dir="$1" name="$2"
  cat > "$dir/package.json" <<EOF
{
  "name": "$name",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": { "dev": "tsx watch src/index.ts" },
  "dependencies": { "fastify": "^4.28.1" },
  "devDependencies": { "tsx": "^4.16.2", "typescript": "^5.6.3" }
}
EOF
}

create_fastify_stub() {
  local dir="$1" port="$2"
  mkdir -p "$dir/src"
  create_fastify_pkg "$dir" "$(basename "$dir")"
  create_tsconfig "$dir"
  cat > "$dir/src/index.ts" <<EOF
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.all("/*", async (req, rep) => rep.code(501).send({ error: "not implemented" }));
const port = Number(process.env.PORT ?? $port);
app.listen({ port, host: "0.0.0.0" });
EOF
}

create_gateway() {
  local dir="$1" port=4000
  mkdir -p "$dir/src"
  create_fastify_pkg "$dir" "svc-api-gateway"
  create_tsconfig "$dir"
  cat > "$dir/src/index.ts" <<EOF
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.get("/whoami", async (req) => ({
  userId: req.headers["x-user-id"] ?? null,
  tenantId: req.headers["x-tenant-id"] ?? null,
  traceId: req.headers["x-trace-id"] ?? null
}));
// TODO: proxy /svc/* con verifica firma HMAC
const port = Number(process.env.PORT ?? $port);
app.listen({ port, host: "0.0.0.0" });
EOF
}

create_auth() {
  local dir="$1" port=4001
  mkdir -p "$dir/src"
  create_fastify_pkg "$dir" "svc-auth"
  create_tsconfig "$dir"
  cat > "$dir/src/index.ts" <<EOF
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.post("/auth/signup",  async (req, rep) => rep.code(501).send({ error:"signup TODO" }));
app.post("/auth/login",   async (req, rep) => rep.code(501).send({ error:"login TODO" }));
app.post("/auth/refresh", async (req, rep) => rep.code(501).send({ error:"refresh TODO" }));
const port = Number(process.env.PORT ?? $port);
app.listen({ port, host: "0.0.0.0" });
EOF
}

create_plugins() {
  local dir="$1" port=4002
  mkdir -p "$dir/src"
  create_fastify_pkg "$dir" "svc-plugins"
  create_tsconfig "$dir"
  cat > "$dir/src/index.ts" <<EOF
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.post("/plugins", async (req, rep) => rep.code(501).send({ error:"install plugin TODO" }));
app.post("/hooks",   async (req, rep) => rep.code(501).send({ error:"plugin hook TODO" }));
const port = Number(process.env.PORT ?? $port);
app.listen({ port, host: "0.0.0.0" });
EOF
}

create_media() {
  local dir="$1" port=4003
  mkdir -p "$dir/src"
  create_fastify_pkg "$dir" "svc-media"
  create_tsconfig "$dir"
  cat > "$dir/src/index.ts" <<EOF
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.post("/assets/upload-url", async (req, rep) => rep.code(501).send({ error:"signed URL TODO" }));
app.post("/assets",            async (req, rep) => rep.code(501).send({ error:"create asset TODO" }));
app.get("/assets",             async (req, rep) => rep.code(200).send([]));
app.get("/assets/:id",         async (req, rep) => rep.code(501).send({ error:"get asset TODO" }));
app.post("/assets/:id/version",async (req, rep) => rep.code(501).send({ error:"new version TODO" }));
const port = Number(process.env.PORT ?? $port);
app.listen({ port, host: "0.0.0.0" });
EOF
}

create_billing() {
  local dir="$1" port=4004
  mkdir -p "$dir/src"
  create_fastify_pkg "$dir" "svc-billing"
  create_tsconfig "$dir"
  cat > "$dir/src/index.ts" <<EOF
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.post("/plans",        async (req, rep) => rep.code(501).send({ error:"create plan TODO" }));
app.post("/usage",        async (req, rep) => rep.code(501).send({ error:"report usage TODO" }));
app.get("/invoices/:id",  async (req, rep) => rep.code(501).send({ error:"get invoice TODO" }));
const port = Number(process.env.PORT ?? $port);
app.listen({ port, host: "0.0.0.0" });
EOF
}

create_next() {
  local dir="$1"
  mkdir -p "$dir/pages/api" "$dir/pages"
  cat > "$dir/package.json" <<EOF
{
  "name": "$dir",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": { "dev": "next dev -p 3000" },
  "dependencies": {
    "next": "14.2.5",
    "react": "18.3.1",
    "react-dom": "18.3.1"
  },
  "devDependencies": {
    "typescript": "^5.6.3",
    "@types/node": "^20.12.13",
    "@types/react": "^18.3.7",
    "@types/react-dom": "^18.3.0"
  }
}
EOF
  cat > "$dir/tsconfig.json" <<'EOF'
{ "compilerOptions": { "target":"ES2022","lib":["dom","es2022"],"module":"ESNext","jsx":"preserve","strict":true,"esModuleInterop":true,"skipLibCheck":true } }
EOF
  cat > "$dir/pages/api/health.ts" <<'EOF'
import type { NextApiRequest, NextApiResponse } from "next";
export default function handler(req: NextApiRequest, res: NextApiResponse) {
  res.status(200).json({ status: "ok" });
}
EOF
  cat > "$dir/pages/index.tsx" <<EOF
export default function Home(){return <main style={{padding:24,fontFamily:"system-ui"}}>$dir – ok</main>}
EOF
}

bootstrap_repo() {
  local name="$1"
  local dir="$BASE/$name"
  if [[ ! -d "$dir" ]]; then
    echo "skip $name (cartella assente)"
    return
  fi
  if [[ -f "$dir/package.json" ]]; then
    echo "ok $name (già presente)"
    return
  fi

  case "$name" in
    app-*) create_next "$dir" ;;
    svc-api-gateway) create_gateway "$dir" ;;
    svc-auth)        create_auth "$dir" ;;
    svc-plugins)     create_plugins "$dir" ;;
    svc-media)       create_media "$dir" ;;
    svc-billing)     create_billing "$dir" ;;
    svc-*)           create_fastify_stub "$dir" 5000 ;; # default port placeholder
    *) echo "skip $name (non classificato)"; return ;;
  esac

  ( cd "$dir" && git add . && git commit -m "chore: bootstrap skeleton (dev + /health + stubs)" && git push origin main ) || true
  echo "done $name"
}

# ciclo su tutte le cartelle presenti
for d in "$BASE"/*; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  bootstrap_repo "$name"
done

echo "ALL DONE"
