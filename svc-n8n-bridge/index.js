const express = require('express');
const cors = require('cors');
const Redis = require('ioredis');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 5680;

// Redis client
const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  db: 0
});

app.use(cors());
app.use(express.json());

// Mock auth middleware (per testing)
function extractTenant(req, res, next) {
  // In produzione: decodifica JWT
  req.tenant_id = 'tenant-test-123';
  req.user_id = 'user-test-456';
  next();
}

/**
 * 1. Execute workflow
 */
app.post('/workflows/:workflow_name/execute', extractTenant, async (req, res) => {
  const { workflow_name } = req.params;
  const { tenant_id, user_id } = req;

  // Genera correlation ID
  const correlationId = uuidv4();

  console.log(`📤 New workflow request:`);
  console.log(`   Correlation ID: ${correlationId}`);
  console.log(`   Workflow: ${workflow_name}`);
  console.log(`   Tenant: ${tenant_id}`);

  // Salva in Redis
  await redis.setex(
    `correlation:${correlationId}`,
    3600,
    JSON.stringify({
      tenant_id,
      user_id,
      workflow_name,
      status: 'pending',
      created_at: Date.now(),
      input: req.body
    })
  );

  // Forward a n8n
  try {
    console.log(`   → Forwarding to n8n: http://localhost:5678/webhook/${workflow_name}`);

    const response = await fetch(`http://localhost:5678/webhook/${workflow_name}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Correlation-ID': correlationId,
        'X-Tenant-ID': tenant_id,
        'X-User-ID': user_id
      },
      body: JSON.stringify({
        ...req.body,
        correlation_id: correlationId
      })
    });

    // Aggiorna status
    await redis.setex(
      `correlation:${correlationId}`,
      3600,
      JSON.stringify({
        tenant_id,
        user_id,
        workflow_name,
        status: 'processing',
        created_at: Date.now(),
        input: req.body
      })
    );

    console.log(`   ✅ Request sent to n8n`);

    res.json({
      correlation_id: correlationId,
      status: 'processing',
      message: 'Workflow execution started',
      poll_url: `/workflows/results/${correlationId}`
    });
  } catch (error) {
    console.error(`   ❌ Error forwarding to n8n:`, error.message);
    res.status(500).json({
      error: 'Failed to execute workflow',
      details: error.message
    });
  }
});

/**
 * 2. n8n saves results here
 */
app.post('/workflows/results/:correlation_id', async (req, res) => {
  const { correlation_id } = req.params;
  const { result, status, error } = req.body;

  console.log(`📥 Result received for: ${correlation_id}`);
  console.log(`   Status: ${status}`);

  const contextStr = await redis.get(`correlation:${correlation_id}`);
  if (!contextStr) {
    return res.status(404).json({ error: 'Correlation ID not found' });
  }

  const context = JSON.parse(contextStr);

  // Salva risultato
  await redis.setex(
    `correlation:${correlation_id}`,
    3600,
    JSON.stringify({
      ...context,
      status: status || 'completed',
      result,
      error,
      completed_at: Date.now()
    })
  );

  console.log(`   ✅ Result saved`);

  res.json({ success: true });
});

/**
 * 3. Client polls for results
 */
app.get('/workflows/results/:correlation_id', extractTenant, async (req, res) => {
  const { correlation_id } = req.params;
  const { tenant_id } = req;

  const contextStr = await redis.get(`correlation:${correlation_id}`);
  if (!contextStr) {
    return res.status(404).json({
      error: 'Result not found',
      message: 'Correlation ID not found or expired'
    });
  }

  const context = JSON.parse(contextStr);

  // Tenant isolation
  if (context.tenant_id !== tenant_id) {
    console.log(`   ⚠️  Access denied: tenant mismatch`);
    return res.status(403).json({
      error: 'Access denied',
      message: 'This result belongs to a different tenant'
    });
  }

  res.json({
    correlation_id,
    status: context.status,
    result: context.result,
    error: context.error,
    created_at: context.created_at,
    completed_at: context.completed_at,
    duration_ms: context.completed_at ? context.completed_at - context.created_at : null
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'n8n-bridge',
    redis: redis.status,
    uptime: process.uptime()
  });
});

redis.on('connect', () => {
  console.log('✓ Redis connected');
});

redis.on('error', (err) => {
  console.error('✗ Redis error:', err.message);
});

app.listen(PORT, () => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  n8n Bridge Service');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`✓ HTTP Server: http://localhost:${PORT}`);
  console.log(`✓ Redis: ${redis.status}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log('Ready to process workflows! 🚀');
  console.log('');
});
