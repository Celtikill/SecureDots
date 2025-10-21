# SecureDots Documentation Navigator

**Quick access to all documentation organized by what you want to accomplish.**

---

## I Want To...

### Get Started (First-Time Users)

| Task | Document | Time |
|------|----------|------|
| **Install dotfiles quickly** | [Quick Setup Paths](README.md#quick-setup-paths) | 15-20 min |
| **Understand what this does** | [README Overview](README.md) | 5 min |
| **Set up AWS credentials securely** | [Pass Setup Guide](docs/guides/pass-setup.md) | 30 min |
| **Configure AWS profiles** | [AWS Config Example](examples/aws-config.example) | 10 min |
| **Set up GPG (basic)** | [GPG Quick Start](docs/guides/gpg-quickstart.md) | 15 min |

### Use It Daily

| Task | Document | Time |
|------|----------|------|
| **Find commands I need** | [Command Cheat Sheet](CHEAT-SHEET.md) | 30 sec |
| **Switch AWS profiles** | [Quick Reference - AWS](QUICK-REFERENCE.md#aws-profile-management) | 30 sec |
| **Manage credentials** | [Quick Reference - Credentials](QUICK-REFERENCE.md#credential-management) | 1 min |
| **See all available functions** | Run `dotfiles_help` in terminal | 30 sec |

### Fix Problems

| Task | Document | Time |
|------|----------|------|
| **Quick troubleshooting fixes** | [Cheat Sheet - Troubleshooting](CHEAT-SHEET.md#troubleshooting-one-liners) | 1 min |
| **Find solution by symptom** | [Troubleshooting Guide](docs/guides/TROUBLESHOOTING.md) | 5-10 min |
| **GPG agent not working** | [Troubleshooting - GPG Issues](docs/guides/TROUBLESHOOTING.md#gpg-issues) | 2 min |
| **AWS credentials not loading** | [Troubleshooting - AWS](docs/guides/TROUBLESHOOTING.md#aws-credential-issues) | 5 min |
| **Setup validation failed** | [5-Minute Validation](QUICK-REFERENCE.md#5-minute-setup-validation) | 5 min |

### Understand the System

| Task | Document | Time |
|------|----------|------|
| **How does security work?** | [Security Model](SECURITY.md) | 15 min |
| **Verify security claims** | [Security Verification](SECURITY-VERIFICATION.md) | 10 min |
| **Understand architecture** | [Architecture Documentation](docs/ARCHITECTURE.md) | 20 min |
| **Show to my CISO/security team** | [Security Model](SECURITY.md) + [Architecture](docs/ARCHITECTURE.md) | 30 min |
| **See full user guide** | [Complete User Guide](docs/USER-GUIDE.md) | 45 min |

### Advanced Setup

| Task | Document | Time |
|------|----------|------|
| **Set up hardware security keys** | [GPG Quick Start - Hardware](docs/guides/gpg-quickstart.md#hardware-key-setup) | 45 min |
| **Enterprise GPG key management** | [GPG Enterprise Playbook](docs/guides/gpg-enterprise-playbook.md) | 2-3 hours |
| **SSH with GPG authentication** | [GPG SSH Auth Guide](docs/guides/gpg-ssh-auth.md) | 45 min |
| **Customize for my workflow** | Run `dotfiles_customize` in terminal | 10 min |
| **Deploy for my team** | [Team Deployment Template](TEMPLATE.md) | Variable |

---

## By User Type (Persona-Based Navigation)

### New Developer / First-Time User

**Your journey:**
1. Start: [Quick Setup Paths](README.md#quick-setup-paths)
2. Install: Run `./setup/setup-simple.sh`
3. Learn: [Quick Reference](QUICK-REFERENCE.md)
4. Get help: [Troubleshooting](docs/guides/TROUBLESHOOTING.md)

**Key documents:**
- [README](README.md) - Overview and setup
- [AWS Config Example](examples/aws-config.example) - Copy and customize
- [Pass Setup Guide](docs/guides/pass-setup.md) - Store your first credentials
- [Command Cheat Sheet](CHEAT-SHEET.md) - Daily commands

**Estimated setup time:** 30-45 minutes

---

### Experienced SRE / DevOps Engineer

**Your journey:**
1. Review: [Architecture](docs/ARCHITECTURE.md) - Technical deep-dive
2. Install: Run `./setup/setup-secure-zsh.sh`
3. Reference: [Cheat Sheet](CHEAT-SHEET.md) - Quick commands
4. Customize: Run `dotfiles_customize`

**Key documents:**
- [Architecture Documentation](docs/ARCHITECTURE.md) - System design
- [Command Cheat Sheet](CHEAT-SHEET.md) - Single-page reference
- [Security Model](SECURITY.md) - Threat analysis
- [Troubleshooting](docs/guides/TROUBLESHOOTING.md) - Self-service debugging

**Estimated setup time:** 20-30 minutes

---

### Security Engineer / CISO

**Your focus:**
1. Evaluate: [Security Model](SECURITY.md) - Threat model and mitigations
2. Verify: [Security Verification](SECURITY-VERIFICATION.md) - Independent validation
3. Understand: [Architecture](docs/ARCHITECTURE.md) - Technical implementation
4. Deploy: [Team Template](TEMPLATE.md) - Organization rollout

**Key documents:**
- [Security Model](SECURITY.md) - Complete security analysis
- [Security Verification](SECURITY-VERIFICATION.md) - Validation procedures
- [Architecture Documentation](docs/ARCHITECTURE.md) - Design decisions
- [Governance](GOVERNANCE.md) - Security procedures

**Evaluation time:** 1-2 hours

---

### Multi-Platform User (macOS / Linux / WSL)

**Platform-specific guidance:**
- [Platform Notes](PLATFORM-NOTES.md) - Platform quirks and solutions
- [Troubleshooting - Platform Issues](docs/guides/TROUBLESHOOTING.md#platform-specific-issues) - Platform-specific debugging

**Testing checklist:**
- macOS: Test on both Intel and Apple Silicon
- Linux: Verify distribution-specific packages
- WSL2: Check Windows integration

---

## By Document Type

### Quick Reference

| Document | Purpose | Length |
|----------|---------|--------|
| [CHEAT-SHEET.md](CHEAT-SHEET.md) | Single-page command reference | 1 page |
| [QUICK-REFERENCE.md](QUICK-REFERENCE.md) | Daily commands and workflows | 10 min read |
| [AWS Config Example](examples/aws-config.example) | Copy-paste AWS configuration | 5 min |

### Setup & Installation

| Document | Purpose | Length |
|----------|---------|--------|
| [README.md](README.md) | Overview and quick setup | 10 min read |
| [USER-GUIDE.md](docs/USER-GUIDE.md) | Complete setup walkthrough | 45 min read |
| [Pass Setup Guide](docs/guides/pass-setup.md) | Credential storage setup | 30 min |
| [GPG Quick Start](docs/guides/gpg-quickstart.md) | Basic GPG setup | 15-45 min |

### Daily Usage

| Document | Purpose | Length |
|----------|---------|--------|
| [QUICK-REFERENCE.md](QUICK-REFERENCE.md) | Command reference | 10 min |
| [CHEAT-SHEET.md](CHEAT-SHEET.md) | Printable quick reference | 1 page |
| Run `dotfiles_help` | Interactive command help | Instant |
| Run `dotfiles_examples` | Workflow examples | 5 min |

### Troubleshooting

| Document | Purpose | Length |
|----------|---------|--------|
| [TROUBLESHOOTING.md](docs/guides/TROUBLESHOOTING.md) | Complete troubleshooting guide | Variable |
| [Cheat Sheet](CHEAT-SHEET.md#troubleshooting-one-liners) | Quick fixes | 30 sec |

### Advanced Topics

| Document | Purpose | Length |
|----------|---------|--------|
| [GPG Enterprise Playbook](docs/guides/gpg-enterprise-playbook.md) | Air-gapped keys, FIPS-140 | 2-3 hours |
| [GPG SSH Authentication](docs/guides/gpg-ssh-auth.md) | SSH with GPG keys | 45 min |
| [Architecture](docs/ARCHITECTURE.md) | System design details | 20 min |

### Security & Compliance

| Document | Purpose | Length |
|----------|---------|--------|
| [SECURITY.md](SECURITY.md) | Threat model and security analysis | 15 min |
| [SECURITY-VERIFICATION.md](SECURITY-VERIFICATION.md) | Independent security validation | 10 min |
| [GOVERNANCE.md](GOVERNANCE.md) | Security procedures | 10 min |

### Team Deployment

| Document | Purpose | Length |
|----------|---------|--------|
| [TEMPLATE.md](TEMPLATE.md) | Team deployment guide | Variable |
| [Architecture](docs/ARCHITECTURE.md) | Technical overview for teams | 20 min |
| [Security Model](SECURITY.md) | Security justification | 15 min |

---

## Common Workflows

### First-Time Setup Workflow

```
1. Clone repo
   ↓
2. Read README quick setup
   ↓
3. Run setup-simple.sh
   ↓
4. Set up first AWS profile
   ↓
5. Test with aws_check
   ↓
6. Bookmark CHEAT-SHEET.md
```

**Documents needed:**
- [README - Quick Setup](README.md#quick-setup-paths)
- [AWS Config Example](examples/aws-config.example)
- [Pass Setup](docs/guides/pass-setup.md)
- [Cheat Sheet](CHEAT-SHEET.md)

---

### Adding a New AWS Account Workflow

```
1. Get AWS credentials
   ↓
2. Store in pass: pass insert -m aws/new-account
   ↓
3. Add profile to ~/.aws/config
   ↓
4. Test: aws_switch new-account && aws_check
```

**Documents needed:**
- [AWS Config Example](examples/aws-config.example) (copy profile template)
- [Pass Setup - Store Credentials](docs/guides/pass-setup.md#store-aws-credentials)

---

### Troubleshooting Workflow

```
1. Identify symptom
   ↓
2. Check CHEAT-SHEET.md quick fixes
   ↓
3. If not resolved, see TROUBLESHOOTING.md
   ↓
4. Use symptom index to find relevant section
   ↓
5. Follow step-by-step solution
```

**Documents needed:**
- [Cheat Sheet - Troubleshooting](CHEAT-SHEET.md#troubleshooting-one-liners)
- [Troubleshooting Guide](docs/guides/TROUBLESHOOTING.md)

---

## Quick Links by Topic

### AWS
- [AWS Config Example](examples/aws-config.example)
- [AWS Commands](QUICK-REFERENCE.md#aws-profile-management)
- [AWS Troubleshooting](docs/guides/TROUBLESHOOTING.md#aws-credential-issues)

### GPG
- [GPG Quick Start](docs/guides/gpg-quickstart.md)
- [GPG Enterprise Playbook](docs/guides/gpg-enterprise-playbook.md)
- [GPG Troubleshooting](docs/guides/TROUBLESHOOTING.md#gpg-issues)

### Pass (Password Manager)
- [Pass Setup Guide](docs/guides/pass-setup.md)
- [Pass Commands](QUICK-REFERENCE.md#credential-management)
- [Pass Troubleshooting](docs/guides/TROUBLESHOOTING.md#pass-issues)

### SSH
- [GPG SSH Authentication](docs/guides/gpg-ssh-auth.md)
- [SSH Troubleshooting](docs/guides/TROUBLESHOOTING.md#ssh-authentication-issues)

### Security
- [Security Model](SECURITY.md)
- [Security Verification](SECURITY-VERIFICATION.md)
- [Architecture](docs/ARCHITECTURE.md)

---

## Document Relationships

```
README (Start Here)
├── QUICK-REFERENCE (Daily Use)
│   └── CHEAT-SHEET (Quick Lookup)
├── USER-GUIDE (Complete Setup)
│   ├── Pass Setup Guide
│   ├── GPG Quick Start
│   └── AWS Config Example
├── TROUBLESHOOTING (Fix Problems)
│   ├── Platform Notes
│   └── Cheat Sheet Quick Fixes
└── Advanced Topics
    ├── GPG Enterprise Playbook
    ├── GPG SSH Auth
    ├── Architecture
    └── Security Model
```

---

## Still Can't Find What You Need?

1. **Search this repository:** Use GitHub search or `grep -r "keyword" docs/`
2. **Run interactive help:** `dotfiles_help` for available functions
3. **Check examples:** `dotfiles_examples` for workflow examples
4. **Ask for help:** Create an issue with your question

---

## Contributing to Documentation

Found a gap in the documentation? See [CONTRIBUTING.md](CONTRIBUTING.md) for how to improve these docs.

---

**Last Updated:** Generated with documentation navigator
**Feedback:** Help us improve - what were you looking for?
