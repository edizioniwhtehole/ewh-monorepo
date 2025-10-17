# 🗺️ API Endpoints Complete Map
## Mappa Completa di Tutti gli Endpoint della Piattaforma

**Data**: 15 Ottobre 2025
**Versione**: 1.0.0

---

## 📊 Panoramica

```
Total Endpoints: 150+
├── Platform Admin: 42 endpoints
├── Tenant Admin: 38 endpoints
├── User: 24 endpoints
├── Services: 46+ endpoints
└── Public: 8 endpoints
```

---

## 🏛️ PLATFORM ADMIN (OWNER / PLATFORM_ADMIN only)

### Base: `/api/admin/platform`

```
Platform Settings
├── GET    /settings                    # Get all platform settings
├── GET    /settings/:key               # Get specific setting
├── PUT    /settings/:key               # Create/update setting
├── DELETE /settings/:key               # Delete setting
└── GET    /settings/history/:key      # Get setting history

Service Registry
├── GET    /services                    # List all services
├── GET    /services/:id                # Get service details
├── POST   /services                    # Register new service
├── PUT    /services/:id                # Update service
├── DELETE /services/:id                # Delete service
├── POST   /services/:id/health         # Trigger health check
└── GET    /services/health             # Health status of all

Tenants Management
├── GET    /tenants                     # List all tenants
├── GET    /tenants/:id                 # Get tenant details
├── POST   /tenants                     # Create new tenant
├── PUT    /tenants/:id                 # Update tenant
├── DELETE /tenants/:id                 # Delete tenant
├── POST   /tenants/:id/suspend         # Suspend tenant
├── POST   /tenants/:id/activate        # Activate tenant
├── GET    /tenants/:id/users           # Get tenant users
├── GET    /tenants/:id/services        # Get tenant services
├── GET    /tenants/:id/usage           # Get tenant usage stats
└── GET    /tenants/:id/audit           # Get tenant audit logs

Analytics & Monitoring
├── GET    /analytics/stats             # Platform-wide statistics
├── GET    /analytics/usage             # Usage metrics
├── GET    /analytics/revenue           # Revenue analytics
├── GET    /analytics/services          # Service health metrics
├── GET    /analytics/tenants           # Tenant growth metrics
└── GET    /analytics/users             # User activity metrics

Billing & Payments (Platform Level)
├── GET    /billing/overview            # Revenue overview
├── GET    /billing/transactions        # All transactions
├── GET    /billing/failed-payments     # Failed payments
└── POST   /billing/retry-payment/:id   # Retry failed payment

System Configuration
├── GET    /system/info                 # System information
├── GET    /system/logs                 # System logs
├── POST   /system/maintenance          # Toggle maintenance mode
└── GET    /system/backups              # Database backups list

Visual Database Editor 🗄️ NEW!
├── GET    /db-editor/tables            # List all custom tables
├── GET    /db-editor/tables/:name      # Get table schema
├── POST   /db-editor/tables            # Create custom table
├── PUT    /db-editor/tables/:name      # Modify table schema
├── DELETE /db-editor/tables/:name      # Drop table
├── POST   /db-editor/tables/:name/columns       # Add column
├── PUT    /db-editor/tables/:name/columns/:col  # Modify column
├── DELETE /db-editor/tables/:name/columns/:col  # Drop column
├── POST   /db-editor/relationships     # Create foreign key
├── DELETE /db-editor/relationships/:id # Drop foreign key
├── GET    /db-editor/data/:name        # Get table data (paginated)
├── POST   /db-editor/data/:name        # Insert row
├── PUT    /db-editor/data/:name/:id    # Update row
├── DELETE /db-editor/data/:name/:id    # Delete row
├── POST   /db-editor/query             # Execute custom query
├── POST   /db-editor/views             # Create view
├── GET    /db-editor/views             # List views
├── POST   /db-editor/export/:name      # Export data (CSV/JSON)
└── POST   /db-editor/import/:name      # Import data (CSV/JSON)
```

---

## 👥 TENANT ADMIN

### Base: `/api/admin/tenant`

