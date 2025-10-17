# Migration Guide: Public Views V1 → V2

**Migration Type:** Security Critical
**Estimated Time:** 4 days (with testing)
**Downtime Required:** Minimal (< 5 minutes during deployment)
**Risk Level:** Medium (with proper testing)

---

## 📋 Pre-Migration Checklist

### Prerequisites
- [ ] Backup current database (full backup)
- [ ] Review all client code using V1 functions
- [ ] Set up staging environment identical to production
- [ ] Prepare rollback plan
- [ ] Schedule maintenance window
- [ ] Notify stakeholders

### Required Access
- [ ] Database admin access (SUPERUSER or owner of schemas)
- [ ] Supabase dashboard access (if using Supabase)
- [ ] Application deployment access
- [ ] Monitoring/logging access

### Environment Verification
- [ ] PostgreSQL version 12+ (verify: `SELECT version();`)
- [ ] Supabase auth extension installed (if using Supabase)
- [ ] `core`, `analytics` schemas exist
- [ ] All tenant schemas exist (`tenant_*`)

---

## 🗓️ Migration Timeline (4 Days)

### **Day 1: Staging Deployment**
**Duration:** 4-6 hours

#### Morning (2 hours)
1. Deploy V2 to staging
2. Create `core.tenant_users` table
3. Seed test data
4. Run security tests

#### Afternoon (2-4 hours)
5. Update staging application code
6. Manual functional testing
7. Document any issues
8. Fix issues if found

---

### **Day 2: Security Testing**
**Duration:** 6-8 hours

#### Security Tests (4 hours)
1. SQL injection tests (automated + manual)
2. Permission validation tests
3. Cross-tenant access attempts
4. Table whitelist verification
5. Rate limiting tests

#### Penetration Testing (2-4 hours)
6. External security audit (if available)
7. Vulnerability scanning
8. Authentication bypass attempts
9. Document findings

---

### **Day 3: Load Testing & Client Updates**
**Duration:** 6-8 hours

#### Load Testing (3 hours)
1. Concurrent user simulation (100+ users)
2. Rate limit stress test
3. Large dataset queries
4. Performance benchmarking

#### Client Code Updates (3-5 hours)
5. Update all API calls to use V2 signatures
6. Test updated code in staging
7. Code review
8. Create deployment package

---

### **Day 4: Production Deployment**
**Duration:** 3-4 hours + monitoring

#### Deployment Window (1 hour)
1. Final backup
2. Deploy V2 SQL script
3. Deploy updated application code
4. Smoke tests

#### Monitoring (2-3 hours + ongoing)
5. Monitor error rates
6. Check audit logs
7. Performance monitoring
8. User feedback collection

---

## 📝 Detailed Migration Steps

### Step 1: Create Backup

```bash
# Full database backup
pg_dump -h localhost -U postgres -d your_database > backup_before_v2_$(date +%Y%m%d_%H%M%S).sql

# Verify backup
ls -lh backup_before_v2_*.sql
```

---

### Step 2: Create `core.tenant_users` Table

```sql
-- This table tracks which users have access to which tenants
CREATE TABLE IF NOT EXISTS core.tenant_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES core.tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'pending')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_tenant_users_tenant ON core.tenant_users(tenant_id);
CREATE INDEX idx_tenant_users_user ON core.tenant_users(user_id);
CREATE INDEX idx_tenant_users_status ON core.tenant_users(status) WHERE status = 'active';

-- Unique constraint: one user per tenant
CREATE UNIQUE INDEX idx_tenant_users_unique ON core.tenant_users(tenant_id, user_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tenant_users_updated_at
  BEFORE UPDATE ON core.tenant_users
  FOR EACH ROW
  EXECUTE FUNCTION core.update_updated_at_column();

-- Comments
COMMENT ON TABLE core.tenant_users IS 'Maps users to tenants with roles and permissions';
COMMENT ON COLUMN core.tenant_users.role IS 'User role: owner, admin, member, viewer';
COMMENT ON COLUMN core.tenant_users.status IS 'User status: active, suspended, pending';
```

---

### Step 3: Migrate Existing User-Tenant Relationships

