#!/bin/bash

# GitHub Copilot CLI Automation Accelerator Install Script
# Downloads and installs the complete GitHub Copilot CLI Automation Suite from the remote repository.
# Supports both fresh installations and updates of existing installations.

set -e  # Exit on any error

# Default configuration
INSTALL_PATH=""
MODE="current"
UPDATE=false
BRANCH="main"
REPOSITORY="neildcruz/copilot-cli-automation-accelerator"
VERBOSE=false
SKIP_EXAMPLES=false
GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

# Color functions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

print_success() { echo -e "${GREEN}✓ $1${NC}" >&2; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}" >&2; }
print_error() { echo -e "${RED}✗ $1${NC}" >&2; }
print_info() { echo -e "${CYAN}ℹ $1${NC}" >&2; }
print_step() { echo -e "${BLUE}→ $1${NC}" >&2; }

# Check GitHub authentication
check_github_authentication() {
    local silent="${1:-false}"
    
    if [[ "$silent" != "true" ]]; then
        print_step "Checking GitHub authentication..."
    fi
    
    # Track which auth sources are available
    AUTH_GITHUB_TOKEN="false"
    AUTH_GH_TOKEN="false"
    AUTH_COPILOT_TOKEN="false"
    AUTH_GH_CLI="false"
    AUTH_SOURCE=""
    
    # Check for GITHUB_TOKEN environment variable
    if [[ -n "$GITHUB_TOKEN" ]]; then
        AUTH_GITHUB_TOKEN="true"
        AUTH_SOURCE="GITHUB_TOKEN environment variable"
        if [[ "$silent" != "true" ]]; then
            print_success "GitHub token found in GITHUB_TOKEN environment variable"
        fi
    fi
    
    # Check for GH_TOKEN environment variable
    if [[ -n "$GH_TOKEN" ]]; then
        AUTH_GH_TOKEN="true"
        if [[ -z "$AUTH_SOURCE" ]]; then
            AUTH_SOURCE="GH_TOKEN environment variable"
        fi
    fi
    
    # Check for COPILOT_GITHUB_TOKEN environment variable
    if [[ -n "$COPILOT_GITHUB_TOKEN" ]]; then
        AUTH_COPILOT_TOKEN="true"
        if [[ -z "$AUTH_SOURCE" ]]; then
            AUTH_SOURCE="COPILOT_GITHUB_TOKEN environment variable"
        fi
    fi
    
    # Check for GitHub CLI authentication
    if command -v gh >/dev/null 2>&1; then
        if gh auth token >/dev/null 2>&1; then
            AUTH_GH_CLI="true"
            if [[ -z "$AUTH_SOURCE" ]]; then
                AUTH_SOURCE="GitHub CLI (gh auth)"
                if [[ "$silent" != "true" ]]; then
                    print_success "GitHub CLI authentication found"
                fi
            fi
        fi
    fi
    
    # Return 0 if any auth source is available
    if [[ -n "$AUTH_SOURCE" ]]; then
        return 0
    fi
    return 1
}

# Show authentication status with detailed info
show_authentication_status() {
    echo ""
    echo -e "${CYAN}AUTHENTICATION STATUS:${NC}"
    echo ""
    
    if [[ "$AUTH_GITHUB_TOKEN" == "true" ]]; then
        echo -e "  ${GREEN}\u2713 GITHUB_TOKEN:          ${NC}Set (${#GITHUB_TOKEN} chars)"
    else
        echo -e "  ${RED}\u2717 GITHUB_TOKEN:          ${NC}Not set"
    fi
    
    if [[ "$AUTH_GH_TOKEN" == "true" ]]; then
        echo -e "  ${GREEN}\u2713 GH_TOKEN:              ${NC}Set (${#GH_TOKEN} chars)"
    else
        echo -e "  ${RED}\u2717 GH_TOKEN:              ${NC}Not set"
    fi
    
    if [[ "$AUTH_COPILOT_TOKEN" == "true" ]]; then
        echo -e "  ${GREEN}\u2713 COPILOT_GITHUB_TOKEN:  ${NC}Set"
    else
        echo -e "  ${RED}\u2717 COPILOT_GITHUB_TOKEN:  ${NC}Not set"
    fi
    
    if [[ "$AUTH_GH_CLI" == "true" ]]; then
        echo -e "  ${GREEN}\u2713 GitHub CLI (gh):       ${NC}Authenticated"
    else
        echo -e "  ${RED}\u2717 GitHub CLI (gh):       ${NC}Not authenticated"
    fi
    
    echo ""
}

