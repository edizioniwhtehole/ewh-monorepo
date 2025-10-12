-- ============================================================================
-- SITE MANAGEMENT & MULTI-DOMAIN SCHEMA (FIXED)
-- Enterprise-grade multi-site CMS with domain mapping
-- ============================================================================

-- Drop existing tables if they exist (for clean slate)
DROP TABLE IF EXISTS cms.redirects CASCADE;
DROP TABLE IF EXISTS cms.seo_meta CASCADE;
DROP TABLE IF EXISTS cms.post_revisions CASCADE;
DROP TABLE IF EXISTS cms.posts CASCADE;
DROP TABLE IF EXISTS cms.content_terms CASCADE;
DROP TABLE IF EXISTS cms.terms CASCADE;
DROP TABLE IF EXISTS cms.taxonomies CASCADE;
DROP TABLE IF EXISTS cms.site_domains CASCADE;
DROP TABLE IF EXISTS cms.sites CASCADE;

-- ============================================================================
-- SITES TABLE
-- Multi-site management per tenant - ogni tenant può avere più siti
-- ============================================================================
CREATE TABLE cms.sites (
  site_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL, -- Ogni site appartiene a un tenant

  -- Site Identity
  name TEXT NOT NULL,
  description TEXT,
  site_type TEXT NOT NULL CHECK (site_type IN ('main', 'microsite', 'landing', 'blog', 'docs', 'store')),

  -- Domain Configuration
  primary_domain TEXT UNIQUE, -- es. 'example.com'
  is_primary BOOLEAN DEFAULT FALSE, -- Solo un site primary per tenant

  -- Site Settings
  settings JSONB DEFAULT '{}'::jsonb, -- Theme, layout, features, etc.
  locale_settings JSONB DEFAULT '{}'::jsonb, -- Default locale, supported locales
  seo_defaults JSONB DEFAULT '{}'::jsonb, -- Default meta tags, OG tags

  -- Status
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'maintenance', 'suspended')),
  published_at TIMESTAMPTZ,

  -- Audit
  created_by UUID NOT NULL,
  updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unique constraint for one primary site per tenant
CREATE UNIQUE INDEX idx_sites_one_primary_per_tenant ON cms.sites(tenant_id)
  WHERE is_primary = TRUE;

CREATE INDEX idx_sites_tenant_id ON cms.sites(tenant_id);
CREATE INDEX idx_sites_primary_domain ON cms.sites(primary_domain);
CREATE INDEX idx_sites_status ON cms.sites(status);

COMMENT ON TABLE cms.sites IS 'Multi-site management - ogni tenant può gestire più siti separati';
COMMENT ON COLUMN cms.sites.is_primary IS 'Sito principale del tenant (solo uno consentito)';

-- ============================================================================
-- SITE DOMAINS TABLE
-- Mapping di domini e sottodomini a sites
-- ============================================================================
CREATE TABLE cms.site_domains (
  domain_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL REFERENCES cms.sites(site_id) ON DELETE CASCADE,

  -- Domain Configuration
  domain TEXT UNIQUE NOT NULL, -- es. 'blog.example.com', 'www.example.com'
  domain_type TEXT NOT NULL CHECK (domain_type IN ('primary', 'subdomain', 'alias', 'custom')),
  is_active BOOLEAN DEFAULT TRUE,

  -- SSL/TLS
  ssl_enabled BOOLEAN DEFAULT TRUE,
  ssl_certificate TEXT, -- Certificate ID o path
  ssl_auto_provision BOOLEAN DEFAULT TRUE, -- Auto Let's Encrypt

  -- Redirect Rules
  redirect_to TEXT, -- Domain di destinazione per redirect
  redirect_type TEXT CHECK (redirect_type IN ('301', '302', 'none')),

  -- DNS Configuration
  dns_verified BOOLEAN DEFAULT FALSE,
  dns_verification_token TEXT,
  dns_verified_at TIMESTAMPTZ,

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_site_domains_site_id ON cms.site_domains(site_id);
CREATE INDEX idx_site_domains_domain ON cms.site_domains(domain);
CREATE INDEX idx_site_domains_is_active ON cms.site_domains(is_active);

COMMENT ON TABLE cms.site_domains IS 'Mapping di domini/sottodomini a sites - supporta multi-domain per site';
COMMENT ON COLUMN cms.site_domains.dns_verified IS 'Domain ownership verificato via DNS challenge';

-- ============================================================================
-- SITE PAGES MAPPING
-- Collega pages ai sites (una page può appartenere a un solo site)
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'cms'
      AND table_name = 'pages'
      AND column_name = 'site_id'
  ) THEN
    ALTER TABLE cms.pages ADD COLUMN site_id UUID REFERENCES cms.sites(site_id) ON DELETE CASCADE;
    CREATE INDEX idx_pages_site_id ON cms.pages(site_id);
  END IF;
