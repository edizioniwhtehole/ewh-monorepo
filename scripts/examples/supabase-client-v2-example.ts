/**
 * Supabase Client Examples for Public Views V2
 *
 * This file demonstrates how to use the secure V2 API functions
 * with proper error handling, types, and best practices.
 *
 * @see create-public-views-v2.sql for backend implementation
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';

// ============================================================================
// TYPES
// ============================================================================

interface Project {
  id: string;
  name: string;
  description: string;
  status: 'planning' | 'active' | 'on-hold' | 'completed' | 'cancelled';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  start_date: string;
  end_date: string;
  created_at: string;
  updated_at: string;
}

interface Customer {
  id: string;
  company_name: string;
  contact_name: string;
  email: string;
  phone: string;
  status: 'active' | 'inactive' | 'prospect';
  created_at: string;
  updated_at: string;
}

interface TenantInfo {
  id: string;
  name: string;
  slug: string;
  status: 'active' | 'suspended' | 'trial';
  created_at: string;
}

interface App {
  app_code: string;
  app_name: string;
  app_description: string;
  is_enabled: boolean;
  settings: Record<string, any>;
}

interface ApiError {
  message: string;
  code?: string;
  details?: any;
}

// ============================================================================
// CLIENT SETUP
// ============================================================================

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

export const supabase: SupabaseClient = createClient(supabaseUrl, supabaseAnonKey);

// ============================================================================
// GENERIC QUERY FUNCTION (WITH PAGINATION)
// ============================================================================

/**
 * Query any tenant table with pagination
 *
 * @param tenantSlug - Tenant identifier (e.g., 'acme-corp')
 * @param tableName - Table to query (must be whitelisted)
 * @param limit - Max rows to return (default: 100, max: 1000)
 * @param offset - Number of rows to skip (default: 0)
 * @returns Query results as JSON array
 */
export async function queryTenant<T = any>(
  tenantSlug: string,
  tableName: string,
  limit: number = 100,
  offset: number = 0
): Promise<{ data: T[] | null; error: ApiError | null }> {
  try {
    const { data, error } = await supabase.rpc('query_tenant', {
      tenant_slug: tenantSlug,
      table_name: tableName,
      query_limit: limit,
      query_offset: offset,
    });

    if (error) {
      return {
        data: null,
        error: {
          message: error.message,
          code: error.code,
          details: error.details,
        },
      };
    }

    // Parse JSONB response
    const parsedData: T[] = Array.isArray(data) ? data : [];

    return { data: parsedData, error: null };
  } catch (err: any) {
    return {
      data: null,
      error: {
        message: err.message || 'Unknown error',
      },
    };
  }
}

// ============================================================================
// PROJECTS API
// ============================================================================

/**
 * Get all projects for a tenant
 */
export async function getTenantProjects(
  tenantSlug: string,
  status?: Project['status'],
  limit: number = 50
): Promise<{ data: Project[] | null; error: ApiError | null }> {
  try {
    const { data, error } = await supabase.rpc('get_tenant_projects', {
      tenant_slug: tenantSlug,
      project_status: status || null,
      limit_rows: limit,
    });

    if (error) {
      return {
        data: null,
        error: {
          message: error.message,
          code: error.code,
        },
      };
    }

    return { data: data as Project[], error: null };
  } catch (err: any) {
    return {
      data: null,
      error: { message: err.message },
    };
  }
}

/**
 * Get active projects only
 */
export async function getActiveProjects(
  tenantSlug: string,
  limit: number = 50
): Promise<{ data: Project[] | null; error: ApiError | null }> {
  return getTenantProjects(tenantSlug, 'active', limit);
}

/**
 * Get projects with pagination
 */
export async function getProjectsPaginated(
  tenantSlug: string,
  page: number = 1,
  pageSize: number = 20
): Promise<{ data: Project[] | null; error: ApiError | null; hasMore: boolean }> {
  const offset = (page - 1) * pageSize;
  const limit = pageSize + 1; // Fetch one extra to check if there's more

  const result = await queryTenant<Project>(
    tenantSlug,
    'pm_projects',
    limit,
    offset
  );

  if (result.error || !result.data) {
    return { ...result, hasMore: false };
  }

  const hasMore = result.data.length > pageSize;
  const data = hasMore ? result.data.slice(0, pageSize) : result.data;

  return { data, error: null, hasMore };
}

// ============================================================================
// CUSTOMERS API
// ============================================================================

/**
 * Get all customers for a tenant
 */
