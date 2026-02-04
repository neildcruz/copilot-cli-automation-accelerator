#!/bin/bash

# GitHub Copilot CLI Wrapper Script
# A zero-config wrapper for GitHub Copilot CLI with prompt repository integration,
# automatic installation, and CI/CD-optimized execution.

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
NO_COLOR="false"

# New: Prompt repository options
USE_PROMPT=""
DEFAULT_PROMPT_REPO="github/awesome-copilot"
PROMPT_CACHE_DIR=""
LIST_PROMPTS="false"
SEARCH_PROMPTS=""
PROMPT_INFO=""
UPDATE_PROMPT_CACHE="false"

# New: CLI parity options
AGENT=""
ALLOW_ALL_URLS="false"
ALLOW_URLS=""
DENY_URLS=""
AVAILABLE_TOOLS=""
EXCLUDED_TOOLS=""
ADD_GITHUB_MCP_TOOL=""
ADD_GITHUB_MCP_TOOLSET=""
NO_ASK_USER="false"
SILENT="false"
CONFIG_DIR=""
SHARE=""
SHARE_GIST="false"
RESUME=""
CONTINUE_SESSION="false"
INIT="false"
LIST_AGENTS="false"
USE_DEFAULTS="false"

# Function to show usage
show_usage() {
    cat << 'EOF'
GitHub Copilot CLI Wrapper Script

A zero-config wrapper for GitHub Copilot CLI with prompt repository integration,
automatic installation, and CI/CD-optimized execution.

Usage: ./copilot-cli.sh [OPTIONS]

QUICK START:
    ./copilot-cli.sh --agent code-review                # Use built-in agent
    ./copilot-cli.sh --use-defaults                     # Use built-in default prompts
    ./copilot-cli.sh --list-agents                      # List available agents
    ./copilot-cli.sh --prompt "Review this code"        # Direct prompt
    ./copilot-cli.sh --init                             # Initialize project config

BUILT-IN AGENTS:
    --list-agents                  List all available built-in agents
    --agent NAME                   Use a built-in agent by name
                                   Examples: code-review, security-analysis, test-generation

PROMPT REPOSITORY OPTIONS:
    --use-prompt NAME              Use a prompt from GitHub repository
                                   Format: name (uses default repo) or owner/repo:name
    --default-prompt-repo REPO     Default repository for prompts (default: github/awesome-copilot)
    --prompt-cache-dir DIR         Directory to cache downloaded prompts
    --list-prompts                 List available prompts from default repository
    --search-prompts QUERY         Search prompts by keyword
    --prompt-info NAME             Show detailed information about a prompt
    --update-prompt-cache          Force refresh of cached prompts

PROMPT OPTIONS:
    -c, --config FILE              Configuration properties file (default: copilot-cli.properties)
    -p, --prompt TEXT              The prompt to execute
    --prompt-file FILE             Load prompt from text/markdown file
    -s, --system-prompt TEXT       System prompt with guidelines to emphasize
    --system-prompt-file FILE      Load system prompt from file
    --use-defaults                 Use built-in default prompts (useful for quick analysis)

MODEL & AGENT OPTIONS:
    -m, --model MODEL              AI model (gpt-5, claude-sonnet-4, claude-sonnet-4.5)
    --agent AGENT                  Specify a custom agent to use

TOOL PERMISSIONS:
    --allow-all-tools BOOL         Allow all tools automatically (default: true)
    --allow-all-paths BOOL         Allow access to any filesystem path (default: false)
    --allow-all-urls BOOL          Allow access to all URLs (default: false)
    --allowed-tools TOOLS          Comma-separated list of allowed tools
    --denied-tools TOOLS           Comma-separated list of denied tools
    --available-tools TOOLS        Limit which tools are available
    --excluded-tools TOOLS         Exclude specific tools
    --allow-urls URLS              Comma-separated list of allowed URLs/domains
    --deny-urls URLS               Comma-separated list of denied URLs/domains
    --additional-dirs DIRS         Comma-separated list of additional directories

MCP SERVER OPTIONS:
    --mcp-config TEXT              MCP server configuration as JSON string
    --mcp-config-file FILE         MCP server configuration file path
    --disable-builtin-mcps BOOL    Disable all built-in MCP servers (default: false)
    --disable-mcp-servers SERVERS  Comma-separated list of MCP servers to disable
    --enable-all-github-tools BOOL Enable all GitHub MCP tools (default: false)
    --add-github-mcp-tool TOOLS    Add specific GitHub MCP tools
    --add-github-mcp-toolset SETS  Add GitHub MCP toolsets

SESSION & OUTPUT OPTIONS:
    --continue                     Resume the most recent session
    --resume SESSION-ID            Resume a specific session
    --share PATH                   Save session to markdown file
    --share-gist                   Share session as a secret GitHub gist
    --silent                       Output only agent response

EXECUTION OPTIONS:
    --no-ask-user BOOL             Disable interactive questions (autonomous mode)
    --config-dir PATH              Set the configuration directory
    --working-dir DIR              Working directory to run from
    --timeout MINUTES              Timeout in minutes (default: 30)
    --log-level LEVEL              Log level (none, error, warning, info, debug, all)
    --no-color                     Disable colored output
    --dry-run                      Show command without executing
    --verbose                      Enable verbose output

SETUP OPTIONS:
    -t, --github-token TOKEN       GitHub Personal Access Token
    --auto-install-cli BOOL        Auto-install Copilot CLI if not found (default: true)
    --init                         Initialize project with starter configuration
    -h, --help                     Show this help message

EXAMPLES:
    # Use a pre-built prompt from awesome-copilot
    ./copilot-cli.sh --use-prompt code-review
    
    # Use a prompt from a custom repository
    ./copilot-cli.sh --use-prompt myorg/prompts:security-audit
    
    # Autonomous mode for CI/CD
    ./copilot-cli.sh --use-prompt code-review --no-ask-user true --silent
    
    # Initialize a new project
    ./copilot-cli.sh --init

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

# Function to get prompt cache directory
get_prompt_cache_dir() {
    if [[ -n "$PROMPT_CACHE_DIR" ]]; then
        echo "$PROMPT_CACHE_DIR"
    else
        echo "${HOME}/.copilot-cli-automation/prompts"
    fi
}

# Function to parse prompt reference (owner/repo:name or just name)
parse_prompt_reference() {
    local reference="$1"
    
    if [[ "$reference" =~ ^([^/:]+)/([^/:]+):(.+)$ ]]; then
        PARSED_OWNER="${BASH_REMATCH[1]}"
        PARSED_REPO="${BASH_REMATCH[2]}"
        PARSED_FULL_REPO="${PARSED_OWNER}/${PARSED_REPO}"
        local path_and_name="${BASH_REMATCH[3]}"
        
        if [[ "$path_and_name" =~ ^(.+)/([^/]+)$ ]]; then
            PARSED_PATH="${BASH_REMATCH[1]}"
            PARSED_NAME="${BASH_REMATCH[2]}"
        else
            PARSED_PATH="prompts"
            PARSED_NAME="$path_and_name"
        fi
    else
        IFS='/' read -r PARSED_OWNER PARSED_REPO <<< "$DEFAULT_PROMPT_REPO"
        PARSED_FULL_REPO="$DEFAULT_PROMPT_REPO"
        PARSED_PATH="prompts"
        PARSED_NAME="$reference"
    fi
}

# Function to get cached prompt path
get_cached_prompt_path() {
    local cache_dir
    cache_dir=$(get_prompt_cache_dir)
    local repo_dir="${cache_dir}/${PARSED_OWNER}/${PARSED_REPO}"
    
    local file_name="$PARSED_NAME"
    if [[ ! "$file_name" =~ \.prompt\.md$ ]]; then
        file_name="${file_name}.prompt.md"
    fi
    
    echo "${repo_dir}/${file_name}"
}

# Function to fetch prompt from GitHub repository
get_remote_prompt() {
    local prompt_reference="$1"
    local force_refresh="${2:-false}"
    
    parse_prompt_reference "$prompt_reference"
    local cached_path
    cached_path=$(get_cached_prompt_path)
    
    if [[ "$force_refresh" != "true" && -f "$cached_path" ]]; then
        log "Using cached prompt: $cached_path"
        cat "$cached_path"
        return 0
    fi
    
    local file_name="$PARSED_NAME"
    if [[ ! "$file_name" =~ \.prompt\.md$ ]]; then
        file_name="${file_name}.prompt.md"
    fi
    
    local url="https://raw.githubusercontent.com/${PARSED_FULL_REPO}/main/${PARSED_PATH}/${file_name}"
    
    echo "Fetching prompt from: $url" >&2
    log "Fetching prompt from URL: $url"
    
    local content
    if content=$(curl -fsSL "$url" 2>/dev/null); then
        local cache_dir
        cache_dir=$(dirname "$cached_path")
        mkdir -p "$cache_dir"
        echo "$content" > "$cached_path"
        log "Cached prompt to: $cached_path"
        echo "$content"
    else
        if [[ -f "$cached_path" ]]; then
            echo "Warning: Could not fetch remote prompt, using cached version" >&2
            cat "$cached_path"
        else
            echo "Error: Failed to fetch prompt '$prompt_reference' from $url" >&2
            exit 1
        fi
    fi
}

# Function to parse prompt file frontmatter
parse_prompt_frontmatter() {
    local content="$1"
    
    FRONTMATTER_DESCRIPTION=""
    FRONTMATTER_TOOLS=""
    FRONTMATTER_AGENT=""
    FRONTMATTER_BODY="$content"
    
    # Simple frontmatter extraction
    if [[ "$content" == ---* ]]; then
        local body_start
        body_start=$(echo "$content" | grep -n "^---$" | sed -n '2p' | cut -d: -f1)
        if [[ -n "$body_start" ]]; then
            FRONTMATTER_BODY=$(echo "$content" | tail -n +$((body_start + 1)))
            local frontmatter
            frontmatter=$(echo "$content" | head -n $((body_start - 1)) | tail -n +2)
            
            if echo "$frontmatter" | grep -q "description:"; then
                FRONTMATTER_DESCRIPTION=$(echo "$frontmatter" | grep "description:" | sed "s/description:[[:space:]]*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/")
            fi
            if echo "$frontmatter" | grep -q "agent:"; then
                FRONTMATTER_AGENT=$(echo "$frontmatter" | grep "agent:" | sed "s/agent:[[:space:]]*['\"]\\?\\([^'\"]*\\)['\"]\\?.*/\\1/")
            fi
        fi
    fi
}

# Function to list prompts from a repository
get_prompt_list() {
    local repo="${1:-$DEFAULT_PROMPT_REPO}"
    local api_url="https://api.github.com/repos/${repo}/contents/prompts"
    
    echo "Fetching prompt list from: $repo" >&2
    
    local auth_header=""
    if [[ -n "$GH_TOKEN" ]]; then
        auth_header="-H \"Authorization: token $GH_TOKEN\""
    fi
    
    local response
    if response=$(eval curl -fsSL $auth_header "$api_url" 2>/dev/null); then
        echo "$response" | grep -o '"name": "[^"]*\.prompt\.md"' | sed 's/"name": "//g; s/\.prompt\.md"//g'
    else
        echo "Error: Failed to list prompts from $repo" >&2
        exit 1
    fi
}

# Function to show prompt information
show_prompt_info() {
    local prompt_reference="$1"
    
    local content
    content=$(get_remote_prompt "$prompt_reference")
    parse_prompt_frontmatter "$content"
    parse_prompt_reference "$prompt_reference"
    
    echo ""
    echo "Prompt: $PARSED_NAME"
    echo "Repository: $PARSED_FULL_REPO"
    echo ""
    
    if [[ -n "$FRONTMATTER_DESCRIPTION" ]]; then
        echo "Description: $FRONTMATTER_DESCRIPTION"
        echo ""
    fi
    
    if [[ -n "$FRONTMATTER_AGENT" ]]; then
        echo "Agent: $FRONTMATTER_AGENT"
    fi
    
    echo "Preview (first 500 chars):"
    echo "${FRONTMATTER_BODY:0:500}..."
}

# Function to display prompt list
show_prompt_list() {
    local prompts="$1"
    
    if [[ -z "$prompts" ]]; then
        echo "No prompts found."
        return
    fi
    
    local count
    count=$(echo "$prompts" | wc -l)
    
    echo ""
    echo "Available Prompts ($count found):"
    echo ""
    
    echo "$prompts" | sort | while read -r prompt; do
        echo "  $prompt"
    done
    
    echo ""
    echo "Usage: --use-prompt <name> or --use-prompt owner/repo:name"
}

# Function to initialize a new project with copilot-cli configuration
initialize_project() {
    local config_path="./copilot-cli.properties"
    
    if [[ -f "$config_path" ]]; then
        echo "Configuration file already exists: $config_path"
        return
    fi
    
    cat > "$config_path" << 'CONFIGEOF'
# Copilot CLI Wrapper Configuration
# Generated by copilot-cli.sh --init

prompt.file=user.prompt.md
system.prompt.file=system.prompt.md
copilot.model=claude-sonnet-4.5
allow.all.tools=true
allow.all.paths=false
timeout.minutes=30
log.level=info
CONFIGEOF

    cat > "./user.prompt.md" << 'USEREOF'
# User Prompt

Analyze this codebase and provide a summary of:
1. The project structure and architecture
2. Key technologies and frameworks used
3. Potential areas for improvement
USEREOF

    cat > "./system.prompt.md" << 'SYSEOF'
# System Prompt

You are a helpful AI assistant focused on code quality and best practices.
Please follow these guidelines:
- Be thorough but concise in your analysis
- Provide actionable recommendations
- Consider security, performance, and maintainability
SYSEOF

    echo "Initialized Copilot CLI configuration:"
    echo "  - $config_path"
    echo "  - ./user.prompt.md"
    echo "  - ./system.prompt.md"
    echo ""
    echo "Edit these files and run: ./copilot-cli.sh"
}

# Function to get built-in agents from examples directory
get_builtin_agents() {
    local examples_dir="${SCRIPT_DIR}/examples"
    
    if [[ ! -d "$examples_dir" ]]; then
        return
    fi
    
    for agent_dir in "$examples_dir"/*/; do
        if [[ ! -d "$agent_dir" ]]; then
            continue
        fi
        
        local agent_name=$(basename "$agent_dir")
        
        # Check if this is a valid agent directory
        local has_config=false
        local has_prompt=false
        
        if [[ -f "${agent_dir}copilot-cli.properties" ]] || ls "${agent_dir}"*.properties &>/dev/null; then
            has_config=true
        fi
        
        if [[ -f "${agent_dir}user.prompt.md" ]] || [[ -f "${agent_dir}system.prompt.md" ]]; then
            has_prompt=true
        fi
        
        if [[ "$has_config" == "true" ]] || [[ "$has_prompt" == "true" ]]; then
            local description=""
            if [[ -f "${agent_dir}description.txt" ]]; then
                description=$(cat "${agent_dir}description.txt" | head -1)
            fi
            echo "${agent_name}|${description}"
        fi
    done
}

# Function to display built-in agents list
show_builtin_agents() {
    local agents
    agents=$(get_builtin_agents)
    
    if [[ -z "$agents" ]]; then
        echo "No built-in agents found in examples directory."
        return
    fi
    
    echo ""
    echo "Built-in Agents:"
    echo ""
    
    # Find max name length for formatting
    local max_len=20
    while IFS='|' read -r name desc; do
        if [[ ${#name} -gt $max_len ]]; then
            max_len=${#name}
        fi
    done <<< "$agents"
    
    # Display agents
    while IFS='|' read -r name desc; do
        printf "  %-${max_len}s  %s\n" "$name" "$desc"
    done <<< "$agents" | sort
    
    echo ""
    echo "Usage: --agent <name>  (e.g., --agent code-review)"
}

# Function to check if agent is a built-in agent and get its config
get_builtin_agent_config() {
    local agent_name="$1"
    local examples_dir="${SCRIPT_DIR}/examples"
    local agent_dir="${examples_dir}/${agent_name}"
    
    if [[ ! -d "$agent_dir" ]]; then
        return 1
    fi
    
    # Export configuration paths
    BUILTIN_AGENT_PATH="$agent_dir"
    BUILTIN_AGENT_PROPS=""
    BUILTIN_AGENT_USER_PROMPT=""
    BUILTIN_AGENT_SYSTEM_PROMPT=""
    
    # Look for properties file
    if [[ -f "${agent_dir}/copilot-cli.properties" ]]; then
        BUILTIN_AGENT_PROPS="${agent_dir}/copilot-cli.properties"
    else
        local props_file
        props_file=$(ls "${agent_dir}"/*.properties 2>/dev/null | head -1)
        if [[ -n "$props_file" ]]; then
            BUILTIN_AGENT_PROPS="$props_file"
        fi
    fi
    
    # Look for prompt files
    if [[ -f "${agent_dir}/user.prompt.md" ]]; then
        BUILTIN_AGENT_USER_PROMPT="${agent_dir}/user.prompt.md"
    fi
    
    if [[ -f "${agent_dir}/system.prompt.md" ]]; then
        BUILTIN_AGENT_SYSTEM_PROMPT="${agent_dir}/system.prompt.md"
    fi
    
    return 0
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

# Function to check if prompt content has meaningful text (not just comments)
has_meaningful_content() {
    local content="$1"
    local content_type="$2"
    
    if [[ -z "$content" ]]; then
        return 1
    fi
    
    # Remove HTML comments and check if anything meaningful remains
    local without_comments
    without_comments=$(echo "$content" | sed 's/<!--.*-->//g' | sed 's/<!--//g; s/-->//g')
    # Remove markdown headers that are just titles and empty lines
    local meaningful
    meaningful=$(echo "$without_comments" | grep -v '^#' | grep -v '^[[:space:]]*$' | head -1)
    
    if [[ -z "$meaningful" ]]; then
        echo "Warning: $content_type appears to contain only comments or headers. The prompt may not produce meaningful results." >&2
        echo "Tip: Add actual instructions to your prompt file, or use --use-defaults to use the built-in default prompts." >&2
        return 1
    fi
    
    return 0
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
                # New: Prompt repository options
                use.prompt) [[ -z "$USE_PROMPT" ]] && USE_PROMPT="$value" ;;
                default.prompt.repo) DEFAULT_PROMPT_REPO="$value" ;;
                prompt.cache.dir) [[ -z "$PROMPT_CACHE_DIR" ]] && PROMPT_CACHE_DIR="$value" ;;
                # New: CLI parity options
                agent) [[ -z "$AGENT" ]] && AGENT="$value" ;;
                allow.all.urls) ALLOW_ALL_URLS=$(parse_bool "$value") ;;
                allow.urls) [[ -z "$ALLOW_URLS" ]] && ALLOW_URLS="$value" ;;
                deny.urls) [[ -z "$DENY_URLS" ]] && DENY_URLS="$value" ;;
                available.tools) [[ -z "$AVAILABLE_TOOLS" ]] && AVAILABLE_TOOLS="$value" ;;
                excluded.tools) [[ -z "$EXCLUDED_TOOLS" ]] && EXCLUDED_TOOLS="$value" ;;
                add.github.mcp.tool) [[ -z "$ADD_GITHUB_MCP_TOOL" ]] && ADD_GITHUB_MCP_TOOL="$value" ;;
                add.github.mcp.toolset) [[ -z "$ADD_GITHUB_MCP_TOOLSET" ]] && ADD_GITHUB_MCP_TOOLSET="$value" ;;
                no.ask.user) NO_ASK_USER=$(parse_bool "$value") ;;
                config.dir) [[ -z "$CONFIG_DIR" ]] && CONFIG_DIR="$value" ;;
                share) [[ -z "$SHARE" ]] && SHARE="$value" ;;
                resume) [[ -z "$RESUME" ]] && RESUME="$value" ;;
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
    
    # Add agent if specified
    if [[ -n "$AGENT" ]]; then
        cmd="$cmd --agent \"$AGENT\""
    fi
    
    # Add tool permissions
    if [[ "$ALLOW_ALL_TOOLS" == "true" ]]; then
        cmd="$cmd --allow-all-tools"
    fi
    
    # Add --allow-all-paths flag only if explicitly enabled (FIXED: was always adding this)
    if [[ "$ALLOW_ALL_PATHS" == "true" ]]; then
        cmd="$cmd --allow-all-paths"
    fi
    
    # Add URL permissions
    if [[ "$ALLOW_ALL_URLS" == "true" ]]; then
        cmd="$cmd --allow-all-urls"
    fi
    
    # Add allowed URLs
    if [[ -n "$ALLOW_URLS" ]]; then
        IFS=',' read -ra URLS <<< "$ALLOW_URLS"
        for url in "${URLS[@]}"; do
            url=$(echo "$url" | xargs)
            cmd="$cmd --allow-url \"$url\""
        done
    fi
    
    # Add denied URLs
    if [[ -n "$DENY_URLS" ]]; then
        IFS=',' read -ra URLS <<< "$DENY_URLS"
        for url in "${URLS[@]}"; do
            url=$(echo "$url" | xargs)
            cmd="$cmd --deny-url \"$url\""
        done
    fi
    
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
    
    # Add available tools
    if [[ -n "$AVAILABLE_TOOLS" ]]; then
        IFS=',' read -ra TOOLS <<< "$AVAILABLE_TOOLS"
        for tool in "${TOOLS[@]}"; do
            tool=$(echo "$tool" | xargs)
            cmd="$cmd --available-tools \"$tool\""
        done
    fi
    
    # Add excluded tools
    if [[ -n "$EXCLUDED_TOOLS" ]]; then
        IFS=',' read -ra TOOLS <<< "$EXCLUDED_TOOLS"
        for tool in "${TOOLS[@]}"; do
            tool=$(echo "$tool" | xargs)
            cmd="$cmd --excluded-tools \"$tool\""
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
    
    # Add GitHub MCP tools
    if [[ -n "$ADD_GITHUB_MCP_TOOL" ]]; then
        IFS=',' read -ra TOOLS <<< "$ADD_GITHUB_MCP_TOOL"
        for tool in "${TOOLS[@]}"; do
            tool=$(echo "$tool" | xargs)
            cmd="$cmd --add-github-mcp-tool \"$tool\""
        done
    fi
    
    # Add GitHub MCP toolsets
    if [[ -n "$ADD_GITHUB_MCP_TOOLSET" ]]; then
        IFS=',' read -ra TOOLSETS <<< "$ADD_GITHUB_MCP_TOOLSET"
        for toolset in "${TOOLSETS[@]}"; do
            toolset=$(echo "$toolset" | xargs)
            cmd="$cmd --add-github-mcp-toolset \"$toolset\""
        done
    fi
    
    # Add disabled MCP servers
    if [[ -n "$DISABLE_MCP_SERVERS" ]]; then
        IFS=',' read -ra SERVERS <<< "$DISABLE_MCP_SERVERS"
        for server in "${SERVERS[@]}"; do
            server=$(echo "$server" | xargs)  # Trim whitespace
            cmd="$cmd --disable-mcp-server \"$server\""
        done
    fi
    
    # Add autonomous mode
    if [[ "$NO_ASK_USER" == "true" ]]; then
        cmd="$cmd --no-ask-user"
    fi
    
    # Add config directory
    if [[ -n "$CONFIG_DIR" ]]; then
        cmd="$cmd --config-dir \"$CONFIG_DIR\""
    fi
    
    # Add session resume options
    if [[ "$CONTINUE_SESSION" == "true" ]]; then
        cmd="$cmd --continue"
    elif [[ -n "$RESUME" ]]; then
        cmd="$cmd --resume \"$RESUME\""
    fi
    
    # Add share options
    if [[ -n "$SHARE" ]]; then
        cmd="$cmd --share \"$SHARE\""
    fi
    if [[ "$SHARE_GIST" == "true" ]]; then
        cmd="$cmd --share-gist"
    fi
    
    # Add silent mode
    if [[ "$SILENT" == "true" ]]; then
        cmd="$cmd --silent"
    fi
    
    # Add log level
    if [[ -n "$LOG_LEVEL" ]]; then
        cmd="$cmd --log-level $LOG_LEVEL"
    fi
    
    # Add no-color flag conditionally (auto-detect CI/CD)
    local is_ci="false"
    [[ -n "$CI" || -n "$GITHUB_ACTIONS" || -n "$TF_BUILD" || -n "$JENKINS_URL" ]] && is_ci="true"
    if [[ "$NO_COLOR" == "true" || "$is_ci" == "true" ]]; then
        cmd="$cmd --no-color"
        log "No-color mode enabled for better output compatibility"
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
        --agent)
            AGENT="$2"
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
        --allow-all-urls)
            ALLOW_ALL_URLS=$(parse_bool "$2")
            shift 2
            ;;
        --allow-urls)
            ALLOW_URLS="$2"
            shift 2
            ;;
        --deny-urls)
            DENY_URLS="$2"
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
        --available-tools)
            AVAILABLE_TOOLS="$2"
            shift 2
            ;;
        --excluded-tools)
            EXCLUDED_TOOLS="$2"
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
        --add-github-mcp-tool)
            ADD_GITHUB_MCP_TOOL="$2"
            shift 2
            ;;
        --add-github-mcp-toolset)
            ADD_GITHUB_MCP_TOOLSET="$2"
            shift 2
            ;;
        --no-ask-user)
            NO_ASK_USER=$(parse_bool "$2")
            shift 2
            ;;
        --silent)
            SILENT="true"
            shift
            ;;
        --config-dir)
            CONFIG_DIR="$2"
            shift 2
            ;;
        --share)
            SHARE="$2"
            shift 2
            ;;
        --share-gist)
            SHARE_GIST="true"
            shift
            ;;
        --continue)
            CONTINUE_SESSION="true"
            shift
            ;;
        --resume)
            RESUME="$2"
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
        --no-color)
            NO_COLOR="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        # New: Prompt repository options
        --use-prompt)
            USE_PROMPT="$2"
            shift 2
            ;;
        --default-prompt-repo)
            DEFAULT_PROMPT_REPO="$2"
            shift 2
            ;;
        --prompt-cache-dir)
            PROMPT_CACHE_DIR="$2"
            shift 2
            ;;
        --list-prompts)
            LIST_PROMPTS="true"
            shift
            ;;
        --search-prompts)
            SEARCH_PROMPTS="$2"
            shift 2
            ;;
        --prompt-info)
            PROMPT_INFO="$2"
            shift 2
            ;;
        --update-prompt-cache)
            UPDATE_PROMPT_CACHE="true"
            shift
            ;;
        --init)
            INIT="true"
            shift
            ;;
        --list-agents)
            LIST_AGENTS="true"
            shift
            ;;
        --use-defaults)
            USE_DEFAULTS="true"
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

# Handle --init command
if [[ "$INIT" == "true" ]]; then
    initialize_project
    exit 0
fi

# Handle --list-agents command
if [[ "$LIST_AGENTS" == "true" ]]; then
    show_builtin_agents
    exit 0
fi

# Handle --agent: check if it's a built-in agent first
if [[ -n "$AGENT" ]]; then
    if get_builtin_agent_config "$AGENT"; then
        echo "Using built-in agent: $AGENT"
        
        # Load the agent's properties file if it exists
        if [[ -n "$BUILTIN_AGENT_PROPS" ]]; then
            CONFIG_FILE="$BUILTIN_AGENT_PROPS"
        fi
        
        # Set prompt files if not already set
        if [[ -z "$PROMPT_FILE" ]] && [[ -n "$BUILTIN_AGENT_USER_PROMPT" ]]; then
            PROMPT_FILE="$BUILTIN_AGENT_USER_PROMPT"
        fi
        if [[ -z "$SYSTEM_PROMPT_FILE" ]] && [[ -n "$BUILTIN_AGENT_SYSTEM_PROMPT" ]]; then
            SYSTEM_PROMPT_FILE="$BUILTIN_AGENT_SYSTEM_PROMPT"
        fi
        
        # Clear the AGENT variable so it doesn't get passed to copilot CLI
        AGENT=""
    fi
fi

# Load configuration file
load_config "$CONFIG_FILE"

# Setup GitHub authentication early (needed for API calls)
setup_github_auth

# Handle --list-prompts command
if [[ "$LIST_PROMPTS" == "true" ]]; then
    prompts=$(get_prompt_list "$DEFAULT_PROMPT_REPO")
    show_prompt_list "$prompts"
    exit 0
fi

# Handle --search-prompts command
if [[ -n "$SEARCH_PROMPTS" ]]; then
    echo "Searching for '$SEARCH_PROMPTS' in $DEFAULT_PROMPT_REPO..."
    prompts=$(get_prompt_list "$DEFAULT_PROMPT_REPO" | grep -i "$SEARCH_PROMPTS" || echo "")
    show_prompt_list "$prompts"
    exit 0
fi

# Handle --prompt-info command
if [[ -n "$PROMPT_INFO" ]]; then
    show_prompt_info "$PROMPT_INFO"
    exit 0
fi

# Handle --update-prompt-cache command
if [[ "$UPDATE_PROMPT_CACHE" == "true" ]]; then
    echo "Updating prompt cache..."
    prompts=$(get_prompt_list "$DEFAULT_PROMPT_REPO")
    while read -r prompt; do
        [[ -z "$prompt" ]] && continue
        if get_remote_prompt "$prompt" "true" > /dev/null 2>&1; then
            echo "  Cached: $prompt"
        else
            echo "  Failed: $prompt"
        fi
    done <<< "$prompts"
    echo "Cache update complete."
    exit 0
fi

# Handle --use-prompt: fetch prompt from remote repository
if [[ -n "$USE_PROMPT" ]]; then
    log "Fetching prompt: $USE_PROMPT"
    prompt_content=$(get_remote_prompt "$USE_PROMPT")
    parse_prompt_frontmatter "$prompt_content"
    
    # Use the prompt body as the main prompt
    if [[ -z "$PROMPT" ]]; then
        PROMPT="$FRONTMATTER_BODY"
    fi
    
    # If the prompt specifies an agent and we don't have one, use it
    if [[ -z "$AGENT" && -n "$FRONTMATTER_AGENT" ]]; then
        AGENT="$FRONTMATTER_AGENT"
        log "Using agent from prompt: $AGENT"
    fi
fi

# Handle --use-defaults: use built-in default prompt files
if [[ "$USE_DEFAULTS" == "true" ]]; then
    echo "Using built-in default prompts"
    PROMPT_FILE="${SCRIPT_DIR}/user.prompt.md"
    SYSTEM_PROMPT_FILE="${SCRIPT_DIR}/system.prompt.md"
    # Clear any inline prompts to force loading from files
    PROMPT=""
    SYSTEM_PROMPT=""
fi

# Load prompts from files if specified (command line params override)
# Load prompt from file if PROMPT_FILE is specified and PROMPT is empty
if [[ -z "$PROMPT" && -n "$PROMPT_FILE" ]]; then
    PROMPT=$(load_file_content "$PROMPT_FILE" "Prompt")
fi

# Load system prompt from file if SYSTEM_PROMPT_FILE is specified and SYSTEM_PROMPT is empty
if [[ -z "$SYSTEM_PROMPT" && -n "$SYSTEM_PROMPT_FILE" ]]; then
    SYSTEM_PROMPT=$(load_file_content "$SYSTEM_PROMPT_FILE" "System prompt")
fi

# Validate that prompts have meaningful content (not just comments)
if [[ -n "$PROMPT" ]]; then
    has_meaningful_content "$PROMPT" "User prompt" || true
fi
if [[ -n "$SYSTEM_PROMPT" ]]; then
    has_meaningful_content "$SYSTEM_PROMPT" "System prompt" || true
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

# Explicitly export auth environment variables - these are automatically inherited by child processes
export GH_TOKEN GITHUB_TOKEN COPILOT_GITHUB_TOKEN

# Run the command directly (no subshell needed since we just want to run copilot)
if command -v timeout &> /dev/null; then
    # Debug inside the subshell to verify inheritance
    timeout --preserve-status "${TIMEOUT_MINUTES}m" bash -c "
        echo '[DEBUG] Inside subshell - GH_TOKEN is set:' \$([ -n \"\$GH_TOKEN\" ] && echo 'yes ('\${#GH_TOKEN}' chars)' || echo 'no')
        echo '[DEBUG] Inside subshell - GITHUB_TOKEN is set:' \$([ -n \"\$GITHUB_TOKEN\" ] && echo 'yes' || echo 'no')
        echo '[DEBUG] Inside subshell - COPILOT_GITHUB_TOKEN is set:' \$([ -n \"\$COPILOT_GITHUB_TOKEN\" ] && echo 'yes' || echo 'no')
        $COPILOT_CMD
    "
else
    eval "$COPILOT_CMD"
fi

echo "Copilot CLI execution completed successfully"