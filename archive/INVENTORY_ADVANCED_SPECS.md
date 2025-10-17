# Inventory Management - Advanced Specifications

## Overview
Sistema di gestione magazzino enterprise con gestione avanzata articoli, specifiche tecniche, controllo qualità, accettazione merce, e sistema di contestazioni.

---

## 1. Item Details & Specifications

### 1.1 Tipi di Articolo (Item Types)

#### A. Shelf Items (Articoli a Scaffale)
- **Caratteristiche**:
  - Prodotti finiti pronti per la vendita
  - Codice SKU univoco
  - Prezzo fisso/listino
  - Gestione per ubicazione specifica
  - Tracciamento seriale opzionale
  - Foto prodotto principale + galleria
  - Scheda tecnica PDF
  - Dimensioni e peso per shipping

#### B. Bulk Items (Articoli Sfusi)
- **Caratteristiche**:
  - Venduti a peso/volume (kg, litri, metri)
  - Nessun tracking seriale
  - Gestione per container/big bag
  - Certificati di analisi
  - Specifiche chimiche/fisiche
  - Schede di sicurezza (SDS)
  - Temperatura/umidità stoccaggio

#### C. Lot-Managed Items (Articoli con Lotto)
- **Caratteristiche**:
  - OBBLIGATORIO numero lotto
  - Data produzione
  - Data scadenza
  - Certificato di conformità per lotto
  - Tracciabilità completa lotto → ordine cliente
  - Blocco lotti non conformi
  - Alert scadenze

#### D. Serial-Tracked Items (Articoli Serializzati)
- **Caratteristiche**:
  - Numero seriale univoco per ogni unità
  - Storico completo per seriale
  - Garanzia per seriale
  - Registro manutenzioni
  - Non mescolabili in picking

### 1.2 Scheda Articolo Dettagliata

```typescript
interface ItemDetail {
  // Base Info
  id: string;
  sku: string;
  name: string;
  description: string;
  long_description: string; // HTML editor
  item_type: 'product' | 'raw_material' | 'component' | 'consumable' | 'service';
  
  // Classification
  category: string;
  subcategory: string;
  brand: string;
  manufacturer: string;
  manufacturer_part_number: string;
  ean_barcode: string;
  custom_classification: Record<string, any>; // Custom fields
  
  // Inventory Management
  storage_type: 'shelf' | 'bulk' | 'lot_managed' | 'serial_tracked';
  unit_of_measure: string;
  secondary_uom: string; // e.g. box/pallet
  conversion_factor: number;
  lot_tracking_enabled: boolean;
  serial_tracking_enabled: boolean;
  expiry_tracking_enabled: boolean;
  
  // Physical Properties
  dimensions: {
    length: number;
    width: number;
    height: number;
    unit: 'mm' | 'cm' | 'm';
  };
  weight: {
    gross: number;
    net: number;
    unit: 'g' | 'kg' | 'ton';
  };
  volume: {
    value: number;
    unit: 'ml' | 'l' | 'm3';
  };
  
  // Storage Requirements
  storage_conditions: {
    temperature_min: number;
    temperature_max: number;
    humidity_min: number;
    humidity_max: number;
    special_requirements: string[];
    hazardous_material: boolean;
    un_number: string; // UN code per materiali pericolosi
  };
  
  // Procurement
  preferred_supplier_id: string;
  alternative_suppliers: string[];
  lead_time_days: number;
  moq: number; // Minimum Order Quantity
  order_multiple: number; // Ordini in multipli di X
  
  // Costing
  cost_method: 'fifo' | 'lifo' | 'weighted_avg' | 'standard';
  standard_cost: number;
  last_purchase_cost: number;
  average_cost: number;
  
  // Reordering
  reorder_level: number;
  reorder_quantity: number;
  safety_stock: number;
  max_stock_level: number;
  
  // Quality Control
  inspection_required_on_receipt: boolean;
  quality_hold_on_receipt: boolean; // Blocco automatico in attesa ispezione
  shelf_life_days: number;
  quarantine_location_id: string;
  
  // Documentation
  attachments: Attachment[];
  photos: Photo[];
  technical_specs: TechnicalSpec[];
  certificates: Certificate[];
  sds_document_id: string; // Safety Data Sheet
  
  // Status
  is_active: boolean;
  is_discontinued: boolean;
  replacement_item_id: string;
  lifecycle_status: 'development' | 'active' | 'phase_out' | 'discontinued';
  
  // Metadata
  created_by: string;
  created_at: Date;
  updated_at: Date;
}

interface Attachment {
  id: string;
  item_id: string;
  file_name: string;
  file_type: string;
  file_size: number;
  file_url: string;
  document_type: 'datasheet' | 'manual' | 'certificate' | 'drawing' | 'photo' | 'other';
  version: string;
  uploaded_by: string;
  uploaded_at: Date;
}

interface Photo {
  id: string;
  item_id: string;
  url: string;
  thumbnail_url: string;
  is_primary: boolean;
  caption: string;
  sort_order: number;
  uploaded_by: string;
  uploaded_at: Date;
}

interface TechnicalSpec {
  id: string;
  item_id: string;
  spec_name: string;
  spec_value: string;
  spec_unit: string;
  spec_category: string; // e.g. "Electrical", "Mechanical", "Chemical"
  is_critical: boolean; // Spec critiche per QC
  tolerance_min: number;
  tolerance_max: number;
}

interface Certificate {
  id: string;
  item_id: string;
  lot_number: string; // Null se certificato generale
  certificate_type: 'conformity' | 'analysis' | 'quality' | 'origin' | 'rohs' | 'ce';
  certificate_number: string;
  issue_date: Date;
  expiry_date: Date;
  issued_by: string;
  document_url: string;
  verification_status: 'pending' | 'verified' | 'rejected';
}
```

