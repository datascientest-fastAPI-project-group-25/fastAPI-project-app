import path from "node:path"
import { TanStackRouterVite } from "@tanstack/router-vite-plugin"
import react from "@vitejs/plugin-react-swc"
import { defineConfig as defineViteConfig, mergeConfig } from "vite"
import { defineConfig as defineVitestConfig } from 'vitest/config'

// Base Vite config
const viteConfig = defineViteConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  plugins: [react(), TanStackRouterVite()],
});

// Vitest specific config
const vitestConfig = defineVitestConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
    // css: true, // Uncomment if needed
  },
});

// Export merged config
export default mergeConfig(viteConfig, vitestConfig);
