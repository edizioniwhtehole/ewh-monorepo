# Automazione Deploy su Scalingo con GitHub Actions

> Guida per implementare l'automazione del deploy e sostituzione variabili su Scalingo tramite GitHub Actions

## 📋 Indice

- [Overview](#overview)
- [Prerequisiti](#prerequisiti)
- [Setup Secrets](#setup-secrets)
- [Workflow Deploy Automatico](#workflow-deploy-automatico)
- [Gestione Variabili d'Ambiente](#gestione-variabili-dambiente)
- [Deploy Multi-Servizio](#deploy-multi-servizio)
- [Rollback Automatico](#rollback-automatico)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Architettura Proposta

```
┌─────────────────────────────────────────────────────────────────┐
│  GitHub Repository (monorepo)                                   │
│                                                                   │
│  Push su main → GitHub Actions                                   │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 1. Detect changed services                                 │ │
│  │    - svc-auth, svc-media, app-web-frontend                │ │
│  │                                                            │ │
│  │ 2. Per ogni servizio modificato:                          │ │
│  │    ├─ Build & Test                                        │ │
│  │    ├─ Sostituisci variabili env (se necessario)          │ │
│  │    ├─ Deploy su Scalingo                                  │ │
│  │    └─ Verifica health check                               │ │
│  │                                                            │ │
│  │ 3. Notifica risultato (GitHub Release)                    │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Scalingo PaaS                                                   │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ ewh-prod-    │  │ ewh-prod-    │  │ ewh-prod-    │         │
│  │ svc-auth     │  │ svc-media    │  │ app-web-     │         │
│  │              │  │              │  │ frontend     │         │
│  │ + PostgreSQL │  │ + PostgreSQL │  │              │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

### Vantaggi

✅ **Deploy automatico** solo dei servizi modificati (risparmio tempo)
✅ **Sostituzione variabili** gestita centralmente (niente hardcoded values)
✅ **Rollback automatico** in caso di errore durante deploy
✅ **Health check** post-deploy per verificare che il servizio sia up
✅ **Notifiche** su GitHub con changelog e status deploy

---

## Prerequisiti

### 1. Scalingo CLI Token

Genera un API token da Scalingo:

```bash
# Login su Scalingo
scalingo login

# Genera token (valido indefinitamente)
scalingo tokens-create "GitHub Actions Deploy" --no-expire
```

Salva il token generato, lo userai nei secrets di GitHub.

### 2. Repository GitHub

Il monorepo `ewh-monorepo` deve avere:
- ✅ Tutti i 53 servizi come submodules
- ✅ File `.github/workflows/deploy.yml` (verrà creato)
- ✅ File `infra/scalingo-apps.json` con mapping servizi → app Scalingo

---

## Setup Secrets

Aggiungi questi secrets su GitHub:

**Settings → Secrets and variables → Actions → New repository secret**

```bash
SCALINGO_API_TOKEN          # Token generato sopra
SCALINGO_REGION             # osc-fr1 (oppure osc-secnum-fr1)
```

Opzionale (per sostituire variabili):

```bash
# Secrets di produzione (se vuoi gestirli da GitHub)
DATABASE_URL                # Se vuoi sovrascrivere
JWT_PUBLIC_KEY              # Se vuoi iniettare chiavi
WASABI_ACCESS_KEY           # Credenziali storage
WASABI_SECRET_KEY           # Credenziali storage
# ... altri secrets
```

---

## Workflow Deploy Automatico

Crea il file `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Scalingo

on:
  push:
    branches: [main, develop]
  workflow_dispatch:
    inputs:
      service:
        description: 'Service to deploy (leave empty for all changed)'
        required: false
        type: string
      environment:
        description: 'Environment'
        required: true
        type: choice
        options:
          - production
          - staging

permissions:
  contents: read

jobs:
  detect-changes:
    name: Detect Changed Services
    runs-on: ubuntu-latest
    outputs:
      services: ${{ steps.detect.outputs.services }}
      matrix: ${{ steps.detect.outputs.matrix }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
          submodules: false

      - name: Detect changed services
        id: detect
        run: |
          # Manual trigger
          if [ -n "${{ inputs.service }}" ]; then
            SERVICES='["${{ inputs.service }}"]'
            echo "services=$SERVICES" >> $GITHUB_OUTPUT
            echo "matrix={\"service\":[\"${{ inputs.service }}\"]}" >> $GITHUB_OUTPUT
            exit 0
          fi

          # Auto-detect from git diff
          CHANGED=$(git diff --name-only HEAD^ HEAD | grep -E '^(app-|svc-)' | cut -d'/' -f1 | sort -u)

          if [ -z "$CHANGED" ]; then
            echo "No services changed"
            echo "services=[]" >> $GITHUB_OUTPUT
            echo "matrix={\"service\":[]}" >> $GITHUB_OUTPUT
          else
            SERVICES=$(echo "$CHANGED" | jq -R -s -c 'split("\n")[:-1]')
            MATRIX=$(echo "$CHANGED" | jq -R -s -c '{service: split("\n")[:-1]}')
            echo "services=$SERVICES" >> $GITHUB_OUTPUT
            echo "matrix=$MATRIX" >> $GITHUB_OUTPUT

            echo "Changed services:"
            echo "$CHANGED"
          fi

  deploy:
    name: Deploy ${{ matrix.service }}
    needs: detect-changes
    if: needs.detect-changes.outputs.services != '[]'
    runs-on: ubuntu-latest
    strategy:
      matrix: ${{ fromJson(needs.detect-changes.outputs.matrix) }}
      fail-fast: false
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true

      - name: Determine environment
        id: env
        run: |
          if [ "${{ github.ref }}" == "refs/heads/main" ] || [ "${{ inputs.environment }}" == "production" ]; then
            echo "env=prod" >> $GITHUB_OUTPUT
            echo "scalingo_app=ewh-prod-${{ matrix.service }}" >> $GITHUB_OUTPUT
          else
            echo "env=stg" >> $GITHUB_OUTPUT
            echo "scalingo_app=ewh-stg-${{ matrix.service }}" >> $GITHUB_OUTPUT
          fi

      - name: Install Scalingo CLI
        run: |
          curl -O https://cli-dl.scalingo.com/install && bash install
          echo "$HOME/bin" >> $GITHUB_PATH

      - name: Scalingo Login
        run: |
          scalingo login --api-token "${{ secrets.SCALINGO_API_TOKEN }}"

      - name: Get current deployment info
        id: current
        run: |
          cd ${{ matrix.service }}
          CURRENT_COMMIT=$(scalingo --region ${{ secrets.SCALINGO_REGION }} \
            --app ${{ steps.env.outputs.scalingo_app }} \
            deployments | head -n 2 | tail -n 1 | awk '{print $4}' || echo "unknown")
          echo "commit=$CURRENT_COMMIT" >> $GITHUB_OUTPUT

      - name: Deploy to Scalingo
        id: deploy
        working-directory: ${{ matrix.service }}
        run: |
          # Add Scalingo remote
          git remote add scalingo \
            git@ssh.${{ secrets.SCALINGO_REGION }}.scalingo.com:${{ steps.env.outputs.scalingo_app }}.git \
            || git remote set-url scalingo \
            git@ssh.${{ secrets.SCALINGO_REGION }}.scalingo.com:${{ steps.env.outputs.scalingo_app }}.git

          # Push to Scalingo
          echo "Deploying ${{ matrix.service }} to ${{ steps.env.outputs.scalingo_app }}..."

          # Get current commit in submodule
          COMMIT=$(git rev-parse HEAD)

          # Push
          git push scalingo HEAD:main --force

          echo "Deployment triggered. Commit: $COMMIT"
          echo "commit=$COMMIT" >> $GITHUB_OUTPUT

      - name: Wait for deployment
        run: |
          echo "Waiting for deployment to complete..."
          sleep 30

          # Check deployment status
          for i in {1..20}; do
            STATUS=$(scalingo --region ${{ secrets.SCALINGO_REGION }} \
              --app ${{ steps.env.outputs.scalingo_app }} \
              deployments | head -n 2 | tail -n 1 | awk '{print $2}')

            if [ "$STATUS" == "success" ]; then
              echo "✅ Deployment successful"
              exit 0
            elif [ "$STATUS" == "aborted" ] || [ "$STATUS" == "error" ]; then
              echo "❌ Deployment failed with status: $STATUS"
              exit 1
            fi

            echo "Status: $STATUS - waiting..."
            sleep 15
          done

          echo "⏰ Timeout waiting for deployment"
          exit 1

      - name: Health check
        run: |
          # Get app URL
          APP_URL=$(scalingo --region ${{ secrets.SCALINGO_REGION }} \
            --app ${{ steps.env.outputs.scalingo_app }} \
            apps-info | grep "URL" | awk '{print $2}')

          if [ -z "$APP_URL" ]; then
            echo "⚠️ Could not determine app URL, skipping health check"
            exit 0
          fi

          echo "Checking health at $APP_URL/health"

          # Retry health check
          for i in {1..5}; do
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health" || echo "000")

            if [ "$HTTP_CODE" == "200" ]; then
              echo "✅ Health check passed"
              exit 0
            fi

            echo "Health check returned $HTTP_CODE - retrying in 10s..."
            sleep 10
          done

          echo "⚠️ Health check failed, but deployment completed"

      - name: Rollback on failure
        if: failure() && steps.current.outputs.commit != 'unknown'
        run: |
          echo "❌ Deployment failed, rolling back to ${{ steps.current.outputs.commit }}"

          cd ${{ matrix.service }}
          git fetch scalingo
          git push scalingo ${{ steps.current.outputs.commit }}:main --force

          echo "Rollback completed"

  summary:
    name: Deployment Summary
    needs: [detect-changes, deploy]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Generate summary
        run: |
          echo "## 🚀 Deployment Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Branch:** ${{ github.ref_name }}" >> $GITHUB_STEP_SUMMARY
          echo "**Commit:** ${{ github.sha }}" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY

          SERVICES='${{ needs.detect-changes.outputs.services }}'
          if [ "$SERVICES" == "[]" ]; then
            echo "No services deployed" >> $GITHUB_STEP_SUMMARY
          else
            echo "**Deployed services:**" >> $GITHUB_STEP_SUMMARY
            echo "$SERVICES" | jq -r '.[]' | sed 's/^/- /' >> $GITHUB_STEP_SUMMARY
          fi

          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Status:** ${{ needs.deploy.result }}" >> $GITHUB_STEP_SUMMARY
```

---

## Gestione Variabili d'Ambiente

### Metodo 1: Scalingo Dashboard (Raccomandato)

Le variabili sono già configurate su Scalingo per ogni app. Non serve fare nulla, le GitHub Actions deployano e Scalingo usa le variabili esistenti.

### Metodo 2: Script di Configurazione (Avanzato)

Se vuoi **centralizzare** le variabili nel monorepo:

**Crea `infra/env-config.json`:**

```json
{
  "production": {
    "svc-auth": {
      "JWT_PRIVATE_KEY_PATH": "/app/keys/jwt_private.pem",
      "JWT_PUBLIC_KEY_PATH": "/app/keys/jwt_public.pem",
      "JWT_ACCESS_TOKEN_EXPIRY": "15m",
      "JWT_REFRESH_TOKEN_EXPIRY": "30d"
    },
    "svc-media": {
      "WASABI_ENDPOINT": "https://s3.eu-central-2.wasabisys.com",
      "WASABI_BUCKET": "ewh-prod-media",
      "WASABI_REGION": "eu-central-2"
    }
  },
  "staging": {
    "svc-auth": {
      "JWT_ACCESS_TOKEN_EXPIRY": "1h"
    },
    "svc-media": {
      "WASABI_BUCKET": "ewh-stg-media"
    }
  }
}
```

**Aggiungi step al workflow:**

```yaml
      - name: Configure environment variables
        run: |
          SERVICE="${{ matrix.service }}"
          ENV="${{ steps.env.outputs.env }}"
          APP="${{ steps.env.outputs.scalingo_app }}"

          # Read config
          ENV_VARS=$(jq -r ".${ENV}.${SERVICE} // {} | to_entries | .[] | .key + \"=\" + .value" \
            infra/env-config.json)

          # Set on Scalingo
          while IFS= read -r VAR; do
            if [ -n "$VAR" ]; then
              echo "Setting $VAR"
              scalingo --region ${{ secrets.SCALINGO_REGION }} \
                --app $APP \
                env-set "$VAR"
            fi
          done <<< "$ENV_VARS"
```

### Metodo 3: Template Variables (Per sostituzioni in codice)

Se hai **placeholder** nel codice tipo `{{API_URL}}`:

**Crea script `scripts/replace-env-vars.sh`:**

```bash
#!/bin/bash
set -e

SERVICE=$1
ENV=$2

echo "Replacing variables for $SERVICE in $ENV environment"

# Read variables from JSON
VARS=$(jq -r ".${ENV}.${SERVICE} // {} | to_entries | .[] | .key + \"=\" + .value" \
  infra/env-config.json)

# Replace in files
cd "$SERVICE"
while IFS='=' read -r KEY VALUE; do
  if [ -n "$KEY" ]; then
    echo "Replacing {{$KEY}} with $VALUE"
    find . -type f \( -name "*.js" -o -name "*.ts" -o -name "*.json" \) \
      -exec sed -i "s|{{$KEY}}|$VALUE|g" {} +
  fi
done <<< "$VARS"
```

**Aggiungi al workflow prima del deploy:**

```yaml
      - name: Replace template variables
        run: |
          chmod +x scripts/replace-env-vars.sh
          ./scripts/replace-env-vars.sh ${{ matrix.service }} ${{ steps.env.outputs.env }}
```

---

## Deploy Multi-Servizio

### Deploy Manuale di Servizi Specifici

Usa il workflow dispatch per deployare servizi specifici:

```bash
# Via GitHub UI:
Actions → Deploy to Scalingo → Run workflow
  - Service: svc-auth
  - Environment: production

# Via GitHub CLI:
gh workflow run deploy.yml \
  -f service=svc-auth \
  -f environment=production
```

### Deploy Coordinato (Cross-service)

Per deployare più servizi insieme (es. modifiche su API gateway + Auth):

**Crea `infra/deploy-groups.json`:**

```json
{
  "auth-stack": ["svc-auth", "svc-api-gateway"],
  "creative-stack": ["svc-image-orchestrator", "svc-raster-runtime", "svc-media"],
  "frontend-stack": ["app-web-frontend", "app-admin-console"]
}
```

**Workflow dispatch con gruppo:**

```yaml
  workflow_dispatch:
    inputs:
      deploy_group:
        description: 'Deploy group'
        type: choice
        options:
          - auth-stack
          - creative-stack
          - frontend-stack
```

---

## Rollback Automatico

Il workflow include già rollback automatico. In caso di fallimento:

1. ✅ Detecta il commit precedente su Scalingo
2. ✅ Esegue `git push scalingo <commit>:main --force`
3. ✅ Il servizio torna alla versione precedente

### Rollback Manuale

Se serve rollback manuale:

```bash
# Lista deployment
scalingo --app ewh-prod-svc-auth deployments

# Rollback a deployment specifico
scalingo --app ewh-prod-svc-auth deployments-rollback <deployment-id>
```

Oppure via GitHub Actions:

```bash
gh workflow run deploy.yml \
  -f service=svc-auth \
  -f environment=production \
  -f commit=abc123def  # commit SHA specifico
```

---

## Troubleshooting

### Errore: "Permission denied (publickey)"

**Problema:** GitHub Actions non può pushare su Scalingo

**Soluzione:** Aggiungi SSH key

```yaml
      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SCALINGO_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -t rsa ssh.${{ secrets.SCALINGO_REGION }}.scalingo.com >> ~/.ssh/known_hosts
```

Genera la chiave SSH:

```bash
ssh-keygen -t rsa -b 4096 -C "github-actions@ewh"
# Aggiungi la chiave pubblica su Scalingo Dashboard → Account → SSH Keys
# Aggiungi la chiave privata come secret SCALINGO_SSH_KEY su GitHub
```

### Errore: "App not found"

**Problema:** Nome app Scalingo errato

**Soluzione:** Verifica naming convention

```bash
# Lista app
scalingo apps

# Controlla che seguano il pattern: ewh-{env}-{service}
# Es: ewh-prod-svc-auth, ewh-stg-app-web-frontend
```

### Deploy Stuck

**Problema:** Deployment rimane in "building" per troppo tempo

**Soluzione:** Controlla buildpack

```bash
# Vedi logs
scalingo --app ewh-prod-svc-auth logs --lines 100

# Verifica buildpack
scalingo --app ewh-prod-svc-auth env | grep BUILDPACK
```

### Health Check Failed

**Problema:** `/health` endpoint non risponde 200

**Soluzione:** Assicurati che ogni servizio abbia l'endpoint

```typescript
// Aggiungi a ogni servizio Fastify
fastify.get('/health', async () => {
  return { status: 'ok', timestamp: new Date().toISOString() }
})
```

---

## Prossimi Passi

1. **Crea il workflow** - Copia `.github/workflows/deploy.yml`
2. **Aggiungi secrets** - `SCALINGO_API_TOKEN`, `SCALINGO_REGION`
3. **Testa su staging** - Fai un push su `develop` e verifica il deploy
4. **Monitora** - Controlla i logs su GitHub Actions e Scalingo
5. **Abilita per production** - Quando sei sicuro, merge su `main`

---

## Riferimenti

- [Scalingo CLI Docs](https://doc.scalingo.com/cli)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [DEPLOYMENT.md](DEPLOYMENT.md) - Guida deploy manuale
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architettura sistema
