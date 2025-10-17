# PM System - Adaptive Mode Architecture

## 🎯 Concept: Single User ↔ Team Seamless Transition

Il sistema deve permettere transizioni fluide tra modalità single-user e team **senza perdita dati**.

---

## 📊 Scenari Reali

### Scenario 1: Scale Up (Single → Team)
```
Giorno 1:  Freelancer Mario lavora da solo
           ✅ Single-user mode, no login

Giorno 30: Mario assume 2 collaboratori
           ✅ Abilita Team Mode
           ✅ Crea account per Sara e Luca
           ✅ Tutti i progetti di Mario rimangono intatti
           ✅ Può assegnare nuovi task a Sara/Luca
```

### Scenario 2: Downsize (Team → Single)
```
Giorno 1:  Team di 5 persone con 20 progetti attivi
           ✅ Team mode con login

Giorno 60: Riorganizzazione, restano solo 2 persone
           ✅ Disabilita 3 utenti (soft-delete)
           ✅ Storico task assegnati rimane visibile
           ✅ Può tornare a Single-user se vuole
```

### Scenario 3: Progetti Temporanei
```
Progetto X: Team di 8 persone per 6 mesi
            ✅ Team mode attivo

Fine progetto: Team si scioglie
               ✅ Disabilita utenti (soft-delete)
               ✅ Storico completo conservato
               ✅ Possiamo vedere chi ha fatto cosa
```

---

## 🏗️ Architettura Unificata

### 1. Database: Sempre Multi-User Ready

**Tabella `users`** (sempre presente, anche in single-user):

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  password_hash TEXT,              -- NULL = no password (default user)
  role VARCHAR(50) DEFAULT 'USER', -- USER, ADMIN, MANAGER
  status VARCHAR(20) DEFAULT 'active', -- active, disabled, deleted
  is_default_user BOOLEAN DEFAULT false,  -- true per utente single-user
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  disabled_at TIMESTAMPTZ,         -- Soft-delete timestamp
  disabled_by UUID REFERENCES users(id),
  deleted_at TIMESTAMPTZ,          -- Hard-delete (raramente usato)
  last_login_at TIMESTAMPTZ,
  metadata JSONB                   -- Dati extra flessibili
);

-- Indici per performance
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_email ON users(email) WHERE status = 'active';
CREATE INDEX idx_users_disabled ON users(disabled_at) WHERE disabled_at IS NOT NULL;
```

**Tabella `tasks`** (già ok, con soft-delete per assigned_to):

```sql
-- assigned_to punta sempre a users.id
-- Se l'utente viene disabilitato, il riferimento rimane
-- Possiamo mostrare "Sara Rossi (disabilitato)" nelle viste storiche
```

### 2. Sistema di Autenticazione "Optional"

**Logica Backend:**

```typescript
// config.ts
export const config = {
  // Non più "mode", ma "authRequired"
  authRequired: process.env.AUTH_REQUIRED === 'true',

  // Default user (sempre presente)
  defaultUser: {
    id: process.env.DEFAULT_USER_ID || '00000000-0000-0000-0000-000000000001',
    name: process.env.DEFAULT_USER_NAME || 'Me',
    email: process.env.DEFAULT_USER_EMAIL || 'user@localhost'
  }
}

// Middleware unificato
fastify.addHook('preHandler', async (request, reply) => {
  // Skip auth routes
  if (request.url.startsWith('/api/pm/auth')) {
    return;
  }

  // AUTH REQUIRED MODE (Team)
  if (config.authRequired) {
    // Richiedi JWT token
    const token = extractToken(request);
    if (!token) {
      return reply.status(401).send({ error: 'Authentication required' });
    }

    const user = await verifyToken(token);
    if (!user || user.status !== 'active') {
      return reply.status(401).send({ error: 'Invalid or disabled user' });
    }

    request.user = user;
    request.userId = user.id;
  }

  // AUTH OPTIONAL MODE (Single-user)
  else {
    // Auto-login con default user
    request.user = await getOrCreateDefaultUser();
    request.userId = request.user.id;
  }
});

