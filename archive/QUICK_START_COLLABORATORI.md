# 🚀 Guida Rapida per Collaboratori EWH
## Come Sviluppare Servizi e App Stabili

**Benvenuto nel team!** Questa guida ti porterà da zero a produttivo in 15 minuti.

---

## 📋 Prerequisiti

Prima di iniziare, assicurati di avere:

- [ ] Node.js 18+ installato
- [ ] PostgreSQL in esecuzione (porta 5432)
- [ ] Redis in esecuzione (porta 6379)
- [ ] Git configurato
- [ ] Accesso alla repository `ewh`

---

## 🎯 Workflow Standard

### 1. Prima di Scrivere Codice

```bash
# 1. Leggi gli standard mandatori
cat PLATFORM_MANDATORY_STANDARDS.md

# 2. Controlla le porte disponibili
cat PORT_ALLOCATION.md

# 3. Scegli una porta libera per il tuo servizio/app
# Range: 3000-3999 per frontend, 4000-6999 per backend
```

### 2. Creare un Nuovo Backend Service

```bash
# 1. Crea la directory
mkdir svc-example
cd svc-example

# 2. Inizializza npm
npm init -y

# 3. Installa dipendenze
npm install express cors helmet compression dotenv
npm install -D tsx typescript @types/express @types/cors @types/compression

# 4. Crea la struttura
mkdir -p src/routes
touch src/index.ts
touch tsconfig.json
touch .env.example
touch README.md

# 5. Copia il template standard da PLATFORM_MANDATORY_STANDARDS.md
# Sezione "1.2 Entry Point Standard (index.ts)"

# 6. Configura le variabili ambiente
cat > .env.example << 'EOF'
NODE_ENV=development
PORT=4100
SERVICE_NAME=svc-example
DATABASE_URL=postgres://ewh:ewhpass@localhost:5432/ewh_master
REDIS_URL=redis://localhost:6379/0
CORS_ORIGIN=*
EOF

# 7. Aggiungi script al package.json
npm pkg set scripts.dev="tsx watch src/index.ts"
npm pkg set scripts.build="tsc"
npm pkg set scripts.start="node dist/index.js"

# 8. Crea tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
EOF

# 9. Testa in locale
npm run dev

# 10. Verifica health check
curl http://localhost:4100/health
```

### 3. Creare una Nuova Frontend App (Vite)

```bash
# 1. Crea app con Vite
npm create vite@latest app-example-frontend -- --template react-ts
cd app-example-frontend

# 2. Configura vite.config.ts
cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3100,
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: 'http://localhost:4100',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
});
EOF

# 3. Crea .env.example
cat > .env.example << 'EOF'
VITE_API_BASE_URL=http://localhost:4100
VITE_BACKEND_URL=http://localhost:4100
EOF

# 4. Testa in locale
npm run dev

# 5. Verifica che l'app sia accessibile
open http://localhost:3100
```

### 4. Creare una Nuova Frontend App (Next.js)

```bash
# 1. Crea app con Next.js
npx create-next-app@latest app-example-frontend --typescript --tailwind --app
cd app-example-frontend

# 2. Configura next.config.js
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
EOF

# 3. Modifica package.json per usare porta specifica
npm pkg set scripts.dev="next dev -p 3100"
npm pkg set scripts.start="next start -p 3100"

# 4. Crea .env.example
cat > .env.example << 'EOF'
NEXT_PUBLIC_API_BASE_URL=http://localhost:4100
NEXT_PUBLIC_SERVICE_URL=http://localhost:4100
EOF

# 5. Testa in locale
npm run dev

# 6. Verifica che l'app sia accessibile
open http://localhost:3100
```

---

## 🔧 Integrare con il Sistema

### 5. Aggiungere al PM2 Config

```bash
cd /Users/andromeda/dev/ewh

# Apri il file di configurazione PM2
code ecosystem.macstudio.config.cjs

# Aggiungi il tuo servizio/app seguendo il template
# Vedi PLATFORM_MANDATORY_STANDARDS.md sezione "3.1 File ecosystem.macstudio.config.cjs"
```

