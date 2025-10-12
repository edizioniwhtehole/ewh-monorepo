/**
 * Hello World Plugin
 * Demonstrates the CMS plugin system
 */

exports.activate = async function(ctx) {
  ctx.logger.info('Hello World plugin activated! 🎉');

  // Register action hooks
  ctx.addAction('post.after_create', async (post) => {
    ctx.logger.info(`New post created: "${post.title}" by plugin!`);
  }, 10);

  ctx.addAction('post.after_publish', async (post) => {
    ctx.logger.info(`Post published: "${post.title}" - Congratulations! 🚀`);

    // Example: Could send notification here
    // await sendNotification({ title: post.title, status: 'published' });
  });

  // Register filter hooks
  ctx.addFilter('post.content', (content, post) => {
    ctx.logger.info(`Processing post content for: "${post.title}"`);

    // Example: Add custom watermark
    if (content && content.blocks) {
      content.blocks = content.blocks.map(block => {
        if (block.type === 'text') {
          block.data.pluginProcessed = true;
        }
        return block;
      });
    }

    return content;
  });

  // Register filter for site settings
  ctx.addFilter('site.settings', (settings, site) => {
    ctx.logger.info(`Enhancing settings for site: "${site.name}"`);

    settings.hello_world_plugin = {
      enabled: true,
      version: ctx.plugin.version,
      message: 'Plugin system working! 🎉'
    };

    return settings;
  });

  // Save a setting
  await ctx.setSetting('activation_time', new Date().toISOString());
  await ctx.setSetting('activation_count', 1);

  // Store some data
  await ctx.storage.set('last_activated', Date.now());

  ctx.logger.info('Hello World plugin hooks registered successfully');
};

exports.deactivate = async function() {
  console.log('[hello-world] Plugin deactivated');
};
