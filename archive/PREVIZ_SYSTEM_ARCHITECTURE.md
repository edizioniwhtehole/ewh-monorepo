# Pre-visualization System Architecture

## Overview

Il **Pre-visualization System (Previz)** è un'applicazione completa per la pianificazione di scene 3D, storyboarding e pre-visualizzazione cinematografica. Permette di creare set virtuali, posizionare personaggi e oggetti, configurare luci, simulare riprese con camera virtuali, e generare storyboard professionali.

## Architettura

### Servizi

#### Backend: `svc-previz`
- **Porta**: 5800
- **Stack**: Node.js + Express + TypeScript
- **Database**: PostgreSQL
- **Funzioni**:
  - Gestione scene 3D
  - Gestione personaggi, props, luci, camere
  - Sistema di shots e storyboard
  - Libreria props (tenant e pubblica)
  - Integrazione AI per generazione assets
  - Sistema webhook per eventi
  - Export scene (JSON, FBX, USD, Alembic, glTF)

#### Frontend: `app-previz-frontend`
- **Porta**: 5801
- **Stack**: React + Vite + TypeScript + Three.js
- **Librerie**:
  - `@react-three/fiber` - React renderer per Three.js
  - `@react-three/drei` - Helpers e componenti 3D
  - `leva` - UI controls per parametri 3D
  - `zustand` - State management
  - `@tanstack/react-query` - Data fetching

### Database Schema

#### Tabelle Principali

1. **previz_scenes** - Scene 3D
   - Dimensioni scene e unità di misura
   - Metadata personalizzabili
   - Soft delete

2. **previz_characters** - Personaggi
   - Transform (position, rotation, scale)
   - Rig configuration (sistema scheletrico)
   - Appearance (colore, texture, materiale)
   - Preset (adult-male, adult-female, child, etc.)

3. **previz_props** - Oggetti di scena
   - Geometria (box, sphere, cylinder, mesh custom)
   - Collegamento a DAM per asset esterni
   - Supporto AI generation
   - Categorizzazione

4. **previz_lights** - Luci
   - Tipi: point, spot, directional, area, ambient
   - Parametri: colore, intensità, range, angolo
   - Cast shadows

5. **previz_cameras** - Camere virtuali
   - Lens properties (focal length, aperture, sensor size)
   - Camera settings (ISO, shutter speed, white balance, FOV)
   - Aspect ratio configurabile

6. **previz_shots** - Inquadrature
   - Shot types (wide, medium, close-up, etc.)
   - Camera movement (pan, tilt, dolly, etc.)
   - Keyframe animation
   - Thumbnail preview

7. **previz_storyboards** - Storyboard
   - Collezione di shots ordinati
   - Collegamento a progetti
   - Export PDF e video

8. **previz_library_props** - Libreria props
   - Props riutilizzabili
   - Libreria tenant-specific e pubblica
   - Tag e categorizzazione
   - Integrazione DAM

9. **previz_ai_requests** - Richieste AI
   - Generazione props, characters, scene
   - Status tracking
   - Quota management

10. **previz_webhooks** - Webhook subscriptions
    - Eventi: scene.created, shot.created, ai.generation.completed, etc.
    - HMAC-SHA256 signature
    - Retry logic con exponential backoff

## API Endpoints

### Scenes
```
GET    /api/scenes              - Get all scenes
GET    /api/scenes/:id          - Get scene by ID
POST   /api/scenes              - Create scene
PUT    /api/scenes/:id          - Update scene
DELETE /api/scenes/:id          - Delete scene
GET    /api/scenes/:id/export   - Export scene (json, fbx, usd, alembic)
POST   /api/scenes/:id/duplicate - Duplicate scene
```

### Characters
```
GET    /api/characters          - Get characters in scene
GET    /api/characters/:id      - Get character by ID
POST   /api/characters          - Create character
PUT    /api/characters/:id      - Update character
PUT    /api/characters/:id/transform - Update transform
PUT    /api/characters/:id/pose      - Update pose (joints)
DELETE /api/characters/:id      - Delete character
GET    /api/characters/presets/list  - Get character presets
```

