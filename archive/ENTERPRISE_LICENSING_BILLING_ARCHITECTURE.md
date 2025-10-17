# Enterprise Licensing, Billing & Multi-Mode Architecture
## Architettura Completa: SSO, Single/Team Mode, Billing, Guest Users

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: ARCHITECTURAL SPECIFICATION

---

## 🎯 Obiettivi Chiave

1. ✅ **SSO Cross-App** - Una volta loggato nella Shell, accesso a tutte le app
2. ✅ **Single-User vs Team Mode** - Stessa UI, stesso DB, funzionalità adaptive
3. ✅ **License Reduction Transparency** - Da 10 utenti a 1, dati visibili, accessi disabilitati
4. ✅ **Account Inheritance** - Passaggio dati tra utenti senza cambiare ownership
5. ✅ **Guest Users** - Accesso temporaneo limitato
6. ✅ **Per-App Per-User Billing** - Ogni app ha prezzo per utente + costo infrastruttura
7. ✅ **Usage-Based Billing** - API calls, AI tokens, storage fatturati a consumo
8. ✅ **Credits System** - Prepagato per usage-based services

---

## 📐 Parte 1: SSO Cross-App Architecture

### Problema

Utente fa login in `app-shell-frontend` → Deve entrare automaticamente in tutte le app (`app-pm-frontend`, `app-dam`, `app-cms-frontend`, etc.) senza re-autenticarsi.

### Soluzione: Token Propagation via postMessage + SharedWorker

```
┌─────────────────────────────────────────────────────────────────┐
│                     app-shell-frontend                           │
│                      (localhost:3100)                            │
│                                                                  │
│  1. User login → svc-auth/login                                 │
│  2. Receive: accessToken, refreshToken, user, organization      │
│  3. Store in:                                                    │
│     - localStorage: shell_token, shell_user                     │
│     - SharedWorker: global token store                          │
│                                                                  │
│  4. Broadcast to all iframes:                                   │
│     window.postMessage({                                        │
│       type: 'AUTH_TOKEN',                                       │
│       token: accessToken,                                       │
│       user: user,                                               │
│       tenant: organization                                      │
│     }, '*')                                                     │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ postMessage
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│           All Child Apps (running in iframes)                   │
│                                                                  │
│  app-pm-frontend, app-dam, app-cms-frontend, etc.              │
│                                                                  │
│  window.addEventListener('message', (event) => {                │
│    if (event.data.type === 'AUTH_TOKEN') {                     │
│      // Save token                                              │
│      localStorage.setItem('app_token', event.data.token);      │
│      localStorage.setItem('app_user', JSON.stringify(          │
│        event.data.user                                          │
│      ));                                                         │
│      localStorage.setItem('app_tenant', JSON.stringify(        │
│        event.data.tenant                                        │
│      ));                                                         │
│                                                                  │
│      // Initialize app with auth                                │
│      initializeApp();                                           │
│    }                                                             │
│                                                                  │
│    if (event.data.type === 'TENANT_CHANGED') {                 │
│      // Reload app for new tenant                               │
│      switchTenant(event.data.tenant);                           │
│    }                                                             │
│  });                                                             │
└─────────────────────────────────────────────────────────────────┘
```

### Implementation

#### 1. Shell: Token Broadcaster

```typescript
// app-shell-frontend/src/lib/auth-broadcaster.ts
export class AuthBroadcaster {
  private broadcastChannel: BroadcastChannel;

  constructor() {
    // BroadcastChannel for same-origin communication
    this.broadcastChannel = new BroadcastChannel('ewh-auth');
  }

  broadcastLogin(token: string, user: User, tenant: Tenant) {
    const message = {
      type: 'AUTH_TOKEN',
      token,
      user,
      tenant,
      timestamp: Date.now()
    };

    // Broadcast to all tabs/windows (same origin)
    this.broadcastChannel.postMessage(message);

    // Also post to all iframes
    const iframes = document.querySelectorAll('iframe');
    iframes.forEach(iframe => {
      iframe.contentWindow?.postMessage(message, '*');
    });
  }

  broadcastLogout() {
    const message = { type: 'AUTH_LOGOUT', timestamp: Date.now() };
    this.broadcastChannel.postMessage(message);

    const iframes = document.querySelectorAll('iframe');
    iframes.forEach(iframe => {
      iframe.contentWindow?.postMessage(message, '*');
    });
  }

  broadcastTenantChange(tenant: Tenant) {
    const message = {
      type: 'TENANT_CHANGED',
      tenant,
      timestamp: Date.now()
    };

    this.broadcastChannel.postMessage(message);

    const iframes = document.querySelectorAll('iframe');
    iframes.forEach(iframe => {
      iframe.contentWindow?.postMessage(message, '*');
    });
  }
}
```

#### 2. Child Apps: Token Receiver

