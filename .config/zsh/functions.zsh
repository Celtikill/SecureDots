#!/usr/bin/env zsh
# Utility functions

# Create directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives (simplified)
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.gz|*.tgz)  tar xzf "$1" ;;
            *.tar.bz2|*.tbz2) tar xjf "$1" ;;
            *.tar.xz)        tar xJf "$1" ;;
            *.tar)           tar xf "$1" ;;
            *.zip)           unzip "$1" ;;
            *.gz)            gunzip "$1" ;;
            *.bz2)           bunzip2 "$1" ;;
            *.7z)            7z x "$1" ;;
            *)               echo "Unknown archive format: $1" >&2; return 1 ;;
        esac
    else
        echo "File not found: $1" >&2
        return 1
    fi
}

# Simple NVM lazy loading (if NVM is installed)
if [[ -d "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    
    # Create lazy loaders for Node.js commands
    for cmd in nvm node npm npx yarn pnpm; do
        eval "${cmd}() {
            unset -f nvm node npm npx yarn pnpm
            [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
            ${cmd} \"\$@\"
        }"
    done
fi


# Configuration discovery and help functions

# Show all available SecureDots configuration options
dotfiles_help() {
    echo "🔧 SecureDots Configuration Help"
    echo "=============================="
    echo
    echo "Essential Functions:"
    echo "  dotfiles_help        - Show this help message"
    echo "  dotfiles_status      - Check what's working and what needs attention"
    echo "  dotfiles_examples    - Show real-world workflow examples"
    echo "  dotfiles_customize   - Guide for personalizing this setup"
    echo
    echo "System Information:"  
    echo "  dotfiles_config      - Show current configuration values"
    echo "  dotfiles_env         - Show environment variables that affect behavior"
    echo "  dotfiles_modules     - Show loaded zsh modules"
    echo "  dotfiles_functions   - List all available functions"
    echo "  dotfiles_security    - Explain security model and architecture"
    echo
    echo "Setup Options:"
    echo "  ./setup-simple.sh    - Basic shell setup without security features"
    echo "  ./setup-secure-zsh.sh - Full security setup with GPG/pass integration"
    echo
    echo "Documentation:"
    echo "  README.md           - Main setup guide"
    echo "  TROUBLESHOOTING.md  - Common issues and solutions"
    echo "  pass-setup.md       - Password manager setup"
    echo "  gpg-mgmnt.md        - GPG key management"
    echo
    echo "📖 Quick Reference: QUICK-REFERENCE.md"
    echo "📚 Full Documentation: docs/USER-GUIDE.md"
}

# Check system status and highlight issues
dotfiles_status() {
    echo "🔍 SecureDots System Status"
    echo "========================="
    echo

    # Check shell configuration
    echo "🐚 Shell Configuration:"
    if [[ "$SHELL" == *"zsh" ]]; then
        echo "   ✓ Zsh is your default shell"
    else
        echo "   ⚠️  Default shell is $SHELL (consider: chsh -s /usr/bin/zsh)"
    fi

    if [[ -n "$ZSH" && -d "$ZSH" ]]; then
        echo "   ✓ Oh My Zsh installed at $ZSH"
    else
        echo "   ❌ Oh My Zsh not found"
    fi

    # Check dotfiles configuration
    echo
    echo "⚙️  Configuration:"
    if [[ -f ~/.zshrc && -L ~/.zshrc ]]; then
        echo "   ✓ .zshrc properly symlinked"
    elif [[ -f ~/.zshrc ]]; then
        echo "   ⚠️  .zshrc exists but not symlinked (backup may exist)"
    else
        echo "   ❌ .zshrc not found"
    fi

    if command -v dotfiles_help &>/dev/null; then
        echo "   ✓ SecureDots functions loaded"
    else
        echo "   ❌ SecureDots functions not available"
    fi

    # Check AWS configuration  
    echo
    echo "☁️  AWS Configuration:"
    if [[ -n "$AWS_PROFILE" ]]; then
        echo "   ✓ AWS profile set: $AWS_PROFILE"
        if command -v aws &>/dev/null; then
            if aws sts get-caller-identity &>/dev/null; then
                echo "   ✓ AWS credentials working"
            else
                echo "   ❌ AWS credentials not working (try: aws_switch $AWS_PROFILE)"
            fi
        else
            echo "   ⚠️  AWS CLI not installed"
        fi
    else
        echo "   ⚠️  No AWS profile set (try: aws_switch dev)"
    fi

    # Check security tools
    echo  
    echo "🔐 Security Tools:"
    if command -v gpg &>/dev/null; then
        echo "   ✓ GPG available"
        if gpg-connect-agent 'getinfo version' /bye &>/dev/null; then
            echo "   ✓ GPG agent running"
        else
            echo "   ⚠️  GPG agent not running"
        fi
    else
        echo "   ❌ GPG not installed"
    fi

    if command -v pass &>/dev/null; then
        echo "   ✓ Pass password manager available"
    else
        echo "   ❌ Pass not installed (see: docs/guides/pass-setup.md)"
    fi

    # Overall status
    echo
    echo "📋 Quick Actions:"
    echo "   • Reload config: source ~/.zshrc"  
    echo "   • Get help: dotfiles_help"
    echo "   • See examples: dotfiles_examples"
    echo "   • Full setup: ./setup/setup-secure-zsh.sh"
}

# Show current configuration values
dotfiles_config() {
    echo "📋 Current SecureDots Configuration"
    echo "=================================="
    echo
    echo "Shell Configuration:"
    echo "  Shell:              ${SHELL}"
    echo "  Oh My Zsh:          ${ZSH:-Not set}"
    echo "  Platform:           $(uname -s)"
    echo "  Architecture:       $(uname -m)"
    echo
    echo "AWS Configuration:"
    echo "  AWS Profile:        ${AWS_PROFILE:-default}"
    echo "  AWS Config:         ${AWS_CONFIG_FILE:-~/.aws/config}"
    echo "  AWS Credentials:    ${AWS_SHARED_CREDENTIALS_FILE:-~/.aws/credentials}"
    echo
    echo "GPG Configuration:"
    echo "  GPG TTY:            ${GPG_TTY:-Not set}"
    echo "  GPG Agent:          $(gpg-connect-agent 'getinfo version' /bye 2>/dev/null | head -1 || echo 'Not running')"
    echo
    echo "Pass Configuration:"
    echo "  Pass Store:         ${PASSWORD_STORE_DIR:-~/.password-store}"
    echo "  Pass GPG ID:        $(pass show .gpg-id 2>/dev/null || echo 'Not configured')"
    echo
    echo "Development Tools:"
    echo "  Git:                $(git --version 2>/dev/null || echo 'Not installed')"
    echo "  Vim:                $(vim --version 2>/dev/null | head -1 || echo 'Not installed')"
    echo "  Conda:              ${CONDA_PREFIX:-Not activated}"
    echo "  Conda Base:         ${CONDA_BASE:-Not configured}"
    echo "  NVM:                ${NVM_DIR:-Not installed}"
}

# Show environment variables that affect behavior
dotfiles_env() {
    echo "🌍 Environment Variables"
    echo "======================="
    echo
    echo "Shell Behavior:"
    echo "  ZSH_VERBOSE         - Enable verbose startup messages"
    echo "  Current value:      ${ZSH_VERBOSE:-false}"
    echo
    echo "AWS Behavior:"
    echo "  AWS_PROFILE_INTERACTIVE - Enable interactive profile selection"
    echo "  Current value:      ${AWS_PROFILE_INTERACTIVE:-true}"
    echo
    echo "  AWS_PROFILE_TIMEOUT - Timeout for profile selection (seconds)"
    echo "  Current value:      ${AWS_PROFILE_TIMEOUT:-10}"
    echo
    echo "  AWS_PROFILE_DEFAULT - Default profile to use"
    echo "  Current value:      ${AWS_PROFILE_DEFAULT:-default}"
    echo
    echo "  AWS_CREDENTIAL_PROCESS_DEBUG - Enable credential debug output"
    echo "  Current value:      ${AWS_CREDENTIAL_PROCESS_DEBUG:-false}"
    echo
    echo "GPG Behavior:"
    echo "  GPG_TTY             - Terminal for GPG operations"
    echo "  Current value:      ${GPG_TTY:-$(tty)}"
    echo
    echo "Pass Behavior:"
    echo "  PASSWORD_STORE_DIR  - Location of password store"
    echo "  Current value:      ${PASSWORD_STORE_DIR:-~/.password-store}"
    echo
    echo "Conda Behavior:"
    echo "  CONDA_AUTO_ACTIVATE - Auto-activate base environment"
    echo "  Current value:      ${CONDA_AUTO_ACTIVATE:-true}"
    echo
    echo "  CONDA_AUTO_REFRESH  - Auto-refresh environment list"
    echo "  Current value:      ${CONDA_AUTO_REFRESH:-true}"
    echo
    echo "  CONDA_CUSTOM_PATH   - Custom conda installation path"
    echo "  Current value:      ${CONDA_CUSTOM_PATH:-Not set}"
    echo
    echo "To set any of these, add to ~/.zshrc.local:"
    echo "  echo 'export ZSH_VERBOSE=true' >> ~/.zshrc.local"
}

# Show loaded zsh modules
dotfiles_modules() {
    echo "📦 Loaded Zsh Modules"
    echo "===================="
    echo
    echo "Configuration modules loaded from ~/.config/zsh/:"
    
    local modules_dir="$HOME/.config/zsh"
    if [[ -d "$modules_dir" ]]; then
        for module in "$modules_dir"/*.zsh; do
            if [[ -f "$module" ]]; then
                local module_name=$(basename "$module" .zsh)
                echo "  ✓ $module_name"
                
                # Try to extract description from first comment
                local description=$(grep -m1 "^#" "$module" 2>/dev/null | sed 's/^# *//' || echo "No description")
                echo "    $description"
            fi
        done
    else
        echo "  Module directory not found: $modules_dir"
    fi
    echo
    echo "To add custom modules, create .zsh files in $modules_dir"
}

# List all available functions
dotfiles_functions() {
    echo "⚡ Available Functions"
    echo "===================="
    echo
    echo "Setup Functions:"
    echo "  mkcd <dir>          - Create directory and enter it"
    echo "  extract <file>      - Extract various archive formats"
    echo
    echo "Pass/AWS Functions:"
    echo "  penv <path>         - Load environment variables from pass"
    echo "  penv_clear          - Clear environment variables loaded by penv"
    echo
    echo "Conda Functions:"
    echo "  conda_list_environments - List all conda environments"
    echo "  conda_activate <env>    - Activate conda environment"
    echo "  conda_refresh_environments - Refresh local environment list"
    echo
    echo "Configuration Functions:"
    echo "  dotfiles_help       - Show configuration help"
    echo "  dotfiles_config     - Show current configuration"
    echo "  dotfiles_env        - Show environment variables"
    echo "  dotfiles_modules    - Show loaded modules"
    echo "  dotfiles_functions  - Show this function list"
    echo
    echo "AWS Functions (if configured):"
    echo "  aws_check           - Check AWS credentials"
    echo "  aws_switch <profile> - Switch AWS profile"
    echo
    echo "GPG Functions (if configured):"
    echo "  gpg_card_status     - Check GPG card status"
    echo "  mount_gpg_vault     - Mount GPG vault"
    echo
    echo "For detailed help on any function, run: <function_name> --help"
}

# Show practical workflow examples
dotfiles_examples() {
    echo "🚀 Real-World Workflow Examples"
    echo "==============================="
    echo
    echo "🏁 First-Time Setup Check:"
    echo "  dotfiles_status                # Check what's working"
    echo "  dotfiles_help                  # See available functions"
    echo "  source ~/.zshrc                # Reload if needed"
    echo
    echo "🔐 Daily AWS Development:"
    echo "  aws_switch dev                 # Switch to development"
    echo "  aws_check                      # Verify credentials work"
    echo "  aws s3 ls                      # Use AWS CLI normally"
    echo "  aws_current                    # Check which account you're in"
    echo
    echo "🔑 Secure Credential Loading:"
    echo "  penv aws/dev                   # Load from encrypted storage"
    echo "  aws sts get-caller-identity    # Test the loaded credentials"
    echo "  # ... do your work ..."
    echo "  penv_clear                     # Clean up when done"
    echo
    echo "🛠️  Troubleshooting Workflow:"
    echo "  dotfiles_status                # See what needs attention"
    echo "  source ~/.zshrc                # Reload configuration"
    echo "  dotfiles_config                # Check current settings"
    echo "  # Still having issues? See: QUICK-REFERENCE.md"
    echo
    echo "⚙️  Customization Examples:"
    echo "  # Create ~/.zshrc.local for personal settings:"
    echo "  echo 'export AWS_PROFILE_DEFAULT=staging' >> ~/.zshrc.local"
    echo "  echo 'export ZSH_VERBOSE=true' >> ~/.zshrc.local"
    echo "  echo 'alias myproject=\"cd ~/work/myproject\"' >> ~/.zshrc.local"
    echo
    echo "📖 More Examples: See QUICK-REFERENCE.md for mobile-friendly format"
}

# Explain security model and choices
dotfiles_security() {
    echo "🔒 Security Model & Architecture"
    echo "==============================="
    echo
    echo "🛡️  Defense-in-Depth Approach:"
    echo "  Layer 1: No plaintext credentials stored anywhere"
    echo "  Layer 2: GPG encryption for all sensitive data"
    echo "  Layer 3: Input validation and injection prevention"
    echo "  Layer 4: Environment restrictions and allowlists"
    echo
    echo "🔐 Credential Management:"
    echo "  • AWS credentials: Stored in 'pass' (GPG-encrypted)"
    echo "  • Credential process: Dynamically retrieves from pass/GPG"
    echo "  • No credentials file: AWS_SHARED_CREDENTIALS_FILE=/dev/null"
    echo "  • Profile restrictions: Only dev/staging accessible via aws_switch"
    echo
    echo "🔑 GPG Integration:"
    echo "  • Hardware security keys supported (Yubikey, etc.)"
    echo "  • Software-only GPG keys for development machines"
    echo "  • Configurable cache TTL for security vs usability balance"
    echo "  • SSH authentication via GPG (optional advanced feature)"
    echo
    echo "⚠️  Threat Model:"
    echo "  ✓ Protects against: Credential theft, accidental commits, injection attacks"
    echo "  ✓ Assumes: Local machine compromise detection, physical security"
    echo "  ℹ️  For production: Use hardware security keys + short cache TTL"
    echo
    echo "📚 Security Resources:"
    echo "  • GPG setup: docs/guides/gpg-mgmnt.md"
    echo "  • Pass setup: docs/guides/pass-setup.md"
    echo "  • Troubleshooting: docs/guides/TROUBLESHOOTING.md"
}

# Guide for customizing the setup
dotfiles_customize() {
    echo "🎨 Customization Guide"
    echo "====================="
    echo
    echo "🚀 Quick Start Customization:"
    echo "  1. Create ~/.zshrc.local for personal settings"
    echo "  2. Fork this repository for extensive changes"
    echo "  3. Use environment variables for feature toggles"
    echo
    echo "📝 Common Customizations:"
    echo
    echo "  # ~/.zshrc.local examples:"
    echo "  export AWS_PROFILE_DEFAULT=prod    # Change default AWS profile"
    echo "  export AWS_DEFAULT_REGION=us-west-2 # Change default region"
    echo "  export ZSH_VERBOSE=true            # Enable startup diagnostics"
    echo "  export ENABLE_CONDA=1              # Enable Python environment management"
    echo "  alias myproject='cd ~/dev/myproject && code .'"
    echo
    echo "🔧 Module Configuration:"
    echo "  • AWS profiles: Edit available_profiles in ~/.config/zsh/aws.zsh"
    echo "  • Aliases: Add custom aliases to ~/.config/zsh/aliases.zsh"
    echo "  • Functions: Add utilities to ~/.config/zsh/functions.zsh"
    echo
    echo "🎯 Performance Tuning:"
    echo "  • Disable unused features via environment variables"
    echo "  • Use conditional loading for heavy modules (conda, etc.)"
    echo "  • Profile startup time with: time zsh -i -c exit"
    echo
    echo "🔐 Security Customization:"
    echo "  • Update GPG cache TTL in ~/.gnupg/gpg-agent.conf"
    echo "  • Modify profile restrictions in aws.zsh"
    echo "  • Configure pass store location with PASSWORD_STORE_DIR"
    echo
    echo "🌐 Multi-Platform:"
    echo "  • OS-specific settings in ~/.config/zsh/platform.zsh"
    echo "  • Conditional feature loading based on available commands"
    echo "  • Use .stow-local-ignore to exclude platform-specific files"
    echo
    echo "For more help: dotfiles_help | dotfiles_examples | dotfiles_security"
}

# Enhanced penv function with help
penv() {
    local pass_path="$1"
    
    if [[ -z "$pass_path" || "$pass_path" == "--help" ]]; then
        echo "📋 Pass Environment Loader"
        echo "========================="
        echo
        echo "Usage: penv <pass-path>"
        echo
        echo "Examples:"
        echo "  penv aws/dev        - Load AWS credentials from aws/dev"
        echo "  penv aws/prod       - Load AWS credentials from aws/prod"
        echo "  penv_clear          - Clear loaded environment variables"
        echo
        echo "AWS credential paths should contain:"
        echo "  aws/profile/access-key-id"
        echo "  aws/profile/secret-access-key"
        echo "  aws/profile/session-token (optional)"
        echo
        echo "Current loaded path: ${PENV_LOADED_PATH:-None}"
        return 0
    fi
    
    # Check if pass entry exists
    if ! pass ls "$pass_path" &>/dev/null; then
        echo "❌ Pass entry not found: $pass_path" >&2
        echo "Available entries:"
        pass ls | head -10
        return 1
    fi
    
    # Load common AWS credential patterns
    if [[ "$pass_path" =~ ^aws/ ]]; then
        local access_key_path="${pass_path}/access-key-id"
        local secret_key_path="${pass_path}/secret-access-key"
        local session_token_path="${pass_path}/session-token"
        
        if pass show "$access_key_path" &>/dev/null; then
            export AWS_ACCESS_KEY_ID="$(pass show "$access_key_path")"
            echo "✓ AWS_ACCESS_KEY_ID loaded from $access_key_path"
        fi
        
        if pass show "$secret_key_path" &>/dev/null; then
            export AWS_SECRET_ACCESS_KEY="$(pass show "$secret_key_path")"
            echo "✓ AWS_SECRET_ACCESS_KEY loaded from $secret_key_path"
        fi
        
        if pass show "$session_token_path" &>/dev/null; then
            export AWS_SESSION_TOKEN="$(pass show "$session_token_path")"
            echo "✓ AWS_SESSION_TOKEN loaded from $session_token_path"
        fi
        
        # Store the loaded path for easy clearing
        export PENV_LOADED_PATH="$pass_path"
        echo "Environment variables loaded from pass:$pass_path"
    else
        echo "Generic pass entry loading not yet implemented for: $pass_path" >&2
        return 1
    fi
}

# Clear environment variables loaded by penv
penv_clear() {
    local patterns=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_SESSION_TOKEN")
    
    for var in "${patterns[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            unset "$var"
            echo "✓ Cleared $var"
        fi
    done
    
    if [[ -n "$PENV_LOADED_PATH" ]]; then
        echo "Cleared environment variables from pass:$PENV_LOADED_PATH"
        unset PENV_LOADED_PATH
    fi
}

export GPG_TTY=$(tty)
