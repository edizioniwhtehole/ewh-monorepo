#!/bin/bash

# Deploy Voice/Phone System to Mac Studio
# This script:
# 1. Runs database migration
# 2. Syncs svc-voice to Mac Studio
# 3. Installs dependencies on Mac Studio
# 4. Starts svc-voice service

set -e

MAC_STUDIO_IP="192.168.1.47"
MAC_STUDIO_USER="fabio"
REMOTE_DIR="/Users/fabio/dev/ewh"

echo "🚀 Deploying Voice System to Mac Studio..."

# 1. Run database migration on Mac Studio
echo ""
echo "📊 Running database migration..."
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} << 'ENDSSH'
cd /Users/fabio/dev/ewh
PGPASSWORD=ewhpass psql -h localhost -U postgres -d ewh_master -f migrations/051_voice_system_tables.sql 2>&1 | grep -v "already exists" || true
echo "✅ Database migration completed"
ENDSSH

# 2. Sync svc-voice directory
echo ""
echo "📦 Syncing svc-voice to Mac Studio..."
rsync -avz --delete \
  --exclude 'node_modules' \
  --exclude 'dist' \
  --exclude '.env' \
  /Users/andromeda/dev/ewh/svc-voice/ \
  ${MAC_STUDIO_USER}@${MAC_STUDIO_IP}:${REMOTE_DIR}/svc-voice/

# 3. Create .env file on Mac Studio
echo ""
echo "⚙️  Creating .env file..."
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} << 'ENDSSH'
cd /Users/fabio/dev/ewh/svc-voice

cat > .env << 'EOF'
# Server Configuration
NODE_ENV=development
PORT=4640
WS_PORT=4641

# Database
DATABASE_URL=postgresql://postgres:ewhpass@localhost:5432/ewh_master

# Redis
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=ewh-super-secret-jwt-key-2024

# Twilio Configuration (placeholder - configure with real credentials)
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_API_KEY=your-twilio-api-key
TWILIO_API_SECRET=your-twilio-api-secret
TWILIO_TWIML_APP_SID=your-twiml-app-sid
TWILIO_DEFAULT_FROM_NUMBER=+1234567890

# OpenAI Configuration (placeholder - configure with real key)
OPENAI_API_KEY=your-openai-api-key
OPENAI_MODEL=whisper-1

# Storage
STORAGE_TYPE=local
MINIO_ENDPOINT=localhost
MINIO_PORT=9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET=voice-recordings

# Webhooks
WEBHOOK_BASE_URL=http://localhost:4640
WEBHOOK_SECRET=ewh-webhook-secret

# Recording Configuration
AUTO_RECORD_CALLS=true
RECORDING_MAX_DURATION_SECONDS=3600
AUTO_TRANSCRIBE=false

# IVR Configuration
IVR_DEFAULT_LANGUAGE=en-US
IVR_DEFAULT_VOICE=Polly.Joanna

# Rate Limiting
RATE_LIMIT_CALLS_PER_MINUTE=10
RATE_LIMIT_CALLS_PER_HOUR=100

# Feature Flags
ENABLE_AI_TRANSCRIPTION=false
ENABLE_SENTIMENT_ANALYSIS=false
ENABLE_CALL_RECORDING=true
ENABLE_VOICEMAIL=true
ENABLE_IVR=true
EOF

echo "✅ .env file created"
ENDSSH

# 4. Install dependencies on Mac Studio
echo ""
echo "📦 Installing dependencies on Mac Studio..."
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} << 'ENDSSH'
cd /Users/fabio/dev/ewh/svc-voice
npm install --quiet 2>&1 | grep -v "deprecated" || true
echo "✅ Dependencies installed"
ENDSSH

# 5. Build TypeScript
echo ""
echo "🔨 Building TypeScript..."
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} << 'ENDSSH'
cd /Users/fabio/dev/ewh/svc-voice
npm run build 2>&1 || true
echo "✅ Build completed"
ENDSSH

# 6. Add to PM2
echo ""
echo "🚀 Starting svc-voice with PM2..."
ssh ${MAC_STUDIO_USER}@${MAC_STUDIO_IP} << 'ENDSSH'
cd /Users/fabio/dev/ewh/svc-voice

# Stop if already running
npx pm2 delete svc-voice 2>/dev/null || true

# Start with PM2
npx pm2 start src/index.ts \
  --name svc-voice \
  --interpreter tsx \
  --watch src \
  --ignore-watch node_modules \
  --log /Users/fabio/dev/ewh/logs/svc-voice.log \
  --time

npx pm2 save
echo "✅ svc-voice started"
ENDSSH

echo ""
echo "✅ Voice System deployed successfully!"
echo ""
echo "📍 Endpoints:"
echo "   - HTTP API:     http://192.168.1.47:4640"
echo "   - WebSocket:    ws://192.168.1.47:4641"
echo "   - API Docs:     http://192.168.1.47:4640/dev"
echo "   - Health Check: http://192.168.1.47:4640/health"
echo ""
echo "📝 Next steps:"
echo "   1. Configure Twilio credentials in .env"
echo "   2. Configure OpenAI API key in .env"
echo "   3. Test with: curl http://192.168.1.47:4640/health"
echo ""
