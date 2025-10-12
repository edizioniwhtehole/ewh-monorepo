/**
 * EXAMPLE CRM PLUGIN
 * Demonstrates zero-touch modular development
 *
 * This plugin automatically:
 * - Registers routes from routes/*.route.js
 * - Runs migrations from migrations/*.sql
 * - Mounts UI from ui/
 * - Registers permissions from plugin.json
 *
 * NO CORE CODE CHANGES NEEDED!
 */

/**
 * Plugin activation
 * Called when plugin is activated
 *
 * @param {PluginContext} ctx - Plugin context
 */
exports.activate = async function (ctx) {
  ctx.logger.info('CRM Plugin activating...');

  // Initialize plugin settings
  await ctx.settings.set('email_notifications', true);
  await ctx.settings.set('auto_assign_leads', false);
  await ctx.settings.set('default_currency', 'USD');

  // Register event hooks
  ctx.hooks.addAction('lead.created', onLeadCreated.bind(null, ctx));
  ctx.hooks.addAction('deal.closed', onDealClosed.bind(null, ctx));

  // Add filter to modify lead data before save
  ctx.hooks.addFilter('lead.before_save', enrichLeadData.bind(null, ctx));

  ctx.logger.info('CRM Plugin activated successfully', {
    routes: 'auto-registered from routes/',
    migrations: 'auto-run from migrations/',
    ui: 'auto-mounted at /app/crm'
  });
};

/**
 * Plugin deactivation
 * Called when plugin is deactivated
 *
 * @param {PluginContext} ctx - Plugin context
 */
exports.deactivate = async function (ctx) {
  ctx.logger.info('CRM Plugin deactivating...');

  // Remove event hooks (cleanup)
  // The plugin system will handle this automatically,
  // but you can do manual cleanup here if needed

  ctx.logger.info('CRM Plugin deactivated');
};

/**
 * Plugin upgrade
 * Called when plugin version changes
 *
 * @param {PluginContext} ctx - Plugin context
 * @param {string} fromVersion - Previous version
 * @param {string} toVersion - New version
 */
exports.upgrade = async function (ctx, fromVersion, toVersion) {
  ctx.logger.info(`Upgrading CRM plugin from ${fromVersion} to ${toVersion}`);

  // Version-specific upgrade logic
  if (fromVersion === '1.0.0' && toVersion === '2.0.0') {
    // Example: Add new column
    await ctx.db.query('ALTER TABLE crm.leads ADD COLUMN IF NOT EXISTS tags TEXT[]');
    ctx.logger.info('Added tags column to leads table');
  }

  ctx.logger.info('CRM plugin upgrade complete');
};

// ============================================
// EVENT HANDLERS
// ============================================

/**
 * Called when a lead is created
 * Hook: 'lead.created'
 */
async function onLeadCreated(ctx, lead, user) {
  ctx.logger.info('New lead created', {
    lead_id: lead.id,
    email: lead.email,
    created_by: user.id
  });

  // Send notification if enabled
  const emailNotifications = await ctx.settings.get('email_notifications');
  if (emailNotifications) {
    // Send email to sales team
    await sendLeadNotification(ctx, lead);
  }

  // Auto-assign if enabled
  const autoAssign = await ctx.settings.get('auto_assign_leads');
  if (autoAssign) {
    await autoAssignLead(ctx, lead);
  }

  // Track in analytics
  await ctx.events.emit('analytics.track', {
    event: 'lead_created',
    properties: {
      lead_id: lead.id,
      source: lead.source
    }
  });
}

/**
 * Called when a deal is closed
 * Hook: 'deal.closed'
 */
async function onDealClosed(ctx, deal, user) {
  ctx.logger.info('Deal closed', {
    deal_id: deal.id,
    stage: deal.stage,
    amount: deal.amount
  });

  // Update lead if connected
  if (deal.lead_id && deal.stage === 'closed_won') {
    await ctx.db.query(
      `UPDATE crm.leads
       SET status = 'converted', converted_at = NOW()
       WHERE id = $1`,
      [deal.lead_id]
    );
  }

  // Send notification
  if (deal.stage === 'closed_won') {
    await sendDealWonNotification(ctx, deal);
  }

  // Track revenue
  await ctx.events.emit('analytics.revenue', {
    deal_id: deal.id,
    amount: deal.amount,
    currency: deal.currency
  });
}

/**
 * Enrich lead data before save
 * Filter: 'lead.before_save'
 */
async function enrichLeadData(ctx, lead) {
  // Add default values
  if (!lead.source) {
    lead.source = 'other';
  }

  // Normalize email
  if (lead.email) {
    lead.email = lead.email.toLowerCase().trim();
  }

  // Add metadata
  lead.enriched_at = new Date().toISOString();

  return lead;
}

// ============================================
// HELPER FUNCTIONS
// ============================================

async function sendLeadNotification(ctx, lead) {
  // Use communication service to send email
  try {
    await ctx.http.post('http://svc-comm:3000/email/send', {
      to: 'sales@company.com',
      subject: `New Lead: ${lead.first_name} ${lead.last_name}`,
      template: 'new_lead',
      data: lead
    });
    ctx.logger.info('Lead notification sent', { lead_id: lead.id });
  } catch (error) {
    ctx.logger.error('Failed to send lead notification', {
      error: error.message
    });
  }
}

async function autoAssignLead(ctx, lead) {
  // Simple round-robin assignment logic
  try {
    const result = await ctx.db.query(`
      SELECT id FROM auth.users
      WHERE role = 'sales'
      ORDER BY
        (SELECT COUNT(*) FROM crm.leads WHERE assigned_to = auth.users.id) ASC
      LIMIT 1
    `);

    if (result.rows.length > 0) {
      const assigneeId = result.rows[0].id;
      await ctx.db.query(
        'UPDATE crm.leads SET assigned_to = $1 WHERE id = $2',
        [assigneeId, lead.id]
      );
      ctx.logger.info('Lead auto-assigned', {
        lead_id: lead.id,
        assigned_to: assigneeId
      });
    }
  } catch (error) {
    ctx.logger.error('Failed to auto-assign lead', {
      error: error.message
    });
  }
}

async function sendDealWonNotification(ctx, deal) {
  try {
    await ctx.http.post('http://svc-comm:3000/email/send', {
      to: 'sales@company.com',
      subject: `Deal Won: ${deal.title}`,
      template: 'deal_won',
      data: deal
    });
  } catch (error) {
    ctx.logger.error('Failed to send deal won notification', {
      error: error.message
    });
  }
}
