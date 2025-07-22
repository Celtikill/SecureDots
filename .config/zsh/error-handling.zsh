#!/usr/bin/env zsh
# Standardized error handling and user feedback functions

# Colors for consistent output
export ERROR_RED='\033[0;31m'
export SUCCESS_GREEN='\033[0;32m'
export WARNING_YELLOW='\033[1;33m'
export INFO_BLUE='\033[0;34m'
export RESET_COLOR='\033[0m'

# Standardized output functions
print_error() {
    echo -e "${ERROR_RED}[ERROR]${RESET_COLOR} $1" >&2
}

print_success() {
    echo -e "${SUCCESS_GREEN}[SUCCESS]${RESET_COLOR} $1"
}

print_warning() {
    echo -e "${WARNING_YELLOW}[WARNING]${RESET_COLOR} $1"
}

print_info() {
    echo -e "${INFO_BLUE}[INFO]${RESET_COLOR} $1"
}

print_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${INFO_BLUE}[DEBUG]${RESET_COLOR} $1" >&2
    fi
}

# Enhanced error handling with recovery guidance
handle_error() {
    local error_code="$1"
    local error_message="$2"
    local recovery_hint="$3"
    
    print_error "$error_message"
    
    if [[ -n "$recovery_hint" ]]; then
        echo -e "${WARNING_YELLOW}Recovery suggestion:${RESET_COLOR} $recovery_hint"
    fi
    
    case "$error_code" in
        "missing_tool")
            echo -e "${INFO_BLUE}Installation help:${RESET_COLOR}"
            echo "  macOS: brew install <tool-name>"
            echo "  Ubuntu/Debian: sudo apt-get install <tool-name>"
            echo "  Arch Linux: sudo pacman -S <tool-name>"
            ;;
        "network_error")
            echo -e "${INFO_BLUE}Network troubleshooting:${RESET_COLOR}"
            echo "  1. Check your internet connection"
            echo "  2. Verify you can reach the endpoint"
            echo "  3. Check if you're behind a proxy"
            echo "  4. Try again in a few minutes"
            ;;
        "permission_error")
            echo -e "${INFO_BLUE}Permission troubleshooting:${RESET_COLOR}"
            echo "  1. Check file/directory permissions"
            echo "  2. Ensure you own the target directory"
            echo "  3. Try running with appropriate permissions"
            ;;
        "config_error")
            echo -e "${INFO_BLUE}Configuration troubleshooting:${RESET_COLOR}"
            echo "  1. Check configuration file syntax"
            echo "  2. Verify all required values are set"
            echo "  3. Run: dotfiles_config to see current values"
            echo "  4. See TROUBLESHOOTING.md for detailed help"
            ;;
        "gpg_error")
            echo -e "${INFO_BLUE}GPG troubleshooting:${RESET_COLOR}"
            echo "  1. Check GPG key status: gpg --list-keys"
            echo "  2. Restart GPG agent: gpg-connect-agent reloadagent /bye"
            echo "  3. Check GPG_TTY is set: echo \$GPG_TTY"
            echo "  4. See gpg-mgmnt.md for detailed help"
            ;;
        "pass_error")
            echo -e "${INFO_BLUE}Pass troubleshooting:${RESET_COLOR}"
            echo "  1. Initialize pass: pass init <gpg-key-id>"
            echo "  2. Check pass store: pass ls"
            echo "  3. Verify GPG key access"
            echo "  4. See pass-setup.md for detailed help"
            ;;
        "aws_error")
            echo -e "${INFO_BLUE}AWS troubleshooting:${RESET_COLOR}"
            echo "  1. Check AWS credentials: aws sts get-caller-identity"
            echo "  2. Verify AWS profile: echo \$AWS_PROFILE"
            echo "  3. Test credential process: ~/.aws/credential-process.sh"
            echo "  4. Enable debug: export AWS_CREDENTIAL_PROCESS_DEBUG=true"
            ;;
    esac
    
    echo -e "${INFO_BLUE}For more help:${RESET_COLOR}"
    echo "  • Run: dotfiles_help"
    echo "  • Check: TROUBLESHOOTING.md"
    echo "  • View logs with: DEBUG=true <command>"
    
    return 1
}

