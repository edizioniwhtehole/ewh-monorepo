/**
 * Prometheus-style Metrics Collection for Microservices
 *
 * Provides standardized metrics endpoints that can be scraped by svc-metrics-collector
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';

export interface MetricValue {
  value: number;
  labels?: Record<string, string>;
  timestamp?: number;
}

export interface MetricDefinition {
  name: string;
  type: 'counter' | 'gauge' | 'histogram' | 'summary';
  help: string;
  unit?: string;
  labelNames?: string[];
}

/**
 * Metrics Registry - Stores all metrics for a service
 */
export class MetricsRegistry {
  private metrics = new Map<string, MetricDefinition>();
  private values = new Map<string, MetricValue[]>();
  private counters = new Map<string, number>();
  private gauges = new Map<string, number>();

  /**
   * Register a new metric
   */
  register(metric: MetricDefinition) {
    this.metrics.set(metric.name, metric);
    this.values.set(metric.name, []);
  }

  /**
   * Increment a counter metric
   */
  incrementCounter(name: string, value: number = 1, labels?: Record<string, string>) {
    const key = this.makeKey(name, labels);
    this.counters.set(key, (this.counters.get(key) || 0) + value);
  }

  /**
   * Set a gauge value
   */
  setGauge(name: string, value: number, labels?: Record<string, string>) {
    const key = this.makeKey(name, labels);
    this.gauges.set(key, value);
  }

  /**
   * Record a histogram value
   */
  recordHistogram(name: string, value: number, labels?: Record<string, string>) {
    const values = this.values.get(name) || [];
    values.push({ value, labels, timestamp: Date.now() });
    this.values.set(name, values);
  }

  /**
   * Get all metrics in Prometheus format
   */
  getPrometheusFormat(): string {
    let output = '';

    // Export counters
    for (const [key, value] of this.counters.entries()) {
      const { name, labels } = this.parseKey(key);
      const metric = this.metrics.get(name);
      if (metric) {
        output += `# HELP ${name} ${metric.help}\n`;
        output += `# TYPE ${name} counter\n`;
        output += `${name}${this.formatLabels(labels)} ${value}\n\n`;
      }
    }

    // Export gauges
    for (const [key, value] of this.gauges.entries()) {
      const { name, labels } = this.parseKey(key);
      const metric = this.metrics.get(name);
      if (metric) {
        output += `# HELP ${name} ${metric.help}\n`;
        output += `# TYPE ${name} gauge\n`;
        output += `${name}${this.formatLabels(labels)} ${value}\n\n`;
      }
    }

    return output;
  }

  /**
   * Get all metrics as JSON
   */
  getJSON() {
    const result: Record<string, any> = {};

    // Counters
    for (const [key, value] of this.counters.entries()) {
      const { name, labels } = this.parseKey(key);
      if (!result[name]) result[name] = [];
      result[name].push({ type: 'counter', value, labels, timestamp: Date.now() });
    }

    // Gauges
    for (const [key, value] of this.gauges.entries()) {
      const { name, labels } = this.parseKey(key);
      if (!result[name]) result[name] = [];
      result[name].push({ type: 'gauge', value, labels, timestamp: Date.now() });
    }

    // Histograms
    for (const [name, values] of this.values.entries()) {
      const metric = this.metrics.get(name);
      if (metric && metric.type === 'histogram') {
        // Calculate statistics
        const sortedValues = values.map(v => v.value).sort((a, b) => a - b);
        const sum = sortedValues.reduce((a, b) => a + b, 0);
        const count = sortedValues.length;
        const avg = count > 0 ? sum / count : 0;
        const p50 = this.percentile(sortedValues, 0.5);
        const p95 = this.percentile(sortedValues, 0.95);
        const p99 = this.percentile(sortedValues, 0.99);

        result[name] = [{
          type: 'histogram',
          count,
          sum,
          avg,
          p50,
          p95,
          p99,
          min: sortedValues[0] || 0,
          max: sortedValues[count - 1] || 0,
          timestamp: Date.now()
        }];
      }
    }

    return result;
  }

  /**
   * Reset all metrics
   */
  reset() {
    this.counters.clear();
    this.gauges.clear();
    this.values.clear();
  }

