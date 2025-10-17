import React, { useState } from 'react';
import { Database, Server, Globe, Users, Shield, Package, Layers, GitBranch, Cpu, HardDrive, Zap, Video, Mail, Calendar } from 'lucide-react';

const ArchitectureCanvas = () => {
  const [activeTab, setActiveTab] = useState('overview');

  const tabs = [
    { id: 'overview', label: 'Overview', icon: Layers },
    { id: 'services', label: 'Servizi', icon: Server },
    { id: 'new', label: 'Nuovi', icon: Package },
    { id: 'suites', label: 'Suite', icon: Package },
    { id: 'database', label: 'Database', icon: Database },
    { id: 'frontend', label: 'Frontend', icon: Globe },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
      <div className="max-w-7xl mx-auto p-6">
        <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
          <h1 className="text-3xl font-bold text-slate-900 mb-2">
            EWH Platform - Mega Architecture 3.0
          </h1>
          <p className="text-slate-600 mb-4">
            SaaS B2B Multi-Tenant Enterprise con Plugin System + Meta-Platform
          </p>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3 text-sm">
            <div className="flex items-center gap-2 bg-green-50 px-3 py-2 rounded">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="font-semibold">90 Servizi</span>
            </div>
            <div className="flex items-center gap-2 bg-blue-50 px-3 py-2 rounded">
              <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
              <span className="font-semibold">77+ Frontend</span>
            </div>
            <div className="flex items-center gap-2 bg-purple-50 px-3 py-2 rounded">
              <div className="w-3 h-3 bg-purple-500 rounded-full"></div>
              <span className="font-semibold">12 Suite</span>
            </div>
            <div className="flex items-center gap-2 bg-orange-50 px-3 py-2 rounded">
              <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
              <span className="font-semibold">4 DB Layer</span>
            </div>
            <div className="flex items-center gap-2 bg-red-50 px-3 py-2 rounded">
              <div className="w-3 h-3 bg-red-500 rounded-full"></div>
              <span className="font-semibold">Self-Modifying</span>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-lg mb-6">
          <div className="flex overflow-x-auto border-b">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-6 py-4 font-medium transition-colors whitespace-nowrap ${
                    activeTab === tab.id
                      ? 'text-blue-600 border-b-2 border-blue-600'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <Icon size={18} />
                  {tab.label}
                </button>
              );
            })}
          </div>

          <div className="p-6">
            {activeTab === 'overview' && <OverviewTab />}
            {activeTab === 'services' && <ServicesTab />}
            {activeTab === 'new' && <NewServicesTab />}
            {activeTab === 'suites' && <SuitesTab />}
            {activeTab === 'database' && <DatabaseTab />}
            {activeTab === 'frontend' && <FrontendTab />}
          </div>
        </div>
      </div>
    </div>
  );
};

