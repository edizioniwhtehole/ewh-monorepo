# Real Estate SaaS - Technical Implementation Spec

## Executive Summary

This document provides the complete technical specification for the **Real Estate SaaS MVP** (Q1 2025). The goal is to launch a fully functional product for real estate agencies in **8 weeks**, targeting the first 100 customers via door-to-door sales.

**Architecture**: 100% web-based, modular (Odoo-style), multi-tenant.

**Stack**: Next.js, Node.js, PostgreSQL, S3, Stripe.

**Pricing**: 4 tiers (Free/€49, Pro €99, Ultra €179, Top €249/month).

---

## 1. Product Overview

### Target Customer

**Who**: Real estate agencies (agenzie immobiliari) in Italy
- Small: 1-5 agents
- Medium: 5-20 agents
- Large: 20+ agents

**Pain Points**:
- ❌ Photos look unprofessional (dark, distorted)
- ❌ Manual data entry for every property
- ❌ Spreadsheets for lead tracking
- ❌ No follow-up automation (lose leads)
- ❌ Generating brochures takes hours
- ❌ Expensive tools (€300-500/month) or free but limited

**Solution**:
- ✅ AI photo enhancement (brighten, HDR, perspective fix)
- ✅ Virtual staging (add furniture to empty rooms)
- ✅ CRM for buyers/sellers/agents
- ✅ Automated follow-ups (email, SMS, WhatsApp)
- ✅ One-click brochure generation
- ✅ Affordable (€49-249/month)

### Features by Tier

| Feature | Free (€0) | Starter (€49) | Pro (€99) | Ultra (€179) | Top (€249) |
|---------|-----------|---------------|-----------|--------------|------------|
| Properties | 3 | 10 | 50 | Unlimited | Unlimited |
| Photos/month | 50 | 200 | 1000 | 5000 | Unlimited |
| Agents | 1 | 2 | 5 | 15 | Unlimited |
| CRM Contacts | 100 | 500 | 5000 | Unlimited | Unlimited |
| **AI Photo Enhancement** | ❌ | ✅ Basic | ✅ Advanced | ✅ Advanced | ✅ Advanced |
| **Virtual Staging** | ❌ | ❌ | ✅ 10/mo | ✅ 50/mo | ✅ Unlimited |
| **Automated Follow-ups** | ❌ | ✅ Email | ✅ Email+SMS | ✅ All+WhatsApp | ✅ All+WhatsApp |
| **Brochure Templates** | 3 | 10 | 50 | Unlimited | Unlimited+Custom |
| **Analytics** | Basic | Standard | Advanced | Advanced+Export | Full BI |
| **White Label** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **API Access** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Priority Support** | ❌ | ❌ | ✅ | ✅ | ✅ 24/7 |

### Modules

**Core Modules** (MVP):
1. **Property Management** - Add, edit, browse properties
2. **DAM (Digital Asset Manager)** - Upload, organize, enhance photos
3. **CRM** - Contacts, deals, pipeline
4. **Forms** - Lead capture, contact forms
5. **Brochures** - Generate PDFs from templates
6. **Analytics** - Dashboard with key metrics
7. **Settings** - User, billing, integrations

**Future Modules** (Post-MVP):
- Calendar (appointments, open houses)
- Email campaigns (bulk, drip)
- Website builder (property listings)
- Mobile app (iOS/Android)
- Desktop photo editor (Q2)

---

## 2. Architecture

### High-Level Diagram

```
┌────────────────────────────────────────────────────────────┐
│                   Users (Browser)                          │
│              https://app.realestate.ewh.io                 │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│              CDN (Cloudflare/Vercel)                       │
│              Static Assets, Images                         │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│           Frontend (Next.js 14 - Port 3150)                │
│              SSR + Client-Side Rendering                   │
├────────────────────────────────────────────────────────────┤
│  Modules:                                                  │
│  • Dashboard                                               │
│  • Properties (list, detail, create, edit)                │
│  • Photos (upload, enhance, organize)                     │
│  • CRM (contacts, deals, pipeline)                        │
│  • Forms (lead capture)                                    │
│  • Brochures (templates, generate PDF)                    │
│  • Analytics (charts, metrics)                            │
│  • Settings (profile, billing, team)                      │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│         API Gateway (Node.js/Fastify - Port 4000)          │
│                                                            │
│  Responsibilities:                                         │
│  • Authentication (JWT)                                    │
│  • Rate limiting (by tier)                                 │
│  • Request routing                                         │
│  • Tenant context injection                               │
│  • Error handling                                          │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│                    Microservices                           │
├────────────────────────────────────────────────────────────┤
│  • svc-auth (4001)       - Login, JWT, MFA                │
│  • svc-properties (4002) - CRUD properties                │
│  • svc-media (4003)      - Upload, AI enhance, staging    │
│  • svc-crm (4004)        - Contacts, deals, activities    │
│  • svc-forms (4005)      - Form builder, submissions      │
│  • svc-pdf (4006)        - Brochure generation            │
│  • svc-analytics (4007)  - Metrics, charts                │
│  • svc-billing (4008)    - Stripe, subscriptions          │
│  • svc-notifications (4009) - Email, SMS, WhatsApp        │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│                 Data Layer                                 │
├────────────────────────────────────────────────────────────┤
│  • PostgreSQL 14+ (multi-tenant)                           │
│  • Redis 7+ (cache, sessions, queues)                      │
│  • S3/R2 (photo storage)                                   │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│                 External Services                          │
├────────────────────────────────────────────────────────────┤
│  • Stripe (payments)                                       │
│  • SendGrid (transactional email)                          │
│  • Twilio (SMS)                                            │
│  • OpenAI API (AI photo enhancement)                       │
│  • Cloudflare R2 (storage)                                 │
└────────────────────────────────────────────────────────────┘
```

### Multi-Tenancy

**Row-Level Isolation**:

Every table has a `tenant_id` column:

```sql
CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2),
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  zip VARCHAR(20),
  bedrooms INT,
  bathrooms INT,
  sqm DECIMAL(10, 2),
  status VARCHAR(50) DEFAULT 'draft', -- draft, active, sold, rented
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for fast tenant queries
CREATE INDEX idx_properties_tenant ON properties(tenant_id);
```

**Middleware** (API Gateway):

```typescript
// Inject tenant from JWT
app.use(async (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    req.tenantId = decoded.tenantId; // Every query uses this

    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
});
```

**Prisma ORM** (automatic tenant filtering):

```typescript
// Extend Prisma client with tenant middleware
const prisma = new PrismaClient().$extends({
  query: {
    $allModels: {
      async $allOperations({ model, operation, args, query }) {
        // Inject tenant_id for all queries
        if (args.where) {
          args.where.tenant_id = req.tenantId;
        } else {
          args.where = { tenant_id: req.tenantId };
        }

        return query(args);
      },
    },
  },
});
```

---

## 3. Database Schema

### Core Tables

**Tenants**:
```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  plan VARCHAR(50) DEFAULT 'free', -- free, starter, pro, ultra, top
  status VARCHAR(50) DEFAULT 'active', -- active, suspended, cancelled
  stripe_customer_id VARCHAR(255),
  stripe_subscription_id VARCHAR(255),
  limits JSONB DEFAULT '{"properties": 3, "photos": 50, "agents": 1}',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Users**:
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  role VARCHAR(50) DEFAULT 'agent', -- admin, agent, viewer
  avatar_url TEXT,
  phone VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Tenant Users** (Many-to-Many):
```sql
CREATE TABLE tenant_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'agent', -- owner, admin, agent, viewer
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, user_id)
);

