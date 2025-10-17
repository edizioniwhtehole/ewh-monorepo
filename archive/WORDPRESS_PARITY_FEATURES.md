# 🔌 WordPress Parity + Advanced Features

## Funzionalità WordPress + CrocoBlog + Static Generation

---

## 1. 📦 ADVANCED CUSTOM FIELDS (ACF)

### 1.1 Field Types System

```sql
CREATE TABLE cms.custom_field_groups (
  field_group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Identity
  title TEXT NOT NULL,
  slug TEXT NOT NULL,

  -- Scope - dove appare questo field group
  location_rules JSONB NOT NULL,
  -- [
  --   {
  --     "param": "post_type",
  --     "operator": "==",
  --     "value": "product"
  --   },
  --   {
  --     "param": "page_template",
  --     "operator": "==",
  --     "value": "template-landing"
  --   }
  -- ]

  -- Display
  position TEXT DEFAULT 'normal' CHECK (position IN ('normal', 'side', 'advanced')),
  menu_order INT DEFAULT 0,
  style TEXT DEFAULT 'default' CHECK (style IN ('default', 'seamless')),

  -- Fields Definition
  fields JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(site_id, slug)
);

-- Field Types disponibili
CREATE TYPE cms.field_type AS ENUM (
  -- Basic
  'text',
  'textarea',
  'number',
  'email',
  'url',
  'password',

  -- Content
  'wysiwyg',
  'code_editor',
  'markdown',

  -- Choice
  'select',
  'checkbox',
  'radio',
  'button_group',
  'true_false',

  -- Relational
  'post_object',
  'page_link',
  'relationship',
  'taxonomy',
  'user',

  -- jQuery
  'date_picker',
  'date_time_picker',
  'time_picker',
  'color_picker',

  -- Layout
  'message',
  'accordion',
  'tab',
  'group',
  'repeater',
  'flexible_content',
  'clone',

  -- Media
  'image',
  'file',
  'gallery',
  'oembed',

  -- Advanced
  'google_map',
  'link',
  'range'
);

-- Field definition example
-- {
--   "key": "field_product_price",
--   "label": "Price",
--   "name": "price",
--   "type": "number",
--   "required": true,
--   "default_value": 0,
--   "placeholder": "0.00",
--   "prepend": "$",
--   "step": 0.01,
--   "min": 0,
--   "conditional_logic": [
--     {
--       "field": "field_product_type",
--       "operator": "==",
--       "value": "physical"
--     }
--   ]
-- }
```

### 1.2 Field Values Storage

```sql
-- Metadati per any content type (pages, posts, custom post types)
CREATE TABLE cms.content_meta (
  meta_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  content_type TEXT NOT NULL, -- 'page', 'post', 'product', etc.

  -- Field info
  meta_key TEXT NOT NULL,
  meta_value JSONB NOT NULL, -- Supporta qualsiasi tipo di dato

  -- Per field repeater/flexible content
  parent_meta_id UUID REFERENCES cms.content_meta(meta_id) ON DELETE CASCADE,
  meta_order INT DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_content_meta_content ON cms.content_meta(content_id, content_type);
CREATE INDEX idx_content_meta_key ON cms.content_meta(meta_key);
CREATE INDEX idx_content_meta_parent ON cms.content_meta(parent_meta_id);

-- Query optimization per meta_value (GIN index per JSONB)
CREATE INDEX idx_content_meta_value ON cms.content_meta USING gin(meta_value);
```

### 1.3 ACF Service

