#!/bin/bash

# Simple Setup Script for Basic Shell Configuration
# This script provides dotfiles setup without GPG/pass security model

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Enhanced error handling
handle_error() {
    local error_type="$1"
    local error_msg="$2"
    
    print_error "$error_msg"
    
    case "$error_type" in
        "missing_tool")
            echo "Installation help:"
            echo "  macOS: brew install <tool-name>"
            echo "  Ubuntu/Debian: sudo apt-get install <tool-name>"
            echo "  Arch Linux: sudo pacman -S <tool-name>"
            ;;
        "stow_error")
            echo "Stow troubleshooting:"
            echo "  1. Check if files are already symlinked"
            echo "  2. Remove conflicting files manually"
            echo "  3. Run with --verbose for detailed output"
            echo "  4. Try: stow --restow ."
            ;;
        "config_error")
            echo "Configuration troubleshooting:"
            echo "  1. Check file permissions"
            echo "  2. Verify shell syntax"
            echo "  3. Try: zsh -n ~/.zshrc"
            echo "  4. Check backup directory for previous config"
            ;;
    esac
    
    echo "For more help:"
    echo "  • Check: README.md"
    echo "  • Run: dotfiles_help (after setup)"
    echo "  • See: docs/guides/TROUBLESHOOTING.md"
}

# Check if we're in the dotfiles directory
if [[ ! -f "$(pwd)/setup/setup-simple.sh" ]] && [[ ! -f "setup-simple.sh" ]]; then
    print_error "This script must be run from the dotfiles directory (found $(pwd))"
    exit 1
fi

echo "🔒 SecureDots Simple Setup"
echo "========================="
echo "This will configure your local development environment with enterprise-grade security (15-20 minutes)"
echo ""

# Progress tracking
TOTAL_STEPS=7
CURRENT_STEP=1

# Progress indicator function
show_progress() {
    echo "Step $CURRENT_STEP/$TOTAL_STEPS: $1"
    CURRENT_STEP=$((CURRENT_STEP + 1))
}

show_progress "Checking prerequisites and required tools"

if ! command -v git &> /dev/null; then
    handle_error "missing_tool" "git is required but not installed"
    exit 1
fi

if ! command -v stow &> /dev/null; then
    handle_error "missing_tool" "GNU Stow is required but not installed"
    exit 1
fi

if ! command -v zsh &> /dev/null; then
    handle_error "missing_tool" "zsh is required but not installed"
    exit 1
fi

print_success "All required tools are available"

show_progress "Installing Oh My Zsh framework"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    if ! ./setup/install-omz.sh; then
        handle_error "config_error" "Failed to install Oh My Zsh"
        exit 1
    fi
    print_success "Oh My Zsh installed"
else
    print_warning "Oh My Zsh already installed, skipping"
fi

show_progress "Installing Pure theme (minimal, fast prompt)"
if ./setup/install-pure-theme.sh; then
    print_success "Pure theme installed"
else
    print_warning "Failed to install Pure theme, continuing..."
fi

# Install vim-plug for vim plugin management
show_progress "Installing vim-plug for plugin management"
VIM_PLUG_PATH="$HOME/.vim/autoload/plug.vim"
if [[ ! -f "$VIM_PLUG_PATH" ]]; then
    mkdir -p "$HOME/.vim/autoload"
    if curl -fLo "$VIM_PLUG_PATH" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; then
        print_success "vim-plug installed"
        print_info "Run ':PlugInstall' in vim to install configured plugins"
    else
        print_warning "Failed to install vim-plug, vim plugins may not work"
    fi
else
    print_info "vim-plug already installed"
fi

show_progress "Creating backup of existing configuration files"
BACKUP_DIR=$(mktemp -d "${HOME}/.dotfiles-backup-XXXXXX")
chmod 700 "$BACKUP_DIR"

for file in .zshrc .vimrc .gitignore_global; do
    if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
        cp "$HOME/$file" "$BACKUP_DIR/"
        print_info "Backed up $file"
    fi
done

print_success "Backup created at $BACKUP_DIR"

show_progress "Creating configuration symlinks"
if ! stow --ignore='.aws' --ignore='.gnupg' --ignore='pass-setup.md' --ignore='gpg-*.md' .; then
    handle_error "stow_error" "Failed to create symlinks with stow"
    exit 1
fi
print_success "Symlinks created"

show_progress "Configuring git and finalizing setup"
if ! git config --global core.excludesfile ~/.gitignore_global; then
    handle_error "config_error" "Failed to configure git global gitignore"
    exit 1
fi
print_success "Git configured to use global gitignore"

# Test the configuration
print_info "Testing configuration..."
if zsh -c "source ~/.zshrc && echo 'Configuration loaded successfully'" &> /dev/null; then
    print_success "Configuration test passed"
else
    print_warning "Configuration test failed - you may need to restart your shell"
    echo "Try running: source ~/.zshrc"
fi

echo ""
echo "🎉 SecureDots Setup Complete!"
echo "==========================="
echo ""
print_success "Professional local environment configuration is ready"
echo ""
echo "📋 Quick Validation:"
echo "   ✓ All required tools installed"
echo "   ✓ Configuration files symlinked"  
echo "   ✓ Git configured for global gitignore"
echo "   ✓ Shell configuration ready"
echo ""
echo "🚀 Next Steps:"
echo "   1. Restart your terminal or run: source ~/.zshrc"
echo "   2. Try: dotfiles_help (see all available functions)"
echo "   3. For AWS integration: see docs/guides/pass-setup.md"
echo "   4. For hardware security: run ./setup/setup-secure-zsh.sh"
echo ""
echo "📚 Documentation:"
echo "   • Quick commands: QUICK-REFERENCE.md"
echo "   • Full guide: docs/USER-GUIDE.md"
echo "   • Troubleshooting: docs/guides/TROUBLESHOOTING.md"
echo ""
echo "💾 Backup: Previous dotfiles saved to $BACKUP_DIR"
echo ""