CREATE INDEX idx_tenant_users_tenant ON tenant_users(tenant_id);
CREATE INDEX idx_tenant_users_user ON tenant_users(user_id);
```

**Properties**:
```sql
CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  property_type VARCHAR(50), -- apartment, house, villa, land, commercial
  listing_type VARCHAR(50), -- sale, rent
  price DECIMAL(12, 2),
  price_period VARCHAR(50), -- month, year (for rent)
  address TEXT,
  city VARCHAR(100),
  province VARCHAR(100),
  region VARCHAR(100),
  zip VARCHAR(20),
  country VARCHAR(50) DEFAULT 'Italy',
  lat DECIMAL(10, 8),
  lng DECIMAL(11, 8),
  bedrooms INT,
  bathrooms INT,
  sqm DECIMAL(10, 2),
  sqm_garden DECIMAL(10, 2),
  floor INT,
  total_floors INT,
  year_built INT,
  energy_class VARCHAR(10),
  features JSONB DEFAULT '[]', -- ["parking", "balcony", "elevator"]
  status VARCHAR(50) DEFAULT 'draft', -- draft, active, pending, sold, rented
  views_count INT DEFAULT 0,
  leads_count INT DEFAULT 0,
  published_at TIMESTAMP,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_properties_tenant ON properties(tenant_id);
CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_properties_city ON properties(city);
CREATE INDEX idx_properties_listing_type ON properties(listing_type);
```

**Photos**:
```sql
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
  original_url TEXT NOT NULL,
  enhanced_url TEXT,
  staged_url TEXT,
  thumbnail_url TEXT,
  filename VARCHAR(255),
  size_bytes BIGINT,
  width INT,
  height INT,
  format VARCHAR(20),
  room_type VARCHAR(50), -- living_room, bedroom, kitchen, bathroom, exterior
  is_cover BOOLEAN DEFAULT FALSE,
  order_index INT DEFAULT 0,
  ai_tags JSONB DEFAULT '[]', -- ["modern", "spacious", "bright"]
  enhancement_applied BOOLEAN DEFAULT FALSE,
  staging_applied BOOLEAN DEFAULT FALSE,
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_photos_tenant ON photos(tenant_id);
CREATE INDEX idx_photos_property ON photos(property_id);
CREATE INDEX idx_photos_room_type ON photos(room_type);
```

**CRM Contacts**:
```sql
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  type VARCHAR(50) DEFAULT 'buyer', -- buyer, seller, owner, tenant
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  company VARCHAR(255),
  address TEXT,
  city VARCHAR(100),
  province VARCHAR(100),
  zip VARCHAR(20),
  budget_min DECIMAL(12, 2),
  budget_max DECIMAL(12, 2),
  preferences JSONB DEFAULT '{}', -- {"bedrooms": 3, "city": "Milano"}
  notes TEXT,
  tags JSONB DEFAULT '[]',
  source VARCHAR(50), -- website, referral, ad, cold_call
  assigned_to UUID REFERENCES users(id),
  last_contact_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_contacts_tenant ON contacts(tenant_id);
CREATE INDEX idx_contacts_type ON contacts(type);
CREATE INDEX idx_contacts_assigned ON contacts(assigned_to);
```

**Deals**:
```sql
CREATE TABLE deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  contact_id UUID REFERENCES contacts(id),
  property_id UUID REFERENCES properties(id),
  title VARCHAR(255) NOT NULL,
  type VARCHAR(50), -- sale, rent
  value DECIMAL(12, 2),
  commission DECIMAL(5, 2), -- percentage
  stage VARCHAR(50) DEFAULT 'lead', -- lead, viewing, offer, negotiation, contract, closed_won, closed_lost
  probability INT DEFAULT 0, -- 0-100%
  expected_close_date DATE,
  closed_at TIMESTAMP,
  lost_reason TEXT,
  notes TEXT,
  assigned_to UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_deals_tenant ON deals(tenant_id);
CREATE INDEX idx_deals_stage ON deals(stage);
CREATE INDEX idx_deals_assigned ON deals(assigned_to);
```

**Activities** (CRM timeline):
```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  type VARCHAR(50) NOT NULL, -- call, email, meeting, note, viewing
  subject VARCHAR(255),
  description TEXT,
  contact_id UUID REFERENCES contacts(id),
  deal_id UUID REFERENCES deals(id),
  property_id UUID REFERENCES properties(id),
  scheduled_at TIMESTAMP,
  completed_at TIMESTAMP,
  status VARCHAR(50) DEFAULT 'pending', -- pending, completed, cancelled
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_activities_tenant ON activities(tenant_id);
CREATE INDEX idx_activities_contact ON activities(contact_id);
CREATE INDEX idx_activities_deal ON activities(deal_id);
CREATE INDEX idx_activities_scheduled ON activities(scheduled_at);
```

**Forms** (Lead capture):
```sql
CREATE TABLE forms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  title VARCHAR(255),
  description TEXT,
  fields JSONB NOT NULL, -- [{"name": "email", "type": "email", "required": true}]
  settings JSONB DEFAULT '{}', -- {"redirect_url": "https://...", "notification_email": "..."}
  status VARCHAR(50) DEFAULT 'active', -- active, paused, archived
  submissions_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, slug)
);

CREATE INDEX idx_forms_tenant ON forms(tenant_id);
```

**Form Submissions**:
```sql
CREATE TABLE form_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  form_id UUID NOT NULL REFERENCES forms(id),
  data JSONB NOT NULL, -- {"email": "...", "name": "...", "phone": "..."}
  contact_id UUID REFERENCES contacts(id), -- Auto-created contact
  source_url TEXT,
  ip_address VARCHAR(50),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_form_submissions_tenant ON form_submissions(tenant_id);
CREATE INDEX idx_form_submissions_form ON form_submissions(form_id);
```

**Brochure Templates**:
```sql
CREATE TABLE brochure_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id), -- NULL = system template
  name VARCHAR(255) NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  layout JSONB NOT NULL, -- Template structure
  is_system BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_brochure_templates_tenant ON brochure_templates(tenant_id);
```

**Generated Brochures**:
```sql
CREATE TABLE brochures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  property_id UUID NOT NULL REFERENCES properties(id),
  template_id UUID REFERENCES brochure_templates(id),
  pdf_url TEXT,
  settings JSONB DEFAULT '{}',
  generated_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_brochures_tenant ON brochures(tenant_id);
CREATE INDEX idx_brochures_property ON brochures(property_id);
```

**Analytics Events**:
```sql
CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  event_type VARCHAR(100) NOT NULL, -- property_view, photo_enhance, brochure_generate
  entity_type VARCHAR(50), -- property, contact, deal
  entity_id UUID,
  user_id UUID REFERENCES users(id),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_analytics_events_tenant ON analytics_events(tenant_id);
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_created ON analytics_events(created_at);
```

**Usage Tracking** (for limits):
```sql
CREATE TABLE usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  period VARCHAR(20) NOT NULL, -- YYYY-MM
  metric VARCHAR(100) NOT NULL, -- photos_uploaded, photos_enhanced, staging_applied
  count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(tenant_id, period, metric)
);

