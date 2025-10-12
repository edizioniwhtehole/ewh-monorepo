-- God Mode: Meta-Programming System for Dynamic Frontend Creation
-- This allows infrastructure admins to create widgets, interfaces, modules, and functions from the admin panel

-- Widget Definitions (building blocks for interfaces)
CREATE TABLE IF NOT EXISTS workflow.widget_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) NOT NULL CHECK (category IN ('data-display', 'form', 'chart', 'layout', 'navigation', 'media', 'custom')),

  -- Component specification
  component_type VARCHAR(100) NOT NULL, -- 'react-component', 'html', 'iframe', 'custom'
  component_code TEXT, -- React component code or HTML
  component_props JSONB DEFAULT '{}', -- Default props schema

  -- Styling
  default_styles JSONB DEFAULT '{}',
  css_classes TEXT[] DEFAULT '{}',
  custom_css TEXT,

  -- Configuration
  config_schema JSONB DEFAULT '{}', -- JSON Schema for widget configuration
  default_config JSONB DEFAULT '{}',

  -- Data binding
  data_source_type VARCHAR(50) CHECK (data_source_type IN ('static', 'api', 'database', 'function', 'webhook', 'realtime')),
  data_source_config JSONB DEFAULT '{}',

  -- Events and actions
  event_handlers JSONB DEFAULT '{}', -- { onClick: 'function_id', onLoad: 'function_id' }

  -- Permissions
  required_permissions TEXT[] DEFAULT '{}',
  visible_to_roles TEXT[] DEFAULT '{}',

  -- Lifecycle
  enabled BOOLEAN DEFAULT true,
  version INTEGER DEFAULT 1,
  is_template BOOLEAN DEFAULT false,
  tags TEXT[] DEFAULT '{}',

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_widget_definitions_category ON workflow.widget_definitions(category);
CREATE INDEX idx_widget_definitions_enabled ON workflow.widget_definitions(enabled);
CREATE INDEX idx_widget_definitions_template ON workflow.widget_definitions(is_template);

-- Page/Interface Definitions (composition of widgets)
CREATE TABLE IF NOT EXISTS workflow.page_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Routing
  path VARCHAR(500) NOT NULL UNIQUE, -- /dashboard, /reports/:id
  is_dynamic BOOLEAN DEFAULT false, -- true if path has parameters
  parent_page_id UUID REFERENCES workflow.page_definitions(id),

  -- Layout
  layout_type VARCHAR(50) NOT NULL CHECK (layout_type IN ('grid', 'flex', 'absolute', 'custom')),
  layout_config JSONB DEFAULT '{}',

  -- Widgets on this page
  widgets JSONB NOT NULL DEFAULT '[]', -- [{ widget_id, position, config, bindings }]

  -- Page-level configuration
  page_config JSONB DEFAULT '{}',
  seo_meta JSONB DEFAULT '{}',

  -- Security
  requires_auth BOOLEAN DEFAULT true,
  required_permissions TEXT[] DEFAULT '{}',
  visible_to_roles TEXT[] DEFAULT '{}',

  -- Lifecycle
  enabled BOOLEAN DEFAULT true,
  is_published BOOLEAN DEFAULT false,
  version INTEGER DEFAULT 1,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  published_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES auth.users(id),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_page_definitions_path ON workflow.page_definitions(path);
CREATE INDEX idx_page_definitions_enabled ON workflow.page_definitions(enabled);
CREATE INDEX idx_page_definitions_published ON workflow.page_definitions(is_published);

-- Module Definitions (packaged widgets + pages + functions)
CREATE TABLE IF NOT EXISTS workflow.module_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  display_name VARCHAR(255) NOT NULL,
  description TEXT,
  version VARCHAR(50) NOT NULL,

  -- Module contents
  widget_ids UUID[] DEFAULT '{}',
  page_ids UUID[] DEFAULT '{}',
  function_ids UUID[] DEFAULT '{}',
  api_ids UUID[] DEFAULT '{}',

  -- Dependencies
  depends_on UUID[] DEFAULT '{}', -- Other module IDs
  requires_services TEXT[] DEFAULT '{}', -- Required backend services

  -- Installation
  install_script TEXT, -- Setup code to run on installation
  uninstall_script TEXT,

  -- Configuration
  config_schema JSONB DEFAULT '{}',
  default_config JSONB DEFAULT '{}',

  -- Lifecycle
  enabled BOOLEAN DEFAULT true,
  installed BOOLEAN DEFAULT false,
  installed_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  tags TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_module_definitions_enabled ON workflow.module_definitions(enabled);
CREATE INDEX idx_module_definitions_installed ON workflow.module_definitions(installed);

-- Widget Instances (actual widgets placed on pages)
CREATE TABLE IF NOT EXISTS workflow.widget_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  widget_definition_id UUID NOT NULL REFERENCES workflow.widget_definitions(id) ON DELETE CASCADE,
  page_id UUID NOT NULL REFERENCES workflow.page_definitions(id) ON DELETE CASCADE,

  -- Instance-specific configuration
  instance_config JSONB DEFAULT '{}',
  instance_styles JSONB DEFAULT '{}',

  -- Positioning
  position JSONB NOT NULL, -- { x, y, width, height, zIndex }

  -- Data binding overrides
  data_bindings JSONB DEFAULT '{}',

  -- State
  enabled BOOLEAN DEFAULT true,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_widget_instances_page ON workflow.widget_instances(page_id);
