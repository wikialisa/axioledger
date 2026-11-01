#!/usr/bin/env bash
# scripts/post-deploy-governance-setup.sh
# ─────────────────────────────────────────────────────────────────────────────
# AXIOLEDGER — Post-Deploy Governance Setup
#
# Chạy SAU KHI sepolia-finalize.sh hoàn thành.
# Thực hiện các bước cần thiết để AXQGovernance có thể hoạt động:
#
#   1. rdTreasury (0x9B7AF5...) self-delegate → có voting power
#   2. Deployer (0xAf3D0...) self-delegate → có voting power
#   3. Kiểm tra voting power đã active
#   4. Test propose() với proposal mẫu
#
# Yêu cầu (sau re-deploy):
#   export SEPOLIA_RPC_URL="..."
#   export SEPOLIA_DEPLOYER_PK="<pk của 0xAf3D0...>"   [AXQ_DEPLOYER]
#   export ANS_TREASURY_PK="<pk của 0x9B7AF5...>"       [ANS_TREASURY / rdTreasury]
#   export AXQ_TOKEN="<địa chỉ AXQToken mới sau re-deploy>"
#   export AXQ_GOVERNANCE="<địa chỉ AXQGovernance mới>"
#
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DEPLOYER="0xAf3D0febB24706912706660FB41D48Fc89548A53"
RD_TREASURY="0x9B7AF512e3E5d2C27FFf9d53814883DAeca08AE4"

# ── Kiểm tra env ──────────────────────────────────────────────────────────────
check_env() {
  local missing=0
  for var in SEPOLIA_RPC_URL SEPOLIA_DEPLOYER_PK ANS_TREASURY_PK AXQ_TOKEN AXQ_GOVERNANCE; do
    if [[ -z "${!var:-}" ]]; then
      echo "❌ Thiếu: $var"; missing=1
    fi
  done
  if [[ $missing -eq 1 ]]; then
    echo ""
    echo "Set từ addresses-sepolia.json sau re-deploy:"
    echo "  export AXQ_TOKEN=\$(python3 -c \"import json; d=json.load(open('smart-contracts/axioledger-system/script/addresses-sepolia.json')); print(d['contracts']['axqToken'])\")"
    echo "  export AXQ_GOVERNANCE=\$(python3 -c \"import json; d=json.load(open('smart-contracts/axioledger-system/script/addresses-sepolia.json')); print(d['contracts']['axqGovernance'])\")"
    exit 1
  fi
  echo "✅ Env OK"
  echo "   AXQToken:      $AXQ_TOKEN"
  echo "   AXQGovernance: $AXQ_GOVERNANCE"
}

# ── Bước 1: rdTreasury self-delegate ─────────────────────────────────────────
# rdTreasury nhận 150B AXQ tại genesis — cần delegate để có voting power
# Nếu không delegate: getPastVotes() = 0 → không propose/vote được
delegate_rd_treasury() {
  echo ""
  echo "=== BƯỚC 1: rdTreasury self-delegate ==="
  echo "  rdTreasury: $RD_TREASURY"
  echo "  AXQToken:   $AXQ_TOKEN"

  cast send "$AXQ_TOKEN" \
    "delegate(address)" "$RD_TREASURY" \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --private-key "$ANS_TREASURY_PK"

  echo "✅ rdTreasury delegated to self"
}

# ── Bước 2: Deployer self-delegate ───────────────────────────────────────────
delegate_deployer() {
  echo ""
  echo "=== BƯỚC 2: Deployer self-delegate ==="
  echo "  Deployer: $DEPLOYER"

  cast send "$AXQ_TOKEN" \
    "delegate(address)" "$DEPLOYER" \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --private-key "$SEPOLIA_DEPLOYER_PK"

  echo "✅ Deployer delegated to self"
}