// Funzione per creare/recuperare default user
async function getOrCreateDefaultUser() {
  let user = await db.query(
    'SELECT * FROM users WHERE is_default_user = true LIMIT 1'
  );

  if (user.rows.length === 0) {
    // Crea default user
    user = await db.query(`
      INSERT INTO users (id, email, name, is_default_user, status)
      VALUES ($1, $2, $3, true, 'active')
      RETURNING *
    `, [config.defaultUser.id, config.defaultUser.email, config.defaultUser.name]);
  }

  return user.rows[0];
}
```

### 3. Frontend: UI Adattiva

**Login Page:**

```typescript
// Se AUTH_REQUIRED=false, redirect automatico
// Se AUTH_REQUIRED=true, mostra form login

useEffect(() => {
  // Check se auth è richiesta
  fetch('/api/pm/auth/required')
    .then(res => res.json())
    .then(data => {
      if (!data.authRequired) {
        // Single-user mode: auto-login e redirect
        navigate('/');
      }
    });
}, []);
```

**User Management UI:**

```tsx
// Pannello "Team" nel menu
<Route path="/team" element={<TeamManagement />} />

// TeamManagement.tsx
function TeamManagement() {
  const [authEnabled, setAuthEnabled] = useState(false);
  const [users, setUsers] = useState([]);

  return (
    <div>
      <h1>Team Management</h1>

      {/* Toggle Team Mode */}
      <Card>
        <h2>Team Mode</h2>
        <Switch
          checked={authEnabled}
          onChange={handleToggleAuth}
          label={authEnabled ? "Team Mode (login required)" : "Single-User Mode"}
        />

        {authEnabled && (
          <Alert type="warning">
            When you disable Team Mode, all users will be hidden but their
            work history will be preserved.
          </Alert>
        )}
      </Card>

      {/* User List (solo se authEnabled) */}
      {authEnabled && (
        <Card>
          <h2>Team Members</h2>
          <Button onClick={handleAddUser}>+ Add User</Button>

          <Table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Status</th>
                <th>Last Login</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id}>
                  <td>{user.name}</td>
                  <td>{user.email}</td>
                  <td>
                    <Badge color={user.status === 'active' ? 'green' : 'gray'}>
                      {user.status}
                    </Badge>
                  </td>
                  <td>{user.last_login_at || 'Never'}</td>
                  <td>
                    <Button onClick={() => handleDisableUser(user.id)}>
                      {user.status === 'active' ? 'Disable' : 'Enable'}
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </Table>
        </Card>
      )}

      {/* Disabled Users (archivio) */}
      <Card>
        <h2>Disabled Users Archive</h2>
        <p>Users who worked on projects but are no longer active</p>
        <Table>
          {/* Lista utenti disabilitati con storico */}
        </Table>
      </Card>
    </div>
  );
}
```

### 4. Task Assignment: Intelligente

**Quando assegno un task:**

```typescript
// TaskAssignment.tsx
function TaskAssignmentDropdown({ taskId, currentAssignee }) {
  const [users, setUsers] = useState([]);
  const [authEnabled, setAuthEnabled] = useState(false);

  useEffect(() => {
    // Carica utenti attivi
    fetch('/api/pm/users?status=active')
      .then(res => res.json())
      .then(data => {
        setUsers(data.data);
        setAuthEnabled(data.authEnabled);
      });
  }, []);

  if (!authEnabled && users.length === 1) {
    // Single-user mode: non mostrare dropdown
    return <span>Assigned to: Me</span>;
  }

  return (
    <Select
      value={currentAssignee}
      onChange={handleAssign}
    >
      <option value="">Unassigned</option>
      {users.map(user => (
        <option key={user.id} value={user.id}>
          {user.name} {user.status === 'disabled' && '(disabled)'}
        </option>
      ))}
    </Select>
  );
}
```

**Vista storico task:**

```typescript
// Quando mostro task completati
function TaskHistory({ projectId }) {
  const tasks = useTaskHistory(projectId);

  return (
    <Table>
      {tasks.map(task => (
        <tr>
          <td>{task.name}</td>
          <td>
            {task.assigned_to_user ? (
              <UserBadge user={task.assigned_to_user} />
            ) : (
              <span>Unassigned</span>
            )}
          </td>
          <td>{task.completed_at}</td>
        </tr>
      ))}
    </Table>
  );
}