# Show authentication help
show_authentication_help() {
    echo -e "${YELLOW}Quick fix (choose one):${NC}"
    echo -e "  1. Set token:     ${CYAN}export GITHUB_TOKEN='ghp_...'${NC}"
    echo -e "  2. Login via CLI: ${CYAN}gh auth login${NC}"
    echo -e "  3. Create token:  ${CYAN}https://github.com/settings/tokens/new${NC}"
    echo ""
    echo -e "Minimum token permissions needed: ${YELLOW}repo (read)${NC}"
    echo ""
}

# Get HTTP error message with actionable help
get_http_error_message() {
    local status_code="$1"
    local url="$2"
    
    case "$status_code" in
        401)
            HTTP_ERROR_MSG="Authentication required (HTTP 401)"
            HTTP_ERROR_HELP="Your token may be invalid or expired|Generate a new token at: https://github.com/settings/tokens/new|Ensure the token has 'repo' scope for private repositories"
            ;;
        403)
            HTTP_ERROR_MSG="Access forbidden (HTTP 403)"
            HTTP_ERROR_HELP="You may have hit the GitHub API rate limit|Your token may lack required permissions|Try authenticating: gh auth login|Or wait a few minutes and try again"
            ;;
        404)
            HTTP_ERROR_MSG="File not found (HTTP 404)"
            HTTP_ERROR_HELP="Check that the repository URL is correct: $url|Verify the branch name (current: $BRANCH)|Ensure the file exists in the repository"
            ;;
        5[0-9][0-9])
            HTTP_ERROR_MSG="GitHub server error (HTTP $status_code)"
            HTTP_ERROR_HELP="This is a temporary GitHub issue|Wait a few minutes and try again|Check GitHub status: https://www.githubstatus.com/"
            ;;
        0)
            HTTP_ERROR_MSG="Connection timed out or network error"
            HTTP_ERROR_HELP="Check your internet connection|If behind a proxy, set HTTP_PROXY and HTTPS_PROXY|Try: curl -I https://raw.githubusercontent.com"
            ;;
        *)
            HTTP_ERROR_MSG="HTTP error (status code: $status_code)"
            HTTP_ERROR_HELP="Unexpected error occurred|Check your network connection and try again"
            ;;
    esac
}

# Print HTTP error with help
print_http_error() {
    local error_msg="$1"
    local error_help="$2"
    
    echo ""
    print_error "$error_msg"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    
    # Split help by | and print each line
    IFS='|' read -ra HELP_LINES <<< "$error_help"
    for line in "${HELP_LINES[@]}"; do
        echo -e "  - $line"
    done
    echo ""
}

