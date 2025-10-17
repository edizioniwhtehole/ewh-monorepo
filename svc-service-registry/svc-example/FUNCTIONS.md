# Function Index - svc-example

**Service**: svc-example (Example Service)
**Version**: 1.0.0
**Port**: 5100
**Type**: Backend Service
**Last Updated**: 2025-10-15

## Overview
Complete reference implementation demonstrating all platform standards: PM2 auto-restart, health checks, service registry integration, tenant isolation, structured logging.

---

## 📁 src/index.ts (Main Entry Point)

### Application Initialization
**Purpose**: Express app setup with all middleware
**Dependencies**: express, cors, helmet, pino-http
**Exports**: app, server
**Features**:
- CORS enabled
- Helmet security
- JSON body parsing
- Request logging (Pino)
- Error handling

### Graceful Shutdown Handler
**Function**: `gracefulShutdown(signal: string)`
**Purpose**: Clean service shutdown
**Process**:
1. Stop service registry heartbeat
2. Unregister from service registry
3. Close HTTP server
4. Exit process
**Timeout**: 10 seconds force shutdown

---

## 📁 src/config.ts

### Configuration Object
**Export**: `config`
**Purpose**: Centralized environment configuration
**Sections**:
- `port`: Service port (default: 5100)
- `nodeEnv`: Environment (development/production)
- `db`: Database connection settings
- `serviceRegistry`: Registry URL
- `logging`: Log level configuration
- `service`: Service metadata (id, name, version)

---

## 📁 src/logger.ts

### Logger Instance
**Export**: `logger`
**Purpose**: Structured logging with Pino
**Features**:
- Pretty printing in development
- JSON logs in production
- Service metadata in all logs
**Base Fields**: service, version

---

## 📁 src/controllers/healthController.ts

### `healthCheck(req, res)`
**HTTP**: `GET /health`
**Auth**: None (public)
**Purpose**: Service health status
**Returns**:
```json
{
  "status": "healthy" | "degraded" | "unhealthy",
  "timestamp": "ISO 8601",
  "uptime": 123,
  "service": { "id", "name", "version" },
  "dependencies": {
    "database": "healthy" | "unhealthy",
    "serviceRegistry": "healthy" | "unhealthy"
  }
}
```
**Status Codes**:
- 200: Healthy
- 503: Degraded or unhealthy
- 500: Health check error

### `resetStartTime()`
**Purpose**: Reset uptime counter (called on server start)

---

## 📁 src/controllers/exampleController.ts

### `listItems(req, res)`
**HTTP**: `POST /api/v1/items`
**Auth**: Required (tenant context)
**Headers**: `x-tenant-id`, `x-user-id`
**Purpose**: List all items for tenant
**Returns**:
```json
{
  "success": true,
  "data": [ExampleItem],
  "meta": { "total": 10 }
}
```
**Tenant Isolation**: ✅ Automatic

### `getItem(req, res)`
**HTTP**: `GET /api/v1/items/:id`
**Auth**: Required (tenant context)
**Headers**: `x-tenant-id`
**Params**: `id` (item ID)
**Purpose**: Get single item by ID
**Returns**: `{ success: true, data: ExampleItem }`
**Errors**: 404 if not found or wrong tenant

### `createItem(req, res)`
**HTTP**: `POST /api/v1/items`
**Auth**: Required (tenant context)
**Headers**: `x-tenant-id`, `x-user-id`
**Body**:
```json
{
  "name": "string (required)",
  "description": "string (optional)"
}
```
**Purpose**: Create new item
**Returns**: `{ success: true, data: ExampleItem }` (201)
**Validation**: Name is required
**Tenant Isolation**: ✅ Automatic

### `updateItem(req, res)`
**HTTP**: `PUT /api/v1/items/:id`
**Auth**: Required (tenant context)
**Headers**: `x-tenant-id`
**Params**: `id` (item ID)
**Body**:
```json
{
  "name": "string (optional)",
  "description": "string (optional)"
}
```
**Purpose**: Update existing item
**Returns**: `{ success: true, data: ExampleItem }`
**Errors**: 404 if not found or wrong tenant
**Tenant Isolation**: ✅ Automatic

### `deleteItem(req, res)`
**HTTP**: `DELETE /api/v1/items/:id`
**Auth**: Required (tenant context)
**Headers**: `x-tenant-id`
**Params**: `id` (item ID)
**Purpose**: Delete item
**Returns**: `{ success: true, message: "Item deleted" }`
**Errors**: 404 if not found or wrong tenant
**Tenant Isolation**: ✅ Automatic

---

