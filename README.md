# dotfiles

Modular zsh configuration with GPG-encrypted credential management.

> **Opinionated setup:** This reflects my personal preferences (vim, zsh, conda, Claude AI configs). Customize to match your own workflow.

## What This Does

- **Modular zsh shell** with fast startup via lazy-loaded modules
- **Encrypted AWS credentials** using `pass` + GPG (no plaintext secrets)
- **Cross-platform** support (macOS, Linux, WSL2)
- **GNU Stow** for clean symlink management
- **Optional hardware key** integration (YubiKey)

## Quick Start

Install prerequisites:

```bash
# macOS
brew install git stow zsh gnupg pass

# Ubuntu/Debian
sudo apt-get install git stow zsh gnupg pass

# Arch
sudo pacman -S git stow zsh gnupg pass
```

Clone and run setup:

```bash
git clone https://github.com/Celtikill/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup/setup-simple.sh
source ~/.zshrc && dotfiles_help
```

Verify:

```bash
./validate.sh
```

## How It Works

### Module Architecture

The shell loads modules from `~/.config/zsh/`. Core modules always load; optional modules are controlled by environment variables.

| Module | Type | Purpose |
|--------|------|---------|
| `error-handling.zsh` | Core | Error capture and logging |
| `platform.zsh` | Core | OS detection and paths |
| `aliases.zsh` | Core | Command shortcuts |
| `functions.zsh` | Core | Utility functions (dotfiles_help, etc.) |
| `aws.zsh` | Default | AWS profile management |
| `conda.zsh` | Optional (`ENABLE_CONDA`) | Conda environments |
| `gemini.zsh` | Optional (`ENABLE_GEMINI_CODE_ASSIST`) | Gemini AI integration |
| `gpg.zsh` | Optional (`ENABLE_GPG`) | GPG agent management |
| `gpg-auth.zsh` | Optional (`ENABLE_GPG_AUTH`) | GPG-based SSH authentication |

### Credential Flow

```
AWS CLI → credential-process.sh → pass → GPG decrypt → credentials returned as JSON
```

When you run an AWS command, the CLI calls `credential-process.sh`, which retrieves the encrypted credential from `pass`, GPG decrypts it (prompting for passphrase or hardware key touch), and returns temporary credentials. No plaintext secrets are stored on disk.

### File Layout

```
dotfiles/
├── .zshrc                          # Main shell configuration
├── .config/zsh/                    # Modular shell config
│   ├── aliases.zsh
│   ├── aws.zsh
│   ├── conda.zsh
│   ├── error-handling.zsh
│   ├── functions.zsh
│   ├── gemini.zsh
│   ├── gpg.zsh
│   ├── gpg-auth.zsh
│   └── platform.zsh
├── .aws/
│   ├── config                      # AWS CLI profiles
│   └── credential-process.sh       # Secure credential retrieval
├── .stow-local-ignore              # Prevents credential exposure
├── setup/
│   ├── setup-simple.sh             # Basic setup (15-20 min)
│   ├── setup-secure-zsh.sh         # Full security setup (30-45 min)
│   ├── install-omz.sh              # Oh My Zsh installation
│   └── install-pure-theme.sh       # Pure theme installation
└── docs/
    ├── USER-GUIDE.md               # Complete setup and usage
    ├── guides/
    │   ├── TROUBLESHOOTING.md      # Problem solving
    │   ├── gpg-mgmnt.md            # GPG key lifecycle
    │   ├── gpg-ssh-auth.md         # SSH via GPG
    │   └── pass-setup.md           # Password store setup
    └── ...
```

## Usage

```bash
# Help
dotfiles_help               # All available functions
dotfiles_examples           # Workflow examples

# AWS profile management
aws_switch dev              # Switch to dev profile
aws_check                   # Verify credentials work
aws_current                 # Show current profile/account

# Credential management
penv aws/dev                # Load credentials from pass
penv_clear                  # Clear loaded credentials
```

See [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for the full command list.

## Setup Options

| Script | Time | What It Does |
|--------|------|-------------|
| `setup-simple.sh` | 15-20 min | Shell config, vim, basic GPG/pass integration |
| `setup-secure-zsh.sh` | 30-45 min | Full security with hardware key support, GPG agent config |

## Adding Credentials

```bash
# Store AWS credentials in pass
pass insert aws/dev/access-key-id
pass insert aws/dev/secret-access-key

# Test
aws_switch dev && aws sts get-caller-identity
```

## Customization

Create `~/.zshrc.local` for personal overrides without modifying the base config:

```bash
# Custom aliases
alias myproject="cd ~/work/myproject"

# Enable optional modules
export ENABLE_CONDA=true
export ENABLE_GEMINI_CODE_ASSIST=1

# Custom environment variables
export EDITOR=nvim
```

To customize AWS profiles, edit `.config/securedots/aws-profiles.conf`.

## Documentation

- **[User Guide](docs/USER-GUIDE.md)** - Complete setup and usage reference
- **[Quick Reference](QUICK-REFERENCE.md)** - Essential commands for daily use
- **[Troubleshooting](docs/guides/TROUBLESHOOTING.md)** - Solutions for common issues
- **[GPG Management](docs/guides/gpg-mgmnt.md)** - Key lifecycle and hardware tokens
- **[Pass Setup](docs/guides/pass-setup.md)** - Password store configuration
- **[Security Policy](SECURITY.md)** - Vulnerability reporting and security model

## License

MIT. See [SECURITY.md](SECURITY.md) for warranty disclaimer.
