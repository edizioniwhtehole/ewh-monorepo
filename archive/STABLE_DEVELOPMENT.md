# Stable Development Environment Guide

## Quick Start (Recommended)

```bash
# 1. Start the system with wave deployment (most stable)
./scripts/stable-start.sh

# 2. Check system health
./scripts/health-check.sh

# 3. If services are down, restart them
docker restart [service_name]
```

## Understanding Container Status

### Docker Desktop shows "Up" ≠ Service is working

**Important:** Docker shows container status, not application status!

| What Docker Shows | What It Means | What Monitoring Shows |
|-------------------|---------------|----------------------|
| Container "Up" ✅ | Container process is running | May show "DOWN" ❌ if app crashed |
| Container "Healthy" ✅ | Docker health check passed | Should show "UP" ✅ |
| Container "Unhealthy" ⚠️ | Docker health check failed | Will show "DOWN" ❌ |

**Example Scenario:**
```
1. Docker starts container → Status: "Up" ✅
2. Node.js starts and tries to connect to postgres
3. Postgres is not ready yet → Connection error
4. Node.js crashes and exits
5. Container shell stays alive → Docker still shows "Up" ✅
6. HTTP server not responding → Monitoring shows "DOWN" ❌
```

### How to Check Real Status

```bash
# Check if Node.js is actually running inside container
docker exec [service_name] ps aux | grep node

# Check application logs
docker logs [service_name] --tail 50

# Test HTTP endpoint directly
curl http://localhost:[PORT]/health
```

## Common Issues and Solutions

### Issue 1: Services show "Up" but monitoring shows "DOWN"

**Cause:** Node.js process crashed inside the container

**Solution:**
```bash
# Check which services are crashed
./scripts/health-check.sh

# Restart crashed services
docker restart svc_crm svc_products svc_content

# Or restart all services
docker ps --format "{{.Names}}" | grep "^svc_" | xargs docker restart
```

### Issue 2: Services fail to start with "ENOTFOUND postgres"

**Cause:** Services started before PostgreSQL was ready

**Solution:**
```bash
# Use the stable startup script (handles ordering)
./scripts/stable-start.sh

# Or manually wait for postgres first
docker-compose up -d postgres
sleep 10
docker-compose up -d
```

### Issue 3: Admin frontend not accessible on :3200

**Cause:** Port conflict or admin container crashed

**Solution:**
```bash
# Check what's on port 3200
lsof -ti:3200

# Kill conflicting process
lsof -ti:3200 | xargs kill -9

# Restart admin frontend
docker restart app_admin_frontend

# Check logs
docker logs -f app_admin_frontend
```

### Issue 4: Random services crash after 10-30 minutes

**Cause:** Memory pressure or database connection pool exhaustion

**Solution:**
```bash
# Check container memory usage
docker stats --no-stream

# Increase Docker Desktop memory allocation
# Docker Desktop → Settings → Resources → Memory: 8GB+

# Restart specific service
docker restart [service_name]
```

## Development Workflows

### Starting Fresh

```bash
# Stop everything
docker-compose -f compose/docker-compose.dev.yml -p ewh down

# Remove volumes (fresh database)
docker-compose -f compose/docker-compose.dev.yml -p ewh down -v

# Start with stable script
./scripts/stable-start.sh

# Run migrations
cat migrations/*.sql | docker exec -i ewh_postgres psql -U ewh -d ewh_master
```

### Developing a Specific Service

```bash
# Start only infrastructure + your service
docker-compose up -d postgres redis minio
docker-compose up -d svc-your-service

# Watch logs
docker logs -f svc_your_service

# Make code changes (hot reload with tsx watch)
# Edit files in your-service/src/

# Restart if needed
docker restart svc_your_service
```

### Working on Admin Frontend

```bash
# Option 1: Run inside Docker
docker-compose up -d app-admin-frontend
docker logs -f app_admin_frontend

# Option 2: Run on host (faster hot reload)
cd app-admin-frontend
PORT=3200 npm run dev

# Note: Also start terminal proxy
node scripts/terminal-proxy.cjs
```

