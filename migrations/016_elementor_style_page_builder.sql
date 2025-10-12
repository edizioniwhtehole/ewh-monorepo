-- Migration 016: Elementor-style Page Builder
-- Adds support for sections, columns, and visual elements within widgets

-- Page Sections (containers for columns)
CREATE TABLE IF NOT EXISTS plugins.page_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id VARCHAR(255) NOT NULL,
  section_order INTEGER DEFAULT 0,
  section_type VARCHAR(50) DEFAULT 'full-width', -- full-width, boxed, custom
  background_type VARCHAR(50) DEFAULT 'color', -- color, gradient, image, video
  background_config JSONB DEFAULT '{}'::jsonb,
  padding JSONB DEFAULT '{"top": 20, "right": 20, "bottom": 20, "left": 20}'::jsonb,
  margin JSONB DEFAULT '{"top": 0, "right": 0, "bottom": 0, "left": 0}'::jsonb,
  custom_css TEXT,
  custom_classes VARCHAR(500),
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  FOREIGN KEY (page_id) REFERENCES plugins.page_definitions(page_id) ON DELETE CASCADE
);

CREATE INDEX idx_page_sections_page ON plugins.page_sections(page_id);
CREATE INDEX idx_page_sections_order ON plugins.page_sections(page_id, section_order);

-- Columns within sections
CREATE TABLE IF NOT EXISTS plugins.section_columns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id UUID NOT NULL,
  column_order INTEGER DEFAULT 0,
  column_width INTEGER DEFAULT 12, -- Out of 12 (Bootstrap-style)
  background_config JSONB DEFAULT '{}'::jsonb,
  padding JSONB DEFAULT '{"top": 10, "right": 10, "bottom": 10, "left": 10}'::jsonb,
  vertical_align VARCHAR(20) DEFAULT 'top', -- top, middle, bottom
  custom_css TEXT,
  custom_classes VARCHAR(500),
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  FOREIGN KEY (section_id) REFERENCES plugins.page_sections(id) ON DELETE CASCADE
);

CREATE INDEX idx_section_columns_section ON plugins.section_columns(section_id);
CREATE INDEX idx_section_columns_order ON plugins.section_columns(section_id, column_order);

-- Elements within columns (buttons, text, images, forms, etc.)
CREATE TABLE IF NOT EXISTS plugins.column_elements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  column_id UUID NOT NULL,
  element_order INTEGER DEFAULT 0,
  element_type VARCHAR(100) NOT NULL, -- button, heading, text, image, icon, divider, spacer, form-field, etc.
  element_config JSONB DEFAULT '{}'::jsonb, -- Content, styling, etc.
  actions JSONB DEFAULT '[]'::jsonb, -- Array of {event: 'onClick', action: 'navigate', params: {...}}
  conditions JSONB DEFAULT '{}'::jsonb, -- Visibility conditions
  animations JSONB DEFAULT '{}'::jsonb, -- Entrance/exit animations
  custom_css TEXT,
  custom_classes VARCHAR(500),
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  FOREIGN KEY (column_id) REFERENCES plugins.section_columns(id) ON DELETE CASCADE
);

CREATE INDEX idx_column_elements_column ON plugins.column_elements(column_id);
CREATE INDEX idx_column_elements_order ON plugins.column_elements(column_id, element_order);
CREATE INDEX idx_column_elements_type ON plugins.column_elements(element_type);

-- Element Library (reusable element templates)
CREATE TABLE IF NOT EXISTS plugins.element_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  element_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  element_type VARCHAR(100) NOT NULL,
  category VARCHAR(100), -- content, form, media, layout, advanced
  icon VARCHAR(100),
  preview_image TEXT,
  default_config JSONB DEFAULT '{}'::jsonb,
  available_actions TEXT[], -- Array of available actions for this element
  config_schema JSONB, -- JSON Schema for configuration
  is_system_element BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_element_library_type ON plugins.element_library(element_type);
CREATE INDEX idx_element_library_category ON plugins.element_library(category);

-- Safe Functions Library (approved functions for element actions)
CREATE TABLE IF NOT EXISTS plugins.safe_functions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  function_id VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  function_type VARCHAR(100) NOT NULL, -- api-call, navigation, form-submit, data-transform, etc.
  parameters_schema JSONB, -- JSON Schema for parameters
  implementation TEXT, -- Safe implementation code or API endpoint
  is_async BOOLEAN DEFAULT false,
  requires_auth BOOLEAN DEFAULT false,
  rate_limit INTEGER, -- Calls per minute
  is_system_function BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_safe_functions_type ON plugins.safe_functions(function_type);

