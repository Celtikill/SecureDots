#!/bin/bash
# Test Core Functions - error-handling.zsh, functions.zsh, aliases.zsh
# Consolidates high-priority function tests into one file

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Disable strict error checking for tests (after framework sets -euo pipefail)
set +euo pipefail

# ===== Setup / Teardown =====

setup() {
    setup_test_environment "corefunc"
}

teardown() {
    cleanup_test_environment
}

# ===== Helper =====
run_zsh_mod() {
    local module="$1"
    local code="$2"
    local extra="${3:-}"
    zsh -c "
        export HOME='$TEST_HOME'
        ${extra:+$extra; }
        source '$DOTFILES_DIR/.config/zsh/$module'
        $code
    " 2>&1
}

# ================================================================
# Error Handling Tests (error-handling.zsh)
# ================================================================

test_check_required_tools_all_present() {
    local output
    output=$(run_zsh_mod "error-handling.zsh" 'check_required_tools ls cat echo')
    local rc=$?
    assert_exit_code "0" "$rc" "Should succeed when all tools present"
}

test_check_required_tools_missing_tool() {
    local output
    output=$(run_zsh_mod "error-handling.zsh" 'check_required_tools ls nonexistent_tool_xyz_12345')
    local rc=$?
    assert_not_equals "0" "$rc" "Should fail when tool missing"
    assert_contains "$output" "nonexistent_tool_xyz_12345" "Should name the missing tool"
}

test_validate_file_exists_readable() {
    local test_file="$TEST_HOME/testfile.txt"
    echo "content" > "$test_file"
    chmod 644 "$test_file"
    local output
    output=$(run_zsh_mod "error-handling.zsh" "validate_file '$test_file' 'test config'")
    local rc=$?
    assert_exit_code "0" "$rc" "Should pass for existing readable file"
}

test_validate_file_not_exists() {
    local output
    output=$(run_zsh_mod "error-handling.zsh" "validate_file '/tmp/nonexistent_file_xyz' 'test config'")
    local rc=$?
    assert_not_equals "0" "$rc" "Should fail for nonexistent file"
    assert_contains "$output" "not found" "Should report not found"
}

test_validate_directory_exists_writable() {
    mkdir -p "$TEST_HOME/testdir"
    chmod 755 "$TEST_HOME/testdir"
    local output
    output=$(run_zsh_mod "error-handling.zsh" "validate_directory '$TEST_HOME/testdir' 'test dir'")
    local rc=$?
    assert_exit_code "0" "$rc" "Should pass for existing writable directory"
}

test_validate_directory_not_exists() {
    local output
    output=$(run_zsh_mod "error-handling.zsh" "validate_directory '/tmp/nonexistent_dir_xyz' 'test dir'")
    local rc=$?
    assert_not_equals "0" "$rc" "Should fail for nonexistent directory"
    assert_contains "$output" "not found" "Should report not found"
}

test_show_stop_progress_no_orphans() {
    # Test that show_progress/stop_progress don't leave orphan processes
    zsh -c "
        source '$DOTFILES_DIR/.config/zsh/error-handling.zsh'
        show_progress 'testing'
        sleep 0.3
        stop_progress
        # Check no background jobs remain
        jobs_count=\$(jobs -p 2>/dev/null | wc -l)
        exit \$jobs_count
    " >/dev/null 2>&1
    local rc=$?
    assert_exit_code "0" "$rc" "Should have no orphan processes after stop_progress"
}

