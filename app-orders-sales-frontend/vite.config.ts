import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 6800,
    proxy: {
      '/api/inventory': {
        target: 'http://localhost:6400',
        changeOrigin: true
      }
    }
  }
});
