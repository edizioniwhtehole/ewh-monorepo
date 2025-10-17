# ♻️ Code Reusability Strategy
## Evitare Duplicazioni nel Codice - Best Practices EWH

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: STANDARD MANDATORIO

---

## 🎯 Obiettivo

**Ridurre al minimo le duplicazioni di codice** attraverso:

1. **Shared libraries** - Pacchetti npm condivisi
2. **Database utilities** - Helper per query comuni
3. **API clients** - Client generati automaticamente
4. **Component libraries** - UI components riutilizzabili
5. **Middleware standard** - Authentication, logging, error handling
6. **Type definitions** - Types condivisi tra frontend e backend

---

## 📦 Shared Packages Architecture

```
ewh/
├── shared/
│   ├── packages/
│   │   ├── @ewh/types/              # TypeScript types condivisi
│   │   ├── @ewh/db-utils/           # Database utilities
│   │   ├── @ewh/api-client/         # API client generator
│   │   ├── @ewh/auth/               # Auth middleware & utilities
│   │   ├── @ewh/ui-components/      # React components
│   │   ├── @ewh/validation/         # Zod schemas
│   │   ├── @ewh/logger/             # Logging utilities
│   │   └── @ewh/error-handling/     # Error handling
│   └── package.json
├── svc-*/                            # Backend services
├── app-*/                            # Frontend apps
└── pnpm-workspace.yaml
```

### pnpm Workspace Configuration

```yaml
# pnpm-workspace.yaml
packages:
  - 'svc-*'
  - 'app-*'
  - 'shared/packages/*'
```

---

## 🧩 1. Shared Types Package

### @ewh/types

```typescript
// shared/packages/types/src/index.ts

/**
 * Common types used across all services
 */

// User types
export interface User {
  id: number;
  email: string;
  name: string;
  avatar?: string;
  tenantId: number;
  role: UserRole;
  status: UserStatus;
  createdAt: string;
  updatedAt: string;
}

export enum UserRole {
  OWNER = 'OWNER',
  PLATFORM_ADMIN = 'PLATFORM_ADMIN',
  TENANT_ADMIN = 'TENANT_ADMIN',
  USER = 'USER',
  GUEST = 'GUEST',
}

export enum UserStatus {
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  DELETED = 'deleted',
}

// Tenant types
export interface Tenant {
  id: number;
  name: string;
  slug: string;
  status: TenantStatus;
  plan: TenantPlan;
  createdAt: string;
  updatedAt: string;
}

export enum TenantStatus {
  ACTIVE = 'active',
  TRIAL = 'trial',
  SUSPENDED = 'suspended',
  CANCELLED = 'cancelled',
}

export enum TenantPlan {
  FREE = 'free',
  STARTER = 'starter',
  PROFESSIONAL = 'professional',
  ENTERPRISE = 'enterprise',
}

// API Response types
export interface APIResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  success: boolean;
  data: {
    items: T[];
    pagination: Pagination;
  };
}

export interface Pagination {
  total: number;
  page: number;
  limit: number;
  pages: number;
}

// Settings types
export interface Setting<T = any> {
  key: string;
  value: T;
  category: string;
  description?: string;
  updatedAt: string;
  updatedBy?: User;
}
```

**Usage in services:**

```typescript
// In any service (svc-pm, svc-inventory, etc.)
import { User, Tenant, APIResponse } from '@ewh/types';

async function getProject(id: string): Promise<APIResponse<Project>> {
  // Implementation
}
```

---

## 🗄️ 2. Database Utilities Package

### @ewh/db-utils