END $$;

COMMENT ON COLUMN cms.pages.site_id IS 'Site a cui appartiene questa page - NULL per pages globali/admin';

-- ============================================================================
-- CONTENT TAXONOMY SYSTEM
-- Sistema di categorizzazione enterprise: categories, tags, custom taxonomies
-- ============================================================================

-- Taxonomies Definition Table
CREATE TABLE cms.taxonomies (
  taxonomy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID, -- NULL = platform-wide taxonomy

  -- Taxonomy Identity
  slug TEXT NOT NULL, -- 'category', 'tag', 'product-type', etc.
  name TEXT NOT NULL,
  description TEXT,
  taxonomy_type TEXT NOT NULL CHECK (taxonomy_type IN ('hierarchical', 'flat')),

  -- Configuration
  is_system BOOLEAN DEFAULT FALSE, -- Built-in taxonomies (category, tag)
  is_required BOOLEAN DEFAULT FALSE, -- Must be assigned to content
  allow_multiple BOOLEAN DEFAULT TRUE, -- Allow multiple terms per content

  -- Scope
  applicable_to TEXT[] DEFAULT ARRAY['page'], -- ['page', 'post', 'media', 'product']

  -- Status
  is_active BOOLEAN DEFAULT TRUE,

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tenant_id, slug)
);

CREATE INDEX idx_taxonomies_tenant_id ON cms.taxonomies(tenant_id);
CREATE INDEX idx_taxonomies_slug ON cms.taxonomies(slug);
CREATE INDEX idx_taxonomies_is_system ON cms.taxonomies(is_system);

COMMENT ON TABLE cms.taxonomies IS 'Definizioni di tassonomie custom - categories, tags, etc.';
COMMENT ON COLUMN cms.taxonomies.taxonomy_type IS 'hierarchical=con parent/child, flat=piatto';

-- Terms Table (actual taxonomy values)
CREATE TABLE cms.terms (
  term_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  taxonomy_id UUID NOT NULL REFERENCES cms.taxonomies(taxonomy_id) ON DELETE CASCADE,

  -- Term Identity
  slug TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,

  -- Hierarchy (per hierarchical taxonomies)
  parent_id UUID REFERENCES cms.terms(term_id) ON DELETE CASCADE,
  term_order INT DEFAULT 0,
  term_path TEXT, -- Materialized path: '/parent-slug/child-slug/'

  -- Metadata
  meta_data JSONB DEFAULT '{}'::jsonb, -- Color, icon, image, custom fields

  -- Stats
  usage_count INT DEFAULT 0, -- Numero di contenuti con questo term

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(taxonomy_id, slug)
);

CREATE INDEX idx_terms_taxonomy_id ON cms.terms(taxonomy_id);
CREATE INDEX idx_terms_slug ON cms.terms(slug);
CREATE INDEX idx_terms_parent_id ON cms.terms(parent_id);
CREATE INDEX idx_terms_path ON cms.terms USING gin(to_tsvector('simple', coalesce(term_path, '')));
CREATE INDEX idx_terms_usage_count ON cms.terms(usage_count DESC);

COMMENT ON TABLE cms.terms IS 'Valori effettivi delle tassonomie (es. "Technology", "News")';
COMMENT ON COLUMN cms.terms.term_path IS 'Materialized path per query gerarchiche veloci';

-- Content Terms Relationship (many-to-many)
CREATE TABLE cms.content_terms (
  content_term_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL, -- page_id, post_id, media_id, etc.
  content_type TEXT NOT NULL, -- 'page', 'post', 'media'
  term_id UUID NOT NULL REFERENCES cms.terms(term_id) ON DELETE CASCADE,
  term_order INT DEFAULT 0, -- Ordine di visualizzazione

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(content_id, content_type, term_id)
);

CREATE INDEX idx_content_terms_content ON cms.content_terms(content_id, content_type);
CREATE INDEX idx_content_terms_term_id ON cms.content_terms(term_id);

COMMENT ON TABLE cms.content_terms IS 'Relazione many-to-many tra contenuti e terms';

