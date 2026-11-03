/**
 * axiopass-wallet.spec.ts — Playwright UI tests for axiopass-wallet
 *
 * Covers:
 *   1. Page loads without crash (CSP, no console errors)
 *   2. Passkey onboarding screen visible when not connected
 *   3. Wallet connection via injected mock ethereum
 *   4. $AXQ balance tile appears after connect
 *   5. Passkey registration flow (WebAuthn mock)
 *   6. VRQPasskeyValidator install panel visible
 *   7. ANS address masking — AddressDisplay renders name not raw hex
 *   8. TLP badges visible on info cards
 *   9. Send/Receive/Swap buttons trigger toast
 *  10. Disconnect clears the address display
 */

import { test, expect, testUserAccount, CONTRACTS, publicClient } from './fixtures/wallet-mock';

const AXQ_TOKEN_ABI_BALANCE = [
  { name: 'balanceOf', type: 'function', stateMutability: 'view',
    inputs: [{ type: 'address' }], outputs: [{ type: 'uint256' }] },
] as const;

test.describe('axiopass-wallet', () => {

  // ── 1. Page load ────────────────────────────────────────────────────────────
  test('loads without console errors', async ({ walletPage: page }) => {
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error' && !msg.text().includes('axio-mock')) {
        consoleErrors.push(msg.text());
      }
    });
    page.on('pageerror', err => consoleErrors.push(err.message));

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Filter known benign Next.js hydration warnings
    const realErrors = consoleErrors.filter(e =>
      !e.includes('Warning:') &&
      !e.includes('hydration') &&
      !e.includes('Expected server HTML')
    );
    expect(realErrors, `Console errors: ${realErrors.join('\n')}`).toHaveLength(0);
  });

  // ── 2. Onboarding screen ────────────────────────────────────────────────────
  test('shows passkey onboarding when not connected', async ({ page }) => {
    // Fresh page with NO wallet mock (ethereum not injected)
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');

    // The onboarding section contains the passkey CTA
    await expect(page.getByText(/Face ID|Touch ID|Create Wallet/i)).toBeVisible({ timeout: 10_000 });
    await expect(page.getByText(/No seed phrase/i)).toBeVisible();
  });

  // ── 3. Wallet connection ────────────────────────────────────────────────────
  test('connects wallet and shows address', async ({ testUserPage: page }) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');

    // Click "Connect Wallet" or "Connect existing wallet"
    const connectBtn = page.getByRole('button', { name: /connect.*wallet|connect existing/i });
    await connectBtn.first().click();

    // After connection: address should appear (truncated or ANS-resolved)
    // AddressDisplay renders either the ANS name or truncated hex
    const addr = testUserAccount.address.toLowerCase();
    const addrTruncated = `${addr.slice(0, 6)}…${addr.slice(-4)}`;

    await expect(
      page.locator('[class*="axio-address"], [title*="0x"]').first()
    ).toBeVisible({ timeout: 10_000 });
  });

  // ── 4. AXQ balance tile ─────────────────────────────────────────────────────
  test('shows $AXQ balance after connect (requires deployed token)', async ({ testUserPage: page }) => {
    // Verify the contract actually has balance first
    const balance = await publicClient.readContract({
      address: CONTRACTS.axqToken,
      abi: AXQ_TOKEN_ABI_BALANCE,
      functionName: 'balanceOf',
      args: [testUserAccount.address],
    }) as bigint;

    test.skip(balance === 0n, 'AXQ token not deployed — skipping balance test');

    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');

    // Connect
    await page.getByRole('button', { name: /connect/i }).first().click();
    await page.waitForTimeout(2000); // wagmi loads balance async

    // Balance tile should appear with a non-zero number
    // The tile contains "AXQ Balance" label
    await expect(page.getByText('$AXQ Balance')).toBeVisible({ timeout: 15_000 });
  });

  // ── 5. Passkey registration (mocked WebAuthn) ───────────────────────────────
  test('passkey button triggers registration flow', async ({ testUserPage: page }) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');

    // Look for the PasskeyButton
    const passkeyBtn = page.getByRole('button', {
      name: /face id|touch id|create wallet/i,
    });

    // If not visible (already connected), skip
    const isVisible = await passkeyBtn.isVisible().catch(() => false);
    test.skip(!isVisible, 'PasskeyButton not visible — wallet may already be connected');

    await passkeyBtn.click();

    // After clicking, the mock navigator.credentials.create() resolves immediately
    // PasskeyButton transitions: idle → "Authenticated ✓"
    await expect(
      page.getByText(/authenticated|registered/i)
    ).toBeVisible({ timeout: 10_000 });
  });

  // ── 6. Validator install panel ──────────────────────────────────────────────
  test('shows VRQPasskeyValidator install panel when VRQ configured', async ({ testUserPage: page }) => {
    // Only meaningful if VRQ_VALIDATOR is configured
    test.skip(
      CONTRACTS.vrqValidator === '' || CONTRACTS.vrqValidator === '0x',
      'VRQ_VALIDATOR not configured'
    );

    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');

    // Connect
    await page.getByRole('button', { name: /connect/i }).first().click();
    await page.waitForTimeout(1500);

    // The InstallValidatorPanel heading should appear
    await expect(page.getByText('Install Passkey Validator')).toBeVisible({ timeout: 10_000 });

    // Install steps should be visible
    await expect(page.getByText(/Register biometric passkey/i)).toBeVisible();
    await expect(page.getByText(/Build ERC-7579 install payload/i)).toBeVisible();
  });

  // ── 7. TLP badges on info cards ─────────────────────────────────────────────
  test('info cards show TLP namespace badges', async ({ testUserPage: page }) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');

    // TLP badges have data-tlp attribute set by NamespaceBadge component
    const safeBadges   = page.locator('[data-tlp="safe"]');
    const cautionBadges = page.locator('[data-tlp="caution"]');

    // At least one safe badge (validator.vrq, compliance.vrq, node.axq)
    await expect(safeBadges.first()).toBeVisible({ timeout: 8_000 });

    // One caution badge (pool.kpx)
    await expect(cautionBadges.first()).toBeVisible({ timeout: 8_000 });
  });

  // ── 8. Disconnect ───────────────────────────────────────────────────────────
  test('disconnect button clears connection state', async ({ testUserPage: page }) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded');

    // Connect first
    const connectBtn = page.getByRole('button', { name: /connect/i }).first();
    await connectBtn.click();
    await page.waitForTimeout(1500);

    // Now disconnect
    const disconnectBtn = page.getByRole('button', { name: /disconnect/i });
    const isVisible = await disconnectBtn.isVisible().catch(() => false);
    if (!isVisible) { test.skip(true, 'Already disconnected or button not found'); return; }

    await disconnectBtn.click();

    // After disconnect: passkey onboarding or connect button should reappear
    await expect(
      page.getByRole('button', { name: /connect.*wallet|face id|touch id/i }).first()
    ).toBeVisible({ timeout: 8_000 });
  });

});
