# Troubleshooting Guide

This guide covers common issues you might encounter with the security-focused dotfiles setup and their solutions.

## Table of Contents

- [GPG Issues](#gpg-issues)
- [Pass Issues](#pass-issues)
- [AWS Credential Issues](#aws-credential-issues)
- [SSH Authentication Issues](#ssh-authentication-issues)
- [Shell Configuration Issues](#shell-configuration-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Hardware Key Issues](#hardware-key-issues)
- [Performance Issues](#performance-issues)

## GPG Issues

### GPG Agent Not Starting

**Symptoms:**
- Commands hang when requiring GPG
- Error: "gpg: can't connect to the agent"

**Solutions:**
```bash
# Kill any existing agents
gpgconf --kill gpg-agent

# Start agent manually
gpg-agent --daemon

# Add to .zshrc for automatic startup
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
```

### GPG Key Not Found

**Symptoms:**
- Error: "gpg: skipped: No such file or directory"
- Pass fails to decrypt

**Solutions:**
```bash
# List available keys
gpg --list-secret-keys --keyid-format LONG

# Re-initialize pass with correct key ID
pass init YOUR-CORRECT-KEY-ID

# Import missing keys
gpg --import /path/to/backup.asc
```

### Permission Errors

**Symptoms:**
- "Permission denied" when accessing GPG
- GPG operations fail silently

**Solutions:**
```bash
# Fix GPG directory permissions
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*

# Fix ownership (if needed)
sudo chown -R $(whoami):$(whoami) ~/.gnupg
```

### GPG Pinentry Issues

**Symptoms:**
- PIN entry dialog doesn't appear
- Error: "pinentry died"

**Solutions:**
```bash
# For SSH sessions, use curses pinentry
export PINENTRY_USER_DATA="USE_CURSES=1"

# Configure in ~/.gnupg/gpg-agent.conf
echo "pinentry-program /usr/bin/pinentry-curses" >> ~/.gnupg/gpg-agent.conf

# Restart GPG agent
gpgconf --kill gpg-agent
```

## Pass Issues

### Pass Not Initialized

**Symptoms:**
- Error: "Error: password store is empty"
- Pass commands don't work

**Solutions:**
```bash
# Initialize with your GPG key
gpg --list-secret-keys --keyid-format LONG
pass init YOUR-GPG-KEY-ID

# Verify initialization
pass ls
```

### Password Store Corruption

**Symptoms:**
- Random decryption failures
- Missing entries

**Solutions:**
```bash
# Check password store integrity
find ~/.password-store -name "*.gpg" -exec gpg --decrypt {} \; >/dev/null

# Restore from backup
tar xzf password-store-backup.tar.gz -C ~/

# Re-encrypt all entries (if needed)
pass init --reencrypt YOUR-GPG-KEY-ID
```

### Git Integration Issues

**Symptoms:**
- Error: "fatal: not a git repository"
- Pass git commands fail

**Solutions:**
```bash
# Initialize git in password store
cd ~/.password-store
pass git init

# Configure git
pass git config user.email "your-email@example.com"
pass git config user.name "Your Name"

# Add existing files
pass git add -A
pass git commit -m "Initial commit"
```

## AWS Credential Issues

### Credential Process Script Not Found

**Symptoms:**
- Error: "`credential_process: command not found`"
- Error: "`[Errno 2] No such file or directory: './credential-process.sh'`" (common on macOS)
- AWS CLI fails to authenticate

**Root Cause:**
AWS requires **absolute paths** for `credential_process` configuration. Relative paths (like `./credential-process.sh`, `~/credential-process.sh`, or `../credential-process.sh`) will fail because AWS CLI executes the script from its own working directory, not from `~/.aws/`.

**Common Mistakes:**
```ini
# ❌ These will FAIL:
credential_process = ./credential-process.sh personal
credential_process = ~/credential-process.sh personal
credential_process = $HOME/.aws/credential-process.sh personal  # Variables not expanded

# ✅ This works:
credential_process = /home/username/.aws/credential-process.sh personal  # Linux
credential_process = /Users/username/.aws/credential-process.sh personal  # macOS
```

**Solutions:**

1. **Check if script exists and is executable:**
   ```bash
   ls -la ~/.aws/credential-process.sh
   chmod +x ~/.aws/credential-process.sh
   ```

2. **Diagnose path issues:**
   ```bash
   # Check your current AWS config
   grep credential_process ~/.aws/config

   # Look for relative paths (these are the problem)
   grep credential_process ~/.aws/config | grep -E '\./|~/|\.\./|= [^/]'
   ```

3. **Fix relative paths automatically:**
   ```bash
   # Get your correct absolute path
   echo "$HOME/.aws/credential-process.sh"

   # Fix common relative path patterns (creates backup as config.bak)
   sed -i.bak "s|credential_process = \./credential-process.sh|credential_process = $HOME/.aws/credential-process.sh|g" ~/.aws/config
   sed -i.bak "s|credential_process = ~/\.|credential_process = $HOME/.|g" ~/.aws/config
   sed -i.bak "s|credential_process = \$HOME|credential_process = $HOME|g" ~/.aws/config
   ```

4. **Manual fix:**
   ```bash
   # Edit config file
   nano ~/.aws/config

   # Replace relative paths with absolute paths
   # macOS example: /Users/yourname/.aws/credential-process.sh
   # Linux example: /home/yourname/.aws/credential-process.sh
   ```

5. **Test the script directly:**
   ```bash
   # Test with absolute path
   ~/.aws/credential-process.sh dev

   # Should output JSON with credentials
   ```

6. **Verify the fix:**
   ```bash
   # Run AWS command
   aws sts get-caller-identity

   # Should succeed without errors
   ```

**Prevention:**
Run `./validate.sh` from your dotfiles directory to catch this issue before it causes problems.

### Invalid JSON Output

**Symptoms:**
- Error: "Unable to parse JSON"
- Credential process returns malformed data

**Solutions:**
```bash
# Test with debug mode
AWS_CREDENTIAL_PROCESS_DEBUG=true ~/.aws/credential-process.sh dev

# Check for stderr output interfering
~/.aws/credential-process.sh dev 2>/dev/null | jq .

# Verify pass entries exist
pass ls aws/dev/
```

### Credentials Not Found in Pass

**Symptoms:**
- Error: "CredentialNotFoundError"
- No AWS credentials stored

**Solutions:**
```bash
# Check pass structure
pass ls aws/

# Add missing credentials
pass insert aws/dev/access-key-id
pass insert aws/dev/secret-access-key

# Verify storage
pass show aws/dev/access-key-id
```

### AWS CLI Profile Issues

**Symptoms:**
- Error: "The config profile could not be found"
- Wrong profile being used

**Solutions:**
```bash
# Check AWS config syntax
aws configure list --profile dev

# View current configuration
cat ~/.aws/config

# Set profile explicitly
export AWS_PROFILE=dev
```

## SSH Authentication Issues

### GPG SSH Not Working

**Symptoms:**
- SSH still asks for password
- GPG card not used for SSH

**Solutions:**
```bash
# Check SSH_AUTH_SOCK is set to GPG agent
echo $SSH_AUTH_SOCK

# Restart GPG SSH setup
gpg_ssh_restart

# Verify SSH keys are available
ssh-add -l
```

### SSH Public Key Not Available

**Symptoms:**
- Error: "ssh-add -L" returns empty
- No SSH identity available

**Solutions:**
```bash
# Check GPG authentication key exists
gpg --list-keys --with-keygrip | grep -A1 "\[A\]"

# Restart GPG agent with SSH support
gpgconf --kill gpg-agent
gpg-connect-agent updatestartuptty /bye

# Extract SSH key manually
gpg --export-ssh-key YOUR-AUTH-SUBKEY-ID
```

### PIN Entry for SSH

**Symptoms:**
- PIN dialog appears for every SSH connection
- SSH authentication is slow

**Solutions:**
```bash
# Configure PIN caching in ~/.gnupg/gpg-agent.conf
default-cache-ttl-ssh 600  # 10 minutes
max-cache-ttl-ssh 3600    # 1 hour

# Restart agent
gpgconf --kill gpg-agent
```

## Shell Configuration Issues

### Functions Not Available

**Symptoms:**
- Command "aws_check" not found
- Shell functions don't work

**Solutions:**
```bash
# Source the configuration
source ~/.zshrc

# Check if functions are defined
type aws_check

# Verify .zshrc is being loaded
echo $ZSH
```

### Oh My Zsh Conflicts

**Symptoms:**
- Slow shell startup
- Plugin conflicts

**Solutions:**
```bash
# Check loading time
time zsh -c exit

# Disable problematic plugins
# Edit ~/.zshrc and remove from plugins=() array

# Reset Oh My Zsh
rm -rf ~/.oh-my-zsh
```

### Theme and Display Issues

#### Pure Theme Issues (Most Common)

**Symptoms:**
- "Usage: prompt (options)" error on shell startup
- Prompt shows default macOS/Linux prompt instead of Pure theme
- Error messages about unknown `prompt` command

**Root Cause:** Pure theme not installed or not accessible to zsh

**Solutions:**
```bash
# 1. Check if Pure theme exists
ls ~/.oh-my-zsh/custom/themes/pure/
# Should show: pure.zsh, async.zsh, README.md

# 2. If directory is empty/missing, install Pure theme
./setup/install-pure-theme.sh

# Or manually:
git clone https://github.com/sindresorhus/pure.git ~/.oh-my-zsh/custom/themes/pure

# 3. Verify .zshrc has fallback protection (should be automatic)
grep -A5 "Pure Theme Setup" ~/.zshrc

# 4. Restart shell
exec zsh
```

**macOS-specific notes:**
- macOS has its own built-in `prompt` command that conflicts with Pure
- Our configuration includes fallback protection to prevent this issue
- If you still see errors, ensure Oh My Zsh is properly installed

#### Other Theme Issues

**Symptoms:**
- Strange characters in prompt (boxes, question marks) 
- Agnoster theme not displaying properly
- AWS profile not showing in prompt

**Solutions:**
```bash
# Check terminal capabilities
echo "256-color: ${TERMINAL_HAS_256_COLOR:-unknown}"
echo "Unicode: ${TERMINAL_HAS_UNICODE:-unknown}" 
echo "Powerline: ${TERMINAL_HAS_POWERLINE:-unknown}"

# Install powerline fonts (for Agnoster theme)
install_powerline_fonts

# Force theme selection
export TERMINAL_HAS_POWERLINE=false  # Force robbyrussell
export TERMINAL_HAS_POWERLINE=true   # Force agnoster (if fonts available)

# Switch to Pure theme (recommended)
# See USER-GUIDE.md -> Shell Theme Configuration

# Restart shell
exec zsh
```

**Font Installation per Platform:**
- **macOS**: `brew install font-fira-code-nerd-font`
- **Ubuntu/Debian**: `apt-get install fonts-powerline fonts-firacode` 
- **WSL**: Install fonts in Windows and configure Windows Terminal

### AWS Profile Display Issues

**Symptoms:**
- AWS profile not showing in prompt
- aws_switch command not found

**Solutions:**
```bash
# Check AWS plugin is loaded
echo $plugins | grep aws

# Verify AWS functions are available
type aws_switch
type aws_current

# Check current profile
echo $AWS_PROFILE

# Test AWS profile switching
aws_switch dev
aws_current
```

### Environment Variables Not Set

**Symptoms:**
- AWS_PROFILE not working
- GPG_TTY issues

**Solutions:**
```bash
# Add to .zshrc
export GPG_TTY=$(tty)
export AWS_PROFILE=dev

# Source immediately
source ~/.zshrc

# Check variables
env | grep -E "(AWS|GPG)"
```

## Platform-Specific Issues

### macOS Issues

#### Pinentry Problems
```bash
# Install pinentry-mac
brew install pinentry-mac

# Configure in ~/.gnupg/gpg-agent.conf
pinentry-program /usr/local/bin/pinentry-mac
```

#### Homebrew PATH Issues
```bash
# Add to .zshrc (Apple Silicon)
export PATH="/opt/homebrew/bin:$PATH"

# Add to .zshrc (Intel)
export PATH="/usr/local/bin:$PATH"
```

### Linux Issues

#### Missing Dependencies
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gnupg2 pass pinentry-curses

# Arch Linux
sudo pacman -S gnupg pass pinentry

# CentOS/RHEL
sudo yum install gnupg2 pass pinentry
```

#### Systemd Socket Issues
```bash
# Check systemd user services
systemctl --user status gpg-agent

# Restart GPG agent socket
systemctl --user restart gpg-agent-ssh.socket
```

### WSL Issues

#### GPG Agent in WSL
```bash
# Install socat for socket forwarding
sudo apt-get install socat

# Add to .zshrc
export GPG_TTY=$(tty)
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    # WSL-specific GPG configuration
    export GNUPGHOME="/mnt/c/Users/$USER/.gnupg"
fi
```

#### Windows Integration
```bash
# Use Windows GPG from WSL
alias gpg='/mnt/c/Program\ Files\ \(x86\)/GnuPG/bin/gpg.exe'
```

## Hardware Key Issues

### YubiKey Not Detected

**Symptoms:**
- Error: "Card not present"
- gpg --card-status fails

**Solutions:**
```bash
# Check USB connection
lsusb | grep -i yubikey

# Restart card services
sudo systemctl restart pcscd

# Check card status
gpg --card-status
```

### PIN Blocked

**Symptoms:**
- Error: "PIN blocked"
- Cannot authenticate

**Solutions:**
```bash
# Check PIN retry counter
gpg --card-status | grep -i "retry counter"

# Reset with Admin PIN (if available)
gpg --card-edit
# > admin
# > unblock

# Factory reset (DESTROYS ALL DATA)
# Only if you have backups!
gpg --card-edit
# > admin
# > factory-reset
```

### Touch Policy Issues

**Symptoms:**
- Touch required for every operation
- No touch prompt appears

**Solutions:**
```bash
# Check current touch policy
ykman openpgp keys get-touch-policy aut

# Configure touch policy (requires Admin PIN)
ykman openpgp keys set-touch-policy aut on

# For SSH: configure caching
echo "default-cache-ttl-ssh 600" >> ~/.gnupg/gpg-agent.conf
```

## Performance Issues

### Slow Shell Startup

**Symptoms:**
- Long delay when opening new terminals
- Slow command execution

**Solutions:**
```bash
# Profile shell startup
time zsh -c exit

# Disable heavy plugins temporarily
# Comment out in ~/.zshrc:
# plugins=(... heavy-plugin ...)

# Check for slow network calls
# Remove or optimize AWS credential checks in prompt
```

### GPG Operations Slow

**Symptoms:**
- Long delays for GPG operations
- Frequent PIN prompts

**Solutions:**
```bash
# Enable caching in ~/.gnupg/gpg-agent.conf
default-cache-ttl 1800
max-cache-ttl 7200

# Use faster pinentry
pinentry-program /usr/bin/pinentry-curses

# Restart agent
gpgconf --kill gpg-agent
```

### AWS CLI Slow

**Symptoms:**
- Long delays for AWS commands
- Credential process timeout

**Solutions:**
```bash
# Check credential process performance
time ~/.aws/credential-process.sh dev

# Optimize GPG operations
gpg-connect-agent reloadagent /bye

# Use credential caching
aws configure set credential_process "~/.aws/credential-process.sh dev" --profile dev
```

## Debug Information Collection

When reporting issues, collect this information:

```bash
#!/bin/bash
# debug-info.sh - Collect system information for troubleshooting

echo "=== System Information ==="
uname -a
echo

echo "=== GPG Version ==="
gpg --version | head -1
echo

echo "=== Pass Version ==="
pass --version
echo

echo "=== GPG Agent Status ==="
gpg-connect-agent /bye 2>&1
echo

echo "=== GPG Keys ==="
gpg --list-secret-keys --keyid-format LONG
echo

echo "=== Pass Structure ==="
pass ls 2>/dev/null || echo "Pass not initialized"
echo

echo "=== AWS Config ==="
aws configure list 2>/dev/null || echo "AWS CLI not configured"
echo

echo "=== Environment Variables ==="
env | grep -E "(GPG|AWS|SSH|GNUPG)" | sort
echo

echo "=== Shell Functions ==="
type aws_check 2>/dev/null || echo "aws_check function not found"
echo

echo "=== Hardware Keys ==="
lsusb | grep -i yubikey || echo "No YubiKey detected"
echo

echo "=== Card Status ==="
gpg --card-status 2>/dev/null || echo "No card available"
```

## Getting Help

If you're still experiencing issues:

1. **Check Logs**:
   ```bash
   # GPG agent logs
   tail -f ~/.gnupg/gpg-agent.log
   
   # System logs
   journalctl --user -u gpg-agent -f
   ```

2. **Test Components Individually**:
   - Test GPG: `echo "test" | gpg --clearsign`
   - Test pass: `pass ls`
   - Test credential script: `~/.aws/credential-process.sh --help`
   - Test AWS CLI: `aws sts get-caller-identity`

3. **Review Documentation**:
   - [GPG Management](gpg-mgmnt.md)
   - [Pass Setup](pass-setup.md)
   - [SSH Authentication](gpg-ssh-auth.md)

4. **Create Issue Reports**:
   Include the output from `debug-info.sh` and specific error messages.