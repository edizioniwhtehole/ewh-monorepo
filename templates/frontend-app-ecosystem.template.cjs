// Template for Frontend App PM2 Configuration
// Replace: APP_NAME, APP_PORT, APP_PATH

module.exports = {
  apps: [
    {
      name: '{{APP_NAME}}',
      script: 'npm',
      args: 'run dev',
      cwd: '{{APP_PATH}}',
      instances: 1,
      exec_mode: 'fork',

      // Auto-restart configuration
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 2000,

      // Memory limits (frontend apps need more than backend)
      max_memory_restart: '800M',

      // Environment
      env: {
        NODE_ENV: 'development',
        PORT: '{{APP_PORT}}',
        BROWSER: 'none',
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: '{{APP_PORT}}',
      },

      // Logging
      error_file: './logs/error.log',
      out_file: './logs/out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,

      // Process management
      kill_timeout: 5000,
      listen_timeout: 10000,
      shutdown_with_message: true,

      // Health check (will check if port is responding)
      health_check: {
        enabled: true,
        interval: 60000, // 60 seconds
        timeout: 10000,
        url: 'http://localhost:{{APP_PORT}}',
      },
    },
  ],
};
