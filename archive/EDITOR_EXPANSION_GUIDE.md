# 🎨 GrapesJS Editor Expansion Guide - Safe Development

## Come Espandere l'Editor Senza Rompere Nulla

---

## ✅ APPROCCIO SICURO: Feature Branches + Backup

### Step 1: Backup Before Changes

```bash
# 1. Commit current state
cd /Users/andromeda/dev/ewh
git add .
git commit -m "chore: backup before editor expansion"

# 2. Create feature branch
git checkout -b feature/editor-expansion

# 3. Tag current working state
git tag -a editor-base-v1 -m "Working editor before expansion"
```

### Step 2: Modular Development Strategy

**NON modificare file core esistenti direttamente!**
**Estendi con nuovi moduli separati**

```
app-page-builder/
├── src/
│   ├── editor/                    # ← Esistente (NON TOCCARE)
│   │   └── GrapesJSEditor.tsx
│   │
│   ├── extensions/                # ← NUOVO (Aggiungi qui)
│   │   ├── acf/                   # ACF integration
│   │   ├── workflows/             # Workflow triggers
│   │   ├── database/              # DB field binding
│   │   └── filters/               # Content filters
│   │
│   └── plugins/                   # ← NUOVO (Plugins GrapesJS custom)
│       ├── acf-plugin.ts
│       ├── workflow-plugin.ts
│       └── database-plugin.ts
```

---

## 🔌 INTEGRAZIONE 1: ACF nel Editor

### 1.1 Creare Plugin ACF per GrapesJS

```typescript
// app-page-builder/src/plugins/acf-plugin.ts
import grapesjs from 'grapesjs';

export default grapesjs.plugins.add('gjs-plugin-acf', (editor, options = {}) => {
  const { BlockManager, Components } = editor;

  // Add ACF block category
  BlockManager.add('acf-field', {
    label: 'Custom Field',
    category: 'Advanced',
    content: {
      type: 'acf-field',
      components: 'ACF Field Placeholder'
    },
    attributes: {
      title: 'Drag to add custom field'
    }
  });

  // Define ACF field component type
  Components.addType('acf-field', {
    model: {
      defaults: {
        tagName: 'div',
        draggable: true,
        droppable: false,
        editable: false,

        traits: [
          {
            type: 'select',
            label: 'Field Name',
            name: 'field-name',
            options: [] // Populated from API
          },
          {
            type: 'select',
            label: 'Field Type',
            name: 'field-type',
            options: [
              { value: 'text', name: 'Text' },
              { value: 'image', name: 'Image' },
              { value: 'wysiwyg', name: 'WYSIWYG' },
              { value: 'repeater', name: 'Repeater' }
            ]
          },
          {
            type: 'text',
            label: 'Fallback Value',
            name: 'fallback'
          }
        ],

        // Store ACF config in component
        'acf-config': {
          fieldName: '',
          fieldType: 'text',
          fallback: ''
        }
      },

      init() {
        // Load available ACF fields when component added
        this.on('change:field-name', this.updateFieldPreview);
        this.loadACFFields();
      },

      async loadACFFields() {
        // Fetch available ACF fields from API
        const response = await fetch('/api/acf/fields');
        const fields = await response.json();

        // Update trait options
        const trait = this.getTrait('field-name');
        trait.set('options', fields.map(f => ({
          value: f.name,
          name: f.label
        })));
      },

      updateFieldPreview() {
        const fieldName = this.get('field-name');
        const fieldType = this.get('field-type');

        // Update component with preview
        this.set('content', `
          <div class="acf-field-preview">
            <span class="field-label">${fieldName}</span>
            <span class="field-type">(${fieldType})</span>
          </div>
        `);
      },

      // Convert to template syntax for rendering
      toHTML() {
        const config = this.get('acf-config');

        // Generate Liquid/Handlebars template
        return `{{ acf.${config.fieldName} | default: "${config.fallback}" }}`;
      }
    },

    view: {
      onRender() {
        // Add visual indicator
        this.el.classList.add('acf-component');
      }
    }
  });
});
```

