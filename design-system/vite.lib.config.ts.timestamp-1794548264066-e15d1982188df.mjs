// vite.lib.config.ts
import { defineConfig } from "file:///root/axioledger/node_modules/.pnpm/vite@5.4.21_@types+node@26.6.6_terser@5.51.2/node_modules/vite/dist/node/index.js";
import react from "file:///root/axioledger/node_modules/.pnpm/@vitejs+plugin-react@4.7.0_vite@5.4.21_@types+node@26.6.6_terser@5.51.2_/node_modules/@vitejs/plugin-react/dist/index.js";
import dts from "file:///root/axioledger/node_modules/.pnpm/vite-plugin-dts@4.5.4_@types+node@26.6.6_rollup@4.63.1_typescript@5.9.3_vite@5.4.21_@types+node@26.6.6_terser@5.51.2_/node_modules/vite-plugin-dts/dist/index.mjs";
import { resolve } from "path";
var __vite_injected_original_dirname = "/root/axioledger/design-system";
var vite_lib_config_default = defineConfig({
  plugins: [
    react(),
    dts({
      project: "./tsconfig.lib.json",
      insertTypesEntry: true,
      rollupTypes: true
    })
  ],
  resolve: {
    alias: { "@": resolve(__vite_injected_original_dirname, "src") }
  },
  build: {
    lib: {
      entry: resolve(__vite_injected_original_dirname, "src/index.ts"),
      name: "AxioDesignSystem",
      fileName: (format) => `index.${format === "es" ? "js" : "cjs"}`,
      formats: ["es", "cjs"]
    },
    rollupOptions: {
      // Do not bundle peer deps
      external: ["react", "react-dom", "react/jsx-runtime"],
      output: {
        globals: {
          react: "React",
          "react-dom": "ReactDOM",
          "react/jsx-runtime": "jsxRuntime"
        },
        // Tree-shaking: preserve modules lets consumers import only what they use
        preserveModules: false,
        assetFileNames: (assetInfo) => {
          if (assetInfo.name === "style.css") return "styles.css";
          return assetInfo.name ?? "asset";
        }
      }
    },
    // Inline CSS into a single styles.css (no CSS code split)
    cssCodeSplit: false,
    // Target modern browsers — aligns with Next.js 15 default
    target: "es2020",
    // Source maps for debugging in consuming apps
    sourcemap: true,
    // Fail on bundle > 500KB (pre-gzip) as a safety guard
    chunkSizeWarningLimit: 500
  }
});
export {
  vite_lib_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5saWIuY29uZmlnLnRzIl0sCiAgInNvdXJjZXNDb250ZW50IjogWyJjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfZGlybmFtZSA9IFwiL3Jvb3QvYXhpb2xlZGdlci9kZXNpZ24tc3lzdGVtXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCIvcm9vdC9heGlvbGVkZ2VyL2Rlc2lnbi1zeXN0ZW0vdml0ZS5saWIuY29uZmlnLnRzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9yb290L2F4aW9sZWRnZXIvZGVzaWduLXN5c3RlbS92aXRlLmxpYi5jb25maWcudHNcIjtpbXBvcnQgeyBkZWZpbmVDb25maWcgfSBmcm9tICd2aXRlJztcbmltcG9ydCByZWFjdCBmcm9tICdAdml0ZWpzL3BsdWdpbi1yZWFjdCc7XG5pbXBvcnQgZHRzIGZyb20gJ3ZpdGUtcGx1Z2luLWR0cyc7XG5pbXBvcnQgeyByZXNvbHZlIH0gZnJvbSAncGF0aCc7XG5cbi8qKlxuICogVml0ZSBsaWJyYXJ5IGJ1aWxkIGNvbmZpZ3VyYXRpb24uXG4gKlxuICogT3V0cHV0czpcbiAqICAgZGlzdC9pbmRleC5qcyAgICBcdTIwMTQgRVMgbW9kdWxlICh0cmVlLXNoYWtlYWJsZSlcbiAqICAgZGlzdC9pbmRleC5janMgICBcdTIwMTQgQ29tbW9uSlMgKE5leHQuanMgU1NSIC8gSmVzdClcbiAqICAgZGlzdC9zdHlsZXMuY3NzICBcdTIwMTQgQWxsIGNvbXBvbmVudCBDU1MgKG1lcmdlZCwgbm8gcnVudGltZSlcbiAqXG4gKiBQZWVyIGRlcGVuZGVuY2llcyAocmVhY3QsIHJlYWN0LWRvbSkgYXJlIGV4dGVybmFsaXplZCBcdTIwMTQgbm90IGJ1bmRsZWQuXG4gKi9cbmV4cG9ydCBkZWZhdWx0IGRlZmluZUNvbmZpZyh7XG4gIHBsdWdpbnM6IFtcbiAgICByZWFjdCgpLFxuICAgIGR0cyh7XG4gICAgICBwcm9qZWN0OiAnLi90c2NvbmZpZy5saWIuanNvbicsXG4gICAgICBpbnNlcnRUeXBlc0VudHJ5OiB0cnVlLFxuICAgICAgcm9sbHVwVHlwZXM6IHRydWUsXG4gICAgfSksXG4gIF0sXG5cbiAgcmVzb2x2ZToge1xuICAgIGFsaWFzOiB7ICdAJzogcmVzb2x2ZShfX2Rpcm5hbWUsICdzcmMnKSB9LFxuICB9LFxuXG4gIGJ1aWxkOiB7XG4gICAgbGliOiB7XG4gICAgICBlbnRyeTogcmVzb2x2ZShfX2Rpcm5hbWUsICdzcmMvaW5kZXgudHMnKSxcbiAgICAgIG5hbWU6ICdBeGlvRGVzaWduU3lzdGVtJyxcbiAgICAgIGZpbGVOYW1lOiAoZm9ybWF0KSA9PiBgaW5kZXguJHtmb3JtYXQgPT09ICdlcycgPyAnanMnIDogJ2Nqcyd9YCxcbiAgICAgIGZvcm1hdHM6IFsnZXMnLCAnY2pzJ10sXG4gICAgfSxcblxuICAgIHJvbGx1cE9wdGlvbnM6IHtcbiAgICAgIC8vIERvIG5vdCBidW5kbGUgcGVlciBkZXBzXG4gICAgICBleHRlcm5hbDogWydyZWFjdCcsICdyZWFjdC1kb20nLCAncmVhY3QvanN4LXJ1bnRpbWUnXSxcbiAgICAgIG91dHB1dDoge1xuICAgICAgICBnbG9iYWxzOiB7XG4gICAgICAgICAgcmVhY3Q6ICdSZWFjdCcsXG4gICAgICAgICAgJ3JlYWN0LWRvbSc6ICdSZWFjdERPTScsXG4gICAgICAgICAgJ3JlYWN0L2pzeC1ydW50aW1lJzogJ2pzeFJ1bnRpbWUnLFxuICAgICAgICB9LFxuICAgICAgICAvLyBUcmVlLXNoYWtpbmc6IHByZXNlcnZlIG1vZHVsZXMgbGV0cyBjb25zdW1lcnMgaW1wb3J0IG9ubHkgd2hhdCB0aGV5IHVzZVxuICAgICAgICBwcmVzZXJ2ZU1vZHVsZXM6IGZhbHNlLFxuICAgICAgICBhc3NldEZpbGVOYW1lczogKGFzc2V0SW5mbykgPT4ge1xuICAgICAgICAgIGlmIChhc3NldEluZm8ubmFtZSA9PT0gJ3N0eWxlLmNzcycpIHJldHVybiAnc3R5bGVzLmNzcyc7XG4gICAgICAgICAgcmV0dXJuIGFzc2V0SW5mby5uYW1lID8/ICdhc3NldCc7XG4gICAgICAgIH0sXG4gICAgICB9LFxuICAgIH0sXG5cbiAgICAvLyBJbmxpbmUgQ1NTIGludG8gYSBzaW5nbGUgc3R5bGVzLmNzcyAobm8gQ1NTIGNvZGUgc3BsaXQpXG4gICAgY3NzQ29kZVNwbGl0OiBmYWxzZSxcblxuICAgIC8vIFRhcmdldCBtb2Rlcm4gYnJvd3NlcnMgXHUyMDE0IGFsaWducyB3aXRoIE5leHQuanMgMTUgZGVmYXVsdFxuICAgIHRhcmdldDogJ2VzMjAyMCcsXG5cbiAgICAvLyBTb3VyY2UgbWFwcyBmb3IgZGVidWdnaW5nIGluIGNvbnN1bWluZyBhcHBzXG4gICAgc291cmNlbWFwOiB0cnVlLFxuXG4gICAgLy8gRmFpbCBvbiBidW5kbGUgPiA1MDBLQiAocHJlLWd6aXApIGFzIGEgc2FmZXR5IGd1YXJkXG4gICAgY2h1bmtTaXplV2FybmluZ0xpbWl0OiA1MDAsXG4gIH0sXG59KTtcbiJdLAogICJtYXBwaW5ncyI6ICI7QUFBb1IsU0FBUyxvQkFBb0I7QUFDalQsT0FBTyxXQUFXO0FBQ2xCLE9BQU8sU0FBUztBQUNoQixTQUFTLGVBQWU7QUFIeEIsSUFBTSxtQ0FBbUM7QUFlekMsSUFBTywwQkFBUSxhQUFhO0FBQUEsRUFDMUIsU0FBUztBQUFBLElBQ1AsTUFBTTtBQUFBLElBQ04sSUFBSTtBQUFBLE1BQ0YsU0FBUztBQUFBLE1BQ1Qsa0JBQWtCO0FBQUEsTUFDbEIsYUFBYTtBQUFBLElBQ2YsQ0FBQztBQUFBLEVBQ0g7QUFBQSxFQUVBLFNBQVM7QUFBQSxJQUNQLE9BQU8sRUFBRSxLQUFLLFFBQVEsa0NBQVcsS0FBSyxFQUFFO0FBQUEsRUFDMUM7QUFBQSxFQUVBLE9BQU87QUFBQSxJQUNMLEtBQUs7QUFBQSxNQUNILE9BQU8sUUFBUSxrQ0FBVyxjQUFjO0FBQUEsTUFDeEMsTUFBTTtBQUFBLE1BQ04sVUFBVSxDQUFDLFdBQVcsU0FBUyxXQUFXLE9BQU8sT0FBTyxLQUFLO0FBQUEsTUFDN0QsU0FBUyxDQUFDLE1BQU0sS0FBSztBQUFBLElBQ3ZCO0FBQUEsSUFFQSxlQUFlO0FBQUE7QUFBQSxNQUViLFVBQVUsQ0FBQyxTQUFTLGFBQWEsbUJBQW1CO0FBQUEsTUFDcEQsUUFBUTtBQUFBLFFBQ04sU0FBUztBQUFBLFVBQ1AsT0FBTztBQUFBLFVBQ1AsYUFBYTtBQUFBLFVBQ2IscUJBQXFCO0FBQUEsUUFDdkI7QUFBQTtBQUFBLFFBRUEsaUJBQWlCO0FBQUEsUUFDakIsZ0JBQWdCLENBQUMsY0FBYztBQUM3QixjQUFJLFVBQVUsU0FBUyxZQUFhLFFBQU87QUFDM0MsaUJBQU8sVUFBVSxRQUFRO0FBQUEsUUFDM0I7QUFBQSxNQUNGO0FBQUEsSUFDRjtBQUFBO0FBQUEsSUFHQSxjQUFjO0FBQUE7QUFBQSxJQUdkLFFBQVE7QUFBQTtBQUFBLElBR1IsV0FBVztBQUFBO0FBQUEsSUFHWCx1QkFBdUI7QUFBQSxFQUN6QjtBQUNGLENBQUM7IiwKICAibmFtZXMiOiBbXQp9Cg==