---

## 2. Goods Receiving & Inspection (Accettazione Merce)

### 2.1 Receiving Process Flow

```
1. Purchase Order Created
   ↓
2. Shipment Notification (ASN - Advanced Shipping Notice)
   ↓
3. Goods Arrive at Dock
   ↓
4. Create Goods Receipt Note (GRN)
   ↓
5. Physical Count & Condition Check
   ↓
6. Quality Inspection (if required)
   ↓
7a. Accept → Move to Stock
7b. Partial Accept → Split acceptance/rejection
7c. Reject → Open Dispute Ticket
```

### 2.2 Goods Receipt Note (GRN)

```typescript
interface GoodsReceiptNote {
  id: string;
  tenant_id: string;
  grn_number: string; // GRN-2025-00001
  
  // Reference Documents
  purchase_order_id: string;
  supplier_id: string;
  supplier_delivery_note: string;
  supplier_invoice_number: string;
  
  // Shipment Info
  carrier: string;
  tracking_number: string;
  received_date: Date;
  received_by_user_id: string;
  receiving_location_id: string;
  
  // Status
  status: 'draft' | 'receiving' | 'inspection' | 'accepted' | 'rejected' | 'partial' | 'dispute';
  
  // Lines
  lines: GRNLine[];
  
  // Inspection
  inspection_required: boolean;
  inspection_completed: boolean;
  inspection_result: 'pass' | 'fail' | 'conditional';
  inspector_user_id: string;
  inspection_notes: string;
  
  // Photos/Documents
  delivery_photos: Photo[]; // Foto del pallet/colli alla ricezione
  damage_photos: Photo[]; // Foto eventuali danni
  documents: Attachment[]; // DDT, fatture, certificati
  
  // Totals
  total_packages: number;
  total_weight: number;
  
  created_at: Date;
  updated_at: Date;
}

interface GRNLine {
  id: string;
  grn_id: string;
  line_number: number;
  
  // Item Info
  item_id: string;
  item_name: string;
  item_sku: string;
  
  // Ordered vs Received
  ordered_quantity: number;
  received_quantity: number;
  accepted_quantity: number;
  rejected_quantity: number;
  
  // Lot/Serial
  lot_number: string;
  serial_numbers: string[];
  manufacture_date: Date;
  expiry_date: Date;
  
  // Quality Check
  inspection_status: 'pending' | 'pass' | 'fail' | 'conditional';
  inspection_notes: string;
  quality_photos: Photo[];
  
  // Rejection Reasons
  rejection_reason: 'damaged' | 'wrong_item' | 'wrong_quantity' | 'expired' | 'quality_fail' | 'other';
  rejection_notes: string;
  
  // Acceptance
  accepted_to_location_id: string;
  rejected_to_location_id: string; // Zona resi/contestazioni
  
  created_at: Date;
}
```

### 2.3 Quality Inspection Checklist