### 1.2 Integrare Plugin nell'Editor

```typescript
// app-page-builder/src/editor/GrapesJSEditor.tsx
import grapesjs from 'grapesjs';
import acfPlugin from '../plugins/acf-plugin';
import workflowPlugin from '../plugins/workflow-plugin';
import databasePlugin from '../plugins/database-plugin';

export default function GrapesJSEditor() {
  useEffect(() => {
    const editor = grapesjs.init({
      container: '#gjs',

      // ... existing config ...

      plugins: [
        'gjs-blocks-basic',
        'grapesjs-plugin-forms',
        acfPlugin,          // ← NUOVO
        workflowPlugin,     // ← NUOVO
        databasePlugin      // ← NUOVO
      ],

      pluginsOpts: {
        'gjs-plugin-acf': {
          apiEndpoint: '/api/acf'
        },
        'gjs-plugin-workflow': {
          apiEndpoint: '/api/workflows'
        },
        'gjs-plugin-database': {
          apiEndpoint: '/api/database/tables'
        }
      }
    });

    return () => editor.destroy();
  }, []);

  return <div id="gjs"></div>;
}
```

---

## 🔄 INTEGRAZIONE 2: Workflow System

### 2.1 Database Schema per Workflows

```sql
-- migrations/023_workflow_system.sql
CREATE TABLE cms.workflows (
  workflow_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL,

  -- Workflow Identity
  name TEXT NOT NULL,
  description TEXT,
  trigger_type TEXT NOT NULL CHECK (trigger_type IN (
    'content_published',
    'form_submitted',
    'user_registered',
    'order_placed',
    'manual',
    'scheduled'
  )),

  -- Trigger Configuration
  trigger_config JSONB DEFAULT '{}'::jsonb,

  -- Workflow Steps (n8n-style)
  steps JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- [
  --   {
  --     "id": "step-1",
  --     "type": "send_email",
  --     "config": {
  --       "to": "{{ user.email }}",
  --       "subject": "Welcome!",
  --       "template": "welcome-email"
  --     }
  --   },
  --   {
  --     "id": "step-2",
  --     "type": "http_request",
  --     "config": {
  --       "url": "https://api.example.com/webhook",
  --       "method": "POST",
  --       "body": "{{ data }}"
  --     }
  --   }
  -- ]

  -- Status
  is_active BOOLEAN DEFAULT TRUE,

  -- Stats
  execution_count INT DEFAULT 0,
  last_executed_at TIMESTAMPTZ,

  created_by UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workflow Executions Log
CREATE TABLE cms.workflow_executions (
  execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES cms.workflows(workflow_id) ON DELETE CASCADE,

  -- Execution
  status TEXT DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'cancelled')),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,

  -- Input/Output
  input_data JSONB,
  output_data JSONB,

  -- Steps execution
  step_results JSONB DEFAULT '[]'::jsonb,

  -- Error handling
  error_message TEXT,
  error_step TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workflow_executions_workflow ON cms.workflow_executions(workflow_id);
CREATE INDEX idx_workflow_executions_status ON cms.workflow_executions(status);
```

### 2.2 Workflow Plugin per GrapesJS