```typescript
// shared/packages/auth-client/src/iframe-auth-receiver.ts
export class IframeAuthReceiver {
  private onAuthCallback?: (token: string, user: User, tenant: Tenant) => void;
  private onLogoutCallback?: () => void;
  private onTenantChangeCallback?: (tenant: Tenant) => void;

  constructor() {
    window.addEventListener('message', this.handleMessage.bind(this));

    // Also listen to BroadcastChannel
    const bc = new BroadcastChannel('ewh-auth');
    bc.addEventListener('message', (event) => {
      this.handleMessage({ data: event.data } as MessageEvent);
    });
  }

  onAuth(callback: (token: string, user: User, tenant: Tenant) => void) {
    this.onAuthCallback = callback;

    // Check if already authenticated (from localStorage)
    const storedToken = localStorage.getItem('app_token');
    const storedUser = localStorage.getItem('app_user');
    const storedTenant = localStorage.getItem('app_tenant');

    if (storedToken && storedUser && storedTenant) {
      callback(
        storedToken,
        JSON.parse(storedUser),
        JSON.parse(storedTenant)
      );
    }
  }

  onLogout(callback: () => void) {
    this.onLogoutCallback = callback;
  }

  onTenantChange(callback: (tenant: Tenant) => void) {
    this.onTenantChangeCallback = callback;
  }

  private handleMessage(event: MessageEvent) {
    const { type, token, user, tenant } = event.data;

    switch (type) {
      case 'AUTH_TOKEN':
        // Save to localStorage
        localStorage.setItem('app_token', token);
        localStorage.setItem('app_user', JSON.stringify(user));
        localStorage.setItem('app_tenant', JSON.stringify(tenant));

        // Notify app
        this.onAuthCallback?.(token, user, tenant);
        break;

      case 'AUTH_LOGOUT':
        // Clear localStorage
        localStorage.removeItem('app_token');
        localStorage.removeItem('app_user');
        localStorage.removeItem('app_tenant');

        // Notify app
        this.onLogoutCallback?.();
        break;

      case 'TENANT_CHANGED':
        // Update localStorage
        localStorage.setItem('app_tenant', JSON.stringify(tenant));

        // Notify app
        this.onTenantChangeCallback?.(tenant);
        break;
    }
  }
}
```

#### 3. Usage in Child Apps

```typescript
// app-pm-frontend/src/index.tsx
import { IframeAuthReceiver } from '@ewh/auth-client';

const authReceiver = new IframeAuthReceiver();

authReceiver.onAuth((token, user, tenant) => {
  console.log('[PM App] Received auth from Shell', { user, tenant });

  // Initialize app with auth
  initializeApp({ token, user, tenant });
});

authReceiver.onLogout(() => {
  console.log('[PM App] Logout received from Shell');

  // Clear app state and redirect
  clearAppState();
  window.location.href = '/logged-out';
});

authReceiver.onTenantChange((tenant) => {
  console.log('[PM App] Tenant changed', tenant);

  // Reload data for new tenant
  switchTenantContext(tenant);
});
```

### Token Refresh Flow

```typescript
// shared/packages/auth-client/src/token-manager.ts
export class TokenManager {
  private refreshInterval?: NodeJS.Timeout;
  private token: string;
  private refreshToken: string;

  constructor(token: string, refreshToken: string) {
    this.token = token;
    this.refreshToken = refreshToken;

    // Refresh token 1 minute before expiry (accessToken TTL = 15 min)
    this.startRefreshTimer(14 * 60 * 1000); // 14 minutes
  }

  private startRefreshTimer(interval: number) {
    this.refreshInterval = setInterval(async () => {
      try {
        const response = await fetch('http://localhost:4001/refresh', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refreshToken: this.refreshToken })
        });

        if (!response.ok) {
          throw new Error('Token refresh failed');
        }

        const data = await response.json();
        this.token = data.accessToken;
        this.refreshToken = data.refreshToken;

        // Broadcast new token to all apps
        const broadcaster = new AuthBroadcaster();
        broadcaster.broadcastLogin(this.token, data.user, data.organization);

      } catch (error) {
        console.error('[TokenManager] Refresh failed', error);
        // Logout user
        this.logout();
      }
    }, interval);
  }

  private logout() {
    clearInterval(this.refreshInterval);
    // Broadcast logout
    const broadcaster = new AuthBroadcaster();
    broadcaster.broadcastLogout();
  }
}
```

---

## 📐 Parte 2: Single-User vs Team Mode Architecture

### Requisiti

1. **Stessa interfaccia** - Solo campi "Assegna a" disabilitati in single-user mode
2. **Stesso database** - Nessuna separazione schema
3. **Auto-assignment** - In single-user mode, tutto assegnato automaticamente all'unico utente
4. **Seamless upgrade** - Da single → team senza migration

### Database Schema Extensions

```sql
-- Add mode tracking to organizations
ALTER TABLE auth.organizations ADD COLUMN IF NOT EXISTS mode VARCHAR(20) DEFAULT 'team';
-- Values: 'single', 'team'

ALTER TABLE auth.organizations ADD COLUMN IF NOT EXISTS license_seats INTEGER DEFAULT 1;
-- Single: 1, Team: 1-unlimited

-- Add user status for license management
ALTER TABLE auth.memberships ADD COLUMN IF NOT EXISTS is_active_seat BOOLEAN DEFAULT true;
-- true = conta nella licenza, false = disabilitato per riduzione seats

-- Track deactivated users
CREATE TABLE IF NOT EXISTS auth.deactivated_user_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  organization_id UUID NOT NULL REFERENCES auth.organizations(id),
  deactivated_at TIMESTAMPTZ DEFAULT NOW(),
  deactivated_by UUID REFERENCES auth.users(id),
  reason VARCHAR(100), -- 'license_reduction', 'manual', 'inheritance'
  data_visibility VARCHAR(20) DEFAULT 'visible', -- 'visible', 'hidden', 'transferred'
  transferred_to_user_id UUID REFERENCES auth.users(id), -- For inheritance
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_deactivated_user_history_user ON auth.deactivated_user_history(user_id);
CREATE INDEX idx_deactivated_user_history_org ON auth.deactivated_user_history(organization_id);
```

### Mode Detection Middleware

