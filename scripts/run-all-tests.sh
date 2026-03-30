#!/usr/bin/env bash
#
# Run all tests: toolkit unit/integration tests + all example app tests.
#
# Discovers example apps in ./examples/ and runs:
#   - Unit tests (xcodebuild test targets ending in "Tests", not "UITests")
#   - E2E tests (run-ui-tests.sh if present, or xcodebuild UITests targets)
#
# Credentials are loaded from ./.env (TEST_USER, TEST_PASSWORD).
#
# Usage:
#   ./scripts/run-all-tests.sh
#   PROXY_URL=https://my-proxy.workers.dev ./scripts/run-all-tests.sh
#   SKIP_INTEGRATION=1 ./scripts/run-all-tests.sh   # skip live API tests
#   SKIP_E2E=1 ./scripts/run-all-tests.sh           # skip E2E/UI tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROXY_URL="${PROXY_URL:-http://127.0.0.1:3333}"
CREDENTIALS_FILE="$PROJECT_DIR/test-credentials.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASSED=()
FAILED=()
SKIPPED=()

cleanup() {
    rm -f "$CREDENTIALS_FILE"
    # Clean up per-example credential files
    for f in "$PROJECT_DIR"/examples/*/ui-test-credentials.json; do
        rm -f "$f" 2>/dev/null
    done
}
trap cleanup EXIT

# ── Load credentials from .env ───────────────────────────────────────────
ENV_FILE="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
    echo -e "${GREEN}Loaded credentials from .env${NC}"
else
    echo -e "${YELLOW}Warning: No .env file found at $ENV_FILE${NC}"
    echo "Create one with TEST_USER and TEST_PASSWORD for E2E/integration tests."
fi

# ── Helper: find simulator ───────────────────────────────────────────────
find_simulator() {
    if [ -n "${SIMULATOR_ID:-}" ]; then
        echo "$SIMULATOR_ID"
        return
    fi
    xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
booted = []
available = []
for runtime, devices in sorted(data['devices'].items(), reverse=True):
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if not d.get('isAvailable', False) or 'iPhone' not in d.get('name', ''):
            continue
        if d.get('state') == 'Booted':
            booted.append(d['udid'])
        else:
            available.append(d['udid'])
for udid in booted + available:
    print(udid)
    sys.exit(0)
" 2>/dev/null || true
}

# ── Helper: record result ────────────────────────────────────────────────
record_result() {
    local name="$1" exit_code="$2"
    if [ "$exit_code" -eq 0 ]; then
        PASSED+=("$name")
    else
        FAILED+=("$name")
    fi
}

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Run All Tests${NC}"
echo -e "${BLUE}============================================${NC}"
echo "Proxy: $PROXY_URL"
echo ""

# ── Ensure local proxy is running ───────────────────────────────────────
if [ "${SKIP_INTEGRATION:-}" != "1" ]; then
    echo -e "${BLUE}[0] Ensuring local proxy is running${NC}"
    echo "────────────────────────────────────────────"
    "$SCRIPT_DIR/ensure-proxy.sh"
    echo ""
fi

# ══════════════════════════════════════════════════════════════════════════
# 1. Toolkit unit tests
# ══════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}[1] Toolkit unit tests (swift test)${NC}"
echo "────────────────────────────────────────────"
cd "$PROJECT_DIR"
set +e
swift test --skip LiveServiceTests 2>&1 | tail -5
UNIT_EXIT=${PIPESTATUS[0]}
set -e
record_result "Toolkit unit tests" "$UNIT_EXIT"
echo ""

# ══════════════════════════════════════════════════════════════════════════
# 2. Toolkit integration tests (live API)
# ══════════════════════════════════════════════════════════════════════════
if [ "${SKIP_INTEGRATION:-}" = "1" ]; then
    echo -e "${YELLOW}[2] Toolkit integration tests — SKIPPED (SKIP_INTEGRATION=1)${NC}"
    SKIPPED+=("Toolkit integration tests")
    echo ""
else
    echo -e "${BLUE}[2] Toolkit integration tests${NC}"
    echo "────────────────────────────────────────────"

    # Install Node deps if needed
    cd "$PROJECT_DIR"
    if [ ! -d "node_modules" ]; then
        echo "Installing Node dependencies..."
        npm install
        npx playwright install chromium
    fi

    # Acquire credentials
    echo "Acquiring test credentials..."
    PROXY_URL="$PROXY_URL" node scripts/get-test-token.js
    if [ ! -f "$CREDENTIALS_FILE" ]; then
        echo -e "${RED}Token acquisition failed${NC}"
        FAILED+=("Toolkit integration tests")
    else
        set +e
        PROXY_URL="$PROXY_URL" swift test --filter LiveServiceTests 2>&1 | tail -5
        INT_EXIT=${PIPESTATUS[0]}
        set -e
        record_result "Toolkit integration tests" "$INT_EXIT"
    fi
    echo ""
fi

# ══════════════════════════════════════════════════════════════════════════
# 3. Discover and test example apps
# ══════════════════════════════════════════════════════════════════════════
EXAMPLES_DIR="$PROJECT_DIR/examples"
SIMULATOR=""
STEP=2

for EXAMPLE_DIR in "$EXAMPLES_DIR"/*/; do
    [ ! -d "$EXAMPLE_DIR" ] && continue
    EXAMPLE_NAME=$(basename "$EXAMPLE_DIR")

    # Find the Xcode project
    XCODEPROJ=$(find "$EXAMPLE_DIR" -maxdepth 2 -name "*.xcodeproj" -type d | head -1)
    if [ -z "$XCODEPROJ" ]; then
        continue
    fi

    # Get scheme name (same as project name without .xcodeproj)
    SCHEME=$(basename "$XCODEPROJ" .xcodeproj)

    # Discover test targets
    TARGETS=$(xcodebuild -project "$XCODEPROJ" -list 2>/dev/null \
        | sed -n '/Targets:/,/Build Configurations:/p' \
        | grep -v "Targets:" | grep -v "Build Configurations:" \
        | sed 's/^[[:space:]]*//' | grep -v "^$" || true)

    UNIT_TARGETS=$(echo "$TARGETS" | grep "Tests$" | grep -v "UITests$" || true)
    UI_TARGETS=$(echo "$TARGETS" | grep "UITests$" || true)

    # ── Unit tests ────────────────────────────────────────────────────
    if [ -n "$UNIT_TARGETS" ]; then
        STEP=$((STEP + 1))
        echo -e "${BLUE}[$STEP] $EXAMPLE_NAME — unit tests${NC}"
        echo "────────────────────────────────────────────"

        # Find simulator lazily
        if [ -z "$SIMULATOR" ]; then
            SIMULATOR=$(find_simulator)
            if [ -z "$SIMULATOR" ]; then
                echo -e "${RED}No iOS simulator found${NC}"
                FAILED+=("$EXAMPLE_NAME unit tests")
                echo ""
                continue
            fi
            # Boot if needed
            SIM_STATE=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIMULATOR':
            print(d['state']); sys.exit(0)
")
            if [ "$SIM_STATE" != "Booted" ]; then
                xcrun simctl boot "$SIMULATOR" 2>/dev/null || true
            fi
            SIM_NAME=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIMULATOR':
            print(d['name']); sys.exit(0)
")
            echo "Simulator: $SIM_NAME ($SIMULATOR)"
        fi

        # Build -only-testing args for each unit test target
        ONLY_TESTING=""
        while IFS= read -r target; do
            [ -z "$target" ] && continue
            ONLY_TESTING="$ONLY_TESTING -only-testing:$target"
        done <<< "$UNIT_TARGETS"

        set +e
        xcodebuild test \
            -project "$XCODEPROJ" \
            -scheme "$SCHEME" \
            -destination "id=$SIMULATOR" \
            $ONLY_TESTING \
            2>&1 | grep -E '(Test Case|Test suite|passed|failed|skipped|\*\* TEST)' | tail -20
        UT_EXIT=${PIPESTATUS[0]}
        set -e
        record_result "$EXAMPLE_NAME unit tests" "$UT_EXIT"
        echo ""
    fi

    # ── E2E / UI tests ───────────────────────────────────────────────
    if [ -n "$UI_TARGETS" ] && [ "${SKIP_E2E:-}" != "1" ]; then
        STEP=$((STEP + 1))
        echo -e "${BLUE}[$STEP] $EXAMPLE_NAME — E2E tests${NC}"
        echo "────────────────────────────────────────────"

        # Use run-ui-tests.sh if available (it handles credential injection)
        if [ -x "$EXAMPLE_DIR/run-ui-tests.sh" ]; then
            set +e
            PROXY_URL="$PROXY_URL" SIMULATOR_ID="${SIMULATOR:-}" \
                bash "$EXAMPLE_DIR/run-ui-tests.sh" 2>&1 \
                | grep -E '(Test Case|Test suite|passed|failed|skipped|\*\* TEST|Credentials|Error)' | tail -20
            E2E_EXIT=${PIPESTATUS[0]}
            set -e
            record_result "$EXAMPLE_NAME E2E tests" "$E2E_EXIT"
        else
            # No script — run UITests directly via xcodebuild
            if [ -z "$SIMULATOR" ]; then
                SIMULATOR=$(find_simulator)
                if [ -z "$SIMULATOR" ]; then
                    echo -e "${RED}No iOS simulator found${NC}"
                    FAILED+=("$EXAMPLE_NAME E2E tests")
                    echo ""
                    continue
                fi
                SIM_STATE=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIMULATOR':
            print(d['state']); sys.exit(0)
")
                if [ "$SIM_STATE" != "Booted" ]; then
                    xcrun simctl boot "$SIMULATOR" 2>/dev/null || true
                fi
            fi

            # Ensure we have credentials for injection
            if [ ! -f "$CREDENTIALS_FILE" ]; then
                "$SCRIPT_DIR/ensure-proxy.sh"
                cd "$PROJECT_DIR"
                if [ ! -d "node_modules" ]; then
                    npm install
                    npx playwright install chromium
                fi
                PROXY_URL="$PROXY_URL" node scripts/get-test-token.js || true
            fi

            # Write per-example credentials file
            if [ -f "$CREDENTIALS_FILE" ]; then
                python3 -c "
import json
creds = json.load(open('$CREDENTIALS_FILE'))
creds['expiresIn'] = str(creds.get('expiresIn', 3600))
with open('$EXAMPLE_DIR/ui-test-credentials.json', 'w') as f:
    json.dump(creds, f, indent=2)
"
            fi

            ONLY_TESTING=""
            while IFS= read -r target; do
                [ -z "$target" ] && continue
                ONLY_TESTING="$ONLY_TESTING -only-testing:$target"
            done <<< "$UI_TARGETS"

            set +e
            xcodebuild test \
                -project "$XCODEPROJ" \
                -scheme "$SCHEME" \
                -destination "id=$SIMULATOR" \
                $ONLY_TESTING \
                2>&1 | grep -E '(Test Case|Test suite|passed|failed|skipped|\*\* TEST)' | tail -20
            E2E_EXIT=${PIPESTATUS[0]}
            set -e
            record_result "$EXAMPLE_NAME E2E tests" "$E2E_EXIT"
        fi
        echo ""
    elif [ -n "$UI_TARGETS" ] && [ "${SKIP_E2E:-}" = "1" ]; then
        SKIPPED+=("$EXAMPLE_NAME E2E tests")
    fi
done

# ══════════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}============================================${NC}"

for name in "${PASSED[@]+"${PASSED[@]}"}"; do
    echo -e "  ${GREEN}PASS${NC}  $name"
done
for name in "${SKIPPED[@]+"${SKIPPED[@]}"}"; do
    echo -e "  ${YELLOW}SKIP${NC}  $name"
done
for name in "${FAILED[@]+"${FAILED[@]}"}"; do
    echo -e "  ${RED}FAIL${NC}  $name"
done

TOTAL=$(( ${#PASSED[@]} + ${#FAILED[@]} + ${#SKIPPED[@]} ))
echo ""
echo -e "  Total: $TOTAL  |  ${GREEN}Passed: ${#PASSED[@]}${NC}  |  ${RED}Failed: ${#FAILED[@]}${NC}  |  ${YELLOW}Skipped: ${#SKIPPED[@]}${NC}"
echo -e "${BLUE}============================================${NC}"

if [ ${#FAILED[@]} -gt 0 ]; then
    exit 1
fi
exit 0
