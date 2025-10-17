# 🗄️ Visual Database Editor Specification
## Editor DB Visuale Stile Xano per EWH Platform

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0
**Status**: STANDARD MANDATORIO

---

## 🎯 Executive Summary

Il Visual Database Editor è uno strumento moderno simile a **Xano** o **NocoDB** che permette agli utenti di:

1. **Creare tabelle custom** con interfaccia drag-and-drop
2. **Definire relazioni** tra tabelle visivamente
3. **Gestire dati** con interfaccia simile a spreadsheet
4. **Creare API automatiche** per ogni tabella creata
5. **Definire business logic** con workflow visuali

### Posizionamento nella Piattaforma

```
┌─────────────────────────────────────────────────────────────┐
│              app-shell-frontend (Admin Menu)                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  👥 Users    🏢 Tenants    🔧 Services               │  │
│  │  📊 Analytics    🗄️ DATABASE EDITOR (NEW!)          │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│          app-database-editor (Frontend - React)             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • Schema Designer (visual table builder)           │  │
│  │  • Relationship Manager (ER diagram)                │  │
│  │  • Data Editor (spreadsheet-like)                   │  │
│  │  • API Builder (auto-generate endpoints)            │  │
│  │  • Query Builder (visual SQL)                       │  │
│  └──────────────────────┬───────────────────────────────┘  │
└────────────────────────┼────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│          svc-database-editor (Backend - Express)            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • Schema Management Controller                     │  │
│  │  • DDL Generator (CREATE/ALTER/DROP)                │  │
│  │  • Dynamic API Generator                            │  │
│  │  • Data Operations Controller                       │  │
│  │  • Query Executor                                   │  │
│  └──────────────────────┬───────────────────────────────┘  │
└────────────────────────┼────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL (ewh_tenant)                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • custom_tables_registry                           │  │
│  │  • custom_* tables (dynamically created)            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Service Architecture

### app-database-editor (Frontend)

**Port**: 3950
**Tech Stack**: React 18 + Vite + TypeScript + TailwindCSS

#### Features

1. **Schema Designer**
   - Visual table builder
   - Column type selector (text, number, date, relation, json, etc.)
   - Drag-and-drop column reordering
   - Field validation rules

2. **Relationship Manager**
   - ER diagram visualization
   - Visual foreign key creation
   - One-to-many, many-to-many support
   - Cascade delete/update options

3. **Data Editor**
   - Spreadsheet-like interface (similar to Airtable)
   - Inline editing
   - Bulk operations (import/export CSV, JSON)
   - Filtering, sorting, searching

4. **API Builder**
   - Auto-generate CRUD endpoints
   - Custom endpoint creator
   - API documentation generator
   - Test console

5. **Query Builder**
   - Visual SQL builder (no-code)
   - Preview results
   - Save as view
   - Export to code

### svc-database-editor (Backend)

**Port**: 5950
**Tech Stack**: Express + TypeScript + node-postgres

#### API Routes

```
POST   /api/db-editor/tables                    # Create table
GET    /api/db-editor/tables                    # List tables
GET    /api/db-editor/tables/:tableName         # Get table schema
PUT    /api/db-editor/tables/:tableName         # Modify table schema
DELETE /api/db-editor/tables/:tableName         # Drop table

POST   /api/db-editor/tables/:tableName/columns # Add column
PUT    /api/db-editor/tables/:tableName/columns/:columnName # Modify column
DELETE /api/db-editor/tables/:tableName/columns/:columnName # Drop column

POST   /api/db-editor/relationships             # Create foreign key
DELETE /api/db-editor/relationships/:id         # Drop foreign key

GET    /api/db-editor/data/:tableName           # Get data (paginated)
POST   /api/db-editor/data/:tableName           # Insert row
PUT    /api/db-editor/data/:tableName/:id       # Update row
DELETE /api/db-editor/data/:tableName/:id       # Delete row

POST   /api/db-editor/query                     # Execute custom query
POST   /api/db-editor/views                     # Create view
GET    /api/db-editor/views                     # List views

