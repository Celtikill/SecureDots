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

# macOS-specific assertion functions
assert_macos_architecture() {
    local expected_arch="$1"
    local message="${2:-Architecture should match expected}"
    
    local actual_arch
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        actual_arch="arm64"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        actual_arch="x86_64"
    else
        actual_arch="unknown"
    fi
    
    if [[ "$expected_arch" == "$actual_arch" ]]; then
        return 0
    else
        echo "  Expected architecture: $expected_arch"
        echo "  Detected architecture: $actual_arch"
        return 1
    fi
}

assert_homebrew_path() {
    local expected_path="$1"
    local message="${2:-Homebrew path should match expected}"
    
    local actual_path
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        actual_path="/opt/homebrew"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        actual_path="/usr/local"
    else
        actual_path="not_found"
    fi
    
    if [[ "$expected_path" == "$actual_path" ]]; then
        return 0
    else
        echo "  Expected Homebrew path: $expected_path"
        echo "  Detected Homebrew path: $actual_path"
        return 1
    fi
}

assert_pinentry_path() {
    local expected_path="$1"
    local message="${2:-Pinentry path should match expected}"
    
    if [[ -f "$expected_path" ]]; then
        return 0
    else
        echo "  Pinentry not found at: $expected_path"
        return 1
    fi
}

assert_gpg_config() {
    local config_file="$1"
    local expected_setting="$2"
    local message="${3:-GPG config should contain expected setting}"
    
    if [[ -f "$config_file" ]] && grep -q "$expected_setting" "$config_file"; then
        return 0
    else
        echo "  Config file: $config_file"
        echo "  Missing setting: $expected_setting"
        return 1
    fi
}

# Performance measurement functions
benchmark_start() {
    local test_name="$1"
    echo "$test_name:$(date +%s.%N)" > "/tmp/benchmark_${test_name// /_}.start"
}

benchmark_end() {
    local test_name="$1"
    local start_file="/tmp/benchmark_${test_name// /_}.start"
    
    if [[ -f "$start_file" ]]; then
        local start_time=$(cat "$start_file" | cut -d: -f2)
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        echo "  Duration: ${duration}s"
        rm -f "$start_file"
        return 0
    else
        echo "  No benchmark start found for: $test_name"
        return 1
    fi
}

measure_shell_startup() {
    local shell_config="$1"
    local iterations="${2:-3}"
    local total_time=0
    
    print_info "Measuring shell startup time ($iterations iterations)"
    
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s.%N)
        # Simulate shell startup by sourcing config
        (source "$shell_config" 2>/dev/null) || true
        local end_time=$(date +%s.%N)
        local iteration_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        total_time=$(echo "$total_time + $iteration_time" | bc -l 2>/dev/null || echo "$total_time")
        echo "    Iteration $i: ${iteration_time}s"
    done
    
    local avg_time=$(echo "scale=3; $total_time / $iterations" | bc -l 2>/dev/null || echo "0")
    echo "  Average startup time: ${avg_time}s"
    
    # Return 0 if under 1 second, 1 if over
    local threshold_check=$(echo "$avg_time < 1.0" | bc -l 2>/dev/null || echo "0")
    [[ "$threshold_check" == "1" ]]
}

# Hardware simulation functions
mock_yubikey_present() {
    export MOCK_YUBIKEY_STATUS="present"
    export MOCK_GPG_CARD_STATUS="Card available
Application ID : D2760001240102010006123456780000
Application type : OpenPGP
Version : 2.1
Manufacturer : Yubico
Serial number : 12345678
Name of cardholder : [not set]
Language prefs : [not set]
Sex : unspecified
URL of public key : [not set]
Login data : [not set]
Signature PIN : not forced
Key attributes : rsa2048 rsa2048 rsa2048
Max. PIN lengths : 127 127 127
PIN retry counter : 3 0 3
Signature counter : 0
Signature key : [none]
Encryption key : [none]
Authentication key: [none]
General key info..: [none]"
}

mock_yubikey_absent() {
    export MOCK_YUBIKEY_STATUS="absent"
    export MOCK_GPG_CARD_STATUS="gpg: selecting card failed: No such device"
}