```typescript
class ACFService {
  // Get field value
  async getField(contentId: string, contentType: string, fieldName: string) {
    const result = await db.query(`
      SELECT meta_value FROM cms.content_meta
      WHERE content_id = $1 AND content_type = $2 AND meta_key = $3
    `, [contentId, contentType, fieldName]);

    return result.rows[0]?.meta_value;
  }

  // Update field value
  async updateField(contentId: string, contentType: string, fieldName: string, value: any) {
    await db.query(`
      INSERT INTO cms.content_meta (content_id, content_type, meta_key, meta_value)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (content_id, content_type, meta_key)
      DO UPDATE SET
        meta_value = EXCLUDED.meta_value,
        updated_at = NOW()
    `, [contentId, contentType, fieldName, JSON.stringify(value)]);
  }

  // Get all fields for content
  async getFields(contentId: string, contentType: string): Promise<Record<string, any>> {
    const result = await db.query(`
      SELECT meta_key, meta_value FROM cms.content_meta
      WHERE content_id = $1 AND content_type = $2
    `, [contentId, contentType]);

    return result.rows.reduce((acc, row) => {
      acc[row.meta_key] = row.meta_value;
      return acc;
    }, {});
  }

  // Get repeater field
  async getRepeaterField(contentId: string, contentType: string, fieldName: string) {
    const result = await db.query(`
      WITH RECURSIVE repeater_tree AS (
        -- Root items
        SELECT * FROM cms.content_meta
        WHERE content_id = $1
          AND content_type = $2
          AND meta_key = $3
          AND parent_meta_id IS NULL

        UNION ALL

        -- Child items
        SELECT cm.* FROM cms.content_meta cm
        INNER JOIN repeater_tree rt ON cm.parent_meta_id = rt.meta_id
      )
      SELECT * FROM repeater_tree ORDER BY meta_order
    `, [contentId, contentType, fieldName]);

    // Build hierarchical structure
    return this.buildRepeaterTree(result.rows);
  }

  private buildRepeaterTree(rows: any[]) {
    const map = new Map();
    const roots = [];

    // First pass: create map
    rows.forEach(row => {
      map.set(row.meta_id, { ...row, children: [] });
    });

    // Second pass: build tree
    rows.forEach(row => {
      if (row.parent_meta_id) {
        const parent = map.get(row.parent_meta_id);
        parent.children.push(map.get(row.meta_id));
      } else {
        roots.push(map.get(row.meta_id));
      }
    });

    return roots;
  }
}

// Usage in templates
const product = await PostService.findById(productId);
const price = await ACFService.getField(productId, 'product', 'price');
const gallery = await ACFService.getRepeaterField(productId, 'product', 'gallery');
```

### 1.4 ACF UI Builder

```typescript
const ACFFieldBuilder = () => {
  const [fieldGroups, setFieldGroups] = useState([]);

  const fieldTypeTemplates = {
    text: {
      label: 'Text',
      icon: <TextIcon />,
      defaultConfig: {
        type: 'text',
        placeholder: '',
        maxlength: '',
        prepend: '',
        append: ''
      }
    },
    repeater: {
      label: 'Repeater',
      icon: <RepeatIcon />,
      defaultConfig: {
        type: 'repeater',
        min: 0,
        max: 0,
        layout: 'table', // 'table', 'block', 'row'
        button_label: 'Add Row',
        sub_fields: []
      }
    },
    flexible_content: {
      label: 'Flexible Content',
      icon: <FlexIcon />,
      defaultConfig: {
        type: 'flexible_content',
        button_label: 'Add Section',
        layouts: [] // Each layout is like a repeater
      }
    },
    // ... altri field types
  };

  return (
    <div className="acf-builder">
      <FieldGroupList
        groups={fieldGroups}
        onEdit={editGroup}
        onCreate={createGroup}
      />

      <FieldEditor
        group={selectedGroup}
        availableFields={fieldTypeTemplates}
        onAddField={addField}
        onReorder={reorderFields}
      />

      <LocationRules
        group={selectedGroup}
        onUpdateRules={updateLocationRules}
      />
    </div>
  );
};

// Esempio: Product ACF
const productACF = {
  title: 'Product Details',
  slug: 'product_details',
  location_rules: [
    {
      param: 'post_type',
      operator: '==',
      value: 'product'
    }
  ],
  fields: [
    {
      key: 'field_price',
      label: 'Price',
      name: 'price',
      type: 'number',
      prepend: '$',
      step: 0.01
    },
    {
      key: 'field_sku',
      label: 'SKU',
      name: 'sku',
      type: 'text',
      required: true
    },
    {
      key: 'field_gallery',
      label: 'Product Gallery',
      name: 'gallery',
      type: 'repeater',
      layout: 'block',
      sub_fields: [
        {
          key: 'field_gallery_image',
          label: 'Image',
          name: 'image',
          type: 'image'
        },
        {
          key: 'field_gallery_caption',
          label: 'Caption',
          name: 'caption',
          type: 'text'
        }
      ]
    },
    {
      key: 'field_sections',
      label: 'Product Sections',
      name: 'sections',
      type: 'flexible_content',
      layouts: [
        {
          key: 'layout_features',
          label: 'Features',
          sub_fields: [
            {
              key: 'field_feature_title',
              label: 'Title',
              name: 'title',
              type: 'text'
            },
            {
              key: 'field_feature_list',
              label: 'Features',
              name: 'features',
              type: 'repeater',
              sub_fields: [
                {
                  key: 'field_feature_text',
                  label: 'Feature',
                  name: 'text',
                  type: 'text'
                }
              ]
            }
          ]
        },
        {
          key: 'layout_testimonials',
          label: 'Testimonials',
          sub_fields: [
            // ... fields
          ]
        }
      ]
    }
  ]
};
```

