#!/bin/bash
# Script per aggiungere FEATURES.md a un singolo servizio
# Uso: ./scripts/add-features-to-service.sh <service-name> <features-file.md>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Verifica argomenti
if [ $# -lt 2 ]; then
    echo "❌ Uso: $0 <service-name> <features-file.md>"
    echo ""
    echo "Esempi:"
    echo "  $0 svc-dam ~/Desktop/DAM_FEATURES.md"
    echo "  $0 app-crm-frontend ~/Desktop/CRM_FRONTEND_FEATURES.md"
    exit 1
fi

SERVICE_NAME="$1"
FEATURES_FILE="$2"
SERVICE_DIR="$PROJECT_ROOT/$SERVICE_NAME"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           📋 Add Features to Service                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Verifica servizio esiste
if [ ! -d "$SERVICE_DIR" ]; then
    echo "❌ Errore: Servizio '$SERVICE_NAME' non trovato"
    echo "   Path: $SERVICE_DIR"
    exit 1
fi
echo "✅ Servizio trovato: $SERVICE_NAME"

# 2. Verifica file features esiste
if [ ! -f "$FEATURES_FILE" ]; then
    echo "❌ Errore: File features '$FEATURES_FILE' non trovato"
    exit 1
fi
echo "✅ File features trovato: $FEATURES_FILE"
echo ""

# 3. Copia FEATURES.md nel servizio
echo "📋 Copiando FEATURES.md in $SERVICE_NAME/..."
cp "$FEATURES_FILE" "$SERVICE_DIR/FEATURES.md"
echo "   ✅ Copiato: $SERVICE_DIR/FEATURES.md"
echo ""

# 4. Crea CONTEXT.md se non esiste
if [ ! -f "$SERVICE_DIR/CONTEXT.md" ]; then
    echo "📝 Creando CONTEXT.md..."

    # Determina tipo servizio e porta
    if [[ "$SERVICE_NAME" == svc-* ]]; then
        SERVICE_TYPE="Backend"
        # Estrai porta da package.json se esiste
        if [ -f "$SERVICE_DIR/package.json" ]; then
            PORT=$(grep -o '"start".*--port [0-9]*' "$SERVICE_DIR/package.json" | grep -o '[0-9]*' | head -1)
            [ -z "$PORT" ] && PORT="XXXX"
        else
            PORT="XXXX"
        fi
    else
        SERVICE_TYPE="Frontend"
        PORT="3XXX"
    fi

    # Crea CONTEXT.md dal template
    cat > "$SERVICE_DIR/CONTEXT.md" << EOF
# 🎯 $SERVICE_NAME - Quick Context

> **LEGGIMI PRIMA DI INIZIARE** - Context minimo (risparmio token: ~800 vs ~7000)

## ⚡ Quick Facts (30 secondi)

- **Service Type**: $SERVICE_TYPE
- **Port**: $PORT
- **Database**: ewh_tenant.\${schema}
- **Auth**: JWT via svc-auth (port 4610)
- **Storage**: S3 via svc-storage

## 📋 P1 Features ONLY

Vedi [FEATURES.md](./FEATURES.md) per la lista completa prioritizzata.

**Focus SOLO su P1 per questa iterazione!**

## 🔧 Tech Stack

- **Runtime**: Node.js 20+ / TypeScript 5+
- **Framework**: $([ "$SERVICE_TYPE" == "Backend" ] && echo "Fastify 4.x" || echo "Next.js 14 + React 18")
- **Database**: PostgreSQL 16 (con RLS)
- **Cache**: Redis (via svc-cache)
- **Queue**: BullMQ (via svc-queue)

## 🚀 Quick Start

\`\`\`bash
cd $SERVICE_NAME
npm install
cp .env.example .env

# Sviluppo
npm run dev

# IMPORTANTE: Apri browser durante sviluppo
open http://localhost:$PORT
\`\`\`

## 📚 Riferimenti Rapidi

- **Workflow**: [AGENT_WORKFLOW.md](../AGENT_WORKFLOW.md) ⭐ OBBLIGATORIO
- **Specs**: [PLATFORM_SPECS_2025.md](../PLATFORM_SPECS_2025.md)
- **Architecture**: [ARCHITECTURE.md](../ARCHITECTURE.md)
- **Progress**: [CHECKPOINT.md](./CHECKPOINT.md)

---

**Aggiornato**: $(date +"%Y-%m-%d")
EOF

    echo "   ✅ Creato: $SERVICE_DIR/CONTEXT.md"
else
    echo "⏭️  CONTEXT.md già esistente, skip"
fi
echo ""

# 5. Crea CHECKPOINT.md se non esiste
if [ ! -f "$SERVICE_DIR/CHECKPOINT.md" ]; then
    echo "🔄 Creando CHECKPOINT.md..."

    cat > "$SERVICE_DIR/CHECKPOINT.md" << EOF
# 🔄 Development Checkpoint - $SERVICE_NAME

> **Progress tracking & bug reporting**
> Aggiorna questo file ad ogni iterazione completata

---

## ✅ Completed (DO NOT TOUCH - LOCKED)

_Nessuna feature completata ancora_

---

## 🚧 In Progress

### Iteration 1 - Setup iniziale
**Started**: $(date +"%Y-%m-%d %H:%M")
**Status**: 🟡 In Development

**Tasks**:
- [ ] Setup base project structure
- [ ] Database schema (migrations)
- [ ] Core routes/API
- [ ] Basic frontend UI
- [ ] Integration tests

---

## 🐛 Bugs Found (Needs Debugger)

_Nessun bug ancora_

---

## 📝 Notes per Human QA

_Aggiungi qui note per il QA umano quando apri il browser_

---

**Last Updated**: $(date +"%Y-%m-%d %H:%M")
EOF

    echo "   ✅ Creato: $SERVICE_DIR/CHECKPOINT.md"
else
    echo "⏭️  CHECKPOINT.md già esistente, skip"
fi
echo ""

# 6. Summary
echo "══════════════════════════════════════════════════════════════"
echo "✅ SERVIZIO CONFIGURATO"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "📁 Files creati in $SERVICE_NAME/:"
echo "   ✅ FEATURES.md (copiato)"
[ ! -f "$SERVICE_DIR/CONTEXT.md" ] || echo "   ✅ CONTEXT.md (creato)"
[ ! -f "$SERVICE_DIR/CHECKPOINT.md" ] || echo "   ✅ CHECKPOINT.md (creato)"
echo ""
echo "🎯 NEXT STEPS:"
echo ""
echo "1. Review features:"
echo "   cd $SERVICE_NAME && cat FEATURES.md"
echo ""
echo "2. Lancia AI agent su questo servizio:"
echo "   - Leggerà automaticamente FEATURES.md"
echo "   - Leggerà CONTEXT.md (veloce)"
echo "   - Seguirà AGENT_WORKFLOW.md"
echo "   - Aggiornerà CHECKPOINT.md"
echo ""
echo "3. Durante sviluppo, agent aprirà:"
echo "   open http://localhost:$PORT"
echo ""
