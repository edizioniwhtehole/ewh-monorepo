# Sistema HR Enterprise - Documentazione Completa

## 📋 Overview

Sistema HR completo enterprise-grade per gestione dipendenti, presenze, contratti, buste paga, viaggi di lavoro e note spese.

## ✅ Funzionalità Implementate

### 1. Database Schema Completo
**File**: `svc-timesheet/migrations/002_hr_system.sql`

#### Tabelle Create:
- **departments** - Struttura gerarchica dipartimenti con manager e budget
- **employees** - Anagrafica completa dipendenti con RFID
- **employment_contracts** - Gestione contratti di lavoro
- **payslips** - Buste paga con calcolo lordo/netto/detrazioni
- **attendance_checkins** - Presenze con check-in/out e GPS
- **work_trips** - Viaggi di lavoro con tracciamento GPS
- **travel_expenses** - Note spese e rimborsi
- **kiosk_stations** - Postazioni kiosk con RFID reader
- **employee_documents** - Documenti dipendenti
- **employee_dashboards** - Configurazione dashboard personali

#### Trigger Automatici:
- Calcolo automatico ore lavorate
- Calcolo distanza viaggi (Haversine formula)
- Update timestamps

### 2. Backend API (Fastify)
**Path**: `svc-timesheet/src/routes/`

#### Employee Routes (`employees.ts`):
- `GET /api/v1/employees` - Lista dipendenti (con filtri)
- `GET /api/v1/employees/:id` - Dettaglio dipendente
- `POST /api/v1/employees` - Crea dipendente (admin only)
- `PUT /api/v1/employees/:id` - Aggiorna dipendente
- `DELETE /api/v1/employees/:id` - Elimina dipendente (admin only)

#### Department Routes (`employees.ts`):
- `GET /api/v1/departments` - Lista dipartimenti
- `POST /api/v1/departments` - Crea dipartimento (admin only)
- `PUT /api/v1/departments/:id` - Aggiorna dipartimento
- `DELETE /api/v1/departments/:id` - Soft delete dipartimento

#### Attendance Routes (`attendance.ts`):
- `GET /api/v1/attendance` - Lista presenze per data
- `GET /api/v1/attendance/my/today` - Mia presenza oggi
- `POST /api/v1/attendance/check-in` - Check-in (manual/kiosk/rfid/remote)
- `POST /api/v1/attendance/:id/check-out` - Check-out con GPS
- `GET /api/v1/attendance/:id` - Dettaglio presenza

#### Autorizzazioni:
- **Role-based** (administrator, manager, employee, external_collaborator)
- **Tenant isolation** su tutte le query
- **Field-level permissions** per update

### 3. Frontend (Next.js)
**Path**: `app-web-frontend/pages/dashboard/hr/`

#### Pagine Implementate:

##### 📊 Employees (`employees.tsx`)
- Lista dipendenti con filtri (department, status)
- Modal "Aggiungi Dipendente" completo
- Ricerca real-time
- Statistiche overview (totali, attivi, in ferie, dipartimenti)
- Integrazione con backend reale

##### ⏰ Attendance (`attendance.tsx`)
- **Modalità Kiosk** fullscreen per check-in/out
  - Supporto RFID scan
  - Clock in tempo reale
  - Check-in manuale fallback
- **Vista normale**:
  - Personal attendance card
  - Check-in/out con GPS
  - Lista presenze team
  - Filtro per data
  - Indicatori ritardo/completamento

##### 📝 Timesheet (`timesheet.tsx`)
- Vista settimanale/mensile ore lavorate
- Report team con produttività
- Già esistente e funzionante

##### 📈 Reports (`reports.tsx`)
- Metriche HR (presenze, assenze, produttività)
- Trend temporali
- Già esistente e funzionante

#### Menu Navigazione:
- ✅ Dipendenti
- ✅ Presenze
- ✅ Timesheet
- ✅ Report
- ⏳ Contratti (TODO)
- ⏳ Buste Paga (TODO)
- ⏳ Viaggi Lavoro (TODO)
- ⏳ Note Spese (TODO)

