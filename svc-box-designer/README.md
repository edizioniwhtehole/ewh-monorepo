# Box Designer Service (svc-box-designer)

Enterprise backend service for parametric box design, die-line generation, and nesting optimization.

## Features

- **Parametric Box Design**: Support for rectangular boxes, truncated pyramids, and custom shapes
- **FEFCO Standards**: Industry-standard box templates (FEFCO 0201, Tuck End Boxes, etc.)
- **Geometry Calculations**: Automatic volume, area, and weight calculations
- **Die-line Generation**: Production-ready die-cutting templates
- **Nesting Optimization**: Material usage optimization with real machine constraints
- **Multi-tenancy**: Full tenant isolation with role-based access control
- **Project Management**: Versioning, collaboration, and workflow support
- **REST API**: Complete API-first architecture
- **Export Formats**: SVG, PDF, DXF, AI, PLT

## Quick Start

### Development

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your database credentials

# Run database migration
psql -U postgres -d ewh_platform -f ../migrations/080_box_designer_system.sql

# Start development server
npm run dev
```

The service will be available at `http://localhost:5850`

### Production

```bash
# Build TypeScript
npm run build

# Start production server
npm start
```

### Docker

```bash
# Build Docker image
docker build -t ewh/svc-box-designer:latest .

# Run container
docker run -p 5850:5850 \
  -e DB_HOST=postgres \
  -e DB_NAME=ewh_platform \
  -e DB_USER=postgres \
  -e DB_PASSWORD=yourpassword \
  -e JWT_SECRET=your-secret \
  ewh/svc-box-designer:latest
```

## API Endpoints

### Health & Info

- `GET /health` - Health check
- `GET /` - Service info

### Projects

- `GET /api/box/projects` - List projects
- `GET /api/box/projects/:id` - Get project
- `POST /api/box/projects` - Create project
- `PUT /api/box/projects/:id` - Update project
- `DELETE /api/box/projects/:id` - Delete project
- `POST /api/box/projects/:id/duplicate` - Duplicate project
- `GET /api/box/projects/:id/versions` - Get version history

### Calculations

- `POST /api/box/calculate/geometry` - Calculate volume, area, weight
- `POST /api/box/calculate/dieline` - Generate die-line template
- `POST /api/box/calculate/nesting` - Calculate nesting efficiency
- `POST /api/box/validate` - Validate box configuration

### Coming Soon

- `/api/box/templates` - Template library
- `/api/box/quotes` - Quote generation
- `/api/box/orders` - Order management
- `/api/box/machines` - Machine management
- `/api/box/export` - Async export jobs

## Authentication

All API endpoints require JWT authentication via Bearer token:

```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:5850/api/box/projects
```

## Example: Create a Project

```bash
curl -X POST http://localhost:5850/api/box/projects \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Shipping Box 300x200x150",
    "description": "Standard shipping box",
    "box_config": {
      "name": "Standard Box",
      "shape": "rectangular",
      "dimensions": {
        "baseWidth": 300,
        "baseLength": 200,
        "topWidth": 300,
        "topLength": 200,
        "height": 150
      },
      "material": {
        "name": "Corrugated E",
        "type": "corrugated_e",
        "thickness": 1.5,
        "weight": 450,
        "rigidity": "medium"
      },
      "bottomType": "simple",
      "topType": "simple",
      "gluingFlaps": {
        "enabled": true,
        "width": 25
      },
      "bleed": {
        "enabled": true,
        "width": 3
      }
    }
  }'
```

## Configuration

Key environment variables:

```env
# Service
PORT=5850
NODE_ENV=production

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ewh_platform
DB_USER=postgres
DB_PASSWORD=yourpassword

# Authentication
JWT_SECRET=your-secret-key

# Service URLs
DAM_SERVICE_URL=http://svc-dam:5100
CRM_SERVICE_URL=http://svc-crm-unified:6200
APPROVALS_SERVICE_URL=http://svc-approvals:5950

# Limits
MAX_PROJECTS_PER_TENANT=100
MAX_DIMENSION_MM=3000
```

## Architecture

```
svc-box-designer/
├── src/
│   ├── controllers/        # Request handlers
│   │   ├── projects.controller.ts
│   │   ├── calculations.controller.ts
│   │   └── ...
│   ├── services/           # Business logic
│   │   ├── geometry.service.ts
│   │   ├── dieline.service.ts
│   │   ├── nesting.service.ts
│   │   └── ...
│   ├── routes/             # Route definitions
│   ├── middleware/         # Auth, validation, etc.
│   ├── models/             # Data models
│   ├── types/              # TypeScript types
│   ├── db/                 # Database connection
│   └── index.ts            # Application entry point
├── package.json
├── tsconfig.json
├── Dockerfile
└── README.md
```

## Database Schema

See `migrations/080_box_designer_system.sql` for complete schema:

- `box_projects` - Box design projects
- `box_project_versions` - Version history
- `box_templates` - Reusable templates
- `box_machines` - Production machines
- `box_quotes` - Customer quotes
- `box_orders` - Production orders
- `box_export_jobs` - Async export jobs
- `box_design_metrics` - Analytics

## Development

```bash
# Run tests
npm test

# Lint code
npm run lint

# Type check
npm run build
```

## Contributing

See main project CONTRIBUTING.md

## License

MIT License - See LICENSE file

---

**EWH Platform** - Enterprise Web Hub
Box Designer Service v1.0.0
