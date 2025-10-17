-- Migration: Local Development Credentials
-- Description: Create local development users for testing
-- Date: 2025-01-17

-- =====================================================
-- LOCAL DEVELOPMENT USERS
-- =====================================================

-- This migration creates local development credentials
-- DO NOT run this in production!

-- Owner user: fabio.polosa@gmail.com / 1234saas
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_user_meta_data
)
VALUES (
  gen_random_uuid(),
  'fabio.polosa@gmail.com',
  crypt('1234saas', gen_salt('bf')), -- bcrypt hash
  now(),
  now(),
  now(),
  jsonb_build_object(
    'full_name', 'Fabio Polosa',
    'platform_role', 'owner',
    'avatar_url', null
  )
)
ON CONFLICT (email) DO UPDATE
SET
  encrypted_password = EXCLUDED.encrypted_password,
  raw_user_meta_data = EXCLUDED.raw_user_meta_data;

-- Tenant admin user: edizioniwhiteholesrl@gmail.com / 1234saas
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_user_meta_data
)
VALUES (
  gen_random_uuid(),
  'edizioniwhiteholesrl@gmail.com',
  crypt('1234saas', gen_salt('bf')), -- bcrypt hash
  now(),
  now(),
  now(),
  jsonb_build_object(
    'full_name', 'Edizioni White Hole',
    'platform_role', 'tenant_admin',
    'avatar_url', null
  )
)
ON CONFLICT (email) DO UPDATE
SET
  encrypted_password = EXCLUDED.encrypted_password,
  raw_user_meta_data = EXCLUDED.raw_user_meta_data;

-- =====================================================
-- DEVELOPMENT TENANT
-- =====================================================

-- Create a default development tenant for testing
INSERT INTO public.tenants (
  id,
  org_id,
  name,
  slug,
  tier,
  status,
  created_at,
  updated_at
)
VALUES (
  gen_random_uuid(),
  'ewh-dev',
  'EWH Development Tenant',
  'ewh-dev',
  'trial',
  'active',
  now(),
  now()
)
ON CONFLICT (org_id) DO UPDATE
SET
  name = EXCLUDED.name,
  status = EXCLUDED.status;

-- =====================================================
-- ASSIGN USERS TO TENANT
-- =====================================================

-- Assign owner to tenant
INSERT INTO public.tenant_users (
  tenant_id,
  user_id,
  role,
  created_at
)
SELECT
  t.id,
  u.id,
  'owner',
  now()
FROM public.tenants t
CROSS JOIN auth.users u
WHERE t.org_id = 'ewh-dev'
  AND u.email = 'fabio.polosa@gmail.com'
ON CONFLICT (tenant_id, user_id) DO UPDATE
SET role = EXCLUDED.role;

-- Assign tenant admin to tenant
INSERT INTO public.tenant_users (
  tenant_id,
  user_id,
  role,
  created_at
)
SELECT
  t.id,
  u.id,
  'admin',
  now()
FROM public.tenants t
CROSS JOIN auth.users u
WHERE t.org_id = 'ewh-dev'
  AND u.email = 'edizioniwhiteholesrl@gmail.com'
ON CONFLICT (tenant_id, user_id) DO UPDATE
SET role = EXCLUDED.role;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify users were created
DO $$
DECLARE
  owner_count INT;
  admin_count INT;
BEGIN
  SELECT COUNT(*) INTO owner_count
  FROM auth.users
  WHERE email = 'fabio.polosa@gmail.com';

  SELECT COUNT(*) INTO admin_count
  FROM auth.users
  WHERE email = 'edizioniwhiteholesrl@gmail.com';

  IF owner_count = 0 THEN
    RAISE EXCEPTION 'Owner user was not created';
  END IF;

  IF admin_count = 0 THEN
    RAISE EXCEPTION 'Admin user was not created';
  END IF;

  RAISE NOTICE 'Local dev credentials created successfully';
  RAISE NOTICE 'Owner: fabio.polosa@gmail.com / 1234saas';
  RAISE NOTICE 'Tenant Admin: edizioniwhiteholesrl@gmail.com / 1234saas';
END $$;

-- =====================================================
-- NOTES
-- =====================================================

-- For staging/production environments:
-- 1. DO NOT run this migration
-- 2. Users should register normally
-- 3. Force password change on first login
-- 4. Use stronger passwords
-- 5. Enable MFA for all users

-- =====================================================
-- ROLLBACK (if needed)
-- =====================================================

-- Uncomment to remove test users:
--
-- DELETE FROM public.tenant_users
-- WHERE user_id IN (
--   SELECT id FROM auth.users
--   WHERE email IN ('fabio.polosa@gmail.com', 'edizioniwhiteholesrl@gmail.com')
-- );
--
-- DELETE FROM auth.users
-- WHERE email IN ('fabio.polosa@gmail.com', 'edizioniwhiteholesrl@gmail.com');
--
-- DELETE FROM public.tenants
-- WHERE org_id = 'ewh-dev';
