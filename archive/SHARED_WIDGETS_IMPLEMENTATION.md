# Shared Widgets Implementation - Come Condividere Componenti tra Due Frontend

## Il Problema

Hai due frontend separati:
- **app-admin-frontend** (porta 3200) - Admin panel
- **app-web-frontend** (porta 3100) - Frontend pubblico/tenant

Entrambi devono usare gli stessi widget (es. `ConnectedUsersWidget`), ma i widget sono componenti React. Come si fa?

## La Soluzione: pnpm Workspace con Package Condiviso

### 1. Struttura Creata

```
ewh/
├── pnpm-workspace.yaml              # Configura workspace
├── shared/
│   └── packages/
│       └── widgets/                 # Package condiviso @ewh/shared-widgets
│           ├── package.json
│           ├── tsconfig.json
│           └── src/
│               ├── index.ts         # Export principale
│               ├── types.ts         # Tipi condivisi
│               ├── ConnectedUsersWidget.tsx
│               └── WidgetRegistry.ts
├── app-admin-frontend/
│   ├── package.json                 # Importa "@ewh/shared-widgets": "workspace:*"
│   ├── next.config.js              # transpilePackages: ['@ewh/shared-widgets']
│   └── pages/
│       ├── api/users/connected.ts  # API endpoint context-aware
│       └── admin/monitoring/users.tsx  # Usa widget in ADMIN context
└── app-web-frontend/
    ├── package.json                # Importa "@ewh/shared-widgets": "workspace:*"
    ├── next.config.js             # transpilePackages: ['@ewh/shared-widgets']
    └── pages/
        ├── api/users/connected.ts # API endpoint context-aware (stesso)
        └── dashboard/team.tsx     # Usa widget in TENANT/USER context
```

### 2. Come Funziona

#### A. pnpm Workspace (`pnpm-workspace.yaml`)

```yaml
packages:
  - 'app-admin-frontend'
  - 'app-web-frontend'
  - 'shared/packages/*'
  - 'svc-*'
  - 'plugins/*'
```

Questo dice a pnpm: "questi sono tutti package del mio monorepo, possono importarsi tra loro".

#### B. Package Condiviso (`shared/packages/widgets/package.json`)

```json
{
  "name": "@ewh/shared-widgets",
  "version": "1.0.0",
  "private": true,
  "exports": {
    ".": {
      "import": "./src/index.ts"
    },
    "./ConnectedUsersWidget": {
      "import": "./src/ConnectedUsersWidget.tsx"
    }
  }
}
```

Questo package contiene tutti i widget riutilizzabili.

#### C. Dipendenza nei Frontend

Entrambi i frontend hanno in `package.json`:

```json
{
  "dependencies": {
    "@ewh/shared-widgets": "workspace:*"
  }
}
```

Il `workspace:*` dice a pnpm: "usa la versione locale dal workspace".

#### D. Next.js Transpilation

Entrambi i `next.config.js` hanno:

```javascript
{
  transpilePackages: ['@ewh/shared-widgets']
}
```

Questo dice a Next.js: "compila anche questo package esterno".

### 3. Uso nei Frontend

#### Admin Frontend (mostra TUTTI gli utenti)

```tsx
// app-admin-frontend/pages/admin/monitoring/users.tsx
import { ConnectedUsersWidget } from '@ewh/shared-widgets';

export default function AdminMonitoringUsersPage() {
  return (
    <ConnectedUsersWidget
      context={{ context: 'admin' }}
      config={{
        maxUsers: 20,
        showAvatar: true,
        sortBy: 'lastActive'
      }}
    />
  );
}
```

#### Web Frontend (mostra solo utenti del tenant)

```tsx
// app-web-frontend/pages/dashboard/team.tsx
import { ConnectedUsersWidget } from '@ewh/shared-widgets';

export default function TenantTeamDashboard() {
  return (
    <ConnectedUsersWidget
      context={{
        context: 'tenant',
        tenantId: 'acme-corp'
      }}
      config={{
        maxUsers: 15,
        customTitle: 'Team Members',
        brandColor: '#10b981'
      }}
    />
  );
}
```

### 4. Context-Aware Data Fetching

Il widget chiama `/api/users/connected` con parametri di context:

```typescript
const params = new URLSearchParams({
  context: context.context,           // 'admin' | 'tenant' | 'user'
  tenantId: context.tenantId,        // Se presente
  userId: context.userId,            // Se presente
  maxUsers: config.maxUsers.toString()
});

fetch(`/api/users/connected?${params}`);
```

L'endpoint API fa query diverse in base al context:

```typescript
switch (context) {
  case 'admin':
    // Query: SELECT * FROM users (tutti)
    query = `SELECT ... FROM auth.users u LEFT JOIN auth.tenants t ...`;
    break;

  case 'tenant':
    // Query: SELECT * FROM users WHERE tenant_id = $1
    query = `SELECT ... FROM auth.users u WHERE u.tenant_id = $1 ...`;
    break;

  case 'user':
    // Query: SELECT * FROM users WHERE team_id = (SELECT team_id FROM users WHERE id = $1)
    query = `SELECT ... FROM auth.users u WHERE u.team_id = ...`;
    break;
}
```

### 5. Setup e Installazione

```bash
# 1. Installa tutte le dipendenze (pnpm risolve automaticamente i workspace)
pnpm install

# 2. (Opzionale) Build del package condiviso
cd shared/packages/widgets
pnpm build

# 3. Avvia admin frontend
cd app-admin-frontend
pnpm dev  # Porta 3200

# 4. Avvia web frontend (in altro terminale)
cd app-web-frontend
pnpm dev  # Porta 3100
```

### 6. Vantaggi di Questo Approccio