POST   /api/db-editor/export/:tableName         # Export data (CSV/JSON)
POST   /api/db-editor/import/:tableName         # Import data (CSV/JSON)
```

---

## 📊 Database Schema

### custom_tables_registry

```sql
CREATE TABLE custom_tables_registry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  table_name VARCHAR(100) NOT NULL, -- actual PostgreSQL table name (prefixed with custom_)
  display_name VARCHAR(500) NOT NULL,
  description TEXT,
  icon VARCHAR(50), -- emoji or icon name
  color VARCHAR(20), -- hex color
  schema_config JSONB NOT NULL,
  -- Schema config structure:
  -- {
  --   "columns": [
  --     {
  --       "name": "email",
  --       "displayName": "Email Address",
  --       "type": "text",
  --       "nullable": false,
  --       "unique": true,
  --       "defaultValue": null,
  --       "validation": {
  --         "pattern": "^[^@]+@[^@]+\\.[^@]+$",
  --         "minLength": 5,
  --         "maxLength": 255
  --       }
  --     }
  --   ]
  -- }
  relationships JSONB DEFAULT '[]'::jsonb,
  -- Relationships structure:
  -- [
  --   {
  --     "type": "belongsTo",
  --     "targetTable": "custom_companies",
  --     "foreignKey": "company_id",
  --     "displayName": "Company"
  --   }
  -- ]
  permissions JSONB DEFAULT '{}'::jsonb,
  -- Permissions structure:
  -- {
  --   "read": ["TENANT_ADMIN", "USER"],
  --   "create": ["TENANT_ADMIN"],
  --   "update": ["TENANT_ADMIN"],
  --   "delete": ["TENANT_ADMIN"]
  -- }
  api_enabled BOOLEAN DEFAULT true,
  api_prefix VARCHAR(100), -- e.g., /api/custom/contacts
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL,
  updated_by INTEGER,
  UNIQUE(tenant_id, table_name)
);

CREATE INDEX idx_custom_tables_tenant ON custom_tables_registry(tenant_id);
CREATE INDEX idx_custom_tables_api_enabled ON custom_tables_registry(api_enabled);
```

### custom_views

```sql
CREATE TABLE custom_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  view_name VARCHAR(100) NOT NULL,
  display_name VARCHAR(500) NOT NULL,
  description TEXT,
  base_table VARCHAR(100) NOT NULL, -- references custom_tables_registry.table_name
  query_config JSONB NOT NULL,
  -- Query config structure:
  -- {
  --   "select": ["column1", "column2"],
  --   "where": [{"field": "status", "operator": "=", "value": "active"}],
  --   "orderBy": [{"field": "created_at", "direction": "DESC"}],
  --   "limit": 100
  -- }
  is_materialized BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL,
  UNIQUE(tenant_id, view_name)
);
```

### custom_api_endpoints

```sql
CREATE TABLE custom_api_endpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL,
  endpoint_key VARCHAR(100) NOT NULL,
  endpoint_path VARCHAR(500) NOT NULL, -- e.g., /api/custom/search-contacts
  http_method VARCHAR(10) NOT NULL, -- GET, POST, PUT, DELETE
  description TEXT,
  base_table VARCHAR(100), -- optional, for table-based endpoints
  query_config JSONB, -- SQL query configuration
  workflow_id UUID, -- optional, reference to workflow engine
  permissions JSONB DEFAULT '{}'::jsonb,
  rate_limit INTEGER DEFAULT 100, -- requests per minute
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by INTEGER NOT NULL,
  UNIQUE(tenant_id, endpoint_key)
);
```

---

## 🎨 Frontend Components

### 1. SchemaDesigner.tsx

```typescript
/**
 * Visual table schema designer
 * Allows users to create and modify table structures
 */

interface SchemaDesignerProps {
  tableName?: string; // undefined for new table
  onSave: (schema: TableSchema) => void;
}

interface TableSchema {
  tableName: string;
  displayName: string;
  description?: string;
  icon?: string;
  color?: string;
  columns: ColumnDefinition[];
}

interface ColumnDefinition {
  name: string;
  displayName: string;
  type: 'text' | 'number' | 'boolean' | 'date' | 'datetime' | 'json' | 'uuid' | 'relation';
  nullable: boolean;
  unique: boolean;
  defaultValue?: any;
  validation?: ValidationRules;
  relatedTable?: string; // for relation type
  relationType?: 'belongsTo' | 'hasMany';
}

interface ValidationRules {
  minLength?: number;
  maxLength?: number;
  min?: number;
  max?: number;
  pattern?: string; // regex pattern
  enum?: string[]; // allowed values
}
```

**Features**:
- Add/remove columns
- Column type selector with icons
- Inline validation rule editor
- Preview generated SQL
- Test mode (creates temporary table)

### 2. RelationshipManager.tsx

```typescript
/**
 * Visual ER diagram for managing table relationships
 * Similar to Xano's relationship view
 */

