/**
 * global-teardown.ts — Playwright global teardown
 * Logs a summary. Does NOT kill Anvil — let localnet-setup.sh manage it.
 */
export default async function globalTeardown() {
  console.log('\n[Playwright] Global teardown complete.');
}
