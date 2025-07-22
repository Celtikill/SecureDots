# GPG SSH Authentication Setup and Management

## Overview
This guide covers setting up SSH authentication using your GPG authentication key stored on a hardware security card (YubiKey, etc.). This eliminates the need for separate SSH keys and provides hardware-backed authentication.

## Prerequisites
- GPG authentication subkey on hardware card (from main playbook)
- FIPS-140 USB drive with .gnupg directory
- GPG agent configured for SSH support
- Hardware security card (YubiKey, etc.)

## Architecture

```
Hardware Card (YubiKey)
├── GPG Authentication Subkey
│   └── Used for SSH authentication
├── SSH Public Key (derived from GPG auth key)
│   └── Distributed to SSH servers
└── PIN Protection
    └── Required for each authentication
```

## Initial Setup

### Step 1: Enable SSH Support in GPG Agent

1. **Update GPG Agent Configuration**
   ```bash
   # Edit ~/.gnupg/gpg-agent.conf on your FIPS-140 USB drive
   export GNUPGHOME=/mnt/gpg-vault/.gnupg
   
   cat >> $GNUPGHOME/gpg-agent.conf << 'EOF'
   
   # SSH support configuration
   enable-ssh-support
   
   # SSH key caching (set to 0 for hardware keys)
   default-cache-ttl-ssh 0
   max-cache-ttl-ssh 0
   
   # For hardware keys: always require PIN/touch
   no-allow-external-cache
   
   # SSH socket location (optional, for custom location)
   # ssh-socket /run/user/1000/gnupg/S.gpg-agent.ssh
   EOF
   ```

2. **Restart GPG Agent**
   ```bash
   # Kill existing agent
   gpgconf --kill gpg-agent
   
   # Start new agent with SSH support
   gpg-connect-agent updatestartuptty /bye
   
   # Verify SSH support is enabled
   gpg-connect-agent 'getinfo ssh_socket_name' /bye
   ```

### Step 2: Configure Shell Environment

1. **Update Your .zshrc**
   
   Add this to your existing `.zshrc` (the one from your documents):
   
   ```bash
   # ===== GPG SSH Authentication Setup =====
   # Configure SSH to use GPG agent for authentication
   
   setup_gpg_ssh() {
       # Only set up SSH if GPG vault is mounted and hardware key present
       if [[ -n "$GNUPGHOME" ]] && [[ -d "$GNUPGHOME" ]]; then
           # Get GPG agent SSH socket
           local ssh_socket
           ssh_socket=$(gpg-connect-agent 'getinfo ssh_socket_name' /bye 2>/dev/null | head -1)
           
           if [[ -n "$ssh_socket" ]] && [[ -S "$ssh_socket" ]]; then
               export SSH_AUTH_SOCK="$ssh_socket"
               
               # Verify hardware card is available
               if gpg --card-status &>/dev/null; then
                   export GPG_SSH_ENABLED=true
                   echo "✅ GPG SSH authentication enabled"
                   
                   # Show available SSH keys
                   ssh-add -L &>/dev/null && echo "📋 SSH public key available"
               else
                   echo "⚠️  GPG card not detected for SSH authentication"
                   export GPG_SSH_ENABLED=false
               fi
           else
               echo "⚠️  GPG agent SSH socket not available"
               export GPG_SSH_ENABLED=false
           fi
       fi
   }
   
   # Function to show SSH status
   ssh_status() {
       echo "=== SSH Authentication Status ==="
       echo "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-not set}"
       echo "GPG_SSH_ENABLED: ${GPG_SSH_ENABLED:-false}"
       echo
       
       if [[ "$GPG_SSH_ENABLED" == "true" ]]; then
           echo "Available SSH identities:"
           ssh-add -l 2>/dev/null || echo "No identities available"
           echo
           
           echo "SSH public key:"
           ssh-add -L 2>/dev/null || echo "Public key not available"
           echo
           
           echo "GPG authentication key:"
           gpg --list-keys --with-keygrip | grep -A1 "\[A\]" || echo "No auth key found"
       else
           echo "GPG SSH authentication not active"
       fi
   }
   
   # Function to restart GPG SSH
   gpg_ssh_restart() {
       echo "Restarting GPG agent for SSH..."
       gpgconf --kill gpg-agent
       gpg-connect-agent updatestartuptty /bye >/dev/null
       setup_gpg_ssh
   }
   
   # Auto-setup when GPG vault is mounted
   if [[ -n "$GNUPGHOME" ]] && [[ -d "$GNUPGHOME" ]]; then
       setup_gpg_ssh
   fi
   ```

2. **Source Updated Configuration**
   ```bash
   source ~/.zshrc
   ```

### Step 3: Extract SSH Public Key