### 4. API Proxy Frontend
**Path**: `app-web-frontend/pages/api/hr/`

- `employees.ts` - Proxy CRUD dipendenti
- `departments.ts` - Proxy CRUD dipartimenti
- `attendance.ts` - Proxy lista presenze
- `attendance/check-in.ts` - Proxy check-in
- `attendance/[id]/check-out.ts` - Proxy check-out

Tutte con:
- Authorization header passthrough
- Error handling
- Trasformazione dati per frontend

## 🚀 Funzionalità Enterprise Chiave

### Check-in/Check-out System
- **Multi-modalità**:
  - Manual - Click button
  - Remote - Da casa con GPS
  - Kiosk - Postazione dedicata
  - RFID - Scan badge

- **Kiosk Mode**:
  - Fullscreen UI
  - Auto-focus RFID input
  - Success/error feedback
  - Clock in tempo reale
  - Branding aziendale

- **GPS Tracking**:
  - Cattura automatica posizione
  - Storage lat/lng JSON
  - Privacy-first (on-demand)

- **Late Detection**:
  - Calcolo automatico ritardi
  - Visual indicators
  - Report statistics

### Role-Based Access Control (RBAC)
Implementato nel backend con 4 ruoli:

1. **Administrator**
   - Full access
   - CRUD dipendenti/dipartimenti
   - Configura tutto il sistema

2. **Manager**
   - View team
   - Approva presenze/spese
   - Report dipartimento

3. **Employee**
   - View self data
   - Check-in/out
   - Submit expenses

4. **External Collaborator**
   - Limited view
   - Basic timesheet
   - No sensitive data

### GPS & Location Tracking
- Formato: `{lat: number, lng: number}`
- Storage: JSONB per flessibilità
- Calcolo distanze: Haversine formula
- Privacy: Optional, user-consented

### Database Optimization
- **Indexes** su tutte le foreign keys
- **Composite indexes** per query comuni
- **Views** per query complesse (v_employees_full, v_attendance_today)
- **Triggers** per calcoli automatici

## 📁 Struttura File

```
svc-timesheet/
├── migrations/
│   └── 002_hr_system.sql          # Schema completo HR
├── src/
│   ├── db/
│   │   └── hr-schema.ts            # TypeScript types
│   ├── routes/
│   │   ├── employees.ts            # CRUD employees/departments
│   │   └── attendance.ts           # Check-in/out API
│   └── app.ts                      # Route registration

app-web-frontend/
├── pages/
│   ├── dashboard/hr/
│   │   ├── employees.tsx           # Lista dipendenti
│   │   ├── attendance.tsx          # Presenze + Kiosk
│   │   ├── timesheet.tsx           # Timesheet esistente
│   │   └── reports.tsx             # Report esistente
│   └── api/hr/
│       ├── employees.ts
│       ├── departments.ts
│       ├── attendance.ts
│       ├── attendance/
│       │   └── check-in.ts
│       └── attendance/[id]/
│           └── check-out.ts
└── src/
    ├── mock/
    │   └── apps.ts                 # HR app in menu
    └── types/
        └── apps.ts                 # HR category type
```

## 🔧 Tecnologie Utilizzate

### Backend
- **Fastify** - Web framework
- **PostgreSQL** - Database con JSONB per GPS
- **TypeScript** - Type safety
- **JWT** - Authentication

### Frontend
- **Next.js 14** (Pages Router)
- **React 18**
- **TanStack Query** - Data fetching
- **Tailwind CSS** - Styling
- **Lucide React** - Icons

## 📊 Schema Database (Highlights)

### employees
```sql
- id, tenant_id, user_id
- first_name, last_name, email, phone
- department_id, manager_id
- role (administrator/manager/employee/external_collaborator)
- status (active/inactive/on_leave/terminated)
- hire_date, termination_date
- rfid_tag (per kiosk)
- salary_annual, weekly_hours
```

### attendance_checkins
```sql
- id, tenant_id, employee_id
- check_in_time, check_out_time
- check_in_type (manual/kiosk/rfid/remote/gps)
- check_in_location, check_out_location (JSONB)
- total_hours (auto-calculated)
- is_late, is_early_leave
- kiosk_id, rfid_tag
```

