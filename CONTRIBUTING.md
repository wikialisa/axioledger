# Contributing to AXIOLEDGER

Thank you for contributing. Please read this guide before opening PRs.

## Code of Conduct

All contributors must adhere to our [Code of Conduct](./CODE_OF_CONDUCT.md).

## Development Setup

```bash
# 1. Fork & clone
git clone https://github.com/axioledger/axioledger-monorepo.git
cd axioledger-monorepo

# 2. Install dependencies
pnpm install

# 3. Build
pnpm build

# 4. Test
pnpm test
```

## Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code, protected |
| `feat/*` | New features |
| `fix/*` | Bug fixes |
| `chore/*` | Non-functional changes |
| `release/*` | Release preparation |

## Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(scope): short description
fix(scope): short description
chore(scope): short description
```

GPG signing is **required** for all commits to `main`.

## Pull Request Guidelines

1. Open against `main` from a `feat/` or `fix/` branch
2. All CI checks must pass
3. Requires 1 approving review (2 for `smart-contracts/`)
4. Link relevant GitHub Issues
5. Update `CHANGELOG.md` for user-visible changes

## Licensing

Contributions to `smart-contracts/` and `core-nodes/` fall under BSL-1.1.
Contributions to `packages/` and `apps/` fall under MIT/Apache-2.0.
By submitting a PR you agree to these terms.
