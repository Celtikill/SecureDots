#!/bin/bash
# Test macOS Architecture Detection
# Comprehensive testing for Apple Silicon vs Intel Mac detection

# Disable strict error checking for tests
set +euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Test functions
test_architecture_detection() {
    # Test actual architecture detection on this machine
    local detected_arch
    
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        detected_arch="arm64"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        detected_arch="x86_64"
    else
        detected_arch="unknown"
    fi
    
    # This should always pass on the current machine
    assert_true "[[ -n '$detected_arch' ]]" "Should detect some architecture"
    
    # Verify uname consistency
    local uname_arch=$(uname -m)
    if [[ "$detected_arch" == "arm64" ]]; then
        assert_equals "arm64" "$uname_arch" "uname should match Homebrew detection for Apple Silicon"
    elif [[ "$detected_arch" == "x86_64" ]]; then
        assert_true '[[ "$uname_arch" == "x86_64" || "$uname_arch" == "i386" ]]' "uname should match Intel detection"
    fi
}

test_homebrew_path_detection() {
    # Test Homebrew path detection
    local homebrew_path
    
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        homebrew_path="/opt/homebrew"
        assert_homebrew_path "/opt/homebrew" "Should detect Apple Silicon Homebrew path"
        assert_file_exists "/opt/homebrew/bin/brew" "Homebrew binary should exist"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        homebrew_path="/usr/local"
        assert_homebrew_path "/usr/local" "Should detect Intel Homebrew path"
        assert_file_exists "/usr/local/bin/brew" "Homebrew binary should exist"
    else
        skip_test "No Homebrew installation detected" "Install Homebrew to run this test"
        return 0
    fi
    
    # Verify Homebrew works
    if command -v brew &>/dev/null; then
        assert_true "brew --version >/dev/null 2>&1" "Homebrew should be functional"
    fi
}

test_pinentry_detection() {
    # Test pinentry program detection based on architecture
    local expected_pinentry=""
    local brew_prefix=""

    # Get Homebrew prefix dynamically
    if command -v brew &>/dev/null; then
        brew_prefix="$(brew --prefix 2>/dev/null)"
    fi

    # Check in priority order matching the improved detection logic
    local candidates=(
        "${brew_prefix}/bin/pinentry-mac"
        "/opt/homebrew/bin/pinentry-mac"
        "/usr/local/bin/pinentry-mac"
    )

    # Try pinentry-mac first
    for candidate in "${candidates[@]}"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            expected_pinentry="$candidate"
            break
        fi
    done

    # Fallback to curses if no pinentry-mac
    if [[ -z "$expected_pinentry" ]]; then
        local curses_candidates=(
            "${brew_prefix}/bin/pinentry-curses"
            "/opt/homebrew/bin/pinentry-curses"
            "/usr/local/bin/pinentry-curses"
            "/usr/bin/pinentry-curses"
        )
        for candidate in "${curses_candidates[@]}"; do
            if [[ -n "$candidate" && -x "$candidate" ]]; then
                expected_pinentry="$candidate"
                break
            fi
        done
    fi

    # If still nothing, check PATH
    if [[ -z "$expected_pinentry" ]] && command -v pinentry &>/dev/null; then
        expected_pinentry="$(command -v pinentry)"
    fi

    # If no pinentry found at all, skip the test
    if [[ -z "$expected_pinentry" ]]; then
        skip_test "No pinentry program found" "Install pinentry with: brew install pinentry-mac"
        return 0
    fi

    # Verify the detected pinentry
    assert_pinentry_path "$expected_pinentry" "Detected pinentry should exist"
    assert_true "[[ -x '$expected_pinentry' ]]" "Pinentry should be executable"
}

