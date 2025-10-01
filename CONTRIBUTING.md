# Contributing to EWH Platform

> Grazie per voler contribuire alla piattaforma EWH! Questa guida ti aiuterà a iniziare.

## 📋 Indice

- [Codice di Condotta](#codice-di-condotta)
- [Come Contribuire](#come-contribuire)
- [Workflow Git](#workflow-git)
- [Standard Codice](#standard-codice)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Documentazione](#documentazione)

---

## Codice di Condotta

### Principi

- **Rispetto**: Tratta tutti i membri del team con rispetto e professionalità
- **Collaborazione**: Lavoriamo insieme per costruire il miglior prodotto possibile
- **Trasparenza**: Comunica chiaramente e frequentemente
- **Qualità**: Scrivi codice pulito, testato e documentato
- **Sicurezza**: Non committare mai secrets o dati sensibili

### Comportamenti Non Accettati

- Linguaggio offensivo o discriminatorio
- Commit di secrets/credentials
- Deploy non autorizzati su production
- Modifiche breaking senza discussione preventiva

---

## Come Contribuire

### Tipi di Contributi

1. **Bug Fix** - Correggi bug esistenti
2. **Feature** - Aggiungi nuove funzionalità
3. **Refactoring** - Migliora codice esistente senza cambiare comportamento
4. **Documentazione** - Migliora o aggiungi documentazione
5. **Testing** - Aggiungi o migliora test
6. **Performance** - Ottimizza performance

### Prima di Iniziare

1. **Verifica che il bug/feature non sia già in lavorazione**
   - Controlla GitHub Issues
   - Chiedi nel canale Slack #dev

2. **Crea una issue se non esiste**
   ```bash
   # Crea issue su GitHub
   gh issue create --title "Bug: auth token expires too soon" \
     --body "Describe the bug..." \
     --label bug
   ```

3. **Assegnati la issue**
   ```bash
   gh issue develop 123 --checkout
   ```

---

## Workflow Git

### Branch Strategy

```
main          ← Production (protetto, richiede PR + review)
  ↑
  └─ develop  ← Staging (protetto, richiede PR)
       ↑
       ├─ feature/oauth-support     ← Nuove feature
       ├─ fix/token-expiration      ← Bug fix
       ├─ refactor/auth-module      ← Refactoring
       └─ docs/api-documentation    ← Documentazione
```

### Creare Feature Branch

```bash
# Da develop
git checkout develop
git pull origin develop

# Crea branch
git checkout -b feature/oauth-support

# Oppure usa gh CLI
gh issue develop 123 --checkout  # Crea branch da issue
```

### Naming Convention Branches

```
feature/<short-description>    # Nuove feature
fix/<short-description>        # Bug fix
refactor/<component-name>      # Refactoring
docs/<section-name>            # Documentazione
test/<component-name>          # Aggiungi test
hotfix/<critical-bug>          # Emergency fix
```

**Esempi:**
```
feature/oauth-google
fix/token-expiration
refactor/database-pool
docs/api-reference
test/auth-endpoints
hotfix/critical-auth-bypass
```

---

## Standard Codice

### TypeScript

**Configurazione tsconfig.json:**
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16"
  }
}
```

**Buone Pratiche:**
```typescript
// ✅ Buono: Type-safe, explicit return
async function getUser(id: string): Promise<User | null> {
  const result = await db.query<User>(
    'SELECT * FROM users WHERE id = $1',
    [id]
  );
  return result.rows[0] ?? null;
}

// ❌ Male: any, no return type
async function getUser(id) {
  const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
  return result.rows[0];
}
```

### Validazione Input (Zod)

**Sempre validare input utente:**
```typescript
import { z } from 'zod';

const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).regex(/[A-Z]/).regex(/[0-9]/),
  organization_name: z.string().min(2).max(100)
});

app.post('/auth/signup', async (request, reply) => {
  try {
    const data = signupSchema.parse(request.body);
    // ... business logic ...
  } catch (error) {
    if (error instanceof z.ZodError) {
      return reply.code(400).send({
        error: 'Validation error',
        details: error.errors
      });
    }
    throw error;
  }
});
```

### Error Handling

**Pattern standard per gestione errori:**
```typescript
import { match } from 'ts-pattern';

