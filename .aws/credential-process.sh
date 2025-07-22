#!/bin/bash
# AWS credential helper script using pass password manager
# This script integrates with AWS CLI's credential_process feature
# to securely retrieve credentials from pass

set -euo pipefail

# Script version
readonly SCRIPT_VERSION="1.0.0"

# Default profile if none specified
readonly DEFAULT_PROFILE="default"

# Pass prefix for AWS credentials
readonly PASS_PREFIX="aws"

# Enable debug mode if AWS_CREDENTIAL_PROCESS_DEBUG is set
DEBUG="${AWS_CREDENTIAL_PROCESS_DEBUG:-false}"

# Colors for terminal output (only when stderr is a terminal)
if [ -t 2 ]; then
    readonly RED='\033[0;31m'
    readonly YELLOW='\033[1;33m'
    readonly NC='\033[0m' # No Color
else
    readonly RED=''
    readonly YELLOW=''
    readonly NC=''
fi

# Debug logging function with credential sanitization
debug_log() {
    if [[ "$DEBUG" == "true" ]]; then
        local message="$*"
        # Sanitize potential credential information from debug output
        message=$(echo "$message" | sed -E 's/AKIA[A-Z0-9]{16}/AKIA[REDACTED]/g')
        message=$(echo "$message" | sed -E 's/aws\/[^\/]+\/[^\/]+/aws\/[PROFILE]\/[CREDENTIAL_TYPE]/g')
        message=$(echo "$message" | sed -E 's/pass show [^ ]+/pass show [REDACTED_PATH]/g')
        echo -e "${YELLOW}[DEBUG]${NC} $message" >&2
    fi
}

# Error output function that follows AWS credential process protocol
error_output() {
    local message="$1"
    local code="${2:-CredentialProcessError}"
    
    # Log to stderr for debugging
    echo -e "${RED}[ERROR]${NC} $message" >&2
    
    # Output JSON error format expected by AWS CLI
    cat <<JSON
{
  "Version": 1,
  "Code": "$code",
  "Message": "$message"
}
JSON
    exit 1
}