CREATE INDEX idx_usage_tenant ON usage(tenant_id);
CREATE INDEX idx_usage_period ON usage(period);
```

---

## 4. API Specification

### Authentication

**POST /api/auth/register**

Register new user and create tenant.

Request:
```json
{
  "email": "fabio@example.com",
  "password": "password123",
  "name": "Fabio Polosa",
  "company": "Acme Real Estate",
  "phone": "+39 123 456 7890"
}
```

Response:
```json
{
  "user": {
    "id": "uuid",
    "email": "fabio@example.com",
    "name": "Fabio Polosa"
  },
  "tenant": {
    "id": "uuid",
    "name": "Acme Real Estate",
    "slug": "acme-real-estate",
    "plan": "free"
  },
  "token": "jwt-token"
}
```

**POST /api/auth/login**

Request:
```json
{
  "email": "fabio@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "user": {
    "id": "uuid",
    "email": "fabio@example.com",
    "name": "Fabio Polosa"
  },
  "tenants": [
    {
      "id": "uuid",
      "name": "Acme Real Estate",
      "slug": "acme-real-estate",
      "plan": "pro",
      "role": "owner"
    }
  ],
  "token": "jwt-token"
}
```

### Properties

**GET /api/properties**

List properties for tenant.

Query params:
- `status` - Filter by status (draft, active, sold, rented)
- `city` - Filter by city
- `listing_type` - Filter by listing type (sale, rent)
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20)

Response:
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Luxurious Apartment in Milano",
      "property_type": "apartment",
      "listing_type": "sale",
      "price": 450000,
      "city": "Milano",
      "bedrooms": 3,
      "bathrooms": 2,
      "sqm": 120,
      "status": "active",
      "cover_photo": {
        "id": "uuid",
        "thumbnail_url": "https://cdn.ewh.io/..."
      },
      "photos_count": 25,
      "views_count": 145,
      "leads_count": 8,
      "published_at": "2025-01-15T10:00:00Z",
      "created_at": "2025-01-10T09:00:00Z"
    }
  ],
  "meta": {
    "total": 42,
    "page": 1,
    "limit": 20,
    "pages": 3
  }
}
```

**POST /api/properties**

Create new property.

Request:
```json
{
  "title": "Luxurious Apartment in Milano",
  "description": "Beautiful apartment with panoramic view...",
  "property_type": "apartment",
  "listing_type": "sale",
  "price": 450000,
  "address": "Via Roma 123",
  "city": "Milano",
  "province": "Milano",
  "region": "Lombardia",
  "zip": "20100",
  "bedrooms": 3,
  "bathrooms": 2,
  "sqm": 120,
  "floor": 5,
  "total_floors": 8,
  "year_built": 2015,
  "energy_class": "B",
  "features": ["parking", "balcony", "elevator", "air_conditioning"]
}
```

Response:
```json
{
  "id": "uuid",
  "title": "Luxurious Apartment in Milano",
  ...
  "status": "draft",
  "created_at": "2025-01-10T09:00:00Z"
}
```

**GET /api/properties/:id**

Get property details.

Response:
```json
{
  "id": "uuid",
  "title": "Luxurious Apartment in Milano",
  "description": "Beautiful apartment...",
  ...all fields...,
  "photos": [
    {
      "id": "uuid",
      "original_url": "https://cdn.ewh.io/...",
      "enhanced_url": "https://cdn.ewh.io/...",
      "thumbnail_url": "https://cdn.ewh.io/...",
      "room_type": "living_room",
      "is_cover": true,
      "order_index": 0
    }
  ],
  "created_by": {
    "id": "uuid",
    "name": "Fabio Polosa",
    "email": "fabio@example.com"
  }
}
```

**PUT /api/properties/:id**

Update property.

**DELETE /api/properties/:id**

Delete property.

### Photos

**POST /api/photos/upload-url**

Get presigned URL for direct S3 upload.

Request:
```json
{
  "property_id": "uuid",
  "filename": "living_room.jpg",
  "content_type": "image/jpeg",
  "size_bytes": 2048576
}
```

Response:
```json
{
  "upload_url": "https://r2.cloudflarestorage.com/...",
  "photo_id": "uuid",
  "fields": {
    "key": "tenants/uuid/photos/uuid/living_room.jpg"
  }
}
```

Client uploads directly to S3, then calls:

**POST /api/photos/:id/confirm**

Confirm upload completed.

Request:
```json
{
  "property_id": "uuid",
  "room_type": "living_room",
  "is_cover": false
}
```

Response:
```json
{
  "id": "uuid",
  "original_url": "https://cdn.ewh.io/...",
  "thumbnail_url": "https://cdn.ewh.io/...",
  "width": 1920,
  "height": 1080,
  "size_bytes": 2048576
}
```

**POST /api/photos/:id/enhance**

Apply AI enhancement.

Request:
```json
{
  "preset": "real_estate_standard" // or "hdr", "brighten", "wide_angle_fix"
}
```

Response (async job):
```json
{
  "job_id": "uuid",
  "status": "processing",
  "estimated_seconds": 10
}
```

Client polls:

**GET /api/photos/:id/enhance/:jobId**

Response:
```json
{
  "status": "completed",
  "enhanced_url": "https://cdn.ewh.io/...",
  "original_url": "https://cdn.ewh.io/..."
}
```

**POST /api/photos/:id/stage**

Apply virtual staging (add furniture).

Request:
```json
{
  "style": "modern" // or "classic", "minimalist", "luxury"
}
```

Response (async):
```json
{
  "job_id": "uuid",
  "status": "processing",
  "estimated_seconds": 30
}
```

**GET /api/photos/:id/stage/:jobId**

Response:
```json
{
  "status": "completed",
  "staged_url": "https://cdn.ewh.io/...",
  "original_url": "https://cdn.ewh.io/..."
}
```

### CRM

**GET /api/contacts**

List contacts.

**POST /api/contacts**

Create contact.

**GET /api/contacts/:id**

Get contact details with activity timeline.

**PUT /api/contacts/:id**

Update contact.

**DELETE /api/contacts/:id**

Delete contact.

**GET /api/deals**

List deals with pipeline visualization data.

Response:
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Milano Apartment - John Doe",
      "contact": {
        "id": "uuid",
        "name": "John Doe",
        "email": "john@example.com"
      },
      "property": {
        "id": "uuid",
        "title": "Luxurious Apartment in Milano",
        "price": 450000
      },
      "value": 450000,
      "commission": 3.0,
      "commission_amount": 13500,
      "stage": "viewing",
      "probability": 30,
      "expected_close_date": "2025-02-15",
      "assigned_to": {
        "id": "uuid",
        "name": "Fabio Polosa"
      }
    }
  ],
  "pipeline": {
    "lead": { "count": 15, "value": 6750000 },
    "viewing": { "count": 8, "value": 3200000 },
    "offer": { "count": 3, "value": 1350000 },
    "negotiation": { "count": 2, "value": 950000 },
    "contract": { "count": 1, "value": 450000 },
    "closed_won": { "count": 5, "value": 2250000 },
    "closed_lost": { "count": 12, "value": 4800000 }
  }
}
```

**POST /api/deals**

Create deal.

**PUT /api/deals/:id**

Update deal (move to different stage, etc).

**GET /api/activities**

List activities (timeline).

**POST /api/activities**

Create activity (schedule call, meeting, etc).

### Forms

**GET /api/forms**

List forms.

**POST /api/forms**

Create form.

Request:
```json
{
  "name": "Contact Form",
  "title": "Interested in this property?",
  "description": "Fill out the form and we'll get back to you.",
  "fields": [
    {
      "name": "name",
      "label": "Full Name",
      "type": "text",
      "required": true,
      "placeholder": "John Doe"
    },
    {
      "name": "email",
      "label": "Email",
      "type": "email",
      "required": true
    },
    {
      "name": "phone",
      "label": "Phone",
      "type": "tel",
      "required": false
    },
    {
      "name": "message",
      "label": "Message",
      "type": "textarea",
      "required": false,
      "placeholder": "Tell us about your requirements..."
    }
  ],
  "settings": {
    "redirect_url": "https://example.com/thank-you",
    "notification_email": "info@acme.com",
    "create_contact": true,
    "create_deal": false
  }
}
```

Response:
```json
{
  "id": "uuid",
  "slug": "contact-form",
  "embed_code": "<script src=\"https://app.realestate.ewh.io/embed/uuid\"></script>",
  "public_url": "https://app.realestate.ewh.io/f/acme-real-estate/contact-form"
}
```

**POST /api/forms/:id/submit** (Public endpoint)

Submit form (no auth required).

Request:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+39 123 456 7890",
  "message": "I'm interested in the Milano apartment."
}
```

