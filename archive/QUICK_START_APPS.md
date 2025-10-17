# Quick Start - All Apps

Quick reference for starting and managing all frontend applications.

## 🚀 Start All Apps at Once

```bash
# From root directory
pm2 start ecosystem.all-apps.config.cjs

# Check status
pm2 status

# View logs
pm2 logs

# Monitor resources
pm2 monit
```

## 🎯 Start Individual Apps

### Core Apps

```bash
# PM Frontend (Project Management)
pm2 start app-pm-frontend/ecosystem.config.cjs
# Access: http://localhost:3100

# Admin Frontend
pm2 start app-admin-frontend/ecosystem.config.cjs
# Access: http://localhost:3200

# DAM (Digital Asset Management)
pm2 start app-dam/ecosystem.config.cjs
# Access: http://localhost:3300

# Media Frontend
pm2 start app-media-frontend/ecosystem.config.cjs
# Access: http://localhost:3310

# Web Frontend
pm2 start app-web-frontend/ecosystem.config.cjs
# Access: http://localhost:3320

# Shell Frontend (Main Entry Point)
pm2 start app-shell-frontend/ecosystem.config.cjs
# Access: http://localhost:3330
```

### Content & Design Apps

```bash
# CMS Frontend
pm2 start app-cms-frontend/ecosystem.config.cjs
# Access: http://localhost:3340

# Page Builder
pm2 start app-page-builder/ecosystem.config.cjs
# Access: http://localhost:3350

# Box Designer
pm2 start app-box-designer/ecosystem.config.cjs
# Access: http://localhost:3360

# Previz Frontend
pm2 start app-previz-frontend/ecosystem.config.cjs
# Access: http://localhost:3370
```

### Business Apps

```bash
# Communications Client
pm2 start app-communications-client/ecosystem.config.cjs
# Access: http://localhost:3380

# CRM Frontend
pm2 start app-crm-frontend/ecosystem.config.cjs
# Access: http://localhost:3390

# Inventory Frontend
pm2 start app-inventory-frontend/ecosystem.config.cjs
# Access: http://localhost:3400

# Orders - Purchase
pm2 start app-orders-purchase-frontend/ecosystem.config.cjs
# Access: http://localhost:3410

# Orders - Sales
pm2 start app-orders-sales-frontend/ecosystem.config.cjs
# Access: http://localhost:3420

# Quotations Frontend
pm2 start app-quotations-frontend/ecosystem.config.cjs
# Access: http://localhost:3430

# Procurement Frontend
pm2 start app-procurement-frontend/ecosystem.config.cjs
# Access: http://localhost:3440

# Settings Frontend
pm2 start app-settings-frontend/ecosystem.config.cjs
# Access: http://localhost:3450

# Workflow Editor
pm2 start app-workflow-editor/ecosystem.config.cjs
# Access: http://localhost:3460

# Workflow Insights
pm2 start app-workflow-insights/ecosystem.config.cjs
# Access: http://localhost:3470
```

### Specialized Apps

```bash
# Approvals Frontend
pm2 start app-approvals-frontend/ecosystem.config.cjs
# Access: http://localhost:3480

# Layout Editor
pm2 start app-layout-editor/ecosystem.config.cjs
# Access: http://localhost:3490

# Photo Editing
pm2 start app-photoediting/ecosystem.config.cjs
# Access: http://localhost:3500

# Orchestrator Frontend
pm2 start app-orchestrator-frontend/ecosystem.config.cjs
# Access: http://localhost:3510
```

## 🛠️ Common Commands

### View Logs

```bash
# All apps
pm2 logs

# Specific app
pm2 logs app-pm-frontend

# Last 50 lines
pm2 logs app-pm-frontend --lines 50

# No streaming (just show recent)
pm2 logs app-pm-frontend --nostream
```

### Restart Apps

```bash
# Restart all
pm2 restart all

# Restart specific app
pm2 restart app-pm-frontend

# Restart multiple apps
pm2 restart app-pm-frontend app-admin-frontend app-dam
```

### Stop Apps

```bash
# Stop all
pm2 stop all

# Stop specific app
pm2 stop app-pm-frontend

# Delete from PM2 (won't auto-restart)
pm2 delete app-pm-frontend
```

### Monitor Resources

```bash
# Interactive monitor
pm2 monit

# Status table
pm2 status

# Detailed info for one app
pm2 show app-pm-frontend
```

## 🔍 Troubleshooting

### App Not Starting

```bash
# Check logs
pm2 logs app-pm-frontend --lines 100

# Check if port is already in use
lsof -i :3100

# Kill process on port
kill -9 $(lsof -t -i:3100)

# Restart app
pm2 restart app-pm-frontend
```

### High Memory Usage

```bash
# Check memory
pm2 status

# If app is using >800MB, PM2 will auto-restart it
# Check logs for memory issues
pm2 logs app-pm-frontend | grep memory
```

### App Keeps Crashing

```bash
# Check restart count
pm2 status
# If restart count is high (>5), check logs

# View error logs only
pm2 logs app-pm-frontend --err

# Check if dependencies are installed
cd app-pm-frontend
pnpm install
```

## 📊 Port Reference

| Port Range | Purpose |
|------------|---------|
| 3100-3339 | Core apps (PM, Admin, DAM, Media, Web, Shell, CMS, Page Builder, Box Designer, Previz) |
| 3380-3499 | Business apps (Communications, CRM, Inventory, Orders, Quotations, Procurement, Settings, Workflows, Approvals) |
| 3500-3599 | Specialized apps (Layout Editor, Photo Editing, Orchestrator, Video Editor, Raster Editor) |

## 🎯 Typical Workflow

### Development

```bash
# 1. Start core apps
pm2 start app-shell-frontend/ecosystem.config.cjs
pm2 start app-admin-frontend/ecosystem.config.cjs

# 2. Start the app you're working on
pm2 start app-pm-frontend/ecosystem.config.cjs

# 3. Watch logs while developing
pm2 logs app-pm-frontend

# 4. Stop when done
pm2 stop app-pm-frontend
```

### Full Platform Testing

```bash
# 1. Start all apps
pm2 start ecosystem.all-apps.config.cjs

# 2. Check everything is running
pm2 status

# 3. Monitor resources
pm2 monit

# 4. Stop all when done
pm2 stop all
```

### Production-like Environment

```bash
# 1. Start with ecosystem file
pm2 start ecosystem.all-apps.config.cjs

# 2. Save PM2 configuration
pm2 save

# 3. Setup PM2 to start on boot
pm2 startup
# Follow the instructions provided

# 4. Apps will now restart automatically on system reboot
```

## 💡 Tips

- **Use `pm2 monit`** for real-time monitoring
- **Use `pm2 save`** to persist the current process list
- **Use `pm2 logs --lines 0`** to clear old logs and start fresh
- **Use `pm2 flush`** to clear all log files
- **Set `BROWSER=none`** in .env to prevent auto-opening browser tabs

## 🔗 Related Documents

- [ALL_APPS_MIGRATION_COMPLETE.md](ALL_APPS_MIGRATION_COMPLETE.md) - Migration details
- [APP_PORTS_ALLOCATION.md](APP_PORTS_ALLOCATION.md) - Port allocation table
- [REFERENCE_SERVICE_IMPLEMENTATION_COMPLETE.md](REFERENCE_SERVICE_IMPLEMENTATION_COMPLETE.md) - Service implementation guide

---

**Last Updated**: October 15, 2025
**Apps**: 24 frontend applications
**Status**: ✅ All migrated to PM2 standard