```typescript
// shared/packages/middleware/src/mode-detector.ts
export interface TenantMode {
  mode: 'single' | 'team';
  licenseSeats: number;
  activeSeats: number;
  availableSeats: number;
  isSingleUserMode: boolean;
  singleUserId?: string;
}

export async function detectTenantMode(
  organizationId: string
): Promise<TenantMode> {
  const org = await db.query(
    `SELECT mode, license_seats
     FROM auth.organizations
     WHERE id = $1`,
    [organizationId]
  );

  const activeSeats = await db.query(
    `SELECT COUNT(*) as count
     FROM auth.memberships
     WHERE organization_id = $1
       AND status = 'active'
       AND is_active_seat = true`,
    [organizationId]
  );

  const mode = org.rows[0].mode;
  const licenseSeats = org.rows[0].license_seats;
  const activeCount = parseInt(activeSeats.rows[0].count);

  let singleUserId: string | undefined;
  if (mode === 'single' || activeCount === 1) {
    const singleUser = await db.query(
      `SELECT user_id
       FROM auth.memberships
       WHERE organization_id = $1
         AND status = 'active'
         AND is_active_seat = true
       LIMIT 1`,
      [organizationId]
    );
    singleUserId = singleUser.rows[0]?.user_id;
  }

  return {
    mode,
    licenseSeats,
    activeSeats: activeCount,
    availableSeats: licenseSeats - activeCount,
    isSingleUserMode: mode === 'single' || activeCount === 1,
    singleUserId
  };
}
```

### Auto-Assignment Middleware

```typescript
// shared/packages/middleware/src/auto-assign.ts
export function autoAssignMiddleware(req: Request, res: Response, next: NextFunction) {
  const tenantId = req.headers['x-tenant-id'] as string;
  const tenantMode = await detectTenantMode(tenantId);

  // Inject mode into request
  req.tenantMode = tenantMode;

  // If single-user mode, auto-assign
  if (tenantMode.isSingleUserMode && req.body) {
    if ('assigned_to' in req.body && !req.body.assigned_to) {
      req.body.assigned_to = tenantMode.singleUserId;
    }
    if ('created_by' in req.body && !req.body.created_by) {
      req.body.created_by = tenantMode.singleUserId;
    }
    if ('owner_id' in req.body && !req.body.owner_id) {
      req.body.owner_id = tenantMode.singleUserId;
    }
  }

  next();
}
```

### Frontend: Adaptive UI

```typescript
// shared/packages/ui-components/src/AssigneeField.tsx
import { useTenantMode } from '@ewh/hooks';

export function AssigneeField({ value, onChange, disabled }: Props) {
  const { isSingleUserMode, singleUserId } = useTenantMode();

  // In single-user mode, field is always disabled and shows current user
  if (isSingleUserMode) {
    return (
      <div className="flex items-center gap-2 opacity-60">
        <User size={16} />
        <span>Assigned to you (Single-user mode)</span>
      </div>
    );
  }

  // Team mode: normal select
  return (
    <UserSelect
      value={value}
      onChange={onChange}
      disabled={disabled}
      placeholder="Select assignee"
    />
  );
}
```

```typescript
// shared/packages/hooks/src/useTenantMode.ts
export function useTenantMode() {
  const { currentTenant } = useShell();
  const [tenantMode, setTenantMode] = useState<TenantMode | null>(null);

  useEffect(() => {
    if (!currentTenant) return;

    fetch(`/api/v1/tenants/${currentTenant.id}/mode`, {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(setTenantMode);
  }, [currentTenant]);

  return tenantMode || {
    isSingleUserMode: false,
    mode: 'team',
    licenseSeats: 1,
    activeSeats: 1,
    availableSeats: 0
  };
}
```

---

## 📐 Parte 3: License Reduction & Data Visibility

### Scenario

**Prima**: 10 utenti attivi
**Dopo**: Licenza ridotta a 1 utente
**Requisito**: Dati di tutti i 10 utenti visibili, ma 9 utenti non possono più accedere

### Implementation

#### 1. Deactivate Users (Keep Data)

```typescript
// svc-billing/src/controllers/reduce-license.ts
export async function reduceLicense(
  organizationId: string,
  newSeatCount: number,
  keepActiveUserIds: string[]
) {
  await db.transaction(async (client) => {
    // 1. Get current active users
    const activeUsers = await client.query(
      `SELECT user_id, tenant_role
       FROM auth.memberships
       WHERE organization_id = $1
         AND status = 'active'
         AND is_active_seat = true`,
      [organizationId]
    );

    // 2. Determine who to deactivate
    const usersToDeactivate = activeUsers.rows
      .filter(u => !keepActiveUserIds.includes(u.user_id))
      .slice(0, activeUsers.rows.length - newSeatCount);

    // 3. Deactivate (but keep membership)
    for (const user of usersToDeactivate) {
      // Set is_active_seat = false (don't delete membership!)
      await client.query(
        `UPDATE auth.memberships
         SET is_active_seat = false,
             updated_at = NOW()
         WHERE user_id = $1 AND organization_id = $2`,
        [user.user_id, organizationId]
      );

      // Record deactivation
      await client.query(
        `INSERT INTO auth.deactivated_user_history
           (user_id, organization_id, reason, data_visibility)
         VALUES ($1, $2, 'license_reduction', 'visible')`,
        [user.user_id, organizationId]
      );
    }

    // 4. Update organization license count
    await client.query(
      `UPDATE auth.organizations
       SET license_seats = $1,
           updated_at = NOW()
       WHERE id = $2`,
      [newSeatCount, organizationId]
    );
  });
}
```

#### 2. Data Visibility Filter

