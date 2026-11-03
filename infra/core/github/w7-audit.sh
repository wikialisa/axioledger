#!/usr/bin/env bash
# AXIOLEDGER — Workflow 7: Audit Snapshot → JSON
# Usage: ./w7-audit.sh [output-dir]

source "$(dirname "$0")/bootstrap.sh"

OUTPUT_DIR="${1:-/root/logs}"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
REPORT="$OUTPUT_DIR/audit-$TIMESTAMP.json"
mkdir -p "$OUTPUT_DIR"

echo ""; echo "════════════════════════════════════════════════════════════════"
echo "  WORKFLOW 7 — AUDIT SNAPSHOT: $TIMESTAMP"
echo "════════════════════════════════════════════════════════════════"
check_token

GITHUB_KEY="$GITHUB_KEY" GH_ACTOR="$GH_ACTOR" REPORT="$REPORT" TIMESTAMP="$TIMESTAMP" \
python3 - <<'PYEOF'
import json, os, urllib.request

orgs   = ["axioledger","kinetoprotocol","sequentichain","valiprecision","veraciphers"]
token  = os.environ["GITHUB_KEY"]
actor  = os.environ["GH_ACTOR"]
ts     = os.environ["TIMESTAMP"]
report = {"timestamp": ts, "actor": actor, "orgs": {}}

def gh(path):
    req = urllib.request.Request(
        f"https://api.github.com/{path}",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}
    )
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except Exception as e:
        return {"error": str(e)}

for org in orgs:
    print(f"  [→] Scanning {org}...")
    repos   = gh(f"orgs/{org}/repos?per_page=100&type=all")
    members = gh(f"orgs/{org}/members?per_page=100")
    hooks   = gh(f"orgs/{org}/hooks")
    secrets = gh(f"orgs/{org}/actions/secrets")
    report["orgs"][org] = {
        "repos_count":   len(repos)   if isinstance(repos, list)   else "ERR",
        "members_count": len(members) if isinstance(members, list) else "ERR",
        "hooks_count":   len(hooks)   if isinstance(hooks, list)   else "ERR",
        "secrets_names": [s["name"] for s in secrets.get("secrets",[])] if isinstance(secrets,dict) else "ERR",
        "repos": [{"name":r["name"],"private":r["private"],"default_branch":r["default_branch"]} for r in repos] if isinstance(repos,list) else [],
    }
    rc = report["orgs"][org]["repos_count"]
    mc = report["orgs"][org]["members_count"]
    print(f"  [✓] {org}: {rc} repos, {mc} members")

out = os.environ["REPORT"]
with open(out, "w") as f:
    json.dump(report, f, indent=2, ensure_ascii=False)
print(f"\n  [DONE] Audit report → {out}")
PYEOF

echo "════════════════════════════════════════════════════════════════"