#### ✅ **Single Source of Truth**
- Widget definito UNA volta in `@ewh/shared-widgets`
- Modifichi in un posto, funziona ovunque
- Bug fix si applica automaticamente a entrambi i frontend

#### ✅ **Type Safety**
- TypeScript funziona perfettamente
- Auto-complete e IntelliSense in entrambi i frontend
- Errori di tipo vengono rilevati al compile time

#### ✅ **Hot Module Replacement (HMR)**
- Durante sviluppo, modifiche ai widget si riflettono immediatamente
- pnpm watch sui packages condivisi (opzionale)

#### ✅ **Context-Aware Logic**
- Stesso componente React
- Comportamento diverso in base al context prop
- API endpoint filtra dati automaticamente

#### ✅ **3-Level Configuration**
1. **System** (Level 1): Config di default per tutti
2. **Tenant** (Level 2): Override per singolo tenant (es. brandColor)
3. **User** (Level 3): Preferenze utente (es. compactView)

#### ✅ **Scalabilità**
- Aggiungi nuovi widget in `@ewh/shared-widgets`
- Importali nei frontend dove servono
- Nessuna duplicazione di codice

### 7. Aggiungere Nuovi Widget

```bash
# 1. Crea nuovo widget
touch shared/packages/widgets/src/MyNewWidget.tsx

# 2. Implementa il widget
cat > shared/packages/widgets/src/MyNewWidget.tsx << 'EOF'
import { WidgetProps } from './types';

export function MyNewWidget({ context, config }: WidgetProps) {
  // Implementazione...
}
EOF

# 3. Exporta nel package
echo "export * from './MyNewWidget';" >> shared/packages/widgets/src/index.ts

# 4. Usa nei frontend
# In app-admin-frontend o app-web-frontend:
import { MyNewWidget } from '@ewh/shared-widgets';
```

### 8. Widget Registry (Sistema Avanzato)

Per discovery dinamica dei widget:

```typescript
// Registra widget all'avvio dell'app
import WidgetRegistry from '@ewh/shared-widgets';
import { ConnectedUsersWidget } from '@ewh/shared-widgets';

WidgetRegistry.register({
  id: 'connected-users',
  pluginId: 'user-management',
  name: 'Connected Users',
  contextSupport: { admin: true, tenant: true, user: true },
  defaultConfig: { maxUsers: 10, showAvatar: true }
}, ConnectedUsersWidget);

// Poi recupera widget dinamicamente
const Widget = WidgetRegistry.getComponent('connected-users');
<Widget context={...} config={...} />
```

### 9. API Endpoint Context-Aware

Ogni frontend ha lo stesso endpoint `/api/users/connected` che:

1. Riceve parametri `context`, `tenantId`, `userId`
2. Esegue query SQL diversa in base al context
3. Ritorna solo dati autorizzati per quel context

**Esempio query admin vs tenant:**

```sql
-- ADMIN context: vede TUTTO
SELECT u.*, t.name as "tenantName"
FROM auth.users u
LEFT JOIN auth.tenants t ON u.tenant_id = t.id

-- TENANT context: vede solo suo tenant
SELECT u.*
FROM auth.users u
WHERE u.tenant_id = $1

-- USER context: vede solo suo team
SELECT u.*
FROM auth.users u
WHERE u.team_id = (SELECT team_id FROM auth.users WHERE id = $1)
```

### 10. Testing

```bash
# Test admin frontend
curl "http://localhost:3200/api/users/connected?context=admin&maxUsers=10"

# Test web frontend (tenant context)
curl "http://localhost:3100/api/users/connected?context=tenant&tenantId=acme-corp&maxUsers=15"

# Test web frontend (user context)
curl "http://localhost:3100/api/users/connected?context=user&tenantId=acme-corp&userId=user-123"
```

### 11. Database Migration

Assicurati di eseguire la migration che crea le tabelle widget:

```bash
psql -h localhost -U ewh -d ewh_master -f migrations/023_unified_plugin_widget_system.sql
```

Questo crea:
- `widgets.widget_definitions` - Definizioni widget (Level 1)
- `widgets.tenant_widget_configs` - Config per tenant (Level 2)
- `widgets.user_widget_preferences` - Preferenze utente (Level 3)
- `widgets.widget_instances` - Istanze widget nelle pagine
- `plugins.plugin_capabilities` - Collega widget a plugin

### 12. Debug

Se il widget non viene trovato:

```bash
# 1. Verifica che workspace sia configurato
cat pnpm-workspace.yaml

# 2. Verifica link
cd app-admin-frontend
ls -la node_modules/@ewh/shared-widgets  # Deve essere symlink

# 3. Re-installa
rm -rf node_modules
pnpm install

# 4. Verifica transpilation
grep transpilePackages app-admin-frontend/next.config.js
```

### 13. Production Build

```bash
# Build tutti i package in ordine
pnpm install

# Build admin frontend
cd app-admin-frontend
pnpm build

# Build web frontend
cd app-web-frontend
pnpm build

# Deploy separatamente
# - app-admin-frontend → Server privato / VPN
# - app-web-frontend → CDN / Edge
```

## Conclusione

Con questo sistema:

1. ✅ **Stesso componente React** usato in entrambi i frontend
2. ✅ **Comportamento context-aware** (admin vede tutto, tenant vede solo suo)
3. ✅ **3-level configuration** (sistema → tenant → utente)
4. ✅ **Zero duplicazione** di codice
5. ✅ **Type-safe** con TypeScript
6. ✅ **Hot reload** durante sviluppo
7. ✅ **Scalabile** per centinaia di widget

Il widget `ConnectedUsersWidget` è lo stesso file React, ma mostra dati diversi in base al `context` prop che gli passi!