```typescript
interface InspectionChecklist {
  id: string;
  item_id: string;
  checklist_name: string;
  checklist_type: 'receiving' | 'production' | 'shipping' | 'periodic';
  
  checkpoints: InspectionCheckpoint[];
  
  is_mandatory: boolean;
  created_by: string;
  created_at: Date;
}

interface InspectionCheckpoint {
  id: string;
  sequence: number;
  checkpoint_name: string;
  checkpoint_type: 'visual' | 'measurement' | 'test' | 'document';
  
  // For measurements
  expected_value: string;
  tolerance_min: number;
  tolerance_max: number;
  unit: string;
  
  // For visual/test
  pass_criteria: string;
  
  is_critical: boolean; // Se fallisce, blocca accettazione
  photo_required: boolean;
}

interface InspectionResult {
  id: string;
  grn_line_id: string;
  checklist_id: string;
  
  inspector_id: string;
  inspection_date: Date;
  
  checkpoint_results: CheckpointResult[];
  
  overall_result: 'pass' | 'fail' | 'conditional';
  notes: string;
  photos: Photo[];
  
  signed_by: string;
  signature_data: string; // Base64 firma digitale
}

interface CheckpointResult {
  checkpoint_id: string;
  result: 'pass' | 'fail' | 'na';
  measured_value: string;
  notes: string;
  photo_ids: string[];
}
```

---

## 3. Dispute Management (Sistema Contestazioni)

### 3.1 Dispute Ticket

```typescript
interface DisputeTicket {
  id: string;
  tenant_id: string;
  ticket_number: string; // DISP-2025-00001
  
  // Reference
  dispute_type: 'receiving' | 'quality' | 'delivery' | 'invoice' | 'other';
  grn_id: string;
  purchase_order_id: string;
  supplier_id: string;
  item_id: string;
  
  // Issue Details
  issue_category: 'damaged_goods' | 'wrong_item' | 'short_delivery' | 'quality_defect' | 
                  'late_delivery' | 'documentation_error' | 'other';
  issue_description: string;
  
  // Quantities
  disputed_quantity: number;
  disputed_value: number;
  
  // Evidence
  photos: Photo[];
  documents: Attachment[];
  inspection_results: string[]; // IDs of failed inspections
  
  // Resolution
  status: 'open' | 'investigating' | 'supplier_contacted' | 'awaiting_response' | 
          'resolved' | 'closed' | 'escalated';
  priority: 'low' | 'medium' | 'high' | 'critical';
  
  requested_action: 'replacement' | 'credit_note' | 'refund' | 'discount' | 'repair';
  
  // Communication
  supplier_notified_date: Date;
  supplier_response_date: Date;
  supplier_response: string;
  
  // Resolution
  resolution_type: 'replacement_sent' | 'credit_issued' | 'refund_processed' | 
                   'goods_returned' | 'accepted_with_discount' | 'no_action';
  resolution_date: Date;
  resolution_notes: string;
  resolution_amount: number;
  
  // Assignment
  assigned_to_user_id: string;
  escalated_to_user_id: string;
  
  // Timeline
  created_by: string;
  created_at: Date;
  updated_at: Date;
  closed_at: Date;
  
  // Activity Log
  activities: DisputeActivity[];
}

interface DisputeActivity {
  id: string;
  dispute_ticket_id: string;
  activity_type: 'created' | 'updated' | 'supplier_contacted' | 'response_received' | 
                 'escalated' | 'resolved' | 'closed' | 'comment_added';
  user_id: string;
  description: string;
  created_at: Date;
}
```

### 3.2 Supplier Communication

```typescript
interface SupplierNotification {
  id: string;
  dispute_ticket_id: string;
  
  notification_type: 'email' | 'portal' | 'phone' | 'letter';
  
  subject: string;
  message: string;
  attachments: string[]; // URLs to photos/docs
  
  sent_to_email: string;
  sent_to_contact_person: string;
  sent_date: Date;
  
  response_required_by: Date;
  response_received: boolean;
  response_date: Date;
  response_text: string;
  
  template_used: string; // Email template ID
}
```

---

## 4. Photo Management System

### 4.1 Photo Storage & Categories

