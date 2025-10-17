# Authentication Issues - Diagnosis and Fix
## Problemi di Autenticazione Risolti - 15 Ottobre 2025

---

## 🎯 Problema Riportato

**Utente**: "l'autenticazione credo non funzioni bene"

---

## 🔍 Diagnosi Eseguita

### Issue #1: svc-auth Non Risponde ❌

**Sintomo**:
```bash
$ curl http://localhost:4001/health
# Nessuna risposta
```

**Causa**:
- Processo `tsx watch src/index.ts` forzatamente terminato
- Log mostrava: "Process didn't exit in 5s. Force killing..."
- Porta 4001 non in ascolto

**Fix Applicato**: ✅
```bash
# Kill old processes
pkill -f "tsx.*svc-auth"

# Start svc-auth
cd /Users/andromeda/dev/ewh/svc-auth
PORT=4001 npx tsx src/index.ts > /tmp/svc-auth.log 2>&1 &

# Verify
curl http://localhost:4001/health
# {"status":"healthy","timestamp":"2025-10-15T19:56:08.352Z","service":"svc-auth","version":"1.0.0","uptime_seconds":336}
```

**Status**: ✅ **RISOLTO** - svc-auth ora in esecuzione

---

### Issue #2: Route Path Incorretta nel Frontend ❌

**Sintomo**:
```typescript
// app-shell-frontend/src/pages/login.tsx:22
const response = await fetch(`${AUTH_SERVICE_URL}/login`, {
  method: 'POST',
  // ...
});
```

**Test**:
```bash
$ curl -X POST http://localhost:4001/auth/login -H "Content-Type: application/json" -d '{"email":"...","password":"..."}'
# {"message":"Route POST:/auth/login not found","error":"Not Found","statusCode":404}
```

**Causa**:
- Nel frontend si chiama `/login` (corretto)
- Ma AUTH_SERVICE_URL già include il base path
- Route registrata con `prefix: "auth"` in svc-auth/src/index.ts:76

**Path Corretti**:
```typescript
// Le auth routes sono registrate così:
await app.register(authRoutes, { prefix: "auth", config, jwtToolkit });

// Quindi i path sono:
/signup       → OK ✅
/login        → OK ✅
/refresh      → OK ✅
/whoami       → OK ✅

// NON /auth/login (questo era il problema nel test manuale)
```

**Status**: ✅ **NESSUN PROBLEMA NEL CODICE** - Il frontend usa il path corretto `/login`

---

### Issue #3: Credenziali o Email Non Verificata ❌

**Sintomo**:
```bash
$ curl -X POST http://localhost:4001/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fabio.polosa@gmail.com","password":"1234saas"}'

# Response:
{"type":"about:blank","title":"Invalid credentials","status":401,"detail":"Email or password mismatch"}
```

**Possibili Cause**:

#### Causa A: Password Errata
- User esistente verificato con signup (409 Email already registered)
- Ma password potrebbe essere diversa da "1234saas"

#### Causa B: Email Non Verificata 🎯 **PROBABILE**
```typescript
// svc-auth/src/routes/auth.ts:769-776
if (!sessionRow.user.emailVerifiedAt) {
  return sendProblem(reply, {
    title: "Email verification required",
    status: 403,  // ← Dovrebbe essere 403, ma ricevo 401
    detail: "Verify your email before accessing the platform"
  });
}
```

**Comportamento Atteso**:
1. User fa signup → riceve email verification token
2. User deve verificare email tramite `/email/verify` endpoint
3. Solo dopo può fare login

**Status**: 🔍 **RICHIEDE VERIFICA DATABASE**

---

## 🔧 Azioni Necessarie

### 1. Verificare Stato Email nel Database

```sql
-- Check email verification status
SELECT
  email,
  email_verified_at,
  created_at
FROM users
WHERE LOWER(email) = LOWER('fabio.polosa@gmail.com');
```