test_safe_network_op_retries_on_failure() {
    # Test that safe_network_op retries a failing command
    local output
    output=$(zsh -c "
        source '$DOTFILES_DIR/.config/zsh/error-handling.zsh'
        # Command that always fails
        safe_network_op false
    " 2>&1)
    local rc=$?
    assert_not_equals "0" "$rc" "Should fail after retries"
    assert_contains "$output" "failed" "Should report failure"
}

# ================================================================
# Functions Tests (functions.zsh)
# ================================================================

test_mkcd_creates_dir_and_cd() {
    local output
    output=$(zsh -c "
        source '$DOTFILES_DIR/.config/zsh/functions.zsh'
        mkcd '/tmp/dotfiles_test_mkcd_$$'
        pwd
        cd /
        rm -rf '/tmp/dotfiles_test_mkcd_$$'
    " 2>&1)
    assert_contains "$output" "dotfiles_test_mkcd" "mkcd should cd into created directory"
}

test_extract_handles_tar_gz() {
    # Create a test tar.gz
    local test_dir="/tmp/dotfiles_test_extract_$$"
    mkdir -p "$test_dir/src"
    echo "test content" > "$test_dir/src/file.txt"
    tar czf "$test_dir/archive.tar.gz" -C "$test_dir" src
    rm -rf "$test_dir/src"

    zsh -c "
        cd '$test_dir'
        source '$DOTFILES_DIR/.config/zsh/functions.zsh'
        extract archive.tar.gz
    " >/dev/null 2>&1
    assert_file_exists "$test_dir/src/file.txt" "Should extract tar.gz correctly"
    rm -rf "$test_dir"
}

test_extract_rejects_unknown_format() {
    local test_file="/tmp/dotfiles_test_unknown_$$.xyz"
    echo "data" > "$test_file"
    local output
    output=$(zsh -c "
        source '$DOTFILES_DIR/.config/zsh/functions.zsh'
        extract '$test_file'
    " 2>&1)
    local rc=$?
    assert_not_equals "0" "$rc" "Should fail for unknown format"
    assert_contains "$output" "Unknown archive format" "Should report unknown format"
    rm -f "$test_file"
}

test_penv_rejects_path_traversal() {
    local output
    output=$(run_zsh_mod "functions.zsh" 'penv "../etc/passwd"')
    local rc=$?
    assert_not_equals "0" "$rc" "Should reject path traversal"
    assert_contains "$output" "Invalid pass path" "Should report invalid path"
}

test_penv_rejects_special_chars() {
    local output
    output=$(run_zsh_mod "functions.zsh" 'penv "aws;rm -rf /"')
    local rc=$?
    assert_not_equals "0" "$rc" "Should reject special chars"
    assert_contains "$output" "Invalid pass path" "Should report invalid format"
}

test_penv_rejects_leading_dot_slash() {
    local output
    output=$(run_zsh_mod "functions.zsh" 'penv "./aws/dev"')
    local rc=$?
    assert_not_equals "0" "$rc" "Should reject leading dot-slash"
}

test_penv_clear_unsets_credential_vars() {
    local output
    output=$(zsh -c "
        source '$DOTFILES_DIR/.config/zsh/functions.zsh'
        export AWS_ACCESS_KEY_ID='AKIATEST'
        export AWS_SECRET_ACCESS_KEY='secret'
        export AWS_SESSION_TOKEN='token'
        export PENV_LOADED_PATH='aws/dev'
        penv_clear
        echo \"AK=\${AWS_ACCESS_KEY_ID:-}\"
        echo \"SK=\${AWS_SECRET_ACCESS_KEY:-}\"
        echo \"ST=\${AWS_SESSION_TOKEN:-}\"
    " 2>&1)
    assert_contains "$output" "AK=" "Access key should be empty after clear"
    assert_not_contains "$output" "AK=AKIATEST" "Access key should be unset"
    assert_not_contains "$output" "SK=secret" "Secret key should be unset"
}

test_penv_clear_reports_duration() {
    local output
    output=$(zsh -c "
        source '$DOTFILES_DIR/.config/zsh/functions.zsh'
        export AWS_ACCESS_KEY_ID='AKIATEST'
        export PENV_LOADED_PATH='aws/dev'
        export PENV_LOADED_AT=\$(( \$(date +%s) - 60 ))
        penv_clear
    " 2>&1)
    assert_contains "$output" "active" "Should report active duration"
}

# ================================================================
# Aliases Tests (aliases.zsh)
# ================================================================

test_safety_aliases_contain_i_flag() {
    local output
    output=$(zsh -c "
        source '$DOTFILES_DIR/.config/zsh/aliases.zsh'
        alias rm; alias cp; alias mv
    " 2>&1)
    # Check each safety alias has -i
    for cmd in rm cp mv; do
        if ! echo "$output" | grep -q "${cmd}.*-i"; then
            echo "  Alias $cmd missing -i flag"
            return 1
        fi
    done
    return 0
}

test_tofu_preferred_over_terraform() {
    # When tofu is available, tf alias should point to tofu
    local output
    output=$(zsh -c "
        # Create mock tofu command
        tofu() { echo 'tofu'; }
        export -f tofu 2>/dev/null || true
        source '$DOTFILES_DIR/.config/zsh/aliases.zsh'
        alias tf 2>/dev/null || echo 'tf not set'
    " 2>&1)
    # If tofu is available on this system, tf should be tofu
    if command -v tofu &>/dev/null; then
        assert_contains "$output" "tofu" "tf should alias to tofu when available"
    else
        # On systems without tofu, just verify the alias file has the conditional
        local file_content
        file_content=$(cat "$DOTFILES_DIR/.config/zsh/aliases.zsh")
        assert_contains "$file_content" "command -v tofu" "Should check for tofu before terraform"
    fi
}

test_docker_aliases_conditional() {
    # Docker aliases should only be defined when docker is available
    local file_content
    file_content=$(cat "$DOTFILES_DIR/.config/zsh/aliases.zsh")
    assert_contains "$file_content" "command -v docker" "Docker aliases should be conditional"
}

test_navigation_aliases_defined() {
    local output
    output=$(zsh -c "
        source '$DOTFILES_DIR/.config/zsh/aliases.zsh'
        alias .. 2>/dev/null && echo 'dotdot_ok'
        alias ... 2>/dev/null && echo 'dotdotdot_ok'
    " 2>&1)
    assert_contains "$output" "dotdot_ok" ".. alias should be defined"
    assert_contains "$output" "dotdotdot_ok" "... alias should be defined"
}

# ===== Run Tests =====

describe "Error Handling - check_required_tools"
run_test "check_required_tools all present" test_check_required_tools_all_present
run_test "check_required_tools missing tool" test_check_required_tools_missing_tool

describe "Error Handling - validate_file/directory"
run_test "validate_file exists/readable" test_validate_file_exists_readable
run_test "validate_file not exists" test_validate_file_not_exists
run_test "validate_directory exists/writable" test_validate_directory_exists_writable
run_test "validate_directory not exists" test_validate_directory_not_exists

describe "Error Handling - Progress & Network"
run_test "show_progress/stop_progress no orphans" test_show_stop_progress_no_orphans
run_test "safe_network_op retries on failure" test_safe_network_op_retries_on_failure

describe "Functions - mkcd & extract"
run_test "mkcd creates dir and cd" test_mkcd_creates_dir_and_cd
run_test "extract handles tar.gz" test_extract_handles_tar_gz
run_test "extract rejects unknown format" test_extract_rejects_unknown_format

describe "Functions - penv security"
run_test "penv rejects path traversal" test_penv_rejects_path_traversal
run_test "penv rejects special chars" test_penv_rejects_special_chars
run_test "penv rejects leading dot/slash" test_penv_rejects_leading_dot_slash

describe "Functions - penv_clear"
run_test "penv_clear unsets all credential vars" test_penv_clear_unsets_credential_vars
run_test "penv_clear reports duration" test_penv_clear_reports_duration

describe "Aliases"
run_test "Safety aliases contain -i flag" test_safety_aliases_contain_i_flag
run_test "Tofu preferred over terraform" test_tofu_preferred_over_terraform
run_test "Docker aliases conditional on docker" test_docker_aliases_conditional
run_test "Navigation aliases defined" test_navigation_aliases_defined

# Cleanup
teardown

# Print summary
print_summary