interface RelationshipManagerProps {
  tenantId: number;
}

interface Relationship {
  id: string;
  sourceTable: string;
  targetTable: string;
  type: 'one-to-many' | 'many-to-many';
  foreignKey: string;
  onDelete: 'CASCADE' | 'SET NULL' | 'RESTRICT';
  onUpdate: 'CASCADE' | 'SET NULL' | 'RESTRICT';
}
```

**Features**:
- Canvas-based ER diagram (React Flow)
- Drag tables to reposition
- Click-and-drag to create relationships
- Auto-layout button
- Export as image

### 3. DataEditor.tsx

```typescript
/**
 * Spreadsheet-like data editor
 * Similar to Airtable's grid view
 */

interface DataEditorProps {
  tableName: string;
  schema: TableSchema;
}
```

**Features**:
- Virtualized rows for performance (react-virtual)
- Inline cell editing
- Column resizing and reordering
- Row selection (multi-select)
- Bulk actions (delete, export)
- Filter and sort controls
- Pagination

### 4. APIBuilder.tsx

```typescript
/**
 * Automatic API endpoint generator
 * Creates CRUD endpoints for custom tables
 */

interface APIBuilderProps {
  tableName: string;
}

interface GeneratedEndpoint {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  path: string;
  description: string;
  requestBody?: object;
  responseExample: object;
}
```

**Features**:
- Auto-generate CRUD endpoints
- Custom endpoint creator
- Request/response examples
- API testing console
- Copy as cURL command
- Generate OpenAPI spec

### 5. QueryBuilder.tsx

```typescript
/**
 * Visual SQL query builder
 * No-code interface for creating queries
 */

interface QueryBuilderProps {
  onExecute: (query: QueryConfig) => void;
}

interface QueryConfig {
  table: string;
  select: string[];
  where: WhereClause[];
  orderBy: OrderByClause[];
  limit: number;
  offset: number;
}

interface WhereClause {
  field: string;
  operator: '=' | '!=' | '>' | '<' | '>=' | '<=' | 'LIKE' | 'IN';
  value: any;
  logicalOperator?: 'AND' | 'OR';
}
```

**Features**:
- Drag-and-drop query builder
- Field selector with autocomplete
- Operator selector (=, !=, >, LIKE, etc.)
- Preview results in real-time
- Save as view
- Export as SQL
- Convert to API endpoint

---

## 🔧 Backend Implementation

### Controller: SchemaManagementController.ts

```typescript
/**
 * Handles table creation, modification, and deletion
 * src/controllers/schema/SchemaManagementController.ts
 */

import { Request, Response } from 'express';
import { Pool } from 'pg';

export class SchemaManagementController {
  private pool: Pool;

  constructor(pool: Pool) {
    this.pool = pool;
  }