```typescript
// app-page-builder/src/plugins/workflow-plugin.ts
import grapesjs from 'grapesjs';

export default grapesjs.plugins.add('gjs-plugin-workflow', (editor, options = {}) => {
  const { BlockManager, Components } = editor;

  // Add Workflow trigger block
  BlockManager.add('workflow-trigger', {
    label: 'Workflow Trigger',
    category: 'Advanced',
    content: {
      type: 'workflow-trigger',
      components: '<button>Trigger Workflow</button>'
    }
  });

  // Define workflow trigger component
  Components.addType('workflow-trigger', {
    model: {
      defaults: {
        tagName: 'button',

        traits: [
          {
            type: 'select',
            label: 'Workflow',
            name: 'workflow-id',
            options: [] // Loaded from API
          },
          {
            type: 'text',
            label: 'Button Text',
            name: 'button-text',
            placeholder: 'Click to start'
          },
          {
            type: 'checkbox',
            label: 'Show Loading',
            name: 'show-loading'
          }
        ]
      },

      init() {
        this.loadWorkflows();
        this.on('change:workflow-id', this.updateWorkflowInfo);
      },

      async loadWorkflows() {
        const response = await fetch('/api/workflows');
        const workflows = await response.json();

        const trait = this.getTrait('workflow-id');
        trait.set('options', workflows.map(w => ({
          value: w.workflow_id,
          name: w.name
        })));
      },

      toHTML() {
        const workflowId = this.get('workflow-id');
        const buttonText = this.get('button-text');
        const showLoading = this.get('show-loading');

        return `
          <button
            class="workflow-trigger-btn"
            data-workflow-id="${workflowId}"
            data-show-loading="${showLoading}"
            onclick="triggerWorkflow('${workflowId}', this)"
          >
            ${buttonText}
          </button>
        `;
      }
    }
  });

  // Add workflow script to page
  editor.on('component:mount', () => {
    editor.Canvas.getDocument().head.insertAdjacentHTML('beforeend', `
      <script>
        async function triggerWorkflow(workflowId, button) {
          if (button.dataset.showLoading === 'true') {
            button.disabled = true;
            button.textContent = 'Loading...';
          }

          try {
            const response = await fetch('/api/workflows/' + workflowId + '/execute', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                context: {
                  page: window.location.pathname,
                  user: window.currentUser
                }
              })
            });

            const result = await response.json();

            // Trigger custom event
            window.dispatchEvent(new CustomEvent('workflow:completed', {
              detail: { workflowId, result }
            }));

            alert('Workflow completed successfully!');

          } catch (error) {
            alert('Workflow failed: ' + error.message);
          } finally {
            button.disabled = false;
            button.textContent = button.dataset.originalText;
          }
        }
      </script>
    `);
  });
});
```

---

## 🗄️ INTEGRAZIONE 3: Database Fields

### 3.1 Database Plugin per GrapesJS

```typescript
// app-page-builder/src/plugins/database-plugin.ts
import grapesjs from 'grapesjs';

export default grapesjs.plugins.add('gjs-plugin-database', (editor, options = {}) => {
  const { BlockManager, Components } = editor;

  // Add database field block
  BlockManager.add('db-field', {
    label: 'Database Field',
    category: 'Data',
    content: {
      type: 'db-field',
      components: 'Database Field'
    }
  });

  // Define database field component
  Components.addType('db-field', {
    model: {
      defaults: {
        tagName: 'span',

        traits: [
          {
            type: 'select',
            label: 'Table',
            name: 'db-table',
            options: [] // Loaded from API
          },
          {
            type: 'select',
            label: 'Field',
            name: 'db-field',
            options: [] // Updated when table changes
          },
          {
            type: 'text',
            label: 'Filter (WHERE)',
            name: 'db-filter',
            placeholder: 'id = {{post.id}}'
          },
          {
            type: 'select',
            label: 'Format',
            name: 'db-format',
            options: [
              { value: 'raw', name: 'Raw Value' },
              { value: 'date', name: 'Date' },
              { value: 'currency', name: 'Currency' },
              { value: 'number', name: 'Number' }
            ]
          }
        ]
      },

      init() {
        this.loadTables();
        this.on('change:db-table', this.loadFields);
      },

      async loadTables() {
        const response = await fetch('/api/database/tables');
        const tables = await response.json();

        const trait = this.getTrait('db-table');
        trait.set('options', tables.map(t => ({
          value: t.name,
          name: t.label || t.name
        })));
      },

      async loadFields() {
        const tableName = this.get('db-table');
        if (!tableName) return;

        const response = await fetch(`/api/database/tables/${tableName}/fields`);
        const fields = await response.json();

        const trait = this.getTrait('db-field');
        trait.set('options', fields.map(f => ({
          value: f.name,
          name: f.label || f.name
        })));
      },

      toHTML() {
        const table = this.get('db-table');
        const field = this.get('db-field');
        const filter = this.get('db-filter');
        const format = this.get('db-format');

        // Generate template syntax
        return `{{ db.query('${table}', '${field}', '${filter}') | ${format} }}`;
      }
    }
  });

  // Add query builder UI
  editor.Commands.add('open-query-builder', {
    run(editor) {
      const modal = editor.Modal;

      modal.setTitle('Query Builder');
      modal.setContent(`
        <div class="query-builder">
          <h3>Build Database Query</h3>

          <div class="form-group">
            <label>Table</label>
            <select id="qb-table"></select>
          </div>

          <div class="form-group">
            <label>Fields</label>
            <select id="qb-fields" multiple></select>
          </div>

          <div class="form-group">
            <label>WHERE Clause</label>
            <textarea id="qb-where"></textarea>
          </div>

          <div class="form-group">
            <label>ORDER BY</label>
            <input type="text" id="qb-order" />
          </div>

          <button onclick="generateQuery()">Generate Query</button>
        </div>
      `);

      modal.open();
    }
  });
});
```