```sql
-- If you have existing user data in another table, migrate it
-- Example: If users are currently in core.tenants with owner_id field

INSERT INTO core.tenant_users (tenant_id, user_id, role, status)
SELECT
  id as tenant_id,
  owner_id as user_id,
  'owner' as role,
  'active' as status
FROM core.tenants
WHERE owner_id IS NOT NULL
ON CONFLICT (tenant_id, user_id) DO NOTHING;

-- Verify migration
SELECT COUNT(*) as migrated_users FROM core.tenant_users;
```

---

### Step 4: Deploy V2 Script

```bash
# Run V2 script in staging first
psql -h staging-host -U postgres -d staging_db -f scripts/create-public-views-v2.sql

# Check for errors
echo $?  # Should be 0 if successful
```

---

### Step 5: Run Security Tests

```bash
# Run automated security tests
psql -h staging-host -U postgres -d staging_db -f scripts/test-public-views-security.sql

# Review output for any FAILED tests
```

---

### Step 6: Update Client Code

**Before (V1):**
```javascript
// Old V1 API call
const { data, error } = await supabase
  .rpc('query_tenant', {
    tenant_slug: 'acme-corp',
    table_name: 'pm_projects'
  });
```

**After (V2):**
```javascript
// New V2 API call with pagination
const { data, error } = await supabase
  .rpc('query_tenant', {
    tenant_slug: 'acme-corp',
    table_name: 'pm_projects',
    query_limit: 100,     // New: pagination support
    query_offset: 0       // New: pagination support
  });
```

**Type-safe helpers (recommended):**
```javascript
// Use specific helper functions instead of generic query_tenant
const { data: projects, error } = await supabase
  .rpc('get_tenant_projects', {
    tenant_slug: 'acme-corp',
    project_status: 'active',  // New: optional filter
    limit_rows: 50             // New: limit
  });

const { data: customers, error } = await supabase
  .rpc('get_tenant_customers', {
    tenant_slug: 'acme-corp',
    customer_status: 'active',
    limit_rows: 50
  });
```

---

### Step 7: Test in Staging

```bash
# 1. Start staging application
npm run start:staging

# 2. Run integration tests
npm test

# 3. Manual testing checklist
# - [ ] Login as different users
# - [ ] Access different tenants
# - [ ] Try to access unauthorized tenants (should fail)
# - [ ] Query various tables
# - [ ] Test pagination
# - [ ] Verify audit logs
```

---

### Step 8: Production Deployment

```sql
-- 1. Put application in maintenance mode (optional)
-- 2. Run V2 script in production

BEGIN;

-- Backup current functions (for quick rollback)
CREATE SCHEMA IF NOT EXISTS backup_v1;

CREATE OR REPLACE FUNCTION backup_v1.query_tenant_v1(...)
  -- Copy of old function for rollback

-- Deploy V2
\i scripts/create-public-views-v2.sql

-- Verify deployment
SELECT
  proname as function_name,
  pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname IN ('query_tenant', 'get_tenant_projects', 'user_has_tenant_access')
  AND pronamespace = 'public'::regnamespace;

-- If everything looks good, commit
COMMIT;

-- If issues found, rollback
-- ROLLBACK;
```

---

## 🔄 Rollback Plan

### Quick Rollback (< 5 minutes)

```sql
-- 1. Restore V1 functions from backup schema
CREATE OR REPLACE FUNCTION public.query_tenant(...)
AS $$
  -- Copy from backup_v1.query_tenant_v1
$$ LANGUAGE plpgsql;

-- 2. Restore old permissions
GRANT EXECUTE ON FUNCTION public.query_tenant TO authenticated;

-- 3. Verify
SELECT public.query_tenant('demo', 'pm_projects');
```

### Full Rollback (if database corrupted)

```bash
# Restore from backup
psql -h prod-host -U postgres -d prod_db < backup_before_v2_YYYYMMDD_HHMMSS.sql

# Verify restoration
psql -h prod-host -U postgres -d prod_db -c "SELECT COUNT(*) FROM core.tenants;"
```

---

## ✅ Post-Migration Checklist

### Immediate (First Hour)
- [ ] Smoke tests passed
- [ ] No critical errors in logs
- [ ] Authentication working
- [ ] Users can access their tenants
- [ ] Audit logs being created

