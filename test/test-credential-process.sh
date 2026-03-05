#!/bin/bash
# Test Credential Process - Tests for .aws/credential-process.sh
# Covers validation, debug logging sanitization, cross-platform date parsing

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Disable strict error checking for tests (after framework sets -euo pipefail)
set +euo pipefail

CRED_SCRIPT="$DOTFILES_DIR/.aws/credential-process.sh"

# Extract function definitions once (everything before the final case statement).
# This avoids re-running sed in every test and prevents main() execution.
CRED_FUNCTIONS="$(sed -n '1,/^case/{ /^case/d; p }' "$CRED_SCRIPT")"

# ===== Setup / Teardown =====

setup() {
    setup_test_environment "credproc"
    # Create mock password store
    mkdir -p "$TEST_HOME/.password-store"
}

teardown() {
    cleanup_test_environment
}

# ===== Helper: run credential-process functions in isolation =====
# Sources extracted function definitions, then runs the provided code.
# IMPORTANT: Define mocks AFTER sourcing, since the source redefines functions.
# Does NOT trigger pass/gpg/pinentry.

run_cred_func() {
    local func_body="$1"
    bash -c "
        export HOME='$TEST_HOME'
        $CRED_FUNCTIONS
        $func_body
    " 2>&1
}

# ===== validate_profile =====

test_validate_profile_accepts_valid() {
    local names=("dev" "staging" "my-profile" "prod_01" "management-dev")
    for name in "${names[@]}"; do
        # validate_profile calls error_output which exits on failure
        # so success = no exit
        run_cred_func "validate_profile '$name'" >/dev/null 2>&1
        local rc=$?
        if [[ $rc -ne 0 ]]; then
            echo "  Rejected valid profile name: $name"
            return 1
        fi
    done
    return 0
}

test_validate_profile_rejects_empty() {
    local output
    output=$(run_cred_func 'validate_profile ""' 2>&1)
    local rc=$?
    assert_not_equals "0" "$rc" "Should reject empty profile"
    assert_contains "$output" "empty" "Should mention empty"
}

test_validate_profile_rejects_special_chars() {
    local bad_names=('dev;rm' 'pro file' 'a@b' 'x!y' 'test#1')
    for name in "${bad_names[@]}"; do
        run_cred_func "validate_profile '$name'" >/dev/null 2>&1
        local rc=$?
        if [[ $rc -eq 0 ]]; then
            echo "  Accepted invalid profile name: $name"
            return 1
        fi
    done
    return 0
}

test_validate_profile_rejects_path_traversal() {
    local output
    output=$(run_cred_func 'validate_profile "../etc/passwd"' 2>&1)
    local rc=$?
    assert_not_equals "0" "$rc" "Should reject path traversal"
    assert_contains "$output" "Invalid profile" "Should report invalid"
}

test_validate_profile_rejects_long_name() {
    local long_name
    long_name=$(python3 -c "print('a' * 65)")
    run_cred_func "validate_profile '$long_name'" >/dev/null 2>&1
    local rc=$?
    assert_not_equals "0" "$rc" "Should reject >64 char name"
}

# ===== debug_log =====

