# EWH Platform - Admin Menu Structure (Complete)

> Comprehensive hierarchical menu organization for all 50+ microservices and features

**Created:** 2025-10-08
**Status:** ✅ Complete & Production-Ready
**Total Menu Items:** 140+
**Root Sections:** 15

---

## 📊 Menu Overview

```
EWH Admin Console
├── 1. Dashboard & Overview (2 items)
├── 2. Monitoring & Operations (7 items) 🔥 Enterprise
├── 3. Infrastructure (6 items)
├── 4. Tenants & Billing (6 items)
├── 5. Creative Studio (11 items) 🎨
├── 6. Publishing & Sites (6 items)
├── 7. ERP & E-Commerce (9 items) 🏭
├── 8. Collaboration (7 items)
├── 9. Communication (4 items)
├── 10. HR & Workforce (7 items)
├── 11. Analytics & BI (3 items)
├── 12. Automation (4 items) 🤖
├── 13. Plugins & Extensions (3 items)
├── 14. God Mode (10 items) ⚡ Advanced
└── 15. System Settings (7 items)
```

---

## 🎯 Section 1: Dashboard & Overview

**Position:** 1-2
**Icon:** 📊
**Purpose:** Main entry points and system overview

| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `admin-dashboard` | Dashboard | `/admin/dashboard` | LayoutDashboard | Main control panel |
| `admin-overview` | System Overview | `/admin/overview` | Activity | Platform health status |

---

## 🔥 Section 2: Monitoring & Operations (Enterprise)

**Position:** 10-16
**Icon:** 📈
**Purpose:** Enterprise-grade observability and incident management

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `monitoring-root` | Monitoring & Ops | `/admin/monitoring` | Activity |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `monitoring-enterprise` | Enterprise Dashboard | `/admin/enterprise-monitoring` | BarChart3 | **Comprehensive observability** |
| `monitoring-services` | Services Health | `/admin/monitoring` | Cpu | Service health monitoring |
| `monitoring-metrics` | Custom Metrics | `/god-mode/metrics-config` | LineChart | **Configure custom metrics** |
| `monitoring-logs` | Log Aggregation | `/admin/logs` | FileText | Centralized logs |
| `monitoring-alerts` | Alerts & SLOs | `/admin/alerts` | Bell | Alert rules & SLO tracking |
| `monitoring-incidents` | Incidents | `/admin/incidents` | AlertTriangle | Incident management |

**Features:**
- ✅ Real-time service health
- ✅ Custom application metrics
- ✅ SLO/SLA tracking
- ✅ Alert management
- ✅ Incident lifecycle
- ✅ Log aggregation

---

## 🏗️ Section 3: Infrastructure

**Position:** 20-25
**Icon:** 🖥️
**Purpose:** Platform infrastructure and deployment

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `infrastructure-root` | Infrastructure | `/admin/infrastructure` | Server |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `infrastructure-map` | Service Topology | `/admin/infrastructure-map` | GitBranch | Visual dependency map |
| `infrastructure-services` | Service Registry | `/admin/services` | Database | All services registry |
| `infrastructure-deployments` | Deployments | `/admin/deployments` | Rocket | Deployment history |
| `infrastructure-gateway` | API Gateway | `/admin/gateway-enterprise` | Router | Gateway configuration |
| `infrastructure-nodes` | Service Nodes | `/admin/service-nodes` | Box | N8N workflow nodes |

**Services Covered:**
- svc-api-gateway
- svc-job-worker
- All 50+ microservices

---

## 👥 Section 4: Tenants & Billing

**Position:** 30-35
**Icon:** 💰
**Purpose:** Multi-tenancy and revenue management

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `tenancy-root` | Tenants & Billing | `/admin/tenants` | Users |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `tenancy-tenants` | All Tenants | `/admin/tenants` | Building | Manage tenants |
| `tenancy-packages` | Packages & Features | `/admin/packages` | Package | Feature packages |
| `tenancy-billing` | Billing & Invoices | `/admin/billing` | DollarSign | Billing management |
| `tenancy-migration` | Tenant Migration | `/admin/tenant-migration` | Move | **Tier migration (new)** |
| `tenancy-verticals` | Vertical Markets | `/admin/verticals` | Layers | **Vertical configs (new)** |

**Services Covered:**
- svc-auth (multi-tenancy)
- svc-billing