```typescript
// shared/packages/db-utils/src/visibility-filter.ts
export function buildVisibilityFilter(tenantMode: TenantMode): string {
  // In team mode with deactivated users, show all data
  // (deactivated users' data is still visible)

  // No filter needed - all data visible
  return '';
}

// Usage in queries:
const tasks = await db.query(
  `SELECT t.*, u.name as assigned_to_name,
          CASE
            WHEN m.is_active_seat = false THEN true
            ELSE false
          END as assigned_to_deactivated
   FROM pm.tasks t
   LEFT JOIN auth.users u ON u.id = t.assigned_to
   LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.organization_id = $1
   WHERE t.tenant_id = $1
   ORDER BY t.created_at DESC`,
  [tenantId]
);
```

#### 3. UI Indication of Deactivated Users

```typescript
// shared/packages/ui-components/src/UserAvatar.tsx
export function UserAvatar({ userId, showDeactivated = true }: Props) {
  const { data: user } = useUser(userId);

  if (user?.isDeactivated && showDeactivated) {
    return (
      <div className="relative">
        <Avatar src={user.avatar} name={user.name} />
        <div className="absolute inset-0 bg-gray-500/50 rounded-full flex items-center justify-center">
          <UserX size={12} className="text-white" />
        </div>
        <Tooltip content="User deactivated (license reduced)" />
      </div>
    );
  }

  return <Avatar src={user?.avatar} name={user?.name} />;
}
```

---

## 📐 Parte 4: Account Inheritance System

### Requisito

"Bisogna far ereditare account tra utenti, senza però cambiare il nome del vecchio utente con il nuovo."

**Scenario**:
- User A lascia l'azienda
- User B eredita tutti i progetti/task di User A
- Nei record storici, User A rimane come creator/owner originale
- Nuove assegnazioni vanno a User B

### Database Schema

```sql
-- Track inheritance relationships
CREATE TABLE IF NOT EXISTS auth.user_inheritance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID NOT NULL REFERENCES auth.users(id),
  to_user_id UUID NOT NULL REFERENCES auth.users(id),
  organization_id UUID NOT NULL REFERENCES auth.organizations(id),
  inheritance_type VARCHAR(50) NOT NULL, -- 'full', 'projects_only', 'custom'
  effective_date TIMESTAMPTZ DEFAULT NOW(),
  reason TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(from_user_id, to_user_id, organization_id)
);

-- Track what gets inherited (flexible JSON)
CREATE TABLE IF NOT EXISTS auth.inheritance_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inheritance_id UUID NOT NULL REFERENCES auth.user_inheritance(id) ON DELETE CASCADE,
  entity_type VARCHAR(100), -- 'projects', 'tasks', 'documents', 'leads', etc.
  action VARCHAR(50), -- 'transfer_ownership', 'transfer_assignment', 'add_collaborator'
  filter_conditions JSONB, -- e.g., {"status": ["active", "in_progress"]}
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Implementation

```typescript
// svc-auth/src/controllers/user-inheritance.ts
export async function createInheritance(params: {
  fromUserId: string;
  toUserId: string;
  organizationId: string;
  inheritanceType: 'full' | 'projects_only' | 'custom';
  rules?: InheritanceRule[];
  reason?: string;
}) {
  await db.transaction(async (client) => {
    // 1. Create inheritance record
    const inheritance = await client.query(
      `INSERT INTO auth.user_inheritance
         (from_user_id, to_user_id, organization_id, inheritance_type, reason)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id`,
      [
        params.fromUserId,
        params.toUserId,
        params.organizationId,
        params.inheritanceType,
        params.reason
      ]
    );

    const inheritanceId = inheritance.rows[0].id;

    // 2. Create rules
    const rules = params.rules || getDefaultRules(params.inheritanceType);
    for (const rule of rules) {
      await client.query(
        `INSERT INTO auth.inheritance_rules
           (inheritance_id, entity_type, action, filter_conditions)
         VALUES ($1, $2, $3, $4)`,
        [
          inheritanceId,
          rule.entityType,
          rule.action,
          rule.filterConditions || {}
        ]
      );
    }

    // 3. Apply inheritance (background job)
    await queueInheritanceJob(inheritanceId);
  });
}

function getDefaultRules(type: string): InheritanceRule[] {
  if (type === 'full') {
    return [
      {
        entityType: 'projects',
        action: 'transfer_ownership',
        filterConditions: { status: ['active', 'planning'] }
      },
      {
        entityType: 'tasks',
        action: 'transfer_assignment',
        filterConditions: { status: ['todo', 'in_progress'] }
      },
      {
        entityType: 'documents',
        action: 'add_collaborator',
        filterConditions: {}
      },
      {
        entityType: 'leads',
        action: 'transfer_ownership',
        filterConditions: { status: ['new', 'contacted', 'qualified'] }
      }
    ];
  }

  if (type === 'projects_only') {
    return [
      {
        entityType: 'projects',
        action: 'transfer_ownership',
        filterConditions: {}
      }
    ];
  }

  return [];
}
```

### Inheritance Job Worker

```typescript
// svc-job-worker/src/jobs/apply-inheritance.ts
export async function applyInheritance(inheritanceId: string) {
  const inheritance = await db.query(
    `SELECT i.*, u1.name as from_user_name, u2.name as to_user_name
     FROM auth.user_inheritance i
     JOIN auth.users u1 ON u1.id = i.from_user_id
     JOIN auth.users u2 ON u2.id = i.to_user_id
     WHERE i.id = $1`,
    [inheritanceId]
  );

  const rules = await db.query(
    `SELECT * FROM auth.inheritance_rules WHERE inheritance_id = $1`,
    [inheritanceId]
  );

  for (const rule of rules.rows) {
    await applyRule(inheritance.rows[0], rule);
  }
}

