# SecureDots Command Cheat Sheet

**Single-page quick reference for daily operations** • Print this for your desk!

---

## AWS Profile Management

| Command | Purpose | Example |
|---------|---------|---------|
| `aws_switch <profile>` | Switch to a specific AWS profile | `aws_switch dev` |
| `aws_check` | Verify current AWS credentials are working | `aws_check` |
| `aws_current` | Show currently active AWS profile | `aws_current` |
| `aws sts get-caller-identity` | Show detailed AWS identity info | Shows account, user, ARN |

**Quick workflow:**
```bash
aws_switch prod    # Switch to production
aws_check          # Verify it works
# Do your AWS work
aws_switch dev     # Switch back to dev
```

---

## Credential Management (Pass)

| Command | Purpose | Example |
|---------|---------|---------|
| `pass ls` | List all stored credentials | `pass ls` or `pass ls aws/` |
| `pass show <path>` | Display a credential (decrypts) | `pass show aws/dev/access-key-id` |
| `pass insert <path>` | Store a new credential | `pass insert aws/prod/secret-key` |
| `pass insert -m <path>` | Store multi-line credential (JSON) | `pass insert -m aws/dev` |
| `pass -c <path>` | Copy credential to clipboard | `pass -c aws/dev/secret-key` |
| `pass rm <path>` | Delete a credential | `pass rm aws/old-account` |
| `pass git log` | View credential change history | `pass git log --oneline` |

**Quick workflow:**
```bash
# Add new AWS account
pass insert -m aws/new-account
# Paste JSON:
{
  "AWS_ACCESS_KEY_ID": "AKIA...",
  "AWS_SECRET_ACCESS_KEY": "..."
}
# Ctrl+D to save
```

---

## GPG Operations

| Command | Purpose | Example |
|---------|---------|---------|
| `gpg --card-status` | Check hardware key status | `gpg --card-status` |
| `gpg --list-secret-keys` | List your GPG keys | `gpg --list-secret-keys --keyid-format LONG` |
| `gpg --list-keys` | List all GPG keys (public) | `gpg --list-keys` |
| `echo "test" \| gpg --clearsign` | Test GPG signing works | Tests GPG + prompts for PIN |
| `gpgconf --kill gpg-agent` | Restart GPG agent | Use when GPG hangs |
| `gpg-connect-agent updatestartuptty /bye` | Reinitialize GPG agent | After killing agent |

---

## Shell Functions & Helpers

| Command | Purpose | Output |
|---------|---------|--------|
| `dotfiles_help` | Show all available functions | Lists custom commands |
| `dotfiles_examples` | Show workflow examples | Common usage patterns |
| `dotfiles_customize` | Get customization guidance | How to modify config |
| `source ~/.zshrc` | Reload shell configuration | Apply changes without restart |

---

## Troubleshooting One-Liners

### GPG Issues

```bash
# GPG agent not responding
gpgconf --kill gpg-agent && gpg-connect-agent updatestartuptty /bye

# Test GPG is working
echo "test" | gpg --clearsign

# Check hardware key
gpg --card-status

# Fix GPG permissions
chmod 700 ~/.gnupg && chmod 600 ~/.gnupg/*
```

### Pass Issues

```bash
# Pass not initialized
pass init YOUR-GPG-KEY-ID

# Re-encrypt all passwords (after key change)
pass init --reencrypt YOUR-GPG-KEY-ID

# Check pass structure
pass ls

# Verify pass entry is valid JSON
pass show aws/dev | jq .
```

### AWS Credential Issues

```bash
# Debug credential process
AWS_CREDENTIAL_PROCESS_DEBUG=true aws sts get-caller-identity

# Test credential process directly
pass show aws/dev | jq -r "{Version: 1, AccessKeyId: .AWS_ACCESS_KEY_ID, SecretAccessKey: .AWS_SECRET_ACCESS_KEY}"

# Check AWS config syntax
aws configure list --profile dev

# Verify credential process script exists
ls -la ~/.aws/credential-process.sh
chmod +x ~/.aws/credential-process.sh
```

### SSH Issues (GPG SSH Auth)

```bash
# Check SSH agent is using GPG
echo $SSH_AUTH_SOCK

# List available SSH keys
ssh-add -l

# Show SSH public key from GPG
ssh-add -L

# Restart GPG SSH support
gpgconf --kill gpg-agent && source ~/.zshrc
```

### Shell Configuration Issues

```bash
# Functions not available
source ~/.zshrc
type aws_check  # Should show function definition

# Check shell loaded correctly
echo $ZSH  # Should show Oh My Zsh path

# Reload dotfiles configuration
source ~/.zshrc && dotfiles_help
```

---

## File Locations

| Path | Purpose |
|------|---------|
| `~/.zshrc` | Main shell configuration |
| `~/.aws/config` | AWS profile definitions |
| `~/.aws/credential-process.sh` | Credential fetching script |
| `~/.password-store/` | Encrypted credentials (via pass) |
| `~/.gnupg/` | GPG configuration and keys |
| `~/.config/zsh/` | Modular zsh configuration files |
| `~/dotfiles/` | This repository (your clone location may vary) |