try {
  const user = await createUser(data);
  return reply.code(201).send({ user });
} catch (error) {
  // Pattern matching per error handling
  return match(error)
    .when(
      (e) => e.code === '23505', // Postgres unique violation
      () => reply.code(409).send({ error: 'Email already exists' })
    )
    .when(
      (e) => e.code === '23503', // Foreign key violation
      () => reply.code(400).send({ error: 'Invalid reference' })
    )
    .otherwise(() => {
      app.log.error({ error, correlationId: request.id }, 'Unexpected error');
      return reply.code(500).send({ error: 'Internal server error' });
    });
}
```

### Logging

**Structured logging con pino:**
```typescript
// ✅ Buono: Structured, context-aware
app.log.info({
  correlationId: request.headers['x-correlation-id'],
  tenantId: request.user.org_id,
  userId: request.user.sub,
  action: 'order.created',
  orderId: order.id
}, 'Order created successfully');

// ❌ Male: String logging senza context
app.log.info('Order created');
```

### Database

**Sempre usa parametrizzazione:**
```typescript
// ✅ Buono: Parametrizzato (SQL injection safe)
const users = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// ❌ Male: Concatenazione (SQL injection vulnerability!)
const users = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
);
```

**Transazioni per operazioni multiple:**
```typescript
const client = await pool.connect();
try {
  await client.query('BEGIN');

  const order = await client.query(
    'INSERT INTO orders (...) VALUES (...) RETURNING *'
  );

  await client.query(
    'UPDATE inventory SET quantity = quantity - $1 WHERE product_id = $2',
    [quantity, productId]
  );

  await client.query('COMMIT');
  return order.rows[0];
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}
```

---

## Commit Guidelines

### Formato

Usa [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Descrizione | Esempio |
|------|-------------|---------|
| `feat` | Nuova feature | `feat(auth): add OAuth2 Google provider` |
| `fix` | Bug fix | `fix(orders): prevent negative quantity` |
| `docs` | Documentazione | `docs(readme): update setup instructions` |
| `style` | Formattazione (no logic change) | `style(auth): format code with prettier` |
| `refactor` | Refactoring | `refactor(db): extract connection pool` |
| `test` | Aggiungi/modifica test | `test(auth): add signup validation tests` |
| `chore` | Maintenance | `chore(deps): update fastify to 4.28` |
| `perf` | Performance | `perf(queries): add index on user_id` |

### Scope

Opzionale, indica il modulo modificato:
```
auth, orders, media, billing, api-gateway, etc.
```

### Subject

- Usa imperativo presente: "add" non "added" o "adds"
- Non capitalizzare prima lettera
- No punto finale
- Max 72 caratteri

### Body (Opzionale)

- Spiega **perché** non **cosa** (il codice spiega il "cosa")
- Wrapped a 72 caratteri
- Separato da subject con blank line

### Footer (Opzionale)

- Breaking changes: `BREAKING CHANGE: <description>`
- Issue reference: `Closes #123`, `Fixes #456`

### Esempi

**Buoni commit:**
```bash
feat(auth): add OAuth2 support for Google

Implements OAuth2 authentication flow using Google Identity Platform.
Users can now sign in with their Google account instead of creating
a new password.

Closes #234
```

```bash
fix(orders): prevent order creation with negative quantity

Adds validation to ensure quantity is always positive. Previously,
negative quantities would cause inventory to increase incorrectly.

Fixes #456
```

```bash
refactor(database): extract connection pool to separate module

Moves database connection logic to db/pool.ts for better testability
and reusability across services.
```

**Cattivi commit:**
```bash
# ❌ Male: non descriptive
fix bug

# ❌ Male: troppo vago
updated code

# ❌ Male: multiple unrelated changes
feat: add OAuth, fix bugs, update docs

# ❌ Male: capitals and period
Fix: Added new feature.
```

---

## Pull Request Process

### 1. Pre-PR Checklist

Prima di aprire PR, verifica:

- [ ] **Tests passano**: `pnpm test`
- [ ] **Build OK**: `pnpm build`
- [ ] **Linter OK**: `pnpm lint` (se configurato)
- [ ] **Nessun secret committato**: verifica `.env`, keys, passwords
- [ ] **Branch aggiornato**: `git pull origin develop`
- [ ] **Commits puliti**: considera `git rebase -i` se necessario

### 2. Creare Pull Request