test_debug_log_silent_when_unset() {
    local output
    output=$(run_cred_func '
        export DEBUG=false
        debug_log "this should not appear"
    ')
    assert_equals "" "$output" "debug_log should be silent when DEBUG=false"
}

test_debug_log_sanitizes_akia_keys() {
    local output
    output=$(run_cred_func '
        export DEBUG=true
        debug_log "key is AKIAIOSFODNN7EXAMPLE"
    ')
    assert_not_contains "$output" "AKIAIOSFODNN7EXAMPLE" "Should sanitize AKIA keys"
    assert_contains "$output" "AKIA[REDACTED]" "Should show redacted marker"
}

test_debug_log_sanitizes_pass_paths() {
    local output
    output=$(run_cred_func '
        export DEBUG=true
        debug_log "running pass show aws/dev/access-key-id"
    ')
    assert_not_contains "$output" "aws/dev/access-key-id" "Should sanitize pass paths"
    assert_contains "$output" "[REDACTED_PATH]" "Should show redacted path"
}

# ===== error_output =====

test_error_output_formats_json() {
    local output
    output=$(run_cred_func "
        RED='' YELLOW='' NC=''
        error_output 'test error' 'TestCode'
    ")
    # error_output exits, so we check the combined output
    # The JSON goes to stdout, the human message to stderr
    assert_contains "$output" '"Version"' "Should contain Version key"
    assert_contains "$output" '"Code"' "Should contain Code key"
    assert_contains "$output" '"Message"' "Should contain Message key"
}

# ===== get_credential =====

test_get_credential_succeeds_first_try() {
    local output
    output=$(run_cred_func "
        pass() { echo 'AKIAIOSFODNN7EXAMPLE'; return 0; }
        export -f pass
        get_credential 'aws/dev/access-key-id'
    ")
    assert_contains "$output" "AKIAIOSFODNN7EXAMPLE" "Should return credential on first try"
}

test_get_credential_retries_then_succeeds() {
    local attempt_file="/tmp/dotfiles_test_attempt_$$"
    echo "0" > "$attempt_file"
    local output
    output=$(bash -c "
        export HOME='$TEST_HOME'
        export DEBUG=false
        $CRED_FUNCTIONS
        # Mock pass to fail twice then succeed using a file counter
        pass() {
            local a=\$(cat '$attempt_file')
            a=\$((a + 1))
            echo \"\$a\" > '$attempt_file'
            if [[ \$a -lt 3 ]]; then
                return 1
            fi
            echo 'AKIAIOSFODNN7EXAMPLE'
            return 0
        }
        export -f pass
        get_credential 'aws/dev/access-key-id'
    " 2>&1)
    rm -f "$attempt_file"
    assert_contains "$output" "AKIAIOSFODNN7EXAMPLE" "Should succeed after retries"
}

test_get_credential_fails_after_max_retries() {
    run_cred_func "
        export DEBUG=false
        pass() { return 1; }
        export -f pass
        get_credential 'aws/dev/access-key-id'
    " >/dev/null 2>&1
    local rc=$?
    assert_not_equals "0" "$rc" "Should fail after max retries"
}

# ===== get_session_token =====

test_get_session_token_returns_when_exists() {
    local output
    output=$(bash -c "
        eval \"\$(sed -n '1,/^case/{ /^case/d; p }' '$CRED_SCRIPT')\"
        pass() {
            case \"\$1\" in
                show) echo 'FwoGZXIvYXdzEBYaDHqa0AP'; return 0 ;;
                *) return 0 ;;
            esac
        }
        pass_entry_exists() { return 0; }
        export -f pass pass_entry_exists
        get_session_token 'dev'
    " 2>&1)
    assert_not_empty "$output" "Should return session token"
}

test_get_session_token_empty_when_missing() {
    local output
    output=$(bash -c "
        export DEBUG=false
        eval \"\$(sed -n '1,/^case/{ /^case/d; p }' '$CRED_SCRIPT')\"
        pass_entry_exists() { return 1; }
        export -f pass_entry_exists
        get_session_token 'dev'
    " 2>&1)
    assert_equals "" "$output" "Should return empty when no session token"
}

# ===== check_expiration =====

test_check_expiration_passes_future_date() {
    # Future date should not trigger error
    local future
    future=$(date -d "+1 hour" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null \
        || date -v+1H "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    if [[ -z "$future" ]]; then
        skip_test "check_expiration future date" "Cannot generate future date on this platform"
        return 0
    fi
    bash -c "
        eval \"\$(sed -n '1,/^case/{ /^case/d; p }' '$CRED_SCRIPT')\"
        pass_entry_exists() { return 0; }
        get_credential() { echo '$future'; }
        export -f pass_entry_exists get_credential
        check_expiration 'dev'
    " >/dev/null 2>&1
    local rc=$?
    assert_exit_code "0" "$rc" "Future expiration should pass"
}

test_check_expiration_fails_past_date() {
    bash -c "
        eval \"\$(sed -n '1,/^case/{ /^case/d; p }' '$CRED_SCRIPT')\"
        pass_entry_exists() { return 0; }
        get_credential() { echo '2020-01-01T00:00:00Z'; }
        export -f pass_entry_exists get_credential
        check_expiration 'dev'
    " >/dev/null 2>&1
    local rc=$?
    assert_not_equals "0" "$rc" "Past expiration should fail"
}

# ===== CLI flags =====

test_version_flag() {
    local output
    output=$(bash "$CRED_SCRIPT" --version 2>&1)
    assert_contains "$output" "AWS Credential Process Script v" "Should show version"
}

test_help_flag() {
    local output
    output=$(bash "$CRED_SCRIPT" --help 2>&1)
    assert_contains "$output" "Usage:" "Should show usage"
    assert_contains "$output" "PROFILE" "Should mention profile arg"
}

# ===== Run Tests =====

describe "Credential Process - validate_profile"
run_test "validate_profile accepts valid names" test_validate_profile_accepts_valid
run_test "validate_profile rejects empty" test_validate_profile_rejects_empty
run_test "validate_profile rejects special chars" test_validate_profile_rejects_special_chars
run_test "validate_profile rejects path traversal" test_validate_profile_rejects_path_traversal
run_test "validate_profile rejects >64 chars" test_validate_profile_rejects_long_name

describe "Credential Process - debug_log"
run_test "debug_log silent when DEBUG unset" test_debug_log_silent_when_unset
run_test "debug_log sanitizes AKIA keys" test_debug_log_sanitizes_akia_keys
run_test "debug_log sanitizes pass paths" test_debug_log_sanitizes_pass_paths

describe "Credential Process - error_output"
run_test "error_output formats JSON correctly" test_error_output_formats_json

describe "Credential Process - get_credential"
run_test "get_credential succeeds first try" test_get_credential_succeeds_first_try
run_test "get_credential retries then succeeds" test_get_credential_retries_then_succeeds
run_test "get_credential fails after max retries" test_get_credential_fails_after_max_retries

describe "Credential Process - get_session_token"
run_test "get_session_token returns when exists" test_get_session_token_returns_when_exists
run_test "get_session_token empty when missing" test_get_session_token_empty_when_missing

describe "Credential Process - check_expiration"
run_test "check_expiration passes future date" test_check_expiration_passes_future_date
run_test "check_expiration fails past date" test_check_expiration_fails_past_date

describe "Credential Process - CLI"
run_test "--version flag" test_version_flag
run_test "--help flag" test_help_flag

# Cleanup
teardown

# Print summary
print_summary