### Props
```
GET    /api/props               - Get props in scene
GET    /api/props/:id           - Get prop by ID
POST   /api/props               - Create prop
PUT    /api/props/:id           - Update prop
PUT    /api/props/:id/transform - Update transform
DELETE /api/props/:id           - Delete prop
POST   /api/props/:id/duplicate - Duplicate prop
```

### Lights
```
GET    /api/lights              - Get lights in scene
GET    /api/lights/:id          - Get light by ID
POST   /api/lights              - Create light
PUT    /api/lights/:id          - Update light
DELETE /api/lights/:id          - Delete light
GET    /api/lights/presets/list      - Get lighting presets
POST   /api/lights/presets/:preset   - Apply preset (3-point, outdoor, studio)
```

### Cameras
```
GET    /api/cameras             - Get cameras in scene
GET    /api/cameras/:id         - Get camera by ID
POST   /api/cameras             - Create camera
PUT    /api/cameras/:id         - Update camera
PUT    /api/cameras/:id/transform - Update transform
DELETE /api/cameras/:id         - Delete camera
GET    /api/cameras/lenses/list - Get lens presets (24mm, 35mm, 50mm, 85mm)
POST   /api/cameras/:id/look-at - Point camera at target
```

### Shots
```
GET    /api/shots               - Get shots
GET    /api/shots/:id           - Get shot by ID
POST   /api/shots               - Create shot
PUT    /api/shots/:id           - Update shot
PUT    /api/shots/:id/order     - Reorder shot
DELETE /api/shots/:id           - Delete shot
POST   /api/shots/:id/render    - Render shot preview
GET    /api/shots/:id/thumbnail - Get thumbnail
```

### Storyboards
```
GET    /api/storyboards         - Get storyboards
GET    /api/storyboards/:id     - Get storyboard by ID
POST   /api/storyboards         - Create storyboard
PUT    /api/storyboards/:id     - Update storyboard
DELETE /api/storyboards/:id     - Delete storyboard
POST   /api/storyboards/:id/scenes       - Add scene
DELETE /api/storyboards/:id/scenes/:sid  - Remove scene
POST   /api/storyboards/:id/shots        - Add shot
DELETE /api/storyboards/:id/shots/:sid   - Remove shot
GET    /api/storyboards/:id/export       - Export (pdf, video, images)
```

### Library
```
GET    /api/library/props       - Get prop library
GET    /api/library/props/:id   - Get library prop
POST   /api/library/props       - Add to library
PUT    /api/library/props/:id   - Update library prop
DELETE /api/library/props/:id   - Delete from library
GET    /api/library/categories  - Get categories
POST   /api/library/import      - Import from URL
```

### AI Generation
```
POST   /api/ai/generate/prop       - Generate prop with AI
POST   /api/ai/generate/character  - Generate character with AI
POST   /api/ai/generate/scene      - Generate scene with AI
GET    /api/ai/requests/:id        - Get request status
GET    /api/ai/requests            - Get all requests
POST   /api/ai/enhance/prop        - Enhance existing prop
```

### Webhooks
```
GET    /api/webhooks            - Get all webhooks
GET    /api/webhooks/:id        - Get webhook by ID
POST   /api/webhooks            - Create webhook
PUT    /api/webhooks/:id        - Update webhook
DELETE /api/webhooks/:id        - Delete webhook
POST   /api/webhooks/:id/test   - Test webhook
GET    /api/webhooks/:id/deliveries - Get delivery history
```

### Documentation
```
GET    /api/docs                - OpenAPI/Swagger spec
GET    /api/docs/webhooks       - Webhook documentation
```

## Webhook Events

### Eventi Disponibili

