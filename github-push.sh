#!/usr/bin/env bash
# github-push.sh — quick helper to stage, commit and push updates to axioledger/axioledger
# Usage:  ./github-push.sh "your commit message"

set -euo pipefail

MSG="${1:-chore: update}"
source ~/.bashrc

cd "$(dirname "$0")"

git add -A
git commit -m "$MSG"
git push origin main

echo "✓ Pushed: $MSG"
