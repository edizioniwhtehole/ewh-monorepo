#!/bin/bash

# Script to populate PM system with realistic, complete data
# Includes: projects with hierarchy, tasks with subtasks/checklists, costs, expenses

API_URL="http://localhost:5500/api/pm"
TENANT_ID="00000000-0000-0000-0000-000000000001"
USER_ID="00000000-0000-0000-0000-000000000001"

echo "🚀 Popolamento database PM con dati realistici..."
echo ""

# Function to create project with full data
create_project() {
  local NAME="$1"
  local CODE="$2"
  local BUDGET="$3"
  local PARENT_ID="$4"

  echo "📁 Creando progetto: $NAME"

  RESPONSE=$(curl -s -X POST "$API_URL/projects/from-template" \
    -H "Content-Type: application/json" \
    -d "{
      \"tenantId\": \"$TENANT_ID\",
      \"templateKey\": \"book_publication\",
      \"projectName\": \"$NAME\",
      \"projectCode\": \"$CODE\",
      \"budget\": $BUDGET,
      \"hourlyRate\": 75,
      \"currency\": \"EUR\",
      \"parentProjectId\": $PARENT_ID,
      \"customFields\": {
        \"industry\": \"Editorial\",
        \"client\": \"Casa Editrice Mondadori\"
      }
    }")

  PROJECT_ID=$(echo $RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "   ✅ ID: $PROJECT_ID"
  echo "$PROJECT_ID"
}

# Function to create task with subtasks and checklist
create_task_with_hierarchy() {
  local PROJECT_ID="$1"
  local TASK_NAME="$2"
  local PRIORITY="$3"
  local EST_HOURS="$4"

  echo "   📝 Task: $TASK_NAME"

  # Create main task
  TASK_RESPONSE=$(curl -s -X POST "$API_URL/tasks" \
    -H "Content-Type: application/json" \
    -d "{
      \"tenantId\": \"$TENANT_ID\",
      \"projectId\": \"$PROJECT_ID\",
      \"taskName\": \"$TASK_NAME\",
      \"status\": \"in_progress\",
      \"priority\": \"$PRIORITY\",
      \"assignedTo\": \"$USER_ID\",
      \"estimatedHours\": $EST_HOURS,
      \"startDate\": \"2025-10-13\",
      \"endDate\": \"2025-10-27\",
      \"cardCustomData\": {
        \"tags\": [\"editorial\", \"design\"],
        \"effort\": $EST_HOURS
      }
    }")

  TASK_ID=$(echo $TASK_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "      Task ID: $TASK_ID"
  echo "$TASK_ID"
}

# Function to add subtask
add_subtask() {
  local PARENT_ID="$1"
  local PROJECT_ID="$2"
  local NAME="$3"
  local STATUS="$4"

  curl -s -X POST "$API_URL/tasks" \
    -H "Content-Type: application/json" \
    -d "{
      \"tenantId\": \"$TENANT_ID\",
      \"projectId\": \"$PROJECT_ID\",
      \"parentTaskId\": \"$PARENT_ID\",
      \"taskName\": \"$NAME\",
      \"status\": \"$STATUS\",
      \"taskLevel\": 1,
      \"estimatedHours\": 4
    }" > /dev/null

  echo "      ↳ Subtask: $NAME ($STATUS)"
}

# Function to add expense
add_expense() {
  local PROJECT_ID="$1"
  local DESCRIPTION="$2"
  local AMOUNT="$3"
  local CATEGORY="$4"

  curl -s -X POST "$API_URL/expenses" \
    -H "Content-Type: application/json" \
    -d "{
      \"tenantId\": \"$TENANT_ID\",
      \"projectId\": \"$PROJECT_ID\",
      \"expenseDate\": \"2025-10-10\",
      \"description\": \"$DESCRIPTION\",
      \"amount\": $AMOUNT,
      \"category\": \"$CATEGORY\",
      \"vendorName\": \"Fornitore Esterno\",
      \"isBillable\": true,
      \"approvalStatus\": \"approved\",
      \"submittedBy\": \"$USER_ID\"
    }" > /dev/null

  echo "      💰 Spesa: $DESCRIPTION (€$AMOUNT)"
}