const OverviewTab = () => (
  <div className="space-y-6">
    <div className="bg-gradient-to-r from-purple-600 to-pink-600 text-white p-6 rounded-lg">
      <h2 className="text-2xl font-bold mb-3">🚀 Meta-Platform Architecture</h2>
      <p className="text-lg opacity-90">
        La piattaforma che si auto-modifica: costruisci database, UI e workflow visivamente.
        Nessun codice necessario per creare nuove app!
      </p>
    </div>

    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div className="bg-gradient-to-br from-blue-50 to-blue-100 p-6 rounded-lg">
        <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
          <Server className="text-blue-600" size={24} />
          Backend Architecture
        </h3>
        <div className="space-y-2 text-sm">
          <div className="font-semibold text-blue-900">90 Servizi Microservizi</div>
          <div>✅ 3 Automation Core (workflow, approval, webhook)</div>
          <div>✅ 12 Shared Services (contacts, comm, AI, storage...)</div>
          <div>✅ 7 Creative Suite (image, RAW, video, canvas, mockup...)</div>
          <div>✅ 5 Communication Suite (email, newsletter, VoIP...)</div>
          <div>✅ 3 Content Suite (text, CMS, multi-site)</div>
          <div>✅ 11 Business Ops (HR, accounting, warehouse, quotes...)</div>
          <div>✅ 8 Domain Services (CRM, PM, DAM, PIM, DMS...)</div>
          <div>✅ 4 Client Portal (portal, tracking, documents...)</div>
          <div>✅ 6 Ecommerce (shop, payments, reviews...)</div>
          <div>✅ 3 Production (storyboard, script, docs...)</div>
          <div>✅ 5 Notion-like DB (database, blocks, collaboration...)</div>
          <div>✅ 7 Notes & Productivity (notes, time tracking, mind maps...)</div>
          <div>✅ 11 AI & Automations (assistant, image gen, sync...)</div>
          <div>✅ 5 Platform & Security (marketplace, mobile, security...)</div>
        </div>
      </div>

      <div className="bg-gradient-to-br from-purple-50 to-purple-100 p-6 rounded-lg">
        <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
          <Globe className="text-purple-600" size={24} />
          Frontend Architecture
        </h3>
        <div className="space-y-2 text-sm">
          <div className="font-semibold text-purple-900">77+ Frontend Apps</div>
          <div>✅ 2 Shell (Tenant + Admin)</div>
          <div>✅ 7 Creative Apps (image, RAW, video, canvas...)</div>
          <div>✅ 5 Communication Apps (email, newsletter...)</div>
          <div>✅ 5 Builder Apps (workflow, DB, dashboard, mind maps...)</div>
          <div>✅ 12 Domain Apps (CRM, PM, HR, DMS, Ecommerce...)</div>
          <div>✅ 11 Business Ops (warehouse, quotes, multi-site...)</div>
          <div>✅ 20+ New Apps (social, meetings, security, notes...)</div>
          <div>✅ @ewh/ui-components (libreria universale)</div>
        </div>
      </div>

      <div className="bg-gradient-to-br from-orange-50 to-orange-100 p-6 rounded-lg">
        <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
          <Database className="text-orange-600" size={24} />
          Database Strategy
        </h3>
        <div className="space-y-2 text-sm">
          <div>✅ <strong>DB Auth</strong> - Utenti e autenticazione</div>
          <div>✅ <strong>DB Core</strong> - Config sistema per servizio</div>
          <div>✅ <strong>DB Tenant</strong> - Multi-schema clienti base</div>
          <div>✅ <strong>DB Dedicati</strong> - Clienti enterprise</div>
          <div>✅ <strong>Custom Tables</strong> - Visual DB Editor (Xano-like)</div>
          <div className="pt-2 font-semibold">RLS + org_id isolation totale</div>
        </div>
      </div>

      <div className="bg-gradient-to-br from-green-50 to-green-100 p-6 rounded-lg">
        <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
          <Zap className="text-green-600" size={24} />
          Meta-Platform Features
        </h3>
        <div className="space-y-2 text-sm">
          <div>✅ <strong>Visual DB Editor</strong> - Crea tabelle senza SQL</div>
          <div>✅ <strong>Auto API Generation</strong> - CRUD automatico</div>
          <div>✅ <strong>Workflow Editor</strong> - n8n-like, node-based</div>
          <div>✅ <strong>Dashboard Builder</strong> - Compose widget drag&drop</div>
          <div>✅ <strong>Page Builder</strong> - WYSIWYG interno</div>
          <div>✅ <strong>Plugin System</strong> - Hot reload, no restart</div>
        </div>
      </div>
    </div>

    <div className="bg-gradient-to-r from-slate-800 to-slate-900 text-white p-6 rounded-lg">
      <h3 className="font-bold text-xl mb-4">🎯 Killer Features</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
        <div>
          <div className="font-semibold mb-2">🔌 Plugin-First</div>
          <p className="text-slate-300">Zero modifiche al core, tutto estendibile via plugin in-process</p>
        </div>
        <div>
          <div className="font-semibold mb-2">🔥 Hot Reload</div>
          <p className="text-slate-300">Modifica plugin senza restart servizio, deploy in 200ms</p>
        </div>
        <div>
          <div className="font-semibold mb-2">🎨 Visual Everything</div>
          <p className="text-slate-300">DB, workflows, dashboards, pages: tutto costruibile visualmente</p>
        </div>
        <div>
          <div className="font-semibold mb-2">🤖 AI Native</div>
          <p className="text-slate-300">AI engine centralizzato per text, image, translation, analytics</p>
        </div>
        <div>
          <div className="font-semibold mb-2">🔒 Enterprise Security</div>
          <p className="text-slate-300">Multi-tenant, RLS, SSO, audit trail, GDPR compliant</p>
        </div>
        <div>
          <div className="font-semibold mb-2">📦 Self-Modifying</div>
          <p className="text-slate-300">La piattaforma può creare nuove app dall'interno, no-code</p>
        </div>
        <div>
          <div className="font-semibold mb-2">📊 Notion-like DB</div>
          <p className="text-slate-300">Database visuale con views multiple, formulas, relations</p>
        </div>
        <div>
          <div className="font-semibold mb-2">🧠 Mind Maps</div>
          <p className="text-slate-300">Visual thinking board stile Milanote per brainstorming</p>
        </div>
        <div>
          <div className="font-semibold mb-2">📷 RAW Editor</div>
          <p className="text-slate-300">Editor fotografico professionale Lightroom-like</p>
        </div>
      </div>
    </div>
  </div>
);

