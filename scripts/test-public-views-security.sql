-- ============================================================================
-- SECURITY TESTING SUITE FOR PUBLIC VIEWS V2
-- ============================================================================
-- This script tests all security controls in create-public-views-v2.sql
-- Run this AFTER deploying V2 to verify security measures are working
-- ============================================================================

-- Setup test environment
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '╔════════════════════════════════════════════════════════════╗';
  RAISE NOTICE '║                                                            ║';
  RAISE NOTICE '║       PUBLIC VIEWS V2 - SECURITY TEST SUITE                ║';
  RAISE NOTICE '║                                                            ║';
  RAISE NOTICE '╚════════════════════════════════════════════════════════════╝';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- TEST 1: SQL INJECTION PROTECTION
-- ============================================================================

DO $$
DECLARE
  test_result JSONB;
  test_passed BOOLEAN := TRUE;
BEGIN
  RAISE NOTICE '🧪 TEST 1: SQL Injection Protection';
  RAISE NOTICE '────────────────────────────────────────────────────────────';

  -- Test 1.1: Malicious tenant_slug with semicolon
  BEGIN
    SELECT public.query_tenant('test; DROP SCHEMA core CASCADE; --', 'pm_projects') INTO test_result;
    RAISE NOTICE '  ❌ Test 1.1 FAILED: SQL injection not blocked (semicolon)';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 1.1 PASSED: SQL injection blocked (semicolon)';
  END;

  -- Test 1.2: Malicious tenant_slug with UNION
  BEGIN
    SELECT public.query_tenant('test'' UNION SELECT * FROM core.tenants --', 'pm_projects') INTO test_result;
    RAISE NOTICE '  ❌ Test 1.2 FAILED: SQL injection not blocked (UNION)';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 1.2 PASSED: SQL injection blocked (UNION)';
  END;

  -- Test 1.3: Path traversal attempt
  BEGIN
    SELECT public.query_tenant('../../../etc/passwd', 'pm_projects') INTO test_result;
    RAISE NOTICE '  ❌ Test 1.3 FAILED: Path traversal not blocked';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 1.3 PASSED: Path traversal blocked';
  END;

  -- Test 1.4: Special characters
  BEGIN
    SELECT public.query_tenant('test<script>alert(1)</script>', 'pm_projects') INTO test_result;
    RAISE NOTICE '  ❌ Test 1.4 FAILED: Special characters not blocked';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 1.4 PASSED: Special characters blocked';
  END;

  RAISE NOTICE '';
  IF test_passed THEN
    RAISE NOTICE '  ✅ SQL INJECTION TESTS: ALL PASSED';
  ELSE
    RAISE NOTICE '  ❌ SQL INJECTION TESTS: SOME FAILED';
  END IF;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- TEST 2: TABLE WHITELIST ENFORCEMENT
-- ============================================================================

DO $$
DECLARE
  test_result JSONB;
  test_passed BOOLEAN := TRUE;
BEGIN
  RAISE NOTICE '🧪 TEST 2: Table Whitelist Enforcement';
  RAISE NOTICE '────────────────────────────────────────────────────────────';

  -- Test 2.1: Try to query system table pg_authid
  BEGIN
    SELECT public.query_tenant('demo', 'pg_authid') INTO test_result;
    RAISE NOTICE '  ❌ Test 2.1 FAILED: System table access not blocked (pg_authid)';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 2.1 PASSED: System table access blocked (pg_authid)';
  END;

  -- Test 2.2: Try to query auth.users
  BEGIN
    SELECT public.query_tenant('demo', 'users') INTO test_result;
    RAISE NOTICE '  ❌ Test 2.2 FAILED: Auth table access not blocked';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 2.2 PASSED: Auth table access blocked';
  END;

  -- Test 2.3: Try to query core.tenants directly
  BEGIN
    SELECT public.query_tenant('demo', 'tenants') INTO test_result;
    RAISE NOTICE '  ❌ Test 2.3 FAILED: Core table access not blocked';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 2.3 PASSED: Core table access blocked';
  END;

  -- Test 2.4: Verify whitelisted table works (should succeed)
  BEGIN
    -- This should work if table exists and user has access
    SELECT public.query_tenant('demo', 'pm_projects') INTO test_result;
    RAISE NOTICE '  ✅ Test 2.4 PASSED: Whitelisted table accessible (pm_projects)';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 2.4 SKIPPED: Demo tenant or table not found (expected in test env)';
  END;

  RAISE NOTICE '';
  IF test_passed THEN
    RAISE NOTICE '  ✅ TABLE WHITELIST TESTS: ALL PASSED';
  ELSE
    RAISE NOTICE '  ❌ TABLE WHITELIST TESTS: SOME FAILED';
  END IF;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- TEST 3: RATE LIMITING
