## Summary

<!-- One or two sentences describing what this PR does and why. -->

## Related Issue

<!-- Link the issue this PR closes, if applicable. -->
Closes #

## Type of Change

<!-- Check all that apply -->
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Chore / maintenance
- [ ] Refactor (no behavior change)
- [ ] Security hardening
- [ ] CI / tooling

## Area

<!-- Which package or area does this change affect? -->
- [ ] `design-system/`
- [ ] `packages/dom`
- [ ] `packages/events`
- [ ] `packages/time`
- [ ] `packages/*` (other)
- [ ] `apps/axiopass-wallet`
- [ ] `apps/axq-governance-ui`
- [ ] `docs/`
- [ ] `CI / monorepo`
- [ ] `smart-contracts/`
- [ ] `core-nodes/`
- [ ] `swift-server/`

## Changes Made

<!-- List the specific changes in this PR. Keep it concise. -->
- 
- 
- 

## Validation

<!-- Which commands did you run? Did they pass? -->

```bash
pnpm --filter <package> build
pnpm --filter <package> test
pnpm --filter <package> lint
pnpm --filter <package> typecheck
```

- [ ] `build` passes
- [ ] `test` passes
- [ ] `lint` passes
- [ ] `typecheck` passes
- [ ] `build:tokens:check` passes (design-system only)

## PR Checklist

- [ ] Change is minimal and scoped to the stated problem
- [ ] No unrelated code changed
- [ ] Tests added or updated for new behavior
- [ ] Docs / README updated if behavior changed
- [ ] No new dependencies added without discussion
- [ ] No hardcoded colors, credentials, or API keys introduced
- [ ] Accessibility considerations reviewed (if UI change)
- [ ] Security considerations reviewed (if auth/wallet/crypto change)

## Screenshots / Notes

<!-- Add screenshots, logs, or relevant context if helpful -->

## Security Note

<!-- If this PR touches TLP, auth, passkey, wallet storage, PIN, or cryptographic logic — describe the threat model consideration here. -->
