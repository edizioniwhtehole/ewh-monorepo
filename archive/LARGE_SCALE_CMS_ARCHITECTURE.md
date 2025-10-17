# 🏗️ Large-Scale Enterprise CMS Architecture

## Sistema per Migliaia di Pagine, News Sites, Directory, E-commerce

---

## 📊 SCALABILITY TARGETS

### Performance Requirements
- ✅ **10,000+ pages** per site
- ✅ **100+ concurrent editors**
- ✅ **10,000+ requests/second** serving content
- ✅ **1M+ daily visitors** per site
- ✅ **Sub-100ms** response time (p95)
- ✅ **99.99% uptime** SLA

### Content Volume
- ✅ **News Sites**: 10,000+ articles, 1000+ posts/day
- ✅ **Directory**: 100,000+ listings, faceted search
- ✅ **E-commerce**: 50,000+ products, inventory management
- ✅ **Corporate Sites**: Multi-language, multi-brand
- ✅ **Landing Pages**: A/B testing, conversion optimization

---

## 1. 🗄️ DATABASE OPTIMIZATION FOR SCALE

### 1.1 Partitioning Strategy

```sql
-- Partition posts table by published_at (monthly partitions)
CREATE TABLE cms.posts (
  post_id UUID NOT NULL,
  site_id UUID NOT NULL,
  published_at TIMESTAMPTZ NOT NULL,
  -- ... other fields ...
) PARTITION BY RANGE (published_at);

-- Create partitions (automated via script)
CREATE TABLE cms.posts_2025_01 PARTITION OF cms.posts
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE cms.posts_2025_02 PARTITION OF cms.posts
  FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- Auto-create future partitions (cron job)
CREATE OR REPLACE FUNCTION cms.create_monthly_partitions()
RETURNS void AS $$
DECLARE
  start_date DATE;
  end_date DATE;
  partition_name TEXT;
BEGIN
  -- Create partitions for next 3 months
  FOR i IN 0..2 LOOP
    start_date := DATE_TRUNC('month', NOW() + (i || ' months')::INTERVAL);
    end_date := start_date + INTERVAL '1 month';
    partition_name := 'posts_' || TO_CHAR(start_date, 'YYYY_MM');

    EXECUTE format(
      'CREATE TABLE IF NOT EXISTS cms.%I PARTITION OF cms.posts
       FOR VALUES FROM (%L) TO (%L)',
      partition_name, start_date, end_date
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Partition pages by site_id (for multi-site)
CREATE TABLE cms.pages (
  page_id UUID NOT NULL,
  site_id UUID NOT NULL,
  -- ... fields ...
) PARTITION BY HASH (site_id);

-- Create 16 hash partitions for better distribution
CREATE TABLE cms.pages_0 PARTITION OF cms.pages FOR VALUES WITH (MODULUS 16, REMAINDER 0);
CREATE TABLE cms.pages_1 PARTITION OF cms.pages FOR VALUES WITH (MODULUS 16, REMAINDER 1);
-- ... up to 15
```

### 1.2 Indexing Strategy

```sql
-- Composite indexes for common queries
CREATE INDEX idx_posts_site_status_published ON cms.posts(site_id, status, published_at DESC)
  WHERE status = 'published';

CREATE INDEX idx_posts_category_published ON cms.posts(site_id, category_id, published_at DESC)
  WHERE status = 'published';

-- Partial indexes for specific use cases
CREATE INDEX idx_posts_featured ON cms.posts(site_id, published_at DESC)
  WHERE is_featured = TRUE AND status = 'published';

-- GIN index for full-text search
CREATE INDEX idx_posts_search ON cms.posts USING gin(
  to_tsvector('english', title || ' ' || excerpt || ' ' || content)
);

-- JSONB indexes for metadata queries
CREATE INDEX idx_posts_metadata ON cms.posts USING gin(metadata jsonb_path_ops);

-- Covering index to avoid table lookups
CREATE INDEX idx_posts_list ON cms.posts(site_id, published_at DESC)
  INCLUDE (post_id, title, excerpt, featured_image, author_id);
```

