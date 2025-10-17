# Standard Mandatori per la Piattaforma EWH
## Documento Ufficiale per Tutti i Collaboratori

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: OBBLIGATORIO PER TUTTI I SERVIZI E APPLICAZIONI

---

## 🎯 Executive Summary

Questo documento definisce gli **standard obbligatori** che TUTTI i servizi backend e le applicazioni frontend devono rispettare per garantire:

1. **Stabilità del sistema** - servizi che non crashano
2. **Integrazione con la Shell** - app visibili nell'interfaccia unificata
3. **Monitoraggio e debugging** - health check e logging standardizzati
4. **Deployment consistente** - configurazione PM2/Docker uniforme
5. **Developer experience** - sviluppo locale e remoto funzionante

---

## 📊 Audit della Situazione Attuale

### Problemi Identificati

#### 1. **Servizi Non Stabili**
- PM2 non installato/configurato correttamente
- Servizi crashano senza restart automatico
- Memory leak non gestiti
- Nessun limite di memoria configurato

#### 2. **App Non Integrate nelle Shell**
- File `services.config.ts` duplicato in più posizioni
  - `/tmp/services.config.ts`
  - `app-shell-frontend/src/lib/services.config.ts`
- Disallineamento tra configurazione e servizi reali
- Porte non documentate o in conflitto

#### 3. **Configurazione Inconsistente**
- **32 app** totali trovate
- **69 servizi** backend totali trovati
- Solo **8 servizi** nel file `ecosystem.macstudio.config.cjs`
- Mancano configurazioni per la maggior parte dei servizi

#### 4. **Health Check Mancanti**
- Molti servizi non hanno endpoint `/health`
- Shell non riesce a verificare lo stato dei servizi
- Bottom bar mostra "Checking Services..." costantemente

---

## 🏗️ Architettura Standard

### Struttura Monorepo

```
ewh/
├── app-*/              # Frontend applications (Next.js/Vite)
├── svc-*/              # Backend services (Express/Fastify)
├── shared/             # Codice condiviso
├── migrations/         # Database migrations
├── scripts/            # Script di automazione
├── ecosystem.macstudio.config.cjs  # PM2 config
└── services.config.ts  # SINGLE SOURCE OF TRUTH
```

---

## ✅ STANDARD MANDATORI

### 📦 1. BACKEND SERVICES (svc-*)

Ogni servizio backend **DEVE** implementare:

#### 1.1 Structure Obbligatoria

```
svc-example/
├── src/
│   ├── index.ts           # Entry point con health check
│   ├── routes/            # Route handlers
│   ├── db/
│   │   └── pool.ts       # Database connection
│   └── middleware/        # Express middleware
├── package.json           # Con script standard
├── tsconfig.json          # TypeScript config
├── .env.example           # Template variabili ambiente
└── README.md             # Documentazione del servizio
```

#### 1.2 Entry Point Standard (index.ts)

```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;
const SERVICE_NAME = process.env.SERVICE_NAME || 'svc-example';

// OBBLIGATORIO: Middleware di base
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN || '*', credentials: true }));
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// OBBLIGATORIO: Request logging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${req.method} ${req.path} ${res.statusCode} - ${duration}ms`);
  });
  next();
});

// OBBLIGATORIO: Health Check Endpoint
app.get('/health', async (req, res) => {
  try {
    // Se hai un database, testa la connessione
    // await pool.query('SELECT 1');

    res.json({
      service: SERVICE_NAME,
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: '1.0.0',
      // database: 'connected', // se applicabile
    });
  } catch (error) {
    res.status(503).json({
      service: SERVICE_NAME,
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

// OBBLIGATORIO: API Info Endpoint
app.get('/', (req, res) => {
  res.json({
    service: SERVICE_NAME,
    version: '1.0.0',
    description: 'Service description here',
    endpoints: {
      health: '/health',
      // list your main endpoints
    },
  });
});

// Le tue routes vanno qui
// app.use('/api/resource', resourceRoutes);

// OBBLIGATORIO: 404 Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path,
    service: SERVICE_NAME,
  });
});

// OBBLIGATORIO: Error Handler
app.use((err: any, req: any, res: any, next: any) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    service: SERVICE_NAME,
  });
});

// OBBLIGATORIO: Server startup con PM2 signal
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ ${SERVICE_NAME} running on port ${PORT}`);

  // OBBLIGATORIO per PM2
  if (process.send) {
    process.send('ready');
  }
});

// OBBLIGATORIO: Graceful shutdown
process.on('SIGINT', () => {
  console.log(`\n${SERVICE_NAME} shutting down...`);
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
```

#### 1.3 Package.json Obbligatorio

