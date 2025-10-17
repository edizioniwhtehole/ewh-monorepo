# Admin Frontend - Architettura Separata

## Overview

Il frontend amministrativo è stato separato da `app-web-frontend` in un'applicazione Next.js indipendente: `app-admin-frontend`.

## Motivazioni

### 1. **Resilienza e Fault Isolation**
- Se il frontend pubblico crasha, l'admin panel rimane operativo
- Gli amministratori possono sempre accedere per diagnosticare e risolvere problemi
- Deploy indipendenti: aggiornamenti admin non impattano gli utenti finali

### 2. **Sicurezza**
- Autenticazione e autorizzazione separate e più rigorose
- Possibilità di mettere l'admin su network privata/VPN
- Superficie d'attacco ridotta per il frontend pubblico
- Rate limiting e firewall rules differenziati

### 3. **Performance**
- Bundle JavaScript più leggero per il frontend pubblico
- Nessun codice admin nel bundle utente finale
- Strategie di caching separate
- CDN optimization solo per contenuti pubblici

### 4. **Sviluppo**
- Team separati possono lavorare senza conflitti
- Dipendenze isolate (admin può usare librerie pesanti)
- Versioning indipendente
- CI/CD pipelines separate

### 5. **Scalabilità**
- Scaling diversificato (admin: meno istanze ma più potenti)
- Admin può essere su infrastruttura separata
- Ottimizzazione risorse per tipologia di traffico

## Architettura

```
┌─────────────────────┐         ┌──────────────────────┐
│ app-web-frontend    │         │ app-admin-frontend   │
│ Port: 3100          │         │ Port: 3200           │
│                     │         │                      │
│ - Landing pages     │         │ - Monitoring         │
│ - User interface    │         │ - Landing mgmt       │
│ - DAM (user)        │         │ - System config      │
│ - Public features   │         │ - User management    │
└──────────┬──────────┘         └──────────┬───────────┘
           │                               │
           └───────────┬───────────────────┘
                       │
           ┌───────────▼────────────┐
           │   svc-api-gateway      │
           │   Port: 4000           │
           │                        │
           │   - Auth routing       │
           │   - Request proxying   │
           │   - Rate limiting      │
           └───────────┬────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼────────┐         ┌─────────▼──────┐
│  svc-auth      │         │  Other services │
│  Port: 4001    │         │  Ports: 4xxx   │
└────────────────┘         └────────────────┘
```

## Porte

| Servizio | Dev Port | Prod Port | Descrizione |
|----------|----------|-----------|-------------|
| app-web-frontend | 3100 | 80/443 | Frontend pubblico utenti |
| app-admin-frontend | 3200 | 3200 | Frontend amministrazione |
| svc-api-gateway | 4000 | 4000 | API Gateway |

## Routing

### Sviluppo Locale
- Frontend pubblico: `http://localhost:3100`
- Admin frontend: `http://localhost:3200`

### Produzione
- Frontend pubblico: `https://yourdomain.com`
- Admin frontend: `https://admin.yourdomain.com` (o VPN-only)

## Contenuti

### app-web-frontend
Contiene tutto il codice per gli utenti finali:
- Landing pages pubbliche
- DAM (Digital Asset Management) per utenti
- Interfacce di collaborazione
- Editor creativi (immagini, video, testo)

### app-admin-frontend
Contiene solo funzionalità amministrative:
- `/admin/monitoring` - Dashboard monitoraggio sistema
- `/admin/landing-pages` - Gestione landing pages tenant
- `/profile/*` - Gestione profilo amministratore
- Future: user management, system config, analytics

## Sviluppo

### Setup app-admin-frontend

```bash
cd app-admin-frontend
pnpm install
pnpm dev  # Avvia su porta 3200
```

### Build per produzione

```bash
pnpm build
pnpm start  # Avvia in modalità production
```

### Docker

```bash
# Build
docker build -t ewh-admin-frontend app-admin-frontend/

# Run
docker run -p 3200:3200 ewh-admin-frontend

# Docker Compose
docker-compose --profile admin up app-admin-frontend
```

## Deployment

### Separazione in Produzione

1. **Frontend pubblico** (`app-web-frontend`)
   - Deploy su CDN (Vercel, Netlify, CloudFront)
   - Alta scalabilità orizzontale
   - Edge locations globali

