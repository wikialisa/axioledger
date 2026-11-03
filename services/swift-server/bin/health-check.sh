#!/usr/bin/env bash
# swift-server/bin/health-check.sh
# ─────────────────────────────────────────────────────────────────────────────
# Kiểm tra trạng thái MGW — điều kiện báo cáo "Giai đoạn A Hoàn tất"
#
# Sử dụng:
#   bash swift-server/bin/health-check.sh [apikey] [port]
#
# Exit code:
#   0 — MGW HEALTHY
#   1 — MGW không phản hồi hoặc unhealthy
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

APIKEY="${1:-${MGW_ADMIN_APIKEY:-}}"
PORT="${2:-9003}"
HOST="localhost"
ENDPOINT="http://${HOST}:${PORT}/monitoring/health"

if [ -z "$APIKEY" ]; then
    echo "Usage: $0 <admin_apikey> [port]"
    echo "       or set env: MGW_ADMIN_APIKEY=<key>"
    exit 1
fi

echo "Checking SWIFT MGW health at $ENDPOINT ..."

RESPONSE=$(curl -s -o /tmp/mgw-health.json -w "%{http_code}" \
    -H "X-API-Key: ${APIKEY}" \
    --connect-timeout 5 \
    --max-time 10 \
    "$ENDPOINT" 2>/dev/null || echo "000")

if [ "$RESPONSE" = "200" ]; then
    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║   ✅ MGW STATUS: HEALTHY             ║"
    echo "╚══════════════════════════════════════╝"
    echo ""
    cat /tmp/mgw-health.json 2>/dev/null | python3 -m json.tool 2>/dev/null || \
        cat /tmp/mgw-health.json 2>/dev/null || true
    echo ""
    echo "  Giai đoạn A — Đội 1 HOÀN TẤT ✅"
    exit 0
elif [ "$RESPONSE" = "000" ]; then
    echo "❌ MGW không phản hồi tại $ENDPOINT"
    echo "   Kiểm tra: ./bin/start.sh đã chạy chưa? Port $PORT có bị block không?"
    exit 1
else
    echo "❌ MGW trả về HTTP $RESPONSE"
    cat /tmp/mgw-health.json 2>/dev/null || true
    exit 1
fi
