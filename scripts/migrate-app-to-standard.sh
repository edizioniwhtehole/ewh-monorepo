#!/bin/bash
# Migrate frontend app to platform standards

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <app-name> <port>"
  echo "Example: $0 app-pm-frontend 3100"
  exit 1
fi

APP_NAME=$1
PORT=$2
APP_PATH="/Users/andromeda/dev/ewh/$APP_NAME"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ Error: App directory not found: $APP_PATH"
  exit 1
fi

echo "🔄 Migrating $APP_NAME to platform standards..."

# 1. Create logs directory
echo "📁 Creating logs directory..."
mkdir -p "$APP_PATH/logs"

# 2. Create ecosystem.config.cjs from template
echo "⚙️  Creating PM2 configuration..."
cat > "$APP_PATH/ecosystem.config.cjs" << EOF
module.exports = {
  apps: [
    {
      name: '$APP_NAME',
      script: 'npm',
      args: 'run dev',
      cwd: '$APP_PATH',
      instances: 1,
      exec_mode: 'fork',

      // Auto-restart configuration
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 2000,

      // Memory limits
      max_memory_restart: '800M',

      // Environment
      env: {
        NODE_ENV: 'development',
        PORT: $PORT,
        BROWSER: 'none',
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: $PORT,
      },

      // Logging
      error_file: './logs/error.log',
      out_file: './logs/out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,

      // Process management
      kill_timeout: 5000,
      listen_timeout: 10000,
      shutdown_with_message: true,

      // Health check
      health_check: {
        enabled: true,
        interval: 60000,
        timeout: 10000,
        url: 'http://localhost:$PORT',
      },
    },
  ],
};
EOF

# 3. Update .gitignore
echo "📝 Updating .gitignore..."
if [ -f "$APP_PATH/.gitignore" ]; then
  if ! grep -q "logs/" "$APP_PATH/.gitignore"; then
    echo "" >> "$APP_PATH/.gitignore"
    echo "# PM2 logs" >> "$APP_PATH/.gitignore"
    echo "logs/" >> "$APP_PATH/.gitignore"
    echo "*.log" >> "$APP_PATH/.gitignore"
  fi
else
  cat > "$APP_PATH/.gitignore" << EOF
node_modules
dist
.next
build
logs/
*.log
.DS_Store
.env.local
EOF
fi

# 4. Create FUNCTIONS.md placeholder
if [ ! -f "$APP_PATH/FUNCTIONS.md" ]; then
  echo "📚 Creating FUNCTIONS.md placeholder..."
  cat > "$APP_PATH/FUNCTIONS.md" << EOF
# Function Index - $APP_NAME

**App**: $APP_NAME
**Port**: $PORT
**Type**: Frontend Application
**Last Updated**: $(date +%Y-%m-%d)

## Overview
Frontend application for EWH platform.

---

## 📁 File Structure

(To be documented)

---

## 🎯 Main Components

(To be documented)

---

## 🔌 API Endpoints Used

(To be documented)

---

## 📊 Platform Standards Compliance

- [x] PM2 configuration
- [x] Logs directory
- [ ] Health check endpoint (optional for frontend)
- [ ] Service registry integration (optional for frontend)
- [ ] Function index documentation

---

**Note**: This is a placeholder. Update with actual component and function documentation.
EOF
fi

# 5. Create README if missing
if [ ! -f "$APP_PATH/README.md" ]; then
  echo "📖 Creating README.md..."
  cat > "$APP_PATH/README.md" << EOF
# $APP_NAME

Frontend application for EWH platform.

## Quick Start

\`\`\`bash
# Install dependencies
pnpm install

# Development (manual)
pnpm dev

# Or run with PM2 (recommended)
pm2 start ecosystem.config.cjs
pm2 logs $APP_NAME
\`\`\`

## Configuration

- **Port**: $PORT
- **Environment**: See \`.env\` file

## PM2 Management

\`\`\`bash
# Start
pm2 start ecosystem.config.cjs

# Status
pm2 status

# Logs
pm2 logs $APP_NAME

# Restart
pm2 restart $APP_NAME

# Stop
pm2 stop $APP_NAME
\`\`\`

## Platform Standards

- ✅ PM2 configuration with auto-restart
- ✅ Structured logging to ./logs/
- ✅ Health check monitoring
- ✅ Environment configuration

See [FUNCTIONS.md](./FUNCTIONS.md) for component documentation.
EOF
fi

echo ""
echo "✅ Migration complete for $APP_NAME!"
echo ""
echo "📋 Summary:"
echo "  - PM2 config: ✅ ecosystem.config.cjs"
echo "  - Logs dir: ✅ logs/"
echo "  - .gitignore: ✅ Updated"
echo "  - FUNCTIONS.md: ✅ Created"
echo "  - README.md: ✅ Created"
echo ""
echo "🚀 Next steps:"
echo "  1. cd $APP_NAME"
echo "  2. pm2 start ecosystem.config.cjs"
echo "  3. pm2 logs $APP_NAME"
echo ""
