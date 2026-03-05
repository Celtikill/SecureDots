#!/bin/bash
# Test Module Integration - module loading, cross-platform, security regression
# Validates .zshrc module loading behavior and security invariants

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Disable strict error checking for tests (after framework sets -euo pipefail)
set +euo pipefail

# ===== Setup / Teardown =====

setup() {
    setup_test_environment "modint"
    # Symlink .config/zsh modules into test home for zshrc sourcing
    mkdir -p "$TEST_HOME/.config"
    ln -sf "$DOTFILES_DIR/.config/zsh" "$TEST_HOME/.config/zsh"
}

teardown() {
    cleanup_test_environment
}

# ===== Helper: check if zsh function is defined after sourcing modules =====
zsh_func_defined() {
    local func_name="$1"
    local extra_setup="${2:-}"
    zsh -c "
        export HOME='$TEST_HOME'
        # Mock aws to prevent GPG/pinentry triggers
        aws() { return 1; }
        ${extra_setup:+$extra_setup; }
        ZSH_CONFIG_DIR='$TEST_HOME/.config/zsh'
        for module in error-handling platform aliases functions; do
            [[ -f \"\${ZSH_CONFIG_DIR}/\${module}.zsh\" ]] && source \"\${ZSH_CONFIG_DIR}/\${module}.zsh\"
        done
        if [[ \"\${DISABLE_AWS_INTEGRATION:-false}\" != \"true\" ]] && [[ -f \"\${ZSH_CONFIG_DIR}/aws.zsh\" ]]; then
            source \"\${ZSH_CONFIG_DIR}/aws.zsh\"
        fi
        [[ -n \"\$ENABLE_CONDA\" ]] && [[ -f \"\${ZSH_CONFIG_DIR}/conda.zsh\" ]] && source \"\${ZSH_CONFIG_DIR}/conda.zsh\"
        [[ -n \"\$ENABLE_GEMINI_CODE_ASSIST\" ]] && [[ -f \"\${ZSH_CONFIG_DIR}/gemini.zsh\" ]] && source \"\${ZSH_CONFIG_DIR}/gemini.zsh\"
        whence -f '$func_name' >/dev/null 2>&1
    " 2>/dev/null
}

# ================================================================
# Module Loading Tests
# ================================================================

test_core_modules_load() {
    # Core functions from each module should be defined
    local funcs=("print_error" "check_powerline_fonts" "mkcd" "extract")
    for func in "${funcs[@]}"; do
        if ! zsh_func_defined "$func"; then
            echo "  Core function not defined: $func"
            return 1
        fi
    done
    return 0
}

test_aws_loads_by_default() {
    if ! zsh_func_defined "aws_switch"; then
        echo "  aws_switch should be defined by default"
        return 1
    fi
    return 0
}

test_aws_skips_when_disabled() {
    if zsh_func_defined "aws_switch" "export DISABLE_AWS_INTEGRATION=true"; then
        echo "  aws_switch should NOT be defined when DISABLE_AWS_INTEGRATION=true"
        return 1
    fi
    return 0
}

test_conda_loads_when_enabled() {
    # Check if conda.zsh exists first
    if [[ ! -f "$DOTFILES_DIR/.config/zsh/conda.zsh" ]]; then
        skip_test "Conda module loads when ENABLE_CONDA=1" "conda.zsh not present"
        return 0
    fi
    # conda.zsh returns early when CONDA_LAZY_LOAD=true (default) or when
    # conda is not installed. Verify the module sources without error.
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        export ENABLE_CONDA=1
        export CONDA_LAZY_LOAD=false
        source '$DOTFILES_DIR/.config/zsh/conda.zsh'
    " 2>&1)
    local rc=$?
    # Module should source without errors (rc=0), even if conda isn't installed
    # (it just won't define functions if conda binary isn't found)
    if [[ $rc -ne 0 ]] && [[ "$output" == *"error"* || "$output" == *"Error"* ]]; then
        echo "  conda.zsh sourcing produced errors: $output"
        return 1
    fi
    return 0
}

test_gemini_loads_when_enabled() {
    if [[ ! -f "$DOTFILES_DIR/.config/zsh/gemini.zsh" ]]; then
        skip_test "Gemini module loads when ENABLE_GEMINI_CODE_ASSIST=1" "gemini.zsh not present"
        return 0
    fi
    if ! zsh_func_defined "gemini_check" "export ENABLE_GEMINI_CODE_ASSIST=1"; then
        echo "  gemini functions should be defined when ENABLE_GEMINI_CODE_ASSIST=1"
        return 1
    fi
    return 0
}

# ================================================================
# Cross-Platform Tests
# ================================================================

test_platform_matches_uname() {
    local output
    output=$(zsh -c "
        source '$DOTFILES_DIR/.config/zsh/platform.zsh'
        echo \"\$PLATFORM\"
    " 2>&1)
    local kernel
    kernel=$(uname -s)
    case "$kernel" in
        Darwin*) assert_contains "$output" "macos" "PLATFORM should be macos on Darwin" ;;
        Linux*)  assert_contains "$output" "linux" "PLATFORM should contain linux on Linux" ;;
        *)       assert_not_empty "$output" "PLATFORM should be set" ;;
    esac
}

test_file_permission_helper_works() {
    # stat should work to read permissions on current OS
    local test_file="/tmp/dotfiles_test_perms_$$"
    echo "test" > "$test_file"
    chmod 644 "$test_file"
    local perms
    perms=$(stat -c %a "$test_file" 2>/dev/null || stat -f %Lp "$test_file" 2>/dev/null)
    rm -f "$test_file"
    assert_equals "644" "$perms" "stat should read file permissions"
}

test_sha256_available() {
    if command -v sha256sum &>/dev/null; then
        return 0
    elif command -v shasum &>/dev/null; then
        return 0
    else
        echo "  Neither sha256sum nor shasum found"
        return 1
    fi
}

# ================================================================
# Security Regression Tests
# ================================================================

test_credentials_file_dev_null() {
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        echo \"\$AWS_SHARED_CREDENTIALS_FILE\"
    " 2>&1)
    assert_equals "/dev/null" "$output" "AWS_SHARED_CREDENTIALS_FILE must be /dev/null"
}

test_stow_ignores_aws_credentials() {
    local stow_ignore="$DOTFILES_DIR/.stow-local-ignore"
    if [[ ! -f "$stow_ignore" ]]; then
        echo "  .stow-local-ignore not found"
        return 1
    fi
    local content
    content=$(cat "$stow_ignore")
    assert_contains "$content" "\.aws/credentials" "stow-local-ignore should cover .aws/credentials"
}

test_profiles_config_permissions() {
    # Create a profiles config and verify aws_switch enforces 600
    mkdir -p "$TEST_HOME/.config/securedots"
    cat > "$TEST_HOME/.config/securedots/aws-profiles.conf" << 'EOF'
dev
staging
EOF
    chmod 755 "$TEST_HOME/.config/securedots/aws-profiles.conf"

    # Run aws_switch which should fix permissions
    zsh -c "
        export HOME='$TEST_HOME'
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        aws_switch dev
    " >/dev/null 2>&1

    local perms
    perms=$(stat -c %a "$TEST_HOME/.config/securedots/aws-profiles.conf" 2>/dev/null \
        || stat -f %Lp "$TEST_HOME/.config/securedots/aws-profiles.conf" 2>/dev/null)
    assert_equals "600" "$perms" "aws-profiles.conf should be enforced to 600"
}

test_no_credential_patterns_in_output() {
    # Run key functions and verify no credential patterns leak
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        aws_switch dev 2>&1
        aws_current 2>&1
    " 2>&1)
    assert_no_credential_exposure "$output" "Function output should not contain credentials"
}

# ===== Run Tests =====

describe "Module Loading"
run_test "Core modules load (error-handling, platform, aliases, functions)" test_core_modules_load
run_test "AWS loads by default" test_aws_loads_by_default
run_test "AWS skips when DISABLE_AWS_INTEGRATION=true" test_aws_skips_when_disabled
run_test "Conda loads when ENABLE_CONDA=1" test_conda_loads_when_enabled
run_test "Gemini loads when ENABLE_GEMINI_CODE_ASSIST=1" test_gemini_loads_when_enabled

describe "Cross-Platform"
run_test "PLATFORM matches uname" test_platform_matches_uname
run_test "File permission helper works on current OS" test_file_permission_helper_works
run_test "sha256sum or shasum available" test_sha256_available

describe "Security Regression"
run_test "AWS_SHARED_CREDENTIALS_FILE /dev/null" test_credentials_file_dev_null
run_test "stow-local-ignore covers .aws/credentials" test_stow_ignores_aws_credentials
run_test "aws-profiles.conf permissions enforced" test_profiles_config_permissions
run_test "No credential patterns in function output" test_no_credential_patterns_in_output

# Cleanup
teardown

# Print summary
print_summary
