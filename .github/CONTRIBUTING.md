# Contributing to AXIOLEDGER

Thank you for contributing to the AXIOLEDGER ecosystem. This guide explains how to get started, what our standards are, and how to open a good pull request.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Where to Start](#where-to-start)
- [Repo Map](#repo-map)
- [Setup](#setup)
- [Contribution Rules](#contribution-rules)
- [PR Workflow](#pr-workflow)
- [Commit Convention](#commit-convention)
- [Validation](#validation)
- [Security](#security)
- [First PR Path](#first-pr-path)

---

## Code of Conduct

All contributors are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md). Be respectful, constructive, and inclusive.

---

## Where to Start

The best starting points for new contributors, in order of accessibility:

| Priority | Area | Why |
|----------|------|-----|
| P0 ⭐ | `design-system/` | Central UI library, high impact per PR |
| P0 | `packages/dom` | DOM utilities, clear API surface |
| P0 | `packages/events` | Event subscriptions, clear scope |
| P0 | `packages/time` | Timer lifecycle, well-scoped |
| P1 | `apps/axiopass-wallet` | Integration validation, real flows |
| P2 | `docs/` | Onboarding, architecture maps |
| P2 | `CI / monorepo` | Build pipeline, package hygiene |
| P3 | `smart-contracts/` | Requires Solidity + security expertise |
| P3 | `core-nodes/` | Requires infra / protocol expertise |
| P3 | `swift-server/` | Requires SWIFT / PKI domain expertise |

**Tip:** Do not start from the full monorepo. Pick one package, open one PR.

---

## Repo Map

```
axioledger-monorepo/
├── design-system/         ← UI tokens, components, hooks (start here)
├── packages/
│   ├── dom/               ← DOM focus, blur, trap utilities
│   ├── events/            ← keyboard, window, frame event subscriptions
│   ├── time/              ← timers, timeouts, session lifecycle
│   └── */                 ← other utilities
├── apps/
│   ├── axiopass-wallet/   ← wallet UI app
│   └── axq-governance-ui/ ← DAO / governance / voting UI
├── smart-contracts/       ← Solidity, Foundry, on-chain logic
├── core-nodes/            ← RPC, validator, sequencer
├── swift-server/          ← SWIFT enterprise integration
└── docs/                  ← architecture + contributor docs
```

**Namespace overview:**

| Namespace | Scope |
|-----------|-------|
| `@axioledger/*` | Core UI, wallet, SDK |
| `@veraciphers/*` | Cryptographic utilities |
| `@kinetoprotocol/*` | Protocol-layer packages |
| `@valiprecision/*` | Validation and precision utilities |

---

## Setup

```bash
# Clone the repo
git clone https://github.com/axioledger/axioledger-monorepo.git
cd axioledger-monorepo

# Install dependencies (pnpm required)
pnpm install

# Build the design system
pnpm --filter @axioledger/axio-design-system build

# Run tests for a specific package
pnpm --filter @axioledger/dom test
```

**Requirements:**
- Node.js ≥ 18
- pnpm ≥ 8
- git

---

## Contribution Rules

1. **Keep PRs small and focused.** One problem, one solution, one PR.
2. **Do not refactor unrelated code.** Stay within the scope of your change.
3. **Follow existing style and conventions.** Do not introduce new patterns without discussion.
4. **Write tests for new behavior.** Every behavioral change needs a test.
5. **Update docs when behavior changes.** If you change an API, update the README.
6. **Do not add new dependencies** without maintainer approval.
7. **Security-sensitive changes require additional review.** Anything touching TLP, auth, passkey, wallet storage, or cryptographic logic must be flagged in the PR.

---

## PR Workflow

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes.** Follow the contribution rules above.

3. **Validate your change** before opening a PR:
   ```bash
   pnpm --filter <your-package> build
   pnpm --filter <your-package> test
   pnpm --filter <your-package> lint
   pnpm --filter <your-package> typecheck
   ```

4. **Open a PR** against the `main` branch using the [PR template](.github/PULL_REQUEST_TEMPLATE.md).

5. **Respond to review feedback** promptly and keep the PR updated.

---

## Commit Convention

Use conventional commits:

```
<type>(<scope>): <short description>

[optional body]
```

**Types:**

| Type | Use for |
|------|---------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `chore` | Tooling, CI, maintenance |
| `test` | Adding or fixing tests |
| `refactor` | Code change without behavior change |
| `style` | Formatting, whitespace |
| `perf` | Performance improvement |
| `security` | Security hardening |

**Examples:**
```
feat(packages/dom): add safe focus lifecycle helpers
fix(design-system): remove hardcoded hex in Button component
docs(packages/events): add keyboard subscription usage examples
chore(ci): add changed-package detection to PR workflow
```

---

## Validation

Before a PR can merge, the following must pass for the changed package:

```bash
pnpm --filter <package> build
pnpm --filter <package> test
pnpm --filter <package> lint
pnpm --filter <package> typecheck
```

For `design-system` changes, also run:

```bash
pnpm --filter @axioledger/axio-design-system run build:tokens:check
```

Do not submit a PR if validation fails. Report the failure honestly in the PR description.

---

## Security

- **Do not commit secrets, API keys, or credentials.**
- **Do not open public issues for critical vulnerabilities.** See [SECURITY.md](SECURITY.md).
- Security-relevant components (`SecurityAlert`, `resolveTLP`, `NamespaceBadge`, wallet auth, passkey, PIN) require maintainer review before merge.
- All changes to cryptographic or access-control logic must include a threat model note in the PR.

---

## First PR Path

The fastest way to open a useful first PR:

| Day | Action |
|-----|--------|
| 1–2 | Read `design-system/README.md` + the README of one package |
| 3 | Pick one specific problem: export bug, missing test, incomplete docs, hardcoded hex |
| 4–5 | Write the fix + test + docs update |
| 6 | Open a draft PR to get early feedback |
| 7 | Address feedback and mark ready for review |

**Good first issues:**
- Fix an export gap in `design-system`
- Add a test for a component state
- Improve a package README example
- Add missing design token docs
- Add a missing event subscription example

---

## Questions?

Open a [documentation issue](.github/ISSUE_TEMPLATE/docs.md) or start a discussion in the repo.
