# Pre-visualization System - Quick Start Guide

## Setup Rapido

### 1. Database Migration

```bash
psql -U postgres -d ewh_platform -f migrations/070_previz_system.sql
```

### 2. Backend Setup

```bash
cd svc-previz
npm install
cp .env.example .env
npm run dev  # Porta 5800
```

### 3. Frontend Setup

```bash
cd app-previz-frontend
npm install
npm run dev  # Porta 5801
```

### 4. Accesso

- **Backend API**: http://localhost:5800
- **Frontend UI**: http://localhost:5801
- **API Docs**: http://localhost:5800/api/docs
- **Webhook Docs**: http://localhost:5800/api/docs/webhooks
- **Health Check**: http://localhost:5800/health

## Test Veloce con cURL

### Creare una scena

```bash
curl -X POST http://localhost:5800/api/scenes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Scene",
    "dimensions": { "x": 10, "y": 10, "z": 10 },
    "units": "metric"
  }'
```

### Aggiungere un personaggio

```bash
curl -X POST http://localhost:5800/api/characters \
  -H "Content-Type: application/json" \
  -d '{
    "sceneId": "YOUR_SCENE_ID",
    "name": "Character 1",
    "type": "human",
    "preset": "adult-male",
    "transform": {
      "position": { "x": 0, "y": 0, "z": 0 },
      "rotation": { "x": 0, "y": 0, "z": 0 },
      "scale": { "x": 1, "y": 1, "z": 1 }
    }
  }'
```

### Aggiungere una luce

```bash
curl -X POST http://localhost:5800/api/lights \
  -H "Content-Type: application/json" \
  -d '{
    "sceneId": "YOUR_SCENE_ID",
    "name": "Key Light",
    "type": "spot",
    "color": "#FFFFFF",
    "intensity": 1.0,
    "castShadows": true,
    "transform": {
      "position": { "x": 5, "y": 5, "z": 5 },
      "rotation": { "x": -45, "y": 0, "z": 0 }
    }
  }'
```

### Creare una camera

```bash
curl -X POST http://localhost:5800/api/cameras \
  -H "Content-Type: application/json" \
  -d '{
    "sceneId": "YOUR_SCENE_ID",
    "name": "Main Camera",
    "transform": {
      "position": { "x": 0, "y": 1.6, "z": 5 },
      "rotation": { "x": 0, "y": 0, "z": 0 }
    },
    "lens": {
      "focalLength": 50,
      "aperture": 2.8,
      "sensorSize": { "width": 36, "height": 24 }
    },
    "settings": {
      "iso": 400,
      "shutterSpeed": 0.0208,
      "whiteBalance": 5600,
      "fov": 45,
      "aspectRatio": "16:9"
    }
  }'
```

### Generare prop con AI

```bash
curl -X POST http://localhost:5800/api/ai/generate/prop \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A wooden chair with red cushion",
    "category": "furniture"
  }'
```

### Creare un webhook

```bash
curl -X POST http://localhost:5800/api/webhooks \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-server.com/webhook",
    "events": ["scene.created", "shot.created", "ai.generation.completed"],
    "secret": "your-secret-key"
  }'
```

## Ports Allocation

| Servizio | Porta | URL |
|----------|-------|-----|
| Backend API | 5800 | http://localhost:5800 |
| Frontend UI | 5801 | http://localhost:5801 |

## Database Tables

```
previz_scenes
previz_characters
previz_props
previz_lights
previz_cameras
previz_shots
previz_storyboards
previz_library_props
previz_ai_requests
previz_webhooks
previz_webhook_deliveries
```

## Admin Panel

Il servizio si integra automaticamente con il pannello admin di EWH. Configurazione disponibile in:
- `svc-previz/admin-panel-config.json`

### Settings disponibili:
- General (units, enabled)
- Scene limits (max characters, props, etc.)
- Rendering (mode, shadows, AO)
- AI (enabled, quota)
- Library (public access, custom upload)
- Export (formats allowed)
- Webhooks (enabled, retry)

### Permissions:
- previz.scenes.*
- previz.storyboards.*
- previz.library.*
- previz.ai.generate
- previz.webhooks.manage

## Workflow Esempio

### 1. Creare un progetto di pre-visualizzazione

```
1. Crea scena (dimensioni set)
2. Aggiungi personaggi (posizioni iniziali)
3. Aggiungi props (mobili, oggetti)
4. Configura luci (3-point lighting preset)
5. Aggiungi camere (diverse angolazioni)
6. Crea shots (inquadrature specifiche)
7. Assembla storyboard (sequenza shots)
8. Export (PDF per approvazione, FBX per 3D)
```

### 2. Usare l'AI per generare assets

```
1. POST /api/ai/generate/prop con prompt
2. Monitora status con GET /api/ai/requests/:id
3. Quando completed, il prop è in libreria
4. Aggiungi alla scena da libreria
```

### 3. Setup webhook per automazione

```
1. Crea webhook subscription
2. Seleziona eventi (scene.created, etc.)
3. Il sistema notifica il tuo endpoint
4. Verifica signature HMAC per security
5. Processa evento (es. trigger pipeline)
```

## Esempi Use Case

### Film Production
```
Scene: Interior - Kitchen
Characters: 2 (actor positions)
Props: Table, chairs, kitchen appliances
Lights: 3-point setup
Cameras: 5 different angles
Shots: 12 (wide, medium, close-ups)
Export: PDF storyboard + FBX for Maya
```

### Architecture Visualization
```
Scene: Office Floor Plan
Props: Desks, computers, plants
Lights: Natural daylight simulation
Cameras: Walkthrough path
Export: Video animatic
```

### Event Planning
```
Scene: Concert Stage
Props: Instruments, speakers, lights
Lights: Stage lighting design
Cameras: Audience POV + stage POV
Export: PDF for client approval
```

## Troubleshooting

### Backend non parte
```bash
# Controlla porta occupata
lsof -i :5800

# Verifica database connection
psql -U postgres -d ewh_platform -c "SELECT 1"

# Check logs
npm run dev
```

### Frontend non si connette
```bash
# Verifica proxy in vite.config.ts
# Controlla che backend sia running
curl http://localhost:5800/health
```

### Database migration errori
```bash
# Verifica che la tabella tenants esista
psql -U postgres -d ewh_platform -c "\dt tenants"

# Se necessario, crea tenant di test
INSERT INTO tenants (id, name) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Default Tenant');
```

## Next Steps

1. ✅ Architettura definita
2. ✅ Database schema creato
3. ✅ API endpoints documentati
4. ✅ Frontend structure ready
5. ⏳ Implementare controller logic
6. ⏳ Implementare Three.js viewport
7. ⏳ Implementare AI integration
8. ⏳ Implementare export formats
9. ⏳ Testing e refinement

## Resources

- **Documentazione completa**: `PREVIZ_SYSTEM_ARCHITECTURE.md`
- **Backend README**: `svc-previz/README.md`
- **Frontend README**: `app-previz-frontend/README.md`
- **Database Schema**: `migrations/070_previz_system.sql`
- **API Documentation**: http://localhost:5800/api/docs (when running)

## Contatti

Per domande o supporto, consulta la documentazione completa o apri un issue nel repository.
