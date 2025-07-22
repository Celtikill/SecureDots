# SecureDots Quick Reference

<!-- Navigation aid for screen readers -->
<details>
<summary>Quick Navigation</summary>

- [First-Time Setup](#first-time-setup)
- [Daily Commands](#daily-commands)  
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)
- [Support & Resources](#support--resources)

</details>

*Essential commands for daily use - enterprise-grade local configuration*

<!-- Skip to main content landmark for screen readers -->
<a href="#first-time-setup" class="sr-only">Skip to setup instructions</a>

## 🚀 First-Time Setup

<!-- Cognitive load reduction: Clear expectation setting -->
<details open>
<summary><strong>Prerequisites Check</strong> (verify before setup)</summary>

**What this does:** Checks that all required tools are installed and working.

**Expected result:** Each command should show a version number (e.g., "git version 2.34.1").

```bash
# Verify you have required tools
git --version && stow --version && zsh --version && gpg --version && pass version
```

**If any command fails:**
- **macOS:** `brew install git stow zsh gnupg pass`
- **Ubuntu/Debian:** `sudo apt-get install git stow zsh gnupg pass`
- **Arch Linux:** `sudo pacman -S git stow zsh gnupg pass`

</details>

## Setup Commands

<!-- Clear expectations and time estimates -->
<details open>
<summary><strong>Choose Your Setup Level</strong></summary>

**🔰 Basic Setup (15-20 minutes):**
```bash
./setup/setup-simple.sh
```
*What this does:* Installs shell configuration, vim setup, basic security. Good for personal use.
*Requirements:* Standard tools (git, stow, zsh, gpg, pass)

**🔒 Advanced Setup (30-45 minutes):**
```bash
./setup/setup-secure-zsh.sh
```
*What this does:* Full security setup with hardware key support, GPG configuration, audit trails.
*Requirements:* All basic tools + optional hardware security key

</details>

<!-- Post-setup validation -->
<details open>
<summary><strong>Verify Your Setup Works</strong></summary>

```bash
# Test your setup
./validate.sh
```

**What this does:** Runs comprehensive health checks to ensure everything is working correctly.

**Expected result:** All checks should show ✅ (green checkmarks). Any ❌ or ⚠️ symbols indicate issues that need attention.

</details>

## Daily Commands

### Help & Status
```bash
dotfiles_help              # Show all available functions
dotfiles_examples           # See real workflow examples  
dotfiles_customize          # Customization guide
dotfiles_config             # Show current configuration
```

### AWS Profile Management

<details open>
<summary><strong>Switch Between AWS Environments</strong></summary>

```bash
aws_switch dev              # Switch to development profile
aws_switch staging          # Switch to staging profile
```

**Expected output:**
```
✅ AWS Profile: dev
✅ Credentials: Working
🏢 Account: 123456789012 (Development)
```

</details>

<details>
<summary><strong>Check Current AWS Status</strong></summary>

```bash
aws_check                   # Verify current credentials work
aws_current                 # Show current profile and account
```

**What these do:**
- `aws_check`: Tests if your AWS credentials are working by making a simple API call
- `aws_current`: Shows which AWS profile you're using and which account you're connected to

**If something is wrong:** Commands will show ❌ with helpful error messages and suggested fixes.

</details>

### Credential Management
```bash
penv aws/dev                # Load credentials from pass store
penv_clear                  # Clear loaded credentials
pass show aws/dev/access-key-id    # View stored credential
```

### Common Workflows

**Switch AWS Environment:**
```bash
aws_switch dev
aws_check
aws s3 ls                   # Test with actual AWS command
```

**Load Temporary Credentials:**
```bash
penv aws/dev                # Load from encrypted storage
aws sts get-caller-identity # Verify loaded credentials
penv_clear                  # Clean up when done
```

**Check System Status:**
```bash
dotfiles_config             # See what's configured
aws_current                 # Check current AWS profile
gpg --card-status           # Check hardware key (if using)
```

## 🆘 Troubleshooting Quick Fixes

<!-- Decision tree for common problems -->
<details>
<summary><strong>🔧 Shell/Configuration Problems</strong></summary>

**Problem:** Commands like `dotfiles_help` not found

**Solution:**
```bash
# Reload shell configuration
source ~/.zshrc
```

**If that doesn't work:**
```bash
# Manually load functions
source ~/.config/zsh/functions.zsh
dotfiles_help
```

**Expected result:** You should see the help menu with all available functions.

</details>

<details>
<summary><strong>☁️ AWS Credentials Problems</strong></summary>

**Problem:** "AWS credentials not found" or similar error

**Step 1 - Check status:**
```bash
aws_check                   # See specific error details
```

**Step 2 - Try switching profiles:**
```bash
aws_switch dev              # Re-select your profile
```

**Step 3 - Verify credentials exist:**
```bash
pass ls                     # Should show aws/profile entries
```

**If credentials are missing:** You need to add them with `pass insert aws/profile/access-key-id`

</details>

<details>
<summary><strong>🔐 GPG/Security Problems</strong></summary>

**Problem:** GPG operations failing or hanging

**Step 1 - Check GPG agent:**
```bash
gpg-connect-agent reloadagent /bye  # Restart GPG agent
```

**Step 2 - Test GPG functionality:**
```bash
echo "test" | gpg --clearsign        # Should prompt for passphrase
```

**Step 3 - Check hardware key (if using one):**
```bash
gpg --card-status           # Should show card details
```

**If hardware key not detected:** Check USB connection, try different port, or verify PIN attempts remaining.

</details>

### Common Issues

**"Command not found"**
- Run: `source ~/.zshrc`
- Or restart your terminal

**"AWS credentials not found"**  
- Run: `aws_switch dev` (or your profile)
- Check: `pass ls` to see stored credentials

**"GPG agent error"**
- Run: `gpg-connect-agent reloadagent /bye`
- Check: `gpg --card-status` if using hardware key

## File Locations

```bash
~/.zshrc                    # Main shell configuration
~/.config/zsh/              # Modular configuration files
~/.password-store/          # Encrypted credential storage (pass)
~/dotfiles/                 # This repository
```

## 🆘 Troubleshooting Quick Fixes

### System Not Working?
```bash
# Step 1: Reload configuration
source ~/.zshrc

# Step 2: Check system status  
dotfiles_status

# Step 3: Run health check
./validate.sh
```

### Still Need Help?

**📚 Documentation:**
- [Complete User Guide](docs/USER-GUIDE.md) - Full setup and usage
- [Troubleshooting Guide](docs/guides/TROUBLESHOOTING.md) - Detailed problem solving
- [Architecture Details](docs/ARCHITECTURE.md) - Technical implementation

**🔗 Support Channels:**
- [GitHub Issues](https://github.com/yourusername/securedots/issues) - Bug reports and features
- Security issues: **celtikill@celtikill.io** - Private disclosure

**🔍 Accessibility:**
- All documentation follows WCAG 2.1 AA standards
- Screen reader compatible
- High contrast mode supported
- Text-based alternatives provided for all visual content