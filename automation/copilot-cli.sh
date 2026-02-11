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
AGENT_FILE=""
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
VIEW_AGENT=""
USE_DEFAULTS="false"

# Multi-agent composition options
AGENTS=""
AGENT_ERROR_MODE="continue"

# Custom agent directories
AGENT_DIRECTORY=""
ADDITIONAL_AGENT_DIRECTORIES=""

# Remote agent repository cache
AGENT_CACHE_DIR=""
UPDATE_AGENT_CACHE="false"

# Agent creation options
AS_AGENT="false"
AGENT_NAME=""

# Diagnostic mode
DIAGNOSE="false"

# Function to show usage
show_usage() {
    cat << 'EOF'
GitHub Copilot CLI Wrapper Script

A zero-config wrapper for GitHub Copilot CLI with prompt repository integration,
automatic installation, and CI/CD-optimized execution.

Usage: ./copilot-cli.sh [OPTIONS]

QUICK START:
    ./copilot-cli.sh --agent code-review                # Use built-in agent
    ./copilot-cli.sh --agents "security,code-review"    # Run multiple agents
    ./copilot-cli.sh --use-defaults                     # Use built-in default prompts
    ./copilot-cli.sh --list-agents                      # List available agents
    ./copilot-cli.sh --prompt "Review this code"        # Direct prompt
    ./copilot-cli.sh --init                             # Initialize project config

BUILT-IN AGENTS:
    --list-agents                  List all available built-in and custom agents
    --view-agent NAME              Show detailed configuration for a specific agent
    --agent NAME                   Use an agent by name or path
                                   Examples: code-review, ./my-agents/custom, /path/to/agent
    --agents NAMES                 Run multiple agents sequentially (comma-separated)
                                   Example: --agents "security-analysis,code-review"
    --agent-error-mode MODE        Behavior on agent failure: 'continue' (default) or 'stop'

CUSTOM AGENT MANAGEMENT:
    --agent-directory DIR          Primary custom agent directory (local path or remote repo)
                                   Local:  --agent-directory ./my-agents
                                   Remote: --agent-directory owner/repo
                                   Remote with branch: --agent-directory owner/repo@branch
                                   Remote single agent: --agent-directory owner/repo:agent-name
    --additional-agent-dirs DIRS   Comma-separated list of additional agent directories
                                   Each entry can be a local path or remote repo reference
    --agent-cache-dir DIR          Directory to cache downloaded remote agents
                                   (default: ~/.copilot-cli-automation/agents/)
    --update-agent-cache           Force re-download of cached remote agents
    --init --as-agent              Create a new custom agent (requires --agent-name)
    --agent-name NAME              Name for new agent (used with --init --as-agent)
                                   Example: --init --as-agent --agent-name "dotnet-review"

REMOTE AGENT REPOSITORY FORMAT:
    Remote agent repositories must have this structure:
      <repo-root>/agents/<agent-name>/
    Each agent subdirectory can contain:
      - copilot-cli.properties     Agent configuration overrides
      - user.prompt.md             User prompt/task definition
      - <agent-name>.agent.md      GitHub custom agent definition
      - description.txt            One-line description for --list-agents
      - mcp-config.json            MCP server configuration

AGENT DISCOVERY ORDER (first match wins):
    1. --agent-directory parameter (local or remote)
    2. --additional-agent-dirs parameter (local or remote)
    3. COPILOT_AGENT_DIRECTORIES environment variable (colon-separated)
    4. .copilot-agents/ in current directory
    5. Built-in examples directory

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
    --agent-file FILE              Path to a .agent.md custom agent file
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
    --diagnose                     Run comprehensive system check and show status report
    -h, --help                     Show this help message

EXAMPLES:
    # Create a custom agent
    ./copilot-cli.sh --init --as-agent --agent-name "my-review"
    # Then use it
    ./copilot-cli.sh --agent my-review
    
    # Use agent by path
    ./copilot-cli.sh --agent ./custom-agents/dotnet-standards
    
    # List all agents (built-in and custom)
    ./copilot-cli.sh --list-agents
    
    # View detailed agent configuration
    ./copilot-cli.sh --view-agent code-review
    
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

# Function to run comprehensive system diagnostics
show_diagnostic_status() {
    echo ""
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  GitHub Copilot CLI - System Diagnostics${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo ""
    
    local all_passed=true
    local warnings=0
    
    # 1. Node.js Check
    echo -e "${YELLOW}Node.js:${NC}"
    if command -v node &>/dev/null; then
        local node_version=$(node --version)
        local major_version=$(echo "$node_version" | sed 's/v//' | cut -d. -f1)
        if [[ "$major_version" -ge 20 ]]; then
            echo -e "  ${GREEN}✓ Version: $node_version (meets requirement >=20)${NC}"
        else
            echo -e "  ${YELLOW}⚠ Version: $node_version (recommended: >=20)${NC}"
            ((warnings++))
        fi
        local node_path=$(which node)
        echo -e "  ✓ Path: $node_path"
    else
        echo -e "  ${RED}✗ Not installed or not in PATH${NC}"
        echo -e "    → Install from: ${CYAN}https://nodejs.org/${NC}"
        all_passed=false
    fi
    echo ""
    
    # 2. npm Check
    echo -e "${YELLOW}npm:${NC}"
    if command -v npm &>/dev/null; then
        local npm_version=$(npm --version)
        echo -e "  ${GREEN}✓ Version: $npm_version${NC}"
    else
        echo -e "  ${RED}✗ Not available${NC}"
        all_passed=false
    fi
    echo ""
    
    # 3. GitHub Copilot CLI Check
    echo -e "${YELLOW}GitHub Copilot CLI:${NC}"
    if command -v copilot &>/dev/null; then
        local copilot_version=$(copilot --version 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✓ Installed: $copilot_version${NC}"
    else
        echo -e "  ${RED}✗ Not installed${NC}"
        echo -e "    → Install with: ${CYAN}npm install -g @github/copilot${NC}"
        all_passed=false
    fi
    echo ""
    
    # 4. GitHub Authentication Check
    echo -e "${YELLOW}GitHub Authentication:${NC}"
    local has_auth=false
    
    if [[ -n "$GITHUB_TOKEN" ]]; then
        echo -e "  ${GREEN}✓ GITHUB_TOKEN: Set (${#GITHUB_TOKEN} chars)${NC}"
        has_auth=true
    else
        echo -e "  ○ GITHUB_TOKEN: Not set"
    fi
    
    if [[ -n "$GH_TOKEN" ]]; then
        echo -e "  ${GREEN}✓ GH_TOKEN: Set (${#GH_TOKEN} chars)${NC}"
        has_auth=true
    else
        echo -e "  ○ GH_TOKEN: Not set"
    fi
    
    if [[ -n "$COPILOT_GITHUB_TOKEN" ]]; then
        echo -e "  ${GREEN}✓ COPILOT_GITHUB_TOKEN: Set${NC}"
        has_auth=true
    else
        echo -e "  ○ COPILOT_GITHUB_TOKEN: Not set"
    fi
    
    if command -v gh &>/dev/null && gh auth token &>/dev/null; then
        echo -e "  ${GREEN}✓ GitHub CLI: Authenticated${NC}"
        has_auth=true
    else
        echo -e "  ○ GitHub CLI: Not authenticated"
    fi
    
    if [[ "$has_auth" != "true" ]]; then
        echo -e "  ${YELLOW}⚠ No authentication configured${NC}"
        echo -e "    → Run: ${CYAN}gh auth login${NC}"
        echo -e "    → Or set: ${CYAN}export GITHUB_TOKEN='ghp_...'${NC}"
        ((warnings++))
    fi
    echo ""
    
    # 5. Network Check
    echo -e "${YELLOW}Network:${NC}"
    if curl -s --connect-timeout 5 https://api.github.com &>/dev/null; then
        echo -e "  ${GREEN}✓ GitHub API: Accessible${NC}"
    else
        echo -e "  ${RED}✗ GitHub API: Not accessible${NC}"
        echo -e "    → Check internet connection or proxy settings"
        all_passed=false
    fi
    
    if [[ -n "$HTTP_PROXY" ]] || [[ -n "$HTTPS_PROXY" ]]; then
        echo -e "  ${GREEN}✓ Proxy configured:${NC}"
        [[ -n "$HTTP_PROXY" ]] && echo "    HTTP_PROXY: $HTTP_PROXY"
        [[ -n "$HTTPS_PROXY" ]] && echo "    HTTPS_PROXY: $HTTPS_PROXY"
    fi
    echo ""
    
    # 6. Configuration Check
    echo -e "${YELLOW}Configuration:${NC}"
    local config_path="${SCRIPT_DIR}/copilot-cli.properties"
    if [[ -f "$config_path" ]]; then
        echo -e "  ${GREEN}✓ Properties file: $config_path${NC}"
    else
        echo "  ○ Properties file: Not found (using defaults)"
    fi
    
    local mcp_path="${SCRIPT_DIR}/mcp-config.json"
    if [[ -f "$mcp_path" ]]; then
        if command -v jq &>/dev/null && jq . "$mcp_path" &>/dev/null; then
            echo -e "  ${GREEN}✓ MCP config: $mcp_path (valid JSON)${NC}"
        else
            echo -e "  ${RED}✗ MCP config: $mcp_path (invalid JSON)${NC}"
            all_passed=false
        fi
    else
        echo "  ○ MCP config: Not found (will be skipped)"
    fi
    echo ""
    
    # 7. Working Directory
    echo -e "${YELLOW}Working Directory:${NC}"
    echo -e "  ${GREEN}✓ Current: $(pwd)${NC}"
    if [[ -d ".git" ]]; then
        echo -e "  ${GREEN}✓ Git repository detected${NC}"
    fi
    echo ""
    
    # 8. Built-in Agents
    echo -e "${YELLOW}Built-in Agents:${NC}"
    local agents=$(get_builtin_agents)
    if [[ -n "$agents" ]]; then
        local agent_count=$(echo "$agents" | wc -l)
        echo -e "  ${GREEN}✓ Available: $agent_count agents${NC}"
        echo "$agents" | head -5 | while IFS='|' read -r name desc; do
            echo "    - $name"
        done
        if [[ $agent_count -gt 5 ]]; then
            echo "    - ... and $((agent_count - 5)) more"
        fi
    else
        echo "  ○ No built-in agents found"
    fi
    echo ""
    
    # Summary
    echo -e "${CYAN}=========================================${NC}"
    if [[ "$all_passed" == "true" ]] && [[ $warnings -eq 0 ]]; then
        echo -e "  ${GREEN}Ready to run: YES ✓${NC}"
    elif [[ "$all_passed" == "true" ]]; then
        echo -e "  ${YELLOW}Ready to run: YES (with $warnings warning(s))${NC}"
    else
        echo -e "  ${RED}Ready to run: NO ✗${NC}"
        echo -e "  ${YELLOW}Fix the issues above and run --diagnose again${NC}"
    fi
    echo -e "${CYAN}=========================================${NC}"
    echo ""
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
    # Check if this is agent creation mode
    if [[ "$AS_AGENT" == "true" ]]; then
        if [[ -z "$AGENT_NAME" ]]; then
            echo "Error: --agent-name is required when using --as-agent" >&2
            echo "Example: --init --as-agent --agent-name 'my-custom-agent'" >&2
            return 1
        fi
        
        # Create agent in .copilot-agents/ directory
        local agents_base_dir="./.copilot-agents"
        local agent_dir="${agents_base_dir}/${AGENT_NAME}"
        
        if [[ -d "$agent_dir" ]]; then
            echo "Error: Agent '$AGENT_NAME' already exists at: $agent_dir" >&2
            return 1
        fi
        
        # Create agent directory structure
        mkdir -p "$agent_dir"
        
        # Create configuration file
        cat > "${agent_dir}/copilot-cli.properties" << CONFIGEOF
# Custom Agent Configuration: ${AGENT_NAME}
# Generated by copilot-cli.sh --init --as-agent

prompt.file=user.prompt.md
agent.file=${AGENT_NAME}.agent.md
copilot.model=claude-sonnet-4.5
allow.all.tools=true
allow.all.paths=false

# GitHub Authentication (if needed)
# github.token=ghp_xxxxxxxxxxxxxxxxxxxx

log.level=info
timeout.minutes=30
CONFIGEOF

        # Create user prompt
        cat > "${agent_dir}/user.prompt.md" << USERPROMPTEOF
# User Prompt: ${AGENT_NAME}

<!-- 
This file contains the main prompt/task for your custom agent.
Edit this file to specify what you want Copilot to analyze or do.

Example prompts:
- Analyze this C# codebase for SOLID principle violations
- Review this Python code for async/await best practices
- Check this JavaScript code for security vulnerabilities
- Generate unit tests for the service layer
-->

Analyze this codebase and:
1. [Describe your first task]
2. [Describe your second task]
3. [Describe your third task]

Provide specific, actionable recommendations.
USERPROMPTEOF

        # Create agent file (.agent.md with YAML frontmatter)
        cat > "${agent_dir}/${AGENT_NAME}.agent.md" << AGENTEOF
---
name: ${AGENT_NAME}
description: "Custom agent: ${AGENT_NAME}"
tools:
  - read
  - edit
  - search
---

# ${AGENT_NAME}

You are an expert code reviewer focused on:
- Code quality and maintainability
- Best practices and design patterns
- Security and performance

Provide:
- Clear, actionable recommendations
- Examples of improvements when possible
- Priority levels for each finding
AGENTEOF

        # Create description file
        echo "Custom agent: ${AGENT_NAME}" > "${agent_dir}/description.txt"
        
        echo ""
        echo "Created custom agent '$AGENT_NAME':"
        echo "  Location: $agent_dir"
        echo ""
        echo "Files created:"
        echo "  - copilot-cli.properties"
        echo "  - user.prompt.md"
        echo "  - ${AGENT_NAME}.agent.md"
        echo "  - description.txt"
        echo ""
        echo "Next steps:"
        echo "  1. Edit the prompt files in: $agent_dir"
        echo "  2. Run: ./copilot-cli.sh --agent $AGENT_NAME"
        echo ""
        return 0
    fi
    
    # Standard project initialization (original behavior)
    local config_path="./copilot-cli.properties"
    
    if [[ -f "$config_path" ]]; then
        echo "Configuration file already exists: $config_path"
        return
    fi
    
    cat > "$config_path" << 'CONFIGEOF'
# Copilot CLI Wrapper Configuration
# Generated by copilot-cli.sh --init

prompt.file=user.prompt.md
agent.file=default.agent.md

# Custom Agent Directories
# agent.directory=./.copilot-agents
# additional.agent.directories=./ci/agents,./custom-agents

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

    cat > "./default.agent.md" << 'SYSEOF'
---
name: default
description: "Default analysis agent"
tools:
  - read
  - edit
  - search
---

# Default Agent

You are a helpful AI assistant focused on code quality and best practices.
Please follow these guidelines:
- Be thorough but concise in your analysis
- Provide actionable recommendations
- Consider security, performance, and maintainability
SYSEOF

    echo "Initialized Copilot CLI configuration:"
    echo "  - $config_path"
    echo "  - ./user.prompt.md"
    echo "  - ./default.agent.md"
    echo ""
    echo "Edit these files and run: ./copilot-cli.sh"
}

# Function to install an agent .agent.md file to .github/agents/ in the working directory
install_agent_to_repository() {
    local agent_file="$1"
    local agent_name="$2"
    
    if [[ -z "$agent_file" ]] || [[ ! -f "$agent_file" ]]; then
        log "No agent file to install or file not found: $agent_file"
        return
    fi
    
    local agent_filename
    agent_filename=$(basename "$agent_file")
    local target_dir="$(pwd)/.github/agents"
    local target_file="${target_dir}/${agent_filename}"
    
    if [[ -f "$target_file" ]]; then
        log "Agent file already installed at: $target_file"
        return
    fi
    
    mkdir -p "$target_dir"
    cp "$agent_file" "$target_file"
    echo -e "${GREEN}Installed agent '${agent_name}' to: ${target_file}${NC}"
    log "Copied agent file from $agent_file to $target_file"
}

# ============================================================================
# Remote Agent Repository Functions
# ============================================================================

# Function to detect if a string references a remote GitHub repository (not a local path)
is_remote_agent_ref() {
    local ref="$1"
    
    [[ -z "$ref" ]] && return 1
    
    # If it looks like a local path, it's not remote
    [[ "$ref" == .* ]] && return 1
    [[ "$ref" == /* ]] && return 1
    [[ "$ref" == ~* ]] && return 1
    
    # If it exists as a local directory, it's not remote
    local resolved
    resolved=$(resolve_file_path "$ref")
    [[ -d "$resolved" ]] && return 1
    
    # Match owner/repo[@branch][:agent-name] pattern
    if [[ "$ref" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(@[A-Za-z0-9_./%+-]+)?(:[A-Za-z0-9_.-]+)?$ ]]; then
        return 0
    fi
    
    return 1
}

# Function to parse a remote agent repository reference
# Sets global variables: PARSED_REPO_OWNER, PARSED_REPO_NAME, PARSED_REPO_BRANCH,
# PARSED_REPO_AGENT_NAME, PARSED_REPO_IS_ALL, PARSED_REPO_FULL
parse_agent_repo_reference() {
    local ref="$1"
    
    PARSED_REPO_OWNER=""
    PARSED_REPO_NAME=""
    PARSED_REPO_BRANCH="main"
    PARSED_REPO_AGENT_NAME=""
    PARSED_REPO_IS_ALL="true"
    PARSED_REPO_FULL=""
    
    local remaining="$ref"
    
    # Extract agent name after last ':'
    if [[ "$remaining" =~ ^(.+):([^:@]+)$ ]]; then
        remaining="${BASH_REMATCH[1]}"
        PARSED_REPO_AGENT_NAME="${BASH_REMATCH[2]}"
        PARSED_REPO_IS_ALL="false"
    fi
    
    # Extract branch after '@'
    if [[ "$remaining" =~ ^(.+)@(.+)$ ]]; then
        remaining="${BASH_REMATCH[1]}"
        PARSED_REPO_BRANCH="${BASH_REMATCH[2]}"
    fi
    
    # Parse owner/repo
    if [[ "$remaining" =~ ^([^/]+)/(.+)$ ]]; then
        PARSED_REPO_OWNER="${BASH_REMATCH[1]}"
        PARSED_REPO_NAME="${BASH_REMATCH[2]}"
        PARSED_REPO_FULL="${PARSED_REPO_OWNER}/${PARSED_REPO_NAME}"
    else
        print_error "Invalid remote agent reference '$ref'. Expected format: owner/repo[@branch][:agent-name]"
        return 1
    fi
    
    return 0
}

# Function to get the agent cache directory
get_agent_cache_dir() {
    if [[ -n "$AGENT_CACHE_DIR" ]]; then
        echo "$AGENT_CACHE_DIR"
    else
        echo "${HOME}/.copilot-cli-automation/agents"
    fi
}

# Function to sync (download) agents from a remote GitHub repository
# Outputs synced agent directory paths, one per line
sync_remote_agent_repo() {
    local reference="$1"
    local force_refresh="${2:-false}"
    
    parse_agent_repo_reference "$reference" || return 1
    
    local cache_base
    cache_base=$(get_agent_cache_dir)
    local repo_cache="$cache_base/$PARSED_REPO_OWNER/$PARSED_REPO_NAME"
    
    # Known files that can exist in an agent directory
    local known_files=("copilot-cli.properties" "user.prompt.md" "description.txt" "mcp-config.json")
    
    # Prepare authentication
    local auth_header=""
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    if [[ -z "$token" ]] && command -v gh >/dev/null 2>&1; then
        token=$(gh auth token 2>/dev/null || true)
    fi
    if [[ -n "$token" ]]; then
        auth_header="Authorization: Bearer $token"
    fi
    
    local synced_paths=()
    
    if [[ "$PARSED_REPO_IS_ALL" == "true" ]]; then
        # List all subdirectories under agents/
        local api_url="https://api.github.com/repos/$PARSED_REPO_FULL/contents/agents?ref=$PARSED_REPO_BRANCH"
        log "Fetching agent list from: $api_url"
        
        local response
        local http_code
        local temp_file
        temp_file=$(mktemp)
        
        local curl_args=(-s -w "\n%{http_code}" --connect-timeout 30 --max-time 60
            -H "Accept: application/vnd.github.v3+json"
            -H "User-Agent: CopilotCLI-AgentSync")
        [[ -n "$auth_header" ]] && curl_args+=(-H "$auth_header")
        
        response=$(curl "${curl_args[@]}" "$api_url" 2>"$temp_file")
        http_code=$(echo "$response" | tail -n1)
        response=$(echo "$response" | sed '$d')
        rm -f "$temp_file"
        
        if [[ "$http_code" != "200" ]]; then
            case "$http_code" in
                404) print_error "Repository '$PARSED_REPO_FULL' not found or has no 'agents/' directory"
                     echo -e "  Expected structure: $PARSED_REPO_FULL/agents/<agent-name>/" >&2 ;;
                401|403) print_error "Authentication required for '$PARSED_REPO_FULL'. Set GITHUB_TOKEN or run 'gh auth login'" ;;
                *) print_error "Failed to list agents from $PARSED_REPO_FULL (HTTP $http_code)" ;;
            esac
            return 1
        fi
        
        # Parse directory names from JSON response (find "name" fields where "type" is "dir")
        local agent_names=()
        if command -v jq >/dev/null 2>&1; then
            while IFS= read -r name; do
                [[ -n "$name" ]] && agent_names+=("$name")
            done < <(echo "$response" | jq -r '.[] | select(.type == "dir") | .name' 2>/dev/null)
        elif command -v python3 >/dev/null 2>&1; then
            while IFS= read -r name; do
                [[ -n "$name" ]] && agent_names+=("$name")
            done < <(echo "$response" | python3 -c "import sys, json; [print(e['name']) for e in json.load(sys.stdin) if e.get('type') == 'dir']" 2>/dev/null)
        else
            # Fallback: basic grep parsing
            while IFS= read -r name; do
                [[ -n "$name" ]] && agent_names+=("$name")
            done < <(echo "$response" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
        fi
        
        if [[ ${#agent_names[@]} -eq 0 ]]; then
            print_warning "No agent directories found in $PARSED_REPO_FULL/agents/"
            return 0
        fi
        
        for agent_name in "${agent_names[@]}"; do
            local agent_cache_path="$repo_cache/$agent_name"
            
            # Skip if cached and not force refresh
            if [[ "$force_refresh" != "true" ]] && [[ -d "$agent_cache_path" ]] && \
               [[ $(find "$agent_cache_path" -maxdepth 1 -type f 2>/dev/null | wc -l) -gt 0 ]]; then
                log "Using cached agent: $agent_name"
                synced_paths+=("$agent_cache_path")
                continue
            fi
            
            # Create cache directory
            mkdir -p "$agent_cache_path"
            
            # Download known files
            local downloaded_any=false
            for file_name in "${known_files[@]}"; do
                local file_url="https://raw.githubusercontent.com/$PARSED_REPO_FULL/$PARSED_REPO_BRANCH/agents/$agent_name/$file_name"
                local dest_path="$agent_cache_path/$file_name"
                local dl_args=(-fsSL --connect-timeout 15 --max-time 30 -H "User-Agent: CopilotCLI-AgentSync")
                [[ -n "$auth_header" ]] && dl_args+=(-H "$auth_header")
                
                if curl "${dl_args[@]}" "$file_url" -o "$dest_path" 2>/dev/null; then
                    downloaded_any=true
                else
                    rm -f "$dest_path"
                fi
            done
            
            # Also try {agent-name}.agent.md
            local agent_md_url="https://raw.githubusercontent.com/$PARSED_REPO_FULL/$PARSED_REPO_BRANCH/agents/$agent_name/$agent_name.agent.md"
            local agent_md_dest="$agent_cache_path/$agent_name.agent.md"
            local dl_args=(-fsSL --connect-timeout 15 --max-time 30 -H "User-Agent: CopilotCLI-AgentSync")
            [[ -n "$auth_header" ]] && dl_args+=(-H "$auth_header")
            
            if curl "${dl_args[@]}" "$agent_md_url" -o "$agent_md_dest" 2>/dev/null; then
                downloaded_any=true
            else
                rm -f "$agent_md_dest"
            fi
            
            if [[ "$downloaded_any" == true ]]; then
                print_success "Synced remote agent: $agent_name (from $PARSED_REPO_FULL)"
                synced_paths+=("$agent_cache_path")
            fi
        done
    else
        # Single agent mode
        local agent_name="$PARSED_REPO_AGENT_NAME"
        local agent_cache_path="$repo_cache/$agent_name"
        
        # Skip if cached and not force refresh
        if [[ "$force_refresh" != "true" ]] && [[ -d "$agent_cache_path" ]] && \
           [[ $(find "$agent_cache_path" -maxdepth 1 -type f 2>/dev/null | wc -l) -gt 0 ]]; then
            log "Using cached agent: $agent_name"
            echo "$agent_cache_path"
            return 0
        fi
        
        # Create cache directory
        mkdir -p "$agent_cache_path"
        
        # Download known files
        local downloaded_any=false
        for file_name in "${known_files[@]}"; do
            local file_url="https://raw.githubusercontent.com/$PARSED_REPO_FULL/$PARSED_REPO_BRANCH/agents/$agent_name/$file_name"
            local dest_path="$agent_cache_path/$file_name"
            local dl_args=(-fsSL --connect-timeout 15 --max-time 30 -H "User-Agent: CopilotCLI-AgentSync")
            [[ -n "$auth_header" ]] && dl_args+=(-H "$auth_header")
            
            if curl "${dl_args[@]}" "$file_url" -o "$dest_path" 2>/dev/null; then
                downloaded_any=true
            else
                rm -f "$dest_path"
            fi
        done
        
        # Also try {agent-name}.agent.md
        local agent_md_url="https://raw.githubusercontent.com/$PARSED_REPO_FULL/$PARSED_REPO_BRANCH/agents/$agent_name/$agent_name.agent.md"
        local agent_md_dest="$agent_cache_path/$agent_name.agent.md"
        local dl_args=(-fsSL --connect-timeout 15 --max-time 30 -H "User-Agent: CopilotCLI-AgentSync")
        [[ -n "$auth_header" ]] && dl_args+=(-H "$auth_header")
        
        if curl "${dl_args[@]}" "$agent_md_url" -o "$agent_md_dest" 2>/dev/null; then
            downloaded_any=true
        else
            rm -f "$agent_md_dest"
        fi
        
        if [[ "$downloaded_any" == true ]]; then
            print_success "Synced remote agent: $agent_name (from $PARSED_REPO_FULL)"
            synced_paths+=("$agent_cache_path")
        else
            print_error "Agent '$agent_name' not found in $PARSED_REPO_FULL/agents/"
        fi
    fi
    
    # Output synced paths
    for p in "${synced_paths[@]}"; do
        echo "$p"
    done
}

# Function to get built-in agents from examples directory and custom directories
get_builtin_agents() {
    local search_dirs=()
    declare -A seen_names
    
    # 1. User-specified primary directory (highest priority)
    # Supports both local paths and remote repo references (owner/repo[@branch][:agent-name])
    if [[ -n "$AGENT_DIRECTORY" ]]; then
        if is_remote_agent_ref "$AGENT_DIRECTORY"; then
            local first_path=""
            while IFS= read -r rp; do
                if [[ -n "$rp" ]]; then
                    # Capture the first path to derive the parent directory
                    if [[ -z "$first_path" ]]; then
                        first_path="$rp"
                    fi
                fi
            done < <(sync_remote_agent_repo "$AGENT_DIRECTORY" "$UPDATE_AGENT_CACHE")
            # Add the parent directory (repo cache) so agent subdirectories are discoverable
            if [[ -n "$first_path" ]]; then
                local repo_parent
                repo_parent=$(dirname "$first_path")
                search_dirs+=("$repo_parent")
            fi
            log "Synced remote agent directory: $AGENT_DIRECTORY"
        elif [[ -d "$AGENT_DIRECTORY" ]]; then
            search_dirs+=("$AGENT_DIRECTORY")
            log "Using custom agent directory: $AGENT_DIRECTORY"
        fi
    fi
    
    # 2. User-specified additional directories
    # Each entry can independently be a local path or remote repo reference
    if [[ -n "$ADDITIONAL_AGENT_DIRECTORIES" ]]; then
        IFS=',' read -ra dirs <<< "$ADDITIONAL_AGENT_DIRECTORIES"
        for dir in "${dirs[@]}"; do
            dir=$(echo "$dir" | xargs)  # Trim whitespace
            if [[ -n "$dir" ]]; then
                if is_remote_agent_ref "$dir"; then
                    local first_rp=""
                    while IFS= read -r rp; do
                        if [[ -n "$rp" ]]; then
                            if [[ -z "$first_rp" ]]; then
                                first_rp="$rp"
                            fi
                        fi
                    done < <(sync_remote_agent_repo "$dir" "$UPDATE_AGENT_CACHE")
                    # Add the parent directory (repo cache) so agent subdirectories are discoverable
                    if [[ -n "$first_rp" ]]; then
                        local rp_parent
                        rp_parent=$(dirname "$first_rp")
                        search_dirs+=("$rp_parent")
                    fi
                    log "Synced remote additional agent directory: $dir"
                elif [[ -d "$dir" ]]; then
                    search_dirs+=("$dir")
                    log "Using additional agent directory: $dir"
                fi
            fi
        done
    fi
    
    # 3. Environment variable (COPILOT_AGENT_DIRECTORIES)
    if [[ -n "${COPILOT_AGENT_DIRECTORIES:-}" ]]; then
        IFS=':' read -ra dirs <<< "$COPILOT_AGENT_DIRECTORIES"
        for dir in "${dirs[@]}"; do
            if [[ -n "$dir" ]] && [[ -d "$dir" ]]; then
                search_dirs+=("$dir")
                log "Using agent directory from environment: $dir"
            fi
        done
    fi
    
    # 4. .copilot-agents/ in current working directory (convention)
    local local_agents_dir="./.copilot-agents"
    if [[ -d "$local_agents_dir" ]]; then
        search_dirs+=("$local_agents_dir")
        log "Using local agent directory: $local_agents_dir"
    fi
    
    # 5. Built-in examples (fallback, lowest priority)
    local examples_dir="${SCRIPT_DIR}/examples"
    if [[ -d "$examples_dir" ]]; then
        search_dirs+=("$examples_dir")
    fi
    
    # Discover agents from all directories (first occurrence wins)
    for search_dir in "${search_dirs[@]}"; do
        if [[ ! -d "$search_dir" ]]; then
            continue
        fi
        
        for agent_dir in "$search_dir"/*/; do
            if [[ ! -d "$agent_dir" ]]; then
                continue
            fi
            
            local agent_name=$(basename "$agent_dir")
            
            # Skip if we've already seen this agent name (first wins)
            if [[ -n "${seen_names[$agent_name]:-}" ]]; then
                continue
            fi
            
            # Check if this is a valid agent directory
            local has_config=false
            local has_prompt=false
            
            if [[ -f "${agent_dir}copilot-cli.properties" ]] || ls "${agent_dir}"*.properties &>/dev/null; then
                has_config=true
            fi
            
            if [[ -f "${agent_dir}user.prompt.md" ]] || ls "${agent_dir}"*.agent.md >/dev/null 2>&1; then
                has_prompt=true
            fi
            
            if [[ "$has_config" == "true" ]] || [[ "$has_prompt" == "true" ]]; then
                local description=""
                if [[ -f "${agent_dir}description.txt" ]]; then
                    description=$(cat "${agent_dir}description.txt" | head -1)
                fi
                echo "${agent_name}|${description}|${search_dir}"
                seen_names[$agent_name]=1
            fi
        done
    done
}

# Function to display built-in agents list
show_builtin_agents() {
    local agents
    agents=$(get_builtin_agents)
    
    if [[ -z "$agents" ]]; then
        echo ""
        echo "No agents found."
        echo ""
        echo "To get started with agents:"
        echo "  - Use a remote agent repo:  --agent-directory owner/repo"
        echo "  - Create a custom agent:    --init --as-agent --agent-name \"my-agent\""
        echo "  - Add a local agent dir:    --agent-directory ./my-agents"
        echo "  - Reinstall with examples:  Re-run install without --skip-examples"
        echo ""
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
    echo "Info:  --view-agent <name> for detailed configuration"
}

# Function to display detailed agent configuration
show_agent_info() {
    local agent_name="$1"
    
    if ! get_builtin_agent_config "$agent_name"; then
        return 1
    fi
    
    local agent_path="$BUILTIN_AGENT_PATH"
    local display_name
    display_name=$(basename "$agent_path")
    
    echo ""
    echo "===== Agent: $display_name ====="
    echo ""
    
    # Path
    echo "  Path:         $agent_path"
    
    # Description
    if [[ -f "${agent_path}/description.txt" ]]; then
        local desc
        desc=$(cat "${agent_path}/description.txt" | tr -d '\n')
        echo "  Description:  $desc"
    fi
    echo ""
    
    # Files present
    echo "  Files:"
    local has_files=false
    for f in "$agent_path"/*; do
        if [[ -f "$f" ]]; then
            echo "    - $(basename "$f")"
            has_files=true
        fi
    done
    if [[ "$has_files" != "true" ]]; then
        echo "    (none)"
    fi
    echo ""
    
    # Properties
    if [[ -n "$BUILTIN_AGENT_PROPS" ]] && [[ -f "$BUILTIN_AGENT_PROPS" ]]; then
        echo "  Properties ($(basename "$BUILTIN_AGENT_PROPS")):"
        while IFS= read -r line; do
            local trimmed
            trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            # Skip comments and empty lines
            if [[ "$trimmed" == \#* ]] || [[ -z "$trimmed" ]]; then
                continue
            fi
            if [[ "$trimmed" == *=* ]]; then
                local key="${trimmed%%=*}"
                local val="${trimmed#*=}"
                key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                val=$(echo "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                printf "    %-25s = %s\n" "$key" "$val"
            fi
        done < "$BUILTIN_AGENT_PROPS"
        echo ""
    fi
    
    # Agent definition (.agent.md frontmatter)
    if [[ -n "$BUILTIN_AGENT_FILE" ]] && [[ -f "$BUILTIN_AGENT_FILE" ]]; then
        local agent_md_name
        agent_md_name=$(basename "$BUILTIN_AGENT_FILE")
        echo "  Agent Definition ($agent_md_name):"
        
        # Extract frontmatter between --- markers
        local in_frontmatter=false
        local frontmatter=""
        while IFS= read -r line; do
            if [[ "$line" == "---" ]]; then
                if [[ "$in_frontmatter" == "true" ]]; then
                    break
                else
                    in_frontmatter=true
                    continue
                fi
            fi
            if [[ "$in_frontmatter" == "true" ]]; then
                frontmatter="${frontmatter}${line}"$'\n'
            fi
        done < "$BUILTIN_AGENT_FILE"
        
        if [[ -n "$frontmatter" ]]; then
            # Extract name
            local fm_name
            fm_name=$(echo "$frontmatter" | grep -m1 '^name:' | sed "s/^name:[[:space:]]*['\"]\{0,1\}//" | sed "s/['\"].*//")
            if [[ -n "$fm_name" ]]; then
                echo "    Name:        $fm_name"
            fi
            
            # Extract description
            local fm_desc
            fm_desc=$(echo "$frontmatter" | grep -m1 '^description:' | sed "s/^description:[[:space:]]*['\"]\{0,1\}//" | sed "s/['\"].*//")
            if [[ -n "$fm_desc" ]]; then
                echo "    Description: $fm_desc"
            fi
            
            # Extract tools (YAML list format: "  - tool" lines after "tools:")
            local tools_list=""
            local in_tools=false
            while IFS= read -r line; do
                if [[ "$line" =~ ^tools: ]]; then
                    # Check for inline array
                    if [[ "$line" =~ \[(.+)\] ]]; then
                        tools_list=$(echo "${BASH_REMATCH[1]}" | sed "s/['\"]//g" | sed 's/,/, /g')
                        break
                    fi
                    in_tools=true
                    continue
                fi
                if [[ "$in_tools" == "true" ]]; then
                    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.*) ]]; then
                        local tool_name
                        tool_name=$(echo "${BASH_REMATCH[1]}" | sed "s/['\"]//g" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                        if [[ -n "$tools_list" ]]; then
                            tools_list="${tools_list}, ${tool_name}"
                        else
                            tools_list="$tool_name"
                        fi
                    else
                        break
                    fi
                fi
            done <<< "$frontmatter"
            
            if [[ -n "$tools_list" ]]; then
                echo "    Tools:       $tools_list"
            fi
        fi
        echo ""
    fi
    
    # User prompt preview
    if [[ -n "$BUILTIN_AGENT_USER_PROMPT" ]] && [[ -f "$BUILTIN_AGENT_USER_PROMPT" ]]; then
        local prompt_name
        prompt_name=$(basename "$BUILTIN_AGENT_USER_PROMPT")
        echo "  User Prompt Preview ($prompt_name):"
        local prompt_content
        prompt_content=$(head -c 500 "$BUILTIN_AGENT_USER_PROMPT")
        local full_size
        full_size=$(wc -c < "$BUILTIN_AGENT_USER_PROMPT")
        while IFS= read -r line; do
            echo "    $line"
        done <<< "$prompt_content"
        if [[ "$full_size" -gt 500 ]]; then
            echo "    ..."
        fi
        echo ""
    fi
    
    # MCP config
    if [[ -f "${agent_path}/mcp-config.json" ]]; then
        echo "  MCP Servers (mcp-config.json):"
        # Extract server names using grep
        local server_names
        server_names=$(grep -oE '"[a-zA-Z0-9_-]+"\s*:\s*\{' "${agent_path}/mcp-config.json" 2>/dev/null | grep -oE '"[a-zA-Z0-9_-]+"' | tr -d '"' | tail -n +2 | head -10)
        if [[ -n "$server_names" ]]; then
            while IFS= read -r sname; do
                echo "    - $sname"
            done <<< "$server_names"
        else
            echo "    (present but no servers found)"
        fi
        echo ""
    fi
    
    local sep_len=$((15 + ${#display_name}))
    printf "  %${sep_len}s\n" | tr ' ' '='
    echo ""
}

# Function to check if agent is a built-in agent and get its config
get_builtin_agent_config() {
    local agent_name="$1"
    
    # Check if agent_name is actually a path (contains /)
    if [[ "$agent_name" == */* ]]; then
        log "Agent specified as path: $agent_name"
        
        # Resolve and validate the path
        local agent_path="$agent_name"
        if [[ ! -d "$agent_path" ]]; then
            echo "Error: Agent path not found: $agent_name" >&2
            return 1
        fi
        
        # Check if it's a valid agent directory
        local has_config=false
        local has_prompt=false
        
        if [[ -f "${agent_path}/copilot-cli.properties" ]] || ls "${agent_path}"/*.properties &>/dev/null; then
            has_config=true
        fi
        
        if [[ -f "${agent_path}/user.prompt.md" ]] || ls "${agent_path}"/*.agent.md >/dev/null 2>&1; then
            has_prompt=true
        fi
        
        if [[ "$has_config" != "true" ]] && [[ "$has_prompt" != "true" ]]; then
            echo "Error: Directory does not appear to be a valid agent (no config or prompt files found)" >&2
            echo "Expected files: copilot-cli.properties, user.prompt.md, or *.agent.md" >&2
            return 1
        fi
        
        # Export configuration paths
        BUILTIN_AGENT_PATH="$agent_path"
        BUILTIN_AGENT_PROPS=""
        BUILTIN_AGENT_USER_PROMPT=""
        BUILTIN_AGENT_FILE=""
        
        # Look for properties file
        if [[ -f "${agent_path}/copilot-cli.properties" ]]; then
            BUILTIN_AGENT_PROPS="${agent_path}/copilot-cli.properties"
        else
            local props_file
            props_file=$(ls "${agent_path}"/*.properties 2>/dev/null | head -1)
            if [[ -n "$props_file" ]]; then
                BUILTIN_AGENT_PROPS="$props_file"
            fi
        fi
        
        # Look for prompt files
        if [[ -f "${agent_path}/user.prompt.md" ]]; then
            BUILTIN_AGENT_USER_PROMPT="${agent_path}/user.prompt.md"
        fi
        
        BUILTIN_AGENT_FILE=$(ls "${agent_path}"/*.agent.md 2>/dev/null | head -1)
        
        return 0
    fi
    
    # Search by name in agent directories
    local agents
    agents=$(get_builtin_agents)
    
    local agent_found=false
    local agent_dir=""
    
    while IFS='|' read -r name desc source; do
        if [[ "$name" == "$agent_name" ]]; then
            agent_found=true
            agent_dir="${source}/${agent_name}"
            break
        fi
    done <<< "$agents"
    
    if [[ "$agent_found" != "true" ]]; then
        echo "Error: Agent '$agent_name' not found" >&2
        echo "" >&2
        echo "Available agents:" >&2
        local count=0
        while IFS='|' read -r name desc source; do
            if [[ $count -lt 10 ]]; then
                echo "  - $name" >&2
                ((count++))
            fi
        done <<< "$agents" | sort
        if [[ $(echo "$agents" | wc -l) -gt 10 ]]; then
            echo "  ... and more" >&2
        fi
        echo "" >&2
        echo "Use --list-agents to see all available agents" >&2
        return 1
    fi
    
    # Export configuration paths
    BUILTIN_AGENT_PATH="$agent_dir"
    BUILTIN_AGENT_PROPS=""
    BUILTIN_AGENT_USER_PROMPT=""
    BUILTIN_AGENT_FILE=""
    
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
    
    BUILTIN_AGENT_FILE=$(ls "${agent_dir}"/*.agent.md 2>/dev/null | head -1)
    
    return 0
}

# ============================================================================
# Multi-Agent Composition Functions
# ============================================================================

# Function to parse comma-separated agent list
parse_agent_list() {
    local agents_string="$1"
    # Remove spaces around commas and split
    echo "$agents_string" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
}

# Function to validate all agents in a list exist
validate_agent_list() {
    local agents_string="$1"
    local invalid_agents=()
    local valid_agents=()
    
    while IFS= read -r agent_name; do
        [[ -z "$agent_name" ]] && continue
        local examples_dir="${SCRIPT_DIR}/examples"
        local agent_dir="${examples_dir}/${agent_name}"
        
        if [[ -d "$agent_dir" ]]; then
            valid_agents+=("$agent_name")
        else
            invalid_agents+=("$agent_name")
        fi
    done < <(parse_agent_list "$agents_string")
    
    if [[ ${#invalid_agents[@]} -gt 0 ]]; then
        echo "Error: The following agents were not found:" >&2
        for agent in "${invalid_agents[@]}"; do
            echo "  - $agent" >&2
        done
        echo "" >&2
        echo "Available agents:" >&2
        get_builtin_agents | while IFS='|' read -r name desc; do
            echo "  - $name" >&2
        done
        echo "" >&2
        echo "Use --list-agents to see all available agents." >&2
        return 1
    fi
    
    echo "${valid_agents[@]}"
    return 0
}

# Function to run a single agent and capture results
# Returns: 0 on success, non-zero on failure
# Outputs: Agent output to stdout, status info to stderr
run_single_agent() {
    local agent_name="$1"
    local agent_index="$2"
    local total_agents="$3"
    local output_dir="$4"
    
    local start_time=$(date +%s)
    local output_file="${output_dir}/${agent_name}.output.md"
    
    echo "" >&2
    echo "===== Running Agent: ${agent_name} (${agent_index}/${total_agents}) =====" >&2
    echo "" >&2
    
    # Get agent configuration
    if ! get_builtin_agent_config "$agent_name"; then
        echo "Error: Failed to load agent '$agent_name'" >&2
        return 1
    fi
    
    # Store original values
    local orig_config_file="$CONFIG_FILE"
    local orig_prompt_file="$PROMPT_FILE"
    local orig_agent_file="$AGENT_FILE"
    local orig_agent="$AGENT"
    local orig_prompt="$PROMPT"
    
    # Apply agent configuration
    if [[ -n "$BUILTIN_AGENT_PROPS" ]]; then
        CONFIG_FILE="$BUILTIN_AGENT_PROPS"
        load_config "$CONFIG_FILE"
    fi
    
    if [[ -n "$BUILTIN_AGENT_USER_PROMPT" ]]; then
        PROMPT_FILE="$BUILTIN_AGENT_USER_PROMPT"
        PROMPT=""
    fi
    
    # Install agent file and set AGENT variable
    if [[ -n "$BUILTIN_AGENT_FILE" ]]; then
        local agent_basename
        agent_basename=$(basename "$BUILTIN_AGENT_FILE" .agent.md)
        install_agent_to_repository "$BUILTIN_AGENT_FILE" "$agent_basename"
        AGENT="$agent_basename"
    fi
    
    # Load prompts from files
    if [[ -z "$PROMPT" && -n "$PROMPT_FILE" ]]; then
        PROMPT=$(load_file_content "$PROMPT_FILE" "Prompt")
    fi
    
    # Build and execute command
    local copilot_cmd
    copilot_cmd=$(build_copilot_command)
    
    echo "Agent command: $copilot_cmd" >&2
    echo "" >&2
    
    local exit_code=0
    
    # Execute with output capture
    {
        echo "# Agent: ${agent_name}"
        echo "## Execution Time: $(date -Iseconds)"
        echo ""
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Command: $copilot_cmd"
        else
            if command -v timeout &> /dev/null; then
                timeout --preserve-status "${TIMEOUT_MINUTES}m" bash -c "$copilot_cmd" 2>&1 || exit_code=$?
            else
                eval "$copilot_cmd" 2>&1 || exit_code=$?
            fi
        fi
    } | tee "$output_file"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Restore original values
    CONFIG_FILE="$orig_config_file"
    PROMPT_FILE="$orig_prompt_file"
    AGENT_FILE="$orig_agent_file"
    AGENT="$orig_agent"
    PROMPT="$orig_prompt"
    
    # Report status
    if [[ $exit_code -eq 0 ]]; then
        echo "" >&2
        echo "Agent '${agent_name}' completed successfully (${duration}s)" >&2
    else
        echo "" >&2
        echo "Agent '${agent_name}' failed with exit code ${exit_code} (${duration}s)" >&2
    fi
    
    return $exit_code
}

# Function to run multiple agents sequentially
run_agent_queue() {
    local agents_string="$1"
    local error_mode="$2"
    
    # Create output directory
    local timestamp=$(date +%Y-%m-%d_%H%M%S)
    local output_base_dir="${HOME}/.copilot-cli-automation/runs"
    local output_dir="${output_base_dir}/${timestamp}"
    mkdir -p "$output_dir"
    
    # Parse and validate agents
    local agents_array
    if ! agents_array=$(validate_agent_list "$agents_string"); then
        return 1
    fi
    
    # Convert to array
    read -ra agents <<< "$agents_array"
    local total_agents=${#agents[@]}
    
    if [[ $total_agents -eq 0 ]]; then
        echo "Error: No agents specified" >&2
        return 1
    fi
    
    echo ""
    echo "===== Multi-Agent Execution ====="
    echo "Agents to run: ${agents[*]}"
    echo "Error mode: $error_mode"
    echo "Output directory: $output_dir"
    echo "================================="
    echo ""
    
    # Track results
    local passed=0
    local failed=0
    local results=()
    local start_total=$(date +%s)
    
    # Run each agent
    local index=1
    for agent_name in "${agents[@]}"; do
        local agent_start=$(date +%s)
        local status="PASSED"
        
        if run_single_agent "$agent_name" "$index" "$total_agents" "$output_dir"; then
            ((passed++))
        else
            ((failed++))
            status="FAILED"
            
            if [[ "$error_mode" == "stop" ]]; then
                echo ""
                echo "Error mode is 'stop'. Aborting remaining agents." >&2
                break
            fi
        fi
        
        local agent_end=$(date +%s)
        local agent_duration=$((agent_end - agent_start))
        results+=("${agent_name}|${status}|${agent_duration}")
        
        ((index++))
    done
    
    local end_total=$(date +%s)
    local total_duration=$((end_total - start_total))
    
    # Generate summary
    echo ""
    echo "===== Multi-Agent Run Summary ====="
    echo "Total agents: $total_agents | Passed: $passed | Failed: $failed"
    echo "Total duration: ${total_duration}s"
    echo ""
    
    # Print individual results
    for result in "${results[@]}"; do
        IFS='|' read -r name status duration <<< "$result"
        printf "  %-25s [%s] (%ss)\n" "$name" "$status" "$duration"
    done
    
    echo ""
    echo "Outputs saved to: $output_dir"
    echo "===================================="
    
    # Save summary to file
    {
        echo "# Multi-Agent Run Summary"
        echo "## $(date -Iseconds)"
        echo ""
        echo "- **Total agents:** $total_agents"
        echo "- **Passed:** $passed"
        echo "- **Failed:** $failed"
        echo "- **Total duration:** ${total_duration}s"
        echo "- **Error mode:** $error_mode"
        echo ""
        echo "## Results"
        echo ""
        for result in "${results[@]}"; do
            IFS='|' read -r name status duration <<< "$result"
            echo "- **$name**: $status (${duration}s)"
        done
    } > "${output_dir}/SUMMARY.md"
    
    # Return failure if any agent failed
    [[ $failed -eq 0 ]]
}

# Function to find and suggest similar files
find_similar_files() {
    local file_path="$1"
    local extensions="${2:-.md .txt}"
    
    local directory=$(dirname "$file_path")
    [[ -z "$directory" || "$directory" == "." ]] && directory="$SCRIPT_DIR"
    
    local filename=$(basename "$file_path")
    local basename="${filename%.*}"
    
    local suggestions=()
    
    if [[ -d "$directory" ]]; then
        # Find files with similar extensions
        for ext in $extensions; do
            while IFS= read -r -d '' file; do
                local name=$(basename "$file")
                suggestions+=("$name")
            done < <(find "$directory" -maxdepth 1 -type f -name "*${ext}" -print0 2>/dev/null)
        done
        
        # Sort unique and limit to 5
        printf '%s\n' "${suggestions[@]}" | sort -u | head -5
    fi
}

# Function to show file suggestions
show_file_suggestions() {
    local file_path="$1"
    local file_type="$2"
    local extensions="${3:-.md .txt}"
    
    local suggestions=$(find_similar_files "$file_path" "$extensions")
    
    if [[ -n "$suggestions" ]]; then
        echo "" >&2
        echo -e "${YELLOW}Did you mean one of these?${NC}" >&2
        while IFS= read -r suggestion; do
            [[ -n "$suggestion" ]] && echo -e "  ${CYAN}- $suggestion${NC}" >&2
        done <<< "$suggestions"
        echo "" >&2
        echo -e "Tip: Use the correct file path or create the file:" >&2
        echo -e "  ${CYAN}touch $file_path${NC}" >&2
    else
        local directory=$(dirname "$file_path")
        [[ -z "$directory" || "$directory" == "." ]] && directory="."
        echo "" >&2
        echo -e "No similar files found in: $directory" >&2
        echo -e "${YELLOW}Available files in directory:${NC}" >&2
        ls -1 "$directory" 2>/dev/null | head -5 | while read -r f; do
            echo -e "  ${CYAN}- $f${NC}" >&2
        done
    fi
}

# Function to load content from file preserving formatting
load_file_content() {
    local file_path="$1"
    local content_type="$2"
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}Error: $content_type file not found: $file_path${NC}" >&2
        show_file_suggestions "$file_path" "$content_type" ".md .txt"
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
                agent.file) AGENT_FILE="$value" ;;
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
                # New: Custom agent directories
                agent.directory) [[ -z "$AGENT_DIRECTORY" ]] && AGENT_DIRECTORY="$value" ;;
                additional.agent.directories) [[ -z "$ADDITIONAL_AGENT_DIRECTORIES" ]] && ADDITIONAL_AGENT_DIRECTORIES="$value" ;;
                agent.cache.dir) [[ -z "$AGENT_CACHE_DIR" ]] && AGENT_CACHE_DIR="$value" ;;
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
    # Combine user prompt
    local full_prompt="$PROMPT"
    
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
            echo -e "${RED}Error: MCP configuration file not found: $MCP_CONFIG_FILE${NC}" >&2
            show_file_suggestions "$MCP_CONFIG_FILE" "MCP config" ".json"
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
        --agent-file)
            AGENT_FILE="$2"
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
        --view-agent)
            VIEW_AGENT="$2"
            shift 2
            ;;
        --agents)
            AGENTS="$2"
            shift 2
            ;;
        --agent-error-mode)
            AGENT_ERROR_MODE="$2"
            shift 2
            ;;
        --agent-directory)
            AGENT_DIRECTORY="$2"
            shift 2
            ;;
        --additional-agent-dirs)
            ADDITIONAL_AGENT_DIRECTORIES="$2"
            shift 2
            ;;
        --agent-cache-dir)
            AGENT_CACHE_DIR="$2"
            shift 2
            ;;
        --update-agent-cache)
            UPDATE_AGENT_CACHE="true"
            shift
            ;;
        --as-agent)
            AS_AGENT="true"
            shift
            ;;
        --agent-name)
            AGENT_NAME="$2"
            shift 2
            ;;
        --use-defaults)
            USE_DEFAULTS="true"
            shift
            ;;
        --diagnose)
            DIAGNOSE="true"
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

# Load configuration file early (needed for --list-agents, --view-agent, --diagnose)
load_config "$CONFIG_FILE"

# Setup GitHub authentication early (needed for API calls including remote agent sync)
setup_github_auth

# Handle --list-agents command
if [[ "$LIST_AGENTS" == "true" ]]; then
    show_builtin_agents
    exit 0
fi

# Handle --view-agent command
if [[ -n "$VIEW_AGENT" ]]; then
    show_agent_info "$VIEW_AGENT"
    exit 0
fi

# Handle --diagnose command
if [[ "$DIAGNOSE" == "true" ]]; then
    show_diagnostic_status
    exit 0
fi

# Handle --update-agent-cache: inform user cache will be refreshed
if [[ "$UPDATE_AGENT_CACHE" == "true" ]]; then
    print_info "Agent cache will be refreshed on next sync operation."
fi

# Check for COPILOT_AGENT environment variable if no agent specified
if [[ -z "$AGENT" ]] && [[ -z "$AGENTS" ]] && [[ -n "${COPILOT_AGENT:-}" ]]; then
    AGENT="$COPILOT_AGENT"
    log "Using agent from COPILOT_AGENT environment variable: $AGENT"
fi

# Check for mutual exclusivity of --agent and --agents
if [[ -n "$AGENT" ]] && [[ -n "$AGENTS" ]]; then
    echo "Error: Cannot use both --agent and --agents together." >&2
    echo "Use --agent for a single agent, or --agents for multiple agents." >&2
    exit 1
fi

# Handle --agents: run multiple agents sequentially
if [[ -n "$AGENTS" ]]; then
    # Setup dependencies and auth first
    check_dependencies
    setup_github_auth
    
    # Run the agent queue
    if run_agent_queue "$AGENTS" "$AGENT_ERROR_MODE"; then
        exit 0
    else
        exit 1
    fi
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
        
        # Install agent file to .github/agents/ and set AGENT for --agent flag
        if [[ -n "$BUILTIN_AGENT_FILE" ]]; then
            local agent_basename
            agent_basename=$(basename "$BUILTIN_AGENT_FILE" .agent.md)
            install_agent_to_repository "$BUILTIN_AGENT_FILE" "$agent_basename"
            AGENT="$agent_basename"
        fi
    fi
fi

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
    AGENT_FILE="${SCRIPT_DIR}/default.agent.md"
    # Install default agent and set AGENT
    if [[ -f "$AGENT_FILE" ]]; then
        install_agent_to_repository "$AGENT_FILE" "default"
        AGENT="default"
    fi
    # Clear any inline prompts to force loading from files
    PROMPT=""
fi

# Load prompts from files if specified (command line params override)
# Load prompt from file if PROMPT_FILE is specified and PROMPT is empty
if [[ -z "$PROMPT" && -n "$PROMPT_FILE" ]]; then
    PROMPT=$(load_file_content "$PROMPT_FILE" "Prompt")
fi

# Install agent file to .github/agents/ if AGENT_FILE is set and AGENT is not yet set
if [[ -n "$AGENT_FILE" && -z "$AGENT" ]]; then
    if [[ -f "$AGENT_FILE" ]]; then
        local_agent_name=$(basename "$AGENT_FILE" .agent.md)
        install_agent_to_repository "$AGENT_FILE" "$local_agent_name"
        AGENT="$local_agent_name"
    fi
fi

# Validate that prompts have meaningful content (not just comments)
if [[ -n "$PROMPT" ]]; then
    has_meaningful_content "$PROMPT" "User prompt" || true
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