```json
{
  "name": "svc-example",
  "version": "1.0.0",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "eslint src"
  },
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.0",
    "@types/cors": "^2.8.0",
    "@types/compression": "^1.7.0",
    "tsx": "^4.0.0",
    "typescript": "^5.0.0"
  }
}
```

#### 1.4 Environment Variables Obbligatorie

File `.env.example`:
```bash
# OBBLIGATORIO
NODE_ENV=development
PORT=4000
SERVICE_NAME=svc-example

# OBBLIGATORIO se hai un database
DATABASE_URL=postgres://user:pass@localhost:5432/dbname

# OBBLIGATORIO se usi Redis
REDIS_URL=redis://localhost:6379/0

# OPZIONALE
CORS_ORIGIN=*
LOG_LEVEL=info
```

---

### 🎨 2. FRONTEND APPLICATIONS (app-*)

Ogni applicazione frontend **DEVE** implementare:

#### 2.1 Structure Obbligatoria

```
app-example-frontend/
├── src/
│   ├── pages/ (Next.js) o ├── App.tsx (Vite)
│   ├── components/
│   ├── lib/
│   │   └── config.ts      # Config locale (NON services.config.ts)
│   └── styles/
├── public/
├── package.json            # Con script standard
├── next.config.js (Next)   # Con configurazione standard
├── vite.config.ts (Vite)   # Con configurazione standard
├── .env.example            # Template variabili ambiente
└── README.md              # Documentazione dell'app
```

#### 2.2 Vite Config Standard

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,                    // OBBLIGATORIO: Porta univoca
    host: '0.0.0.0',              // OBBLIGATORIO: Per accesso remoto
    proxy: {                       // Se serve proxy verso backend
      '/api': {
        target: 'http://localhost:4000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,               // OBBLIGATORIO: Per debugging
  },
});
```

#### 2.3 Next.js Config Standard

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,           // OBBLIGATORIO

  // OBBLIGATORIO: Headers di sicurezza
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
```

#### 2.4 Package.json Obbligatorio

**Per Vite:**
```json
{
  "name": "app-example-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite --port 3000 --host",
    "build": "vite build",
    "preview": "vite preview",
    "lint": "eslint src"
  }
}
```

**Per Next.js:**
```json
{
  "name": "app-example-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint"
  }
}
```

#### 2.5 Environment Variables Obbligatorie

File `.env.example`:
```bash
# Vite apps (VITE_ prefix)
VITE_API_BASE_URL=http://localhost:4000
VITE_BACKEND_URL=http://localhost:4000

# Next.js apps (NEXT_PUBLIC_ prefix)
NEXT_PUBLIC_API_BASE_URL=http://localhost:4000
NEXT_PUBLIC_SERVICE_URL=http://localhost:4000
```

---

### 🔧 3. CONFIGURAZIONE PM2

#### 3.1 File ecosystem.macstudio.config.cjs

**TUTTI I SERVIZI** devono essere aggiunti qui:

```javascript
module.exports = {
  apps: [
    // Template per BACKEND SERVICE
    {
      name: 'svc-example',
      cwd: './svc-example',
      script: 'npx',
      args: 'tsx watch src/index.ts',
      env: {
        NODE_ENV: 'development',
        PORT: 4000,
        DATABASE_URL: 'postgres://ewh:ewhpass@localhost:5432/ewh_master',
        SERVICE_NAME: 'svc-example',
      },
      // OBBLIGATORIO: Stability settings
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      max_memory_restart: '512M',
      restart_delay: 3000,
      // OBBLIGATORIO: Logs
      error_file: './logs/svc-example-error.log',
      out_file: './logs/svc-example-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      // OBBLIGATORIO: Memory limit
      node_args: '--max-old-space-size=512',
      // OBBLIGATORIO: Health check
      wait_ready: true,
      listen_timeout: 10000,
    },

    // Template per FRONTEND APP (Vite)
    {
      name: 'app-example-frontend',
      cwd: './app-example-frontend',
      script: 'npm',
      args: 'run dev',
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
      },
      autorestart: true,
      max_restarts: 5,
      min_uptime: '10s',
      max_memory_restart: '1G',
      restart_delay: 5000,
      error_file: './logs/app-example-frontend-error.log',
      out_file: './logs/app-example-frontend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      node_args: '--max-old-space-size=1024',
      wait_ready: true,
      listen_timeout: 30000,
    },
  ]
};
```

#### 3.2 Regole per Memory Limits

| Tipo Servizio | Limit | Restart Threshold |
|---------------|-------|-------------------|
| Core Services (auth, gateway) | 512M | 512M |
| Business Services (pm, inventory) | 768M | 768M |
| Media Services (media, dam) | 1G | 768M |
| Frontend Apps (Next.js) | 1.5G | 1G |
| Frontend Apps (Vite) | 1G | 1G |