### First Day
- [ ] Monitor error rates (should be < 1%)
- [ ] Check performance metrics (< 500ms avg)
- [ ] Review audit logs for anomalies
- [ ] Collect user feedback
- [ ] No security incidents reported

### First Week
- [ ] Performance stable
- [ ] No permission issues reported
- [ ] Audit logs reviewed daily
- [ ] Security scan clean
- [ ] Documentation updated

---

## 📊 Success Criteria

### Functional
✅ All V1 features working in V2
✅ Pagination working correctly
✅ Filters working (status, etc)
✅ Error handling correct

### Security
✅ SQL injection blocked (100% of tests)
✅ Permission validation working
✅ Table whitelist enforced
✅ Rate limiting active
✅ Audit logging complete

### Performance
✅ Query time < 500ms (95th percentile)
✅ No timeout errors
✅ Concurrent users supported (100+)
✅ Database CPU < 70%

### Monitoring
✅ Error rate < 1%
✅ Success rate > 99%
✅ Audit logs complete
✅ No security alerts

---

## 🐛 Common Issues & Solutions

### Issue 1: "Function user_has_tenant_access not found"

**Cause:** V2 script not fully deployed

**Solution:**
```sql
-- Check if function exists
SELECT proname FROM pg_proc WHERE proname = 'user_has_tenant_access';

-- If missing, redeploy
\i scripts/create-public-views-v2.sql
```

---

### Issue 2: "Access denied to tenant"

**Cause:** User not in `core.tenant_users` table

**Solution:**
```sql
-- Check user's tenant access
SELECT * FROM core.tenant_users WHERE user_id = 'user-uuid-here';

-- If missing, add access
INSERT INTO core.tenant_users (tenant_id, user_id, role)
VALUES ('tenant-uuid', 'user-uuid', 'member');
```

---

### Issue 3: "Table not queryable"

**Cause:** Table not in whitelist

**Solution:**
```sql
-- Check if table is whitelisted
SELECT public.is_table_queryable('your_table_name');

-- If FALSE, add to whitelist in create-public-views-v2.sql
-- Then redeploy
```

---

### Issue 4: Performance Degradation

**Cause:** Missing indexes or inefficient queries

**Solution:**
```sql
-- Add indexes to frequently queried columns
CREATE INDEX IF NOT EXISTS idx_pm_projects_status
  ON tenant_demo.pm_projects(status);

CREATE INDEX IF NOT EXISTS idx_pm_projects_created
  ON tenant_demo.pm_projects(created_at DESC);

-- Analyze tables
ANALYZE tenant_demo.pm_projects;
```

---

## 📞 Support Contacts

- **Database Team:** db-team@company.com
- **Security Team:** security@company.com
- **DevOps:** devops@company.com
- **On-Call:** +1-XXX-XXX-XXXX

---

## 📚 Additional Resources

- [PUBLIC_VIEWS_SECURITY_ANALYSIS.md](PUBLIC_VIEWS_SECURITY_ANALYSIS.md) - Security audit
- [create-public-views-v2.sql](create-public-views-v2.sql) - V2 script
- [test-public-views-security.sql](test-public-views-security.sql) - Security tests
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/security.html)
- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)

---

## 🎯 Final Go/No-Go Decision

**Before deploying to production, verify ALL of the following:**

### Go Criteria (ALL must be ✅)
- [ ] Staging deployment successful
- [ ] All security tests passed (0 failures)
- [ ] Performance tests passed
- [ ] Client code updated and tested
- [ ] Rollback plan tested
- [ ] Team trained on new functions
- [ ] Monitoring configured
- [ ] Stakeholders notified
- [ ] Maintenance window scheduled
- [ ] Backup verified and tested

### No-Go Criteria (ANY is 🔴)
- [ ] Security tests failing
- [ ] Performance degraded > 20%
- [ ] Critical bugs found
- [ ] Team not ready
- [ ] Monitoring not ready
- [ ] Rollback not tested

---

**Migration Lead:** _______________  **Date:** ___________

**Security Approval:** _____________  **Date:** ___________

**Manager Approval:** ______________  **Date:** ___________

---

**Document Version:** 1.0
**Last Updated:** October 17, 2025
**Status:** Ready for Review
