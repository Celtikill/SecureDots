#!/bin/bash
# Test Framework for SecureDots
# ==============================
# Simple but effective test framework for shell scripts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test results storage
declare -a FAILED_TESTS=()

# Helper functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    if [[ "$unexpected" != "$actual" ]]; then
        return 0
    else
        echo "  Values are equal: '$actual'"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Condition should be true}"
    
    if eval "$condition"; then
        return 0
    else
        echo "  Condition failed: $condition"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Condition should be false}"
    
    if ! eval "$condition"; then
        return 0
    else
        echo "  Condition succeeded when it should have failed: $condition"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    if [[ -f "$file" ]]; then
        return 0
    else
        echo "  File not found: $file"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist}"
    
    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "  Directory not found: $dir"
        return 1
    fi
}

assert_command_exists() {
    local cmd="$1"
    local message="${2:-Command should exist}"
    
    if command -v "$cmd" &>/dev/null; then
        return 0
    else
        echo "  Command not found: $cmd"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "  String: '$haystack'"
        echo "  Does not contain: '$needle'"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain substring}"
    
    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        echo "  String: '$haystack'"
        echo "  Contains: '$needle'"
        return 1
    fi
}

# Test runner functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "  $test_name ... "
    
    # Run test in subshell to isolate environment
    if ( $test_function ) &>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        # Re-run with output for debugging
        echo "    Details:"
        ( $test_function ) 2>&1 | sed 's/^/      /'
    fi
}

skip_test() {
    local test_name="$1"
    local reason="${2:-No reason given}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    
    echo -e "  $test_name ... ${YELLOW}SKIP${NC} ($reason)"
}

# Test suite functions
describe() {
    local suite_name="$1"
    echo ""
    echo "Testing: $suite_name"
    echo "=================================="
}

# Summary function
print_summary() {
    echo ""
    echo "Test Summary"
    echo "============"
    echo "Total:   $TESTS_RUN"
    echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
    [[ $TESTS_FAILED -gt 0 ]] && echo -e "Failed:  ${RED}$TESTS_FAILED${NC}" || echo "Failed:  $TESTS_FAILED"
    [[ $TESTS_SKIPPED -gt 0 ]] && echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}" || echo "Skipped: $TESTS_SKIPPED"
    
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo ""
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
    fi
    
    echo ""
    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_success "All tests passed!"
        return 0
    else
        print_error "Some tests failed!"
        return 1
    fi
}

# Setup and teardown hooks
setup() {
    # Override in test files if needed
    return 0
}

teardown() {
    # Override in test files if needed
    return 0
}

# Export functions for use in test files
export -f assert_equals
export -f assert_not_equals
export -f assert_true
export -f assert_false
export -f assert_file_exists
export -f assert_dir_exists
export -f assert_command_exists
export -f assert_contains
export -f assert_not_contains
export -f run_test
export -f skip_test
export -f describe
export -f print_summary
export -f print_success
export -f print_error
export -f print_warning
export -f print_info