1. **Get SSH Public Key from GPG**
   ```bash
   # Method 1: Using ssh-add (if GPG agent is running)
   ssh-add -L
   
   # Method 2: Extract from GPG directly
   gpg --export-ssh-key YOUR_KEY_ID
   
   # Method 3: Using keygrip (more reliable)
   # First, get the keygrip of your auth subkey
   gpg --list-keys --with-keygrip YOUR_KEY_ID
   
   # Look for the keygrip associated with [A] (authentication)
   # Then extract the SSH key using the keygrip
   gpg --export-ssh-key YOUR_KEYGRIP
   ```

2. **Save SSH Public Key**
   ```bash
   # Save to file for distribution
   ssh-add -L > ~/.ssh/id_gpg.pub
   
   # Or save directly from GPG
   gpg --export-ssh-key YOUR_KEY_ID > ~/.ssh/id_gpg.pub
   
   # Verify the key format
   cat ~/.ssh/id_gpg.pub
   # Should show: ssh-rsa AAAAB3... or ssh-ed25519 AAAAC3...
   ```

### Step 4: Test Local SSH Setup

1. **Verify SSH Agent Communication**
   ```bash
   # Check SSH agent socket
   echo $SSH_AUTH_SOCK
   
   # List available identities
   ssh-add -l
   
   # Show public keys
   ssh-add -L
   
   # Test signing operation (requires PIN/touch)
   echo "test" | ssh-keygen -Y sign -f /dev/stdin -n test
   ```

2. **Test GPG Card Interaction**
   ```bash
   # Verify card status
   gpg --card-status
   
   # Test authentication (will prompt for PIN/touch)
   ssh-add -T ~/.ssh/id_gpg.pub
   ```

## Server Configuration

### Step 1: Distribute Public Key to Servers

1. **Using ssh-copy-id**
   ```bash
   # Copy key to remote server
   ssh-copy-id -i ~/.ssh/id_gpg.pub user@server.example.com
   
   # Or manually specify the key
   ssh-add -L | ssh user@server.example.com 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
   ```

2. **Manual Installation**
   ```bash
   # On remote server, add to authorized_keys
   echo "ssh-rsa AAAAB3NzaC1yc2E... your-comment" >> ~/.ssh/authorized_keys
   
   # Set proper permissions
   chmod 600 ~/.ssh/authorized_keys
   chmod 700 ~/.ssh
   ```

3. **Using Configuration Management**
   ```yaml
   # Ansible example
   - name: Add GPG SSH key
     authorized_key:
       user: "{{ ansible_user }}"
       key: "{{ gpg_ssh_public_key }}"
       comment: "GPG Hardware Key"
   ```

### Step 2: Test SSH Connection

1. **Basic Connection Test**
   ```bash
   # Test connection (should prompt for PIN/touch)
   ssh -v user@server.example.com
   
   # Check which key was used
   ssh -v user@server.example.com 2>&1 | grep -i "offering\|accepted"
   ```

2. **Advanced Testing**
   ```bash
   # Test with specific identity
   ssh -i ~/.ssh/id_gpg.pub user@server.example.com
   
   # Test with debug output
   ssh -vvv user@server.example.com 2>&1 | grep -i gpg
   ```

## Daily Operations

### SSH Configuration

1. **Create SSH Config File**
   ```bash
   # ~/.ssh/config
   cat > ~/.ssh/config << 'EOF'
   # GPG SSH Authentication Configuration
   
   # Default settings for all hosts
   Host *
       # Use GPG agent for authentication
       IdentitiesOnly yes
       # Don't use default SSH agent
       AddKeysToAgent no
       # Prefer GPG key authentication
       PreferredAuthentications publickey
       # Connection timeouts
       ConnectTimeout 30
       ServerAliveInterval 60
       ServerAliveCountMax 3
   
   # Specific server configurations
   Host production-server
       HostName prod.example.com
       User admin
       Port 22
       # Force GPG key usage
       IdentitiesOnly yes
       
   Host development-server
       HostName dev.example.com
       User developer
       Port 2222
       
   # Bastion/jump host configuration
   Host bastion
       HostName bastion.example.com
       User jumpuser
       # Use GPG key for bastion
       IdentitiesOnly yes
       
   Host internal-server
       HostName 10.0.1.100
       User admin
       # Connect through bastion
       ProxyJump bastion
   EOF
   
   chmod 600 ~/.ssh/config
   ```

### PIN Management

1. **PIN Entry Configuration**
   ```bash
   # For remote/SSH sessions, ensure curses pinentry
   if [[ -n "$SSH_CONNECTION" ]]; then
       export PINENTRY_USER_DATA="USE_CURSES=1"
   fi
   
   # Test PIN entry
   echo GETPIN | gpg-connect-agent
   ```