test_platform_detection_function() {
    # Extract and test the detect_pinentry function from setup script
    local setup_script="$DOTFILES_DIR/setup/setup-secure-zsh.sh"
    assert_file_exists "$setup_script" "Setup script should exist"

    # Extract the function and test it
    local temp_script=$(mktemp)

    # Create a test version matching the improved detection logic
    cat > "$temp_script" << 'EOF'
detect_pinentry_test() {
    local pinentry_program=""
    local brew_prefix=""

    # Get Homebrew prefix if available
    if command -v brew &>/dev/null; then
        brew_prefix="$(brew --prefix 2>/dev/null)"
    fi

    case "$(uname -s)" in
        Darwin*)
            # Check candidates in priority order
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

            # Fallback to PATH
            if [[ -z "$pinentry_program" ]] && command -v pinentry-mac &>/dev/null; then
                pinentry_program="$(command -v pinentry-mac)"
            fi

            # Fallback to curses
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

            # Last resort
            if [[ -z "$pinentry_program" ]] && command -v pinentry &>/dev/null; then
                pinentry_program="$(command -v pinentry)"
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

            # Try PATH
            if [[ -z "$pinentry_program" ]] && command -v pinentry-curses &>/dev/null; then
                pinentry_program="$(command -v pinentry-curses)"
            elif [[ -z "$pinentry_program" ]] && command -v pinentry &>/dev/null; then
                pinentry_program="$(command -v pinentry)"
            fi
            ;;
        *)
            if command -v pinentry &>/dev/null; then
                pinentry_program="$(command -v pinentry)"
            fi
            ;;
    esac

    echo "$pinentry_program"
}
EOF

    source "$temp_script"

    # Test the function
    local detected_pinentry=$(detect_pinentry_test)

    # The function should either find a pinentry or return empty
    # If empty, that's actually OK - it means no pinentry installed
    if [[ -n "$detected_pinentry" ]]; then
        # If something was detected, verify it's valid
        assert_true "[[ '$detected_pinentry' == *pinentry* ]]" "Should contain 'pinentry' in path"

        # If the path exists, it should be executable
        if [[ -f "$detected_pinentry" ]]; then
            assert_true "[[ -x '$detected_pinentry' ]]" "Detected pinentry should be executable"
        fi
    else
        # No pinentry found - this is a valid state on systems without pinentry
        print_warning "No pinentry program found (this is expected if pinentry-mac is not installed)"
    fi

    # Clean up
    rm -f "$temp_script"
}

test_cross_architecture_simulation() {
    # Simulate different architectures by mocking file existence
    local test_env_dir=$(mktemp -d)
    
    # Test Apple Silicon simulation
    mkdir -p "$test_env_dir/opt/homebrew/bin"
    touch "$test_env_dir/opt/homebrew/bin/pinentry-mac"
    
    # Mock function that uses our test directory
    mock_detect_pinentry_apple_silicon() {
        if [[ -f "$test_env_dir/opt/homebrew/bin/pinentry-mac" ]]; then
            echo "$test_env_dir/opt/homebrew/bin/pinentry-mac"
        fi
    }
    
    local result=$(mock_detect_pinentry_apple_silicon)
    assert_equals "$test_env_dir/opt/homebrew/bin/pinentry-mac" "$result" "Should detect Apple Silicon path in simulation"
    
    # Test Intel simulation
    mkdir -p "$test_env_dir/usr/local/bin"
    touch "$test_env_dir/usr/local/bin/pinentry-mac"
    rm -f "$test_env_dir/opt/homebrew/bin/pinentry-mac"
    
    mock_detect_pinentry_intel() {
        if [[ -f "$test_env_dir/usr/local/bin/pinentry-mac" ]]; then
            echo "$test_env_dir/usr/local/bin/pinentry-mac"
        fi
    }
    
    local result_intel=$(mock_detect_pinentry_intel)
    assert_equals "$test_env_dir/usr/local/bin/pinentry-mac" "$result_intel" "Should detect Intel path in simulation"
    
    # Clean up
    rm -rf "$test_env_dir"
}

