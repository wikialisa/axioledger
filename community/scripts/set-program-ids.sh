#!/usr/bin/env bash
# set-program-ids.sh — Export PROGRAM_ID_* env vars for anchor build
#
# Usage:
#   source scripts/set-program-ids.sh [devnet|mainnet]
#   anchor build
#
# The program IDs are read from programs/program-ids.config.json
# Fill in that file after your first `anchor deploy`.

set -euo pipefail

NETWORK="${1:-devnet}"
CONFIG="$(dirname "$0")/../programs/program-ids.config.json"

if [ ! -f "$CONFIG" ]; then
  echo "ERROR: $CONFIG not found" >&2
  exit 1
fi

export_id() {
  local key="$1"
  local val
  val=$(python3 -c "
import json, sys
d = json.load(open('$CONFIG'))
print(d['solana']['$NETWORK'].get('$key', '11111111111111111111111111111111'))
")
  export "$key"="$val"
  echo "  $key=$val"
}

echo "Setting Solana program IDs for network: $NETWORK"
export_id PROGRAM_ID_P2P_ESCROW
export_id PROGRAM_ID_MINT_GOVERNANCE
export_id PROGRAM_ID_AMM_SWAP
export_id PROGRAM_ID_TREASURY_RBS
export_id PROGRAM_ID_SWIFT_BRIDGE
echo "Done — run: anchor build"
