-- Migration 033: Sample Projects for Demo

-- Create 3 sample projects from templates
DO $$
DECLARE
    book_template_id UUID;
    guide_template_id UUID;
    gadget_template_id UUID;
    project1_id UUID;
    project2_id UUID;
    project3_id UUID;
    user1_id UUID := '00000000-0000-0000-0000-000000000001';
    tenant_id UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Get template IDs
    SELECT id INTO book_template_id FROM pm.project_templates WHERE template_key = 'book_publication' LIMIT 1;
    SELECT id INTO guide_template_id FROM pm.project_templates WHERE template_key = 'tourist_guide' LIMIT 1;
    SELECT id INTO gadget_template_id FROM pm.project_templates WHERE template_key = 'gadget_production' LIMIT 1;

    -- Project 1: Book Publication
    INSERT INTO pm.projects (
        id, tenant_id, template_id, project_code, project_name, description,
        status, priority, start_date, end_date, completion_percentage,
        project_manager_id, budget, spent, currency, created_by
    ) VALUES (
        uuid_generate_v4(), tenant_id, book_template_id, 'BOOK-001',
        'Italian Cookbook - Pasta & Risotto',
        'A comprehensive guide to traditional Italian pasta and risotto recipes',
        'active', 'high', CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE + INTERVAL '150 days', 35,
        user1_id, 25000, 8500, 'EUR', user1_id
    ) RETURNING id INTO project1_id;

    -- Tasks for Project 1
    INSERT INTO pm.tasks (project_id, tenant_id, task_name, task_category, status, priority, estimated_hours, actual_hours, assigned_to, task_order)
    VALUES
        (project1_id, tenant_id, 'Recipe Research', 'research', 'done', 'high', 40, 38, user1_id, 1),
        (project1_id, tenant_id, 'First Draft Writing', 'writing', 'done', 'high', 80, 85, user1_id, 2),
        (project1_id, tenant_id, 'Photography Session', 'photography', 'in_progress', 'medium', 60, 25, user1_id, 3),
        (project1_id, tenant_id, 'Recipe Testing', 'testing', 'todo', 'high', 100, 0, user1_id, 4),
        (project1_id, tenant_id, 'Professional Editing', 'editing', 'todo', 'high', 80, 0, user1_id, 5),
        (project1_id, tenant_id, 'Layout Design', 'layout', 'todo', 'medium', 60, 0, user1_id, 6);

    -- Project 2: Tourist Guide
    INSERT INTO pm.projects (
        id, tenant_id, template_id, project_code, project_name, description,
        status, priority, start_date, end_date, completion_percentage,
        project_manager_id, budget, spent, currency, created_by
    ) VALUES (
        uuid_generate_v4(), tenant_id, guide_template_id, 'GUIDE-001',
        'Venice Hidden Gems - Off the Beaten Path',
        'A tourist guide focusing on lesser-known attractions in Venice',
        'planning', 'medium', CURRENT_DATE, CURRENT_DATE + INTERVAL '120 days', 10,
        user1_id, 18000, 1200, 'EUR', user1_id
    ) RETURNING id INTO project2_id;

    -- Tasks for Project 2
    INSERT INTO pm.tasks (project_id, tenant_id, task_name, task_category, status, priority, estimated_hours, assigned_to, task_order)
    VALUES
        (project2_id, tenant_id, 'Location Scouting', 'research', 'in_progress', 'high', 50, user1_id, 1),
        (project2_id, tenant_id, 'Historical Research', 'research', 'todo', 'medium', 40, user1_id, 2),
        (project2_id, tenant_id, 'Photography', 'photography', 'todo', 'high', 80, user1_id, 3),
        (project2_id, tenant_id, 'Content Writing', 'writing', 'todo', 'high', 100, user1_id, 4);

    -- Project 3: Gadget Production
    INSERT INTO pm.projects (
        id, tenant_id, template_id, project_code, project_name, description,
        status, priority, start_date, end_date, completion_percentage,
        project_manager_id, budget, spent, currency, created_by
    ) VALUES (
        uuid_generate_v4(), tenant_id, gadget_template_id, 'GADGET-001',
        'Venice Themed Bookmarks',
        'Elegant metal bookmarks with Venice landmarks designs',
        'active', 'medium', CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE + INTERVAL '40 days', 60,
        user1_id, 8000, 4500, 'EUR', user1_id
    ) RETURNING id INTO project3_id;

    -- Tasks for Project 3
    INSERT INTO pm.tasks (project_id, tenant_id, task_name, task_category, status, priority, estimated_hours, actual_hours, assigned_to, task_order, due_date)
    VALUES
        (project3_id, tenant_id, 'Design Concepts', 'design', 'done', 'high', 20, 22, user1_id, 1, CURRENT_DATE - INTERVAL '15 days'),
        (project3_id, tenant_id, 'Prototype Creation', 'prototype', 'done', 'high', 30, 28, user1_id, 2, CURRENT_DATE - INTERVAL '10 days'),
        (project3_id, tenant_id, 'Material Sourcing', 'procurement', 'done', 'medium', 15, 18, user1_id, 3, CURRENT_DATE - INTERVAL '5 days'),
        (project3_id, tenant_id, 'Manufacturing Setup', 'manufacturing', 'in_progress', 'high', 40, 20, user1_id, 4, CURRENT_DATE + INTERVAL '10 days'),
        (project3_id, tenant_id, 'Quality Check', 'qa', 'todo', 'high', 20, 0, user1_id, 5, CURRENT_DATE + INTERVAL '20 days'),
        (project3_id, tenant_id, 'Packaging Design', 'design', 'todo', 'low', 15, 0, user1_id, 6, CURRENT_DATE + INTERVAL '30 days');

    -- Add some milestones
    INSERT INTO pm.milestones (project_id, milestone_name, description, due_date, status)
    VALUES
        (project1_id, 'Manuscript Complete', 'All recipes written and tested', CURRENT_DATE + INTERVAL '60 days', 'pending'),
        (project1_id, 'Photography Complete', 'All food photography finished', CURRENT_DATE + INTERVAL '90 days', 'pending'),
        (project1_id, 'Ready for Print', 'Final layout approved', CURRENT_DATE + INTERVAL '150 days', 'pending'),

        (project2_id, 'Research Complete', 'All locations researched', CURRENT_DATE + INTERVAL '40 days', 'pending'),
        (project2_id, 'First Draft', 'Initial content draft ready', CURRENT_DATE + INTERVAL '80 days', 'pending'),

        (project3_id, 'Prototype Approved', 'Design finalized', CURRENT_DATE - INTERVAL '10 days', 'completed'),
        (project3_id, 'Production Start', 'Manufacturing begins', CURRENT_DATE + INTERVAL '5 days', 'pending'),
        (project3_id, 'Ready to Ship', 'All units packaged', CURRENT_DATE + INTERVAL '40 days', 'pending');

    -- Mark completed milestone
    UPDATE pm.milestones SET completed_at = CURRENT_DATE - INTERVAL '10 days' WHERE milestone_name = 'Prototype Approved';

    RAISE NOTICE '✅ Created 3 sample projects with tasks and milestones';
    RAISE NOTICE '   - BOOK-001: Italian Cookbook (35%% complete)';
    RAISE NOTICE '   - GUIDE-001: Venice Guide (10%% complete)';
    RAISE NOTICE '   - GADGET-001: Bookmarks (60%% complete)';
END $$;
