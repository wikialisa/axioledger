#!/usr/bin/env bash
# AXIOLEDGER — Workflow 6: Kích hoạt GitHub Actions xuyên 5 orgs
# Usage: ./w6-trigger-actions.sh <repo> <workflow.yml> [branch] [inputs-json]

source "$(dirname "$0")/bootstrap.sh"

REPO_NAME="${1:?Usage: ./w6-trigger-actions.sh <repo> <workflow.yml>}"
WORKFLOW_FILE="${2:-"deploy.yml"}"
BRANCH="${3:-"main"}"
INPUTS="${4:-"{}"}"

echo ""; echo "════════════════════════════════════════════════════════════════"
echo "  WORKFLOW 6 — TRIGGER ACTIONS: $WORKFLOW_FILE @ $BRANCH"
echo "════════════════════════════════════════════════════════════════"
check_token

for ORG in "${ORGS[@]}"; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$GH_API/repos/$ORG/$REPO_NAME/actions/workflows/$WORKFLOW_FILE/dispatches" \
    -H "Authorization: Bearer $GITHUB_KEY" -H "Accept: $GH_ACCEPT" -H "Content-Type: application/json" \
    -d "{\"ref\":\"$BRANCH\",\"inputs\":$INPUTS}")
  [[ "$HTTP" == "204" ]] \
    && log_ok "[$ORG] Triggered (HTTP $HTTP)" \
    || log_err "[$ORG] FAILED (HTTP $HTTP)"
done

echo ""; echo "  [DONE] Actions triggered xuyên 5 tổ chức"
echo "════════════════════════════════════════════════════════════════"