---

## 🎯 INTEGRAZIONE 4: Filters & Rules

### 4.1 Content Filter System

```typescript
// app-page-builder/src/extensions/filters/ContentFilter.tsx
export interface FilterRule {
  field: string;
  operator: 'equals' | 'contains' | 'greater_than' | 'less_than' | 'in' | 'not_in';
  value: any;
  logic?: 'AND' | 'OR';
}

export interface FilterConfig {
  rules: FilterRule[];
  orderBy?: string;
  limit?: number;
  offset?: number;
}

export class ContentFilter {
  static async apply(contentType: string, filters: FilterConfig) {
    const query = this.buildQuery(contentType, filters);

    const response = await fetch('/api/content/filter', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contentType, filters: query })
    });

    return response.json();
  }

  private static buildQuery(contentType: string, config: FilterConfig) {
    const { rules, orderBy, limit, offset } = config;

    let sql = `SELECT * FROM cms.${contentType}`;

    if (rules.length > 0) {
      const whereClauses = rules.map((rule, index) => {
        const clause = this.buildWhereClause(rule);
        const logic = index > 0 ? (rule.logic || 'AND') : '';
        return `${logic} ${clause}`;
      });

      sql += ` WHERE ${whereClauses.join(' ')}`;
    }

    if (orderBy) {
      sql += ` ORDER BY ${orderBy}`;
    }

    if (limit) {
      sql += ` LIMIT ${limit}`;
    }

    if (offset) {
      sql += ` OFFSET ${offset}`;
    }

    return sql;
  }

  private static buildWhereClause(rule: FilterRule): string {
    switch (rule.operator) {
      case 'equals':
        return `${rule.field} = '${rule.value}'`;
      case 'contains':
        return `${rule.field} LIKE '%${rule.value}%'`;
      case 'greater_than':
        return `${rule.field} > ${rule.value}`;
      case 'less_than':
        return `${rule.field} < ${rule.value}`;
      case 'in':
        return `${rule.field} IN (${rule.value.join(',')})`;
      case 'not_in':
        return `${rule.field} NOT IN (${rule.value.join(',')})`;
      default:
        return '';
    }
  }
}

// Filter UI Component
export const FilterBuilder = ({ onApply }) => {
  const [rules, setRules] = useState<FilterRule[]>([]);

  const addRule = () => {
    setRules([...rules, {
      field: '',
      operator: 'equals',
      value: '',
      logic: 'AND'
    }]);
  };

  return (
    <div className="filter-builder">
      <h3>Content Filters</h3>

      {rules.map((rule, index) => (
        <div key={index} className="filter-rule">
          {index > 0 && (
            <select
              value={rule.logic}
              onChange={e => updateRule(index, 'logic', e.target.value)}
            >
              <option value="AND">AND</option>
              <option value="OR">OR</option>
            </select>
          )}

          <select
            value={rule.field}
            onChange={e => updateRule(index, 'field', e.target.value)}
          >
            <option value="">Select field...</option>
            <option value="title">Title</option>
            <option value="status">Status</option>
            <option value="created_at">Created Date</option>
          </select>

          <select
            value={rule.operator}
            onChange={e => updateRule(index, 'operator', e.target.value)}
          >
            <option value="equals">Equals</option>
            <option value="contains">Contains</option>
            <option value="greater_than">Greater than</option>
            <option value="less_than">Less than</option>
          </select>

          <input
            type="text"
            value={rule.value}
            onChange={e => updateRule(index, 'value', e.target.value)}
            placeholder="Value"
          />

          <button onClick={() => removeRule(index)}>✕</button>
        </div>
      ))}

      <button onClick={addRule}>+ Add Rule</button>
      <button onClick={() => onApply({ rules })}>Apply Filters</button>
    </div>
  );
};
```

