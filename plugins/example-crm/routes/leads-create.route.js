/**
 * CREATE LEAD ROUTE
 * Auto-registered as: POST /crm/leads
 */

module.exports = {
  method: 'POST',
  path: '/leads',
  middleware: ['auth', 'validate'],
  permissions: ['crm.admin', 'crm.sales'],

  handler: async (req, res, ctx) => {
    try {
      const {
        first_name,
        last_name,
        email,
        phone,
        company,
        source,
        notes
      } = req.body;

      // Validate email uniqueness
      const existing = await ctx.db.query(
        'SELECT id FROM crm.leads WHERE email = $1',
        [email]
      );

      if (existing.rows.length > 0) {
        return res.status(409).json({
          error: 'Lead with this email already exists'
        });
      }

      // Insert lead
      const result = await ctx.db.query(
        `INSERT INTO crm.leads (
          first_name, last_name, email, phone, company,
          source, notes, status, created_by
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING *`,
        [
          first_name,
          last_name,
          email,
          phone,
          company,
          source,
          notes,
          'new',
          req.user.id
        ]
      );

      const lead = result.rows[0];

      // Trigger event hook
      await ctx.hooks.doAction('lead.created', lead, req.user);

      // Log creation
      ctx.logger.info('Lead created', {
        lead_id: lead.id,
        created_by: req.user.id,
        email: lead.email
      });

      // Return created lead
      res.status(201).json(lead);
    } catch (error) {
      ctx.logger.error('Failed to create lead', { error: error.message });
      res.status(500).json({ error: 'Failed to create lead' });
    }
  },

  // Validation schema (Zod, Joi, or plain JSON schema)
  schema: {
    body: {
      first_name: { type: 'string', required: true, minLength: 1 },
      last_name: { type: 'string', required: true, minLength: 1 },
      email: { type: 'string', required: true, format: 'email' },
      phone: { type: 'string' },
      company: { type: 'string' },
      source: {
        type: 'string',
        enum: ['website', 'referral', 'social', 'advertisement', 'other']
      },
      notes: { type: 'string' }
    }
  }
};
