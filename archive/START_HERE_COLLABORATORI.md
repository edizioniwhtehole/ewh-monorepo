# 👋 Benvenuto nella Piattaforma EWH

## Inizia da Qui!

Se sei un nuovo collaboratore o un developer che vuole contribuire, **leggi questo documento prima di scrivere codice**.

---

## 📚 Documentazione Obbligatoria (in ordine)

### 1. [QUICK_START_COLLABORATORI.md](./QUICK_START_COLLABORATORI.md) ⭐ INIZIA QUI
**Tempo di lettura**: 10 minuti
**Cosa impari**:
- Come creare un nuovo servizio/app in 15 minuti
- Workflow standard per sviluppo
- Comandi essenziali PM2
- Troubleshooting comune

**Quando leggerlo**: PRIMA di scrivere qualsiasi codice

### 2. [PLATFORM_MANDATORY_STANDARDS.md](./PLATFORM_MANDATORY_STANDARDS.md) ⚠️ OBBLIGATORIO
**Tempo di lettura**: 30 minuti
**Cosa impari**:
- Standard tecnici mandatori per TUTTI i servizi
- Template completi per backend e frontend
- Configurazione PM2 richiesta
- Health check implementation
- Integrazione con la Shell
- Allocazione porte

**Quando leggerlo**: Mentre sviluppi, come riferimento continuo

### 3. [AUDIT_REPORT_15_OCT_2025.md](./AUDIT_REPORT_15_OCT_2025.md) 📊 CONTEXT
**Tempo di lettura**: 15 minuti
**Cosa impari**:
- Perché esistono questi standard
- Problemi identificati nella piattaforma
- Piano di remediation
- Metriche di successo

**Quando leggerlo**: Per capire il contesto e le decisioni

---

## ⚡ Quick Start (5 Minuti)

### Se devi creare un BACKEND SERVICE:

```bash
# 1. Leggi il template
less PLATFORM_MANDATORY_STANDARDS.md
# Vai alla sezione "1.2 Entry Point Standard (index.ts)"

# 2. Crea la struttura
mkdir svc-my-service
cd svc-my-service
npm init -y
npm install express cors helmet compression dotenv
npm install -D tsx typescript @types/express @types/cors

# 3. Copia il template da PLATFORM_MANDATORY_STANDARDS.md
# nel file src/index.ts

# 4. Testa
npm run dev

# 5. Valida
cd ..
./scripts/validate-service.sh svc-my-service
```

### Se devi creare una FRONTEND APP:

```bash
# 1. Scegli framework (Vite o Next.js)
# Vite (consigliato per nuove app):
npm create vite@latest app-my-app -- --template react-ts

# Next.js (se serve SSR):
npx create-next-app@latest app-my-app --typescript --tailwind

# 2. Configura seguendo template in PLATFORM_MANDATORY_STANDARDS.md
cd app-my-app
# Modifica vite.config.ts o next.config.js

# 3. Testa
npm run dev

# 4. Valida
cd ..
./scripts/validate-app.sh app-my-app
```

---

## 🎯 Checklist Prima del Commit

**Stampa questa checklist e tienila sulla scrivania!**

### Per BACKEND Services
```
□ Health check /health implementato
□ Health check risponde: curl http://localhost:PORT/health
□ Graceful shutdown (SIGINT) implementato
□ PM2 ready signal presente
□ Aggiunto a ecosystem.macstudio.config.cjs
□ Memory limits configurati
□ .env.example completo
□ README.md completo
□ ./scripts/validate-service.sh passa ✅
□ Porta documentata in PORT_ALLOCATION.md
```

### Per FRONTEND Apps
```
□ Porta univoca configurata
□ Host impostato a 0.0.0.0
□ Sourcemaps abilitati
□ Aggiunto a ecosystem.macstudio.config.cjs
□ Aggiunto a app-shell-frontend/src/lib/services.config.ts
□ .env.example completo
□ README.md completo
□ ./scripts/validate-app.sh passa ✅
□ Porta documentata in PORT_ALLOCATION.md
□ Testato in browser
```

---

## 🚨 Regole d'Oro (ZERO Eccezioni)

### 1. Health Check Obbligatorio
```typescript
app.get('/health', async (req, res) => {
  res.json({
    service: SERVICE_NAME,
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});
```

### 2. PM2 Config Obbligatorio
Ogni servizio/app DEVE essere in `ecosystem.macstudio.config.cjs`

### 3. Shell Integration Obbligatoria (Frontend)
Ogni app frontend DEVE essere in `app-shell-frontend/src/lib/services.config.ts`

### 4. Validation Passa
```bash
./scripts/validate-service.sh <nome> # DEVE passare
./scripts/validate-app.sh <nome>     # DEVE passare
```

### 5. README Completo
Ogni servizio/app DEVE avere README con:
- Descrizione
- Porte
- Environment variables
- Come avviare
- Troubleshooting

---

## 🛠️ Tools Essenziali

### Script di Validazione
```bash
# Valida backend service
./scripts/validate-service.sh svc-example

# Valida frontend app
./scripts/validate-app.sh app-example-frontend
```

### Comandi PM2 Essenziali
```bash
# Avvia servizio
pm2 start ecosystem.macstudio.config.cjs --only service-name

# Status
pm2 list

# Logs
pm2 logs service-name

# Monitoring
pm2 monit

# Restart
pm2 restart service-name

# Stop
pm2 stop service-name
```