```typescript
interface PhotoMetadata {
  id: string;
  
  // Context
  photo_category: 'item_product' | 'item_inspection' | 'receiving_delivery' | 
                  'receiving_damage' | 'quality_inspection' | 'dispute_evidence' | 
                  'location' | 'packing' | 'other';
  
  // References (multiple possibili)
  item_id: string;
  grn_id: string;
  grn_line_id: string;
  inspection_id: string;
  dispute_ticket_id: string;
  stock_take_id: string;
  
  // File Info
  file_name: string;
  original_file_name: string;
  mime_type: string;
  file_size: number;
  
  // URLs (CDN o local storage)
  original_url: string;
  thumbnail_url: string; // 200x200
  medium_url: string; // 800x800
  large_url: string; // 1600x1600
  
  // Image Properties
  width: number;
  height: number;
  
  // Metadata
  caption: string;
  tags: string[];
  geo_location: { lat: number, lng: number };
  
  // Audit
  uploaded_by: string;
  uploaded_at: Date;
  camera_info: string; // EXIF data
  
  // Organization
  is_primary: boolean; // Primary photo for item
  sort_order: number;
  is_public: boolean; // Visibile su ecommerce/cataloghi
}
```

### 4.2 Photo Upload API

```typescript
// POST /api/inventory/photos/upload
interface PhotoUploadRequest {
  file: File; // Multipart form data
  category: string;
  item_id?: string;
  grn_id?: string;
  inspection_id?: string;
  dispute_ticket_id?: string;
  caption?: string;
  tags?: string[];
  is_primary?: boolean;
}

interface PhotoUploadResponse {
  success: boolean;
  photo: PhotoMetadata;
  urls: {
    original: string;
    thumbnail: string;
    medium: string;
    large: string;
  };
}
```

---

## 5. Database Schema Extensions

### 5.1 New Tables

