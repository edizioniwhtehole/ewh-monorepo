# EWH Platform - Port Allocation

Complete port allocation for all services in the EWH Platform.

## Core Services

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 3150 | Frontend | Shell | `app-shell-frontend` | ✅ Running |
| 3600 | Frontend | Admin Console | `app-admin-frontend` | ✅ Ready |
| 4001 | Backend | Authentication | `svc-auth` | ✅ Running |
| 5432 | Database | PostgreSQL | `postgres` | ✅ Running |

## Project Management

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 5400 | Frontend | PM Dashboard | `app-pm-frontend` | ✅ Ready |
| 5401 | Backend | PM Service | `svc-pm` | ✅ Ready |

## Media & DAM

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 3300 | Frontend | DAM Library | `app-dam` | ✅ Ready |
| 5200 | Frontend | Media Upload | `app-media-frontend` | ✅ Ready |
| 5201 | Backend | Media Service | `svc-media` | ✅ Ready |

## Approvals & Workflow

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 5500 | Frontend | Approvals | `app-approvals-frontend` | ✅ Ready |
| 5501 | Backend | Approvals Service | `svc-approvals` | ✅ Ready |

## Design Tools

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 5101 | Frontend | Page Builder | `app-page-builder` | ✅ Ready |
| 3350 | Frontend | Box Designer | `app-box-designer` | ✅ Ready |
| 5800 | Backend | Previz Backend | `svc-previz` | ✅ Running |
| 5801 | Frontend | Previz Studio | `app-previz-frontend` | ✅ Running |
| 5850 | Frontend | Photo Editor | `app-photoediting` | ⚠️  Needs Setup |
| 5851 | Backend | Photo Editor Service | `svc-photo-editor` | ⚠️  Needs Setup |
| 5860 | Frontend | Raster Editor | `app-raster-editor` | ⚠️  Needs Setup |
| 5861 | Backend | Raster Service | `svc-raster-runtime` | ⚠️  Needs Setup |
| 5870 | Frontend | Video Editor | `app-video-editor` | ⚠️  Needs Setup |
| 5871 | Backend | Video Orchestrator | `svc-video-orchestrator` | ⚠️  Needs Setup |
| 5872 | Backend | Video Runtime | `svc-video-runtime` | ⚠️  Needs Setup |

## Business Operations

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 5700 | Frontend | Inventory | `app-inventory-frontend` | ✅ Ready |
| 5701 | Backend | Inventory Service | `svc-inventory` | ✅ Ready |
| 5750 | Frontend | Procurement | `app-procurement-frontend` | ✅ Ready |
| 5751 | Backend | Procurement Service | `svc-procurement` | ✅ Ready |
| 5900 | Frontend | Purchase Orders | `app-orders-purchase-frontend` | ✅ Ready |
| 5901 | Backend | Purchase Orders Service | `svc-orders-purchase` | ✅ Ready |
| 6000 | Frontend | Sales Orders | `app-orders-sales-frontend` | ✅ Ready |
| 6001 | Backend | Sales Orders Service | `svc-orders-sales` | ✅ Ready |
| 6100 | Frontend | Quotations | `app-quotations-frontend` | ✅ Ready |
| 6101 | Backend | Quotations Service | `svc-quotations` | ✅ Ready |

## Communications & CRM

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 5640 | Frontend | Phone System | `app-communications-client` | ✅ Ready |
| 5641 | Backend | Communications Service | `svc-communications` | ✅ Ready |
| 5642 | Backend | Voice Service | `svc-voice` | ✅ Ready |
| 3310 | Frontend | CRM | `app-crm-frontend` | ⚠️  Needs Setup |
| 3311 | Backend | CRM Service | `svc-crm-unified` | ✅ Ready |

## Content Management

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 5310 | Frontend | CMS Manager | `app-cms-frontend` | ⚠️  Needs Setup |
| 5311 | Backend | CMS Service | `svc-cms` | ⚠️  Needs Setup |
| 5320 | Frontend | Site Builder | `app-web-frontend` | ⚠️  Needs Setup |
| 5321 | Backend | Site Builder Service | `svc-site-builder` | ⚠️  Needs Setup |
| 5322 | Backend | Site Publisher | `svc-site-publisher` | ⚠️  Needs Setup |
| 5323 | Backend | Site Renderer | `svc-site-renderer` | ⚠️  Needs Setup |

## Workflow & Orchestration

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 5880 | Frontend | Workflow Editor | `app-workflow-editor` | ⚠️  Needs Setup |
| 5881 | Backend | Workflow Tracker | `svc-workflow-tracker` | ⚠️  Needs Setup |
| 5890 | Frontend | Orchestrator UI | `app-orchestrator-frontend` | ⚠️  Needs Setup |
| 5891 | Backend | API Orchestrator | `svc-api-orchestrator` | ⚠️  Needs Setup |

## Support Services

| Port | Type | Service | App/Service Name | Status |
|------|------|---------|------------------|--------|
| 4100 | Backend | API Gateway | `svc-api-gateway` | ⚠️  Needs Setup |
| 4200 | Backend | Search Service | `svc-search` | ⚠️  Needs Setup |
| 4300 | Backend | Billing Service | `svc-billing` | ⚠️  Needs Setup |
| 4400 | Backend | Metrics Collector | `svc-metrics-collector` | ⚠️  Needs Setup |
| 4500 | Backend | Job Worker | `svc-job-worker` | ⚠️  Needs Setup |

## Port Ranges

- **3000-3999**: Frontend applications (React/Next.js)
- **4000-4999**: Core backend services (Auth, Gateway, Infrastructure)
- **5000-5999**: Domain backend services (PM, Media, Business, etc.)
- **6000-6999**: Extended business services
- **5432**: PostgreSQL database
- **6379**: Redis (if used)
- **5672**: RabbitMQ (if used)

## Notes

- ✅ **Ready**: Service has dependencies and basic structure
- ✅ **Running**: Service is currently running
- ⚠️  **Needs Setup**: Requires template application and configuration
- All ports are configured to bind to `0.0.0.0` for network access
- Frontend apps use Vite dev server with HMR
- Backend services use Express.js with tsx watch for development