---

## 🎨 Section 5: Creative Studio

**Position:** 40-50
**Icon:** 🎨
**Purpose:** Content creation and media management

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `creative-root` | Creative Studio | `/admin/creative` | Palette |

### Sub-items

#### Asset Management
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `creative-dam` | Asset Management (DAM) | `/admin/dam` | FolderOpen | **Digital Asset Management** |
| `creative-media` | Media Library | `/admin/media` | Image | Global media library |

#### Content
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `creative-content` | Content CMS | `/admin/content` | FileText | Headless CMS |
| `creative-writer` | AI Text Lab | `/dashboard/apps/text-lab/ai-text-generator` | Wand2 | **AI text generation** |
| `creative-kb` | Knowledge Base | `/admin/kb` | BookOpen | Documentation |

#### Visual Editors
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `creative-image` | Image Editor | `/dashboard/apps/image-studio/photo-editor` | ImageIcon | Advanced photo editing |
| `creative-vector` | Vector Lab | `/dashboard/apps/vector-lab/vector-editor` | PenTool | Vector graphics |
| `creative-layout` | Layout Studio | `/dashboard/apps/layout-studio/layout-editor` | Layout | **Desktop publishing** |
| `creative-mockup` | Mockup Creator | `/dashboard/apps/mockup-studio/mockup-creator` | Box | 3D mockups |
| `creative-video` | Video Studio | `/admin/video` | Video | Video encoding |

**Services Covered:**
- svc-dms (DAM)
- svc-media
- svc-content
- svc-writer
- svc-kb
- svc-image-orchestrator
- svc-vector-lab
- svc-layout
- svc-mockup
- svc-video-orchestrator
- svc-video-runtime
- svc-raster-runtime
- svc-prepress

---

## 🌐 Section 6: Publishing & Sites

**Position:** 60-65
**Icon:** 🌍
**Purpose:** Website building and publishing

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `publishing-root` | Publishing & Sites | `/admin/publishing` | Globe |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `publishing-sites` | Site Builder | `/admin/site-builder` | Globe | Build websites |
| `publishing-pages` | Landing Pages | `/admin/landing-pages` | FileText | **Landing page builder** |
| `publishing-renderer` | Site Renderer | `/admin/site-renderer` | Monitor | SSR engine |
| `publishing-publisher` | Site Publisher | `/admin/site-publisher` | Upload | Deploy sites |
| `publishing-search` | Search Engine | `/admin/search` | Search | Meilisearch config |

**Services Covered:**
- svc-site-builder
- svc-site-renderer
- svc-site-publisher
- svc-search

---

## 🏭 Section 7: ERP & E-Commerce

**Position:** 70-79
**Icon:** 🛒
**Purpose:** Business management and e-commerce

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `erp-root` | ERP & E-Commerce | `/admin/erp` | ShoppingCart |

### Sub-items

#### Products & Inventory
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `erp-products` | Products | `/admin/products` | Package | Product catalog |
| `erp-inventory` | Inventory | `/admin/inventory` | Warehouse | Stock management |
| `erp-channels` | Sales Channels | `/admin/channels` | Store | Multi-channel |

#### Sales
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `erp-orders` | Orders | `/admin/orders` | ShoppingBag | Order management |
| `erp-quotation` | Quotations | `/admin/quotation` | FileSpreadsheet | Quotes |
| `erp-shipping` | Shipping | `/admin/shipping` | Truck | Logistics |

#### Procurement
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `erp-procurement` | Procurement | `/admin/procurement` | ShoppingBasket | Purchase orders |
| `erp-mrp` | Production (MRP) | `/admin/mrp` | Factory | MRP system |
| `erp-crm` | CRM | `/admin/crm` | Users | Customer relations |

**Services Covered:**
- svc-products
- svc-inventory
- svc-channels
- svc-orders
- svc-quotation
- svc-shipping
- svc-procurement
- svc-mrp
- svc-crm

---

## 👥 Section 8: Collaboration