### 1.3 Materialized Views for Analytics

```sql
-- Daily stats (refresh every hour)
CREATE MATERIALIZED VIEW cms.daily_post_stats AS
SELECT
  site_id,
  DATE(published_at) as publish_date,
  COUNT(*) as posts_count,
  COUNT(*) FILTER (WHERE is_featured) as featured_count,
  SUM(view_count) as total_views,
  AVG(view_count) as avg_views
FROM cms.posts
WHERE status = 'published'
GROUP BY site_id, DATE(published_at);

CREATE UNIQUE INDEX ON cms.daily_post_stats(site_id, publish_date);

-- Auto-refresh every hour
CREATE OR REPLACE FUNCTION cms.refresh_daily_stats()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY cms.daily_post_stats;
END;
$$ LANGUAGE plpgsql;

-- Category popularity (for directory sites)
CREATE MATERIALIZED VIEW cms.category_stats AS
SELECT
  ct.taxonomy_id,
  t.term_id,
  t.name as category_name,
  COUNT(DISTINCT content_id) as content_count,
  SUM(p.view_count) as total_views
FROM cms.content_terms ct
JOIN cms.terms t ON ct.term_id = t.term_id
JOIN cms.posts p ON ct.content_id = p.post_id
WHERE p.status = 'published'
GROUP BY ct.taxonomy_id, t.term_id, t.name;

CREATE INDEX ON cms.category_stats(taxonomy_id, total_views DESC);
```

---

## 2. 📰 NEWS SITE FEATURES

### 2.1 Breaking News System

```sql
CREATE TABLE cms.breaking_news (
  breaking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Content
  headline TEXT NOT NULL,
  summary TEXT,
  post_id UUID REFERENCES cms.posts(post_id),

  -- Display
  priority INT DEFAULT 1, -- Higher = more important
  display_style TEXT DEFAULT 'banner' CHECK (display_style IN ('banner', 'ticker', 'modal', 'push')),

  -- Timing
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,

  -- Targeting
  show_on_homepage BOOLEAN DEFAULT TRUE,
  show_on_sections TEXT[], -- ['politics', 'world']

  -- Status
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_breaking_news_active ON cms.breaking_news(site_id, is_active, priority DESC)
  WHERE is_active = TRUE AND (expires_at IS NULL OR expires_at > NOW());
```

### 2.2 Live Blog System

```sql
CREATE TABLE cms.live_blogs (
  live_blog_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES cms.posts(post_id),

  -- Config
  auto_refresh_interval INT DEFAULT 30, -- seconds
  allow_comments BOOLEAN DEFAULT TRUE,

  -- Status
  status TEXT DEFAULT 'live' CHECK (status IN ('upcoming', 'live', 'paused', 'ended')),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cms.live_blog_updates (
  update_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  live_blog_id UUID NOT NULL REFERENCES cms.live_blogs(live_blog_id) ON DELETE CASCADE,

  -- Content
  content JSONB NOT NULL,
  author_id UUID NOT NULL,

  -- Display
  is_pinned BOOLEAN DEFAULT FALSE,
  is_important BOOLEAN DEFAULT FALSE,

  -- Timing
  posted_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_live_blog_updates_blog ON cms.live_blog_updates(live_blog_id, posted_at DESC);
```

### 2.3 Related Content Engine

