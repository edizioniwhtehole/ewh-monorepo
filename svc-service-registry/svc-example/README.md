# svc-example - Reference Service

Complete reference implementation demonstrating all platform standards.

## Features

✅ **Platform Standards Compliant**
- PM2 configuration with auto-restart
- Health check endpoint
- Structured logging with Pino
- Graceful shutdown
- Service registry integration
- Tenant isolation
- Error handling

## Quick Start

```bash
# Install dependencies
pnpm install

# Copy environment file
cp .env.example .env

# Development (with auto-reload)
pnpm dev

# Or run with PM2 (production-like)
pm2 start ecosystem.config.cjs
pm2 logs svc-example
```

## API Endpoints

### Health Check
```bash
GET /health
# Returns service health status
```

### Items CRUD
```bash
# List items
GET /api/v1/items
Headers:
  x-tenant-id: <tenant-id>
  x-user-id: <user-id>

# Get item
GET /api/v1/items/:id
Headers:
  x-tenant-id: <tenant-id>

# Create item
POST /api/v1/items
Headers:
  x-tenant-id: <tenant-id>
  x-user-id: <user-id>
Body:
  {
    "name": "Example Item",
    "description": "Optional description"
  }

# Update item
PUT /api/v1/items/:id
Headers:
  x-tenant-id: <tenant-id>
Body:
  {
    "name": "Updated name"
  }

# Delete item
DELETE /api/v1/items/:id
Headers:
  x-tenant-id: <tenant-id>
```

## Architecture

```
svc-example/
├── src/
│   ├── controllers/       # Request handlers
│   │   ├── healthController.ts
│   │   └── exampleController.ts
│   ├── middleware/        # Express middleware
│   │   ├── errorHandler.ts
│   │   └── tenantContext.ts
│   ├── services/          # Business logic
│   │   └── serviceRegistry.ts
│   ├── routes/            # API routes
│   │   └── index.ts
│   ├── types/             # TypeScript types
│   │   └── index.ts
│   ├── config.ts          # Configuration
│   ├── logger.ts          # Logging setup
│   └── index.ts           # Entry point
├── ecosystem.config.cjs   # PM2 configuration
├── package.json
├── tsconfig.json
└── .env                   # Environment variables
```

## Service Registry Integration

The service automatically:
1. Registers itself on startup
2. Sends heartbeat every 30 seconds
3. Unregisters on graceful shutdown
4. Re-registers if it crashes and restarts

## PM2 Auto-Recovery

If the service crashes, PM2 will:
1. Automatically restart it (max 10 restarts)
2. Wait at least 10 seconds uptime before considering it stable
3. Delay 1 second between restarts
4. Restart if memory exceeds 500MB

Check PM2 status:
```bash
pm2 status
pm2 logs svc-example
pm2 restart svc-example
pm2 stop svc-example
```

## Testing

```bash
# Test health check
curl http://localhost:5100/health

# Test create item
curl -X POST http://localhost:5100/api/v1/items \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: tenant-123" \
  -H "x-user-id: user-456" \
  -d '{"name":"Test Item","description":"Testing"}'

# Test list items
curl http://localhost:5100/api/v1/items \
  -H "x-tenant-id: tenant-123"
```

## Platform Standards Compliance

- ✅ PM2 configuration with health checks
- ✅ Graceful shutdown handlers
- ✅ Structured logging (Pino)
- ✅ Health check endpoint
- ✅ Service registry integration
- ✅ Tenant isolation
- ✅ Error handling middleware
- ✅ TypeScript with strict types
- ✅ Environment configuration
- ✅ Auto-restart on crash

See [FUNCTIONS.md](./FUNCTIONS.md) for complete function index.
