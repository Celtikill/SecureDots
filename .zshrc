#!/usr/bin/env zsh
# ~/.zshrc - Streamlined Zsh configuration
#
# This configuration prioritizes fast startup and security-first practices.
# It uses a modular approach - each feature is in its own file for easy customization.
# 
# CUSTOMIZE: Fork this repository and modify paths/preferences as needed
# For help: run 'dotfiles_help' after setup

# ===== Core Setup =====
# Remove PATH duplicates (typeset -gU) and add common development paths
# This ensures clean PATH without redundant entries for better performance
typeset -gU PATH path
# CUSTOMIZE: Add your preferred directories to this path array
path=("$HOME/bin" "$HOME/.local/bin" "/usr/local/bin" $path)

# ===== Oh My Zsh =====
export ZSH="$HOME/.oh-my-zsh"
# Disable oh-my-zsh theme for pure
ZSH_THEME=""

# ===== Pure Theme Setup =====
# Pure theme: Minimal, fast, and works without special fonts
# Alternative: Remove this section and set ZSH_THEME="robbyrussell" above for default
if [[ -d "$ZSH/custom/themes/pure" ]]; then
    fpath+="$ZSH/custom/themes/pure"
    autoload -U promptinit; promptinit
    # Load pure theme with error suppression for hook warnings (known issue)
    prompt pure 2>/dev/null
else
    # Fallback to oh-my-zsh default theme if Pure isn't available
    ZSH_THEME="robbyrussell"
fi

# Load essential plugins only (minimal for fast startup)
# CUSTOMIZE: Add plugins like (git docker aws kubectl) but watch startup time
# Popular additions: zsh-syntax-highlighting zsh-autosuggestions
plugins=(git)

# Source Oh My Zsh
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# ===== Zsh Options =====
# History
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt SHARE_HISTORY EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST

# Navigation
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS

# Completion
setopt COMPLETE_IN_WORD ALWAYS_TO_END

# Misc
setopt NO_BEEP INTERACTIVE_COMMENTS

# ===== Load Modules =====
# Modular configuration: each feature in its own file for easy customization
ZSH_CONFIG_DIR="${HOME}/.config/zsh"

# Load core modules first (order matters for dependencies)
# error-handling: Better error messages and debugging
# platform: OS-specific settings and optimizations  
# aliases: Command shortcuts and safe defaults
# functions: Utility functions and workflow helpers
for module in error-handling platform aliases functions; do
    [[ -f "${ZSH_CONFIG_DIR}/${module}.zsh" ]] && source "${ZSH_CONFIG_DIR}/${module}.zsh"
done

# Load optional modules conditionally (only when needed for performance)
# These modules have startup cost, so they're opt-in via environment variables

# Conda: Python environment management (slow startup)
# Enable with: export ENABLE_CONDA=1 in ~/.zshrc.local
[[ -n "$ENABLE_CONDA" ]] && [[ -f "${ZSH_CONFIG_DIR}/conda.zsh" ]] && source "${ZSH_CONFIG_DIR}/conda.zsh"

# GPG: Hardware security key integration (requires hardware)
# Enable with: export ENABLE_GPG=1 in ~/.zshrc.local  
[[ -n "$ENABLE_GPG" ]] && [[ -f "${ZSH_CONFIG_DIR}/gpg.zsh" ]] && source "${ZSH_CONFIG_DIR}/gpg.zsh"

# GPG SSH Authentication: Use GPG key for SSH (advanced setup)
# Enable with: export ENABLE_GPG_AUTH=1 in ~/.zshrc.local
[[ -n "$ENABLE_GPG_AUTH" ]] && [[ -f "${ZSH_CONFIG_DIR}/gpg-auth.zsh" ]] && source "${ZSH_CONFIG_DIR}/gpg-auth.zsh"

# AWS integration: Profile switching and credential management
# Loaded by default because it's lightweight and commonly used
# Disable with: export DISABLE_AWS_INTEGRATION=true in ~/.zshrc.local
if [[ "${DISABLE_AWS_INTEGRATION:-false}" != "true" ]] && [[ -f "${ZSH_CONFIG_DIR}/aws.zsh" ]]; then
    source "${ZSH_CONFIG_DIR}/aws.zsh"
fi

# ===== Completions =====
autoload -U +X bashcompinit && bashcompinit

# AWS completion
if [[ -f /usr/local/share/zsh/site-functions/_aws || -f /usr/share/zsh/site-functions/_aws ]]; then
    # Native zsh completion available
    :
elif command -v aws_completer &>/dev/null; then
    complete -C aws_completer aws
fi

# ===== Local Overrides =====
# CUSTOMIZE: Create ~/.zshrc.local for your personal settings
# Example ~/.zshrc.local contents:
#   export ENABLE_CONDA=1
#   export ZSH_VERBOSE=true
#   alias myproject='cd ~/dev/myproject'
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ===== Startup Messages (configurable) =====
# Show environment info on startup - useful for debugging
# Enable with: export ZSH_VERBOSE=true in ~/.zshrc.local
if [[ -o interactive && "${ZSH_VERBOSE:-false}" == "true" ]]; then
    echo "Platform: ${PLATFORM:-unknown}"
    echo "AWS Profile: ${AWS_PROFILE:-none}"
    echo "Theme: ${ZSH_THEME} (Powerline: ${TERMINAL_HAS_POWERLINE:-false})"
    [[ -n "${available_commands[gpg]}" ]] && gpg --card-status &>/dev/null && echo "✅ GPG hardware key detected"
    if command -v conda &>/dev/null; then
        echo "✅ Conda: $(conda --version 2>/dev/null | cut -d' ' -f2) (${CONDA_DEFAULT_ENV:-no active env})"
    else
        echo "❌ Conda: not available"
    fi
    # Pure theme doesn't require special fonts
fi