2. **PIN Caching Policies**
   ```bash
   # Check current PIN cache settings
   gpg-connect-agent 'getinfo ssh_socket_name' /bye
   
   # For zero caching (always require PIN):
   # default-cache-ttl-ssh 0
   # max-cache-ttl-ssh 0
   
   # For limited caching (e.g., 5 minutes):
   # default-cache-ttl-ssh 300
   # max-cache-ttl-ssh 300
   ```

### Key Management Functions

Add these functions to your `.zshrc`:

```bash
# ===== GPG SSH Management Functions =====

# Show SSH key fingerprint
ssh_fingerprint() {
    if [[ "$GPG_SSH_ENABLED" == "true" ]]; then
        local pubkey=$(ssh-add -L 2>/dev/null)
        if [[ -n "$pubkey" ]]; then
            echo "$pubkey" | ssh-keygen -lf -
            echo "$pubkey" | ssh-keygen -E md5 -lf -
        else
            echo "No SSH public key available"
        fi
    else
        echo "GPG SSH not enabled"
    fi
}

# Test SSH connection with debugging
ssh_test() {
    local host="$1"
    if [[ -z "$host" ]]; then
        echo "Usage: ssh_test <hostname>"
        return 1
    fi
    
    echo "Testing SSH connection to $host..."
    echo "Using GPG SSH key: $(ssh_fingerprint | head -1)"
    echo
    
    ssh -v -o ConnectTimeout=10 "$host" echo "SSH test successful" 2>&1 | \
        grep -E "(debug1:|Offering|Accepted|Failed)"
}

# Add SSH key to multiple servers
ssh_deploy_key() {
    local servers=("$@")
    if [[ ${#servers[@]} -eq 0 ]]; then
        echo "Usage: ssh_deploy_key server1 [server2 ...]"
        return 1
    fi
    
    local pubkey=$(ssh-add -L 2>/dev/null | head -1)
    if [[ -z "$pubkey" ]]; then
        echo "No SSH public key available from GPG"
        return 1
    fi
    
    echo "Deploying GPG SSH key to servers..."
    echo "Key fingerprint: $(echo "$pubkey" | ssh-keygen -lf -)"
    echo
    
    for server in "${servers[@]}"; do
        echo "Deploying to $server..."
        if echo "$pubkey" | ssh "$server" 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'; then
            echo "✅ Successfully deployed to $server"
        else
            echo "❌ Failed to deploy to $server"
        fi
    done
}

# Remove SSH key from servers
ssh_remove_key() {
    local servers=("$@")
    if [[ ${#servers[@]} -eq 0 ]]; then
        echo "Usage: ssh_remove_key server1 [server2 ...]"
        return 1
    fi
    
    local pubkey=$(ssh-add -L 2>/dev/null | head -1)
    if [[ -z "$pubkey" ]]; then
        echo "No SSH public key available from GPG"
        return 1
    fi
    
    # Extract the key part (without comment)
    local keypart=$(echo "$pubkey" | awk '{print $1 " " $2}')
    
    echo "Removing GPG SSH key from servers..."
    echo "Key fingerprint: $(echo "$pubkey" | ssh-keygen -lf -)"
    echo
    
    for server in "${servers[@]}"; do
        echo "Removing from $server..."
        if ssh "$server" "grep -v '$keypart' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys"; then
            echo "✅ Successfully removed from $server"
        else
            echo "❌ Failed to remove from $server"
        fi
    done
}

# Audit SSH key usage
ssh_audit() {
    echo "=== SSH Key Audit ==="
    echo "Timestamp: $(date)"
    echo
    
    echo "GPG Card Status:"
    gpg --card-status | grep -E "(Reader|Application|Version|Serial|Name|URL|Signature key|Encryption key|Authentication key)"
    echo
    
    echo "SSH Configuration:"
    ssh_status
    echo
    
    echo "SSH Key Fingerprint:"
    ssh_fingerprint
    echo
    
    echo "Recent SSH Usage (from auth.log):"
    if [[ -f /var/log/auth.log ]]; then
        sudo grep -i "ssh.*Accepted publickey" /var/log/auth.log | tail -5
    elif [[ -f /var/log/secure ]]; then
        sudo grep -i "ssh.*Accepted publickey" /var/log/secure | tail -5
    else
        echo "No SSH logs accessible"
    fi
}
```

## Security Considerations

### PIN Policy

1. **Hardware Token PIN Management**
   ```bash
   # Change User PIN (required for SSH auth)
   gpg --change-pin
   
   # Change Admin PIN (for token management)
   gpg --card-edit
   # > admin
   # > passwd
   # > 3 (Admin PIN)
   ```

2. **PIN Complexity Requirements**
   - User PIN: 6-127 characters
   - Admin PIN: 8-127 characters
   - Use strong, unique PINs
   - Consider using passphrases instead of numeric PINs