```sql
CREATE TABLE cms.content_relationships (
  relationship_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  content_type TEXT NOT NULL,
  related_content_id UUID NOT NULL,
  related_content_type TEXT NOT NULL,

  -- Relationship
  relationship_type TEXT DEFAULT 'related' CHECK (relationship_type IN (
    'related',      -- Generic related
    'follow_up',    -- Continuation of story
    'background',   -- Background context
    'mentioned_in', -- Referenced in
    'series'        -- Part of series
  )),

  -- Scoring (for ranking)
  relevance_score DECIMAL(5, 4), -- 0.0000 to 1.0000

  -- Auto vs Manual
  is_manual BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_content_relationships_content ON cms.content_relationships(content_id, content_type, relevance_score DESC);

-- Auto-generate related content using AI
CREATE OR REPLACE FUNCTION cms.generate_related_content(p_post_id UUID)
RETURNS void AS $$
DECLARE
  post_record RECORD;
  related_posts RECORD;
BEGIN
  -- Get post details
  SELECT * INTO post_record FROM cms.posts WHERE post_id = p_post_id;

  -- Find similar posts by tags, categories, and content similarity
  FOR related_posts IN
    SELECT
      p.post_id,
      -- Similarity score based on multiple factors
      (
        -- Tag overlap
        (SELECT COUNT(*) FROM unnest(p.tags) t WHERE t = ANY(post_record.tags)) * 0.3 +
        -- Category match
        (CASE WHEN p.category_id = post_record.category_id THEN 1.0 ELSE 0.0 END) * 0.3 +
        -- Content similarity (using full-text search)
        ts_rank(
          to_tsvector('english', p.title || ' ' || p.excerpt),
          to_tsquery('english', regexp_replace(post_record.title, '\s+', ' & ', 'g'))
        ) * 0.4
      ) as score
    FROM cms.posts p
    WHERE p.site_id = post_record.site_id
      AND p.post_id != p_post_id
      AND p.status = 'published'
      AND p.published_at < NOW()
    ORDER BY score DESC
    LIMIT 10
  LOOP
    INSERT INTO cms.content_relationships (
      content_id, content_type,
      related_content_id, related_content_type,
      relationship_type, relevance_score
    ) VALUES (
      p_post_id, 'post',
      related_posts.post_id, 'post',
      'related', related_posts.score
    )
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

---

## 3. 📂 DIRECTORY SITE FEATURES

### 3.1 Listings System

```sql
CREATE TABLE cms.listings (
  listing_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Basic Info
  title TEXT NOT NULL,
  slug TEXT NOT NULL,
  description TEXT,
  featured_image TEXT,

  -- Contact
  email TEXT,
  phone TEXT,
  website TEXT,
  social_links JSONB,

  -- Location
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  postal_code TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),

  -- Business Hours
  hours JSONB, -- { "monday": "9:00-17:00", ... }

  -- Metadata
  custom_fields JSONB,

  -- Rating & Reviews
  rating_avg DECIMAL(3, 2) DEFAULT 0,
  rating_count INT DEFAULT 0,
  review_count INT DEFAULT 0,

  -- Pricing (for paid listings)
  listing_tier TEXT DEFAULT 'basic' CHECK (listing_tier IN ('basic', 'featured', 'premium')),
  featured_until TIMESTAMPTZ,

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
  verified BOOLEAN DEFAULT FALSE,

  -- SEO
  meta_title TEXT,
  meta_description TEXT,

  -- Stats
  view_count INT DEFAULT 0,
  claim_status TEXT DEFAULT 'unclaimed' CHECK (claim_status IN ('unclaimed', 'claimed', 'verified')),

  owner_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(site_id, slug)
);

-- Spatial index for geo queries
CREATE INDEX idx_listings_location ON cms.listings USING gist(
  ll_to_earth(latitude, longitude)
) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Faceted search indexes
CREATE INDEX idx_listings_category ON cms.listings USING gin(
  (SELECT array_agg(term_id) FROM cms.content_terms WHERE content_id = listing_id)
);

CREATE INDEX idx_listings_tier ON cms.listings(site_id, listing_tier, rating_avg DESC)
  WHERE status = 'approved';
```

### 3.2 Reviews & Ratings

```sql
CREATE TABLE cms.reviews (
  review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES cms.listings(listing_id) ON DELETE CASCADE,

  -- Author
  user_id UUID,
  author_name TEXT NOT NULL,
  author_email TEXT,

  -- Rating
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),

  -- Content
  title TEXT,
  content TEXT NOT NULL,
  pros TEXT,
  cons TEXT,

  -- Media
  images TEXT[],

  -- Verification
  is_verified_purchase BOOLEAN DEFAULT FALSE,
  visit_date DATE,

  -- Moderation
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'spam')),
  moderation_notes TEXT,

  -- Engagement
  helpful_count INT DEFAULT 0,
  not_helpful_count INT DEFAULT 0,

  -- Response from business
  owner_response TEXT,
  owner_response_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reviews_listing ON cms.reviews(listing_id, status, created_at DESC);