---

### 🗺️ 4. INTEGRAZIONE SHELL

#### 4.1 Single Source of Truth

**UNICO FILE** per la configurazione dei servizi:
- **Posizione**: `app-shell-frontend/src/lib/services.config.ts`
- **Altre copie**: Da eliminare o sincronizzare automaticamente

#### 4.2 Registrazione Nuova App

Per aggiungere una nuova app alla shell, aggiungi a `services.config.ts`:

```typescript
// In SERVICE_APPS array
{
  id: 'my-new-app',                    // OBBLIGATORIO: ID univoco
  name: 'My App',                      // OBBLIGATORIO: Nome visualizzato
  icon: 'Package',                     // OBBLIGATORIO: Icona Lucide React
  url: 'http://localhost:3100',        // OBBLIGATORIO: URL completo
  description: 'What this app does',   // OBBLIGATORIO: Descrizione
  categoryId: 'business',              // OBBLIGATORIO: Una delle categorie esistenti
  requiresAuth: true,                  // OBBLIGATORIO: true nella maggior parte dei casi
  roles: ['USER'],                     // OPZIONALE: Ruoli richiesti
},
```

#### 4.3 Categorie Disponibili

- `projects` - Project Management & Collaboration
- `content` - Content Management & Publishing
- `media` - Digital Asset Management
- `workflow` - Approvals & Collaboration
- `design` - Visual Design Tools
- `business` - Orders, Inventory & Operations
- `communications` - Voice, Email, Messaging & CRM

#### 4.4 Settings Panel (Opzionale)

Se la tua app ha un pannello settings, aggiungi a `SETTINGS_PANELS`:

```typescript
{
  id: 'my-app-settings',
  name: 'My App Settings',
  icon: 'Settings',
  url: 'http://localhost:3100/settings',
  description: 'Configure my app',
  serviceId: 'my-new-app',           // Collega all'app principale
  requiresAuth: true,
  roles: ['TENANT_ADMIN', 'PLATFORM_ADMIN', 'OWNER'],
  level: 'tenant',                   // platform | tenant | user
},
```

---

### 📝 5. ALLOCAZIONE PORTE

#### 5.1 Range Porte Riservate

| Range | Uso |
|-------|-----|
| 3000-3999 | Frontend Applications |
| 4000-4999 | Core Backend Services |
| 5000-5999 | Business Backend Services |
| 6000-6999 | Business Backend Services (extended) |
| 7000-7999 | Utility Services |
| 8000-8999 | Reserved |
| 9000-9999 | External Services (Minio, etc) |

#### 5.2 Porte Già Allocate

Consulta sempre il file `PORT_ALLOCATION.md` prima di scegliere una porta!

**Core Services:**
- 3150: app-shell-frontend
- 4000: svc-api-gateway
- 4001: svc-auth
- 4003: svc-media

**Example Apps:**
- 3200: app-admin-frontend
- 3300: app-dam
- 3350: app-box-designer
- 3400: app-pm-frontend
- 5700: app-inventory-frontend
- 5800: app-procurement-frontend
- 5801: app-previz-frontend

---

### 📚 6. DOCUMENTAZIONE OBBLIGATORIA

#### 6.1 README.md per ogni servizio/app

```markdown
# Service/App Name

## Descrizione
Breve descrizione di cosa fa questo servizio/app.

## Porte
- DEV: 3000
- PROD: TBD

## Environment Variables
```bash
PORT=3000
DATABASE_URL=postgres://...
```

## Dipendenze Esterne
- PostgreSQL (porta 5432)
- Redis (porta 6379) [se applicabile]

## API Endpoints
- `GET /health` - Health check
- `GET /` - Service info
- [Altri endpoint principali]

## Come Avviare

### Sviluppo Locale
```bash
npm install
npm run dev
```

### Con PM2
```bash
pm2 start ecosystem.macstudio.config.cjs --only service-name
```

## Testing
```bash
npm test
```

## Troubleshooting
- Problema comune 1 -> Soluzione
- Problema comune 2 -> Soluzione
```

---

## 🚀 PROCESSO DI DEPLOYMENT

### Sviluppo Nuovo Servizio/App