CREATE INDEX idx_widget_instances_widget ON workflow.widget_instances(widget_definition_id);

-- Frontend Function Library (extends workflow.custom_functions for frontend use)
CREATE TABLE IF NOT EXISTS workflow.frontend_functions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  function_id UUID NOT NULL REFERENCES workflow.custom_functions(id) ON DELETE CASCADE,

  -- Frontend-specific
  execution_context VARCHAR(50) NOT NULL CHECK (execution_context IN ('client', 'server', 'both')),
  is_pure BOOLEAN DEFAULT false, -- Pure functions can be cached

  -- Dependencies
  depends_on_functions UUID[] DEFAULT '{}',
  requires_apis UUID[] DEFAULT '{}',

  -- Performance
  cache_enabled BOOLEAN DEFAULT false,
  cache_ttl INTEGER, -- seconds

  -- Permissions
  callable_by_roles TEXT[] DEFAULT '{}',

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_frontend_functions_context ON workflow.frontend_functions(execution_context);

-- Page Visit Analytics
CREATE TABLE IF NOT EXISTS workflow.page_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  page_id UUID NOT NULL REFERENCES workflow.page_definitions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),

  visited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  session_id VARCHAR(255),
  ip_address INET,
  user_agent TEXT,

  -- Interaction data
  time_spent_ms INTEGER,
  interactions JSONB DEFAULT '{}',

  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_page_analytics_page ON workflow.page_analytics(page_id);
CREATE INDEX idx_page_analytics_visited ON workflow.page_analytics(visited_at DESC);

-- Update triggers
CREATE TRIGGER update_widget_definitions_updated_at BEFORE UPDATE ON workflow.widget_definitions
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_page_definitions_updated_at BEFORE UPDATE ON workflow.page_definitions
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

CREATE TRIGGER update_module_definitions_updated_at BEFORE UPDATE ON workflow.module_definitions
  FOR EACH ROW EXECUTE FUNCTION workflow.update_updated_at_column();

-- Seed some example widgets
INSERT INTO workflow.widget_definitions (name, display_name, description, category, component_type, component_code, config_schema)
VALUES
  ('simple-card', 'Simple Card', 'A basic card component with title and content', 'layout', 'react-component',
   'export default function SimpleCard({ title, content, config }) {
     return (
       <div className="bg-white rounded-lg shadow p-4">
         <h3 className="text-lg font-bold mb-2">{title}</h3>
         <p className="text-gray-600">{content}</p>
       </div>
     );
   }',
   '{"type": "object", "properties": {"title": {"type": "string"}, "content": {"type": "string"}}}'
  ),

  ('data-table', 'Data Table', 'Table component with sorting and filtering', 'data-display', 'react-component',
   'export default function DataTable({ columns, data, config }) {
     return (
       <div className="overflow-x-auto">
         <table className="min-w-full divide-y divide-gray-200">
           <thead className="bg-gray-50">
             <tr>
               {columns.map(col => (
                 <th key={col.key} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                   {col.label}
                 </th>
               ))}
             </tr>
           </thead>
           <tbody className="bg-white divide-y divide-gray-200">
             {data.map((row, i) => (
               <tr key={i}>
                 {columns.map(col => (
                   <td key={col.key} className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                     {row[col.key]}
                   </td>
                 ))}
               </tr>
             ))}
           </tbody>
         </table>
       </div>
     );
   }',
   '{"type": "object", "properties": {"columns": {"type": "array"}, "data": {"type": "array"}}}'
  ),

  ('custom-form', 'Custom Form', 'Dynamic form builder with validation', 'form', 'react-component',
   'export default function CustomForm({ fields, onSubmit, config }) {
     const [formData, setFormData] = useState({});

     const handleSubmit = (e) => {
       e.preventDefault();
       onSubmit(formData);
     };

     return (
       <form onSubmit={handleSubmit} className="space-y-4">
         {fields.map(field => (
           <div key={field.name}>
             <label className="block text-sm font-medium text-gray-700 mb-1">
               {field.label}
             </label>
             <input
               type={field.type}
               name={field.name}
               required={field.required}
               className="w-full px-3 py-2 border border-gray-300 rounded-md"
               onChange={(e) => setFormData({...formData, [field.name]: e.target.value})}
             />
           </div>
         ))}
         <button type="submit" className="px-4 py-2 bg-blue-500 text-white rounded-md">
           Submit
         </button>
       </form>
     );
   }',
   '{"type": "object", "properties": {"fields": {"type": "array"}, "onSubmit": {"type": "string"}}}'
  )
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE workflow.widget_definitions IS 'Widget definitions for dynamic frontend creation';
COMMENT ON TABLE workflow.page_definitions IS 'Page/interface definitions composed of widgets';
COMMENT ON TABLE workflow.module_definitions IS 'Packaged modules containing widgets, pages, and functions';
COMMENT ON TABLE workflow.widget_instances IS 'Actual widget instances placed on pages';
COMMENT ON TABLE workflow.frontend_functions IS 'Frontend-callable functions';
COMMENT ON TABLE workflow.page_analytics IS 'Page visit and interaction analytics';
