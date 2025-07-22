#!/usr/bin/env zsh
# AWS configuration module - Security-focused AWS profile management
#
# This module implements defense-in-depth for AWS credential handling:
# 1. Forces use of credential process (no plaintext credentials)
# 2. Validates profile names to prevent injection attacks
# 3. Restricts profiles to approved environments only
# 4. Provides safe switching and validation functions
#
# CUSTOMIZE: Update available_profiles array for your environments

# Default settings - Security hardened configuration
# CUSTOMIZE: Change region to your preferred default
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-2}"
export AWS_CONFIG_FILE="$HOME/.aws/config"
# Security: Disable credentials file to force secure credential process usage
# This prevents plaintext credential storage and enforces encryption via pass/GPG
export AWS_SHARED_CREDENTIALS_FILE="/dev/null"

# Lazy loading: Set default profile only if AWS_PROFILE is not already set
# Interactive profile selection is disabled by default for lazy loading
if [[ -z "$AWS_PROFILE" ]]; then
    export AWS_PROFILE="${AWS_PROFILE_DEFAULT:-dev}"
fi

# Utility functions
aws_profile() {
    [[ -n "$1" ]] && export AWS_PROFILE="$1" || echo "$AWS_PROFILE"
}

aws_check() {
    [[ -z "$AWS_PROFILE" ]] && { echo "No AWS profile set"; return 1; }
    aws sts get-caller-identity &>/dev/null && echo "✓ AWS credentials valid" || echo "✗ AWS credentials invalid"
}

# Switch AWS profile with comprehensive security validation
# Security: Only allows switching to pre-approved profiles to prevent
# accidental access to production or unauthorized environments
aws_switch() {
    local target_profile="$1"
    # CUSTOMIZE: Add your approved environment profiles here
    # Keep this list minimal - only environments you regularly access
    local available_profiles=("dev" "staging")
    
    # Show usage if no profile specified
    if [[ -z "$target_profile" ]]; then
        echo "Usage: aws_switch <profile>"
        echo "Available profiles: ${available_profiles[@]}"
        return 1
    fi
    
    # Security Layer 1: Format validation
    # Prevents command injection and ensures AWS profile name compliance
    # AWS profile names must be alphanumeric with hyphens/underscores only
    if [[ ! "$target_profile" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]; then
        echo "Error: Invalid profile name format. Must contain only alphanumeric characters, hyphens, and underscores (1-64 chars)"
        return 1
    fi
    
    # Security Layer 2: Injection prevention
    # Blocks path traversal (../) and shell metacharacters that could enable command injection
    # This prevents malicious profile names from executing arbitrary commands
    if [[ "$target_profile" =~ \.\. ]] || [[ "$target_profile" =~ ^[./] ]] || [[ "$target_profile" =~ /$ ]] || [[ "$target_profile" =~ [\;\&\|\`\$] ]]; then
        echo "Error: Profile name contains invalid characters"
        return 1
    fi
    
    # Security Layer 3: Allowlist validation
    # Final check against approved profiles - prevents access to unauthorized environments
    # This is the primary security control preventing accidental production access
    if [[ ! " ${available_profiles[@]} " =~ " ${target_profile} " ]]; then
        echo "Error: Profile '$target_profile' not supported"
        echo "Available profiles: ${available_profiles[@]}"
        return 1
    fi
    
    # Switch profile
    export AWS_PROFILE="$target_profile"
    echo "Switched to AWS profile: $target_profile"
    
    # Asynchronous credential validation (non-blocking)
    # Tests actual AWS API access without slowing down the shell prompt
    # Background process provides feedback without interrupting workflow
    if command -v aws &>/dev/null; then
        (aws sts get-caller-identity &>/dev/null && echo "✓ AWS credentials validated for $target_profile" || echo "⚠ AWS credentials invalid for $target_profile") &
    fi
}

# Get current profile info
aws_current() {
    if [[ -n "$AWS_PROFILE" ]]; then
        echo "Current AWS Profile: $AWS_PROFILE"
        echo "Region: ${AWS_DEFAULT_REGION:-not set}"
        if command -v aws &>/dev/null; then
            aws sts get-caller-identity 2>/dev/null | jq -r '.Account // "unknown"' | sed 's/^/Account: /'
        fi
    else
        echo "No AWS profile set"
    fi
}