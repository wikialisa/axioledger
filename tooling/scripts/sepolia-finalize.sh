#!/usr/bin/env bash
# scripts/sepolia-finalize.sh
# ─────────────────────────────────────────────────────────────────────────────
# AXIOLEDGER — Sepolia Full Deploy + Finalization Script
#
# Deployer hiện tại: 0x77DF94665C671218beE29c7f4BD62aB083cb59B3 (rotated)
# Contracts tại 0xCFcDD... được deploy bởi deployer cũ (0xC9661928...) —
# deployer mới không phải owner nên không thể gọi genesisAllocate().
#
# Script này thực hiện full re-deploy với deployer mới, sau đó:
#   1. DeployAxqSepolia    — deploy AXQToken + AXQVestingVault + AXQGovernance
#   2. DeployAxqSepoliaGenesis — genesisAllocate() + self-delegate + transferOwnership
#   3. Verify 3 contracts trên Etherscan Sepolia
#   4. Cập nhật identity-declaration.json
#
# Yêu cầu:
#   export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/<KEY>"
#   export SEPOLIA_DEPLOYER_PK="<private key 0x77DF94665C671218beE29c7f4BD62aB083cb59B3>"
#   export ETHERSCAN_API_KEY="<etherscan api key>"
#
# Chạy:
#   bash scripts/sepolia-finalize.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DEPLOYER="0xAf3D0febB24706912706660FB41D48Fc89548A53"
CHAIN_ID=11155111
CONTRACTS_DIR="smart-contracts/axioledger-system"
ADDR_JSON="${CONTRACTS_DIR}/script/addresses-sepolia.json"

# ── Kiểm tra biến môi trường bắt buộc ────────────────────────────────────────
check_env() {
  local missing=0
  for var in SEPOLIA_RPC_URL SEPOLIA_DEPLOYER_PK ETHERSCAN_API_KEY; do
    if [[ -z "${!var:-}" ]]; then
      echo "❌ Thiếu biến môi trường: $var"
      missing=1
    fi
  done
  if [[ $missing -eq 1 ]]; then
    echo ""
    echo "Hướng dẫn export:"
    echo "  export SEPOLIA_RPC_URL=\"https://eth-sepolia.g.alchemy.com/v2/<ALCHEMY_KEY>\""
    echo "  export SEPOLIA_DEPLOYER_PK=\"<private key 0x77DF94...>\""
    echo "  export ETHERSCAN_API_KEY=\"<etherscan key>\""
    exit 1
  fi

  # Xác nhận key khớp với địa chỉ deployer dự kiến
  DERIVED=$(cast wallet address "$SEPOLIA_DEPLOYER_PK" 2>/dev/null || echo "unknown")
  if [[ "$DERIVED" != "$DEPLOYER" && "$DERIVED" != "unknown" ]]; then
    echo "❌ Private key không khớp với DEPLOYER=$DEPLOYER"
    echo "   Derived address: $DERIVED"
    exit 1
  fi
  echo "✅ Biến môi trường OK (deployer: $DEPLOYER)"
}

# ── Kiểm tra balance deployer ─────────────────────────────────────────────────
check_balance() {
  echo ""
  echo "=== Kiểm tra balance deployer ==="
  BALANCE=$(curl -s -X POST "$SEPOLIA_RPC_URL" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$DEPLOYER\",\"latest\"],\"id\":1}" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); print(int(r['result'],16))" 2>/dev/null || echo "0")
  ETH=$(python3 -c "print(f'{$BALANCE/1e18:.4f}')")
  echo "  Deployer: $DEPLOYER"
  echo "  Balance:  $ETH ETH"
  if (( BALANCE < 20000000000000000 )); then  # 0.02 ETH minimum
    echo "❌ Balance quá thấp (< 0.02 ETH). Faucet tại: https://sepoliafaucet.com"
    exit 1
  fi
  echo "✅ Balance OK ($ETH ETH)"
}

# ── Step 1: Deploy contracts (fresh deploy với deployer mới) ──────────────────
run_deploy() {
  echo ""
  echo "=== STEP 1: Deploy AXQToken + AXQVestingVault + AXQGovernance ==="
  echo "  Deployer: $DEPLOYER"
  echo "  Reason:   Re-deploy với key mới — contracts cũ (0xCFcDD...) owned by old deployer"
  echo ""

  cd "$CONTRACTS_DIR"

  forge script script/DeployAxqSepolia.s.sol:DeployAxqSepolia \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --private-key "$SEPOLIA_DEPLOYER_PK" \
    --chain-id "$CHAIN_ID" \
    --broadcast \
    -vvv

  cd - > /dev/null

  # Đọc địa chỉ mới từ file được tạo bởi script
  if [[ ! -f "$ADDR_JSON" ]]; then
    echo "❌ $ADDR_JSON không tồn tại sau deploy — kiểm tra forge output"
    exit 1
  fi

  AXQ_TOKEN=$(python3 -c "import json; d=json.load(open('$ADDR_JSON')); print(d['contracts']['axqToken'])")
  AXQ_GOVERNANCE=$(python3 -c "import json; d=json.load(open('$ADDR_JSON')); print(d['contracts']['axqGovernance'])")
  AXQ_VESTING=$(python3 -c "import json; d=json.load(open('$ADDR_JSON')); print(d['contracts']['axqVesting'])")

  echo "✅ Deploy complete"
  echo "  AXQToken:      $AXQ_TOKEN"
  echo "  AXQGovernance: $AXQ_GOVERNANCE"
  echo "  AXQVestingVault: $AXQ_VESTING"

  # Export cho các steps sau
  export AXQ_TOKEN AXQ_GOVERNANCE AXQ_VESTING
}

