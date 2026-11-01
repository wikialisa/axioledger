#!/usr/bin/env bash
# AXIOLEDGER Automation Core v0.0.0 — Bootstrap
# file: /root/core/github/bootstrap.sh

set -euo pipefail

# Load GITHUB_KEY an toàn (bỏ qua lỗi unbound variable trong .bashrc)
GITHUB_KEY="${GITHUB_KEY:-$(grep -E '^export GITHUB_KEY=' ~/.bashrc | tail -1 | cut -d= -f2- | tr -d "\"'")}"
: "${GITHUB_KEY:?ERROR: GITHUB_KEY chưa được thiết lập trong ~/.bashrc}"

export GH_ACTOR="315885655+davictran76@users.noreply.github.com"
export GH_API="https://api.github.com"
export GH_ACCEPT="application/vnd.github+json"
export GH_COMMITTER_NAME="Axioledger Core Maintainer"
export GH_COMMITTER_EMAIL="315885655+davictran76@users.noreply.github.com"

export ORGS=(
  "axioledger"
  "kinetoprotocol"
  "sequentichain"
  "valiprecision"
  "veraciphers"
)

gh_get()  { curl -sf -H "Authorization: Bearer $GITHUB_KEY" -H "Accept: $GH_ACCEPT" "$GH_API/$1"; }
gh_post() { curl -sf -X POST   -H "Authorization: Bearer $GITHUB_KEY" -H "Accept: $GH_ACCEPT" -H "Content-Type: application/json" "$GH_API/$1" -d "$2"; }
gh_put()  { curl -sf -X PUT    -H "Authorization: Bearer $GITHUB_KEY" -H "Accept: $GH_ACCEPT" -H "Content-Type: application/json" "$GH_API/$1" -d "$2"; }
gh_patch(){ curl -sf -X PATCH  -H "Authorization: Bearer $GITHUB_KEY" -H "Accept: $GH_ACCEPT" -H "Content-Type: application/json" "$GH_API/$1" -d "$2"; }
gh_del()  { curl -sf -X DELETE -H "Authorization: Bearer $GITHUB_KEY" -H "Accept: $GH_ACCEPT" "$GH_API/$1"; }

log_ok()   { echo "  [✓] $*"; }
log_info() { echo "  [→] $*"; }
log_err()  { echo "  [✗] $*" >&2; }

check_token() {
  local user
  user=$(gh_get "user" | python3 -c "import sys,json; print(json.load(sys.stdin)['login'])")
  log_ok "Authenticated as: $user (${GH_ACTOR})"
}