# Check repository visibility
check_repository_visibility() {
    local repository="$1"
    
    print_step "Checking repository visibility..."
    
    local api_url="https://api.github.com/repos/$repository"
    local headers=()
    
    # Add authentication headers if available
    local token="$GITHUB_TOKEN"
    if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
        token=$(gh auth token 2>/dev/null || true)
    fi
    
    if [[ -n "$token" ]]; then
        headers=(-H "Authorization: Bearer $token")
    fi
    
    local response
    local status_code
    
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s -w "\n%{http_code}" "${headers[@]}" \
                       -H "Accept: application/vnd.github.v3+json" \
                       -H "User-Agent: Bash-Installer" \
                       --connect-timeout 30 --max-time 60 \
                       "$api_url" 2>/dev/null)
        status_code=$(echo "$response" | tail -n1)
        response=$(echo "$response" | sed '$d')
    elif command -v wget >/dev/null 2>&1; then
        local auth_header=""
        if [[ -n "$token" ]]; then
            auth_header="--header=Authorization: Bearer $token"
        fi
        response=$(wget -qO- --timeout=30 --tries=1 \
                        --header="Accept: application/vnd.github.v3+json" \
                        --header="User-Agent: Bash-Installer" \
                        $auth_header \
                        "$api_url" 2>/dev/null)
        status_code=$?
        if [[ $status_code -eq 0 ]]; then
            status_code=200
        else
            status_code=404
        fi
    fi
    
    case $status_code in
        200)
            local is_private
            if command -v python3 >/dev/null 2>&1; then
                is_private=$(echo "$response" | python3 -c "import sys, json; print(str(json.load(sys.stdin)['private']).lower())" 2>/dev/null || echo "false")
            elif command -v python >/dev/null 2>&1; then
                is_private=$(echo "$response" | python -c "import sys, json; print(str(json.load(sys.stdin)['private']).lower())" 2>/dev/null || echo "false")
            elif command -v jq >/dev/null 2>&1; then
                is_private=$(echo "$response" | jq -r '.private' 2>/dev/null || echo "false")
            else
                # Fallback: check if response contains '"private":true'
                if echo "$response" | grep -q '"private"[[:space:]]*:[[:space:]]*true'; then
                    is_private="true"
                else
                    is_private="false"
                fi
            fi
            
            if [[ "$is_private" == "true" ]]; then
                print_success "Repository $repository is private"
                echo "private"
            else
                print_success "Repository $repository is public"
                echo "public"
            fi
            return 0
            ;;
        404)
            print_warning "Repository not found or you don't have access. It might be private and require authentication."
            echo "private"
            return 1
            ;;
        403)
            print_warning "Access forbidden. Repository might be private or you've hit rate limits."
            echo "private"
            return 1
            ;;
        401)
            print_warning "Authentication required. Repository is likely private."
            echo "private"
            return 1
            ;;
        *)
            print_error "Failed to check repository visibility (HTTP $status_code)"
            echo "unknown"
            return 1
            ;;
    esac
}

# Show usage information
show_usage() {
    cat << EOF
GitHub Copilot CLI Automation Accelerator Installer

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -p, --path PATH       Installation directory (default: current/~/.copilot-cli-automation based on mode)
    -m, --mode MODE       Installation mode: 'current' or 'central' (default: current)
    -u, --update          Update existing installation instead of creating new one
    -b, --branch BRANCH   Git branch to download from (default: main)
    -r, --repo REPO       GitHub repository in format 'owner/repo' 
                         (default: neildcruz/copilot-cli-automation-accelerator)
    -s, --skip-examples   Skip downloading built-in example agents
    -t, --token TOKEN     GitHub personal access token for private repository access
    -v, --verbose         Enable verbose output
    -h, --help            Show this help message

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN          GitHub personal access token (alternative to --token)
    GH_TOKEN              GitHub token (used by GitHub Actions)

EXAMPLES:
    $0                                    # Install in current directory
    $0 --mode central                     # Install in ~/.copilot-cli-automation
    $0 --path ~/my-tools --update         # Update installation in ~/my-tools
    $0 --token ghp_xxx...                 # Install with explicit token
    $0 --branch develop --verbose         # Install from develop branch with verbose output
    $0 --skip-examples                    # Install without example agents

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--path)
                INSTALL_PATH="$2"
                shift 2
                ;;
            -m|--mode)
                if [[ "$2" != "current" && "$2" != "central" ]]; then
                    print_error "Mode must be 'current' or 'central'"
                    exit 1
                fi
                MODE="$2"
                shift 2
                ;;
            -u|--update)
                UPDATE=true
                shift
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            -r|--repo)
                REPOSITORY="$2"
                shift 2
                ;;
            -t|--token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--skip-examples)
                SKIP_EXAMPLES=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set default installation path if not provided
    if [[ -z "$INSTALL_PATH" ]]; then
        if [[ "$MODE" == "central" ]]; then
            INSTALL_PATH="$HOME/.copilot-cli-automation"
        else
            INSTALL_PATH="$(pwd)/.copilot-cli-automation"
        fi
    fi
}