```typescript
// shared/packages/db-utils/src/index.ts

import { Pool, QueryResult } from 'pg';

/**
 * Base database client with common utilities
 */
export class DatabaseClient {
  constructor(private pool: Pool) {}

  /**
   * Execute query with automatic tenant isolation
   */
  async queryWithTenant<T = any>(
    tenantId: number,
    query: string,
    params: any[] = []
  ): Promise<QueryResult<T>> {
    // Automatically add tenant_id to WHERE clause
    const tenantQuery = query.replace(
      /WHERE /i,
      `WHERE tenant_id = ${tenantId} AND `
    );
    return this.pool.query<T>(tenantQuery, params);
  }

  /**
   * Insert with automatic tenant_id and created_by
   */
  async insert<T = any>(
    table: string,
    data: Record<string, any>,
    tenantId: number,
    userId: number
  ): Promise<T> {
    const insertData = {
      ...data,
      tenant_id: tenantId,
      created_by: userId,
    };

    const fields = Object.keys(insertData);
    const values = Object.values(insertData);
    const placeholders = fields.map((_, i) => `$${i + 1}`).join(', ');

    const query = `
      INSERT INTO "${table}" (${fields.map(f => `"${f}"`).join(', ')})
      VALUES (${placeholders})
      RETURNING *
    `;

    const result = await this.pool.query<T>(query, values);
    return result.rows[0];
  }

  /**
   * Update with automatic tenant isolation and updated_at
   */
  async update<T = any>(
    table: string,
    id: string,
    data: Record<string, any>,
    tenantId: number
  ): Promise<T> {
    delete data.id;
    delete data.tenant_id;
    delete data.created_at;
    delete data.created_by;

    data.updated_at = new Date().toISOString();

    const fields = Object.keys(data);
    const values = Object.values(data);
    const setClause = fields.map((f, i) => `"${f}" = $${i + 1}`).join(', ');

    const query = `
      UPDATE "${table}"
      SET ${setClause}
      WHERE id = $${fields.length + 1} AND tenant_id = $${fields.length + 2}
      RETURNING *
    `;

    const result = await this.pool.query<T>(query, [...values, id, tenantId]);
    if (result.rows.length === 0) {
      throw new Error('Record not found or access denied');
    }
    return result.rows[0];
  }

  /**
   * Delete with automatic tenant isolation
   */
  async delete(
    table: string,
    id: string,
    tenantId: number
  ): Promise<boolean> {
    const result = await this.pool.query(
      `DELETE FROM "${table}" WHERE id = $1 AND tenant_id = $2 RETURNING id`,
      [id, tenantId]
    );
    return result.rows.length > 0;
  }

  /**
   * Paginated query
   */
  async paginate<T = any>(
    table: string,
    tenantId: number,
    options: PaginationOptions = {}
  ): Promise<PaginatedResult<T>> {
    const {
      page = 1,
      limit = 50,
      sortBy = 'created_at',
      sortOrder = 'DESC',
      filters = {},
    } = options;

    const offset = (page - 1) * limit;

    // Build WHERE clause
    let whereClause = 'WHERE tenant_id = $1';
    const params: any[] = [tenantId];
    let paramIndex = 2;

    for (const [field, value] of Object.entries(filters)) {
      whereClause += ` AND "${field}" = $${paramIndex}`;
      params.push(value);
      paramIndex++;
    }

    // Get data
    const dataQuery = `
      SELECT * FROM "${table}"
      ${whereClause}
      ORDER BY "${sortBy}" ${sortOrder}
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;
    params.push(limit, offset);

    const dataResult = await this.pool.query<T>(dataQuery, params);

    // Get total count
    const countQuery = `SELECT COUNT(*) as total FROM "${table}" ${whereClause}`;
    const countResult = await this.pool.query(countQuery, params.slice(0, paramIndex - 1));
    const total = parseInt(countResult.rows[0].total);

    return {
      items: dataResult.rows,
      pagination: {
        total,
        page,
        limit,
        pages: Math.ceil(total / limit),
      },
    };
  }
}

export interface PaginationOptions {
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'ASC' | 'DESC';
  filters?: Record<string, any>;
}

export interface PaginatedResult<T> {
  items: T[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    pages: number;
  };
}
```

**Usage in services:**

```typescript
// svc-pm/src/index.ts
import { DatabaseClient } from '@ewh/db-utils';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const db = new DatabaseClient(pool);

// Automatic tenant isolation!
app.get('/projects', async (req, res) => {
  const tenantId = req.user.tenantId;
  const result = await db.paginate('projects', tenantId, {
    page: parseInt(req.query.page as string) || 1,
    limit: 50,
  });
  res.json({ success: true, data: result });
});

// Automatic created_by and tenant_id
app.post('/projects', async (req, res) => {
  const project = await db.insert('projects', req.body, req.user.tenantId, req.user.id);
  res.json({ success: true, data: project });
});
```

---

## 🔐 3. Auth Middleware Package

### @ewh/auth

```typescript
// shared/packages/auth/src/index.ts

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthenticatedRequest extends Request {
  user: {
    id: number;
    email: string;
    tenantId: number;
    role: string;
  };
}

/**
 * JWT authentication middleware
 */
export function authenticate() {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '');

      if (!token) {
        return res.status(401).json({
          success: false,
          error: 'Authentication required',
        });
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;

      (req as AuthenticatedRequest).user = {
        id: decoded.userId,
        email: decoded.email,
        tenantId: decoded.tenantId,
        role: decoded.role,
      };

      next();
    } catch (error) {
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired token',
      });
    }
  };
}

/**
 * Role-based authorization middleware
 */
export function requireRole(roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = (req as AuthenticatedRequest).user;

    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
      });
    }

    if (!roles.includes(user.role)) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions',
      });
    }

    next();
  };
}

/**
 * Tenant ownership verification
 */
