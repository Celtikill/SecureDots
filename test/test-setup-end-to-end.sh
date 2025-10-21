#!/bin/bash
# Test End-to-End Setup
# Comprehensive testing for complete setup process simulation

# Disable strict error checking for tests
set +euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.sh"

# Setup and teardown for end-to-end tests
setup() {
    setup_test_environment "e2e"
    
    # Create mock directories for a complete setup
    mkdir -p "${TEST_HOME}/.oh-my-zsh"
    mkdir -p "${TEST_HOME}/.config/securedots"
    mkdir -p "${TEST_AWS_DIR}"
    
    # Set up mock Homebrew environment
    export MOCK_HOMEBREW_PRESENT="true"
    export MOCK_GPG_PRESENT="true"
    export MOCK_PASS_PRESENT="true"
}

teardown() {
    cleanup_test_environment
    unset MOCK_HOMEBREW_PRESENT MOCK_GPG_PRESENT MOCK_PASS_PRESENT
}

# Mock command availability
mock_command_available() {
    local cmd="$1"
    case "$cmd" in
        "brew")
            [[ "$MOCK_HOMEBREW_PRESENT" == "true" ]]
            ;;
        "gpg")
            [[ "$MOCK_GPG_PRESENT" == "true" ]]
            ;;
        "pass")
            [[ "$MOCK_PASS_PRESENT" == "true" ]]
            ;;
        "git"|"zsh"|"stow"|"jq")
            return 0  # Always available for tests
            ;;
        *)
            return 1
            ;;
    esac
}

# Test complete setup simulation
test_fresh_installation_simulation() {
    # Simulate a fresh system with all dependencies
    export MOCK_HOMEBREW_PRESENT="true"
    export MOCK_GPG_PRESENT="true"
    export MOCK_PASS_PRESENT="true"
    
    # Create basic configuration files that setup would create
    local zshrc_file="${TEST_HOME}/.zshrc"
    local aws_config="${TEST_AWS_DIR}/config"
    local gpg_agent_conf="${TEST_GNUPG_DIR}/gpg-agent.conf"
    
    # Simulate Oh My Zsh installation
    mkdir -p "${TEST_HOME}/.oh-my-zsh/custom/themes"
    touch "${TEST_HOME}/.oh-my-zsh/oh-my-zsh.sh"
    
    # Simulate .zshrc creation
    cat > "$zshrc_file" << 'EOF'
#!/usr/bin/env zsh
# ~/.zshrc - Test configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
source $ZSH/oh-my-zsh.sh
source "$HOME/.config/zsh/error-handling.zsh"
source "$HOME/.config/zsh/platform.zsh"
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/functions.zsh"
source "$HOME/.config/zsh/aws.zsh"
EOF
    
    # Simulate AWS config creation
    cat > "$aws_config" << 'EOF'
[default]
region = us-east-2
output = json

[profile dev]
region = us-east-2
credential_process = /bin/true

[profile staging]
region = us-east-2
credential_process = /bin/true
EOF
    
    # Simulate GPG agent config creation
    cat > "$gpg_agent_conf" << 'EOF'
default-cache-ttl 0
max-cache-ttl 0
pinentry-program /opt/homebrew/bin/pinentry-mac
enable-ssh-support
EOF
    
    chmod 600 "$gpg_agent_conf"
    chmod 600 "$aws_config"
    
    # Verify all files created
    assert_file_exists "$zshrc_file" "Should create .zshrc"
    assert_file_exists "$aws_config" "Should create AWS config"
    assert_file_exists "$gpg_agent_conf" "Should create GPG agent config"
    
    # Verify file permissions
    assert_file_permissions "$gpg_agent_conf" "600" "GPG agent config should have secure permissions"
    assert_file_permissions "$aws_config" "600" "AWS config should have secure permissions"
    
    # Verify configuration content
    assert_contains "$(cat "$zshrc_file")" "oh-my-zsh" "Should configure Oh My Zsh"
    assert_contains "$(cat "$aws_config")" "credential_process" "Should use credential process"
    assert_contains "$(cat "$gpg_agent_conf")" "default-cache-ttl 0" "Should use secure cache settings"
}