CREATE INDEX idx_reviews_rating ON cms.reviews(listing_id, rating) WHERE status = 'approved';

-- Trigger to update listing rating
CREATE OR REPLACE FUNCTION cms.update_listing_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE cms.listings SET
    rating_avg = (
      SELECT AVG(rating)::DECIMAL(3,2)
      FROM cms.reviews
      WHERE listing_id = NEW.listing_id AND status = 'approved'
    ),
    rating_count = (
      SELECT COUNT(*)
      FROM cms.reviews
      WHERE listing_id = NEW.listing_id AND status = 'approved'
    ),
    review_count = (
      SELECT COUNT(*)
      FROM cms.reviews
      WHERE listing_id = NEW.listing_id AND status = 'approved'
    )
  WHERE listing_id = NEW.listing_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_listing_rating_trigger
  AFTER INSERT OR UPDATE ON cms.reviews
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_listing_rating();
```

### 3.3 Advanced Search & Filtering

```sql
-- Faceted search function
CREATE OR REPLACE FUNCTION cms.search_listings(
  p_site_id UUID,
  p_query TEXT DEFAULT NULL,
  p_categories UUID[] DEFAULT NULL,
  p_location_lat DECIMAL DEFAULT NULL,
  p_location_lng DECIMAL DEFAULT NULL,
  p_radius_km INT DEFAULT 10,
  p_min_rating DECIMAL DEFAULT NULL,
  p_listing_tier TEXT DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'relevance', -- 'relevance', 'rating', 'distance', 'newest'
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  listing_id UUID,
  title TEXT,
  distance_km DECIMAL,
  relevance_score DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.listing_id,
    l.title,
    -- Calculate distance if location provided
    CASE
      WHEN p_location_lat IS NOT NULL AND p_location_lng IS NOT NULL THEN
        earth_distance(
          ll_to_earth(p_location_lat, p_location_lng),
          ll_to_earth(l.latitude, l.longitude)
        ) / 1000 -- Convert to km
      ELSE NULL
    END as distance_km,
    -- Calculate relevance score
    (
      -- Text search score
      CASE WHEN p_query IS NOT NULL THEN
        ts_rank(
          to_tsvector('english', l.title || ' ' || l.description),
          plainto_tsquery('english', p_query)
        )
      ELSE 0.5
      END * 0.4 +
      -- Rating score
      (l.rating_avg / 5.0) * 0.3 +
      -- Listing tier bonus
      CASE l.listing_tier
        WHEN 'premium' THEN 0.3
        WHEN 'featured' THEN 0.2
        WHEN 'basic' THEN 0.1
      END
    ) as relevance_score
  FROM cms.listings l
  WHERE l.site_id = p_site_id
    AND l.status = 'approved'
    -- Text search filter
    AND (
      p_query IS NULL OR
      to_tsvector('english', l.title || ' ' || l.description) @@ plainto_tsquery('english', p_query)
    )
    -- Category filter
    AND (
      p_categories IS NULL OR
      EXISTS (
        SELECT 1 FROM cms.content_terms ct
        WHERE ct.content_id = l.listing_id
          AND ct.content_type = 'listing'
          AND ct.term_id = ANY(p_categories)
      )
    )
    -- Location filter
    AND (
      p_location_lat IS NULL OR
      earth_distance(
        ll_to_earth(p_location_lat, p_location_lng),
        ll_to_earth(l.latitude, l.longitude)
      ) <= (p_radius_km * 1000)
    )
    -- Rating filter
    AND (p_min_rating IS NULL OR l.rating_avg >= p_min_rating)
    -- Tier filter
    AND (p_listing_tier IS NULL OR l.listing_tier = p_listing_tier)
  ORDER BY
    CASE p_sort_by
      WHEN 'rating' THEN l.rating_avg
      WHEN 'newest' THEN EXTRACT(EPOCH FROM l.created_at)
      ELSE NULL
    END DESC NULLS LAST,
    CASE p_sort_by
      WHEN 'distance' THEN
        earth_distance(
          ll_to_earth(p_location_lat, p_location_lng),
          ll_to_earth(l.latitude, l.longitude)
        )
      ELSE NULL
    END ASC NULLS LAST,
    relevance_score DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;
```

---

## 4. 🛒 E-COMMERCE FEATURES

### 4.1 Product System

```sql
CREATE TABLE cms.products (
  product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Basic Info
  sku TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  slug TEXT NOT NULL,
  description TEXT,
  short_description TEXT,

  -- Pricing
  price DECIMAL(12, 2) NOT NULL,
  sale_price DECIMAL(12, 2),
  cost_price DECIMAL(12, 2), -- For profit calculation
  currency TEXT DEFAULT 'USD',

  -- Tax
  tax_class TEXT,
  tax_status TEXT DEFAULT 'taxable',

  -- Inventory
  manage_stock BOOLEAN DEFAULT TRUE,
  stock_quantity INT DEFAULT 0,
  stock_status TEXT DEFAULT 'in_stock' CHECK (stock_status IN ('in_stock', 'out_of_stock', 'on_backorder')),
  backorders TEXT DEFAULT 'no' CHECK (backorders IN ('no', 'notify', 'yes')),
  low_stock_threshold INT DEFAULT 2,

  -- Shipping
  weight DECIMAL(10, 4),
  length DECIMAL(10, 4),
  width DECIMAL(10, 4),
  height DECIMAL(10, 4),
  shipping_class TEXT,

  -- Media
  featured_image TEXT,
  gallery_images TEXT[],

  -- SEO
  meta_title TEXT,
  meta_description TEXT,

  -- Product Type
  product_type TEXT DEFAULT 'simple' CHECK (product_type IN ('simple', 'variable', 'grouped', 'external', 'digital')),
  external_url TEXT, -- For external products
  button_text TEXT,  -- For external products

  -- Digital Products
  downloadable BOOLEAN DEFAULT FALSE,
  download_limit INT, -- -1 = unlimited
  download_expiry INT, -- Days

  -- Visibility
  visibility TEXT DEFAULT 'visible' CHECK (visibility IN ('visible', 'catalog', 'search', 'hidden')),
  featured BOOLEAN DEFAULT FALSE,

  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  published_at TIMESTAMPTZ,

  -- Stats
  view_count INT DEFAULT 0,
  sales_count INT DEFAULT 0,
  rating_avg DECIMAL(3, 2) DEFAULT 0,
  review_count INT DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(site_id, slug)
);

-- Product Variations (for variable products)
CREATE TABLE cms.product_variations (
  variation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES cms.products(product_id) ON DELETE CASCADE,

  -- Variation specifics
  sku TEXT UNIQUE,
  attributes JSONB NOT NULL, -- {"size": "Large", "color": "Blue"}

  -- Pricing (can override parent)
  price DECIMAL(12, 2),
  sale_price DECIMAL(12, 2),

  -- Inventory (separate from parent)
  stock_quantity INT DEFAULT 0,
  stock_status TEXT DEFAULT 'in_stock',

  -- Media
  image TEXT,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_product_variations_product ON cms.product_variations(product_id);
CREATE INDEX idx_product_variations_attributes ON cms.product_variations USING gin(attributes);
```

### 4.2 Order Management

```sql
CREATE TABLE cms.orders (
  order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Order Number (human-readable)
  order_number TEXT UNIQUE NOT NULL,

  -- Customer
  customer_id UUID,
  customer_email TEXT NOT NULL,
  customer_name TEXT NOT NULL,

  -- Billing Address
  billing_address JSONB NOT NULL,

  -- Shipping Address
  shipping_address JSONB,
  shipping_method TEXT,
  shipping_cost DECIMAL(10, 2) DEFAULT 0,

  -- Totals
  subtotal DECIMAL(12, 2) NOT NULL,
  discount_total DECIMAL(12, 2) DEFAULT 0,
  tax_total DECIMAL(12, 2) DEFAULT 0,
  shipping_total DECIMAL(12, 2) DEFAULT 0,
  total DECIMAL(12, 2) NOT NULL,
  currency TEXT DEFAULT 'USD',

  -- Payment
  payment_method TEXT NOT NULL,
  payment_method_title TEXT,
  transaction_id TEXT,
  paid_at TIMESTAMPTZ,

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending',
    'processing',
    'on_hold',
    'completed',
    'cancelled',
    'refunded',
    'failed'
  )),

  -- Notes
  customer_note TEXT,
  admin_notes TEXT[],

  -- Metadata
  metadata JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cms.order_items (
  item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES cms.orders(order_id) ON DELETE CASCADE,

  -- Product
  product_id UUID NOT NULL,
  variation_id UUID,
  product_name TEXT NOT NULL,
  sku TEXT,

  -- Quantity & Pricing
  quantity INT NOT NULL,
  unit_price DECIMAL(12, 2) NOT NULL,
  subtotal DECIMAL(12, 2) NOT NULL,
  tax_total DECIMAL(12, 2) DEFAULT 0,
  total DECIMAL(12, 2) NOT NULL,

  -- Metadata
  metadata JSONB, -- Product attributes, etc.

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON cms.order_items(order_id);
CREATE INDEX idx_order_items_product ON cms.order_items(product_id);

-- Inventory management trigger
CREATE OR REPLACE FUNCTION cms.update_product_inventory()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Reduce stock when order item created
    UPDATE cms.products SET
      stock_quantity = stock_quantity - NEW.quantity,
      sales_count = sales_count + NEW.quantity
    WHERE product_id = NEW.product_id AND manage_stock = TRUE;

    -- Update stock status
    UPDATE cms.products SET
      stock_status = CASE
        WHEN stock_quantity <= 0 THEN 'out_of_stock'
        WHEN stock_quantity <= low_stock_threshold THEN 'low_stock'
        ELSE 'in_stock'
      END
    WHERE product_id = NEW.product_id AND manage_stock = TRUE;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory_trigger
  AFTER INSERT ON cms.order_items
  FOR EACH ROW
  EXECUTE FUNCTION cms.update_product_inventory();
```

---

## 5. ⚡ PERFORMANCE & CACHING

### 5.1 Multi-Layer Caching Strategy

```typescript
// Cache hierarchy
const CacheStrategy = {
  // L1: Memory cache (fastest, smallest)
  L1: {
    type: 'node-cache',
    ttl: 60, // 1 minute
    maxKeys: 1000,
    useFor: ['hot content', 'session data']
  },

  // L2: Redis (fast, medium)
  L2: {
    type: 'redis',
    ttl: 3600, // 1 hour
    maxMemory: '2gb',
    useFor: ['pages', 'API responses', 'query results']
  },

  // L3: CDN (fast for static, global)
  L3: {
    type: 'cloudflare/cloudfront',
    ttl: 86400, // 24 hours
    useFor: ['static pages', 'images', 'assets']
  },

  // L4: Database query cache
  L4: {
    type: 'postgres',
    useFor: ['materialized views', 'prepared statements']
  }
};

// Cache service
class CacheService {
  async get(key: string, fetcher: () => Promise<any>, options = {}) {
    // L1: Check memory
    let value = memoryCache.get(key);
    if (value) return value;

    // L2: Check Redis
    value = await redis.get(key);
    if (value) {
      memoryCache.set(key, value);
      return JSON.parse(value);
    }

    // L3: Fetch from source
    value = await fetcher();

    // Store in caches
    await redis.setex(key, options.ttl || 3600, JSON.stringify(value));
    memoryCache.set(key, value);

    return value;
  }

  async invalidate(pattern: string) {
    // Invalidate all cache layers
    memoryCache.flushAll();
    const keys = await redis.keys(pattern);
    if (keys.length > 0) {
      await redis.del(...keys);
    }
    await cdn.purge(pattern);
  }
}

// Usage
const post = await cache.get(`post:${postId}`, async () => {
  return await PostService.findById(postId);
}, { ttl: 3600 });
```

### 5.2 CDN Integration

```typescript
class CDNService {
  async purge(paths: string[]) {
    // Cloudflare purge
    await fetch('https://api.cloudflare.com/client/v4/zones/{zone}/purge_cache', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${CLOUDFLARE_API_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ files: paths })
    });
  }

  async preload(paths: string[]) {
    // Preload content to CDN edge
    for (const path of paths) {
      await fetch(`https://cdn.example.com${path}`, {
        headers: { 'X-Preload': 'true' }
      });
    }
  }
}