export function requireTenantAccess() {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = (req as AuthenticatedRequest).user;
    const tenantId = req.params.tenantId || req.headers['x-tenant-id'];

    // OWNER and PLATFORM_ADMIN can access all tenants
    if (['OWNER', 'PLATFORM_ADMIN'].includes(user.role)) {
      return next();
    }

    // Other users can only access their tenant
    if (user.tenantId !== parseInt(tenantId as string)) {
      return res.status(403).json({
        success: false,
        error: 'Access to this tenant is forbidden',
      });
    }

    next();
  };
}
```

**Usage in services:**

```typescript
// In ANY service
import { authenticate, requireRole, AuthenticatedRequest } from '@ewh/auth';

// Public endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Protected endpoint
app.get('/projects', authenticate(), async (req, res) => {
  const user = (req as AuthenticatedRequest).user;
  // user.tenantId is available
});

// Admin only
app.delete('/projects/:id', authenticate(), requireRole(['TENANT_ADMIN']), async (req, res) => {
  // Only TENANT_ADMIN can delete
});
```

---

## 🎨 4. UI Components Package

### @ewh/ui-components

```typescript
// shared/packages/ui-components/src/Button.tsx

import React from 'react';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

export function Button({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  children,
  className = '',
  disabled,
  ...props
}: ButtonProps) {
  const baseClasses = 'rounded font-medium transition-colors focus:outline-none focus:ring-2';

  const variantClasses = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
    danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
  };

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };

  const classes = `${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`;

  return (
    <button className={classes} disabled={disabled || isLoading} {...props}>
      {isLoading ? (
        <>
          <span className="animate-spin mr-2">⏳</span>
          Loading...
        </>
      ) : (
        children
      )}
    </button>
  );
}
```

```typescript
// shared/packages/ui-components/src/DataTable.tsx

import React from 'react';

export interface Column<T> {
  key: keyof T;
  header: string;
  render?: (value: any, row: T) => React.ReactNode;
  sortable?: boolean;
}

export interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  onRowClick?: (row: T) => void;
  isLoading?: boolean;
  emptyMessage?: string;
}