---

## 2. ⚙️ HOOKS & FILTERS SYSTEM (WordPress-style)

### 2.1 Hook Architecture

```typescript
// Hook/Filter Registry
class HookSystem {
  private actions: Map<string, Array<{
    callback: Function;
    priority: number;
    acceptedArgs: number;
  }>> = new Map();

  private filters: Map<string, Array<{
    callback: Function;
    priority: number;
    acceptedArgs: number;
  }>> = new Map();

  // Add action hook
  addAction(
    tag: string,
    callback: Function,
    priority: number = 10,
    acceptedArgs: number = 1
  ) {
    if (!this.actions.has(tag)) {
      this.actions.set(tag, []);
    }

    this.actions.get(tag)!.push({ callback, priority, acceptedArgs });

    // Sort by priority
    this.actions.get(tag)!.sort((a, b) => a.priority - b.priority);
  }

  // Do action (execute all callbacks)
  async doAction(tag: string, ...args: any[]) {
    const hooks = this.actions.get(tag) || [];

    for (const hook of hooks) {
      const callbackArgs = args.slice(0, hook.acceptedArgs);
      await hook.callback(...callbackArgs);
    }
  }

  // Add filter hook
  addFilter(
    tag: string,
    callback: Function,
    priority: number = 10,
    acceptedArgs: number = 1
  ) {
    if (!this.filters.has(tag)) {
      this.filters.set(tag, []);
    }

    this.filters.get(tag)!.push({ callback, priority, acceptedArgs });
    this.filters.get(tag)!.sort((a, b) => a.priority - b.priority);
  }

  // Apply filters (modify value through chain)
  async applyFilters(tag: string, value: any, ...args: any[]) {
    const hooks = this.filters.get(tag) || [];
    let modifiedValue = value;

    for (const hook of hooks) {
      const callbackArgs = [modifiedValue, ...args].slice(0, hook.acceptedArgs);
      modifiedValue = await hook.callback(...callbackArgs);
    }

    return modifiedValue;
  }

  // Remove action/filter
  removeAction(tag: string, callback: Function) {
    const hooks = this.actions.get(tag) || [];
    this.actions.set(
      tag,
      hooks.filter(h => h.callback !== callback)
    );
  }

  removeFilter(tag: string, callback: Function) {
    const hooks = this.filters.get(tag) || [];
    this.filters.set(
      tag,
      hooks.filter(h => h.callback !== callback)
    );
  }
}

export const hooks = new HookSystem();
```

### 2.2 Core Hooks (WordPress-like)

