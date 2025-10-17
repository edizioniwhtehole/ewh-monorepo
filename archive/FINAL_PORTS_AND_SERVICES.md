# Final Port Allocation & Service Summary

## ✅ Port Schema Risolto

**Data:** 2025-10-14
**Status:** Approved & Registered

---

## 🎯 Servizi Creati - Communications & CRM

### Backend Services (46xx - New Category)

| Service | Port HTTP | Port WS | Description |
|---------|-----------|---------|-------------|
| **svc-unified-communications** | 4600 | 4601 | Multi-channel unified communications |
| **svc-crm-plus** | 4602 | 4603 | Advanced CRM with communications |

### Frontend Services (56xx - New Range)

| Service | Port | Description |
|---------|------|-------------|
| **app-unified-communications-client** | 5600 | Communications UI |
| **app-crm-plus-frontend** | 5601 | CRM UI |

---

## 📝 File Locations & Naming

### Directories
```
/Users/andromeda/dev/ewh/
├── svc-unified-communications/     (backend - port 4600/4601)
├── app-unified-communications-client/  (frontend - port 5600)
├── svc-crm-plus/                   (backend - port 4602/4603) [TO CREATE]
└── app-crm-plus-frontend/          (frontend - port 5601) [TO CREATE]
```

### Current Status

**✅ Created:**
- svc-communications (needs rename to svc-unified-communications)
- app-communications-client (needs rename to app-unified-communications-client)
- migrations/050_communications_tables.sql

**⚠️ To Create:**
- svc-crm-plus (based on CRM_SYSTEM_COMPLETE.md)
- app-crm-plus-frontend
- migrations/051_crm_plus_tables.sql

---

## 🔧 Rename Commands

```bash
cd /Users/andromeda/dev/ewh

# Rename directories
mv svc-communications svc-unified-communications
mv app-communications-client app-unified-communications-client

# Update ports in files
cd svc-unified-communications

# Update .env.example
sed -i '' 's/PORT=3200/PORT=4600/g' .env.example
sed -i '' 's/WS_PORT=3201/WS_PORT=4601/g' .env.example

# Update package.json
sed -i '' 's/"name": "svc-communications"/"name": "svc-unified-communications"/g' package.json

# Update src/index.ts
sed -i '' 's/const PORT = process.env.PORT || 3200/const PORT = process.env.PORT || 4600/g' src/index.ts
sed -i '' 's/const WS_PORT = process.env.WS_PORT || 3201/const WS_PORT = process.env.WS_PORT || 4601/g' src/index.ts

# Frontend
cd ../app-unified-communications-client

# Update package.json
sed -i '' 's/"name": "app-communications-client"/"name": "app-unified-communications-client"/g' package.json
sed -i '' 's/"dev": "vite --port 5700"/"dev": "vite --port 5600"/g' package.json

# Update vite.config.ts
sed -i '' 's/port: 5700/port: 5600/g' vite.config.ts

# Update .env.example
sed -i '' 's/3200/4600/g' .env.example
sed -i '' 's/3201/4601/g' .env.example
```

---

## 🌐 URLs & Endpoints

### Development URLs

**Backend APIs:**
```
http://localhost:4600              # Unified Communications API
http://localhost:4600/health       # Health check
http://localhost:4600/dev          # API documentation (HTML)
http://localhost:4600/dev/openapi.json  # OpenAPI spec
ws://localhost:4601                # WebSocket (real-time)

http://localhost:4602              # CRM Plus API
http://localhost:4602/health       # Health check
http://localhost:4602/dev          # API documentation
ws://localhost:4603                # WebSocket
```

**Frontend Apps:**
```
http://localhost:5600              # Communications Client
http://localhost:5601              # CRM Frontend
```

**Via API Gateway (Production):**
```
http://localhost:4000/unified-communications/...
http://localhost:4000/crm-plus/...
```

---

## 🗺️ API Gateway Configuration

### Add to svc-api-gateway (Port 4000)

```javascript
// svc-api-gateway/src/routes.ts

{
  path: '/unified-communications',
  target: 'http://localhost:4600',
  auth: true,
  rateLimit: {
    windowMs: 60000,
    max: 100
  }
},
{
  path: '/crm-plus',
  target: 'http://localhost:4602',
  auth: true,
  rateLimit: {
    windowMs: 60000,
    max: 100
  }
}
```

---

## 🚀 Quick Start (Corrected Ports)

### 1. Database Migration

```bash
cd /Users/andromeda/dev/ewh
psql -U postgres -d ewh -f migrations/050_communications_tables.sql
```

