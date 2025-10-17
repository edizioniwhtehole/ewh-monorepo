-- Migration 032: PM Audit Log System
-- Complete audit trail for all entity changes

-- ============================================================================
-- AUDIT LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- What changed
    entity_type VARCHAR(50) NOT NULL, -- 'project', 'task', 'milestone', 'template'
    entity_id UUID NOT NULL,
    action VARCHAR(20) NOT NULL, -- 'create', 'update', 'delete', 'status_change', 'assign'

    -- Who changed it
    user_id UUID REFERENCES users(id),
    user_name VARCHAR(255),
    user_email VARCHAR(255),

    -- What changed
    field_name VARCHAR(100), -- For updates: which field changed
    old_value TEXT,
    new_value TEXT,
    changes JSONB, -- Full diff for complex updates

    -- Context
    ip_address INET,
    user_agent TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_tenant ON pm.audit_log(tenant_id);
CREATE INDEX idx_audit_entity ON pm.audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_user ON pm.audit_log(user_id);
CREATE INDEX idx_audit_created ON pm.audit_log(created_at DESC);
CREATE INDEX idx_audit_action ON pm.audit_log(action);

-- ============================================================================
-- TASK COMMENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.task_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES pm.tasks(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,

    user_id UUID NOT NULL REFERENCES users(id),
    user_name VARCHAR(255) NOT NULL,

    comment_text TEXT NOT NULL,

    -- Mentions
    mentions UUID[], -- Array of mentioned user IDs

    -- Attachments (future)
    attachments JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ -- Soft delete
);

CREATE INDEX idx_comments_task ON pm.task_comments(task_id);
CREATE INDEX idx_comments_user ON pm.task_comments(user_id);
CREATE INDEX idx_comments_created ON pm.task_comments(created_at DESC);

-- ============================================================================
-- TIME LOGS (for timer tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.time_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES pm.tasks(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,

    user_id UUID NOT NULL REFERENCES users(id),
    user_name VARCHAR(255) NOT NULL,

    -- Time tracking
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_seconds INTEGER, -- Calculated on stop

    -- Manual entry
    is_manual BOOLEAN DEFAULT FALSE,
    notes TEXT,

    -- Billing
    billable BOOLEAN DEFAULT TRUE,
    hourly_rate DECIMAL(10,2),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_time_logs_task ON pm.time_logs(task_id);
CREATE INDEX idx_time_logs_user ON pm.time_logs(user_id);
CREATE INDEX idx_time_logs_start ON pm.time_logs(start_time DESC);
CREATE INDEX idx_time_logs_tenant ON pm.time_logs(tenant_id);

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pm.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    user_id UUID NOT NULL REFERENCES users(id),

    -- Notification content
    type VARCHAR(50) NOT NULL, -- 'task_assigned', 'mention', 'deadline', 'status_change'
    title VARCHAR(255) NOT NULL,
    message TEXT,

    -- Link to entity
    entity_type VARCHAR(50), -- 'project', 'task', 'milestone'
    entity_id UUID,

    -- Status
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,

    -- Action URL
    action_url TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON pm.notifications(user_id, read);
CREATE INDEX idx_notifications_created ON pm.notifications(created_at DESC);
CREATE INDEX idx_notifications_tenant ON pm.notifications(tenant_id);

-- ============================================================================
-- UPDATE PROJECTS TABLE - Add budget fields
-- ============================================================================

ALTER TABLE pm.projects
    ADD COLUMN IF NOT EXISTS budget DECIMAL(12,2),
    ADD COLUMN IF NOT EXISTS spent DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'EUR',
    ADD COLUMN IF NOT EXISTS actual_start_date DATE;

-- ============================================================================
-- HELPER FUNCTION - Get Activity Feed
-- ============================================================================

CREATE OR REPLACE FUNCTION pm.get_project_activity(
    p_project_id UUID,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    event_timestamp TIMESTAMPTZ,
    activity_type VARCHAR,
    user_name VARCHAR,
    description TEXT,
    entity_type VARCHAR,
    entity_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.created_at as event_timestamp,
        a.action as activity_type,
        a.user_name,
        CASE
            WHEN a.action = 'create' THEN 'Created ' || a.entity_type || ' "' || COALESCE(a.new_value, '') || '"'
            WHEN a.action = 'update' THEN 'Updated ' || COALESCE(a.field_name, 'field') || ' to "' || COALESCE(a.new_value, '') || '"'
            WHEN a.action = 'status_change' THEN 'Changed status from ' || COALESCE(a.old_value, '') || ' to ' || COALESCE(a.new_value, '')
            WHEN a.action = 'assign' THEN 'Assigned to ' || COALESCE(a.new_value, '')
            ELSE a.action
        END as description,
        a.entity_type,
        a.entity_id
    FROM pm.audit_log a
    JOIN pm.tasks t ON t.id = a.entity_id
    WHERE t.project_id = p_project_id
        OR (a.entity_type = 'project' AND a.entity_id = p_project_id)
    ORDER BY a.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- UPDATE USERS TABLE - Add status if missing
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'status'
    ) THEN
        ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'disabled_at'
    ) THEN
        ALTER TABLE users ADD COLUMN disabled_at TIMESTAMPTZ;
    END IF;
END $$;

COMMENT ON TABLE pm.audit_log IS 'Complete audit trail for all PM entities';
COMMENT ON TABLE pm.task_comments IS 'Comments and discussions on tasks';
COMMENT ON TABLE pm.time_logs IS 'Time tracking logs with timer support';
COMMENT ON TABLE pm.notifications IS 'In-app notifications for users';
