#!/bin/bash
# validate.sh - Essential dotfiles configuration validation
# Replaces multiple phantom validation scripts with single working validator

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Validation results
VALIDATION_ERRORS=0

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((VALIDATION_ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo "Validating dotfiles configuration..."
    echo
}

# Check AWS configuration
validate_aws_config() {
    echo "📋 AWS Configuration:"
    
    if [[ -f .aws/config ]]; then
        print_success "AWS config file exists"
        
        # Check for credential_process configuration
        if grep -q "credential_process" .aws/config; then
            print_success "AWS credential process configured"
        else
            print_warning "No credential_process found in AWS config"
        fi
    else
        print_error "AWS config file missing (.aws/config)"
    fi
    
    # Check credential process script
    if [[ -f .aws/credential-process.sh ]]; then
        if [[ -x .aws/credential-process.sh ]]; then
            print_success "Credential process script is executable"
        else
            print_error "Credential process script not executable"
        fi
    else
        print_error "Credential process script missing (.aws/credential-process.sh)"
    fi
    
    echo
}

# Check GPG configuration
validate_gpg() {
    echo "🔐 GPG Configuration:"
    
    if command -v gpg &>/dev/null; then
        print_success "GPG command available"
        
        # Check for GPG keys
        if gpg --list-secret-keys &>/dev/null; then
            key_count=$(gpg --list-secret-keys --keyid-format LONG | grep -c "^sec" || echo "0")
            print_success "GPG secret keys available ($key_count keys)"
        else
            print_warning "No GPG secret keys found"
        fi
    else
        print_error "GPG command not found"
    fi
    
    echo
}

# Check Pass password manager
validate_pass() {
    echo "🔑 Pass Password Manager:"
    
    if command -v pass &>/dev/null; then
        print_success "Pass command available"
        
        # Check if pass is initialized
        if [[ -d "$HOME/.password-store" ]]; then
            print_success "Pass store initialized"
            
            # Check for AWS credentials
            if pass ls aws &>/dev/null; then
                profile_count=$(pass ls aws 2>/dev/null | grep -c "/" || echo "0")
                print_success "AWS credentials found in pass ($profile_count profiles)"
            else
                print_warning "No AWS credentials found in pass"
            fi
        else
            print_error "Pass store not initialized (run: pass init YOUR-GPG-KEY-ID)"
        fi
    else
        print_error "Pass command not found"
    fi
    
    echo
}

# Check file permissions
validate_permissions() {
    echo "🔒 File Permissions:"
    
    # Check .aws directory permissions
    if [[ -d .aws ]]; then
        aws_perms=$(stat -c %a .aws 2>/dev/null || stat -f %Lp .aws 2>/dev/null)
        if [[ "$aws_perms" == "700" ]]; then
            print_success ".aws directory permissions correct (700)"
        else
            print_warning ".aws directory permissions: $aws_perms (should be 700)"
        fi
    fi
    
    # Check credential script permissions
    if [[ -f .aws/credential-process.sh ]]; then
        script_perms=$(stat -c %a .aws/credential-process.sh 2>/dev/null || stat -f %Lp .aws/credential-process.sh 2>/dev/null)
        if [[ "$script_perms" == "700" ]]; then
            print_success "Credential script permissions correct (700)"
        else
            print_warning "Credential script permissions: $script_perms (should be 700)"
        fi
    fi
    
    echo
}

# Check stow ignore patterns
validate_stow_ignore() {
    echo "🚫 Credential Exposure Prevention:"
    
    if [[ -f .stow-local-ignore ]]; then
        print_success ".stow-local-ignore file exists"
        
        # Check for critical patterns
        critical_patterns=("\.aws/credentials" "\.password-store" ".*secret.*" ".*token.*")
        missing_patterns=()
        
        for pattern in "${critical_patterns[@]}"; do
            if grep -q "$pattern" .stow-local-ignore; then
                print_success "Critical pattern protected: $pattern"
            else
                missing_patterns+=("$pattern")
            fi
        done
        
        if [[ ${#missing_patterns[@]} -gt 0 ]]; then
            print_warning "Missing protection patterns: ${missing_patterns[*]}"
        fi
    else
        print_error ".stow-local-ignore file missing"
    fi
    
    echo
}

# Main validation function
main() {
    print_info
    
    validate_aws_config
    validate_gpg
    validate_pass
    validate_permissions
    validate_stow_ignore
    
    echo "=== Validation Summary ==="
    if [[ $VALIDATION_ERRORS -eq 0 ]]; then
        print_success "All validations passed! Your dotfiles configuration is healthy."
        exit 0
    else
        print_error "$VALIDATION_ERRORS validation error(s) found."
        echo
        echo "Next steps:"
        echo "1. Review the errors above"
        echo "2. Follow the setup guide: README.md"
        echo "3. For help: dotfiles_help (after sourcing .zshrc)"
        exit 1
    fi
}

# Run validation
main "$@"