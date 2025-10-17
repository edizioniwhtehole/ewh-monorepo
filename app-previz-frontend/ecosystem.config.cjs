module.exports = {
  apps: [
    {
      name: 'app-previz-frontend',
      script: 'npm',
      args: 'run dev',
      cwd: '/Users/andromeda/dev/ewh/app-previz-frontend',
      instances: 1,
      exec_mode: 'fork',

      // Auto-restart configuration
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 2000,

      // Memory limits
      max_memory_restart: '800M',

      // Environment
      env: {
        NODE_ENV: 'development',
        PORT: 3370,
        BROWSER: 'none',
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3370,
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

      // Health check
      health_check: {
        enabled: true,
        interval: 60000,
        timeout: 10000,
        url: 'http://localhost:3370',
      },
    },
  ],
};