# Check if required tools are installed
check_required_tools() {
    local tools=("$@")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        handle_error "missing_tool" "Required tools not found: ${missing_tools[*]}" "Install the missing tools and try again"
        return 1
    fi
    
    return 0
}

# Validate file exists with helpful error
validate_file() {
    local file_path="$1"
    local description="$2"
    
    if [[ ! -f "$file_path" ]]; then
        handle_error "config_error" "$description not found: $file_path" "Create the file or check the path"
        return 1
    fi
    
    if [[ ! -r "$file_path" ]]; then
        handle_error "permission_error" "Cannot read $description: $file_path" "Check file permissions"
        return 1
    fi
    
    return 0
}

# Validate directory exists with helpful error
validate_directory() {
    local dir_path="$1"
    local description="$2"
    
    if [[ ! -d "$dir_path" ]]; then
        handle_error "config_error" "$description not found: $dir_path" "Create the directory or check the path"
        return 1
    fi
    
    if [[ ! -w "$dir_path" ]]; then
        handle_error "permission_error" "Cannot write to $description: $dir_path" "Check directory permissions"
        return 1
    fi
    
    return 0
}

# Safe network operation with retry
safe_network_op() {
    local operation="$1"
    local max_retries=3
    local retry_delay=2
    
    for ((i=1; i<=max_retries; i++)); do
        print_debug "Attempting network operation (attempt $i/$max_retries): $operation"
        
        if eval "$operation"; then
            return 0
        fi
        
        if [[ $i -lt $max_retries ]]; then
            print_warning "Network operation failed, retrying in ${retry_delay}s..."
            sleep "$retry_delay"
            retry_delay=$((retry_delay * 2))
        fi
    done
    
    handle_error "network_error" "Network operation failed after $max_retries attempts" "Check network connectivity and try again"
    return 1
}

# Test GPG functionality
test_gpg() {
    if ! command -v gpg &> /dev/null; then
        handle_error "missing_tool" "GPG not installed" "Install GPG and try again"
        return 1
    fi
    
    if ! gpg --list-keys &> /dev/null; then
        handle_error "gpg_error" "GPG keys not accessible" "Check GPG configuration and key availability"
        return 1
    fi
    
    return 0
}

# Test pass functionality
test_pass() {
    if ! command -v pass &> /dev/null; then
        handle_error "missing_tool" "Pass not installed" "Install pass password manager and try again"
        return 1
    fi
    
    if ! pass ls &> /dev/null; then
        handle_error "pass_error" "Pass not initialized" "Initialize pass with: pass init <gpg-key-id>"
        return 1
    fi
    
    return 0
}

# Test AWS CLI functionality
test_aws() {
    if ! command -v aws &> /dev/null; then
        handle_error "missing_tool" "AWS CLI not installed" "Install AWS CLI and try again"
        return 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        handle_error "aws_error" "AWS credentials not accessible" "Configure AWS credentials and try again"
        return 1
    fi
    
    return 0
}

# Progress indicator for long operations
show_progress() {
    local message="$1"
    local delay="${2:-0.5}"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    
    while true; do
        for frame in "${frames[@]}"; do
            echo -ne "\r${INFO_BLUE}${frame}${RESET_COLOR} $message"
            sleep "$delay"
        done
    done
}

# Stop progress indicator
stop_progress() {
    kill $! 2>/dev/null
    echo -ne "\r"
}

# Confirmation prompt with default
confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local response
    
    while true; do
        if [[ "$default" == "y" ]]; then
            echo -ne "${WARNING_YELLOW}${prompt} [Y/n]:${RESET_COLOR} "
        else
            echo -ne "${WARNING_YELLOW}${prompt} [y/N]:${RESET_COLOR} "
        fi
        
        read -r response
        response=${response:-$default}
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}