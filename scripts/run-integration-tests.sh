#!/usr/bin/env bash
#
# Orchestrator for Swift integration tests against a live EEN mobile proxy.
#
# Usage:
#   ./scripts/run-integration-tests.sh
#   PROXY_URL=https://my-proxy.workers.dev ./scripts/run-integration-tests.sh
#
# Prerequisites:
#   - Mobile proxy running (locally: cd ../een-mobile-proxy/proxy && npm run dev)
#   - Node.js + npm installed
#   - Swift toolchain installed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROXY_URL="${PROXY_URL:-http://127.0.0.1:3333}"
CREDENTIALS_FILE="$PROJECT_DIR/test-credentials.json"

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
echo -e "${BLUE}Swift Integration Tests${NC}"
echo -e "${BLUE}============================================${NC}"
echo "Proxy: $PROXY_URL"
echo ""

# 1. Ensure proxy is running (starts it if needed)
echo -e "${BLUE}1. Ensuring proxy is running...${NC}"
"$SCRIPT_DIR/ensure-proxy.sh"
echo ""

# 2. Install Node dependencies if needed
echo -e "${BLUE}2. Checking Node dependencies...${NC}"
cd "$PROJECT_DIR"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
    npx playwright install chromium
fi
echo -e "${GREEN}Dependencies ready${NC}"
echo ""

# 3. Get test credentials via Playwright
echo -e "${BLUE}3. Acquiring test credentials...${NC}"
PROXY_URL="$PROXY_URL" node scripts/get-test-token.js
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo -e "${RED}Error:${NC} Token acquisition failed — no credentials file"
    exit 1
fi
echo -e "${GREEN}Credentials acquired${NC}"
echo ""

# 4. Run Swift integration tests
echo -e "${BLUE}4. Running Swift integration tests...${NC}"
echo ""
PROXY_URL="$PROXY_URL" swift test --filter LiveServiceTests 2>&1
TEST_EXIT=$?
echo ""

# 5. Report result
echo -e "${BLUE}============================================${NC}"
if [ $TEST_EXIT -eq 0 ]; then
    echo -e "${GREEN}All integration tests passed!${NC}"
else
    echo -e "${RED}Some integration tests failed (exit $TEST_EXIT)${NC}"
fi
echo -e "${BLUE}============================================${NC}"

exit $TEST_EXIT
