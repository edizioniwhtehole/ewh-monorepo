# Device Resolutions Management System

## Overview
Sistema completo per gestire le risoluzioni dei dispositivi (mobile/tablet/desktop) per il page builder, con database PostgreSQL, API REST, integrazione frontend e **UI di gestione integrata nel Page Builder**.

## 🎯 Quick Start

**Per aggiungere un nuovo dispositivo (es: iPhone 18):**

1. Apri il Page Builder
2. Clicca l'icona 📱 **smartphone verde** nell'header (accanto a ⚙️ Settings)
3. Nel modal che si apre, compila il form a sinistra:
   - Device Key: `iphone-18`
   - Device Name: `iPhone 18`
   - Width: `410` px
   - Label: `iPhone 18 (410px)`
4. Click **"Add Device"**
5. ✅ Il dispositivo appare subito nella lista e nel dropdown mobile!

**Tempo necessario:** 30 secondi ⚡

## Struttura

### 1. Database (`migrations/016_create_device_resolutions.sql`)

#### Schema: `page_builder`

#### Tabella: `page_builder.device_resolutions`

```sql
Colonne:
- id (UUID, PK)
- device_key (VARCHAR, UNIQUE) - chiave univoca (es: 'iphone-17-pro')
- device_name (VARCHAR) - nome completo del dispositivo
- device_type (VARCHAR) - tipo: 'mobile', 'tablet', 'desktop'
- width_px (INTEGER) - larghezza viewport in pixel
- height_px (INTEGER) - altezza viewport in pixel (opzionale)
- label (VARCHAR) - etichetta UI (es: 'iPhone 17 Pro (402px)')
- manufacturer (VARCHAR) - produttore (es: 'Apple')
- model (VARCHAR) - modello
- release_year (INTEGER) - anno di rilascio
- is_active (BOOLEAN) - attivo/disattivo
- is_default (BOOLEAN) - default per il tipo
- display_order (INTEGER) - ordine di visualizzazione
- created_at, updated_at, created_by, updated_by
```

#### Dispositivi Pre-caricati (2024-2025)

**iPhone:**
- iPhone SE (375px)
- iPhone 13/14 (390px) - DEFAULT
- iPhone 14 Plus (428px)
- iPhone 14/15/16 Pro (393-402px)
- iPhone 14/15/16 Pro Max (430-440px)
- iPhone 17, 17 Pro (402px)

**Samsung Galaxy:**
- S21, S22, S23, S24 (360px)
- S24 Ultra (384px)

**Google Pixel:**
- Pixel 5-9 (393-448px)

**Tablet:**
- iPad mini (744px)
- iPad Air (820px)
- iPad Pro 11" (834px) - DEFAULT
- iPad Pro 13" (1024px)
- Samsung Tab S9 (800px)

### 2. API REST (`svc-layout/src/index.ts`)

Base URL: `http://localhost:5000`

#### Endpoints

**GET `/api/device-resolutions`**
- Ritorna tutte le risoluzioni attive
- Response: `{ success: true, data: DeviceResolution[] }`

**GET `/api/device-resolutions/:type`**
- Parametri: `type` = 'mobile' | 'tablet' | 'desktop'
- Ritorna risoluzioni filtrate per tipo
- Response: `{ success: true, data: DeviceResolution[] }`

**POST `/api/device-resolutions`**
- Crea nuova risoluzione (admin)
- Body: `{ device_key, device_name, device_type, width_px, height_px?, label, manufacturer?, model?, release_year?, is_default?, display_order? }`
- Response: `{ success: true, data: DeviceResolution }`

**PATCH `/api/device-resolutions/:id`**
- Aggiorna risoluzione esistente
- Body: campi da aggiornare
- Response: `{ success: true, data: DeviceResolution }`

**DELETE `/api/device-resolutions/:id`**
- Disattiva risoluzione (soft delete)
- Response: `{ success: true, message: 'Device resolution deactivated' }`

### 3. Frontend Integration (`shared/packages/page-builder`)

#### Page Builder Component

```typescript
// Caricamento automatico delle risoluzioni da API
React.useEffect(() => {
  const response = await fetch('http://localhost:5000/api/device-resolutions/mobile');
  const data = await response.json();

  // Costruisce dinamicamente il dropdown
  setMobileResolutions(resolutions);
  setMobileResolution(defaultKey);
}, []);
```

