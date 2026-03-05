# User Guide

Complete setup and usage reference for the dotfiles system.

## Setup Walkthrough

### Basic Setup (setup-simple.sh)

This script installs the shell configuration with software-based GPG encryption.

What it does:
1. Checks prerequisites (git, stow, zsh, gpg, pass)
2. Installs Oh My Zsh and Pure theme
3. Uses GNU Stow to symlink dotfiles to your home directory
4. Sets zsh as your default shell
5. Creates backup of existing configs

```bash
cd ~/dotfiles && ./setup/setup-simple.sh
```

### Advanced Setup (setup-secure-zsh.sh)

Adds hardware security key support and full GPG agent configuration on top of basic setup.

```bash
cd ~/dotfiles && ./setup/setup-secure-zsh.sh
```

Requirements: YubiKey 5 or compatible hardware security key.

### Post-Setup Verification

```bash
source ~/.zshrc
./validate.sh          # Run health checks
dotfiles_help          # Verify functions loaded
```

## Adding Credentials

### Store AWS Credentials in Pass

```bash
# Add access key
pass insert aws/dev/access-key-id

# Add secret key
pass insert aws/dev/secret-access-key

# Test the integration
aws_switch dev
aws sts get-caller-identity
```

### Add Credentials from Environment Variables

```bash
echo "$AWS_ACCESS_KEY_ID" | pass insert -e aws/dev/access-key-id
echo "$AWS_SECRET_ACCESS_KEY" | pass insert -e aws/dev/secret-access-key
```

### Add a New AWS Profile

After storing credentials in pass, add the profile to `~/.aws/config`:

```ini
[profile newprofile]
region = us-east-1
credential_process = /absolute/path/to/.aws/credential-process.sh newprofile
```

Then test: `aws_switch newprofile && aws_check`

## Module Configuration

### How Modules Work

Core modules always load. Optional modules are enabled by setting environment variables in `~/.zshrc.local`.

### Enabling Optional Modules

```bash
# In ~/.zshrc.local:
export ENABLE_CONDA=true      # Conda environment management
export ENABLE_GEMINI_CODE_ASSIST=1  # Gemini AI integration
export ENABLE_GPG=true        # GPG agent management
export ENABLE_GPG_AUTH=true   # GPG-based SSH authentication
```

Reload with `source ~/.zshrc`.

### Module Details

**AWS** (loaded by default)
- `aws_switch <profile>` - Switch AWS profiles
- `aws_check` - Verify credentials
- `aws_current` - Show current profile/account

**Conda** (`ENABLE_CONDA=true`)
- Lazy-loads conda to avoid slowing shell startup
- Activates conda environments on demand

**Gemini** (`ENABLE_GEMINI_CODE_ASSIST=1`)
- `gemini_check` - Verify Gemini credentials
- `gemini_status` - Show credential status (masked)
- `gemini_clear` - Clear Gemini credentials

**GPG** (`ENABLE_GPG=true`)
- Manages GPG agent startup and TTY configuration
- Required for hardware key setups

**GPG Auth** (`ENABLE_GPG_AUTH=true`)
- Enables SSH authentication via GPG keys
- See [GPG SSH Authentication Guide](guides/gpg-ssh-auth.md)

## Common Tasks

### Switch Between AWS Environments

```bash
aws_switch dev
aws s3 ls                   # Use AWS normally
aws_current                 # Verify which account
```

### View and Manage Stored Secrets

```bash
pass ls                     # List all entries
pass show aws/dev/access-key-id   # View a credential
pass -c aws/dev/secret-access-key  # Copy to clipboard
pass edit aws/dev/access-key-id    # Edit an entry
```

### Debug AWS Credential Issues

```bash
export AWS_CREDENTIAL_PROCESS_DEBUG=true
aws sts get-caller-identity
# Check output for error details
```

### Manage GPG Keys

```bash
gpg --list-secret-keys      # List keys
gpg --card-status           # Check hardware token
gpgconf --kill gpg-agent    # Restart GPG agent
```

## Migration from Existing Dotfiles

### 1. Back Up Current Configuration

```bash
cp -r ~/.config/zsh ~/.config/zsh.backup 2>/dev/null
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null
cp -r ~/.aws ~/.aws.backup 2>/dev/null
```

### 2. Run Setup

```bash
cd ~/dotfiles && ./setup/setup-simple.sh
```

The setup script creates backups automatically before making changes.

### 3. Import Existing Credentials

```bash
echo "$EXISTING_ACCESS_KEY" | pass insert -e aws/profile/access-key-id
echo "$EXISTING_SECRET_KEY" | pass insert -e aws/profile/secret-access-key
```

### 4. Add Personal Customizations

Put overrides in `~/.zshrc.local` (not tracked by git):

```bash
alias myproject="cd ~/work/myproject"
export CUSTOM_VAR="value"
```

### 5. Verify and Clean Up

```bash
./validate.sh
aws_switch dev && aws_check
# Once verified, remove plaintext credential files
```

## Customization

### Personal Overrides (~/.zshrc.local)

This file is sourced at the end of `.zshrc` and is not tracked by git. Use it for:
- Custom aliases and functions
- Environment variable overrides
- Module enable/disable flags
- Machine-specific settings

### Custom Aliases

Add to `~/.zshrc.local`:

```bash
alias k=kubectl
alias tf=tofu
alias dc=docker-compose
```

### AWS Profile Configuration

Edit `.config/zsh/aws.zsh` to customize:
- Available profiles
- Default region
- Profile validation rules

## Shell Theme

### Pure Theme (Default)

[Pure](https://github.com/sindresorhus/pure) is installed by default. It provides a clean prompt with git status and command duration. No special fonts required.

### Manual Theme Installation

If Pure theme didn't install correctly:

```bash
./setup/install-pure-theme.sh
source ~/.zshrc
```

### Switching Themes

To use a different Oh My Zsh theme, edit `~/.zshrc`:

```bash
# Comment out Pure theme section and set:
ZSH_THEME="robbyrussell"
```

Popular alternatives: `robbyrussell` (default), `agnoster` (requires powerline fonts).

## Troubleshooting

Quick fixes for common issues:

**Commands not found** (dotfiles_help, aws_check, etc.):
```bash
source ~/.zshrc
```

**GPG operations failing**:
```bash
gpgconf --kill gpg-agent
gpg-connect-agent updatestartuptty /bye
```

**AWS credentials not working**:
```bash
pass ls aws/              # Check credentials exist
aws_check                 # See specific error
```

For detailed troubleshooting, see [TROUBLESHOOTING.md](guides/TROUBLESHOOTING.md).

## Documentation

- **[Quick Reference](../QUICK-REFERENCE.md)** - Daily commands cheat sheet
- **[Troubleshooting](guides/TROUBLESHOOTING.md)** - Detailed problem solving
- **[GPG Management](guides/gpg-mgmnt.md)** - Key lifecycle and hardware tokens
- **[GPG SSH Auth](guides/gpg-ssh-auth.md)** - SSH authentication via GPG
- **[Pass Setup](guides/pass-setup.md)** - Password store configuration
- **[Security Policy](../SECURITY.md)** - Vulnerability reporting
