# Pre-visualization Service (svc-previz)

Sistema backend per la gestione di scene 3D, storyboarding e pre-visualizzazione.

## Quick Start

### 1. Installazione

```bash
cd svc-previz
npm install
```

### 2. Configurazione

```bash
cp .env.example .env
# Modifica le variabili d'ambiente
```

### 3. Database Setup

```bash
# Esegui la migration
psql -U postgres -d ewh_platform -f ../migrations/070_previz_system.sql
```

### 4. Avvio

```bash
# Development
npm run dev

# Production
npm run build
npm start
```

Il servizio sarà disponibile su: http://localhost:5800

## API Documentation

Una volta avviato, la documentazione completa delle API è disponibile su:
- http://localhost:5800/api/docs
- http://localhost:5800/api/docs/webhooks

## Endpoints Principali

### Scenes
- `GET /api/scenes` - Ottieni tutte le scene
- `POST /api/scenes` - Crea nuova scena
- `GET /api/scenes/:id` - Ottieni scena specifica
- `PUT /api/scenes/:id` - Aggiorna scena
- `DELETE /api/scenes/:id` - Elimina scena
- `GET /api/scenes/:id/export` - Esporta scena

### Characters, Props, Lights, Cameras
- Endpoints simili per ogni risorsa
- CRUD completo
- Transform updates

### Shots & Storyboards
- Gestione inquadrature
- Sequencing shots
- Export PDF/video

### Library & AI
- Libreria props
- Generazione AI
- Import/Export

## Struttura

```
svc-previz/
├── src/
│   ├── controllers/      # Business logic
│   ├── routes/          # API routes
│   ├── services/        # Data services
│   ├── models/          # Data models
│   ├── middleware/      # Express middleware
│   ├── types/           # TypeScript types
│   └── index.ts         # Entry point
├── admin-panel-config.json  # Admin panel settings
├── package.json
└── tsconfig.json
```

## Features

✅ Scene management (3D sets)
✅ Characters (modular rigs)
✅ Props (library + AI generation)
✅ Lighting system (5 types)
✅ Camera system (real lens simulation)
✅ Shots & Storyboards
✅ Webhook system
✅ Export (JSON, FBX, USD, Alembic)
✅ Admin panel integration
✅ Multi-tenant support

## Sviluppo

Il servizio è attualmente in fase di sviluppo. I controller sono stub che ritornano dati mock. Per implementare la logica:

1. Aggiungere servizi database in `src/services/`
2. Implementare logica nei controller
3. Aggiungere validazione Zod
4. Implementare webhook delivery
5. Implementare export formats

## License

Proprietario - EWH Platform
