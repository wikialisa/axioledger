# Contributing from the Wikialisa Fork

> **Scope:** This guide explains how to work within the `wikialisa/axioledger` fork
> and open Pull Requests back to the upstream `axioledger/axioledger` repository.

---

## Overview

```
axioledger/axioledger  ←── Pull Request ───  wikialisa/axioledger
       (upstream)                                    (fork)
```

Changes developed in the fork can be contributed upstream via a Pull Request.
The `apps/website/` workspace is maintained by the fork and is also a candidate
for upstreaming once it has been reviewed.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Node.js | ≥ 20.0.0 |
| pnpm | ≥ 9.0.0 (see `packageManager` in `package.json`) |
| Git | any recent version |

```bash
# Install pnpm if not already available
npm install -g pnpm@9
```

---

## Local Development

### 1 — Clone the fork

```bash
git clone https://github.com/wikialisa/axioledger.git
cd axioledger
```

### 2 — Add the upstream remote

```bash
git remote add upstream https://github.com/axioledger/axioledger.git
git fetch upstream
```

Verify remotes:

```bash
git remote -v
# origin    https://github.com/wikialisa/axioledger.git (fetch)
# origin    https://github.com/wikialisa/axioledger.git (push)
# upstream  https://github.com/axioledger/axioledger.git (fetch)
# upstream  https://github.com/axioledger/axioledger.git (push)
```

### 3 — Install dependencies

```bash
pnpm install
```

> **Note on private packages:** The monorepo references `@veraciphers/*` and
> `@axioledger/*` packages hosted on GitHub Packages. If you do not have a
> GitHub PAT with `read:packages` scope, install only the website workspace:
>
> ```bash
> pnpm install --filter axioledger-website
> ```

### 4 — Run the website locally

```bash
pnpm --filter axioledger-website dev
# → http://localhost:3010
```

The dev server runs with `basePath = ''` (no path prefix), which is fine for local use.
The static export with `/axioledger` basePath is only needed for GitHub Pages deployment.

### 5 — Build static export (optional local check)

```bash
NEXT_PUBLIC_BASE_PATH=/axioledger pnpm --filter axioledger-website build
# Output: apps/website/out/
```

Serve it locally:

```bash
npx serve apps/website/out
# → http://localhost:3000/axioledger/
```

---

## Branching Strategy

Follow the upstream convention (from `CONTRIBUTING.md`):

| Branch pattern | Purpose |
|---------------|---------|
| `feat/website-*` | New website features or sections |
| `fix/website-*` | Bug fixes for the website |
| `chore/website-*` | Non-functional updates (deps, config) |
| `docs/*` | Documentation-only changes |

```bash
# Create a new feature branch from the latest upstream main
git fetch upstream
git checkout -b feat/website-ecosystem-section upstream/main
```

---

## Commit Convention

Follows [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(website): add ecosystem section with pillar cards
fix(website): correct basePath for production build
chore(website): upgrade next to 15.2.0
docs(website): add contributing guide for fork
```

Scope `website` is recommended for all changes in `apps/website/`.

---

## Keeping the Fork Up to Date

Before opening a PR, sync your fork with upstream:

```bash
git fetch upstream
git checkout main
git merge upstream/main        # or: git rebase upstream/main
git push origin main
```

If your feature branch has diverged:

```bash
git checkout feat/website-my-change
git rebase upstream/main
# resolve conflicts if any
git push origin feat/website-my-change --force-with-lease
```

---

## Opening a Pull Request to Upstream

1. Push your branch to the fork:

   ```bash
   git push origin feat/website-my-change
   ```

2. Go to **https://github.com/wikialisa/axioledger** on GitHub.

3. Click **"Contribute" → "Open pull request"** — GitHub will automatically
   suggest opening a PR against `axioledger/axioledger:main`.

4. Fill in the PR template:
   - **Title**: `feat(website): <short description>`
   - **Description**: explain what changed and why; link related issues
   - **Checklist**: confirm CI passes, no secrets added, no unverified claims

5. The upstream repository requires **1 approving review** (2 for smart contracts).
   All CI checks must be green before merge.

---

## Enabling GitHub Pages for the Fork

To preview the website at `https://wikialisa.github.io/axioledger/`:

1. Go to **https://github.com/wikialisa/axioledger/settings/pages**
2. Under **Source**, select **GitHub Actions**
3. Push any change to `apps/website/**` on `main`, or manually trigger
   the workflow at **Actions → "Deploy Website to GitHub Pages" → Run workflow**

The workflow file is at [`.github/workflows/pages-website.yml`](./.github/workflows/pages-website.yml).

> **Important:** `https://wikialisa.github.io/axioledger/` is the correct URL
> for this fork's GitHub Pages. Publishing at `axioledger.github.io` requires
> direct access to the `axioledger` GitHub organisation's Pages configuration
> and a repository named `axioledger.github.io` — this cannot be done from a fork.

---

## What Belongs in the Fork vs Upstream

| Change type | Fork only | Upstream PR |
|------------|-----------|-------------|
| Fork-specific fork notice in footer | ✅ | ❌ |
| Website content improvements | ✅ draft | ✅ when ready |
| New documentation pages | ✅ draft | ✅ when ready |
| Core protocol code | ❌ do not modify | ✅ only |
| Smart contract changes | ❌ do not modify | ✅ with extra review |
| Secrets / credentials | ❌ never | ❌ never |

---

## Questions

Open an issue on the fork: **https://github.com/wikialisa/axioledger/issues**

For upstream questions, use: **https://github.com/axioledger/axioledger/issues**