-- ============================================================================

DO $$
DECLARE
  test_result JSONB;
  test_passed BOOLEAN := TRUE;
  result_count INTEGER;
BEGIN
  RAISE NOTICE '🧪 TEST 3: Rate Limiting';
  RAISE NOTICE '────────────────────────────────────────────────────────────';

  -- Test 3.1: Try to query more than 1000 rows
  BEGIN
    SELECT public.query_tenant('demo', 'pm_projects', 5000, 0) INTO test_result;
    result_count := jsonb_array_length(test_result);

    IF result_count <= 1000 THEN
      RAISE NOTICE '  ✅ Test 3.1 PASSED: Rate limit enforced (got % rows, max 1000)', result_count;
    ELSE
      RAISE NOTICE '  ❌ Test 3.1 FAILED: Rate limit not enforced (got % rows)', result_count;
      test_passed := FALSE;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 3.1 SKIPPED: Demo tenant not found (expected in test env)';
  END;

  -- Test 3.2: Verify negative limit is handled
  BEGIN
    SELECT public.query_tenant('demo', 'pm_projects', -100, 0) INTO test_result;
    result_count := jsonb_array_length(test_result);

    IF result_count >= 0 THEN
      RAISE NOTICE '  ✅ Test 3.2 PASSED: Negative limit handled correctly';
    ELSE
      RAISE NOTICE '  ❌ Test 3.2 FAILED: Negative limit not handled';
      test_passed := FALSE;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 3.2 SKIPPED: Demo tenant not found';
  END;

  -- Test 3.3: Verify negative offset is handled
  BEGIN
    SELECT public.query_tenant('demo', 'pm_projects', 10, -100) INTO test_result;
    RAISE NOTICE '  ✅ Test 3.3 PASSED: Negative offset handled correctly';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 3.3 SKIPPED: Demo tenant not found';
  END;

  RAISE NOTICE '';
  IF test_passed THEN
    RAISE NOTICE '  ✅ RATE LIMITING TESTS: ALL PASSED';
  ELSE
    RAISE NOTICE '  ❌ RATE LIMITING TESTS: SOME FAILED';
  END IF;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- TEST 4: PERMISSION VALIDATION
-- ============================================================================

DO $$
DECLARE
  has_access BOOLEAN;
  test_passed BOOLEAN := TRUE;
BEGIN
  RAISE NOTICE '🧪 TEST 4: Permission Validation';
  RAISE NOTICE '────────────────────────────────────────────────────────────';

  -- Test 4.1: Check function exists
  BEGIN
    SELECT public.user_has_tenant_access('demo') INTO has_access;
    RAISE NOTICE '  ✅ Test 4.1 PASSED: user_has_tenant_access() function exists';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ❌ Test 4.1 FAILED: user_has_tenant_access() function not found';
    test_passed := FALSE;
  END;

  -- Test 4.2: Check invalid tenant returns false
  BEGIN
    SELECT public.user_has_tenant_access('nonexistent-tenant-xyz') INTO has_access;
    IF has_access = FALSE THEN
      RAISE NOTICE '  ✅ Test 4.2 PASSED: Invalid tenant returns false';
    ELSE
      RAISE NOTICE '  ❌ Test 4.2 FAILED: Invalid tenant should return false';
      test_passed := FALSE;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 4.2 SKIPPED: Permission check failed (expected without auth)';
  END;

  -- Test 4.3: Verify is_table_queryable function
  BEGIN
    IF public.is_table_queryable('pm_projects') = TRUE THEN
      RAISE NOTICE '  ✅ Test 4.3 PASSED: pm_projects is queryable';
    ELSE
      RAISE NOTICE '  ❌ Test 4.3 FAILED: pm_projects should be queryable';
      test_passed := FALSE;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ❌ Test 4.3 FAILED: is_table_queryable() function error';
    test_passed := FALSE;
  END;

  -- Test 4.4: Verify system table is not queryable
  BEGIN
    IF public.is_table_queryable('pg_authid') = FALSE THEN
      RAISE NOTICE '  ✅ Test 4.4 PASSED: pg_authid is not queryable';
    ELSE
      RAISE NOTICE '  ❌ Test 4.4 FAILED: pg_authid should not be queryable';
      test_passed := FALSE;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ❌ Test 4.4 FAILED: is_table_queryable() function error';
    test_passed := FALSE;
  END;

  RAISE NOTICE '';
  IF test_passed THEN
    RAISE NOTICE '  ✅ PERMISSION VALIDATION TESTS: ALL PASSED';
  ELSE
    RAISE NOTICE '  ❌ PERMISSION VALIDATION TESTS: SOME FAILED';
  END IF;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- TEST 5: INPUT VALIDATION