1. **scene.created** - Nuova scena creata
2. **scene.updated** - Scena aggiornata
3. **shot.created** - Nuovo shot creato
4. **shot.updated** - Shot aggiornato
5. **ai.generation.completed** - Generazione AI completata
6. **ai.generation.failed** - Generazione AI fallita
7. **render.completed** - Rendering completato

### Formato Payload

```json
{
  "event": "scene.created",
  "data": {
    "id": "scene-uuid",
    "tenantId": "tenant-uuid",
    "name": "Scene Name",
    "createdBy": "user-uuid",
    "createdAt": "2025-01-15T10:00:00Z"
  },
  "timestamp": "2025-01-15T10:00:00Z"
}
```

### Security

- Signature: HMAC-SHA256
- Header: `X-EWH-Signature`
- Format: `sha256={hash}`

### Retry Strategy

- Tentativi: 3
- Delay: 5s, 15s, 60s (exponential backoff)

## Features Principali

### 1. Scene Builder
- Creazione set 3D con dimensioni reali
- Unità metriche o imperiali
- Grid system e snap-to-grid
- Multi-level scene hierarchy

### 2. Character System
- Personaggi modulari articolati
- Preset anatomici (adulto, bambino, etc.)
- Sistema di rig con joints configurabili
- Pose library
- Appearance customization

### 3. Props System
- Libreria props tenant e pubblica
- Geometrie primitive (box, sphere, cylinder)
- Import mesh esterni (FBX, OBJ, glTF)
- AI generation on-demand
- Categorizzazione e tagging

### 4. Lighting System
- 5 tipi di luci (point, spot, directional, area, ambient)
- Preset illuminazione (3-point, outdoor, studio, cinema)
- Shadow casting
- Color temperature
- Intensity control

### 5. Camera System
- Simulazione ottiche reali
- Lens presets (24mm, 35mm, 50mm, 85mm, ecc.)
- Camera settings (ISO, shutter, WB)
- Aspect ratio multipli (16:9, 2.39:1, 4:3, etc.)
- Look-at targeting

### 6. Shot Planning
- Shot types (wide, medium, close-up, etc.)
- Camera movement (pan, tilt, dolly, track, crane)
- Keyframe animation
- Duration management
- Thumbnail generation

### 7. Storyboard
- Sequencing shots
- Drag-and-drop reordering
- Export PDF con thumbnails
- Export video animatics
- Print-ready layouts

### 8. AI Integration
- Generazione props da prompt testuale
- Generazione personaggi
- Generazione layout scene
- Monthly quota per tenant
- Queue management

### 9. Rendering
- **Wireframe mode** - Visualizzazione strutturale
- **Shaded mode** - Flat shading veloce
- **Textured mode** - Con texture applicate
- **Realistic mode** - PBR rendering con AO
- Shadow rendering
- Ambient occlusion
- Antialiasing

### 10. Export
- **JSON** - Scene completa
- **FBX** - Autodesk format (Maya, 3ds Max, Blender)
- **USD** - Universal Scene Description (Pixar)
- **Alembic** - VFX pipeline standard
- **glTF** - Web 3D standard

## Admin Panel Settings

### Configurazione disponibile (waterfall: global → tenant → user)

#### General
- Enable/disable sistema
- Default units (metric/imperial)

#### Scene Settings
- Max scenes per project
- Max characters per scene
- Max props per scene

#### Rendering
- Default render mode
- Enable shadows
- Enable ambient occlusion

#### AI Generation
- Enable AI generation
- Monthly quota per tenant

#### Library
- Enable public library
- Allow custom props upload

#### Export
- Allowed export formats

#### Webhooks
- Enable webhooks
- Retry attempts

## Permissions

```
previz.scenes.view
previz.scenes.create
previz.scenes.edit
previz.scenes.delete
previz.scenes.export
previz.storyboards.view
previz.storyboards.create
previz.storyboards.edit
previz.storyboards.delete
previz.library.view
previz.library.upload
previz.ai.generate
previz.webhooks.manage
```

## Integrazioni

### DAM Service
- Storage assets (mesh, texture, materiali)
- Versioning
- CDN delivery

