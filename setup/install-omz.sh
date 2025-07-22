#!/bin/bash
# Oh My Zsh installation script with error handling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if Oh My Zsh is already installed
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_warning "Oh My Zsh is already installed"
    echo "Location: $HOME/.oh-my-zsh"
    echo "To reinstall, remove the directory first: rm -rf ~/.oh-my-zsh"
    exit 0
fi

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed"
    echo "Install with:"
    echo "  macOS: brew install curl"
    echo "  Ubuntu/Debian: sudo apt-get install curl"
    echo "  Arch Linux: sudo pacman -S curl"
    exit 1
fi

if ! command -v git &> /dev/null; then
    print_error "git is required but not installed"
    echo "Install with:"
    echo "  macOS: brew install git"
    echo "  Ubuntu/Debian: sudo apt-get install git"
    echo "  Arch Linux: sudo pacman -S git"
    exit 1
fi

print_success "Prerequisites check passed"

# Download and install Oh My Zsh
print_info "Downloading and installing Oh My Zsh..."

# Use the official installer with unattended mode
if ! RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    print_error "Failed to install Oh My Zsh"
    echo "Recovery suggestions:"
    echo "  1. Check your internet connection"
    echo "  2. Try running the installer manually"
    echo "  3. Check if GitHub is accessible"
    echo "  4. Verify you have write permissions to your home directory"
    exit 1
fi

# Verify installation
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_success "Oh My Zsh installed successfully"
    echo "Installation location: $HOME/.oh-my-zsh"
    echo "Configuration file: $HOME/.zshrc"
else
    print_error "Oh My Zsh installation appears to have failed"
    echo "The .oh-my-zsh directory was not created"
    exit 1
fi

print_info "Next steps:"
echo "1. Continue with dotfiles setup: stow ."
echo "2. Or run the setup script: ./setup/setup-secure-zsh.sh"
echo "3. Restart your terminal to use the new configuration"