-- Insert default element library
INSERT INTO plugins.element_library (element_id, name, description, element_type, category, icon, default_config, available_actions) VALUES
  ('el-heading', 'Heading', 'Heading text (H1-H6)', 'heading', 'content', 'Heading1', '{"content": "Your Heading", "tag": "h2", "color": "#ffffff", "align": "left"}'::jsonb, ARRAY['onClick']),
  ('el-text', 'Text', 'Paragraph text', 'text', 'content', 'Type', '{"content": "Your text here...", "color": "#94a3b8", "fontSize": 14}'::jsonb, ARRAY[]::text[]),
  ('el-button', 'Button', 'Interactive button', 'button', 'content', 'MousePointerClick', '{"text": "Click Me", "variant": "primary", "size": "medium"}'::jsonb, ARRAY['onClick']),
  ('el-image', 'Image', 'Image with caption', 'image', 'media', 'Image', '{"src": "", "alt": "", "width": "100%", "objectFit": "cover"}'::jsonb, ARRAY['onClick']),
  ('el-icon', 'Icon', 'Icon from library', 'icon', 'content', 'Star', '{"iconName": "Star", "size": 24, "color": "#ffffff"}'::jsonb, ARRAY['onClick']),
  ('el-divider', 'Divider', 'Horizontal divider line', 'divider', 'layout', 'Minus', '{"style": "solid", "color": "#334155", "width": "100%"}'::jsonb, ARRAY[]::text[]),
  ('el-spacer', 'Spacer', 'Empty space', 'spacer', 'layout', 'MoveVertical', '{"height": 20}'::jsonb, ARRAY[]::text[]),
  ('el-input', 'Input Field', 'Text input field', 'form-field', 'form', 'TextCursorInput', '{"label": "Field Label", "placeholder": "Enter text...", "type": "text", "required": false}'::jsonb, ARRAY['onChange', 'onBlur']),
  ('el-textarea', 'Text Area', 'Multi-line text input', 'form-field', 'form', 'FileText', '{"label": "Message", "placeholder": "Enter message...", "rows": 4}'::jsonb, ARRAY['onChange']),
  ('el-select', 'Select Dropdown', 'Dropdown selection', 'form-field', 'form', 'ChevronDown', '{"label": "Select Option", "options": [{"label": "Option 1", "value": "1"}]}'::jsonb, ARRAY['onChange']),
  ('el-checkbox', 'Checkbox', 'Checkbox input', 'form-field', 'form', 'CheckSquare', '{"label": "I agree", "checked": false}'::jsonb, ARRAY['onChange']),
  ('el-alert', 'Alert', 'Alert message box', 'alert', 'content', 'AlertCircle', '{"message": "Alert message", "type": "info"}'::jsonb, ARRAY[]::text[]),
  ('el-card', 'Card', 'Content card', 'card', 'layout', 'Square', '{"title": "Card Title", "content": "Card content", "padding": 16}'::jsonb, ARRAY[]::text[]);

-- Insert default safe functions
INSERT INTO plugins.safe_functions (function_id, name, description, function_type, parameters_schema, is_async, requires_auth) VALUES
  ('fn-navigate', 'Navigate to URL', 'Navigate to another page', 'navigation', '{"url": {"type": "string"}}'::jsonb, false, false),
  ('fn-api-get', 'GET API Call', 'Make GET request to API', 'api-call', '{"url": {"type": "string"}}'::jsonb, true, false),
  ('fn-api-post', 'POST API Call', 'Make POST request to API', 'api-call', '{"url": {"type": "string"}, "body": {"type": "object"}}'::jsonb, true, false),
  ('fn-show-alert', 'Show Alert', 'Display alert message', 'ui', '{"message": {"type": "string"}, "type": {"type": "string"}}'::jsonb, false, false),
  ('fn-open-modal', 'Open Modal', 'Open a modal dialog', 'ui', '{"modalId": {"type": "string"}}'::jsonb, false, false),
  ('fn-toggle-visibility', 'Toggle Visibility', 'Show/hide an element', 'ui', '{"elementId": {"type": "string"}}'::jsonb, false, false),
  ('fn-form-submit', 'Submit Form', 'Submit form data', 'form', '{"formId": {"type": "string"}, "endpoint": {"type": "string"}}'::jsonb, true, false),
  ('fn-set-value', 'Set Value', 'Set element value', 'data', '{"elementId": {"type": "string"}, "value": {"type": "any"}}'::jsonb, false, false),
  ('fn-copy-to-clipboard', 'Copy to Clipboard', 'Copy text to clipboard', 'utility', '{"text": {"type": "string"}}'::jsonb, false, false),
  ('fn-scroll-to', 'Scroll to Element', 'Scroll page to element', 'utility', '{"elementId": {"type": "string"}}'::jsonb, false, false);

-- Show inserted data
SELECT 'Element Library:' as info;
SELECT element_id, name, category FROM plugins.element_library ORDER BY category, name;

SELECT 'Safe Functions:' as info;
SELECT function_id, name, function_type FROM plugins.safe_functions ORDER BY function_type, name;
