import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5900,
    proxy: {
      '/api/quotations': {
        target: 'http://localhost:5800',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/quotations/, '/api/quotations')
      },
      '/api/pricing': {
        target: 'http://localhost:5800',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/pricing/, '/api/pricing')
      }
    }
  }
});