Response:
```json
{
  "success": true,
  "redirect_url": "https://example.com/thank-you"
}
```

Backend creates:
- Contact (if not exists)
- Deal (if enabled)
- Activity (note with submission data)
- Sends notification email

### Brochures

**GET /api/brochures/templates**

List available templates (system + custom).

Response:
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Classic Brochure",
      "description": "Traditional layout with large photos",
      "thumbnail_url": "https://cdn.ewh.io/...",
      "is_system": true
    },
    {
      "id": "uuid",
      "name": "Modern Minimalist",
      "description": "Clean design with focus on photos",
      "thumbnail_url": "https://cdn.ewh.io/...",
      "is_system": true
    }
  ]
}
```

**POST /api/brochures/generate**

Generate brochure PDF.

Request:
```json
{
  "property_id": "uuid",
  "template_id": "uuid",
  "settings": {
    "include_floor_plan": true,
    "include_qr_code": true,
    "agent_contact": true
  }
}
```

Response (async):
```json
{
  "job_id": "uuid",
  "status": "processing",
  "estimated_seconds": 15
}
```

**GET /api/brochures/:jobId**

Check generation status.

Response:
```json
{
  "status": "completed",
  "pdf_url": "https://cdn.ewh.io/...",
  "brochure_id": "uuid"
}
```

### Analytics

**GET /api/analytics/dashboard**

Get dashboard metrics.

Query params:
- `period` - Time period (today, week, month, year, all)

Response:
```json
{
  "period": "month",
  "metrics": {
    "properties": {
      "total": 42,
      "active": 35,
      "sold": 5,
      "rented": 2,
      "draft": 7
    },
    "photos": {
      "uploaded": 1250,
      "enhanced": 890,
      "staged": 120
    },
    "crm": {
      "contacts": 345,
      "deals": 28,
      "deals_value": 12500000,
      "deals_won": 5,
      "deals_won_value": 2250000,
      "conversion_rate": 17.9
    },
    "leads": {
      "total": 156,
      "from_website": 89,
      "from_forms": 67,
      "conversion_to_deal": 17.9
    },
    "views": {
      "total": 5670,
      "unique": 3240,
      "avg_per_property": 135
    }
  },
  "charts": {
    "properties_by_status": [...],
    "leads_over_time": [...],
    "deals_pipeline": [...],
    "top_properties": [...]
  }
}
```

**GET /api/analytics/properties/:id**

Get analytics for specific property.

Response:
```json
{
  "property_id": "uuid",
  "views": {
    "total": 245,
    "unique": 178,
    "by_date": [
      { "date": "2025-01-01", "views": 12 },
      { "date": "2025-01-02", "views": 18 }
    ]
  },
  "leads": {
    "total": 15,
    "converted_to_deal": 3,
    "conversion_rate": 20.0
  },
  "engagement": {
    "avg_time_on_page": 125, // seconds
    "photo_views": [
      { "photo_id": "uuid", "views": 89 },
      { "photo_id": "uuid", "views": 76 }
    ]
  }
}
```

### Billing

**GET /api/billing/plans**

Get available plans (public).

Response:
```json
{
  "plans": [
    {
      "id": "free",
      "name": "Free",
      "price": 0,
      "interval": "month",
      "limits": {
        "properties": 3,
        "photos": 50,
        "agents": 1,
        "contacts": 100
      },
      "features": [
        "3 properties",
        "50 photos/month",
        "Basic CRM",
        "3 brochure templates"
      ]
    },
    {
      "id": "starter",
      "name": "Starter",
      "price": 49,
      "interval": "month",
      "stripe_price_id": "price_xxx",
      "limits": {
        "properties": 10,
        "photos": 200,
        "agents": 2,
        "contacts": 500
      },
      "features": [
        "Everything in Free",
        "10 properties",
        "200 photos/month",
        "AI Photo Enhancement (Basic)",
        "Email automation",
        "10 brochure templates"
      ]
    }
    // ... other plans
  ]
}
```

**POST /api/billing/subscribe**

Subscribe to plan (creates Stripe checkout session).

Request:
```json
{
  "plan_id": "pro",
  "interval": "month"
}
```

Response:
```json
{
  "checkout_url": "https://checkout.stripe.com/..."
}
```

**GET /api/billing/subscription**

Get current subscription.

Response:
```json
{
  "plan": "pro",
  "status": "active",
  "current_period_start": "2025-01-01T00:00:00Z",
  "current_period_end": "2025-02-01T00:00:00Z",
  "cancel_at_period_end": false,
  "stripe_customer_id": "cus_xxx",
  "stripe_subscription_id": "sub_xxx",
  "usage": {
    "properties": { "used": 35, "limit": 50 },
    "photos": { "used": 750, "limit": 1000 },
    "agents": { "used": 4, "limit": 5 },
    "contacts": { "used": 2340, "limit": 5000 }
  }
}
```

**POST /api/billing/cancel**

Cancel subscription.

**POST /api/billing/reactivate**

Reactivate cancelled subscription.

---

## 5. Frontend Structure

### Pages

**Public**:
- `/` - Landing page
- `/login` - Login
- `/register` - Register
- `/pricing` - Pricing plans

**Dashboard** (authenticated):
- `/dashboard` - Main dashboard (analytics overview)
- `/properties` - List properties
- `/properties/new` - Create property
- `/properties/:id` - Property detail
- `/properties/:id/edit` - Edit property
- `/photos` - DAM (all photos)
- `/photos/:id` - Photo detail/editor
- `/crm` - CRM dashboard
- `/crm/contacts` - List contacts
- `/crm/contacts/:id` - Contact detail
- `/crm/deals` - Pipeline (kanban)
- `/crm/deals/:id` - Deal detail
- `/forms` - List forms
- `/forms/new` - Create form
- `/forms/:id` - Form detail/submissions
- `/brochures` - Generated brochures
- `/analytics` - Detailed analytics
- `/settings` - Settings
- `/settings/billing` - Billing & subscription
- `/settings/team` - Team members

### Components

**Shared** (`@ewh/shared-widgets`):
```
/shared/packages/widgets/
├── src/
│   ├── ui/
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Select.tsx
│   │   ├── Modal.tsx
│   │   ├── Dropdown.tsx
│   │   ├── Card.tsx
│   │   ├── Table.tsx
│   │   ├── Badge.tsx
│   │   ├── Avatar.tsx
│   │   └── ...
│   ├── charts/
│   │   ├── LineChart.tsx
│   │   ├── BarChart.tsx
│   │   ├── PieChart.tsx
│   │   └── ...
│   ├── forms/
│   │   ├── FormBuilder.tsx
│   │   ├── FormRenderer.tsx
│   │   └── ...
│   └── layouts/
│       ├── DashboardLayout.tsx
│       ├── Sidebar.tsx
│       └── Topbar.tsx
```

**Module-Specific**:
```
/app-real-estate/
├── components/
│   ├── properties/
│   │   ├── PropertyCard.tsx
│   │   ├── PropertyList.tsx
│   │   ├── PropertyForm.tsx
│   │   ├── PropertyDetail.tsx
│   │   └── PropertyFilters.tsx
│   ├── photos/
│   │   ├── PhotoGrid.tsx
│   │   ├── PhotoUploader.tsx
│   │   ├── PhotoEditor.tsx
│   │   ├── PhotoEnhancer.tsx
│   │   └── VirtualStaging.tsx
│   ├── crm/
│   │   ├── ContactCard.tsx
│   │   ├── ContactForm.tsx
│   │   ├── DealPipeline.tsx (kanban)
│   │   ├── DealCard.tsx
│   │   ├── ActivityTimeline.tsx
│   │   └── ActivityForm.tsx
│   ├── forms/
│   │   ├── FormEditor.tsx
│   │   ├── FormEmbed.tsx
│   │   └── SubmissionList.tsx
│   ├── brochures/
│   │   ├── TemplateSelector.tsx
│   │   ├── BrochurePreview.tsx
│   │   └── BrochureGenerator.tsx
│   └── analytics/
│       ├── DashboardMetrics.tsx
│       ├── PropertyAnalytics.tsx
│       └── LeadsChart.tsx
```

### State Management

**Zustand stores** (per domain):

**useAuthStore**:
```typescript
interface AuthState {
  user: User | null;
  tenant: Tenant | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  switchTenant: (tenantId: string) => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  tenant: null,
  token: null,
  isAuthenticated: false,