  /**
   * Create a new custom table
   * POST /api/db-editor/tables
   */
  async createTable(req: Request, res: Response) {
    const { displayName, description, columns, icon, color } = req.body;
    const tenantId = req.user.tenantId;
    const userId = req.user.id;

    try {
      // Generate safe table name
      const tableName = `custom_${this.sanitizeTableName(displayName)}`;

      // Validate columns
      this.validateColumns(columns);

      // Generate CREATE TABLE SQL
      const createTableSQL = this.generateCreateTableSQL(tableName, columns, tenantId);

      // Start transaction
      await this.pool.query('BEGIN');

      // Create the actual table
      await this.pool.query(createTableSQL);

      // Register in custom_tables_registry
      const schemaConfig = { columns };
      await this.pool.query(
        `INSERT INTO custom_tables_registry
         (tenant_id, table_name, display_name, description, icon, color, schema_config, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [tenantId, tableName, displayName, description, icon, color, JSON.stringify(schemaConfig), userId]
      );

      // Commit transaction
      await this.pool.query('COMMIT');

      res.json({
        success: true,
        data: {
          tableName,
          displayName,
          message: 'Table created successfully',
        },
      });
    } catch (error) {
      await this.pool.query('ROLLBACK');
      console.error('Error creating table:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create table',
      });
    }
  }

  /**
   * Generate CREATE TABLE SQL from column definitions
   */
  private generateCreateTableSQL(tableName: string, columns: ColumnDefinition[], tenantId: number): string {
    const columnDefs = columns.map(col => {
      let def = `"${col.name}" ${this.mapColumnType(col.type)}`;

      if (!col.nullable) def += ' NOT NULL';
      if (col.unique) def += ' UNIQUE';
      if (col.defaultValue !== undefined) def += ` DEFAULT ${this.formatDefaultValue(col.defaultValue, col.type)}`;

      return def;
    }).join(',\n  ');

    return `
      CREATE TABLE "${tableName}" (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id INTEGER NOT NULL DEFAULT ${tenantId},
        ${columnDefs},
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW(),
        created_by INTEGER NOT NULL
      );

      CREATE INDEX "idx_${tableName}_tenant" ON "${tableName}"(tenant_id);
    `;
  }

  /**
   * Map UI column types to PostgreSQL types
   */
  private mapColumnType(type: string): string {
    const typeMap: Record<string, string> = {
      text: 'TEXT',
      number: 'NUMERIC',
      boolean: 'BOOLEAN',
      date: 'DATE',
      datetime: 'TIMESTAMPTZ',
      json: 'JSONB',
      uuid: 'UUID',
      relation: 'UUID', // foreign key
    };
    return typeMap[type] || 'TEXT';
  }

  /**
   * Sanitize table name (remove special characters)
   */
  private sanitizeTableName(name: string): string {
    return name
      .toLowerCase()
      .replace(/[^a-z0-9_]/g, '_')
      .replace(/^_+|_+$/g, '')
      .substring(0, 50);
  }

  /**
   * Validate column definitions
   */
  private validateColumns(columns: ColumnDefinition[]): void {
    if (!columns || columns.length === 0) {
      throw new Error('At least one column is required');
    }

    const columnNames = new Set<string>();
    for (const col of columns) {
      if (!col.name || !col.type) {
        throw new Error('Column name and type are required');
      }
      if (columnNames.has(col.name)) {
        throw new Error(`Duplicate column name: ${col.name}`);
      }
      columnNames.add(col.name);
    }
  }

  /**
   * Format default value based on column type
   */
  private formatDefaultValue(value: any, type: string): string {
    if (value === null) return 'NULL';

    switch (type) {
      case 'text':
        return `'${value.replace(/'/g, "''")}'`;
      case 'number':
        return String(value);
      case 'boolean':
        return value ? 'TRUE' : 'FALSE';
      case 'date':
      case 'datetime':
        return `'${value}'`;
      case 'json':
        return `'${JSON.stringify(value)}'::jsonb`;
      default:
        return `'${value}'`;
    }
  }

  /**
   * Add column to existing table
   * POST /api/db-editor/tables/:tableName/columns
   */
  async addColumn(req: Request, res: Response) {
    const { tableName } = req.params;
    const column: ColumnDefinition = req.body;
    const tenantId = req.user.tenantId;

    try {
      // Verify table ownership
      await this.verifyTableOwnership(tableName, tenantId);

      // Generate ALTER TABLE SQL
      const alterSQL = this.generateAddColumnSQL(tableName, column);

      await this.pool.query('BEGIN');

      // Add column to table
      await this.pool.query(alterSQL);

      // Update schema_config in registry
      await this.pool.query(
        `UPDATE custom_tables_registry
         SET schema_config = jsonb_set(
           schema_config,
           '{columns}',
           schema_config->'columns' || $1::jsonb
         ),
         updated_at = NOW(),
         updated_by = $2
         WHERE tenant_id = $3 AND table_name = $4`,
        [JSON.stringify(column), req.user.id, tenantId, tableName]
      );

      await this.pool.query('COMMIT');

      res.json({
        success: true,
        message: 'Column added successfully',
      });
    } catch (error) {
      await this.pool.query('ROLLBACK');
      console.error('Error adding column:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to add column',
      });
    }
  }

  /**
   * Generate ALTER TABLE ADD COLUMN SQL
   */
  private generateAddColumnSQL(tableName: string, column: ColumnDefinition): string {
    let def = `"${column.name}" ${this.mapColumnType(column.type)}`;

    if (!column.nullable) def += ' NOT NULL';
    if (column.unique) def += ' UNIQUE';
    if (column.defaultValue !== undefined) {
      def += ` DEFAULT ${this.formatDefaultValue(column.defaultValue, column.type)}`;
    }

    return `ALTER TABLE "${tableName}" ADD COLUMN ${def};`;
  }

  /**
   * Verify that the table belongs to the current tenant
   */
  private async verifyTableOwnership(tableName: string, tenantId: number): Promise<void> {
    const result = await this.pool.query(
      'SELECT id FROM custom_tables_registry WHERE table_name = $1 AND tenant_id = $2',
      [tableName, tenantId]
    );

    if (result.rows.length === 0) {
      throw new Error('Table not found or access denied');
    }
  }
}
```

### Controller: DataOperationsController.ts

```typescript
/**
 * Handles CRUD operations on custom tables
 * src/controllers/data/DataOperationsController.ts
 */

