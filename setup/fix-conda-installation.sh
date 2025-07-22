#!/bin/bash
# fix-conda-installation.sh - Proper conda installation script
# This script removes the current portable conda and installs Miniconda properly

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

print_status "Starting conda installation fix..."

# Step 1: Remove current portable conda
print_status "Removing current portable conda installation..."
if [[ -f /usr/local/bin/conda ]]; then
    sudo rm -f /usr/local/bin/conda
    print_status "Removed /usr/local/bin/conda"
else
    print_warning "No conda found in /usr/local/bin/"
fi

# Step 2: Clean up existing conda init block from .zshrc
print_status "Cleaning up existing conda initialization in .zshrc..."
if grep -q "# >>> conda initialize >>>" ~/.zshrc; then
    # Create backup
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    
    # Remove conda init block
    sed -i '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' ~/.zshrc
    print_status "Removed conda initialization block from .zshrc (backup created)"
else
    print_warning "No conda initialization block found in .zshrc"
fi

# Step 3: Download and install Miniconda
print_status "Downloading Miniconda..."
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
INSTALLER_PATH="/tmp/Miniconda3-latest-Linux-x86_64.sh"

if ! curl -fsSL "$MINICONDA_URL" -o "$INSTALLER_PATH"; then
    print_error "Failed to download Miniconda installer"
    exit 1
fi

# Verify download
if [[ ! -f "$INSTALLER_PATH" ]]; then
    print_error "Miniconda installer not found after download"
    exit 1
fi

print_status "Installing Miniconda to ~/miniconda3..."
if bash "$INSTALLER_PATH" -b -p ~/miniconda3; then
    print_status "Miniconda installed successfully"
else
    print_error "Failed to install Miniconda"
    exit 1
fi

# Clean up installer
rm -f "$INSTALLER_PATH"

# Step 4: Initialize conda for zsh
print_status "Initializing conda for zsh..."
if ~/miniconda3/bin/conda init zsh; then
    print_status "Conda initialized for zsh"
else
    print_error "Failed to initialize conda for zsh"
    exit 1
fi

# Step 5: Update PATH in current session
export PATH="$HOME/miniconda3/bin:$PATH"

# Step 6: Verify installation
print_status "Verifying conda installation..."
if ~/miniconda3/bin/conda --version; then
    print_status "Conda installation verified"
else
    print_error "Conda installation verification failed"
    exit 1
fi

# Step 7: Migrate existing environments
print_status "Checking for existing conda environments..."
if [[ -d ~/.conda/envs ]]; then
    print_status "Found existing environments in ~/.conda/envs"
    print_status "These will be automatically detected by the new conda installation"
    ~/miniconda3/bin/conda env list
else
    print_warning "No existing conda environments found"
fi

print_status "Conda installation fix completed successfully!"
echo
print_warning "IMPORTANT: Please restart your terminal or run 'source ~/.zshrc' to apply changes"
echo
print_status "After restarting, you can test with: conda activate <environment-name>"