```sql
-- Extended Item Details
CREATE TABLE inventory_item_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  
  -- Classification
  brand VARCHAR(100),
  manufacturer VARCHAR(255),
  manufacturer_part_number VARCHAR(100),
  ean_barcode VARCHAR(50),
  
  -- Storage type
  storage_type VARCHAR(50) DEFAULT 'shelf' CHECK (storage_type IN ('shelf', 'bulk', 'lot_managed', 'serial_tracked')),
  lot_tracking_enabled BOOLEAN DEFAULT false,
  serial_tracking_enabled BOOLEAN DEFAULT false,
  expiry_tracking_enabled BOOLEAN DEFAULT false,
  
  -- Physical properties
  dimensions JSONB, -- {length, width, height, unit}
  weight JSONB, -- {gross, net, unit}
  volume JSONB, -- {value, unit}
  
  -- Storage conditions
  storage_conditions JSONB,
  hazardous_material BOOLEAN DEFAULT false,
  un_number VARCHAR(50),
  
  -- Procurement
  preferred_supplier_id UUID,
  moq NUMERIC(15,2),
  order_multiple NUMERIC(15,2),
  
  -- Quality control
  inspection_required_on_receipt BOOLEAN DEFAULT false,
  quality_hold_on_receipt BOOLEAN DEFAULT false,
  shelf_life_days INTEGER,
  quarantine_location_id UUID,
  
  -- Lifecycle
  lifecycle_status VARCHAR(50) DEFAULT 'active',
  is_discontinued BOOLEAN DEFAULT false,
  replacement_item_id UUID,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Photos
CREATE TABLE inventory_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  
  photo_category VARCHAR(50) NOT NULL,
  
  item_id UUID REFERENCES inventory_items(id),
  grn_id UUID,
  grn_line_id UUID,
  inspection_id UUID,
  dispute_ticket_id UUID,
  stock_take_id UUID,
  
  file_name VARCHAR(255) NOT NULL,
  original_file_name VARCHAR(255),
  mime_type VARCHAR(50),
  file_size INTEGER,
  
  original_url TEXT NOT NULL,
  thumbnail_url TEXT,
  medium_url TEXT,
  large_url TEXT,
  
  width INTEGER,
  height INTEGER,
  
  caption TEXT,
  tags TEXT[],
  geo_location JSONB,
  
  uploaded_by UUID,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  camera_info TEXT,
  
  is_primary BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  is_public BOOLEAN DEFAULT false
);

CREATE INDEX idx_photos_item ON inventory_photos(item_id);
CREATE INDEX idx_photos_grn ON inventory_photos(grn_id);
CREATE INDEX idx_photos_dispute ON inventory_photos(dispute_ticket_id);
CREATE INDEX idx_photos_category ON inventory_photos(photo_category);

-- Attachments/Documents
CREATE TABLE inventory_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  
  item_id UUID REFERENCES inventory_items(id),
  grn_id UUID,
  dispute_ticket_id UUID,
  
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50),
  file_size INTEGER,
  file_url TEXT NOT NULL,
  
  document_type VARCHAR(50), -- 'datasheet', 'manual', 'certificate', 'drawing', 'sds', 'other'
  version VARCHAR(20),
  
  uploaded_by UUID,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_attachments_item ON inventory_attachments(item_id);

-- Technical Specifications
CREATE TABLE inventory_technical_specs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  
  spec_name VARCHAR(255) NOT NULL,
  spec_value TEXT,
  spec_unit VARCHAR(50),
  spec_category VARCHAR(100),
  
  is_critical BOOLEAN DEFAULT false,
  tolerance_min NUMERIC(15,4),
  tolerance_max NUMERIC(15,4),
  
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tech_specs_item ON inventory_technical_specs(item_id);

-- Certificates
CREATE TABLE inventory_certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  
  item_id UUID REFERENCES inventory_items(id),
  lot_number VARCHAR(100),
  
  certificate_type VARCHAR(50) NOT NULL,
  certificate_number VARCHAR(100),
  
  issue_date DATE,
  expiry_date DATE,
  issued_by VARCHAR(255),
  
  document_url TEXT,
  verification_status VARCHAR(50) DEFAULT 'pending',
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_certificates_item ON inventory_certificates(item_id);
CREATE INDEX idx_certificates_lot ON inventory_certificates(lot_number);

-- Goods Receipt Notes
CREATE TABLE inventory_grn (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  grn_number VARCHAR(50) NOT NULL UNIQUE,
  
  purchase_order_id UUID,
  supplier_id UUID,
  supplier_delivery_note VARCHAR(100),
  supplier_invoice_number VARCHAR(100),
  
  carrier VARCHAR(255),
  tracking_number VARCHAR(100),
  received_date TIMESTAMPTZ,
  received_by UUID,
  receiving_location_id UUID REFERENCES inventory_locations(id),
  
  status VARCHAR(50) DEFAULT 'draft',
  
  inspection_required BOOLEAN DEFAULT false,
  inspection_completed BOOLEAN DEFAULT false,
  inspection_result VARCHAR(50),
  inspector_user_id UUID,
  inspection_notes TEXT,
  
  total_packages INTEGER,
  total_weight NUMERIC(15,2),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_grn_tenant ON inventory_grn(tenant_id);
CREATE INDEX idx_grn_po ON inventory_grn(purchase_order_id);
CREATE INDEX idx_grn_supplier ON inventory_grn(supplier_id);

-- GRN Lines
CREATE TABLE inventory_grn_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grn_id UUID NOT NULL REFERENCES inventory_grn(id) ON DELETE CASCADE,
  line_number INTEGER NOT NULL,
  
  item_id UUID NOT NULL REFERENCES inventory_items(id),
  
  ordered_quantity NUMERIC(15,2),
  received_quantity NUMERIC(15,2),
  accepted_quantity NUMERIC(15,2),
  rejected_quantity NUMERIC(15,2),
  
  lot_number VARCHAR(100),
  serial_numbers TEXT[],
  manufacture_date DATE,
  expiry_date DATE,
  
  inspection_status VARCHAR(50) DEFAULT 'pending',
  inspection_notes TEXT,
  
  rejection_reason VARCHAR(50),
  rejection_notes TEXT,
  
  accepted_to_location_id UUID REFERENCES inventory_locations(id),
  rejected_to_location_id UUID REFERENCES inventory_locations(id),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(grn_id, line_number)
);

CREATE INDEX idx_grn_lines_grn ON inventory_grn_lines(grn_id);
CREATE INDEX idx_grn_lines_item ON inventory_grn_lines(item_id);

-- Inspection Checklists
CREATE TABLE inventory_inspection_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  item_id UUID REFERENCES inventory_items(id),
  
  checklist_name VARCHAR(255) NOT NULL,
  checklist_type VARCHAR(50) NOT NULL,
  
  is_mandatory BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_checklists_item ON inventory_inspection_checklists(item_id);

-- Inspection Checkpoints
CREATE TABLE inventory_inspection_checkpoints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_id UUID NOT NULL REFERENCES inventory_inspection_checklists(id) ON DELETE CASCADE,
  
  sequence INTEGER NOT NULL,
  checkpoint_name VARCHAR(255) NOT NULL,
  checkpoint_type VARCHAR(50) NOT NULL,
  
  expected_value TEXT,
  tolerance_min NUMERIC(15,4),
  tolerance_max NUMERIC(15,4),
  unit VARCHAR(50),
  
  pass_criteria TEXT,
  
  is_critical BOOLEAN DEFAULT false,
  photo_required BOOLEAN DEFAULT false,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_checkpoints_checklist ON inventory_inspection_checkpoints(checklist_id);

-- Inspection Results
CREATE TABLE inventory_inspection_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grn_line_id UUID REFERENCES inventory_grn_lines(id),
  checklist_id UUID NOT NULL REFERENCES inventory_inspection_checklists(id),
  
  inspector_id UUID,
  inspection_date TIMESTAMPTZ,
  
  overall_result VARCHAR(50),
  notes TEXT,
  
  signed_by UUID,
  signature_data TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inspection_results_grn ON inventory_inspection_results(grn_line_id);

-- Checkpoint Results
CREATE TABLE inventory_checkpoint_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_result_id UUID NOT NULL REFERENCES inventory_inspection_results(id) ON DELETE CASCADE,
  checkpoint_id UUID NOT NULL REFERENCES inventory_inspection_checkpoints(id),
  
  result VARCHAR(50), -- 'pass', 'fail', 'na'
  measured_value TEXT,
  notes TEXT,
  photo_ids UUID[],
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_checkpoint_results_inspection ON inventory_checkpoint_results(inspection_result_id);

-- Dispute Tickets
CREATE TABLE inventory_dispute_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  ticket_number VARCHAR(50) NOT NULL UNIQUE,
  
  dispute_type VARCHAR(50) NOT NULL,
  grn_id UUID REFERENCES inventory_grn(id),
  purchase_order_id UUID,
  supplier_id UUID,
  item_id UUID REFERENCES inventory_items(id),
  
  issue_category VARCHAR(50) NOT NULL,
  issue_description TEXT,
  
  disputed_quantity NUMERIC(15,2),
  disputed_value NUMERIC(15,2),
  
  status VARCHAR(50) DEFAULT 'open',
  priority VARCHAR(50) DEFAULT 'medium',
  
  requested_action VARCHAR(50),
  
  supplier_notified_date TIMESTAMPTZ,
  supplier_response_date TIMESTAMPTZ,
  supplier_response TEXT,
  
  resolution_type VARCHAR(50),
  resolution_date TIMESTAMPTZ,
  resolution_notes TEXT,
  resolution_amount NUMERIC(15,2),
  
  assigned_to_user_id UUID,
  escalated_to_user_id UUID,
  
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  closed_at TIMESTAMPTZ
);

CREATE INDEX idx_disputes_tenant ON inventory_dispute_tickets(tenant_id);
CREATE INDEX idx_disputes_grn ON inventory_dispute_tickets(grn_id);
CREATE INDEX idx_disputes_supplier ON inventory_dispute_tickets(supplier_id);
CREATE INDEX idx_disputes_status ON inventory_dispute_tickets(status);

-- Dispute Activities
CREATE TABLE inventory_dispute_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_ticket_id UUID NOT NULL REFERENCES inventory_dispute_tickets(id) ON DELETE CASCADE,
  
  activity_type VARCHAR(50) NOT NULL,
  user_id UUID,
  description TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_dispute_activities_ticket ON inventory_dispute_activities(dispute_ticket_id);

-- Supplier Notifications
CREATE TABLE inventory_supplier_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_ticket_id UUID NOT NULL REFERENCES inventory_dispute_tickets(id),
  
  notification_type VARCHAR(50) NOT NULL,
  
  subject TEXT,
  message TEXT,
  attachments TEXT[],
  
  sent_to_email VARCHAR(255),
  sent_to_contact_person VARCHAR(255),
  sent_date TIMESTAMPTZ,
  
  response_required_by DATE,
  response_received BOOLEAN DEFAULT false,
  response_date TIMESTAMPTZ,
  response_text TEXT,
  
  template_used VARCHAR(100),
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_supplier_notif_ticket ON inventory_supplier_notifications(dispute_ticket_id);
```