  login: async (email, password) => {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });
    const { user, tenants, token } = await res.json();

    set({
      user,
      tenant: tenants[0],
      token,
      isAuthenticated: true
    });

    localStorage.setItem('token', token);
  },

  logout: () => {
    set({ user: null, tenant: null, token: null, isAuthenticated: false });
    localStorage.removeItem('token');
  }
}));
```

**usePropertiesStore**:
```typescript
interface PropertiesState {
  properties: Property[];
  loading: boolean;
  filters: PropertyFilters;
  fetchProperties: () => Promise<void>;
  createProperty: (data: PropertyInput) => Promise<Property>;
  updateProperty: (id: string, data: Partial<Property>) => Promise<void>;
  deleteProperty: (id: string) => Promise<void>;
  setFilters: (filters: Partial<PropertyFilters>) => void;
}
```

**useCRMStore**, **useFormsStore**, etc.

---

## 6. Key Features Implementation

### 1. AI Photo Enhancement

**Flow**:
1. User uploads photo → S3
2. User clicks "Enhance"
3. Frontend calls `POST /api/photos/:id/enhance`
4. Backend creates job, adds to queue
5. Worker processes job:
   - Downloads original from S3
   - Calls OpenAI DALL-E API (or local model)
   - Applies enhancements (brighten, HDR, perspective correction)
   - Uploads enhanced version to S3
   - Updates photo record with `enhanced_url`
   - Sends webhook notification
6. Frontend receives webhook (via WebSocket), updates UI

**Backend (svc-media)**:
```typescript
// routes/enhance.ts
export async function enhancePhoto(req, res) {
  const { photoId } = req.params;
  const { preset } = req.body;

  // Check limits
  const usage = await checkUsage(req.tenantId, 'photos_enhanced');
  if (usage.exceeded) {
    return res.status(403).json({
      error: 'Limit exceeded',
      message: `You've used ${usage.used} of ${usage.limit} enhancements this month. Upgrade to continue.`
    });
  }

  // Create job
  const job = await queue.add('enhance-photo', {
    photoId,
    tenantId: req.tenantId,
    preset,
    userId: req.user.id
  });

  return res.json({
    job_id: job.id,
    status: 'processing',
    estimated_seconds: 10
  });
}
```

**Worker**:
```typescript
// workers/enhance-photo.ts
import { OpenAI } from 'openai';
import sharp from 'sharp';

queue.process('enhance-photo', async (job) => {
  const { photoId, tenantId, preset } = job.data;

  // Get photo
  const photo = await prisma.photo.findUnique({
    where: { id: photoId }
  });

  // Download original
  const originalBuffer = await downloadFromS3(photo.original_url);

  // Apply enhancements based on preset
  let enhancedBuffer: Buffer;

  if (preset === 'real_estate_standard') {
    // 1. Brighten
    // 2. Auto white balance
    // 3. Sharpen
    enhancedBuffer = await sharp(originalBuffer)
      .modulate({ brightness: 1.2 })
      .normalize()
      .sharpen()
      .toBuffer();
  } else if (preset === 'hdr') {
    // Use AI for HDR effect
    const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

    // Upload to OpenAI, apply HDR
    // (Simplified - actual implementation more complex)
    const base64 = originalBuffer.toString('base64');
    const response = await openai.images.edit({
      image: base64,
      prompt: 'Enhance this real estate photo with HDR effect, brighten dark areas, balance exposure',
      n: 1,
      size: '1024x1024'
    });

    // Download enhanced
    const enhancedUrl = response.data[0].url;
    enhancedBuffer = await fetch(enhancedUrl).then(r => r.arrayBuffer()).then(Buffer.from);
  }

  // Upload enhanced
  const enhancedKey = `tenants/${tenantId}/photos/${photoId}/enhanced.jpg`;
  await uploadToS3(enhancedKey, enhancedBuffer, 'image/jpeg');

  const enhancedUrl = getS3Url(enhancedKey);

  // Update photo
  await prisma.photo.update({
    where: { id: photoId },
    data: {
      enhanced_url: enhancedUrl,
      enhancement_applied: true
    }
  });

  // Track usage
  await incrementUsage(tenantId, 'photos_enhanced');

  // Notify frontend via WebSocket
  await notifyWebSocket(tenantId, {
    type: 'PHOTO_ENHANCED',
    photo_id: photoId,
    enhanced_url: enhancedUrl
  });

  return { success: true, enhanced_url: enhancedUrl };
});
```

**Cost**:
- OpenAI DALL-E 2: $0.020 per image
- 1000 enhancements = $20
- Pass cost to customer or eat it (€99/month plan = 1000 photos)

**Alternative**: Train custom model (Stable Diffusion fine-tuned on real estate photos), run locally on GPU server. Cost: $0.001/image, but requires infrastructure.

### 2. Virtual Staging

**Flow**:
1. User selects empty room photo
2. Clicks "Virtual Staging"
3. Selects style (modern, classic, minimalist, luxury)
4. Backend generates staged version:
   - Detects room type (living room, bedroom, kitchen)
   - Generates furniture placement with AI
   - Composites furniture into photo
5. Returns staged version

**Implementation**:
```typescript
// workers/virtual-staging.ts
queue.process('virtual-staging', async (job) => {
  const { photoId, style } = job.data;

  const photo = await prisma.photo.findUnique({ where: { id: photoId } });
  const originalBuffer = await downloadFromS3(photo.original_url);

  // Use specialized API (e.g., Virtual Staging AI, Apply Design)
  // Or train custom model

  // Example with Virtual Staging AI API
  const response = await fetch('https://api.virtualstagingai.com/stage', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.VIRTUAL_STAGING_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      image: originalBuffer.toString('base64'),
      style: style,
      room_type: photo.room_type || 'living_room'
    })
  });

  const { staged_image_url } = await response.json();

  // Download and upload to our S3
  const stagedBuffer = await fetch(staged_image_url).then(r => r.arrayBuffer()).then(Buffer.from);
  const stagedKey = `tenants/${photo.tenant_id}/photos/${photoId}/staged.jpg`;
  await uploadToS3(stagedKey, stagedBuffer, 'image/jpeg');

  const stagedUrl = getS3Url(stagedKey);

  // Update photo
  await prisma.photo.update({
    where: { id: photoId },
    data: {
      staged_url: stagedUrl,
      staging_applied: true
    }
  });

  // Track usage
  await incrementUsage(photo.tenant_id, 'staging_applied');

  // Notify
  await notifyWebSocket(photo.tenant_id, {
    type: 'PHOTO_STAGED',
    photo_id: photoId,
    staged_url: stagedUrl
  });

  return { success: true, staged_url: stagedUrl };
});
```

**Cost**:
- Virtual Staging AI: $0.50-1.00 per image
- Our pricing: Include 10 stagings/month in Pro (€99), 50 in Ultra (€179), unlimited in Top (€249)
- Margin: €99/mo - 10 × €1 = €89/mo gross margin (before other costs)

### 3. CRM Deal Pipeline (Kanban)

**Frontend** (`components/crm/DealPipeline.tsx`):
```typescript
import { DragDropContext, Droppable, Draggable } from 'react-beautiful-dnd';

