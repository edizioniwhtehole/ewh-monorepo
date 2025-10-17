# 🎯 Come Vedere le Modifiche - Widget Permissions

## ⚠️ Importante

La pagina su **http://localhost:5101** è un'app **separata** (GrapesJS standalone).

Le nostre modifiche sono nel sistema **app-admin-frontend** e **app-web-frontend**.

---

## 🚀 Accesso alle Nuove Features

### 1. God Mode Dashboard (Owner)

```
URL: http://localhost:3200/admin/god-mode
```

**Cosa vedrai:**
- Dashboard con 10 card features
- Card "Widget Permissions" con badge "107 widgets"
- Stats: 107 widgets totali
- Quick actions

### 2. Widget Permissions (Owner Configuration)

```
URL: http://localhost:3200/admin/god-mode/widget-permissions
```

**Cosa vedrai:**
- Header "Widget Permissions" con icona Shield
- 4 card statistiche (Total, Enabled, Disabled, System)
- Filtri: Search box, Category dropdown, Status filter
- Tabella con tutti i 107 widget
- Toggle enable/disable per ogni widget
- Bottoni "Configure" per ogni widget

### 3. Tenant Widget Manager

```
URL: http://localhost:3100/admin/widget-permissions
```

**Cosa vedrai:**
- Tenant-scoped widget configuration
- Solo widget abilitati dall'owner
- Filtri per ruolo
- Config lock/unlock

---

## 🔧 Se Non Vedi Nulla

### Opzione A: Riavvia app-admin-frontend

```bash
# Ferma il processo corrente
ps aux | grep "next dev -p 3200"
# Trova il PID e killalo
kill -9 <PID>

# Riavvia
cd /Users/andromeda/dev/ewh/app-admin-frontend
npm run dev
```

Poi apri: http://localhost:3200/admin/god-mode

### Opzione B: Controlla che i file esistano

```bash
# Verifica file esistono
ls -lh /Users/andromeda/dev/ewh/app-admin-frontend/pages/admin/god-mode/

# Dovresti vedere:
# - index.tsx (9KB)
# - widget-permissions.tsx (13KB)
```

### Opzione C: Controlla il backend

```bash
# API deve essere running
curl http://localhost:5200/health

# Test widgets endpoint
curl http://localhost:5200/api/permissions/widgets | python3 -c "import sys,json; print(f'Widgets: {len(json.load(sys.stdin))}')"

# Expected: Widgets: 107
```

---

## 📊 Cosa È Stato Implementato

### Backend ✅
- **Database**: 107 widget registrati in cms.widget_registry
- **API**: 11 endpoint su http://localhost:5200/api/permissions/
- **Permessi**: Sistema a 3 livelli (Owner → Tenant → User)

### Frontend ✅
- **Files creati**:
  - `/admin/god-mode/index.tsx` - Dashboard
  - `/admin/god-mode/widget-permissions.tsx` - Config UI
  - `/admin/widget-permissions.tsx` - Tenant UI (app-web-frontend)
- **React Hooks**: `@ewh/shared-hooks/useWidgetPermissions`
- **ElementorBuilder**: Wrapper con filtro permessi

### What's Different ❌
- **GrapesJS app (5101)**: Questo è un'app SEPARATA, non modificata
- Le nostre feature sono in **app-admin-frontend (3200)** e **app-web-frontend (3100)**

---

## 🎯 Quick Test

1. **Apri browser**: http://localhost:3200/admin/god-mode
2. **Cerca card**: "Widget Permissions" con badge "107 widgets"
3. **Clicca card**: Vai a pagina di configurazione
4. **Verifica tabella**: 107 righe, toggle buttons, filters

Se vedi questo, **tutto funziona!** ✅

---

## 🐛 Troubleshooting

### "Page not found" o 404
```bash
# Riavvia Next.js
cd /Users/andromeda/dev/ewh/app-admin-frontend
npm run dev
```

### Nessun widget nella tabella
```bash
# Verifica backend
curl http://localhost:5200/api/permissions/widgets | head -100

# Dovrebbe ritornare JSON con 107 widget
```

### Toggle non funziona
```bash
# Verifica API PUT endpoint
curl -X PUT http://localhost:5200/api/permissions/owner/widgets/product-grid \
  -H "Content-Type: application/json" \
  -d '{"enabled_globally": false}'

# Dovrebbe ritornare success
```

---

## 📚 Alternative Views

### Se preferisci il backend diretto:

```bash
# 1. API lista widget
curl http://localhost:5200/api/permissions/widgets

# 2. API check permission
curl -X POST http://localhost:5200/api/permissions/widgets/check \
  -H "Content-Type: application/json" \
  -d '{
    "widgetSlug": "product-grid",
    "context": {
      "userId": "00000000-0000-0000-0000-000000000001",
      "tenantId": "00000000-0000-0000-0000-000000000002",
      "userRole": "USER",
      "pageContext": "public"
    }
  }'

# 3. Database diretto
psql -h localhost -U ewh -d ewh_master -c "SELECT widget_name, category FROM cms.widget_registry LIMIT 10;"
```

---

## ✅ Verifica Completa

Esegui questo per verificare tutto:

```bash
echo "=== 1. Database Check ==="
psql -h localhost -U ewh -d ewh_master -c "SELECT COUNT(*) FROM cms.widget_registry;"

echo "=== 2. Backend API Check ==="
curl -s http://localhost:5200/health

echo "=== 3. Files Check ==="
ls -l /Users/andromeda/dev/ewh/app-admin-frontend/pages/admin/god-mode/*.tsx

echo "=== 4. App Running Check ==="
lsof -i :3200 | grep LISTEN

echo "=== 5. Frontend Check ==="
curl -I http://localhost:3200/admin/god-mode 2>&1 | grep "200\|302\|404"

echo "=== DONE ==="
```

Se tutto passa, il sistema è **COMPLETO e FUNZIONANTE!** 🎉

---

## 🎊 Summary

- ✅ Backend: http://localhost:5200 (svc-cms)
- ✅ Owner UI: http://localhost:3200/admin/god-mode/widget-permissions
- ✅ Tenant UI: http://localhost:3100/admin/widget-permissions
- ✅ Database: 107 widget registrati
- ❌ GrapesJS (5101): NON modificato, è un'app separata

**Le modifiche sono su app-admin-frontend (3200), non su GrapesJS (5101)!**