### AI Service
- Text-to-3D generation
- Prop enhancement
- Scene layout suggestions

### Project Management
- Collegamento storyboard a progetti
- Task integration
- Timeline sync

## Use Cases

### 1. Film & TV Production
- Pre-visualization set complessi
- Planning camera movements
- Lighting design
- Storyboarding episodi

### 2. Architecture
- Client presentations
- Walkthrough planning
- Lighting studies

### 3. Events
- Stage design
- Camera positions planning
- Lighting plots

### 4. Education
- Film school projects
- Cinematography training
- 3D animation courses

### 5. Marketing & Advertising
- Commercial storyboarding
- Product shot planning
- Set design

## Competitive Analysis

### Competitor Comparison

| Feature | EWH Previz | Shot Designer | FrameForge | Previs Pro |
|---------|-----------|---------------|------------|------------|
| Pricing | SaaS/Free tier | $29.99 | $399+ | $995+ |
| Web-based | ✅ | ❌ (iOS) | ❌ (Desktop) | ❌ (Desktop) |
| AI Generation | ✅ | ❌ | ❌ | ❌ |
| Multi-tenant | ✅ | ❌ | ❌ | ❌ |
| API First | ✅ | ❌ | ❌ | ❌ |
| Real-time Collab | ✅ | ❌ | ❌ | Limited |
| Export Formats | 5+ | Limited | FBX | Multiple |
| Webhooks | ✅ | ❌ | ❌ | ❌ |

### Unique Selling Points

1. **AI-Powered** - Generazione automatica props/characters
2. **Web-based** - Nessuna installazione, cross-platform
3. **API-First** - Integrazione in pipeline esistenti
4. **Multi-tenant** - SaaS con isolamento tenant
5. **Free Tier** - Accessibile a studenti e indie filmmakers
6. **Real-time Collaboration** - Team simultanei su scene
7. **Webhook Automation** - Integrazione workflow esterni

## Tech Stack Summary

### Backend
- Node.js + Express
- TypeScript
- PostgreSQL (scene data)
- JWT Authentication
- Webhook system con retry

### Frontend
- React 18
- Vite
- TypeScript
- Three.js (3D rendering)
- React Three Fiber
- Zustand (state)
- TanStack Query (data fetching)
- Tailwind CSS

### 3D Pipeline
- Three.js engine
- FBX/OBJ/glTF loaders
- USD export support
- PBR materials
- Real-time shadows
- Post-processing effects

## Deployment

### Development
```bash
# Backend
cd svc-previz
npm install
npm run dev  # Port 5800

# Frontend
cd app-previz-frontend
npm install
npm run dev  # Port 5801
```

### Production
```bash
# Build
npm run build

# Run
npm start

# Environment variables
PORT=5800
DB_HOST=localhost
DB_NAME=ewh_previz
AI_SERVICE_URL=http://localhost:5600
DAM_SERVICE_URL=http://localhost:5100
```

### Database Migration
```bash
psql -U postgres -d ewh_platform -f migrations/070_previz_system.sql
```

## Roadmap

### Phase 1 (MVP) ✅
- Scene creation
- Characters & props
- Lights & cameras
- Basic shots
- Wireframe/shaded rendering

### Phase 2 (Current)
- Storyboards
- AI generation
- Library system
- Webhooks
- Export formats

### Phase 3 (Future)
- Real-time collaboration
- Animation timeline
- VR preview
- Motion capture import
- Cloud rendering farm

### Phase 4 (Advanced)
- Physics simulation
- Particle systems
- Advanced materials
- AI camera suggestions
- Auto-storyboard from script

## Conclusion

Il sistema Pre-visualization di EWH è una soluzione completa, moderna e API-first per la pianificazione di scene 3D e storyboarding. Con l'integrazione AI e l'architettura multi-tenant, si posiziona come alternativa competitiva ai tool desktop tradizionali, offrendo flessibilità, collaborazione e automazione superiori.
