/**
 * Connected Users Widget
 *
 * Riutilizzabile in 3 contesti:
 * - Admin: Mostra TUTTI gli utenti di TUTTI i tenant
 * - Tenant: Mostra solo utenti del tenant corrente
 * - User: Mostra solo utenti del team dell'utente
 *
 * Configurabile a 3 livelli:
 * - Level 1 (System): Default config dal plugin
 * - Level 2 (Tenant): Tenant può customizzare (es. colori brand)
 * - Level 3 (User): User può personalizzare (es. ordinamento preferito)
 */

'use client';

import { useState, useEffect } from 'react';
import { Users, Circle, Clock, Settings } from 'lucide-react';

// Types
export interface ConnectedUsersWidgetConfig {
  showAvatar: boolean;
  maxUsers: number;
  refreshInterval: number;
  showStatus: boolean;
  sortBy: 'name' | 'lastActive';
  // Tenant-level customization
  brandColor?: string;
  customTitle?: string;
  // User-level customization
  favoriteUsersFirst?: boolean;
  compactView?: boolean;
}

export interface WidgetContext {
  context: 'admin' | 'tenant' | 'user';
  tenantId?: string;
  userId?: string;
  permissions?: string[];
}

export interface ConnectedUser {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  status: 'online' | 'away' | 'offline';
  lastActive: Date;
  tenantId?: string;
  tenantName?: string;  // Only in admin context
  role?: string;
}

interface ConnectedUsersWidgetProps {
  // Widget instance ID
  instanceId: string;

  // Context (determines data scope)
  context: WidgetContext;

  // Configuration (merged from Level 1-2-3-4)
  config: ConnectedUsersWidgetConfig;

  // Callbacks
  onConfigure?: () => void;
  onUserClick?: (user: ConnectedUser) => void;

  // UI options
  showHeader?: boolean;
  showConfigButton?: boolean;
}