```
Tenant Settings
├── GET    /settings                    # Get all tenant settings
├── GET    /settings/:key               # Get specific setting
├── PUT    /settings/:key               # Update setting
├── DELETE /settings/:key               # Delete custom setting
└── POST   /settings/:key/reset         # Reset to platform default

Users & Permissions
├── GET    /users                       # List tenant users
├── GET    /users/:id                   # Get user details
├── POST   /users/invite                # Invite new user
├── PUT    /users/:id                   # Update user
├── DELETE /users/:id                   # Remove user
├── PUT    /users/:id/role              # Change user role
├── POST   /users/:id/suspend           # Suspend user
├── POST   /users/:id/activate          # Activate user
├── GET    /users/:id/activity          # User activity log
└── POST   /users/:id/reset-password    # Force password reset

Services Management
├── GET    /services                    # List available services
├── GET    /services/enabled            # List enabled services
├── GET    /services/:id                # Get service details
├── POST   /services/:id/enable         # Enable service
├── POST   /services/:id/disable        # Disable service
├── PUT    /services/:id/config         # Update service config
└── GET    /services/:id/usage          # Service usage stats

Billing & Subscription
├── GET    /billing/subscription        # Current subscription
├── GET    /billing/invoices            # Invoice history
├── GET    /billing/invoice/:id         # Get specific invoice
├── POST   /billing/payment-method      # Update payment method
├── POST   /billing/change-plan         # Change subscription plan
├── GET    /billing/usage               # Current usage
└── POST   /billing/cancel              # Cancel subscription

Security & Audit
├── GET    /security/audit              # Audit logs
├── GET    /security/sessions           # Active sessions
├── DELETE /security/sessions/:id       # Revoke session
├── GET    /security/api-keys           # List API keys
├── POST   /security/api-keys           # Create API key
├── DELETE /security/api-keys/:id       # Delete API key
├── PUT    /security/mfa                # Configure MFA settings
└── GET    /security/events             # Security events

Branding & Customization
├── GET    /branding                    # Get branding settings
├── PUT    /branding/logo               # Update logo
├── PUT    /branding/colors             # Update color scheme
├── PUT    /branding/domain             # Set custom domain
└── DELETE /branding/reset              # Reset to default

Reports
├── GET    /reports/users               # User activity report
├── GET    /reports/services            # Services usage report
├── GET    /reports/projects            # Projects report
└── POST   /reports/export              # Export data
```

---

## 👤 USER

### Base: `/api/user`

```
Profile
├── GET    /profile                     # Get user profile
├── PUT    /profile                     # Update profile
├── POST   /profile/avatar              # Upload avatar
├── POST   /profile/change-password     # Change password
└── DELETE /profile                     # Delete account

Settings
├── GET    /settings                    # Get all user settings
├── GET    /settings/:key               # Get specific setting
├── PUT    /settings/:key               # Update setting
└── DELETE /settings/:key               # Delete custom setting

Notifications
├── GET    /notifications               # List notifications
├── GET    /notifications/unread        # Unread count
├── PUT    /notifications/:id/read      # Mark as read
├── PUT    /notifications/read-all      # Mark all as read
├── DELETE /notifications/:id           # Delete notification
├── GET    /notifications/preferences   # Notification preferences
└── PUT    /notifications/preferences   # Update preferences

Integrations
├── GET    /integrations                # List connected integrations
├── GET    /integrations/available      # Available integrations
├── POST   /integrations/:provider      # Connect integration
├── DELETE /integrations/:id            # Disconnect integration
└── GET    /integrations/:id/sync       # Sync integration

Sessions
├── GET    /sessions                    # Active sessions
├── DELETE /sessions/:id                # Revoke session
└── DELETE /sessions/all                # Revoke all sessions

Activity
├── GET    /activity                    # Recent activity
└── GET    /activity/stats              # Activity statistics
```

---

## 🔌 BUSINESS SERVICES

### Project Management (svc-pm)
**Base**: `/api/pm`