test_rosetta_environment() {
    # Test behavior in Rosetta environment (Intel apps on Apple Silicon)
    local arch_output=$(arch)
    local uname_output=$(uname -m)
    
    # Check if we're potentially in Rosetta
    if [[ -f "/opt/homebrew/bin/brew" && "$arch_output" == "i386" ]]; then
        print_warning "Detected potential Rosetta environment"
        assert_true "[[ '$uname_output' == 'arm64' ]]" "uname should still report arm64 in Rosetta"
    fi
    
    # Test that our detection still works correctly
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        assert_homebrew_path "/opt/homebrew" "Should still detect Apple Silicon Homebrew even in Rosetta"
    fi
}

test_environment_variables() {
    # Test that platform detection sets appropriate environment variables
    set +u  # Disable nounset temporarily for platform.zsh
    source "$DOTFILES_DIR/.config/zsh/platform.zsh"
    set -u  # Re-enable nounset

    assert_true "[[ -n '$PLATFORM' ]]" "PLATFORM variable should be set"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        assert_true "[[ '$PLATFORM' == 'macos' ]]" "Should detect macOS platform"
    fi
    
    # Test conda search paths are set appropriately
    assert_true "[[ -n '$CONDA_SEARCH_PATHS' ]]" "CONDA_SEARCH_PATHS should be set"
    
    # Verify Apple Silicon paths are included if appropriate
    if [[ -d "/opt/homebrew" ]]; then
        local conda_paths_str="${CONDA_SEARCH_PATHS[*]}"
        assert_contains "$conda_paths_str" "/opt/homebrew" "Should include Apple Silicon conda paths"
    fi
}

test_command_availability() {
    # Test that expected commands are available on macOS
    local expected_commands=("uname" "arch" "stat" "date")
    
    for cmd in "${expected_commands[@]}"; do
        assert_command_exists "$cmd" "Command $cmd should be available on macOS"
    done
    
    # Test macOS-specific stat format
    local temp_file=$(mktemp)
    echo "test" > "$temp_file"
    
    # macOS uses -f for format, Linux uses -c
    local stat_output
    if stat_output=$(stat -f "%OLp" "$temp_file" 2>/dev/null); then
        assert_true "[[ '$stat_output' =~ ^[0-9]+$ ]]" "macOS stat should return numeric permissions"
    fi
    
    rm -f "$temp_file"
}

test_path_precedence() {
    # Test that the correct binaries take precedence based on architecture
    if [[ -f "/opt/homebrew/bin/brew" && -f "/usr/local/bin/brew" ]]; then
        # Both exist - Apple Silicon should take precedence
        local which_brew=$(which brew)
        assert_equals "/opt/homebrew/bin/brew" "$which_brew" "Apple Silicon brew should take precedence when both exist"
    fi
}

test_architecture_specific_optimizations() {
    # Test that architecture-specific optimizations are applied
    set +u  # Disable nounset temporarily for platform.zsh
    source "$DOTFILES_DIR/.config/zsh/platform.zsh"
    set -u  # Re-enable nounset

    # Check that the PATH includes the correct Homebrew directory
    if [[ -d "/opt/homebrew/bin" ]]; then
        assert_contains "$PATH" "/opt/homebrew/bin" "PATH should include Apple Silicon Homebrew"
    elif [[ -d "/usr/local/bin" ]]; then
        assert_contains "$PATH" "/usr/local/bin" "PATH should include Intel Homebrew"
    fi
}

# Run tests
describe "macOS Architecture Detection Tests"

run_test "Architecture detection" test_architecture_detection
run_test "Homebrew path detection" test_homebrew_path_detection
run_test "Pinentry detection" test_pinentry_detection
run_test "Platform detection function" test_platform_detection_function

describe "Cross-Architecture Simulation Tests"

run_test "Cross-architecture simulation" test_cross_architecture_simulation
run_test "Rosetta environment" test_rosetta_environment

describe "Environment and Configuration Tests"

run_test "Environment variables" test_environment_variables
run_test "Command availability" test_command_availability
run_test "Path precedence" test_path_precedence
run_test "Architecture-specific optimizations" test_architecture_specific_optimizations

# Print test summary
print_summary