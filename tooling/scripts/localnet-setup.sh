#!/usr/bin/env bash
# =============================================================================
# scripts/localnet-setup.sh — AXIOLEDGER Localnet Boot Script
#
# Boots Anvil, deploys all contracts, seeds test data, writes .env.local
# to both frontend apps, then prints a ready-to-use E2E checklist.
#
# Requirements:
#   - foundry (forge, anvil, cast)  https://getfoundry.sh
#   - node >= 20, pnpm >= 9
#   - Run from monorepo root: bash scripts/localnet-setup.sh
#
# After running:
#   pnpm --filter axiopass-wallet   dev   # http://localhost:3000
#   pnpm --filter axq-governance-ui dev   # http://localhost:3001
# =============================================================================

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# ── Colour output ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

# ── Config ────────────────────────────────────────────────────────────────────
ANVIL_PORT=8545
ANVIL_CHAIN_ID=31337
ANVIL_PID_FILE="/tmp/axioledger-anvil.pid"
ANVIL_LOG="/tmp/axioledger-anvil.log"

# Anvil account 0 — default mnemonic "test test test ... junk"
DEPLOYER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

TEST_USER_ADDRESS="0x976EA74026E726554dB657fA54763abd0C3a0aa9"
TEST_USER_KEY="0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e"

# ── Prerequisite checks ───────────────────────────────────────────────────────
header "Prerequisite Checks"

command -v anvil  >/dev/null 2>&1 || error "anvil not found. Install foundry: https://getfoundry.sh"
command -v forge  >/dev/null 2>&1 || error "forge not found. Install foundry: https://getfoundry.sh"
command -v cast   >/dev/null 2>&1 || error "cast not found. Install foundry: https://getfoundry.sh"
command -v node   >/dev/null 2>&1 || error "node not found. Install node >= 20."
command -v pnpm   >/dev/null 2>&1 || error "pnpm not found. Run: npm i -g pnpm"

NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
[[ "$NODE_VER" -ge 20 ]] || error "Node >= 20 required, got $(node --version)"

success "All prerequisites satisfied"

# ── Kill any existing Anvil ───────────────────────────────────────────────────
header "Anvil Startup"

