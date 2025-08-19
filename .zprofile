#!/usr/bin/env zsh
# ~/.zprofile - Login shell configuration
#
# This file is sourced only for login shells. It ensures that our
# main .zshrc configuration is loaded for all shell types.
#
# Zsh loading order for login shells:
#   1. .zshenv (always)
#   2. .zprofile (login shells only) ← we are here
#   3. .zshrc (interactive shells only, but we're sourcing it manually)
#   4. .zlogin (login shells only)

# Source .zshrc to ensure consistent configuration across all shell types
# This makes login shells behave the same as interactive shells
if [[ -r "${ZDOTDIR:-$HOME}/.zshrc" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshrc"
fi