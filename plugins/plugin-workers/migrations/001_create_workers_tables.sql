-- Workers Plugin - Database Schema

CREATE SCHEMA IF NOT EXISTS workers;

-- Worker Instances
CREATE TABLE workers.worker_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  hostname VARCHAR(255),
  pid INTEGER,

  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'idle',  -- active|idle|error|stopped
  current_task_id UUID,

  -- Stats
  tasks_completed INTEGER DEFAULT 0,
  tasks_failed INTEGER DEFAULT 0,

  -- Resources
  cpu_usage DECIMAL(5, 2),
  memory_usage_mb INTEGER,

  -- Lifecycle
  started_at TIMESTAMPTZ DEFAULT NOW(),
  last_heartbeat TIMESTAMPTZ DEFAULT NOW(),
  stopped_at TIMESTAMPTZ,

  CONSTRAINT valid_status CHECK (status IN ('active', 'idle', 'error', 'stopped'))
);

-- Task Queue
CREATE TABLE workers.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_type VARCHAR(100) NOT NULL,
  priority INTEGER DEFAULT 5,

  -- Payload
  payload JSONB NOT NULL,

  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending',  -- pending|processing|completed|failed|cancelled
  assigned_worker_id UUID REFERENCES workers.worker_instances(id),

  -- Timing
  created_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  -- Results
  result JSONB,
  error_message TEXT,

  -- Retry
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,

  CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled'))
);

-- Task History (for analytics)
CREATE TABLE workers.task_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL,
  task_type VARCHAR(100) NOT NULL,
  worker_id UUID,

  -- Timing metrics
  execution_time_ms INTEGER,
  queue_time_ms INTEGER,

  -- Result
  status VARCHAR(50) NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT NOW(),

  -- Retention: keep last 30 days
  CONSTRAINT retention_check CHECK (completed_at > NOW() - INTERVAL '30 days')
);

-- Indexes
CREATE INDEX idx_workers_status ON workers.worker_instances(status);
CREATE INDEX idx_workers_heartbeat ON workers.worker_instances(last_heartbeat);

CREATE INDEX idx_tasks_status ON workers.tasks(status);
CREATE INDEX idx_tasks_priority ON workers.tasks(priority DESC);
CREATE INDEX idx_tasks_created ON workers.tasks(created_at);
CREATE INDEX idx_tasks_type ON workers.tasks(task_type);

CREATE INDEX idx_task_history_type ON workers.task_history(task_type);
CREATE INDEX idx_task_history_completed ON workers.task_history(completed_at);

-- Functions
CREATE OR REPLACE FUNCTION workers.update_worker_heartbeat()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IN ('active', 'idle') THEN
    NEW.last_heartbeat = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_heartbeat
  BEFORE UPDATE ON workers.worker_instances
  FOR EACH ROW
  EXECUTE FUNCTION workers.update_worker_heartbeat();

COMMENT ON SCHEMA workers IS 'Worker management and task queue system';
COMMENT ON TABLE workers.worker_instances IS 'Active worker instances in the pool';
COMMENT ON TABLE workers.tasks IS 'Task queue for background job processing';
COMMENT ON TABLE workers.task_history IS 'Historical task execution data for analytics';