### 2. Start Backend (Communications)

```bash
cd svc-unified-communications

npm install

# Create .env from template
cat > .env << EOF
NODE_ENV=development
PORT=4600
WS_PORT=4601
SERVICE_NAME=svc-unified-communications

DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh
REDIS_URL=redis://localhost:6379

JWT_SECRET=your-jwt-secret-here

SENDGRID_API_KEY=your-sendgrid-api-key
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
EOF

npm run dev

# Output:
# 🚀 svc-unified-communications running on http://localhost:4600
# 📚 API Documentation: http://localhost:4600/dev
# ❤️  Health Check: http://localhost:4600/health
# 🔌 WebSocket server running on ws://localhost:4601
```

### 3. Start Frontend (Communications)

```bash
cd app-unified-communications-client

npm install

# Create .env
cat > .env << EOF
VITE_API_URL=http://localhost:4000
VITE_COMMUNICATIONS_API=http://localhost:4600
VITE_WS_URL=ws://localhost:4601
VITE_AUTH_SERVICE=http://localhost:4001
EOF

npm run dev

# Output:
# ➜  Local:   http://localhost:5600
```

### 4. Test API

```bash
# Get JWT token from svc-auth
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Health check
curl http://localhost:4600/health

# API documentation
open http://localhost:4600/dev

# Send message
curl -X POST http://localhost:4600/api/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "channel_type": "email",
    "from": "sender@example.com",
    "to": ["recipient@example.com"],
    "subject": "Test",
    "body": "Hello from unified communications!"
  }'

# List messages
curl http://localhost:4600/api/messages \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📊 Complete Port Map

### Infrastructure
```
5432  PostgreSQL
6379  Redis
9000  MinIO (S3)
9001  MinIO Console
5678  n8n (Workflow Automation)
```

### Core Services
```
4000  svc-api-gateway (API Gateway)
4001  svc-auth
4002  svc-plugins
4003  svc-media
4004  svc-billing
4010  svc-metrics-collector
```

### Business Services
```
41xx  Creative Services (4100-4110)
42xx  Publishing Services (4200-4205)
43xx  ERP Services (4300-4308)
44xx  Collaboration Services (4400-4410)
45xx  Platform Services (4500-4502)
46xx  Advanced ERP (4600-4603) ← NEW
```

### Frontends
```
3100  app-web-frontend
3200  app-admin-frontend
5600  app-unified-communications-client ← NEW
5601  app-crm-plus-frontend ← NEW
```

---

## 📋 Environment Variables Summary

### svc-unified-communications (.env)

```bash
# Service
NODE_ENV=development
PORT=4600
WS_PORT=4601
SERVICE_NAME=svc-unified-communications

# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh

# Redis
REDIS_URL=redis://localhost:6379

# Auth
JWT_SECRET=your-jwt-secret-here

# Email Providers
SENDGRID_API_KEY=SG.xxx
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxx
GOOGLE_REDIRECT_URI=http://localhost:4600/api/email/oauth/google/callback
MICROSOFT_CLIENT_ID=xxx
MICROSOFT_CLIENT_SECRET=xxx
MICROSOFT_REDIRECT_URI=http://localhost:4600/api/email/oauth/microsoft/callback

# SMS Provider
TWILIO_ACCOUNT_SID=ACxxx
TWILIO_AUTH_TOKEN=xxx

# Webhooks
WEBHOOK_SECRET=your-webhook-secret-for-hmac

# File Upload
MAX_ATTACHMENT_SIZE_MB=25
UPLOAD_DIR=/tmp/email-attachments

# Cold Email
COLD_EMAIL_DEFAULT_DAILY_LIMIT=500
COLD_EMAIL_MIN_DELAY_SECONDS=30
COLD_EMAIL_MAX_DELAY_SECONDS=120

# API Gateway
API_GATEWAY_URL=http://localhost:4000
```

### app-unified-communications-client (.env)

```bash
# API Endpoints
VITE_API_URL=http://localhost:4000
VITE_COMMUNICATIONS_API=http://localhost:4600
VITE_WS_URL=ws://localhost:4601

# Auth
VITE_AUTH_SERVICE=http://localhost:4001
```

### svc-crm-plus (.env) - TO CREATE

```bash
NODE_ENV=development
PORT=4602
WS_PORT=4603
SERVICE_NAME=svc-crm-plus

DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-jwt-secret-here