async function applyRule(inheritance: Inheritance, rule: InheritanceRule) {
  const { fromUserId, toUserId, organizationId } = inheritance;
  const { entityType, action, filterConditions } = rule;

  switch (entityType) {
    case 'projects':
      if (action === 'transfer_ownership') {
        // Update project ownership
        let query = `
          UPDATE pm.projects
          SET owner_id = $1,
              updated_at = NOW()
          WHERE owner_id = $2
            AND tenant_id = $3
        `;

        const params = [toUserId, fromUserId, organizationId];

        // Apply filters
        if (filterConditions.status) {
          query += ` AND status = ANY($4)`;
          params.push(filterConditions.status);
        }

        await db.query(query, params);

        // BUT: Keep created_by as original user (don't change history!)
        // created_by stays as fromUserId
      }
      break;

    case 'tasks':
      if (action === 'transfer_assignment') {
        let query = `
          UPDATE pm.tasks
          SET assigned_to = $1,
              updated_at = NOW()
          WHERE assigned_to = $2
            AND tenant_id = $3
        `;

        const params = [toUserId, fromUserId, organizationId];

        if (filterConditions.status) {
          query += ` AND status = ANY($4)`;
          params.push(filterConditions.status);
        }

        await db.query(query, params);

        // created_by and assigned_by stay as original users
      }
      break;

    case 'documents':
      if (action === 'add_collaborator') {
        // Don't transfer ownership, just add as collaborator
        await db.query(
          `INSERT INTO dam.document_collaborators (document_id, user_id, role)
           SELECT id, $1, 'editor'
           FROM dam.documents
           WHERE owner_id = $2
             AND tenant_id = $3
           ON CONFLICT (document_id, user_id) DO NOTHING`,
          [toUserId, fromUserId, organizationId]
        );
      }
      break;
  }
}
```

### UI: Inheritance History

```typescript
// Show in user profile
export function UserInheritanceHistory({ userId }: Props) {
  const { data: inheritances } = useQuery({
    queryKey: ['user-inheritances', userId],
    queryFn: () => fetch(`/api/v1/users/${userId}/inheritances`).then(r => r.json())
  });

  return (
    <div className="space-y-4">
      <h3>Account Inheritance History</h3>
      {inheritances?.map(inh => (
        <div key={inh.id} className="border rounded p-4">
          <div className="flex items-center gap-2">
            <ArrowRight size={16} />
            <span>
              Inherited from <strong>{inh.fromUserName}</strong> to{' '}
              <strong>{inh.toUserName}</strong>
            </span>
          </div>
          <div className="text-sm text-gray-600 mt-2">
            {inh.effectiveDate} • {inh.inheritanceType} • {inh.transferredCount} items
          </div>
        </div>
      ))}
    </div>
  );
}
```

---

## 📐 Parte 5: Guest User System

### Requirements

- Accesso temporaneo e limitato
- Nessuna email/password required (link-based)
- Permessi granulari per risorsa
- Scadenza automatica

### Database Schema

```sql
CREATE TABLE IF NOT EXISTS auth.guest_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES auth.organizations(id),
  email VARCHAR(320), -- Optional
  full_name VARCHAR(255),
  invited_by UUID NOT NULL REFERENCES auth.users(id),
  access_token VARCHAR(512) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ,
  access_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth.guest_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  guest_user_id UUID NOT NULL REFERENCES auth.guest_users(id) ON DELETE CASCADE,
  resource_type VARCHAR(100) NOT NULL, -- 'project', 'document', 'board', etc.
  resource_id UUID NOT NULL,
  permissions JSONB NOT NULL, -- ["read", "comment", "download"]
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(guest_user_id, resource_type, resource_id)
);

CREATE INDEX idx_guest_users_token ON auth.guest_users(access_token);
CREATE INDEX idx_guest_users_org ON auth.guest_users(organization_id);
CREATE INDEX idx_guest_permissions_guest ON auth.guest_permissions(guest_user_id);
CREATE INDEX idx_guest_permissions_resource ON auth.guest_permissions(resource_type, resource_id);
```

### Implementation

```typescript
// svc-auth/src/controllers/guest-users.ts
export async function createGuestAccess(params: {
  organizationId: string;
  invitedBy: string;
  email?: string;
  fullName: string;
  expiresInHours: number;
  resources: Array<{
    type: string;
    id: string;
    permissions: string[];
  }>;
}): Promise<{ guestId: string; accessUrl: string }> {
  const accessToken = generateSecureToken(64);
  const expiresAt = new Date(Date.now() + params.expiresInHours * 60 * 60 * 1000);

  await db.transaction(async (client) => {
    // 1. Create guest user
    const guest = await client.query(
      `INSERT INTO auth.guest_users
         (organization_id, email, full_name, invited_by, access_token, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id`,
      [
        params.organizationId,
        params.email,
        params.fullName,
        params.invitedBy,
        accessToken,
        expiresAt
      ]
    );

    const guestId = guest.rows[0].id;

    // 2. Create permissions
    for (const resource of params.resources) {
      await client.query(
        `INSERT INTO auth.guest_permissions
           (guest_user_id, resource_type, resource_id, permissions)
         VALUES ($1, $2, $3, $4)`,
        [guestId, resource.type, resource.id, JSON.stringify(resource.permissions)]
      );
    }
  });

  const accessUrl = `${config.urls.webAppBaseUrl}/guest?token=${accessToken}`;

  return { guestId: guest.rows[0].id, accessUrl };
}
```

### Guest Authentication Middleware

```typescript
// shared/packages/middleware/src/guest-auth.ts
export async function guestAuthMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const token = req.query.token || req.headers['x-guest-token'];

  if (!token) {
    return next(); // Not a guest request
  }

  const guest = await db.query(
    `SELECT g.*, o.id as organization_id
     FROM auth.guest_users g
     JOIN auth.organizations o ON o.id = g.organization_id
     WHERE g.access_token = $1
       AND g.expires_at > NOW()
       AND g.revoked_at IS NULL`,
    [token]
  );

  if (guest.rowCount === 0) {
    return res.status(403).json({ error: 'Invalid or expired guest token' });
  }

  // Update access tracking
  await db.query(
    `UPDATE auth.guest_users
     SET last_accessed_at = NOW(),
         access_count = access_count + 1
     WHERE id = $1`,
    [guest.rows[0].id]
  );

  // Inject guest context
  req.guestUser = guest.rows[0];
  req.isGuest = true;
  req.tenantId = guest.rows[0].organization_id;

  next();
}
```

### Permission Check

```typescript
// shared/packages/middleware/src/check-guest-permission.ts
export function checkGuestPermission(
  resourceType: string,
  permission: string
) {
  return async (req: Request, res: Response, next: NextFunction) => {
    if (!req.isGuest) {
      return next(); // Not a guest, use normal auth
    }

    const resourceId = req.params.id || req.params.projectId || req.params.documentId;

    const hasPermission = await db.query(
      `SELECT 1
       FROM auth.guest_permissions
       WHERE guest_user_id = $1
         AND resource_type = $2
         AND resource_id = $3
         AND permissions ? $4`,
      [req.guestUser.id, resourceType, resourceId, permission]
    );

    if (hasPermission.rowCount === 0) {
      return res.status(403).json({ error: 'Guest does not have access to this resource' });
    }

    next();
  };
}

