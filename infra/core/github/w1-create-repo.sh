#!/usr/bin/env bash
# AXIOLEDGER — Workflow 1: Tạo Repository đồng nhất xuyên 5 tổ chức
# Usage: ./w1-create-repo.sh <repo-name> <description> [public|private]

source "$(dirname "$0")/bootstrap.sh"

REPO_NAME="${1:?Usage: ./w1-create-repo.sh <name> <desc> [public|private]}"
REPO_DESC="${2:-"AXIOLEDGER ecosystem repository"}"
VISIBILITY="${3:-public}"
PRIVATE="false"; [[ "$VISIBILITY" == "private" ]] && PRIVATE="true"

echo ""; echo "════════════════════════════════════════════════════════════════"
echo "  WORKFLOW 1 — TẠO REPO: $REPO_NAME ($VISIBILITY)"
echo "════════════════════════════════════════════════════════════════"
check_token

for ORG in "${ORGS[@]}"; do
  log_info "[$ORG] Tạo $REPO_NAME..."
  RESULT=$(gh_post "orgs/$ORG/repos" \
    "{\"name\":\"$REPO_NAME\",\"description\":\"[$ORG] $REPO_DESC\",\"private\":$PRIVATE,\"auto_init\":true,\"has_issues\":true,\"has_projects\":true,\"has_wiki\":false}" 2>&1) \
    || { log_err "[$ORG] Thất bại (repo có thể đã tồn tại)"; continue; }

  CLONE_URL=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['clone_url'])" 2>/dev/null)
  log_ok "[$ORG] Created → $CLONE_URL"

  sleep 1
  SHA=$(gh_get "repos/$ORG/$REPO_NAME/git/ref/heads/main" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['object']['sha'])")
  for BRANCH in dev ledger master; do
    gh_post "repos/$ORG/$REPO_NAME/git/refs" \
      "{\"ref\":\"refs/heads/$BRANCH\",\"sha\":\"$SHA\"}" > /dev/null 2>&1 \
      && log_ok "[$ORG]   branch/$BRANCH created" \
      || log_err "[$ORG]   branch/$BRANCH failed"
  done
done

echo ""; echo "  [DONE] $REPO_NAME — tồn tại trên cả 5 tổ chức"
echo "════════════════════════════════════════════════════════════════"
