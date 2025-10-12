-- Migration: Seed Services from INFRASTRUCTURE_REGISTRY.json
-- Version: 002
-- Created: 2025-10-06
-- Description: Populate registry.services with current service definitions

INSERT INTO registry.services (name, type, description, port_default, critical) VALUES
  ('app-web-frontend', 'frontend', 'Main web application frontend', 3100, true),
  ('app-admin-frontend', 'frontend', 'Admin dashboard frontend', 3200, true),
  ('svc-api-gateway', 'gateway', 'API Gateway and routing', 4000, true),
  ('svc-auth', 'core', 'Authentication and authorization', 4001, true),
  ('svc-plugins', 'core', 'Plugin management', 4002, false),
  ('svc-media', 'core', 'Media processing and storage', 4003, false),
  ('svc-billing', 'core', 'Billing and invoicing', 4004, false),
  ('svc-metrics-collector', 'monitoring', 'Metrics collection and aggregation', 4010, false),
  ('svc-image-orchestrator', 'creative', 'Image processing orchestration', 4100, false),
  ('svc-job-worker', 'creative', 'Background job processing', 4101, false),
  ('svc-writer', 'creative', 'Document writing and editing', 4102, false),
  ('svc-content', 'creative', 'Content management', 4103, false),
  ('svc-layout', 'creative', 'Layout management', 4104, false),
  ('svc-prepress', 'creative', 'Prepress workflow', 4105, false),
  ('svc-vector-lab', 'creative', 'Vector graphics processing', 4106, false),
  ('svc-mockup', 'creative', 'Mockup generation', 4107, false),
  ('svc-video-orchestrator', 'creative', 'Video processing orchestration', 4108, false),
  ('svc-video-runtime', 'creative', 'Video processing runtime', 4109, false),
  ('svc-raster-runtime', 'creative', 'Raster image processing runtime', 4110, false),
  ('svc-projects', 'publishing', 'Project services', 4200, false),
  ('svc-search', 'publishing', 'Search and indexing', 4201, false),
  ('svc-site-builder', 'publishing', 'Website builder', 4202, false),
  ('svc-site-renderer', 'publishing', 'Website rendering', 4203, false),
  ('svc-site-publisher', 'publishing', 'Website publishing', 4204, false),
  ('svc-connectors-web', 'publishing', 'Web connectors and integrations', 4205, false),
  ('svc-products', 'erp', 'Product catalog', 4300, false),
  ('svc-orders', 'erp', 'Order management', 4301, false),
  ('svc-inventory', 'erp', 'Inventory management', 4302, false),
  ('svc-channels', 'erp', 'Multi-channel communication', 4303, false),
  ('svc-quotation', 'erp', 'Quote generation', 4304, false),
  ('svc-procurement', 'erp', 'Procurement', 4305, false),
  ('svc-mrp', 'erp', 'Material requirements planning', 4306, false),
  ('svc-shipping', 'erp', 'Shipping and logistics', 4307, false),
  ('svc-crm', 'erp', 'Customer relationship management', 4308, false),
  ('svc-pm', 'collab', 'Project management', 4400, false),
  ('svc-support', 'collab', 'Customer support', 4401, false),
  ('svc-chat', 'collab', 'Real-time chat', 4402, false),
  ('svc-boards', 'collab', 'Kanban and task boards', 4403, false),
  ('svc-kb', 'collab', 'Knowledge base', 4404, false),
  ('svc-collab', 'collab', 'Collaboration tools', 4405, false),
  ('svc-dms', 'collab', 'Document management system', 4406, false),
  ('svc-timesheet', 'collab', 'Time tracking', 4407, false),
  ('svc-forms', 'collab', 'Dynamic forms', 4408, false),
  ('svc-forum', 'collab', 'Forum and discussions', 4409, false),
  ('svc-assistant', 'collab', 'AI assistant services', 4410, false),
  ('svc-comm', 'platform', 'Communication services', 4500, false),
  ('svc-enrichment', 'platform', 'Content enrichment', 4501, false),
  ('svc-bi', 'platform', 'Business intelligence', 4502, false)
ON CONFLICT (name) DO NOTHING;

-- Log seed operation
INSERT INTO registry.service_events (service_id, event_type, severity, message, created_by)
SELECT id, 'service_registered', 'info', 'Service definition seeded from INFRASTRUCTURE_REGISTRY.json', 'migration_002'
FROM registry.services;

SELECT COUNT(*) as total_services FROM registry.services;