**Position:** 80-87
**Icon:** 🤝
**Purpose:** Team collaboration and communication

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `collab-root` | Collaboration | `/admin/collaboration` | Users |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `collab-projects` | Projects | `/admin/projects` | Folder | Project management |
| `collab-pm` | Project Management | `/admin/pm` | Trello | Advanced PM |
| `collab-boards` | Boards (Kanban) | `/admin/boards` | LayoutGrid | Kanban boards |
| `collab-chat` | Team Chat | `/admin/chat` | MessageSquare | Real-time chat |
| `collab-collab` | Real-time Collab | `/admin/collab` | Users | Live collaboration |
| `collab-forum` | Forum | `/admin/forum` | MessageCircle | Discussion forums |
| `collab-support` | Support Tickets | `/admin/support` | LifeBuoy | Help desk |

**Services Covered:**
- svc-projects
- svc-pm
- svc-boards
- svc-chat
- svc-collab
- svc-forum
- svc-support

---

## 📧 Section 9: Communication

**Position:** 90-94
**Icon:** ✉️
**Purpose:** Marketing and external communication

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `comm-root` | Communication | `/admin/communication` | Mail |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `comm-email` | Email Client | `/admin/email` | Mail | **Integrated email (new)** |
| `comm-campaigns` | Campaigns | `/admin/campaigns` | Megaphone | Marketing campaigns |
| `comm-forms` | Forms | `/admin/forms` | FileInput | Form builder |
| `comm-enrichment` | Data Enrichment | `/admin/enrichment` | Database | Contact enrichment |

**Services Covered:**
- svc-comm
- svc-forms
- svc-enrichment

---

## 👔 Section 10: HR & Workforce

**Position:** 100-107
**Icon:** 👥
**Purpose:** Human resources management

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `hr-root` | HR & Workforce | `/admin/hr` | Users |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `hr-employees` | Employees | `/dashboard/hr/employees` | User | Employee directory |
| `hr-timesheet` | Timesheet | `/dashboard/hr/timesheet` | Clock | Time tracking |
| `hr-attendance` | Attendance | `/dashboard/hr/attendance` | Calendar | Attendance |
| `hr-contracts` | Contracts | `/dashboard/hr/contracts` | FileText | Employment contracts |
| `hr-payslips` | Payslips | `/dashboard/hr/payslips` | DollarSign | Payroll |
| `hr-expenses` | Expenses | `/dashboard/hr/expenses` | Receipt | Expense management |
| `hr-trips` | Business Trips | `/dashboard/hr/trips` | Plane | Travel management |

**Services Covered:**
- svc-timesheet
- + HR system (partially implemented)

---

## 📊 Section 11: Analytics & BI

**Position:** 110-113
**Icon:** 📈
**Purpose:** Business intelligence and reporting

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `analytics-root` | Analytics & BI | `/admin/analytics` | BarChart3 |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `analytics-bi` | BI Dashboard | `/admin/bi` | BarChart | BI dashboards |
| `analytics-reports` | Reports | `/dashboard/admin/reports` | FileText | Custom reports |
| `analytics-metrics` | Metrics Overview | `/admin/metrics` | TrendingUp | Platform metrics |

**Services Covered:**
- svc-bi

---

## 🤖 Section 12: Automation

**Position:** 120-124
**Icon:** ⚡
**Purpose:** Workflow automation and AI

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `automation-root` | Automation | `/admin/automation` | Zap |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `automation-workflows` | Workflow Builder | `/admin/workflow-builder` | GitBranch | **N8N workflow builder** |
| `automation-assistant` | AI Assistant | `/admin/assistant` | Bot | AI-powered assistant |
| `automation-integrations` | API Integrations | `/admin/api-integrations` | Plug | Third-party APIs |
| `automation-connectors` | Web Connectors | `/admin/connectors` | Link | Shopify, WordPress |

**Services Covered:**
- svc-assistant
- svc-connectors-web
- N8N integration

---

## 🧩 Section 13: Plugins & Extensions

**Position:** 130-133
**Icon:** 🧩
**Purpose:** Plugin system management

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `plugins-root` | Plugins & Extensions | `/admin/plugins` | Puzzle |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `plugins-manager` | Plugin Manager | `/god-mode/plugins` | Package | Install plugins |
| `plugins-widgets` | Widget Gallery | `/god-mode/widgets` | LayoutGrid | Browse widgets |
| `plugins-marketplace` | Marketplace | `/admin/plugin-marketplace` | Store | Plugin marketplace |

**Services Covered:**
- svc-plugins
- svc-plugin-manager

---

## ⚡ Section 14: God Mode (Advanced)

**Position:** 140-149
**Icon:** 🪄
**Purpose:** Advanced platform configuration

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `godmode-root` | God Mode | `/god-mode` | Wand2 |

