-- Migration 029: Editorial House Templates (OPTIONAL - Industry Specific)
-- These are example templates for a publishing house (Casa Editrice)
-- Can be removed or replaced with templates for other industries

-- ============================================================================
-- EDITORIAL TEMPLATES (Casa Editrice)
-- ============================================================================

INSERT INTO pm.project_templates (id, tenant_id, template_key, template_name, category, description, estimated_duration_days, task_templates, milestone_templates)
VALUES
-- Template 1: Book Publication
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'book_publication',
    'Pubblicazione Libro',
    'editorial',
    'Workflow completo per pubblicazione libro: editing, impaginazione, stampa',
    180,
    '[
        {"name": "Revisione Editoriale", "category": "editing", "estimated_hours": 80, "order": 1},
        {"name": "Impaginazione", "category": "layout", "estimated_hours": 40, "order": 2},
        {"name": "Correzione Bozze", "category": "editing", "estimated_hours": 24, "order": 3},
        {"name": "Progettazione Copertina", "category": "design", "estimated_hours": 16, "order": 4},
        {"name": "Stampa Prototipo", "category": "printing", "estimated_hours": 8, "order": 5},
        {"name": "Revisione Finale", "category": "editing", "estimated_hours": 16, "order": 6},
        {"name": "Stampa Tiratura", "category": "printing", "estimated_hours": 4, "order": 7},
        {"name": "Distribuzione", "category": "logistics", "estimated_hours": 8, "order": 8}
    ]'::jsonb,
    '[
        {"name": "Bozza Approvata", "due_days": 60},
        {"name": "Layout Completato", "due_days": 120},
        {"name": "Stampa Confermata", "due_days": 150},
        {"name": "Distribuzione Avviata", "due_days": 180}
    ]'::jsonb
),

-- Template 2: Tourist Guide
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'tourist_guide',
    'Guida Turistica',
    'editorial',
    'Creazione guida turistica con foto, mappe, traduzioni',
    120,
    '[
        {"name": "Ricerca e Sopralluoghi", "category": "research", "estimated_hours": 40, "order": 1},
        {"name": "Scrittura Contenuti", "category": "writing", "estimated_hours": 60, "order": 2},
        {"name": "Fotografia", "category": "photography", "estimated_hours": 24, "order": 3},
        {"name": "Traduzione", "category": "translation", "estimated_hours": 48, "order": 4},
        {"name": "Editing Multilingua", "category": "editing", "estimated_hours": 32, "order": 5},
        {"name": "Impaginazione", "category": "layout", "estimated_hours": 24, "order": 6},
        {"name": "Stampa", "category": "printing", "estimated_hours": 8, "order": 7}
    ]'::jsonb,
    '[
        {"name": "Contenuti Completati", "due_days": 45},
        {"name": "Traduzioni Approvate", "due_days": 75},
        {"name": "Pronta per Stampa", "due_days": 105}
    ]'::jsonb
),

-- Template 3: Gadget Production
(
    uuid_generate_v4(),
    '00000000-0000-0000-0000-000000000001',
    'gadget_production',
    'Gadget Promozionale',
    'editorial',
    'Produzione gadget turistici (magneti, segnalibri, ecc.)',
    60,
    '[
        {"name": "Concept Design", "category": "design", "estimated_hours": 16, "order": 1},
        {"name": "Prototipo", "category": "prototyping", "estimated_hours": 8, "order": 2},
        {"name": "Approvazione Cliente", "category": "approval", "estimated_hours": 4, "order": 3},
        {"name": "Ordine Materiali", "category": "procurement", "estimated_hours": 4, "order": 4},
        {"name": "Produzione", "category": "manufacturing", "estimated_hours": 16, "order": 5},
        {"name": "Controllo Qualità", "category": "qa", "estimated_hours": 8, "order": 6},
        {"name": "Confezionamento", "category": "packaging", "estimated_hours": 8, "order": 7}
    ]'::jsonb,
    '[
        {"name": "Design Approvato", "due_days": 14},
        {"name": "Materiali Arrivati", "due_days": 30},
        {"name": "Produzione Completata", "due_days": 52}
    ]'::jsonb
)
ON CONFLICT (tenant_id, template_key) DO NOTHING;

DO $$
DECLARE
    template_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO template_count FROM pm.project_templates WHERE category = 'editorial';
    RAISE NOTICE '✅ Installed % editorial templates', template_count;
END $$;
