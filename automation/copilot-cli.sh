#!/bin/bash

# GitHub Copilot CLI Wrapper Script
# Provides the same functionality as the GitHub Action but for local execution
# Supports configuration via properties file and command line arguments

set -e

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/copilot-cli.properties"
PROMPT=""
PROMPT_FILE=""
SYSTEM_PROMPT=""
SYSTEM_PROMPT_FILE=""
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
MCP_CONFIG=""
MCP_CONFIG_FILE=""
COPILOT_MODEL="claude-sonnet-4.5"
AUTO_INSTALL_CLI="true"
ALLOW_ALL_TOOLS="true"
ALLOW_ALL_PATHS="false"
ADDITIONAL_DIRECTORIES=""
ALLOWED_TOOLS=""
DENIED_TOOLS=""
DISABLE_BUILTIN_MCPS="false"
DISABLE_MCP_SERVERS=""
ENABLE_ALL_GITHUB_MCP_TOOLS="false"
LOG_LEVEL="info"
WORKING_DIRECTORY="."
NODE_VERSION="22"
TIMEOUT_MINUTES="30"
DRY_RUN="false"
VERBOSE="false"

# Function to show usage
show_usage() {
    cat << EOF
GitHub Copilot CLI Wrapper Script

Usage: $0 [OPTIONS]

OPTIONS:
    -c, --config FILE               Configuration properties file (default: copilot-cli.properties)
    -p, --prompt TEXT              The prompt to execute with Copilot CLI (required unless --prompt-file is provided)
    --prompt-file FILE             Path to text/markdown file containing the prompt (overridden by -p/--prompt)
    -s, --system-prompt TEXT       System prompt with guidelines to be emphasized and followed
    --system-prompt-file FILE      Path to text/markdown file containing the system prompt (overridden by -s/--system-prompt)
    -t, --github-token TOKEN       GitHub Personal Access Token for authentication
    -m, --model MODEL              AI model to use (gpt-5, claude-sonnet-4, claude-sonnet-4.5)
    --auto-install-cli BOOL        Automatically install Copilot CLI if not found (true/false, default: true)
    --mcp-config TEXT              MCP server configuration as JSON string
    --mcp-config-file FILE         MCP server configuration file path
    --allow-all-tools BOOL         Allow all tools to run automatically (true/false)
    --allow-all-paths BOOL         Allow access to any path (true/false)
    --additional-dirs DIRS         Comma-separated list of additional directories
    --allowed-tools TOOLS          Comma-separated list of allowed tools
    --denied-tools TOOLS           Comma-separated list of denied tools
    --disable-builtin-mcps BOOL    Disable all built-in MCP servers (true/false)
    --disable-mcp-servers SERVERS  Comma-separated list of MCP servers to disable
    --enable-all-github-tools BOOL Enable all GitHub MCP tools (true/false)
    --log-level LEVEL              Log level (none, error, warning, info, debug, all)
    --working-dir DIR              Working directory to run from
    --timeout MINUTES              Timeout in minutes
    --dry-run                      Show command without executing
    --verbose                      Enable verbose output
    -h, --help                     Show this help message

EXAMPLES:
    # Basic usage with prompt
    $0 --prompt "Review the code for issues"
    
    # Using prompt from file
    $0 --prompt-file user.prompt.md
    
    # With system prompt for guidelines
    $0 --prompt "Review the code" --system-prompt "Focus on security and performance issues only"
    
    # With system prompt from file
    $0 --prompt "Review the code" --system-prompt-file system.prompt.md
    
    # Command line prompt overrides file
    $0 --prompt-file user.prompt.md --prompt "Override with this prompt"
    
    # With GitHub token authentication
    $0 --prompt "Review the code" --github-token "ghp_xxxxxxxxxxxxxxxxxxxx"
    
    # Using custom configuration file
    $0 --config my-config.properties --prompt "Analyze security"
    
    # With MCP configuration file
    $0 --prompt "Use custom tools" --mcp-config-file examples/mcp-config.json
    
    # Dry run to see generated command
    $0 --prompt "Test" --dry-run

AUTHENTICATION:
    GitHub Copilot CLI requires authentication via one of these methods (in order of precedence):
    1. --github-token command line argument
    2. github.token in properties file  
    3. GH_TOKEN environment variable
    4. GITHUB_TOKEN environment variable
    5. Existing GitHub CLI authentication (gh auth login)

CONFIGURATION FILE:
    Create a .properties file with key=value pairs for any option.
    Command line arguments override configuration file values.

EOF
}

# Function to log messages
log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
    fi
}

# Function to parse boolean values
parse_bool() {
    local value="$1"
    case "${value,,}" in
        true|yes|1|on) echo "true" ;;
        false|no|0|off) echo "false" ;;
        *) echo "$value" ;;
    esac
}