// Usage:
app.get(
  '/api/v1/projects/:id',
  guestAuthMiddleware,
  checkGuestPermission('project', 'read'),
  getProject
);
```

---

## 📐 Parte 6: Per-App Per-User Billing System

### Pricing Model

```typescript
export interface AppPricing {
  appId: string;
  appName: string;
  pricingModel: 'per_user' | 'flat' | 'usage_based' | 'hybrid';

  // Per-user pricing
  pricePerUserPerMonth?: number;

  // Flat infrastructure cost
  infrastructureCostPerMonth?: number;

  // Usage-based (API calls, AI tokens, storage)
  usagePricing?: {
    apiCallsPerThousand?: number;
    aiTokensPer1M?: number;
    storagePerGB?: number;
  };

  // Free tier
  freeTier?: {
    users?: number;
    apiCalls?: number;
    aiTokens?: number;
    storageGB?: number;
  };
}
```

### Example Pricing

```typescript
const APP_PRICING: AppPricing[] = [
  {
    appId: 'app-pm-frontend',
    appName: 'Project Management',
    pricingModel: 'hybrid',
    pricePerUserPerMonth: 15, // €15/user/month
    infrastructureCostPerMonth: 50, // €50/month base
    usagePricing: {
      apiCallsPerThousand: 0.01, // €0.01 per 1000 API calls
      storagePerGB: 0.10 // €0.10 per GB
    },
    freeTier: {
      users: 3,
      apiCalls: 10000,
      storageGB: 5
    }
  },
  {
    appId: 'app-dam',
    appName: 'Digital Asset Management',
    pricingModel: 'hybrid',
    pricePerUserPerMonth: 25, // €25/user/month (more expensive)
    infrastructureCostPerMonth: 100, // €100/month base (storage intensive)
    usagePricing: {
      storagePerGB: 0.15, // €0.15 per GB (more expensive)
      aiTokensPer1M: 2.00 // €2 per 1M tokens (AI tagging)
    },
    freeTier: {
      users: 1,
      storageGB: 10,
      aiTokens: 100000
    }
  },
  {
    appId: 'app-cms-frontend',
    appName: 'Content Management',
    pricingModel: 'per_user',
    pricePerUserPerMonth: 20,
    freeTier: {
      users: 2
    }
  }
];
```

### Database Schema

```sql
-- App subscriptions
CREATE TABLE IF NOT EXISTS billing.app_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES auth.organizations(id),
  app_id VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  subscribed_users INTEGER DEFAULT 0, -- How many users subscribed
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ends_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, app_id)
);

-- Usage tracking per app
CREATE TABLE IF NOT EXISTS billing.app_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES auth.organizations(id),
  app_id VARCHAR(100) NOT NULL,
  user_id UUID REFERENCES auth.users(id), -- NULL for tenant-wide usage
  metric_type VARCHAR(50) NOT NULL, -- 'api_calls', 'ai_tokens', 'storage_gb', 'bandwidth_gb'
  quantity DECIMAL(20,6) NOT NULL,
  cost DECIMAL(10,4), -- Calculated cost
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_app_usage_org_app_period ON billing.app_usage(organization_id, app_id, period_start, period_end);
CREATE INDEX idx_app_usage_metric ON billing.app_usage(metric_type);

-- Monthly invoices
CREATE TABLE IF NOT EXISTS billing.invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES auth.organizations(id),
  invoice_number VARCHAR(50) UNIQUE NOT NULL,
  billing_period_start DATE NOT NULL,
  billing_period_end DATE NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  tax DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'EUR',
  status VARCHAR(20) DEFAULT 'draft', -- draft, sent, paid, overdue, cancelled
  issued_at TIMESTAMPTZ,
  due_date DATE,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invoice line items
