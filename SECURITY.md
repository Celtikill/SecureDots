# Security Policy

## Reporting Vulnerabilities

**Do not create public GitHub issues for security vulnerabilities.**

Email security issues to **celtikill@celtikill.io**. Include:
- Description of the vulnerability
- Steps to reproduce (if applicable)
- Potential impact
- Suggested mitigations (if any)

We aim to acknowledge reports within 48 hours.

For non-security bugs, use [GitHub Issues](https://github.com/yourusername/dotfiles/issues).

### Disclosure Timeline

1. **Report received** - Acknowledged within 48 hours
2. **Investigation** - Assessment within 1 week
3. **Fix development** - Patches within 2 weeks
4. **Coordinated disclosure** - Public disclosure after fix is available

## Security Model

This system encrypts all credentials using GPG via the `pass` password manager. No plaintext secrets are stored on disk.

Key security properties:
- **Encrypted at rest**: All credentials GPG-encrypted in the pass store
- **Dynamic retrieval**: Credentials decrypted only when needed by AWS CLI
- **Hardware key support**: Optional YubiKey integration for tamper-resistant keys
- **Exposure prevention**: `.stow-local-ignore` and `.gitignore` patterns prevent accidental credential commits
- **Audit trail**: `pass` git integration logs credential access

## User Responsibilities

You are responsible for:
- **Backing up GPG keys** to secure offline storage
- **Rotating credentials** regularly
- **Keeping dependencies updated** (gpg, pass, etc.)
- **Reviewing scripts** before running them

## Disclaimer

This software is provided "as-is" without warranty of any kind. Contributors are not liable for any damages arising from use, including credential exposure or security breaches. Users accept full responsibility for securing their credentials and GPG keys. See LICENSE for full terms.

---

**Last Updated:** March 2026
