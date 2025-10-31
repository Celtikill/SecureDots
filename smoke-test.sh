#!/bin/bash
# smoke-test.sh - Post-deployment verification for dotfiles
# Tests actual functionality after setup/changes

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Test results
TEST_FAILURES=0

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((TEST_FAILURES++))
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo "Running dotfiles smoke tests..."
    echo
}

# Test shell configuration
test_shell_config() {
    echo "🐚 Shell Configuration:"
    
    # Test if .zshrc exists and is valid
    if [[ -f .zshrc ]]; then
        print_success ".zshrc file exists"
        
        # Test if .zshrc is syntactically valid
        if zsh -n .zshrc 2>/dev/null; then
            print_success ".zshrc syntax is valid"
        else
            print_error ".zshrc has syntax errors"
        fi
    else
        print_error ".zshrc file missing"
    fi
    
    echo
}

# Test AWS functionality
test_aws_functionality() {
    echo "☁️  AWS Functionality:"
    
    # Source shell configuration to get functions
    if [[ -f .zshrc ]]; then
        # Source minimal AWS functions for testing
        if [[ -f .config/zsh/aws.zsh ]]; then
            source .config/zsh/aws.zsh 2>/dev/null || true
            
            # Test if aws_check function is available
            if declare -f aws_check >/dev/null; then
                print_success "AWS functions loaded"
                
                # Test AWS CLI availability
                if command -v aws &>/dev/null; then
                    print_success "AWS CLI available"
                    
                    # Check for relative paths in AWS config (common error on macOS)
                    if [[ -f .aws/config ]]; then
                        if grep -E '^\s*credential_process\s*=' .aws/config | grep -qvE '^\s*credential_process\s*=\s*/'; then
                            print_error "AWS config uses relative paths (will fail at runtime)"
                            echo "  Run: ./validate.sh for fix instructions"
                        else
                            print_success "AWS config uses absolute paths"
                        fi
                    fi

                    # Test credential process (if configured)
                    if [[ -x .aws/credential-process.sh ]]; then
                        # Test with a likely profile (but don't fail if it doesn't exist)
                        if AWS_PROFILE=dev timeout 10s .aws/credential-process.sh dev &>/dev/null; then
                            print_success "Credential process working"
                        elif [[ -f "$HOME/.password-store/aws/dev/access-key-id.gpg" ]]; then
                            print_warning "Credential process failed (may need GPG authentication)"
                        else
                            print_warning "No dev profile configured (expected for new setups)"
                        fi
                    else
                        print_warning "Credential process script not executable"
                    fi
                else
                    print_warning "AWS CLI not installed"
                fi
            else
                print_error "AWS functions not available"
            fi
        else
            print_warning "AWS configuration module not found"
        fi
    fi
    
    echo
}

# Test GPG functionality
test_gpg_functionality() {
    echo "🔐 GPG Functionality:"
    
    if command -v gpg &>/dev/null; then
        print_success "GPG command available"
        
        # Test GPG agent
        if gpg-connect-agent /bye &>/dev/null; then
            print_success "GPG agent responding"
        else
            print_warning "GPG agent not responding (may need restart)"
        fi
        
        # Test basic GPG functionality
        if echo "test" | gpg --clearsign &>/dev/null; then
            print_success "GPG signing works"
        else
            print_warning "GPG signing failed (may need key setup or authentication)"
        fi
    else
        print_error "GPG command not found"
    fi
    
    echo
}

# Test Pass functionality
test_pass_functionality() {
    echo "🔑 Pass Functionality:"
    
    if command -v pass &>/dev/null; then
        print_success "Pass command available"
        
        # Test if pass is initialized
        if pass ls &>/dev/null; then
            print_success "Pass store accessible"
            
            # Check for AWS entries
            if pass ls aws &>/dev/null; then
                print_success "AWS entries found in pass"
            else
                print_warning "No AWS entries in pass (expected for new setups)"
            fi
        else
            print_warning "Pass store not initialized or inaccessible"
        fi
    else
        print_error "Pass command not found"
    fi
    
    echo
}

# Test file permissions and security
test_security() {
    echo "🔒 Security Configuration:"
    
    # Test .aws directory permissions
    if [[ -d .aws ]]; then
        aws_perms=$(stat -c %a .aws 2>/dev/null || stat -f %Lp .aws 2>/dev/null)
        if [[ "$aws_perms" == "700" ]]; then
            print_success ".aws directory secure (700)"
        else
            print_warning ".aws permissions: $aws_perms (recommend 700)"
        fi
    fi
    
    # Test for credential exposure protection
    if [[ -f .stow-local-ignore ]]; then
        if grep -q "\.aws/credentials" .stow-local-ignore; then
            print_success "Credential exposure protection active"
        else
            print_warning "Credential exposure protection may be incomplete"
        fi
    else
        print_error "No credential exposure protection (.stow-local-ignore missing)"
    fi
    
    echo
}

# Test utility functions
test_utility_functions() {
    echo "🛠️  Utility Functions:"
    
    # Source functions if available
    if [[ -f .config/zsh/functions.zsh ]]; then
        source .config/zsh/functions.zsh 2>/dev/null || true
        
        # Test key functions
        functions_to_test=("dotfiles_help" "dotfiles_config")
        for func in "${functions_to_test[@]}"; do
            if declare -f "$func" >/dev/null; then
                print_success "$func function available"
            else
                print_warning "$func function not found"
            fi
        done
    else
        print_warning "Functions module not found"
    fi
    
    echo
}

# Main test function
main() {
    print_info
    
    test_shell_config
    test_aws_functionality
    test_gpg_functionality
    test_pass_functionality
    test_security
    test_utility_functions
    
    echo "=== Smoke Test Summary ==="
    if [[ $TEST_FAILURES -eq 0 ]]; then
        print_success "All smoke tests passed! Your dotfiles are working correctly."
        echo
        echo "Next steps:"
        echo "1. Source your shell config: source ~/.zshrc"
        echo "2. Add AWS credentials: pass insert aws/dev/access-key-id"
        echo "3. Test AWS integration: aws_check"
        exit 0
    else
        print_error "$TEST_FAILURES smoke test(s) failed."
        echo
        echo "Troubleshooting:"
        echo "1. Run validation first: ./validate.sh"
        echo "2. Check setup scripts: ./setup-simple.sh or ./setup-secure-zsh.sh"
        echo "3. Review documentation: README.md"
        exit 1
    fi
}

# Run smoke tests
main "$@"