# Files to download with their paths
# Format: "path:required|optional:core|example"
# The third field marks whether a file is a core file or an example agent file.
# Example files are skipped when --skip-examples is set.
declare -a FILES_TO_DOWNLOAD=(
    # Core files
    "README.md:required:core"
    "INDEX.md:required:core"
    "automation/README.md:required:core"
    "automation/copilot-cli.sh:required:core"
    "automation/copilot-cli.ps1:required:core"
    "automation/copilot-cli.properties:required:core"
    "automation/user.prompt.md:optional:core"
    "automation/default.agent.md:optional:core"
    # Example agents (skipped when --skip-examples is set)
    "automation/examples/README.md:optional:example"
    "automation/examples/mcp-config.json:optional:example"
    # Code Review Agent
    "automation/examples/code-review/copilot-cli.properties:optional:example"
    "automation/examples/code-review/user.prompt.md:optional:example"
    "automation/examples/code-review/code-review.agent.md:optional:example"
    "automation/examples/code-review/description.txt:optional:example"
    "automation/examples/code-review/mcp-config.json:optional:example"
    # Security Analysis Agent
    "automation/examples/security-analysis/copilot-cli.properties:optional:example"
    "automation/examples/security-analysis/user.prompt.md:optional:example"
    "automation/examples/security-analysis/security-analysis.agent.md:optional:example"
    "automation/examples/security-analysis/description.txt:optional:example"
    # Test Generation Agent
    "automation/examples/test-generation/copilot-cli.properties:optional:example"
    "automation/examples/test-generation/user.prompt.md:optional:example"
    "automation/examples/test-generation/test-generation.agent.md:optional:example"
    "automation/examples/test-generation/description.txt:optional:example"
    # Documentation Generation Agent
    "automation/examples/documentation-generation/copilot-cli.properties:optional:example"
    "automation/examples/documentation-generation/user.prompt.md:optional:example"
    "automation/examples/documentation-generation/documentation-generation.agent.md:optional:example"
    "automation/examples/documentation-generation/description.txt:optional:example"
    # Refactoring Agent
    "automation/examples/refactoring/copilot-cli.properties:optional:example"
    "automation/examples/refactoring/user.prompt.md:optional:example"
    "automation/examples/refactoring/refactoring.agent.md:optional:example"
    "automation/examples/refactoring/description.txt:optional:example"
    # CI/CD Analysis Agent
    "automation/examples/cicd-analysis/copilot-cli.properties:optional:example"
    "automation/examples/cicd-analysis/user.prompt.md:optional:example"
    "automation/examples/cicd-analysis/cicd-analysis.agent.md:optional:example"
    "automation/examples/cicd-analysis/description.txt:optional:example"
    # Multi-Stage Workflow
    "automation/examples/multi-stage-workflow/README.md:optional:example"
    "automation/examples/multi-stage-workflow/stage-1-scanner/copilot-cli.properties:optional:example"
    "automation/examples/multi-stage-workflow/stage-1-scanner/user.prompt.md:optional:example"
    "automation/examples/multi-stage-workflow/stage-1-scanner/stage-1-scanner.agent.md:optional:example"
    "automation/examples/multi-stage-workflow/stage-1-scanner/description.txt:optional:example"
    "automation/examples/multi-stage-workflow/stage-2-fixer/copilot-cli.properties:optional:example"
    "automation/examples/multi-stage-workflow/stage-2-fixer/user.prompt.md:optional:example"
    "automation/examples/multi-stage-workflow/stage-2-fixer/stage-2-fixer.agent.md:optional:example"
    "automation/examples/multi-stage-workflow/stage-2-fixer/description.txt:optional:example"
)

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check for required commands
    local missing_commands=()
    
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing_commands+=("curl or wget")
    fi
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        print_info "Please install the missing commands and try again"
        exit 1
    fi
    
    print_success "Required commands available"
    
    # Check internet connectivity
    if command -v curl >/dev/null 2>&1; then
        if ! curl -s --connect-timeout 10 https://api.github.com >/dev/null; then
            print_error "Unable to connect to GitHub API."
            echo ""
            echo -e "${YELLOW}TROUBLESHOOTING:${NC}"
            echo -e "  1. Check your internet connection"
            echo -e "  2. If behind a proxy, set:"
            echo -e "     ${CYAN}export HTTP_PROXY='http://proxy:port'${NC}"
            echo -e "     ${CYAN}export HTTPS_PROXY='http://proxy:port'${NC}"
            echo -e "  3. If firewall is blocking, allow access to:"
            echo -e "     - api.github.com"
            echo -e "     - raw.githubusercontent.com"
            echo -e "  4. Try: ${CYAN}curl -I https://api.github.com${NC}"
            echo ""
            
            # Check proxy settings
            if [[ -n "$HTTP_PROXY" ]] || [[ -n "$HTTPS_PROXY" ]]; then
                echo -e "Current proxy settings:"
                [[ -n "$HTTP_PROXY" ]] && echo -e "  HTTP_PROXY:  $HTTP_PROXY"
                [[ -n "$HTTPS_PROXY" ]] && echo -e "  HTTPS_PROXY: $HTTPS_PROXY"
            fi
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget --spider --timeout=10 https://api.github.com >/dev/null 2>&1; then
            print_error "Unable to connect to GitHub API."
            echo ""
            echo -e "${YELLOW}TROUBLESHOOTING:${NC}"
            echo -e "  1. Check your internet connection"
            echo -e "  2. If behind a proxy, set HTTP_PROXY and HTTPS_PROXY"
            echo -e "  3. Try: ${CYAN}wget --spider https://api.github.com${NC}"
            exit 1
        fi
    fi
    print_success "Internet connectivity confirmed"
    
    # Check repository visibility
    local repo_visibility
    repo_visibility=$(check_repository_visibility "$REPOSITORY")
    
    if [[ "$repo_visibility" == "private" ]]; then
        print_info "Repository is private - authentication required"
        
        # Check for authentication with detailed status
        if ! check_github_authentication "false"; then
            print_error "Private repository requires GitHub authentication."
            show_authentication_status
            show_authentication_help
            exit 1
        fi
    else
        print_success "Repository is public - no authentication required"
    fi
    
    # Check for Node.js (optional but recommended)
    if command -v node >/dev/null 2>&1; then
        local node_version
        node_version=$(node --version 2>/dev/null | sed 's/v//')
        local major_version
        major_version=$(echo "$node_version" | cut -d. -f1)
        
        if [[ "$major_version" -ge 20 ]]; then
            print_success "Node.js v$node_version detected (suitable for GitHub Copilot CLI)"
        else
            print_warning "Node.js v$node_version detected, but version 20+ is recommended for GitHub Copilot CLI"
        fi
    else
        print_warning "Node.js not found. You may need to install Node.js 20+ for GitHub Copilot CLI"
        print_info "Install from: https://nodejs.org/"
    fi
    
    # Check shell compatibility
    if [[ -n "$BASH_VERSION" ]]; then
        if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
            print_warning "Bash version ${BASH_VERSION} detected. Version 4+ recommended for best compatibility."
        else
            print_success "Bash version check passed"
        fi
    fi
    
    echo "$repo_visibility"
}

