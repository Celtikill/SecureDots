# GPG Key Management Playbook

## Overview
This playbook covers complete GPG key lifecycle management for a security-focused setup using:
- Air-gapped root key generation and storage
- Hardware security keys (YubiKey/similar) for daily operations
- FIPS-140 compliant USB storage for .gnupg directory
- Standards-compliant key management practices

## Key Architecture

### Master Key (Root Key)
- **Purpose**: Certification only (C flag)
- **Location**: Air-gapped system, offline storage
- **Usage**: Creating/revoking subkeys, signing other keys
- **Backup**: Multiple secure locations (safe deposit box, secure facility)

### Subkeys on Hardware Token
- **Signing Key (S)**: Code signing, email signing
- **Encryption Key (E)**: File/email encryption
- **Authentication Key (A)**: SSH, system authentication

### Storage Architecture
```
├── Air-gapped Master Key
│   ├── Root private key (never leaves air-gap)
│   └── Revocation certificate
├── FIPS-140 USB Drive (.gnupg)
│   ├── Public keyring
│   ├── Subkey stubs
│   └── Configuration files
└── Hardware Token (YubiKey)
    ├── Signing subkey
    ├── Encryption subkey
    └── Authentication subkey
```

## Initial Setup Ceremony

### Phase 1: Air-Gapped Master Key Generation

#### Prerequisites
- Air-gapped computer (never connected to network)
- Tails/secure live OS
- Multiple USB drives (FIPS-140 compliant)
- Printer for paper backups
- Dice for entropy (optional but recommended)

#### Steps

1. **Boot Air-Gapped System**
   ```bash
   # Boot Tails or secure live OS
   # Disconnect all network interfaces
   sudo rfkill block all
   
   # Verify network isolation
   ip link show
   ```

2. **Generate Master Key**
   ```bash
   # Set secure GPG configuration
   mkdir -p ~/.gnupg
   chmod 700 ~/.gnupg
   
   cat > ~/.gnupg/gpg.conf << 'EOF'
   # Strong cryptographic preferences
   personal-cipher-preferences AES256 AES192 AES
   personal-digest-preferences SHA512 SHA384 SHA256
   personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
   default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
   cert-digest-algo SHA512
   s2k-digest-algo SHA512
   s2k-cipher-algo AES256
   charset utf-8
   fixed-list-mode
   no-comments
   no-emit-version
   keyid-format 0xlong
   list-options show-uid-validity
   verify-options show-uid-validity
   with-fingerprint
   require-cross-certification
   no-symkey-cache
   use-agent
   throw-keyids
   EOF
   
   # Generate master key (Certification only)
   gpg --full-generate-key --expert
   # Choose: (8) RSA (set your own capabilities)
   # Toggle: S, E, A off (only C should remain)
   # Key size: 4096
   # Expiry: 2 years (or your preference)
   # Real name, email, comment
   ```

3. **Generate Revocation Certificate**
   ```bash
   # Get key ID
   KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep sec | awk '{print $2}' | cut -d'/' -f2)
   
   # Generate revocation certificate
   gpg --output revoke-${KEY_ID}.asc --gen-revoke ${KEY_ID}
   
   # Print revocation certificate for paper backup
   lpr revoke-${KEY_ID}.asc
   ```

4. **Create Subkeys**
   ```bash
   # Edit key to add subkeys
   gpg --expert --edit-key ${KEY_ID}
   
   # Add signing subkey
   gpg> addkey
   # Choose: (4) RSA (sign only)
   # Key size: 4096 or 2048 (hardware dependent)
   # Expiry: 1 year
   
   # Add encryption subkey
   gpg> addkey
   # Choose: (6) RSA (encrypt only)
   # Key size: 4096 or 2048
   # Expiry: 1 year
   
   # Add authentication subkey
   gpg> addkey
   # Choose: (8) RSA (set your own capabilities)
   # Toggle S and E off, A on
   # Key size: 4096 or 2048
   # Expiry: 1 year
   
   gpg> save
   ```

### Phase 2: Hardware Token Setup

1. **Prepare Hardware Token**
   ```bash
   # Insert YubiKey/hardware token
   gpg --card-status
   
   # Change default PINs (if not already done)
   gpg --change-pin
   # Default User PIN: 123456
   # Default Admin PIN: 12345678
   # Set strong PINs (6-127 chars for user, 8-127 for admin)
   ```

2. **Move Subkeys to Hardware Token**
   ```bash
   # Edit key
   gpg --edit-key ${KEY_ID}
   
   # Select signing subkey
   gpg> key 1
   gpg> keytocard
   # Choose: (1) Signature key
   
   # Select encryption subkey
   gpg> key 1  # deselect
   gpg> key 2  # select encryption key
   gpg> keytocard
   # Choose: (2) Encryption key
   
   # Select authentication subkey
   gpg> key 2  # deselect
   gpg> key 3  # select auth key
   gpg> keytocard
   # Choose: (3) Authentication key
   
   gpg> save
   ```

