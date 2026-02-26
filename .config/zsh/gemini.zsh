#!/usr/bin/env zsh
# Gemini Code Assist module - OAuth and ADC credential management
#
# Supports three auth methods (in priority order for the Gemini CLI):
#   1. OAuth (browser login) - recommended for interactive use
#      Tokens cached in ~/.gemini/ by the CLI itself.
#      First run: `gemini` prompts for browser-based Google login.
#
#   2. API Key (GEMINI_API_KEY) - fallback for headless/CI environments
#      pass insert gemini/api-key   # from Google AI Studio
#      Enable with: export GEMINI_AUTH_MODE=api-key  in ~/.zshrc.local
#
#   3. ADC (GOOGLE_APPLICATION_CREDENTIALS + GOOGLE_CLOUD_PROJECT) - for
#      enterprise Vertex AI / Gemini Code Assist Standard/Enterprise
#      gcloud auth application-default login
#      Enable with: export GEMINI_AUTH_MODE=adc  in ~/.zshrc.local
#
# Prerequisites:
#   OAuth:   just run `gemini` — browser login handles the rest
#   API Key: pass insert gemini/api-key
#   ADC:     gcloud auth application-default login
#   All:     pass insert gemini/cloud-project  (optional, for Workspace accounts)
#
# Enable with: export ENABLE_GEMINI_CODE_ASSIST=1 in ~/.zshrc.local

# Auth mode: "oauth" (default), "api-key", or "adc"
# Not readonly — allows re-sourcing to switch modes within a session
: "${GEMINI_AUTH_MODE:=oauth}"