const ServiceCard = ({ name, port, desc, color }) => (
  <div className={`bg-${color}-50 border border-${color}-200 rounded-lg p-4`}>
    <div className="flex items-start justify-between mb-2">
      <div className="font-bold text-sm">{name}</div>
      <Server size={16} className={`text-${color}-600 flex-shrink-0`} />
    </div>
    <div className="text-xs text-slate-600 mb-2">{desc}</div>
    <div className={`text-xs font-mono bg-${color}-100 px-2 py-1 rounded inline-block`}>
      :{port}
    </div>
  </div>
);

const ServicesTab = () => (
  <div className="space-y-6">
    <div className="bg-blue-50 p-4 rounded-lg border-l-4 border-blue-500">
      <p className="text-sm font-medium">
        <strong>90 Servizi Backend</strong> organizzati in suite logiche. 
        Ogni servizio = 1 istanza con Core + Plugin system in-process.
      </p>
    </div>

    <div>
      <h3 className="font-bold text-lg mb-3 text-red-600">⚡ AUTOMATION CORE (3)</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ServiceCard name="svc-workflow-engine" port="4900" desc="Node-based automation (n8n-like)" color="red" />
        <ServiceCard name="svc-approvals" port="4409" desc="Multi-level approval system" color="red" />
        <ServiceCard name="svc-webhooks" port="4910" desc="Webhook orchestration" color="red" />
      </div>
    </div>

    <div>
      <h3 className="font-bold text-lg mb-3 text-blue-600">🔧 SHARED SERVICES (12)</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ServiceCard name="svc-contacts" port="4600" desc="Rubrica universale" color="blue" />
        <ServiceCard name="svc-comm" port="4700" desc="Email, SMS, Push, In-app" color="blue" />
        <ServiceCard name="svc-analytics" port="4710" desc="BI e metriche" color="blue" />
        <ServiceCard name="svc-search" port="4720" desc="Full-text + semantic search" color="blue" />
        <ServiceCard name="svc-ai-engine" port="4730" desc="GPT, image gen, OCR" color="blue" />
        <ServiceCard name="svc-storage" port="4740" desc="File storage abstraction" color="blue" />
        <ServiceCard name="svc-translation" port="4750" desc="Translation management" color="blue" />
        <ServiceCard name="svc-forms" port="4760" desc="Form builder & submission" color="blue" />
        <ServiceCard name="svc-audit" port="4770" desc="Audit trail universale" color="blue" />
        <ServiceCard name="svc-visual-db" port="4850" desc="Visual DB editor (Xano-like)" color="blue" />
        <ServiceCard name="svc-dashboard-builder" port="4860" desc="Dashboard composer" color="blue" />
        <ServiceCard name="svc-page-builder-backend" port="4870" desc="Page builder backend" color="blue" />
      </div>
    </div>

    <div>
      <h3 className="font-bold text-lg mb-3 text-purple-600">🎨 CREATIVE SUITE (7)</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ServiceCard name="svc-image-editor" port="4920" desc="Image editor (Photoshop-like)" color="purple" />
        <ServiceCard name="svc-raw-editor" port="5505" desc="RAW photo editor (Lightroom-like)" color="purple" />
        <ServiceCard name="svc-video-editor" port="4930" desc="Video editor cloud" color="purple" />
        <ServiceCard name="svc-canvas" port="4940" desc="Quick design (Canva-like)" color="purple" />
        <ServiceCard name="svc-mockup-generator" port="4950" desc="Product mockups" color="purple" />
        <ServiceCard name="svc-prepress" port="4960" desc="Pre-stampa validation" color="purple" />
        <ServiceCard name="svc-dtp" port="4830" desc="Desktop publishing" color="purple" />
      </div>
    </div>

    <div>
      <h3 className="font-bold text-lg mb-3 text-green-600">📧 COMMUNICATION SUITE (5)</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ServiceCard name="svc-email-server" port="4970" desc="SMTP + IMAP completo" color="green" />
        <ServiceCard name="svc-cold-email" port="4980" desc="Cold email campaigns" color="green" />
        <ServiceCard name="svc-newsletter" port="4990" desc="Newsletter (SendGrid)" color="green" />
        <ServiceCard name="svc-scraping" port="5000" desc="Web scraping + enrichment + email validation" color="green" />
        <ServiceCard name="svc-voip" port="5080" desc="VoIP + SIP server" color="green" />
      </div>
    </div>

    <div>
      <h3 className="font-bold text-lg mb-3 text-orange-600">📝 CONTENT SUITE (3)</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ServiceCard name="svc-text-editor" port="5010" desc="Text + AI-enhanced" color="orange" />
        <ServiceCard name="svc-multi-site" port="5020" desc="Multi-site publishing" color="orange" />
        <ServiceCard name="svc-cms" port="4200" desc="Headless CMS" color="orange" />
      </div>
    </div>

    <div>
      <h3 className="font-bold text-lg mb-3 text-pink-600">🏢 BUSINESS OPS (11)</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ServiceCard name="svc-shipping" port="5030" desc="Carrier integration" color="pink" />
        <ServiceCard name="svc-fleet" port="5040" desc="Fleet management" color="pink" />
        <ServiceCard name="svc-hr" port="5050" desc="HR completo" color="pink" />
        <ServiceCard name="svc-invoicing" port="5060" desc="Fatturazione" color="pink" />
        <ServiceCard name="svc-accounting" port="5070" desc="Contabilità" color="pink" />
        <ServiceCard name="svc-billing" port="4004" desc="Stripe + subscriptions" color="pink" />
        <ServiceCard name="svc-warehouse-advanced" port="5255" desc="WMS avanzato" color="pink" />
        <ServiceCard name="svc-multi-location" port="5250" desc="Multi-sede management" color="pink" />
        <ServiceCard name="svc-inventory-multi" port="5260" desc="Multi-magazzino inventory" color="pink" />
        <ServiceCard name="svc-quotes-out" port="5265" desc="Preventivazione vendita" color="pink" />
        <ServiceCard name="svc-quotes-in" port="5270" desc="Preventivazione acquisto/RFQ" color="pink" />
      </div>
    </div>

    <div>
      <h3 className="font-bold text-lg mb-3 text-indigo-600">📊 DOMAIN SERVICES (8)</h3>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <ServiceCard name="svc-dam" port="4100" desc="Digital Asset Management" color="indigo" />
        <ServiceCard name="svc-crm" port="4800" desc="Customer Relationship" color="indigo" />
        <ServiceCard name="svc-mrp" port="4810" desc="Material Planning" color="indigo" />
        <ServiceCard name="svc-pim" port="4820" desc="Product Info Management" color="indigo" />
        <ServiceCard name="svc-pm" port="4400" desc="Project Management" color="indigo" />
        <ServiceCard name="svc-wysiwyg" port="4840" desc="Page editor engine" color="indigo" />
        <ServiceCard name="svc-call-center" port="5090" desc="Call center software" color="indigo" />
        <ServiceCard name="svc-booking" port="5100" desc="Booking system" color="indigo" />
      </div>
    </div>
  </div>
);