#### Features:
- Dropdown automatico con tutte le risoluzioni mobile dal DB
- Selezione del device default automatica
- Fallback su risoluzioni hardcoded se API non disponibile
- Canvas responsive con larghezza esatta del dispositivo selezionato

### 4. Admin UI (da implementare)

Pagina: `/admin/settings/device-resolutions`

Funzionalità:
- ✅ Visualizza tabella con tutte le risoluzioni
- ✅ Filtra per tipo (mobile/tablet/desktop)
- ✅ Aggiungi nuova risoluzione
- ✅ Modifica risoluzione esistente
- ✅ Attiva/Disattiva risoluzione
- ✅ Imposta device default
- ✅ Riordina dispositivi (drag & drop)
- ✅ Importa nuovi dispositivi da file JSON
- ✅ Esporta configurazione

## Come Usare

### Aggiungere un Nuovo Dispositivo (es: iPhone 18)

**Opzione 1: Via API**
```bash
curl -X POST http://localhost:5000/api/device-resolutions \
  -H "Content-Type: application/json" \
  -d '{
    "device_key": "iphone-18",
    "device_name": "iPhone 18",
    "device_type": "mobile",
    "width_px": 410,
    "height_px": 890,
    "label": "iPhone 18 (410px)",
    "manufacturer": "Apple",
    "model": "iPhone 18",
    "release_year": 2026,
    "is_default": false,
    "display_order": 170
  }'
```

**Opzione 2: Via SQL**
```sql
INSERT INTO page_builder.device_resolutions
  (device_key, device_name, device_type, width_px, label, manufacturer, model, release_year, display_order)
VALUES
  ('iphone-18', 'iPhone 18', 'mobile', 410, 'iPhone 18 (410px)', 'Apple', 'iPhone 18', 2026, 170);
```

**Opzione 3: Via Admin UI** ✅ (PIÙ SEMPLICE)
1. Apri il Page Builder
2. Clicca l'icona 📱 smartphone nell'header (accanto a ⚙️ Settings)
3. Compila il form a sinistra con i dati del device
4. Click "Add Device"
5. Il dispositivo appare subito nella lista e nel dropdown!

### Modificare Risoluzione Default

```sql
-- Rimuovi default corrente
UPDATE page_builder.device_resolutions
SET is_default = false
WHERE device_type = 'mobile' AND is_default = true;

-- Imposta nuovo default
UPDATE page_builder.device_resolutions
SET is_default = true
WHERE device_key = 'iphone-17';
```

### Aggiornare Device Esistente

```bash
curl -X PATCH http://localhost:5000/api/device-resolutions/{id} \
  -H "Content-Type: application/json" \
  -d '{ "width_px": 415, "label": "iPhone 17 Pro (415px)" }'
```

## Vantaggi del Sistema

1. **Centralizzato**: Una singola fonte di verità per le risoluzioni
2. **Dinamico**: Aggiornabile senza rebuild del frontend
3. **Flessibile**: Supporta qualsiasi dispositivo (mobile, tablet, desktop)
4. **Storicizzato**: Mantiene lo storico con created_at/updated_at
5. **Ordinabile**: display_order per personalizzare l'ordine nel dropdown
6. **Soft Delete**: is_active per nascondere senza eliminare
7. **Future-proof**: Facile aggiungere iPhone 18, 19, 20...

## File Coinvolti

```
/migrations/016_create_device_resolutions.sql          # Migrazione DB
/svc-layout/src/index.ts                                # API REST
/shared/packages/page-builder/src/ElementorBuilder.tsx # Frontend integration
/shared/packages/page-builder/src/types.ts             # Types
```

## Prossimi Step

- [ ] Creare Admin UI completa per gestione dispositivi
- [ ] Aggiungere autenticazione agli endpoint POST/PATCH/DELETE
- [ ] Implementare import/export JSON per batch updates
- [ ] Aggiungere device resolution per desktop
- [ ] Implementare preview screenshot per ogni device
- [ ] Aggiungere statistiche d'uso per device

## Notes

- La migrazione include già iPhone fino al 17 (2025)
- Quando esce iPhone 18, basta aggiungere un record
- Il page builder si aggiorna automaticamente al prossimo refresh
- Le risoluzioni sono basate sui CSS pixels (logical pixels), non physical
