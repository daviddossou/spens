import { fileURLToPath } from "node:url"
import { defineConfig } from "vitest/config"

export default defineConfig({
  // Mirrors the importmap pin of app/javascript/lib.
  resolve: {
    alias: { lib: fileURLToPath(new URL("./app/javascript/lib", import.meta.url)) }
  },
  test: {
    environment: "jsdom",
    include: ["spec/javascript/**/*.spec.js"],
    setupFiles: ["./spec/javascript/setup.js"]
  }
})
