#!/usr/bin/env bash
#
# Run SwiftUsers XCUITests on the iOS Simulator.
#
# Acquires OAuth credentials via the existing get-test-token.js script,
# then runs the UI test suite with those credentials injected via
# environment variables.
#
# Usage:
#   ./run-ui-tests.sh
#   PROXY_URL=https://my-proxy.workers.dev ./run-ui-tests.sh
#   SIMULATOR_ID=XXXX ./run-ui-tests.sh
#
# Prerequisites:
#   - Mobile proxy running (locally: cd ../../../../een-mobile-proxy/proxy && npm run dev)
#   - Node.js + npm installed (for Playwright token acquisition)
#   - Xcode + iOS Simulator available

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROXY_URL="${PROXY_URL:-http://127.0.0.1:3333}"
CREDENTIALS_FILE="$TOOLKIT_ROOT/test-credentials.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cleanup() {
    if [ -f "$CREDENTIALS_FILE" ]; then
        rm -f "$CREDENTIALS_FILE"
        echo -e "${BLUE}Cleaned up${NC} $CREDENTIALS_FILE"
    fi
}
trap cleanup EXIT

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}SwiftUsers UI Tests${NC}"
echo -e "${BLUE}============================================${NC}"
echo "Proxy: $PROXY_URL"
echo ""

# ── 1. Check proxy ──────────────────────────────────────────────────────
echo -e "${BLUE}1. Checking proxy...${NC}"
if ! curl -sf "$PROXY_URL/proxy/version" > /dev/null 2>&1; then
    echo -e "${RED}Error:${NC} Proxy not reachable at $PROXY_URL"
    echo "Start it with: cd ../../../../een-mobile-proxy/proxy && npm run dev"
    exit 1
fi
echo -e "${GREEN}Proxy is running${NC}"
echo ""

# ── 2. Check Node dependencies ──────────────────────────────────────────
echo -e "${BLUE}2. Checking Node dependencies...${NC}"
cd "$TOOLKIT_ROOT"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
    npx playwright install chromium
fi
echo -e "${GREEN}Dependencies ready${NC}"
echo ""

# ── 3. Acquire test credentials ─────────────────────────────────────────
echo -e "${BLUE}3. Acquiring test credentials...${NC}"
PROXY_URL="$PROXY_URL" node scripts/get-test-token.js
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo -e "${RED}Error:${NC} Token acquisition failed — no credentials file"
    exit 1
fi
echo -e "${GREEN}Credentials acquired${NC}"
echo ""

# Parse credentials into environment variables
export TEST_TOKEN=$(python3 -c "import json; print(json.load(open('$CREDENTIALS_FILE'))['accessToken'])")
export TEST_BASE_URL=$(python3 -c "import json; print(json.load(open('$CREDENTIALS_FILE'))['httpsBaseUrl'])")
export TEST_SESSION_ID=$(python3 -c "import json; print(json.load(open('$CREDENTIALS_FILE'))['sessionId'])")
export TEST_EXPIRES_IN=$(python3 -c "import json; print(json.load(open('$CREDENTIALS_FILE'))['expiresIn'])")
export TEST_USER_EMAIL=$(python3 -c "import json; print(json.load(open('$CREDENTIALS_FILE')).get('userEmail',''))")

# ── 4. Find simulator ───────────────────────────────────────────────────
echo -e "${BLUE}4. Finding simulator...${NC}"
if [ -n "${SIMULATOR_ID:-}" ]; then
    SIMULATOR="$SIMULATOR_ID"
    echo "Using provided SIMULATOR_ID=$SIMULATOR"
else
    # Pick a simulator: prefer booted iPhone on iOS 18.x, then any available iPhone on iOS 18.x
    SIMULATOR=$(xcrun simctl list devices available -j \
        | python3 -c "
import json, sys
data = json.load(sys.stdin)
booted = []
available = []
for runtime, devices in sorted(data['devices'].items(), reverse=True):
    if 'iOS' not in runtime:
        continue
    # Prefer iOS 18.x for compatibility
    is_18 = 'iOS-18' in runtime or 'iOS 18' in runtime
    for d in devices:
        if not d.get('isAvailable', False):
            continue
        if 'iPhone' not in d.get('name', ''):
            continue
        entry = (d['udid'], is_18)
        if d.get('state') == 'Booted':
            booted.append(entry)
        else:
            available.append(entry)
# Prefer booted iOS 18, then any booted, then available iOS 18, then any
for lst in [booted, available]:
    for udid, is18 in lst:
        if is18:
            print(udid)
            sys.exit(0)
for lst in [booted, available]:
    for udid, is18 in lst:
        print(udid)
        sys.exit(0)
" 2>/dev/null || true)

    if [ -z "$SIMULATOR" ]; then
        echo -e "${RED}Error:${NC} No available iOS simulator found"
        exit 1
    fi

    # Boot the simulator if not already booted
    STATE=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIMULATOR':
            print(d['state'])
            sys.exit(0)
")
    if [ "$STATE" != "Booted" ]; then
        echo "Booting simulator $SIMULATOR..."
        xcrun simctl boot "$SIMULATOR" 2>/dev/null || true
    fi

    SIM_NAME=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIMULATOR':
            print(d['name'])
            sys.exit(0)
")
    echo "Using simulator: $SIM_NAME ($SIMULATOR)"
fi
echo ""

# ── 5. Run UI tests ─────────────────────────────────────────────────────
echo -e "${BLUE}5. Running UI tests...${NC}"
echo ""

cd "$SCRIPT_DIR"

set +e
xcodebuild test \
    -project SwiftUsers.xcodeproj \
    -scheme SwiftUsers \
    -destination "id=$SIMULATOR" \
    -only-testing:SwiftUsersUITests \
    2>&1 | tee /tmp/uitest-output.log \
    | grep -E '(Test Case|Test suite|Executed|passed|failed|\*\* TEST)'
# Capture xcodebuild's exit code from PIPESTATUS
TEST_EXIT=${PIPESTATUS[0]}
set -e

echo ""

# ── 6. Report result ────────────────────────────────────────────────────
echo -e "${BLUE}============================================${NC}"
if [ $TEST_EXIT -eq 0 ]; then
    echo -e "${GREEN}All UI tests passed!${NC}"
else
    echo -e "${RED}Some UI tests failed (exit $TEST_EXIT)${NC}"
    echo "Full log: /tmp/uitest-output.log"
fi
echo -e "${BLUE}============================================${NC}"

exit $TEST_EXIT
