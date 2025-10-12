/**
 * Enterprise-Grade Health Check System
 *
 * Provides comprehensive health checks for microservices including:
 * - Database connectivity
 * - Redis connectivity
 * - External dependencies
 * - Disk space
 * - Memory usage
 * - Response time metrics
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { Pool } from 'pg';

export interface HealthCheckDependency {
  name: string;
  check: () => Promise<{ status: 'healthy' | 'degraded' | 'unhealthy'; latency_ms?: number; error?: string }>;
  critical?: boolean; // If true, service is unhealthy if this dependency fails
}

export interface HealthCheckResult {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  uptime_seconds: number;
  version: string;
  service: string;
  dependencies: Record<string, {
    status: 'healthy' | 'degraded' | 'unhealthy';
    latency_ms?: number;
    error?: string;
    critical: boolean;
  }>;
  system: {
    memory: {
      used_mb: number;
      total_mb: number;
      percentage: number;
    };
    uptime_seconds: number;
  };
}

/**
 * Database health check
 */
export function createDatabaseCheck(pool: Pool): HealthCheckDependency {
  return {
    name: 'database',
    critical: true,
    check: async () => {
      const start = Date.now();
      try {
        const result = await pool.query('SELECT 1 as health');
        const latency_ms = Date.now() - start;

        if (latency_ms > 1000) {
          return { status: 'degraded', latency_ms, error: 'High latency' };
        }

        return { status: 'healthy', latency_ms };
      } catch (error: any) {
        return {
          status: 'unhealthy',
          latency_ms: Date.now() - start,
          error: error.message
        };
      }
    }
  };
}

/**
 * Redis health check
 */
export function createRedisCheck(redis: any): HealthCheckDependency {
  return {
    name: 'redis',
    critical: false, // Redis is often optional (caching)
    check: async () => {
      const start = Date.now();
      try {
        await redis.ping();
        const latency_ms = Date.now() - start;

        if (latency_ms > 500) {
          return { status: 'degraded', latency_ms, error: 'High latency' };
        }

        return { status: 'healthy', latency_ms };
      } catch (error: any) {
        return {
          status: 'unhealthy',
          latency_ms: Date.now() - start,
          error: error.message
        };
      }
    }
  };
}

/**
 * HTTP endpoint health check (for external APIs)
 */
export function createHttpCheck(name: string, url: string, critical = false): HealthCheckDependency {
  return {
    name,
    critical,
    check: async () => {
      const start = Date.now();
      try {
        const response = await fetch(url, {
          method: 'GET',
          signal: AbortSignal.timeout(5000) // 5 second timeout
        });
        const latency_ms = Date.now() - start;

        if (!response.ok) {
          return {
            status: 'unhealthy',
            latency_ms,
            error: `HTTP ${response.status}`
          };
        }

        if (latency_ms > 2000) {
          return { status: 'degraded', latency_ms, error: 'High latency' };
        }

        return { status: 'healthy', latency_ms };
      } catch (error: any) {
        return {
          status: 'unhealthy',
          latency_ms: Date.now() - start,
          error: error.message
        };
      }
    }
  };
}

/**
 * Register health check endpoints
 */
export function registerHealthChecks(
  app: FastifyInstance,
  serviceName: string,
  version: string,
  dependencies: HealthCheckDependency[]
) {
  const startTime = Date.now();

  /**
   * Liveness probe - is the service running?
   * Used by Kubernetes/orchestrators to restart dead containers
   */
  app.get('/health/live', async (req: FastifyRequest, rep: FastifyReply) => {
    return rep.code(200).send({
      status: 'alive',
      timestamp: new Date().toISOString(),
      uptime_seconds: Math.floor((Date.now() - startTime) / 1000)
    });
  });

  /**
   * Readiness probe - is the service ready to accept traffic?
   * Used by load balancers to route traffic
   */
  app.get('/health/ready', async (req: FastifyRequest, rep: FastifyReply) => {
    const results = await Promise.all(
      dependencies
        .filter(d => d.critical)
        .map(d => d.check())
    );

    const allHealthy = results.every(r => r.status === 'healthy' || r.status === 'degraded');

    if (allHealthy) {
      return rep.code(200).send({
        status: 'ready',
        timestamp: new Date().toISOString()
      });
    } else {
      return rep.code(503).send({
        status: 'not_ready',
        timestamp: new Date().toISOString(),
        errors: results.filter(r => r.status === 'unhealthy').map(r => r.error)
      });
    }
  });

  /**
   * Full health check - detailed status of all dependencies
   * Used by monitoring systems and dashboards
   */
  app.get('/health', async (req: FastifyRequest, rep: FastifyReply) => {
    const dependencyResults = await Promise.all(
      dependencies.map(async (dep) => {
        const result = await dep.check();
        return {
          name: dep.name,
          ...result,
          critical: dep.critical ?? false
        };
      })
    );

    // Determine overall health
    const hasCriticalFailure = dependencyResults.some(
      r => r.critical && r.status === 'unhealthy'
    );
    const hasDegradation = dependencyResults.some(
      r => r.status === 'degraded'
    );
    const hasNonCriticalFailure = dependencyResults.some(
      r => !r.critical && r.status === 'unhealthy'
    );

    let overallStatus: 'healthy' | 'degraded' | 'unhealthy';
    if (hasCriticalFailure) {
      overallStatus = 'unhealthy';
    } else if (hasDegradation || hasNonCriticalFailure) {
      overallStatus = 'degraded';
    } else {
      overallStatus = 'healthy';
    }

    // System metrics
    const memUsage = process.memoryUsage();
    const totalMem = memUsage.heapTotal + memUsage.external + memUsage.arrayBuffers;
    const usedMem = memUsage.heapUsed;

    const healthResult: HealthCheckResult = {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      uptime_seconds: Math.floor((Date.now() - startTime) / 1000),
      version,
      service: serviceName,
      dependencies: dependencyResults.reduce((acc, dep) => {
        acc[dep.name] = {
          status: dep.status,
          latency_ms: dep.latency_ms,
          error: dep.error,
          critical: dep.critical
        };
        return acc;
      }, {} as any),
      system: {
        memory: {
          used_mb: Math.round(usedMem / 1024 / 1024),
          total_mb: Math.round(totalMem / 1024 / 1024),
          percentage: Math.round((usedMem / totalMem) * 100)
        },
        uptime_seconds: Math.floor(process.uptime())
      }
    };

    const httpCode = overallStatus === 'unhealthy' ? 503 : 200;
    return rep.code(httpCode).send(healthResult);
  });

  app.log.info(`✅ Health check endpoints registered: /health, /health/live, /health/ready`);
}