```typescript
// Available hooks nel sistema
const HOOKS = {
  // Content hooks
  'content.before_save': 'Before saving content',
  'content.after_save': 'After saving content',
  'content.before_delete': 'Before deleting content',
  'content.after_delete': 'After deleting content',
  'content.before_publish': 'Before publishing content',
  'content.after_publish': 'After publishing content',

  // Post hooks
  'post.created': 'When post is created',
  'post.updated': 'When post is updated',
  'post.deleted': 'When post is deleted',
  'post.status_changed': 'When post status changes',

  // Page hooks
  'page.saved': 'When page is saved',

  // User hooks
  'user.registered': 'When user registers',
  'user.logged_in': 'When user logs in',
  'user.profile_updated': 'When user profile updates',

  // Media hooks
  'media.uploaded': 'When media is uploaded',
  'media.deleted': 'When media is deleted',

  // Comment hooks
  'comment.posted': 'When comment is posted',
  'comment.approved': 'When comment is approved'
};

const FILTERS = {
  // Content filters
  'content.title': 'Modify content title',
  'content.content': 'Modify content body',
  'content.excerpt': 'Modify content excerpt',

  // Rendering filters
  'render.post': 'Modify post before rendering',
  'render.page': 'Modify page before rendering',
  'render.widget': 'Modify widget output',

  // SEO filters
  'seo.title': 'Modify SEO title',
  'seo.description': 'Modify SEO description',

  // Query filters
  'query.posts': 'Modify posts query',
  'query.results': 'Modify query results',

  // URL filters
  'url.permalink': 'Modify permalink structure',
  'url.canonical': 'Modify canonical URL'
};
```

### 2.3 Usage Examples

```typescript
// Example 1: Auto-tag posts based on content
hooks.addAction('post.created', async (post) => {
  // Auto-generate tags from content
  const tags = await AIService.extractTags(post.content);

  for (const tag of tags) {
    await TagService.addToPost(post.post_id, tag);
  }
}, 10, 1);

// Example 2: Send notification when post published
hooks.addAction('post.after_publish', async (post) => {
  // Send to subscribers
  await NotificationService.sendToSubscribers({
    title: `New post: ${post.title}`,
    url: post.permalink
  });

  // Trigger webhook
  await WebhookService.trigger('post.published', post);
}, 10, 1);

// Example 3: Add custom content to post
hooks.addFilter('render.post', async (post) => {
  // Add reading time
  post.readingTime = calculateReadingTime(post.content);

  // Add related posts
  post.relatedPosts = await PostService.getRelated(post.post_id, 3);

  return post;
}, 10, 1);

// Example 4: Modify SEO title
hooks.addFilter('seo.title', (title, post) => {
  return `${title} | ${post.category.name} | My Site`;
}, 10, 2);

// Example 5: Add watermark to images
hooks.addAction('media.uploaded', async (media) => {
  if (media.type === 'image') {
    await ImageService.addWatermark(media.url);
  }
});

// In service code
class PostService {
  async create(data: CreatePostData) {
    // Apply filter to data before save
    data = await hooks.applyFilters('post.before_create', data);

    // Do action before save
    await hooks.doAction('post.before_save', data);

    const post = await db.query(/* ... */);

    // Do action after save
    await hooks.doAction('post.created', post);

    return post;
  }

  async publish(postId: string) {
    const post = await this.findById(postId);

    // Do action before publish
    await hooks.doAction('post.before_publish', post);

    await db.query(/* update status to published */);

    // Do action after publish
    await hooks.doAction('post.after_publish', post);

    // Clear cache
    await cache.invalidate(`post:${postId}`);
  }
}
```

### 2.4 Plugin System con Hooks

```typescript
// Plugin structure
interface Plugin {
  name: string;
  version: string;
  author: string;
  description: string;
  activate: () => Promise<void>;
  deactivate: () => Promise<void>;
}

// Example plugin: Auto-SEO
class AutoSEOPlugin implements Plugin {
  name = 'Auto SEO';
  version = '1.0.0';
  author = 'EWH';
  description = 'Automatically generate SEO meta tags';

  async activate() {
    // Add filter for SEO title
    hooks.addFilter('seo.title', this.generateTitle, 10, 1);
    hooks.addFilter('seo.description', this.generateDescription, 10, 1);
  }

  async deactivate() {
    hooks.removeFilter('seo.title', this.generateTitle);
    hooks.removeFilter('seo.description', this.generateDescription);
  }

  private generateTitle(title: string, post: any): string {
    if (!title || title.length < 10) {
      // Generate from post content
      return post.title.substring(0, 60) + '...';
    }
    return title;
  }

  private generateDescription(description: string, post: any): string {
    if (!description) {
      // Extract first paragraph
      const firstPara = post.content.split('\n\n')[0];
      return firstPara.substring(0, 160) + '...';
    }
    return description;
  }
}

// Plugin manager
class PluginManager {
  private plugins: Map<string, Plugin> = new Map();

  async install(plugin: Plugin) {
    this.plugins.set(plugin.name, plugin);
    await plugin.activate();
  }

  async uninstall(pluginName: string) {
    const plugin = this.plugins.get(pluginName);
    if (plugin) {
      await plugin.deactivate();
      this.plugins.delete(pluginName);
    }
  }
}
```

