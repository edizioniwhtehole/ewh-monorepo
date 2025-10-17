import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: PORT_NUMBER,
    host: '0.0.0.0',
  },
});