**Template per Backend Service:**
```javascript
{
  name: 'svc-example',
  cwd: './svc-example',
  script: 'npx',
  args: 'tsx watch src/index.ts',
  env: {
    NODE_ENV: 'development',
    PORT: 4100,
    DATABASE_URL: 'postgres://ewh:ewhpass@localhost:5432/ewh_master',
    SERVICE_NAME: 'svc-example',
  },
  autorestart: true,
  max_restarts: 10,
  min_uptime: '10s',
  max_memory_restart: '512M',
  restart_delay: 3000,
  error_file: './logs/svc-example-error.log',
  out_file: './logs/svc-example-out.log',
  log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
  merge_logs: true,
  node_args: '--max-old-space-size=512',
  wait_ready: true,
  listen_timeout: 10000,
},
```

### 6. Registrare l'App nella Shell (Solo Frontend)

```bash
# Apri il file di configurazione della shell
code app-shell-frontend/src/lib/services.config.ts

# Aggiungi la tua app nell'array SERVICE_APPS
```

**Template:**
```typescript
{
  id: 'my-app',
  name: 'My Application',
  icon: 'Package',  // Icona da lucide-react
  url: 'http://localhost:3100',
  description: 'Description of what this app does',
  categoryId: 'business',  // projects|content|media|workflow|design|business|communications
  requiresAuth: true,
  roles: ['USER'],  // opzionale
},
```

---

## ✅ Validare il Tuo Lavoro

### 7. Eseguire Validazione Automatica

```bash
cd /Users/andromeda/dev/ewh

# Per backend services
./scripts/validate-service.sh svc-example

# Per frontend apps
./scripts/validate-app.sh app-example-frontend
```

Lo script controllerà:
- ✓ Struttura directory corretta
- ✓ File obbligatori presenti
- ✓ Health check implementato
- ✓ PM2 config presente
- ✓ Integrazione shell (frontend)
- ✓ Environment variables documentate
- ✓ README completo

### 8. Testare con PM2

```bash
# Avvia solo il tuo servizio/app
pm2 start ecosystem.macstudio.config.cjs --only svc-example

# Verifica lo stato
pm2 list

# Guarda i logs
pm2 logs svc-example

# Monitora
pm2 monit

# Riavvia se necessario
pm2 restart svc-example

# Ferma quando hai finito
pm2 stop svc-example
```

---

## 🐛 Debugging e Troubleshooting

### Servizio Non Parte

```bash
# 1. Verifica che la porta sia libera
lsof -i :4100

# 2. Controlla i logs
pm2 logs svc-example --lines 50

# 3. Prova ad avviare manualmente
cd svc-example
npm run dev

# 4. Verifica database
psql -U ewh -d ewh_master -c "SELECT 1"

# 5. Verifica Redis
redis-cli ping
```

### App Non Appare nella Shell

```bash
# 1. Verifica che l'app sia registrata in services.config.ts
grep -A 5 "my-app" app-shell-frontend/src/lib/services.config.ts

# 2. Verifica che la porta sia corretta
curl http://localhost:3100

# 3. Riavvia la shell
pm2 restart app-shell-frontend

# 4. Controlla console browser (F12) per errori CORS
```

### Health Check Non Funziona

```bash
# 1. Verifica endpoint
curl -v http://localhost:4100/health

# 2. Controlla il codice
grep -A 10 "/health" svc-example/src/index.ts

# 3. Verifica che il server invii il segnale ready
grep "process.send" svc-example/src/index.ts
```

---

## 📝 Checklist Pre-Commit

Prima di fare commit, verifica:

### Backend Service
- [ ] `npm run dev` funziona senza errori
- [ ] `curl http://localhost:PORT/health` ritorna status 200
- [ ] `.env.example` contiene tutte le variabili
- [ ] `README.md` è completo
- [ ] Aggiunto a `ecosystem.macstudio.config.cjs`
- [ ] Porta documentata in `PORT_ALLOCATION.md`
- [ ] `./scripts/validate-service.sh svc-name` passa
- [ ] Graceful shutdown implementato (SIGINT)
- [ ] PM2 ready signal presente (`process.send('ready')`)

### Frontend App
- [ ] `npm run dev` funziona senza errori
- [ ] App visibile in browser su `http://localhost:PORT`
- [ ] `.env.example` contiene tutte le variabili
- [ ] `README.md` è completo
- [ ] Aggiunto a `ecosystem.macstudio.config.cjs`
- [ ] Aggiunto a `app-shell-frontend/src/lib/services.config.ts`
- [ ] Porta documentata in `PORT_ALLOCATION.md`
- [ ] `./scripts/validate-app.sh app-name` passa
- [ ] Host impostato a `0.0.0.0` (per accesso remoto)
- [ ] Sourcemaps abilitati

---

## 🎓 Best Practices

