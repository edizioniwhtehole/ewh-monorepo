-- i18n System Migration
-- Multi-language translation system

CREATE SCHEMA IF NOT EXISTS i18n;

-- Languages
CREATE TABLE i18n.languages (
  code VARCHAR(10) PRIMARY KEY, -- 'en', 'it', 'es', etc.
  name VARCHAR(100) NOT NULL,
  native_name VARCHAR(100) NOT NULL,
  rtl BOOLEAN DEFAULT FALSE,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default languages
INSERT INTO i18n.languages (code, name, native_name) VALUES
('en', 'English', 'English'),
('it', 'Italian', 'Italiano'),
('es', 'Spanish', 'Español'),
('fr', 'French', 'Français'),
('de', 'German', 'Deutsch');

-- Translation namespaces
CREATE TABLE i18n.namespaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace VARCHAR(100) UNIQUE NOT NULL, -- 'common', 'admin', 'errors', etc.
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default namespaces
INSERT INTO i18n.namespaces (namespace, description) VALUES
('common', 'Common translations'),
('admin', 'Admin panel translations'),
('errors', 'Error messages'),
('validation', 'Form validation messages'),
('emails', 'Email templates');

-- Translation keys
CREATE TABLE i18n.translation_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  namespace_id UUID REFERENCES i18n.namespaces(id),
  key VARCHAR(255) NOT NULL,
  description TEXT,
  context TEXT, -- Additional context for translators
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(namespace_id, key)
);

CREATE INDEX idx_translation_keys_namespace ON i18n.translation_keys(namespace_id);

-- Translations
CREATE TABLE i18n.translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  translation_key_id UUID REFERENCES i18n.translation_keys(id) ON DELETE CASCADE,
  language_code VARCHAR(10) REFERENCES i18n.languages(code),
  translation TEXT NOT NULL,

  -- Metadata
  translated_by UUID REFERENCES auth.users(id),
  translated_at TIMESTAMPTZ DEFAULT NOW(),
  verified BOOLEAN DEFAULT FALSE,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMPTZ,

  UNIQUE(translation_key_id, language_code)
);

CREATE INDEX idx_translations_key ON i18n.translations(translation_key_id);
CREATE INDEX idx_translations_language ON i18n.translations(language_code);

-- Translation exports (for import/export)
CREATE TABLE i18n.translation_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  language_code VARCHAR(10) REFERENCES i18n.languages(code),
  namespace_id UUID REFERENCES i18n.namespaces(id),
  format VARCHAR(20) NOT NULL, -- 'json' | 'csv' | 'po' | 'xliff'
  content TEXT NOT NULL,
  exported_by UUID REFERENCES auth.users(id),
  exported_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to get all translations for a language
CREATE OR REPLACE FUNCTION i18n.get_translations(p_language_code VARCHAR(10), p_namespace VARCHAR(100) DEFAULT NULL)
RETURNS TABLE(key VARCHAR, translation TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    tk.key,
    COALESCE(t.translation, tk.key) as translation
  FROM i18n.translation_keys tk
  JOIN i18n.namespaces ns ON tk.namespace_id = ns.id
  LEFT JOIN i18n.translations t ON t.translation_key_id = tk.id AND t.language_code = p_language_code
  WHERE p_namespace IS NULL OR ns.namespace = p_namespace;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE i18n.languages IS 'Supported languages';
COMMENT ON TABLE i18n.translation_keys IS 'Translation keys with context';
COMMENT ON TABLE i18n.translations IS 'Actual translations per language';
