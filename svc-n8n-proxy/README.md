# n8n Authentication Proxy

This service acts as an authentication proxy between your frontend and n8n, validating JWT tokens from the EWH auth service.

## Architecture

```
Frontend → svc-n8n-proxy (port 5679) → n8n (port 5678)
              ↓
         svc-auth (JWT validation)
```

## Features

- JWT token validation using RS256 algorithm
- Public key fetching from auth service
- User context forwarding to n8n via headers
- WebSocket support for real-time features
- CORS configuration
- Health check endpoint

## Setup

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables (copy `.env.example` to `.env`)

3. Start the service:
```bash
npm run dev
```

## Usage

### From Frontend

Instead of connecting directly to n8n on port 5678, connect to the proxy on port 5679:

```javascript
const response = await fetch('http://localhost:5679/api/workflows', {
  headers: {
    'Authorization': `Bearer ${yourJwtToken}`,
    'Content-Type': 'application/json'
  }
});
```

### User Context Headers

The proxy automatically adds these headers to requests forwarded to n8n:

- `x-ewh-user-id` - User's unique ID
- `x-ewh-user-email` - User's email address
- `x-ewh-tenant-id` - Organization/tenant ID
- `x-ewh-tenant-role` - User's role in the tenant

These can be used in n8n workflows to create tenant-specific automations.

## Endpoints

- `GET /health` - Health check (no auth required)
- `POST /refresh-key` - Refresh JWT public key from auth service (no auth required)
- `/*` - All other routes are proxied to n8n with JWT validation

## Security

- All requests (except health check) require valid JWT token
- Tokens are validated using RS256 public key from auth service
- Invalid or expired tokens return 401 Unauthorized
- Public key is cached in memory and refreshed on startup

## Development

```bash
npm run dev  # Start with hot reload
```

## Production

```bash
npm run build  # Compile TypeScript
npm start      # Run compiled JavaScript
```