const STAGES = [
  { id: 'lead', name: 'Lead' },
  { id: 'viewing', name: 'Viewing Scheduled' },
  { id: 'offer', name: 'Offer Made' },
  { id: 'negotiation', name: 'Negotiation' },
  { id: 'contract', name: 'Contract' },
  { id: 'closed_won', name: 'Closed Won' }
];

export function DealPipeline() {
  const [deals, setDeals] = useState<Deal[]>([]);

  useEffect(() => {
    fetchDeals();
  }, []);

  const fetchDeals = async () => {
    const res = await fetch('/api/deals');
    const data = await res.json();
    setDeals(data.data);
  };

  const onDragEnd = async (result) => {
    if (!result.destination) return;

    const { draggableId, destination } = result;
    const dealId = draggableId;
    const newStage = destination.droppableId;

    // Optimistic update
    setDeals(deals.map(d =>
      d.id === dealId ? { ...d, stage: newStage } : d
    ));

    // Update backend
    await fetch(`/api/deals/${dealId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ stage: newStage })
    });
  };

  const dealsByStage = STAGES.reduce((acc, stage) => {
    acc[stage.id] = deals.filter(d => d.stage === stage.id);
    return acc;
  }, {});

  return (
    <DragDropContext onDragEnd={onDragEnd}>
      <div className="flex gap-4 overflow-x-auto">
        {STAGES.map(stage => (
          <Droppable key={stage.id} droppableId={stage.id}>
            {(provided) => (
              <div
                ref={provided.innerRef}
                {...provided.droppableProps}
                className="bg-gray-100 rounded p-4 min-w-[300px]"
              >
                <h3 className="font-bold mb-2">{stage.name}</h3>
                <div className="text-sm text-gray-500 mb-4">
                  {dealsByStage[stage.id]?.length || 0} deals
                </div>

                {dealsByStage[stage.id]?.map((deal, index) => (
                  <Draggable key={deal.id} draggableId={deal.id} index={index}>
                    {(provided) => (
                      <div
                        ref={provided.innerRef}
                        {...provided.draggableProps}
                        {...provided.dragHandleProps}
                        className="bg-white rounded shadow p-3 mb-2"
                      >
                        <div className="font-medium">{deal.title}</div>
                        <div className="text-sm text-gray-600 mt-1">
                          {deal.contact.name}
                        </div>
                        <div className="text-lg font-bold mt-2">
                          €{deal.value.toLocaleString()}
                        </div>
                        {deal.property && (
                          <div className="text-xs text-gray-500 mt-1">
                            {deal.property.title}
                          </div>
                        )}
                      </div>
                    )}
                  </Draggable>
                ))}

                {provided.placeholder}
              </div>
            )}
          </Droppable>
        ))}
      </div>
    </DragDropContext>
  );
}
```

### 4. Brochure Generation

**Flow**:
1. User selects property
2. Clicks "Generate Brochure"
3. Selects template
4. Backend generates PDF:
   - Loads template (HTML/CSS or PDF template)
   - Injects property data (title, price, features, photos)
   - Generates PDF with Puppeteer or PDFKit
   - Uploads to S3
5. Returns PDF URL

**Backend** (`services/pdf-generator.ts`):
```typescript
import puppeteer from 'puppeteer';
import handlebars from 'handlebars';
import fs from 'fs/promises';

export async function generateBrochure(
  property: Property,
  photos: Photo[],
  template: BrochureTemplate
): Promise<string> {
  // Load template HTML
  const templateHtml = await fs.readFile(`./templates/${template.id}.html`, 'utf-8');
  const compiledTemplate = handlebars.compile(templateHtml);

  // Render with data
  const html = compiledTemplate({
    property: {
      title: property.title,
      description: property.description,
      price: property.price.toLocaleString('it-IT', {
        style: 'currency',
        currency: 'EUR'
      }),
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      sqm: property.sqm,
      address: `${property.address}, ${property.city}`,
      features: property.features
    },
    photos: photos.map(p => ({
      url: p.enhanced_url || p.original_url,
      room: p.room_type
    })),
    agent: {
      name: 'Fabio Polosa',
      phone: '+39 123 456 7890',
      email: 'fabio@acme.com',
      photo: 'https://...'
    },
    qr_code: generateQRCode(`https://acme.com/properties/${property.id}`)
  });

  // Generate PDF with Puppeteer
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'networkidle0' });

  const pdfBuffer = await page.pdf({
    format: 'A4',
    printBackground: true,
    margin: { top: '0', right: '0', bottom: '0', left: '0' }
  });

  await browser.close();

  // Upload to S3
  const key = `tenants/${property.tenant_id}/brochures/${property.id}-${Date.now()}.pdf`;
  await uploadToS3(key, pdfBuffer, 'application/pdf');

  const pdfUrl = getS3Url(key);

  // Save to database
  await prisma.brochure.create({
    data: {
      tenant_id: property.tenant_id,
      property_id: property.id,
      template_id: template.id,
      pdf_url: pdfUrl
    }
  });

  return pdfUrl;
}
```

**Template Example** (`templates/classic.html`):
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: 'Georgia', serif;
      margin: 0;
      padding: 0;
    }
    .cover {
      position: relative;
      height: 100vh;
      background-image: url('{{photos.0.url}}');
      background-size: cover;
      background-position: center;
    }
    .cover-overlay {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      background: linear-gradient(transparent, rgba(0,0,0,0.8));
      padding: 40px;
      color: white;
    }
    .price {
      font-size: 48px;
      font-weight: bold;
    }
    .details {
      padding: 40px;
    }
    .photos-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 20px;
      padding: 40px;
    }
    .photo {
      width: 100%;
      height: 300px;
      object-fit: cover;
      border-radius: 8px;
    }
  </style>
</head>
<body>
  <div class="cover">
    <div class="cover-overlay">
      <h1>{{property.title}}</h1>
      <div class="price">{{property.price}}</div>
      <div>{{property.address}}</div>
    </div>
  </div>

  <div class="details">
    <h2>Details</h2>
    <ul>
      <li>{{property.bedrooms}} bedrooms</li>
      <li>{{property.bathrooms}} bathrooms</li>
      <li>{{property.sqm}} sqm</li>
    </ul>

    <h2>Description</h2>
    <p>{{property.description}}</p>

    <h2>Features</h2>
    <ul>
      {{#each property.features}}
        <li>{{this}}</li>
      {{/each}}
    </ul>
  </div>

  <div class="photos-grid">
    {{#each photos}}
      <img src="{{url}}" alt="{{room}}" class="photo" />
    {{/each}}
  </div>

  <div style="padding: 40px; text-align: center; background: #f5f5f5;">
    <h3>Contact Agent</h3>
    <p><strong>{{agent.name}}</strong></p>
    <p>{{agent.phone}} | {{agent.email}}</p>
    <img src="{{qr_code}}" alt="QR Code" style="width: 150px; height: 150px;" />
    <p style="font-size: 12px; color: #666;">Scan to view online</p>
  </div>
</body>
</html>
```