---

## 3. 📝 CUSTOM CODE INJECTION

### 3.1 Code Injection Points

```sql
CREATE TABLE cms.code_injections (
  injection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Code Identity
  name TEXT NOT NULL,
  description TEXT,

  -- Code
  code TEXT NOT NULL,
  code_type TEXT NOT NULL CHECK (code_type IN ('html', 'css', 'javascript', 'liquid')),

  -- Injection Points
  position TEXT NOT NULL CHECK (position IN (
    'head_before',      -- Before </head>
    'head_after',       -- After <head>
    'body_before',      -- Before </body>
    'body_after',       -- After <body>
    'footer',           -- In footer
    'post_before',      -- Before post content
    'post_after',       -- After post content
    'custom'            -- Custom hook name
  )),
  custom_hook TEXT,   -- If position = 'custom'

  -- Conditional Display
  display_rules JSONB DEFAULT '{
    "pages": "*",
    "post_types": "*",
    "devices": ["desktop", "mobile", "tablet"],
    "logged_in": null
  }'::jsonb,

  -- Priority
  priority INT DEFAULT 10,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_code_injections_site ON cms.code_injections(site_id);
CREATE INDEX idx_code_injections_position ON cms.code_injections(position);
```

### 3.2 Code Injection Service

```typescript
class CodeInjectionService {
  async getInjections(siteId: string, position: string) {
    const result = await db.query(`
      SELECT * FROM cms.code_injections
      WHERE site_id = $1 AND position = $2 AND is_active = TRUE
      ORDER BY priority ASC
    `, [siteId, position]);

    return result.rows;
  }

  async renderInjections(
    siteId: string,
    position: string,
    context: any
  ): Promise<string> {
    const injections = await this.getInjections(siteId, position);

    let output = '';

    for (const injection of injections) {
      // Check display rules
      if (!this.shouldDisplay(injection, context)) {
        continue;
      }

      // Render code (support Liquid templates)
      const rendered = await this.renderCode(injection.code, injection.code_type, context);

      output += rendered + '\n';
    }

    return output;
  }

  private shouldDisplay(injection: any, context: any): boolean {
    const rules = injection.display_rules;

    // Check page type
    if (rules.pages !== '*' && !rules.pages.includes(context.pageType)) {
      return false;
    }

    // Check post type
    if (rules.post_types !== '*' && !rules.post_types.includes(context.postType)) {
      return false;
    }

    // Check device
    if (!rules.devices.includes(context.device)) {
      return false;
    }

    // Check logged in
    if (rules.logged_in !== null && rules.logged_in !== context.isLoggedIn) {
      return false;
    }

    return true;
  }

  private async renderCode(code: string, codeType: string, context: any): Promise<string> {
    switch (codeType) {
      case 'liquid':
        // Render Liquid template
        return await LiquidEngine.render(code, context);

      case 'javascript':
        return `<script>${code}</script>`;

      case 'css':
        return `<style>${code}</style>`;

      case 'html':
      default:
        return code;
    }
  }
}

// In page rendering
const PageRenderer = async ({ page, context }) => {
  const headBefore = await CodeInjectionService.renderInjections(
    page.siteId,
    'head_before',
    context
  );

  const bodyAfter = await CodeInjectionService.renderInjections(
    page.siteId,
    'body_after',
    context
  );

  return `
    <!DOCTYPE html>
    <html>
      <head>
        ${headBefore}
        <title>${page.title}</title>
        <!-- ... -->
      </head>
      <body>
        ${page.content}
        ${bodyAfter}
      </body>
    </html>
  `;
};
```

