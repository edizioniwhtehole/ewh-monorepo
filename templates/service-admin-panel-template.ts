/**
 * TEMPLATE STANDARD PER PANNELLO ADMIN SERVIZIO
 *
 * Questo template va inserito in ogni servizio come:
 * src/routes/admin-panel.ts
 *
 * Endpoint: GET /admin/dev/api
 *
 * Fornisce:
 * - Informazioni sul servizio (nome, versione, descrizione)
 * - Lista completa API endpoints con metodi e descrizioni
 * - Lista webhooks disponibili
 * - Health status
 * - Settings configurabili (se presenti)
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';

interface AdminPanelResponse {
  service: string;
  name: string;
  description: string;
  version: string;
  status: 'healthy' | 'degraded' | 'down';
  port: number;
  gateway_prefix: string;
  category: string; // 'Core', 'ERP', 'CMS', 'Commerce', 'Workflow', 'Integration'

  endpoints: {
    path: string;
    method: string;
    description: string;
    auth_required: boolean;
    params?: string[];
    query?: string[];
    body_schema?: any;
  }[];

  webhooks: {
    event: string;
    description: string;
    payload_schema?: any;
  }[];

  settings?: {
    key: string;
    name: string;
    description: string;
    type: 'string' | 'number' | 'boolean' | 'json';
    default_value: any;
    required: boolean;
  }[];

  documentation_url?: string;
  health_endpoint?: string;
  metrics_endpoint?: string;
}

export default async function adminPanelRoutes(fastify: FastifyInstance) {

  /**
   * GET /admin/dev/api
   * Restituisce tutte le informazioni per il pannello admin
   */
  fastify.get('/admin/dev/api', async (
    request: FastifyRequest,
    reply: FastifyReply
  ): Promise<AdminPanelResponse> => {

    // TODO: Personalizza questi valori per il tuo servizio
    return {
      service: 'example-service',
      name: 'Example Service',
      description: 'Service description here',
      version: '1.0.0',
      status: 'healthy',
      port: 4000, // Porta del servizio
      gateway_prefix: '/api/example',
      category: 'Core', // Core | ERP | CMS | Commerce | Workflow | Integration

      // Lista TUTTI gli endpoint
      endpoints: [
        {
          path: '/api/example/items',
          method: 'GET',
          description: 'Get all items',
          auth_required: true,
          query: ['limit', 'offset', 'search']
        },
        {
          path: '/api/example/items/:id',
          method: 'GET',
          description: 'Get item by ID',
          auth_required: true,
          params: ['id']
        },
        {
          path: '/api/example/items',
          method: 'POST',
          description: 'Create new item',
          auth_required: true,
          body_schema: {
            name: 'string',
            description: 'string'
          }
        }
        // ... aggiungi tutti gli altri endpoint
      ],

      // Webhooks disponibili (se il servizio supporta webhooks)
      webhooks: [
        {
          event: 'item.created',
          description: 'Triggered when a new item is created',
          payload_schema: {
            item_id: 'string',
            name: 'string',
            created_at: 'timestamp'
          }
        }
        // ... aggiungi altri webhooks
      ],

      // Settings configurabili (opzionale)
      settings: [
        {
          key: 'max_items_per_page',
          name: 'Max Items Per Page',
          description: 'Maximum number of items returned per page',
          type: 'number',
          default_value: 50,
          required: false
        }
        // ... aggiungi altri settings
      ],

      // URL opzionali
      documentation_url: '/api/example/docs',
      health_endpoint: '/api/example/health',
      metrics_endpoint: '/api/example/metrics'
    };
  });

  /**
   * GET /admin/dev/health
   * Health check dettagliato per admin panel
   */
  fastify.get('/admin/dev/health', async (
    request: FastifyRequest,
    reply: FastifyReply
  ) => {
    // TODO: Implementa health check specifico
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      checks: {
        database: 'healthy',
        cache: 'healthy',
        external_apis: 'healthy'
      }
    };
  });
}