# Function to log time
log_time() {
  local TASK_ID="$1"
  local HOURS="$2"
  local RATE="$3"

  curl -s -X POST "$API_URL/time/manual" \
    -H "Content-Type: application/json" \
    -d "{
      \"tenantId\": \"$TENANT_ID\",
      \"taskId\": \"$TASK_ID\",
      \"userId\": \"$USER_ID\",
      \"startTime\": \"2025-10-13T09:00:00Z\",
      \"hours\": $HOURS,
      \"hourlyRate\": $RATE,
      \"billable\": true
    }" > /dev/null

  echo "      ⏱️  Ore registrate: ${HOURS}h @ €$RATE/h"
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  PROGETTO PRINCIPALE: Collana Cucina Italiana"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

MAIN_PROJECT=$(create_project "Collana Cucina Italiana 2025" "COOK-2025" 150000 null)
sleep 1

# Add main project tasks
TASK1=$(create_task_with_hierarchy "$MAIN_PROJECT" "Definizione Concept Collana" "high" 40)
sleep 0.5
add_subtask "$TASK1" "$MAIN_PROJECT" "Ricerca mercato e competitor" "done"
add_subtask "$TASK1" "$MAIN_PROJECT" "Definizione target e positioning" "done"
add_subtask "$TASK1" "$MAIN_PROJECT" "Creazione moodboard e concept visivo" "in_progress"
add_subtask "$TASK1" "$MAIN_PROJECT" "Approvazione stakeholder" "todo"
log_time "$TASK1" 25 80

TASK2=$(create_task_with_hierarchy "$MAIN_PROJECT" "Setup Struttura Editoriale" "high" 30)
sleep 0.5
add_subtask "$TASK2" "$MAIN_PROJECT" "Definizione formato e pagine" "done"
add_subtask "$TASK2" "$MAIN_PROJECT" "Creazione template InDesign" "in_progress"
add_subtask "$TASK2" "$MAIN_PROJECT" "Sistema di gestione contenuti" "todo"
log_time "$TASK2" 18 75

add_expense "$MAIN_PROJECT" "Licenze Adobe Creative Cloud Team" 2500 "Software"
add_expense "$MAIN_PROJECT" "Consulenza Food Stylist" 3500 "External Services"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  SOTTOPROGETTO: Volume 1 - Pasta & Primi"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VOL1=$(create_project "Volume 1: Pasta e Primi Piatti" "COOK-VOL1" 45000 "\"$MAIN_PROJECT\"")
sleep 1

TASK3=$(create_task_with_hierarchy "$VOL1" "Raccolta e Selezione Ricette" "urgent" 60)
sleep 0.5
add_subtask "$TASK3" "$VOL1" "Ricette tradizionali pasta fresca" "done"
add_subtask "$TASK3" "$VOL1" "Ricette pasta secca" "done"
add_subtask "$TASK3" "$VOL1" "Ricette risotti" "in_progress"
add_subtask "$TASK3" "$VOL1" "Ricette zuppe e minestre" "in_progress"
add_subtask "$TASK3" "$VOL1" "Testing e validazione ricette" "todo"
log_time "$TASK3" 45 50

TASK4=$(create_task_with_hierarchy "$VOL1" "Servizio Fotografico Piatti" "high" 80)
sleep 0.5
add_subtask "$TASK4" "$VOL1" "Pianificazione shooting (20 ricette)" "done"
add_subtask "$TASK4" "$VOL1" "Preparazione food styling" "in_progress"
add_subtask "$TASK4" "$VOL1" "Shooting in studio (5 giorni)" "todo"
add_subtask "$TASK4" "$VOL1" "Post-produzione immagini" "todo"
log_time "$TASK4" 12 150