### 1. Logging
```typescript
// ✓ BUONO - Structured logging
console.log(`[${SERVICE_NAME}] ${req.method} ${req.path} - ${duration}ms`);

// ✗ CATTIVO - Non informativo
console.log('request');
```

### 2. Error Handling
```typescript
// ✓ BUONO - Error handling appropriato
try {
  await someOperation();
} catch (error) {
  console.error('[SERVICE_NAME] Error:', error);
  res.status(500).json({
    error: error instanceof Error ? error.message : 'Unknown error',
    service: SERVICE_NAME,
  });
}

// ✗ CATTIVO - Errori non gestiti
const result = await someOperation(); // può crashare!
```

### 3. Environment Variables
```typescript
// ✓ BUONO - Default values
const PORT = process.env.PORT || 4000;

// ✗ CATTIVO - No defaults, può crashare
const PORT = process.env.PORT;
```

### 4. Health Checks
```typescript
// ✓ BUONO - Verifica connessioni
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1'); // testa DB
    res.json({ status: 'healthy', database: 'connected' });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy' });
  }
});

// ✗ CATTIVO - Health check finto
app.get('/health', (req, res) => {
  res.json({ status: 'ok' }); // non verifica nulla!
});
```

---

## 📚 Risorse Utili

### Documentazione Interna
- **[PLATFORM_MANDATORY_STANDARDS.md](./PLATFORM_MANDATORY_STANDARDS.md)** - Standard completi e dettagliati
- **[PORT_ALLOCATION.md](./PORT_ALLOCATION.md)** - Mappa delle porte allocate
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Architettura della piattaforma

### Script Utili
```bash
# Validazione
./scripts/validate-service.sh <service-name>
./scripts/validate-app.sh <app-name>

# Status sistema
pm2 list
pm2 monit

# Logs
pm2 logs <name>
pm2 logs <name> --lines 100

# Restart
pm2 restart <name>
pm2 restart all
```

### Comandi Frequenti

```bash
# Vedere tutti i processi
pm2 list

# Avviare tutto
pm2 start ecosystem.macstudio.config.cjs

# Fermare tutto
pm2 stop all

# Riavviare tutto
pm2 restart all

# Vedere logs in tempo reale
pm2 logs --raw

# Salvare configurazione PM2
pm2 save

# Monitorare risorse
pm2 monit

# Informazioni dettagliate
pm2 describe <service-name>
```

---

## 🆘 Chiedi Aiuto

### In caso di problemi:

1. **Consulta prima la documentazione**
   - `PLATFORM_MANDATORY_STANDARDS.md`
   - `PORT_ALLOCATION.md`
   - Il README del servizio specifico

2. **Esegui gli script di validazione**
   ```bash
   ./scripts/validate-service.sh svc-name
   ./scripts/validate-app.sh app-name
   ```

3. **Raccogli informazioni**
   ```bash
   pm2 logs service-name --lines 100 > debug.log
   curl -v http://localhost:PORT/health >> debug.log
   ```

4. **Chiedi nel canale appropriato**
   - #platform-dev - Problemi di piattaforma
   - #frontend-dev - Problemi frontend
   - #backend-dev - Problemi backend

---

## 🎯 Esempi Reali

Guarda questi servizi come riferimento:

### Backend Service Completo
```bash
# Esempio ben fatto
cat svc-box-designer/src/index.ts
```

### Frontend App Vite
```bash
# Esempio ben fatto
cat app-box-designer/vite.config.ts
```

### Frontend App Next.js
```bash
# Esempio ben fatto
cat app-shell-frontend/next.config.js
```

---

## ✨ Tips & Tricks

### Sviluppo Veloce
```bash
# Auto-restart quando cambi codice
npm run dev

# Avvia solo ciò che ti serve
pm2 start ecosystem.macstudio.config.cjs --only service1,service2

# Logs in tempo reale con filtro
pm2 logs | grep ERROR
```

### Debugging
```bash
# Port in uso?
lsof -i :PORT

# Processo in esecuzione?
ps aux | grep node | grep service-name

# Database raggiungibile?
psql -U ewh -d ewh_master -c "SELECT 1"

# Redis raggiungibile?
redis-cli ping
```

### Performance
```bash
# Monitora memoria
pm2 monit

# Vedi stats
pm2 list

# Reset restart counter
pm2 reset <name>
```

---

**Buon lavoro! 🚀**

Per domande o suggerimenti su questa guida, apri una issue o contatta il Platform Team.

**Ultimo aggiornamento**: 15 Ottobre 2025