1. **Crea la struttura** seguendo gli standard sopra
2. **Implementa health check** (`/health` endpoint)
3. **Testa localmente** (`npm run dev`)
4. **Aggiungi a PM2 config** (`ecosystem.macstudio.config.cjs`)
5. **Aggiungi a services.config.ts** (se è un'app frontend)
6. **Documenta in README.md**
7. **Aggiorna PORT_ALLOCATION.md**
8. **Testa con PM2** (`pm2 start ecosystem.macstudio.config.cjs --only nome-servizio`)
9. **Verifica nella shell** (se frontend)
10. **Commit e push**

### Checklist Pre-Commit

- [ ] Health check endpoint implementato e testato
- [ ] Environment variables documentate in `.env.example`
- [ ] Porta univoca allocata e documentata
- [ ] PM2 config aggiunto/aggiornato
- [ ] services.config.ts aggiornato (se frontend)
- [ ] README.md completo
- [ ] Logs configurati correttamente
- [ ] Memory limits impostati
- [ ] Graceful shutdown implementato
- [ ] Error handling implementato
- [ ] CORS configurato correttamente

---

## 🔍 SISTEMA DI VALIDAZIONE

### Script di Validazione Automatica

Usa lo script di validazione prima di ogni commit:

```bash
./scripts/validate-service.sh svc-example
./scripts/validate-app.sh app-example-frontend
```

Lo script verifica:
- [ ] Presenza file obbligatori
- [ ] Health check endpoint funzionante
- [ ] Configurazione PM2 presente
- [ ] Porta non in conflitto
- [ ] Environment variables documentate
- [ ] README.md presente e completo

---

## 🆘 TROUBLESHOOTING

### Servizio non parte con PM2

1. Verifica health check: `curl http://localhost:PORT/health`
2. Controlla logs: `tail -f logs/service-name-error.log`
3. Verifica porta libera: `lsof -i :PORT`
4. Controlla database: `psql -U ewh -d ewh_master -c "SELECT 1"`

### App non appare nella Shell

1. Verifica `services.config.ts` in `app-shell-frontend/src/lib/`
2. Controlla che l'URL sia corretto
3. Verifica che la porta sia in ascolto: `lsof -i :PORT`
4. Riavvia la shell: `pm2 restart app-shell-frontend`
5. Controlla console browser (F12) per errori CORS

### Memory Issues

1. Verifica usage: `pm2 monit`
2. Aumenta limite in `ecosystem.macstudio.config.cjs`
3. Controlla memory leaks nel codice
4. Abilita `--max-old-space-size` appropriato

---

## 📞 SUPPORTO

### Per Domande

1. Consulta prima questo documento
2. Verifica `PORT_ALLOCATION.md`
3. Leggi il README del servizio specifico
4. Chiedi nel canale #platform-dev

### Per Bug o Problemi

1. Raccogli logs: `pm2 logs service-name --lines 100`
2. Verifica health check: `curl http://localhost:PORT/health`
3. Documenta i passaggi per riprodurre
4. Apri issue su GitHub con template

---

## 📈 METRICHE E MONITORAGGIO

### Health Check Monitoring

La shell controlla automaticamente ogni 30 secondi:
- Status di ogni servizio registrato
- Tempo di risposta
- Uptime

### Logs Centralizzati

Tutti i logs vanno in `./logs/` con formato standard:
```
[YYYY-MM-DD HH:mm:ss] [SERVICE_NAME] [LEVEL] Message
```

### PM2 Monitoring

```bash
pm2 monit              # Dashboard interattiva
pm2 list               # Lista servizi
pm2 logs service-name  # Logs in real-time
pm2 describe service   # Info dettagliate
```

---

## ✅ SUMMARY CHECKLIST

### Per Backend Services (svc-*)
- [ ] Health check `/health` endpoint
- [ ] Service info `/` endpoint
- [ ] Graceful shutdown (SIGINT)
- [ ] PM2 ready signal (`process.send('ready')`)
- [ ] Request logging middleware
- [ ] Error handling middleware
- [ ] Environment variables in `.env.example`
- [ ] README.md completo
- [ ] Aggiunto a `ecosystem.macstudio.config.cjs`
- [ ] Memory limits configurati

### Per Frontend Apps (app-*)
- [ ] Porta univoca configurata
- [ ] Host `0.0.0.0` per accesso remoto
- [ ] Sourcemaps abilitati
- [ ] Environment variables in `.env.example`
- [ ] README.md completo
- [ ] Aggiunto a `ecosystem.macstudio.config.cjs`
- [ ] Aggiunto a `services.config.ts` in shell
- [ ] Memory limits configurati
- [ ] Icona e descrizione appropriati

---

## 🎓 RISORSE UTILI

- [PM2 Documentation](https://pm2.keymetrics.io/docs/usage/quick-start/)
- [Express Best Practices](https://expressjs.com/en/advanced/best-practice-performance.html)
- [Vite Configuration](https://vitejs.dev/config/)
- [Next.js Configuration](https://nextjs.org/docs/api-reference/next.config.js/introduction)

---

**Questo documento è OBBLIGATORIO per tutti i collaboratori.**
**Non creare nuovi servizi o app senza seguire questi standard.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team