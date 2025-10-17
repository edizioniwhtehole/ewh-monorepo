module.exports = {
  apps: [
    {
      name: 'svc-service-registry',
      script: 'npx',
      args: 'tsx src/index.ts',
      cwd: __dirname,
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 1000,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'development',
        PORT: 5960,
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 5960,
      },
      error_file: './logs/error.log',
      out_file: './logs/out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      kill_timeout: 5000,
      listen_timeout: 3000,
      shutdown_with_message: true,
    },
  ],
};