const NewServicesTab = () => (
  <div className="space-y-6">
    <div className="bg-gradient-to-r from-red-600 to-pink-600 text-white p-6 rounded-lg">
      <h2 className="text-2xl font-bold mb-2">🆕 47 Nuovi Servizi Aggiunti</h2>
      <p>Completano la piattaforma con Notion-like DB, Mind Maps, RAW Editor e molto altro!</p>
    </div>

    <div className="bg-yellow-50 border-l-4 border-yellow-500 p-4 rounded">
      <div className="font-semibold mb-2">📊 Crescita della Piattaforma</div>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
        <div><strong>90</strong> Servizi Backend (43 → 90, +47)</div>
        <div><strong>77+</strong> Frontend Apps (30 → 77+, +47)</div>
        <div><strong>12</strong> Suite Complete (6 → 12, +6)</div>
        <div><strong>100%</strong> Coverage Enterprise + B2C + Creative</div>
      </div>
    </div>

    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {[
        { cat: 'Document Management', count: 2, services: 'DMS, E-Sign' },
        { cat: 'Multi-Location & Warehouse', count: 3, services: 'Multi-location, WMS, Inventory' },
        { cat: 'Quotation Systems', count: 2, services: 'Quotes Out, Quotes In' },
        { cat: 'Social & Engagement', count: 2, services: 'Social Media, Gamification' },
        { cat: 'Meetings & Collaboration', count: 3, services: 'Meetings, Calendar, Chat' },
        { cat: 'Knowledge & Learning', count: 2, services: 'Knowledge Base, LMS' },
        { cat: 'Analytics & Goals', count: 2, services: 'OKRs, BI' },
        { cat: 'Platform & Security', count: 4, services: 'Notifications, Marketplace, Security, Mobile Builder' },
        { cat: 'Client Portal', count: 4, services: 'Portal, Document Sharing, Project Tracking, Order Tracking' },
        { cat: 'AI Assistant & Help', count: 3, services: 'AI Assistant, Context Help, Helpdesk' },
        { cat: 'Ecommerce Suite', count: 6, services: 'Shop, Payments, Promotions, Reviews, Wishlist, Recommendations' },
        { cat: 'Creative Production', count: 3, services: 'Storyboard, Script Writer, Production Docs' },
        { cat: 'AI Image Generation', count: 2, services: 'AI Image Advanced, AI Enhancement' },
        { cat: 'PDF & Documents', count: 2, services: 'PDF Engine, Document Templates' },
        { cat: 'Email Validation', count: 1, services: 'Email Validation' },
        { cat: 'Notion-like Database', count: 5, services: 'Notion DB, Blocks, Collab, Workspace, AI' },
        { cat: 'Notes & Annotations', count: 3, services: 'Notes, Annotations, Bookmarks' },
        { cat: 'Productivity & Time', count: 4, services: 'Time Tracking, Reminders, Templates, Focus' },
        { cat: 'Linking & Relationships', count: 2, services: 'Relationships, Mentions' },
        { cat: 'Database Automations', count: 5, services: 'Automations, Sync, Forms, Reports, Permissions' },
        { cat: 'Mind Mapping', count: 1, services: 'Mind Maps (Milanote-like)' },
        { cat: 'Photo Editing', count: 1, services: 'RAW Editor (Lightroom-like)' },
      ].map((item, i) => (
        <div key={i} className="bg-white border-2 border-blue-300 rounded-lg p-4">
          <div className="text-2xl font-bold text-blue-600 mb-1">{item.count}</div>
          <div className="font-bold text-sm mb-2">{item.cat}</div>
          <div className="text-xs text-slate-600">{item.services}</div>
        </div>
      ))}
    </div>
  </div>
);

