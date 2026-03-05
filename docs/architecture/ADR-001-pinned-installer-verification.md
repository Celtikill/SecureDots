# ADR-001: Pinned Installer Verification for Third-Party Scripts

**Status**: Accepted
**Date**: 2026-03-05
**Deciders**: Repository owner
**Related**: SEC-H11 (code review), SEC-H10 (vim-plug), Batch 1/2/8 remediation

---

## Context

The dotfiles setup scripts download and execute third-party installers at runtime:
- Oh My Zsh (`install.sh`) in `setup/setup-secure-zsh.sh` and `setup/install-omz.sh`
- vim-plug (`plug.vim`) in `setup/setup-simple.sh`

### Current Situation
- Installers were fetched from `master` branch via `curl | sh` pattern
- No integrity verification before execution
- Every run could pull different code without the user's knowledge

### Problem Statement
Downloading and executing scripts from mutable URLs (`master` branch) without verification is a supply chain attack vector. A compromised upstream repository or man-in-the-middle attack could inject malicious code that executes with the user's privileges.

### Research & Discovery
- OWASP CI/CD Security Cheat Sheet identifies unverified dependency downloads as a key risk
- The `curl | sh` anti-pattern is widely documented as insecure (no inspection, no rollback, no verification)
- Oh My Zsh's `install.sh` changes infrequently (pinned commit's last change was a domain rename, 2025-11-20)
- vim-plug's `plug.vim` is similarly stable

