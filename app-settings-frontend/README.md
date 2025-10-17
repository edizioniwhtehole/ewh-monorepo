# app-settings-frontend

Frontend application for EWH platform.

## Quick Start

```bash
# Install dependencies
pnpm install

# Development (manual)
pnpm dev

# Or run with PM2 (recommended)
pm2 start ecosystem.config.cjs
pm2 logs app-settings-frontend
```

## Configuration

- **Port**: 3450
- **Environment**: See `.env` file

## PM2 Management

```bash
# Start
pm2 start ecosystem.config.cjs

# Status
pm2 status

# Logs
pm2 logs app-settings-frontend

# Restart
pm2 restart app-settings-frontend

# Stop
pm2 stop app-settings-frontend
```

## Platform Standards

- ✅ PM2 configuration with auto-restart
- ✅ Structured logging to ./logs/
- ✅ Health check monitoring
- ✅ Environment configuration

See [FUNCTIONS.md](./FUNCTIONS.md) for component documentation.
