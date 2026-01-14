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

# Color functions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ $1${NC}"; }
print_step() { echo -e "${BLUE}→ $1${NC}"; }

# Check GitHub authentication
check_github_authentication() {
    print_step "Checking GitHub authentication..."
    
    # Check for GitHub token in environment
    if [[ -n "$GITHUB_TOKEN" ]]; then
        print_success "GitHub token found in environment variable"
        return 0
    fi
    
    # Check for GitHub CLI authentication
    if command -v gh >/dev/null 2>&1; then
        if gh auth token >/dev/null 2>&1; then
            print_success "GitHub CLI authentication found"
            return 0
        fi
    fi
    
    return 1
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
        headers=(-H "Authorization: token $token")
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
            auth_header="--header=Authorization: token $token"
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
                is_private=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['private'])" 2>/dev/null || echo "false")
            elif command -v python >/dev/null 2>&1; then
                is_private=$(echo "$response" | python -c "import sys, json; print(json.load(sys.stdin)['private'])" 2>/dev/null || echo "false")
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
    -p, --path PATH       Installation directory (default: current/~/copilot-tools based on mode)
    -m, --mode MODE       Installation mode: 'current' or 'central' (default: current)
    -u, --update          Update existing installation instead of creating new one
    -b, --branch BRANCH   Git branch to download from (default: main)
    -r, --repo REPO       GitHub repository in format 'owner/repo' 
                         (default: neildcruz/copilot-cli-automation-accelerator)
    -v, --verbose         Enable verbose output
    -h, --help            Show this help message

EXAMPLES:
    $0                                    # Install in current directory
    $0 --mode central                     # Install in ~/copilot-tools
    $0 --path ~/my-tools --update         # Update installation in ~/my-tools
    $0 --branch develop --verbose         # Install from develop branch with verbose output

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
            -v|--verbose)
                VERBOSE=true
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
            INSTALL_PATH="$HOME/copilot-tools"
        else
            INSTALL_PATH="$(pwd)/copilot-cli-automation-accelerator"
        fi
    fi
}