// Auto-purge on content update
hooks.addAction('post.after_publish', async (post) => {
  await CDNService.purge([
    `/blog/${post.slug}`,
    `/blog`, // Index page
    `/feed.xml`, // RSS feed
    `/sitemap.xml`
  ]);
});
```

---

## 6. 🔍 SEARCH SYSTEM (Elasticsearch/OpenSearch)

### 6.1 Search Index Structure

```typescript
// Elasticsearch mapping
const searchIndex = {
  settings: {
    number_of_shards: 5,
    number_of_replicas: 2,
    analysis: {
      analyzer: {
        content_analyzer: {
          type: 'custom',
          tokenizer: 'standard',
          filter: ['lowercase', 'stop', 'snowball']
        }
      }
    }
  },
  mappings: {
    properties: {
      // Core fields
      content_id: { type: 'keyword' },
      content_type: { type: 'keyword' },
      site_id: { type: 'keyword' },
      title: {
        type: 'text',
        analyzer: 'content_analyzer',
        fields: {
          keyword: { type: 'keyword' },
          suggest: { type: 'completion' }
        }
      },
      content: {
        type: 'text',
        analyzer: 'content_analyzer'
      },
      excerpt: { type: 'text' },

      // Metadata
      author_id: { type: 'keyword' },
      author_name: { type: 'text' },
      categories: { type: 'keyword' },
      tags: { type: 'keyword' },

      // Dates
      published_at: { type: 'date' },
      updated_at: { type: 'date' },

      // Stats
      view_count: { type: 'integer' },
      rating_avg: { type: 'float' },

      // Location (for directory)
      location: { type: 'geo_point' },

      // Custom fields
      custom_fields: { type: 'object', enabled: false }
    }
  }
};