# Backup existing installation
backup_existing_installation() {
    if [[ -d "$INSTALL_PATH" ]]; then
        if [[ "$UPDATE" == true ]]; then
            local backup_path="${INSTALL_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
            print_step "Backing up existing installation to: $backup_path"
            
            if cp -r "$INSTALL_PATH" "$backup_path" 2>/dev/null; then
                print_success "Backup created successfully"
                echo "$backup_path"
            else
                print_error "Failed to create backup"
                exit 1
            fi
        else
            print_error "Installation directory already exists: $INSTALL_PATH"
            print_info "Use --update flag to update existing installation, or choose a different path"
            exit 1
        fi
    fi
}

# Download a file from GitHub
download_file() {
    local file_path="$1"
    local destination_path="$2"
    local is_required="$3"
    local is_private="$4"
    
    local url="https://raw.githubusercontent.com/$REPOSITORY/$BRANCH/$file_path"
    local destination_dir
    destination_dir=$(dirname "$destination_path")
    
    # Create directory if it doesn't exist
    if [[ ! -d "$destination_dir" ]]; then
        mkdir -p "$destination_dir"
    fi
    
    # Always try to use authentication if available (some repos may require it)
    local auth_headers=()
    local token="$GITHUB_TOKEN"
    if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
        token=$(gh auth token 2>/dev/null || true)
    fi
    
    if [[ -n "$token" ]]; then
        auth_headers=(-H "Authorization: Bearer $token")
    elif [[ "$is_private" == "private" ]]; then
        check_github_authentication "true"
        print_error "No GitHub token found for private repository access"
        show_authentication_status
        show_authentication_help
        return 1
    fi
    
    # Download file using curl or wget with status code capture
    local success=1
    local http_code=0
    
    if command -v curl >/dev/null 2>&1; then
        # Use curl with status code capture
        local temp_file=$(mktemp)
        http_code=$(curl -fsSL --connect-timeout 30 --max-time 60 \
            "${auth_headers[@]}" "$url" \
            -o "$destination_path" \
            -w "%{http_code}" 2>"$temp_file") || true
        
        # Check if successful (2xx status)
        if [[ "$http_code" =~ ^2[0-9][0-9]$ ]] && [[ -f "$destination_path" ]]; then
            success=0
        else
            # Read any error from temp file
            local curl_error=$(cat "$temp_file" 2>/dev/null)
            rm -f "$temp_file"
            
            # Handle connection errors
            if [[ -z "$http_code" ]] || [[ "$http_code" == "000" ]]; then
                http_code=0
            fi
        fi
        rm -f "$temp_file"
    elif command -v wget >/dev/null 2>&1; then
        local auth_header=""
        if [[ ${#auth_headers[@]} -gt 0 ]]; then
            for header in "${auth_headers[@]}"; do
                if [[ "$header" == "Authorization: Bearer "* ]]; then
                    auth_header="--header=$header"
                    break
                fi
            done
        fi
        
        # wget doesn't easily return status codes, check via exit code
        if wget --timeout=30 --tries=3 $auth_header "$url" -O "$destination_path" >/dev/null 2>&1; then
            success=0
            http_code=200
        else
            # Try to determine error type from exit code
            local wget_exit=$?
            case $wget_exit in
                3) http_code=0 ;;   # File I/O error
                4) http_code=0 ;;   # Network failure
                5) http_code=403 ;; # SSL verification failure
                6) http_code=401 ;; # Authentication required
                7) http_code=500 ;; # Protocol error
                8) http_code=404 ;; # Server issued error (usually 404)
                *) http_code=0 ;;
            esac
        fi
    fi
    
    if [[ $success -eq 0 ]]; then
        print_success "Downloaded: $file_path"
        return 0
    else
        # Get actionable error message
        get_http_error_message "$http_code" "$url"
        
        if [[ "$is_required" == "required" ]]; then
            print_error "Failed to download required file: $file_path"
            print_http_error "$HTTP_ERROR_MSG" "$HTTP_ERROR_HELP"
            return 1
        else
            print_warning "Failed to download optional file: $file_path ($HTTP_ERROR_MSG)"
            return 0
        fi
    fi
}