export class DataOperationsController {
  private pool: Pool;

  constructor(pool: Pool) {
    this.pool = pool;
  }

  /**
   * Get data from custom table (paginated)
   * GET /api/db-editor/data/:tableName
   */
  async getData(req: Request, res: Response) {
    const { tableName } = req.params;
    const { page = 1, limit = 50, sort, order = 'ASC', filters } = req.query;
    const tenantId = req.user.tenantId;

    try {
      // Verify table ownership
      await this.verifyTableOwnership(tableName, tenantId);

      // Build query
      let query = `SELECT * FROM "${tableName}" WHERE tenant_id = $1`;
      const params: any[] = [tenantId];
      let paramIndex = 2;

      // Add filters
      if (filters) {
        const filterObj = JSON.parse(filters as string);
        for (const [field, value] of Object.entries(filterObj)) {
          query += ` AND "${field}" = $${paramIndex}`;
          params.push(value);
          paramIndex++;
        }
      }

      // Add sorting
      if (sort) {
        query += ` ORDER BY "${sort}" ${order}`;
      } else {
        query += ` ORDER BY created_at DESC`;
      }

      // Add pagination
      const offset = (Number(page) - 1) * Number(limit);
      query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
      params.push(Number(limit), offset);

      // Execute query
      const result = await this.pool.query(query, params);

      // Get total count
      const countResult = await this.pool.query(
        `SELECT COUNT(*) as total FROM "${tableName}" WHERE tenant_id = $1`,
        [tenantId]
      );

      res.json({
        success: true,
        data: {
          rows: result.rows,
          pagination: {
            total: parseInt(countResult.rows[0].total),
            page: Number(page),
            limit: Number(limit),
            pages: Math.ceil(parseInt(countResult.rows[0].total) / Number(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Error fetching data:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch data',
      });
    }
  }

  /**
   * Insert row into custom table
   * POST /api/db-editor/data/:tableName
   */
  async insertData(req: Request, res: Response) {
    const { tableName } = req.params;
    const data = req.body;
    const tenantId = req.user.tenantId;
    const userId = req.user.id;

    try {
      await this.verifyTableOwnership(tableName, tenantId);

      // Add system fields
      data.tenant_id = tenantId;
      data.created_by = userId;

      // Build INSERT query
      const fields = Object.keys(data);
      const values = Object.values(data);
      const placeholders = fields.map((_, i) => `$${i + 1}`).join(', ');

      const query = `
        INSERT INTO "${tableName}" (${fields.map(f => `"${f}"`).join(', ')})
        VALUES (${placeholders})
        RETURNING *
      `;

      const result = await this.pool.query(query, values);

      res.json({
        success: true,
        data: result.rows[0],
      });
    } catch (error) {
      console.error('Error inserting data:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to insert data',
      });
    }
  }

  /**
   * Update row in custom table
   * PUT /api/db-editor/data/:tableName/:id
   */
  async updateData(req: Request, res: Response) {
    const { tableName, id } = req.params;
    const data = req.body;
    const tenantId = req.user.tenantId;

    try {
      await this.verifyTableOwnership(tableName, tenantId);

      // Remove system fields from update
      delete data.id;
      delete data.tenant_id;
      delete data.created_at;
      delete data.created_by;

      // Add updated_at
      data.updated_at = new Date().toISOString();

      // Build UPDATE query
      const fields = Object.keys(data);
      const values = Object.values(data);
      const setClause = fields.map((f, i) => `"${f}" = $${i + 1}`).join(', ');

      const query = `
        UPDATE "${tableName}"
        SET ${setClause}
        WHERE id = $${fields.length + 1} AND tenant_id = $${fields.length + 2}
        RETURNING *
      `;

      const result = await this.pool.query(query, [...values, id, tenantId]);

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Row not found',
        });
      }

      res.json({
        success: true,
        data: result.rows[0],
      });
    } catch (error) {
      console.error('Error updating data:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to update data',
      });
    }
  }

  /**
   * Delete row from custom table
   * DELETE /api/db-editor/data/:tableName/:id
   */
  async deleteData(req: Request, res: Response) {
    const { tableName, id } = req.params;
    const tenantId = req.user.tenantId;

    try {
      await this.verifyTableOwnership(tableName, tenantId);

      const result = await this.pool.query(
        `DELETE FROM "${tableName}" WHERE id = $1 AND tenant_id = $2 RETURNING id`,
        [id, tenantId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Row not found',
        });
      }

      res.json({
        success: true,
        message: 'Row deleted successfully',
      });
    } catch (error) {
      console.error('Error deleting data:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Failed to delete data',
      });
    }
  }

  private async verifyTableOwnership(tableName: string, tenantId: number): Promise<void> {
    const result = await this.pool.query(
      'SELECT id FROM custom_tables_registry WHERE table_name = $1 AND tenant_id = $2',
      [tableName, tenantId]
    );

    if (result.rows.length === 0) {
      throw new Error('Table not found or access denied');
    }
  }
}
```

---

## 🔄 Dynamic API Generation

### Auto-Generated Endpoints

Quando un utente crea una tabella `custom_contacts`, il sistema genera automaticamente:

```
GET    /api/custom/contacts           # List all contacts
GET    /api/custom/contacts/:id       # Get contact by ID
POST   /api/custom/contacts           # Create contact
PUT    /api/custom/contacts/:id       # Update contact
DELETE /api/custom/contacts/:id       # Delete contact
```

### Dynamic Router Implementation

```typescript
/**
 * Dynamic API router generator
 * src/routes/dynamicAPIRouter.ts
 */

