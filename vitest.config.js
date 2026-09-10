import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    environment: "jsdom",
    include: ["spec/javascript/**/*.spec.js"],
    setupFiles: ["./spec/javascript/setup.js"]
  }
})
