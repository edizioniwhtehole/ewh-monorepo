# EWH Platform - Shared Auth Middleware

Shared authentication and authorization middleware for all EWH services.

## Installation

In your service:

```bash
npm install jsonwebtoken @types/jsonwebtoken
```

Then copy or symlink the auth.ts file to your service.

## Usage

### Basic Authentication

```typescript
import express from 'express';
import { authMiddleware } from './middleware/auth';

const app = express();

// Protect all /api routes
app.use('/api', authMiddleware);

// Public routes (no auth)
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Protected routes
app.get('/api/data', (req, res) => {
  // req.user is populated by authMiddleware
  console.log('User:', req.user.email);
  res.json({ data: 'protected' });
});
```

### Optional Authentication

```typescript
import { optionalAuth } from './middleware/auth';

// Route works with or without auth
app.get('/public-or-private', optionalAuth, (req, res) => {
  if (req.user) {
    res.json({ message: `Hello ${req.user.email}` });
  } else {
    res.json({ message: 'Hello guest' });
  }
});
```

### Role-Based Access Control

```typescript
import { authMiddleware, requireRole } from './middleware/auth';

// Only platform admins and owners can access
app.get('/admin/users',
  authMiddleware,
  requireRole(['PLATFORM_ADMIN', 'OWNER']),
  (req, res) => {
    // Handler
  }
);
```

### Tenant Isolation

```typescript
import { authMiddleware, ensureTenantIsolation } from './middleware/auth';

// Ensure users can only access their tenant's data
app.use('/api', authMiddleware, ensureTenantIsolation);

app.get('/api/projects', (req, res) => {
  const tenantId = req.tenantId; // Use this in DB queries
  // SELECT * FROM projects WHERE tenant_id = $1
});
```

## Environment Variables

Required:

```env
JWT_SECRET=your-secret-key-here
JWT_ISSUER=http://svc-auth:4001
JWT_AUDIENCE=ewh-saas
```

## Request Object Extensions

After authentication, the request object will have:

```typescript
req.user = {
  userId: string;      // User's unique ID
  email: string;       // User's email
  platformRole: string; // OWNER, PLATFORM_ADMIN, or USER
  tenantRole?: string;  // TENANT_OWNER, TENANT_ADMIN, or TENANT_MEMBER
  tenantId?: string;    // User's default tenant ID
};

req.tenantId = string; // Tenant ID for multi-tenant requests
```

## Middleware Functions

| Function | Description |
|----------|-------------|
| `authMiddleware` | Required authentication - returns 401 if no token |
| `optionalAuth` | Optional authentication - continues without token |
| `requireRole(roles[])` | Checks user has one of the specified roles |
| `ensureTenantIsolation` | Prevents cross-tenant data access |
| `extractTenantHeader` | Reads X-Tenant-ID header for multi-tenant |

## Error Responses

**401 Unauthorized:**
```json
{
  "error": "Unauthorized",
  "message": "No authentication token provided"
}
```

**401 Token Expired:**
```json
{
  "error": "TokenExpired",
  "message": "Authentication token has expired"
}
```

**403 Forbidden:**
```json
{
  "error": "Forbidden",
  "message": "Required role: PLATFORM_ADMIN or OWNER"
}
```

## Integration Example

Complete service with auth:

```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { authMiddleware, requireRole } from './middleware/auth';

const app = express();

// Security
app.use(helmet());
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

// Public routes
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Protected routes
app.use('/api', authMiddleware);

app.get('/api/data', (req, res) => {
  res.json({
    user: req.user.email,
    tenant: req.tenantId,
    data: []
  });
});

// Admin-only routes
app.get('/api/admin/settings',
  requireRole(['PLATFORM_ADMIN', 'OWNER']),
  (req, res) => {
    // Admin handler
  }
);

app.listen(5000, () => {
  console.log('Service running on port 5000');
});
```

## Best Practices

1. **Always protect /api routes** with authMiddleware
2. **Keep /health public** for monitoring
3. **Use tenant isolation** for multi-tenant data
4. **Check roles** for sensitive operations
5. **Store JWT_SECRET** in environment variables, not code
6. **Use HTTPS** in production
7. **Validate tenant ID** in all database queries

## Testing

Test with curl:

```bash
# Get token from auth service
TOKEN=$(curl -s -X POST http://localhost:4001/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}' \
  | jq -r '.accessToken')

# Use token
curl http://localhost:5000/api/data \
  -H "Authorization: Bearer $TOKEN"
```
