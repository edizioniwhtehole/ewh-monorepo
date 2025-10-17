# CMS Integration Examples

## Admin Frontend Integration

```typescript
// Example: Add CMS button to Admin Dashboard
// File: app-admin-frontend/pages/admin/dashboard.tsx

import React from 'react';
import { CMSModal, useCMSModal } from '@ewh/shared-widgets/adapters/CMSModal';
import { Settings } from 'lucide-react';

export default function AdminDashboard() {
  const { isOpen, open, close } = useCMSModal();

  return (
    <div>
      {/* Existing dashboard content */}
      
      {/* CMS Button in header */}
      <button
        onClick={() => open('/pages')}
        className="flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2"
      >
        <Settings size={20} />
        Manage Pages
      </button>

      {/* CMS Modal */}
      <CMSModal
        isOpen={isOpen}
        onClose={close}
        context={{
          tenantId: user.tenantId,
          userId: user.id,
          userRole: 'PLATFORM_ADMIN'
        }}
      />
    </div>
  );
}

```

## Tenant App Integration

```typescript
// Example: Add CMS to Tenant Dashboard
// File: app-tenant/pages/dashboard.tsx

import React from 'react';
import { CMSModal, useCMSModal } from '@ewh/shared-widgets/adapters/CMSModal';
import { Edit } from 'lucide-react';

export default function TenantDashboard() {
  const { isOpen, open, close } = useCMSModal();

  return (
    <div>
      {/* Tenant dashboard content */}
      
      {/* CMS Access for tenant admin */}
      <button
        onClick={() => open('/pages')}
        className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2"
      >
        <Edit size={20} />
        Customize Pages
      </button>

      {/* CMS Modal - tenant context */}
      <CMSModal
        isOpen={isOpen}
        onClose={close}
        initialPage="/pages"
        context={{
          tenantId: tenant.id,
          userId: user.id,
          userRole: 'TENANT_ADMIN'
        }}
      />
    </div>
  );
}

```