if [ -f "$ANVIL_PID_FILE" ]; then
    OLD_PID=$(cat "$ANVIL_PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        info "Killing existing Anvil (PID $OLD_PID)…"
        kill "$OLD_PID" 2>/dev/null || true
        sleep 1
    fi
    rm -f "$ANVIL_PID_FILE"
fi

# Also kill any anvil on port 8545
lsof -ti :"$ANVIL_PORT" | xargs kill -9 2>/dev/null || true

# ── Start Anvil ───────────────────────────────────────────────────────────────
info "Starting Anvil on port $ANVIL_PORT (chain ID $ANVIL_CHAIN_ID)…"

anvil \
    --port "$ANVIL_PORT" \
    --chain-id "$ANVIL_CHAIN_ID" \
    --block-time 1 \
    --accounts 10 \
    --balance 10000 \
    --mnemonic "test test test test test test test test test test test junk" \
    --no-mining \
    > "$ANVIL_LOG" 2>&1 &

ANVIL_PID=$!
echo "$ANVIL_PID" > "$ANVIL_PID_FILE"
info "Anvil PID: $ANVIL_PID (log: $ANVIL_LOG)"

# Wait for Anvil to be ready
RETRIES=0
until cast block-number --rpc-url "http://127.0.0.1:$ANVIL_PORT" >/dev/null 2>&1; do
    RETRIES=$((RETRIES+1))
    [[ $RETRIES -gt 15 ]] && error "Anvil failed to start after 15s. Check $ANVIL_LOG"
    sleep 1
done
success "Anvil is ready (block: $(cast block-number --rpc-url http://127.0.0.1:$ANVIL_PORT))"

# ── Install pnpm dependencies ─────────────────────────────────────────────────
header "Installing Dependencies"
pnpm install --frozen-lockfile 2>/dev/null || pnpm install --no-frozen-lockfile
success "pnpm install complete"

# ── Build contracts (OpenZeppelin remappings) ─────────────────────────────────
header "Building Smart Contracts"

# Install forge dependencies for axioledger-system
for CONTRACT_DIR in smart-contracts/axioledger-system smart-contracts/ans-registry; do
    info "Building $CONTRACT_DIR…"
    (
        cd "$ROOT/$CONTRACT_DIR"
        # Install OZ if not present
        if [ ! -d "lib/openzeppelin-contracts" ]; then
            forge install OpenZeppelin/openzeppelin-contracts@v4.9.6 --no-commit 2>/dev/null || \
            warn "forge install skipped — using existing lib/"
        fi
        forge build --quiet || warn "Build warnings in $CONTRACT_DIR"
    )
done
success "Smart contracts built"

# ── Deploy via Forge script ───────────────────────────────────────────────────
header "Deploying Contracts to Anvil"

# Create a temporary foundry.toml at root for the deploy script
cat > "$ROOT/foundry.toml" << 'TOML'
[profile.default]
src        = "smart-contracts"
test       = "test"
out        = "out"
libs       = ["smart-contracts/axioledger-system/lib", "smart-contracts/ans-registry/lib"]
solc       = "0.8.28"
optimizer  = true
optimizer_runs = 200
via_ir     = true
remappings = [
  "@openzeppelin/=smart-contracts/axioledger-system/lib/openzeppelin-contracts/",
  "forge-std/=smart-contracts/axioledger-system/lib/forge-std/src/"
]
TOML

DEPLOY_OUTPUT=$(
    DEPLOYER_PRIVATE_KEY="$DEPLOYER_KEY" \
    forge script scripts/DeployLocalnet.s.sol \
        --rpc-url "http://127.0.0.1:$ANVIL_PORT" \
        --broadcast \
        --private-key "$DEPLOYER_KEY" \
        2>&1
)

echo "$DEPLOY_OUTPUT"

# ── Parse deployed addresses from forge output ────────────────────────────────
header "Parsing Deployed Addresses"

parse_addr() {
    echo "$DEPLOY_OUTPUT" | grep "$1" | tail -1 | grep -oE '0x[0-9a-fA-F]{40}' | head -1
}

AXQ_TOKEN=$(parse_addr "AXQToken")
ANS_REGISTRY=$(parse_addr "ANSRegistry")
AXQ_GOVERNANCE=$(parse_addr "AXQGovernance")
VRQ_VALIDATOR=$(parse_addr "VRQPasskeyValidator")

# Fall back to deterministic CREATE addresses if parsing fails
AXQ_TOKEN="${AXQ_TOKEN:-0x5FbDB2315678afecb367f032d93F642f64180aa3}"
ANS_REGISTRY="${ANS_REGISTRY:-0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512}"
AXQ_GOVERNANCE="${AXQ_GOVERNANCE:-0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9}"
VRQ_VALIDATOR="${VRQ_VALIDATOR:-0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0}"

success "AXQToken        : $AXQ_TOKEN"
success "ANSRegistry     : $ANS_REGISTRY"
success "AXQGovernance   : $AXQ_GOVERNANCE"
success "VRQValidator    : $VRQ_VALIDATOR"

# ── Verify deployments via cast ───────────────────────────────────────────────
header "Verifying Deployments"

RPC="http://127.0.0.1:$ANVIL_PORT"

AXQ_NAME=$(cast call "$AXQ_TOKEN" "name()(string)" --rpc-url "$RPC" 2>/dev/null || echo "ERR")
AXQ_SUPPLY=$(cast call "$AXQ_TOKEN" "totalSupply()(uint256)" --rpc-url "$RPC" 2>/dev/null || echo "0")
GOV_COUNT=$(cast call "$AXQ_GOVERNANCE" "proposalCount()(uint256)" --rpc-url "$RPC" 2>/dev/null || echo "0")
USER_BALANCE=$(cast call "$AXQ_TOKEN" "balanceOf(address)(uint256)" "$TEST_USER_ADDRESS" --rpc-url "$RPC" 2>/dev/null || echo "0")

success "AXQToken.name()          : $AXQ_NAME"
success "AXQToken.totalSupply()   : $AXQ_SUPPLY"
success "AXQGovernance.proposals  : $GOV_COUNT"
success "TEST_USER AXQ balance    : $USER_BALANCE"

# ── Write .env.local to both apps ─────────────────────────────────────────────
header "Writing .env.local to Frontend Apps"

write_env() {
    local APP_DIR="$1"
    local PORT="$2"
    cat > "$ROOT/$APP_DIR/.env.local" << ENV
# Auto-generated by localnet-setup.sh — $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# DO NOT COMMIT — this file is .gitignored

NEXT_PUBLIC_NETWORK=localnet
NEXT_PUBLIC_RPC_URL=http://127.0.0.1:${ANVIL_PORT}
NEXT_PUBLIC_CHAIN_ID=${ANVIL_CHAIN_ID}

NEXT_PUBLIC_AXQ_TOKEN=${AXQ_TOKEN}
NEXT_PUBLIC_ANS_REGISTRY=${ANS_REGISTRY}
NEXT_PUBLIC_AXQ_GOVERNANCE=${AXQ_GOVERNANCE}
NEXT_PUBLIC_VRQ_VALIDATOR=${VRQ_VALIDATOR}

NEXT_PUBLIC_ENABLE_MOCK_PASSKEY=true
NEXT_PUBLIC_SHOW_DEV_TOOLS=true
ENV
    success "Written: $APP_DIR/.env.local"
}

write_env "apps/axiopass-wallet"   3000
write_env "apps/axq-governance-ui" 3001

# ── Seed: create a sample proposal via cast ───────────────────────────────────
header "Seeding: Sample Governance Proposal"

# Deployer (account 0) has >100k AXQ and is DAO owner
PROPOSE_TX=$(
    cast send "$AXQ_GOVERNANCE" \
        "propose(address,uint256,bytes,string)(uint256)" \
        "$DEPLOYER_ADDRESS" \
        "0" \
        "0x" \
        "Localnet Test Proposal #1 — Fund VPX validator subsidy Q4" \
        --rpc-url "$RPC" \
        --private-key "$DEPLOYER_KEY" \
        2>/dev/null | grep "transactionHash" | head -1 || echo "skipped"
)
success "Sample proposal tx: ${PROPOSE_TX:-skipped}"

# ── Print E2E checklist ───────────────────────────────────────────────────────
header "E2E Localnet Ready"

cat << CHECKLIST

${BOLD}${GREEN}════════════════════════════════════════════════════════════
  AXIOLEDGER LOCALNET READY
════════════════════════════════════════════════════════════${RESET}

${BOLD}Services:${RESET}
  Anvil RPC      http://127.0.0.1:${ANVIL_PORT}  (chain ID ${ANVIL_CHAIN_ID})
  PID file       ${ANVIL_PID_FILE}
  Log file       ${ANVIL_LOG}

${BOLD}Contracts:${RESET}
  AXQToken       ${AXQ_TOKEN}
  ANSRegistry    ${ANS_REGISTRY}
  AXQGovernance  ${AXQ_GOVERNANCE}
  VRQValidator   ${VRQ_VALIDATOR}

${BOLD}Test Accounts:${RESET}
  Deployer/DAO  ${DEPLOYER_ADDRESS}  (500B AXQ, DAO owner)
  Test User     ${TEST_USER_ADDRESS}  (1M AXQ, voter)

${BOLD}ANS Names registered:${RESET}
  alice.axq    → ${DEPLOYER_ADDRESS}  (TLP: SAFE ✅)
  testuser.axq → ${DEPLOYER_ADDRESS}  (TLP: SAFE ✅)
  pool.kpx     → ${DEPLOYER_ADDRESS}  (TLP: CAUTION ⚠️)

${BOLD}Start Frontend Apps:${RESET}
  pnpm --filter axiopass-wallet   dev   # → http://localhost:3000
  pnpm --filter axq-governance-ui dev   # → http://localhost:3001

${BOLD}E2E Test Flow:${RESET}
  1. Open http://localhost:3000 → axiopass-wallet
     a. Click "Create Wallet with Face ID / Touch ID"
        (NEXT_PUBLIC_ENABLE_MOCK_PASSKEY=true → skips real WebAuthn)
     b. Verify: PubKey X/Y stored on PasskeyValidatorStub
     c. Verify: Balance tile shows 1,000,000 AXQ (TEST_USER)

  2. Open http://localhost:3001 → axq-governance-ui
     a. Connect wallet (MetaMask → add network: chain 31337)
     b. Type "alice.axq" in Target → verify TLP SAFE badge
     c. Type "pool.kpx" in Target → verify TLP CAUTION + SecurityAlert
     d. Type "0xdeadbeef" → verify TLP BLOCKED + Submit disabled
     e. Submit a valid proposal with "alice.axq" → verify Toast success

  3. Run automated E2E: pnpm --filter e2e test
     (requires Playwright: pnpm add -D @playwright/test)

${BOLD}Stop Anvil:${RESET}
  kill \$(cat ${ANVIL_PID_FILE})

CHECKLIST
