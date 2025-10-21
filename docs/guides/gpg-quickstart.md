# GPG Quick Start Guide

**Simple GPG setup for SecureDots - Get running in 15-45 minutes**

This guide covers the GPG setup that 80% of users need. For enterprise air-gapped setups, see [GPG Enterprise Playbook](gpg-enterprise-playbook.md).

---

## Who This Guide Is For

✅ **Use this guide if you want:**
- Quick GPG setup for pass (password manager)
- Software-based GPG (no hardware key) OR basic hardware key setup
- To get started in 15-45 minutes

❌ **Use the Enterprise Playbook instead if you need:**
- Air-gapped master key generation
- FIPS-140 compliant USB storage
- Complex key lifecycle management
- Multi-layer security architecture

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Option 1: Software-Based GPG (15 minutes)](#option-1-software-based-gpg-15-minutes)
- [Option 2: Hardware Key Setup (45 minutes)](#option-2-hardware-key-setup-45-minutes)
- [Testing Your Setup](#testing-your-setup)
- [Daily Usage](#daily-usage)
- [Backup Your Keys](#backup-your-keys)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

**macOS:**
```bash
brew install gnupg pinentry-mac
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y gnupg2 pinentry-curses
```

**Arch Linux:**
```bash
sudo pacman -S gnupg pinentry
```

### Check Installation

```bash
gpg --version
# Should show: gpg (GnuPG) 2.2.x or higher
```

---

## Option 1: Software-Based GPG (15 minutes)

**Security level:** Good for development, personal use, non-production credentials
**Pros:** Quick setup, no hardware required
**Cons:** Keys stored on disk (encrypted but accessible if disk is compromised)

### Step 1: Generate Your GPG Key

```bash
# Start key generation wizard
gpg --full-generate-key

# Choose these options:
# 1. Key type: (1) RSA and RSA (default)
# 2. Key size: 4096
# 3. Expiration: 2y (2 years recommended)
# 4. Real name: Your Name
# 5. Email: your.email@example.com
# 6. Comment: (optional, can leave blank)
# 7. Set a STRONG passphrase (use a password manager!)
```

**Important:** Your passphrase protects your GPG key. Make it strong and memorable!

### Step 2: Find Your Key ID

```bash
# List your keys
gpg --list-secret-keys --keyid-format LONG

# Output will look like:
# sec   rsa4096/ABCD1234EFGH5678 2024-01-15 [SC] [expires: 2026-01-15]
#       1234567890ABCDEF1234567890ABCDEF12345678
# uid                 [ultimate] Your Name <your.email@example.com>
# ssb   rsa4096/1234ABCD5678EFGH 2024-01-15 [E] [expires: 2026-01-15]

# Your key ID is: ABCD1234EFGH5678 (the part after rsa4096/)
```

### Step 3: Export and Save Your Key ID

```bash
# Save your key ID for later use
export GPG_KEY_ID="ABCD1234EFGH5678"  # Replace with YOUR key ID

# Verify it's set
echo $GPG_KEY_ID
```

### Step 4: Initialize Pass

```bash
# Initialize pass with your GPG key
pass init "$GPG_KEY_ID"

# You should see:
# Password store initialized for ABCD1234EFGH5678

# Optional: Enable git for audit trail
pass git init
pass git config user.email "your.email@example.com"
pass git config user.name "Your Name"
```

### Step 5: Test It Works

```bash
# Test GPG signing
echo "test" | gpg --clearsign
# Should prompt for your passphrase, then output signed message

# Test pass
pass insert test/demo
# Enter a test password when prompted

# Verify it worked
pass show test/demo
# Should prompt for passphrase, then show your test password

# Clean up test
pass rm test/demo
```

✅ **Done!** You now have working GPG encryption. Skip to [Testing Your Setup](#testing-your-setup).

---

## Option 2: Hardware Key Setup (45 minutes)

**Security level:** Better - keys stored on hardware, can't be extracted
**Pros:** Physical security, touch/PIN required, keys can't leave device
**Cons:** Requires hardware ($20-70), slightly more complex setup

**Supported devices:** YubiKey 5 series, Nitrokey, OnlyKey, and other OpenPGP cards

### Step 1: Install Hardware Key Support

**macOS:**
```bash
# Additional tools for YubiKey management
brew install ykman
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install -y pcscd scdaemon yubikey-manager

# Start card services
sudo systemctl enable pcscd
sudo systemctl start pcscd
```

### Step 2: Verify Hardware Key Detection

```bash
# Insert your hardware key, then check status
gpg --card-status

# Should show card information like:
# Reader: Yubico YubiKey...
# Application ID: ...
# Version: ...
```

If you get "Card not present", see [Troubleshooting](#troubleshooting).

### Step 3: Change Default PINs

**IMPORTANT:** Hardware keys come with default PINs. Change them immediately!

```bash
# Change PINs
gpg --change-pin

# You'll be prompted twice:
# 1. User PIN (default: 123456) -> Choose a new 6+ digit PIN
# 2. Admin PIN (default: 12345678) -> Choose a new 8+ digit PIN
```

**Tips:**
- User PIN: Used for daily operations (signing, encrypting)
- Admin PIN: Used for administrative tasks (changing settings)
- Both can be alphanumeric, not just numbers
- Don't lose these! If you enter wrong PIN 3 times, card locks

### Step 4: Generate Keys on Card

You have two options:

#### Option A: Generate Keys Directly on Card (Simpler, More Secure)

Keys are generated on the hardware and **never** leave it.

```bash
# Edit card to generate keys
gpg --card-edit

# At the gpg/card> prompt:
gpg/card> admin
gpg/card> generate

# Follow prompts:
# - Make off-card backup? n (keys can't be extracted anyway)
# - Key validity: 2y (2 years)
# - Real name: Your Name
# - Email: your.email@example.com
# - Comment: (optional)

gpg/card> quit
```

#### Option B: Generate Keys on Computer, Move to Card (More Flexible)

Use this if you want backups or to put the same keys on multiple cards.

```bash
# 1. Generate a master key with subkeys
gpg --expert --full-generate-key

# Choose: (8) RSA (set your own capabilities)
# For master: Only Certify (toggle off Sign, Encrypt, Authenticate)
# Key size: 4096
# Expiration: 2y

# 2. Add subkeys
gpg --expert --edit-key YOUR-KEY-ID

# Add signing subkey
gpg> addkey
# Choose: (4) RSA (sign only), 2048 or 4096, 1-2y expiration

# Add encryption subkey
gpg> addkey
# Choose: (6) RSA (encrypt only), 2048 or 4096, 1-2y expiration

# Add authentication subkey
gpg> addkey
# Choose: (8) RSA (set your own capabilities)
# Toggle: S and E off, A on
# Size: 2048 or 4096, 1-2y expiration

gpg> save

# 3. Move subkeys to card
gpg --edit-key YOUR-KEY-ID

# Select and move signing key
gpg> key 1
gpg> keytocard
# Choose: (1) Signature key

# Deselect, then select and move encryption key
gpg> key 1
gpg> key 2
gpg> keytocard
# Choose: (2) Encryption key

# Deselect, select and move auth key
gpg> key 2
gpg> key 3
gpg> keytocard
# Choose: (3) Authentication key

gpg> save
```

### Step 5: Get Your Key ID and Initialize Pass

```bash
# Find your key ID
gpg --list-secret-keys --keyid-format LONG

# Save it
export GPG_KEY_ID="YOUR-KEY-ID"  # Replace with your actual key ID

# Initialize pass
pass init "$GPG_KEY_ID"

# Optional: Enable git
pass git init
pass git config user.email "your.email@example.com"
pass git config user.name "Your Name"
```

### Step 6: Test Hardware Key

```bash
# This should prompt for PIN and/or require touching your key
echo "test" | gpg --clearsign

# Test pass with hardware key
pass insert test/hardware-test
# Should require PIN/touch

pass show test/hardware-test
# Should require PIN/touch again

# Clean up
pass rm test/hardware-test
```

✅ **Done!** Your hardware key is set up and working with pass.

---

## Testing Your Setup

Run these tests to verify everything works:

### Test 1: GPG Works

```bash
# Should prompt for passphrase/PIN
echo "test" | gpg --clearsign

# ✅ Success: Shows signed message
# ❌ Failure: See troubleshooting
```

### Test 2: Pass Works

```bash
# Should show empty or your password structure
pass ls

# ✅ Success: Shows password store structure
# ❌ Failure: "Error: password store is empty" means not initialized
```

### Test 3: Can Store and Retrieve

```bash
# Store a test credential
pass insert test/verification

# Retrieve it
pass show test/verification

# Clean up
pass rm test/verification

# ✅ Success: Prompted for passphrase, showed your test password
# ❌ Failure: See troubleshooting
```

### Test 4: Hardware Key (if applicable)

```bash
# Check card status
gpg --card-status

# ✅ Success: Shows card info and key stubs
# ❌ Failure: "Card not present" - check USB connection
```

---

## Daily Usage

### Storing Credentials

```bash
# Store a single-line credential
pass insert aws/dev/access-key-id

# Store multi-line credential (like JSON)
pass insert -m aws/dev
# Then paste your JSON:
{
  "AWS_ACCESS_KEY_ID": "AKIA...",
  "AWS_SECRET_ACCESS_KEY": "..."
}
# Press Ctrl+D when done
```

### Retrieving Credentials

```bash
# Show a credential (decrypts and displays)
pass show aws/dev/access-key-id

# Copy to clipboard (clears after 45 seconds)
pass -c aws/dev/secret-key

# List all credentials
pass ls
```

### Managing Credentials

```bash
# Edit a credential
pass edit aws/dev/access-key-id

# Delete a credential
pass rm aws/dev/old-credential

# Move/rename a credential
pass mv aws/old-name aws/new-name

# Search for credentials
pass grep "production"
```

### View Audit Trail

```bash
# See credential changes (if git enabled)
pass git log --oneline

# See what changed in a specific commit
pass git show HEAD
```

---

## Backup Your Keys

**CRITICAL:** Backup your GPG keys! If you lose them, you lose access to all encrypted credentials.

### Software Keys Backup

```bash
# Create backup directory
mkdir -p ~/gpg-backup-$(date +%Y%m%d)
cd ~/gpg-backup-$(date +%Y%m%d)

# Backup public key
gpg --armor --export $GPG_KEY_ID > gpg-public-key.asc

# Backup secret key
gpg --armor --export-secret-keys $GPG_KEY_ID > gpg-secret-key.asc

# Backup trust database
gpg --export-ownertrust > gpg-ownertrust.txt

# Optional: Create paper backup
# Requires paperkey: brew install paperkey
paperkey --secret-key gpg-secret-key.asc --output gpg-paperkey.txt

# Encrypt the backup
tar czf - . | gpg --symmetric --cipher-algo AES256 --output ../gpg-backup-$(date +%Y%m%d).tar.gz.gpg

# Store this encrypted backup in:
# - Secure cloud storage
# - External hard drive (kept offline)
# - Safe deposit box (for paper backup)
```

### Hardware Keys Backup

For hardware keys where you generated keys on-card, you **cannot** extract the keys. Your backup strategy:

1. **Keep the revocation certificate** (generated during setup)
2. **Document your key ID and fingerprint**
3. **Consider buying a second hardware key** and using Option B above to put the same keys on both

```bash
# Generate revocation certificate (if not done already)
gpg --output ~/gpg-revoke-$GPG_KEY_ID.asc --gen-revoke $GPG_KEY_ID

# Store this somewhere very safe!
```

### Password Store Backup

```bash
# Backup your encrypted credentials
tar czf ~/password-store-backup-$(date +%Y%m%d).tar.gz ~/.password-store/

# This is safe to store in cloud - everything is encrypted
```

---

## Troubleshooting

### GPG Agent Not Running

```bash
# Kill and restart
gpgconf --kill gpg-agent
gpg-connect-agent updatestartuptty /bye
```

### Card Not Detected

```bash
# Linux: Restart card services
sudo systemctl restart pcscd

# Check USB connection
lsusb | grep -i yubikey

# Try card status again
gpg --card-status
```

### PIN Entry Not Appearing

```bash
# For SSH sessions, use curses pinentry
export PINENTRY_USER_DATA="USE_CURSES=1"

# Restart agent
gpgconf --kill gpg-agent
```

### Pass Not Initialized

```bash
# Initialize with your key ID
gpg --list-secret-keys --keyid-format LONG  # Find your key ID
pass init YOUR-KEY-ID
```

### Wrong Permissions

```bash
# Fix GPG directory permissions
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*

# Fix password store permissions
chmod 700 ~/.password-store
find ~/.password-store -type f -exec chmod 600 {} \;
```

### More Help

For comprehensive troubleshooting, see:
- [Complete Troubleshooting Guide](TROUBLESHOOTING.md#gpg-issues)
- [GPG Enterprise Playbook](gpg-enterprise-playbook.md) for advanced scenarios

---

## Next Steps

Now that GPG and pass are set up:

1. **Set up AWS credentials**: See [Pass Setup Guide](pass-setup.md#store-aws-credentials)
2. **Configure AWS profiles**: See [AWS Config Example](../../examples/aws-config.example)
3. **Set up SSH with GPG** (optional): See [GPG SSH Authentication](gpg-ssh-auth.md)
4. **Review security**: See [Security Verification](../../SECURITY-VERIFICATION.md)

---

## Security Levels Comparison

Choose the right security level for your needs:

| Feature | Software GPG | Hardware Key | Enterprise Air-Gapped |
|---------|-------------|--------------|----------------------|
| Setup time | 15 min | 45 min | 2-3 hours |
| Keys stored | On disk (encrypted) | On hardware (can't extract) | Offline system only |
| Protection level | 60% | 85% | 95% |
| Cost | Free | $20-70 | $200+ (hardware + storage) |
| Good for | Dev/personal | Production access | Critical infrastructure |
| This guide | ✅ Yes | ✅ Yes | ❌ See Enterprise Playbook |

**Recommendation:** Start with software GPG, upgrade to hardware key when handling production credentials.

---

**Questions?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or [DOCS-INDEX.md](../../DOCS-INDEX.md)

**Last Updated:** GPG Quick Start Guide
**Time to complete:** 15-45 minutes depending on option chosen