// UserBadge component
function UserBadge({ user }) {
  if (!user) return null;

  return (
    <div className="flex items-center gap-2">
      <Avatar src={user.avatar_url} name={user.name} />
      <span>{user.name}</span>
      {user.status === 'disabled' && (
        <Badge color="gray">Disabled</Badge>
      )}
      {user.deleted_at && (
        <Badge color="red">Deleted</Badge>
      )}
    </div>
  );
}
```

---

## 🔄 API per Gestione Transizioni

### Enable Team Mode

```typescript
// POST /api/pm/settings/enable-team-mode
fastify.post('/api/pm/settings/enable-team-mode', async (request, reply) => {
  // 1. Imposta AUTH_REQUIRED=true nel .env
  // 2. Crea password per default user (diventa admin)
  // 3. Invia email con credenziali
  // 4. Riavvia server

  const { adminEmail, adminPassword } = request.body;

  // Update default user con password
  await db.query(`
    UPDATE users
    SET email = $1,
        password_hash = $2,
        role = 'ADMIN'
    WHERE is_default_user = true
  `, [adminEmail, await bcrypt.hash(adminPassword, 10)]);

  // Update .env
  await updateEnvFile({ AUTH_REQUIRED: 'true' });

  reply.send({
    success: true,
    message: 'Team mode enabled. Server will restart.',
    data: {
      adminEmail,
      loginUrl: '/login'
    }
  });

  // Restart
  setTimeout(() => process.exit(0), 1000);
});
```

### Disable User (Soft-Delete)

```typescript
// POST /api/pm/users/:id/disable
fastify.post('/api/pm/users/:id/disable', async (request, reply) => {
  const { id } = request.params;
  const { reason } = request.body;

  // Soft-delete: mantieni tutto lo storico
  await db.query(`
    UPDATE users
    SET status = 'disabled',
        disabled_at = NOW(),
        disabled_by = $1,
        metadata = metadata || $2::jsonb
    WHERE id = $3
  `, [request.userId, JSON.stringify({ reason }), id]);

  // I task assegnati rimangono visibili nello storico
  // Non tocchiamo la tabella tasks

  reply.send({
    success: true,
    message: 'User disabled. All work history preserved.'
  });
});
```

### Downgrade to Single-User

```typescript
// POST /api/pm/settings/disable-team-mode
fastify.post('/api/pm/settings/disable-team-mode', async (request, reply) => {
  // Verifica che ci sia solo 1 utente attivo
  const activeUsers = await db.query(
    'SELECT COUNT(*) as count FROM users WHERE status = \'active\''
  );

  if (parseInt(activeUsers.rows[0].count) > 1) {
    return reply.code(400).send({
      success: false,
      error: 'Cannot disable team mode with multiple active users. Disable other users first.'
    });
  }

  // Update .env
  await updateEnvFile({ AUTH_REQUIRED: 'false' });

  // Tutti gli utenti disabilitati rimangono nel DB
  // Nessun dato perso

  reply.send({
    success: true,
    message: 'Team mode disabled. Returning to single-user mode.',
    data: {
      preservedUsers: await db.query('SELECT COUNT(*) FROM users WHERE status = \'disabled\'')
    }
  });

  // Restart
  setTimeout(() => process.exit(0), 1000);
});
```

---

## 📈 Benefici Architettura Unificata

### 1. Zero Data Loss
- ✅ Storico task assegnati sempre visibile
- ✅ Chi ha fatto cosa rimane tracciato
- ✅ Audit trail completo anche con utenti disabilitati

### 2. Flessibilità Totale
- ✅ Scale up: abilita Team Mode in 2 click
- ✅ Scale down: disabilita utenti ma mantieni storico
- ✅ Progetti temporanei: team che si formano/sciolgono

### 3. Compliance & Audit
- ✅ Tracciabilità completa (chi-quando-cosa)
- ✅ Soft-delete per sicurezza
- ✅ Storico consultabile anche dopo anni

### 4. User Experience
- ✅ Freelancer: parte subito, zero configurazione
- ✅ Team: abilita quando serve con toggle
- ✅ Transizioni fluide, no migrazioni complesse

---

## 🎨 UI Flow Completo

### Single-User Mode (Default)
```
┌─────────────────────────────┐
│  PM System                  │
│  ┌───────────────────────┐  │
│  │ Projects (no login)   │  │
│  │ • Create project      │  │
│  │ • All tasks "by Me"   │  │
│  └───────────────────────┘  │
│                             │
│  [Settings]                 │
│   └─ Enable Team Mode       │  ← Click here
└─────────────────────────────┘
```

### Abilitazione Team Mode
```
┌─────────────────────────────┐
│  Enable Team Mode           │
│  ┌───────────────────────┐  │
│  │ Create admin account: │  │
│  │ Email: _____________  │  │
│  │ Password: ___________ │  │
│  │                       │  │
│  │ [Enable Team Mode] ✓  │  │
│  └───────────────────────┘  │
│                             │
│  After enabling:            │
│  • Login will be required   │
│  • You can add team members │
│  • All existing projects    │
│    remain intact            │
└─────────────────────────────┘
```

### Team Mode (Post-Abilitazione)
```
┌─────────────────────────────┐
│  PM System    [Mario Rossi ▼]│
│  ┌─────────┬─────────────┐  │
│  │Projects │Team         │  │ ← Nuovo tab
│  │         │             │  │
│  │         │ Members:    │  │
│  │         │ • Mario (Admin)│
│  │         │ • Sara (User)│  │
│  │         │ • Luca (User)│  │
│  │         │             │  │
│  │         │ [+ Add User]│  │
│  │         │             │  │
│  │         │ Disabled:   │  │
│  │         │ • Anna (2023)│  │ ← Storico visibile
│  │         │ • Paolo(2022)│  │
│  └─────────┴─────────────┘  │
└─────────────────────────────┘
```

---

## 🚀 Implementation Priority

### Phase 1: Database Structure (30 min)
1. ✅ Add columns to `users` table (già fatto parzialmente)
2. ✅ Create default user on startup
3. ✅ Update queries to handle disabled users

### Phase 2: Unified Auth Middleware (1 hour)
1. Remove separate single-user/team modes
2. Implement `AUTH_REQUIRED` flag
3. Auto-login vs JWT based on flag

### Phase 3: Team Management UI (2 hours)
1. Settings page with "Enable Team Mode" toggle
2. User management interface
3. User disable/enable functionality
4. Archive view for disabled users

### Phase 4: Task Assignment UI (1 hour)
1. Dropdown shows only active users
2. Historical views show all users (+ status badge)
3. Smart defaults (hide dropdown if 1 user)

---

## 💡 Esempio Pratico: Storia di Mario

**Mese 1: Solo**
```sql
-- Mario è il default user
SELECT * FROM users;
-- id: ...001, name: "Mario", is_default_user: true, status: active

