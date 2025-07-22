#!/bin/bash
# setup-secure-zsh.sh
# Script to set up the secure Zsh configuration with AWS profiles and pass
# This version checks for and uses the existing credential process script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

echo "=== Secure Zsh Configuration Setup ==="
echo

# Step 1: Backup existing configuration
print_info "Backing up existing configuration files..."
backup_dir=$(mktemp -d "${HOME}/.config-backup-XXXXXX")
chmod 700 "$backup_dir"

for file in .zshrc .aws/config .aws/credentials .aws/credential-process.sh .gitignore_global .gnupg/gpg-agent.conf; do
    if [[ -f "$HOME/$file" ]]; then
        # Create subdirectories in backup if needed
        mkdir -p "$backup_dir/$(dirname "$file")"
        cp "$HOME/$file" "$backup_dir/$file"
        print_success "Backed up $file"
    fi
done

# Step 2: Check for required tools
print_info "Checking for required tools..."
missing_tools=()
optional_missing=()

# Required tools
for tool in gpg pass git aws zsh; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    else
        print_success "$tool is installed"
    fi
done

# Optional tools
for tool in jq; do
    if ! command -v "$tool" &> /dev/null; then
        optional_missing+=("$tool")
        print_warning "$tool is not installed (optional but recommended)"
    else
        print_success "$tool is installed"
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    print_error "Missing required tools: ${missing_tools[*]}"
    print_info "Installation commands:"
    
    # Detect OS and provide installation commands
    if [[ -f /etc/debian_version ]]; then
        echo "  sudo apt-get update && sudo apt-get install -y ${missing_tools[*]}"
    elif [[ -f /etc/redhat-release ]]; then
        echo "  sudo yum install -y ${missing_tools[*]}"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "  brew install ${missing_tools[*]}"
    else
        echo "  Please install: ${missing_tools[*]}"
    fi
    
    exit 1
fi

# Step 3: Check Oh My Zsh installation
print_info "Checking Oh My Zsh installation..."
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    print_warning "Oh My Zsh not found"
    read -p "Would you like to install Oh My Zsh? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    fi
else
    print_success "Oh My Zsh is installed"
fi

# Step 4: Install Pure theme
print_info "Checking Pure theme installation..."
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    PURE_DIR="$HOME/.oh-my-zsh/custom/themes/pure"
    if [[ ! -d "$PURE_DIR" ]]; then
        print_warning "Pure theme not found"
        read -p "Would you like to install Pure theme? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installing Pure theme..."
            if ./setup/install-pure-theme.sh; then
                print_success "Pure theme installed"
            else
                print_warning "Failed to install Pure theme, continuing..."
            fi
        fi
    else
        print_success "Pure theme is installed"
    fi
fi

# Step 5: Check GPG setup
print_info "Checking GPG configuration..."
if ! gpg --list-secret-keys | grep -q "sec"; then
    print_warning "No GPG keys found"
    echo "You need to create a GPG key for pass to work:"
    echo "  1. Run: gpg --full-generate-key"
    echo "  2. Follow the prompts (RSA 4096-bit recommended)"
    echo "  3. Note your key ID from: gpg --list-secret-keys --keyid-format LONG"
    echo "  4. Initialize pass: pass init YOUR-GPG-KEY-ID"
    
    read -p "Would you like to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_success "GPG key found"
    
    # Show available GPG keys
    echo "Available GPG keys:"
    gpg --list-secret-keys --keyid-format LONG | grep -E "^sec|^uid" | sed 's/^/  /'
fi

