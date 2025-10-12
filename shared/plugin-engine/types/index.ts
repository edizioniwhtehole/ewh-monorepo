/**
 * Plugin System Type Definitions
 * Shared types for the modular plugin architecture
 */

import { ReactNode, ComponentType } from 'react';

// =====================================================
// PLUGIN MANIFEST
// =====================================================

export interface PluginManifest {
  // Identification
  id: string;                       // Unique: "ewh-plugin-workers"
  name: string;                     // Display: "Worker Management"
  slug: string;                     // URL-safe: "workers"
  version: string;                  // Semver: "1.2.3"
  description: string;

  // Authorship
  author: {
    name: string;
    email: string;
    url?: string;
  };

  // Compatibility
  compatibility: {
    core: string;                   // Core version constraint
    requires?: string[];            // Required plugin IDs
    conflicts?: string[];           // Conflicting plugin IDs
  };

  // Capabilities - what this plugin provides
  capabilities: {
    backend: boolean;               // Has backend/API code
    frontend: boolean;              // Has frontend components
    widgets: boolean;               // Provides widgets
    pages: boolean;                 // Provides full pages
    api: boolean;                   // Exposes API endpoints
    cron: boolean;                  // Has scheduled jobs
    webhooks: boolean;              // Receives webhooks
    hooks: boolean;                 // Listens to system hooks
  };

  // Entry points
  entryPoints?: {
    backend?: string;               // "./backend/index.ts"
    frontend?: string;              // "./frontend/index.tsx"
    widgets?: string;               // "./frontend/widgets/index.ts"
    pages?: string;                 // "./frontend/pages/index.ts"
  };

  // Permissions required
  permissions?: PluginPermission[];

  // Database migrations
  migrations?: string[];

  // Configuration schema
  config?: {
    schema: Record<string, any>;    // JSON Schema
    defaults: Record<string, any>;
  };

  // Hooks this plugin provides
  providedHooks?: HookDefinition[];

  // Hooks this plugin listens to
  consumedHooks?: ConsumedHookDefinition[];

  // UI contributions
  ui?: {
    menu?: MenuItemDefinition[];
    widgets?: WidgetManifest[];
    pages?: PageManifest[];
  };

  // Licensing
  license: string;
  pricing?: {
    model: 'free' | 'one-time' | 'subscription' | 'freemium';
    price?: number;
    currency?: string;
  };
}

// =====================================================
// PERMISSIONS
// =====================================================

export interface PluginPermission {
  type: 'database' | 'api' | 'filesystem' | 'network' | 'cron' | 'event';
  resource: string;                 // What resource (table name, endpoint, etc)
  action: string;                   // read|write|delete|execute
  scope?: string;                   // Additional scope details
  reason: string;                   // Why needed (human-readable)
}

// =====================================================
// HOOKS SYSTEM
// =====================================================

export interface HookDefinition {
  name: string;                     // "worker:task.completed"
  type: 'action' | 'filter';
  category?: string;                // "worker" | "user" | "system"
  description: string;
  payloadSchema?: Record<string, any>; // JSON Schema for payload
}

export interface ConsumedHookDefinition {
  hook: string;                     // Hook name to listen to
  handler: string;                  // Function name
  priority?: number;                // Execution priority (default: 10)
}

export type HookHandler = (...args: any[]) => any | Promise<any>;

export interface RegisteredHook {
  pluginId: string;
  handler: HookHandler;
  priority: number;
}

// =====================================================
// PAGE SYSTEM
// =====================================================

export interface PageManifest {
  id: string;                       // "workers-dashboard"
  name: string;                     // "Workers Dashboard"
  slug: string;                     // "/admin/workers"
  description?: string;
  icon?: string;                    // Lucide icon name
  component: string;                // Path to component

  // Navigation
  showInMenu?: boolean;
  menuPosition?: number;
  parentPage?: string;

  // Access control
  requiredRole?: string[];
  requiredPermissions?: string[];

  // Layout
  layoutType?: 'grid' | 'flex' | 'custom' | 'dashboard';
  layoutConfig?: Record<string, any>;
}

export interface PageDefinition extends PageManifest {
  pluginId: string;
  isActive: boolean;
  isSystemPage: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// =====================================================
// WIDGET SYSTEM
// =====================================================

export interface WidgetManifest {
  id: string;                       // "worker-status-widget"
  name: string;                     // "Worker Status"
  description: string;
  category?: string;                // "monitoring" | "analytics" | "content"
  icon?: string;

  // Component
  component: string;                // Path to component file

  // Size constraints
  defaultSize?: { w: number; h: number };
  minSize?: { w: number; h: number };
  maxSize?: { w: number; h: number };

  // Configuration
  configSchema?: Record<string, any>; // JSON Schema
  defaultConfig?: Record<string, any>;
  configComponent?: string;         // Custom config UI component

  // Capabilities
  isResizable?: boolean;
  supportsRealtime?: boolean;
  hasSettings?: boolean;

