#!/usr/bin/env bash
# =============================================================================
# install-swift-sdk.sh
# Phase A7 — Install SWIFT Security SDK & SWIFT SDK JARs into Maven local repo
#
# Usage:
#   ./scripts/install-swift-sdk.sh --sdk-zip /path/to/swift-sdk-bundle.zip
#
# What it does:
#   1. Validates prerequisites (java, mvn, unzip)
#   2. Extracts outer ZIP → finds inner JARs (2-layer bundle from SWIFT portal)
#   3. Installs swift-security-sdk into Maven local (~/.m2)
#   4. Installs swift-sdk (optional, if present in bundle)
#   5. Verifies installation via mvn dependency:get
#   6. Runs soft tests to confirm compile+test pass
#
# Security rules (Step 4 of SKILL.md):
#   - SDK JARs are NEVER committed to git — this script installs to local Maven only
#   - The ZIP file itself must NOT be committed (add to .gitignore)
#
# Gate condition completed by this script:
#   Phase A7: Backend installs Security SDK into Maven local
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

# ── Defaults from pom.xml ─────────────────────────────────────────────────────
SECURITY_SDK_GROUP="com.swift.commons.oauth"
SECURITY_SDK_ARTIFACT="swift-security-sdk"
SECURITY_SDK_VERSION="2.17.5-6"
SECURITY_SDK_CLASSIFIER="jar-with-dependencies"

SWIFT_SDK_GROUP="com.swift"
SWIFT_SDK_ARTIFACT="swift-sdk"
SWIFT_SDK_VERSION="2.17.10-6"

POM_FILE="packages/swift-bridge/pom.xml"
WORK_DIR=""  # set below to a temp directory

# ── Argument parsing ──────────────────────────────────────────────────────────
SDK_ZIP=""
SKIP_TEST=false

usage() {
  echo "Usage: $0 --sdk-zip <path/to/swift-sdk-bundle.zip> [--skip-test]"
  echo ""
  echo "  --sdk-zip      Path to the SWIFT SDK bundle ZIP downloaded from SWIFT portal"
  echo "  --skip-test    Skip soft-test verification step (not recommended)"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sdk-zip)    SDK_ZIP="$2";  shift 2 ;;
    --skip-test)  SKIP_TEST=true; shift ;;
    -h|--help)    usage ;;
    *)            die "Unknown argument: $1" ;;
  esac
done

[[ -z "$SDK_ZIP" ]] && usage
[[ ! -f "$SDK_ZIP" ]] && die "SDK ZIP not found: $SDK_ZIP"

# ── Prereq checks ─────────────────────────────────────────────────────────────
info "Checking prerequisites..."

command -v java  >/dev/null 2>&1 || die "java not found — install JDK 17 first"
command -v mvn   >/dev/null 2>&1 || die "mvn not found — install Maven 3.9+ first"
command -v unzip >/dev/null 2>&1 || die "unzip not found — install unzip first"

JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/{print $2}' | cut -d. -f1)
[[ "$JAVA_VER" -lt 17 ]] && warn "Java version appears to be $JAVA_VER — pom.xml requires Java 17"

[[ ! -f "$POM_FILE" ]] && die "pom.xml not found at $POM_FILE — run from repo root"

success "Prerequisites OK"

