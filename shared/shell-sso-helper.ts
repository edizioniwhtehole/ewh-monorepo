/**
 * Shell SSO Helper - Shared utility for all frontend apps
 *
 * This file should be copied to each frontend app at:
 * src/lib/shell-sso.ts or src/utils/shell-sso.ts
 *
 * Usage: See SHELL_SSO_INTEGRATION.md
 */

export interface ShellAuthData {
  token: string | null;
  tenantId: string | null;
  tenantSlug: string | null;
}

/**
 * Get authentication data from URL parameters
 * Shell passes token via URL when opening app in iframe
 */
export function getShellAuthFromURL(): ShellAuthData {
  if (typeof window === 'undefined') {
    return { token: null, tenantId: null, tenantSlug: null };
  }

  const params = new URLSearchParams(window.location.search);
  return {
    token: params.get('token'),
    tenantId: params.get('tenant_id'),
    tenantSlug: params.get('tenant_slug'),
  };
}

/**
 * Clean auth parameters from URL after reading them
 * Prevents token from being visible in browser history
 */
export function cleanAuthParamsFromURL(): void {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.delete('token');
  url.searchParams.delete('tenant_id');
  url.searchParams.delete('tenant_slug');
  window.history.replaceState({}, '', url.toString());
}

/**
 * Get stored authentication data from localStorage
 */
export function getStoredShellAuth(): ShellAuthData {
  if (typeof window === 'undefined') {
    return { token: null, tenantId: null, tenantSlug: null };
  }

  return {
    token: localStorage.getItem('shell_token'),
    tenantId: localStorage.getItem('shell_tenant_id'),
    tenantSlug: localStorage.getItem('shell_tenant_slug'),
  };
}

/**
 * Store authentication data in localStorage
 */
export function storeShellAuth(auth: ShellAuthData): void {
  if (typeof window === 'undefined') return;

  if (auth.token) localStorage.setItem('shell_token', auth.token);
  if (auth.tenantId) localStorage.setItem('shell_tenant_id', auth.tenantId);
  if (auth.tenantSlug) localStorage.setItem('shell_tenant_slug', auth.tenantSlug);
}

/**
 * Clear authentication data from localStorage
 */
export function clearShellAuth(): void {
  if (typeof window === 'undefined') return;

  localStorage.removeItem('shell_token');
  localStorage.removeItem('shell_tenant_id');
  localStorage.removeItem('shell_tenant_slug');
}

/**
 * Setup listener for postMessage from shell
 * Call this in useEffect or componentDidMount
 */
export function setupShellAuthListener(
  onAuthUpdate: (auth: ShellAuthData) => void
): () => void {
  if (typeof window === 'undefined') return () => {};

  const handleMessage = (event: MessageEvent) => {
    // Only accept messages from same origin or known shell domains
    // In production, add proper origin validation

    if (event.data && event.data.type === 'AUTH_CONTEXT') {
      const { token, tenant } = event.data;
      const authData: ShellAuthData = {
        token: token || null,
        tenantId: tenant?.id || null,
        tenantSlug: tenant?.slug || null,
      };

      onAuthUpdate(authData);
      storeShellAuth(authData);
    }

    if (event.data && event.data.type === 'THEME_CHANGE') {
      // Optional: handle theme changes
      const { theme } = event.data;
      if (theme) {
        document.documentElement.classList.toggle('dark', theme === 'dark');
      }
    }
  };

  window.addEventListener('message', handleMessage);

  // Notify shell that iframe is ready
  window.parent.postMessage({ type: 'IFRAME_READY' }, '*');

  // Return cleanup function
  return () => window.removeEventListener('message', handleMessage);
}

/**
 * Initialize shell auth - call this once on app startup
 * Returns the initial auth data
 */
export function initializeShellAuth(): ShellAuthData {
  // Priority 1: URL parameters (fresh from shell)
  const urlAuth = getShellAuthFromURL();
  if (urlAuth.token) {
    storeShellAuth(urlAuth);
    cleanAuthParamsFromURL();
    return urlAuth;
  }

  // Priority 2: localStorage (cached)
  return getStoredShellAuth();
}

/**
 * Create Authorization header for API calls
 */
export function getAuthHeader(): Record<string, string> {
  const { token } = getStoredShellAuth();
  if (!token) return {};

  return {
    'Authorization': `Bearer ${token}`,
  };
}

/**
 * Check if token is expired
 * Assumes JWT format with exp claim
 */
export function isTokenExpired(token: string): boolean {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp * 1000 < Date.now();
  } catch {
    return true;
  }
}

/**
 * Get current tenant context
 */
export function getCurrentTenant(): { id: string | null; slug: string | null } {
  const { tenantId, tenantSlug } = getStoredShellAuth();
  return { id: tenantId, slug: tenantSlug };
}