  // Data
  dataSource?: {
    type: 'api' | 'realtime' | 'polling' | 'static';
    endpoint?: string;
    pollInterval?: number;
  };
}

export interface WidgetDefinition extends WidgetManifest {
  pluginId: string;
  componentPath: string;
  createdAt: Date;
  updatedAt: Date;
}

// Widget component props interface
export interface WidgetProps<TConfig = any> {
  instanceId: string;
  config: TConfig;
  onConfigChange?: (config: TConfig) => void;
  isEditMode?: boolean;
}

// Widget instance on a page
export interface WidgetLayout {
  id: string;                       // Instance ID
  widgetId: string;                 // Reference to WidgetDefinition
  pageId: string;
  pluginId: string;

  // Grid positioning
  x: number;
  y: number;
  w: number;
  h: number;

  // Instance configuration
  config: Record<string, any>;

  // State
  isVisible: boolean;
  isLocked: boolean;
  zIndex: number;
}

// =====================================================
// MENU SYSTEM
// =====================================================

export interface MenuItemDefinition {
  id: string;
  label: string;
  route: string;
  icon?: string;
  parent?: string;                  // Parent menu item ID
  position?: number;
  requiredRole?: string[];
  badge?: string;                   // Badge text (e.g., "New", "Beta")
}

// =====================================================
// PLUGIN LIFECYCLE
// =====================================================

export type PluginStatus = 'active' | 'inactive' | 'error' | 'updating' | 'installing';

export interface LoadedPlugin {
  manifest: PluginManifest;
  status: PluginStatus;
  enabled: boolean;
  installedAt: Date;
  activatedAt?: Date;
  lastError?: string;
  config: Record<string, any>;

  // Loaded resources
  backend?: any;
  frontend?: any;
  widgets?: Map<string, ComponentType<WidgetProps>>;
  pages?: Map<string, ComponentType<any>>;
}

export interface PluginLifecycleHooks {
  onInstall?: () => Promise<void>;
  onActivate?: () => Promise<void>;
  onDeactivate?: () => Promise<void>;
  onUninstall?: () => Promise<void>;
  onUpdate?: (oldVersion: string, newVersion: string) => Promise<void>;
  onConfigChange?: (config: Record<string, any>) => Promise<void>;
}

// =====================================================
// PLUGIN CONTEXT
// =====================================================

export interface PluginContext {
  pluginId: string;
  config: Record<string, any>;

  // API methods
  api: {
    get: (endpoint: string) => Promise<any>;
    post: (endpoint: string, data: any) => Promise<any>;
    put: (endpoint: string, data: any) => Promise<any>;
    delete: (endpoint: string) => Promise<any>;
  };

  // Database (if permission granted)
  db?: {
    query: (sql: string, params?: any[]) => Promise<any>;
  };

  // Event system
  events: {
    emit: (event: string, data: any) => void;
    on: (event: string, handler: (data: any) => void) => void;
    off: (event: string, handler: (data: any) => void) => void;
  };

  // Hooks
  hooks: {
    addAction: (hook: string, handler: HookHandler, priority?: number) => void;
    addFilter: (hook: string, handler: HookHandler, priority?: number) => void;
    doAction: (hook: string, ...args: any[]) => Promise<void>;
    applyFilters: (hook: string, value: any, ...args: any[]) => Promise<any>;
  };

  // Storage (plugin-specific)
  storage: {
    get: (key: string) => Promise<any>;
    set: (key: string, value: any) => Promise<void>;
    delete: (key: string) => Promise<void>;
  };

  // Logger
  logger: {
    info: (message: string, meta?: any) => void;
    warn: (message: string, meta?: any) => void;
    error: (message: string, meta?: any) => void;
    debug: (message: string, meta?: any) => void;
  };
}

// =====================================================
// DASHBOARD SYSTEM
// =====================================================

export interface DashboardLayout {
  id: string;
  name: string;
  slug: string;
  description?: string;

  // Access control
  isDefault: boolean;
  isPublic: boolean;
  createdBy: string;
  sharedWith: string[];
  requiredRole?: string;

  // Layout
  layout: WidgetLayout[];

  // Metadata
  createdAt: Date;
  updatedAt: Date;
  version: number;
}

// =====================================================
// REGISTRY TYPES
// =====================================================

export interface PluginRegistry {
  plugins: Map<string, LoadedPlugin>;
  widgets: Map<string, WidgetDefinition>;
  pages: Map<string, PageDefinition>;
  hooks: Map<string, RegisteredHook[]>;
}

// =====================================================
// API TYPES
// =====================================================

export interface PluginInstallRequest {
  manifestPath?: string;            // Path to manifest.json
  packageUrl?: string;              // URL to download plugin package
  localPath?: string;               // Local filesystem path
}

export interface PluginInstallResponse {
  success: boolean;
  pluginId: string;
  message: string;
  errors?: string[];
}

export interface PluginListResponse {
  plugins: LoadedPlugin[];
  total: number;
}

export interface PluginHealthCheck {
  pluginId: string;
  healthy: boolean;
  status: PluginStatus;
  lastError?: string;
  lastCheck: Date;
  uptime?: number;
}