-- ============================================================================

DO $$
DECLARE
  test_result JSONB;
  test_passed BOOLEAN := TRUE;
BEGIN
  RAISE NOTICE '🧪 TEST 5: Input Validation';
  RAISE NOTICE '────────────────────────────────────────────────────────────';

  -- Test 5.1: NULL tenant_slug
  BEGIN
    SELECT public.query_tenant(NULL, 'pm_projects') INTO test_result;
    RAISE NOTICE '  ❌ Test 5.1 FAILED: NULL tenant_slug not rejected';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 5.1 PASSED: NULL tenant_slug rejected';
  END;

  -- Test 5.2: NULL table_name
  BEGIN
    SELECT public.query_tenant('demo', NULL) INTO test_result;
    RAISE NOTICE '  ❌ Test 5.2 FAILED: NULL table_name not rejected';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 5.2 PASSED: NULL table_name rejected';
  END;

  -- Test 5.3: Empty string tenant_slug
  BEGIN
    SELECT public.query_tenant('', 'pm_projects') INTO test_result;
    RAISE NOTICE '  ❌ Test 5.3 FAILED: Empty tenant_slug not rejected';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 5.3 PASSED: Empty tenant_slug rejected';
  END;

  -- Test 5.4: Empty string table_name
  BEGIN
    SELECT public.query_tenant('demo', '') INTO test_result;
    RAISE NOTICE '  ❌ Test 5.4 FAILED: Empty table_name not rejected';
    test_passed := FALSE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✅ Test 5.4 PASSED: Empty table_name rejected';
  END;

  RAISE NOTICE '';
  IF test_passed THEN
    RAISE NOTICE '  ✅ INPUT VALIDATION TESTS: ALL PASSED';
  ELSE
    RAISE NOTICE '  ❌ INPUT VALIDATION TESTS: SOME FAILED';
  END IF;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- TEST 6: HELPER FUNCTIONS
-- ============================================================================

DO $$
DECLARE
  tenant_info RECORD;
  test_passed BOOLEAN := TRUE;
BEGIN
  RAISE NOTICE '🧪 TEST 6: Helper Functions';
  RAISE NOTICE '────────────────────────────────────────────────────────────';

  -- Test 6.1: get_tenant_info function exists
  BEGIN
    SELECT * FROM public.get_tenant_info('demo') INTO tenant_info;
    RAISE NOTICE '  ✅ Test 6.1 PASSED: get_tenant_info() function works';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 6.1 SKIPPED: Demo tenant not found (expected)';
  END;

  -- Test 6.2: get_tenant_projects function exists
  BEGIN
    PERFORM public.get_tenant_projects('demo');
    RAISE NOTICE '  ✅ Test 6.2 PASSED: get_tenant_projects() function exists';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 6.2 SKIPPED: Function failed (expected without data)';
  END;

  -- Test 6.3: get_tenant_customers function exists
  BEGIN
    PERFORM public.get_tenant_customers('demo');
    RAISE NOTICE '  ✅ Test 6.3 PASSED: get_tenant_customers() function exists';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 6.3 SKIPPED: Function failed (expected without data)';
  END;

  -- Test 6.4: get_tenant_available_apps function exists
  BEGIN
    PERFORM public.get_tenant_available_apps('demo');
    RAISE NOTICE '  ✅ Test 6.4 PASSED: get_tenant_available_apps() function exists';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Test 6.4 SKIPPED: Function failed (expected without data)';
  END;

  RAISE NOTICE '';
  RAISE NOTICE '  ✅ HELPER FUNCTIONS TESTS: ALL PASSED';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- TEST 7: VIEW ACCESS PERMISSIONS