```
Projects
├── GET    /projects                    # List projects
├── GET    /projects/:id                # Get project details
├── POST   /projects                    # Create project
├── PUT    /projects/:id                # Update project
├── DELETE /projects/:id                # Delete project
├── POST   /projects/:id/archive        # Archive project
└── GET    /projects/:id/stats          # Project statistics

Tasks
├── GET    /tasks                       # List tasks
├── GET    /tasks/:id                   # Get task details
├── POST   /tasks                       # Create task
├── PUT    /tasks/:id                   # Update task
├── DELETE /tasks/:id                   # Delete task
├── POST   /tasks/:id/assign            # Assign task
├── POST   /tasks/:id/comment           # Add comment
└── GET    /tasks/:id/history           # Task history

Boards
├── GET    /boards                      # List boards
├── GET    /boards/:id                  # Get board
├── POST   /boards                      # Create board
├── PUT    /boards/:id                  # Update board
└── DELETE /boards/:id                  # Delete board
```

### Inventory (svc-inventory)
**Base**: `/api/inventory`

```
Products
├── GET    /products                    # List products
├── GET    /products/:id                # Get product
├── POST   /products                    # Create product
├── PUT    /products/:id                # Update product
├── DELETE /products/:id                # Delete product
└── GET    /products/:id/stock          # Stock levels

Warehouses
├── GET    /warehouses                  # List warehouses
├── GET    /warehouses/:id              # Get warehouse
├── POST   /warehouses                  # Create warehouse
├── PUT    /warehouses/:id              # Update warehouse
└── DELETE /warehouses/:id              # Delete warehouse

Stock Movements
├── GET    /movements                   # List movements
├── POST   /movements/in                # Stock in
├── POST   /movements/out               # Stock out
└── POST   /movements/transfer          # Transfer stock
```

### Box Designer (svc-box-designer)
**Base**: `/api/box`

```
Projects
├── GET    /projects                    # List box projects
├── GET    /projects/:id                # Get project
├── POST   /projects                    # Create project
├── PUT    /projects/:id                # Update project
└── DELETE /projects/:id                # Delete project

Calculations
├── POST   /calculate                   # Calculate die-line
├── POST   /calculate/cost              # Calculate cost
└── POST   /calculate/optimize          # Optimize layout

Templates
├── GET    /templates                   # List FEFCO templates
├── GET    /templates/:code             # Get template
└── GET    /templates/:code/preview     # Preview template

Quotes
├── GET    /quotes                      # List quotes
├── GET    /quotes/:id                  # Get quote
├── POST   /quotes                      # Create quote
└── POST   /quotes/:id/approve          # Approve quote

Orders
├── GET    /orders                      # List orders
├── GET    /orders/:id                  # Get order
├── POST   /orders                      # Create order
└── PUT    /orders/:id/status           # Update status

Export
├── POST   /export/pdf                  # Export to PDF
├── POST   /export/dxf                  # Export to DXF
└── POST   /export/svg                  # Export to SVG
```

### Approvals (svc-approvals)
**Base**: `/api/approvals`

```
Workflows
├── GET    /workflows                   # List workflows
├── GET    /workflows/:id               # Get workflow
├── POST   /workflows                   # Create workflow
├── PUT    /workflows/:id               # Update workflow
└── DELETE /workflows/:id               # Delete workflow

Requests
├── GET    /requests                    # List approval requests
├── GET    /requests/:id                # Get request
├── POST   /requests                    # Create request
├── POST   /requests/:id/approve        # Approve request
├── POST   /requests/:id/reject         # Reject request
└── POST   /requests/:id/comment        # Add comment

Templates
├── GET    /templates                   # List templates
├── GET    /templates/:id               # Get template
├── POST   /templates                   # Create template
└── PUT    /templates/:id               # Update template
```

### Quotations (svc-quotations)
**Base**: `/api/quotations`

```
Quotes
├── GET    /                            # List quotations
├── GET    /:id                         # Get quotation
├── POST   /                            # Create quotation
├── PUT    /:id                         # Update quotation
├── DELETE /:id                         # Delete quotation
├── POST   /:id/send                    # Send to customer
├── POST   /:id/approve                 # Approve quotation
└── POST   /:id/convert                 # Convert to order

Templates
├── GET    /templates                   # List templates
├── POST   /templates                   # Create template
└── PUT    /templates/:id               # Update template

Products
├── GET    /products                    # List quotable products
└── GET    /products/:id/price          # Get product pricing
```

---

## 📱 COMMUNICATIONS

### Communications Suite (svc-communications)
**Base**: `/api/communications`

