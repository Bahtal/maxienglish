import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { fileURLToPath } from 'node:url';

const variablesScssPath = fileURLToPath(new URL('./src/styles/_variables.scss', import.meta.url));

export default defineConfig({
  plugins: [vue()],
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@use "${variablesScssPath}" as *;\n`,
      },
    },
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
});
