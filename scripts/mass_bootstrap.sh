#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/dev/ewh"
cd "$BASE" || exit 1

FRONTENDS=("app-web-frontend" "app-admin-console" "app-raster-editor" "app-layout-editor" "app-video-editor")
CORES=("svc-api-gateway" "svc-auth" "svc-plugins" "svc-media" "svc-billing")

is_in() {
  local x="$1"; shift
  for e in "$@"; do [[ "$e" == "$x" ]] && return 0; done
  return 1
}

tsconfig_common() {
  cat > "$1/tsconfig.json" <<'JSON'
{ "compilerOptions": { "target":"ES2022","module":"ESNext","moduleResolution":"Bundler","strict":true,"esModuleInterop":true,"skipLibCheck":true,"outDir":"dist" }, "include":["src"] }
JSON
}

pkg_fastify() {
  local dir="$1" name="$2"
  cat > "$dir/package.json" <<JSON
{
  "name": "$name",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": { "dev": "tsx watch src/index.ts", "build":"tsc -p tsconfig.json", "start":"node dist/index.js" },
  "dependencies": { "fastify": "^4.28.1" },
  "devDependencies": { "tsx": "^4.16.2", "typescript": "^5.6.3" }
}
JSON
}

bootstrap_stub_svc() {
  local dir="$1"
  mkdir -p "$dir/src"
  pkg_fastify "$dir" "$(basename "$dir")"
  tsconfig_common "$dir"
  cat > "$dir/src/index.ts" <<'TS'
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.all("/*", async (req, rep) => rep.code(501).send({ error: "not implemented" }));
const port = Number(process.env.PORT ?? 5000);
app.listen({ port, host: "0.0.0.0" });
TS
}

bootstrap_gateway() {
  local dir="$1"
  mkdir -p "$dir/src"
  pkg_fastify "$dir" "svc-api-gateway"
  tsconfig_common "$dir"
  cat > "$dir/src/index.ts" <<'TS'
import Fastify from "fastify";
// import fastifyHttpProxy from "@fastify/http-proxy";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.get("/whoami", async (req) => ({
  userId: req.headers["x-user-id"] ?? null,
  tenantId: req.headers["x-tenant-id"] ?? null,
  traceId: req.headers["x-trace-id"] ?? null
}));
// TODO: app.register(fastifyHttpProxy, { upstream: "http://svc-auth:4001", prefix: "/svc/auth" });
const port = Number(process.env.PORT ?? 4000);
app.listen({ port, host: "0.0.0.0" });
TS
}

bootstrap_auth() {
  local dir="$1"
  mkdir -p "$dir/src"
  pkg_fastify "$dir" "svc-auth"
  tsconfig_common "$dir"
  cat > "$dir/src/index.ts" <<'TS'
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.post("/auth/signup",  async (req, rep) => rep.code(501).send({ error:"signup TODO" }));
app.post("/auth/login",   async (req, rep) => rep.code(501).send({ error:"login TODO" }));
app.post("/auth/refresh", async (req, rep) => rep.code(501).send({ error:"refresh TODO" }));
const port = Number(process.env.PORT ?? 4001);
app.listen({ port, host: "0.0.0.0" });
TS
}

bootstrap_plugins() {
  local dir="$1"
  mkdir -p "$dir/src"
  pkg_fastify "$dir" "svc-plugins"
  tsconfig_common "$dir"
  cat > "$dir/src/index.ts" <<'TS'
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.post("/plugins", async (req, rep) => rep.code(501).send({ error:"install plugin TODO" }));
app.post("/hooks",   async (req, rep) => rep.code(501).send({ error:"plugin hook TODO" }));
const port = Number(process.env.PORT ?? 4002);
app.listen({ port, host: "0.0.0.0" });
TS
}