---

## 6. Frontend Implementation

### 6.1 New Pages

1. **Item Detail Page** (`/items/:id`)
   - Tab 1: General Info
   - Tab 2: Technical Specs
   - Tab 3: Photos & Documents
   - Tab 4: Stock Levels by Location
   - Tab 5: Movement History
   - Tab 6: Suppliers & Pricing
   - Tab 7: Quality/Inspection Checklists

2. **Goods Receiving** (`/receiving`)
   - List: All GRNs with status
   - Create: New GRN from PO
   - Detail: GRN with photo upload, inspection
   
3. **Quality Inspection** (`/quality/inspections`)
   - Pending inspections queue
   - Inspection form with checklist
   - Photo capture from webcam/mobile
   - Pass/Fail/Conditional results

4. **Disputes** (`/disputes`)
   - List: All disputes with filters
   - Create: New dispute from GRN
   - Detail: Timeline, communication, resolution
   - Supplier notification templates

### 6.2 Key Components

```tsx
// Photo Gallery Component
<PhotoGallery 
  photos={item.photos}
  onUpload={handlePhotoUpload}
  onDelete={handlePhotoDelete}
  onSetPrimary={handleSetPrimary}
  allowUpload={true}
/>

// Inspection Checklist Component
<InspectionForm
  checklist={checklist}
  grnLine={grnLine}
  onSubmit={handleInspectionSubmit}
  allowPhotoCapture={true}
/>

// Dispute Timeline Component
<DisputeTimeline
  activities={dispute.activities}
  onAddComment={handleAddComment}
  onEscalate={handleEscalate}
/>
```

