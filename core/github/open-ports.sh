#!/usr/bin/env bash
# Mở port 80 + 443 cho Let's Encrypt và public HTTPS
ufw allow 80/tcp comment "HTTP — Let's Encrypt challenge"
ufw allow 443/tcp comment "HTTPS — AXIOLEDGER Ecosystem"
ufw reload
echo "[✓] Ports 80/443 opened"
ufw status numbered | grep -E "80|443"