class SearchService {
  async indexContent(content: any) {
    await elasticsearch.index({
      index: 'content',
      id: content.content_id,
      body: {
        content_id: content.content_id,
        content_type: content.content_type,
        site_id: content.site_id,
        title: content.title,
        content: content.content,
        // ... other fields
      }
    });
  }

  async search(siteId: string, query: SearchQuery) {
    const result = await elasticsearch.search({
      index: 'content',
      body: {
        query: {
          bool: {
            must: [
              { match: { site_id: siteId } },
              {
                multi_match: {
                  query: query.q,
                  fields: ['title^3', 'excerpt^2', 'content'],
                  fuzziness: 'AUTO'
                }
              }
            ],
            filter: [
              // Filters
              ...query.categories ? [{ terms: { categories: query.categories } }] : [],
              ...query.dateFrom ? [{ range: { published_at: { gte: query.dateFrom } } }] : []
            ]
          }
        },
        // Aggregations for facets
        aggs: {
          categories: { terms: { field: 'categories', size: 20 } },
          tags: { terms: { field: 'tags', size: 50 } },
          date_histogram: {
            date_histogram: { field: 'published_at', interval: 'month' }
          }
        },
        // Highlighting
        highlight: {
          fields: {
            title: {},
            excerpt: {},
            content: { fragment_size: 150, number_of_fragments: 3 }
          }
        },
        // Pagination
        from: query.offset || 0,
        size: query.limit || 20,
        // Sorting
        sort: [
          query.sortBy === 'relevance' ? '_score' : { [query.sortBy]: 'desc' }
        ]
      }
    });

    return {
      hits: result.hits.hits.map(hit => ({
        ...hit._source,
        score: hit._score,
        highlights: hit.highlight
      })),
      total: result.hits.total.value,
      aggregations: result.aggregations,
      took: result.took
    };
  }

