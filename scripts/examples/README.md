# Public Views V2 - Client Examples

This directory contains example code for using the secure Public Views V2 API.

## Files

### [supabase-client-v2-example.ts](./supabase-client-v2-example.ts)

**TypeScript/JavaScript client library** for Supabase with V2 API functions.

**Features:**
- ✅ Full TypeScript types
- ✅ Error handling utilities
- ✅ Pagination support
- ✅ React hooks (optional)
- ✅ Retry logic with exponential backoff
- ✅ Permission checking

**Usage:**

```typescript
import { getActiveProjects, getTenantCustomers } from './supabase-client-v2-example';

// Fetch active projects
const { data, error } = await getActiveProjects('acme-corp', 50);

// Fetch customers with pagination
const result = await getProjectsPaginated('acme-corp', 1, 20);
```

---

## Quick Start

### 1. Install Dependencies

```bash
npm install @supabase/supabase-js
# or
yarn add @supabase/supabase-js
```

### 2. Configure Environment Variables

```bash
# .env.local
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

### 3. Import and Use

```typescript
import { getTenantProjects } from '@/lib/supabase-client-v2';

const { data, error } = await getTenantProjects('acme-corp');
```

---

## API Functions

### Generic Query

```typescript
queryTenant<T>(tenantSlug, tableName, limit?, offset?)
```

Query any whitelisted table with pagination.

**Example:**
```typescript
const { data, error } = await queryTenant<Project>(
  'acme-corp',
  'pm_projects',
  100,
  0
);
```

---

### Projects API

#### getTenantProjects
```typescript
getTenantProjects(tenantSlug, status?, limit?)
```

Get projects with optional status filter.

**Example:**
```typescript
// All projects
const { data } = await getTenantProjects('acme-corp');

// Active projects only
const { data } = await getTenantProjects('acme-corp', 'active');
```

#### getActiveProjects
```typescript
getActiveProjects(tenantSlug, limit?)
```

Shortcut for active projects.

#### getProjectsPaginated
```typescript
getProjectsPaginated(tenantSlug, page, pageSize)
```

Get projects with pagination support.

**Example:**
```typescript
const { data, hasMore } = await getProjectsPaginated('acme-corp', 1, 20);

if (hasMore) {
  // Fetch next page
  const page2 = await getProjectsPaginated('acme-corp', 2, 20);
}
```

---

### Customers API

#### getTenantCustomers
```typescript
getTenantCustomers(tenantSlug, status?, limit?)
```

Get customers with optional status filter.

**Example:**
```typescript
const { data } = await getTenantCustomers('acme-corp', 'active', 50);
```

#### getActiveCustomers
```typescript
getActiveCustomers(tenantSlug, limit?)
```

Shortcut for active customers.

---

### Tenant Info API

#### getTenantInfo
```typescript
getTenantInfo(tenantSlug)
```

Get public tenant information.

**Example:**
```typescript
const { data } = await getTenantInfo('acme-corp');
console.log(data.name, data.status);
```

#### getTenantApps
```typescript
getTenantApps(tenantSlug)
```

Get available apps for tenant.

**Example:**
```typescript
const { data } = await getTenantApps('acme-corp');
data.forEach(app => {
  console.log(app.app_name, app.is_enabled);
});
```

---

### Permission Checking

#### checkTenantAccess
```typescript
checkTenantAccess(tenantSlug)
```

Check if current user has access to tenant.

**Example:**
```typescript
const { hasAccess } = await checkTenantAccess('acme-corp');