const SuitesTab = () => (
  <div className="space-y-6">
    <div className="bg-gradient-to-r from-purple-600 to-pink-600 text-white p-6 rounded-lg">
      <h2 className="text-2xl font-bold mb-2">12 Suite Integrate</h2>
      <p>Ogni suite condivide servizi comuni per evitare duplicazioni</p>
    </div>

    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {[
        { name: 'Automation Core', count: 3, desc: 'Workflow, Approvals, Webhooks - Il cuore del sistema' },
        { name: 'Creative Suite', count: 7, desc: 'Image, RAW, Video, Canvas, Mockup, Prepress, DTP' },
        { name: 'Communication Suite', count: 5, desc: 'Email, Cold Email, Newsletter, VoIP, Scraping' },
        { name: 'Content Suite', count: 3, desc: 'Text Editor, CMS, Multi-Site publishing' },
        { name: 'Business Ops Suite', count: 11, desc: 'HR, Invoicing, Warehouse, Quotes, Inventory, Shipping' },
        { name: 'Domain Suite', count: 8, desc: 'DAM, CRM, MRP, PIM, PM, Call Center, Booking' },
        { name: 'Client Portal Suite', count: 4, desc: 'Portal, Document Sharing, Project & Order Tracking' },
        { name: 'Ecommerce Suite', count: 6, desc: 'Shop, Payments, Promotions, Reviews, Wishlist, AI Recommendations' },
        { name: 'Production Suite', count: 3, desc: 'Storyboard, Script Writer, Production Docs (StudioBinder-like)' },
        { name: 'AI Assistant Suite', count: 3, desc: 'AI Assistant, Context Help, Helpdesk' },
        { name: 'Notion-like Suite', count: 5, desc: 'Database, Blocks, Collaboration, Workspace, AI Writing' },
        { name: 'Productivity Suite', count: 7, desc: 'Notes, Time Tracking, Reminders, Templates, Focus, Mind Maps' },
      ].map((suite, i) => (
        <div key={i} className="bg-gradient-to-br from-blue-50 to-blue-100 border-2 border-blue-300 rounded-lg p-5">
          <div className="flex items-center justify-between mb-3">
            <div className="font-bold text-lg">{suite.name}</div>
            <div className="text-2xl font-bold text-blue-600">{suite.count}</div>
          </div>
          <div className="text-sm text-slate-600">{suite.desc}</div>
        </div>
      ))}
    </div>
  </div>
);