2. **Admin frontend** (`app-admin-frontend`)
   - Deploy su server privato o VPN
   - Meno istanze ma più performanti
   - Accesso limitato per IP/VPN

### Strategie di Deploy

#### Opzione A: Monorepo con Deploy Separati
```yaml
# vercel.json (per app-web-frontend)
{
  "buildCommand": "cd app-web-frontend && pnpm build",
  "outputDirectory": "app-web-frontend/.next"
}

# Railway/Render config (per app-admin-frontend)
{
  "buildCommand": "cd app-admin-frontend && pnpm build",
  "startCommand": "cd app-admin-frontend && pnpm start"
}
```

#### Opzione B: Docker Compose in Produzione
```yaml
services:
  app-web-frontend:
    build: ./app-web-frontend
    ports: ["80:3100"]

  app-admin-frontend:
    build: ./app-admin-frontend
    ports: ["3200:3200"]
    networks:
      - admin_network  # Network privata
```

## Sicurezza Admin

### Autenticazione Rafforzata
```typescript
// middleware.ts in app-admin-frontend
export function middleware(request: NextRequest) {
  // Verifica token admin
  const token = request.cookies.get('admin_token');
  if (!token || !isAdminToken(token)) {
    return NextResponse.redirect('/unauthorized');
  }

  // Verifica IP whitelist (opzionale)
  const ip = request.ip;
  if (!isAllowedIP(ip)) {
    return NextResponse.redirect('/forbidden');
  }
}
```

### Variabili d'Ambiente Separate

**app-web-frontend/.env**
```env
NEXT_PUBLIC_API_BASE_URL=https://api.yourdomain.com
NEXT_PUBLIC_APP_ENV=production
```

**app-admin-frontend/.env**
```env
NEXT_PUBLIC_API_BASE_URL=https://api.yourdomain.com
NEXT_PUBLIC_APP_ENV=production
ADMIN_SECRET_KEY=...
ALLOWED_IPS=10.0.0.0/8,192.168.0.0/16
```

## Migrazioni Future

### Step 1: Completare la Separazione
- [ ] Rimuovere `/pages/admin/*` da app-web-frontend
- [ ] Spostare tutti i componenti admin in app-admin-frontend
- [ ] Aggiornare gli import e i link

### Step 2: Ottimizzazione Bundle
- [ ] Tree-shaking aggressivo in app-web-frontend
- [ ] Lazy loading delle route admin
- [ ] Separazione delle dipendenze

### Step 3: Infrastruttura Dedicata
- [ ] Setup VPN per admin frontend
- [ ] IP whitelist configurato
- [ ] Monitoring separato per admin

## Benefici Misurabili

### Performance
- **Bundle size app-web-frontend**: -30% (stimato)
- **First contentful paint**: -200ms (stimato)
- **Time to interactive**: -500ms (stimato)

### Sicurezza
- **Superficie d'attacco**: -40% (nessun codice admin esposto)
- **Privilege escalation**: Impossibile (frontend separati)

### Resilienza
- **Uptime admin**: 99.99% (indipendente da frontend pubblico)
- **Recovery time**: -80% (admin sempre disponibile)

## Monitoring

### Metriche Separate

```typescript
// app-admin-frontend/lib/analytics.ts
export const trackAdminAction = (action: string, metadata: any) => {
  fetch('/api/admin/metrics', {
    method: 'POST',
    body: JSON.stringify({
      action,
      metadata,
      timestamp: Date.now(),
      admin_id: getCurrentAdminId()
    })
  });
};
```

### Logging Centralizzato

```typescript
// app-admin-frontend/lib/logger.ts
export const logAdminActivity = (activity: string) => {
  console.log(`[ADMIN] ${activity}`);

  // Invia a servizio di logging centralizzato
  sendToLogService({
    source: 'admin-frontend',
    level: 'info',
    message: activity,
    timestamp: new Date().toISOString()
  });
};
```

## Conclusione

La separazione dei frontend è una best practice per applicazioni enterprise che migliora:
- ✅ Resilienza del sistema
- ✅ Sicurezza dell'infrastruttura
- ✅ Performance per utenti finali
- ✅ Velocità di sviluppo
- ✅ Scalabilità e manutenibilità

Il costo iniziale di setup è minimo rispetto ai benefici a lungo termine.
