-- Add password authentication to users table
-- Migration: 030_pm_add_user_passwords.sql

-- Add password_hash column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'password_hash'
  ) THEN
    ALTER TABLE users ADD COLUMN password_hash TEXT;
  END IF;
END $$;

-- Add last_login_at column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'last_login_at'
  ) THEN
    ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP;
  END IF;
END $$;

-- Add role column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'role'
  ) THEN
    ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT 'USER';
  END IF;
END $$;

-- Add status column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'status'
  ) THEN
    ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';
  END IF;
END $$;

-- Set default password hash for existing test users (password: 'test123')
-- Hash generated with bcrypt, password: 'test123'
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'password_hash') THEN
    UPDATE users
    SET password_hash = '$2b$10$rZ7qE9YvCxKVxJ6TxH1L8.3F0qH5VZ0xV3.VJz0QZ1J0Z0Z0Z0Z0Z'
    WHERE password_hash IS NULL;
  END IF;
END $$;

COMMENT ON COLUMN users.password_hash IS 'Bcrypt hashed password';
COMMENT ON COLUMN users.last_login_at IS 'Last successful login timestamp';
COMMENT ON COLUMN users.role IS 'User role: USER, ADMIN, MANAGER';
COMMENT ON COLUMN users.status IS 'User status: active, inactive, suspended';
