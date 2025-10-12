-- Migration 026: AI Workflow Learning System (Patent #1)
-- Tracks user workflows, detects patterns, generates SOPs automatically

-- Enable vector extension for CLIP embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Workflow recordings table (main session tracking)
CREATE TABLE IF NOT EXISTS pm.workflow_recordings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Task context
    task_id UUID REFERENCES pm.tasks(id) ON DELETE SET NULL,
    task_category VARCHAR(100) NOT NULL, -- 'photo_editing', 'logo_design', 'video_editing'

    -- Application context
    application VARCHAR(50) NOT NULL, -- 'photoshop', 'illustrator', 'premiere'
    application_version VARCHAR(20),

    -- Session timing
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,

    -- Quality metrics
    quality_score DECIMAL(3,2) CHECK (quality_score BETWEEN 0 AND 1),
    approval_status VARCHAR(20), -- 'approved', 'rejected', 'needs_revision'

    -- Visual similarity (for finding similar images)
    image_embedding VECTOR(512), -- CLIP embedding of final output

    -- Action summary
    total_actions INTEGER DEFAULT 0,
    undo_count INTEGER DEFAULT 0,
    redo_count INTEGER DEFAULT 0,
    tools_used TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- Efficiency metrics
    idle_time_seconds INTEGER DEFAULT 0,
    active_time_seconds INTEGER DEFAULT 0,

    -- Consent (GDPR compliance)
    user_consented BOOLEAN DEFAULT FALSE NOT NULL,
    consent_timestamp TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workflow_recordings_user ON pm.workflow_recordings(user_id, task_category);
CREATE INDEX idx_workflow_recordings_task ON pm.workflow_recordings(task_id);
CREATE INDEX idx_workflow_recordings_time ON pm.workflow_recordings(started_at DESC);
CREATE INDEX idx_workflow_recordings_tenant ON pm.workflow_recordings(tenant_id);

-- IVFFlat index for vector similarity search
CREATE INDEX idx_workflow_recordings_embedding ON pm.workflow_recordings
    USING ivfflat (image_embedding vector_cosine_ops)
    WITH (lists = 100)
    WHERE image_embedding IS NOT NULL;

-- Individual actions within a workflow
CREATE TABLE IF NOT EXISTS pm.workflow_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recording_id UUID NOT NULL REFERENCES pm.workflow_recordings(id) ON DELETE CASCADE,

    -- Action details
    sequence_number INTEGER NOT NULL, -- Order within session
    action_type VARCHAR(50) NOT NULL, -- 'tool_select', 'adjust_parameter', 'undo', 'redo', 'save'
    tool_name VARCHAR(100), -- 'brush', 'lasso', 'crop', 'levels'

    -- Parameters (JSON for flexibility)
    parameters JSONB, -- {size: 50, opacity: 80, mode: 'normal'}

    -- Timing
    timestamp_offset_ms INTEGER NOT NULL, -- Milliseconds from session start
    duration_ms INTEGER, -- How long action took

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workflow_actions_recording ON pm.workflow_actions(recording_id, sequence_number);
CREATE INDEX idx_workflow_actions_type ON pm.workflow_actions(action_type);

-- Detected patterns (inefficiencies, best practices)
CREATE TABLE IF NOT EXISTS pm.workflow_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recording_id UUID NOT NULL REFERENCES pm.workflow_recordings(id) ON DELETE CASCADE,

    -- Pattern identification
    pattern_type VARCHAR(50) NOT NULL, -- 'excessive_undo', 'tool_cycling', 'suboptimal_timing', 'efficient_sequence'
    severity VARCHAR(20) NOT NULL, -- 'low', 'medium', 'high'

    -- Details
    description TEXT NOT NULL,
    evidence JSONB, -- {undo_count: 15, time_wasted_seconds: 120}

    -- Suggestion
    suggestion_title VARCHAR(200),
    suggestion_message TEXT,
    suggestion_shown_to_user BOOLEAN DEFAULT FALSE,
    user_dismissed BOOLEAN DEFAULT FALSE,

    -- Timing
    detected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workflow_patterns_recording ON pm.workflow_patterns(recording_id);
CREATE INDEX idx_workflow_patterns_type ON pm.workflow_patterns(pattern_type, severity);

-- Auto-generated SOPs (Standard Operating Procedures)
CREATE TABLE IF NOT EXISTS pm.workflow_sops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,

    -- SOP identification
    task_category VARCHAR(100) NOT NULL,
    sop_title VARCHAR(200) NOT NULL,
    sop_key VARCHAR(100) NOT NULL, -- 'landscape_editing_best_practice'

    -- Content (auto-generated)
    sop_markdown TEXT NOT NULL,

    -- Generation metadata
    generated_from_recordings UUID[] NOT NULL, -- Top performer recordings used
    generation_algorithm VARCHAR(50) DEFAULT 'lcs_v1', -- Longest Common Subsequence

    -- Quality metrics
    avg_quality_of_source DECIMAL(3,2),
    avg_duration_of_source INTEGER, -- Average seconds

    -- Usage stats
    times_viewed INTEGER DEFAULT 0,
    times_applied INTEGER DEFAULT 0,
    avg_improvement_when_applied DECIMAL(5,2), -- Percentage improvement

    -- Status
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'archived', 'superseded'

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(tenant_id, sop_key)
);