-- ============================================================================
-- POSTS TABLE (Blog/News system)
-- Sistema di post per blog, news, articles
-- ============================================================================
CREATE TABLE cms.posts (
  post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL REFERENCES cms.sites(site_id) ON DELETE CASCADE,

  -- Post Identity
  slug TEXT NOT NULL,
  title TEXT NOT NULL,
  excerpt TEXT,
  content JSONB NOT NULL, -- Rich content (blocks/widgets)
  featured_image TEXT,

  -- Post Type
  post_type TEXT NOT NULL DEFAULT 'post' CHECK (post_type IN ('post', 'article', 'news', 'tutorial', 'case-study')),
  post_format TEXT DEFAULT 'standard' CHECK (post_format IN ('standard', 'video', 'gallery', 'quote', 'link')),

  -- SEO & Meta
  meta_title TEXT,
  meta_description TEXT,
  meta_keywords TEXT[],
  meta_data JSONB DEFAULT '{}'::jsonb, -- OG tags, Twitter cards, structured data

  -- Authoring
  author_id UUID NOT NULL,
  co_authors UUID[], -- Additional authors

  -- Publishing
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'published', 'scheduled', 'archived')),
  published_at TIMESTAMPTZ,
  scheduled_publish_at TIMESTAMPTZ,

  -- Engagement
  view_count INT DEFAULT 0,
  like_count INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  share_count INT DEFAULT 0,

  -- Settings
  allow_comments BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  is_sticky BOOLEAN DEFAULT FALSE, -- Pin to top

  -- Permissions
  visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'password', 'members')),
  password_hash TEXT, -- For password-protected posts
  required_roles TEXT[],

  -- Audit
  created_by UUID NOT NULL,
  updated_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(site_id, slug)
);

