#!/usr/bin/env zsh
# Consolidated aliases

# Safety first
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Better ls
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -alFtr'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git essentials (minimal, as oh-my-zsh provides many)
alias gs='git status'
alias gd='git diff'
alias gdc='git diff --cached'

# Docker (conditional)
if command -v docker &>/dev/null; then
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
fi

# Terraform/OpenTofu (conditional)
if command -v terraform &>/dev/null || command -v tofu &>/dev/null; then
    alias tf='terraform'
    alias tfi='terraform init'
    alias tfp='terraform plan'
    alias tfa='terraform apply'
fi

# Claude AI (conditional)
[[ -x "$HOME/.claude/local/claude" ]] && alias claude="$HOME/.claude/local/claude"

# Dotfiles management
alias dotfiles-help='dotfiles_help'
alias dotfiles-config='dotfiles_config'
alias dotfiles-env='dotfiles_env'
alias dotfiles-test='dotfiles_config && echo && dotfiles_functions'

# Conda management (conditional)
if command -v conda &>/dev/null; then
    alias conda-list='conda_list_environments'
    alias conda-envs='conda_list_environments'
    alias conda-refresh='conda_refresh_environments'
    alias cactivate='conda_activate'
fi