CREATE INDEX idx_workflow_sops_tenant ON pm.workflow_sops(tenant_id, task_category);
CREATE INDEX idx_workflow_sops_status ON pm.workflow_sops(status) WHERE status = 'active';

-- Image embeddings cache (for visual similarity)
CREATE TABLE IF NOT EXISTS pm.image_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Image identification
    image_url TEXT NOT NULL,
    image_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA256 of image

    -- Embedding
    clip_embedding VECTOR(512) NOT NULL,

    -- Metadata
    width INTEGER,
    height INTEGER,
    file_size_bytes INTEGER,
    mime_type VARCHAR(50),

    -- Usage tracking
    used_in_recordings UUID[], -- Recording IDs that used this image

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_image_embeddings_hash ON pm.image_embeddings(image_hash);
CREATE INDEX idx_image_embeddings_vector ON pm.image_embeddings
    USING ivfflat (clip_embedding vector_cosine_ops)
    WITH (lists = 100);

-- Workflow suggestions (proactive recommendations)
CREATE TABLE IF NOT EXISTS pm.workflow_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Suggestion context
    current_recording_id UUID REFERENCES pm.workflow_recordings(id) ON DELETE CASCADE,
    suggestion_type VARCHAR(50) NOT NULL, -- 'similar_image_batch', 'better_approach', 'take_break'

    -- Content
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    action_label VARCHAR(100), -- 'Apply Workflow', 'View SOP', 'Take 2 Min Break'
    action_data JSONB, -- {sop_id: 'xxx', similar_images: [...]}

    -- Display
    shown_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,
    auto_dismiss_after_seconds INTEGER DEFAULT 10,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workflow_suggestions_user ON pm.workflow_suggestions(user_id);
CREATE INDEX idx_workflow_suggestions_recording ON pm.workflow_suggestions(current_recording_id);

-- Function: Calculate workflow efficiency score
CREATE OR REPLACE FUNCTION pm.calculate_workflow_efficiency(recording_id UUID)
RETURNS DECIMAL(3,2) AS $$
DECLARE
    rec RECORD;
    efficiency_score DECIMAL(3,2);
    undo_penalty DECIMAL(3,2);
    idle_penalty DECIMAL(3,2);
    action_density DECIMAL(3,2);
BEGIN
    SELECT
        wr.total_actions,
        wr.undo_count,
        wr.redo_count,
        wr.duration_seconds,
        wr.idle_time_seconds,
        wr.active_time_seconds,
        wr.quality_score
    INTO rec
    FROM pm.workflow_recordings wr
    WHERE wr.id = recording_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    -- Undo penalty (excessive undo = inefficient)
    undo_penalty := LEAST(0.3, (rec.undo_count::DECIMAL / NULLIF(rec.total_actions, 0)) * 0.5);

    -- Idle time penalty
    idle_penalty := LEAST(0.2, (rec.idle_time_seconds::DECIMAL / NULLIF(rec.duration_seconds, 0)) * 0.3);

    -- Action density (more actions in less time = efficient, but quality matters)
    action_density := LEAST(1.0, (rec.total_actions::DECIMAL / NULLIF(rec.active_time_seconds, 0)) * 0.1);

    -- Combined efficiency score
    efficiency_score := GREATEST(0, LEAST(1,
        COALESCE(rec.quality_score, 0.5) * 0.6 +  -- Quality is 60%
        action_density * 0.2 +                     -- Density is 20%
        (1 - undo_penalty) * 0.1 +                 -- Undo efficiency 10%
        (1 - idle_penalty) * 0.1                   -- Active time 10%
    ));

    RETURN efficiency_score;
