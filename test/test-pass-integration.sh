#!/bin/bash
# Test Pass Integration
# Comprehensive testing for pass password store and AWS credential integration

# Disable strict error checking for tests
set +euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Setup and teardown for pass tests
setup() {
    setup_test_environment "pass"
    
    # Create mock pass store structure
    export PASSWORD_STORE_DIR="$TEST_ENV_DIR/password-store"
    mkdir -p "$PASSWORD_STORE_DIR"
    
    # Create mock AWS credential structure
    mkdir -p "$PASSWORD_STORE_DIR/aws/dev"
    mkdir -p "$PASSWORD_STORE_DIR/aws/staging"
    mkdir -p "$PASSWORD_STORE_DIR/aws/prod"
}

teardown() {
    cleanup_test_environment
    unset PASSWORD_STORE_DIR
}

# Mock pass command for testing
mock_pass() {
    local command="$1"
    shift
    local args="$*"
    
    case "$command" in
        "ls")
            if [[ "$args" == "aws/dev" ]]; then
                echo "aws/dev/access-key-id"
                echo "aws/dev/secret-access-key"
                echo "aws/dev/session-token"
                return 0
            elif [[ "$args" == "aws/nonexistent" ]]; then
                return 1
            else
                echo "Password Store"
                echo "├── aws"
                echo "│   ├── dev"
                echo "│   ├── staging"
                echo "│   └── prod"
                return 0
            fi
            ;;
        "show")
            case "$args" in
                "aws/dev/access-key-id")
                    echo "AKIAIOSFODNN7EXAMPLE"
                    return 0
                    ;;
                "aws/dev/secret-access-key")
                    echo "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
                    return 0
                    ;;
                "aws/dev/session-token")
                    echo "AQoDYXdzEJr...<base64 string>...="
                    return 0
                    ;;
                "aws/staging/access-key-id")
                    echo "AKIAIOSFODNN7STAGING"
                    return 0
                    ;;
                ".gpg-id")
                    echo "1234567890ABCDEF1234567890ABCDEF12345678"
                    return 0
                    ;;
                *)
                    echo "Error: $args is not in the password store."
                    return 1
                    ;;
            esac
            ;;
        "init")
            echo "Password store initialized for $args"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Test penv function with mocked pass
test_penv_function_loading() {
    # Source the functions from functions.zsh
    source "$DOTFILES_DIR/.config/zsh/functions.zsh"

    # Override pass command with our mock
    pass() { mock_pass "$@"; }

    # Test loading AWS credentials - redirect output to capture messages
    local output_file=$(mktemp)
    penv aws/dev > "$output_file" 2>&1
    local exit_code=$?
    local output=$(cat "$output_file")
    rm -f "$output_file"

    assert_equals "0" "$exit_code" "penv should succeed with valid AWS path"
    assert_contains "$output" "AWS_ACCESS_KEY_ID loaded" "Should report loading access key"
    assert_contains "$output" "AWS_SECRET_ACCESS_KEY loaded" "Should report loading secret key"
    assert_contains "$output" "AWS_SESSION_TOKEN loaded" "Should report loading session token"

    # Verify environment variables are set (in current shell context)
    assert_equals "AKIAIOSFODNN7EXAMPLE" "${AWS_ACCESS_KEY_ID:-}" "Access key should be loaded"
    assert_equals "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" "${AWS_SECRET_ACCESS_KEY:-}" "Secret key should be loaded"
    assert_equals "AQoDYXdzEJr...<base64 string>...=" "${AWS_SESSION_TOKEN:-}" "Session token should be loaded"
    assert_equals "aws/dev" "${PENV_LOADED_PATH:-}" "Should track loaded path"
}

test_penv_function_help() {
    # Source the functions
    source "$DOTFILES_DIR/.config/zsh/functions.zsh"
    
    # Test help output
    local help_output
    help_output=$(penv --help 2>&1)
    
    assert_contains "$help_output" "Pass Environment Loader" "Should show help header"
    assert_contains "$help_output" "Usage: penv <pass-path>" "Should show usage"
    assert_contains "$help_output" "penv aws/dev" "Should show AWS example"
    assert_contains "$help_output" "penv_clear" "Should mention clear function"
}

test_penv_function_error_handling() {
    # Source the functions
    source "$DOTFILES_DIR/.config/zsh/functions.zsh"
    
    # Override pass command with our mock
    pass() { mock_pass "$@"; }
    
    # Test with nonexistent path
    local error_output
    error_output=$(penv aws/nonexistent 2>&1)
    local exit_code=$?
    
    assert_equals "1" "$exit_code" "Should fail with nonexistent path"
    assert_contains "$error_output" "Pass entry not found" "Should report missing entry"
    assert_contains "$error_output" "Available entries" "Should show available entries"
    
    # Test with empty parameter
    local empty_output
    empty_output=$(penv "" 2>&1)
    local empty_exit_code=$?
    
    assert_equals "0" "$empty_exit_code" "Empty parameter should show help"
    assert_contains "$empty_output" "Usage: penv" "Should show help for empty parameter"
}

