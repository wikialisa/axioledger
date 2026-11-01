#!/usr/bin/env bash
# AXIOLEDGER — Workflow 5: Tạo GitHub Projects v2 xuyên 5 orgs
# Usage: ./w5-projects.sh [project-title]
# API: GitHub GraphQL v4

source "$(dirname "$0")/bootstrap.sh"

PROJECT_TITLE="${1:-"AXIOLEDGER Roadmap v0.0.0"}"
GH_GRAPHQL="https://api.github.com/graphql"

gql() {
  curl -sf -X POST "$GH_GRAPHQL" \
    -H "Authorization: Bearer $GITHUB_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"query\":\"$1\"}"
}

echo ""; echo "════════════════════════════════════════════════════════════════"
echo "  WORKFLOW 5 — GITHUB PROJECTS: $PROJECT_TITLE"
echo "════════════════════════════════════════════════════════════════"
check_token

for ORG in "${ORGS[@]}"; do
  log_info "[$ORG] Getting org ID..."
  ORG_ID=$(gql "query{organization(login:\\\"$ORG\\\"){id}}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['organization']['id'])")

  log_info "[$ORG] Creating project..."
  RESULT=$(gql "mutation{createProjectV2(input:{ownerId:\\\"$ORG_ID\\\",title:\\\"$PROJECT_TITLE\\\"}){projectV2{id url}}}" \
    | python3 -c "import sys,json; p=json.load(sys.stdin)['data']['createProjectV2']['projectV2']; print(p['id']+'|'+p['url'])" 2>/dev/null)

  PROJ_ID=$(echo "$RESULT" | cut -d'|' -f1)
  PROJ_URL=$(echo "$RESULT" | cut -d'|' -f2)
  log_ok "[$ORG] Project → $PROJ_URL"
done

echo ""; echo "  [DONE] Projects created on all 5 orgs"
echo "════════════════════════════════════════════════════════════════"