SELECT * FROM tasks;
-- tutti assigned_to = Mario
```

**Mese 2: Assume Sara e Luca**
```sql
-- Abilita Team Mode, crea utenti
INSERT INTO users (name, email, password_hash) VALUES
  ('Sara', 'sara@example.com', '$2b$...'),
  ('Luca', 'luca@example.com', '$2b$...');

-- Mario diventa ADMIN
UPDATE users SET role = 'ADMIN' WHERE is_default_user = true;

-- Nuovi task assegnati a Sara/Luca
INSERT INTO tasks (..., assigned_to) VALUES (..., sara_id);
```

**Mese 6: Luca se ne va**
```sql
-- Soft-delete Luca
UPDATE users
SET status = 'disabled', disabled_at = NOW()
WHERE id = luca_id;

-- I suoi task completati rimangono visibili:
SELECT t.*, u.name, u.status
FROM tasks t
JOIN users u ON t.assigned_to = u.id
WHERE u.id = luca_id;

-- Output:
-- task_name: "Impaginazione Capitolo 3"
-- assigned_to: "Luca"
-- status: "disabled"  ← Sappiamo chi era
-- completed_at: "2024-05-15"
```

**Mese 12: Torna single-user**
```sql
-- Disabilita anche Sara
UPDATE users SET status = 'disabled' WHERE id = sara_id;

-- Mario rimane solo attivo
SELECT * FROM users WHERE status = 'active';
-- Solo Mario

-- Ma possiamo sempre vedere lo storico:
SELECT DISTINCT u.name, u.status, COUNT(t.id) as tasks_completed
FROM tasks t
JOIN users u ON t.assigned_to = u.id
WHERE t.status = 'done'
GROUP BY u.name, u.status;

-- Output:
-- Mario   | active   | 45 tasks
-- Sara    | disabled | 23 tasks
-- Luca    | disabled | 18 tasks
```

---

## ✅ Conclusione

Questa architettura unificata è **production-ready** per:

1. **Startups** che crescono da 1 a 100 persone
2. **Agencies** con team variabili per progetto
3. **Freelancer** che collaborano saltuariamente
4. **Aziende** che subiscono riorganizzazioni

**Nessun dato perso, massima flessibilità.**

Procedo con l'implementazione? 🚀