---

## Common Workflows

### Add a New AWS Account

```bash
# 1. Store credentials
pass insert -m aws/new-account
# Paste JSON with AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

# 2. Add profile to ~/.aws/config
# See examples/aws-config.example for template

# 3. Test it works
aws_switch new-account
aws_check
```

### Rotate AWS Credentials

```bash
# 1. Get new credentials from AWS console
# 2. Update pass entry
pass insert -m aws/prod  # Will overwrite existing
# 3. Test
aws_switch prod && aws_check
```

### Check What's Using Your Credentials

```bash
# Show current profile
aws_current

# Show detailed identity
aws sts get-caller-identity

# Check recent pass access
pass git log --oneline | head -10
```

### Backup Your Credentials

```bash
# Backup pass store (encrypted)
tar czf ~/backup-pass-$(date +%Y%m%d).tar.gz ~/.password-store/

# Backup GPG keys
gpg --export-secret-keys YOUR-KEY-ID > ~/gpg-backup-$(date +%Y%m%d).asc

# Encrypt the backup
gpg --symmetric --cipher-algo AES256 ~/gpg-backup-$(date +%Y%m%d).asc
```

---

## Quick Diagnostics

### Verify Everything Works

```bash
# Test 1: Shell functions loaded
dotfiles_help  # Should show list of functions

# Test 2: GPG working
echo "test" | gpg --clearsign  # Should prompt for passphrase

# Test 3: Pass initialized
pass ls  # Should show your password store

# Test 4: Credential process works
ls -la ~/.aws/credential-process.sh  # Should exist and be executable

# Test 5: AWS credentials work
aws_switch dev && aws_check  # Should succeed
```

### Common Error Messages & Fixes

| Error | Quick Fix |
|-------|-----------|
| "command not found: aws_check" | `source ~/.zshrc` |
| "gpg: can't connect to the agent" | `gpgconf --kill gpg-agent && gpg-connect-agent updatestartuptty /bye` |
| "Error: password store is empty" | `pass init YOUR-GPG-KEY-ID` |
| "credential_process returned invalid JSON" | Test: `pass show aws/dev \| jq .` |
| "Card not present" | Check hardware key inserted, try `gpg --card-status` |
| "Unable to locate credentials" | Verify `~/.aws/config` has `credential_process` line |

---

## Emergency Recovery

### Lost Hardware Key

```bash
# 1. If you have backup of master key:
#    Boot air-gapped system with backup
#    Generate new subkeys
#    Move to new hardware key
# 2. See docs/guides/gpg-enterprise-playbook.md for full procedure
```

### Corrupted Pass Store

```bash
# Restore from backup
tar xzf backup-pass-YYYYMMDD.tar.gz -C ~/
# Or restore from git
cd ~/.password-store && git log  # Find good commit
git checkout HEAD~5  # Go back 5 commits
```

### GPG Agent Completely Broken

```bash
# Nuclear option: kill everything and restart
pkill -9 gpg-agent
rm -rf ~/.gnupg/S.*  # Remove sockets
gpg-connect-agent reloadagent /bye
source ~/.zshrc
```

---

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `AWS_PROFILE` | Currently active AWS profile | `export AWS_PROFILE=dev` |
| `GPG_TTY` | TTY for GPG pinentry | Auto-set in .zshrc |
| `GNUPGHOME` | GPG home directory | Usually `~/.gnupg` |
| `PASSWORD_STORE_DIR` | Pass store location | Usually `~/.password-store` |
| `SSH_AUTH_SOCK` | SSH agent socket | Auto-set for GPG SSH |

---

## Security Best Practices

```bash
# Never do this:
echo "AKIA..." > ~/.aws/credentials  # ❌ Plaintext credentials

# Always do this:
pass insert -m aws/profile  # ✅ Encrypted storage

# Check for plaintext leaks:
grep -r "AKIA" ~/.aws  # Should find nothing except in credential-process.sh

# Verify encryption:
file ~/.password-store/**/*.gpg  # All should show "GPG encrypted data"
```

---

## Getting More Help

| Need | Command / Link |
|------|----------------|
| Detailed troubleshooting | See [TROUBLESHOOTING.md](docs/guides/TROUBLESHOOTING.md) |
| Full documentation | See [DOCS-INDEX.md](DOCS-INDEX.md) |
| Security details | See [SECURITY.md](SECURITY.md) |
| AWS config examples | See [examples/aws-config.example](examples/aws-config.example) |
| Interactive help | Run `dotfiles_help` |
| Workflow examples | Run `dotfiles_examples` |

---

**Pro Tip:** Bookmark this page or print it for quick reference! Most daily operations are on this single page.

**Last Updated:** Cheat sheet for SecureDots
**Print this:** Perfect single-page reference for daily use