# Set executable permissions
set_executable_permissions() {
    print_step "Setting executable permissions..."
    
    local shell_script="$INSTALL_PATH/automation/copilot-cli.sh"
    if [[ -f "$shell_script" ]]; then
        if chmod +x "$shell_script"; then
            print_success "Shell script made executable"
        else
            print_warning "Could not set executable permissions on shell script"
        fi
    fi
}

# Show post-installation instructions
show_post_install_instructions() {
    echo ""
    echo -e "${GREEN}🎉 GitHub Copilot CLI Automation Suite installed successfully!${NC}"
    echo ""
    
    echo -e "${YELLOW}📁 Installation Location: ${NC}$INSTALL_PATH"
    echo ""
    
    echo -e "${CYAN}🚀 Next Steps:${NC}"
    echo -e "  ${NC}1. Configure GitHub Authentication:"
    echo -e "     ${NC}• GitHub CLI: ${YELLOW}gh auth login${NC}"
    echo -e "     ${NC}• OR set environment variable: ${YELLOW}export GITHUB_TOKEN='your_token'${NC}"
    echo ""
    
    echo -e "  ${NC}2. Install GitHub Copilot CLI (if not already installed):"
    echo -e "     ${YELLOW}npm install -g @github/copilot${NC}"
    echo ""
    
    echo -e "  ${NC}3. Customize configuration:"
    echo -e "     ${NC}• Edit: ${YELLOW}$INSTALL_PATH/automation/copilot-cli.properties${NC}"
    echo -e "     ${NC}• Customize default prompts: ${YELLOW}$INSTALL_PATH/automation/user.prompt.md${NC}"
    echo -e "     ${NC}• Customize agent definitions: ${YELLOW}$INSTALL_PATH/automation/default.agent.md${NC}"
    if [[ "$SKIP_EXAMPLES" != true ]]; then
        echo -e "     ${NC}• Review example configurations in: ${YELLOW}$INSTALL_PATH/automation/examples/${NC}"
    fi
    echo ""
    
    echo -e "  ${NC}4. Test the installation:"
    echo -e "     ${YELLOW}cd '$INSTALL_PATH' && ./automation/copilot-cli.sh -h${NC}"
    echo ""
    
    echo -e "${CYAN}📚 Documentation:${NC}"
    echo -e "  ${NC}• Main README: ${YELLOW}$INSTALL_PATH/README.md${NC}"
    echo -e "  ${NC}• Automation Guide: ${YELLOW}$INSTALL_PATH/automation/README.md${NC}"
    echo -e "  ${NC}• GitHub Actions: ${YELLOW}$INSTALL_PATH/actions/README.md${NC}"
    echo ""
}

