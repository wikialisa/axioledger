import { defineConfig } from 'vitest/config';

/**
 * Root Vitest workspace config for core/sdk
 * Covers all 15 packages across 5 NPM scopes:
 *   @axioledger, @valiprecision, @sequentichain, @kinetoprotocol, @veraciphers
 *
 * Run all tests:     npm test          (from core/sdk/)
 * Run with coverage: npm run test:ci   (from core/sdk/)
 * Run single pkg:    npx vitest run --project @kinetoprotocol/amm
 */
export default defineConfig({
  test: {
    // Discover all packages via glob
    include: ['packages/**/__tests__/**/*.test.ts', 'packages/**/*.test.ts'],
    exclude: ['**/node_modules/**', '**/dist/**'],

    environment: 'node',

    // Reporters: verbose in CI, default locally
    reporters: process.env.CI ? ['verbose', 'json'] : ['verbose'],
    outputFile: process.env.CI ? 'test-results.json' : undefined,

    coverage: {
      provider: 'v8',
      include: ['packages/**/src/**/*.ts'],
      exclude: [
        '**/node_modules/**',
        '**/dist/**',
        '**/__tests__/**',
      ],
      reporter: ['text', 'lcov'],
      // These packages currently export only constants (VERSION, PACKAGE).
      // Thresholds are set to 100% — fully covered by the 3 contract tests per package.
      // When business logic is added to any package, these thresholds enforce coverage.
      thresholds: {
        lines:      100,
        functions:  100,
        statements: 100,
        branches:   100,
      },
      perFile: false,
    },
  },
});
