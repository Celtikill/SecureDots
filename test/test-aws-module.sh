#!/bin/bash
# Test AWS Module - Security validation for aws.zsh
# Tests the 3-layer security validation in aws_switch and related functions

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Disable strict error checking for tests (after framework sets -euo pipefail)
set +euo pipefail

# ===== Setup / Teardown =====

setup() {
    setup_test_environment "aws"
    # Create config directory for aws-profiles.conf
    mkdir -p "$TEST_HOME/.config/securedots"
    # Create a profiles config with known entries
    cat > "$TEST_HOME/.config/securedots/aws-profiles.conf" << 'EOF'
# Test profiles
dev
staging
management-dev
EOF
    chmod 600 "$TEST_HOME/.config/securedots/aws-profiles.conf"

    # Unset AWS_PROFILE so tests start clean
    unset AWS_PROFILE 2>/dev/null || true
}

teardown() {
    cleanup_test_environment
}

# ===== Helper =====
# Run aws.zsh function in isolated zsh with our test HOME
# IMPORTANT: Always mock aws command to prevent GPG/pinentry triggers
# from the background credential validation in aws_switch
run_aws_func() {
    local func_call="$1"
    local extra_setup="${2:-}"
    zsh -c "
        export HOME='$TEST_HOME'
        # Mock aws to prevent GPG/pinentry in background validation
        aws() { return 1; }
        ${extra_setup:+$extra_setup; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        $func_call
    " 2>&1
}

# ===== aws_switch: Usage & Empty Input =====

test_aws_switch_no_arg_shows_usage() {
    local output
    output=$(run_aws_func 'aws_switch ""')
    assert_contains "$output" "Usage: aws_switch" "Should show usage when no arg"
}

test_aws_switch_rejects_empty_profile() {
    run_aws_func 'aws_switch ""' >/dev/null 2>&1
    local exit_code=$?
    assert_exit_code "1" "$exit_code" "Should reject empty profile"
}

# ===== aws_switch: Security Layer 1 - Format Validation =====

test_aws_switch_rejects_special_chars() {
    local output
    output=$(run_aws_func 'aws_switch "dev;rm -rf"')
    assert_contains "$output" "Invalid profile name" "Should reject special chars"
}

test_aws_switch_rejects_long_name() {
    local long_name
    long_name=$(python3 -c "print('a' * 65)")
    local output
    output=$(run_aws_func "aws_switch '$long_name'")
    assert_contains "$output" "Invalid profile name" "Should reject >64 char name"
}

# ===== aws_switch: Security Layer 2 - Injection Prevention =====

test_aws_switch_blocks_path_traversal() {
    local output
    output=$(run_aws_func 'aws_switch "../../etc/passwd"')
    assert_contains "$output" "Invalid" "Should block path traversal"
}

test_aws_switch_blocks_shell_metacharacters() {
    local chars=("dev;ls" "dev&cmd" 'dev|cat' 'dev$(id)' 'dev`id`')
    for input in "${chars[@]}"; do
        local output
        output=$(run_aws_func "aws_switch '$input'" 2>&1)
        local rc=$?
        # Should fail - either format validation or injection prevention catches it
        if [[ $rc -eq 0 ]] && [[ "$output" == *"Switched to"* ]]; then
            echo "  Failed to block metacharacter input: $input"
            return 1
        fi
    done
    return 0
}

# ===== aws_switch: Security Layer 3 - Allowlist Validation =====

test_aws_switch_rejects_unlisted_profile() {
    local output
    output=$(run_aws_func 'aws_switch "production"')
    assert_contains "$output" "not supported" "Should reject unlisted profile"
}

test_aws_switch_accepts_valid_profile() {
    local output
    output=$(run_aws_func 'aws_switch "dev"')
    assert_contains "$output" "Switched to AWS profile: dev" "Should accept valid profile"
}

test_aws_switch_sets_aws_profile() {
    # Verify the export takes effect within the zsh session
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        aws_switch dev >/dev/null 2>&1
        echo \"\$AWS_PROFILE\"
    " 2>&1)
    assert_equals "dev" "$output" "AWS_PROFILE should be set to dev"
}

# ===== aws_switch: Config File Loading =====

test_aws_switch_loads_profiles_from_config() {
    local output
    output=$(run_aws_func 'aws_switch "management-dev"')
    assert_contains "$output" "Switched to AWS profile: management-dev" "Should load profile from config file"
}

test_aws_switch_creates_default_config() {
    # Remove the config so aws_switch creates it
    rm -f "$TEST_HOME/.config/securedots/aws-profiles.conf"
    run_aws_func 'aws_switch "dev"' >/dev/null 2>&1
    assert_file_exists "$TEST_HOME/.config/securedots/aws-profiles.conf" "Should create default config"
}

test_aws_switch_warns_insecure_permissions() {
    chmod 644 "$TEST_HOME/.config/securedots/aws-profiles.conf"
    local output
    output=$(run_aws_func 'aws_switch "dev"')
    assert_contains "$output" "insecure permissions" "Should warn about insecure permissions"
}

test_aws_switch_autofixes_permissions() {
    chmod 644 "$TEST_HOME/.config/securedots/aws-profiles.conf"
    run_aws_func 'aws_switch "dev"' >/dev/null 2>&1
    local perms
    perms=$(stat -c %a "$TEST_HOME/.config/securedots/aws-profiles.conf" 2>/dev/null \
        || stat -f %Lp "$TEST_HOME/.config/securedots/aws-profiles.conf" 2>/dev/null)
    assert_equals "600" "$perms" "Should auto-fix permissions to 600"
}

# ===== aws_profile =====

test_aws_profile_delegates_to_switch() {
    local output
    output=$(run_aws_func 'aws_profile "dev"')
    assert_contains "$output" "Switched to AWS profile: dev" "aws_profile should delegate to aws_switch"
}

test_aws_profile_shows_current() {
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        export AWS_PROFILE='staging'
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        aws_profile
    " 2>&1)
    assert_equals "staging" "$output" "aws_profile with no arg should show current"
}

# ===== aws_check =====

test_aws_check_mock_success() {
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        export AWS_PROFILE='dev'
        # Mock aws to succeed (no GPG/pinentry)
        aws() { echo '{\"UserId\":\"TEST\"}'; return 0; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        aws_check
    " 2>&1)
    assert_contains "$output" "credentials valid" "aws_check should report valid on success"
}

test_aws_check_mock_failure() {
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        export AWS_PROFILE='dev'
        # Mock aws to fail (no GPG/pinentry)
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        aws_check
    " 2>&1)
    assert_contains "$output" "invalid" "aws_check should report invalid on failure"
}

# ===== aws_current =====

test_aws_current_shows_profile_and_region() {
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        export AWS_PROFILE='dev'
        export AWS_DEFAULT_REGION='us-east-2'
        # Mock aws to prevent GPG/pinentry
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        aws_current
    " 2>&1)
    assert_contains "$output" "Current AWS Profile: dev" "Should show profile"
    assert_contains "$output" "Region: us-east-2" "Should show region"
}

# ===== Environment Defaults =====

test_default_region_us_east_2() {
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        unset AWS_DEFAULT_REGION
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        echo \"\$AWS_DEFAULT_REGION\"
    " 2>&1)
    assert_equals "us-east-2" "$output" "Default region should be us-east-2"
}

test_credentials_file_dev_null() {
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        echo \"\$AWS_SHARED_CREDENTIALS_FILE\"
    " 2>&1)
    assert_equals "/dev/null" "$output" "Credentials file should be /dev/null"
}

test_default_profile_management_dev() {
    local output
    output=$(zsh -c "
        export HOME='$TEST_HOME'
        unset AWS_PROFILE
        unset AWS_PROFILE_DEFAULT
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        echo \"\$AWS_PROFILE\"
    " 2>&1)
    assert_equals "management-dev" "$output" "Default profile should be management-dev"
}

# ===== Config File Parsing =====

test_config_comment_blank_line_parsing() {
    # Create config with comments and blank lines
    cat > "$TEST_HOME/.config/securedots/aws-profiles.conf" << 'EOF'
# This is a comment

dev
  # Indented comment
staging

# production
EOF
    chmod 600 "$TEST_HOME/.config/securedots/aws-profiles.conf"

    # dev and staging should work, production should not
    local output_dev output_prod
    output_dev=$(run_aws_func 'aws_switch "dev"')
    output_prod=$(run_aws_func 'aws_switch "production"')
    assert_contains "$output_dev" "Switched to AWS profile: dev" "Should parse dev from config"
    assert_contains "$output_prod" "not supported" "Commented production should be rejected"
}

# ===== Run Tests =====

describe "AWS Module - Usage & Empty Input"
run_test "aws_switch no arg shows usage" test_aws_switch_no_arg_shows_usage
run_test "aws_switch rejects empty profile" test_aws_switch_rejects_empty_profile

describe "AWS Module - Security Layer 1: Format Validation"
run_test "aws_switch rejects special chars" test_aws_switch_rejects_special_chars
run_test "aws_switch rejects >64 char name" test_aws_switch_rejects_long_name

describe "AWS Module - Security Layer 2: Injection Prevention"
run_test "aws_switch blocks path traversal (..)" test_aws_switch_blocks_path_traversal
run_test "aws_switch blocks shell metacharacters" test_aws_switch_blocks_shell_metacharacters

describe "AWS Module - Security Layer 3: Allowlist Validation"
run_test "aws_switch rejects unlisted profile" test_aws_switch_rejects_unlisted_profile
run_test "aws_switch accepts valid profile" test_aws_switch_accepts_valid_profile
run_test "aws_switch sets AWS_PROFILE correctly" test_aws_switch_sets_aws_profile
run_test "aws_switch loads profiles from config" test_aws_switch_loads_profiles_from_config
run_test "aws_switch creates default config on first run" test_aws_switch_creates_default_config
run_test "aws_switch warns on insecure permissions" test_aws_switch_warns_insecure_permissions
run_test "aws_switch auto-fixes permissions to 600" test_aws_switch_autofixes_permissions

describe "AWS Module - aws_profile"
run_test "aws_profile delegates to aws_switch" test_aws_profile_delegates_to_switch
run_test "aws_profile shows current without arg" test_aws_profile_shows_current

describe "AWS Module - aws_check"
run_test "aws_check mock success" test_aws_check_mock_success
run_test "aws_check mock failure" test_aws_check_mock_failure

describe "AWS Module - aws_current"
run_test "aws_current shows profile and region" test_aws_current_shows_profile_and_region

describe "AWS Module - Environment Defaults"
run_test "AWS_DEFAULT_REGION defaults us-east-2" test_default_region_us_east_2
run_test "AWS_SHARED_CREDENTIALS_FILE is /dev/null" test_credentials_file_dev_null
run_test "Default profile fallback management-dev" test_default_profile_management_dev

describe "AWS Module - Config File Parsing"
run_test "Config file comment/blank line parsing" test_config_comment_blank_line_parsing

# Cleanup
teardown

# Print summary
print_summary
