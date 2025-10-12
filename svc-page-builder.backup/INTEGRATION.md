# Page Builder Integration Guide

## Overview

`svc-page-builder` is a standalone GrapesJS-based page builder service that can be integrated into admin frontends, admin backends, and tenant sites.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      svc-page-builder                        │
├─────────────────┬─────────────────┬─────────────────────────┤
│   Backend API   │  Frontend Editor │   Renderer Package      │
│   Port 5100     │   Port 5101      │   @ewh/pb-renderer      │
└─────────────────┴─────────────────┴─────────────────────────┘
         ↑                 ↑                     ↑
         │                 │                     │
         │                 │                     │
    ┌────┴────┐      ┌─────┴──────┐      ┌──────┴─────┐
    │ Admin   │      │   Admin    │      │   Tenant   │
    │ Backend │      │  Frontend  │      │   Sites    │
    └─────────┘      └────────────┘      └────────────┘
```

## Integration Methods

### 1. Admin Frontend (Iframe Embed)

Embed the page builder editor in your admin interface:

```tsx
// app-admin-frontend/src/pages/PageEditor.tsx
import React from 'react';

export default function PageEditor({ pageId }: { pageId: string }) {
  const editorUrl = `http://localhost:5101?pageId=${pageId}`;

  return (
    <div className="h-screen">
      <iframe
        src={editorUrl}
        className="w-full h-full border-0"
        title="Page Builder Editor"
      />
    </div>
  );
}
```

**Pros:**
- Complete isolation (no dependency conflicts)
- Easy to update independently
- Full GrapesJS UI experience

**Cons:**
- Communication requires postMessage
- Separate authentication needed

### 2. Admin Frontend (Package Import)

Use the renderer to display pages in admin preview:

```tsx
// app-admin-frontend/src/components/PagePreview.tsx
import { PageRenderer } from '@ewh/page-builder-renderer';

export default function PagePreview({ pageId, tenantId }: Props) {
  return (
    <PageRenderer
      pageId={pageId}
      tenantId={tenantId}
      dataContext={{
        cms: {
          siteName: 'My Site',
          // ... other CMS data
        }
      }}
    />
  );
}
```

### 3. Tenant Sites (Next.js)

Render published pages on tenant sites:

```tsx
// Tenant site: app/[slug]/page.tsx
import { PageRenderer } from '@ewh/page-builder-renderer';
import { getPageBySlug } from '@/lib/api';

export default async function DynamicPage({ params }: { params: { slug: string } }) {
  const tenantId = getTenantId(); // From domain/subdomain
  const pageData = await getPageBySlug(params.slug, tenantId);

  if (!pageData) {
    notFound();
  }

  // Fetch CMS data for bindings
  const cmsData = await getCMSData(tenantId);

  return (
    <PageRenderer
      pageData={pageData}
      tenantId={tenantId}
      dataContext={{
        cms: cmsData,
        tenant: {
          id: tenantId,
          name: cmsData.siteName,
        },
      }}
    />
  );
}

// Generate static pages at build time
export async function generateStaticParams() {
  const pages = await getAllPublishedPages();
  return pages.map((page) => ({
    slug: page.slug,
  }));
}
```

### 4. API Integration

Direct API calls for programmatic control:

```typescript
// Create a new page
const response = await fetch('http://localhost:5100/api/pages', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Tenant-Id': tenantId,
  },
  body: JSON.stringify({
    slug: 'about-us',
    title: 'About Us',
    components: [],
    styles: '',
  }),
});

// Publish a page
await fetch(`http://localhost:5100/api/pages/${pageId}/publish`, {
  method: 'POST',
  headers: {
    'X-Tenant-Id': tenantId,
  },
});

// Get published pages
const pages = await fetch('http://localhost:5100/api/pages?status=published', {
  headers: {
    'X-Tenant-Id': tenantId,
  },
});
```

## Data Binding

Use `{{variable}}` syntax for dynamic content:

### In GrapesJS Editor

```html
<h1>{{cms.hero.title}}</h1>
<p>{{cms.hero.description}}</p>
<img src="{{cms.hero.image}}" alt="{{cms.hero.imageAlt}}" />
```

### In Renderer

```tsx
<PageRenderer
  pageData={pageData}
  dataContext={{
    cms: {
      hero: {
        title: 'Welcome to Our Site',
        description: 'We build amazing things',
        image: 'https://cdn.example.com/hero.jpg',
        imageAlt: 'Hero image',
      },
    },
    user: {
      name: 'John Doe',
      email: 'john@example.com',
    },
    product: {
      name: 'Premium Plan',
      price: '$99/mo',
    },
  }}
/>
```

## Database Setup

### Using Main EWH Database

```bash
cd svc-page-builder
psql -h localhost -U ewh -d ewh_master -f database/schema.sql
```

### Using Separate Database

```bash
createdb ewh_pagebuilder
psql -h localhost -U ewh -d ewh_pagebuilder -f database/schema.sql
```

Update `backend/.env`:

```env
DATABASE_URL=postgresql://ewh:ewh@localhost:5432/ewh_pagebuilder
```

## Environment Variables

### Backend (.env)

```env
PORT=5100
DATABASE_URL=postgresql://ewh:ewh@localhost:5432/ewh_master
NODE_ENV=development
CORS_ORIGIN=http://localhost:3200,http://localhost:3000
```

### Frontend (optional .env)

```env
VITE_API_URL=http://localhost:5100
```

## Development Workflow

### 1. Start Services

```bash
# Terminal 1: Backend API
cd svc-page-builder
pnpm dev:backend

