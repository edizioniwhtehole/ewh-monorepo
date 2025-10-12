-- CMS Sample Data for Development/Demo
-- This creates initial data for the CMS system

-- Get tenant and user IDs (using existing data)
DO $$
DECLARE
  v_tenant_id UUID := '1845c89e-63c6-4be2-85bc-07c40bacdef9'; -- White Hole SRL
  v_user_id UUID := (SELECT id FROM auth.users WHERE email = 'fabio.polosa@gmail.com' LIMIT 1);
  v_site_id UUID;
  v_post_id UUID;
  v_page_id UUID;
  v_taxonomy_id UUID;
  v_term_id UUID;
BEGIN

  -- =====================
  -- 1. CREATE SAMPLE SITES
  -- =====================

  -- Main Corporate Site
  INSERT INTO cms.sites (
    site_id, tenant_id, name, description, site_type,
    primary_domain, is_primary, status,
    created_by, updated_by, published_at
  ) VALUES (
    gen_random_uuid(), v_tenant_id,
    'White Hole Corporate',
    'Main corporate website for White Hole SRL',
    'main',
    'whiteholesrl.com', true, 'active',
    v_user_id, v_user_id, NOW()
  ) RETURNING site_id INTO v_site_id;

  -- Add primary domain
  INSERT INTO cms.domains (
    domain_id, site_id, domain_name, is_primary, ssl_enabled,
    status, created_by, updated_by
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'whiteholesrl.com', true, true,
    'active', v_user_id, v_user_id
  );

  -- Blog Site
  INSERT INTO cms.sites (
    site_id, tenant_id, name, description, site_type,
    primary_domain, status, created_by, updated_by, published_at
  ) VALUES (
    gen_random_uuid(), v_tenant_id,
    'White Hole Blog',
    'Company blog and news',
    'blog',
    'blog.whiteholesrl.com', 'active',
    v_user_id, v_user_id, NOW()
  );

  -- =====================
  -- 2. CREATE TAXONOMIES
  -- =====================

  -- Blog Categories
  INSERT INTO cms.taxonomies (
    taxonomy_id, site_id, name, slug, type, description,
    hierarchical, created_by, updated_by
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'Blog Categories', 'blog-categories', 'category',
    'Categories for blog posts', true,
    v_user_id, v_user_id
  ) RETURNING taxonomy_id INTO v_taxonomy_id;

  -- Add some terms
  INSERT INTO cms.terms (
    term_id, taxonomy_id, name, slug, description, parent_id,
    created_by, updated_by
  ) VALUES
    (gen_random_uuid(), v_taxonomy_id, 'Technology', 'technology', 'Tech articles and news', NULL, v_user_id, v_user_id),
    (gen_random_uuid(), v_taxonomy_id, 'Business', 'business', 'Business insights', NULL, v_user_id, v_user_id),
    (gen_random_uuid(), v_taxonomy_id, 'Design', 'design', 'Design trends and tips', NULL, v_user_id, v_user_id),
    (gen_random_uuid(), v_taxonomy_id, 'Development', 'development', 'Software development', NULL, v_user_id, v_user_id)
  RETURNING term_id INTO v_term_id;

  -- Tags taxonomy
  INSERT INTO cms.taxonomies (
    taxonomy_id, site_id, name, slug, type, description,
    hierarchical, created_by, updated_by
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'Tags', 'tags', 'tag',
    'Content tags', false,
    v_user_id, v_user_id
  );

  -- =====================
  -- 3. CREATE SAMPLE POSTS
  -- =====================

  -- Welcome Post
  INSERT INTO cms.posts (
    post_id, site_id, title, slug, content, excerpt,
    status, visibility, author_id, featured_image,
    created_by, updated_by, published_at
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'Welcome to White Hole CMS',
    'welcome-to-white-hole-cms',
    '# Welcome to White Hole CMS

This is your first blog post! The CMS is now fully operational with:

## Features Available

- **Rich Content Editor** - Write beautiful content with Markdown support
- **Media Management** - Upload and organize images, videos, and documents
- **SEO Optimization** - Built-in SEO fields and metadata
- **Multi-site Support** - Manage multiple websites from one dashboard
- **Advanced Custom Fields** - Extend your content with custom fields
- **User Permissions** - Role-based access control

## Getting Started

1. Create your first page in the Pages section
2. Set up your site navigation
3. Configure your theme settings
4. Start publishing content!

Enjoy building with White Hole CMS 🚀',
    'Welcome to the White Hole CMS! Start creating amazing content today.',
    'published', 'public', v_user_id,
    'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=1200',
    v_user_id, v_user_id, NOW()
  ) RETURNING post_id INTO v_post_id;

  -- Link post to category
  INSERT INTO cms.term_relationships (content_type, content_id, term_id)
  VALUES ('post', v_post_id, v_term_id);

  -- Getting Started Post
  INSERT INTO cms.posts (
    post_id, site_id, title, slug, content, excerpt,
    status, visibility, author_id, featured_image,
    created_by, updated_by, published_at
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'Getting Started with the CMS',
    'getting-started-cms',
    '# Getting Started with the CMS

## Your Dashboard

The dashboard gives you an overview of:
- Total sites and pages
- Recent posts
- Active plugins
- Quick actions

## Creating Content

Navigate to **Posts** or **Pages** to create new content. Use the powerful editor with:
- Markdown support
- Image uploads
- SEO fields
- Custom fields (ACF)

## Managing Sites

Go to **Sites Manager** to:
- Create new sites
- Configure domains
- Manage SSL certificates
- Site-specific settings

## Next Steps

Check out the documentation to learn more about advanced features!',
    'Learn how to use the CMS dashboard and create your first content.',
    'published', 'public', v_user_id,
    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=1200',
    v_user_id, v_user_id, NOW()
  );

  -- Draft Post
  INSERT INTO cms.posts (
    post_id, site_id, title, slug, content, excerpt,
    status, visibility, author_id,
    created_by, updated_by
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'Upcoming Features',
    'upcoming-features',
    '# Upcoming Features

We''re working on exciting new features:

- Advanced workflow management
- Multi-language support
- Enhanced media library
- AI-powered content suggestions
- Advanced analytics

Stay tuned!',
    'Preview of upcoming CMS features.',
    'draft', 'public', v_user_id,
    v_user_id, v_user_id
  );

  -- =====================
  -- 4. CREATE SAMPLE PAGES
  -- =====================

  -- Homepage
  INSERT INTO cms.pages (
    page_id, site_id, title, slug, content,
    status, visibility, template, parent_id, menu_order,
    author_id, created_by, updated_by, published_at
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'Home',
    'home',
    '# Welcome to White Hole

Your trusted partner in digital transformation.

## Our Services
- Web Development
- Mobile Apps
- Cloud Solutions
- Consulting

[Contact Us](/contact)',
    'published', 'public', 'homepage', NULL, 0,
    v_user_id, v_user_id, v_user_id, NOW()
  ) RETURNING page_id INTO v_page_id;

  -- About Page
  INSERT INTO cms.pages (
    page_id, site_id, title, slug, content,
    status, visibility, template, parent_id, menu_order,
    author_id, created_by, updated_by, published_at
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'About Us',
    'about',
    '# About White Hole SRL

Founded in 2020, White Hole is a leading software development company.

## Our Mission
To deliver innovative digital solutions that transform businesses.

## Our Team
We are a team of passionate developers, designers, and strategists.',
    'published', 'public', 'default', NULL, 1,
    v_user_id, v_user_id, v_user_id, NOW()
  );

  -- Services Page
  INSERT INTO cms.pages (
    page_id, site_id, title, slug, content,
    status, visibility, template, parent_id, menu_order,
    author_id, created_by, updated_by, published_at
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'Services',
    'services',
    '# Our Services

## Web Development
Custom web applications built with modern technologies.

## Mobile Development
Native and cross-platform mobile apps.

## Cloud Solutions
Scalable cloud infrastructure and DevOps.

## Consulting
Expert guidance for your digital transformation journey.',
    'published', 'public', 'default', NULL, 2,
    v_user_id, v_user_id, v_user_id, NOW()
  );

  -- Contact Page
  INSERT INTO cms.pages (
    page_id, site_id, title, slug, content,
    status, visibility, template, parent_id, menu_order,
    author_id, created_by, updated_by, published_at
  ) VALUES (
    gen_random_uuid(), v_site_id,
    'Contact',
    'contact',
    '# Get in Touch

## Contact Information

**Email:** info@whiteholesrl.com
**Phone:** +39 02 1234 5678
**Address:** Via Example 123, Milano, Italy

## Office Hours
Monday - Friday: 9:00 - 18:00',
    'published', 'public', 'contact', NULL, 3,
    v_user_id, v_user_id, v_user_id, NOW()
  );

  -- =====================
  -- 5. CREATE ACF FIELD GROUP
  -- =====================

  INSERT INTO cms.acf_field_groups (
    field_group_id, tenant_id, title, key,
    location, position, style, active, menu_order
  ) VALUES (
    gen_random_uuid(), v_tenant_id,
    'Page Hero Section',
    'group_page_hero',
    '[[{"param":"page_type","operator":"==","value":"homepage"}]]'::jsonb,
    'normal', 'default', true, 0
  );

  RAISE NOTICE 'Sample CMS data created successfully!';
  RAISE NOTICE '- 2 Sites created';
  RAISE NOTICE '- 3 Posts created (2 published, 1 draft)';
  RAISE NOTICE '- 4 Pages created';
  RAISE NOTICE '- 2 Taxonomies with terms';
  RAISE NOTICE '- 1 ACF field group';

END $$;