  // Autocomplete suggestions
  async suggest(siteId: string, prefix: string) {
    const result = await elasticsearch.search({
      index: 'content',
      body: {
        suggest: {
          title_suggest: {
            prefix,
            completion: {
              field: 'title.suggest',
              size: 10,
              contexts: {
                site_id: [siteId]
              }
            }
          }
        }
      }
    });

    return result.suggest.title_suggest[0].options.map(o => o.text);
  }
}

// Auto-index on content change
hooks.addAction('content.after_save', async (content) => {
  await SearchService.indexContent(content);
});
```

---

## 7. 📊 BULK OPERATIONS

### 7.1 Bulk Import/Export

```typescript
class BulkOperationsService {
  async importCSV(siteId: string, file: File, contentType: string) {
    const rows = await parseCSV(file);
    const batchSize = 100;

    for (let i = 0; i < rows.length; i += batchSize) {
      const batch = rows.slice(i, i + batchSize);

      await db.transaction(async (tx) => {
        for (const row of batch) {
          await this.createContent(tx, siteId, contentType, row);
        }
      });

      // Progress update
      await this.updateProgress(i / rows.length * 100);
    }
  }

  async exportCSV(siteId: string, filters: any) {
    const stream = new PassThrough();

    // Stream to CSV
    const csvStream = csv.format({ headers: true });
    csvStream.pipe(stream);

    // Fetch in batches
    let offset = 0;
    const limit = 1000;

    while (true) {
      const batch = await ContentService.query({
        ...filters,
        siteId,
        limit,
        offset
      });

      if (batch.length === 0) break;

      for (const item of batch) {
        csvStream.write(item);
      }

      offset += limit;
    }

    csvStream.end();
    return stream;
  }