# Function to validate profile name
validate_profile() {
    local profile="$1"
    
    # Check for empty profile name
    if [[ -z "$profile" ]]; then
        error_output "Profile name cannot be empty" "InvalidProfileError"
    fi
    
    # Profile name should only contain alphanumeric characters, hyphens, and underscores
    # Length should be reasonable (1-64 characters)
    if [[ ! "$profile" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]; then
        error_output "Invalid profile name: '$profile'. Must contain only alphanumeric characters, hyphens, and underscores (1-64 chars)" "InvalidProfileError"
    fi
    
    # Prevent path traversal attempts
    if [[ "$profile" =~ \.\. ]] || [[ "$profile" =~ ^[./] ]] || [[ "$profile" =~ /$ ]]; then
        error_output "Invalid profile name: '$profile'. Path traversal patterns not allowed" "InvalidProfileError"
    fi
}

# Function to check if pass entry exists
pass_entry_exists() {
    local entry="$1"
    pass show "$entry" &>/dev/null
}

# Function to retrieve credential from pass with hardware token retry logic
get_credential() {
    local entry="$1"
    local retry_count=0
    local max_retries=3
    local credential=""
    
    while [[ $retry_count -lt $max_retries ]]; do
        debug_log "Attempting to retrieve credential (attempt $((retry_count + 1)))"
        
        # Retrieve credential from pass
        if credential=$(pass show "$entry" 2>/dev/null); then
            if [[ -n "$credential" ]]; then
                debug_log "Successfully retrieved credential"
                echo "$credential"
                return 0
            else
                debug_log "Retrieved empty credential"
            fi
        else
            local exit_code=$?
            debug_log "Credential retrieval failed with exit code: $exit_code"
        fi
        
        retry_count=$((retry_count + 1))
        if [[ $retry_count -lt $max_retries ]]; then
            debug_log "Waiting before retry..."
            sleep 1
        fi
    done
    
    debug_log "Failed to retrieve credential after $max_retries attempts"
    return 1
}

# Function to retrieve session token if available
get_session_token() {
    local profile="$1"
    local token_entry="${PASS_PREFIX}/${profile}/session-token"
    
    if pass_entry_exists "$token_entry"; then
        debug_log "Session token found for profile: $profile"
        get_credential "$token_entry"
    else
        debug_log "No session token for profile: $profile"
        echo ""
    fi
}

# Function to check if credentials are expired (if expiration is stored)
check_expiration() {
    local profile="$1"
    local expiry_entry="${PASS_PREFIX}/${profile}/expiration"
    
    if pass_entry_exists "$expiry_entry"; then
        local expiration=$(get_credential "$expiry_entry")
        local now=$(date +%s)
        local exp_timestamp=$(date -d "$expiration" +%s 2>/dev/null || echo "0")
        
        if [[ $exp_timestamp -gt 0 ]] && [[ $now -gt $exp_timestamp ]]; then
            error_output "Credentials for profile '$profile' have expired" "ExpiredCredentialsError"
        fi
    fi
}

# Main function
main() {
    local profile="${1:-$DEFAULT_PROFILE}"
    
    debug_log "Script version: $SCRIPT_VERSION"
    debug_log "Processing profile: $profile"
    
    # Validate profile name
    validate_profile "$profile"
    
    # Check if pass is available
    if ! command -v pass &> /dev/null; then
        error_output "pass command not found. Please install pass password manager." "DependencyError"
    fi
    
    # Check if password store is initialized
    if [[ ! -d "$HOME/.password-store" ]]; then
        error_output "Password store not initialized. Run: pass init YOUR-GPG-KEY-ID" "NotInitializedError"
    fi
    
    # Ensure GPG authentication before proceeding
    local gpg_auth_helper="$(dirname "$0")/gpg-auth-helper.sh"
    if [[ -x "$gpg_auth_helper" ]]; then
        debug_log "Ensuring GPG authentication"
        if ! "$gpg_auth_helper" 2>/dev/null; then
            error_output "GPG authentication failed. Please authenticate with GPG to access AWS credentials." "GPGAuthError"
        fi
    else
        debug_log "GPG auth helper not found or not executable, proceeding without pre-auth"
    fi
    
    # Set up proper TTY context for hardware tokens
    if [[ -z "$GPG_TTY" ]]; then
        export GPG_TTY=$(tty 2>/dev/null || echo "/dev/console")
        debug_log "Set GPG_TTY to: $GPG_TTY"
    fi
    
    # Check if GPG agent is running
    if ! gpg-connect-agent --quiet /bye 2>/dev/null; then
        debug_log "Starting GPG agent"
        gpg-agent --daemon --quiet 2>/dev/null
        
        # Verify agent started successfully with timeout
        local attempts=0
        local max_attempts=5
        while [[ $attempts -lt $max_attempts ]]; do
            if gpg-connect-agent --quiet /bye 2>/dev/null; then
                debug_log "GPG agent started successfully"
                break
            fi
            sleep 0.5
            attempts=$((attempts + 1))
        done
        
        if [[ $attempts -eq $max_attempts ]]; then
            error_output "Failed to start GPG agent after $max_attempts attempts" "GPGAgentError"
        fi
    fi
    
    # Update GPG agent TTY context
    gpg-connect-agent "updatestartuptty" /bye >/dev/null 2>&1 || true
    debug_log "Updated GPG agent TTY context"
    
    # Define credential paths
    local access_key_entry="${PASS_PREFIX}/${profile}/access-key-id"
    local secret_key_entry="${PASS_PREFIX}/${profile}/secret-access-key"
    
    # Check if credentials exist
    if ! pass_entry_exists "$access_key_entry"; then
        error_output "Access key not found for profile: $profile" "CredentialNotFoundError"
    fi
    
    if ! pass_entry_exists "$secret_key_entry"; then
        error_output "Secret key not found for profile: $profile" "CredentialNotFoundError"
    fi
    
    # Check expiration (if applicable)
    check_expiration "$profile"
    
    # Retrieve credentials
    local access_key_id=""
    local secret_access_key=""
    
    if ! access_key_id=$(get_credential "$access_key_entry"); then
        error_output "Failed to retrieve access key for profile: $profile" "RetrievalError"
    fi
    
    if ! secret_access_key=$(get_credential "$secret_key_entry"); then
        error_output "Failed to retrieve secret key for profile: $profile" "RetrievalError"
    fi
    
    # Validate retrieved credentials
    if [[ -z "$access_key_id" ]]; then
        error_output "Empty access key retrieved for profile: $profile" "EmptyCredentialError"
    fi
    
    if [[ -z "$secret_access_key" ]]; then
        error_output "Empty secret key retrieved for profile: $profile" "EmptyCredentialError"
    fi
    
    # Validate access key format (support multiple AWS key types)
    if [[ "$access_key_id" =~ ^AKI[A-Z0-9]{17}$ ]]; then
        debug_log "Standard IAM user access key detected"
    elif [[ "$access_key_id" =~ ^ASIA[A-Z0-9]{16}$ ]]; then
        debug_log "Temporary/STS access key detected"
    elif [[ "$access_key_id" =~ ^AKIA[A-Z0-9]{16}$ ]]; then
        debug_log "IAM user access key (newer format) detected"
    elif [[ "$access_key_id" =~ ^[A-Z0-9]{16,20}$ ]]; then
        debug_log "Warning: Access key format appears non-standard but acceptable"
    else
        debug_log "Warning: Access key format appears invalid"
    fi
    
    # Check for session token (for temporary credentials)
    local session_token=$(get_session_token "$profile")
    
    # Build JSON output
    local json_output="{
  \"Version\": 1,
  \"AccessKeyId\": \"${access_key_id}\",
  \"SecretAccessKey\": \"${secret_access_key}\""
    
    # Add session token if present
    if [[ -n "$session_token" ]]; then
        json_output+=",
  \"SessionToken\": \"${session_token}\""
    fi
    
    json_output+="
}"
    
    # Output the credentials
    echo "$json_output"
    
    debug_log "Successfully retrieved credentials for profile: $profile"
}

# Handle script arguments
case "${1:-}" in
    --version|-v)
        echo "AWS Credential Process Script v$SCRIPT_VERSION"
        exit 0
        ;;
    --help|-h)
        cat <<HELP
AWS Credential Process Script v$SCRIPT_VERSION
Usage: $0 [PROFILE]

This script retrieves AWS credentials from pass password manager
for use with AWS CLI's credential_process feature.

Arguments:
  PROFILE    AWS profile name (default: $DEFAULT_PROFILE)

Options:
  --version  Show version information
  --help     Show this help message

Environment Variables:
  AWS_CREDENTIAL_PROCESS_DEBUG    Enable debug output (true/false)

Expected pass entries:
  ${PASS_PREFIX}/PROFILE/access-key-id       AWS Access Key ID (required)
  ${PASS_PREFIX}/PROFILE/secret-access-key   AWS Secret Access Key (required)
  ${PASS_PREFIX}/PROFILE/session-token       AWS Session Token (optional)
  ${PASS_PREFIX}/PROFILE/expiration          Credential expiration (optional)

Example:
  $0 personal
  AWS_CREDENTIAL_PROCESS_DEBUG=true $0 work

HELP
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