  private makeKey(name: string, labels?: Record<string, string>): string {
    if (!labels || Object.keys(labels).length === 0) return name;
    return `${name}|${JSON.stringify(labels)}`;
  }

  private parseKey(key: string): { name: string; labels?: Record<string, string> } {
    const parts = key.split('|');
    if (parts.length === 1) return { name: parts[0] };
    return { name: parts[0], labels: JSON.parse(parts[1]) };
  }

  private formatLabels(labels?: Record<string, string>): string {
    if (!labels || Object.keys(labels).length === 0) return '';
    const pairs = Object.entries(labels).map(([k, v]) => `${k}="${v}"`);
    return `{${pairs.join(',')}}`;
  }

  private percentile(sorted: number[], p: number): number {
    if (sorted.length === 0) return 0;
    const index = Math.ceil(sorted.length * p) - 1;
    return sorted[Math.max(0, Math.min(index, sorted.length - 1))];
  }
}

/**
 * Register metrics endpoints for a Fastify service
 */
export function registerMetricsEndpoints(
  app: FastifyInstance,
  serviceName: string,
  registry: MetricsRegistry
) {
  // Prometheus-style metrics endpoint
  app.get('/metrics', async (req: FastifyRequest, rep: FastifyReply) => {
    return rep
      .code(200)
      .header('Content-Type', 'text/plain; version=0.0.4')
      .send(registry.getPrometheusFormat());
  });

  // JSON metrics endpoint (more flexible)
  app.get('/metrics/json', async (req: FastifyRequest, rep: FastifyReply) => {
    return rep.code(200).send({
      service: serviceName,
      timestamp: new Date().toISOString(),
      metrics: registry.getJSON()
    });
  });

  app.log.info(`📊 Metrics endpoints registered: /metrics, /metrics/json`);
}

/**
 * Create default application metrics
 */
export function createDefaultMetrics(registry: MetricsRegistry, serviceName: string) {
  // HTTP metrics
  registry.register({
    name: 'http_requests_total',
    type: 'counter',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status']
  });

  registry.register({
    name: 'http_request_duration_ms',
    type: 'histogram',
    help: 'HTTP request duration in milliseconds',
    unit: 'ms',
    labelNames: ['method', 'route']
  });

  registry.register({
    name: 'http_errors_total',
    type: 'counter',
    help: 'Total number of HTTP errors',
    labelNames: ['method', 'route', 'status']
  });

  // Database metrics
  registry.register({
    name: 'db_connections_active',
    type: 'gauge',
    help: 'Number of active database connections'
  });

  registry.register({
    name: 'db_query_duration_ms',
    type: 'histogram',
    help: 'Database query duration in milliseconds',
    unit: 'ms'
  });

  registry.register({
    name: 'db_queries_total',
    type: 'counter',
    help: 'Total number of database queries'
  });

  // Application metrics
  registry.register({
    name: 'app_errors_total',
    type: 'counter',
    help: 'Total number of application errors',
    labelNames: ['type', 'severity']
  });

  registry.register({
    name: 'app_events_processed',
    type: 'counter',
    help: 'Total number of events processed',
    labelNames: ['event_type']
  });

  // Business metrics (examples)
  registry.register({
    name: 'users_active',
    type: 'gauge',
    help: 'Number of currently active users'
  });

  registry.register({
    name: 'operations_completed',
    type: 'counter',
    help: 'Total number of completed operations',
    labelNames: ['operation_type', 'status']
  });
}

/**
 * Fastify plugin for automatic request metrics
 */
export function createMetricsPlugin(registry: MetricsRegistry) {
  return async (app: FastifyInstance) => {
    app.addHook('onRequest', async (request, reply) => {
      (request as any).startTime = Date.now();
    });

    app.addHook('onResponse', async (request, reply) => {
      const duration = Date.now() - ((request as any).startTime || Date.now());
      const method = request.method;
      const route = request.routeOptions?.url || 'unknown';
      const status = reply.statusCode.toString();

      // Record request
      registry.incrementCounter('http_requests_total', 1, { method, route, status });

      // Record duration
      registry.recordHistogram('http_request_duration_ms', duration, { method, route });

      // Record errors
      if (reply.statusCode >= 400) {
        registry.incrementCounter('http_errors_total', 1, { method, route, status });
      }
    });
  };
}