---

## 4. 🚀 STATIC SITE GENERATION (SSG)

### 4.1 Database Schema

```sql
CREATE TABLE cms.static_builds (
  build_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Build Configuration
  build_type TEXT DEFAULT 'full' CHECK (build_type IN ('full', 'incremental')),
  trigger_type TEXT CHECK (trigger_type IN ('manual', 'auto', 'webhook', 'schedule')),

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'building', 'completed', 'failed')),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  duration_ms INT,

  -- Output
  output_path TEXT,
  pages_built INT DEFAULT 0,
  assets_processed INT DEFAULT 0,
  total_size_bytes BIGINT DEFAULT 0,

  -- Build Log
  build_log TEXT,
  error_log TEXT,

  -- Deployment
  deployed BOOLEAN DEFAULT FALSE,
  deployed_at TIMESTAMPTZ,
  deploy_url TEXT,

  -- Metadata
  git_commit TEXT,
  triggered_by UUID,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_static_builds_site ON cms.static_builds(site_id);
CREATE INDEX idx_static_builds_status ON cms.static_builds(status);
CREATE INDEX idx_static_builds_created ON cms.static_builds(created_at DESC);

-- Build triggers configuration
CREATE TABLE cms.static_build_triggers (
  trigger_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Trigger Configuration
  trigger_on TEXT[] DEFAULT ARRAY['post_published', 'page_updated'],
  build_type TEXT DEFAULT 'incremental',

  -- Schedule (cron expression)
  schedule_cron TEXT, -- '0 */6 * * *' = every 6 hours

  -- Deploy Configuration
  auto_deploy BOOLEAN DEFAULT TRUE,
  deploy_target TEXT, -- 'netlify', 'vercel', 's3', 'cloudflare_pages'
  deploy_config JSONB,

  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4.2 Static Site Generator

```typescript
class StaticSiteGenerator {
  async build(siteId: string, options: BuildOptions = {}) {
    const buildId = uuid();

    // Create build record
    await db.query(`
      INSERT INTO cms.static_builds (build_id, site_id, build_type, trigger_type, status)
      VALUES ($1, $2, $3, $4, 'building')
    `, [buildId, siteId, options.buildType || 'full', options.triggerType || 'manual']);

    try {
      const startTime = Date.now();

      // 1. Load site configuration
      const site = await SiteService.findById(siteId);

      // 2. Create output directory
      const outputPath = `/static-sites/${siteId}/${buildId}`;
      await fs.mkdir(outputPath, { recursive: true });

      // 3. Generate pages
      const pages = await this.generatePages(site, outputPath);

      // 4. Generate posts
      const posts = await this.generatePosts(site, outputPath);

      // 5. Copy assets
      const assets = await this.copyAssets(site, outputPath);

      // 6. Generate sitemap
      await this.generateSitemap(site, outputPath, [...pages, ...posts]);

      // 7. Generate RSS feed
      await this.generateRSS(site, outputPath, posts);

      // 8. Generate robots.txt
      await this.generateRobotsTxt(site, outputPath);

      const duration = Date.now() - startTime;
      const totalSize = await this.getDirectorySize(outputPath);

      // Update build record
      await db.query(`
        UPDATE cms.static_builds SET
          status = 'completed',
          completed_at = NOW(),
          duration_ms = $1,
          output_path = $2,
          pages_built = $3,
          assets_processed = $4,
          total_size_bytes = $5
        WHERE build_id = $6
      `, [duration, outputPath, pages.length + posts.length, assets.length, totalSize, buildId]);

      // Trigger deploy if configured
      if (options.autoDeploy) {
        await this.deploy(buildId, siteId);
      }

      return { buildId, outputPath, pages, posts, assets };

    } catch (error) {
      // Mark build as failed
      await db.query(`
        UPDATE cms.static_builds SET
          status = 'failed',
          completed_at = NOW(),
          error_log = $1
        WHERE build_id = $2
      `, [error.message, buildId]);

      throw error;
    }
  }