# Function to load content from file preserving formatting
load_file_content() {
    local file_path="$1"
    local content_type="$2"
    
    if [[ ! -f "$file_path" ]]; then
        echo "Error: $content_type file '$file_path' not found" >&2
        exit 1
    fi
    
    # Validate file extension
    local extension="${file_path##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    if [[ "$extension" != "txt" && "$extension" != "md" ]]; then
        log "Warning: $content_type file has extension '.$extension', expected .txt or .md"
    fi
    
    log "Loading $content_type from file: $file_path"
    
    # Read file content preserving line breaks and formatting
    # Use cat to preserve exact content
    cat "$file_path"
}

# Function to load configuration from properties file
load_config() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        log "Loading configuration from $config_file"
        while IFS='=' read -r key value || [[ -n "$key" ]]; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove leading/trailing whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Remove quotes from value if present
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            
            case "$key" in
                prompt) PROMPT="$value" ;;
                prompt.file) PROMPT_FILE="$value" ;;
                system.prompt) SYSTEM_PROMPT="$value" ;;
                system.prompt.file) SYSTEM_PROMPT_FILE="$value" ;;
                github.token) GITHUB_TOKEN="$value" ;;
                mcp.config) MCP_CONFIG="$value" ;;
                mcp.config.file) MCP_CONFIG_FILE="$value" ;;
                copilot.model) COPILOT_MODEL="$value" ;;
                auto.install.cli) AUTO_INSTALL_CLI=$(parse_bool "$value") ;;
                allow.all.tools) ALLOW_ALL_TOOLS=$(parse_bool "$value") ;;
                allow.all.paths) ALLOW_ALL_PATHS=$(parse_bool "$value") ;;
                additional.directories) ADDITIONAL_DIRECTORIES="$value" ;;
                allowed.tools) ALLOWED_TOOLS="$value" ;;
                denied.tools) DENIED_TOOLS="$value" ;;
                disable.builtin.mcps) DISABLE_BUILTIN_MCPS=$(parse_bool "$value") ;;
                disable.mcp.servers) DISABLE_MCP_SERVERS="$value" ;;
                enable.all.github.mcp.tools) ENABLE_ALL_GITHUB_MCP_TOOLS=$(parse_bool "$value") ;;
                log.level) LOG_LEVEL="$value" ;;
                working.directory) WORKING_DIRECTORY="$value" ;;
                node.version) NODE_VERSION="$value" ;;
                timeout.minutes) TIMEOUT_MINUTES="$value" ;;
            esac
        done < "$config_file"
    else
        log "Configuration file $config_file not found, using defaults"
    fi
}

# Function to validate required dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    # Check Node.js version
    if ! command -v node &> /dev/null; then
        echo "Error: Node.js is not installed" >&2
        exit 1
    fi
    
    local node_version=$(node --version | sed 's/v//')
    local major_version=$(echo "$node_version" | cut -d. -f1)
    
    if [[ "$major_version" -lt 20 ]]; then
        echo "Error: Node.js version $node_version is not supported. Minimum required: 20" >&2
        exit 1
    fi
    
    # Check if copilot CLI is installed
    if ! command -v copilot &> /dev/null; then
        if [[ "$AUTO_INSTALL_CLI" == "true" ]]; then
            echo "GitHub Copilot CLI not found. Installing latest version..."
            log "Running: npm install -g @github/copilot@latest"
            if ! npm install -g @github/copilot@latest; then
                echo "Error: Failed to install GitHub Copilot CLI" >&2
                echo "Try installing manually: npm install -g @github/copilot" >&2
                exit 1
            fi
            echo "✓ GitHub Copilot CLI installed successfully"
        else
            echo "Error: GitHub Copilot CLI is not installed" >&2
            echo "Install with: npm install -g @github/copilot" >&2
            echo "Or enable auto-install with: --auto-install-cli true" >&2
            exit 1
        fi
    else
        # Check if we should update to latest version
        if [[ "$AUTO_INSTALL_CLI" == "true" ]]; then
            log "Checking for Copilot CLI updates..."
            npm update -g @github/copilot@latest &> /dev/null || true
        fi
    fi
    
    # Check jq for JSON processing
    if ! command -v jq &> /dev/null; then
        echo "Warning: jq is not installed. JSON validation will be skipped" >&2
    fi
}

