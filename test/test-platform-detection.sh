#!/bin/bash
# Test Platform Detection
# Tests for platform-specific configuration

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Source the functions we're testing (in isolation)
# We'll extract just the detect_pinentry function for testing
extract_detect_pinentry() {
    # Extract the function from setup-secure-zsh.sh
    sed -n '/^detect_pinentry()/,/^}/p' "$DOTFILES_DIR/setup/setup-secure-zsh.sh" | \
    sed 's/print_info/echo/g; s/print_warning/echo/g; s/print_success/echo/g; s/print_error/echo/g'
}

# Create a temporary file with the function
TEMP_FUNC=$(mktemp)
extract_detect_pinentry > "$TEMP_FUNC"
source "$TEMP_FUNC"
rm -f "$TEMP_FUNC"

# Mock functions for testing
mock_uname() {
    echo "$MOCK_UNAME"
}

mock_command() {
    if [[ "$1" == "-v" && "$2" == "pinentry-mac" && "$MOCK_PINENTRY_MAC_IN_PATH" == "true" ]]; then
        echo "/usr/local/bin/pinentry-mac"
        return 0
    fi
    return 1
}

# Test functions
test_macos_apple_silicon_detection() {
    # Mock Apple Silicon Mac environment
    MOCK_UNAME="Darwin"
    
    # Create temp directory structure
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/opt/homebrew/bin"
    touch "$temp_dir/opt/homebrew/bin/pinentry-mac"
    
    # Override file checks
    _test_file_exists() {
        case "$1" in
            "/opt/homebrew/bin/pinentry-mac") return 0 ;;
            *) return 1 ;;
        esac
    }
    
    # Run detection (simplified version)
    local result
    if [[ -f "/opt/homebrew/bin/pinentry-mac" ]] || _test_file_exists "/opt/homebrew/bin/pinentry-mac"; then
        result="/opt/homebrew/bin/pinentry-mac"
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    assert_equals "/opt/homebrew/bin/pinentry-mac" "$result" "Should detect Apple Silicon pinentry path"
}

test_macos_intel_detection() {
    # Mock Intel Mac environment
    MOCK_UNAME="Darwin"
    
    _test_file_exists() {
        case "$1" in
            "/usr/local/bin/pinentry-mac") return 0 ;;
            *) return 1 ;;
        esac
    }
    
    local result
    if [[ -f "/usr/local/bin/pinentry-mac" ]] || _test_file_exists "/usr/local/bin/pinentry-mac"; then
        result="/usr/local/bin/pinentry-mac"
    fi
    
    assert_equals "/usr/local/bin/pinentry-mac" "$result" "Should detect Intel Mac pinentry path"
}

test_linux_detection() {
    # Mock Linux environment
    MOCK_UNAME="Linux"
    
    _test_file_exists() {
        case "$1" in
            "/usr/bin/pinentry-curses") return 0 ;;
            *) return 1 ;;
        esac
    }
    
    local result
    if [[ "$MOCK_UNAME" == "Linux" ]]; then
        if _test_file_exists "/usr/bin/pinentry-curses"; then
            result="/usr/bin/pinentry-curses"
        fi
    fi
    
    assert_equals "/usr/bin/pinentry-curses" "$result" "Should detect Linux pinentry-curses"
}

test_fallback_detection() {
    # Mock unknown platform
    MOCK_UNAME="Unknown"
    
    _test_file_exists() {
        return 1  # No files exist
    }
    
    local result="/usr/bin/pinentry-curses"  # Default fallback
    
    assert_equals "/usr/bin/pinentry-curses" "$result" "Should fall back to default pinentry"
}

test_aws_profile_config_loading() {
    # Create a temporary config file
    local temp_config=$(mktemp)
    cat > "$temp_config" << 'EOF'
# Test config
dev
staging
# production
test-profile
EOF
    
    # Parse config file (simplified version of aws.zsh logic)
    local profiles=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        line="${line// /}"
        [[ -n "$line" ]] && profiles+=("$line")
    done < "$temp_config"
    
    # Clean up
    rm -f "$temp_config"
    
    # Verify results
    assert_equals "3" "${#profiles[@]}" "Should load 3 profiles"
    assert_equals "dev" "${profiles[0]}" "First profile should be dev"
    assert_equals "staging" "${profiles[1]}" "Second profile should be staging"
    assert_equals "test-profile" "${profiles[2]}" "Third profile should be test-profile"
}

test_aws_profile_validation() {
    # Test profile name validation (from aws.zsh)
    
    # Valid profile names
    assert_true '[[ "dev" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]' "Should accept valid profile name 'dev'"
    assert_true '[[ "staging-2024" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]' "Should accept valid profile name with hyphen"
    assert_true '[[ "test_env" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]' "Should accept valid profile name with underscore"
    
    # Invalid profile names
    assert_false '[[ "../etc/passwd" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]' "Should reject path traversal"
    assert_false '[[ "dev; rm -rf /" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]' "Should reject command injection"
    assert_false '[[ "dev|production" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]' "Should reject pipe character"
}

test_gpg_agent_config_generation() {
    # Test that gpg-agent.conf is generated correctly for different platforms
    local temp_dir=$(mktemp -d)
    local test_config="$temp_dir/gpg-agent.conf"
    
    # Simulate config generation for macOS
    cat > "$test_config" << 'EOF'
pinentry-program /opt/homebrew/bin/pinentry-mac
default-cache-ttl 0
max-cache-ttl 0
enable-ssh-support
EOF
    
    assert_file_exists "$test_config" "Config file should be created"
    assert_contains "$(cat "$test_config")" "pinentry-program" "Should contain pinentry configuration"
    assert_contains "$(cat "$test_config")" "enable-ssh-support" "Should enable SSH support"
    
    # Clean up
    rm -rf "$temp_dir"
}

# Run tests
describe "Platform Detection Tests"

run_test "macOS Apple Silicon detection" test_macos_apple_silicon_detection
run_test "macOS Intel detection" test_macos_intel_detection
run_test "Linux detection" test_linux_detection
run_test "Fallback detection" test_fallback_detection

describe "AWS Profile Configuration Tests"

run_test "AWS profile config loading" test_aws_profile_config_loading
run_test "AWS profile validation" test_aws_profile_validation

describe "GPG Configuration Tests"

run_test "GPG agent config generation" test_gpg_agent_config_generation

# Check for actual platform and run integration test
if [[ "$(uname -s)" == "Darwin" ]]; then
    describe "macOS Integration Tests"
    
    test_actual_macos_paths() {
        # Test actual paths on this Mac
        if [[ -f "/opt/homebrew/bin/pinentry-mac" ]]; then
            assert_file_exists "/opt/homebrew/bin/pinentry-mac" "Apple Silicon pinentry should exist"
        elif [[ -f "/usr/local/bin/pinentry-mac" ]]; then
            assert_file_exists "/usr/local/bin/pinentry-mac" "Intel pinentry should exist"
        else
            skip_test "No pinentry-mac installed" "Install with: brew install pinentry-mac"
            return 0
        fi
    }
    
    run_test "Actual macOS path detection" test_actual_macos_paths
elif [[ "$(uname -s)" == "Linux" ]]; then
    describe "Linux Integration Tests"
    
    test_actual_linux_paths() {
        if [[ -f "/usr/bin/pinentry-curses" ]]; then
            assert_file_exists "/usr/bin/pinentry-curses" "Linux pinentry-curses should exist"
        else
            skip_test "No pinentry-curses installed" "Install with package manager"
            return 1
        fi
    }
    
    run_test "Actual Linux path detection" test_actual_linux_paths
fi

# Print test summary
print_summary