### 5. Automated Follow-ups

**Feature**: After a lead submits a form, automatically send follow-up emails/SMS.

**Implementation**:
```typescript
// When form is submitted
export async function handleFormSubmission(
  form: Form,
  submission: FormSubmission
) {
  // Create contact
  const contact = await createOrUpdateContact({
    tenant_id: form.tenant_id,
    email: submission.data.email,
    name: submission.data.name,
    phone: submission.data.phone,
    source: 'website_form'
  });

  // Create activity
  await prisma.activity.create({
    data: {
      tenant_id: form.tenant_id,
      contact_id: contact.id,
      type: 'note',
      subject: `Form submission: ${form.name}`,
      description: JSON.stringify(submission.data, null, 2),
      completed_at: new Date()
    }
  });

  // Get tenant settings
  const tenant = await prisma.tenant.findUnique({
    where: { id: form.tenant_id }
  });

  const followUpSettings = tenant.settings.follow_up_automation;

  if (followUpSettings?.enabled) {
    // Schedule automated follow-ups
    const sequences = [
      { delay: 0, type: 'email', template: 'thank_you' },
      { delay: 3600, type: 'sms', template: 'agent_intro' }, // 1 hour
      { delay: 86400, type: 'email', template: 'property_recommendations' }, // 1 day
      { delay: 259200, type: 'email', template: 'check_in' } // 3 days
    ];

    for (const seq of sequences) {
      await queue.add(
        'send-follow-up',
        {
          contact_id: contact.id,
          tenant_id: tenant.id,
          type: seq.type,
          template: seq.template
        },
        {
          delay: seq.delay * 1000 // Convert to milliseconds
        }
      );
    }
  }

  // Send immediate notification to agent
  await sendEmail({
    to: form.settings.notification_email,
    subject: `New lead: ${submission.data.name}`,
    template: 'new_lead_notification',
    data: {
      contact: submission.data,
      form: form.name
    }
  });
}
```

---

## 7. Development Timeline

### Week 1-2: Foundation (16 days)

**Backend**:
- [ ] Setup monorepo structure
- [ ] Database schema + migrations
- [ ] Multi-tenant middleware
- [ ] Authentication (JWT, register, login)
- [ ] API Gateway (Fastify, rate limiting)
- [ ] Prisma ORM setup

**Frontend**:
- [ ] Next.js app setup
- [ ] Shared components library (@ewh/shared-widgets)
- [ ] Layout (dashboard, sidebar, topbar)
- [ ] Auth pages (login, register)
- [ ] Dashboard (empty state)

**Infrastructure**:
- [ ] PostgreSQL (Railway/Render)
- [ ] Redis (Upstash)
- [ ] S3/R2 (Cloudflare R2)
- [ ] CI/CD (GitHub Actions)

### Week 3-4: Core Modules (16 days)

**Properties Module**:
- [ ] Backend API (CRUD)
- [ ] Frontend pages (list, create, edit, detail)
- [ ] Filters (city, price, bedrooms, status)
- [ ] Search

**CRM Module**:
- [ ] Contacts (CRUD, list, detail)
- [ ] Deals (CRUD, pipeline kanban)
- [ ] Activities (timeline, create)
- [ ] Drag-and-drop pipeline

**DAM Module**:
- [ ] Photo upload (presigned URLs)
- [ ] Photo grid (all photos, by property)
- [ ] Basic metadata (title, tags, room type)

### Week 5-6: Features (16 days)

**AI Photo Enhancement**:
- [ ] Backend worker (OpenAI API or custom)
- [ ] Queue system (Bull)
- [ ] Frontend UI (enhance button, progress)
- [ ] Usage tracking

**Virtual Staging**:
- [ ] Integration with Virtual Staging AI API
- [ ] Worker implementation
- [ ] Frontend UI (style selector, before/after)
- [ ] Usage tracking

**Forms Module**:
- [ ] Form builder (drag-and-drop fields)
- [ ] Public submission endpoint
- [ ] Embed code generator
- [ ] Submissions list
- [ ] Auto-create contact/deal

**Brochure Generator**:
- [ ] PDF generation (Puppeteer)
- [ ] 3 system templates
- [ ] Template selector UI
- [ ] Download/share PDF

### Week 7-8: Polish & Launch (16 days)

**Analytics**:
- [ ] Dashboard metrics
- [ ] Charts (properties, leads, deals)
- [ ] Property analytics (views, engagement)
- [ ] Export data

**Billing**:
- [ ] Stripe integration
- [ ] Subscription plans
- [ ] Checkout flow
- [ ] Usage limits enforcement
- [ ] Webhooks (payment success, failure)

**Settings**:
- [ ] User profile
- [ ] Team management (invite, remove)
- [ ] Tenant settings
- [ ] Notification preferences

**Onboarding**:
- [ ] Welcome wizard (add first property)
- [ ] Sample data (demo mode)
- [ ] Tooltips/hints

**Testing**:
- [ ] E2E tests (Playwright)
- [ ] Manual testing
- [ ] Performance testing
- [ ] Security audit

**Deployment**:
- [ ] Production environment (Railway/Vercel)
- [ ] Domain setup (app.realestate.ewh.io)
- [ ] SSL certificates
- [ ] Monitoring (Sentry, Datadog)

**Launch**:
- [ ] Landing page
- [ ] Pricing page
- [ ] Documentation
- [ ] First 10 customers (friends/family)
- [ ] First 100 customers (door-to-door)

---

## 8. Go-to-Market Strategy

### Phase 1: First 10 Customers (Week 1-2)

**Target**: Friends, family, personal network

**Approach**:
- Personal outreach (email, WhatsApp, phone)
- Offer: Free for 3 months, then €49/month
- Goal: Feedback, testimonials, case studies

### Phase 2: First 100 Customers (Month 2-3)

**Target**: Local real estate agencies (Torino/Milano)

**Approach**:
- **Door-to-door**: Visit 300 agencies in person
- **Pitch**: 5-minute demo on iPad
- **Offer**: 30-day free trial, no credit card required
- **Conversion**: 30-40% (100 customers from 300 visits)

