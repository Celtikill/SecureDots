# Dotfiles Governance Framework

## Overview

This framework provides simple, practical governance for the secure dotfiles repository while maintaining the zero-plaintext-credential security model.

**Guiding Principles:**
- Security controls must be proportional to risk
- Processes should enhance, not hinder, productivity  
- Simplicity reduces errors and maintenance overhead
- Users should understand what they're running

---

## Change Management

### Change Types

**🔴 Security Changes**
- Credential handling modifications (.aws/credential-process.sh)
- GPG configuration changes  
- Stow ignore pattern updates
- Permission or encryption changes

**Required:** Code review + security validation + testing

**🟡 Feature Changes**
- Shell function additions/modifications
- Setup script improvements
- New platform support
- Performance optimizations

**Required:** Functional testing + documentation updates

**🟢 Documentation Changes**
- README updates
- Guide improvements  
- Comment additions
- Help text changes

**Required:** Review for accuracy

---

## Validation Process

### Before Changes
```bash
# Run validation
./validate.sh

# For security changes, also verify:
# - No credentials in debug output
# - File permissions maintained  
# - Stow patterns protect sensitive files
```

### After Changes
```bash
# Run smoke tests
./smoke-test.sh

# For security changes:
# - Test credential flow works
# - Verify no plaintext exposure
# - Check error handling
```

### Testing Requirements
- **Security changes:** Must test both success and failure scenarios
- **Feature changes:** Must test on supported platforms (macOS, Linux, WSL)
- **All changes:** Must not break existing user workflows

---

## Security Guardrails

### Non-Negotiable Requirements
1. **Zero plaintext credentials** anywhere in the system
2. **GPG encryption** for all sensitive data storage
3. **Secure file permissions** (700 for sensitive directories, 600 for files)
4. **Credential exposure prevention** via comprehensive ignore patterns

### Security Validation
```bash
# Essential security checks
grep -r "AKIA[A-Z0-9]" . --exclude-dir=.git  # No AWS keys in files
find . -name "*.gpg" -exec gpg --list-packets {} \;  # GPG files valid
./validate.sh  # All security controls working
```

### Incident Response
1. **Credential Exposure:** Immediately rotate affected credentials
2. **Security Bug:** Create private issue, patch quickly, then disclose
3. **System Failure:** Use `git revert` and restore from backups

---

## Recovery Procedures

### Quick Recovery
```bash
# Restore from git
git log --oneline -10        # Find last good commit
git revert HEAD              # Undo last change
git reset --hard HEAD~1      # Nuclear option

# Restore configuration
source ~/.zshrc              # Reload shell config
./smoke-test.sh             # Verify functionality
```

### Full System Recovery
1. **Backup restoration:** Use setup script backup directories
2. **Clean reinstall:** Re-run `./setup-simple.sh` or `./setup-secure-zsh.sh`
3. **Credential restoration:** Restore pass store from secure backup
4. **Validation:** Run full test suite to ensure functionality

---

## Quality Standards

### Code Quality
- **Shell scripts:** Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Error handling:** All scripts must handle errors gracefully
- **User feedback:** Clear success/error messages with next steps
- **Documentation:** All functions and complex logic commented

### Security Standards
- **Input validation:** All user inputs validated against allowlists
- **Path safety:** No path traversal vulnerabilities
- **Credential handling:** Debug output must never expose secrets
- **Dependency management:** Minimize external dependencies

### Documentation Standards
- **User-focused:** Written for the intended audience (developers, security teams)
- **Actionable:** Include specific commands and examples
- **Current:** Updated with every functional change
- **Accessible:** Clear language, logical structure, good examples

---

## Maintenance

### Regular Activities
- **Monthly:** Run `./validate.sh` and `./smoke-test.sh`
- **Quarterly:** Review and update documentation
- **As needed:** Security updates and dependency patches

### Performance Monitoring
- Shell startup time should remain under 1 second
- Credential retrieval should complete within 10 seconds
- Setup scripts should complete in under 10 minutes

### Success Metrics
- Zero credential exposure incidents
- User setup success rate > 95%
- Documentation accuracy (user feedback)
- System reliability (minimal support requests)

---

## Support and Escalation

### Self-Service Resources
1. **./validate.sh** - Health check and diagnostics
2. **./smoke-test.sh** - Functionality verification  
3. **TROUBLESHOOTING.md** - Common issues and solutions
4. **dotfiles_help** - Built-in help system (after setup)

### Escalation Path
1. **Functional Issues:** GitHub Issues
2. **Security Issues:** Private message to repository owner
3. **Complex Problems:** Include output from diagnostic scripts

---

**Document Version:** 2.0 (Simplified)  
**Last Updated:** July 2025  
**Review Schedule:** Quarterly or as needed

*This governance framework balances security requirements with practical usability. It replaces the previous complex framework with essential controls that actually enhance rather than hinder productivity.*