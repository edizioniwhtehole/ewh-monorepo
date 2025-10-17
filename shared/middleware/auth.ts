/**
 * Shared Authentication Middleware for EWH Platform
 *
 * Usage:
 * import { authMiddleware, optionalAuth } from '@ewh/shared/middleware/auth';
 *
 * app.use('/api', authMiddleware);  // Protect all /api routes
 * app.get('/public', optionalAuth, handler);  // Optional auth
 */

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

// Extend Express Request type
declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        email: string;
        platformRole: string;
        tenantRole?: string;
        tenantId?: string;
      };
      tenantId?: string;
    }
  }
}

const JWT_SECRET = process.env.JWT_SECRET || 'ewh-platform-secret-change-in-production';
const JWT_ISSUER = process.env.JWT_ISSUER || 'http://svc-auth:4001';
const JWT_AUDIENCE = process.env.JWT_AUDIENCE || 'ewh-saas';

/**
 * Authentication Middleware - Required Auth
 * Returns 401 if no valid token
 */
export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'No authentication token provided',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET, {
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
    }) as any;

    // Attach user info to request
    req.user = {
      userId: decoded.userId || decoded.sub,
      email: decoded.email,
      platformRole: decoded.platformRole || 'USER',
      tenantRole: decoded.tenantRole,
      tenantId: decoded.tenantId,
    };

    req.tenantId = decoded.tenantId;

    next();
  } catch (err: any) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'TokenExpired',
        message: 'Authentication token has expired',
      });
    }

    return res.status(401).json({
      error: 'InvalidToken',
      message: 'Invalid authentication token',
    });
  }
}

/**
 * Optional Authentication Middleware
 * Attaches user if token exists, but doesn't fail if missing
 */
export function optionalAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(); // No token, but that's okay
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET, {
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
    }) as any;

    req.user = {
      userId: decoded.userId || decoded.sub,
      email: decoded.email,
      platformRole: decoded.platformRole || 'USER',
      tenantRole: decoded.tenantRole,
      tenantId: decoded.tenantId,
    };

    req.tenantId = decoded.tenantId;
  } catch (err) {
    // Invalid token, but we don't fail - just continue without user
  }

  next();
}

/**
 * Role-Based Access Control Middleware
 *
 * Usage:
 * app.get('/admin', requireRole(['PLATFORM_ADMIN', 'OWNER']), handler);
 */
export function requireRole(allowedRoles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required',
      });
    }

    const userRole = req.user.platformRole;

    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({
        error: 'Forbidden',
        message: `Required role: ${allowedRoles.join(' or ')}`,
      });
    }

    next();
  };
}

/**
 * Tenant Isolation Middleware
 * Ensures requests can only access data from their tenant
 *
 * Usage:
 * app.use('/api', authMiddleware, ensureTenantIsolation);
 */
export function ensureTenantIsolation(req: Request, res: Response, next: NextFunction) {
  if (!req.user || !req.user.tenantId) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Tenant information missing',
    });
  }

  // Platform admins can access all tenants
  if (req.user.platformRole === 'PLATFORM_ADMIN' || req.user.platformRole === 'OWNER') {
    return next();
  }

  // For regular users, ensure they can only access their tenant
  // This should be enforced in database queries using req.tenantId

  next();
}

/**
 * Extract tenant ID from header (for multi-tenant requests)
 */
export function extractTenantHeader(req: Request, res: Response, next: NextFunction) {
  const tenantHeader = req.headers['x-tenant-id'] as string;

  if (tenantHeader) {
    // Verify user has access to this tenant
    if (req.user && req.user.tenantId !== tenantHeader) {
      // Check if user is platform admin
      if (req.user.platformRole !== 'PLATFORM_ADMIN' && req.user.platformRole !== 'OWNER') {
        return res.status(403).json({
          error: 'Forbidden',
          message: 'Access to this tenant is not allowed',
        });
      }
    }

    req.tenantId = tenantHeader;
  }

  next();
}
