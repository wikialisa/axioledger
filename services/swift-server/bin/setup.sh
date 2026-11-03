#!/usr/bin/env bash
# swift-server/bin/setup.sh
# ─────────────────────────────────────────────────────────────────────────────
# SWIFT MGW Sandboxed Directory — Initial Setup Script (DP-4)
#
# Chạy bởi: Infrastructure Root / SysAdmin
# Mục tiêu: Khởi tạo toàn bộ cấu trúc thư mục, phân quyền, RBAC
#
# Sử dụng:
#   sudo bash swift-server/bin/setup.sh [--group swift-admin] [--user mgw-service]
#
# DP-4 yêu cầu:
#   - ./swift-server/ tách biệt hoàn toàn khỏi blockchain nodes
#   - ./keys/  → chmod 600 (chỉ SysAdmin)
#   - Blockchain Validator / Node Operator KHÔNG có quyền truy cập
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Parse args ────────────────────────────────────────────────────────────────
SWIFT_GROUP="${1:-swift-admin}"
SWIFT_USER="${2:-mgw-service}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   AXIOLEDGER — SWIFT MGW Sandboxed Setup (DP-4)         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "Server dir : $SERVER_DIR"
echo "Group      : $SWIFT_GROUP"
echo "Service user: $SWIFT_USER"
echo ""

# ── Step 1: Create system group & service user ────────────────────────────────
echo "[1/6] Creating group '$SWIFT_GROUP' and user '$SWIFT_USER'..."
if ! getent group "$SWIFT_GROUP" > /dev/null 2>&1; then
    groupadd "$SWIFT_GROUP"
    echo "      ✅ Group '$SWIFT_GROUP' created."
else
    echo "      ℹ️  Group '$SWIFT_GROUP' already exists."
fi

if ! id "$SWIFT_USER" > /dev/null 2>&1; then
    useradd -r -s /sbin/nologin -g "$SWIFT_GROUP" "$SWIFT_USER"
    echo "      ✅ Service user '$SWIFT_USER' created (no shell, no login)."
else
    echo "      ℹ️  User '$SWIFT_USER' already exists."
fi

# ── Step 2: Create directory structure ───────────────────────────────────────
echo "[2/6] Creating sandboxed directory structure..."
mkdir -p \
    "$SERVER_DIR/bin" \
    "$SERVER_DIR/config" \
    "$SERVER_DIR/db" \
    "$SERVER_DIR/keys" \
    "$SERVER_DIR/lib/internal" \
    "$SERVER_DIR/log" \
    "$SERVER_DIR/oas/local-api-repository"

echo "      ✅ Directories created."

# ── Step 3: Apply permissions ─────────────────────────────────────────────────
echo "[3/6] Applying PCI DSS-compliant file permissions..."

# Server root: group-owned, no world access
chown -R "$SWIFT_USER:$SWIFT_GROUP" "$SERVER_DIR"
chmod 750 "$SERVER_DIR"

# keys/: CRITICAL — only root/SysAdmin (DP-4)
chmod 700 "$SERVER_DIR/keys"
echo "      🔒 keys/ → chmod 700 (SysAdmin only)"

# config/: no world read (contains encrypted credentials)
chmod 750 "$SERVER_DIR/config"
echo "      🔒 config/ → chmod 750"

# bin/: executable by service user
chmod 750 "$SERVER_DIR/bin"
chmod +x "$SERVER_DIR/bin/"*.sh 2>/dev/null || true

# log/: writable by service user
chmod 755 "$SERVER_DIR/log"

# db/: writable by service user only
chmod 750 "$SERVER_DIR/db"

echo "      ✅ Permissions applied."

# ── Step 4: RBAC — Block blockchain node-operator ────────────────────────────
echo "[4/6] Configuring RBAC — blocking node-operator access..."

# Attempt to locate node-operator user and explicitly deny
if id "node-operator" > /dev/null 2>&1; then
    # Use ACL if available, otherwise rely on group-based isolation
    if command -v setfacl > /dev/null 2>&1; then
        setfacl -m u:node-operator:--- "$SERVER_DIR"
        setfacl -m u:node-operator:--- "$SERVER_DIR/keys"
        echo "      ✅ ACL: node-operator explicitly denied via setfacl."
    else
        echo "      ⚠️  setfacl not available — relying on group isolation."
        echo "         Ensure 'node-operator' is NOT in group '$SWIFT_GROUP'."
    fi
    # Verify
    if sudo -u node-operator ls "$SERVER_DIR/keys" > /dev/null 2>&1; then
        echo "      ❌ RBAC CHECK FAILED: node-operator can access keys/ !"
        exit 1
    else
        echo "      ✅ RBAC verified: node-operator cannot access keys/"
    fi
else
    echo "      ℹ️  User 'node-operator' not found — no explicit deny needed."
    echo "         Ensure any blockchain validator accounts are NOT in group '$SWIFT_GROUP'."
fi

# ── Step 5: Create .gitkeep placeholders (keys must not be committed) ─────────
echo "[5/6] Creating gitkeep placeholders..."
touch "$SERVER_DIR/keys/.gitkeep"
touch "$SERVER_DIR/db/.gitkeep"
touch "$SERVER_DIR/log/.gitkeep"

# Add a local .gitignore inside keys/ as extra safety net
cat > "$SERVER_DIR/keys/.gitignore" << 'GITIGNORE'
# SWIFT keystore files — NEVER commit (DP-4)
*.jks
*.p12
*.pem
*.key
*.pfx
*.crt
*.der
GITIGNORE
chmod 600 "$SERVER_DIR/keys/.gitignore"

echo "      ✅ Placeholders created."

# ── Step 6: Verify ────────────────────────────────────────────────────────────
echo "[6/6] Verification..."
echo ""
echo "  Directory structure:"
ls -la "$SERVER_DIR/" | awk '{print "    " $0}'
echo ""
echo "  keys/ permissions (must be 700 or 600):"
ls -la "$SERVER_DIR/keys/" | awk '{print "    " $0}'
echo ""

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   ✅ Setup complete!                                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Deploy MGW: unzip swift-mgw-2.0.17-1.zip (2-layer) into this directory"
echo "  2. Security: create JKS keystore → place in keys/ (chmod 600)"
echo "  3. Config:   fill config-swift-mgw.yaml → run bin/encrypt.sh → delete .yaml"
echo "  4. Start:    bash bin/start.sh"
echo "  5. Health:   bash bin/health-check.sh"
echo ""
echo "  DP-4 reminder: This server must NOT share resources with sqx-rollup-core."