3. **Backup Master Key and Subkeys**
   ```bash
   # Export public key
   gpg --armor --export ${KEY_ID} > ${KEY_ID}-public.asc
   
   # Export master key (NEVER put this on networked system)
   gpg --armor --export-secret-keys ${KEY_ID} > ${KEY_ID}-master-secret.asc
   
   # Export subkeys only (safe for daily use system)
   gpg --armor --export-secret-subkeys ${KEY_ID} > ${KEY_ID}-subkeys-secret.asc
   
   # Create paper backup
   paperkey --secret-key ${KEY_ID}-master-secret.asc \
            --output ${KEY_ID}-paperkey.txt
   lpr ${KEY_ID}-paperkey.txt
   ```

4. **Secure Storage**
   ```bash
   # Copy to multiple FIPS-140 USB drives
   cp ${KEY_ID}-public.asc /media/backup1/
   cp ${KEY_ID}-subkeys-secret.asc /media/backup1/
   
   # Copy master key to secure offline storage
   cp ${KEY_ID}-master-secret.asc /media/offline-vault/
   cp revoke-${KEY_ID}.asc /media/offline-vault/
   
   # Secure delete from air-gapped system
   shred -vfz -n 3 ${KEY_ID}-master-secret.asc
   shred -vfz -n 3 revoke-${KEY_ID}.asc
   ```

### Phase 3: Daily Use System Setup

1. **Prepare FIPS-140 USB Drive**
   ```bash
   # Format USB drive with encryption
   sudo cryptsetup luksFormat /dev/sdX1
   sudo cryptsetup luksOpen /dev/sdX1 gpg-vault
   sudo mkfs.ext4 /dev/mapper/gpg-vault
   
   # Mount and set up .gnupg
   sudo mkdir /mnt/gpg-vault
   sudo mount /dev/mapper/gpg-vault /mnt/gpg-vault
   sudo mkdir /mnt/gpg-vault/.gnupg
   sudo chown $(whoami):$(whoami) /mnt/gpg-vault/.gnupg
   chmod 700 /mnt/gpg-vault/.gnupg
   ```

2. **Import Keys to Daily Use System**
   ```bash
   # Set GNUPGHOME to USB drive
   export GNUPGHOME=/mnt/gpg-vault/.gnupg
   
   # Import public key
   gpg --import ${KEY_ID}-public.asc
   
   # Import subkeys
   gpg --import ${KEY_ID}-subkeys-secret.asc
   
   # Trust your own key
   gpg --edit-key ${KEY_ID}
   gpg> trust
   # Choose: (5) I trust ultimately
   gpg> save
   
   # Verify hardware token
   gpg --card-status
   ```

## Daily Operations

### Mounting FIPS-140 USB Drive

```bash
#!/bin/bash
# mount-gpg.sh - Mount GPG vault

DEVICE="/dev/disk/by-uuid/YOUR-UUID"
MOUNT_POINT="/mnt/gpg-vault"

if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# Decrypt and mount
sudo cryptsetup luksOpen "$DEVICE" gpg-vault
sudo mount /dev/mapper/gpg-vault "$MOUNT_POINT"

# Set GPG home in current session
export GNUPGHOME="$MOUNT_POINT/.gnupg"
echo "GPG vault mounted. GNUPGHOME set to $GNUPGHOME"

# Add to shell session
echo "export GNUPGHOME='$MOUNT_POINT/.gnupg'" >> ~/.bashrc
```

### Unmounting GPG Vault

```bash
#!/bin/bash
# umount-gpg.sh - Unmount GPG vault

MOUNT_POINT="/mnt/gpg-vault"

# Kill any GPG agent processes
pkill -f gpg-agent

# Unmount
sudo umount "$MOUNT_POINT"
sudo cryptsetup luksClose gpg-vault

echo "GPG vault unmounted securely"
```

### Key Usage Verification

```bash
# Verify key status
gpg-check() {
    echo "=== GPG Status Check ==="
    echo "GNUPGHOME: $GNUPGHOME"
    echo
    
    echo "Hardware token status:"
    gpg --card-status
    echo
    
    echo "Available secret keys:"
    gpg --list-secret-keys
    echo
    
    echo "Testing signing capability:"
    echo "test" | gpg --clearsign --local-user ${KEY_ID}
}
```

## Backup and Recovery Procedures

### Weekly Backup Routine