```bash
# Via GitHub CLI (raccomandato)
gh pr create \
  --base develop \
  --title "feat(auth): add OAuth2 Google support" \
  --body "Implements OAuth2 flow. Closes #234"

# Oppure via web su GitHub
```

### 3. Descrizione PR

**Template:**
```markdown
## Summary
Brief description of what this PR does.

## Changes
- Added OAuth2 Google authentication
- Updated auth routes to support OAuth flow
- Added tests for OAuth endpoints

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass on local
- [ ] Manually tested on staging

## Screenshots (if UI changes)
[Add screenshots here]

## Breaking Changes
List any breaking changes and migration steps.

## Checklist
- [x] Tests pass
- [x] Documentation updated
- [x] No secrets committed
- [x] Changelog updated (if applicable)

Closes #234
```

### 4. Code Review

**Come Reviewer:**
- Leggi attentamente il codice
- Testa localmente se possibile
- Dai feedback costruttivo
- Approva se tutto OK

**Come Author:**
- Rispondi a tutti i commenti
- Fai requested changes
- Re-request review dopo modifiche

### 5. Merge

**Dopo approvazione:**
```bash
# Squash merge (raccomandato per feature branch)
gh pr merge 123 --squash

# Merge commit (per develop → main)
gh pr merge 456 --merge

# Rebase (se linear history preferito)
gh pr merge 789 --rebase
```

**Auto-deploy:**
- Merge su `develop` → auto-deploy su staging Scalingo
- Merge su `main` → auto-deploy su production Scalingo

---

## Documentazione

### Dove Documentare

| Tipo | Dove | Esempio |
|------|------|---------|
| **Architettura generale** | `ARCHITECTURE.md` | Overview sistema, stack tech |
| **Setup & workflow dev** | `DEVELOPMENT.md` | Come sviluppare localmente |
| **Deploy & ops** | `DEPLOYMENT.md` | Come deployare su Scalingo |
| **API endpoints** | `svc-*/README.md` | Documentazione API servizio |
| **Funzioni/classi** | JSDoc nel codice | Documentazione inline |
| **Decisioni architetturali** | ADR (TODO) | Architecture Decision Records |

### JSDoc Standard

```typescript
/**
 * Creates a new user and organization (self-service signup).
 *
 * @param data - User signup data containing email, password, and org name
 * @returns Created user with organization membership
 * @throws {ConflictError} If email already exists
 * @throws {ValidationError} If data is invalid
 *
 * @example
 * const user = await createUser({
 *   email: 'john@example.com',
 *   password: 'SecurePass123!',
 *   organization_name: 'Acme Corp'
 * });
 */
async function createUser(data: SignupData): Promise<User> {
  // Implementation...
}
```

### README per Servizi

Ogni servizio dovrebbe avere `README.md` con:

```markdown
# svc-service-name

Brief description of service responsibility.

## API Endpoints

### POST /resource
Description, request/response examples.

## Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| PORT | Yes | HTTP port | 4000 |
| DATABASE_URL | Yes | PostgreSQL connection | - |

## Development

\`\`\`bash
pnpm install
pnpm run dev
\`\`\`

## Testing

\`\`\`bash
pnpm test
\`\`\`
```

---

## Domande Frequenti

### Come aggiungo una nuova dipendenza?

```bash
cd svc-auth
pnpm add <package>          # Dependency
pnpm add -D <package>       # Dev dependency
git commit -m "chore(deps): add <package>"
```

### Come faccio rollback di una migration?

```bash
cd svc-auth
npm run migrate:down  # Rollback ultima migration
```

### Come testo modifiche cross-service?

```bash
# Avvia servizi coinvolti con Docker Compose
cd compose
docker-compose -f docker-compose.dev.yml up svc-auth svc-api-gateway

# Test manualmente o con script
curl http://localhost:4000/...
```

### Come gestisco secrets in development?

```bash
# Usa .env locale (gitignored)
cp .env.example .env
# Popola con valori di sviluppo (non production!)
```

### Come propongo una breaking change?

1. Apri issue per discussione preventiva
2. Documenta migration path in PR description
3. Update CHANGELOG.md
4. Commit message: `BREAKING CHANGE: <description>`

---

## Supporto

- **Slack**: #dev (domande generali), #help (supporto)
- **GitHub Issues**: Per bug report e feature request
- **Email**: dev@ewhsaas.it (per questioni private)

---

**Grazie per contribuire a EWH Platform! 🚀**
