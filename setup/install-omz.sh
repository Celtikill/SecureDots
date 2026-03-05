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

# Pin to specific commit for supply chain security (see ADR-001)
omz_commit="b52dd1a425e9ed9f844ba46cd27ff94a3b4949dc"
omz_sha256="ce0b7c94aa04d8c7a8137e45fe5c4744e3947871f785fd58117c480c1bf49352"
omz_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/${omz_commit}/tools/install.sh"
omz_tmp="$(mktemp)"

if curl -fsSL "$omz_url" -o "$omz_tmp"; then
    # Cross-platform SHA-256 verification
    actual_sha256=""
    if command -v sha256sum &>/dev/null; then
        actual_sha256="$(sha256sum "$omz_tmp" | awk '{print $1}')"
    elif command -v shasum &>/dev/null; then
        actual_sha256="$(shasum -a 256 "$omz_tmp" | awk '{print $1}')"
    else
        print_warning "No SHA-256 tool available, skipping checksum verification"
    fi

    if [[ -n "$actual_sha256" && "$actual_sha256" != "$omz_sha256" ]]; then
        print_error "Oh My Zsh installer checksum mismatch!"
        print_error "Expected: $omz_sha256"
        print_error "Actual:   $actual_sha256"
        rm -f "$omz_tmp"
        exit 1
    fi

    if ! RUNZSH=no CHSH=no sh "$omz_tmp"; then
        print_error "Failed to install Oh My Zsh"
        echo "Recovery suggestions:"
        echo "  1. Check your internet connection"
        echo "  2. Try running the installer manually"
        echo "  3. Check if GitHub is accessible"
        echo "  4. Verify you have write permissions to your home directory"
        rm -f "$omz_tmp"
        exit 1
    fi
    rm -f "$omz_tmp"
else
    rm -f "$omz_tmp"
    print_error "Failed to download Oh My Zsh installer"
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