### Debugging
```bash
# Porta in uso?
lsof -i :PORT

# Database ok?
psql -U ewh -d ewh_master -c "SELECT 1"

# Redis ok?
redis-cli ping

# Health check?
curl http://localhost:PORT/health
```

---

## 📞 Help & Support

### Prima di Chiedere Aiuto

1. ✓ Ho letto `QUICK_START_COLLABORATORI.md`?
2. ✓ Ho consultato `PLATFORM_MANDATORY_STANDARDS.md`?
3. ✓ Ho eseguito lo script di validazione?
4. ✓ Ho controllato i logs con `pm2 logs`?
5. ✓ Ho verificato health check con `curl`?

### Dove Chiedere

- **Platform issues**: #platform-dev
- **Frontend issues**: #frontend-dev
- **Backend issues**: #backend-dev
- **Urgenze**: @platform-team

### Come Chiedere

```markdown
**Problema**: Descrizione breve
**Servizio**: svc-example o app-example-frontend
**Cosa ho provato**:
1. ...
2. ...

**Logs**:
```
pm2 logs service-name --lines 50
```

**Health check**:
```
curl -v http://localhost:PORT/health
```

**Script di validazione**:
```
./scripts/validate-service.sh service-name
```
```

---

## 🎓 Best Practices Highlight

### Logging
```typescript
// ✅ BUONO
console.log(`[${SERVICE_NAME}] ${req.method} ${req.path} - ${duration}ms`);

// ❌ CATTIVO
console.log('request');
```

### Error Handling
```typescript
// ✅ BUONO
try {
  await operation();
} catch (error) {
  console.error(`[${SERVICE_NAME}] Error:`, error);
  res.status(500).json({
    error: error.message,
    service: SERVICE_NAME
  });
}

// ❌ CATTIVO
const result = await operation(); // può crashare!
```

### Environment Variables
```typescript
// ✅ BUONO
const PORT = process.env.PORT || 4000;

// ❌ CATTIVO
const PORT = process.env.PORT; // undefined se manca!
```

---

## 📈 Progressione del Developer

### Livello 1: Onboarding (Giorno 1)
- [x] Letto `QUICK_START_COLLABORATORI.md`
- [ ] Creato primo servizio di test
- [ ] Script di validazione passa
- [ ] Servizio avviato con PM2

### Livello 2: Autonomo (Settimana 1)
- [ ] Creato servizio reale per feature
- [ ] Integrato app in shell (se frontend)
- [ ] README completo scritto
- [ ] Commits passano validation

### Livello 3: Esperto (Mese 1)
- [ ] Contribuito a migliorare standard
- [ ] Aiutato altri developer
- [ ] Zero validation errors nei commits
- [ ] Services stabili in produzione

---

## 🎯 Obiettivi della Piattaforma

### Metriche Target (Fine Ottobre 2025)
- **Uptime**: 99%+
- **Services con PM2**: 100%
- **Services con health check**: 100%
- **Apps in shell**: 100%
- **Time to onboard**: <1 ora
- **Crashes per giorno**: <1

### Come Contribuire
Ogni developer contribuisce a questi obiettivi:
- Seguendo gli standard ✅
- Validando il proprio codice ✅
- Documentando i propri servizi ✅
- Aiutando i colleghi ✅

---

## 📁 Struttura Repository

```
ewh/
├── 📄 START_HERE_COLLABORATORI.md           ← SEI QUI
├── 📄 QUICK_START_COLLABORATORI.md          ← Leggi per primo
├── 📄 PLATFORM_MANDATORY_STANDARDS.md       ← Reference continuo
├── 📄 AUDIT_REPORT_15_OCT_2025.md          ← Context
├── 📄 PORT_ALLOCATION.md                    ← Registro porte
│
├── 📁 app-*/                                ← Frontend Applications
│   ├── app-shell-frontend/                  ← Shell principale
│   ├── app-box-designer/
│   ├── app-pm-frontend/
│   └── ...
│
├── 📁 svc-*/                                ← Backend Services
│   ├── svc-api-gateway/
│   ├── svc-auth/
│   ├── svc-box-designer/
│   └── ...
│
├── 📁 scripts/                              ← Automation scripts
│   ├── validate-service.sh                  ← Valida backend
│   ├── validate-app.sh                      ← Valida frontend
│   └── ...
│
├── 📁 shared/                               ← Shared code
├── 📁 migrations/                           ← DB migrations
└── ecosystem.macstudio.config.cjs          ← PM2 config master
```

---

## 🚀 Pronto per Iniziare?

### Next Steps:

1. **Leggi** [QUICK_START_COLLABORATORI.md](./QUICK_START_COLLABORATORI.md) (10 min)
2. **Consulta** [PLATFORM_MANDATORY_STANDARDS.md](./PLATFORM_MANDATORY_STANDARDS.md) (come reference)
3. **Crea** il tuo primo servizio/app seguendo i template
4. **Valida** con gli script (`./scripts/validate-*.sh`)
5. **Testa** con PM2 (`pm2 start ecosystem.macstudio.config.cjs --only nome`)
6. **Commit** solo dopo che validation passa ✅

---

## ✨ Tips Finali

- **Non reinventare la ruota**: usa i template forniti
- **Valida sempre**: gli script sono tuoi amici
- **Documenta tutto**: il README è obbligatorio
- **Chiedi aiuto**: meglio chiedere che bloccarsi
- **Segui gli standard**: zero eccezioni

---

**Benvenuto nel team! 🎉**

Insieme costruiremo una piattaforma stabile, scalabile e facile da mantenere.

**Questions?** Chiedi in #platform-dev

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team
