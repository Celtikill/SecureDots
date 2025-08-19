#!/usr/bin/env zsh
# Platform detection - simplified and universal

# Detect platform with a single variable
case "$(uname -s)" in
    Darwin*) PLATFORM="macos" ;;
    Linux*)  
        if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
            PLATFORM="wsl"
        else
            PLATFORM="linux"
        fi
        ;;
    *)       PLATFORM="unknown" ;;
esac

# Detect if running in container
[[ -f /.dockerenv || -f /run/.containerenv ]] && PLATFORM="${PLATFORM}-container"

# Export for use in other scripts
export PLATFORM

# ===== Font and Terminal Capability Detection =====

# Simplified font check (removed expensive system_profiler call)
check_powerline_fonts() {
    # Since we're not using powerline themes anymore, always return false
    # This avoids expensive system calls during startup
    false
}

# Simplified terminal capabilities (no powerline needed)
# Export basic capabilities without expensive checks
export TERMINAL_HAS_256_COLOR=true
export TERMINAL_HAS_UNICODE=true
export TERMINAL_HAS_POWERLINE=false

# Font installation helpers
install_powerline_fonts() {
    echo "Installing powerline fonts for $PLATFORM..."
    
    case "$PLATFORM" in
        macos*)
            if command -v brew >/dev/null 2>&1; then
                echo "Installing via Homebrew..."
                brew install font-powerline-symbols font-fira-code-nerd-font font-dejavu-sans-mono-nerd-font
            else
                echo "Homebrew not found. Install manually from:"
                echo "https://github.com/powerline/fonts"
                echo "https://github.com/ryanoasis/nerd-fonts"
            fi
            ;;
        linux*)
            if command -v apt-get >/dev/null 2>&1; then
                echo "Installing via APT..."
                sudo apt-get update
                sudo apt-get install -y fonts-powerline fonts-firacode
            elif command -v dnf >/dev/null 2>&1; then
                echo "Installing via DNF..."
                sudo dnf install -y powerline-fonts fira-code-fonts
            elif command -v pacman >/dev/null 2>&1; then
                echo "Installing via Pacman..."
                sudo pacman -S powerline-fonts ttf-fira-code
            else
                echo "Package manager not found. Install manually from:"
                echo "https://github.com/powerline/fonts"
                echo "https://github.com/ryanoasis/nerd-fonts"
            fi
            ;;
        wsl*)
            echo "WSL detected. Install fonts in Windows:"
            echo "1. Download from https://github.com/ryanoasis/nerd-fonts"
            echo "2. Install FiraCode Nerd Font or DejaVu Sans Mono Nerd Font"
            echo "3. Configure your Windows Terminal to use the font"
            ;;
        *)
            echo "Platform $PLATFORM not supported for automatic font installation"
            echo "Install manually from: https://github.com/powerline/fonts"
            ;;
    esac
}

# Font installation suggestion (disabled for pure theme)
suggest_font_installation() {
    # Pure theme doesn't require special fonts
    return 0
}

# Platform-specific PATH additions (only if directories exist)
case "$PLATFORM" in
    macos*)
        [[ -d "/opt/homebrew/bin" ]] && path=("/opt/homebrew/bin" $path)
        [[ -d "/usr/local/opt/node@22/bin" ]] && path=("/usr/local/opt/node@22/bin" $path)
        ;;
    linux*)
        # Initialize nvm if available
        export NVM_DIR="$HOME/.nvm"
        [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
        ;;
esac

# ===== Conda Path Setup =====
# Export conda paths for use by conda.zsh module
case "$PLATFORM" in
    macos*)
        # Check homebrew installations first
        [[ -x "/opt/homebrew/anaconda3/bin/conda" ]] && CONDA_PREFIX="/opt/homebrew/anaconda3"
        [[ -x "/opt/homebrew/miniconda3/bin/conda" ]] && CONDA_PREFIX="/opt/homebrew/miniconda3"
        
        export CONDA_SEARCH_PATHS=(
            "${CONDA_PREFIX:-}"
            "$HOME/opt/anaconda3"
            "$HOME/opt/miniconda3"
            "$HOME/miniconda3"
            "$HOME/anaconda3"
            "/usr/local/anaconda3"
            "/usr/local/miniconda3"
            "/opt/anaconda3"
            "/opt/miniconda3"
        )
        ;;
    linux*|wsl*)
        export CONDA_SEARCH_PATHS=(
            "$HOME/miniconda3"
            "$HOME/anaconda3"
            "/opt/conda"
            "/opt/miniconda3"
            "/opt/anaconda3"
            "/usr/local/miniconda3"
            "/usr/local/anaconda3"
        )
        ;;
    *container*)
        # In containers, only look for user installations
        export CONDA_SEARCH_PATHS=(
            "$HOME/miniconda3"
            "$HOME/anaconda3"
        )
        ;;
    *)
        # Default/unknown platform
        export CONDA_SEARCH_PATHS=(
            "$HOME/miniconda3"
            "$HOME/anaconda3"
        )
        ;;
esac