const DatabaseTab = () => (
  <div className="space-y-6">
    <div className="bg-gradient-to-r from-orange-600 to-red-600 text-white p-6 rounded-lg">
      <h3 className="font-bold text-xl mb-3">🗄️ Architettura Database a 4 Layer + Custom Tables</h3>
      <p className="text-sm opacity-90">
        Strategia ibrida ottimizzata: multi-schema per efficienza, DB dedicati per isolamento, custom tables per no-code
      </p>
    </div>

    <div className="grid grid-cols-1 gap-4">
      <div className="bg-white border-2 border-blue-500 rounded-lg p-5">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
            <Shield className="text-blue-600" size={20} />
          </div>
          <div>
            <h4 className="font-bold text-lg">1. DB Auth (ewh_auth)</h4>
            <p className="text-sm text-slate-600">Utenti e autenticazione centralizzata</p>
          </div>
        </div>
        <div className="space-y-2 text-sm">
          <div><strong>users</strong> - email, password_hash, platform_role</div>
          <div><strong>sessions</strong> - JWT refresh tokens</div>
          <div><strong>oauth_providers</strong> - SSO integrations</div>
        </div>
      </div>

      <div className="bg-white border-2 border-green-500 rounded-lg p-5">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
            <Cpu className="text-green-600" size={20} />
          </div>
          <div>
            <h4 className="font-bold text-lg">2. DB Core per Servizio</h4>
            <p className="text-sm text-slate-600">Config e dati di sistema del servizio</p>
          </div>
        </div>
        <div className="text-sm">
          <div>Ogni servizio ha il suo DB core per templates, workflow definitions, config</div>
        </div>
      </div>

      <div className="bg-white border-2 border-purple-500 rounded-lg p-5">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
            <Users className="text-purple-600" size={20} />
          </div>
          <div>
            <h4 className="font-bold text-lg">3. DB Tenant Multi-Schema (ewh_tenant)</h4>
            <p className="text-sm text-slate-600">Clienti base - schema separati + custom tables</p>
          </div>
        </div>
        <div className="text-sm">
          <div className="mb-2"><strong>95% clienti SMB.</strong> Custom tables create via Visual DB Editor!</div>
          <div className="font-mono text-xs bg-purple-50 p-2 rounded">
            ewh_tenant.tenant_acme.custom_leads (Visual DB!)
          </div>
        </div>
      </div>

      <div className="bg-white border-2 border-orange-500 rounded-lg p-5">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
            <HardDrive className="text-orange-600" size={20} />
          </div>
          <div>
            <h4 className="font-bold text-lg">4. DB Dedicati Enterprise</h4>
            <p className="text-sm text-slate-600">Clienti enterprise - database separato</p>
          </div>
        </div>
        <div className="text-sm">
          <strong>5% clienti enterprise, 50% revenue</strong>
        </div>
      </div>
    </div>
  </div>
);

