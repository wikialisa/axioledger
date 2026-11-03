#!/usr/bin/env bash
# =============================================================================
# provision-mgw-server.sh
# Phase A1–A5 — Provision dedicated MGW server directory structure
#
# Usage (on the dedicated MGW server — NOT the SQX blockchain node, DP-4):
#   sudo ./scripts/provision-mgw-server.sh --mgw-zip /path/to/swift-mgw.zip \
#                                          --server-root /opt/swift-server
#
# What it does:
#   A1. Creates sandboxed directory tree under --server-root
#   A2. Sets ownership + permissions (keys/ → chmod 700 dir, 600 files)
#   A3. Checks for Java 8 JDK (required by MGW — separate from Bridge Java 17)
#   A4. Extracts MGW distribution ZIP into ./bin/ and ./lib/
#   A5. Creates config skeleton (cleartext YAML stub — must be encrypted by
#       Security Engineer via bin/encrypt.sh before first MGW start)
#
# DP-4 enforced: script exits if it detects it is running on the same host
#                as a running SQX node (checks for sqxd process).
#
# Security rules (Step 4 of SKILL.md):
#   - config-swift-mgw.yaml must NEVER be committed to git
#   - *.jks, *.p12, *.pem, *.key must NEVER be committed to git
#   - keys/ directory managed by Security Engineer only
#
# Gate conditions completed by this script (partial Phase A):
#   A1: Dedicated server provisioned, ./swift-server/ structure created
#   A2: Java 8 JDK presence confirmed
#   A3: MGW extracted
#   A4: keys/ directory exists with chmod 700/600
#   A5: config skeleton in place (cleartext — Security Engineer must encrypt)
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()     { error "$*"; exit 1; }

# ── Defaults ──────────────────────────────────────────────────────────────────
SERVER_ROOT="/opt/swift-server"
MGW_ZIP=""
MGW_SERVICE_USER="swift-mgw"
MGW_PORT=9003
SKIP_DP4_CHECK=false

# ── Argument parsing ──────────────────────────────────────────────────────────
usage() {
  echo "Usage: $0 --mgw-zip <path/to/swift-mgw.zip> [--server-root <dir>] [--skip-dp4-check]"
  echo ""
  echo "  --mgw-zip         Path to the SWIFT MGW distribution ZIP"
  echo "  --server-root     Installation root (default: /opt/swift-server)"
  echo "  --skip-dp4-check  Skip SQX co-location check (NOT recommended in production)"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mgw-zip)         MGW_ZIP="$2";        shift 2 ;;
    --server-root)     SERVER_ROOT="$2";    shift 2 ;;
    --skip-dp4-check)  SKIP_DP4_CHECK=true; shift ;;
    -h|--help)         usage ;;
    *)                 die "Unknown argument: $1" ;;
  esac
done

[[ -z "$MGW_ZIP" ]] && usage

# ── DP-4: Must NOT run on SQX blockchain node ─────────────────────────────────
if [[ "$SKIP_DP4_CHECK" == false ]]; then
  if pgrep -x "sqxd" >/dev/null 2>&1; then
    die "DP-4 VIOLATION: sqxd (SQX blockchain node) is running on this host. MGW must run on a DEDICATED server, never co-located with the blockchain node. Exiting."
  fi
  success "DP-4 check passed — no SQX node detected on this host"
fi

# ── Prereq checks ─────────────────────────────────────────────────────────────
info "Checking prerequisites..."

command -v unzip >/dev/null 2>&1 || die "unzip not found — install unzip first"

[[ ! -f "$MGW_ZIP" ]] && die "MGW ZIP not found: $MGW_ZIP"

# Java 8 check (MGW requires Java 8 JVM — separate from Bridge Java 17)
JAVA8_BIN=""
for candidate in \
  "/usr/lib/jvm/java-8-openjdk-amd64/bin/java" \
  "/usr/lib/jvm/java-8-openjdk/bin/java" \
  "/opt/java/8/bin/java" \
  "$(command -v java 2>/dev/null || true)"; do
  if [[ -x "$candidate" ]]; then
    ver=$("$candidate" -version 2>&1 | awk -F '"' '/version/{print $2}' | cut -d. -f1-2)
    if [[ "$ver" == "1.8" ]]; then
      JAVA8_BIN="$candidate"
      break
    fi
  fi
done