END;
$$ LANGUAGE plpgsql;

-- Function: Find similar workflows by visual similarity
CREATE OR REPLACE FUNCTION pm.find_similar_workflows(
    target_embedding VECTOR(512),
    task_category_filter VARCHAR(100) DEFAULT NULL,
    similarity_threshold DECIMAL(3,2) DEFAULT 0.85,
    max_results INTEGER DEFAULT 10
)
RETURNS TABLE (
    recording_id UUID,
    similarity_score DECIMAL(4,3),
    user_id UUID,
    quality_score DECIMAL(3,2),
    duration_seconds INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        wr.id as recording_id,
        (1 - (wr.image_embedding <=> target_embedding))::DECIMAL(4,3) as similarity_score,
        wr.user_id,
        wr.quality_score,
        wr.duration_seconds
    FROM pm.workflow_recordings wr
    WHERE wr.image_embedding IS NOT NULL
      AND (task_category_filter IS NULL OR wr.task_category = task_category_filter)
      AND (1 - (wr.image_embedding <=> target_embedding)) >= similarity_threshold
    ORDER BY wr.image_embedding <=> target_embedding ASC
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Update workflow recording stats on action insert
CREATE OR REPLACE FUNCTION pm.update_workflow_recording_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE pm.workflow_recordings
    SET
        total_actions = total_actions + 1,
        undo_count = CASE WHEN NEW.action_type = 'undo' THEN undo_count + 1 ELSE undo_count END,
        redo_count = CASE WHEN NEW.action_type = 'redo' THEN redo_count + 1 ELSE redo_count END,
        tools_used = CASE
            WHEN NEW.tool_name IS NOT NULL AND NOT (NEW.tool_name = ANY(tools_used))
            THEN array_append(tools_used, NEW.tool_name)
            ELSE tools_used
        END,
        updated_at = NOW()
    WHERE id = NEW.recording_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_workflow_stats
    AFTER INSERT ON pm.workflow_actions
    FOR EACH ROW
    EXECUTE FUNCTION pm.update_workflow_recording_stats();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.workflow_recordings TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.workflow_actions TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.workflow_patterns TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.workflow_sops TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.image_embeddings TO ewh;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm.workflow_suggestions TO ewh;

-- Materialized view: Top performers per category (for SOP generation)
CREATE MATERIALIZED VIEW pm.top_performers_by_category AS
SELECT
    task_category,
    user_id,
    COUNT(*) as total_workflows,
    AVG(quality_score) as avg_quality,
    AVG(duration_seconds) as avg_duration,
    AVG(pm.calculate_workflow_efficiency(id)) as avg_efficiency,
    ARRAY_AGG(id ORDER BY quality_score DESC, duration_seconds ASC LIMIT 10) as top_recording_ids
FROM pm.workflow_recordings
WHERE quality_score >= 0.75
  AND completed_at IS NOT NULL
  AND user_consented = TRUE
GROUP BY task_category, user_id
HAVING COUNT(*) >= 10;

CREATE UNIQUE INDEX idx_top_performers_category_user ON pm.top_performers_by_category(task_category, user_id);

-- Refresh function (call daily)
CREATE OR REPLACE FUNCTION pm.refresh_top_performers()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY pm.top_performers_by_category;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE pm.workflow_recordings IS 'Patent #1: AI Workflow Pattern Learning - Main session tracking';
COMMENT ON TABLE pm.workflow_actions IS 'Patent #1: Individual actions within workflow session';
COMMENT ON TABLE pm.workflow_patterns IS 'Patent #1: Detected inefficiency patterns and best practices';
COMMENT ON TABLE pm.workflow_sops IS 'Patent #1: Auto-generated Standard Operating Procedures';
COMMENT ON TABLE pm.image_embeddings IS 'Patent #1: Visual similarity search for batch workflow suggestions';
COMMENT ON FUNCTION pm.calculate_workflow_efficiency IS 'Patent #1: Efficiency scoring algorithm';
COMMENT ON FUNCTION pm.find_similar_workflows IS 'Patent #1: Visual similarity matching for workflow suggestions';