TASK5=$(create_task_with_hierarchy "$VOL1" "Impaginazione e Grafica" "medium" 100)
sleep 0.5
add_subtask "$TASK5" "$VOL1" "Definizione layout pagine ricette" "done"
add_subtask "$TASK5" "$VOL1" "Impaginazione capitolo 1 (pasta fresca)" "in_progress"
add_subtask "$TASK5" "$VOL1" "Impaginazione capitolo 2 (pasta secca)" "todo"
add_subtask "$TASK5" "$VOL1" "Impaginazione capitolo 3 (risotti)" "todo"
add_subtask "$TASK5" "$VOL1" "Revisione e correzioni" "todo"
log_time "$TASK5" 32 75

TASK6=$(create_task_with_hierarchy "$VOL1" "Editing e Correzione Bozze" "medium" 40)
sleep 0.5
add_subtask "$TASK6" "$VOL1" "Prima revisione testi" "in_progress"
add_subtask "$TASK6" "$VOL1" "Correzione refusi e errori" "todo"
add_subtask "$TASK6" "$VOL1" "Verifica coerenza terminologia" "todo"
add_subtask "$TASK6" "$VOL1" "Approvazione finale" "todo"
log_time "$TASK6" 22 60

add_expense "$VOL1" "Servizio fotografico professionale (5gg)" 8500 "Photography"
add_expense "$VOL1" "Food styling e props" 2800 "Photography"
add_expense "$VOL1" "Ingredienti per test ricette" 1200 "Materials"
add_expense "$VOL1" "Stampa bozze colore" 450 "Printing"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  SOTTOPROGETTO: Volume 2 - Secondi & Contorni"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VOL2=$(create_project "Volume 2: Secondi e Contorni" "COOK-VOL2" 42000 "\"$MAIN_PROJECT\"")
sleep 1

TASK7=$(create_task_with_hierarchy "$VOL2" "Sviluppo Contenuti" "high" 50)
sleep 0.5
add_subtask "$TASK7" "$VOL2" "Ricette carne" "in_progress"
add_subtask "$TASK7" "$VOL2" "Ricette pesce" "todo"
add_subtask "$TASK7" "$VOL2" "Ricette vegetariane" "todo"
add_subtask "$TASK7" "$VOL2" "Contorni stagionali" "todo"
log_time "$TASK7" 18 50

TASK8=$(create_task_with_hierarchy "$VOL2" "Pianificazione Fotografica" "medium" 20)
sleep 0.5
add_subtask "$TASK8" "$VOL2" "Selezione location" "in_progress"
add_subtask "$TASK8" "$VOL2" "Brief al fotografo" "todo"
add_subtask "$TASK8" "$VOL2" "Calendario shooting" "todo"
log_time "$TASK8" 8 80

add_expense "$VOL2" "Ricerca e scouting location" 800 "External Services"
add_expense "$VOL2" "Acquisto stoviglie e props" 1500 "Materials"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  PROGETTO SEPARATO: Guida Turistica Venezia"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VENICE=$(create_project "Guida Turistica: Venezia Segreta" "VENICE-2025" 35000 null)
sleep 1

TASK9=$(create_task_with_hierarchy "$VENICE" "Ricerca Contenuti" "high" 80)
sleep 0.5
add_subtask "$TASK9" "$VENICE" "Itinerari fuori dai percorsi turistici" "done"
add_subtask "$TASK9" "$VENICE" "Interviste artigiani locali" "in_progress"
add_subtask "$TASK9" "$VENICE" "Ristoranti e bacari tipici" "in_progress"
add_subtask "$TASK9" "$VENICE" "Eventi culturali" "todo"
log_time "$TASK9" 48 60