export function DataTable<T extends { id: string | number }>({
  data,
  columns,
  onRowClick,
  isLoading = false,
  emptyMessage = 'No data available',
}: DataTableProps<T>) {
  if (isLoading) {
    return <div className="text-center py-8">Loading...</div>;
  }

  if (data.length === 0) {
    return <div className="text-center py-8 text-gray-500">{emptyMessage}</div>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            {columns.map(col => (
              <th
                key={String(col.key)}
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                {col.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {data.map(row => (
            <tr
              key={row.id}
              onClick={() => onRowClick?.(row)}
              className={onRowClick ? 'cursor-pointer hover:bg-gray-50' : ''}
            >
              {columns.map(col => (
                <td key={String(col.key)} className="px-6 py-4 whitespace-nowrap">
                  {col.render ? col.render(row[col.key], row) : String(row[col.key])}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

**Usage in frontend apps:**

```typescript
// In ANY frontend (app-pm-frontend, app-inventory-frontend, etc.)
import { Button, DataTable } from '@ewh/ui-components';

function ProjectsList() {
  const [projects, setProjects] = useState([]);

  return (
    <div>
      <Button variant="primary" onClick={handleCreate}>
        Create Project
      </Button>

      <DataTable
        data={projects}
        columns={[
          { key: 'name', header: 'Project Name' },
          { key: 'status', header: 'Status' },
          { key: 'createdAt', header: 'Created', render: (val) => formatDate(val) },
        ]}
        onRowClick={handleRowClick}
      />
    </div>
  );
}
```

---

## 🔧 5. API Client Generator

### @ewh/api-client

```typescript
// shared/packages/api-client/src/index.ts

import axios, { AxiosInstance } from 'axios';
import { APIResponse, PaginatedResponse } from '@ewh/types';

/**
 * Base API client with authentication
 */
export class APIClient {
  private client: AxiosInstance;

  constructor(baseURL: string) {
    this.client = axios.create({
      baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Request interceptor
    this.client.interceptors.request.use(config => {
      const token = localStorage.getItem('auth_token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }

      const tenantId = localStorage.getItem('tenant_id');
      if (tenantId) {
        config.headers['X-Tenant-ID'] = tenantId;
      }

      return config;
    });

    // Response interceptor
    this.client.interceptors.response.use(
      response => response.data,
      error => {
        if (error.response?.status === 401) {
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  async get<T>(url: string, params?: any): Promise<APIResponse<T>> {
    return this.client.get(url, { params });
  }

  async post<T>(url: string, data?: any): Promise<APIResponse<T>> {
    return this.client.post(url, data);
  }

  async put<T>(url: string, data?: any): Promise<APIResponse<T>> {
    return this.client.put(url, data);
  }

  async delete<T>(url: string): Promise<APIResponse<T>> {
    return this.client.delete(url);
  }
}

/**
 * Resource-based API client
 */
export class ResourceClient<T> {
  constructor(private client: APIClient, private resource: string) {}

  async list(params?: any): Promise<PaginatedResponse<T>> {
    return this.client.get(`/${this.resource}`, params);
  }

  async get(id: string | number): Promise<APIResponse<T>> {
    return this.client.get(`/${this.resource}/${id}`);
  }

  async create(data: Partial<T>): Promise<APIResponse<T>> {
    return this.client.post(`/${this.resource}`, data);
  }

  async update(id: string | number, data: Partial<T>): Promise<APIResponse<T>> {
    return this.client.put(`/${this.resource}/${id}`, data);
  }

  async delete(id: string | number): Promise<APIResponse<void>> {
    return this.client.delete(`/${this.resource}/${id}`);
  }
}
```

**Usage in frontend:**

```typescript
// app-pm-frontend/src/api/projects.ts
import { APIClient, ResourceClient } from '@ewh/api-client';
import { Project } from '@ewh/types';

const apiClient = new APIClient('http://localhost:5500');
export const projectsAPI = new ResourceClient<Project>(apiClient, 'projects');

// Usage in components
const projects = await projectsAPI.list({ page: 1, limit: 50 });
const project = await projectsAPI.get('project-123');
const newProject = await projectsAPI.create({ name: 'New Project' });
```

---

## 📝 6. Validation Package

### @ewh/validation

```typescript
// shared/packages/validation/src/schemas.ts

import { z } from 'zod';

/**
 * Common validation schemas
 */

export const emailSchema = z.string().email('Invalid email address');

export const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
  .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
  .regex(/[0-9]/, 'Password must contain at least one number');

export const userSchema = z.object({
  email: emailSchema,
  name: z.string().min(2, 'Name must be at least 2 characters'),
  password: passwordSchema,
  role: z.enum(['OWNER', 'PLATFORM_ADMIN', 'TENANT_ADMIN', 'USER', 'GUEST']),
});

export const projectSchema = z.object({
  name: z.string().min(3, 'Project name must be at least 3 characters'),
  description: z.string().optional(),
  startDate: z.string().datetime().optional(),
  dueDate: z.string().datetime().optional(),
  budget: z.number().positive().optional(),
});

export const paginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(50),
  sortBy: z.string().optional(),
  sortOrder: z.enum(['ASC', 'DESC']).default('DESC'),
});
```

**Usage in backend:**

```typescript
// svc-pm/src/routes/projects.ts
import { projectSchema, paginationSchema } from '@ewh/validation';

app.post('/projects', async (req, res) => {
  try {
    // Validate request body
    const data = projectSchema.parse(req.body);

    // Create project with validated data
    const project = await db.insert('projects', data, req.user.tenantId, req.user.id);

    res.json({ success: true, data: project });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        error: 'Validation error',
        details: error.errors,
      });
    }
    throw error;
  }
});
```

---

## 📊 Implementation Plan

### Phase 1: Setup Workspace (Week 1)

```bash
# Create shared packages
mkdir -p shared/packages/{types,db-utils,auth,ui-components,api-client,validation}

# Initialize each package
cd shared/packages/types
npm init -y
# Repeat for all packages

# Setup pnpm workspace
cat > pnpm-workspace.yaml << EOF
packages:
  - 'svc-*'
  - 'app-*'
  - 'shared/packages/*'
EOF

# Install dependencies
pnpm install
```

### Phase 2: Migrate Existing Code (Week 2-3)

- [ ] Extract common types to `@ewh/types`
- [ ] Extract database utilities to `@ewh/db-utils`
- [ ] Extract auth middleware to `@ewh/auth`
- [ ] Extract UI components to `@ewh/ui-components`
- [ ] Update all services to use shared packages
- [ ] Update all frontends to use shared packages

### Phase 3: Create New Features (Week 4)

- [ ] Use shared packages for all new features
- [ ] Document shared packages usage
- [ ] Add tests for shared packages
- [ ] Setup CI/CD for shared packages

---

## ✅ Benefits

1. **No Code Duplication**: Write once, use everywhere
2. **Type Safety**: Shared types ensure consistency
3. **Easier Maintenance**: Fix bug once, fixed everywhere
4. **Faster Development**: Reuse tested components/utilities
5. **Consistency**: Same UX across all apps
6. **Easier Onboarding**: New developers learn shared patterns

---

**Questo documento è MANDATORIO per evitare duplicazioni.**

**Usa SEMPRE shared packages per codice comune.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team