const FrontendTab = () => (
  <div className="space-y-6">
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div className="bg-gradient-to-br from-blue-500 to-blue-700 text-white rounded-lg p-6">
        <div className="flex items-center gap-3 mb-4">
          <Globe size={32} />
          <div>
            <h3 className="font-bold text-xl">Tenant Shell</h3>
            <p className="text-sm opacity-90">app.ewh.com:3150</p>
          </div>
        </div>
        <div className="space-y-2 text-sm">
          <div>✅ Business apps loader</div>
          <div>✅ White-label branding</div>
          <div>✅ Custom dashboard</div>
          <div>✅ Org switcher</div>
          <div>✅ SSO integration</div>
        </div>
      </div>

      <div className="bg-gradient-to-br from-red-500 to-red-700 text-white rounded-lg p-6">
        <div className="flex items-center gap-3 mb-4">
          <Shield size={32} />
          <div>
            <h3 className="font-bold text-xl">Admin Shell</h3>
            <p className="text-sm opacity-90">admin.ewh.com:3100</p>
          </div>
        </div>
        <div className="space-y-2 text-sm">
          <div>✅ Platform management</div>
          <div>✅ Tenant admin</div>
          <div>✅ System monitoring</div>
          <div>✅ Impersonate</div>
          <div>✅ Analytics globali</div>
        </div>
      </div>
    </div>

    <div className="bg-white border-2 border-slate-300 rounded-lg p-5">
      <h4 className="font-bold mb-4">🎨 77+ Frontend Apps Organizzate</h4>
      
      <div className="space-y-4">
        {[
          { cat: 'Creative (7)', apps: ['Image Editor', 'RAW Editor', 'Video Editor', 'Canvas', 'DTP Editor', 'Mockup Gen', 'DAM'] },
          { cat: 'Communication (5)', apps: ['Email Client', 'Newsletter', 'Cold Email', 'Scraping', 'Call Center'] },
          { cat: 'Builders (5)', apps: ['Workflow Editor', 'Visual DB Editor', 'Dashboard Builder', 'Page Builder', 'Mind Maps'] },
          { cat: 'Domain (12)', apps: ['CRM', 'PM', 'MRP', 'PIM', 'CMS', 'HR', 'Invoicing', 'Accounting', 'DMS', 'Ecommerce Shop', 'Client Portal', 'Production Suite'] },
          { cat: 'Productivity (7)', apps: ['Notes', 'Time Tracking', 'Reminders', 'Templates', 'Focus Mode', 'Bookmarks', 'Annotations'] },
        ].map((group, i) => (
          <div key={i}>
            <div className="font-semibold mb-2 text-blue-600">{group.cat}:</div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-sm">
              {group.apps.map((app, j) => (
                <div key={j} className="bg-blue-50 border border-blue-200 rounded px-3 py-2">{app}</div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  </div>
);

export default ArchitectureCanvas;