export function ConnectedUsersWidget({
  instanceId,
  context,
  config,
  onConfigure,
  onUserClick,
  showHeader = true,
  showConfigButton = true
}: ConnectedUsersWidgetProps) {
  const [users, setUsers] = useState<ConnectedUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());

  // Fetch users with context-aware filtering
  async function fetchUsers() {
    try {
      setLoading(true);
      setError(null);

      // Build API URL with context params
      const params = new URLSearchParams({
        context: context.context,
        ...(context.tenantId && { tenantId: context.tenantId }),
        ...(context.userId && { userId: context.userId }),
        maxUsers: config.maxUsers.toString(),
        sortBy: config.sortBy
      });

      const response = await fetch(`/api/users/connected?${params}`);

      if (!response.ok) {
        throw new Error('Failed to fetch connected users');
      }

      const data = await response.json();
      setUsers(data.users || []);
      setLastUpdate(new Date());
    } catch (err: any) {
      setError(err.message);
      console.error('[ConnectedUsersWidget] Error:', err);
    } finally {
      setLoading(false);
    }
  }

  // Initial fetch
  useEffect(() => {
    fetchUsers();
  }, [context.context, context.tenantId, context.userId, config.sortBy, config.maxUsers]);

  // Auto-refresh
  useEffect(() => {
    const interval = setInterval(
      fetchUsers,
      config.refreshInterval
    );

    return () => clearInterval(interval);
  }, [config.refreshInterval]);

  // Sort users based on config
  const sortedUsers = [...users].sort((a, b) => {
    if (config.sortBy === 'name') {
      return a.name.localeCompare(b.name);
    } else {
      return new Date(b.lastActive).getTime() - new Date(a.lastActive).getTime();
    }
  });

  // Get context-specific title
  function getTitle() {
    if (config.customTitle) return config.customTitle;

    switch (context.context) {
      case 'admin':
        return 'Connected Users (All Tenants)';
      case 'tenant':
        return 'Connected Users (Your Organization)';
      case 'user':
        return 'Team Members Online';
      default:
        return 'Connected Users';
    }
  }

  // Get status color
  function getStatusColor(status: ConnectedUser['status']) {
    switch (status) {
      case 'online': return config.brandColor || '#10b981';
      case 'away': return '#f59e0b';
      case 'offline': return '#6b7280';
    }
  }

  // Format last active time
  function formatLastActive(date: Date) {
    const now = new Date();
    const diff = now.getTime() - new Date(date).getTime();
    const minutes = Math.floor(diff / 60000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (minutes < 1440) return `${Math.floor(minutes / 60)}h ago`;
    return `${Math.floor(minutes / 1440)}d ago`;
  }

  return (
    <div className="connected-users-widget h-full flex flex-col bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700">
      {/* Header */}
      {showHeader && (
        <div className="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700">
          <div className="flex items-center gap-2">
            <Users className="text-slate-600 dark:text-slate-400" size={20} />
            <h3 className="font-semibold text-slate-900 dark:text-slate-100">
              {getTitle()}
            </h3>
            <span className="text-xs px-2 py-0.5 bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 rounded">
              {users.length}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-500 dark:text-slate-400">
              Updated {formatLastActive(lastUpdate)}
            </span>
            {showConfigButton && onConfigure && (
              <button
                onClick={onConfigure}
                className="p-1 hover:bg-slate-100 dark:hover:bg-slate-700 rounded transition-colors"
                title="Configure widget"
              >
                <Settings size={16} className="text-slate-600 dark:text-slate-400" />
              </button>
            )}
          </div>
        </div>
      )}

      {/* Content */}
      <div className="flex-1 overflow-auto p-4">
        {loading && (
          <div className="flex items-center justify-center h-full">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-slate-900 dark:border-slate-100" />
          </div>
        )}

        {error && (
          <div className="flex items-center justify-center h-full text-red-500">
            <p>{error}</p>
          </div>
        )}

        {!loading && !error && users.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full text-slate-500 dark:text-slate-400">
            <Users size={48} className="mb-2 opacity-50" />
            <p>No users connected</p>
          </div>
        )}

        {!loading && !error && users.length > 0 && (
          <div className="space-y-2">
            {sortedUsers.map((user) => (
              <div
                key={user.id}
                onClick={() => onUserClick?.(user)}
                className={`
                  flex items-center gap-3 p-3 rounded-lg
                  ${onUserClick ? 'cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700' : ''}
                  transition-colors
                `}
              >
                {/* Avatar */}
                {config.showAvatar && (
                  <div className="relative">
                    {user.avatar ? (
                      <img
                        src={user.avatar}
                        alt={user.name}
                        className="w-10 h-10 rounded-full"
                      />
                    ) : (
                      <div className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-600 flex items-center justify-center">
                        <span className="text-sm font-medium text-slate-600 dark:text-slate-300">
                          {user.name.charAt(0).toUpperCase()}
                        </span>
                      </div>
                    )}
                    {/* Status indicator */}
                    {config.showStatus && (
                      <Circle
                        size={10}
                        className="absolute -bottom-0.5 -right-0.5 bg-white dark:bg-slate-800 rounded-full"
                        fill={getStatusColor(user.status)}
                        color={getStatusColor(user.status)}
                      />
                    )}
                  </div>
                )}

                {/* User info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-medium text-slate-900 dark:text-slate-100 truncate">
                      {user.name}
                    </p>
                    {user.role && (
                      <span className="text-xs px-1.5 py-0.5 bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 rounded">
                        {user.role}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
                    <Clock size={12} />
                    <span>{formatLastActive(user.lastActive)}</span>
                    {/* Tenant name (admin context only) */}
                    {context.context === 'admin' && user.tenantName && (
                      <>
                        <span>•</span>
                        <span>{user.tenantName}</span>
                      </>
                    )}
                  </div>
                </div>

                {/* Status text */}
                {config.showStatus && (
                  <div className="text-xs font-medium" style={{ color: getStatusColor(user.status) }}>
                    {user.status}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Footer info */}
      <div className="px-4 py-2 border-t border-slate-200 dark:border-slate-700 text-xs text-slate-500 dark:text-slate-400">
        {context.context === 'admin' && (
          <p>Showing users from all tenants</p>
        )}
        {context.context === 'tenant' && (
          <p>Showing users in your organization</p>
        )}
        {context.context === 'user' && (
          <p>Showing your team members</p>
        )}
      </div>
    </div>
  );
}

// Configuration panel component
export function ConnectedUsersWidgetConfig({
  config,
  onChange,
  level
}: {
  config: ConnectedUsersWidgetConfig;
  onChange: (config: Partial<ConnectedUsersWidgetConfig>) => void;
  level: 1 | 2 | 3;  // System | Tenant | User
}) {
  return (
    <div className="space-y-4 p-4">
      <h3 className="font-semibold text-lg">
        Widget Configuration
        {level === 2 && ' (Tenant Level)'}
        {level === 3 && ' (User Level)'}
      </h3>

      {/* Level 1 & 2: All options */}
      {(level === 1 || level === 2) && (
        <>
          <div>
            <label className="block text-sm font-medium mb-2">
              Max Users to Display
            </label>
            <input
              type="number"
              min="1"
              max="50"
              value={config.maxUsers}
              onChange={(e) => onChange({ maxUsers: parseInt(e.target.value) })}
              className="w-full px-3 py-2 border rounded"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Refresh Interval (seconds)
            </label>
            <input
              type="number"
              min="5"
              max="300"
              value={config.refreshInterval / 1000}
              onChange={(e) => onChange({ refreshInterval: parseInt(e.target.value) * 1000 })}
              className="w-full px-3 py-2 border rounded"
            />
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="showAvatar"
              checked={config.showAvatar}
              onChange={(e) => onChange({ showAvatar: e.target.checked })}
            />
            <label htmlFor="showAvatar">Show Avatars</label>
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="showStatus"
              checked={config.showStatus}
              onChange={(e) => onChange({ showStatus: e.target.checked })}
            />
            <label htmlFor="showStatus">Show Status Indicators</label>
          </div>
        </>
      )}

      {/* Level 2: Tenant customization */}
      {level === 2 && (
        <>
          <div>
            <label className="block text-sm font-medium mb-2">
              Custom Title (optional)
            </label>
            <input
              type="text"
              value={config.customTitle || ''}
              onChange={(e) => onChange({ customTitle: e.target.value })}
              placeholder="e.g., 'Team Members'"
              className="w-full px-3 py-2 border rounded"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Brand Color
            </label>
            <input
              type="color"
              value={config.brandColor || '#10b981'}
              onChange={(e) => onChange({ brandColor: e.target.value })}
              className="w-full h-10 border rounded"
            />
          </div>
        </>
      )}

      {/* Level 3: User preferences */}
      {level === 3 && (
        <>
          <div>
            <label className="block text-sm font-medium mb-2">
              Sort By
            </label>
            <select
              value={config.sortBy}
              onChange={(e) => onChange({ sortBy: e.target.value as 'name' | 'lastActive' })}
              className="w-full px-3 py-2 border rounded"
            >
              <option value="lastActive">Last Active</option>
              <option value="name">Name</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="compactView"
              checked={config.compactView || false}
              onChange={(e) => onChange({ compactView: e.target.checked })}
            />
            <label htmlFor="compactView">Compact View</label>
          </div>
        </>
      )}
    </div>
  );
}

export default ConnectedUsersWidget;