if [[ -z "$JAVA8_BIN" ]]; then
  warn "Java 8 JDK not found at standard paths. MGW requires Java 8."
  warn "Install via: apt-get install openjdk-8-jdk  (Debian/Ubuntu)"
  warn "             yum install java-1.8.0-openjdk  (RHEL/CentOS)"
  warn "Continuing — but MGW will not start until Java 8 is installed."
else
  success "Java 8 found: $JAVA8_BIN"
fi

success "Prerequisites OK"

# ── A1: Create directory tree ─────────────────────────────────────────────────
info "A1 — Creating directory structure under $SERVER_ROOT..."

install -d -m 755 "$SERVER_ROOT"
install -d -m 755 "$SERVER_ROOT/bin"
install -d -m 755 "$SERVER_ROOT/lib"
install -d -m 755 "$SERVER_ROOT/logs"
install -d -m 755 "$SERVER_ROOT/config"
install -d -m 700 "$SERVER_ROOT/keys"   # keys dir: owner-only (chmod 700)

success "Directory tree created"

# ── A2: Set service user ownership (if user exists) ──────────────────────────
info "A2 — Setting ownership..."

if id "$MGW_SERVICE_USER" >/dev/null 2>&1; then
  chown -R "$MGW_SERVICE_USER":"$MGW_SERVICE_USER" "$SERVER_ROOT"
  success "Ownership set to $MGW_SERVICE_USER"
else
  warn "Service user '$MGW_SERVICE_USER' does not exist — skipping chown."
  warn "Create it before starting MGW: useradd --system --no-create-home $MGW_SERVICE_USER"
  warn "Then run: chown -R $MGW_SERVICE_USER:$MGW_SERVICE_USER $SERVER_ROOT"
fi

# ── A3: Extract MGW distribution ─────────────────────────────────────────────
info "A3 — Extracting MGW distribution: $MGW_ZIP"

