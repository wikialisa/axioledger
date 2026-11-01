#!/usr/bin/env bash
# AXIOLEDGER — Workflow 4: Luân chuyển Secrets xuyên 5 orgs
# Usage: ./w4-rotate-secrets.sh <SECRET_NAME> <SECRET_VALUE>
# Requires: pip3 install PyNaCl

source "$(dirname "$0")/bootstrap.sh"

SECRET_NAME="${1:?Usage: ./w4-rotate-secrets.sh <SECRET_NAME> <SECRET_VALUE>}"
SECRET_VALUE="${2:?Thiếu giá trị secret}"

encrypt_secret() {
  python3 - "$1" "$2" <<'PYEOF'
import sys, base64
from nacl import public as nacl_public

pub_b64, secret = sys.argv[1], sys.argv[2]
pub_key = nacl_public.PublicKey(base64.b64decode(pub_b64))
box = nacl_public.SealedBox(pub_key)
print(base64.b64encode(box.encrypt(secret.encode())).decode())
PYEOF
}

echo ""; echo "════════════════════════════════════════════════════════════════"
echo "  WORKFLOW 4 — ROTATE SECRET: $SECRET_NAME"
echo "════════════════════════════════════════════════════════════════"
check_token

for ORG in "${ORGS[@]}"; do
  log_info "[$ORG] Fetching public key..."
  KEY_RESP=$(gh_get "orgs/$ORG/actions/secrets/public-key")
  KEY_ID=$(echo "$KEY_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['key_id'])")
  KEY_VAL=$(echo "$KEY_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['key'])")

  ENCRYPTED=$(encrypt_secret "$KEY_VAL" "$SECRET_VALUE")

  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "$GH_API/orgs/$ORG/actions/secrets/$SECRET_NAME" \
    -H "Authorization: Bearer $GITHUB_KEY" -H "Accept: $GH_ACCEPT" -H "Content-Type: application/json" \
    -d "{\"encrypted_value\":\"$ENCRYPTED\",\"key_id\":\"$KEY_ID\",\"visibility\":\"all\"}")

  [[ "$HTTP" =~ ^(201|204)$ ]] \
    && log_ok "[$ORG] $SECRET_NAME rotated (HTTP $HTTP)" \
    || log_err "[$ORG] Rotate FAILED (HTTP $HTTP)"
done

echo ""; echo "  [DONE] Secret luân chuyển xuyên 5 tổ chức"
echo "════════════════════════════════════════════════════════════════"
