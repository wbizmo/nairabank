import react from "@vitejs/plugin-react"
import { defineConfig } from "vitest/config"

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("recharts") || id.includes("d3-")) return "charts"
          if (id.includes("@phosphor-icons")) return "icons"
          if (id.includes("node_modules/react") || id.includes("node_modules/scheduler")) return "react-vendor"
          return undefined
        },
      },
    },
  },
  test: { environment: "jsdom", setupFiles: "./src/test/setup.ts", globals: true },
})