# Function to setup GitHub authentication
setup_github_auth() {
    log "Setting up GitHub authentication..."
    
    # Determine which token to use (in order of precedence)
    local token=""
    local source=""
    
    if [[ -n "$GITHUB_TOKEN" ]]; then
        token="$GITHUB_TOKEN"
        source="GITHUB_TOKEN environment variable"
    elif [[ -n "$COPILOT_GITHUB_TOKEN" ]]; then
        token="$COPILOT_GITHUB_TOKEN"
        source="COPILOT_GITHUB_TOKEN environment variable"
    elif [[ -n "$GH_TOKEN" ]]; then
        token="$GH_TOKEN"
        source="GH_TOKEN environment variable"
    fi
    
    # Set the environment variable for Copilot CLI if we have a token
    if [[ -n "$token" ]]; then
        export GH_TOKEN="$token"
        export GITHUB_TOKEN="$token"
        export COPILOT_GITHUB_TOKEN="$token"
        log "GitHub token configured from $source"
        log "Token length: ${#token} characters"
    else
        log "No GitHub token provided, relying on existing GitHub CLI authentication"
    fi
}

# Function to validate MCP configuration
validate_mcp_config() {
    local config="$1"
    
    if [[ -n "$config" ]] && command -v jq &> /dev/null; then
        if ! echo "$config" | jq . &> /dev/null; then
            echo "Error: Invalid JSON in MCP configuration" >&2
            exit 1
        fi
    fi
}

# Function to build copilot command
build_copilot_command() {
    # Combine system prompt and user prompt
    local full_prompt="$PROMPT"
    if [[ -n "$SYSTEM_PROMPT" ]]; then
        full_prompt="IMPORTANT: Please follow these guidelines strictly: $SYSTEM_PROMPT

$PROMPT"
    fi
    
    local cmd="copilot -p \"$full_prompt\""
    
    # Add model
    if [[ -n "$COPILOT_MODEL" ]]; then
        cmd="$cmd --model $COPILOT_MODEL"
    fi
    
    # Add tool permissions
    if [[ "$ALLOW_ALL_TOOLS" == "true" ]]; then
        cmd="$cmd --allow-all-tools"
    fi
    
    # Always add --allow-all-paths flag
    cmd="$cmd --allow-all-paths"
    
    # Add allowed tools
    if [[ -n "$ALLOWED_TOOLS" ]]; then
        IFS=',' read -ra TOOLS <<< "$ALLOWED_TOOLS"
        for tool in "${TOOLS[@]}"; do
            tool=$(echo "$tool" | xargs)  # Trim whitespace
            cmd="$cmd --allow-tool \"$tool\""
        done
    fi
    
    # Add denied tools
    if [[ -n "$DENIED_TOOLS" ]]; then
        IFS=',' read -ra TOOLS <<< "$DENIED_TOOLS"
        for tool in "${TOOLS[@]}"; do
            tool=$(echo "$tool" | xargs)  # Trim whitespace
            cmd="$cmd --deny-tool \"$tool\""
        done
    fi
    
    # Add additional directories
    if [[ -n "$ADDITIONAL_DIRECTORIES" ]]; then
        IFS=',' read -ra DIRS <<< "$ADDITIONAL_DIRECTORIES"
        for dir in "${DIRS[@]}"; do
            dir=$(echo "$dir" | xargs)  # Trim whitespace
            cmd="$cmd --add-dir \"$dir\""
        done
    fi
    
    # Add MCP configuration
    if [[ -n "$MCP_CONFIG_FILE" ]]; then
        if [[ ! -f "$MCP_CONFIG_FILE" ]]; then
            echo "Error: MCP configuration file '$MCP_CONFIG_FILE' not found" >&2
            exit 1
        fi
        cmd="$cmd --additional-mcp-config @$MCP_CONFIG_FILE"
    elif [[ -n "$MCP_CONFIG" ]]; then
        # Create temporary file for MCP config
        local temp_mcp_file=$(mktemp)
        echo "$MCP_CONFIG" > "$temp_mcp_file"
        cmd="$cmd --additional-mcp-config @$temp_mcp_file"
        
        # Store temp file path for cleanup
        TEMP_MCP_FILE="$temp_mcp_file"
    fi
    
    # Add MCP server options
    if [[ "$DISABLE_BUILTIN_MCPS" == "true" ]]; then
        cmd="$cmd --disable-builtin-mcps"
    fi
    
    if [[ "$ENABLE_ALL_GITHUB_MCP_TOOLS" == "true" ]]; then
        cmd="$cmd --enable-all-github-mcp-tools"
    fi
    
    # Add disabled MCP servers
    if [[ -n "$DISABLE_MCP_SERVERS" ]]; then
        IFS=',' read -ra SERVERS <<< "$DISABLE_MCP_SERVERS"
        for server in "${SERVERS[@]}"; do
            server=$(echo "$server" | xargs)  # Trim whitespace
            cmd="$cmd --disable-mcp-server \"$server\""
        done
    fi
    
    # Add log level
    if [[ -n "$LOG_LEVEL" ]]; then
        cmd="$cmd --log-level $LOG_LEVEL"
    fi
    
    echo "$cmd"
}

