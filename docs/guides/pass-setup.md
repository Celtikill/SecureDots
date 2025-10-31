# Setting Up Pass for AWS Credentials

This guide covers the complete setup of `pass` password manager for secure AWS credential storage, integrated with the credential process feature of AWS CLI.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [GPG Key Setup](#gpg-key-setup)
- [Initialize Pass](#initialize-pass)
- [Store AWS Credentials](#store-aws-credentials)
- [Verify Setup](#verify-setup)
- [Security Best Practices](#security-best-practices)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)
- [Backup and Recovery](#backup-and-recovery)

## Prerequisites

Before setting up pass, ensure you have:

1. **A GPG key** (or ability to create one)
2. **Administrative access** to install software
3. **Basic understanding** of command line operations

## Installation

### macOS

```bash
# Install using Homebrew
brew install pass gnupg pinentry-mac

# Verify installation
pass --version
gpg --version
```

### Ubuntu/Debian

```bash
# Update package list
sudo apt-get update

# Install pass and GPG
sudo apt-get install -y pass gnupg2 pinentry-curses

# Verify installation
pass --version
gpg --version
```

### Arch Linux

```bash
# Install pass and GPG
sudo pacman -S pass gnupg pinentry

# Verify installation
pass --version
gpg --version
```

### Other Linux Distributions

```bash
# For Red Hat/CentOS/Fedora
sudo yum install pass gnupg2 pinentry

# For openSUSE
sudo zypper install password-store gpg2 pinentry
```

## GPG Key Setup

### Option 1: Create a New GPG Key

```bash
# Generate a new GPG key with recommended settings
gpg --full-generate-key

# Follow the prompts:
# 1. Choose: (1) RSA and RSA
# 2. Key size: 4096
# 3. Expiry: 2y (2 years recommended)
# 4. Enter your name and email
# 5. Set a strong passphrase

# List your keys to find the key ID
gpg --list-secret-keys --keyid-format LONG

# Example output:
# sec   rsa4096/ABCD1234EFGH5678 2024-01-15 [SC] [expires: 2026-01-15]
#       1234567890ABCDEF1234567890ABCDEF12345678
# uid                 [ultimate] Your Name <your.email@example.com>
# ssb   rsa4096/1234ABCD5678EFGH 2024-01-15 [E] [expires: 2026-01-15]
```

### Option 2: Use Existing GPG Key

```bash
# List existing keys
gpg --list-secret-keys --keyid-format LONG

# Note the key ID (the part after rsa4096/)
# Example: ABCD1234EFGH5678
```

### Export GPG Key ID

```bash
# Export for easy reference
export GPG_KEY_ID="ABCD1234EFGH5678"  # Replace with your actual key ID

# Verify it's set
echo $GPG_KEY_ID
```

## Initialize Pass

### Basic Initialization

```bash
# Initialize pass with your GPG key
pass init "$GPG_KEY_ID"

# You should see:
# Password store initialized for ABCD1234EFGH5678
```

### Initialize with Git (Recommended)

```bash
# Initialize pass with git for version control
pass init "$GPG_KEY_ID"
pass git init

# Configure git user (if not already done)
pass git config user.email "your.email@example.com"
pass git config user.name "Your Name"

# Create initial commit
pass git add -A
pass git commit -m "Initial password store"

# Optional: Add a remote repository (use a PRIVATE repo only!)
pass git remote add origin git@github.com:yourusername/password-store.git
pass git branch -M main
pass git push -u origin main
```

## Store AWS Credentials

The repository's AWS configuration supports multiple profiles. Here's how to store credentials for each:

### Understanding the Structure

Pass entries for AWS follow this pattern:
```
aws/
├── profile-name/
│   ├── access-key-id
│   ├── secret-access-key
│   └── session-token (optional, for temporary credentials)
└── another-profile/
    ├── access-key-id
    └── secret-access-key
```

### Store Credentials for Common Profiles

#### Dev Profile
```bash
# Store access key ID
pass insert aws/dev/access-key-id
# When prompted, enter your AWS access key ID (starts with AKIA...)

# Store secret access key
pass insert aws/dev/secret-access-key
# When prompted, enter your AWS secret access key

# Optional: For multi-line input or from file
pass insert -m aws/dev/credentials << EOF
access_key_id=AKIAIOSFODNN7EXAMPLE
secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
EOF
```

#### Work Profile
```bash
# Store access key ID
pass insert aws/work/access-key-id

# Store secret access key
pass insert aws/work/secret-access-key
```

#### Additional Profiles
```bash
# For staging environment
pass insert aws/staging/access-key-id
pass insert aws/staging/secret-access-key

# For production environment (with extra confirmation)
pass insert aws/production/access-key-id
pass insert aws/production/secret-access-key

# For temporary credentials with session token
pass insert aws/temp-role/access-key-id
pass insert aws/temp-role/secret-access-key
pass insert aws/temp-role/session-token
```

### Organize Credentials by Account

For better organization with multiple AWS accounts:

```bash
# Account-based structure
pass insert aws/accounts/123456789012/admin/access-key-id
pass insert aws/accounts/123456789012/admin/secret-access-key

pass insert aws/accounts/987654321098/developer/access-key-id
pass insert aws/accounts/987654321098/developer/secret-access-key
```

### Import Existing Credentials

If you have credentials in CSV format (from AWS Console):

```bash
#!/bin/bash
# import-aws-csv.sh - Import AWS credentials from CSV

CSV_FILE="$1"
PROFILE="$2"

if [[ -z "$CSV_FILE" ]] || [[ -z "$PROFILE" ]]; then
    echo "Usage: $0 <csv-file> <profile-name>"
    exit 1
fi

# Skip header and read credentials
tail -n +2 "$CSV_FILE" | while IFS=',' read -r username access_key secret_key; do
    echo "$access_key" | pass insert -e "aws/$PROFILE/access-key-id"
    echo "$secret_key" | pass insert -e "aws/$PROFILE/secret-access-key"
    echo "Imported credentials for profile: $PROFILE"
done

# Secure delete the CSV file
shred -vfz -n 3 "$CSV_FILE"
```

## Verify Setup

### 1. Verify Pass Installation and GPG

```bash
# Check pass is initialized
pass ls
# Should show your password store structure

# Verify GPG is working
echo "test" | gpg --clearsign
# Should output a signed message
```

### 2. Test Credential Storage

```bash
# List AWS credentials
pass ls aws/

# View a specific credential (will prompt for GPG passphrase)
pass show aws/dev/access-key-id

# Copy to clipboard (clears after timeout)
pass -c aws/dev/secret-access-key
```

### 3. Verify Credential Process Script

```bash
# Make the script executable if not already
chmod +x ~/.aws/credential-process.sh

# Test help output
~/.aws/credential-process.sh --help

# Test credential retrieval (debug mode)
AWS_CREDENTIAL_PROCESS_DEBUG=true ~/.aws/credential-process.sh dev

# Should output JSON like:
# {
#   "Version": 1,
#   "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
#   "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
# }
```

### 4. Test AWS CLI Integration

```bash
# Test with specific profile
AWS_PROFILE=dev aws sts get-caller-identity

# Should output:
# {
#     "UserId": "AIDACKCEVSQ6C2EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/username"
# }

# Test with environment variable
export AWS_PROFILE=work
aws s3 ls  # Or any other AWS command
```

### 5. Verify Security Functions

```bash
# Test the aws_check function from .zshrc
aws_check

# Test profile switching
aws_switch dev
aws_switch work
```

## Security Best Practices

### 1. GPG Key Management

```bash
# Create GPG key backup
gpg --armor --export-secret-keys "$GPG_KEY_ID" > ~/gpg-backup-secret.asc
gpg --armor --export "$GPG_KEY_ID" > ~/gpg-backup-public.asc

# Store these files in a secure, offline location
# Consider using a hardware security key for added protection
```

### 2. Pass Configuration

```bash
# Set secure environment variables (add to .zshrc)
export PASSWORD_STORE_CLIP_TIME=45     # Clear clipboard after 45 seconds
export PASSWORD_STORE_ENABLE_EXTENSIONS=true
export PASSWORD_STORE_GENERATED_LENGTH=32  # For generated passwords

# Configure GPG agent (add to ~/.gnupg/gpg-agent.conf)
default-cache-ttl 1800        # 30 minutes
max-cache-ttl 3600           # 1 hour
pinentry-program /usr/bin/pinentry-curses
```

### 3. Git Integration for Audit Trail

```bash
# Enable git commits for all changes
cd ~/.password-store
pass git init

# Configure git
pass git config user.email "your-email@example.com"
pass git config user.name "Your Name"

# View history
pass git log --oneline

# See what changed
pass git show HEAD
```

### 4. Access Control

```bash
# Restrict password store permissions
chmod 700 ~/.password-store
find ~/.password-store -type f -exec chmod 600 {} \;
find ~/.password-store -type d -exec chmod 700 {} \;

# Verify no credentials in shell history
history | grep -E "(AKIA|aws_secret)" && echo "WARNING: Credentials in history!"
```

## Advanced Configuration

### Multiple GPG Keys

Allow multiple users to access the password store:

```bash
# Add another GPG key
pass init -p aws "$GPG_KEY_ID" "COLLEAGUE_GPG_KEY_ID"

# Now both keys can decrypt aws/* entries
```

### Password Store Extensions

```bash
# Install pass-otp for 2FA codes
# macOS
brew install pass-otp

# Linux
sudo apt-get install pass-extension-otp

# Store AWS MFA secret
pass otp insert aws/dev/mfa

# Generate OTP code
pass otp aws/dev/mfa
```

### Integration with AWS Config

Your `~/.aws/config` should reference the credential process:

```ini
[profile dev]
region = us-east-2
output = json
credential_process = /home/user/.aws/credential-process.sh dev

[profile work]
region = us-west-2
output = json
credential_process = /home/user/.aws/credential-process.sh work
```

> **⚠️ CRITICAL: Absolute Paths Required - Especially on macOS**
>
> AWS requires **absolute paths** for `credential_process`. This is **particularly strict on macOS**.
>
> **🍎 macOS Users: The `./` prefix WILL NOT WORK**
>
> On macOS, you **must remove the dot** (`./`) and use the full absolute path:
> ```ini
> # ❌ THIS WILL FAIL ON macOS:
> credential_process = ./credential-process.sh personal
>
> # ✅ THIS WORKS ON macOS:
> credential_process = /Users/yourname/.aws/credential-process.sh personal
> ```
>
> **Error you'll see if using relative paths:**
> ```
> [Errno 2] No such file or directory: './credential-process.sh'
> ```
>
> **Get your correct absolute path:**
> ```bash
> # This shows your absolute path
> echo "$HOME/.aws/credential-process.sh"
>
> # macOS example: /Users/yourname/.aws/credential-process.sh
> # Linux example: /home/yourname/.aws/credential-process.sh
> ```
>
> **Quick fix command (macOS/Linux):**
> ```bash
> # Fix relative paths in your config (creates backup)
> sed -i.bak "s|credential_process = \./credential-process.sh|credential_process = $HOME/.aws/credential-process.sh|g" ~/.aws/config
>
> # Verify the fix
> grep credential_process ~/.aws/config
> ```
>
> **Why this matters:**
> - AWS CLI executes `credential_process` from its own working directory
> - Relative paths won't resolve correctly from that context
> - Environment variables like `$HOME` are not expanded in the config file
> - Tilde (`~`) expansion doesn't work in `credential_process` settings
> - **macOS is particularly strict** about enforcing absolute paths
>
> **Validation:**
> Run `./validate.sh` from your dotfiles directory to check for this issue.

## Troubleshooting

See the main [Troubleshooting Guide](TROUBLESHOOTING.md) for common issues.

### Common Issues and Solutions

#### GPG Agent Not Running
```bash
# Start GPG agent
gpg-connect-agent reloadagent /bye

# Add to .zshrc for automatic start
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
```

#### Permission Denied Errors
```bash
# Fix permissions
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*
chmod 700 ~/.password-store
chmod 755 ~/.aws/credential-process.sh
```

#### Pass Commands Hanging
```bash
# Kill stuck GPG agent
gpgconf --kill gpg-agent

# Restart with logging
gpg-agent --daemon --verbose --log-file ~/gpg-agent.log
```

#### AWS CLI Not Finding Credentials
```bash
# Debug credential process
export AWS_CREDENTIAL_PROCESS_DEBUG=true
aws sts get-caller-identity

# Check AWS config syntax
aws configure list --profile dev
```

### Testing Components Individually

```bash
#!/bin/bash
# test-aws-pass-setup.sh - Comprehensive test script

echo "=== Testing AWS Pass Setup ==="

# Test 1: GPG
echo -n "Testing GPG... "
if echo "test" | gpg --clearsign >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ GPG not working"
    exit 1
fi

# Test 2: Pass
echo -n "Testing pass... "
if pass ls >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ Pass not initialized"
    exit 1
fi

# Test 3: AWS credentials in pass
echo -n "Testing AWS credentials... "
if pass show aws/dev/access-key-id >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ No credentials found"
    exit 1
fi

# Test 4: Credential process script
echo -n "Testing credential process... "
if ~/.aws/credential-process.sh dev >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ Credential process failed"
    exit 1
fi

# Test 5: AWS CLI
echo -n "Testing AWS CLI... "
if AWS_PROFILE=dev aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ AWS CLI failed"
    exit 1
fi

echo "All tests passed! ✓"
```

## Backup and Recovery

### Regular Backups

```bash
#!/bin/bash
# backup-pass.sh - Backup password store and GPG keys

BACKUP_DIR="$HOME/backups/pass-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup password store
tar czf "$BACKUP_DIR/password-store.tar.gz" -C "$HOME" .password-store

# Backup GPG keys
gpg --armor --export-secret-keys > "$BACKUP_DIR/gpg-secret-keys.asc"
gpg --armor --export > "$BACKUP_DIR/gpg-public-keys.asc"
gpg --export-ownertrust > "$BACKUP_DIR/gpg-ownertrust.txt"

# Encrypt the backup
tar czf - "$BACKUP_DIR" | gpg --symmetric --cipher-algo AES256 > "$BACKUP_DIR.tar.gz.gpg"

# Clean up unencrypted backup
rm -rf "$BACKUP_DIR"

echo "Backup created: $BACKUP_DIR.tar.gz.gpg"
```

### Recovery Process

```bash
#!/bin/bash
# restore-pass.sh - Restore password store from backup

BACKUP_FILE="$1"

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Usage: $0 <backup-file.tar.gz.gpg>"
    exit 1
fi

# Decrypt and extract
gpg --decrypt "$BACKUP_FILE" | tar xzf -

# Find the backup directory
BACKUP_DIR=$(find . -maxdepth 1 -name "pass-*" -type d | head -1)

# Restore GPG keys
gpg --import "$BACKUP_DIR/gpg-secret-keys.asc"
gpg --import "$BACKUP_DIR/gpg-public-keys.asc"
gpg --import-ownertrust < "$BACKUP_DIR/gpg-ownertrust.txt"

# Restore password store
tar xzf "$BACKUP_DIR/password-store.tar.gz" -C "$HOME"

echo "Restore completed"
```

## Next Steps

After completing this setup:

1. **Test everything** using the verification steps above
2. **Create backups** of your GPG keys and password store
3. **Document** your key IDs and backup locations securely
4. **Consider** hardware security keys for enhanced protection
5. **Review** the security practices regularly

For advanced GPG configurations and hardware key setup, see [gpg-mgmnt.md](gpg-mgmnt.md).