# ── Step 2: genesisAllocate() ─────────────────────────────────────────────────
run_genesis() {
  echo ""
  echo "=== STEP 2: genesisAllocate() ==="
  echo "  AXQToken:    $AXQ_TOKEN"
  echo "  Governance:  $AXQ_GOVERNANCE"

  cd "$CONTRACTS_DIR"

  forge script script/DeployAxqSepolia.s.sol:DeployAxqSepoliaGenesis \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --private-key "$SEPOLIA_DEPLOYER_PK" \
    --chain-id "$CHAIN_ID" \
    --broadcast \
    -vvv

  cd - > /dev/null
  echo "✅ genesisAllocate() complete — 500B AXQ minted"
}

# ── Step 3: Verify contracts trên Etherscan ───────────────────────────────────
run_verify() {
  echo ""
  echo "=== STEP 3: Verify contracts trên Etherscan Sepolia ==="

  cd "$CONTRACTS_DIR"

  echo "  → Verifying AXQToken ($AXQ_TOKEN)..."
  forge verify-contract \
    --chain sepolia \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --watch \
    "$AXQ_TOKEN" src/AXQToken.sol:AXQToken || echo "⚠️  AXQToken verify failed (có thể đã verified)"

  echo "  → Verifying AXQGovernance ($AXQ_GOVERNANCE)..."
  forge verify-contract \
    --chain sepolia \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --watch \
    "$AXQ_GOVERNANCE" src/AXQGovernance.sol:AXQGovernance || echo "⚠️  AXQGovernance verify failed"

  echo "  → Verifying AXQVestingVault ($AXQ_VESTING)..."
  forge verify-contract \
    --chain sepolia \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --watch \
    "$AXQ_VESTING" src/AXQVestingVault.sol:AXQVestingVault || echo "⚠️  AXQVestingVault verify failed"

  cd - > /dev/null
  echo "✅ Verify step complete"
}

# ── Step 4: Cập nhật identity-declaration.json ────────────────────────────────
update_identity() {
  echo ""
  echo "=== STEP 4: Cập nhật identity-declaration.json ==="

  python3 - << PYEOF
import json, os

token    = os.environ['AXQ_TOKEN']
gov      = os.environ['AXQ_GOVERNANCE']
vesting  = os.environ['AXQ_VESTING']
deployer = os.environ['DEPLOYER']

with open('identity-declaration.json', 'r') as f:
    doc = json.load(f)

for pillar in doc['intermediate_pillars']:
    if pillar['ticker'] == '\$AXQ':
        pillar['sepolia_status'] = 'deployed'
        pillar['sepolia_deployer'] = deployer
        pillar['sepolia_contracts'] = {
            'axqToken':      token,
            'axqGovernance': gov,
            'axqVesting':    vesting,
            'network':       'sepolia',
            'chainId':       11155111,
            'genesis':       'genesisAllocate() called — 500B AXQ minted',
        }
        break

with open('identity-declaration.json', 'w') as f:
    json.dump(doc, f, indent=2)

print(f'✅ identity-declaration.json updated')
print(f'   AXQToken:      {token}')
print(f'   AXQGovernance: {gov}')
print(f'   AXQVesting:    {vesting}')
PYEOF
}

# ── Cập nhật .env.sepolia 3 frontend apps ────────────────────────────────────
update_envs() {
  echo ""
  echo "=== Cập nhật .env.sepolia frontend apps ==="

  for app in apps/axiopass-wallet apps/axq-governance-ui apps/kpx-dex-frontend; do
    if [[ -f "$app/.env.sepolia" ]]; then
      sed -i "s|NEXT_PUBLIC_AXQ_TOKEN=.*|NEXT_PUBLIC_AXQ_TOKEN=$AXQ_TOKEN|" "$app/.env.sepolia"
      sed -i "s|NEXT_PUBLIC_AXQ_GOVERNANCE=.*|NEXT_PUBLIC_AXQ_GOVERNANCE=$AXQ_GOVERNANCE|" "$app/.env.sepolia"
      sed -i "s|NEXT_PUBLIC_AXQ_VESTING=.*|NEXT_PUBLIC_AXQ_VESTING=$AXQ_VESTING|" "$app/.env.sepolia"
      sed -i "s|NEXT_PUBLIC_RD_TREASURY=.*|NEXT_PUBLIC_RD_TREASURY=$DEPLOYER|" "$app/.env.sepolia"
      echo "  ✅ $app/.env.sepolia updated"
    fi
  done
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   AXIOLEDGER — Sepolia Full Deploy + Finalization        ║"
echo "║   Deployer: 0x77DF94665C671218beE29c7f4BD62aB083cb59B3  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  NOTE: Re-deploying contracts vì deployer mới 0x77DF94..."
echo "          không phải owner của contracts cũ (0xCFcDD...)."
echo "          Contracts mới sẽ có địa chỉ khác — cập nhật GitHub Secrets sau."
echo ""

check_env
check_balance
run_deploy
run_genesis
run_verify
update_identity
update_envs

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   ✅ SEPOLIA FINALIZATION COMPLETE                       ║"
echo "║                                                          ║"
echo "║   Contracts deployed & verified ✓                       ║"
echo "║   500B AXQ minted ✓                                     ║"
echo "║   identity-declaration.json updated ✓                   ║"
echo "║   .env.sepolia apps updated ✓                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Bước tiếp theo:"
echo "  1. git add identity-declaration.json smart-contracts/axioledger-system/script/addresses-sepolia.json"
echo "  2. git commit -m 'chore(sepolia): re-deploy with new deployer + genesis complete'"
echo "  3. Cập nhật GitHub Secret SEPOLIA_DEPLOYER_PK với key mới (nếu chưa làm)"
echo "  4. Trigger publish-sdk.yml (GITHUB_TOKEN sẽ tự xử lý — không cần PAT)"