```
Inbox
├── GET    /inbox                       # Unified inbox
├── GET    /inbox/:id                   # Get message
├── POST   /inbox/:id/reply             # Reply to message
└── DELETE /inbox/:id                   # Delete message

Email
├── GET    /email/accounts              # List email accounts
├── POST   /email/accounts              # Add account
├── GET    /email/messages              # List emails
├── POST   /email/send                  # Send email
└── POST   /email/sync                  # Sync account

SMS
├── POST   /sms/send                    # Send SMS
├── GET    /sms/messages                # List SMS
└── GET    /sms/templates               # SMS templates

WhatsApp
├── POST   /whatsapp/send               # Send WhatsApp
├── GET    /whatsapp/messages           # List messages
└── GET    /whatsapp/contacts           # WhatsApp contacts

Campaigns
├── GET    /campaigns                   # List campaigns
├── GET    /campaigns/:id               # Get campaign
├── POST   /campaigns                   # Create campaign
├── POST   /campaigns/:id/send          # Send campaign
└── GET    /campaigns/:id/stats         # Campaign stats
```

### Voice (svc-voice)
**Base**: `/api/voice`

```
Calls
├── GET    /calls                       # Call history
├── GET    /calls/:id                   # Get call details
├── POST   /calls/make                  # Make call
├── POST   /calls/:id/hangup            # End call
└── GET    /calls/:id/recording         # Get recording

Voicemail
├── GET    /voicemail                   # List voicemails
├── GET    /voicemail/:id               # Get voicemail
├── GET    /voicemail/:id/audio         # Get audio file
├── GET    /voicemail/:id/transcription # Get transcription
└── DELETE /voicemail/:id               # Delete voicemail

Numbers
├── GET    /numbers                     # List phone numbers
├── POST   /numbers                     # Purchase number
├── PUT    /numbers/:id                 # Update number
└── DELETE /numbers/:id                 # Release number

IVR
├── GET    /ivr/flows                   # List IVR flows
├── GET    /ivr/flows/:id               # Get flow
├── POST   /ivr/flows                   # Create flow
└── PUT    /ivr/flows/:id               # Update flow
```

### CRM (svc-crm)
**Base**: `/api/crm`

```
Contacts
├── GET    /contacts                    # List contacts
├── GET    /contacts/:id                # Get contact
├── POST   /contacts                    # Create contact
├── PUT    /contacts/:id                # Update contact
├── DELETE /contacts/:id                # Delete contact
└── GET    /contacts/:id/timeline       # Contact timeline

Companies
├── GET    /companies                   # List companies
├── GET    /companies/:id               # Get company
├── POST   /companies                   # Create company
└── PUT    /companies/:id               # Update company

Deals
├── GET    /deals                       # List deals
├── GET    /deals/:id                   # Get deal
├── POST   /deals                       # Create deal
├── PUT    /deals/:id                   # Update deal
└── POST   /deals/:id/stage             # Move stage

Pipelines
├── GET    /pipelines                   # List pipelines
├── POST   /pipelines                   # Create pipeline
└── PUT    /pipelines/:id               # Update pipeline
```

---

## 🎨 MEDIA & DESIGN

### Media (svc-media)
**Base**: `/api/media`

```
Assets
├── GET    /assets                      # List assets
├── GET    /assets/:id                  # Get asset
├── POST   /assets/upload               # Upload asset
├── PUT    /assets/:id                  # Update metadata
├── DELETE /assets/:id                  # Delete asset
└── GET    /assets/:id/versions         # Asset versions

Folders
├── GET    /folders                     # List folders
├── POST   /folders                     # Create folder
├── PUT    /folders/:id                 # Update folder
└── DELETE /folders/:id                 # Delete folder

Search
├── GET    /search                      # Search assets
├── GET    /search/suggestions          # Search suggestions
└── GET    /search/filters              # Available filters

Processing
├── POST   /process/resize              # Resize image
├── POST   /process/convert             # Convert format
└── POST   /process/optimize            # Optimize asset
```

### Previz (svc-previz)
**Base**: `/api/previz`

