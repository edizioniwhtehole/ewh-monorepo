-- Simple CMS Sample Data
-- Creates minimal sample data for demo/development

DO $$
DECLARE
  v_tenant_id UUID := '1845c89e-63c6-4be2-85bc-07c40bacdef9';
  v_user_id UUID;
  v_site_id UUID;
BEGIN

  -- Get user ID
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'fabio.polosa@gmail.com' LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User fabio.polosa@gmail.com not found';
  END IF;

  -- Create main site
  INSERT INTO cms.sites (
    tenant_id, name, description, site_type,
    primary_domain, is_primary, status, created_by, updated_by, published_at
  ) VALUES (
    v_tenant_id,
    'White Hole Corporate',
    'Main corporate website',
    'main',
    'whiteholesrl.localhost', true, 'active',
    v_user_id, v_user_id, NOW()
  ) ON CONFLICT (tenant_id) WHERE is_primary = true DO NOTHING
  RETURNING site_id INTO v_site_id;

  IF v_site_id IS NULL THEN
    SELECT site_id INTO v_site_id FROM cms.sites WHERE tenant_id = v_tenant_id AND is_primary = true LIMIT 1;
  END IF;

  -- Create blog site
  INSERT INTO cms.sites (
    tenant_id, name, description, site_type,
    primary_domain, status, created_by, updated_by, published_at
  ) VALUES (
    v_tenant_id,
    'Company Blog',
    'News and articles',
    'blog',
    'blog.whiteholesrl.localhost', 'active',
    v_user_id, v_user_id, NOW()
  ) ON CONFLICT (primary_domain) DO NOTHING;

  RAISE NOTICE 'Sample data created successfully!';
  RAISE NOTICE 'Main site ID: %', v_site_id;

END $$;