# Files to download with their paths
declare -a FILES_TO_DOWNLOAD=(
    "README.md:required"
    "INDEX.md:required"
    "actions/README.md:required"
    "actions/QUICK_START.md:required"
    "actions/copilot-cli-action.yml:required"
    "actions/example-copilot-usage.yml:required"
    "automation/README.md:required"
    "automation/copilot-cli.sh:required"
    "automation/copilot-cli.ps1:required"
    "automation/copilot-cli.properties:required"
    "automation/user.prompt.md:optional"
    "automation/system.prompt.md:optional"
    "automation/examples/README.md:required"
    "automation/examples/mcp-config.json:optional"
    "automation/examples/code-review/code-review-agent.properties:required"
    "automation/examples/code-review/user.prompt.md:required"
    "automation/examples/code-review/system.prompt.md:required"
    "automation/examples/security-analysis/security-analysis-agent.properties:required"
    "automation/examples/security-analysis/user.prompt.md:required"
    "automation/examples/security-analysis/system.prompt.md:required"
    "automation/examples/test-generation/test-generation-agent.properties:required"
    "automation/examples/test-generation/user.prompt.md:required"
    "automation/examples/test-generation/system.prompt.md:required"
    "automation/examples/documentation-generation/documentation-generation-agent.properties:required"
    "automation/examples/documentation-generation/user.prompt.md:required"
    "automation/examples/documentation-generation/system.prompt.md:required"
    "automation/examples/refactoring/refactoring-agent.properties:required"
    "automation/examples/refactoring/user.prompt.md:required"
    "automation/examples/refactoring/system.prompt.md:required"
    "automation/examples/cicd-analysis/cicd-analysis-agent.properties:required"
    "automation/examples/cicd-analysis/user.prompt.md:required"
    "automation/examples/cicd-analysis/system.prompt.md:required"
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
            print_error "Unable to connect to GitHub API. Check your internet connection."
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget --spider --timeout=10 https://api.github.com >/dev/null 2>&1; then
            print_error "Unable to connect to GitHub API. Check your internet connection."
            exit 1
        fi
    fi
    print_success "Internet connectivity confirmed"
    
    # Check repository visibility
    local repo_visibility
    repo_visibility=$(check_repository_visibility "$REPOSITORY")
    
    if [[ "$repo_visibility" == "private" ]]; then
        print_info "Repository is private - authentication required"
        
        # Check for authentication
        if ! check_github_authentication; then
            print_error "Private repository requires GitHub authentication."
            print_info "Please set up authentication using one of these methods:"
            print_info "  1. Set environment variable: export GITHUB_TOKEN='your_token'"
            print_info "  2. Use GitHub CLI: gh auth login"
            print_info "  3. Create token at: https://github.com/settings/personal-access-tokens/new"
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
    
    local destination_dir
    destination_dir=$(dirname "$destination_path")
    
    # Create directory if it doesn't exist
    if [[ ! -d "$destination_dir" ]]; then
        mkdir -p "$destination_dir"
    fi
    
    # Prepare authentication token
    local token=""
    if [[ "$is_private" == "private" ]]; then
        token="$GITHUB_TOKEN"
        if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
            token=$(gh auth token 2>/dev/null || true)
        fi
        
        if [[ -z "$token" ]]; then
            print_error "No GitHub token found for private repository access"
            return 1
        fi
    fi
    
    # For private repositories, use GitHub API instead of raw.githubusercontent.com
    # as raw URLs don't support Authorization headers properly for private repos
    local success=false
    
    if [[ "$is_private" == "private" ]]; then
        # Use GitHub Contents API for private repositories
        local api_url="https://api.github.com/repos/$REPOSITORY/contents/$file_path?ref=$BRANCH"
        
        if command -v curl >/dev/null 2>&1; then
            # Get raw file content from API
            if [[ "$VERBOSE" == true ]]; then
                local response
                response=$(curl -fsSL --connect-timeout 30 --max-time 60 \
                    -H "Authorization: token $token" \
                    -H "Accept: application/vnd.github.v3.raw" \
                    "$api_url")
                success=$?
                if [[ $success -eq 0 ]]; then
                    echo "$response" > "$destination_path"
                fi
            else
                curl -fsSL --connect-timeout 30 --max-time 60 \
                    -H "Authorization: token $token" \
                    -H "Accept: application/vnd.github.v3.raw" \
                    "$api_url" -o "$destination_path" 2>/dev/null
                success=$?
            fi
        elif command -v wget >/dev/null 2>&1; then
            # wget version
            if [[ "$VERBOSE" == true ]]; then
                wget --timeout=30 --tries=3 \
                    --header="Authorization: token $token" \
                    --header="Accept: application/vnd.github.v3.raw" \
                    "$api_url" -O "$destination_path"
            else
                wget --timeout=30 --tries=3 \
                    --header="Authorization: token $token" \
                    --header="Accept: application/vnd.github.v3.raw" \
                    "$api_url" -O "$destination_path" >/dev/null 2>&1
            fi
            success=$?
        fi
    else
        # For public repositories, use raw.githubusercontent.com
        local url="https://raw.githubusercontent.com/$REPOSITORY/$BRANCH/$file_path"
        
        if command -v curl >/dev/null 2>&1; then
            if [[ "$VERBOSE" == true ]]; then
                curl -fsSL --connect-timeout 30 --max-time 60 "$url" -o "$destination_path"
            else
                curl -fsSL --connect-timeout 30 --max-time 60 "$url" -o "$destination_path" 2>/dev/null
            fi
            success=$?
        elif command -v wget >/dev/null 2>&1; then
            if [[ "$VERBOSE" == true ]]; then
                wget --timeout=30 --tries=3 "$url" -O "$destination_path"
            else
                wget --timeout=30 --tries=3 "$url" -O "$destination_path" >/dev/null 2>&1
            fi
            success=$?
        fi
    fi
    
    if [[ $success -eq 0 ]]; then
        print_success "Downloaded: $file_path"
        return 0
    else
        if [[ "$is_required" == "required" ]]; then
            print_error "Failed to download required file: $file_path"
            return 1
        else
            print_warning "Failed to download optional file: $file_path"
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
    echo -e "     ${NC}• Customize system prompts: ${YELLOW}$INSTALL_PATH/automation/system.prompt.md${NC}"
    echo -e "     ${NC}• Review example configurations in: ${YELLOW}$INSTALL_PATH/automation/examples/${NC}"
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
    
    for file_info in "${FILES_TO_DOWNLOAD[@]}"; do
        local file_path="${file_info%%:*}"
        local is_required="${file_info##*:}"
        local destination_path="$INSTALL_PATH/$file_path"
        
        if download_file "$file_path" "$destination_path" "$is_required" "$repo_visibility"; then
            ((download_count++))
        else
            ((failed_count++))
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