export async function getTenantCustomers(
  tenantSlug: string,
  status?: Customer['status'],
  limit: number = 50
): Promise<{ data: Customer[] | null; error: ApiError | null }> {
  try {
    const { data, error } = await supabase.rpc('get_tenant_customers', {
      tenant_slug: tenantSlug,
      customer_status: status || null,
      limit_rows: limit,
    });

    if (error) {
      return {
        data: null,
        error: {
          message: error.message,
          code: error.code,
        },
      };
    }

    return { data: data as Customer[], error: null };
  } catch (err: any) {
    return {
      data: null,
      error: { message: err.message },
    };
  }
}

/**
 * Get active customers only
 */
export async function getActiveCustomers(
  tenantSlug: string,
  limit: number = 50
): Promise<{ data: Customer[] | null; error: ApiError | null }> {
  return getTenantCustomers(tenantSlug, 'active', limit);
}

// ============================================================================
// TENANT INFO API
// ============================================================================

/**
 * Get tenant information (public data)
 */
export async function getTenantInfo(
  tenantSlug: string
): Promise<{ data: TenantInfo | null; error: ApiError | null }> {
  try {
    const { data, error } = await supabase.rpc('get_tenant_info', {
      tenant_slug: tenantSlug,
    });

    if (error) {
      return {
        data: null,
        error: {
          message: error.message,
          code: error.code,
        },
      };
    }

    // Returns array, get first element
    const tenantInfo = Array.isArray(data) && data.length > 0 ? data[0] : null;

    return { data: tenantInfo, error: null };
  } catch (err: any) {
    return {
      data: null,
      error: { message: err.message },
    };
  }
}

/**
 * Get available apps for a tenant
 */
export async function getTenantApps(
  tenantSlug: string
): Promise<{ data: App[] | null; error: ApiError | null }> {
  try {
    const { data, error } = await supabase.rpc('get_tenant_available_apps', {
      tenant_slug: tenantSlug,
    });

    if (error) {
      return {
        data: null,
        error: {
          message: error.message,
          code: error.code,
        },
      };
    }

    return { data: data as App[], error: null };
  } catch (err: any) {
    return {
      data: null,
      error: { message: err.message },
    };
  }
}

// ============================================================================
// PERMISSION CHECKING
// ============================================================================

/**
 * Check if current user has access to a tenant
 */
export async function checkTenantAccess(
  tenantSlug: string
): Promise<{ hasAccess: boolean; error: ApiError | null }> {
  try {
    const { data, error } = await supabase.rpc('user_has_tenant_access', {
      tenant_slug: tenantSlug,
    });

    if (error) {
      return {
        hasAccess: false,
        error: {
          message: error.message,
          code: error.code,
        },
      };
    }

    return { hasAccess: data === true, error: null };
  } catch (err: any) {
    return {
      hasAccess: false,
      error: { message: err.message },
    };
  }
}

// ============================================================================
// REACT HOOKS (EXAMPLE)
// ============================================================================

import { useEffect, useState } from 'react';

/**
 * React hook to fetch tenant projects
 */
export function useTenantProjects(tenantSlug: string, status?: Project['status']) {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiError | null>(null);

  useEffect(() => {
    async function fetchProjects() {
      setLoading(true);
      setError(null);

      const result = await getTenantProjects(tenantSlug, status);

      if (result.error) {
        setError(result.error);
      } else {
        setProjects(result.data || []);
      }

      setLoading(false);
    }

    fetchProjects();
  }, [tenantSlug, status]);

  return { projects, loading, error };
}

/**
 * React hook to fetch tenant customers
 */
export function useTenantCustomers(tenantSlug: string, status?: Customer['status']) {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiError | null>(null);

  useEffect(() => {
    async function fetchCustomers() {
      setLoading(true);
      setError(null);

      const result = await getTenantCustomers(tenantSlug, status);

      if (result.error) {
        setError(result.error);
      } else {
        setCustomers(result.data || []);
      }

      setLoading(false);
    }

    fetchCustomers();
  }, [tenantSlug, status]);

  return { customers, loading, error };
}

/**
 * React hook for paginated data
 */
