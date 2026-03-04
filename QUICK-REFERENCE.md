# Quick Reference

Essential commands for daily use.

## Setup Commands

**Basic Setup (15-20 minutes):**
```bash
./setup/setup-simple.sh
```

**Advanced Setup (30-45 minutes):**
```bash
./setup/setup-secure-zsh.sh
```

**Verify Setup:**
```bash
./validate.sh
```

## Daily Commands

### Help and Status
```bash
dotfiles_help              # Show all available functions
dotfiles_examples          # See real workflow examples
dotfiles_customize         # Customization guide
dotfiles_config            # Show current configuration
dotfiles_status            # Check what's working
dotfiles_security          # Explain security model
```

### AWS Profile Management

```bash
aws_switch dev             # Switch to development profile
aws_switch staging         # Switch to staging profile
aws_check                  # Verify current credentials work
aws_current                # Show current profile and account
```

### Credential Management
```bash
penv aws/dev               # Load credentials from pass store
penv_clear                 # Clear loaded credentials
pass show aws/dev/access-key-id   # View stored credential
```

### Gemini AI (Optional)

Requires `ENABLE_GEMINI=true` in `~/.zshrc.local`.

```bash
gemini_check               # Verify credentials are set
gemini_status              # Show current values (masked)
gemini_clear               # Clear credentials from environment
```

## Common Workflows

**Switch AWS Environment:**
```bash
aws_switch dev
aws_check
aws s3 ls                  # Test with actual AWS command
```

**Load Temporary Credentials:**
```bash
penv aws/dev               # Load from encrypted storage
aws sts get-caller-identity # Verify loaded credentials
penv_clear                 # Clean up when done
```

**Check System Status:**
```bash
dotfiles_config            # See what's configured
aws_current                # Check current AWS profile
gpg --card-status          # Check hardware key (if using)
```

## Troubleshooting Quick Fixes

### Shell/Configuration Problems

**Commands not found** (dotfiles_help, etc.):
```bash
source ~/.zshrc
```

If that doesn't work:
```bash
source ~/.config/zsh/functions.zsh
dotfiles_help
```

### AWS Credential Problems

```bash
aws_check                  # See specific error details
aws_switch dev             # Re-select profile
pass ls                    # Check credentials exist
```

If credentials are missing: `pass insert aws/profile/access-key-id`

### GPG/Security Problems

```bash
gpg-connect-agent reloadagent /bye   # Restart GPG agent
echo "test" | gpg --clearsign        # Test GPG functionality
gpg --card-status                    # Check hardware key
```

## File Locations

```bash
~/.zshrc                   # Main shell configuration
~/.config/zsh/             # Modular configuration files
~/.password-store/         # Encrypted credential storage (pass)
~/dotfiles/                # This repository
```

## Documentation

- [User Guide](docs/USER-GUIDE.md) - Complete setup and usage
- [Troubleshooting](docs/guides/TROUBLESHOOTING.md) - Detailed problem solving
- [Security Policy](SECURITY.md) - Vulnerability reporting

**Security issues:** celtikill@celtikill.io (private disclosure)