# --- OAuth mode (default) ---
# The Gemini CLI manages its own tokens in ~/.gemini/ via browser login.
# No credential loading needed at shell startup — the CLI handles it.
if [[ "$GEMINI_AUTH_MODE" == "oauth" ]]; then
    [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ✓ Gemini auth mode: OAuth (CLI-managed)"
fi

# --- API Key mode (headless/CI fallback) ---
if [[ "$GEMINI_AUTH_MODE" == "api-key" ]]; then
    if ! command -v pass &>/dev/null; then
        echo "[WARNING] Gemini module: pass not installed - skipping API key load" >&2
    elif [[ ! -f "${PASSWORD_STORE_DIR:-$HOME/.password-store}/.gpg-id" ]]; then
        echo "[WARNING] Gemini module: pass not initialized - skipping API key load" >&2
    else
        _gemini_api_key="$(pass show gemini/api-key 2>/dev/null | head -1)"
        if [[ -n "$_gemini_api_key" ]]; then
            export GEMINI_API_KEY="$_gemini_api_key"
            [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ✓ GEMINI_API_KEY loaded"
        else
            [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ⚠  gemini/api-key not found in pass (skipping)" >&2
        fi
        unset _gemini_api_key
    fi
fi

# --- ADC mode (Vertex AI / Enterprise) ---
if [[ "$GEMINI_AUTH_MODE" == "adc" ]]; then
    _gemini_gcp_creds="${GOOGLE_APPLICATION_CREDENTIALS:-${HOME}/.config/gcloud/application_default_credentials.json}"
    if [[ -f "$_gemini_gcp_creds" ]]; then
        export GOOGLE_APPLICATION_CREDENTIALS="$_gemini_gcp_creds"
        [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ✓ GOOGLE_APPLICATION_CREDENTIALS set"
    else
        [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ⚠  ADC file not found: $_gemini_gcp_creds (ADC disabled)" >&2
    fi
    unset _gemini_gcp_creds
fi

# --- Common settings (all modes) ---

# Load GOOGLE_CLOUD_PROJECT if available in pass (needed for Workspace/enterprise)
if command -v pass &>/dev/null && [[ -f "${PASSWORD_STORE_DIR:-$HOME/.password-store}/.gpg-id" ]]; then
    _gemini_cloud_project="$(pass show gemini/cloud-project 2>/dev/null | head -1)"
    if [[ -n "$_gemini_cloud_project" ]]; then
        export GOOGLE_CLOUD_PROJECT="$_gemini_cloud_project"
        [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ✓ GOOGLE_CLOUD_PROJECT loaded"
    else
        [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ⚠  gemini/cloud-project not found in pass (skipping)" >&2
    fi
    unset _gemini_cloud_project
fi

# Default GCP location - overridable via ~/.zshrc.local before module loads
export GOOGLE_CLOUD_LOCATION="${GOOGLE_CLOUD_LOCATION:-us-central1}"

# --- Helper functions ---

# Check Gemini auth readiness based on current mode
gemini_check() {
    echo "Gemini Code Assist Check"
    echo "========================"
    echo
    echo "  Auth mode: ${GEMINI_AUTH_MODE}"
    echo

    local ok=true

    case "$GEMINI_AUTH_MODE" in
        oauth)
            if [[ -d "$HOME/.gemini" ]]; then
                # Check for cached OAuth credentials using zsh-native globs
                local has_creds=false
                if [[ -f "$HOME/.gemini/settings.json" ]]; then
                    has_creds=true
                else
                    local -a _gemini_oauth_files _gemini_json_files
                    setopt local_options nullglob
                    _gemini_oauth_files=("$HOME/.gemini"/oauth*)
                    _gemini_json_files=("$HOME/.gemini"/*.json)
                    if (( ${#_gemini_oauth_files[@]} > 0 || ${#_gemini_json_files[@]} > 0 )); then
                        has_creds=true
                    fi
                fi
                if [[ "$has_creds" == "true" ]]; then
                    echo "  [ok] OAuth tokens cached in ~/.gemini/"
                else
                    echo "  [action needed] No OAuth tokens found"
                    echo "     Fix: run 'gemini' to authenticate via browser"
                    ok=false
                fi
            else
                echo "  [action needed] ~/.gemini/ directory not found"
                echo "     Fix: run 'gemini' to authenticate via browser"
                ok=false
            fi
            ;;
        api-key)
            if [[ -n "$GEMINI_API_KEY" ]]; then
                echo "  [ok] GEMINI_API_KEY is set"
            else
                echo "  [missing] GEMINI_API_KEY is not set"
                echo "     Fix: pass insert gemini/api-key"
                ok=false
            fi
            ;;
        adc)
            if [[ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
                if [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
                    echo "  [ok] GOOGLE_APPLICATION_CREDENTIALS file exists"
                else
                    echo "  [missing] GOOGLE_APPLICATION_CREDENTIALS file missing: $GOOGLE_APPLICATION_CREDENTIALS"
                    ok=false
                fi
            else
                echo "  [missing] GOOGLE_APPLICATION_CREDENTIALS not set"
                echo "     Fix: gcloud auth application-default login"
                ok=false
            fi
            ;;
        *)
            echo "  [error] Unknown auth mode: $GEMINI_AUTH_MODE"
            echo "     Valid modes: oauth, api-key, adc"
            ok=false
            ;;
    esac

    if [[ -n "$GOOGLE_CLOUD_PROJECT" ]]; then
        echo "  [ok] GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT}"
    else
        echo "  [info] GOOGLE_CLOUD_PROJECT not set (optional for personal accounts)"
    fi

    echo "  [ok] GOOGLE_CLOUD_LOCATION: ${GOOGLE_CLOUD_LOCATION}"

    echo
    if [[ "$ok" == "true" ]]; then
        echo "  Status: Ready"
    else
        echo "  Status: Action needed (see above)"
    fi

    echo
    echo "  Switch mode: export GEMINI_AUTH_MODE=oauth|api-key|adc"
    echo "  Reload:      source \${ZSH_CONFIG_DIR:-~/.config/zsh}/gemini.zsh"
}

# Show current Gemini env var values (masked for security)
gemini_status() {
    echo "Gemini Code Assist Status"
    echo "========================="
    echo
    echo "  Auth mode:                      ${GEMINI_AUTH_MODE}"

    case "$GEMINI_AUTH_MODE" in
        oauth)
            if [[ -d "$HOME/.gemini" ]]; then
                echo "  OAuth token cache:              ~/.gemini/ (exists)"
            else
                echo "  OAuth token cache:              ~/.gemini/ (not found)"
            fi
            ;;
        api-key)
            if [[ -n "$GEMINI_API_KEY" ]]; then
                local key_len="${#GEMINI_API_KEY}"
                if (( key_len > 8 )); then
                    local masked="${GEMINI_API_KEY:0:4}********"
                    echo "  GEMINI_API_KEY:                 ${masked} (${key_len} chars)"
                else
                    echo "  GEMINI_API_KEY:                 (set, ${key_len} chars)"
                fi
            else
                echo "  GEMINI_API_KEY:                 (not set)"
            fi
            ;;
        adc)
            if [[ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
                echo "  GOOGLE_APPLICATION_CREDENTIALS: ${GOOGLE_APPLICATION_CREDENTIALS}"
            else
                echo "  GOOGLE_APPLICATION_CREDENTIALS: (not set)"
            fi
            ;;
    esac

    if [[ -n "$GOOGLE_CLOUD_PROJECT" ]]; then
        echo "  GOOGLE_CLOUD_PROJECT:           ${GOOGLE_CLOUD_PROJECT}"
    else
        echo "  GOOGLE_CLOUD_PROJECT:           (not set)"
    fi

    echo "  GOOGLE_CLOUD_LOCATION:          ${GOOGLE_CLOUD_LOCATION:-us-central1}"
}

# Clear all Gemini credentials from environment and optionally OAuth cache
gemini_clear() {
    local clear_oauth=false

    # Parse flags
    case "${1:-}" in
        --all|-a) clear_oauth=true ;;
        '')       ;;
        *)  echo "  Unknown option: $1" >&2
            echo "  Usage: gemini_clear [--all|-a]" >&2
            return 1
            ;;
    esac

    # Clear environment variables
    local vars=(GEMINI_API_KEY GOOGLE_CLOUD_PROJECT GOOGLE_APPLICATION_CREDENTIALS GOOGLE_CLOUD_LOCATION)
    for var in "${vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            unset "$var"
            echo "  Cleared $var"
        fi
    done

    # Clear OAuth token cache if requested
    if [[ "$clear_oauth" == "true" ]] && [[ -d "$HOME/.gemini" ]]; then
        # Remove only credential files, preserve settings
        local -a _cred_files
        setopt local_options nullglob
        _cred_files=(
            "$HOME/.gemini"/oauth*
            "$HOME/.gemini"/token*
            "$HOME/.gemini"/credentials*
        )
        local removed=0
        for f in "${_cred_files[@]}"; do
            [[ -f "$f" ]] && rm -f "$f" && (( removed++ ))
        done
        if (( removed > 0 )); then
            echo "  Cleared $removed OAuth token file(s) from ~/.gemini/"
        else
            echo "  No OAuth token files found in ~/.gemini/"
        fi
    fi

    echo "Gemini credentials cleared from environment"
    if [[ "$clear_oauth" == "false" ]]; then
        echo "  (use 'gemini_clear --all' to also remove cached OAuth tokens)"
    fi
}
