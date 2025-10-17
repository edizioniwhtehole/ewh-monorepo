# 🔌 svc-box-designer - API Standards

**Service Name:** svc-box-designer
**Port:** 3800 (backend)
**Version:** 2.0.0
**Follows:** [API_FIRST_ARCHITECTURE.md](../API_FIRST_ARCHITECTURE.md)

---

## 📡 API ENDPOINTS

### Base URL
```
Development: http://localhost:3800
Gateway:     http://localhost:5000/api/box-designer
Production:  https://api.ewh.app/box-designer
```

---

## 🎨 CAD DRAWINGS API

### Drawings Management

#### Create Drawing
```http
POST /api/cad/drawings
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
  "name": "My Drawing",
  "description": "Optional description",
  "data": {
    "version": "2.0",
    "objects": [...],
    "layers": [...],
    "settings": {...}
  }
}

Response 201:
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "My Drawing",
    "created_at": "2025-10-16T10:00:00Z",
    "updated_at": "2025-10-16T10:00:00Z"
  }
}
```

#### List Drawings
```http
GET /api/cad/drawings
Authorization: Bearer {token}

Query params:
  - limit: number (default 50, max 100)
  - offset: number (default 0)
  - sort: string (created_at, updated_at, name)
  - order: string (asc, desc)
  - search: string (search in name/description)

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Drawing 1",
      "thumbnail_url": "https://...",
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "pagination": {
    "total": 42,
    "limit": 50,
    "offset": 0,
    "has_more": false
  }
}
```

#### Get Drawing
```http
GET /api/cad/drawings/:id
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "My Drawing",
    "description": "...",
    "data": {
      "version": "2.0",
      "objects": [...],
      "layers": [...]
    },
    "metadata": {
      "object_count": 125,
      "layer_count": 5
    },
    "created_at": "...",
    "updated_at": "..."
  }
}
```

#### Update Drawing
```http
PUT /api/cad/drawings/:id
Authorization: Bearer {token}

Request:
{
  "name": "Updated name",
  "data": {...}
}

Response 200:
{
  "success": true,
  "data": {...}
}
```

#### Delete Drawing
```http
DELETE /api/cad/drawings/:id
Authorization: Bearer {token}

Response 204: No Content
```

---

## 📦 PACKAGING TEMPLATES API

### Templates Library

#### List Templates
```http
GET /api/packaging/templates
Authorization: Bearer {token}

Query params:
  - category: string (box, tray, display, custom)
  - fefco_code: string (0201, 0215, 0427, etc.)
  - search: string

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "4-Corner Box",
      "category": "box",
      "fefco_code": "0201",
      "thumbnail_url": "...",
      "parameters": [
        {"name": "length", "type": "number", "min": 50, "max": 1000, "default": 200},
        {"name": "width", "type": "number", ...},
        {"name": "height", "type": "number", ...}
      ]
    }
  ]
}
```

#### Get Template
```http
GET /api/packaging/templates/:id
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "4-Corner Box",
    "description": "...",
    "fefco_code": "0201",
    "parameters": [...],
    "dieline_generator": {
      "algorithm": "4_corner_box_v1",
      "version": "1.0"
    }
  }
}
```

#### Generate Dieline from Template
```http
POST /api/packaging/templates/:id/generate
Authorization: Bearer {token}

Request:
{
  "parameters": {
    "length": 200,
    "width": 150,
    "height": 100
  },
  "options": {
    "include_dimensions": true,
    "include_guides": true
  }
}

Response 200:
{
  "success": true,
  "data": {
    "dieline": {
      "version": "2.0",
      "objects": [...],
      "layers": [...],
      "metadata": {
        "flat_width": 450,
        "flat_height": 350,
        "area_cm2": 1575
      }
    }
  }
}
```

---

## 🎬 3D PREVIEW API

### 3D Folding

#### Generate 3D Model
```http
POST /api/cad/3d/fold
Authorization: Bearer {token}

Request:
{
  "drawing_id": "uuid",
  "options": {
    "fold_all": true,
    "animation": false
  }
}

Response 200:
{
  "success": true,
  "data": {
    "model_url": "https://cdn.../model.glb",
    "thumbnail_url": "https://cdn.../thumb.png",
    "metadata": {
      "faces": 24,
      "vertices": 48
    }
  }
}
```

---

## 📐 CALCULATIONS API

### Geometric Calculations

