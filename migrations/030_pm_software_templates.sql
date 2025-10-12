-- Migration 030: Software Development Templates (OPTIONAL - Industry Specific)
-- Example templates for software agencies, dev teams, SaaS companies

INSERT INTO pm.project_templates (id, tenant_id, template_key, template_name, category, description, estimated_duration_days, task_templates, milestone_templates)
VALUES
-- Template 1: API Feature Development
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'api_feature',
    'API Feature Development',
    'software',
    'Full-stack API feature: design, implementation, testing, deployment',
    14,
    '[
        {"name": "API Design & Spec", "category": "architecture", "estimated_hours": 8, "order": 1},
        {"name": "Database Schema", "category": "backend", "estimated_hours": 4, "order": 2},
        {"name": "Backend Implementation", "category": "backend", "estimated_hours": 16, "order": 3},
        {"name": "Unit Tests", "category": "testing", "estimated_hours": 8, "order": 4},
        {"name": "API Documentation", "category": "documentation", "estimated_hours": 4, "order": 5},
        {"name": "Code Review", "category": "review", "estimated_hours": 4, "order": 6},
        {"name": "Integration Tests", "category": "testing", "estimated_hours": 6, "order": 7},
        {"name": "Deploy to Staging", "category": "devops", "estimated_hours": 2, "order": 8},
        {"name": "QA Testing", "category": "qa", "estimated_hours": 8, "order": 9},
        {"name": "Deploy to Production", "category": "devops", "estimated_hours": 2, "order": 10}
    ]'::jsonb,
    '[
        {"name": "Design Approved", "due_days": 2},
        {"name": "Code Complete", "due_days": 7},
        {"name": "QA Passed", "due_days": 12},
        {"name": "Production Live", "due_days": 14}
    ]'::jsonb
),

-- Template 2: Bug Fix
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'bug_fix',
    'Bug Fix',
    'software',
    'Standard bug fix workflow: reproduce, fix, test, deploy',
    3,
    '[
        {"name": "Reproduce Bug", "category": "investigation", "estimated_hours": 2, "order": 1},
        {"name": "Root Cause Analysis", "category": "investigation", "estimated_hours": 2, "order": 2},
        {"name": "Implement Fix", "category": "backend", "estimated_hours": 4, "order": 3},
        {"name": "Add Regression Test", "category": "testing", "estimated_hours": 2, "order": 4},
        {"name": "Code Review", "category": "review", "estimated_hours": 1, "order": 5},
        {"name": "Deploy Fix", "category": "devops", "estimated_hours": 1, "order": 6},
        {"name": "Verify in Production", "category": "qa", "estimated_hours": 1, "order": 7}
    ]'::jsonb,
    '[
        {"name": "Root Cause Identified", "due_days": 1},
        {"name": "Fix Deployed", "due_days": 3}
    ]'::jsonb
),

-- Template 3: Mobile App Development
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'mobile_app',
    'Mobile App Development',
    'software',
    'Complete mobile app: design, development, testing, app store submission',
    90,
    '[
        {"name": "UI/UX Design", "category": "design", "estimated_hours": 40, "order": 1},
        {"name": "Design Review", "category": "review", "estimated_hours": 4, "order": 2},
        {"name": "Backend API Development", "category": "backend", "estimated_hours": 80, "order": 3},
        {"name": "iOS App Development", "category": "mobile_ios", "estimated_hours": 120, "order": 4},
        {"name": "Android App Development", "category": "mobile_android", "estimated_hours": 120, "order": 5},
        {"name": "Integration Testing", "category": "testing", "estimated_hours": 40, "order": 6},
        {"name": "Beta Testing", "category": "qa", "estimated_hours": 60, "order": 7},
        {"name": "Bug Fixes from Beta", "category": "backend", "estimated_hours": 40, "order": 8},
        {"name": "App Store Submission", "category": "release", "estimated_hours": 8, "order": 9},
        {"name": "Marketing Assets", "category": "marketing", "estimated_hours": 16, "order": 10}
    ]'::jsonb,
    '[
        {"name": "Design Finalized", "due_days": 15},
        {"name": "Backend Complete", "due_days": 35},
        {"name": "Apps Complete", "due_days": 70},
        {"name": "Beta Released", "due_days": 75},
        {"name": "App Store Live", "due_days": 90}
    ]'::jsonb
)
ON CONFLICT (tenant_id, template_key) DO NOTHING;

DO $$
DECLARE
    template_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO template_count FROM pm.project_templates WHERE category = 'software';
    RAISE NOTICE '✅ Installed % software development templates', template_count;
END $$;
