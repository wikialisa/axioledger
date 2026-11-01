#!/usr/bin/env bash
# AXIOLEDGER — Let's Encrypt SSL Setup
# Chạy script này khi đã có domain thật trỏ A record về 113.22.172.197
# Usage: ./setup-letsencrypt.sh yourdomain.com

set -euo pipefail

DOMAIN="${1:?Usage: ./setup-letsencrypt.sh <domain.com>}"
EMAIL="315885655+davictran76@users.noreply.github.com"

echo "════════════════════════════════════════════════════════"
echo "  Let's Encrypt SSL — $DOMAIN"
echo "  IP: 113.22.172.197"
echo "════════════════════════════════════════════════════════"

# Kiểm tra domain đã trỏ về server chưa
RESOLVED=$(dig +short "$DOMAIN" 2>/dev/null | head -1)
if [[ "$RESOLVED" != "113.22.172.197" ]]; then
  echo "  [✗] $DOMAIN → $RESOLVED (cần trỏ về 113.22.172.197)"
  echo "  Thêm A record: $DOMAIN → 113.22.172.197 tại DNS provider"
  exit 1
fi
echo "  [✓] DNS OK: $DOMAIN → $RESOLVED"

# Issue cert
certbot --nginx \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  -d "$DOMAIN" \
  -d "www.$DOMAIN" \
  --redirect

echo "  [✓] Let's Encrypt cert issued for $DOMAIN"
echo "  Auto-renew: sudo certbot renew --dry-run"
echo "════════════════════════════════════════════════════════"