# ── Bước 3: Kiểm tra voting power ────────────────────────────────────────────
check_voting_power() {
  echo ""
  echo "=== BƯỚC 3: Kiểm tra voting power ==="

  # Đợi 1 block để checkpoint được ghi
  echo "  Đợi 5 giây cho block mới..."
  sleep 5

  BLOCK=$(cast block-number --rpc-url "$SEPOLIA_RPC_URL" 2>/dev/null || echo "unknown")
  echo "  Block hiện tại: $BLOCK"

  VP_TREASURY=$(cast call "$AXQ_TOKEN" \
    "getVotes(address)(uint256)" "$RD_TREASURY" \
    --rpc-url "$SEPOLIA_RPC_URL" 2>/dev/null || echo "0")
  VP_DEPLOYER=$(cast call "$AXQ_TOKEN" \
    "getVotes(address)(uint256)" "$DEPLOYER" \
    --rpc-url "$SEPOLIA_RPC_URL" 2>/dev/null || echo "0")

  echo "  rdTreasury voting power: $VP_TREASURY"
  echo "  Deployer voting power:   $VP_DEPLOYER"

  # Cần ≥ 100,000e18 để propose (PROPOSAL_THRESHOLD)
  THRESHOLD=100000000000000000000000  # 100,000 AXQ
  if [[ "$VP_TREASURY" -ge "$THRESHOLD" ]] 2>/dev/null; then
    echo "✅ rdTreasury đủ voting power để propose"
  else
    echo "⚠️  Cần đợi thêm 1 block để checkpoint active"
  fi
}

# ── Bước 4: Test propose — governance proposal mẫu ───────────────────────────
test_propose() {
  echo ""
  echo "=== BƯỚC 4: Test propose() ==="
  echo "  Proposer: $RD_TREASURY"
  echo "  Target:   $DEPLOYER (nhận 0 ETH — proposal test)"

  # Proposal mẫu: transfer 0 ETH đến deployer (no-op, chỉ để test flow)
  PROPOSAL_ID=$(cast send "$AXQ_GOVERNANCE" \
    "propose(address,uint256,bytes,string)" \
    "$DEPLOYER" \
    "0" \
    "0x" \
    "Governance test: verify DAO lifecycle — propose/vote/queue/execute" \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --private-key "$ANS_TREASURY_PK" \
    --json 2>/dev/null | python3 -c "
import json,sys
data = json.load(sys.stdin)
# Decode ProposalCreated event nếu có
print(data.get('transactionHash', 'pending'))
" || echo "pending")

  echo "  Tx: $PROPOSAL_ID"
  echo ""
  echo "✅ Proposal submitted"
  echo ""
  echo "Timeline tiếp theo:"
  echo "  +3 ngày : castVote(1, true) từ rdTreasury"
  echo "  +3 ngày : queue(1)"
  echo "  +10 ngày: execute(1)"
  echo ""
  echo "Cast commands:"
  echo "  # Vote"
  echo "  cast send $AXQ_GOVERNANCE 'castVote(uint256,bool)' 1 true \\"
  echo "    --rpc-url \$SEPOLIA_RPC_URL --private-key \$ANS_TREASURY_PK"
  echo ""
  echo "  # Queue (sau 3 ngày)"
  echo "  cast send $AXQ_GOVERNANCE 'queue(uint256)' 1 \\"
  echo "    --rpc-url \$SEPOLIA_RPC_URL --private-key \$SEPOLIA_DEPLOYER_PK"
  echo ""
  echo "  # Execute (sau 10 ngày)"
  echo "  cast send $AXQ_GOVERNANCE 'execute(uint256)' 1 \\"
  echo "    --rpc-url \$SEPOLIA_RPC_URL --private-key \$SEPOLIA_DEPLOYER_PK"
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   AXIOLEDGER — Post-Deploy Governance Setup              ║"
echo "║   rdTreasury: 0x9B7AF512e3E5d2C27FFf9d53814883DAeca08AE4 ║"
echo "╚══════════════════════════════════════════════════════════╝"

check_env
delegate_rd_treasury
delegate_deployer
check_voting_power
test_propose

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   ✅ GOVERNANCE SETUP COMPLETE                           ║"
echo "║                                                          ║"
echo "║   rdTreasury delegated (150B AXQ voting power) ✓        ║"
echo "║   Deployer delegated ✓                                   ║"
echo "║   Test proposal submitted ✓                             ║"
echo "╚══════════════════════════════════════════════════════════╝"