CREATE TABLE IF NOT EXISTS billing.invoice_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id UUID NOT NULL REFERENCES billing.invoices(id) ON DELETE CASCADE,
  app_id VARCHAR(100),
  description TEXT NOT NULL,
  item_type VARCHAR(50) NOT NULL, -- 'per_user', 'infrastructure', 'usage', 'credit'
  quantity DECIMAL(20,6),
  unit_price DECIMAL(10,4),
  amount DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Credits/prepaid balance
CREATE TABLE IF NOT EXISTS billing.credits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES auth.organizations(id),
  amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'EUR',
  reason VARCHAR(255), -- 'purchase', 'refund', 'usage', 'bonus'
  reference_id UUID, -- Link to invoice or purchase
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_credits_org ON billing.credits(organization_id);
```

---

## 📐 Parte 7: Usage Tracking & Credits System

### Usage Tracker Middleware

```typescript
// shared/packages/middleware/src/usage-tracker.ts
export function trackUsage(appId: string, metricType: string) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();

    // Continue with request
    next();

    // Track after response (don't block request)
    res.on('finish', async () => {
      try {
        const organizationId = req.tenantId;
        const userId = req.user?.id;

        let quantity = 1; // Default: 1 API call

        // Calculate quantity based on metric
        if (metricType === 'api_calls') {
          quantity = 1;
        } else if (metricType === 'ai_tokens') {
          quantity = req.aiTokensUsed || 0;
        } else if (metricType === 'storage_gb') {
          quantity = req.storageUsedGB || 0;
        }

        if (quantity === 0) return;

        // Get pricing
        const pricing = APP_PRICING.find(p => p.appId === appId);
        const unitPrice = pricing?.usagePricing?.[metricType] || 0;
        const cost = (quantity * unitPrice);

        // Record usage
        await db.query(
          `INSERT INTO billing.app_usage
             (organization_id, app_id, user_id, metric_type, quantity, cost, period_start, period_end)
           VALUES ($1, $2, $3, $4, $5, $6, date_trunc('hour', NOW()), date_trunc('hour', NOW()) + INTERVAL '1 hour')
           ON CONFLICT (organization_id, app_id, metric_type, period_start)
           DO UPDATE SET
             quantity = billing.app_usage.quantity + EXCLUDED.quantity,
             cost = billing.app_usage.cost + EXCLUDED.cost`,
          [organizationId, appId, userId, metricType, quantity, cost]
        );

      } catch (error) {
        console.error('[UsageTracker] Error:', error);
      }
    });
  };
}

// Usage in routes:
app.post(
  '/api/v1/ai/generate',
  trackUsage('app-ai-assistant', 'ai_tokens'),
  generateAIContent
);
```

### Credits System

```typescript
// svc-billing/src/services/credits.ts
export class CreditsService {
  async getBalance(organizationId: string): Promise<number> {
    const result = await db.query(
      `SELECT COALESCE(SUM(amount), 0) as balance
       FROM billing.credits
       WHERE organization_id = $1`,
      [organizationId]
    );
    return parseFloat(result.rows[0].balance);
  }

  async addCredits(
    organizationId: string,
    amount: number,
    reason: string,
    referenceId?: string
  ) {
    await db.query(
      `INSERT INTO billing.credits (organization_id, amount, reason, reference_id)
       VALUES ($1, $2, $3, $4)`,
      [organizationId, amount, reason, referenceId]
    );
  }

  async deductCredits(
    organizationId: string,
    amount: number,
    reason: string,
    referenceId?: string
  ) {
    const balance = await this.getBalance(organizationId);

    if (balance < amount) {
      throw new Error('Insufficient credits');
    }

    await this.addCredits(organizationId, -amount, reason, referenceId);
  }

