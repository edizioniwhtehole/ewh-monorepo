# svc-voice

Complete VoIP and Phone System Service with AI Transcription

## Features

- **Inbound/Outbound Calls**: Full Twilio-powered voice calling
- **Call Recording**: Automatic call recording with storage
- **AI Transcription**: OpenAI Whisper transcription with sentiment analysis
- **Voicemail System**: Complete voicemail with custom greetings
- **IVR Builder**: Visual IVR flow builder with TwiML generation
- **Mobile Device Support**: React Native SDK integration
- **Phone Number Management**: Purchase, configure, and release numbers
- **Call Analytics**: Comprehensive call logging and statistics

## Technology Stack

- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL
- **VoIP Provider**: Twilio
- **Transcription**: OpenAI Whisper
- **Real-time**: WebSocket
- **Authentication**: JWT via svc-auth

## Ports

- **HTTP API**: 4640
- **WebSocket**: 4641

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

```bash
# Twilio credentials
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_API_KEY=your-api-key
TWILIO_API_SECRET=your-api-secret

# OpenAI for transcription
OPENAI_API_KEY=your-openai-api-key

# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/ewh_master

# Webhook base URL (for Twilio callbacks)
WEBHOOK_BASE_URL=https://your-domain.com
```

### 3. Run Database Migration

```bash
psql -U postgres -d ewh_master -f ../migrations/051_voice_system_tables.sql
```

### 4. Start Service

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm run build
npm start
```

## API Documentation

Visit `http://localhost:4640/dev` for interactive API documentation.

## Key Endpoints

### Calls
- `POST /api/calls/outbound` - Make a call
- `GET /api/calls/log` - Get call history
- `GET /api/calls/:callId` - Get call details
- `GET /api/calls/stats/summary` - Get call statistics

### Voicemail
- `GET /api/voicemail/messages` - List voicemails
- `GET /api/voicemail/messages/:id` - Get voicemail with transcription
- `POST /api/voicemail/greetings` - Create custom greeting

### Phone Numbers
- `GET /api/numbers` - List owned numbers
- `GET /api/numbers/available` - Search available numbers
- `POST /api/numbers/purchase` - Purchase a number
- `DELETE /api/numbers/:phoneNumber` - Release number

### Transcription
- `POST /api/transcription/request` - Request transcription
- `GET /api/transcription/:id` - Get transcription

### Mobile Devices
- `POST /api/devices/register` - Register device for VoIP
- `POST /api/devices/token/refresh` - Refresh Twilio token
- `GET /api/devices` - List devices

## Architecture

### Call Flow

1. **Inbound Call**:
   - Twilio → `/api/voice/webhooks/twiml/inbound`
   - Check IVR configuration
   - Route to destination or voicemail
   - Record call (optional)
   - Transcribe (optional)

2. **Outbound Call**:
   - Client → `POST /api/calls/outbound`
   - Create Twilio call
   - Store in database
   - Webhook updates → `/api/voice/webhooks/status`

3. **Voicemail**:
   - Call → Voicemail TwiML
   - Record message
   - Webhook → `/api/voice/webhooks/voicemail`
   - Auto-transcribe
   - Notify user

### Mobile Integration

React Native apps use Twilio Voice SDK:

1. Register device: `POST /api/devices/register`
2. Receive access token for Twilio
3. Use token with Twilio Voice SDK
4. Native CallKit (iOS) / ConnectionService (Android)
5. Push notifications for incoming calls

## Database Schema

### Main Tables
- `calls` - Call records
- `phone_numbers` - Owned phone numbers
- `voicemails` - Voicemail messages
- `voicemail_greetings` - Custom greetings
- `transcriptions` - AI transcriptions
- `ivr_flows` - IVR flow definitions
- `mobile_devices` - Registered devices
- `recordings` - Call recordings

### Settings Tables (Cascade Configuration)
- `voice_platform_settings`
- `voice_tenant_settings`
- `voice_user_settings`

## Features by Priority

### Tier 1 (MVP) ✅
- Outbound calls
- Call recording
- Call log/history
- Phone number management
- Health check & API docs

### Tier 2 (Essential) ✅
- Inbound calls
- Voicemail system
- AI transcription (Whisper)
- Mobile device registration
- Twilio access tokens

### Tier 3 (Advanced) ✅
- IVR builder
- Custom voicemail greetings
- Call analytics
- Sentiment analysis
- Action item extraction

### Tier 4 (Future)
- Call conferencing
- Call transfer
- Call queues
- SIP trunking
- WebRTC browser calls

## Testing

### Health Check
```bash
curl http://localhost:4640/health
```

### Make a Test Call
```bash
TOKEN="your-jwt-token"

curl -X POST http://localhost:4640/api/calls/outbound \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "+1234567890",
    "from": "+0987654321",
    "record": true,
    "transcribe": true
  }'
```

### Get Call Log
```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:4640/api/calls/log?limit=10"
```

## Cost Optimization

### Twilio Pricing (approximate)
- Outbound calls: $0.013/min
- Inbound calls: $0.0085/min
- Phone numbers: $1/month
- Recording storage: Free (30 days), then $0.0005/min/month

### OpenAI Whisper
- Transcription: $0.006/minute

### Optimization Tips
1. Enable selective recording (not all calls)
2. Set recording retention policy
3. Use voicemail transcription sparingly
4. Implement call duration limits
5. Monitor usage via analytics

## Security

- All API endpoints require JWT authentication
- Twilio webhooks use signature validation
- Phone number purchase restricted to admin/owner
- Multi-tenancy with row-level security
- Encrypted recordings in S3/MinIO

## Development

### File Structure
```
svc-voice/
├── src/
│   ├── config/         # Database, Twilio, OpenAI configs
│   ├── middleware/     # Auth, validation, tenant
│   ├── routes/         # API endpoints
│   ├── services/       # Business logic
│   └── index.ts        # Main server
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

### Adding New Features

1. Add database table in migration
2. Create service in `src/services/`
3. Create route in `src/routes/`
4. Register route in `src/index.ts`
5. Update API documentation in `src/routes/dev.ts`

## Troubleshooting

### Calls Not Recording
- Check `AUTO_RECORD_CALLS=true` in .env
- Verify Twilio webhook URL is accessible
- Check recording storage configuration

### Transcription Failing
- Verify `OPENAI_API_KEY` is set
- Check OpenAI API quota
- Review error logs in database

### Mobile Device Can't Connect
- Verify device registration succeeded
- Check Twilio access token expiry (refresh every hour)
- Ensure push notifications configured

## Integration with Other Services

### CRM Integration
- Link calls to CRM contacts
- Auto-create leads from calls
- Call outcome tracking

### Email Integration
- Voicemail transcription via email
- Call recordings sent via email
- Call summaries

### Analytics Integration
- Export call data to BI tools
- Real-time dashboards
- Call quality metrics

## License

MIT

## Support

For issues and questions, contact the EWH Platform team.