#### Calculate Flat Size
```http
POST /api/packaging/calculate/flat-size
Authorization: Bearer {token}

Request:
{
  "dimensions": {
    "length": 200,
    "width": 150,
    "height": 100
  },
  "material_thickness": 1.5,
  "box_type": "4_corner"
}

Response 200:
{
  "success": true,
  "data": {
    "flat_width": 450,
    "flat_height": 350,
    "area_cm2": 1575,
    "area_m2": 0.1575
  }
}
```

#### Calculate Material Weight
```http
POST /api/packaging/calculate/weight
Authorization: Bearer {token}

Request:
{
  "area_m2": 0.1575,
  "material_weight_gsm": 450
}

Response 200:
{
  "success": true,
  "data": {
    "weight_grams": 70.875
  }
}
```

#### Calculate Cost
```http
POST /api/packaging/calculate/cost
Authorization: Bearer {token}

Request:
{
  "area_m2": 0.1575,
  "material_cost_per_m2": 2.50,
  "die_cost": 150,
  "print_cost": 0.05,
  "quantity": 1000
}

Response 200:
{
  "success": true,
  "data": {
    "material_cost": 393.75,
    "die_cost": 150,
    "print_cost": 50,
    "total_cost": 593.75,
    "cost_per_unit": 0.59375
  }
}
```

---

## 📤 EXPORT API

### Export Drawings

#### Export DXF
```http
POST /api/cad/export/dxf
Authorization: Bearer {token}

Request:
{
  "drawing_id": "uuid",
  "options": {
    "version": "AutoCAD 2010",
    "units": "millimeters",
    "layer_mode": "by_type"
  }
}

Response 200:
{
  "success": true,
  "data": {
    "file_url": "https://cdn.../drawing.dxf",
    "expires_at": "2025-10-17T10:00:00Z"
  }
}
```

#### Export SVG
```http
POST /api/cad/export/svg
Authorization: Bearer {token}

Request:
{
  "drawing_id": "uuid",
  "options": {
    "include_dimensions": true,
    "stroke_width": 0.5
  }
}

Response 200:
{
  "success": true,
  "data": {
    "file_url": "https://cdn.../drawing.svg",
    "expires_at": "..."
  }
}
```

#### Export PDF
```http
POST /api/cad/export/pdf
Authorization: Bearer {token}

Request:
{
  "drawing_id": "uuid",
  "options": {
    "page_size": "A4",
    "scale": 1.0,
    "include_dimensions": true
  }
}

Response 200:
{
  "success": true,
  "data": {
    "file_url": "https://cdn.../drawing.pdf",
    "expires_at": "..."
  }
}
```

---

## 📊 NESTING API

### Nesting Optimizer

#### Optimize Layout
```http
POST /api/packaging/nesting/optimize
Authorization: Bearer {token}

Request:
{
  "items": [
    {"drawing_id": "uuid1", "quantity": 100},
    {"drawing_id": "uuid2", "quantity": 50}
  ],
  "sheet_size": {
    "width": 1050,
    "height": 750
  },
  "options": {
    "algorithm": "skyline",
    "allow_rotation": true,
    "spacing": 2,
    "margin": 5
  }
}

Response 200:
{
  "success": true,
  "data": {
    "layout_url": "https://cdn.../layout.svg",
    "sheets_required": 8,
    "efficiency": 0.87,
    "waste_percentage": 13,
    "items_per_sheet": [
      {"sheet": 1, "items": 18},
      {"sheet": 2, "items": 18},
      ...
    ]
  }
}
```

---

## 🎯 MATERIALS DATABASE API

### Materials

#### List Materials
```http
GET /api/packaging/materials
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Cartone ondulato E",
      "type": "corrugated",
      "thickness_mm": 1.5,
      "weight_gsm": 450,
      "cost_per_m2": 2.50,
      "properties": {
        "strength": "medium",
        "printability": "good"
      }
    }
  ]
}
```

---

## 🔧 MACHINES DATABASE API

### Machines

#### List Machines
```http
GET /api/packaging/machines
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "BOBST Novacut 106",
      "type": "die_cutter",
      "manufacturer": "BOBST",
      "sheet_size_max": {
        "width": 1060,
        "height": 760
      },
      "gripper_margin": 10,
      "speed_sheets_per_hour": 6000
    }
  ]
}
```

---

## 🔔 WEBHOOKS

### Outgoing Webhooks

Configurabili da UI `/settings/webhooks`

#### Events
- `drawing.created` - Disegno creato
- `drawing.updated` - Disegno aggiornato
- `drawing.deleted` - Disegno eliminato
- `export.completed` - Export completato
- `nesting.completed` - Nesting completato