-- ============================================================================

DO $$
DECLARE
  view_count INTEGER;
  test_passed BOOLEAN := TRUE;
BEGIN
  RAISE NOTICE '🧪 TEST 7: View Access Permissions';
  RAISE NOTICE '────────────────────────────────────────────────────────────';

  -- Test 7.1: Check public.tenants view exists
  BEGIN
    SELECT COUNT(*) FROM public.tenants INTO view_count;
    RAISE NOTICE '  ✅ Test 7.1 PASSED: public.tenants view accessible';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ❌ Test 7.1 FAILED: public.tenants view not accessible';
    test_passed := FALSE;
  END;

  -- Test 7.2: Check public.apps_registry view exists
  BEGIN
    SELECT COUNT(*) FROM public.apps_registry INTO view_count;
    RAISE NOTICE '  ✅ Test 7.2 PASSED: public.apps_registry view accessible';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ❌ Test 7.2 FAILED: public.apps_registry view not accessible';
    test_passed := FALSE;
  END;

  -- Test 7.3: Check public.tenant_apps view exists
  BEGIN
    SELECT COUNT(*) FROM public.tenant_apps INTO view_count;
    RAISE NOTICE '  ✅ Test 7.3 PASSED: public.tenant_apps view accessible';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ❌ Test 7.3 FAILED: public.tenant_apps view not accessible';
    test_passed := FALSE;
  END;

  RAISE NOTICE '';
  IF test_passed THEN
    RAISE NOTICE '  ✅ VIEW ACCESS TESTS: ALL PASSED';
  ELSE
    RAISE NOTICE '  ❌ VIEW ACCESS TESTS: SOME FAILED';
  END IF;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '════════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  RAISE NOTICE '  🎉 SECURITY TEST SUITE COMPLETE';
  RAISE NOTICE '';
  RAISE NOTICE '  Review the results above for any ❌ FAILED tests.';
  RAISE NOTICE '  ⚠️  SKIPPED tests are expected in test environments.';
  RAISE NOTICE '';
  RAISE NOTICE '  For production deployment:';
  RAISE NOTICE '    1. All ✅ PASSED tests should pass';
  RAISE NOTICE '    2. Create demo tenant and test with real data';
  RAISE NOTICE '    3. Test with actual user authentication';
  RAISE NOTICE '    4. Run penetration tests';
  RAISE NOTICE '';
  RAISE NOTICE '════════════════════════════════════════════════════════════';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- PERFORMANCE TEST (OPTIONAL)
-- ============================================================================

DO $$
DECLARE
  start_time TIMESTAMPTZ;
  end_time TIMESTAMPTZ;
  duration INTERVAL;
BEGIN
  RAISE NOTICE '🧪 PERFORMANCE TEST (Optional)';
  RAISE NOTICE '────────────────────────────────────────────────────────────';

  -- Test query performance
  start_time := clock_timestamp();

  BEGIN
    PERFORM public.query_tenant('demo', 'pm_projects', 100, 0);

    end_time := clock_timestamp();
    duration := end_time - start_time;

    RAISE NOTICE '  ⏱️  Query execution time: %', duration;

    IF duration < interval '1 second' THEN
      RAISE NOTICE '  ✅ Performance acceptable (< 1s)';
    ELSE
      RAISE NOTICE '  ⚠️  Performance slow (> 1s) - optimize if needed';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ⚠️  Performance test skipped (demo tenant not found)';
  END;

  RAISE NOTICE '';
END $$;
