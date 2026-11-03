#!/usr/bin/env bash
# AXIOLEDGER — Workflow 3: Branch protection hàng loạt xuyên 5 orgs
# Usage: ./w3-branch-protection.sh <repo-name>

source "$(dirname "$0")/bootstrap.sh"

REPO_NAME="${1:?Usage: ./w3-branch-protection.sh <repo-name>}"

P_MAIN='{"required_status_checks":null,"enforce_admins":true,"required_pull_request_reviews":{"dismiss_stale_reviews":true,"required_approving_review_count":1},"restrictions":null,"required_linear_history":true,"allow_force_pushes":false,"allow_deletions":false,"required_conversation_resolution":true}'
P_MASTER='{"required_status_checks":null,"enforce_admins":false,"required_pull_request_reviews":{"dismiss_stale_reviews":true,"required_approving_review_count":1},"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}'
P_OPEN='{"required_status_checks":null,"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}'

echo ""; echo "════════════════════════════════════════════════════════════════"
echo "  WORKFLOW 3 — BRANCH PROTECTION: $REPO_NAME"
echo "════════════════════════════════════════════════════════════════"
check_token

for ORG in "${ORGS[@]}"; do
  for BRANCH in main master ledger dev; do
    gh_get "repos/$ORG/$REPO_NAME/branches/$BRANCH" > /dev/null 2>&1 || { log_info "[$ORG] $BRANCH — skip (not found)"; continue; }
    case "$BRANCH" in
      main)   PAYLOAD="$P_MAIN" ;;
      master) PAYLOAD="$P_MASTER" ;;
      *)      PAYLOAD="$P_OPEN" ;;
    esac
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
      -X PUT "$GH_API/repos/$ORG/$REPO_NAME/branches/$BRANCH/protection" \
      -H "Authorization: Bearer $GITHUB_KEY" -H "Accept: $GH_ACCEPT" -H "Content-Type: application/json" \
      -d "$PAYLOAD")
    [[ "$HTTP" == "200" ]] && log_ok "[$ORG] $BRANCH protected" || log_err "[$ORG] $BRANCH FAILED ($HTTP)"
  done
done

echo ""; echo "  [DONE] Branch protection applied"
echo "════════════════════════════════════════════════════════════════"