# ── Create work directory ─────────────────────────────────────────────────────
WORK_DIR=$(mktemp -d /tmp/swift-sdk-install.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

info "Working directory: $WORK_DIR"

# ── Step 1: Extract outer ZIP ─────────────────────────────────────────────────
info "Extracting outer ZIP: $SDK_ZIP"
unzip -q "$SDK_ZIP" -d "$WORK_DIR/outer"

# ── Step 2: Find inner ZIPs or JARs (2-layer bundle) ─────────────────────────
info "Scanning bundle structure..."

# SWIFT bundles typically nest: outer.zip → sdk-bundle/ → swift-security-sdk-*.zip → *.jar
INNER_ZIPS=$(find "$WORK_DIR/outer" -name "*.zip" 2>/dev/null || true)

if [[ -n "$INNER_ZIPS" ]]; then
  info "Found inner ZIP(s) — extracting second layer..."
  while IFS= read -r inner_zip; do
    info "  Extracting: $(basename "$inner_zip")"
    unzip -q "$inner_zip" -d "$WORK_DIR/inner/$(basename "$inner_zip" .zip)"
  done <<< "$INNER_ZIPS"
  JAR_SEARCH_ROOT="$WORK_DIR/inner"
else
  info "No inner ZIPs found — treating outer bundle as flat structure"
  JAR_SEARCH_ROOT="$WORK_DIR/outer"
fi

# ── Step 3: Locate Security SDK JAR ───────────────────────────────────────────
info "Locating swift-security-sdk JAR (classifier: jar-with-dependencies)..."

SECURITY_JAR=$(find "$JAR_SEARCH_ROOT" -name "*swift-security-sdk*jar-with-dependencies*.jar" \
                                       -o -name "*swift-security-sdk*-all.jar" 2>/dev/null \
               | head -1 || true)

if [[ -z "$SECURITY_JAR" ]]; then
  # Fallback: any JAR with security-sdk in the name
  SECURITY_JAR=$(find "$JAR_SEARCH_ROOT" -name "*security-sdk*.jar" | head -1 || true)
fi

[[ -z "$SECURITY_JAR" ]] && die "Could not locate swift-security-sdk JAR in bundle. Expected pattern: *swift-security-sdk*jar-with-dependencies*.jar"

success "Found Security SDK JAR: $(basename "$SECURITY_JAR")"

# ── Step 4: Install Security SDK into Maven local ─────────────────────────────
info "Installing swift-security-sdk into Maven local repository..."

mvn -q install:install-file \
  -Dfile="$SECURITY_JAR" \
  -DgroupId="$SECURITY_SDK_GROUP" \
  -DartifactId="$SECURITY_SDK_ARTIFACT" \
  -Dversion="$SECURITY_SDK_VERSION" \
  -Dpackaging=jar \
  -Dclassifier="$SECURITY_SDK_CLASSIFIER"

success "swift-security-sdk ${SECURITY_SDK_VERSION} installed"

# ── Step 5: Locate and install SWIFT SDK JAR (optional) ───────────────────────
SWIFT_JAR=$(find "$JAR_SEARCH_ROOT" -name "*swift-sdk*.jar" \
                                    ! -name "*security*" \
            | head -1 || true)

if [[ -n "$SWIFT_JAR" ]]; then
  info "Installing swift-sdk into Maven local repository..."
  mvn -q install:install-file \
    -Dfile="$SWIFT_JAR" \
    -DgroupId="$SWIFT_SDK_GROUP" \
    -DartifactId="$SWIFT_SDK_ARTIFACT" \
    -Dversion="$SWIFT_SDK_VERSION" \
    -Dpackaging=jar
  success "swift-sdk ${SWIFT_SDK_VERSION} installed"
else
  warn "swift-sdk JAR not found in bundle — skipping (only security-sdk is required for compile)"
fi

# ── Step 6: Verify via mvn compile ────────────────────────────────────────────
info "Verifying: mvn compile on packages/swift-bridge..."

mvn -B clean compile --file "$POM_FILE" \
  && success "mvn compile PASSED — Phase A7 gate condition met" \
  || die "mvn compile FAILED — check JAR version matches pom.xml (security-sdk.version=${SECURITY_SDK_VERSION})"

# ── Step 7: Run soft tests (unless skipped) ───────────────────────────────────
if [[ "$SKIP_TEST" == false ]]; then
  info "Running soft tests (no credentials required)..."
  mvn -B test \
    -Dtest="**/soft/**Test" \
    -DfailIfNoTests=false \
    --file "$POM_FILE" \
    && success "Soft tests PASSED" \
    || die "Soft tests FAILED — review test output above"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Phase A7 — COMPLETE${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Installed artifacts:"
echo "    com.swift.commons.oauth:swift-security-sdk:${SECURITY_SDK_VERSION}:jar-with-dependencies"
[[ -n "$SWIFT_JAR" ]] && echo "    com.swift:swift-sdk:${SWIFT_SDK_VERSION}:jar"
echo ""
echo "  Next steps (remaining Phase A gate conditions):"
echo "    [ ] GET http://localhost:9003/monitoring/health → {\"status\":\"UP\"}"
echo "    [ ] ./swift-server/config/ contains only .enc and .ks (no .yaml)"
echo "    [ ] Kineto SPV filing submitted + BIC application receipt from SWIFT"
echo "    [ ] GetTokenTest(hard) → HTTP 200, token TTL ≥ 14 min from sandbox.swift.com"
echo ""
echo -e "${YELLOW}  SECURITY REMINDER: Do NOT commit SDK JARs or the bundle ZIP to git.${NC}"
echo ""