## 📁 src/middleware/errorHandler.ts

### `AppError` Class
**Purpose**: Operational error class
**Properties**:
- `statusCode`: HTTP status code
- `message`: Error message
- `isOperational`: true for expected errors

### `errorHandler(err, req, res, next)`
**Purpose**: Global error handling middleware
**Behavior**:
- Operational errors (AppError): Return status + message
- Unexpected errors: Log and return 500
**Logging**: All errors logged with context

---

## 📁 src/middleware/tenantContext.ts

### `AuthenticatedRequest` Interface
**Extends**: Express Request
**Added Properties**:
- `user`: User object (id, email, tenant_id, role)
- `tenant_id`: Current tenant ID

### `extractTenantContext(req, res, next)`
**Purpose**: Extract and validate tenant context
**Headers Required**: `x-tenant-id`
**Headers Optional**: `x-user-id`, `x-user-email`, `x-user-role`
**Errors**: 400 if tenant_id missing
**Note**: In production, validates JWT token

---

## 📁 src/services/serviceRegistry.ts

### `ServiceRegistryClient` Class

#### `constructor()`
**Purpose**: Initialize registry client with service metadata

#### `register()`
**Purpose**: Register service with registry
**HTTP**: `POST {registry}/api/v1/services/register`
**Body**: ServiceRegistration object
**Retry**: Logs warning on failure, continues
**Timeout**: 5 seconds

#### `unregister()`
**Purpose**: Unregister service from registry
**HTTP**: `DELETE {registry}/api/v1/services/{serviceId}`
**Timeout**: 5 seconds

#### `startHeartbeat(intervalMs = 30000)`
**Purpose**: Start periodic re-registration
**Behavior**:
1. Register immediately
2. Re-register every 30 seconds
**Use**: Keeps service visible in shell

#### `stopHeartbeat()`
**Purpose**: Stop periodic re-registration
**Use**: Called during graceful shutdown

---

## 📁 src/routes/index.ts

### `createRouter()`
**Purpose**: Create Express router with all routes
**Routes**:
- `GET /health` - Public health check
- `GET /api/v1/items` - List items (protected)
- `GET /api/v1/items/:id` - Get item (protected)
- `POST /api/v1/items` - Create item (protected)
- `PUT /api/v1/items/:id` - Update item (protected)
- `DELETE /api/v1/items/:id` - Delete item (protected)

**Middleware**:
- `/api/v1/*` routes require tenant context

---

## 📁 src/types/index.ts

### Type Definitions

**HealthCheckResponse**: Health check response structure
**ExampleItem**: Item entity structure
**CreateExampleItemDTO**: Item creation request
**UpdateExampleItemDTO**: Item update request

---

## 🔧 Configuration Files

### ecosystem.config.cjs (PM2)
**Purpose**: PM2 process configuration
**Features**:
- Auto-restart on crash (max 10 restarts)
- Min uptime 10s before considering stable
- Memory limit 500MB
- Health check every 30s
- Graceful shutdown (5s timeout)
- Logs to ./logs/

### package.json
**Scripts**:
- `pnpm dev` - Development with tsx watch
- `pnpm build` - TypeScript compilation
- `pnpm start` - Production start
- `pnpm lint` - ESLint
- `pnpm test` - Jest tests

---

## 📊 Platform Standards Compliance

✅ **PM2 Configuration**
- Auto-restart: Yes
- Health checks: Yes
- Memory limits: Yes (500MB)
- Graceful shutdown: Yes

✅ **Health Check**
- Endpoint: /health
- Dependencies check: Yes
- Status codes: 200/503/500

✅ **Service Registry**
- Auto-registration: Yes
- Heartbeat: Every 30s
- Auto-unregister: Yes

✅ **Logging**
- Structured: Yes (Pino)
- Request logging: Yes
- Error logging: Yes

✅ **Tenant Isolation**
- Middleware: Yes
- All queries filtered: Yes

✅ **Error Handling**
- Global handler: Yes
- Operational vs unexpected: Yes
- Proper logging: Yes

---

## 🚀 Usage Examples

```bash
# Start with PM2
pm2 start ecosystem.config.cjs

# Check health
curl http://localhost:5100/health

# Create item
curl -X POST http://localhost:5100/api/v1/items \
  -H "Content-Type: application/json" \
  -H "x-tenant-id: tenant-123" \
  -H "x-user-id: user-456" \
  -d '{"name":"Test Item"}'

# List items
curl http://localhost:5100/api/v1/items \
  -H "x-tenant-id: tenant-123"
```

---

**Note**: This service is a reference implementation. Copy this pattern for new services.