  private async generatePages(site: Site, outputPath: string) {
    const pages = await PageService.query({
      siteId: site.siteId,
      status: 'published'
    });

    const generated = [];

    for (const page of pages) {
      // Render page to HTML
      const html = await this.renderPage(page, site);

      // Write to file
      const filePath = `${outputPath}/${page.slug}.html`;
      await fs.writeFile(filePath, html);

      generated.push({ slug: page.slug, path: filePath });
    }

    // Generate index.html
    const homePage = pages.find(p => p.slug === 'home' || p.is_home);
    if (homePage) {
      await fs.copyFile(
        `${outputPath}/${homePage.slug}.html`,
        `${outputPath}/index.html`
      );
    }

    return generated;
  }

  private async generatePosts(site: Site, outputPath: string) {
    const posts = await PostService.query({
      siteId: site.siteId,
      status: 'published'
    });

    const generated = [];

    // Create /blog directory
    await fs.mkdir(`${outputPath}/blog`, { recursive: true });

    for (const post of posts) {
      const html = await this.renderPost(post, site);

      const filePath = `${outputPath}/blog/${post.slug}.html`;
      await fs.writeFile(filePath, html);

      generated.push({ slug: post.slug, path: filePath });
    }

    // Generate blog index with pagination
    await this.generateBlogIndex(site, outputPath, posts);

    return generated;
  }

  private async renderPage(page: any, site: Site): Promise<string> {
    // Use template engine (React, Vue, Liquid, etc.)
    const context = {
      page,
      site,
      meta: await SEOService.getMeta(page.page_id, 'page')
    };

    return await TemplateEngine.render('page', context);
  }

  private async generateSitemap(site: Site, outputPath: string, content: any[]) {
    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${content.map(item => `
  <url>
    <loc>${site.url}/${item.slug}</loc>
    <lastmod>${item.updated_at}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>
`).join('')}
</urlset>`;

    await fs.writeFile(`${outputPath}/sitemap.xml`, xml);
  }

  private async deploy(buildId: string, siteId: string) {
    // Get deployment config
    const config = await db.query(`
      SELECT deploy_target, deploy_config FROM cms.static_build_triggers
      WHERE site_id = $1 AND is_active = TRUE
      LIMIT 1
    `, [siteId]);

    if (!config.rows[0]) return;

    const { deploy_target, deploy_config } = config.rows[0];

    const build = await db.query(
      'SELECT output_path FROM cms.static_builds WHERE build_id = $1',
      [buildId]
    );

    const outputPath = build.rows[0].output_path;

    // Deploy based on target
    let deployUrl: string;

    switch (deploy_target) {
      case 'netlify':
        deployUrl = await this.deployToNetlify(outputPath, deploy_config);
        break;

      case 'vercel':
        deployUrl = await this.deployToVercel(outputPath, deploy_config);
        break;

      case 's3':
        deployUrl = await this.deployToS3(outputPath, deploy_config);
        break;

      case 'cloudflare_pages':
        deployUrl = await this.deployToCloudflare(outputPath, deploy_config);
        break;

      default:
        throw new Error(`Unknown deploy target: ${deploy_target}`);
    }

    // Update build record
    await db.query(`
      UPDATE cms.static_builds SET
        deployed = TRUE,
        deployed_at = NOW(),
        deploy_url = $1
      WHERE build_id = $2
    `, [deployUrl, buildId]);

    return deployUrl;
  }

  private async deployToNetlify(outputPath: string, config: any) {
    // Netlify deployment via API
    const tarball = await this.createTarball(outputPath);

    const response = await fetch('https://api.netlify.com/api/v1/sites', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.api_token}`,
        'Content-Type': 'application/zip'
      },
      body: tarball
    });

    const data = await response.json();
    return data.url;
  }
}

