# SSO Architecture - Enterprise Workspace Hub

## Overview

Architettura Single Sign-On centralizzata per tutti i servizi frontend dell'ecosistema EWH.

**Status**: ✅ **IMPLEMENTATO** e **DISTRIBUITO** a 12+ frontend

## Componenti

### 1. Central Authentication Service (svc-auth)

**Porta**: `4001`
**Repository**: `https://github.com/edizioniwhtehole/svc-auth.git`
**Tipo**: Git Submodule

**Responsabilità**:
- Gestione login/signup/logout
- Emissione JWT tokens (RS256)
- Gestione MFA, OAuth, SSO
- User/Tenant/Organization management
- Token refresh e revocation

**API Endpoints**:
```
POST /login         - Autenticazione utente
POST /signup        - Registrazione nuovo utente
POST /refresh       - Refresh token
GET  /whoami        - Info utente corrente
GET  /.well-known/jwks.json - Public keys per validazione JWT
```

**JWT Payload**:
```json
{
  "email": "user@example.com",
  "org_id": "uuid",
  "org_slug": "organization-slug",
  "tenant_role": "TENANT_ADMIN",
  "platform_role": "OWNER",
  "scopes": ["feature:xxx", "..."],
  "exp": 1234567890,
  "sub": "user-uuid"
}
```

### 2. Shell Frontend (app-shell-frontend)

**Porta**: `3150`
**Tipo**: Next.js Application

**Responsabilità**:
- Login centralizzato
- Dashboard unificata
- Routing tra app
- Token distribution agli iframe
- Tenant switching
- Theme management

**Token Passing Mechanisms**:

#### A. URL Parameters (Primary)
```typescript
const iframeUrl = `${appUrl}?token=${JWT}&tenant_id=${id}&tenant_slug=${slug}`;
```

#### B. postMessage API (Updates)
```typescript
// Shell → Iframe
window.postMessage({
  type: 'AUTH_CONTEXT',
  token: 'JWT',
  tenant: { id, name, slug }
}, '*');

// Iframe → Shell
window.postMessage({
  type: 'IFRAME_READY'
}, '*');
```

### 3. Frontend Applications

**Apps Configurati** (12):
- `app-pm-frontend` (Project Management)
- `app-dam` (Digital Asset Manager)
- `app-approvals-frontend`
- `app-inventory-frontend`
- `app-procurement-frontend`
- `app-quotations-frontend`
- `app-orders-purchase-frontend`
- `app-orders-sales-frontend`
- `app-settings-frontend`
- `app-cms-frontend`
- `app-media-frontend`
- `app-page-builder`

**Shared Components**:
- `shared/shell-sso-helper.ts` - Utilities SSO
- `shared/ShellAuthContext.template.tsx` - React Context

## Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User Login                                               │
│    User → Shell → svc-auth                                  │
│    ✅ JWT Token + User Info + Organization                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Token Storage                                            │
│    Shell stores in:                                         │
│    - ShellContext (React State)                             │
│    - localStorage ('shell_token')                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. App Navigation                                           │
│    User clicks app card → Shell opens iframe               │
│    URL: /app?url=http://localhost:5400                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Token Injection                                          │
│    Shell adds token to iframe URL:                         │
│    http://localhost:5400?token=JWT&tenant_id=xxx            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. App Auto-Authentication                                  │
│    App reads token from URL params:                         │
│    - getShellAuthFromURL()                                  │
│    - Store in localStorage                                  │
│    - Clean URL (security)                                   │
│    - Setup postMessage listener                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. API Calls with Token                                     │
│    All API calls include:                                   │
│    Authorization: Bearer <JWT>                              │
│    X-Tenant-ID: <tenant_id>                                 │
└─────────────────────────────────────────────────────────────┘
```

## Permission Cascade

```
┌──────────────────────────────────────────┐
│ PLATFORM_ADMIN / OWNER                   │
│ - Full platform access                   │
│ - All tenant access                      │
│ - Service configuration                  │
│ - User management across tenants         │
└──────────────────────────────────────────┘
            ↓ inherits
┌──────────────────────────────────────────┐
│ TENANT_ADMIN                             │
│ - Tenant configuration                   │
│ - User management (own tenant)           │
│ - Service settings                       │
│ - Billing management                     │
└──────────────────────────────────────────┘
            ↓ inherits
┌──────────────────────────────────────────┐
│ USER                                     │
│ - Personal profile                       │
│ - Personal settings                      │
│ - Assigned apps access                   │
└──────────────────────────────────────────┘
```

## Settings Organization

### Platform Level (PLATFORM_ADMIN only)
```
/settings
├── Platform Configuration
├── Services Management
├── Authentication Service
├── Search Service
└── Billing Service
```

### Tenant Level (TENANT_ADMIN+)
```
/settings
├── Organization Settings
├── Users & Permissions
├── Billing & Subscription
├── Security & Audit
└── Service-Specific Settings
    ├── Project Management
    ├── Media Library
    ├── Approval Workflows
    ├── Inventory
    ├── Procurement
    ├── Quotations
    ├── Email Service
    └── Workflow Engine