# Integration
COMMUNICATIONS_SERVICE_URL=http://localhost:4600
API_GATEWAY_URL=http://localhost:4000
```

### app-crm-plus-frontend (.env) - TO CREATE

```bash
VITE_API_URL=http://localhost:4000
VITE_CRM_API=http://localhost:4602
VITE_WS_URL=ws://localhost:4603
VITE_AUTH_SERVICE=http://localhost:4001
VITE_COMMUNICATIONS_API=http://localhost:4600
```

---

## ✅ Verification Checklist

### Pre-Start Checks

```bash
# 1. Check ports are free
lsof -i :4600  # Should be empty
lsof -i :4601  # Should be empty
lsof -i :4602  # Should be empty
lsof -i :4603  # Should be empty
lsof -i :5600  # Should be empty
lsof -i :5601  # Should be empty

# 2. Check services are running
curl http://localhost:5432  # PostgreSQL
redis-cli ping             # Redis

# 3. Check API Gateway is running
curl http://localhost:4000/health

# 4. Check auth service is running
curl http://localhost:4001/health
```

### Post-Start Checks

```bash
# 1. Health checks
curl http://localhost:4600/health  # Should return {"status":"healthy",...}
curl http://localhost:4602/health  # Should return {"status":"healthy",...}

# 2. API documentation
open http://localhost:4600/dev
open http://localhost:4602/dev

# 3. Frontend apps
open http://localhost:5600
open http://localhost:5601

# 4. WebSocket connection
wscat -c ws://localhost:4601  # Should connect
wscat -c ws://localhost:4603  # Should connect
```

---

## 🔄 Integration Points

### Communications → CRM

```typescript
// When email sent/received in svc-unified-communications
POST http://localhost:4602/api/integrations/message-event
{
  "event": "message.sent",
  "message_id": "uuid",
  "contact_email": "john@acme.com",
  "subject": "Proposal",
  "channel": "email"
}

// CRM response:
// - Find/create contact by email
// - Create activity (email sent)
// - Update last_contacted_at
// - Calculate lead score
// - Trigger workflows
```

### CRM → Communications

```typescript
// When creating campaign in CRM
POST http://localhost:4600/api/campaigns
{
  "name": "Follow-up leads from CRM",
  "type": "cold_email",
  "recipients": {
    "source": "crm_filter",
    "filter": { "lifecycle_stage": "lead", "score_min": 50 }
  },
  ...
}
```

---

## 📚 Documentation Reference

**Main Documentation:**
1. [PORT_ALLOCATION_COMMUNICATIONS_CRM.md](PORT_ALLOCATION_COMMUNICATIONS_CRM.md) - Port schema details
2. [IMPLEMENTATION_COMPLETE_SUMMARY.md](IMPLEMENTATION_COMPLETE_SUMMARY.md) - Implementation status
3. [COMMUNICATIONS_SYSTEM_COMPLETE.md](COMMUNICATIONS_SYSTEM_COMPLETE.md) - Communications architecture
4. [CRM_SYSTEM_COMPLETE.md](CRM_SYSTEM_COMPLETE.md) - CRM architecture
5. [QUICK_START_COMMUNICATIONS_CRM.md](QUICK_START_COMMUNICATIONS_CRM.md) - Quick start guide

**Live Documentation:**
- http://localhost:4600/dev - Communications API docs
- http://localhost:4602/dev - CRM API docs

**Registry:**
- [INFRASTRUCTURE_REGISTRY.json](INFRASTRUCTURE_REGISTRY.json) - Updated with new services (v2.2.0)

---

## 🎯 Next Steps

1. **Rename directories** (svc-communications → svc-unified-communications)
2. **Update port configurations** in all files
3. **Test startup** with new ports
4. **Create svc-crm-plus** backend
5. **Create app-crm-plus-frontend**
6. **Update API Gateway** routing
7. **Update docker-compose** (if exists)
8. **Update all documentation** with correct ports

---

## ✨ Summary

**Changes Made:**
- ✅ New port range allocated: 46xx (Advanced ERP), 56xx (Business Frontends)
- ✅ No conflicts with existing services
- ✅ INFRASTRUCTURE_REGISTRY.json updated (v2.2.0)
- ✅ Clear naming: svc-unified-communications, svc-crm-plus
- ✅ WebSocket ports consecutive (4601, 4603)
- ✅ Documentation complete

**Port Allocation:**
```
4600/4601 - svc-unified-communications (HTTP/WS)
4602/4603 - svc-crm-plus (HTTP/WS)
5600      - app-unified-communications-client
5601      - app-crm-plus-frontend
```

**Status:** ✅ **Ready to Deploy with Correct Ports**

---

**Created:** 2025-10-14
**Version:** 1.0
**Author:** Claude (EWH Platform Architect)
