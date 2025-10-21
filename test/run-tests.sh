#!/bin/bash
# Main test runner for SecureDots
# ================================

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================="
echo "SecureDots Test Suite"
echo "=================================="
echo "Running tests from: $SCRIPT_DIR"
echo ""

# Track overall results
TOTAL_SUITES=0
FAILED_SUITES=0
declare -a FAILED_SUITE_NAMES=()

# Find and run all test files
for test_file in "$SCRIPT_DIR"/test-*.sh; do
    if [[ -f "$test_file" ]]; then
        test_name=$(basename "$test_file" .sh)
        echo -e "${BLUE}Running suite: $test_name${NC}"
        echo "-----------------------------------"
        
        TOTAL_SUITES=$((TOTAL_SUITES + 1))
        
        if bash "$test_file"; then
            echo -e "${GREEN}✓ Suite passed: $test_name${NC}"
        else
            echo -e "${RED}✗ Suite failed: $test_name${NC}"
            FAILED_SUITES=$((FAILED_SUITES + 1))
            FAILED_SUITE_NAMES+=("$test_name")
        fi
        echo ""
    fi
done

# Overall summary
echo "=================================="
echo "Overall Test Results"
echo "=================================="
echo "Total suites run: $TOTAL_SUITES"
echo -e "Suites passed: ${GREEN}$((TOTAL_SUITES - FAILED_SUITES))${NC}"

if [[ $FAILED_SUITES -gt 0 ]]; then
    echo -e "Suites failed: ${RED}$FAILED_SUITES${NC}"
    echo ""
    echo "Failed suites:"
    for suite in "${FAILED_SUITE_NAMES[@]}"; do
        echo "  - $suite"
    done
    exit 1
else
    echo ""
    echo -e "${GREEN}All test suites passed!${NC}"
    exit 0
fi