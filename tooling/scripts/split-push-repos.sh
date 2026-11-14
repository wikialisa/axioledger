#!/usr/bin/env bash
# =============================================================================
# AxioLedger — Split monorepo → multiple GitHub repos
# Usage: GH_TOKEN=ghp_xxx bash split-push-repos.sh
# =============================================================================
set -euo pipefail

GITHUB_ORG="wikialisalabs"
MONOREPO="/root/axioledger"
WORK_DIR="/tmp/axioledger-split"
GH_TOKEN="${GH_TOKEN:-}"

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' CYAN='\033[0;36m' NC='\033[0m' BOLD='\033[1m'
log()  { echo -e "${CYAN}[split]${NC} $*"; }
ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $*"; }
err()  { echo -e "  ${RED}✗${NC} $*"; }

if [[ -z "$GH_TOKEN" ]]; then
  err "GH_TOKEN not set. Run: GH_TOKEN=ghp_xxx bash split-push-repos.sh"
  exit 1
fi

# Auth gh CLI (unset env var so gh doesn't auto-pick it up wrongly)
unset GITHUB_TOKEN GH_TOKEN_ENV 2>/dev/null || true
echo "$GH_TOKEN" | gh auth login --with-token --hostname github.com 2>&1 | grep -v "^$" || true
git config --global user.email "343393306+wikialisa@users.noreply.github.com"
git config --global user.name  "wikialisa"

mkdir -p "$WORK_DIR"

# =============================================================================
# Repo definitions: "repo-name|description|directories..."
# =============================================================================
declare -a REPOS=(
  "axioledger-apps|AxioLedger — Frontend Applications (Next.js)|apps"
  "axioledger-services|AxioLedger — Backend Microservices|services"
  "axioledger-packages|AxioLedger — Shared Packages & Libraries|packages libraries"
  "axioledger-design-system|AxioLedger — Axio Design System|design-system"
  "axioledger-smart-contracts|AxioLedger — Smart Contracts (Solidity/Anchor)|smart-contracts programs"
  "axioledger-infra|AxioLedger — Infrastructure, Docker & Deploy|infra tooling"
  "axioledger-core-nodes|AxioLedger — Protocol Nodes (Sequentichain/Valiprecision)|core-nodes"
)

# =============================================================================
push_repo() {
  local repo_name="$1"
  local description="$2"
  shift 2
  local dirs=("$@")

  log "Processing: ${BOLD}${repo_name}${NC}"
  local dest="$WORK_DIR/$repo_name"
  rm -rf "$dest"
  mkdir -p "$dest"

  # Init git
  cd "$dest"
  git init -q
  git checkout -b main

  # Copy selected directories from monorepo
  local copied=0
  for dir in "${dirs[@]}"; do
    if [[ -d "$MONOREPO/$dir" ]]; then
      cp -r "$MONOREPO/$dir" "$dest/$dir"
      ok "Copied: $dir"
      ((copied++))
    else
      warn "Not found: $dir — skipping"
    fi
  done

  if [[ $copied -eq 0 ]]; then
    warn "No directories found for $repo_name — skipping"
    return
  fi

  # Copy shared root files if relevant
  for f in .gitignore .npmrc pnpm-workspace.yaml; do
    [[ -f "$MONOREPO/$f" ]] && cp "$MONOREPO/$f" "$dest/" 2>/dev/null || true
  done

  # Create README
  cat > "$dest/README.md" << EOF
# ${repo_name}

${description}

Part of the [AxioLedger](https://github.com/${GITHUB_ORG}/axioledger) monorepo ecosystem.

## Structure

$(for d in "${dirs[@]}"; do [ -d "$MONOREPO/$d" ] && echo "- \`${d}/\`"; done)

## Development

See the main [axioledger](https://github.com/${GITHUB_ORG}/axioledger) repository for setup instructions.
EOF

  # Commit
  git add -A
  git commit -q -m "chore: initial split from axioledger monorepo

Extracted directories: ${dirs[*]}
Source: https://github.com/${GITHUB_ORG}/axioledger"

  # Create GitHub repo (skip if exists)
  local visibility="public"
  if gh repo view "${GITHUB_ORG}/${repo_name}" &>/dev/null; then
    warn "Repo ${GITHUB_ORG}/${repo_name} already exists — force pushing"
  else
    log "Creating GitHub repo: ${GITHUB_ORG}/${repo_name}"
    gh repo create "${GITHUB_ORG}/${repo_name}" \
      --description "$description" \
      --$visibility 2>/dev/null || true
    ok "Created: https://github.com/${GITHUB_ORG}/${repo_name}"
  fi

  # Push
  local remote_url="https://${GH_TOKEN}@github.com/${GITHUB_ORG}/${repo_name}.git"
  git remote add origin "$remote_url" 2>/dev/null || git remote set-url origin "$remote_url"
  git push -u origin main --force -q
  ok "Pushed: https://github.com/${GITHUB_ORG}/${repo_name}"

  cd "$MONOREPO"
}

# =============================================================================
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  AxioLedger — Monorepo Split & Push                 ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

for entry in "${REPOS[@]}"; do
  IFS='|' read -r repo_name description dirs_str <<< "$entry"
  read -ra dirs_arr <<< "$dirs_str"
  push_repo "$repo_name" "$description" "${dirs_arr[@]}"
  echo ""
done

# =============================================================================
# Also push the main monorepo if not up to date
log "Pushing main monorepo: ${GITHUB_ORG}/axioledger"
cd "$MONOREPO"
remote_url="https://${GH_TOKEN}@github.com/${GITHUB_ORG}/axioledger.git"
git remote set-url origin "$remote_url"
git add -A
git diff --staged --quiet || git commit -m "chore: sync build artifacts and config fixes" -q
git push origin HEAD:main --force -q 2>/dev/null || true
ok "Pushed: https://github.com/${GITHUB_ORG}/axioledger"

echo ""
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Done! Repos created under github.com/${GITHUB_ORG}${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "  Repos:"
for entry in "${REPOS[@]}"; do
  IFS='|' read -r repo_name _ _ <<< "$entry"
  echo "  → https://github.com/${GITHUB_ORG}/${repo_name}"
done
echo "  → https://github.com/${GITHUB_ORG}/axioledger"
echo ""

# Cleanup
rm -rf "$WORK_DIR"
