import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Tauri dev expects a fixed port + host so the WebView can reach the dev server.
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
    watch: {
      ignored: ["**/src-tauri/**"],
    },
  },
});