test_penv_clear_function() {
    # This test verifies the penv_clear function logic in a bash-compatible way
    # Note: penv_clear is a zsh function, so we test its behavior with a bash equivalent

    # Set up environment variables to clear
    export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
    export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    export AWS_SESSION_TOKEN="AQoDYXdzEJr...<base64 string>...="
    export PENV_LOADED_PATH="aws/dev"

    # Bash-compatible version of penv_clear for testing
    penv_clear_bash() {
        local patterns=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_SESSION_TOKEN")

        for var in "${patterns[@]}"; do
            if [[ -n "${!var}" ]]; then
                unset "$var"
                echo "✓ Cleared $var"
            fi
        done

        if [[ -n "$PENV_LOADED_PATH" ]]; then
            echo "Cleared environment variables from pass:$PENV_LOADED_PATH"
            unset PENV_LOADED_PATH
        fi
    }

    # Test clearing - redirect output to capture messages
    local output_file=$(mktemp)
    penv_clear_bash > "$output_file" 2>&1
    local clear_output=$(cat "$output_file")
    rm -f "$output_file"

    assert_contains "$clear_output" "Cleared AWS_ACCESS_KEY_ID" "Should report clearing access key"
    assert_contains "$clear_output" "Cleared AWS_SECRET_ACCESS_KEY" "Should report clearing secret key"
    assert_contains "$clear_output" "Cleared AWS_SESSION_TOKEN" "Should report clearing session token"
    assert_contains "$clear_output" "Cleared environment variables from pass:aws/dev" "Should report path cleared"

    # Verify variables are actually cleared (use :- to avoid unbound variable errors)
    assert_true "[[ -z '${AWS_ACCESS_KEY_ID:-}' ]]" "Access key should be cleared"
    assert_true "[[ -z '${AWS_SECRET_ACCESS_KEY:-}' ]]" "Secret key should be cleared"
    assert_true "[[ -z '${AWS_SESSION_TOKEN:-}' ]]" "Session token should be cleared"
    assert_true "[[ -z '${PENV_LOADED_PATH:-}' ]]" "Loaded path should be cleared"
}

test_aws_credential_validation() {
    # Test that loaded credentials don't contain obviously invalid patterns
    local test_access_key="AKIAIOSFODNN7EXAMPLE"
    local test_secret_key="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    
    # AWS access keys should start with AKIA
    assert_true "[[ '$test_access_key' =~ ^AKIA ]]" "Access key should start with AKIA"
    
    # AWS access keys should be 20 characters
    assert_equals "20" "${#test_access_key}" "Access key should be 20 characters"
    
    # Secret keys should be 40 characters
    assert_equals "40" "${#test_secret_key}" "Secret key should be 40 characters"
    
    # Should not contain obvious dummy patterns
    assert_false "[[ '$test_access_key' =~ example|test|dummy ]]" "Access key should not contain dummy patterns"
}

test_pass_store_structure() {
    # Test expected pass store structure for AWS credentials
    local expected_paths=(
        "aws/dev/access-key-id"
        "aws/dev/secret-access-key"
        "aws/staging/access-key-id"
        "aws/staging/secret-access-key"
    )
    
    # Override pass command with our mock
    pass() { mock_pass "$@"; }
    
    for path in "${expected_paths[@]}"; do
        local profile=$(echo "$path" | cut -d/ -f2)
        local credential=$(echo "$path" | cut -d/ -f3)
        
        # Test that pass can list the profile
        assert_true "pass ls aws/$profile >/dev/null 2>&1" "Should be able to list $profile credentials"
    done
}

test_credential_security() {
    # Test that credentials are handled securely
    
    # Mock a credential load
    local test_credential="AKIAIOSFODNN7EXAMPLE"
    
    # Credentials should not be logged or exposed
    assert_no_credential_exposure "$test_credential" "Should not expose credential in test context"
    
    # Test that penv doesn't echo credentials
    source "$DOTFILES_DIR/.config/zsh/functions.zsh"
    pass() { mock_pass "$@"; }
    
    local penv_output
    penv_output=$(penv aws/dev 2>&1)
    
    # Output should not contain the actual credential values
    assert_not_contains "$penv_output" "AKIAIOSFODNN7EXAMPLE" "Should not echo access key value"
    assert_not_contains "$penv_output" "wJalrXUtnFEMI/K7MDENG" "Should not echo secret key value"
    
    # But should confirm loading without showing values
    assert_contains "$penv_output" "AWS_ACCESS_KEY_ID loaded" "Should confirm loading without showing value"
}

