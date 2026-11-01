#!/usr/bin/env bash
# AXIOLEDGER — Workflow 2: Đồng bộ bản vá bảo mật từ veraciphers → 4 orgs
# Usage: ./w2-security-patch.sh <repo-name> <patch-file> [commit-msg] [target-path] [branch]

source "$(dirname "$0")/bootstrap.sh"

REPO_NAME="${1:?Usage: ./w2-security-patch.sh <repo> <patch-file>}"
PATCH_FILE="${2:?Thiếu patch file}"
COMMIT_MSG="${3:-"fix(security): apply automated patch from VRQ scanner"}"
TARGET_PATH="${4:-"security/patches/$(basename "$PATCH_FILE")"}"
BRANCH="${5:-dev}"

[[ -f "$PATCH_FILE" ]] || { log_err "File không tồn tại: $PATCH_FILE"; exit 1; }
CONTENT_B64=$(base64 -w 0 "$PATCH_FILE")
TARGET_ORGS=("axioledger" "kinetoprotocol" "sequentichain" "valiprecision")

echo ""; echo "════════════════════════════════════════════════════════════════"
echo "  WORKFLOW 2 — SECURITY PATCH: $(basename "$PATCH_FILE")"
echo "  veraciphers → ${TARGET_ORGS[*]}"
echo "════════════════════════════════════════════════════════════════"
check_token

for ORG in "${TARGET_ORGS[@]}"; do
  log_info "[$ORG] Checking $TARGET_PATH @ $BRANCH..."
  FILE_SHA=$(gh_get "repos/$ORG/$REPO_NAME/contents/$TARGET_PATH?ref=$BRANCH" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sha',''))" 2>/dev/null || echo "")

  COMMITTER="{\"name\":\"$GH_COMMITTER_NAME\",\"email\":\"$GH_COMMITTER_EMAIL\"}"
  if [[ -n "$FILE_SHA" ]]; then
    PAYLOAD="{\"message\":\"$COMMIT_MSG\",\"content\":\"$CONTENT_B64\",\"sha\":\"$FILE_SHA\",\"branch\":\"$BRANCH\",\"committer\":$COMMITTER}"
    gh_put "repos/$ORG/$REPO_NAME/contents/$TARGET_PATH" "$PAYLOAD" > /dev/null \
      && log_ok "[$ORG] Updated $TARGET_PATH" || log_err "[$ORG] Update failed"
  else
    PAYLOAD="{\"message\":\"$COMMIT_MSG\",\"content\":\"$CONTENT_B64\",\"branch\":\"$BRANCH\",\"committer\":$COMMITTER}"
    gh_post "repos/$ORG/$REPO_NAME/contents/$TARGET_PATH" "$PAYLOAD" > /dev/null \
      && log_ok "[$ORG] Created $TARGET_PATH" || log_err "[$ORG] Create failed"
  fi
done

echo ""; echo "  [DONE] Patch applied xuyên tổ chức"
echo "════════════════════════════════════════════════════════════════"