# Terminal 2: Frontend Editor
cd svc-page-builder
pnpm dev:frontend
```

### 2. Access Editor

Navigate to `http://localhost:5101` to open the GrapesJS editor.

### 3. Create Page

1. Drag blocks from left sidebar
2. Customize styles in right sidebar
3. Save (auto-saves every 3 actions)
4. Publish when ready

### 4. View Published Page

```tsx
// In your tenant site
import { PageRenderer } from '@ewh/page-builder-renderer';

<PageRenderer pageId="xxx" tenantId="xxx" />
```

## Advanced: Custom Components

Add custom shadcn/ui components to the editor:

### 1. Add to ComponentMap

```tsx
// renderer/src/components/ComponentMap.tsx
const CustomComponents: Record<string, React.ComponentType<any>> = {
  // ... existing components

  'custom-hero': ({ children, ...props }) => (
    <section className="relative h-screen flex items-center justify-center">
      <div className="container mx-auto px-4 text-center">
        {children}
      </div>
    </section>
  ),
};
```

### 2. Add to GrapesJS Blocks

```typescript
// frontend/src/plugins/shadcn-blocks.ts
blockManager.add('custom-hero', {
  label: 'Hero Section',
  category: 'Custom',
  content: {
    type: 'custom-hero',
    droppable: true,
    components: [
      {
        type: 'text',
        tagName: 'h1',
        content: '{{cms.hero.title}}',
        classes: ['text-5xl', 'font-bold', 'mb-4'],
      },
      {
        type: 'text',
        tagName: 'p',
        content: '{{cms.hero.subtitle}}',
        classes: ['text-xl', 'text-gray-600'],
      },
    ],
  },
});
```

## Multi-Tenant Isolation

All pages are isolated by `tenant_id`:

```sql
SELECT * FROM pb_pages WHERE tenant_id = 'tenant-abc-123';
```

Always pass `X-Tenant-Id` header:

```typescript
fetch('/api/pages', {
  headers: {
    'X-Tenant-Id': getCurrentTenantId(),
  },
});
```

## Publishing Workflow

```
Draft → Review → Published
  ↓       ↓         ↓
  Save    Approve   Deploy
```

### States

- **draft**: Work in progress, not visible
- **review**: Ready for approval
- **published**: Live on tenant site
- **archived**: Hidden but preserved

### Versioning

Each publish creates a new version:

```sql
SELECT * FROM pb_pages
WHERE slug = 'about-us'
AND tenant_id = 'tenant-123'
ORDER BY version DESC;
```

Rollback to previous version:

```typescript
const oldVersion = await db.query(
  'SELECT * FROM pb_pages WHERE id = $1',
  [parentVersionId]
);

await db.query(
  'INSERT INTO pb_pages (tenant_id, slug, title, components, styles, parent_version_id) VALUES ($1, $2, $3, $4, $5, $6)',
  [tenantId, slug, title, oldVersion.components, oldVersion.styles, oldVersion.id]
);
```

## Performance Optimization

### 1. Static Generation (Next.js)

```tsx
export async function generateStaticParams() {
  const pages = await getAllPublishedPages();
  return pages.map((page) => ({ slug: page.slug }));
}
```

### 2. Incremental Static Regeneration

```tsx
export const revalidate = 3600; // Revalidate every hour
```

### 3. Edge Caching

```tsx
export const runtime = 'edge';
```

### 4. Component Preloading

```tsx
import { PageRenderer } from '@ewh/page-builder-renderer';

// Preload page data
export async function getServerSideProps({ params }) {
  const pageData = await getPageBySlug(params.slug);
  return { props: { pageData } };
}

// No need to fetch in component
<PageRenderer pageData={pageData} />
```

## Security

### 1. Sanitize HTML

The renderer uses `dangerouslySetInnerHTML` for HTML content. Ensure GrapesJS editor sanitizes input or implement CSP:

```tsx
// Add to Next.js config
const ContentSecurityPolicy = `
  default-src 'self';
  script-src 'self' 'unsafe-inline' 'unsafe-eval';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
`;
```

### 2. Tenant Isolation

Always validate `X-Tenant-Id` on backend:

```typescript
app.use((req, res, next) => {
  const tenantId = req.headers['x-tenant-id'];
  if (!tenantId) {
    return res.status(400).json({ error: 'Missing tenant ID' });
  }
  // Validate tenantId exists and user has access
  next();
});
```

### 3. RBAC

Implement role-based access:

```typescript
// Only editors and admins can publish
if (!['editor', 'admin'].includes(userRole)) {
  return res.status(403).json({ error: 'Forbidden' });
}
```

## Troubleshooting

### CORS Issues

Update backend CORS config:

```typescript
app.use(cors({
  origin: ['http://localhost:3200', 'http://localhost:3000'],
  credentials: true,
}));
```

### Port Conflicts

Change ports in:
- Backend: `backend/.env` → `PORT=5100`
- Frontend: `frontend/vite.config.ts` → `server.port: 5101`

### Database Connection

Test connection:

```bash
psql -h localhost -U ewh -d ewh_master -c "SELECT * FROM pb_pages LIMIT 1;"
```

## License

Proprietary - EWH Platform