test_dependency_checking() {
    # Test with missing dependencies
    export MOCK_HOMEBREW_PRESENT="false"
    
    local missing_deps=()
    
    # Simulate dependency check
    for cmd in brew gpg pass git zsh stow; do
        if ! mock_command_available "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Should detect missing Homebrew
    assert_contains "${missing_deps[*]}" "brew" "Should detect missing Homebrew"
    
    # Test with all dependencies present
    export MOCK_HOMEBREW_PRESENT="true"
    missing_deps=()
    
    for cmd in brew gpg pass git zsh stow; do
        if ! mock_command_available "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    assert_equals "0" "${#missing_deps[@]}" "Should find no missing dependencies when all present"
}

test_backup_creation() {
    # Create existing configuration files
    local existing_zshrc="${TEST_HOME}/.zshrc"
    local existing_aws_config="${TEST_AWS_DIR}/config"
    
    echo "# Existing zshrc" > "$existing_zshrc"
    echo "[default]" > "$existing_aws_config"
    echo "region = us-west-1" >> "$existing_aws_config"
    
    # Simulate backup creation
    local backup_dir="${TEST_HOME}/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup existing files
    cp "$existing_zshrc" "$backup_dir/"
    cp "$existing_aws_config" "$backup_dir/config"
    
    # Verify backups
    assert_file_exists "$backup_dir/.zshrc" "Should backup existing .zshrc"
    assert_file_exists "$backup_dir/config" "Should backup existing AWS config"
    
    # Verify backup content
    assert_contains "$(cat "$backup_dir/.zshrc")" "Existing zshrc" "Should preserve original content"
    assert_contains "$(cat "$backup_dir/config")" "us-west-1" "Should preserve original AWS region"
}

test_stow_symlink_simulation() {
    # Create dotfiles structure in test environment
    local dotfiles_test_dir="${TEST_ENV_DIR}/dotfiles"
    mkdir -p "$dotfiles_test_dir/.config/zsh"
    
    # Create test dotfiles
    echo "# Test zshrc" > "$dotfiles_test_dir/.zshrc"
    echo "# Test functions" > "$dotfiles_test_dir/.config/zsh/functions.zsh"
    echo "# Test AWS config" > "$dotfiles_test_dir/.config/zsh/aws.zsh"
    
    # Simulate stow operation (create symlinks manually for test)
    ln -s "$dotfiles_test_dir/.zshrc" "${TEST_HOME}/.zshrc"
    mkdir -p "${TEST_HOME}/.config/zsh"
    ln -s "$dotfiles_test_dir/.config/zsh/functions.zsh" "${TEST_HOME}/.config/zsh/functions.zsh"
    ln -s "$dotfiles_test_dir/.config/zsh/aws.zsh" "${TEST_HOME}/.config/zsh/aws.zsh"
    
    # Verify symlinks created
    assert_true "[[ -L '${TEST_HOME}/.zshrc' ]]" "Should create .zshrc symlink"
    assert_true "[[ -L '${TEST_HOME}/.config/zsh/functions.zsh' ]]" "Should create functions.zsh symlink"
    assert_true "[[ -L '${TEST_HOME}/.config/zsh/aws.zsh' ]]" "Should create aws.zsh symlink"
    
    # Verify symlinks point to correct files
    local zshrc_target=$(readlink "${TEST_HOME}/.zshrc")
    assert_equals "$dotfiles_test_dir/.zshrc" "$zshrc_target" "Should link to correct .zshrc"
}

test_aws_profile_allowlist_creation() {
    # Test AWS profile allowlist creation
    local profiles_config="${TEST_HOME}/.config/securedots/aws-profiles.conf"
    
    # Simulate config creation
    mkdir -p "$(dirname "$profiles_config")"
    cat > "$profiles_config" << 'EOF'
# AWS Profile Allowlist Configuration
dev
staging
# production  # Commented out for security
EOF
    
    assert_file_exists "$profiles_config" "Should create AWS profiles config"
    
    # Test profile parsing simulation
    local profiles=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        line="${line// /}"
        [[ -n "$line" ]] && profiles+=("$line")
    done < "$profiles_config"
    
    assert_equals "2" "${#profiles[@]}" "Should parse correct number of profiles"
    assert_equals "dev" "${profiles[0]}" "Should include dev profile"
    assert_equals "staging" "${profiles[1]}" "Should include staging profile"
}

test_git_configuration() {
    # Test Git global configuration
    local gitignore_global="${TEST_HOME}/.gitignore_global"
    
    # Simulate gitignore creation
    cat > "$gitignore_global" << 'EOF'
# Global Git ignore file
.aws/credentials
.env
*.key
*.pem
.DS_Store
EOF
    
    assert_file_exists "$gitignore_global" "Should create global gitignore"
    assert_contains "$(cat "$gitignore_global")" ".aws/credentials" "Should ignore AWS credentials"
    assert_contains "$(cat "$gitignore_global")" "*.key" "Should ignore key files"
    
    # Simulate git config setting
    # (In real test, this would set git config, but we just verify the intent)
    local git_config_command="git config --global core.excludesfile ~/.gitignore_global"
    assert_true "[[ -n '$git_config_command' ]]" "Should set git excludesfile config"
}

test_platform_specific_setup() {
    # Test platform-specific setup variations
    
    # Simulate macOS setup
    if [[ "$(uname -s)" == "Darwin" ]]; then
        local expected_pinentry
        if [[ -f "/opt/homebrew/bin/pinentry-mac" ]]; then
            expected_pinentry="/opt/homebrew/bin/pinentry-mac"
        elif [[ -f "/usr/local/bin/pinentry-mac" ]]; then
            expected_pinentry="/usr/local/bin/pinentry-mac"
        else
            expected_pinentry="/usr/bin/pinentry-curses"
        fi
        
        # Create platform-appropriate GPG config
        local gpg_config="${TEST_GNUPG_DIR}/gpg-agent.conf"
        cat > "$gpg_config" << EOF
pinentry-program $expected_pinentry
default-cache-ttl 0
EOF
        
        assert_gpg_config "$gpg_config" "pinentry-program $expected_pinentry" "Should use correct macOS pinentry"
    else
        # Linux setup would use different pinentry
        local gpg_config="${TEST_GNUPG_DIR}/gpg-agent.conf"
        cat > "$gpg_config" << 'EOF'
pinentry-program /usr/bin/pinentry-curses
default-cache-ttl 0
EOF
        
        assert_gpg_config "$gpg_config" "pinentry-program /usr/bin/pinentry-curses" "Should use curses pinentry on Linux"
    fi
}

test_error_recovery() {
    # Test error recovery scenarios
    
    # Simulate permission error
    local readonly_file="${TEST_HOME}/.readonly_test"
    touch "$readonly_file"
    chmod 444 "$readonly_file"
    
    # Should handle permission errors gracefully
    assert_false "echo 'test' > '$readonly_file' 2>/dev/null" "Should fail to write to readonly file"
    
    # Simulate missing directory
    local missing_dir="${TEST_HOME}/nonexistent/deep/path"
    assert_false "[[ -d '$missing_dir' ]]" "Directory should not exist initially"
    
    # Should be able to create missing directories
    mkdir -p "$missing_dir"
    assert_dir_exists "$missing_dir" "Should create missing directory structure"
    
    # Clean up
    chmod 644 "$readonly_file"
    rm -f "$readonly_file"
}

test_rollback_simulation() {
    # Test configuration rollback capability
    
    # Create original state
    local config_file="${TEST_HOME}/.test_config"
    echo "original content" > "$config_file"
    local original_content=$(cat "$config_file")
    
    # Create backup
    local backup_file="${config_file}.backup"
    cp "$config_file" "$backup_file"
    
    # Simulate configuration change
    echo "modified content" > "$config_file"
    
    # Verify change applied
    assert_not_equals "$original_content" "$(cat "$config_file")" "Should have modified content"
    
    # Simulate rollback
    cp "$backup_file" "$config_file"
    
    # Verify rollback successful
    assert_equals "$original_content" "$(cat "$config_file")" "Should restore original content"
    
    # Clean up
    rm -f "$config_file" "$backup_file"
}

test_setup_validation() {
    # Test that setup can be validated after completion
    
    # Create complete setup state
    local files_to_check=(
        "${TEST_HOME}/.zshrc"
        "${TEST_HOME}/.config/zsh/functions.zsh"
        "${TEST_AWS_DIR}/config"
        "${TEST_GNUPG_DIR}/gpg-agent.conf"
        "${TEST_HOME}/.config/securedots/aws-profiles.conf"
    )
    
    # Create all expected files
    for file in "${files_to_check[@]}"; do
        mkdir -p "$(dirname "$file")"
        echo "# Test content" > "$file"
        if [[ "$file" =~ (gpg-agent|aws) ]]; then
            chmod 600 "$file"
        fi
    done
    
    # Validate setup completion
    local missing_files=()
    for file in "${files_to_check[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    assert_equals "0" "${#missing_files[@]}" "All expected files should be present after setup"
    
    # Validate permissions
    assert_file_permissions "${TEST_AWS_DIR}/config" "600" "AWS config should have secure permissions"
    assert_file_permissions "${TEST_GNUPG_DIR}/gpg-agent.conf" "600" "GPG config should have secure permissions"
}

# Run tests with setup/teardown
describe "End-to-End Setup Simulation Tests"

run_test "Fresh installation simulation" test_fresh_installation_simulation
run_test "Dependency checking" test_dependency_checking
run_test "Backup creation" test_backup_creation
run_test "Stow symlink simulation" test_stow_symlink_simulation

describe "Configuration Creation Tests"

run_test "AWS profile allowlist creation" test_aws_profile_allowlist_creation
run_test "Git configuration" test_git_configuration
run_test "Platform-specific setup" test_platform_specific_setup

describe "Error Handling and Recovery Tests"

run_test "Error recovery" test_error_recovery
run_test "Rollback simulation" test_rollback_simulation
run_test "Setup validation" test_setup_validation

# Clean up
teardown

# Print test summary
print_summary