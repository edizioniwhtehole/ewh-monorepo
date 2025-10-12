/**
 * HEALTH CHECK ROUTE
 * Auto-registered as: GET /crm/health
 * Public route (no auth required)
 */

module.exports = {
  method: 'GET',
  path: '/health',
  middleware: [], // No auth required
  permissions: [], // Public

  handler: async (req, res, ctx) => {
    try {
      // Check database connectivity
      await ctx.db.query('SELECT 1');

      // Get plugin info
      const { name, version } = ctx.plugin;

      // Return health status
      res.json({
        status: 'ok',
        plugin: name,
        version,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(503).json({
        status: 'error',
        error: error.message
      });
    }
  }
};