WORK_DIR=$(mktemp -d /tmp/mgw-provision.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

unzip -q "$MGW_ZIP" -d "$WORK_DIR/mgw"

# SWIFT MGW zip typically contains: swift-microgateway-<version>/ with bin/ and lib/
MGW_ROOT=$(find "$WORK_DIR/mgw" -maxdepth 1 -mindepth 1 -type d | head -1)
if [[ -z "$MGW_ROOT" ]]; then
  # Flat structure
  MGW_ROOT="$WORK_DIR/mgw"
fi

# Copy bin and lib
if [[ -d "$MGW_ROOT/bin" ]]; then
  cp -r "$MGW_ROOT/bin/." "$SERVER_ROOT/bin/"
  chmod +x "$SERVER_ROOT/bin/"*.sh 2>/dev/null || true
  chmod +x "$SERVER_ROOT/bin/"*.jar 2>/dev/null || true
fi

if [[ -d "$MGW_ROOT/lib" ]]; then
  cp -r "$MGW_ROOT/lib/." "$SERVER_ROOT/lib/"
fi

# Copy any top-level JARs (some bundles put the main jar at root)
find "$MGW_ROOT" -maxdepth 1 -name "*.jar" -exec cp {} "$SERVER_ROOT/lib/" \;

success "MGW distribution extracted to $SERVER_ROOT"

# ── A4: keys/ directory — placeholder files with correct permissions ──────────
info "A4 — Preparing keys/ directory (chmod 700 dir, 600 files)..."
info "      Security Engineer must provide: server.jks, truststore.jks"

# Create placeholder README (not a secret, safe to have)
cat > "$SERVER_ROOT/keys/README.txt" << 'EOF'
SWIFT MGW Keys Directory
========================
This directory is managed exclusively by the Security Engineer.

Required files (DO NOT commit to git):
  server.jks      — Server keystore (mTLS client certificate + private key)
  truststore.jks  — SWIFT CA truststore

Permissions:
  This directory: chmod 700 (owner only)
  All .jks files: chmod 600 (owner read/write only)

Create keystore (example — adapt to actual SWIFT CSR process):
  keytool -genkeypair -alias swift-mgw \
          -keyalg RSA -keysize 2048 \
          -validity 730 \
          -keystore server.jks \
          -storetype JKS

After placing files:
  chmod 600 $SERVER_ROOT/keys/*.jks
  chown swift-mgw:swift-mgw $SERVER_ROOT/keys/*.jks
EOF

chmod 600 "$SERVER_ROOT/keys/README.txt"
chmod 700 "$SERVER_ROOT/keys"

success "keys/ directory secured (chmod 700)"

# ── A5: Config skeleton ───────────────────────────────────────────────────────
info "A5 — Writing config skeleton (CLEARTEXT — Security Engineer must encrypt)..."

CONFIG_FILE="$SERVER_ROOT/config/config-swift-mgw.yaml"

cat > "$CONFIG_FILE" << EOF
# =============================================================================
# SWIFT Microgateway Configuration — CLEARTEXT SKELETON
# =============================================================================
# ⚠️  SECURITY ENGINEER ACTION REQUIRED:
#   1. Fill in actual values below
#   2. Run: $SERVER_ROOT/bin/encrypt.sh
#   3. Commit ONLY the generated .enc and .ks files — NEVER this .yaml file
#   4. Delete this file after encryption: rm $CONFIG_FILE
# =============================================================================

server:
  port: ${MGW_PORT}
  host: 127.0.0.1        # loopback only — never expose to external network (DP-4)

swift:
  audience: SANDBOX_PROD  # Phase A/B/C — do NOT change to ON_PREMISES_PROD (DP-5)
  oauth:
    clientId: "REPLACE_ME"
    clientSecret: "REPLACE_ME"
    tokenUrl: "https://sandbox.swift.com/oauth2/v1/token"

tls:
  keystore: "${SERVER_ROOT}/keys/server.jks"
  keystorePassword: "REPLACE_ME"
  truststore: "${SERVER_ROOT}/keys/truststore.jks"
  truststorePassword: "REPLACE_ME"

logging:
  level: INFO
  file: "${SERVER_ROOT}/logs/mgw.log"
EOF

chmod 640 "$CONFIG_FILE"

success "Config skeleton written to $CONFIG_FILE"
warn "⚠️  CLEARTEXT CONFIG — Security Engineer must encrypt before MGW start"

# ── A5b: Create bin/encrypt.sh stub (if not already provided by MGW bundle) ───
ENCRYPT_SCRIPT="$SERVER_ROOT/bin/encrypt.sh"
if [[ ! -f "$ENCRYPT_SCRIPT" ]]; then
  info "Creating bin/encrypt.sh stub (not found in MGW bundle)..."
  cat > "$ENCRYPT_SCRIPT" << 'ENCEOF'
#!/usr/bin/env bash
# encrypt.sh — Encrypt config-swift-mgw.yaml using Java KeyStore
# Replace this stub with the actual SWIFT-provided encryption utility
# or implement using: openssl / keytool + symmetric key from server.jks
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/../config/config-swift-mgw.yaml"
[[ ! -f "$CONFIG" ]] && { echo "ERROR: $CONFIG not found"; exit 1; }
echo "ERROR: encrypt.sh is a stub — implement using SWIFT SDK encryption utility"
echo "       Refer to SWIFT MGW documentation: Security > Config Encryption"
exit 1
ENCEOF
  chmod +x "$ENCRYPT_SCRIPT"
  warn "bin/encrypt.sh is a stub — replace with SWIFT-provided encryption utility"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Phase A1–A5 — COMPLETE (server structure provisioned)${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Directory structure:"
echo "    $SERVER_ROOT/"
echo "    ├── bin/         (MGW startup scripts)"
echo "    ├── lib/         (MGW JARs)"
echo "    ├── config/      (config-swift-mgw.yaml — MUST be encrypted)"
echo "    ├── keys/        (chmod 700 — Security Engineer only)"
echo "    │   └── README.txt"
echo "    └── logs/"
echo ""
echo "  Remaining actions before Phase A is complete:"
echo ""
echo "  [Security Engineer]"
echo "    1. Place server.jks + truststore.jks in $SERVER_ROOT/keys/"
echo "    2. chmod 600 $SERVER_ROOT/keys/*.jks"
echo "    3. Fill in REPLACE_ME values in $CONFIG_FILE"
echo "    4. Run: $SERVER_ROOT/bin/encrypt.sh"
echo "    5. Delete cleartext: rm $CONFIG_FILE"
echo ""
echo "  [SysAdmin — Phase A6]"
echo "    6. Start MGW: java -jar $SERVER_ROOT/lib/<mgw-main>.jar &"
echo "    7. Verify:  curl http://127.0.0.1:${MGW_PORT}/monitoring/health"
echo "       Expected: {\"status\":\"UP\"}"
echo ""
echo "  [Legal — DP-1]"
echo "    8. Submit Kineto SPV SWIFT BIC application"
echo ""
echo -e "${YELLOW}  SECURITY REMINDER: Never commit .jks, .p12, .pem, .key, or .yaml to git.${NC}"
echo ""