### work_trips
```sql
- id, tenant_id, employee_id
- trip_date, purpose
- start_location, end_location (JSONB)
- gps_track_points (JSONB array)
- distance_km (auto-calculated)
- has_expenses
```

### travel_expenses
```sql
- id, tenant_id, employee_id
- work_trip_id (FK)
- expense_date, category, amount
- receipt_url (S3)
- is_mileage_claim, mileage_km
- status (draft/submitted/approved/rejected/paid)
- reviewed_by, reviewed_at
```

## 🎯 Funzionalità Implementate vs TODO

### ✅ Implementato
- [x] Database schema completo
- [x] Backend CRUD dipendenti/dipartimenti
- [x] Backend check-in/check-out con GPS
- [x] Frontend pagina dipendenti con modal
- [x] Frontend pagina presenze
- [x] Kiosk mode fullscreen
- [x] RFID support
- [x] GPS location capture
- [x] Role-based authorization
- [x] Tenant isolation
- [x] Menu navigazione HR

### ⏳ TODO (Per completare enterprise-grade)

#### Pagine Frontend Mancanti:
1. **Contratti** (`/dashboard/hr/contracts`)
   - Lista contratti attivi/scaduti
   - Upload documento contratto
   - Firma elettronica
   - Notifiche rinnovo

2. **Buste Paga** (`/dashboard/hr/payslips`)
   - Lista buste paga per mese/anno
   - Download PDF
   - Dettaglio lordo/netto/detrazioni
   - Storico pagamenti

3. **Viaggi Lavoro** (`/dashboard/hr/trips`)
   - Mappa viaggi (Mapbox/Leaflet)
   - Tracciamento GPS realtime
   - Visualizzazione percorsi
   - Collegamento a note spese

4. **Note Spese** (`/dashboard/hr/expenses`)
   - Submit spesa con ricevuta
   - Upload foto ricevuta
   - Calcolo rimborso km
   - Workflow approvazione
   - Export per contabilità

#### Backend Routes Mancanti:
- [ ] `GET/POST /api/v1/contracts` - Contratti
- [ ] `GET/POST /api/v1/payslips` - Buste paga
- [ ] `GET/POST /api/v1/trips` - Viaggi
- [ ] `POST /api/v1/trips/:id/track` - GPS tracking
- [ ] `GET/POST /api/v1/expenses` - Note spese
- [ ] `POST /api/v1/expenses/:id/approve` - Approvazione
- [ ] `POST /api/v1/expenses/:id/reject` - Rifiuto

#### Dashboard Personali:
- [ ] Dashboard Administrator (overview completo)
- [ ] Dashboard Manager (team focus)
- [ ] Dashboard Employee (personal focus)
- [ ] Dashboard External (limited view)

#### Analytics Avanzati:
- [ ] Costi personale per dipartimento
- [ ] Trend assenze/presenze
- [ ] Produttività metrics
- [ ] Export Excel/PDF reports
- [ ] Predictive analytics

#### Integrazioni:
- [ ] SSO/SAML authentication
- [ ] Calendar integration (Outlook/Google)
- [ ] Export contabilità (CSV/XML)
- [ ] Webhook API per terze parti
- [ ] Mobile app / PWA

#### Compliance:
- [ ] GDPR consent management
- [ ] Data retention policies
- [ ] Audit trail completo
- [ ] Data anonimizzazione
- [ ] Right to be forgotten

## 🚀 Come Usare

### 1. Database Setup
```bash
# Run migration
docker exec -i ewh_postgres psql -U ewh -d ewh_master < svc-timesheet/migrations/002_hr_system.sql
```

### 2. Backend Restart
```bash
docker restart svc_timesheet
```

### 3. Frontend
```bash
cd app-web-frontend
pnpm dev
```

### 4. Accesso
- URL: http://localhost:3100/dashboard/hr/employees
- Menu: Sidebar → Human Resources

## 📝 Note di Sviluppo

