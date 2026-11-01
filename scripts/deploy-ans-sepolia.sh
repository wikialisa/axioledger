#!/usr/bin/env bash
# scripts/deploy-ans-sepolia.sh
# ─────────────────────────────────────────────────────────────────────────────
# AXIOLEDGER — ANSRegistry Deploy to Sepolia
#
# Deployer:  0xAf3D0febB24706912706660FB41D48Fc89548A53  [AXQ_DEPLOYER]
# Treasury:  0x9B7AF512e3E5d2C27FFf9d53814883DAeca08AE4  [ANS_TREASURY]
# DAO:       0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4  (AXQGovernance Sepolia)
#
# Yêu cầu:
#   export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/<KEY>"
#   export SEPOLIA_DEPLOYER_PK="<private key 0x77DF94...>"
#   export ETHERSCAN_API_KEY="<etherscan key>"
#
# Chạy:
#   bash scripts/deploy-ans-sepolia.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DEPLOYER="0xAf3D0febB24706912706660FB41D48Fc89548A53"
ANS_TREASURY="0x9B7AF512e3E5d2C27FFf9d53814883DAeca08AE4"
ANS_DAO="0xd5aae0234F376f418f8dC80fe5a8Dc6029C360b4"
CHAIN_ID=11155111
ANS_DIR="smart-contracts/ans-registry"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   AXIOLEDGER ANS Registry — Sepolia Deploy               ║"
echo "║   Deployer: $DEPLOYER  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Kiểm tra env
for var in SEPOLIA_RPC_URL SEPOLIA_DEPLOYER_PK ETHERSCAN_API_KEY; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Thiếu biến: $var"; exit 1
  fi
done
echo "✅ Env OK"

# Kiểm tra balance
BALANCE=$(curl -s -X POST "$SEPOLIA_RPC_URL" \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBalance\",\"params\":[\"$DEPLOYER\",\"latest\"],\"id\":1}" \
  | python3 -c "import sys,json; r=json.load(sys.stdin); print(int(r['result'],16))" 2>/dev/null || echo "0")
ETH=$(python3 -c "print(f'{$BALANCE/1e18:.4f}')")
echo "  Balance: $ETH ETH"
if (( BALANCE < 5000000000000000 )); then
  echo "❌ Balance < 0.005 ETH"; exit 1
fi
echo "✅ Balance OK"

# Deploy
echo ""
echo "=== Deploy ANSRegistry ==="
cd "$ANS_DIR"

ANS_TREASURY_ADDRESS="$ANS_TREASURY" \
ANS_DAO_ADDRESS="$ANS_DAO" \
DEPLOYER_PRIVATE_KEY="$SEPOLIA_DEPLOYER_PK" \
forge script script/DeployANSRegistry.s.sol:DeployANSRegistry \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --private-key "$SEPOLIA_DEPLOYER_PK" \
  --chain-id "$CHAIN_ID" \
  --broadcast \
  --verify \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  -vvv

cd - > /dev/null

# Đọc địa chỉ từ file
ANS_ADDR=$(python3 -c "
import json
d = json.load(open('$ANS_DIR/script/ans-addresses.json'))
print(d['contracts']['ansRegistry'])
")

echo ""
echo "✅ ANSRegistry deployed: $ANS_ADDR"

# Cập nhật .env.sepolia apps
for app in apps/axiopass-wallet apps/axq-governance-ui apps/kpx-dex-frontend; do
  if [[ -f "$app/.env.sepolia" ]]; then
    sed -i "s|NEXT_PUBLIC_ANS_REGISTRY=.*|NEXT_PUBLIC_ANS_REGISTRY=$ANS_ADDR|" "$app/.env.sepolia"
    echo "  ✅ $app/.env.sepolia updated"
  fi
done

# Cập nhật identity-declaration.json
export ANS_ADDR
python3 - << 'PYEOF'
import json, os
ans_addr = os.environ['ANS_ADDR']
with open('identity-declaration.json', 'r') as f:
    doc = json.load(f)
for pillar in doc['intermediate_pillars']:
    if pillar['ticker'] == '$AXQ':
        if 'sepolia_contracts' not in pillar:
            pillar['sepolia_contracts'] = {}
        pillar['sepolia_contracts']['ansRegistry'] = ans_addr
        break
with open('identity-declaration.json', 'w') as f:
    json.dump(doc, f, indent=2)
print(f'✅ identity-declaration.json: ansRegistry = {ans_addr}')
PYEOF

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   ✅ ANS Registry Deploy COMPLETE                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Bước tiếp theo:"
echo "  git add smart-contracts/ans-registry/script/ans-addresses.json identity-declaration.json"
echo "  git commit -m 'chore(sepolia): deploy ANSRegistry'"
