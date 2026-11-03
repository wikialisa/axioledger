#!/usr/bin/env bash
# scripts/run-ctf.sh — CTF Challenge Runner
#
# Sử dụng:
#   ./scripts/run-ctf.sh                   # build + test tất cả challenges
#   ./scripts/run-ctf.sh reentrancy        # build + test một challenge
#   ./scripts/run-ctf.sh list              # liệt kê tất cả challenges

set -euo pipefail

CTF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ctf"

CHALLENGES=(
    "reentrancy"
    "oracle-manipulation"
    "access-control-bypass"
    "flash-loan-attack"
    "signature-replay"
)

list_challenges() {
    echo ""
    echo "📋 CTF Challenges:"
    echo ""
    printf "  %-5s %-35s %s\n" "#" "Name" "Description"
    printf "  %-5s %-35s %s\n" "---" "-----------------------------------" "-------------------"
    printf "  %-5s %-35s %s\n" "01" "reentrancy"              "CEI pattern violation"
    printf "  %-5s %-35s %s\n" "02" "oracle-manipulation"     "Spot price flash loan"
    printf "  %-5s %-35s %s\n" "03" "access-control-bypass"   "Missing Signer constraint"
    printf "  %-5s %-35s %s\n" "04" "flash-loan-attack"       "Integer overflow in fee calc"
    printf "  %-5s %-35s %s\n" "05" "signature-replay"        "Missing nonce/expiry"
    echo ""
}

run_challenge() {
    local name="$1"
    local pkg="ctf-${name}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 Challenge: ${name}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Build
    echo "📦 Building..."
    cargo build -p "${pkg}" --manifest-path "${CTF_DIR}/Cargo.toml" 2>&1

    # Test (if any test files exist)
    local test_dir="${CTF_DIR}/challenges/${name}/tests"
    if [ -d "${test_dir}" ]; then
        echo "🧪 Running tests..."
        cargo test -p "${pkg}" --manifest-path "${CTF_DIR}/Cargo.toml" -- --nocapture 2>&1
    else
        echo "ℹ️  No tests found. Write your own in challenges/${name}/tests/"
    fi

    echo "✅ Done: ${name}"
}

run_all() {
    echo ""
    echo "🚀 Running all CTF challenges..."
    echo ""
    local passed=0
    local failed=0
    for challenge in "${CHALLENGES[@]}"; do
        if run_challenge "${challenge}"; then
            ((passed++))
        else
            ((failed++))
            echo "❌ FAILED: ${challenge}"
        fi
    done
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Results: ${passed} passed, ${failed} failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    [ "${failed}" -eq 0 ]
}

# ─── Main ────────────────────────────────────────────────────────────────────

case "${1:-all}" in
    list)
        list_challenges ;;
    all)
        run_all ;;
    *)
        # Run a specific challenge by name
        NAME="$1"
        # Validate
        found=0
        for c in "${CHALLENGES[@]}"; do
            [ "${c}" = "${NAME}" ] && found=1 && break
        done
        if [ "${found}" -eq 0 ]; then
            echo "❌ Unknown challenge: ${NAME}"
            echo "   Run: $0 list"
            exit 1
        fi
        run_challenge "${NAME}" ;;
esac