#### Payload Example
```json
{
  "event": "drawing.created",
  "timestamp": "2025-10-16T10:00:00Z",
  "tenant_id": "uuid",
  "data": {
    "drawing_id": "uuid",
    "drawing_name": "My Drawing",
    "created_by": "user_uuid"
  }
}
```

---

## 🌍 INTERNATIONALIZATION

### Supported Languages
- Italian (it) - Default
- English (en)
- French (fr)
- German (de)

### Usage
```http
GET /api/cad/drawings
Authorization: Bearer {token}
Accept-Language: it

Response includes translated strings:
{
  "success": true,
  "message": "Disegni caricati con successo",
  "data": [...]
}
```

---

## ⚙️ SETTINGS API

### Tenant Settings
```http
GET /api/settings/tenant
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "default_units": "mm",
    "default_material": "cartone_ondulato_e",
    "default_sheet_size": {"width": 1050, "height": 750},
    "export_formats_enabled": ["dxf", "svg", "pdf"],
    "features": {
      "3d_preview": true,
      "nesting": true,
      "cost_calculation": true
    }
  }
}
```

```http
PUT /api/settings/tenant
Authorization: Bearer {token}

Request:
{
  "default_units": "inches",
  "features": {
    "3d_preview": false
  }
}

Response 200: {...}
```

### User Settings
```http
GET /api/settings/user
GET /api/settings/user

PUT /api/settings/user
```

---

## 🏥 HEALTH CHECK

```http
GET /health

Response 200:
{
  "status": "healthy",
  "timestamp": "2025-10-16T10:00:00Z",
  "service": "svc-box-designer",
  "version": "2.0.0",
  "uptime_seconds": 3600,
  "dependencies": {
    "database": "healthy",
    "redis": "healthy"
  }
}
```

---

## 📄 OPENAPI SPEC

Available at:
- `/dev` - HTML documentation
- `/dev/openapi.json` - OpenAPI 3.0 JSON
- `/dev/openapi.yaml` - OpenAPI 3.0 YAML

---

## 🔐 AUTHENTICATION

All endpoints require JWT Bearer token except:
- `/health`
- `/dev`

### Token Format
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Token Payload
```json
{
  "userId": "uuid",
  "tenantId": "uuid",
  "role": "owner|admin|user",
  "exp": 1234567890
}
```

---

## 📊 RATE LIMITING

- 100 requests / minute per user
- 1000 requests / minute per tenant
- Export endpoints: 10 / minute

Response when rate limited:
```http
HTTP 429 Too Many Requests
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "retry_after": 60
  }
}
```

---

## ❌ ERROR CODES

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {...}
  }
}
```

### Common Codes
- `UNAUTHORIZED` - Missing/invalid token (401)
- `FORBIDDEN` - No permission (403)
- `NOT_FOUND` - Resource not found (404)
- `VALIDATION_ERROR` - Invalid input (400)
- `RATE_LIMIT_EXCEEDED` - Too many requests (429)
- `INTERNAL_ERROR` - Server error (500)

---

## 📚 DATA MODELS

### Drawing Object
```typescript
interface Drawing {
  id: string;
  tenant_id: string;
  name: string;
  description?: string;
  data: {
    version: string;
    objects: CADObject[];
    layers: Layer[];
    settings: Settings;
  };
  metadata: {
    object_count: number;
    layer_count: number;
  };
  thumbnail_url?: string;
  created_at: string;
  updated_at: string;
}
```

### CAD Object
```typescript
interface CADObject {
  id: string;
  type: 'line' | 'circle' | 'arc' | 'rectangle' | 'polygon' | 'spline' | 'text';
  layer_id: string;
  properties: {
    // Varies by type
    // Line: p1, p2
    // Circle: center, radius
    // etc.
  };
  style: {
    stroke_color: string;
    stroke_width: number;
    fill_color?: string;
    line_type: 'solid' | 'dashed' | 'dotted';
  };
}
```

### Layer
```typescript
interface Layer {
  id: string;
  name: string;
  color: string;
  line_type: 'cut' | 'crease' | 'perforation' | 'bleed' | 'dimension' | 'custom';
  line_width: number;
  visible: boolean;
  locked: boolean;
  printable: boolean;
}
```

---

**Documento:** `API_STANDARDS.md`
**Seguire:** [DEVELOPMENT_STANDARDS_2025.md](../DEVELOPMENT_STANDARDS_2025.md)