```bash
#!/bin/bash
# backup-gpg.sh - Weekly GPG backup routine

BACKUP_DATE=$(date +%Y%m%d)
BACKUP_DIR="/secure/backups/gpg-${BACKUP_DATE}"
GPG_HOME="${GNUPGHOME:-$HOME/.gnupg}"

mkdir -p "$BACKUP_DIR"

echo "Creating GPG backup for $BACKUP_DATE"

# Backup public keyring
cp "$GPG_HOME/pubring.kbx" "$BACKUP_DIR/"

# Backup trust database
cp "$GPG_HOME/trustdb.gpg" "$BACKUP_DIR/"

# Backup configuration
cp "$GPG_HOME/gpg.conf" "$BACKUP_DIR/"
cp "$GPG_HOME/gpg-agent.conf" "$BACKUP_DIR/"

# Export all public keys
gpg --export --armor > "$BACKUP_DIR/all-public-keys.asc"

# Create verification file
gpg --list-keys > "$BACKUP_DIR/key-listing.txt"

# Encrypt backup
tar czf - "$BACKUP_DIR" | gpg --symmetric --cipher-algo AES256 \
    --output "$BACKUP_DIR.tar.gz.gpg"

# Secure delete unencrypted backup
shred -vfz -n 3 -r "$BACKUP_DIR"

echo "Backup completed: $BACKUP_DIR.tar.gz.gpg"
```

### Recovery Procedures

#### Scenario 1: Hardware Token Lost/Damaged

```bash
# Emergency recovery steps
echo "HARDWARE TOKEN RECOVERY PROCEDURE"
echo "================================="

# 1. Get new hardware token
echo "1. Insert new hardware token"

# 2. Access air-gapped master key
echo "2. Boot air-gapped system with master key backup"

# 3. Generate new subkeys (on air-gapped system)
gpg --edit-key ${KEY_ID}
# Delete old subkeys: delkey
# Add new subkeys: addkey
# Save and move to new hardware token

# 4. Update keyservers and notify contacts
echo "4. Upload updated public key to keyservers"
gpg --send-keys ${KEY_ID}

# 5. Create new backup
echo "5. Create new backup with updated keys"
```

#### Scenario 2: USB Drive Corruption

```bash
# Restore from backup
echo "USB DRIVE RECOVERY PROCEDURE"
echo "============================"

# 1. Decrypt and restore backup
gpg --decrypt backup-YYYYMMDD.tar.gz.gpg | tar xzf -

# 2. Prepare new USB drive
cryptsetup luksFormat /dev/sdX1
cryptsetup luksOpen /dev/sdX1 gpg-vault
mkfs.ext4 /dev/mapper/gpg-vault

# 3. Restore .gnupg directory
mount /dev/mapper/gpg-vault /mnt/gpg-vault
cp -r backup/.gnupg /mnt/gpg-vault/
chmod 700 /mnt/gpg-vault/.gnupg

# 4. Verify restoration
export GNUPGHOME=/mnt/gpg-vault/.gnupg
gpg --card-status
gpg --list-secret-keys
```

## Key Lifecycle Management

### Annual Subkey Rotation

```bash
#!/bin/bash
# rotate-subkeys.sh - Annual subkey rotation

echo "SUBKEY ROTATION PROCEDURE"
echo "========================"

# 1. Boot air-gapped system
echo "1. Boot air-gapped system with master key"

# 2. Import current public key state
echo "2. Import current public key from keyserver"
# (On air-gapped system, import from backup)

# 3. Edit master key
gpg --edit-key ${KEY_ID}

# 4. Set expiry on old subkeys to past date
# gpg> key 1
# gpg> expire
# gpg> key 1  # deselect
# Repeat for all subkeys

# 5. Generate new subkeys
# gpg> addkey
# Repeat for S, E, A keys

# 6. Move new subkeys to hardware token
# Follow keytocard procedure

# 7. Export and backup
# Export new public key
# Create new backup

echo "7. Update daily use system with new subkeys"
```

### Master Key Renewal (Every 2-3 Years)

```bash
# Master key renewal procedure
echo "MASTER KEY RENEWAL PROCEDURE"
echo "============================"

# 1. Generate new master key on air-gapped system
echo "1. Generate new master key (follow initial setup)"

# 2. Sign new key with old key (key transition)
gpg --default-key ${OLD_KEY_ID} --sign-key ${NEW_KEY_ID}

# 3. Create key transition statement
cat > key-transition-${NEW_KEY_ID}.txt << EOF
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

I am transitioning my GPG key from:

Old key: ${OLD_KEY_ID}
New key: ${NEW_KEY_ID}

This transition statement is signed with both keys.

Effective date: $(date)
-----END PGP SIGNED MESSAGE-----
EOF

# 4. Sign transition statement with both keys
gpg --default-key ${OLD_KEY_ID} --clearsign key-transition-${NEW_KEY_ID}.txt
gpg --default-key ${NEW_KEY_ID} --clearsign key-transition-${NEW_KEY_ID}.txt.asc

# 5. Publish new key and transition statement
echo "5. Upload to keyservers and publish transition statement"

# 6. Revoke old key after transition period (30-90 days)
echo "6. Schedule old key revocation"
```