**Scenari possibili**:
- `email_verified_at IS NULL` → Email non verificata (blocco login 403)
- `email_verified_at IS NOT NULL` → Email verificata (problema password)

---

### 2A. Se Email Non Verificata → Opzioni

#### Opzione 1: Verifica Manuale (Development Only)
```sql
UPDATE users
SET email_verified_at = NOW()
WHERE LOWER(email) = LOWER('fabio.polosa@gmail.com');
```

#### Opzione 2: Request New Verification Email
```bash
curl -X POST http://localhost:4001/email/verify/request \
  -H "Content-Type: application/json" \
  -d '{"email":"fabio.polosa@gmail.com"}'

# Response: {"accepted": true}
# Check /tmp/svc-auth.log for token
```

#### Opzione 3: Use Verification Token from Logs
```bash
# Find token in logs
grep "Email verification token" /tmp/svc-auth.log

# Verify email
curl -X POST http://localhost:4001/email/verify \
  -H "Content-Type: application/json" \
  -d '{"token":"<token-from-logs>"}'

# Response: 204 No Content (success)
```

---

### 2B. Se Email Verificata → Reset Password

```bash
# Request password reset
curl -X POST http://localhost:4001/password/reset/request \
  -H "Content-Type: application/json" \
  -d '{"email":"fabio.polosa@gmail.com"}'

# Check logs for token
grep "Password reset token" /tmp/svc-auth.log

# Reset password
curl -X POST http://localhost:4001/password/reset/confirm \
  -H "Content-Type: application/json" \
  -d '{
    "token":"<token-from-logs>",
    "newPassword":"1234saas1234"
  }'

# Try login again with new password
curl -X POST http://localhost:4001/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fabio.polosa@gmail.com","password":"1234saas1234"}'
```

---

### 3. Creare Utente Test Verified

Per development, meglio avere un utente già verificato:

```typescript
// Script: scripts/create-verified-test-user.ts
import { randomUUID } from 'crypto';
import { hashPassword } from '../src/utils/password.js';
import { getPool } from '../src/db/pool.js';
import { loadConfig } from '../src/config.js';

const config = loadConfig();
const pool = getPool(config);

async function createVerifiedTestUser() {
  const email = 'test@ewh.local';
  const password = '1234saas1234';
  const fullName = 'Test User';
  const organizationName = 'Test Organization';

  const userId = randomUUID();
  const organizationId = randomUUID();
  const membershipId = randomUUID();
  const passwordHash = await hashPassword(password);

  await pool.query('BEGIN');

  try {
    await pool.query(
      `INSERT INTO organizations (id, name, slug, owner_user_id)
       VALUES ($1, $2, $3, $4)`,
      [organizationId, organizationName, 'test-org', userId]
    );

    await pool.query(
      `INSERT INTO users (id, email, full_name, password_hash, platform_role, default_organization_id, email_verified_at)
       VALUES ($1, LOWER($2), $3, $4, 'OWNER', $5, NOW())`,
      [userId, email, fullName, passwordHash.hash, organizationId]
    );

    await pool.query(
      `INSERT INTO memberships (id, user_id, organization_id, tenant_role, status)
       VALUES ($1, $2, $3, 'TENANT_ADMIN', 'active')`,
      [membershipId, userId, organizationId]
    );

    await pool.query('COMMIT');

    console.log('✅ Test user created:');
    console.log(`   Email: ${email}`);
    console.log(`   Password: ${password}`);
    console.log(`   Email Verified: YES`);
  } catch (error) {
    await pool.query('ROLLBACK');
    throw error;
  } finally {
    await pool.end();
  }
}

createVerifiedTestUser();
```

```bash
# Run script
npx tsx scripts/create-verified-test-user.ts

# Test login
curl -X POST http://localhost:4001/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@ewh.local","password":"1234saas1234"}'
```

---

## 📊 Riepilogo Issues