**Script**:
> "Ciao, sono Fabio. Ho creato un software per agenzie immobiliari che fa tre cose: (1) rende le foto delle case più belle con l'AI, (2) gestisce i contatti e le trattative in modo automatico, e (3) genera brochure professionali in 2 click. Posso mostrarle in 5 minuti?"

**Demo**:
1. Upload photo → Enhance (before/after, wow effect)
2. Add contact → Create deal → Move in pipeline (simple)
3. Generate brochure → Download PDF (fast)

**Close**:
> "Prova gratis per 30 giorni. Se ti piace, sono €49 al mese. Se non ti piace, annulli con un click."

**Tracking**:
- Record all visits (agency name, contact, outcome)
- Follow up after 7 days (email)
- Follow up after 14 days (phone call)
- Convert trial → paid

### Phase 3: Scale (Month 4-12)

**Channels**:
1. **Google Ads** (search: "software gestionale immobiliare")
2. **Facebook/Instagram Ads** (target: real estate agents, 25-55 years old, Italy)
3. **YouTube** (tutorials, case studies, comparisons)
4. **Content Marketing** (blog: "Come vendere casa più velocemente", "Fotografia immobiliare", etc.)
5. **Partnerships** (portals like Immobiliare.it, Idealista.it)
6. **Referrals** (€50 credit for referring another agency)

**Budget**:
- Month 1-3: €5k/month (testing channels)
- Month 4-6: €15k/month (scale winners)
- Month 7-12: €30k/month (aggressive growth)

**Metrics**:
- CAC (Customer Acquisition Cost): Target €150
- LTV (Lifetime Value): €99 × 24 months × 70% retention = €1,663
- LTV/CAC ratio: 11x (healthy)

### Phase 4: Expand (Year 2)

**Geographic**:
- Italy (all regions)
- Spain (similar market)
- Portugal
- France

**Verticals**:
- Architects (use same platform for projects)
- Interior designers
- Property developers

---

## 9. Success Metrics

### Week 4 (MVP Complete)

- ✅ All core features working
- ✅ First 10 test users
- ✅ 90%+ uptime
- ✅ <2s page load time

### Month 3 (First 100 Customers)

- ✅ 100 paying customers
- ✅ €84k ARR (assuming mix of plans, avg €70/month)
- ✅ <10% churn
- ✅ NPS >40

### Month 6 (Scale Validation)

- ✅ 500 customers
- ✅ €600k ARR
- ✅ <5% churn
- ✅ NPS >50
- ✅ CAC <€150
- ✅ Profitable (or break-even)

### Month 12 (Real Estate Vertical Success)

- ✅ 5,000 customers
- ✅ €4M ARR
- ✅ <5% monthly churn
- ✅ NPS >60
- ✅ €1M+ profit (25% net margin)
- ✅ Team of 10 people

---

## 10. Technical Risks & Mitigations

### Risk 1: Photo Enhancement Quality

**Risk**: AI enhancements look bad, customers complain

**Mitigation**:
- Test multiple presets, let users preview before applying
- Allow undo (keep original always)
- Option to adjust intensity (slider: 0-100%)
- Manual editing tools (crop, brightness, contrast)

### Risk 2: Performance (Slow Page Load)

**Risk**: Dashboard loads slowly with 1000s of properties

**Mitigation**:
- Pagination (load 20 at a time)
- Lazy loading images (thumbnails only)
- Server-side rendering (Next.js SSR)
- CDN for assets (Cloudflare)
- Database indexes (tenant_id, status, city)

### Risk 3: Stripe Integration Issues

**Risk**: Payments fail, subscriptions not updated

**Mitigation**:
- Webhooks for all events (payment success, failure, subscription cancelled)
- Idempotency (handle duplicate webhooks)
- Manual reconciliation script (daily)
- Retry failed payments (Stripe Smart Retry)

### Risk 4: Multi-Tenant Data Leakage

**Risk**: Tenant A sees Tenant B's data

**Mitigation**:
- Middleware enforces tenant_id on ALL queries
- Database row-level security (RLS) in PostgreSQL
- Automated tests (create 2 tenants, verify isolation)
- Security audit before launch

### Risk 5: Usage Limit Bypass

**Risk**: Users bypass limits (e.g., unlimited enhancements on free plan)

**Mitigation**:
- Check limits in middleware (before processing)
- Track usage in database (atomic increments)
- Daily reconciliation (sync actual usage vs tracked)
- Soft limits (warn at 80%, block at 100%)

### Risk 6: API Costs Explosion

**Risk**: OpenAI/Virtual Staging costs exceed revenue

**Mitigation**:
- Set per-customer limits (enforced)
- Monitor daily spend (alerts at €500/day)
- Cache common operations (e.g., same photo enhanced twice = reuse)
- Switch to self-hosted models if volume justifies

### Risk 7: Downtime

**Risk**: Server crashes, customers can't access

**Mitigation**:
- Multiple replicas (3 backend instances)
- Load balancer (auto-failover)
- Health checks (restart unhealthy instances)
- Database replication (primary + standby)
- Monitoring (Datadog, PagerDuty)

---

## 11. Cost Projection

### Development (8 weeks)

**Team**:
- You (architect/PM): €0 (founder)
- AI assistants (Claude, GPT): €100/month
- 1 Senior Developer: €5k × 2 months = €10k
- 1 Junior Developer: €3k × 2 months = €6k

**Total**: €16.1k

### Infrastructure (Month 1-3)

**Hosting**:
- Railway (backend): €50/month
- Vercel (frontend): €20/month
- PostgreSQL: €25/month
- Redis: €10/month
- S3/R2 storage: €10/month

**External APIs**:
- OpenAI: €100/month (500 enhancements)
- Virtual Staging: €100/month (100 stagings)
- SendGrid: €15/month (15k emails)
- Twilio: €20/month (SMS)

**Total**: €350/month × 3 = €1.05k

### Marketing (Month 1-3)

- Landing page design: €500
- Google Ads: €2k
- Facebook Ads: €1k
- Content (blog): €500

**Total**: €4k

### Grand Total (Q1)**:
€16.1k + €1.05k + €4k = **€21.15k**

### Break-Even

**Revenue** (100 customers, avg €70/month):
€7k/month = €84k/year

**Costs** (ongoing):
- Infrastructure: €500/month = €6k/year
- Team (2 people): €8k/month = €96k/year
- Marketing: €5k/month = €60k/year

**Total costs**: €162k/year

**Break-even**: €162k / €70 = **2,314 customers**

At 500 customers/month growth: Break-even in **Month 5**.

---

## 12. Next Steps

### This Week

1. **Confirm architecture** (review this doc, approve)
2. **Setup development environment**:
   - Clone monorepo
   - Setup PostgreSQL (local + Railway)
   - Setup S3/R2 (Cloudflare)
   - Install dependencies
3. **Create database schema** (run migrations)
4. **Start Week 1 tasks** (auth, API gateway, frontend layout)

### Week 1 Deliverables

- [ ] Database schema created
- [ ] Auth API (register, login, JWT)
- [ ] Frontend layout (dashboard, sidebar, topbar)
- [ ] First page: Properties list (empty state)

### Week 2 Deliverables

- [ ] Properties CRUD API
- [ ] Properties frontend (list, create, edit)
- [ ] Photo upload (S3 presigned URLs)
- [ ] Photo grid

Then continue with Week 3-4 tasks per timeline above.

---

**Ready to build!** 🚀

Let me know when you want to start Week 1, and I'll help you with the first tasks.
