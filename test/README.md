# Test Suite

135 tests across 10 suites covering security validation, cross-platform compatibility, and credential management. The harness is pure bash -- tests invoke zsh functions in isolated subshells, use `/tmp` sandboxes, and never touch real credentials or GPG operations.

## Running Tests

```bash
# All suites
./test/run-tests.sh

# Single suite
bash test/test-aws-module.sh

# Post-deployment smoke test (runs against live system, separate purpose)
bash smoke-test.sh
```

**Prerequisites:** bash, zsh, coreutils. No external test frameworks required.

Tests auto-create and clean up `/tmp/dotfiles_test_*` directories. Safe to run anytime.

## Test Suites

| Suite | Tests | Coverage |
|-------|-------|----------|
| `test-aws-module` | 22 | 3-layer security validation (format, injection, allowlist), profile management |
| `test-core-functions` | 20 | error-handling, functions, aliases modules |
| `test-credential-process` | 18 | Credential retrieval, validation, debug log sanitization |
| `test-module-integration` | 12 | Module loading, cross-platform, security regression |
| `test-gpg-comprehensive` | 11 | GPG configuration, key management, pinentry |
| `test-hardware-simulation` | 11 | YubiKey presence/absence simulation |
| `test-pass-integration` | 11 | Password store lifecycle |
| `test-setup-end-to-end` | 11 | Full setup script validation |
| `test-macos-architecture` | 10 | macOS ARM/Intel, Homebrew paths |
| `test-platform-detection` | 9 | OS detection, package manager, path resolution |

## Key Patterns

### Framework sourcing

Every test file starts with:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-framework.sh"
set +euo pipefail
```

The framework sets `set -euo pipefail` on load. Tests immediately disable it because assertion failures use non-zero return codes that would otherwise abort the script.

### Testing zsh from bash

The test harness is bash, but the dotfiles are zsh. Tests invoke zsh functions via isolated subshells:

```bash
# Generic helper from test-framework.sh
run_zsh_function "$source_file" "function_call" "optional_setup_code"

# Custom wrapper in test-aws-module.sh
run_aws_func() {
    zsh -c "
        export HOME='$TEST_HOME'
        aws() { return 1; }
        source '$DOTFILES_DIR/.config/zsh/aws.zsh'
        $1
    " 2>&1
}
```

Each call gets a fresh zsh process with a sandboxed `$HOME`.

### Mocking AWS/GPG

Any test that sources `aws.zsh` **must** define `aws() { return 1; }` before sourcing. Without this, `aws.zsh` runs background credential validation on load, which triggers `pass` and GPG pinentry -- hanging the test or producing false failures.

```bash
# Always mock aws before sourcing aws.zsh
zsh -c "
    aws() { return 1; }
    source '$DOTFILES_DIR/.config/zsh/aws.zsh'
    aws_switch dev
"
```

The framework also provides `mock_aws_cli`, `mock_pass_command`, `mock_gpg_command`, `mock_yubikey_present`, and `mock_yubikey_absent` for more detailed simulation.

### Credential-process extraction

`test-credential-process.sh` needs to test individual functions from `credential-process.sh` without executing its `main()`. It extracts function definitions with:

```bash
CRED_FUNCTIONS="$(sed -n '1,/^case/{ /^case/d; p }' "$CRED_SCRIPT")"
```

Then sources the extracted text in a subshell. Mocks must be defined **after** sourcing since the source redefines functions.

## Writing a New Test

1. Create `test/test-<name>.sh` (the `test-*.sh` glob is how `run-tests.sh` discovers suites).
2. Use this template:

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test-framework.sh"
set +euo pipefail

# Override setup/teardown as needed
setup() {
    setup_test_environment "mytest"
}

teardown() {
    cleanup_test_environment
}

# Test functions
test_example() {
    local output
    output=$(echo "hello world")
    assert_contains "$output" "hello"
    assert_not_contains "$output" "goodbye"
}

# Register and run
describe "My Feature"
run_test "example does the thing" test_example

teardown
print_summary
```

See `test-aws-module.sh` for a complete real-world example with setup, mocking, and multi-layer test organization.

## Framework Quick Reference

### Assertions

| Function | Signature | Purpose |
|----------|-----------|---------|
| `assert_equals` | `expected actual [msg]` | Exact string match |
| `assert_not_equals` | `unexpected actual [msg]` | Strings differ |
| `assert_contains` | `haystack needle [msg]` | Substring present |
| `assert_not_contains` | `haystack needle [msg]` | Substring absent |
| `assert_true` | `condition [msg]` | Eval returns 0 |
| `assert_false` | `condition [msg]` | Eval returns non-0 |
| `assert_file_exists` | `path [msg]` | File exists |
| `assert_dir_exists` | `path [msg]` | Directory exists |
| `assert_file_permissions` | `path perms [msg]` | Octal permissions match |
| `assert_command_exists` | `cmd [msg]` | Command in PATH |
| `assert_exit_code` | `expected actual [msg]` | Exit codes match |
| `assert_not_empty` | `value [msg]` | Non-empty string |
| `assert_no_credential_exposure` | `file_or_string [msg]` | No AWS keys/secrets patterns |

### Platform Assertions

| Function | Signature | Purpose |
|----------|-----------|---------|
| `assert_macos_architecture` | `expected_arch [msg]` | arm64 or x86_64 |
| `assert_homebrew_path` | `expected_path [msg]` | /opt/homebrew or /usr/local |
| `assert_pinentry_path` | `expected_path [msg]` | Pinentry binary exists |
| `assert_gpg_config` | `config_file setting [msg]` | Setting present in GPG config |

### Mocks and Helpers

| Function | Purpose |
|----------|---------|
| `setup_test_environment name` | Create `/tmp` sandbox, set `$HOME`, `$GNUPGHOME` |
| `cleanup_test_environment` | Remove sandbox, unset test vars |
| `run_zsh_function file call [setup]` | Run zsh function in isolated subprocess |
| `mock_aws_cli [mode]` | Mock `aws` command (`success` or `failure`) |
| `mock_pass_command` | Mock `pass show`/`pass ls` with test data |
| `mock_gpg_command cmd [args]` | Mock `gpg` card-status, list-secret-keys |
| `mock_yubikey_present` | Simulate YubiKey inserted |
| `mock_yubikey_absent` | Simulate YubiKey removed |
| `skip_test name [reason]` | Mark test as skipped |
| `benchmark_start name` | Start timing |
| `benchmark_end name` | End timing, print duration |
| `measure_shell_startup config [iterations]` | Measure shell startup time |

Full signatures in `test-framework.sh`.

## Smoke Test vs Unit Tests

| Script | Purpose | When to run |
|--------|---------|-------------|
| `test/run-tests.sh` | Unit tests in `/tmp` sandboxes | Anytime, safe in CI |
| `smoke-test.sh` | Post-deployment validation on live system | After setup or changes |
| `validate.sh` | Config health check (not a test suite) | To verify installation |