### Touch Policy

1. **Configure Touch Requirements**
   ```bash
   # Some cards support touch policy configuration
   # Check if your card supports touch requirements
   gpg --card-edit
   # > admin
   # > factory-reset  # CAREFUL: This erases the card!
   
   # During key generation or import, some cards allow:
   # Touch policy: always require touch for authentication
   ```

### Access Logging

1. **Enable SSH Logging**
   ```bash
   # Add to ~/.ssh/config
   cat >> ~/.ssh/config << 'EOF'
   
   # Logging configuration
   Host *
       LogLevel VERBOSE
       # Log to custom file
       UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts_gpg
   EOF
   ```

2. **Monitor GPG Agent Activity**
   ```bash
   # Enable GPG agent logging
   cat >> $GNUPGHOME/gpg-agent.conf << 'EOF'
   
   # Debug logging (enable when troubleshooting)
   # debug-level basic
   # log-file ~/.gnupg/gpg-agent.log
   EOF
   ```

## Troubleshooting

### Common Issues

1. **SSH Agent Not Using GPG**
   ```bash
   # Check environment variables
   echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
   echo "GPG_TTY: $GPG_TTY"
   
   # Restart GPG agent
   gpgconf --kill gpg-agent
   gpg-connect-agent updatestartuptty /bye
   
   # Re-source configuration
   source ~/.zshrc
   ```

2. **PIN Entry Issues**
   ```bash
   # For SSH sessions, ensure curses pinentry
   export PINENTRY_USER_DATA="USE_CURSES=1"
   
   # Test PIN entry
   echo GETPIN | gpg-connect-agent
   
   # Check pinentry program
   which pinentry-curses
   ```

3. **Card Not Detected**
   ```bash
   # Check card status
   gpg --card-status
   
   # Restart card services
   sudo systemctl restart pcscd
   
   # Check USB connection
   lsusb | grep -i yubikey
   ```

4. **Permission Errors**
   ```bash
   # Fix .gnupg permissions
   chmod 700 $GNUPGHOME
   chmod 600 $GNUPGHOME/*
   
   # Fix SSH directory permissions
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/config ~/.ssh/authorized_keys
   ```

### Debugging Commands

```bash
# Debug SSH connection
ssh -vvv user@server 2>&1 | grep -E "(gpg|agent|card|pin)"

# Check GPG agent processes
ps aux | grep gpg-agent

# Verify socket permissions
ls -la $(gpg-connect-agent 'getinfo ssh_socket_name' /bye | head -1)

# Test key operations
ssh-add -T ~/.ssh/id_gpg.pub

# Check hardware token
gpg-connect-agent 'SCD GETINFO card_list' /bye
```

## Backup and Recovery

### SSH Public Key Backup

```bash
# Backup SSH public key
mkdir -p ~/.backup/ssh-keys
ssh-add -L > ~/.backup/ssh-keys/gpg-ssh-public-$(date +%Y%m%d).key

# Backup with GPG key ID for reference
GPG_KEY_ID=$(gpg --list-keys --keyid-format LONG | grep pub | awk '{print $2}' | cut -d'/' -f2)
ssh-add -L > ~/.backup/ssh-keys/gpg-ssh-${GPG_KEY_ID}.pub
```

### Server Inventory

```bash
# Maintain list of servers using your GPG SSH key
cat > ~/.backup/ssh-servers.txt << 'EOF'
# Servers using GPG SSH authentication
# Format: hostname:port:username:date_added

production.example.com:22:admin:2024-01-15
development.example.com:2222:developer:2024-01-15
bastion.example.com:22:jumpuser:2024-01-20
EOF
```

### Recovery Procedures

1. **Lost Hardware Token**
   ```bash
   # 1. Generate new authentication subkey (on air-gapped system)
   # 2. Move to new hardware token
   # 3. Extract new SSH public key
   # 4. Update all servers with new key
   # 5. Remove old key from servers
   ```

2. **Compromised Token**
   ```bash
   # Immediate actions:
   # 1. Revoke authentication subkey
   # 2. Remove SSH keys from all servers
   # 3. Generate new authentication subkey
   # 4. Deploy new keys to servers
   ```

## Integration with Your Existing Setup

The SSH authentication integrates seamlessly with your existing GPG setup:

1. **Uses existing FIPS-140 USB drive** for .gnupg directory
2. **Leverages existing hardware card** with authentication subkey
3. **Works with existing GPG agent configuration** in your .zshrc
4. **Integrates with existing key management procedures**

To enable, simply:
1. Add the SSH configuration to your existing `.zshrc`
2. Update your GPG agent configuration
3. Extract and deploy your SSH public key
4. Test connections

This provides hardware-backed SSH authentication that's consistent with your GPG security model.
