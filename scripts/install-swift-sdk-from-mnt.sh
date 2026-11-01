#!/usr/bin/env bash
# =============================================================================
# install-swift-sdk-from-mnt.sh
# Phase A7 — Install SWIFT SDK JARs từ /mnt/q/ vào Maven local
#
# JARs đã có sẵn tại /mnt/q/core/banking/swift-gateway/ — KHÔNG cần download.
# Chạy script này SAU KHI Java 17 + Maven đã được cài.
#
# Usage (trên dedicated server, từ repo root):
#   chmod +x scripts/install-swift-sdk-from-mnt.sh
#   ./scripts/install-swift-sdk-from-mnt.sh
#
# Sau khi chạy xong:
#   cd packages/swift-bridge && mvn -B clean compile --file pom.xml
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Paths ─────────────────────────────────────────────────────────────────────
MGW_BASE="/mnt/q/core/banking/swift-gateway"
SECURITY_JAR="$MGW_BASE/security/lib/swift-security-sdk-2.17.5-6.jar"
MESSAGING_JAR="$MGW_BASE/sdk/lib/swift-messaging-sdk-1.17.4.jar"
OPENAPI_JAR="$MGW_BASE/sdk/lib/swift-sdk-openapi-2.17.10-6.jar"

SWIFT_BRIDGE_POM="packages/swift-bridge/pom.xml"
BANKING_POM="core/banking/swift-gateway/pom.xml"

# ── Prereq checks ─────────────────────────────────────────────────────────────
info "Checking prerequisites..."
command -v java >/dev/null 2>&1 || die "java not found — run: apt-get install openjdk-17-jdk"
command -v mvn  >/dev/null 2>&1 || die "mvn not found — run: apt-get install maven"
[[ -f "$SECURITY_JAR"  ]] || die "Security SDK not found: $SECURITY_JAR"
[[ -f "$MESSAGING_JAR" ]] || die "Messaging SDK not found: $MESSAGING_JAR"
[[ -f "$OPENAPI_JAR"   ]] || die "OpenAPI SDK not found: $OPENAPI_JAR"
success "Prerequisites OK"

# ── Install 1: swift-security-sdk (required by packages/swift-bridge) ─────────
info "Installing swift-security-sdk:2.17.5-6 ..."
# pom.xml expects classifier=jar-with-dependencies; install the fat jar under that classifier
mvn -q install:install-file \
  -Dfile="$SECURITY_JAR" \
  -DgroupId="com.swift.commons.oauth" \
  -DartifactId="swift-security-sdk" \
  -Dversion="2.17.5-6" \
  -Dpackaging=jar \
  -Dclassifier="jar-with-dependencies"
success "swift-security-sdk:2.17.5-6:jar-with-dependencies installed"

# Also install without classifier for banking module
mvn -q install:install-file \
  -Dfile="$SECURITY_JAR" \
  -DgroupId="com.swift.commons.oauth" \
  -DartifactId="swift-security-sdk" \
  -Dversion="2.17.5-6" \
  -Dpackaging=jar
success "swift-security-sdk:2.17.5-6 (no classifier) installed"

# ── Install 2: swift-messaging-sdk (required by core/banking) ─────────────────
info "Installing swift-messaging-sdk:1.17.4 ..."
mvn -q install:install-file \
  -Dfile="$MESSAGING_JAR" \
  -DgroupId="com.swift" \
  -DartifactId="swift-messaging-sdk" \
  -Dversion="1.17.4" \
  -Dpackaging=jar
success "swift-messaging-sdk:1.17.4 installed"

# ── Install 3: swift-sdk-openapi (optional — for future GPI codegen) ──────────
info "Installing swift-sdk-openapi:2.17.10-6 ..."
mvn -q install:install-file \
  -Dfile="$OPENAPI_JAR" \
  -DgroupId="com.swift" \
  -DartifactId="swift-sdk-openapi" \
  -Dversion="2.17.10-6" \
  -Dpackaging=jar
success "swift-sdk-openapi:2.17.10-6 installed"

# ── Verify: compile packages/swift-bridge ─────────────────────────────────────
if [[ -f "$SWIFT_BRIDGE_POM" ]]; then
  info "Verifying: mvn compile — packages/swift-bridge..."
  mvn -B clean compile --file "$SWIFT_BRIDGE_POM" \
    && success "packages/swift-bridge mvn compile PASSED — Phase A7 gate COMPLETE" \
    || die "packages/swift-bridge mvn compile FAILED"
fi

# ── Soft tests ────────────────────────────────────────────────────────────────
info "Running soft tests — packages/swift-bridge..."
mvn -B test -Dtest="**/soft/**Test" -DfailIfNoTests=false \
    --file "$SWIFT_BRIDGE_POM" \
  && success "packages/swift-bridge soft tests PASSED (40 cases)" \
  || die "Soft tests FAILED"

info "Running soft tests — core/banking/swift-gateway..."
mvn -B test -Dtest="**/soft/**Test" -DfailIfNoTests=false \
    --file "$BANKING_POM" \
  && success "core/banking soft tests PASSED (14 cases)" \
  || die "core/banking soft tests FAILED"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Phase A7 — COMPLETE${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Installed from /mnt/q/core/banking/swift-gateway/:"
echo "    com.swift.commons.oauth:swift-security-sdk:2.17.5-6:jar-with-dependencies"
echo "    com.swift.commons.oauth:swift-security-sdk:2.17.5-6 (no classifier)"
echo "    com.swift:swift-messaging-sdk:1.17.4"
echo "    com.swift:swift-sdk-openapi:2.17.10-6"
echo ""
echo "  Remaining Phase A gate conditions:"
echo "    [ ] GET http://localhost:9003/monitoring/health → {\"status\":\"UP\"}"
echo "    [ ] ./swift-server/config/ contains only .enc and .ks (no .yaml)"
echo "    [ ] Kineto SPV BIC filing + receipt from SWIFT"
echo "    [ ] GetTokenHardTest → HTTP 200 from sandbox.swift.com"
echo ""