# Main installation function
main() {
    echo ""
    echo -e "${MAGENTA}🤖 GitHub Copilot CLI Automation Accelerator Installer${NC}"
    echo -e "${MAGENTA}========================================================${NC}"
    echo ""
    
    print_info "Repository: $REPOSITORY"
    print_info "Branch: $BRANCH"
    print_info "Installation Path: $INSTALL_PATH"
    print_info "Mode: $MODE"
    if [[ "$UPDATE" == true ]]; then
        print_info "Update Mode: Enabled"
    fi
    echo ""
    
    # Step 1: Check prerequisites (now includes repo visibility check)
    local repo_visibility
    repo_visibility=$(check_prerequisites)
    
    # Step 2: Handle existing installation
    local backup_path
    backup_path=$(backup_existing_installation)
    
    # Step 3: Create installation directory
    print_step "Creating installation directory..."
    if mkdir -p "$INSTALL_PATH"; then
        print_success "Installation directory ready: $INSTALL_PATH"
    else
        print_error "Failed to create installation directory: $INSTALL_PATH"
        exit 1
    fi
    
    # Step 4: Download all files (updated to pass repository info)
    print_step "Downloading files from repository..."
    local download_count=0
    local failed_count=0
    local skipped_examples=0
    
    for file_info in "${FILES_TO_DOWNLOAD[@]}"; do
        # Parse the 3-field format: path:required|optional:core|example
        local file_path
        local is_required
        local file_type
        file_path=$(echo "$file_info" | cut -d: -f1)
        is_required=$(echo "$file_info" | cut -d: -f2)
        file_type=$(echo "$file_info" | cut -d: -f3)
        
        # Skip example files when --skip-examples is set
        if [[ "$SKIP_EXAMPLES" == true && "$file_type" == "example" ]]; then
            skipped_examples=$((skipped_examples + 1))
            continue
        fi
        
        local destination_path="$INSTALL_PATH/$file_path"
        
        if download_file "$file_path" "$destination_path" "$is_required" "$repo_visibility"; then
            download_count=$((download_count + 1))
        else
            failed_count=$((failed_count + 1))
            if [[ "$is_required" == "required" ]]; then
                print_error "Installation failed due to missing required file: $file_path"
                
                # Restore backup if update failed
                if [[ -n "$backup_path" && -d "$backup_path" ]]; then
                    print_step "Restoring backup due to failed update..."
                    rm -rf "$INSTALL_PATH" 2>/dev/null
                    mv "$backup_path" "$INSTALL_PATH"
                    print_success "Backup restored"
                fi
                exit 1
            fi
        fi
    done
    
    print_success "Downloaded $download_count files successfully"
    if [[ $skipped_examples -gt 0 ]]; then
        print_info "Skipped $skipped_examples example agent files (--skip-examples flag set)"
    fi
    if [[ $failed_count -gt 0 ]]; then
        print_warning "$failed_count optional files could not be downloaded"
    fi
    
    # Step 5: Set permissions
    set_executable_permissions
    
    # Step 6: Clean up backup if update was successful
    if [[ -n "$backup_path" && -d "$backup_path" && "$UPDATE" == true ]]; then
        print_step "Cleaning up backup..."
        if rm -rf "$backup_path"; then
            print_success "Backup cleaned up"
        fi
    fi
    
    # Step 7: Show post-install instructions
    show_post_install_instructions
}

# Parse command line arguments and run main function
parse_args "$@"

# Trap errors and restore backup if needed
trap 'if [[ -n "$backup_path" && -d "$backup_path" ]]; then print_step "Restoring backup due to failed installation..."; rm -rf "$INSTALL_PATH" 2>/dev/null; mv "$backup_path" "$INSTALL_PATH"; print_success "Backup restored"; fi' ERR

# Run main function
main