### Authorization Pattern
```typescript
// API routes passthrough
headers: { 'Authorization': `Bearer ${session?.accessToken}` }

// Backend verifica
const { tenant_id, user_id } = request.authContext;
```

### GPS Capture
```typescript
const position = await new Promise<GeolocationPosition>((resolve) => {
  navigator.geolocation.getCurrentPosition(resolve, () => resolve(null));
});

const location = position ? {
  lat: position.coords.latitude,
  lng: position.coords.longitude
} : null;
```

### Kiosk Mode
```typescript
// Fullscreen UI con auto-focus RFID
<input autoFocus onKeyPress={(e) => {
  if (e.key === 'Enter') handleRFIDScan();
}} />
```

## 🎨 UI/UX Design

### Color Scheme
- **Primary**: Orange (#ea580c) - HR branding
- **Success**: Green - Check-in, approved
- **Warning**: Orange - Late, pending
- **Error**: Red - Violations, rejected
- **Info**: Blue - In progress

### Icons (Lucide)
- Users - Employees
- Clock - Attendance
- LogIn/LogOut - Check-in/out
- Monitor - Kiosk mode
- MapPin - GPS location
- FileText - Documents
- DollarSign - Expenses

## 🔐 Sicurezza

- ✅ JWT authentication
- ✅ Role-based authorization
- ✅ Tenant isolation (RLS simulata)
- ✅ Input validation
- ✅ SQL injection protection (parameterized queries)
- ✅ Rate limiting
- ✅ CORS configurato
- ✅ Helmet security headers

## 📈 Performance

- ✅ Indexes su tutte FK
- ✅ Composite indexes per query comuni
- ✅ React Query caching
- ✅ Lazy loading componenti (dynamic import)
- ✅ Pagination supporto API
- ⏳ Database connection pooling
- ⏳ Redis caching (future)

## 🧪 Testing TODO

- [ ] Unit tests backend routes
- [ ] Integration tests API
- [ ] E2E tests frontend
- [ ] Load testing
- [ ] Security penetration testing

## 📚 Documentazione Aggiuntiva

- **API Docs**: Swagger/OpenAPI (TODO)
- **User Guide**: Manuale utente (TODO)
- **Admin Guide**: Guida amministratore (TODO)
- **Developer Guide**: Questo documento

## 🎯 Roadmap

### Phase 1 - Core ✅ (DONE)
- Database schema
- Employee management
- Attendance tracking
- Basic UI

### Phase 2 - Documents (IN PROGRESS)
- Contracts management
- Payslips viewer
- Document storage (S3)

### Phase 3 - Mobility
- GPS trip tracking
- Expense management
- Approval workflows

### Phase 4 - Analytics
- Advanced reporting
- Dashboards per role
- Predictive analytics

### Phase 5 - Enterprise
- SSO integration
- Mobile app
- Third-party integrations
- Compliance features

## 💡 Best Practices Implementate

1. **Type Safety**: Full TypeScript coverage
2. **Error Handling**: Structured error responses
3. **Validation**: Input validation at API level
4. **Logging**: Structured logging (Fastify logger)
5. **Monitoring**: Health check endpoints
6. **Documentation**: Inline comments + questo doc
7. **Git**: Conventional commits (TODO)
8. **Code Review**: (TODO)

## 🤝 Contribuire

Per aggiungere nuove funzionalità:

1. Crea migration SQL in `svc-timesheet/migrations/`
2. Genera TypeScript types in `src/db/hr-schema.ts`
3. Crea route backend in `src/routes/`
4. Registra route in `src/app.ts`
5. Crea pagina frontend in `pages/dashboard/hr/`
6. Crea API proxy in `pages/api/hr/`
7. Aggiorna menu in `src/mock/apps.ts`
8. Update questo documento

## 📞 Supporto

Per domande o problemi:
- Issue tracking: GitHub (TODO)
- Documentation: Questo file
- Team: Internal HR Tech team

---

**Versione**: 1.0.0
**Ultimo aggiornamento**: 2025-10-04
**Autore**: EWH Development Team
**Status**: 🟡 In Development (Core Complete)
