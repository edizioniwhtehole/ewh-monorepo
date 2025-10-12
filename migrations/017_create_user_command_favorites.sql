-- Migration: Create user command favorites table
-- This allows users to mark commands as favorites with custom ordering

CREATE TABLE IF NOT EXISTS plugins.user_command_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  command_id TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, command_id)
);

CREATE INDEX idx_user_command_favorites_user ON plugins.user_command_favorites(user_id);

-- Add widget preferences table for storing UI state
CREATE TABLE IF NOT EXISTS plugins.user_widget_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  widget_id TEXT NOT NULL,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, widget_id)
);

CREATE INDEX idx_user_widget_preferences_user ON plugins.user_widget_preferences(user_id);

-- Insert default favorites for demo (using 'default' as user_id for now)
INSERT INTO plugins.user_command_favorites (user_id, command_id, display_order) VALUES
  ('00000000-0000-0000-0000-000000000000', 'git-status', 1),
  ('00000000-0000-0000-0000-000000000000', 'git-commit', 2),
  ('00000000-0000-0000-0000-000000000000', 'git-push', 3),
  ('00000000-0000-0000-0000-000000000000', 'docker-ps', 4),
  ('00000000-0000-0000-0000-000000000000', 'ewh-start-full', 5),
  ('00000000-0000-0000-0000-000000000000', 'ewh-status', 6),
  ('00000000-0000-0000-0000-000000000000', 'ewh-stop', 7)
ON CONFLICT (user_id, command_id) DO NOTHING;

-- Insert default widget preferences for command matrix
INSERT INTO plugins.user_widget_preferences (user_id, widget_id, preferences) VALUES
  ('00000000-0000-0000-0000-000000000000', 'command-matrix-widget', '{"favoritesHeight": "h-32", "columns": 2}')
ON CONFLICT (user_id, widget_id) DO UPDATE SET preferences = EXCLUDED.preferences;

COMMENT ON TABLE plugins.user_command_favorites IS 'User-specific command favorites for the terminal';
COMMENT ON TABLE plugins.user_widget_preferences IS 'User preferences for widget UI configuration';