export async function setupDynamicRoutes(app: Express, pool: Pool) {
  // Fetch all custom tables with API enabled
  const result = await pool.query(`
    SELECT table_name, api_prefix, permissions, schema_config
    FROM custom_tables_registry
    WHERE api_enabled = true
  `);

  for (const table of result.rows) {
    const { table_name, api_prefix, permissions, schema_config } = table;
    const basePath = api_prefix || `/api/custom/${table_name.replace('custom_', '')}`;

    // GET /api/custom/:resource
    app.get(basePath, checkPermission(permissions, 'read'), async (req, res) => {
      const controller = new DataOperationsController(pool);
      req.params.tableName = table_name;
      await controller.getData(req, res);
    });

    // GET /api/custom/:resource/:id
    app.get(`${basePath}/:id`, checkPermission(permissions, 'read'), async (req, res) => {
      const { id } = req.params;
      const tenantId = req.user.tenantId;

      try {
        const result = await pool.query(
          `SELECT * FROM "${table_name}" WHERE id = $1 AND tenant_id = $2`,
          [id, tenantId]
        );

        if (result.rows.length === 0) {
          return res.status(404).json({ success: false, error: 'Not found' });
        }

        res.json({ success: true, data: result.rows[0] });
      } catch (error) {
        res.status(500).json({ success: false, error: 'Internal server error' });
      }
    });

    // POST /api/custom/:resource
    app.post(basePath, checkPermission(permissions, 'create'), async (req, res) => {
      const controller = new DataOperationsController(pool);
      req.params.tableName = table_name;
      await controller.insertData(req, res);
    });

    // PUT /api/custom/:resource/:id
    app.put(`${basePath}/:id`, checkPermission(permissions, 'update'), async (req, res) => {
      const controller = new DataOperationsController(pool);
      req.params.tableName = table_name;
      await controller.updateData(req, res);
    });

    // DELETE /api/custom/:resource/:id
    app.delete(`${basePath}/:id`, checkPermission(permissions, 'delete'), async (req, res) => {
      const controller = new DataOperationsController(pool);
      req.params.tableName = table_name;
      await controller.deleteData(req, res);
    });

    console.log(`✅ Dynamic API routes registered for ${table_name} at ${basePath}`);
  }
}

/**
 * Permission checker middleware
 */
function checkPermission(permissions: any, action: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    const userRole = req.user.role;

    if (!permissions || !permissions[action]) {
      return next(); // No restrictions
    }

    const allowedRoles = permissions[action];
    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions',
      });
    }

    next();
  };
}
```

---

## 🚀 Integration with Shell

### Service Registration

```typescript
// app-shell-frontend/src/lib/services.config.ts