CREATE INDEX idx_posts_site_id ON cms.posts(site_id);
CREATE INDEX idx_posts_slug ON cms.posts(slug);
CREATE INDEX idx_posts_status ON cms.posts(status);
CREATE INDEX idx_posts_author_id ON cms.posts(author_id);
CREATE INDEX idx_posts_published_at ON cms.posts(published_at DESC);
CREATE INDEX idx_posts_post_type ON cms.posts(post_type);
CREATE INDEX idx_posts_is_featured ON cms.posts(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_posts_is_sticky ON cms.posts(is_sticky) WHERE is_sticky = TRUE;

-- Full-text search on posts
CREATE INDEX idx_posts_fulltext ON cms.posts USING gin(
  to_tsvector('english', coalesce(title, '') || ' ' || coalesce(excerpt, '') || ' ' || coalesce(meta_description, ''))
);

COMMENT ON TABLE cms.posts IS 'Blog posts, articles, news - sistema di contenuti pubblicabili';
COMMENT ON COLUMN cms.posts.is_sticky IS 'Post fissato in cima alla lista';

-- ============================================================================
-- POST REVISIONS (Version control for posts)
-- ============================================================================
CREATE TABLE cms.post_revisions (
  revision_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES cms.posts(post_id) ON DELETE CASCADE,
  version_number INT NOT NULL,

  -- Snapshot
  title TEXT NOT NULL,
  excerpt TEXT,
  content JSONB NOT NULL,
  meta_data JSONB,

  -- Changes
  changes_summary TEXT,

  -- Author
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(post_id, version_number)
);

CREATE INDEX idx_post_revisions_post_id ON cms.post_revisions(post_id);
CREATE INDEX idx_post_revisions_version ON cms.post_revisions(post_id, version_number DESC);

-- ============================================================================
-- SEO & META MANAGEMENT
-- Centralizzato per pages e posts
-- ============================================================================
CREATE TABLE cms.seo_meta (
  seo_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL, -- page_id o post_id
  content_type TEXT NOT NULL, -- 'page' o 'post'

  -- Basic SEO
  meta_title TEXT,
  meta_description TEXT,
  meta_keywords TEXT[],
  canonical_url TEXT,
  robots TEXT DEFAULT 'index,follow', -- noindex, nofollow, etc.

  -- Open Graph
  og_title TEXT,
  og_description TEXT,
  og_image TEXT,
  og_type TEXT DEFAULT 'website',

  -- Twitter Card
  twitter_card TEXT DEFAULT 'summary_large_image',
  twitter_title TEXT,
  twitter_description TEXT,
  twitter_image TEXT,
  twitter_creator TEXT,

  -- Structured Data (Schema.org)
  structured_data JSONB, -- JSON-LD format

  -- Advanced
  custom_meta_tags JSONB, -- Array of {name, content} or {property, content}

  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(content_id, content_type)
);

CREATE INDEX idx_seo_meta_content ON cms.seo_meta(content_id, content_type);

COMMENT ON TABLE cms.seo_meta IS 'Centralizzato SEO meta tags per pages e posts';

-- ============================================================================
-- URL REDIRECTS
-- Gestione redirect per cambio URL, SEO, etc.
-- ============================================================================
CREATE TABLE cms.redirects (
  redirect_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID REFERENCES cms.sites(site_id) ON DELETE CASCADE,

  -- Redirect Configuration
  source_path TEXT NOT NULL, -- '/old-page' o '/blog/old-post'
  target_path TEXT NOT NULL, -- '/new-page' o 'https://external.com/page'
  redirect_type TEXT NOT NULL DEFAULT '301' CHECK (redirect_type IN ('301', '302', '307', '308')),

  -- Matching Rules
  match_type TEXT NOT NULL DEFAULT 'exact' CHECK (match_type IN ('exact', 'prefix', 'regex')),
  is_case_sensitive BOOLEAN DEFAULT FALSE,

  -- Query String Handling
  preserve_query_string BOOLEAN DEFAULT TRUE,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  hit_count INT DEFAULT 0, -- Numero di volte che è stato usato

  -- Audit
  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_hit_at TIMESTAMPTZ,

  -- Constraint: unique source per site
  UNIQUE(site_id, source_path)
);

CREATE INDEX idx_redirects_site_id ON cms.redirects(site_id);
CREATE INDEX idx_redirects_source_path ON cms.redirects(source_path);
CREATE INDEX idx_redirects_is_active ON cms.redirects(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_redirects_hit_count ON cms.redirects(hit_count DESC);

COMMENT ON TABLE cms.redirects IS 'URL redirects per SEO e gestione cambio URL';

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Update updated_at timestamp
CREATE TRIGGER update_sites_updated_at BEFORE UPDATE ON cms.sites
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

CREATE TRIGGER update_site_domains_updated_at BEFORE UPDATE ON cms.site_domains
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

CREATE TRIGGER update_taxonomies_updated_at BEFORE UPDATE ON cms.taxonomies
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

CREATE TRIGGER update_terms_updated_at BEFORE UPDATE ON cms.terms
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON cms.posts
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

CREATE TRIGGER update_seo_meta_updated_at BEFORE UPDATE ON cms.seo_meta
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

CREATE TRIGGER update_redirects_updated_at BEFORE UPDATE ON cms.redirects
  FOR EACH ROW EXECUTE FUNCTION cms.update_updated_at_column();

-- Auto-create revision on post update
CREATE OR REPLACE FUNCTION cms.create_post_revision()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.content IS DISTINCT FROM NEW.content THEN
    INSERT INTO cms.post_revisions (
      post_id,
      version_number,
      title,
      excerpt,
      content,
      meta_data,
      changes_summary,
      created_by
    ) VALUES (
      NEW.post_id,
      COALESCE((SELECT MAX(version_number) + 1 FROM cms.post_revisions WHERE post_id = NEW.post_id), 1),
      OLD.title,
      OLD.excerpt,
      OLD.content,
      OLD.meta_data,
      'Auto-saved revision before update',
      NEW.updated_by
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_post_revision_trigger BEFORE UPDATE ON cms.posts
  FOR EACH ROW EXECUTE FUNCTION cms.create_post_revision();

-- Update term usage count
CREATE OR REPLACE FUNCTION cms.update_term_usage_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE cms.terms SET usage_count = usage_count + 1 WHERE term_id = NEW.term_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE cms.terms SET usage_count = usage_count - 1 WHERE term_id = OLD.term_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_term_usage_count_trigger
  AFTER INSERT OR DELETE ON cms.content_terms
  FOR EACH ROW EXECUTE FUNCTION cms.update_term_usage_count();

-- Update redirect hit count and last_hit_at
CREATE OR REPLACE FUNCTION cms.log_redirect_hit(p_redirect_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE cms.redirects
  SET
    hit_count = hit_count + 1,
    last_hit_at = NOW()
  WHERE redirect_id = p_redirect_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEED DATA - System Taxonomies
-- ============================================================================

-- Category taxonomy (hierarchical)
INSERT INTO cms.taxonomies (slug, name, description, taxonomy_type, is_system, applicable_to) VALUES
('category', 'Categories', 'Hierarchical content categories', 'hierarchical', TRUE, ARRAY['page', 'post']),
('tag', 'Tags', 'Flat content tags', 'flat', TRUE, ARRAY['page', 'post', 'media']),
('post_format', 'Post Formats', 'Post format types', 'flat', TRUE, ARRAY['post']);

-- Default categories
WITH cat_taxonomy AS (
  SELECT taxonomy_id FROM cms.taxonomies WHERE slug = 'category'
)
INSERT INTO cms.terms (taxonomy_id, slug, name, description)
SELECT taxonomy_id, 'uncategorized', 'Uncategorized', 'Default category' FROM cat_taxonomy
UNION ALL
SELECT taxonomy_id, 'news', 'News', 'News and announcements' FROM cat_taxonomy
UNION ALL
SELECT taxonomy_id, 'blog', 'Blog', 'Blog posts' FROM cat_taxonomy
UNION ALL
SELECT taxonomy_id, 'tutorials', 'Tutorials', 'How-to guides and tutorials' FROM cat_taxonomy;

-- ============================================================================
-- GRANTS
-- ============================================================================
GRANT ALL ON ALL TABLES IN SCHEMA cms TO ewh;
GRANT ALL ON ALL SEQUENCES IN SCHEMA cms TO ewh;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA cms TO ewh;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON SCHEMA cms IS 'Enterprise CMS with multi-site, taxonomy, and post management';