## Revocation Procedures

### Emergency Revocation

```bash
#!/bin/bash
# emergency-revoke.sh - Emergency key revocation

echo "EMERGENCY REVOCATION PROCEDURE"
echo "============================="

# Method 1: Using pre-generated revocation certificate
echo "Method 1: Using revocation certificate"
gpg --import revoke-${KEY_ID}.asc
gpg --send-keys ${KEY_ID}

# Method 2: Using master key (if accessible)
echo "Method 2: Using master key"
gpg --edit-key ${KEY_ID}
# gpg> revkey
# Select subkey to revoke
# gpg> save

# Method 3: Generate new revocation certificate
echo "Method 3: Generate new revocation"
gpg --gen-revoke ${KEY_ID} > emergency-revoke-${KEY_ID}.asc
gpg --import emergency-revoke-${KEY_ID}.asc
gpg --send-keys ${KEY_ID}

echo "Revocation completed. Notify all contacts immediately."
```

### Subkey Revocation

```bash
# Revoke specific subkey
revoke-subkey() {
    local KEY_ID="$1"
    local SUBKEY_ID="$2"
    
    echo "Revoking subkey $SUBKEY_ID of key $KEY_ID"
    
    # Must be done with master key on air-gapped system
    gpg --edit-key ${KEY_ID}
    # gpg> key ${SUBKEY_ID}
    # gpg> revkey
    # gpg> save
    
    # Export and publish updated key
    gpg --export ${KEY_ID} > ${KEY_ID}-updated.asc
    gpg --send-keys ${KEY_ID}
}
```

## Security Monitoring

### Key Validation Checks

```bash
#!/bin/bash
# validate-keys.sh - Regular key validation

echo "GPG KEY VALIDATION CHECKS"
echo "========================"

# Check key expiry
echo "Key expiration status:"
gpg --list-keys ${KEY_ID} | grep -E "(expires|expired)"

# Check subkey status
echo "Subkey status:"
gpg --list-keys ${KEY_ID}

# Verify hardware token connection
echo "Hardware token status:"
gpg --card-status

# Check for any revoked keys
echo "Checking for revoked keys:"
gpg --list-keys | grep -i revoked

# Verify key fingerprint
echo "Key fingerprint verification:"
gpg --fingerprint ${KEY_ID}

# Check keyserver synchronization
echo "Keyserver sync status:"
gpg --recv-keys ${KEY_ID} 2>&1 | grep -E "(unchanged|updated)"
```

### Audit Trail

```bash
# Log GPG operations
export GPG_AUDIT_LOG="$HOME/.gpg-audit.log"

# Add to .zshrc or equivalent
gpg() {
    echo "$(date): gpg $*" >> "$GPG_AUDIT_LOG"
    command gpg "$@"
}

# Review audit log
audit-gpg() {
    echo "Recent GPG operations:"
    tail -20 "$GPG_AUDIT_LOG"
}
```

## Incident Response

### Compromise Response

1. **Immediate Actions**
   - Revoke compromised keys immediately
   - Change all PINs on hardware tokens
   - Notify all contacts of compromise

2. **Assessment**
   - Determine scope of compromise
   - Check audit logs for suspicious activity
   - Verify integrity of backup systems

3. **Recovery**
   - Generate new keys following standard procedure
   - Re-establish trust relationships
   - Update all systems and configurations

4. **Prevention**
   - Review security procedures
   - Implement additional monitoring
   - Update incident response procedures

## Maintenance Schedule

### Daily
- Verify hardware token connectivity
- Check GPG agent status

### Weekly
- Run backup routine
- Validate key functionality
- Check expiry warnings

### Monthly
- Review audit logs
- Test recovery procedures
- Verify backup integrity

### Annually
- Rotate subkeys
- Review and update procedures
- Test complete disaster recovery

### 2-3 Years
- Consider master key renewal
- Review cryptographic standards
- Update hardware tokens if needed

## Emergency Contacts

Document and maintain:
- Certificate Authority contacts
- Key escrow procedures (if applicable)
- Emergency procedure documentation locations
- Contact information for trusted parties who can verify identity

## Tools and Dependencies

### Required Software
- GPG 2.2+ with support for hardware tokens
- Cryptsetup for LUKS encryption
- Paperkey for paper backups
- Secure delete utilities (shred, wipe)

### Hardware Requirements
- FIPS-140 Level 2+ compliant USB drives
- Hardware security tokens (YubiKey 5, etc.)
- Air-gapped system for master key operations
- Secure printer for paper backups

### Documentation
- Keep printed copies of this playbook
- Maintain offline documentation of procedures
- Document all key IDs and fingerprints
- Maintain contact lists for key distribution
