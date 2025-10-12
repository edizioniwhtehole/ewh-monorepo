#!/usr/bin/env node
/**
 * Generate a development JWT token for testing
 * This creates a token valid for 24 hours
 */

const jose = require('jose');
const crypto = require('crypto');

// Generate RSA key pair for development
const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
});

async function generateToken() {
  const payload = {
    email: "fabio.polosa@gmail.com",
    org_id: "1845c89e-63c6-4be2-85bc-07c40bacdef9",
    org_slug: "white-hole-srl",
    tenant_role: "TENANT_ADMIN",
    platform_role: "OWNER",
    scopes: [
      "feature:bundle.manage",
      "feature:catalog.access",
      "feature:dashboard.saas",
      "feature:dashboard.tenant",
      "feature:editor.access",
      "feature:production.access",
      "feature:reports.access"
    ],
    sub: "c395424b-1d60-4767-a6d9-615271ad679c",
    iss: "http://localhost:4001",
    aud: "ewh-saas"
  };

  const privateKeyObject = await jose.importPKCS8(privateKey, 'RS256');

  const token = await new jose.SignJWT(payload)
    .setProtectedHeader({ alg: 'RS256', kid: 'dev-local' })
    .setIssuedAt()
    .setExpirationTime('24h') // Token valid for 24 hours
    .setJti(crypto.randomUUID())
    .sign(privateKeyObject);

  const session = {
    tokenType: "Bearer",
    accessToken: token,
    expiresIn: 86400, // 24 hours
    refreshToken: "dev-refresh-token",
    scopes: payload.scopes,
    user: {
      id: payload.sub,
      email: payload.email,
      fullName: "Fabio Polosa",
      platformRole: payload.platform_role
    },
    organization: {
      id: payload.org_id,
      name: "White Hole SRL",
      slug: payload.org_slug
    },
    membership: {
      tenantRole: payload.tenant_role
    }
  };

  console.log('\n🔑 Development Token Generated!\n');
  console.log('📋 Copy this command and paste in your browser console:\n');
  console.log(`localStorage.setItem('ewh.session', '${JSON.stringify(session)}');\n`);
  console.log('Then refresh the page.\n');
  console.log('⚠️  Note: This token is for DEVELOPMENT ONLY and expires in 24 hours.\n');
  console.log('🔐 Token:', token.substring(0, 50) + '...\n');
}

generateToken().catch(console.error);
