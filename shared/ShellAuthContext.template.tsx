/**
 * ShellAuthContext Template - Copy this to each frontend app
 *
 * Location: src/context/ShellAuthContext.tsx
 *
 * This provides a React Context for accessing shell authentication
 *
 * Usage in _app.tsx:
 *
 * import { ShellAuthProvider } from '../context/ShellAuthContext';
 *
 * export default function App({ Component, pageProps }) {
 *   return (
 *     <ShellAuthProvider>
 *       <Component {...pageProps} />
 *     </ShellAuthProvider>
 *   );
 * }
 *
 * Usage in pages:
 *
 * import { useShellAuth } from '../context/ShellAuthContext';
 *
 * export default function MyPage() {
 *   const { token, tenantId, isAuthenticated } = useShellAuth();
 *   // ...
 * }
 */

import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import {
  initializeShellAuth,
  setupShellAuthListener,
  storeShellAuth,
  clearShellAuth,
  isTokenExpired,
  getCurrentTenant,
  type ShellAuthData,
} from '../lib/shell-sso'; // Adjust path as needed

interface ShellAuthContextType extends ShellAuthData {
  isAuthenticated: boolean;
  isLoading: boolean;
  logout: () => void;
}

const ShellAuthContext = createContext<ShellAuthContextType | undefined>(undefined);

export function ShellAuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuth] = useState<ShellAuthData>({ token: null, tenantId: null, tenantSlug: null });
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    console.log('[ShellAuth] Initializing...');

    // Initialize auth from URL or localStorage
    const initialAuth = initializeShellAuth();
    console.log('[ShellAuth] Initial auth:', initialAuth.token ? 'Token found' : 'No token');

    // Check if token is expired
    if (initialAuth.token && isTokenExpired(initialAuth.token)) {
      console.log('[ShellAuth] Token expired, clearing...');
      clearShellAuth();
      setAuth({ token: null, tenantId: null, tenantSlug: null });
    } else {
      setAuth(initialAuth);
    }

    setIsLoading(false);

    // Setup listener for updates from shell
    const cleanup = setupShellAuthListener((newAuth) => {
      console.log('[ShellAuth] Received update from shell');
      setAuth(newAuth);
    });

    return cleanup;
  }, []);

  const logout = () => {
    clearShellAuth();
    setAuth({ token: null, tenantId: null, tenantSlug: null });
    // Optionally redirect to shell login
    window.parent.location.href = '/login';
  };

  return (
    <ShellAuthContext.Provider
      value={{
        ...auth,
        isAuthenticated: !!auth.token && !isTokenExpired(auth.token || ''),
        isLoading,
        logout,
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

/**
 * HOC for protecting pages that require authentication
 *
 * Usage:
 * export default withShellAuth(MyPage);
 */
export function withShellAuth<P extends object>(
  Component: React.ComponentType<P>
): React.FC<P> {
  return function ProtectedComponent(props: P) {
    const { isAuthenticated, isLoading } = useShellAuth();

    if (isLoading) {
      return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ animation: 'spin 1s linear infinite', width: '48px', height: '48px', border: '4px solid #3b82f6', borderTopColor: 'transparent', borderRadius: '50%', margin: '0 auto 16px' }} />
            <p>Loading...</p>
          </div>
        </div>
      );
    }

    if (!isAuthenticated) {
      return (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
          <div style={{ textAlign: 'center' }}>
            <h2>Not Authenticated</h2>
            <p>Please login through the Shell</p>
          </div>
        </div>
      );
    }

    return <Component {...props} />;
  };
}