mock_gpg_command() {
    local command="$1"
    shift
    local args="$*"
    
    case "$command" in
        "--card-status")
            if [[ "$MOCK_YUBIKEY_STATUS" == "present" ]]; then
                echo "$MOCK_GPG_CARD_STATUS"
                return 0
            else
                echo "gpg: selecting card failed: No such device"
                return 2
            fi
            ;;
        "--list-secret-keys")
            if [[ "$MOCK_GPG_KEYS" == "present" ]]; then
                echo "sec   rsa4096/ABCD1234EFGH5678 2024-01-15 [SC]
      1234567890ABCDEF1234567890ABCDEF12345678
uid                 [ultimate] Test User <test@example.com>
ssb   rsa4096/1234ABCD5678EFGH 2024-01-15 [E]"
                return 0
            else
                return 2
            fi
            ;;
        *)
            # Default to success for other commands
            return 0
            ;;
    esac
}

# Test environment setup/teardown
setup_test_environment() {
    local test_name="$1"
    export TEST_ENV_DIR="/tmp/dotfiles_test_${test_name}_$$"
    export TEST_HOME="$TEST_ENV_DIR/home"
    export TEST_CONFIG_DIR="$TEST_HOME/.config"
    export TEST_GNUPG_DIR="$TEST_HOME/.gnupg"
    export TEST_AWS_DIR="$TEST_HOME/.aws"
    
    mkdir -p "$TEST_HOME" "$TEST_CONFIG_DIR" "$TEST_GNUPG_DIR" "$TEST_AWS_DIR"
    
    # Set up minimal environment
    export HOME="$TEST_HOME"
    export GNUPGHOME="$TEST_GNUPG_DIR"
    
    print_info "Test environment created: $TEST_ENV_DIR"
}

cleanup_test_environment() {
    if [[ -n "${TEST_ENV_DIR:-}" && -d "${TEST_ENV_DIR:-}" ]]; then
        rm -rf "$TEST_ENV_DIR"
        print_info "Test environment cleaned up"
    fi
    
    # Reset environment variables safely
    unset TEST_ENV_DIR TEST_HOME TEST_CONFIG_DIR TEST_GNUPG_DIR TEST_AWS_DIR 2>/dev/null || true
    unset MOCK_YUBIKEY_STATUS MOCK_GPG_CARD_STATUS MOCK_GPG_KEYS 2>/dev/null || true
}

# Enhanced file testing
assert_file_permissions() {
    local file="$1"
    local expected_perms="$2"
    local message="${3:-File permissions should match expected}"
    
    if [[ ! -f "$file" ]]; then
        echo "  File not found: $file"
        return 1
    fi
    
    local actual_perms=$(stat -f "%OLp" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null)
    
    if [[ "$expected_perms" == "$actual_perms" ]]; then
        return 0
    else
        echo "  File: $file"
        echo "  Expected permissions: $expected_perms"
        echo "  Actual permissions: $actual_perms"
        return 1
    fi
}

assert_no_credential_exposure() {
    local file_or_output="$1"
    local message="${2:-Should not contain credentials}"
    
    # Common credential patterns to avoid
    local patterns=(
        "AKIA[A-Z0-9]{16}"  # AWS Access Key ID
        "[A-Za-z0-9/+=]{40}"  # AWS Secret Key (basic check)
        "BEGIN [A-Z]+ PRIVATE KEY"  # Private keys
        "password.*[:=]"  # Password fields
        "secret.*[:=]"  # Secret fields
    )
    
    local content
    if [[ -f "$file_or_output" ]]; then
        content=$(cat "$file_or_output")
    else
        content="$file_or_output"
    fi
    
    for pattern in "${patterns[@]}"; do
        if echo "$content" | grep -qE "$pattern"; then
            echo "  Found potential credential pattern: $pattern"
            return 1
        fi
    done
    
    return 0
}

# Export all functions for use in test files
export -f assert_equals
export -f assert_not_equals
export -f assert_true
export -f assert_false
export -f assert_file_exists
export -f assert_dir_exists
export -f assert_command_exists
export -f assert_contains
export -f assert_not_contains
export -f assert_macos_architecture
export -f assert_homebrew_path
export -f assert_pinentry_path
export -f assert_gpg_config
export -f assert_file_permissions
export -f assert_no_credential_exposure
export -f benchmark_start
export -f benchmark_end
export -f measure_shell_startup
export -f mock_yubikey_present
export -f mock_yubikey_absent
export -f mock_gpg_command
export -f setup_test_environment
export -f cleanup_test_environment
export -f run_test
export -f skip_test
export -f describe
export -f print_summary
export -f print_success
export -f print_error
export -f print_warning
export -f print_info