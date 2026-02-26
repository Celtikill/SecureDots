#!/usr/bin/env zsh
# Gemini Code Assist module - API key and ADC credential management
#
# Supports two auth methods:
#   1. API Key (GEMINI_API_KEY) - for CLI/direct API access via Google AI Studio
#   2. ADC (GOOGLE_APPLICATION_CREDENTIALS + GOOGLE_CLOUD_PROJECT) - for
#      enterprise Vertex AI / Gemini Code Assist Standard/Enterprise
#
# Prerequisites:
#   pass insert gemini/api-key          # API key from Google AI Studio
#   pass insert gemini/cloud-project    # GCP project ID for Vertex AI
#   # ADC credentials live at the gcloud default path:
#   #   gcloud auth application-default login
#   #   ~/.config/gcloud/application_default_credentials.json
#   # Or place a service account key there and set GOOGLE_APPLICATION_CREDENTIALS
#   # in ~/.zshrc.local to override.
#
# Enable with: export ENABLE_GEMINI_CODE_ASSIST=1 in ~/.zshrc.local

# Verify pass is available before attempting credential load
if ! command -v pass &>/dev/null; then
    echo "[WARNING] Gemini module: pass not installed - skipping credential load" >&2
    return 0
fi

# O(1) check using .gpg-id sentinel file (avoids slow pass ls traversal)
if [[ ! -f "${PASSWORD_STORE_DIR:-$HOME/.password-store}/.gpg-id" ]]; then
    echo "[WARNING] Gemini module: pass not initialized - skipping credential load" >&2
    return 0
fi

# Load GEMINI_API_KEY - single retrieval to avoid TOCTOU and double GPG prompts
_gemini_api_key="$(pass show gemini/api-key 2>/dev/null | head -1)"
if [[ -n "$_gemini_api_key" ]]; then
    export GEMINI_API_KEY="$_gemini_api_key"
    [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ✓ GEMINI_API_KEY loaded"
else
    [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ⚠  gemini/api-key not found in pass (skipping)" >&2
fi
unset _gemini_api_key

# Load GOOGLE_CLOUD_PROJECT - single retrieval
_gemini_cloud_project="$(pass show gemini/cloud-project 2>/dev/null | head -1)"
if [[ -n "$_gemini_cloud_project" ]]; then
    export GOOGLE_CLOUD_PROJECT="$_gemini_cloud_project"
    [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ✓ GOOGLE_CLOUD_PROJECT loaded"
else
    [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ⚠  gemini/cloud-project not found in pass (skipping)" >&2
fi
unset _gemini_cloud_project

# Export GOOGLE_APPLICATION_CREDENTIALS using the gcloud default ADC path.
# Override in ~/.zshrc.local if using a service account key at a different path.
_gemini_gcp_creds="${GOOGLE_APPLICATION_CREDENTIALS:-${HOME}/.config/gcloud/application_default_credentials.json}"
if [[ -f "$_gemini_gcp_creds" ]]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$_gemini_gcp_creds"
    [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ✓ GOOGLE_APPLICATION_CREDENTIALS set"
else
    [[ "${ZSH_VERBOSE:-false}" == "true" ]] && echo "  ⚠  Service account file not found: $_gemini_gcp_creds (ADC disabled)" >&2
fi
unset _gemini_gcp_creds

# Default GCP location - overridable via ~/.zshrc.local before module loads
export GOOGLE_CLOUD_LOCATION="${GOOGLE_CLOUD_LOCATION:-us-central1}"

# Check Gemini API key is set and verify ADC file presence
gemini_check() {
    echo "🔍 Gemini Code Assist Check"
    echo "==========================="
    echo

    local ok=true

    if [[ -n "$GEMINI_API_KEY" ]]; then
        echo "  ✓ GEMINI_API_KEY is set"
    else
        echo "  ❌ GEMINI_API_KEY is not set"
        echo "     Fix: pass insert gemini/api-key"
        ok=false
    fi

    if [[ -n "$GOOGLE_CLOUD_PROJECT" ]]; then
        echo "  ✓ GOOGLE_CLOUD_PROJECT is set"
    else
        echo "  ⚠  GOOGLE_CLOUD_PROJECT is not set (Vertex AI disabled)"
    fi

    if [[ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
        if [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
            echo "  ✓ GOOGLE_APPLICATION_CREDENTIALS file exists"
        else
            echo "  ❌ GOOGLE_APPLICATION_CREDENTIALS file missing: $GOOGLE_APPLICATION_CREDENTIALS"
            ok=false
        fi
    else
        echo "  ⚠  GOOGLE_APPLICATION_CREDENTIALS not set (ADC disabled)"
    fi

    echo "  ✓ GOOGLE_CLOUD_LOCATION: ${GOOGLE_CLOUD_LOCATION}"

    echo

    if [[ "$ok" == "true" ]]; then
        echo "  Status: ✓ Ready"
    else
        echo "  Status: ⚠  Partial (see warnings above)"
    fi

    echo
    echo "  Reload credentials: source \${ZSH_CONFIG_DIR:-~/.config/zsh}/gemini.zsh"
}

# Show current Gemini env var values (masked for security)
gemini_status() {
    echo "🔑 Gemini Code Assist Status"
    echo "============================"
    echo

    if [[ -n "$GEMINI_API_KEY" ]]; then
        local key_len="${#GEMINI_API_KEY}"
        if (( key_len > 8 )); then
            local masked="${GEMINI_API_KEY:0:4}$(printf '%0.s*' {1..8})"
            echo "  GEMINI_API_KEY:                 ${masked} (${key_len} chars)"
        else
            echo "  GEMINI_API_KEY:                 (set, ${key_len} chars)"
        fi
    else
        echo "  GEMINI_API_KEY:                 (not set)"
    fi

    if [[ -n "$GOOGLE_CLOUD_PROJECT" ]]; then
        echo "  GOOGLE_CLOUD_PROJECT:           ${GOOGLE_CLOUD_PROJECT}"
    else
        echo "  GOOGLE_CLOUD_PROJECT:           (not set)"
    fi

    if [[ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
        echo "  GOOGLE_APPLICATION_CREDENTIALS: ${GOOGLE_APPLICATION_CREDENTIALS}"
    else
        echo "  GOOGLE_APPLICATION_CREDENTIALS: (not set)"
    fi

    echo "  GOOGLE_CLOUD_LOCATION:          ${GOOGLE_CLOUD_LOCATION:-us-central1}"
}

# Clear all Gemini credentials from environment
gemini_clear() {
    local vars=(GEMINI_API_KEY GOOGLE_CLOUD_PROJECT GOOGLE_APPLICATION_CREDENTIALS GOOGLE_CLOUD_LOCATION)
    for var in "${vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            unset "$var"
            echo "  ✓ Cleared $var"
        fi
    done
    echo "Gemini credentials cleared from environment"
}
