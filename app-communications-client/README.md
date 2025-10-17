# app-communications-client

Frontend application for EWH platform.

## Quick Start

```bash
# Install dependencies
pnpm install

# Development (manual)
pnpm dev

# Or run with PM2 (recommended)
pm2 start ecosystem.config.cjs
pm2 logs app-communications-client
```

## Configuration

- **Port**: 3380
- **Environment**: See `.env` file

## PM2 Management

```bash
# Start
pm2 start ecosystem.config.cjs

# Status
pm2 status

# Logs
pm2 logs app-communications-client

# Restart
pm2 restart app-communications-client

# Stop
pm2 stop app-communications-client
```

## Platform Standards

- ✅ PM2 configuration with auto-restart
- ✅ Structured logging to ./logs/
- ✅ Health check monitoring
- ✅ Environment configuration

See [FUNCTIONS.md](./FUNCTIONS.md) for component documentation.