**References:**
- [OWASP CI/CD Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html)
- [Supply chain attacks on developer tools](https://attack.mitre.org/techniques/T1195/002/) (MITRE ATT&CK T1195.002)

---

## Decision

We will pin all third-party installer downloads to specific commit hashes and verify SHA-256 checksums before execution.

The pattern is: download to temp file, compute checksum, compare against known-good hash, execute only on match.

Cross-platform SHA-256 verification uses `sha256sum` (Linux) with `shasum -a 256` (macOS) fallback. If neither is available, a warning is emitted but execution proceeds (degraded security, not blocked).

### Scope of Decision
- **Included**: All third-party scripts downloaded and executed by setup scripts
- **Excluded**: Git clone operations (e.g., Pure theme), which have their own integrity mechanisms
- **Excluded**: Oh My Zsh self-update (`omz update`), which is a user-initiated action post-install

---

## Rationale

### Why This Approach

1. **Supply chain integrity**: Ensures the code we execute matches what was reviewed and approved
   - Impact: Eliminates an entire class of supply chain attacks

2. **Deterministic builds**: Same commit + hash = same installer code every time
   - Context: Critical for a security-focused dotfiles repo that manages credentials

3. **Fail-safe design**: Checksum mismatch produces a clear error and halts execution rather than running unknown code
   - Impact: Prevents silent compromise

### Why NOT Alternative Approaches

**Option A: Continue using `master` branch (status quo)**
- **Considered because**: Zero maintenance, always latest version
- **Rejected because**: No integrity verification, vulnerable to upstream compromise
- **Trade-off**: Convenience over security
- **When it would be better**: Throwaway environments where security is irrelevant

**Option B: Git submodules for third-party tools**
- **Considered because**: Full version control of dependencies
- **Rejected because**: Adds complexity to the repo structure, submodules are notoriously fragile, overkill for single-file downloads
- **Trade-off**: Maximum control but high maintenance burden
- **When it would be better**: Larger projects with many pinned dependencies

**Option C: Checksum verification with warning only (non-blocking)**
- **Considered because**: Less friction, doesn't block setup on hash mismatch
- **Rejected because**: Defeats the purpose — users will ignore warnings and run compromised code
- **Trade-off**: Usability over security
- **When it would be better**: If the pinned scripts changed frequently and hash updates lagged

### Decision Drivers
1. **Security posture**: This repo manages AWS credentials via GPG — the setup scripts are a high-value target
2. **Low maintenance cost**: Pinned scripts change infrequently (months/years between updates)
3. **Alignment with project values**: The repo already enforces encryption, input validation, and credential isolation

---

## Consequences

### Positive Consequences

1. **Eliminates supply chain risk**: Installer code is verified before execution
   - Metric: Zero unverified script executions during setup
   - Timeline: Immediate

2. **Audit trail**: Pinned commits are documented with dates, making it clear what version was reviewed
   - Metric: Each pinned dependency has a commit hash and date in the source

3. **Deterministic setup**: Same script produces same results regardless of upstream changes
   - Metric: Setup behavior is reproducible across time

### Negative Consequences

1. **Manual hash updates required**: When upstream fixes bugs or security issues in installers, someone must update the commit hash and recompute the checksum
   - Impact: Repository maintainer
   - Acceptable because: These scripts change infrequently and the update process is straightforward

2. **Stale installer risk**: If the pinned version has a bug that's fixed upstream, users won't get the fix automatically
   - Mitigation: Periodic review (quarterly) of pinned commits against upstream
   - Acceptable because: OMZ updates itself post-install via `omz update`; only the installer is pinned

3. **Hard failure on mismatch**: Setup halts if the checksum doesn't match (e.g., if the pinned commit is force-pushed away)
   - Mitigation: Clear error message with explanation; user can manually update the hash
   - Acceptable because: Failing safe is better than executing unknown code

### Risks & Mitigations

**Risk 1: Pinned commit becomes unavailable (repo restructuring, force-push)**
- **Likelihood**: Low (GitHub preserves commit objects even after force-push)
- **Impact**: Medium (setup script fails)
- **Mitigation**: Error message explains the issue; user updates hash
- **Monitoring**: CI or periodic `curl --head` check on pinned URLs
- **Contingency**: Fall back to latest tagged release with manual verification

**Risk 2: Maintainer forgets to update hashes**
- **Likelihood**: Medium
- **Impact**: Low (users get a working but older installer)
- **Mitigation**: Add quarterly review reminder; document update procedure below
- **Monitoring**: Compare pinned commit date against upstream latest

### Future Evolution

**Triggers for Reconsideration:**
- If pinned scripts start changing weekly/monthly (unlikely)
- If a package manager (e.g., Homebrew) starts packaging these tools reliably
- If GitHub introduces native artifact signing that provides equivalent guarantees

---

## Implementation

### Files Affected
- [`setup/setup-secure-zsh.sh`](../../setup/setup-secure-zsh.sh) - Oh My Zsh installer pinning
- [`setup/install-omz.sh`](../../setup/install-omz.sh) - Oh My Zsh installer pinning (Batch 8)
- [`setup/setup-simple.sh`](../../setup/setup-simple.sh) - vim-plug download pinning (Batch 2)

### Hash Update Procedure

When updating a pinned dependency:

```bash
# 1. Find latest commit that modified the file
curl -fsSL "https://api.github.com/repos/OWNER/REPO/commits?path=PATH&per_page=1" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['sha'])"

# 2. Download at that commit
curl -fsSL "https://raw.githubusercontent.com/OWNER/REPO/COMMIT/PATH" -o /tmp/verify.sh

# 3. Compute hash
sha256sum /tmp/verify.sh

# 4. Update commit hash and sha256 values in the setup script
# 5. Test setup script end-to-end
```

### Current Pinned Versions

| Dependency | Commit | Date | SHA-256 |
|-----------|--------|------|---------|
| Oh My Zsh install.sh | `b52dd1a4...` | 2025-11-20 | `ce0b7c94...` |
| vim-plug plug.vim | `34467fc0...` | 2026-02-18 | `2eec4e7e...` |

---

## Validation & Verification

### Success Criteria
- [x] Setup script downloads installer to temp file (not piped to shell)
- [x] SHA-256 computed and compared before execution
- [x] Checksum mismatch produces clear error and halts
- [x] Cross-platform: works on both Linux (`sha256sum`) and macOS (`shasum`)
- [ ] All three setup scripts updated (Batches 1, 2, 8)

### Timeline
- **Decision Made**: 2026-03-05
- **Batch 1 Implemented**: 2026-03-05 (setup-secure-zsh.sh)
- **Batch 2 Planned**: Next (setup-simple.sh)
- **Batch 8 Planned**: Final batch (install-omz.sh)

---

## References

### External Resources
- [OWASP CI/CD Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html)
- [MITRE ATT&CK T1195.002 - Supply Chain Compromise: Compromise Software Supply Chain](https://attack.mitre.org/techniques/T1195/002/)
- [Oh My Zsh repository](https://github.com/ohmyzsh/ohmyzsh)
- [vim-plug repository](https://github.com/junegunn/vim-plug)

---

**Last Updated**: 2026-03-05
**Review Date**: 2026-06-05 (quarterly review of pinned hashes)
**Review Outcome**: _To be filled at review_