export function usePaginatedProjects(tenantSlug: string, pageSize: number = 20) {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  useEffect(() => {
    async function fetchPage() {
      setLoading(true);
      setError(null);

      const result = await getProjectsPaginated(tenantSlug, page, pageSize);

      if (result.error) {
        setError(result.error);
      } else {
        setProjects(result.data || []);
        setHasMore(result.hasMore);
      }

      setLoading(false);
    }

    fetchPage();
  }, [tenantSlug, page, pageSize]);

  const nextPage = () => {
    if (hasMore) setPage((p) => p + 1);
  };

  const prevPage = () => {
    if (page > 1) setPage((p) => p - 1);
  };

  return { projects, loading, error, page, hasMore, nextPage, prevPage };
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/**
 * Example 1: Fetch all active projects
 */
async function example1() {
  const { data, error } = await getActiveProjects('acme-corp', 50);

  if (error) {
    console.error('Error fetching projects:', error.message);
    return;
  }

  console.log(`Found ${data?.length} active projects`);
  data?.forEach((project) => {
    console.log(`- ${project.name} (${project.status})`);
  });
}

/**
 * Example 2: Fetch customers with pagination
 */
async function example2() {
  const { data, error, hasMore } = await getProjectsPaginated('acme-corp', 1, 20);

  if (error) {
    console.error('Error:', error.message);
    return;
  }

  console.log(`Page 1: ${data?.length} projects`);
  console.log(`Has more pages: ${hasMore}`);
}

/**
 * Example 3: Check tenant access before querying
 */
async function example3() {
  const tenantSlug = 'acme-corp';

  // Check access first
  const { hasAccess, error: accessError } = await checkTenantAccess(tenantSlug);

  if (accessError) {
    console.error('Error checking access:', accessError.message);
    return;
  }

  if (!hasAccess) {
    console.error('Access denied to tenant:', tenantSlug);
    return;
  }

  // Access granted, fetch data
  const { data, error } = await getActiveProjects(tenantSlug);

  if (error) {
    console.error('Error fetching projects:', error.message);
    return;
  }

  console.log(`Access granted. Found ${data?.length} projects`);
}

/**
 * Example 4: React component using hooks
 */
function ProjectListComponent({ tenantSlug }: { tenantSlug: string }) {
  const { projects, loading, error } = useTenantProjects(tenantSlug, 'active');

  if (loading) return <div>Loading projects...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <h2>Active Projects ({projects.length})</h2>
      <ul>
        {projects.map((project) => (
          <li key={project.id}>
            {project.name} - {project.status}
          </li>
        ))}
      </ul>
    </div>
  );
}

/**
 * Example 5: Paginated component
 */
function PaginatedProjectsComponent({ tenantSlug }: { tenantSlug: string }) {
  const { projects, loading, error, page, hasMore, nextPage, prevPage } =
    usePaginatedProjects(tenantSlug, 10);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <h2>Projects (Page {page})</h2>
      <ul>
        {projects.map((project) => (
          <li key={project.id}>{project.name}</li>
        ))}
      </ul>
      <div>
        <button onClick={prevPage} disabled={page === 1}>
          Previous
        </button>
        <button onClick={nextPage} disabled={!hasMore}>
          Next
        </button>
      </div>
    </div>
  );
}

// ============================================================================
// ERROR HANDLING UTILITIES
// ============================================================================

/**
 * Handle API errors with user-friendly messages
 */
export function getErrorMessage(error: ApiError): string {
  switch (error.code) {
    case 'PGRST116':
      return 'You do not have permission to access this data.';
    case 'PGRST204':
      return 'No data found.';
    case '42P01':
      return 'The requested resource does not exist.';
    default:
      return error.message || 'An unexpected error occurred.';
  }
}

/**
 * Retry failed requests with exponential backoff
 */
export async function retryRequest<T>(
  requestFn: () => Promise<{ data: T | null; error: ApiError | null }>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<{ data: T | null; error: ApiError | null }> {
  let lastError: ApiError | null = null;

  for (let i = 0; i < maxRetries; i++) {
    const result = await requestFn();

    if (!result.error) {
      return result;
    }

    lastError = result.error;

    // Don't retry on permission errors
    if (result.error.code === 'PGRST116') {
      break;
    }

    // Wait before retrying (exponential backoff)
    const delay = baseDelay * Math.pow(2, i);
    await new Promise((resolve) => setTimeout(resolve, delay));
  }

  return { data: null, error: lastError };
}

// ============================================================================
// EXPORTS
// ============================================================================

export default {
  queryTenant,
  getTenantProjects,
  getActiveProjects,
  getProjectsPaginated,
  getTenantCustomers,
  getActiveCustomers,
  getTenantInfo,
  getTenantApps,
  checkTenantAccess,
  useTenantProjects,
  useTenantCustomers,
  usePaginatedProjects,
  getErrorMessage,
  retryRequest,
};
