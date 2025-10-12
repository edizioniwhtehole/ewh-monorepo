-- Migration 031: Construction Templates (OPTIONAL - Industry Specific)
-- Example templates for construction companies, contractors, builders

INSERT INTO pm.project_templates (id, tenant_id, template_key, template_name, category, description, estimated_duration_days, task_templates, milestone_templates)
VALUES
-- Template 1: Residential Building
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'residential_building',
    'Residential Building Construction',
    'construction',
    'New residential building from permits to final inspection',
    365,
    '[
        {"name": "Site Survey & Planning", "category": "planning", "estimated_hours": 40, "order": 1},
        {"name": "Building Permit Application", "category": "permits", "estimated_hours": 16, "order": 2},
        {"name": "Site Preparation & Excavation", "category": "earthwork", "estimated_hours": 80, "order": 3},
        {"name": "Foundation Pour", "category": "concrete", "estimated_hours": 60, "order": 4},
        {"name": "Foundation Curing", "category": "concrete", "estimated_hours": 168, "order": 5},
        {"name": "Framing - Walls", "category": "framing", "estimated_hours": 200, "order": 6},
        {"name": "Framing - Roof", "category": "framing", "estimated_hours": 120, "order": 7},
        {"name": "Roofing Installation", "category": "roofing", "estimated_hours": 80, "order": 8},
        {"name": "Windows & Doors", "category": "carpentry", "estimated_hours": 60, "order": 9},
        {"name": "Electrical Rough-In", "category": "electrical", "estimated_hours": 100, "order": 10},
        {"name": "Plumbing Rough-In", "category": "plumbing", "estimated_hours": 100, "order": 11},
        {"name": "HVAC Installation", "category": "hvac", "estimated_hours": 80, "order": 12},
        {"name": "Insulation", "category": "insulation", "estimated_hours": 60, "order": 13},
        {"name": "Drywall Installation", "category": "drywall", "estimated_hours": 120, "order": 14},
        {"name": "Interior Painting", "category": "painting", "estimated_hours": 100, "order": 15},
        {"name": "Flooring Installation", "category": "flooring", "estimated_hours": 80, "order": 16},
        {"name": "Kitchen & Bath Fixtures", "category": "finishing", "estimated_hours": 60, "order": 17},
        {"name": "Electrical Finish Work", "category": "electrical", "estimated_hours": 40, "order": 18},
        {"name": "Final Inspection", "category": "inspection", "estimated_hours": 8, "order": 19}
    ]'::jsonb,
    '[
        {"name": "Permits Approved", "due_days": 30},
        {"name": "Foundation Complete", "due_days": 60},
        {"name": "Framing Complete", "due_days": 150},
        {"name": "Rough-In Complete", "due_days": 220},
        {"name": "Finishing Complete", "due_days": 335},
        {"name": "Final Inspection Passed", "due_days": 365}
    ]'::jsonb
),

-- Template 2: Renovation Project
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'renovation',
    'Home Renovation',
    'construction',
    'Residential renovation project: demolition to finishing',
    60,
    '[
        {"name": "Site Assessment", "category": "planning", "estimated_hours": 8, "order": 1},
        {"name": "Renovation Permits", "category": "permits", "estimated_hours": 8, "order": 2},
        {"name": "Demolition", "category": "demolition", "estimated_hours": 40, "order": 3},
        {"name": "Structural Modifications", "category": "framing", "estimated_hours": 60, "order": 4},
        {"name": "Electrical Updates", "category": "electrical", "estimated_hours": 40, "order": 5},
        {"name": "Plumbing Updates", "category": "plumbing", "estimated_hours": 40, "order": 6},
        {"name": "Drywall Repair", "category": "drywall", "estimated_hours": 30, "order": 7},
        {"name": "Painting", "category": "painting", "estimated_hours": 40, "order": 8},
        {"name": "Flooring", "category": "flooring", "estimated_hours": 30, "order": 9},
        {"name": "Fixtures & Hardware", "category": "finishing", "estimated_hours": 20, "order": 10},
        {"name": "Final Walkthrough", "category": "inspection", "estimated_hours": 4, "order": 11}
    ]'::jsonb,
    '[
        {"name": "Demolition Complete", "due_days": 10},
        {"name": "Structural Work Done", "due_days": 25},
        {"name": "Rough-In Complete", "due_days": 40},
        {"name": "Project Complete", "due_days": 60}
    ]'::jsonb
),

-- Template 3: Commercial Build-Out
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'commercial_buildout',
    'Commercial Office Build-Out',
    'construction',
    'Commercial interior build-out for office/retail space',
    120,
    '[
        {"name": "Space Planning & Design", "category": "planning", "estimated_hours": 40, "order": 1},
        {"name": "Building Permits", "category": "permits", "estimated_hours": 16, "order": 2},
        {"name": "Demolition of Existing", "category": "demolition", "estimated_hours": 60, "order": 3},
        {"name": "Partition Walls Framing", "category": "framing", "estimated_hours": 100, "order": 4},
        {"name": "Electrical Distribution", "category": "electrical", "estimated_hours": 80, "order": 5},
        {"name": "Data/Telecom Cabling", "category": "low_voltage", "estimated_hours": 60, "order": 6},
        {"name": "HVAC Modifications", "category": "hvac", "estimated_hours": 60, "order": 7},
        {"name": "Plumbing for Breakroom", "category": "plumbing", "estimated_hours": 40, "order": 8},
        {"name": "Drywall Installation", "category": "drywall", "estimated_hours": 80, "order": 9},
        {"name": "Ceiling Installation", "category": "ceiling", "estimated_hours": 60, "order": 10},
        {"name": "Interior Painting", "category": "painting", "estimated_hours": 60, "order": 11},
        {"name": "Flooring - Carpet/Tile", "category": "flooring", "estimated_hours": 80, "order": 12},
        {"name": "Millwork & Casework", "category": "carpentry", "estimated_hours": 100, "order": 13},
        {"name": "Light Fixtures & Switches", "category": "electrical", "estimated_hours": 40, "order": 14},
        {"name": "Fire Safety Inspection", "category": "inspection", "estimated_hours": 8, "order": 15},
        {"name": "Final Walkthrough", "category": "inspection", "estimated_hours": 4, "order": 16}
    ]'::jsonb,
    '[
        {"name": "Permits Approved", "due_days": 15},
        {"name": "Demo & Framing Complete", "due_days": 40},
        {"name": "MEP Rough-In Complete", "due_days": 70},
        {"name": "Finishes Complete", "due_days": 105},
        {"name": "Certificate of Occupancy", "due_days": 120}
    ]'::jsonb
)
ON CONFLICT (tenant_id, template_key) DO NOTHING;

DO $$
DECLARE
    template_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO template_count FROM pm.project_templates WHERE category = 'construction';
    RAISE NOTICE '✅ Installed % construction templates', template_count;
END $$;
