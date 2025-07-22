#!/bin/bash
# install-pure-theme.sh
# Cross-platform installer for Pure zsh theme
# Integrates with Oh My Zsh installation

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

# Detect Oh My Zsh installation
detect_omz() {
    if [[ -n "${ZSH:-}" ]]; then
        echo "$ZSH"
    elif [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "$HOME/.oh-my-zsh"
    else
        return 1
    fi
}

# Main installation
main() {
    echo "=== Pure Theme Installer ==="
    echo
    
    # Check prerequisites
    print_info "Checking prerequisites..."
    
    if ! command -v git &> /dev/null; then
        print_error "git is required but not installed"
        echo "Install with:"
        echo "  macOS: brew install git"
        echo "  Ubuntu/Debian: sudo apt-get install git"
        echo "  Arch Linux: sudo pacman -S git"
        echo "  Red Hat/CentOS: sudo yum install git"
        exit 1
    fi
    
    if ! command -v zsh &> /dev/null; then
        print_error "zsh is required but not installed"
        echo "Install with:"
        echo "  macOS: brew install zsh"
        echo "  Ubuntu/Debian: sudo apt-get install zsh"
        echo "  Arch Linux: sudo pacman -S zsh"
        echo "  Red Hat/CentOS: sudo yum install zsh"
        exit 1
    fi
    
    # Detect Oh My Zsh
    if ! OMZ_DIR=$(detect_omz); then
        print_error "Oh My Zsh not found. Please install Oh My Zsh first."
        echo "Run: ./setup/install-omz.sh"
        exit 1
    fi
    
    print_success "Found Oh My Zsh at: $OMZ_DIR"
    
    # Define Pure theme directory
    PURE_DIR="$OMZ_DIR/custom/themes/pure"
    
    # Check if Pure is already installed
    if [[ -d "$PURE_DIR" ]]; then
        print_warning "Pure theme already exists at $PURE_DIR"
        read -p "Do you want to reinstall/update it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Pure theme installation"
            exit 0
        fi
        
        # Backup existing installation
        BACKUP_DIR=$(mktemp -d "${PURE_DIR}.backup-XXXXXX")
        chmod 700 "$BACKUP_DIR"
        print_info "Backing up existing Pure theme to $BACKUP_DIR"
        mv "$PURE_DIR" "$BACKUP_DIR"
    fi
    
    # Clone Pure theme
    print_info "Installing Pure theme..."
    if git clone https://github.com/sindresorhus/pure.git "$PURE_DIR"; then
        print_success "Pure theme installed successfully"
    else
        print_error "Failed to clone Pure theme repository"
        echo "Please check your internet connection and try again"
        exit 1
    fi
    
    # Check if .zshrc needs updating
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q "prompt pure" "$HOME/.zshrc"; then
            print_success "Pure theme is already configured in .zshrc"
        else
            print_warning "Pure theme is not configured in .zshrc"
            echo "Add the following lines to your .zshrc after Oh My Zsh is sourced:"
            echo
            echo "  # Pure Theme Setup"
            echo "  fpath+=\$ZSH/custom/themes/pure"
            echo "  autoload -U promptinit; promptinit"
            echo "  prompt pure"
            echo
            echo "Also ensure ZSH_THEME is set to empty: ZSH_THEME=\"\""
        fi
    fi
    
    print_success "Pure theme installation complete!"
    print_info "Restart your shell or run 'source ~/.zshrc' to see the changes"
}

# Run main function
main "$@"