// Hooks integration for auto-build
hooks.addAction('post.after_publish', async (post) => {
  const triggers = await db.query(`
    SELECT * FROM cms.static_build_triggers
    WHERE site_id = $1 AND is_active = TRUE
      AND 'post_published' = ANY(trigger_on)
  `, [post.site_id]);

  for (const trigger of triggers.rows) {
    if (trigger.build_type === 'incremental') {
      await StaticSiteGenerator.buildIncremental(post.site_id, [post]);
    } else {
      await StaticSiteGenerator.build(post.site_id, {
        buildType: 'full',
        triggerType: 'auto',
        autoDeploy: trigger.auto_deploy
      });
    }
  }
});
```

### 4.3 Incremental Static Regeneration (ISR)

```typescript
class IncrementalStaticRegenerator {
  async regenerate(siteId: string, changedContent: any[]) {
    // Only rebuild affected pages
    for (const content of changedContent) {
      await this.rebuildPage(siteId, content);

      // Rebuild related pages (eg. category pages, index)
      const relatedPages = await this.getRelatedPages(content);
      for (const page of relatedPages) {
        await this.rebuildPage(siteId, page);
      }
    }

    // Invalidate CDN cache
    await this.invalidateCDNCache(changedContent);
  }

  private async getRelatedPages(content: any) {
    // Example: if post published, rebuild:
    // - Blog index
    // - Category archive
    // - Tag archives
    // - Related posts pages

    return [
      { type: 'index', slug: 'blog' },
      { type: 'category', slug: content.category.slug },
      ...content.tags.map(tag => ({ type: 'tag', slug: tag.slug }))
    ];
  }
}
```

---

## 🎯 ROADMAP AGGIORNATA FINALE

### Aggiungi alle fasi precedenti:

### Phase 18: ACF System (2-3 settimane)
1. ✅ Custom field groups
2. ✅ 20+ field types
3. ✅ Repeater & flexible content
4. ✅ Conditional logic
5. ✅ Field group UI builder

### Phase 19: Hooks & Filters (1-2 settimane)
1. ✅ Hook system (actions/filters)
2. ✅ 50+ core hooks
3. ✅ Plugin system
4. ✅ Code injection system

### Phase 20: Static Site Generation (2-3 settimane)
1. ✅ Full site builder
2. ✅ Incremental regeneration
3. ✅ Multi-platform deploy (Netlify, Vercel, S3, CF)
4. ✅ Auto-build triggers
5. ✅ CDN integration

---

## 📊 TIMELINE FINALE COMPLETA

**32-40 settimane** (8-10 mesi)

Breakdown completo:
- Fase 1-11 (security/base): 16-21 settimane
- Fase 12-17 (advanced CMS): 10-12 settimane
- Fase 18-20 (WordPress parity): 5-8 settimane

---

## 💰 COSTI FINALI TOTALI

### Development
- Precedente: ~$120-170k
- ACF + Hooks + SSG: ~$25-40k
- **TOTALE: ~$145-210k**

### Infrastructure (mensile)
- Database cluster: ~$2,000-5,000
- Static hosting (Netlify/Vercel): ~$50-200
- CDN: ~$50-200
- Build servers: ~$200-500
- **TOTALE: ~$2,300-5,900/mese**

---

## 🏆 FEATURE COMPARISON FINALE

| Feature | WordPress | EWH CMS | Status |
|---------|-----------|---------|---------|
| Custom Post Types | ✅ | ✅ | Complete |
| ACF / Custom Fields | ✅ (plugin) | ✅ Built-in | Enhanced |
| Hooks & Filters | ✅ | ✅ | Complete |
| Multi-site | ✅ | ✅ | Enhanced |
| Multi-language | ⚠️ (plugin) | ✅ Built-in | Better |
| Static Generation | ❌ | ✅ | New! |
| Database Isolation | ❌ | ✅ | New! |
| Component Marketplace | ⚠️ Limited | ✅ | Better |
| Visual Builder | ⚠️ (Elementor) | ✅ Built-in | Better |
| API-First | ⚠️ REST only | ✅ REST + GraphQL | Better |
| Real-time Collab | ❌ | ✅ | New! |
| A/B Testing | ⚠️ (plugin) | ✅ Built-in | Better |

**Risultato: EWH CMS >> WordPress + plugins ecosystem**

---

Questo è il sistema CMS più completo ed enterprise che si possa immaginare! Vuoi che inizi l'implementazione di una fase specifica?