export const services = [
  // ... existing services ...

  {
    id: 'database-editor',
    name: 'Database Editor',
    description: 'Visual database editor for creating custom tables and APIs',
    url: 'http://localhost:3950',
    icon: '🗄️',
    category: 'admin',
    roles: ['OWNER', 'PLATFORM_ADMIN', 'TENANT_ADMIN'],
    isNew: true,
    featured: true,
  },
];
```

### PM2 Configuration

```javascript
// ecosystem.macstudio.config.cjs

{
  name: 'app-database-editor',
  script: 'npm',
  args: 'run dev',
  cwd: './app-database-editor',
  env: {
    NODE_ENV: 'development',
    PORT: 3950,
    VITE_API_BASE_URL: 'http://localhost:5950',
  },
  max_memory_restart: '500M',
},
{
  name: 'svc-database-editor',
  script: 'npx',
  args: 'tsx src/index.ts',
  cwd: './svc-database-editor',
  env: {
    NODE_ENV: 'development',
    PORT: 5950,
    DATABASE_URL: 'postgresql://postgres:password@localhost:5432/ewh_tenant',
  },
  max_memory_restart: '300M',
  wait_ready: true,
  listen_timeout: 10000,
},
```

---

## 📋 Implementation Checklist

### Phase 1: Backend Foundation (Week 1)
- [ ] Create `svc-database-editor` service structure
- [ ] Implement `SchemaManagementController`
- [ ] Implement `DataOperationsController`
- [ ] Create database tables (custom_tables_registry, custom_views, etc.)
- [ ] Add dynamic API router
- [ ] Write unit tests

### Phase 2: Frontend Core (Week 2)
- [ ] Create `app-database-editor` frontend structure
- [ ] Implement `SchemaDesigner` component
- [ ] Implement `DataEditor` component (spreadsheet view)
- [ ] Create API client and hooks
- [ ] Add form validation

### Phase 3: Advanced Features (Week 3)
- [ ] Implement `RelationshipManager` with ER diagram
- [ ] Implement `QueryBuilder` (visual SQL)
- [ ] Implement `APIBuilder` (auto-documentation)
- [ ] Add CSV/JSON import/export
- [ ] Add custom views

### Phase 4: Polish & Integration (Week 4)
- [ ] Register in Shell (services.config.ts)
- [ ] Add PM2 configuration
- [ ] Write comprehensive documentation
- [ ] Add example templates
- [ ] E2E testing
- [ ] Performance optimization

---

## 🎯 Key Differentiators vs Competitors

### vs PHPMyAdmin
- ✅ Modern UI/UX (React-based)
- ✅ No-code interface
- ✅ Auto-generated APIs
- ✅ Built-in permissions

### vs Xano
- ✅ Self-hosted (no vendor lock-in)
- ✅ Open-source
- ✅ Integrated with EWH platform
- ✅ PostgreSQL (not proprietary DB)

### vs NocoDB
- ✅ Deeper EWH integration
- ✅ Tenant-aware by default
- ✅ Automatic API documentation
- ✅ Built-in workflow engine integration

---

## 🔒 Security Considerations

1. **SQL Injection Prevention**: All dynamic queries use parameterized statements
2. **Table Name Validation**: Only alphanumeric + underscore allowed
3. **Tenant Isolation**: All queries filter by `tenant_id`
4. **Permission Checks**: Role-based access control on all endpoints
5. **Audit Logging**: All schema changes logged in `settings_audit`
6. **Rate Limiting**: API endpoints have configurable rate limits

---

## 📖 User Documentation

### Creating Your First Custom Table

1. Navigate to **Database Editor** in the Shell admin menu
2. Click **"Create Table"**
3. Enter table details:
   - Name: "Contacts"
   - Description: "Customer contact information"
4. Add columns:
   - `email` (Text, Required, Unique)
   - `name` (Text, Required)
   - `phone` (Text)
   - `company_id` (Relation → Companies)
5. Click **"Create"**
6. Your API is now available at `/api/custom/contacts` 🎉

### Importing Data from CSV

1. Open the table in **Data Editor**
2. Click **"Import"** button
3. Select CSV file
4. Map columns to table fields
5. Review preview
6. Click **"Import Data"**

---

**Questo documento è OBBLIGATORIO per implementare il Database Editor visuale.**

**Non creare editor DB custom senza seguire questa specifica.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team
