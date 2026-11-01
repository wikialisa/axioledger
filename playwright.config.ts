import { defineConfig, devices } from '@playwright/test';

/**
 * AXIOLEDGER — Playwright E2E Configuration
 *
 * Tests two apps:
 *   axiopass-wallet   → http://localhost:3000
 *   axq-governance-ui → http://localhost:3001
 *
 * Strategy: NO MetaMask extension, NO Synpress.
 * We inject a deterministic window.ethereum mock + WebAuthn stub
 * via page.addInitScript() so tests run headless in CI without
 * any browser extension or real hardware authenticator.
 *
 * Prerequisites:
 *   bash scripts/localnet-setup.sh   (Anvil + contracts)
 *   pnpm --filter axiopass-wallet dev --port 3000
 *   pnpm --filter axq-governance-ui dev --port 3001
 *
 * Run:
 *   pnpm test:pw              (headless, all projects)
 *   pnpm test:pw --headed     (with browser window)
 *   pnpm test:pw --project=wallet
 *   pnpm test:pw --project=governance
 */

export default defineConfig({
  testDir:     './e2e/playwright',
  fullyParallel: false,  // wallets tests share Anvil state — run sequentially
  forbidOnly:  !!process.env.CI,
  retries:     process.env.CI ? 1 : 0,
  workers:     1,        // one worker — single Anvil node
  reporter: [
    ['list'],
    ['html', { outputFolder: 'e2e/playwright/reports', open: 'never' }],
    ['junit', { outputFile: 'e2e/playwright/reports/results.xml' }],
  ],

  use: {
    // Both apps run on localhost in CI via `pnpm dev`
    baseURL:     'http://localhost:3000',
    trace:       'on-first-retry',
    screenshot:  'only-on-failure',
    video:       'retain-on-failure',
    // Inject wallet mock before any page script runs
    // (set in each fixture — see fixtures/wallet-mock.ts)
  },

  // Global setup: verify Anvil is running before any test
  globalSetup:  './e2e/playwright/global-setup.ts',
  globalTeardown: './e2e/playwright/global-teardown.ts',

  projects: [
    {
      name: 'wallet',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: 'http://localhost:3000',
      },
      testMatch: '**/axiopass-wallet.spec.ts',
    },
    {
      name: 'governance',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: 'http://localhost:3001',
      },
      testMatch: '**/axq-governance-ui.spec.ts',
    },
    // Mobile viewport — wallet is PWA
    {
      name: 'wallet-mobile',
      use: {
        ...devices['iPhone 14'],
        baseURL: 'http://localhost:3000',
      },
      testMatch: '**/axiopass-wallet.spec.ts',
    },
  ],

  // Start dev servers automatically if not already running
  webServer: [
    {
      command:              'pnpm --filter axiopass-wallet dev --port 3000',
      url:                  'http://localhost:3000',
      reuseExistingServer:  !process.env.CI,
      timeout:              60_000,
      stderr:               'pipe',
    },
    {
      command:              'pnpm --filter axq-governance-ui dev --port 3001',
      url:                  'http://localhost:3001',
      reuseExistingServer:  !process.env.CI,
      timeout:              60_000,
      stderr:               'pipe',
    },
  ],
});