TASK10=$(create_task_with_hierarchy "$VENICE" "Reportage Fotografico" "high" 60)
sleep 0.5
add_subtask "$TASK10" "$VENICE" "Foto monumenti meno noti" "in_progress"
add_subtask "$TASK10" "$VENICE" "Foto vita quotidiana veneziana" "todo"
add_subtask "$TASK10" "$VENICE" "Foto dettagli architettonici" "todo"
log_time "$TASK10" 24 150

TASK11=$(create_task_with_hierarchy "$VENICE" "Mappe Illustrate" "medium" 40)
sleep 0.5
add_subtask "$TASK11" "$VENICE" "Mappa generale Venezia" "in_progress"
add_subtask "$TASK11" "$VENICE" "Mappe quartieri singoli" "todo"
add_subtask "$TASK11" "$VENICE" "Icone e legenda" "todo"
log_time "$TASK11" 16 85

add_expense "$VENICE" "Viaggio e soggiorno Venezia (5gg, 2 persone)" 2800 "Travel"
add_expense "$VENICE" "Fotografo professionista" 4500 "Photography"
add_expense "$VENICE" "Illustratore mappe" 3200 "Design"
add_expense "$VENICE" "Permessi fotografici monumenti" 450 "Administrative"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  PROGETTO: Sistema Gestione Magazine Online"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

MAGAZINE=$(create_project "Piattaforma Magazine Digitale" "MAG-PLATFORM" 65000 null)
sleep 1

TASK12=$(create_task_with_hierarchy "$MAGAZINE" "Backend Development" "urgent" 120)
sleep 0.5
add_subtask "$TASK12" "$MAGAZINE" "Setup architettura microservizi" "done"
add_subtask "$TASK12" "$MAGAZINE" "API gestione articoli" "done"
add_subtask "$TASK12" "$MAGAZINE" "Sistema autenticazione" "in_progress"
add_subtask "$TASK12" "$MAGAZINE" "API media e CDN" "in_progress"
add_subtask "$TASK12" "$MAGAZINE" "Sistema notifiche" "todo"
log_time "$TASK12" 72 100

TASK13=$(create_task_with_hierarchy "$MAGAZINE" "Frontend React" "urgent" 100)
sleep 0.5
add_subtask "$TASK13" "$MAGAZINE" "Setup Next.js e routing" "done"
add_subtask "$TASK13" "$MAGAZINE" "Componenti UI base" "done"
add_subtask "$TASK13" "$MAGAZINE" "Editor articoli WYSIWYG" "in_progress"
add_subtask "$TASK13" "$MAGAZINE" "Sistema preview" "todo"
add_subtask "$TASK13" "$MAGAZINE" "Ottimizzazione performance" "todo"
log_time "$TASK13" 58 100

TASK14=$(create_task_with_hierarchy "$MAGAZINE" "Design System & UI/UX" "high" 60)
sleep 0.5
add_subtask "$TASK14" "$MAGAZINE" "Wireframe e user flows" "done"
add_subtask "$TASK14" "$MAGAZINE" "Design componenti Figma" "done"
add_subtask "$TASK14" "$MAGAZINE" "Implementazione Tailwind" "in_progress"
add_subtask "$TASK14" "$MAGAZINE" "Responsive design" "in_progress"
log_time "$TASK14" 38 75

add_expense "$MAGAZINE" "Hosting AWS (anno)" 3600 "Infrastructure"
add_expense "$MAGAZINE" "CDN Cloudflare Pro" 1200 "Infrastructure"
add_expense "$MAGAZINE" "Licenze Figma Team" 450 "Software"
add_expense "$MAGAZINE" "Testing utenti (10 sessioni)" 1500 "External Services"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Popolamento completato!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Riepilogo dati creati:"
echo "   • 5 progetti principali"
echo "   • 2 sottoprogetti (gerarchia)"
echo "   • 14 task principali"
echo "   • ~50 subtask"
echo "   • ~20 voci di spesa"
echo "   • Ore lavorate registrate"
echo ""
echo "🌐 Visualizza su: http://localhost:5400"
echo ""