# Step 6: Check pass initialization
print_info "Checking pass initialization..."
if [[ ! -d "$HOME/.password-store" ]]; then
    print_warning "Pass not initialized"
    
    # Try to help with initialization if GPG key exists
    if gpg --list-secret-keys | grep -q "sec"; then
        echo "Found GPG key(s). You can initialize pass with:"
        key_id=$(gpg --list-secret-keys --keyid-format LONG | grep "^sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
        echo "  pass init $key_id"
    else
        echo "Initialize pass after creating a GPG key:"
        echo "  pass init YOUR-GPG-KEY-ID"
    fi
    
    read -p "Would you like to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_success "Pass is initialized"
    
    # Check if git is initialized for pass
    if [[ -d "$HOME/.password-store/.git" ]]; then
        print_success "Pass git repository initialized"
    else
        print_info "Pass git not initialized (optional but recommended)"
        echo "  To enable: pass git init"
    fi
fi

# Step 7: Create required directories
print_info "Creating required directories..."
mkdir -p "$HOME/.aws" "$HOME/.gnupg"
chmod 700 "$HOME/.aws" "$HOME/.gnupg"
print_success "Directories created with secure permissions"

# Step 8: Check for credential process script
print_info "Checking AWS credential process script..."
cred_script="$HOME/.aws/credential-process.sh"

if [[ -f "$cred_script" ]]; then
    print_success "Credential process script found"
    
    # Check permissions
    if [[ "$(uname)" == "Darwin" ]]; then
        perms=$(stat -f %p "$cred_script" | cut -c 4-6)
    else
        perms=$(stat -c %a "$cred_script" 2>/dev/null)
    fi
    
    if [[ "$perms" != "700" ]]; then
        print_warning "Fixing insecure permissions on credential script (was: $perms)"
        chmod 700 "$cred_script"
        print_success "Set secure permissions (700) on credential script"
    fi
    
    # Test if script has help and validate output
    if help_output=$("$cred_script" --help 2>&1) && [[ -n "$help_output" ]]; then
        if echo "$help_output" | grep -q "AWS Credential Process Script"; then
            print_success "Credential script appears to be the enhanced version"
        else
            print_warning "Credential script help output unexpected"
            echo "  Script may not be the expected version"
        fi
    else
        print_warning "Credential script doesn't support --help flag"
        echo "  Consider upgrading to the enhanced version with debugging support"
    fi
else
    print_error "Credential process script not found at: $cred_script"
    echo "Please ensure the AWS credential process script is installed at:"
    echo "  $cred_script"
    echo ""
    echo "The script should be the enhanced version with features like:"
    echo "  - Debug mode support (AWS_CREDENTIAL_PROCESS_DEBUG=true)"
    echo "  - Retry logic for credential retrieval"
    echo "  - Session token support"
    echo "  - Proper error handling"
    exit 1
fi

# Step 9: Create AWS config
print_info "Creating AWS config file..."

# Detect default profile based on system
if [[ "$(uname)" == "Linux" ]]; then
    default_profile="personal"
elif [[ "$(uname)" == "Darwin" ]]; then
    default_profile="work"
else
    default_profile="personal"
fi

cat > "$HOME/.aws/config" << EOF
# AWS CLI configuration using credential_process with pass
# Generated by setup script on $(date)

[default]
region = us-east-2
output = json

[profile personal]
region = us-east-2
output = json
credential_process = $cred_script personal

[profile work]
region = us-east-2
output = json
credential_process = $cred_script work

# Additional profiles can be added here
# [profile staging]
# region = us-east-2
# output = json
# credential_process = $cred_script staging
EOF

chmod 600 "$HOME/.aws/config"
print_success "AWS config created (default profile will be: $default_profile)"

# Step 10: Create/update GPG agent configuration
print_info "Configuring GPG agent..."
gpg_conf_dir="$HOME/.gnupg"
gpg_agent_conf="$gpg_conf_dir/gpg-agent.conf"

if [[ -f "$gpg_agent_conf" ]]; then
    print_info "GPG agent config exists, checking for required settings..."
    
    # Check if it's configured for hardware keys
    if grep -q "^default-cache-ttl 0" "$gpg_agent_conf"; then
        print_success "GPG agent configured for hardware keys (no caching)"
    else
        print_warning "GPG agent may be caching credentials"
        echo "  For hardware keys, consider setting: default-cache-ttl 0"
    fi
else
    print_info "Creating GPG agent configuration..."
    cat > "$gpg_agent_conf" << 'EOF'
# GPG Agent configuration
# Generated by setup script

# Cache settings - optimized for hardware keys (YubiKey, etc.)
# Set to 0 to always require touch/PIN for maximum security
default-cache-ttl 0
max-cache-ttl 0

# Note: For software-only GPG keys, you may want caching:
# Uncomment and modify these lines if not using hardware keys:
# default-cache-ttl 600    # 10 minutes
# max-cache-ttl 7200       # 2 hours

# SSH key cache (if using GPG for SSH)
default-cache-ttl-ssh 0
max-cache-ttl-ssh 0

# Pinentry program selection (will fall back if not available)
pinentry-program /usr/bin/pinentry-curses

# Enable SSH support if using GPG authentication key for SSH
enable-ssh-support

# For hardware tokens: don't cache card PIN
no-allow-external-cache

# Card timeout - remove card status after this many seconds
card-timeout 0
EOF
    chmod 600 "$gpg_agent_conf"
    print_success "GPG agent configuration created"
fi

# Step 11: Create global gitignore
print_info "Setting up global gitignore..."
gitignore_global="$HOME/.gitignore_global"

cat > "$gitignore_global" << 'EOF'
# Global Git ignore file
# Generated by setup script

# AWS credentials - NEVER commit these!
.aws/credentials
.aws/config.bak
aws_credentials.txt
*_accessKeys.csv

# Environment files
.env
.env.local
.env.*.local

# GPG/Pass
*.gpg
.password-store/

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.bak
*.backup
EOF

git config --global core.excludesfile "$gitignore_global"
print_success "Global gitignore configured"

# Step 12: Check for existing AWS keys in pass
print_info "Checking for AWS credentials in pass..."
profiles=("personal" "work")
missing_creds=()
configured_profiles=()

for profile in "${profiles[@]}"; do
    if pass show "aws/$profile/access-key-id" &>/dev/null; then
        configured_profiles+=("$profile")
        print_success "Found credentials for profile: $profile"
    else
        missing_creds+=("$profile")
    fi
done

if [[ ${#missing_creds[@]} -gt 0 ]]; then
    print_warning "Missing credentials for profiles: ${missing_creds[*]}"
    echo
    echo "To add credentials for each profile, run:"
    for profile in "${missing_creds[@]}"; do
        echo "  # For $profile profile:"
        echo "  pass insert aws/$profile/access-key-id"
        echo "  pass insert aws/$profile/secret-access-key"
        echo
    done
fi

# Step 13: Test AWS configuration
if [[ ${#configured_profiles[@]} -gt 0 ]]; then
    print_info "Testing AWS configuration..."
    
    # Test with debug mode to see more details
    test_profile="${configured_profiles[0]}"
    
    print_info "Testing profile: $test_profile"
    if AWS_PROFILE="$test_profile" AWS_CREDENTIAL_PROCESS_DEBUG=true aws sts get-caller-identity &>/dev/null; then
        print_success "AWS credentials working for profile: $test_profile"
        
        # Show identity if jq is available
        if command -v jq &>/dev/null; then
            identity=$(AWS_PROFILE="$test_profile" aws sts get-caller-identity)
            account=$(echo "$identity" | jq -r .Account)
            arn=$(echo "$identity" | jq -r .Arn)
            echo "  Account: $account"
            echo "  ARN: $arn"
        else
            AWS_PROFILE="$test_profile" aws sts get-caller-identity --output table
        fi
    else
        print_warning "Could not verify AWS credentials for profile: $test_profile"
        echo "  Debug with: AWS_CREDENTIAL_PROCESS_DEBUG=true aws sts get-caller-identity"
    fi
else
    print_warning "No AWS credentials configured in pass yet"
fi

# Step 14: Test credential process script directly
print_info "Testing credential process script..."
if "$cred_script" --version &>/dev/null; then
    version=$("$cred_script" --version 2>/dev/null | head -1)
    print_success "Credential script version: $version"
else
    print_warning "Could not determine credential script version"
fi

# Final summary and instructions
echo
echo "=== Setup Summary ==="
echo

# Show what was configured
echo "Configured components:"
[[ -f "$HOME/.aws/config" ]] && echo "  ✓ AWS config file"
[[ -x "$cred_script" ]] && echo "  ✓ AWS credential process script"
[[ -f "$gpg_agent_conf" ]] && echo "  ✓ GPG agent configuration"
[[ -f "$gitignore_global" ]] && echo "  ✓ Global gitignore"
[[ -d "$HOME/.password-store" ]] && echo "  ✓ Pass password store"

echo
echo "=== Next Steps ==="
echo

# Numbered next steps
step=1

# Copy zshrc if not already in place
if [[ ! -f "$HOME/.zshrc" ]] || ! grep -q "credential_process" "$HOME/.zshrc" 2>/dev/null; then
    echo "$step. Copy the improved .zshrc file:"
    echo "   cp 'Improved .zshrc with Secure Configuration.txt' ~/.zshrc"
    ((step++))
fi

# Add credentials if missing
if [[ ${#missing_creds[@]} -gt 0 ]]; then
    echo "$step. Add your AWS credentials to pass:"
    for profile in "${missing_creds[@]}"; do
        echo "   pass insert aws/$profile/access-key-id"
        echo "   pass insert aws/$profile/secret-access-key"
    done
    ((step++))
fi

# Source configuration
echo "$step. Source your configuration:"
echo "   source ~/.zshrc"
((step++))

# Test the setup
echo "$step. Test the setup:"
echo "   aws_check                    # Test current profile"
echo "   aws_switch personal         # Switch profiles"
echo "   gpg_card_status            # Check hardware key (if using)"
((step++))

# Security reminder
echo "$step. Security reminders:"
echo "   - Rotate any exposed AWS credentials immediately"
echo "   - Keep your GPG key backed up securely"
echo "   - Never commit credentials to git"
echo

print_info "Backup of original files saved to: $backup_dir"

# Optional: Show debug tips
if [[ ${#optional_missing[@]} -gt 0 ]] || [[ ${#missing_creds[@]} -gt 0 ]]; then
    echo
    echo "=== Troubleshooting Tips ==="
    echo
    echo "If you encounter issues:"
    echo "  - Enable debug mode: export AWS_CREDENTIAL_PROCESS_DEBUG=true"
    echo "  - Check GPG agent: gpg-connect-agent reloadagent /bye"
    echo "  - Test credential script: ~/.aws/credential-process.sh personal"
    echo "  - Verify pass entries: pass show aws/personal/access-key-id"
fi

echo
print_success "Setup complete!"