```
Scenes
├── GET    /scenes                      # List scenes
├── GET    /scenes/:id                  # Get scene
├── POST   /scenes                      # Create scene
├── PUT    /scenes/:id                  # Update scene
└── DELETE /scenes/:id                  # Delete scene

Assets
├── GET    /assets                      # List 3D assets
├── POST   /assets/upload               # Upload asset
└── GET    /assets/:id                  # Get asset

Shots
├── GET    /shots                       # List shots
├── POST   /shots                       # Create shot
└── PUT    /shots/:id                   # Update shot

Render
├── POST   /render                      # Render scene
├── GET    /render/:id                  # Get render status
└── GET    /render/:id/download         # Download render
```

---

## 🔧 CORE SERVICES

### Authentication (svc-auth)
**Base**: `/api/auth`

```
Authentication
├── POST   /register                    # Register user
├── POST   /login                       # Login
├── POST   /logout                      # Logout
├── POST   /refresh                     # Refresh token
├── POST   /forgot-password             # Request reset
├── POST   /reset-password              # Reset password
└── GET    /verify-email/:token         # Verify email

MFA
├── POST   /mfa/setup                   # Setup MFA
├── POST   /mfa/verify                  # Verify MFA code
└── POST   /mfa/disable                 # Disable MFA

OAuth
├── GET    /oauth/:provider             # OAuth login
├── GET    /oauth/:provider/callback    # OAuth callback
└── DELETE /oauth/:provider             # Disconnect OAuth

Sessions
├── GET    /sessions                    # List sessions
└── DELETE /sessions/:id                # Revoke session
```

### API Gateway (svc-api-gateway)
**Base**: `/api`

```
Health & Status
├── GET    /health                      # Gateway health
├── GET    /status                      # Services status
└── GET    /version                     # API version

Proxy
├── *      /pm/*                        # Proxy to svc-pm
├── *      /inventory/*                 # Proxy to svc-inventory
├── *      /box/*                       # Proxy to svc-box-designer
└── *      /:service/*                  # Dynamic service routing

Rate Limiting
├── GET    /rate-limit/status           # Check rate limit
└── GET    /rate-limit/reset            # Time until reset
```

---

## 🌍 PUBLIC APIs

### Base: `/api/public`

```
Information
├── GET    /                            # API info
├── GET    /health                      # Public health check
└── GET    /docs                        # API documentation

Services
├── GET    /services                    # Available services
└── GET    /services/:id                # Service info

Plans
├── GET    /plans                       # Subscription plans
└── GET    /plans/:id                   # Plan details

Webhooks
├── POST   /webhooks/:provider          # Webhook receiver
└── GET    /webhooks/verify/:token      # Webhook verification
```

---

## 📋 Standard Response Format

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data here
  },
  "meta": {
    "timestamp": "2025-10-15T10:30:00Z",
    "requestId": "req_abc123"
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "meta": {
    "timestamp": "2025-10-15T10:30:00Z",
    "requestId": "req_abc123"
  }
}
```

### Paginated Response
```json
{
  "success": true,
  "data": {
    "items": [/* array of items */],
    "pagination": {
      "total": 156,
      "page": 1,
      "limit": 20,
      "pages": 8,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

---

## 🔒 Authentication Headers

All authenticated requests must include:

```http
Authorization: Bearer {jwt_token}
X-Tenant-ID: {tenant_id}      # Required for tenant-scoped requests
X-Request-ID: {unique_id}     # Optional, for tracking
```

---

## 📊 HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET, PUT, DELETE |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE with no response body |
| 400 | Bad Request | Invalid input data |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily down |

---

## 🎯 Rate Limiting

Default rate limits per user:

| Endpoint Type | Limit | Window |
|---------------|-------|--------|
| Authentication | 5 requests | 15 minutes |
| Read Operations | 1000 requests | 1 hour |
| Write Operations | 100 requests | 1 hour |
| Upload Operations | 50 requests | 1 hour |
| Admin Operations | 500 requests | 1 hour |

Headers included in responses:
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 987
X-RateLimit-Reset: 1697368800
```

---

## 📝 Versioning

API versioning via header:
```http
X-API-Version: 1.0
```

Or via URL (for public APIs):
```
/api/v1/public/services
/api/v2/public/services
```

---

**Questa mappa è la fonte ufficiale per tutti gli endpoint della piattaforma.**

**Aggiornare questo documento quando si aggiungono nuovi endpoint.**

**Ultimo aggiornamento**: 15 Ottobre 2025
**Mantenuto da**: Platform Team & API Team
