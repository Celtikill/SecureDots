# Security Claims Verification Guide

**Independent verification procedures for SecureDots security claims**

This guide enables you to independently verify the security properties of SecureDots rather than simply trusting our documentation. Security through transparency.

---

## Table of Contents

- [Quick Verification Script](#quick-verification-script)
- [Claim 1: Zero Plaintext Credentials](#claim-1-zero-plaintext-credentials)
- [Claim 2: Hardware Security Key Support](#claim-2-hardware-security-key-support)
- [Claim 3: Comprehensive Exposure Prevention](#claim-3-comprehensive-exposure-prevention)
- [Claim 4: Audit Trail Capability](#claim-4-audit-trail-capability)
- [Claim 5: Defense in Depth](#claim-5-defense-in-depth)
- [Compliance Mapping](#compliance-mapping)
- [Automated Verification](#automated-verification)

---

## Quick Verification Script

Run all checks at once:

```bash
#!/bin/bash
# quick-verify.sh - Run all security verifications

echo "=== SecureDots Security Verification ==="
echo "Running all security checks..."
echo ""

# Download the full verification script
curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/scripts/verify-security.sh | bash

# Or if you've cloned the repo:
# bash ~/dotfiles/scripts/verify-security.sh
```

---

## Claim 1: Zero Plaintext Credentials

### Security Claim

**Statement**: "No AWS credentials or other secrets are stored in plaintext anywhere on the system."

### Independent Verification

#### Test 1: Search for AWS Access Keys

```bash
# Search for AWS access key patterns in .aws directory
grep -r "AKIA[A-Z0-9]\{16\}" ~/.aws 2>/dev/null

# Expected result: No matches, or only in credential-process.sh as variable names
# ✅ PASS: No output or only variable references in scripts
# ❌ FAIL: If actual access keys are found
```

**Why this works**: AWS access keys follow the pattern `AKIA` followed by 16 alphanumeric characters. If we find this pattern in readable files, credentials are exposed.

#### Test 2: Check for Secret Key Patterns

```bash
# Search for common secret patterns
grep -ri "aws_secret" ~/.aws 2>/dev/null | grep -v ".sh"

# Expected result: Empty (only references in shell scripts, not actual secrets)
# ✅ PASS: No output or only in .sh files
# ❌ FAIL: If secret values are found in config files
```

#### Test 3: Verify All Password Store Files Are Encrypted

```bash
# Find any non-encrypted files in password store
find ~/.password-store -type f ! -name "*.gpg" ! -name ".gpg-id" ! -path "*/.git/*" 2>/dev/null

# Expected result: Empty (no unencrypted credential files)
# ✅ PASS: No output
# ❌ FAIL: If any files are listed
```

#### Test 4: Verify GPG Encryption

```bash
# Check that all credential files are actually GPG encrypted
for f in ~/.password-store/**/*.gpg(N); do
    if ! file "$f" | grep -q "GPG encrypted data"; then
        echo "❌ Not encrypted: $f"
    fi
done

# Alternative for bash:
find ~/.password-store -name "*.gpg" -exec file {} \; | grep -v "GPG encrypted data"

# Expected result: Empty (all .gpg files are encrypted)
# ✅ PASS: No output
# ❌ FAIL: If any files are not GPG encrypted
```

#### Test 5: Check AWS Credentials File

```bash
# Verify credentials file doesn't exist or is empty
if [ -f ~/.aws/credentials ]; then
    echo "⚠️ WARNING: ~/.aws/credentials exists"
    if [ -s ~/.aws/credentials ]; then
        echo "❌ FAIL: Credentials file contains data"
        wc -l ~/.aws/credentials
    else
        echo "✅ PASS: Credentials file is empty"
    fi
else
    echo "✅ PASS: No credentials file exists"
fi
```

### Verification Checklist

- [ ] No AWS access keys found in plaintext
- [ ] No secret keys found in plaintext
- [ ] All pass files are encrypted
- [ ] No plaintext credentials file exists
- [ ] Credential process uses encrypted storage

**Result Interpretation**:
- **All ✅**: Claim verified - zero plaintext credentials
- **Any ❌**: SECURITY ISSUE - report immediately

---

## Claim 2: Hardware Security Key Support

### Security Claim

**Statement**: "System supports hardware-backed GPG operations with YubiKey or similar devices."

### Independent Verification

#### Test 1: Detect Hardware Token

```bash
# Check if GPG detects a hardware card
gpg --card-status 2>&1

# Expected output: Card details including serial number, key information
# ✅ PASS: Shows "Reader", "Application ID", key stubs
# ❌ FAIL: "gpg: selecting card failed" or "Card not present"
```

#### Test 2: Verify Keys Are Stubs (Not Actual Keys)

```bash
# List secret keys with keygrip info
gpg --list-secret-keys --with-keygrip

# Expected: Keys should show "Card serial no. = ..." instead of actual key material
# ✅ PASS: Shows "Card serial no." or "ssb>" (key stub)
# ❌ FAIL: Shows "ssb" without ">" (actual key on disk)
```

**Key indicator**: The `>` symbol after `ssb` means it's a stub pointing to a hardware token.

#### Test 3: Verify Operations Require PIN/Touch

```bash
# Test signing (should prompt for PIN or touch)
echo "test" | gpg --clearsign

# Expected behavior: Prompts for PIN or requires hardware key touch
# ✅ PASS: PIN prompt appears or hardware key blinks
# ❌ FAIL: Signs without any interaction
```

#### Test 4: Check USB Hardware Detection

```bash
# On Linux: Check USB devices
lsusb | grep -i "yubikey\|nitrokey\|ledger"

# On macOS: Check system profiler
system_profiler SPUSBDataType | grep -A10 -i "yubikey\|nitrokey"

# Expected: Hardware token detected
# ✅ PASS: Device listed
# ❌ FAIL: No hardware security device found
```

### Verification Checklist

- [ ] Hardware card detected by GPG
- [ ] GPG keys are stubs (not full keys)
- [ ] Operations require PIN/touch
- [ ] USB hardware device present
- [ ] Private keys NOT stored on disk

**Result Interpretation**:
- **All ✅**: Claim verified - hardware security enabled
- **Any ❌**: Check hardware connection or setup

---

## Claim 3: Comprehensive Exposure Prevention

### Security Claim

**Statement**: "Multiple layers prevent accidental credential exposure through version control, symbolic links, and file permissions."

### Independent Verification

#### Test 1: Stow Ignore Patterns

```bash
# Check stow ignore file exists and protects secrets
if [ -f .stow-local-ignore ]; then
    echo "✅ Stow ignore file exists"

    # Check for key patterns
    grep -E "(credentials|password|secret|token|\.aws/credentials|\.password-store)" .stow-local-ignore

    # Expected: Multiple ignore patterns found
    # ✅ PASS: Sensitive patterns present
    # ❌ FAIL: Missing critical patterns
else
    echo "❌ FAIL: No .stow-local-ignore file"
fi
```

#### Test 2: Git Ignore Patterns

```bash
# Check gitignore protects secrets
if [ -f .gitignore ]; then
    echo "✅ .gitignore exists"

    grep -E "(credentials|password-store|secret|token|\.aws/credentials)" .gitignore

    # Expected: Comprehensive ignore patterns
    # ✅ PASS: Sensitive patterns present
    # ❌ FAIL: Missing critical patterns
else
    echo "⚠️ WARNING: No .gitignore file"
fi
```

#### Test 3: Git Tracking Check

```bash
# Verify git doesn't track sensitive files
cd ~/dotfiles
git ls-files | grep -E "(credentials|password|secret|token|\.env)"

# Expected result: Empty (no sensitive files in git)
# ✅ PASS: No output
# ❌ FAIL: Sensitive files are tracked
```

#### Test 4: Git History Scan

```bash
# Check git history for accidentally committed secrets
cd ~/dotfiles
git log --all --full-history --source --pretty=format: --name-only | grep -E "(credentials|password|secret|token|AKIA)"

# Expected result: Empty (no sensitive files ever committed)
# ✅ PASS: No sensitive file names in history
# ⚠️  WARNING: If found, check if secrets in those files
```

#### Test 5: File Permissions

```bash
# Check password store permissions
if [ -d ~/.password-store ]; then
    ls -la ~/.password-store | head -5

    # Expected: drwx------ (700) for directory
    # ✅ PASS: Only owner can access
    # ❌ FAIL: Group or others have permissions
fi

# Check .gnupg permissions
if [ -d ~/.gnupg ]; then
    ls -ld ~/.gnupg

    # Expected: drwx------ (700)
    # ✅ PASS: Only owner can access
    # ❌ FAIL: Incorrect permissions
fi
```

### Verification Checklist

- [ ] Stow ignores sensitive files
- [ ] Git ignores sensitive files
- [ ] No sensitive files tracked in git
- [ ] No sensitive files in git history
- [ ] Correct file permissions on secrets

**Result Interpretation**:
- **All ✅**: Claim verified - comprehensive protection
- **Any ❌**: Remediate immediately

---

## Claim 4: Audit Trail Capability

### Security Claim

**Statement**: "All credential access and modifications are logged for audit purposes."

### Independent Verification

#### Test 1: Pass Git Integration

```bash
# Check if pass uses git for versioning
if [ -d ~/.password-store/.git ]; then
    echo "✅ Pass git integration enabled"

    # View audit trail
    cd ~/.password-store
    git log --oneline | head -10

    # Expected: Commits for each pass operation
    # ✅ PASS: Git log shows credential operations
    # ❌ FAIL: No git repository
else
    echo "❌ FAIL: Pass not using git for audit trail"
fi
```

#### Test 2: View Pass Audit Trail

```bash
# Show what credentials were added/modified and when
cd ~/.password-store
git log --pretty=format:"%h %ai %s" | head -20

# Expected: Timestamped log of credential operations
# ✅ PASS: Shows dates and operations
# ❌ FAIL: Empty or no git log
```

#### Test 3: Check GPG Logging (Optional)

```bash
# Check if GPG logging is configured
if grep -q "log-file" ~/.gnupg/gpg-agent.conf 2>/dev/null; then
    echo "✅ GPG logging enabled"
    log_file=$(grep "log-file" ~/.gnupg/gpg-agent.conf | awk '{print $2}')
    if [ -f "$log_file" ]; then
        echo "Log location: $log_file"
        tail -5 "$log_file"
    fi
else
    echo "ℹ️ INFO: GPG logging not enabled (optional feature)"
fi
```

#### Test 4: Credential Lifecycle Tracing

```bash
# Trace full lifecycle of a credential
cd ~/.password-store
echo "History for aws/dev:"
git log --follow --oneline -- aws/dev.gpg

# Expected: Shows when created, modified, deleted
# ✅ PASS: Complete history visible
# ℹ️ INFO: If no history, credential never modified
```

### Verification Checklist

- [ ] Pass uses git for versioning
- [ ] Git log shows credential operations
- [ ] Timestamps available for audit
- [ ] Can trace credential lifecycle
- [ ] Optional: GPG operations logged

**Result Interpretation**:
- **All ✅**: Claim verified - audit trail functional
- **Partial**: Basic audit available, enhanced optional

---

## Claim 5: Defense in Depth

### Security Claim

**Statement**: "Multiple overlapping security controls protect credentials even if one layer fails."

### Independent Verification

#### Test 1: Layer Inventory

```bash
# Document all security layers present
echo "Security Layers Inventory:"
echo ""

# Layer 1: Encryption at rest
if [ -d ~/.password-store ]; then
    echo "✅ Layer 1: GPG encryption of credentials"
else
    echo "❌ Layer 1: MISSING"
fi

# Layer 2: Hardware security (optional)
if gpg --card-status &>/dev/null; then
    echo "✅ Layer 2: Hardware security key detected"
else
    echo "ℹ️ Layer 2: Software-only (no hardware key)"
fi

# Layer 3: Credential process (not plaintext config)
if grep -q "credential_process" ~/.aws/config 2>/dev/null; then
    echo "✅ Layer 3: Credential process (no plaintext in config)"
else
    echo "⚠️ Layer 3: Check AWS config"
fi

# Layer 4: Git ignore
if [ -f ~/dotfiles/.gitignore ]; then
    echo "✅ Layer 4: Git ignore protections"
else
    echo "❌ Layer 4: MISSING"
fi

# Layer 5: Stow ignore
if [ -f ~/dotfiles/.stow-local-ignore ]; then
    echo "✅ Layer 5: Stow ignore protections"
else
    echo "❌ Layer 5: MISSING"
fi

# Layer 6: File permissions
perms=$(stat -c "%a" ~/.password-store 2>/dev/null || stat -f "%A" ~/.password-store 2>/dev/null)
if [ "$perms" = "700" ] || [ "$perms" = "0700" ]; then
    echo "✅ Layer 6: Correct file permissions"
else
    echo "⚠️ Layer 6: Permissions may be too open ($perms)"
fi
```

#### Test 2: Single Point of Failure Analysis

```bash
# Verify no single failure exposes credentials

echo "Single Point of Failure Tests:"
echo ""

# Test: Git repo leak doesn't expose credentials
echo "Test: If git repo is exposed..."
cd ~/dotfiles
if git ls-files | grep -qE "credentials|password"; then
    echo "❌ FAIL: Git tracks sensitive files"
else
    echo "✅ PASS: Git doesn't track credentials"
fi

# Test: Config file leak doesn't expose credentials
echo "Test: If ~/.aws/config is exposed..."
if grep -q "aws_access_key_id" ~/.aws/config 2>/dev/null; then
    echo "❌ FAIL: Config contains plaintext credentials"
else
    echo "✅ PASS: Config uses credential process"
fi

# Test: Disk access without GPG key
echo "Test: If attacker has disk but no GPG key..."
if file ~/.password-store/**/*.gpg | grep -qv "GPG encrypted data"; then
    echo "❌ FAIL: Unencrypted credential files exist"
else
    echo "✅ PASS: All credentials encrypted"
fi
```

### Verification Checklist

- [ ] Multiple security layers present
- [ ] GPG encryption enabled
- [ ] Credential process configured
- [ ] Version control protections active
- [ ] File permissions restrictive
- [ ] No single point of failure

**Result Interpretation**:
- **All ✅**: Claim verified - defense in depth implemented
- **Hardware key optional**: Still secure without it

---

## Compliance Mapping

These verifications map to common compliance frameworks:

| Verification | SOC 2 | PCI DSS | HIPAA | GDPR | ISO 27001 |
|--------------|-------|---------|-------|------|-----------|
| No plaintext credentials | CC6.1 | 3.4 | §164.312(a)(2)(iv) | Art. 32 | A.9.4.1 |
| Encrypted storage | CC6.1 | 3.4, 8.2.1 | §164.312(a)(2)(iv) | Art. 32 | A.10.1.1 |
| Hardware key support | CC6.2 | 8.3 | §164.312(a)(2)(i) | Art. 32 | A.9.4.3 |
| Access controls | CC6.2 | 7.1, 7.2 | §164.308(a)(4) | Art. 32 | A.9.2.1 |
| Audit trails | CC4.1 | 10.2 | §164.312(b) | Art. 30 | A.12.4.1 |
| Defense in depth | CC5.1 | 1.3.5 | §164.308(a)(1) | Art. 32 | A.13.1.1 |
| Exposure prevention | CC6.6 | 9.5 | §164.308(a)(3) | Art. 32 | A.8.2.3 |

### Compliance Verification Commands

```bash
# Generate compliance evidence report
cat > ~/security-verification-report.txt << EOF
Security Verification Report
Generated: $(date)
System: $(uname -a)

SOC 2 CC6.1 - Data Encryption:
$(file ~/.password-store/**/*.gpg | wc -l) encrypted credential files

PCI DSS 3.4 - Encryption of cardholder data:
$(find ~/.password-store -name "*.gpg" | wc -l) files encrypted with GPG

HIPAA §164.312(a)(2)(iv) - Encryption:
Verified: $(if [ $(find ~/.password-store -type f ! -name "*.gpg" ! -name ".gpg-id" ! -path "*/.git/*" | wc -l) -eq 0 ]; then echo "PASS"; else echo "FAIL"; fi)

GDPR Art. 32 - Security of processing:
Access control permissions: $(stat -c "%a" ~/.password-store 2>/dev/null || stat -f "%A" ~/.password-store 2>/dev/null)

Audit trail: $(if [ -d ~/.password-store/.git ]; then echo "Enabled"; else echo "Not configured"; fi)
EOF

echo "Compliance report generated: ~/security-verification-report.txt"
cat ~/security-verification-report.txt
```

---

## Automated Verification

### Complete Verification Script

Save this as `verify-security.sh`:

```bash
#!/bin/bash
# verify-security.sh - Comprehensive automated security verification

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║   SecureDots Security Verification Suite              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass_test() {
    echo "✅ $1"
    ((PASS_COUNT++))
}

fail_test() {
    echo "❌ $1"
    ((FAIL_COUNT++))
}

warn_test() {
    echo "⚠️  $1"
    ((WARN_COUNT++))
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUITE 1: Zero Plaintext Credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 1.1: Search for AWS keys
if grep -r "AKIA[A-Z0-9]\{16\}" ~/.aws 2>/dev/null | grep -v credential-process.sh | grep -q .; then
    fail_test "Found plaintext AWS access keys"
else
    pass_test "No plaintext AWS access keys found"
fi

# Test 1.2: Check encrypted storage
unencrypted=$(find ~/.password-store -type f ! -name "*.gpg" ! -name ".gpg-id" ! -path "*/.git/*" 2>/dev/null | wc -l)
if [ "$unencrypted" -eq 0 ]; then
    pass_test "All password store files encrypted"
else
    fail_test "Found $unencrypted unencrypted files in password store"
fi

# Test 1.3: Verify GPG encryption
bad_encryption=0
for f in $(find ~/.password-store -name "*.gpg" 2>/dev/null); do
    if ! file "$f" | grep -q "GPG encrypted data"; then
        ((bad_encryption++))
    fi
done
if [ "$bad_encryption" -eq 0 ]; then
    pass_test "All .gpg files are properly encrypted"
else
    fail_test "Found $bad_encryption files not properly encrypted"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUITE 2: Hardware Security (if applicable)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if gpg --card-status &>/dev/null; then
    pass_test "Hardware security card detected"

    if gpg --list-secret-keys --with-keygrip | grep -q "Card serial"; then
        pass_test "GPG keys are stubs (on hardware)"
    else
        warn_test "GPG keys may not be on hardware"
    fi
else
    warn_test "No hardware security card (software-only mode)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUITE 3: Exposure Prevention"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test 3.1: Stow ignore
if [ -f ~/dotfiles/.stow-local-ignore ]; then
    if grep -q "credentials\|password-store" ~/dotfiles/.stow-local-ignore; then
        pass_test "Stow ignore patterns configured"
    else
        fail_test "Stow ignore missing sensitive patterns"
    fi
else
    fail_test "No .stow-local-ignore file found"
fi

# Test 3.2: Git tracking
if cd ~/dotfiles 2>/dev/null; then
    if git ls-files | grep -qE "credentials|password"; then
        fail_test "Git tracks sensitive files"
    else
        pass_test "Git doesn't track sensitive files"
    fi
fi

# Test 3.3: File permissions
perms=$(stat -c "%a" ~/.password-store 2>/dev/null || stat -f "%A" ~/.password-store 2>/dev/null)
if [ "$perms" = "700" ] || [ "$perms" = "0700" ]; then
    pass_test "Password store has correct permissions (700)"
else
    warn_test "Password store permissions: $perms (should be 700)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST SUITE 4: Audit Trail"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d ~/.password-store/.git ]; then
    pass_test "Pass git integration enabled"

    commit_count=$(cd ~/.password-store && git log --oneline | wc -l)
    if [ "$commit_count" -gt 0 ]; then
        pass_test "Audit trail contains $commit_count commits"
    else
        warn_test "Git initialized but no commits yet"
    fi
else
    fail_test "Pass not using git for audit trail"
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║                  VERIFICATION SUMMARY                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Passed: $PASS_COUNT"
echo "⚠️  Warnings: $WARN_COUNT"
echo "❌ Failed: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "🎉 All critical security checks passed!"
    echo ""
    echo "Security status: VERIFIED"
    exit 0
else
    echo "🚨 Security verification failed!"
    echo ""
    echo "Please review failures above and remediate immediately."
    echo "See TROUBLESHOOTING.md for guidance."
    exit 1
fi
```

### Running the Verification

```bash
# Make script executable
chmod +x verify-security.sh

# Run verification
./verify-security.sh

# Run with detailed output
bash -x ./verify-security.sh
```

---

## Reporting Security Issues

If verification reveals security issues:

1. **For configuration issues**: See [TROUBLESHOOTING.md](docs/guides/TROUBLESHOOTING.md)
2. **For bugs**: Open an issue on GitHub (do NOT include sensitive data)
3. **For security vulnerabilities**: See [SECURITY.md](SECURITY.md) for responsible disclosure

---

## Regular Verification Schedule

**Recommended verification frequency:**

- **After initial setup**: Run full verification
- **After system changes**: Re-verify affected components
- **Monthly**: Run automated verification script
- **Before audits**: Generate compliance report

**Automate monthly verification:**

```bash
# Add to crontab (runs first day of each month)
0 9 1 * * cd ~/dotfiles && ./verify-security.sh >> ~/security-verification.log 2>&1
```

---

## Conclusion

Security through transparency means you can verify our claims independently. This guide provides the tools to validate that SecureDots implements the security properties it claims.

**Questions or concerns?** See [SECURITY.md](SECURITY.md) or open a discussion on GitHub.

**Last Updated:** Security Verification Guide
**Review Schedule:** Verify monthly or after system changes
