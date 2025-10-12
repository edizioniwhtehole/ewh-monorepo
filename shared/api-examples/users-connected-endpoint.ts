/**
 * API Endpoint: /api/users/connected
 *
 * Context-Aware Endpoint che ritorna utenti diversi in base al context:
 * - Admin: Tutti gli utenti di tutti i tenant
 * - Tenant: Solo utenti del tenant corrente
 * - User: Solo team members dell'utente
 *
 * Esempio implementazione per app-admin-frontend e app-web-frontend
 */

import { NextApiRequest, NextApiResponse } from 'next';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://ewh:ewhpass@postgres:5432/ewh_master'
});

interface ConnectedUser {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  status: 'online' | 'away' | 'offline';
  lastActive: Date;
  tenantId?: string;
  tenantName?: string;
  role?: string;
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Get params
    const { context, tenantId, userId, maxUsers = '10', sortBy = 'lastActive' } = req.query;

    // Validate context
    if (!context || !['admin', 'tenant', 'user'].includes(context as string)) {
      return res.status(400).json({ error: 'Invalid context' });
    }

    // Build query based on context
    let query = '';
    let params: any[] = [];

    switch (context) {
      case 'admin':
        // Admin: Show ALL users from ALL tenants
        query = `
          SELECT
            u.id,
            u.name,
            u.email,
            u.avatar_url as avatar,
            CASE
              WHEN us.last_activity > NOW() - INTERVAL '5 minutes' THEN 'online'
              WHEN us.last_activity > NOW() - INTERVAL '30 minutes' THEN 'away'
              ELSE 'offline'
            END as status,
            us.last_activity as "lastActive",
            u.tenant_id as "tenantId",
            t.name as "tenantName",
            r.name as role
          FROM auth.users u
          LEFT JOIN auth.user_sessions us ON u.id = us.user_id AND us.is_active = true
          LEFT JOIN public.tenants t ON u.tenant_id = t.id
          LEFT JOIN auth.user_roles ur ON u.id = ur.user_id
          LEFT JOIN auth.roles r ON ur.role_id = r.id
          WHERE us.last_activity > NOW() - INTERVAL '24 hours'
          ORDER BY ${sortBy === 'name' ? 'u.name' : 'us.last_activity DESC'}
          LIMIT $1
        `;
        params = [parseInt(maxUsers as string)];
        break;

      case 'tenant':
        // Tenant: Show only users from CURRENT tenant
        if (!tenantId) {
          return res.status(400).json({ error: 'tenantId required for tenant context' });
        }

        query = `
          SELECT
            u.id,
            u.name,
            u.email,
            u.avatar_url as avatar,
            CASE
              WHEN us.last_activity > NOW() - INTERVAL '5 minutes' THEN 'online'
              WHEN us.last_activity > NOW() - INTERVAL '30 minutes' THEN 'away'
              ELSE 'offline'
            END as status,
            us.last_activity as "lastActive",
            r.name as role
          FROM auth.users u
          LEFT JOIN auth.user_sessions us ON u.id = us.user_id AND us.is_active = true
          LEFT JOIN auth.user_roles ur ON u.id = ur.user_id
          LEFT JOIN auth.roles r ON ur.role_id = r.id
          WHERE u.tenant_id = $1
            AND us.last_activity > NOW() - INTERVAL '24 hours'
          ORDER BY ${sortBy === 'name' ? 'u.name' : 'us.last_activity DESC'}
          LIMIT $2
        `;
        params = [tenantId, parseInt(maxUsers as string)];
        break;

      case 'user':
        // User: Show only TEAM members (same tenant + same team/department)
        if (!userId) {
          return res.status(400).json({ error: 'userId required for user context' });
        }

        query = `
          SELECT
            u.id,
            u.name,
            u.email,
            u.avatar_url as avatar,
            CASE
              WHEN us.last_activity > NOW() - INTERVAL '5 minutes' THEN 'online'
              WHEN us.last_activity > NOW() - INTERVAL '30 minutes' THEN 'away'
              ELSE 'offline'
            END as status,
            us.last_activity as "lastActive",
            r.name as role
          FROM auth.users u
          LEFT JOIN auth.user_sessions us ON u.id = us.user_id AND us.is_active = true
          LEFT JOIN auth.user_roles ur ON u.id = ur.user_id
          LEFT JOIN auth.roles r ON ur.role_id = r.id
          WHERE u.tenant_id = (SELECT tenant_id FROM auth.users WHERE id = $1)
            AND (
              u.team_id = (SELECT team_id FROM auth.users WHERE id = $1)
              OR u.department_id = (SELECT department_id FROM auth.users WHERE id = $1)
            )
            AND us.last_activity > NOW() - INTERVAL '24 hours'
          ORDER BY ${sortBy === 'name' ? 'u.name' : 'us.last_activity DESC'}
          LIMIT $2
        `;
        params = [userId, parseInt(maxUsers as string)];
        break;
    }

    // Execute query
    const result = await pool.query(query, params);

    // Return users
    return res.status(200).json({
      users: result.rows,
      total: result.rows.length,
      context,
      timestamp: new Date().toISOString()
    });

  } catch (error: any) {
    console.error('[API /users/connected] Error:', error);
    return res.status(500).json({
      error: 'Failed to fetch connected users',
      details: error.message
    });
  }
}
