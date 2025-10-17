"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const ioredis_1 = __importDefault(require("ioredis"));
const uuid_1 = require("uuid");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 5680;
// Redis for correlation ID storage
const redis = new ioredis_1.default({
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
    password: process.env.REDIS_PASSWORD,
    db: parseInt(process.env.REDIS_DB || '0')
});
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Middleware per estrarre tenant_id da JWT
function extractTenant(req, res, next) {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
        return res.status(401).json({ error: 'Missing authorization token' });
    }
    // Qui dovresti decodificare il JWT per estrarre tenant_id
    // Per ora mock
    req.tenant_id = 'tenant-123';
    req.user_id = 'user-456';
    next();
}
/**
 * 1. Endpoint per inviare richiesta a n8n
 * Crea correlation_id e traccia la richiesta
 */
app.post('/workflows/:workflow_name/execute', extractTenant, async (req, res) => {
    const { workflow_name } = req.params;
    const tenant_id = req.tenant_id;
    const user_id = req.user_id;
    // Genera correlation ID
    const correlationId = (0, uuid_1.v4)();
    // Salva context in Redis (TTL 1 ora)
    await redis.setex(`correlation:${correlationId}`, 3600, JSON.stringify({
        tenant_id,
        user_id,
        workflow_name,
        status: 'pending',
        created_at: Date.now(),
        input: req.body
    }));
    // Forward a n8n con correlation_id
    try {
        const n8nResponse = await fetch(`http://localhost:5678/webhook/${workflow_name}`, {
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
        await redis.setex(`correlation:${correlationId}`, 3600, JSON.stringify({
            tenant_id,
            user_id,
            workflow_name,
            status: 'processing',
            created_at: Date.now(),
            input: req.body
        }));
        res.json({
            correlation_id: correlationId,
            status: 'processing',
            message: 'Workflow execution started',
            poll_url: `/workflows/results/${correlationId}`
        });
    }
    catch (error) {
        res.status(500).json({
            error: 'Failed to execute workflow',
            details: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
/**
 * 2. Endpoint per n8n per salvare risultati
 * n8n chiama questo quando ha finito
 */
app.post('/workflows/results/:correlation_id', async (req, res) => {
    const { correlation_id } = req.params;
    const { result, status, error } = req.body;
    // Verifica che correlation_id esista
    const contextStr = await redis.get(`correlation:${correlation_id}`);
    if (!contextStr) {
        return res.status(404).json({ error: 'Correlation ID not found' });
    }
    const context = JSON.parse(contextStr);
    // Aggiorna con risultato
    await redis.setex(`correlation:${correlation_id}`, 3600, JSON.stringify({
        ...context,
        status: status || 'completed',
        result,
        error,
        completed_at: Date.now()
    }));
    // Opzionale: pubblica evento per WebSocket
    await redis.publish(`workflow:${correlation_id}`, JSON.stringify({
        correlation_id,
        status,
        result
    }));
    res.json({ success: true });
});
/**
 * 3. Endpoint per client per recuperare risultati
 * Client fa polling su questo endpoint
 */
app.get('/workflows/results/:correlation_id', extractTenant, async (req, res) => {
    const { correlation_id } = req.params;
    const tenant_id = req.tenant_id;
    const contextStr = await redis.get(`correlation:${correlation_id}`);
    if (!contextStr) {
        return res.status(404).json({
            error: 'Result not found',
            message: 'Correlation ID not found or expired'
        });
    }
    const context = JSON.parse(contextStr);
    // Verifica tenant isolation
    if (context.tenant_id !== tenant_id) {
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
        completed_at: context.completed_at
    });
});
/**
 * 4. WebSocket endpoint per real-time updates (opzionale)
 */
const socket_io_1 = require("socket.io");
const http_1 = require("http");
const httpServer = (0, http_1.createServer)(app);
const io = new socket_io_1.Server(httpServer, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST']
    }
});
io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);
    socket.on('subscribe', async (correlationId) => {
        // Verifica che correlation_id esista
        const exists = await redis.exists(`correlation:${correlationId}`);
        if (exists) {
            socket.join(`workflow:${correlationId}`);
            console.log(`Socket ${socket.id} subscribed to ${correlationId}`);
        }
    });
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});
// Redis subscriber per eventi workflow
const subscriber = new ioredis_1.default({
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379')
});
subscriber.psubscribe('workflow:*', (err, count) => {
    if (err) {
        console.error('Failed to subscribe:', err);
    }
    else {
        console.log(`Subscribed to ${count} channels`);
    }
});
subscriber.on('pmessage', (pattern, channel, message) => {
    const correlationId = channel.split(':')[1];
    io.to(channel).emit('result', JSON.parse(message));
});
// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        service: 'n8n-bridge',
        redis: redis.status
    });
});
httpServer.listen(PORT, () => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('  n8n Bridge Service');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✓ HTTP Server: http://localhost:${PORT}`);
    console.log(`✓ WebSocket: ws://localhost:${PORT}`);
    console.log(`✓ Redis: ${redis.status}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
});
