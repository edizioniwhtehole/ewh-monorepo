module.exports = {
  apps: [
    {
      name: 'svc-example',
      script: 'npx',
      args: 'tsx src/index.ts',
      cwd: __dirname,
      instances: 1,
      exec_mode: 'fork',

      // Auto-restart configuration
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 1000,

      // Memory limits
      max_memory_restart: '500M',

      // Environment
      env: {
        NODE_ENV: 'development',
        PORT: 5100,
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 5100,
      },

      // Logging
      error_file: './logs/error.log',
      out_file: './logs/out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,

      // Process management
      kill_timeout: 5000,
      listen_timeout: 3000,
      shutdown_with_message: true,

      // Health check (PM2 will check this URL)
      health_check: {
        enabled: true,
        interval: 30000, // 30 seconds
        timeout: 5000,
        url: 'http://localhost:5100/health',
      },
    },
  ],
};
