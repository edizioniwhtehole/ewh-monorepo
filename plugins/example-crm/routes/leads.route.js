/**
 * AUTO-REGISTERED ROUTE
 * This file is automatically discovered and registered by the plugin system
 * No manual route registration needed!
 */

module.exports = {
  // Route configuration
  method: 'GET',
  path: '/leads',

  // Optional middleware
  middleware: ['auth'],

  // Required permissions
  permissions: ['crm.view'],

  // Route handler
  handler: async (req, res, ctx) => {
    try {
      // ctx = PluginContext with db, logger, settings, etc.
      const { page = 1, limit = 20, status } = req.query;
      const offset = (page - 1) * limit;

      // Build query
      let query = 'SELECT * FROM crm.leads';
      const params = [];

      if (status) {
        query += ' WHERE status = $1';
        params.push(status);
      }

      query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
      params.push(limit, offset);

      // Execute query (sandboxed to crm schema)
      const result = await ctx.db.query(query, params);

      // Get total count
      const countQuery = status
        ? 'SELECT COUNT(*) FROM crm.leads WHERE status = $1'
        : 'SELECT COUNT(*) FROM crm.leads';
      const countResult = await ctx.db.query(countQuery, status ? [status] : []);
      const total = parseInt(countResult.rows[0].count);

      // Log activity
      ctx.logger.info('Leads retrieved', {
        user: req.user?.id,
        count: result.rows.length,
        status
      });

      // Return response
      res.json({
        data: result.rows,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      });
    } catch (error) {
      ctx.logger.error('Failed to retrieve leads', { error: error.message });
      res.status(500).json({ error: 'Failed to retrieve leads' });
    }
  },

  // Optional: OpenAPI/Swagger schema
  schema: {
    query: {
      page: { type: 'integer', minimum: 1 },
      limit: { type: 'integer', minimum: 1, maximum: 100 },
      status: { type: 'string', enum: ['new', 'contacted', 'qualified', 'lost'] }
    },
    response: {
      200: {
        data: { type: 'array' },
        pagination: { type: 'object' }
      }
    }
  }
};