bootstrap_media() {
  local dir="$1"
  mkdir -p "$dir/src"
  pkg_fastify "$dir" "svc-media"
  tsconfig_common "$dir"
  cat > "$dir/src/index.ts" <<'TS'
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.post("/assets/upload-url", async (req, rep) => rep.code(501).send({ error:"signed URL TODO" }));
app.post("/assets",            async (req, rep) => rep.code(501).send({ error:"create asset TODO" }));
app.get("/assets",             async (req, rep) => rep.code(200).send([]));
app.get("/assets/:id",         async (req, rep) => rep.code(501).send({ error:"get asset TODO" }));
app.post("/assets/:id/version",async (req, rep) => rep.code(501).send({ error:"new version TODO" }));
const port = Number(process.env.PORT ?? 4003);
app.listen({ port, host: "0.0.0.0" });
TS
}

bootstrap_billing() {
  local dir="$1"
  mkdir -p "$dir/src"
  pkg_fastify "$dir" "svc-billing"
  tsconfig_common "$dir"
  cat > "$dir/src/index.ts" <<'TS'
import Fastify from "fastify";
const app = Fastify({ logger: true });
app.get("/health", async () => ({ status: "ok" }));
app.post("/plans",        async (req, rep) => rep.code(501).send({ error:"create plan TODO" }));
app.post("/usage",        async (req, rep) => rep.code(501).send({ error:"report usage TODO" }));
app.get("/invoices/:id",  async (req, rep) => rep.code(501).send({ error:"get invoice TODO" }));
const port = Number(process.env.PORT ?? 4004);
app.listen({ port, host: "0.0.0.0" });
TS
}

bootstrap_next() {
  local dir="$1"
  mkdir -p "$dir/pages/api" "$dir/pages"
  cat > "$dir/package.json" <<JSON
{
  "name": "$(basename "$dir")",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": { "dev": "next dev -p 3000", "build":"next build", "start":"next start -p 3000" },
  "dependencies": { "next": "14.2.5", "react": "18.3.1", "react-dom": "18.3.1" },
  "devDependencies": { "typescript": "^5.6.3", "@types/node": "^20.12.13", "@types/react": "^18.3.7", "@types/react-dom": "^18.3.0" }
}
JSON
  cat > "$dir/tsconfig.json" <<'JSON'
{ "compilerOptions": { "target":"ES2022","lib":["dom","es2022"],"module":"ESNext","jsx":"preserve","strict":true,"esModuleInterop":true,"skipLibCheck":true } }
JSON
  cat > "$dir/pages/api/health.ts" <<'TS'
import type { NextApiRequest, NextApiResponse } from "next";
export default function handler(req: NextApiRequest, res: NextApiResponse) { res.status(200).json({ status: "ok" }); }
TS
  cat > "$dir/pages/index.tsx" <<'TSX'
export default function Home(){return <main style={{padding:24,fontFamily:"system-ui"}}>OK</main>}
TSX
}

process_repo() {
  local name="$1" dir="$BASE/$1"
  [ -d "$dir" ] || return 0
  if [ -f "$dir/package.json" ]; then
    echo "ok: $name (già bootstrap)"
    return 0
  fi
  case "$name" in
    app-*)             bootstrap_next "$dir" ;;
    svc-api-gateway)   bootstrap_gateway "$dir" ;;
    svc-auth)          bootstrap_auth "$dir" ;;
    svc-plugins)       bootstrap_plugins "$dir" ;;
    svc-media)         bootstrap_media "$dir" ;;
    svc-billing)       bootstrap_billing "$dir" ;;
    svc-*)             bootstrap_stub_svc "$dir" ;;
    *)                 echo "skip: $name"; return 0 ;;
  esac
  (cd "$dir" && git add . && git commit -m "chore(bootstrap): skeleton (+/health)" && git push origin main) || true
  echo "done: $name"
}

for d in "$BASE"/*; do
  [ -d "$d" ] || continue
  process_repo "$(basename "$d")"
done

echo "ALL DONE"