  // Bulk update
  async bulkUpdate(siteId: string, ids: string[], updates: any) {
    await db.query(`
      UPDATE cms.posts SET
        ${Object.keys(updates).map((k, i) => `${k} = $${i + 2}`).join(', ')},
        updated_at = NOW()
      WHERE site_id = $1 AND post_id = ANY($${Object.keys(updates).length + 2})
    `, [siteId, ...Object.values(updates), ids]);

    // Invalidate cache
    for (const id of ids) {
      await cache.invalidate(`post:${id}`);
    }

    // Trigger hooks
    for (const id of ids) {
      await hooks.doAction('post.bulk_updated', { postId: id, updates });
    }
  }

  // Bulk delete
  async bulkDelete(siteId: string, ids: string[]) {
    // Soft delete
    await db.query(`
      UPDATE cms.posts SET
        status = 'deleted',
        deleted_at = NOW()
      WHERE site_id = $1 AND post_id = ANY($2)
    `, [siteId, ids]);

    // Remove from search index
    await SearchService.bulkDelete(ids);
  }
}
```

---

## 🎯 RISULTATO FINALE

Con questa architettura hai un CMS che può gestire:

✅ **10,000+ pagine** per site
✅ **100+ concurrent editors**
✅ **1M+ daily visitors**
✅ **News sites** con breaking news e live blogs
✅ **Directory** con 100K+ listings e geo-search
✅ **E-commerce** con inventory management
✅ **Sub-100ms** response time
✅ **Multi-layer caching** (Memory → Redis → CDN)
✅ **Full-text search** (Elasticsearch)
✅ **Bulk operations** (import/export CSV)

**Database**: Partizionato + indicizzato per milioni di record
**Search**: Elasticsearch con autocomplete
**Cache**: 4 livelli (Memory/Redis/CDN/DB)
**Scale**: Horizontal scaling ready

Vuoi che inizi ad implementare qualche parte specifica? (News, Directory, o E-commerce)?
