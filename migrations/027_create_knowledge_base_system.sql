-- Knowledge Base System Migration
-- Context-aware help and documentation

CREATE SCHEMA IF NOT EXISTS kb;

-- KB Articles
CREATE TABLE kb.articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  content TEXT NOT NULL,

  -- Categorization
  category VARCHAR(100),
  tags TEXT[],

  -- Context binding
  page_path VARCHAR(500), -- Which page this article is for
  element_id VARCHAR(255), -- Specific element on page

  -- i18n support
  language_code VARCHAR(10) REFERENCES i18n.languages(code) DEFAULT 'en',

  -- Metadata
  published BOOLEAN DEFAULT FALSE,
  view_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  not_helpful_count INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX idx_kb_articles_category ON kb.articles(category);
CREATE INDEX idx_kb_articles_page_path ON kb.articles(page_path);
CREATE INDEX idx_kb_articles_language ON kb.articles(language_code);
CREATE INDEX idx_kb_articles_published ON kb.articles(published);

-- KB Article Versions
CREATE TABLE kb.article_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID REFERENCES kb.articles(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX idx_kb_versions_article ON kb.article_versions(article_id);

-- KB Article Feedback
CREATE TABLE kb.article_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  article_id UUID REFERENCES kb.articles(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  helpful BOOLEAN NOT NULL,
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_kb_feedback_article ON kb.article_feedback(article_id);

-- Infoboxes (contextual help hints)
CREATE TABLE kb.infoboxes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  element_id VARCHAR(255) NOT NULL, -- Button, field, etc.
  page_path VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  position VARCHAR(20) DEFAULT 'right', -- 'top' | 'right' | 'bottom' | 'left'
  language_code VARCHAR(10) REFERENCES i18n.languages(code) DEFAULT 'en',
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_infoboxes_element ON kb.infoboxes(element_id, page_path);
CREATE INDEX idx_infoboxes_language ON kb.infoboxes(language_code);

-- Function to get articles for a page
CREATE OR REPLACE FUNCTION kb.get_page_articles(
  p_page_path VARCHAR(500),
  p_language_code VARCHAR(10) DEFAULT 'en'
)
RETURNS TABLE(
  id UUID,
  title VARCHAR,
  content TEXT,
  category VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.title,
    a.content,
    a.category
  FROM kb.articles a
  WHERE a.page_path = p_page_path
    AND a.language_code = p_language_code
    AND a.published = TRUE
  ORDER BY a.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get infoboxes for a page
CREATE OR REPLACE FUNCTION kb.get_page_infoboxes(
  p_page_path VARCHAR(500),
  p_language_code VARCHAR(10) DEFAULT 'en'
)
RETURNS TABLE(
  element_id VARCHAR,
  content TEXT,
  position VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    i.element_id,
    i.content,
    i.position
  FROM kb.infoboxes i
  WHERE i.page_path = p_page_path
    AND i.language_code = p_language_code
    AND i.active = TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE kb.articles IS 'Knowledge base articles with context binding';
COMMENT ON TABLE kb.infoboxes IS 'Contextual help tooltips';