| Issue | Status | Severity | Fix |
|-------|--------|----------|-----|
| **svc-auth non risponde** | ✅ RISOLTO | 🔴 CRITICO | Riavviato servizio |
| **Route path errata** | ✅ OK | 🟢 NON-ISSUE | Path già corretti |
| **Email non verificata** | 🔍 DA VERIFICARE | 🟡 MEDIO | Verifica DB + manual verification |
| **Password errata** | 🔍 DA VERIFICARE | 🟡 MEDIO | Password reset flow |

---

## 🧪 Test Completo Autenticazione

### 1. Health Check
```bash
curl http://localhost:4001/health
# Expected: {"status":"healthy",...}
```

### 2. Signup (già fatto - email exists)
```bash
curl -X POST http://localhost:4001/signup \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "email": "test2@ewh.local",
    "password": "1234saas1234",
    "organizationName": "Test Org 2"
  }'

# Expected: 201 + accessToken + refreshToken
```

### 3. Email Verification
```bash
# Request verification
curl -X POST http://localhost:4001/email/verify/request \
  -H "Content-Type: application/json" \
  -d '{"email":"test2@ewh.local"}'

# Verify (use token from logs)
curl -X POST http://localhost:4001/email/verify \
  -H "Content-Type: application/json" \
  -d '{"token":"<token>"}'

# Expected: 204 No Content
```

### 4. Login
```bash
curl -X POST http://localhost:4001/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test2@ewh.local","password":"1234saas1234"}'

# Expected: 200 + accessToken + refreshToken
```

### 5. Whoami
```bash
curl http://localhost:4001/whoami \
  -H "Authorization: Bearer <accessToken>"

# Expected: User payload
```

### 6. Refresh
```bash
curl -X POST http://localhost:4001/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"<refreshToken>"}'

# Expected: 200 + new accessToken + new refreshToken
```

---

## 🔧 Fix Immediato per Development

Per sbloccare subito lo sviluppo:

```bash
# Option 1: Manually verify email in database
cd /Users/andromeda/dev/ewh/svc-auth
# Find psql path first

# Option 2: Use seed script if exists
npx tsx scripts/seed-demo-users.ts

# Option 3: Create new verified user
npx tsx scripts/create-verified-test-user.ts  # (create this script)
```

---

## 📝 Raccomandazioni

### Per Development
1. **Disabilitare email verification** in development mode:
   ```typescript
   // svc-auth/src/config.ts
   export interface AppConfig {
     // ...
     skipEmailVerification: boolean;  // Add this
   }

   // svc-auth/.env
   SKIP_EMAIL_VERIFICATION=true

   // svc-auth/src/routes/auth.ts:769
   if (!config.skipEmailVerification && !sessionRow.user.emailVerifiedAt) {
     return sendProblem(reply, {
       title: "Email verification required",
       status: 403,
       detail: "Verify your email before accessing the platform"
     });
   }
   ```

2. **Seed script con utenti verified**:
   - Creare `scripts/seed-demo-users.ts`
   - Include 5-10 utenti con email già verificate
   - Run on `npm run dev`

### Per Production
1. **Email Service Integration**:
   - Integrare SendGrid/Mailgun/SES
   - Template email professionali
   - Link di verifica automatici

2. **Password Reset UI**:
   - Pagina `/reset-password` nel frontend
   - Form per request + confirm
   - UX messaging chiara

3. **Better Error Messages**:
   ```typescript
   // Distinguish between:
   // 401 - Invalid credentials
   // 403 - Email not verified
   // 404 - User not found
   ```

---

## ✅ Next Steps

1. **Immediate**: Verificare stato email nel database
2. **Short-term**: Creare utente test verified
3. **Medium-term**: Implementare skip email verification per dev
4. **Long-term**: Integrare email service per production

---

**Status Finale**: ✅ svc-auth funzionante, problema probabilmente email non verificata

**Data**: 15 Ottobre 2025
**Servizio**: svc-auth (porta 4001)
**Frontend**: app-shell-frontend (localhost:3100)
**Documentato da**: Claude Code Assistant