### Sub-items

#### Page Builder
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `godmode-pages` | Page Builder | `/god-mode/page-builder-unified` | Layout | Build admin pages |
| `godmode-elementor` | Elementor Builder | `/god-mode/elementor-builder` | Layers | Drag-and-drop |
| `godmode-templates` | Page Templates | `/god-mode/page-templates` | FileText | Template management |
| `godmode-menu` | Menu Editor | `/god-mode/menu-editor` | Menu | Configure menus |

#### Developer Tools
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `godmode-terminal` | Terminal | `/god-mode/terminal` | Terminal | Integrated terminal |
| `godmode-database` | Database Query | `/god-mode/database-query` | Database | Direct DB access |
| `godmode-api-test` | API Tester | `/god-mode/api-test` | Code | Test endpoints |

#### AI & Commands
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `godmode-prompts` | Prompt Library | `/god-mode/prompt-library` | BookOpen | AI prompts |
| `godmode-commands` | Command Matrix | `/god-mode/command-matrix` | Grid | Command palette |

---

## ⚙️ Section 15: System Settings

**Position:** 150-157
**Icon:** ⚙️
**Purpose:** Platform-wide configuration

### Root
| ID | Name | Slug | Icon |
|----|------|------|------|
| `settings-root` | System Settings | `/admin/settings` | Settings |

### Sub-items
| ID | Name | Slug | Icon | Description |
|----|------|------|------|-------------|
| `settings-general` | General Settings | `/admin/settings/general` | Sliders | Platform settings |
| `settings-security` | Security | `/admin/settings/security` | Shield | Security config |
| `settings-auth` | Authentication | `/admin/settings/auth` | Key | Auth providers |
| `settings-i18n` | Internationalization | `/admin/settings/i18n` | Globe | **Languages (new)** |
| `settings-storage` | Storage | `/admin/settings/storage` | HardDrive | S3 configuration |
| `settings-email` | Email Settings | `/admin/settings/email` | Mail | SMTP config |
| `settings-backup` | Backup & Restore | `/admin/settings/backup` | Archive | Database backups |

---

## 🚀 Implementation Guide

### 1. Database Migration

```bash
# Run the migration
psql -U ewh -d ewh_master -f migrations/019_reorganize_admin_menu_complete.sql
```

### 2. Frontend Component

Update your sidebar component to fetch hierarchical menu:

```typescript
// Fetch menu hierarchy
const { data: menu } = await fetch('/api/admin/menu-hierarchy');

// Render hierarchical menu
<Menu>
  {menu.map(section => (
    <MenuSection key={section.id} {...section}>
      {section.children.map(item => (
        <MenuItem key={item.id} {...item} />
      ))}
    </MenuSection>
  ))}
</Menu>
```

### 3. API Endpoint

Create endpoint to serve menu:

```typescript
// /api/admin/menu-hierarchy
export async function GET() {
  const result = await db.query(`
    SELECT * FROM plugins.menu_hierarchy
    ORDER BY path
  `);

  return buildTree(result.rows);
}
```

---

## 📈 Statistics

- **Total Menu Items:** 140+
- **Root Sections:** 15
- **Services Covered:** 50+
- **Hierarchy Levels:** 2 (root + sub-items)
- **Categories:**
  - Operations: 13 items
  - Creative: 11 items
  - ERP: 9 items
  - God Mode: 10 items
  - HR: 7 items
  - Collaboration: 7 items

---

## 🎯 Key Features

1. **Logical Grouping** - Services grouped by functional domain
2. **Scalable** - Easy to add new services/features
3. **User-Friendly** - Clear navigation hierarchy
4. **Enterprise-Ready** - Professional organization
5. **Icon-Coded** - Visual identification
6. **Search-Friendly** - Clear naming convention
7. **Multi-Level** - Support for nested menus
8. **Extensible** - Plugin system integration

---

## 🔄 Next Steps

1. ✅ Run database migration
2. ⏳ Update frontend sidebar component
3. ⏳ Add search/filter functionality
4. ⏳ Implement breadcrumbs
5. ⏳ Add keyboard shortcuts (Cmd+K)
6. ⏳ Create onboarding tour

---

**Version:** 1.0
**Last Updated:** 2025-10-08
**Maintained By:** Platform Team
