# SecureDots

<!-- Table of Contents for screen readers -->
<details>
<summary>Table of Contents</summary>

- [SecureDots](#securedots)
  - [How to Use This Repository](#how-to-use-this-repository)
  - [Quick Setup Paths](#quick-setup-paths)
  - [What You Get](#what-you-get)
  - [Prerequisites & Your Responsibilities](#prerequisites--your-responsibilities)
  - [Quick Commands](#quick-commands)
  - [Advanced Options](#advanced-options)
  - [Documentation](#documentation)
  - [System Requirements](#system-requirements)

</details>

**Local environment configuration with Documentation You Can Show Your CISO**

*Professional-grade credential management that eliminates plaintext secrets while maintaining developer productivity.*

> **⚠️ Opinionated Setup:** This repository reflects my personal development preferences and workflow opinions. Tool choices (vim, zsh, conda, Claude AI configs) represent my individual preferences - not universal recommendations. Customize to match your own workflow needs.

## 🎯 How to Use This Repository

<!-- Progressive disclosure based on user journey -->
<details open>
<summary><strong>👤 Personal Use</strong> (Most Common)</summary>

**Perfect for individual developers who want:**
- Professional credential management setup
- No team coordination required
- Quick setup and daily productivity

**Next step:** Jump to [Quick Setup Paths](#quick-setup-paths) below ↓
</details>

<!-- Decision support for user journey optimization -->
<details>
<summary><strong>🤔 Is This Right for You?</strong></summary>

### ✅ **Perfect for:**
- Developers working with multiple AWS accounts/profiles
- Teams needing standardized credential security practices
- Organizations with compliance requirements (SOX, PCI, FedRAMP, etc.)
- Users wanting [hardware security key](https://www.yubico.com/) integration
- Command-line comfortable developers who value security

### ⚠️ **Consider simpler alternatives if:**
- You only use one AWS account occasionally  
- Your team is < 3 people with simple needs
- You're not comfortable with command-line tools
- You need Windows-native (non-WSL) support
- You prefer graphical interfaces for credential management

**Alternative:** For basic needs, consider [AWS CLI named profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) or [AWS IAM Identity Center](https://aws.amazon.com/single-sign-on/).

</details>

<details>
<summary><strong>👥 Deploy for Your Team/Organization</strong></summary>

**Ideal for development teams who need:**
- Standardized security practices across developers
- Enterprise-grade credential management
- Consistent development environment setup
- Professional documentation for compliance teams

**Next step:** See **[TEMPLATE.md](TEMPLATE.md)** for complete deployment guidance
</details>

<details>
<summary><strong>🔍 Evaluation/Research</strong></summary>

**For security teams and architects evaluating:**
- Technical implementation details
- Security model and threat analysis
- Compliance and audit considerations
- Architecture decisions and trade-offs

**Next steps:** 
- **Technical details:** [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Security model:** [SECURITY.md](SECURITY.md)
- **Complete documentation:** [USER-GUIDE.md](docs/USER-GUIDE.md)
</details>

## Quick Setup Paths

### 👋 New to secure development?  
**Quick setup with software security (15-20 minutes)**

<!-- Mobile-friendly command blocks -->
```bash
# Clone the repository
git clone https://github.com/yourusername/securedots.git ~/dotfiles

# Run setup
cd ~/dotfiles && ./setup/setup-simple.sh
```

### 🔄 Have existing dotfiles?
**Migration notes and compatibility info** → [USER-GUIDE.md](docs/USER-GUIDE.md#migration-from-existing-dotfiles)

### 🔍 Evaluating for your team?  
**Security model, compliance, and architecture** → [SECURITY.md](SECURITY.md) and [ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## What You Get

<!-- Core benefits with progressive disclosure for details -->
<details open>
<summary><strong>🏢 Enterprise-Grade Security Architecture</strong></summary>

**Core Security Features:**
- ✅ **Zero plaintext credentials** stored anywhere in your system  
- ✅ **Hardware security key integration** (YubiKey, etc.) with software fallback
- ✅ **Comprehensive audit trail** through pass git integration
- ✅ **Defense-in-depth** credential protection model

<details>
<summary>Technical Security Details</summary>

- **GPG Encryption**: All credentials encrypted at rest using GPG with strong cipher preferences
- **Hardware Support**: Full YubiKey/hardware token integration with PIN/touch requirements
- **Audit Trails**: All credential access logged through pass git integration
- **Input Validation**: Comprehensive validation prevents injection attacks
- **Secure Architecture**: Multi-layer security model with fail-safe defaults

</details>
</details>

<details open>
<summary><strong>⚡ Developer Productivity Features</strong></summary>

**Daily Workflow Benefits:**
- ✅ **One-command AWS profile switching** with encrypted credential storage  
- ✅ **Cross-platform compatibility** (macOS, Linux, WSL2) with unified experience
- ✅ **Shell performance optimizations** without compromising security
- ✅ **Built-in validation** and health checking functions

<details>
<summary>Productivity Details</summary>

- **Fast Setup**: 15-20 minute basic setup, 45 minutes for full security
- **Performance**: Lazy-loading modules prevent shell slowdown
- **Compatibility**: Works on macOS, Linux, WSL2 with consistent behavior
- **Automation**: Built-in health checks and validation scripts
- **Recovery**: Comprehensive backup and recovery procedures

</details>
</details>

<details>
<summary><strong>📋 Professional Documentation Standards</strong></summary>

**Documentation Quality:**
- ✅ **CISO-ready** security model documentation
- ✅ **WCAG 2.1 AA accessible** documentation
- ✅ **Comprehensive troubleshooting** guides with error resolution
- ✅ **Architecture diagrams** meeting enterprise standards

<details>
<summary>Documentation Details</summary>

- **Accessibility**: All diagrams and content meet WCAG 2.1 AA standards
- **Professional Quality**: Documentation suitable for enterprise security reviews
- **Comprehensive Coverage**: Complete setup, usage, troubleshooting, and security guides
- **Visual Standards**: High-contrast diagrams with text alternatives
- **Mobile Optimized**: Content optimized for mobile and tablet viewing

</details>
</details>  

> **How it works:** Instead of plaintext AWS credentials in `~/.aws/credentials`, this system encrypts everything with [GPG](https://gnupg.org/) and dynamically retrieves credentials only when needed.

**Why this matters:** Traditional AWS credential files store your access keys in plaintext, visible to any process or person with file access. SecureDots eliminates this risk through encryption and optional hardware security key protection, meeting enterprise security standards while maintaining developer productivity.

## Prerequisites & Your Responsibilities

### 📋 **Before You Begin**

**Required Tools** (automatically checked during setup):
- `git` - Version control and repository cloning
- `stow` - GNU Stow for dotfiles management (creates safe symbolic links)
- `zsh` - Shell environment (will be set as default)
- [`gpg`](https://gnupg.org/) - Encryption software (2.2.40+ recommended) for credential protection
- [`pass`](https://www.passwordstore.org/) - Password manager that uses GPG encryption

**Optional Tools** (for advanced features):
- [Hardware security key](https://www.yubico.com/) (YubiKey 5+ recommended) - Physical device for tamper-resistant authentication
- [`aws` CLI](https://aws.amazon.com/cli/) (for AWS credential management)

#### Installation Commands

**macOS (using Homebrew):**
```bash
brew install git stow zsh gnupg pass
```

**Ubuntu/Debian:**  
```bash
sudo apt-get install git stow zsh gnupg pass
```

**Arch Linux:**
```bash
sudo pacman -S git stow zsh gnupg pass
```

### ⚡ **Your Security Responsibilities**

To safely use this system, you must:

1. **🔑 Secure Your Master Keys**
   - Back up GPG keys in offline, secure locations
   - Use strong passphrases for GPG keys
   - Consider hardware security keys for critical environments

2. **🔄 Maintain Your Credentials**  
   - Rotate AWS/cloud credentials regularly
   - Monitor access logs and unusual activity
   - Keep pass store backed up with `pass git push`

3. **📖 Understand the System**
   - Review scripts before running them
   - Follow security best practices in documentation
   - Keep software dependencies updated

**⚠️ Important:** This is **your security system** - no warranties provided. See [SECURITY.md](SECURITY.md) for complete legal details.

**🏗️ Deploying for Your Organization?** See [TEMPLATE.md](TEMPLATE.md) for architecture deployment guidance.

## Quick Commands

After setup, you'll have these essential commands available:

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

## Advanced Options

**🔒 Hardware Security Setup** (teams/compliance):
```bash
cd ~/dotfiles && ./setup/setup-secure-zsh.sh
```

## After Setup: Your Next Steps

Once setup completes successfully, follow this path to start using SecureDots:

### ✅ **1. Verify Everything Works**
```bash
./validate.sh                  # Run comprehensive health checks
```
**Expected result:** All checks show ✅ (green checkmarks)

### 🚀 **2. Learn Essential Commands** 
```bash
dotfiles_help                 # See all available functions
```
**Next:** Bookmark [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for daily use commands

### 🔑 **3. Add Your First Credentials**
```bash
# Add AWS credentials (replace 'dev' with your profile name)
pass insert aws/dev/access-key-id
pass insert aws/dev/secret-access-key

# Test the integration
aws_switch dev && aws sts get-caller-identity
```

### ❓ **Having Problems?**
- **Setup issues:** See [Troubleshooting Guide](docs/guides/TROUBLESHOOTING.md)
- **Command help:** Run `dotfiles_help` or `dotfiles_examples`
- **Complete guidance:** Read [USER-GUIDE.md](docs/USER-GUIDE.md)

## Documentation

- **📖 [User Guide](docs/USER-GUIDE.md)** - Complete setup and usage reference
- **📱 [Quick Reference](QUICK-REFERENCE.md)** - Essential commands for daily use
- **🔧 [Troubleshooting](docs/guides/TROUBLESHOOTING.md)** - Solutions for common issues
- **🏗️ [Architecture](docs/ARCHITECTURE.md)** - Technical details and security model

## System Requirements

<!-- Mobile-responsive requirements list -->
<details>
<summary><strong>Platform & Dependencies Overview</strong> (click to expand)</summary>

**Supported Platforms:**
- ✅ **macOS** (10.14+)
- ✅ **Linux** (Ubuntu, Debian, Arch, etc.)
- ✅ **WSL2** (Windows Subsystem for Linux)

**Required Tools:**
- ✅ **zsh** - Automatically set as default shell
- ⚠️ **git, stow, gpg, pass** - Must be installed first (see installation commands above)

**Optional Hardware:**
- 🔐 **Hardware Security Key** (YubiKey 5+) - For advanced security setup

**Time & Skill Requirements:**
- ⏱️ **Setup Time**: 15-45 minutes (depends on security level)
- 🎓 **Skill Level**: Intermediate+ (command line familiarity required)

</details>

<!-- Traditional table for desktop users -->
<details>
<summary><strong>Detailed Requirements Table</strong></summary>

| Component | Requirement | Auto-Install | Notes |
|-----------|-------------|--------------|-------|
| **Shell** | zsh | ✅ Yes | Set as default during setup |
| **Platform** | macOS, Linux, WSL2 | N/A | Windows requires WSL2 |
| **Dependencies** | git, stow, gpg, pass | ⚠️ Check first | See prerequisites above |
| **Hardware Key** | YubiKey 5+ (optional) | ❌ No | For advanced security setup |
| **Time** | 15-45 minutes | N/A | Depends on security level |
| **Skill Level** | Intermediate+ | N/A | Command line familiarity required |

</details>

---

![Security: Enterprise-Grade - Hardware security key support with GPG encryption](https://img.shields.io/badge/Security-Enterprise%20Grade-green.svg)
![Architecture: Zero-Plaintext - No plaintext credentials stored anywhere](https://img.shields.io/badge/Architecture-Zero%20Plaintext-blue.svg)
![Documentation: CISO-Ready - Professional security documentation](https://img.shields.io/badge/Documentation-CISO%20Ready-purple.svg)
![Platform: Cross-Platform - Works on macOS, Linux, and WSL2](https://img.shields.io/badge/Platform-Cross%20Platform-orange.svg)

*SecureDots: Local environment configuration with documentation that meets professional security standards. All design decisions favor credential protection without compromising developer workflows.*