---

## ✅ TESTING STRATEGY

### Step-by-Step Safe Testing

```bash
# 1. Test ACF plugin alone
cd /Users/andromeda/dev/ewh/app-page-builder
npm run dev

# Open editor, verify:
# - ACF blocks appear in sidebar
# - Can drag ACF field block
# - Traits panel shows field options

# 2. Test workflow plugin
# - Add workflow trigger button
# - Configure workflow
# - Test execution

# 3. Test database plugin
# - Add DB field block
# - Select table and field
# - Verify preview

# 4. Test filters
# - Open filter builder
# - Add rules
# - Apply filters
# - Check results
```

### Rollback Se Qualcosa Non Va

```bash
# Return to working state
git checkout editor-base-v1

# Or discard changes
git reset --hard HEAD

# Or revert specific file
git checkout HEAD -- src/editor/GrapesJSEditor.tsx
```

---

## 📋 CHECKLIST EXPANSION

Prima di espandere, verifica:

- [ ] Commit attuale
- [ ] Feature branch creata
- [ ] Tag backup creato
- [ ] Tutti i servizi running
- [ ] Editor base funzionante

Mentre espandi:

- [ ] Crea plugin separati (non modificare core)
- [ ] Test ogni plugin individualmente
- [ ] Commit frequenti con messaggi chiari
- [ ] Documentazione inline
- [ ] Console.log per debug

Dopo l'espansione:

- [ ] Test completo di integrazione
- [ ] Verifica performance
- [ ] Check compatibilità browser
- [ ] Merge nel main solo se tutto OK

---

## 🚀 ORDINE CONSIGLIATO DI IMPLEMENTAZIONE

1. **Week 1**: ACF Plugin
   - Più semplice
   - Blocchi base
   - Test visuale facile

2. **Week 2**: Database Plugin
   - Medio-difficile
   - Richiede API backend
   - Test con dati reali

3. **Week 3**: Workflow Plugin
   - Più complesso
   - Richiede workflow engine
   - Test di integrazione

4. **Week 4**: Filters & Rules
   - Complesso
   - Query builder UI
   - Performance testing

---

## 💡 PRO TIPS

1. **Hot Reload**: Vite supporta HMR, i cambiamenti si vedono subito
2. **Debug**: GrapesJS ha devtools integrati (`editor.Commands.run('core:open-tm')`)
3. **Console**: Usa `window.editor` per accedere all'istanza GrapesJS da console
4. **Snapshot**: Prima di ogni feature, `git stash` per tornare indietro velocemente
5. **Parallel Dev**: Lavora sui plugin in branch separati, merge quando ready

---

**Non romperai nulla se segui questo approccio modulare!** 🎉