---

## 7. API Endpoints (New)

### Item Details
- `GET /api/inventory/items/:id/details` - Get full item details
- `PUT /api/inventory/items/:id/details` - Update item details
- `GET /api/inventory/items/:id/specs` - Get technical specs
- `POST /api/inventory/items/:id/specs` - Add technical spec
- `GET /api/inventory/items/:id/certificates` - Get certificates

### Photos
- `POST /api/inventory/photos/upload` - Upload photo (multipart)
- `GET /api/inventory/photos/:id` - Get photo metadata
- `DELETE /api/inventory/photos/:id` - Delete photo
- `PUT /api/inventory/photos/:id/primary` - Set as primary

### GRN
- `GET /api/inventory/grn` - List GRNs
- `POST /api/inventory/grn` - Create GRN
- `GET /api/inventory/grn/:id` - Get GRN detail
- `PUT /api/inventory/grn/:id` - Update GRN
- `POST /api/inventory/grn/:id/lines` - Add GRN line
- `PUT /api/inventory/grn/:id/receive` - Complete receiving
- `PUT /api/inventory/grn/:id/inspect` - Start inspection

### Inspection
- `GET /api/inventory/inspections/pending` - Pending inspections
- `POST /api/inventory/inspections` - Submit inspection result
- `GET /api/inventory/inspections/:id` - Get inspection detail
- `GET /api/inventory/checklists` - List checklists
- `POST /api/inventory/checklists` - Create checklist

### Disputes
- `GET /api/inventory/disputes` - List disputes
- `POST /api/inventory/disputes` - Create dispute
- `GET /api/inventory/disputes/:id` - Get dispute detail
- `PUT /api/inventory/disputes/:id` - Update dispute
- `POST /api/inventory/disputes/:id/notify-supplier` - Send notification
- `POST /api/inventory/disputes/:id/resolve` - Resolve dispute
- `POST /api/inventory/disputes/:id/activities` - Add activity/comment

---

## 8. Implementation Priority

### Phase 1: Item Details Enhancement ✅ NEXT
1. Extend item schema with detailed fields
2. Add item detail page with tabs
3. Technical specs CRUD
4. Photo upload and gallery

### Phase 2: Goods Receiving
1. GRN schema and API
2. Receiving workflow UI
3. Photo capture during receiving
4. Basic acceptance/rejection

### Phase 3: Quality Inspection
1. Inspection checklist builder
2. Inspection execution form
3. Pass/fail logic
4. Quality hold implementation

### Phase 4: Dispute Management
1. Dispute ticket system
2. Supplier notification system
3. Resolution workflow
4. Reporting and analytics

---

## 9. Integration Points

- **Purchase Orders** (svc-orders-purchase) → Create GRN from PO
- **Suppliers** (svc-procurement/CRM) → Supplier info for disputes
- **File Storage** → S3/Minio for photos/documents
- **Email Service** → Supplier notifications
- **Workflow Engine** → Approval workflows for disputes
- **Reporting** → Quality metrics, supplier performance

