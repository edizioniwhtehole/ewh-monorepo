# Shell SSO Integration Guide

## Overview

Tutte le app frontend devono implementare l'integrazione SSO con la Shell per evitare login multipli.

La Shell passa il token JWT in **2 modi**:
1. **URL parameters** - `?token=xxx&tenant_id=yyy&tenant_slug=zzz`
2. **postMessage API** - per aggiornamenti dinamici

## Implementazione per App Frontend

### Step 1: Leggere Token dall'URL

```typescript
// src/lib/auth.ts o src/utils/shell-sso.ts

export function getShellAuthFromURL(): {
  token: string | null;
  tenantId: string | null;
  tenantSlug: string | null;
} {
  if (typeof window === 'undefined') return { token: null, tenantId: null, tenantSlug: null };

  const params = new URLSearchParams(window.location.search);
  return {
    token: params.get('token'),
    tenantId: params.get('tenant_id'),
    tenantSlug: params.get('tenant_slug'),
  };
}

// Rimuovi params dall'URL dopo aver letto
export function cleanAuthParamsFromURL() {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.delete('token');
  url.searchParams.delete('tenant_id');
  url.searchParams.delete('tenant_slug');
  window.history.replaceState({}, '', url.toString());
}
```

### Step 2: Context Provider (React)

```typescript
// src/context/ShellAuthContext.tsx

import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { getShellAuthFromURL, cleanAuthParamsFromURL } from '../lib/shell-sso';

interface ShellAuthContextType {
  token: string | null;
  tenantId: string | null;
  tenantSlug: string | null;
  isAuthenticated: boolean;
}

const ShellAuthContext = createContext<ShellAuthContextType | undefined>(undefined);

export function ShellAuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(null);
  const [tenantId, setTenantId] = useState<string | null>(null);
  const [tenantSlug, setTenantSlug] = useState<string | null>(null);

  useEffect(() => {
    // 1. Leggi da URL params (priorità alta)
    const urlAuth = getShellAuthFromURL();
    if (urlAuth.token) {
      setToken(urlAuth.token);
      setTenantId(urlAuth.tenantId);
      setTenantSlug(urlAuth.tenantSlug);

      // Salva in localStorage
      localStorage.setItem('shell_token', urlAuth.token);
      if (urlAuth.tenantId) localStorage.setItem('shell_tenant_id', urlAuth.tenantId);
      if (urlAuth.tenantSlug) localStorage.setItem('shell_tenant_slug', urlAuth.tenantSlug);

      // Pulisci URL
      cleanAuthParamsFromURL();
    } else {
      // 2. Fallback a localStorage
      const storedToken = localStorage.getItem('shell_token');
      const storedTenantId = localStorage.getItem('shell_tenant_id');
      const storedTenantSlug = localStorage.getItem('shell_tenant_slug');

      if (storedToken) {
        setToken(storedToken);
        setTenantId(storedTenantId);
        setTenantSlug(storedTenantSlug);
      }
    }

    // 3. Ascolta postMessage dalla Shell
    const handleMessage = (event: MessageEvent) => {
      if (event.data && event.data.type === 'AUTH_CONTEXT') {
        const { token: newToken, tenant } = event.data;
        if (newToken) {
          setToken(newToken);
          localStorage.setItem('shell_token', newToken);
        }
        if (tenant) {
          setTenantId(tenant.id);
          setTenantSlug(tenant.slug);
          localStorage.setItem('shell_tenant_id', tenant.id);
          localStorage.setItem('shell_tenant_slug', tenant.slug);
        }
      }
    };

    window.addEventListener('message', handleMessage);

    // 4. Notifica shell che sei pronto
    window.parent.postMessage({ type: 'IFRAME_READY' }, '*');

    return () => window.removeEventListener('message', handleMessage);
  }, []);

  return (
    <ShellAuthContext.Provider
      value={{
        token,
        tenantId,
        tenantSlug,
        isAuthenticated: !!token,
      }}
    >
      {children}
    </ShellAuthContext.Provider>
  );
}

export function useShellAuth() {
  const context = useContext(ShellAuthContext);
  if (context === undefined) {
    throw new Error('useShellAuth must be used within a ShellAuthProvider');
  }
  return context;
}
```

### Step 3: Integrazione _app.tsx

```typescript
// src/pages/_app.tsx

import type { AppProps } from 'next/app';
import { ShellAuthProvider } from '../context/ShellAuthContext';

export default function App({ Component, pageProps }: AppProps) {
  return (
    <ShellAuthProvider>
      <Component {...pageProps} />
    </ShellAuthProvider>
  );
}
```

### Step 4: Uso nelle Pagine

```typescript
// src/pages/index.tsx

import { useShellAuth } from '../context/ShellAuthContext';

export default function Home() {
  const { token, tenantId, isAuthenticated } = useShellAuth();

  if (!isAuthenticated) {
    return <div>Not authenticated - redirecting to shell...</div>;
  }

  return (
    <div>
      <h1>Welcome!</h1>
      <p>Tenant: {tenantId}</p>
      {/* Usa il token per le API calls */}
    </div>
  );
}
```

### Step 5: API Calls con Token

```typescript
// src/lib/api.ts

import { getShellAuthFromURL } from './shell-sso';

export async function apiCall(endpoint: string, options: RequestInit = {}) {
  // Prendi token da localStorage o URL
  const { token } = getShellAuthFromURL();
  const storedToken = localStorage.getItem('shell_token');
  const authToken = token || storedToken;

  const response = await fetch(endpoint, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  });

  return response;
}
```

## Checklist per ogni Frontend

- [ ] Implementare `getShellAuthFromURL()` helper
- [ ] Creare `ShellAuthContext` provider
- [ ] Aggiungere provider in `_app.tsx`
- [ ] Ascoltare `message` events per aggiornamenti
- [ ] Notificare shell con `IFRAME_READY`
- [ ] Usare token nelle API calls
- [ ] Gestire tenant switching

## Testing

1. Fai login nella Shell
2. Clicca su un'app dalla dashboard
3. L'app dovrebbe **auto-autenticarsi** senza chiedere credenziali
4. Cambia tenant nella shell → l'app dovrebbe aggiornarsi

## Vantaggi

✅ **Single Sign-On** - login una volta sola
✅ **Token centralizzato** - gestito dalla shell
✅ **Tenant switching** automatico
✅ **Nessun re-login** quando cambi app
✅ **Sicurezza** - token JWT con scadenza

## Servizi che DEVONO implementare questo:

- [x] app-shell-frontend (già fatto)
- [ ] app-pm-frontend
- [ ] app-dam (Media Library)
- [ ] app-approvals-frontend
- [ ] app-inventory-frontend
- [ ] app-procurement-frontend
- [ ] app-quotations-frontend
- [ ] app-orders-purchase-frontend
- [ ] app-orders-sales-frontend
- [ ] app-settings-frontend
- [ ] Tutti gli altri frontend...

## Note per Backend Services

I backend service (svc-*) devono:
1. Validare il JWT token nel header `Authorization: Bearer <token>`
2. Estrarre `org_id` e `tenant_role` dal JWT payload
3. Filtrare dati per tenant corrente
4. Verificare permessi basati su `platform_role` e `tenant_role`