  async canAfford(organizationId: string, amount: number): Promise<boolean> {
    const balance = await this.getBalance(organizationId);
    return balance >= amount;
  }
}
```

### Usage-Based Charging with Credits

```typescript
// Before expensive operation:
export async function generateAIContent(req: Request, res: Response) {
  const estimatedTokens = estimateTokensForRequest(req.body);
  const pricing = APP_PRICING.find(p => p.appId === 'app-ai-assistant');
  const estimatedCost = (estimatedTokens / 1000000) * pricing.usagePricing.aiTokensPer1M;

  const creditsService = new CreditsService();
  const canAfford = await creditsService.canAfford(req.tenantId, estimatedCost);

  if (!canAfford) {
    return res.status(402).json({
      error: 'Insufficient credits',
      required: estimatedCost,
      balance: await creditsService.getBalance(req.tenantId),
      topUpUrl: `/billing/top-up`
    });
  }

  // Proceed with AI generation
  const result = await aiService.generate(req.body.prompt);

  // Deduct actual usage
  const actualCost = (result.tokensUsed / 1000000) * pricing.usagePricing.aiTokensPer1M;
  await creditsService.deductCredits(
    req.tenantId,
    actualCost,
    'ai_content_generation',
    result.id
  );

  return res.json(result);
}
```

---

## 📐 Parte 8: Invoice Generation

### Monthly Invoice Generator

```typescript
// svc-billing/src/jobs/generate-monthly-invoices.ts
export async function generateMonthlyInvoice(
  organizationId: string,
  periodStart: Date,
  periodEnd: Date
) {
  const invoiceNumber = generateInvoiceNumber(organizationId, periodStart);

  await db.transaction(async (client) => {
    // 1. Create invoice
    const invoice = await client.query(
      `INSERT INTO billing.invoices
         (organization_id, invoice_number, billing_period_start, billing_period_end, subtotal, total, status)
       VALUES ($1, $2, $3, $4, 0, 0, 'draft')
       RETURNING id`,
      [organizationId, invoiceNumber, periodStart, periodEnd]
    );

    const invoiceId = invoice.rows[0].id;
    let total = 0;

    // 2. Add per-user subscription costs
    const subscriptions = await client.query(
      `SELECT app_id, subscribed_users
       FROM billing.app_subscriptions
       WHERE organization_id = $1 AND is_active = true`,
      [organizationId]
    );

    for (const sub of subscriptions.rows) {
      const pricing = APP_PRICING.find(p => p.appId === sub.app_id);
      if (!pricing) continue;

      // Per-user cost
      if (pricing.pricePerUserPerMonth) {
        const amount = pricing.pricePerUserPerMonth * sub.subscribed_users;
        await client.query(
          `INSERT INTO billing.invoice_items
             (invoice_id, app_id, description, item_type, quantity, unit_price, amount)
           VALUES ($1, $2, $3, 'per_user', $4, $5, $6)`,
          [
            invoiceId,
            sub.app_id,
            `${pricing.appName} - ${sub.subscribed_users} users`,
            sub.subscribed_users,
            pricing.pricePerUserPerMonth,
            amount
          ]
        );
        total += amount;
      }

      // Infrastructure cost
      if (pricing.infrastructureCostPerMonth) {
        await client.query(
          `INSERT INTO billing.invoice_items
             (invoice_id, app_id, description, item_type, quantity, unit_price, amount)
           VALUES ($1, $2, $3, 'infrastructure', 1, $4, $5)`,
          [
            invoiceId,
            sub.app_id,
            `${pricing.appName} - Infrastructure`,
            pricing.infrastructureCostPerMonth,
            pricing.infrastructureCostPerMonth
          ]
        );
        total += pricing.infrastructureCostPerMonth;
      }
    }

    // 3. Add usage-based costs
    const usage = await client.query(
      `SELECT app_id, metric_type, SUM(quantity) as total_quantity, SUM(cost) as total_cost
       FROM billing.app_usage
       WHERE organization_id = $1
         AND period_start >= $2
         AND period_end <= $3
       GROUP BY app_id, metric_type`,
      [organizationId, periodStart, periodEnd]
    );

    for (const item of usage.rows) {
      const pricing = APP_PRICING.find(p => p.appId === item.app_id);
      const metricName = {
        'api_calls': 'API Calls',
        'ai_tokens': 'AI Tokens',
        'storage_gb': 'Storage',
        'bandwidth_gb': 'Bandwidth'
      }[item.metric_type] || item.metric_type;

      await client.query(
        `INSERT INTO billing.invoice_items
           (invoice_id, app_id, description, item_type, quantity, unit_price, amount)
         VALUES ($1, $2, $3, 'usage', $4, $5, $6)`,
        [
          invoiceId,
          item.app_id,
          `${pricing?.appName} - ${metricName}`,
          item.total_quantity,
          item.total_cost / item.total_quantity,
          item.total_cost
        ]
      );
      total += parseFloat(item.total_cost);
    }

    // 4. Apply credits
    const creditsService = new CreditsService();
    const balance = await creditsService.getBalance(organizationId);

    if (balance > 0) {
      const creditAmount = Math.min(balance, total);
      await client.query(
        `INSERT INTO billing.invoice_items
           (invoice_id, description, item_type, quantity, unit_price, amount)
         VALUES ($1, 'Credits Applied', 'credit', 1, $2, $3)`,
        [invoiceId, -creditAmount, -creditAmount]
      );

      await creditsService.deductCredits(
        organizationId,
        creditAmount,
        'invoice_payment',
        invoiceId
      );

      total -= creditAmount;
    }

    // 5. Update invoice total
    await client.query(
      `UPDATE billing.invoices
       SET subtotal = $1, total = $2, issued_at = NOW(), due_date = NOW() + INTERVAL '30 days'
       WHERE id = $3`,
      [total, total, invoiceId]
    );
  });
}
```

---

## 📊 Summary & Next Steps

### ✅ Architetture Complete

1. **SSO Cross-App** - postMessage + BroadcastChannel + SharedWorker
2. **Single/Team Mode** - Same UI, adaptive behavior, mode detection middleware
3. **License Reduction** - Deactivate users, keep data visible
4. **Account Inheritance** - Transfer ownership without changing history
5. **Guest Users** - Token-based temporary access with granular permissions
6. **Per-App Billing** - Flexible pricing models (per-user, flat, usage-based, hybrid)
7. **Usage Tracking** - Middleware-based automatic tracking
8. **Credits System** - Prepaid balance with deduction on usage

### 🚀 Implementation Priorities

**Phase 1 (Week 1-2)**: SSO & Mode Detection
- Implement AuthBroadcaster in shell
- Implement IframeAuthReceiver in all apps
- Add mode detection middleware
- Test single-user → team upgrade

**Phase 2 (Week 2-3)**: Billing Foundation
- Create billing schema
- Implement usage tracking middleware
- Build credits system
- Create invoice generation job

**Phase 3 (Week 3-4)**: Advanced Features
- Implement account inheritance
- Build guest user system
- Create admin UI for billing

**Phase 4 (Week 4+)**: Polish & Integration
- Stripe/payment gateway integration
- Email invoices
- Usage dashboards
- Billing admin panel

### 📝 Files to Create

1. `AUTHENTICATION_SSO_CROSS_APP.md` - Deep dive on SSO
2. `SINGLE_TEAM_MODE_SPECIFICATION.md` - Mode system details
3. `BILLING_SYSTEM_COMPLETE.md` - Full billing documentation
4. Migration scripts for all new tables

---

**Status**: ✅ ARCHITECTURE COMPLETE
**User Login**: ✅ WORKING (fabio.polosa@gmail.com / 1234saas1234)
**Next**: Implementation Phase 1

