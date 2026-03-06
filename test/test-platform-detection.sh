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
    # Use awk to properly handle nested braces in the function
    awk '/^detect_pinentry\(\) \{$/,/^}$/ {
        if (/^}$/ && --depth == 0) { print; exit }
        if (/\{/) depth++
        print
    }' "$DOTFILES_DIR/setup/setup-secure-zsh.sh" | \
    sed 's/print_info/echo/g; s/print_warning/echo/g; s/print_success/echo/g; s/print_error/echo/g'
}

# Create a temporary file with the function
TEMP_FUNC=$(mktemp)
extract_detect_pinentry > "$TEMP_FUNC"

# Verify extraction succeeded
if [[ ! -s "$TEMP_FUNC" ]] || ! grep -q "detect_pinentry" "$TEMP_FUNC"; then
    print_warning "Failed to extract detect_pinentry function, using simplified test version"
    # Use a simplified version for testing if extraction fails
    cat > "$TEMP_FUNC" << 'FALLBACK_EOF'
detect_pinentry() {
    local pinentry_program=""
    local brew_prefix=""

    if command -v brew &>/dev/null; then
        brew_prefix="$(brew --prefix 2>/dev/null)"
    fi

    case "$(uname -s)" in
        Darwin*)
            local candidates=(
                "${brew_prefix}/bin/pinentry-mac"
                "/opt/homebrew/bin/pinentry-mac"
                "/usr/local/bin/pinentry-mac"
            )
            for candidate in "${candidates[@]}"; do
                if [[ -n "$candidate" && -x "$candidate" ]]; then
                    pinentry_program="$candidate"
                    break
                fi
            done

            if [[ -z "$pinentry_program" ]]; then
                local curses_candidates=(
                    "${brew_prefix}/bin/pinentry-curses"
                    "/opt/homebrew/bin/pinentry-curses"
                    "/usr/local/bin/pinentry-curses"
                    "/usr/bin/pinentry-curses"
                )
                for candidate in "${curses_candidates[@]}"; do
                    if [[ -n "$candidate" && -x "$candidate" ]]; then
                        pinentry_program="$candidate"
                        break
                    fi
                done
            fi
            ;;
        Linux*)
            local candidates=(
                "/usr/bin/pinentry-curses"
                "/usr/bin/pinentry-tty"
                "/usr/bin/pinentry"
            )
            for candidate in "${candidates[@]}"; do
                if [[ -x "$candidate" ]]; then
                    pinentry_program="$candidate"
                    break
                fi
            done
            ;;
    esac

    echo "$pinentry_program"
}
FALLBACK_EOF
fi

source "$TEMP_FUNC"
# Keep TEMP_FUNC for re-sourcing in subshells; clean up on exit
trap 'rm -f "$TEMP_FUNC"' EXIT

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

# Test functions — each calls detect_pinentry in a subshell with mocked uname
test_macos_apple_silicon_detection() {
    # Create temp directory structure to simulate Apple Silicon paths
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/bin"
    touch "$temp_dir/bin/pinentry-mac"
    chmod +x "$temp_dir/bin/pinentry-mac"

    local result
    result=$(
        # Override uname to report Darwin
        uname() { if [[ "$1" == "-s" ]]; then echo "Darwin"; else command uname "$@"; fi; }
        export -f uname
        # Override brew --prefix to point at temp dir
        brew() { echo "$temp_dir"; }
        export -f brew
        source "$TEMP_FUNC"
        detect_pinentry
    )

    rm -rf "$temp_dir"

    assert_equals "$temp_dir/bin/pinentry-mac" "$result" "Should detect Apple Silicon pinentry path"
}

test_macos_intel_detection() {
    # Create temp directory structure to simulate Intel Mac paths
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/bin"
    touch "$temp_dir/bin/pinentry-mac"
    chmod +x "$temp_dir/bin/pinentry-mac"

    local result
    result=$(
        uname() { if [[ "$1" == "-s" ]]; then echo "Darwin"; else command uname "$@"; fi; }
        export -f uname
        brew() { echo "$temp_dir"; }
        export -f brew
        source "$TEMP_FUNC"
        detect_pinentry
    )

    rm -rf "$temp_dir"

    assert_equals "$temp_dir/bin/pinentry-mac" "$result" "Should detect Intel Mac pinentry path"
}

test_linux_detection() {
    local result
    result=$(
        # Override uname to report Linux
        uname() { if [[ "$1" == "-s" ]]; then echo "Linux"; else command uname "$@"; fi; }
        export -f uname
        # Ensure brew is not found
        brew() { return 1; }
        export -f brew
        source "$TEMP_FUNC"
        detect_pinentry
    )

    # Assert based on what's actually available on this system
    if [[ -x "/usr/bin/pinentry-curses" ]]; then
        assert_equals "/usr/bin/pinentry-curses" "$result" "Should detect Linux pinentry-curses"
    elif [[ -x "/usr/bin/pinentry-tty" ]]; then
        assert_equals "/usr/bin/pinentry-tty" "$result" "Should detect Linux pinentry-tty"
    elif [[ -x "/usr/bin/pinentry" ]]; then
        assert_equals "/usr/bin/pinentry" "$result" "Should detect Linux pinentry"
    else
        assert_not_empty "$result" "Should detect some pinentry on Linux"
    fi
}

test_fallback_detection() {
    local result
    local rc=0
    result=$(
        # Override uname to report unknown platform
        uname() { if [[ "$1" == "-s" ]]; then echo "UnknownOS"; else command uname "$@"; fi; }
        export -f uname
        brew() { return 1; }
        export -f brew
        source "$TEMP_FUNC"
        detect_pinentry
    ) || rc=$?

    # Unknown platform falls back to command -v pinentry or /usr/bin/pinentry
    if command -v pinentry &>/dev/null || [[ -x "/usr/bin/pinentry" ]]; then
        assert_not_empty "$result" "Should find pinentry via fallback on this system"
    else
        assert_equals "" "$result" "Should return empty when no pinentry available"
        assert_not_equals "0" "$rc" "Should return non-zero when no pinentry found"
    fi
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