# Function to cleanup temporary files
cleanup() {
    if [[ -n "$TEMP_MCP_FILE" ]] && [[ -f "$TEMP_MCP_FILE" ]]; then
        rm -f "$TEMP_MCP_FILE"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -p|--prompt)
            PROMPT="$2"
            shift 2
            ;;
        --prompt-file)
            PROMPT_FILE="$2"
            shift 2
            ;;
        -s|--system-prompt)
            SYSTEM_PROMPT="$2"
            shift 2
            ;;
        --system-prompt-file)
            SYSTEM_PROMPT_FILE="$2"
            shift 2
            ;;
        -t|--github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -m|--model)
            COPILOT_MODEL="$2"
            shift 2
            ;;
        --auto-install-cli)
            AUTO_INSTALL_CLI=$(parse_bool "$2")
            shift 2
            ;;
        --mcp-config)
            MCP_CONFIG="$2"
            shift 2
            ;;
        --mcp-config-file)
            MCP_CONFIG_FILE="$2"
            shift 2
            ;;
        --allow-all-tools)
            ALLOW_ALL_TOOLS=$(parse_bool "$2")
            shift 2
            ;;
        --allow-all-paths)
            ALLOW_ALL_PATHS=$(parse_bool "$2")
            shift 2
            ;;
        --additional-dirs)
            ADDITIONAL_DIRECTORIES="$2"
            shift 2
            ;;
        --allowed-tools)
            ALLOWED_TOOLS="$2"
            shift 2
            ;;
        --denied-tools)
            DENIED_TOOLS="$2"
            shift 2
            ;;
        --disable-builtin-mcps)
            DISABLE_BUILTIN_MCPS=$(parse_bool "$2")
            shift 2
            ;;
        --disable-mcp-servers)
            DISABLE_MCP_SERVERS="$2"
            shift 2
            ;;
        --enable-all-github-tools)
            ENABLE_ALL_GITHUB_MCP_TOOLS=$(parse_bool "$2")
            shift 2
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        --working-dir)
            WORKING_DIRECTORY="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT_MINUTES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Load configuration file
load_config "$CONFIG_FILE"

# Load prompts from files if specified (command line params override)
# Load prompt from file if PROMPT_FILE is specified and PROMPT is empty
if [[ -z "$PROMPT" && -n "$PROMPT_FILE" ]]; then
    PROMPT=$(load_file_content "$PROMPT_FILE" "Prompt")
fi

# Load system prompt from file if SYSTEM_PROMPT_FILE is specified and SYSTEM_PROMPT is empty
if [[ -z "$SYSTEM_PROMPT" && -n "$SYSTEM_PROMPT_FILE" ]]; then
    SYSTEM_PROMPT=$(load_file_content "$SYSTEM_PROMPT_FILE" "System prompt")
fi

# Validate required parameters
if [[ -z "$PROMPT" ]]; then
    echo "Error: Prompt is required. Use --prompt, --prompt-file, or set prompt/prompt.file in config file." >&2
    exit 1
fi

# Check dependencies
check_dependencies

# Setup GitHub authentication
setup_github_auth

# Validate MCP configuration if provided
if [[ -n "$MCP_CONFIG" ]]; then
    validate_mcp_config "$MCP_CONFIG"
fi

# Change to working directory
if [[ "$WORKING_DIRECTORY" != "." ]]; then
    log "Changing to working directory: $WORKING_DIRECTORY"
    if [[ ! -d "$WORKING_DIRECTORY" ]]; then
        echo "Error: Working directory '$WORKING_DIRECTORY' does not exist" >&2
        exit 1
    fi
    cd "$WORKING_DIRECTORY"
fi

# Build and execute command
COPILOT_CMD=$(build_copilot_command)

echo "Generated Copilot CLI command:"
echo "$COPILOT_CMD"
echo

if [[ "$DRY_RUN" == "true" ]]; then
    echo "Dry run mode - command not executed"
    exit 0
fi

# Execute the command with timeout
log "Executing Copilot CLI command..."

# Debug: Show that tokens are set (without revealing them)
log "GH_TOKEN is set: $([ -n "$GH_TOKEN" ] && echo 'yes' || echo 'no')"
log "GITHUB_TOKEN is set: $([ -n "$GITHUB_TOKEN" ] && echo 'yes' || echo 'no')"
log "COPILOT_GITHUB_TOKEN is set: $([ -n "$COPILOT_GITHUB_TOKEN" ] && echo 'yes' || echo 'no')"

# Explicitly export auth environment variables
export GH_TOKEN GITHUB_TOKEN COPILOT_GITHUB_TOKEN

if command -v timeout &> /dev/null; then
    # Use timeout with --preserve-status to properly propagate exit codes
    # The environment variables are already exported, so they will be inherited
    timeout --preserve-status "${TIMEOUT_MINUTES}m" eval "$COPILOT_CMD"
else
    # Fallback for systems without timeout command
    eval "$COPILOT_CMD"
fi

echo "Copilot CLI execution completed successfully"