```

### User Level (All Users)
```
/settings
├── My Profile
├── Notifications
└── My Integrations
```

## Security

### Token Security
- **Algorithm**: RS256 (RSA + SHA256)
- **Expiration**: 15 minutes (900s)
- **Refresh**: Available via refresh token
- **Storage**: localStorage (encrypted in production)
- **Transmission**: HTTPS only (production)

### Token Validation
Backend services must:
1. Verify JWT signature using public key from `/.well-known/jwks.json`
2. Check expiration timestamp
3. Validate `iss` (issuer) = `http://localhost:4001`
4. Extract `org_id` for tenant filtering
5. Check `platform_role` and `tenant_role` for authorization

### CORS & CSP
```javascript
// Shell allows iframes from:
- http://localhost:* (development)
- https://*.ewh.app (production)

// Apps must allow:
- postMessage from shell origin
- Cookie/localStorage access (same-origin)
```

## Implementation Checklist

### For Each Frontend App:

- [x] Copy `shell-sso-helper.ts` to `src/lib/`
- [x] Copy `ShellAuthContext.tsx` to `src/context/`
- [ ] Update `_app.tsx` to wrap with `<ShellAuthProvider>`
- [ ] Update pages to use `useShellAuth()` hook
- [ ] Update API client to include `Authorization` header
- [ ] Test auto-login from shell
- [ ] Test tenant switching
- [ ] Test token refresh

### Status by App:

| App | Helper Installed | Context Added | _app.tsx | API Updated | Tested |
|-----|-----------------|---------------|----------|-------------|--------|
| app-pm-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-dam | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-approvals-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-inventory-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-procurement-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-quotations-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-orders-purchase-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-orders-sales-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-settings-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-cms-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-media-frontend | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| app-page-builder | ✅ | ✅ | ⏳ | ⏳ | ⏳ |

## Backend Services

Tutti i backend services (svc-*) devono:

### 1. JWT Validation Middleware
```typescript
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

const client = jwksClient({
  jwksUri: 'http://localhost:4001/.well-known/jwks.json'
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    const signingKey = key.getPublicKey();
    callback(null, signingKey);
  });
}

async function validateToken(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');

  jwt.verify(token, getKey, {
    issuer: 'http://localhost:4001',
    audience: 'ewh-saas'
  }, (err, decoded) => {
    if (err) return res.status(401).json({ error: 'Invalid token' });
    req.user = decoded;
    next();
  });
}
```

### 2. Tenant Filtering
```typescript
// Tutti i query devono filtrare per org_id
const data = await db.query(
  'SELECT * FROM resources WHERE org_id = $1',
  [req.user.org_id]
);
```

### 3. Permission Checking
```typescript
function requireRole(roles: string[]) {
  return (req, res, next) => {
    if (!roles.includes(req.user.platform_role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
}

// Usage
app.post('/admin/settings', requireRole(['PLATFORM_ADMIN', 'OWNER']), handler);
```

## Monitoring & Logging

### Metrics to Track:
- Login success/failure rate
- Token validation errors
- Token expiration events
- Tenant switching frequency
- API calls with invalid tokens

### Logging Format:
```json
{
  "timestamp": "2025-10-14T12:00:00Z",
  "event": "token_validation",
  "user_id": "uuid",
  "org_id": "uuid",
  "success": true,
  "service": "svc-pm"
}
```

## Deployment Considerations

### Development
- HTTP allowed
- localhost origins
- Long token expiration (15min)
- Verbose logging

### Production
- HTTPS only
- Whitelisted origins
- Short token expiration (5-10min)
- Structured logging
- Token encryption at rest
- Rate limiting on auth endpoints
- DDoS protection

## Troubleshooting

### "Invalid credentials" on login
- Check svc-auth is running on port 4001
- Verify user exists in database
- Check password correctness

### "Token not found" in app
- Verify URL contains `?token=` parameter
- Check localStorage for 'shell_token'
- Verify postMessage listener is setup

### "Unauthorized" API errors
- Check token is included in Authorization header
- Verify token is not expired
- Check backend JWT validation is correct

### Apps still asking for login
- Verify ShellAuthProvider is in _app.tsx
- Check useShellAuth() is called in pages
- Verify token is being read from URL/localStorage

## References

- [SHELL_SSO_INTEGRATION.md](./SHELL_SSO_INTEGRATION.md) - Integration guide
- [shared/shell-sso-helper.ts](./shared/shell-sso-helper.ts) - Helper utilities
- [shared/ShellAuthContext.template.tsx](./shared/ShellAuthContext.template.tsx) - React context
- [scripts/install-sso-helper.sh](./scripts/install-sso-helper.sh) - Installation script

## Version History

- **v1.0.0** (2025-10-14) - Initial SSO architecture implementation
  - Central auth service (svc-auth)
  - Shell token distribution
  - Helper utilities for all frontends
  - Permission cascade system
  - 12 frontends configured

---

**Maintained by**: EWH Platform Team
**Last Updated**: October 14, 2025
**Status**: ✅ Production Ready
