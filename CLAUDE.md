# CLAUDE.md

This file provides guidance to Claude Code when working with this dotfiles repository.

## Repository Overview

This is a security-focused personal dotfiles repository that provides:
- Modular zsh configuration with fast startup
- GPG-encrypted credential management via `pass`
- AWS profile management with security validation
- Cross-platform compatibility and easy customization

## Key Commands

### Setup & Management
```bash
# Quick setup (basic shell configuration)
bash setup/setup-simple.sh

# Full security setup (GPG + pass integration)  
bash setup/setup-secure-zsh.sh

# Get help with available functions
dotfiles_help
```

### Daily Usage
```bash
# AWS profile management
aws_switch dev
aws_check
aws_current

# Password management
penv aws/dev        # Load credentials from pass
penv_clear         # Clear loaded credentials

# Configuration help
dotfiles_examples   # See workflow examples
dotfiles_customize  # Customization guide
```

## Architecture

### Modular Design
- **Core modules**: `error-handling`, `platform`, `aliases`, `functions` (always loaded)
- **Optional modules**: `conda`, `gpg`, `gpg-auth` (opt-in via environment variables)  
- **Default module**: `aws` (loaded by default, can be disabled)

### Security Model
- No plaintext credentials stored anywhere
- GPG encryption for all sensitive data via `pass`
- Input validation prevents injection attacks
- Environment restrictions limit accidental production access

## Important Files

- **`.zshrc`**: Main configuration with extensive inline documentation
- **`.config/zsh/`**: Modular configuration files
- **`.stow-local-ignore`**: Prevents sensitive files from being symlinked
- **`setup/`**: Installation scripts for different security levels

## Customization

**For personal use**: Create `~/.zshrc.local` for overrides without modifying the base configuration.

**For forking**: 
1. Update AWS profiles in `.config/zsh/aws.zsh`
2. Modify default region and personal preferences
3. Run `dotfiles_customize` for detailed guidance

## Security Considerations

- GPG keys and pass store are excluded from version control
- AWS credentials use credential process (no plaintext storage)
- Profile switching is restricted to approved environments
- All setup scripts validate prerequisites before making changes

For troubleshooting: `docs/guides/TROUBLESHOOTING.md`