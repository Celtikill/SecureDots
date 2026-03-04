# SecureDots User Guide

<!-- Comprehensive table of contents for user guide -->
<details>
<summary>Table of Contents</summary>

- [Before You Begin](#before-you-begin)
  - [Readiness Checklist](#readiness-checklist)
  - [Your Security Responsibilities](#your-security-responsibilities)
- [Quick Start Guide](#quick-start-guide)
  - [New Users](#new-users)
  - [Existing Dotfiles Users](#existing-dotfiles-users)
  - [Security Teams Evaluating](#security-teams-evaluating)
- [Setup Instructions](#setup-instructions)
  - [Basic Security Setup](#basic-security-setup)
  - [Advanced Security Setup](#advanced-security-setup)
  - [Installation Commands](#installation-commands)
- [Daily Usage](#daily-usage)
  - [Essential Commands](#essential-commands)
  - [Daily Workflow Examples](#daily-workflow-examples)
- [Common Tasks](#common-tasks)
  - [Managing AWS Credentials](#managing-aws-credentials)
  - [Working with GPG and Pass](#working-with-gpg-and-pass)
  - [Shell Theme Configuration](#shell-theme-configuration)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)
- [Support Resources](#support-resources)

</details>

*Complete setup and usage reference for professional local environment configuration*

> **What are "dotfiles"?** Dotfiles are configuration files for Unix-like systems that typically start with a dot (like `.zshrc`, `.vimrc`). They customize your shell, editor, and other tools. SecureDots provides a secure, professional-grade dotfiles system with encrypted credential management.

## Before You Begin

### Readiness Checklist

Before starting setup, ensure you have:

**✅ Technical Prerequisites**
- [ ] Command line familiarity (basic `cd`, `ls`, `git` knowledge)
- [ ] Administrator access to install packages
- [ ] 30+ minutes of uninterrupted time
- [ ] Existing dotfiles backed up (if any)

**✅ Security Prerequisites**  
- [ ] Understanding that **you** are responsible for credential security
- [ ] Acceptance that this system requires ongoing maintenance
- [ ] Commitment to following security best practices
- [ ] Plan for GPG key backup and recovery

**✅ Tool Dependencies**

| Tool | Purpose | Check Command | Install Guide |
|------|---------|---------------|---------------|
| `git` | Repository management | `git --version` | [Install Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) |
| `stow` | Dotfiles symlink management | `stow --version` | Package manager: `brew install stow` / `apt install stow` |
| `zsh` | Shell environment | `zsh --version` | Usually pre-installed; package manager if needed |
| `gpg` | Encryption backend | `gpg --version` | Package manager: `brew install gnupg` / `apt install gnupg` |
| `pass` | Password store | `pass version` | Package manager: `brew install pass` / `apt install pass` |

### Your Security Responsibilities

**SecureDots provides enterprise-grade local configuration.** You are responsible for:

**Key Management**
- Creating secure GPG key passphrases
- Backing up GPG keys to offline storage
- Protecting hardware security keys (if used)
- Understanding recovery procedures

**Operational Security**  
- Rotating credentials regularly (quarterly recommended)
- Monitoring for unauthorized access
- Keeping dependencies updated
- Following incident response procedures

**Ongoing Education**
- Reading security updates and advisories
- Understanding what the scripts do before running them
- Staying current with security best practices
- Testing backup and recovery procedures

**⚠️ Critical Understanding:** No security system is perfect. This tool helps manage credentials securely, but **you** remain the primary defense against security breaches.

---

## Quick Start

**Choose your setup path:**

### New Users
```bash
git clone https://github.com/yourusername/securedots.git ~/dotfiles
cd ~/dotfiles && ./setup/setup-simple.sh
source ~/.zshrc && dotfiles_help
```

### Existing Dotfiles Users
**Migration guide:** [Moving from existing configurations](#migration-from-existing-dotfiles)

### Security Teams Evaluating
**Technical details:** [ARCHITECTURE.md](ARCHITECTURE.md) and [SECURITY.md](../SECURITY.md)

---

## What You Get

✅ **Zero plaintext credentials** in your system  
✅ **Hardware security key** integration (optional but recommended)  
✅ **Multi-environment AWS** credential management  
✅ **GPG-encrypted** password storage with `pass`  
✅ **Shell optimizations** for security and productivity

### Feature Dependencies Matrix

| Feature | Required Tools | Optional Tools | Skill Level |
|---------|----------------|----------------|-------------|
| **Basic Setup** | git, stow, zsh | - | Beginner |
| **GPG Encryption** | gpg, pass | Hardware key | Intermediate |
| **AWS Integration** | aws-cli | Multiple profiles | Intermediate |
| **SSH via GPG** | gpg-agent | SSH config knowledge | Advanced |
| **Enterprise Features** | All above | Compliance tools | Expert |  

## Setup Instructions

### Basic Security Setup (15 minutes)
- Software-only GPG encryption
- Standard shell improvements
- AWS credential process (no hardware keys)

### Advanced Security Setup (45 minutes)
- Hardware security key required
- Air-gapped key generation (advanced users)
- FIPS-140 compliant storage

**Details:** [Setup Options](#setup-levels)

### Installation Commands

```bash
# Clone the repository
git clone https://github.com/yourusername/securedots.git ~/dotfiles
cd ~/dotfiles

# For basic security
./setup/setup-simple.sh

# For advanced security with hardware keys
./setup/setup-secure-zsh.sh
```

### Verification

```bash
# Source your new configuration
source ~/.zshrc

# Test AWS credentials (requires AWS account)
aws_check

# View available functions
dotfiles_help
```

**Done!** You now have encrypted credential management.

## Setup Levels

Choose the security level that matches your needs:

### Basic Security Setup

**Good for:**
- Individual developers
- Getting started quickly  
- Software-only security requirements

**What you get:**
- GPG software-based encryption
- AWS credential process
- Shell optimizations
- Basic security protections

**Time commitment:** 15 minutes

```bash
cd ~/dotfiles
./setup/setup-simple.sh
```

### Advanced Security Setup

**Good for:**
- Team environments
- Compliance requirements
- High-value data protection

**What you get:**
- Hardware security key integration
- FIPS-140 compliant storage
- Air-gapped key generation support
- Advanced authentication features

**Time commitment:** 45 minutes + hardware setup

```bash
cd ~/dotfiles
./setup/setup-secure-zsh.sh
```

**Requirements:**
- YubiKey 5 or compatible hardware security key
- USB drive for secure storage (FIPS-140 recommended)

### Enterprise Security (Advanced Users)

**Good for:** Security teams, regulated industries, air-gapped environments

**Features:** Air-gapped master key generation, multiple backup strategies, advanced audit trails, enterprise key management

**Time:** 2-3 hours

**See:** [GPG Management Playbook](guides/gpg-mgmnt.md)

## Daily Usage

### Essential Commands
```bash
# Get help and see all available functions
dotfiles_help

# AWS profile management
aws_switch dev          # Switch to development profile
aws_check              # Verify current credentials work
aws_current            # Show current profile and account info

# Credential management
penv aws/dev           # Load credentials from encrypted storage
penv_clear            # Clear loaded credentials from environment

# See real workflow examples
dotfiles_examples
```

### Your Daily Workflow

**Morning startup:**
1. Open terminal → Shell automatically configures everything
2. Mount GPG vault (if using hardware keys)

**Working with AWS:**
```bash
aws_switch dev          # Switch to development
aws s3 ls              # Use AWS CLI normally
aws_current            # Check which account you're in
```

**Adding new credentials:**
```bash
pass insert aws/new-profile/access-key-id
pass insert aws/new-profile/secret-access-key
AWS_PROFILE=new-profile aws sts get-caller-identity  # Test immediately
```

## Common Tasks

### Managing AWS Credentials

<details>
<summary>Add credentials for a new AWS account</summary>

```bash
# Interactive method
pass insert aws/new-account/access-key-id
pass insert aws/new-account/secret-access-key

# From environment variables
echo "$AWS_ACCESS_KEY_ID" | pass insert -e aws/new-account/access-key-id
echo "$AWS_SECRET_ACCESS_KEY" | pass insert -e aws/new-account/secret-access-key

# Test the new profile
AWS_PROFILE=new-account aws sts get-caller-identity
```
</details>

<details>
<summary>Switch between AWS environments</summary>

```bash
# Switch to development
aws_switch dev

# Switch to staging  
aws_switch staging

# Check current profile
aws_current

# List available profiles
aws configure list-profiles
```
</details>

<details>
<summary>Debug AWS credential issues</summary>

```bash
# Enable debug mode
export AWS_CREDENTIAL_PROCESS_DEBUG=true

# Test credential retrieval
~/.aws/credential-process.sh dev

# Check AWS CLI configuration
aws configure list --profile dev

# Verify pass storage
pass show aws/dev/access-key-id
```
</details>

### Working with GPG and Pass

<details>
<summary>View and manage stored secrets</summary>

```bash
# List all stored passwords
pass ls

# View a specific credential (prompts for GPG passphrase)
pass show aws/dev/access-key-id

# Copy to clipboard (auto-clears after timeout)
pass -c aws/dev/secret-access-key

# Edit an existing entry
pass edit aws/dev/access-key-id
```
</details>

<details>
<summary>Manage GPG keys and hardware tokens</summary>

```bash
# Check GPG key status
gpg --list-secret-keys

# Check hardware token (if using one)
gpg --card-status

# Test GPG functionality
echo "test" | gpg --clearsign

# Restart GPG agent if needed
gpgconf --kill gpg-agent
gpg-connect-agent updatestartuptty /bye
```
</details>

### SSH Authentication (Advanced)

<details>
<summary>Set up SSH with GPG keys</summary>

**Prerequisites:** Advanced security setup with authentication subkey

```bash
# Extract SSH public key
ssh-add -L > ~/.ssh/id_gpg.pub

# Deploy to servers
ssh-copy-id -i ~/.ssh/id_gpg.pub user@server.com

# Test connection (will prompt for PIN/touch)
ssh user@server.com
```

**See:** [GPG SSH Authentication Guide](guides/gpg-ssh-auth.md) for complete setup
</details>

## Troubleshooting

### Quick Fixes

**Problem: "GPG command failed"**
```bash
# Restart GPG agent
gpgconf --kill gpg-agent
gpg-connect-agent updatestartuptty /bye

# Test GPG
echo "test" | gpg --clearsign
```

**Problem: "AWS credentials not found"**
```bash
# Check pass storage
pass ls aws/

# Verify credential process script
ls -la ~/.aws/credential-process.sh
chmod +x ~/.aws/credential-process.sh

# Test with debug mode
AWS_CREDENTIAL_PROCESS_DEBUG=true aws sts get-caller-identity
```

**Problem: "Functions not available (aws_check, etc.)"**
```bash
# Reload shell configuration
source ~/.zshrc

# Check if functions are defined
type aws_check
type dotfiles_help
```

## Shell Theme Configuration

### Understanding Pure Theme

SecureDots uses the [Pure theme](https://github.com/sindresorhus/pure) by default for the zsh prompt. Pure is chosen for its:

- **Minimalist design** - Clean, distraction-free prompt
- **Performance** - Fast loading, no special fonts required
- **Reliability** - Works across all terminals and platforms
- **Useful information** - Shows git status, command duration, etc.

### Automated Installation

Pure theme is automatically installed during setup:

```bash
# Simple setup includes Pure theme
./setup/setup-simple.sh

# Manual Pure theme installation (if needed)
./setup/install-pure-theme.sh
```

### Manual Configuration

If you need to manually configure Pure theme or the automated installation fails:

<details>
<summary>Manual Pure Theme Setup</summary>

**Prerequisites:**
- Oh My Zsh must be installed first
- Internet connection for downloading theme

**Steps:**

1. **Install Pure theme to Oh My Zsh:**
   ```bash
   git clone https://github.com/sindresorhus/pure.git ~/.oh-my-zsh/custom/themes/pure
   ```

2. **Verify installation:**
   ```bash
   ls ~/.oh-my-zsh/custom/themes/pure/
   # Should show: pure.zsh, async.zsh, README.md, etc.
   ```

3. **Reload shell configuration:**
   ```bash
   source ~/.zshrc
   ```

**Troubleshooting:**
- If you see "Usage: prompt (options)" error, the Pure theme directory doesn't exist
- Run the manual installation steps above, then restart your terminal
- Check [Troubleshooting Guide](guides/TROUBLESHOOTING.md#theme-and-display-issues) for additional theme issues

</details>

### Alternative Themes

If Pure theme doesn't meet your needs, you can switch to Oh My Zsh's built-in themes:

<details>
<summary>Switching to Alternative Themes</summary>

**Quick switch to robbyrussell (Oh My Zsh default):**

1. Edit `~/.zshrc` and modify the theme configuration:
   ```bash
   # Comment out Pure theme section and set:
   ZSH_THEME="robbyrussell"
   ```

2. Reload: `source ~/.zshrc`

**Popular alternatives:**
- `robbyrussell` - Simple, reliable default
- `agnoster` - Powerline style (requires special fonts)
- `spaceship` - Feature-rich (requires additional setup)

**Note:** Some themes require powerline fonts or additional configuration. Pure theme is recommended for its simplicity and reliability.

</details>

### Get Help

1. **Check the troubleshooting guide:** [TROUBLESHOOTING.md](guides/TROUBLESHOOTING.md)
2. **Use built-in help:** `dotfiles_help`
3. **Run diagnostics:** Built into setup scripts
4. **Collect debug info:** Use debug modes for detailed output

## System Overview

### Security Architecture

Your setup has **three main layers of security**:

1. **Encryption Layer**: GPG encrypts all sensitive data
2. **Authentication Layer**: Hardware keys (optional) provide tamper-proof storage
3. **Prevention Layer**: Configuration prevents accidental credential exposure

**Key principle:** Never store plaintext secrets anywhere
- All credentials encrypted at rest
- Dynamic credential retrieval only when needed
- Comprehensive ignore patterns prevent accidents
- Hardware keys provide tamper-resistant storage

### Key Files and Purpose

| File | Purpose | When You'll Use It |
|------|---------|-------------------|
| `.zshrc` | Main shell configuration | Automatically on every terminal |
| `.aws/credential-process.sh` | Retrieves AWS credentials securely | When using AWS CLI |
| `.stow-local-ignore` | Prevents credential exposure | Automatically during setup |
| `pass` password store | Encrypted credential storage | When adding/accessing secrets |

**Complete technical details:** [ARCHITECTURE.md](ARCHITECTURE.md)

## File Organization

### Directory Structure

```
dotfiles/
├── 📁 Shell Configuration
│   ├── .zshrc                 # Main shell configuration
│   └── .config/zsh/           # Modular configuration
│       ├── aws.zsh           # AWS profile management
│       ├── functions.zsh     # Utility functions
│       └── platform.zsh      # OS-specific settings
│
├── 🔐 Security Configuration  
│   ├── .aws/
│   │   ├── config            # AWS CLI configuration
│   │   └── credential-process.sh  # Secure credential retrieval
│   ├── .stow-local-ignore    # Prevents credential exposure
│   └── .gitignore            # Global git ignore patterns
│
├── 📚 Documentation
│   ├── README.md             # Quick start guide
│   ├── USER-GUIDE.md         # This comprehensive guide
│   └── guides/               # Specialized guides
│       ├── TROUBLESHOOTING.md    # Problem solving
│       ├── gpg-mgmnt.md         # Advanced GPG management
│       ├── gpg-ssh-auth.md      # SSH authentication setup
│       └── pass-setup.md        # Password manager setup
│
└── 🛠️ Setup Scripts
    └── setup/
        ├── setup-simple.sh       # Basic security setup
        ├── setup-secure-zsh.sh   # Advanced security setup
        ├── install-omz.sh        # Oh My Zsh installation
        └── install-pure-theme.sh # Pure theme installation
```

## Migration from Existing Dotfiles

**Coming from other dotfiles?** Here's how to migrate safely:

### Backup First
```bash
# Create backup of existing configuration
cp -r ~/.config/zsh ~/.config/zsh.backup
cp ~/.zshrc ~/.zshrc.backup
cp -r ~/.aws ~/.aws.backup
```

### Migration Strategy
1. **Start with basic setup** to understand the system
2. **Import credentials** gradually using `pass insert`
3. **Customize** using `~/.zshrc.local` for personal settings
4. **Remove plaintext** credentials after verification

### Common Migration Tasks
```bash
# Import existing AWS credentials
echo "$EXISTING_ACCESS_KEY" | pass insert -e aws/profile/access-key-id
echo "$EXISTING_SECRET_KEY" | pass insert -e aws/profile/secret-access-key

# Add personal aliases to ~/.zshrc.local
echo 'alias myproject="cd ~/work/myproject"' >> ~/.zshrc.local

# Import environment variables
echo 'export CUSTOM_VAR="value"' >> ~/.zshrc.local
```

## Learning Path

### For New Users

1. **Start with Basic Setup** (🔰 Level 1)
   - Understand GPG basics
   - Learn pass password manager
   - Get comfortable with credential process

2. **Add Hardware Security** (🔒 Level 2)
   - Understand hardware key benefits
   - Set up YubiKey or similar
   - Learn touch/PIN policies

3. **Explore Advanced Features**
   - SSH authentication with GPG
   - Multi-environment workflows
   - Backup and recovery procedures

### For Security Teams

1. **Review Architecture** 
   - Understand security model
   - Review compliance aspects
   - Plan deployment strategy

2. **Pilot Implementation**
   - Test with small group
   - Refine documentation
   - Create team-specific procedures

3. **Full Deployment**
   - Roll out to entire team
   - Implement governance framework
   - Set up monitoring and auditing

## Quick Reference

### Essential Commands
```bash
# Get help
dotfiles_help
dotfiles_config
dotfiles_functions
dotfiles_status            # Check what's working and what needs attention
dotfiles_security          # Explain security model and architecture

# AWS management
aws_switch <profile>
aws_current
aws_check

# Gemini AI (optional, requires ENABLE_GEMINI=true)
gemini_check               # Verify credentials are set and ADC file exists
gemini_status              # Show current env var values (masked)
gemini_clear               # Clear Gemini credentials from environment

# Pass management
pass ls
pass show <entry>
pass insert <entry>

# GPG status
gpg --card-status
gpg --list-secret-keys
```

### Important Files
- **Main config**: `~/.zshrc`
- **AWS config**: `~/.aws/config` 
- **Credential script**: `~/.aws/credential-process.sh`
- **Password store**: `~/.password-store/`

### Documentation
- **This guide**: Complete user reference
- **[TROUBLESHOOTING.md](guides/TROUBLESHOOTING.md)**: When things break
- **[gpg-mgmnt.md](guides/gpg-mgmnt.md)**: Advanced GPG operations
- **[pass-setup.md](guides/pass-setup.md)**: Detailed pass configuration
- **[GOVERNANCE.md](GOVERNANCE.md)**: Security policies and procedures

## Support

**Having issues?** The documentation is designed to help you succeed:

1. **Start with this guide** for your specific task
2. **Check troubleshooting** for common issues
3. **Read detailed guides** for advanced topics
4. **Use built-in help** functions for quick reference

Remember: This system prioritizes **security over convenience**. The initial setup investment pays dividends in credential safety and peace of mind.

---

*For detailed technical information, see [ARCHITECTURE.md](ARCHITECTURE.md). For security policies and procedures, see [SECURITY.md](../SECURITY.md).*