## Architecture Understanding

### Service Startup Order (Wave Deployment)

```
Wave 1: Infrastructure (30s)
  └─ postgres, redis, minio

Wave 2: Core Services (10s)
  └─ svc-auth, svc-api-gateway, svc-metrics-collector

Wave 3: Admin Frontend (5s)
  └─ app-admin-frontend

Wave 4: All Microservices (15s)
  └─ 45+ microservices in parallel

Wave 5: Check & Restart Crashed (10s)
  └─ Automatic restart of any crashed processes
```

### Network Architecture

All containers run on `ewh_ewh_net` Docker network:
- Services can reach each other by container name
- `postgres` hostname resolves to database
- Port mapping exposes services to host: `localhost:4001` → `svc-auth:4001`

### Environment Variables

Services get config from `docker-compose.dev.yml`:
```yaml
DATABASE_URL: postgres://ewh:ewhpass@postgres:5432/ewh_master
REDIS_URL: redis://redis:6379/0
S3_ENDPOINT: http://minio:9000
```

## Monitoring and Debugging

### Check Overall System Health

```bash
# Quick health check
./scripts/health-check.sh

# Detailed container status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{Ports}}"

# Check specific service logs
docker logs -f --tail 100 svc_api_gateway
```

### Service-Specific Health Checks

```bash
# Core services
curl http://localhost:4000/health  # API Gateway
curl http://localhost:4001/health  # Auth
curl http://localhost:4004/health  # Billing

# Database
docker exec ewh_postgres pg_isready -U ewh -d ewh_master

# Redis
docker exec ewh_redis redis-cli ping
```

### Performance Monitoring

```bash
# Container resource usage
docker stats

# Check for memory leaks in specific service
docker stats svc_api_gateway --no-stream

# Check database connections
docker exec ewh_postgres psql -U ewh -d ewh_master -c "SELECT count(*) FROM pg_stat_activity;"
```

## Best Practices

### ✅ DO

- Use `./scripts/stable-start.sh` for starting the full stack
- Run `./scripts/health-check.sh` regularly to catch issues early
- Check logs when a service shows as "DOWN": `docker logs [service]`
- Restart services individually when they crash
- Use `docker-compose` for managing services
- Keep Docker Desktop resources high (8GB+ RAM, 4+ CPUs)

### ❌ DON'T

- Don't start all 52 services at once with `docker-compose up -d`
- Don't trust "Up" status alone - always check health endpoints
- Don't restart Docker Desktop when services crash - restart the service instead
- Don't run migrations while services are starting up
- Don't allocate less than 6GB RAM to Docker Desktop

## Troubleshooting Commands

```bash
# Find which services are not responding
for port in 4001 4004 4005 4006 4007; do
  echo -n "Port $port: "
  curl -s --max-time 1 http://localhost:$port/health > /dev/null && echo "✓" || echo "✗"
done

# Restart all crashed services
./scripts/stable-start.sh  # Has auto-restart built in

# View real-time logs from all services
docker-compose logs -f

# Check which Node.js processes are running
docker ps --format "{{.Names}}" | grep svc_ | while read svc; do
  echo -n "$svc: "
  docker exec $svc ps aux | grep -c "node.*src/index" || echo "0"
done

# Quick restart of core services only
docker restart svc_auth svc_api_gateway svc_metrics_collector app_admin_frontend
```

## Getting Help

If services continue to crash:

1. Check logs: `docker logs [service_name] --tail 100`
2. Look for: `ECONNREFUSED`, `ENOTFOUND`, `Error:` messages
3. Verify database is ready: `docker exec ewh_postgres pg_isready -U ewh`
4. Check network: `docker network inspect ewh_ewh_net`
5. Verify environment variables: `docker exec [service] printenv | grep DATABASE_URL`

## Summary

**For a stable development environment:**

1. **Always use** `./scripts/stable-start.sh` to start services
2. **Monitor** with `./scripts/health-check.sh`
3. **Restart** crashed services with `docker restart [name]`
4. **Check logs** when services show as DOWN
5. **Remember**: "Container Up" ≠ "Application Working"