if (!hasAccess) {
  return <div>Access Denied</div>;
}
```

---

## React Hooks

### useTenantProjects

```typescript
const { projects, loading, error } = useTenantProjects('acme-corp', 'active');
```

**Example Component:**
```tsx
function ProjectList({ tenantSlug }) {
  const { projects, loading, error } = useTenantProjects(tenantSlug);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <ul>
      {projects.map(p => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

### useTenantCustomers

```typescript
const { customers, loading, error } = useTenantCustomers('acme-corp');
```

### usePaginatedProjects

```typescript
const { projects, loading, page, hasMore, nextPage, prevPage } =
  usePaginatedProjects('acme-corp', 20);
```

**Example Component:**
```tsx
function PaginatedProjects({ tenantSlug }) {
  const { projects, loading, page, hasMore, nextPage, prevPage } =
    usePaginatedProjects(tenantSlug, 10);

  return (
    <div>
      {projects.map(p => <div key={p.id}>{p.name}</div>)}
      <button onClick={prevPage} disabled={page === 1}>Prev</button>
      <button onClick={nextPage} disabled={!hasMore}>Next</button>
    </div>
  );
}
```

---

## Error Handling

### getErrorMessage

```typescript
getErrorMessage(error: ApiError): string
```

Convert API errors to user-friendly messages.

**Example:**
```typescript
const { error } = await getTenantProjects('acme-corp');

if (error) {
  const message = getErrorMessage(error);
  toast.error(message); // "You do not have permission to access this data."
}
```

### retryRequest

```typescript
retryRequest<T>(requestFn, maxRetries?, baseDelay?)
```

Retry failed requests with exponential backoff.

**Example:**
```typescript
const { data, error } = await retryRequest(
  () => getTenantProjects('acme-corp'),
  3,    // max retries
  1000  // base delay (ms)
);
```

---

## Security Best Practices

### 1. Always Check Permissions

```typescript
// ✅ GOOD: Check access first
const { hasAccess } = await checkTenantAccess(tenantSlug);
if (!hasAccess) {
  return <AccessDenied />;
}

// ❌ BAD: Assume access
const { data } = await getTenantProjects(tenantSlug);
```

### 2. Use Pagination

```typescript
// ✅ GOOD: Paginate large datasets
const { data } = await getProjectsPaginated(tenant, 1, 20);

// ❌ BAD: Fetch everything at once
const { data } = await queryTenant(tenant, 'pm_projects', 10000);
```

### 3. Handle Errors Gracefully

```typescript
// ✅ GOOD: User-friendly error messages
if (error) {
  const message = getErrorMessage(error);
  showToast(message);
}

// ❌ BAD: Show raw error
if (error) {
  alert(error.message); // Technical jargon
}
```

### 4. Validate Input

```typescript
// ✅ GOOD: Validate tenant slug format
const validSlug = /^[a-z0-9-]+$/.test(tenantSlug);
if (!validSlug) {
  return { data: null, error: { message: 'Invalid tenant' } };
}

// ❌ BAD: Pass unvalidated input
await getTenantProjects(userInput);
```

---

## Migration from V1

### Before (V1)

```typescript
// V1 - No pagination, no status filter
const { data } = await supabase.rpc('query_tenant', {
  tenant_slug: 'acme',
  table_name: 'pm_projects'
});
```

### After (V2)

```typescript
// V2 - With pagination and filters
const { data } = await supabase.rpc('get_tenant_projects', {
  tenant_slug: 'acme',
  project_status: 'active',
  limit_rows: 50
});

// Or use helper function
const { data } = await getTenantProjects('acme', 'active', 50);
```

---

## Common Patterns

### Pattern 1: Load Data on Component Mount

```tsx
function MyComponent({ tenantSlug }) {
  const [projects, setProjects] = useState([]);

  useEffect(() => {
    async function load() {
      const { data } = await getActiveProjects(tenantSlug);
      setProjects(data || []);
    }
    load();
  }, [tenantSlug]);

  return <div>{projects.length} projects</div>;
}
```

### Pattern 2: Infinite Scroll

```tsx
function InfiniteList({ tenantSlug }) {
  const [projects, setProjects] = useState([]);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  async function loadMore() {
    const result = await getProjectsPaginated(tenantSlug, page, 20);
    setProjects(prev => [...prev, ...(result.data || [])]);
    setHasMore(result.hasMore);
    setPage(p => p + 1);
  }

  return (
    <InfiniteScroll loadMore={loadMore} hasMore={hasMore}>
      {projects.map(p => <Card key={p.id} project={p} />)}
    </InfiniteScroll>
  );
}
```

### Pattern 3: Search with Debounce

```tsx
function SearchProjects({ tenantSlug }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);

  const debouncedSearch = useMemo(
    () => debounce(async (q) => {
      const { data } = await queryTenant(tenantSlug, 'pm_projects', 50);
      const filtered = data?.filter(p =>
        p.name.toLowerCase().includes(q.toLowerCase())
      );
      setResults(filtered || []);
    }, 300),
    [tenantSlug]
  );

  useEffect(() => {
    debouncedSearch(query);
  }, [query, debouncedSearch]);

  return (
    <div>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      {results.map(p => <div key={p.id}>{p.name}</div>)}
    </div>
  );
}
```

---

## Testing

### Unit Tests

```typescript
import { getTenantProjects } from './supabase-client-v2';

describe('getTenantProjects', () => {
  it('should fetch active projects', async () => {
    const { data, error } = await getTenantProjects('test-tenant', 'active');

    expect(error).toBeNull();
    expect(data).toBeInstanceOf(Array);
    expect(data?.every(p => p.status === 'active')).toBe(true);
  });

  it('should handle permission errors', async () => {
    const { data, error } = await getTenantProjects('forbidden-tenant');

    expect(data).toBeNull();
    expect(error?.code).toBe('PGRST116');
  });
});
```

### Integration Tests

```typescript
describe('Tenant API Integration', () => {
  beforeAll(async () => {
    // Setup test tenant and data
  });

  it('should enforce tenant isolation', async () => {
    // User from tenant A tries to access tenant B
    const { hasAccess } = await checkTenantAccess('tenant-b');
    expect(hasAccess).toBe(false);
  });
});
```

---

## Performance Tips

1. **Use specific functions over generic query**
   ```typescript
   // ✅ Better (type-safe, optimized)
   await getTenantProjects('acme');

   // ❌ Slower (generic)
   await queryTenant('acme', 'pm_projects');
   ```

2. **Limit result sets**
   ```typescript
   // ✅ Good
   await getTenantProjects('acme', 'active', 20);

   // ❌ Bad (could return 1000s of rows)
   await getTenantProjects('acme');
   ```

3. **Use pagination for large datasets**
   ```typescript
   // ✅ Good
   await getProjectsPaginated('acme', 1, 50);

   // ❌ Bad
   await queryTenant('acme', 'pm_projects', 10000);
   ```

4. **Cache frequently accessed data**
   ```typescript
   // Use React Query or SWR
   const { data } = useQuery(
     ['projects', tenantSlug],
     () => getTenantProjects(tenantSlug),
     { staleTime: 5 * 60 * 1000 } // 5 minutes
   );
   ```

---

## Support

- **Documentation:** [PUBLIC_VIEWS_SECURITY_ANALYSIS.md](../PUBLIC_VIEWS_SECURITY_ANALYSIS.md)
- **Migration Guide:** [MIGRATION_GUIDE_V1_TO_V2.md](../MIGRATION_GUIDE_V1_TO_V2.md)
- **Backend Script:** [create-public-views-v2.sql](../create-public-views-v2.sql)

---

**Version:** 2.0
**Last Updated:** October 17, 2025