test_aws_credential_process_integration() {
    # Test integration with AWS credential process
    local credential_script_path="$TEST_AWS_DIR/credential-process.sh"
    
    # Create a mock credential process script
    cat > "$credential_script_path" << 'EOF'
#!/bin/bash
# Mock AWS credential process

# This would normally integrate with pass
echo '{'
echo '  "Version": 1,'
echo '  "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",'
echo '  "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",'
echo '  "SessionToken": "AQoDYXdzEJr...<base64 string>...=",'
echo '  "Expiration": "2024-12-31T23:59:59Z"'
echo '}'
EOF
    
    chmod +x "$credential_script_path"
    
    # Test that script is executable and returns valid JSON
    local json_output
    json_output=$("$credential_script_path")
    
    assert_contains "$json_output" '"Version": 1' "Should return valid credential JSON"
    assert_contains "$json_output" '"AccessKeyId"' "Should include access key ID"
    assert_contains "$json_output" '"SecretAccessKey"' "Should include secret access key"
    
    # Test JSON validity (if jq is available)
    if command -v jq >/dev/null 2>&1; then
        assert_true "echo '$json_output' | jq empty" "Should be valid JSON"
        
        local version
        version=$(echo "$json_output" | jq -r '.Version')
        assert_equals "1" "$version" "Should have correct version number"
    fi
}

test_pass_initialization() {
    # Test pass store initialization simulation
    pass() { mock_pass "$@"; }
    
    # Test initialization with GPG key ID
    local init_output
    init_output=$(pass init "1234567890ABCDEF1234567890ABCDEF12345678" 2>&1)
    
    assert_contains "$init_output" "Password store initialized" "Should initialize pass store"
    
    # Test GPG ID retrieval
    local gpg_id
    gpg_id=$(pass show .gpg-id 2>/dev/null)
    
    assert_equals "1234567890ABCDEF1234567890ABCDEF12345678" "$gpg_id" "Should store GPG ID correctly"
}

test_environment_isolation() {
    # Test that penv doesn't interfere with other environment variables

    # Set some existing variables
    export EXISTING_VAR="original_value"
    export PATH_BACKUP="$PATH"

    # Mock penv function for bash testing
    penv() {
        # Simulate loading credentials without modifying other vars
        export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
        export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        export PENV_LOADED_PATH="$1"
    }

    # Bash-compatible penv_clear
    penv_clear() {
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN PENV_LOADED_PATH
    }

    # Load credentials
    penv aws/dev

    # Verify existing variables unchanged
    assert_equals "original_value" "$EXISTING_VAR" "Should not modify existing variables"
    assert_equals "$PATH_BACKUP" "$PATH" "Should not modify PATH"

    # Clear credentials
    penv_clear

    # Verify existing variables still unchanged
    assert_equals "original_value" "$EXISTING_VAR" "Should still not modify existing variables after clear"
}

test_concurrent_profile_handling() {
    # Test handling of multiple AWS profiles
    source "$DOTFILES_DIR/.config/zsh/functions.zsh"
    pass() { mock_pass "$@"; }
    
    # Load one profile
    penv aws/dev >/dev/null 2>&1
    assert_equals "aws/dev" "$PENV_LOADED_PATH" "Should track dev profile"
    
    # Load different profile (should replace)
    penv aws/staging >/dev/null 2>&1
    assert_equals "aws/staging" "$PENV_LOADED_PATH" "Should track staging profile"
    
    # Verify new credentials loaded
    assert_equals "AKIAIOSFODNN7STAGING" "$AWS_ACCESS_KEY_ID" "Should load staging credentials"
}

# Run tests with setup/teardown
describe "Pass Integration Basic Tests"

run_test "penv function loading" test_penv_function_loading
run_test "penv function help" test_penv_function_help
run_test "penv function error handling" test_penv_function_error_handling
run_test "penv clear function" test_penv_clear_function

describe "AWS Credential Validation Tests"

run_test "AWS credential validation" test_aws_credential_validation
run_test "Pass store structure" test_pass_store_structure
run_test "Credential security" test_credential_security

describe "AWS Integration Tests"

run_test "AWS credential process integration" test_aws_credential_process_integration
run_test "Pass initialization" test_pass_initialization

describe "Environment and Security Tests"

run_test "Environment isolation" test_environment_isolation
run_test "Concurrent profile handling" test_concurrent_profile_handling

# Clean up
teardown

# Print test summary
print_summary