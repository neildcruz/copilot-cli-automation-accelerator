# GitHub Copilot CLI Wrapper Script (PowerShell)
# Provides the same functionality as the GitHub Action but for local execution
# Supports configuration via properties file and command line arguments

param(
    [string]$Config = "copilot-cli.properties",
    [string]$Prompt = "",
    [string]$PromptFile = "",
    [string]$AgentFile = "",
    [string]$GithubToken = "",
    [string]$Model = "claude-sonnet-4.5",
    [string]$AutoInstallCli = "true",
    [string]$McpConfig = "",
    [string]$McpConfigFile = "",
    [string]$AllowAllTools = "true",
    [string]$AllowAllPaths = "false",
    [string]$AdditionalDirectories = "",
    [string]$AllowedTools = "",
    [string]$DeniedTools = "",
    [string]$DisableBuiltinMcps = "false",
    [string]$DisableMcpServers = "",
    [string]$EnableAllGithubMcpTools = "false",
    [string]$LogLevel = "info",
    [string]$WorkingDirectory = ".",
    [string]$NodeVersion = "22",
    [int]$TimeoutMinutes = 30,
    [switch]$NoColor,
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Help,
    # New: Prompt repository integration
    [string]$UsePrompt = "",
    [string]$DefaultPromptRepo = "github/awesome-copilot",
    [string]$PromptCacheDir = "",
    [switch]$ListPrompts,
    [string]$SearchPrompts = "",
    [string]$PromptInfo = "",
    [switch]$UpdatePromptCache,
    # New: CLI parity options
    [string]$Agent = "",
    [string]$AllowAllUrls = "false",
    [string]$AllowUrls = "",
    [string]$DenyUrls = "",
    [string]$AvailableTools = "",
    [string]$ExcludedTools = "",
    [string]$AddGitHubMcpTool = "",
    [string]$AddGitHubMcpToolset = "",
    [string]$NoAskUser = "false",
    [switch]$Silent,
    [string]$ConfigDir = "",
    [string]$Share = "",
    [switch]$ShareGist,
    [string]$Resume = "",
    [switch]$Continue,
    [switch]$Init,
    # New: Built-in agent discovery
    [switch]$ListAgents,
    # New: Use defaults flag
    [switch]$UseDefaults,
    # New: Multi-agent composition
    [string]$Agents = "",
    [ValidateSet("continue", "stop")]
    [string]$AgentErrorMode = "continue",
    # New: Diagnostic mode
    [switch]$Diagnose,
    # New: Custom agent directories
    [string]$AgentDirectory = "",
    [string]$AdditionalAgentDirectories = "",
    # New: Remote agent repository cache
    [string]$AgentCacheDir = "",
    [switch]$UpdateAgentCache,
    # New: Agent creation enhancements
    [switch]$AsAgent,
    [string]$AgentName = ""
)

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Config.Contains('\') -and -not $Config.Contains('/')) {
    $Config = Join-Path $ScriptDir $Config
}

# Function to resolve file paths relative to script directory
function Resolve-FilePath {
    param([string]$FilePath)
    
    if ([string]::IsNullOrEmpty($FilePath)) {
        return $FilePath
    }
    
    # If the path doesn't contain a path separator, resolve relative to script directory
    if (-not $FilePath.Contains('\') -and -not $FilePath.Contains('/')) {
        return Join-Path $ScriptDir $FilePath
    }
    
    return $FilePath
}

# Function to show usage
function Show-Usage {
    Write-Host @"
GitHub Copilot CLI Wrapper Script (PowerShell)

A zero-config wrapper for GitHub Copilot CLI with prompt repository integration,
automatic installation, and CI/CD-optimized execution.

Usage: .\copilot-cli.ps1 [OPTIONS]

QUICK START:
    .\copilot-cli.ps1 -Agent code-review               # Use built-in agent
    .\copilot-cli.ps1 -Agents "security,code-review"   # Run multiple agents
    .\copilot-cli.ps1 -UseDefaults                     # Use built-in default prompts
    .\copilot-cli.ps1 -ListAgents                      # List available agents
    .\copilot-cli.ps1 -Prompt "Review this code"       # Direct prompt
    .\copilot-cli.ps1 -Init                            # Initialize project config

BUILT-IN AGENTS:
    -ListAgents                    List all available built-in and custom agents
    -Agent NAME                    Use an agent by name or path
                                   Examples: code-review, ./my-agents/custom, /path/to/agent
    -Agents NAMES                  Run multiple agents sequentially (comma-separated)
                                   Example: -Agents "security-analysis,code-review"
    -AgentErrorMode MODE           Behavior on agent failure: 'continue' (default) or 'stop'

CUSTOM AGENT MANAGEMENT:
    -AgentDirectory DIR            Primary custom agent directory (local path or remote repo)
                                   Local:  -AgentDirectory ./my-agents
                                   Remote: -AgentDirectory owner/repo
                                   Remote with branch: -AgentDirectory owner/repo@branch
                                   Remote single agent: -AgentDirectory owner/repo:agent-name
    -AdditionalAgentDirectories    Comma-separated list of additional agent directories
                                   Each entry can be a local path or remote repo reference
    -AgentCacheDir DIR             Directory to cache downloaded remote agents
                                   (default: ~/.copilot-cli-automation/agents/)
    -UpdateAgentCache              Force re-download of cached remote agents
    -Init -AsAgent                 Create a new custom agent (requires -AgentName)
    -AgentName NAME                Name for new agent (used with -Init -AsAgent)
                                   Example: -Init -AsAgent -AgentName "dotnet-review"

REMOTE AGENT REPOSITORY FORMAT:
    Remote agent repositories must have this structure:
      <repo-root>/agents/<agent-name>/
    Each agent subdirectory can contain:
      - copilot-cli.properties     Agent configuration overrides
      - user.prompt.md             User prompt/task definition
      - <agent-name>.agent.md      GitHub custom agent definition
      - description.txt            One-line description for -ListAgents
      - mcp-config.json            MCP server configuration

AGENT DISCOVERY ORDER (first match wins):
    1. -AgentDirectory parameter (local or remote)
    2. -AdditionalAgentDirectories parameter (local or remote)
    3. COPILOT_AGENT_DIRECTORIES environment variable (semicolon-separated)
    4. .copilot-agents/ in current directory
    5. Built-in examples directory

PROMPT REPOSITORY OPTIONS:
    -UsePrompt NAME                Use a prompt from GitHub repository
                                   Format: name (uses default repo) or owner/repo:name
                                   Examples: code-review, myorg/prompts:security-scan
    -DefaultPromptRepo REPO        Default repository for prompts (default: github/awesome-copilot)
    -PromptCacheDir DIR            Directory to cache downloaded prompts
    -ListPrompts                   List available prompts from default repository
    -SearchPrompts QUERY           Search prompts by keyword (repo:keyword format supported)
    -PromptInfo NAME               Show detailed information about a prompt
    -UpdatePromptCache             Force refresh of cached prompts

PROMPT OPTIONS:
    -Config FILE                   Configuration properties file (default: copilot-cli.properties)
    -Prompt TEXT                   The prompt to execute (required unless using other prompt options)
    -PromptFile FILE               Load prompt from text/markdown file
    -AgentFile FILE                Path to a .agent.md file to install and use
    -UseDefaults                   Use built-in default prompts (useful for quick analysis)

MODEL & AGENT OPTIONS:
    -Model MODEL                   AI model (gpt-5, claude-sonnet-4, claude-sonnet-4.5)
    -Agent AGENT                   Specify a custom agent to use

TOOL PERMISSIONS:
    -AllowAllTools BOOL            Allow all tools automatically (default: true)
    -AllowAllPaths BOOL            Allow access to any filesystem path (default: false)
    -AllowAllUrls BOOL             Allow access to all URLs (default: false)
    -AllowedTools TOOLS            Comma-separated list of allowed tools
    -DeniedTools TOOLS             Comma-separated list of denied tools
    -AvailableTools TOOLS          Limit which tools are available to the model
    -ExcludedTools TOOLS           Exclude specific tools from the model
    -AllowUrls URLS                Comma-separated list of allowed URLs/domains
    -DenyUrls URLS                 Comma-separated list of denied URLs/domains
    -AdditionalDirectories DIRS    Comma-separated list of additional directories

MCP SERVER OPTIONS:
    -McpConfig TEXT                MCP server configuration as JSON string
    -McpConfigFile FILE            MCP server configuration file path
    -DisableBuiltinMcps BOOL       Disable all built-in MCP servers (default: false)
    -DisableMcpServers SERVERS     Comma-separated list of MCP servers to disable
    -EnableAllGithubMcpTools BOOL  Enable all GitHub MCP tools (default: false)
    -AddGitHubMcpTool TOOLS        Add specific GitHub MCP tools (comma-separated)
    -AddGitHubMcpToolset TOOLSETS  Add GitHub MCP toolsets (comma-separated)

SESSION & OUTPUT OPTIONS:
    -Continue                      Resume the most recent session
    -Resume SESSION-ID             Resume a specific session
    -Share PATH                    Save session to markdown file after completion
    -ShareGist                     Share session as a secret GitHub gist
    -Silent                        Output only agent response (useful for scripting)

EXECUTION OPTIONS:
    -NoAskUser BOOL                Disable interactive questions (autonomous mode)
    -ConfigDir PATH                Set the configuration directory
    -WorkingDirectory DIR          Working directory to run from
    -TimeoutMinutes MINUTES        Timeout in minutes (default: 30)
    -LogLevel LEVEL                Log level (none, error, warning, info, debug, all)
    -NoColor                       Disable colored output (auto-enabled for CI/CD)
    -DryRun                        Show generated command without executing
    -Verbose                       Enable verbose output

SETUP OPTIONS:
    -GithubToken TOKEN             GitHub Personal Access Token for authentication
    -AutoInstallCli BOOL           Auto-install Copilot CLI if not found (default: true)
    -Init                          Initialize project with starter configuration files
    -Diagnose                      Run comprehensive system check and show status report
    -Help                          Show this help message

EXAMPLES:
    # Create a custom agent
    .\copilot-cli.ps1 -Init -AsAgent -AgentName "my-review"
    # Then use it
    .\copilot-cli.ps1 -Agent my-review
    
    # Use agent by path
    .\copilot-cli.ps1 -Agent ./custom-agents/dotnet-standards
    
    # List all agents (built-in and custom)
    .\copilot-cli.ps1 -ListAgents
    
    # Use a pre-built prompt from awesome-copilot
    .\copilot-cli.ps1 -UsePrompt code-review
    .\copilot-cli.ps1 -UsePrompt conventional-commit
    
    # Use a prompt from a custom repository
    .\copilot-cli.ps1 -UsePrompt myorg/internal-prompts:security-audit
    
    # Set custom default repository for your organization
    .\copilot-cli.ps1 -DefaultPromptRepo myorg/prompts -UsePrompt api-review
    
    # Basic usage with inline prompt
    .\copilot-cli.ps1 -Prompt "Review the code for security issues"
    
    # Use an agent with a custom prompt file
    .\copilot-cli.ps1 -Agent code-review -PromptFile task.md
    
    # Autonomous mode for CI/CD (no interactive questions)
    .\copilot-cli.ps1 -UsePrompt code-review -NoAskUser true -Silent
    
    # Restricted permissions for security
    .\copilot-cli.ps1 -Prompt "Analyze" -AllowAllPaths false -DeniedTools shell,bash
    
    # Initialize a new project with starter config
    .\copilot-cli.ps1 -Init
    
    # Discover available prompts
    .\copilot-cli.ps1 -ListPrompts
    .\copilot-cli.ps1 -SearchPrompts security
    .\copilot-cli.ps1 -PromptInfo code-review
    
    # Dry run to preview the command
    .\copilot-cli.ps1 -UsePrompt code-review -DryRun

AUTHENTICATION:
    GitHub Copilot CLI requires authentication (in order of precedence):
    1. -GithubToken command line parameter
    2. github.token in properties file  
    3. COPILOT_GITHUB_TOKEN environment variable
    4. GH_TOKEN environment variable
    5. GITHUB_TOKEN environment variable
    6. Existing GitHub CLI authentication (gh auth login)

ENVIRONMENT VARIABLES:
    COPILOT_AGENT_DIRECTORIES      Semicolon-separated list of agent directories
    COPILOT_AGENT                  Default agent to use if -Agent not specified
    COPILOT_GITHUB_TOKEN          GitHub authentication token
    GH_TOKEN / GITHUB_TOKEN       Alternative authentication tokens

CONFIGURATION FILE (copilot-cli.properties):
    # Agent configuration
    agent.directory=./.copilot-agents
    additional.agent.directories=./ci/agents,./custom-agents
    
    # Prompt options
    use.prompt=code-review
    default.prompt.repo=github/awesome-copilot
    prompt.file=user.prompt.md
    agent.file=default.agent.md
    
    # Tool permissions
    allow.all.tools=true
    allow.all.paths=false
    denied.tools=shell,bash
    
    # Execution options
    copilot.model=claude-sonnet-4.5
    timeout.minutes=30
    no.ask.user=false

"@
}

# Function to log messages
function Write-Log {
    param([string]$Message)
    if ($Verbose) {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" -ForegroundColor Gray
    }
}

# Function to run comprehensive system diagnostics
function Show-DiagnosticStatus {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "  GitHub Copilot CLI - System Diagnostics" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $allPassed = $true
    $warnings = 0
    
    # 1. Node.js Check
    Write-Host "Node.js:" -ForegroundColor Yellow
    try {
        $nodeVersion = & node --version 2>$null
        if ($nodeVersion) {
            $version = [version]($nodeVersion.TrimStart('v').Split('.')[0..2] -join '.')
            if ($version.Major -ge 20) {
                Write-Host "  \u2713 Version: $nodeVersion (meets requirement >=20)" -ForegroundColor Green
            } else {
                Write-Host "  \u26A0 Version: $nodeVersion (recommended: >=20)" -ForegroundColor Yellow
                $warnings++
            }
            $nodePath = (Get-Command node).Source
            Write-Host "  \u2713 Path: $nodePath" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  \u2717 Not installed or not in PATH" -ForegroundColor Red
        Write-Host "    -> Install from: https://nodejs.org/" -ForegroundColor Cyan
        $allPassed = $false
    }
    Write-Host ""
    
    # 2. npm Check
    Write-Host "npm:" -ForegroundColor Yellow
    try {
        $npmVersion = & npm --version 2>$null
        if ($npmVersion) {
            Write-Host "  \u2713 Version: $npmVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "  \u2717 Not available" -ForegroundColor Red
        $allPassed = $false
    }
    Write-Host ""
    
    # 3. GitHub Copilot CLI Check
    Write-Host "GitHub Copilot CLI:" -ForegroundColor Yellow
    try {
        $copilotVersion = & copilot --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  \u2713 Installed: $copilotVersion" -ForegroundColor Green
        } else {
            throw "Not installed"
        }
    } catch {
        try {
            $npmList = & npm list -g @github/copilot --depth=0 2>$null
            if ($npmList -match '@github/copilot@') {
                Write-Host "  \u2713 Installed (via npm)" -ForegroundColor Green
            } else {
                throw "Not found"
            }
        } catch {
            Write-Host "  \u2717 Not installed" -ForegroundColor Red
            Write-Host "    -> Install with: npm install -g @github/copilot" -ForegroundColor Cyan
            $allPassed = $false
        }
    }
    Write-Host ""
    
    # 4. GitHub Authentication Check
    Write-Host "GitHub Authentication:" -ForegroundColor Yellow
    $hasAuth = $false
    
    if ($env:GITHUB_TOKEN) {
        Write-Host "  \u2713 GITHUB_TOKEN: Set ($($env:GITHUB_TOKEN.Length) chars)" -ForegroundColor Green
        $hasAuth = $true
    } else {
        Write-Host "  \u25CB GITHUB_TOKEN: Not set" -ForegroundColor Gray
    }
    
    if ($env:GH_TOKEN) {
        Write-Host "  \u2713 GH_TOKEN: Set ($($env:GH_TOKEN.Length) chars)" -ForegroundColor Green
        $hasAuth = $true
    } else {
        Write-Host "  \u25CB GH_TOKEN: Not set" -ForegroundColor Gray
    }
    
    if ($env:COPILOT_GITHUB_TOKEN) {
        Write-Host "  \u2713 COPILOT_GITHUB_TOKEN: Set" -ForegroundColor Green
        $hasAuth = $true
    } else {
        Write-Host "  \u25CB COPILOT_GITHUB_TOKEN: Not set" -ForegroundColor Gray
    }
    
    try {
        $ghToken = & gh auth token 2>$null
        if ($ghToken -and $LASTEXITCODE -eq 0) {
            Write-Host "  \u2713 GitHub CLI: Authenticated" -ForegroundColor Green
            $hasAuth = $true
        } else {
            Write-Host "  \u25CB GitHub CLI: Not authenticated" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  \u25CB GitHub CLI: Not installed" -ForegroundColor Gray
    }
    
    if (-not $hasAuth) {
        Write-Host "  \u26A0 No authentication configured" -ForegroundColor Yellow
        Write-Host "    -> Run: gh auth login" -ForegroundColor Cyan
        Write-Host "    -> Or set: `$env:GITHUB_TOKEN = 'ghp_...'" -ForegroundColor Cyan
        $warnings++
    }
    Write-Host ""
    
    # 5. Network Check
    Write-Host "Network:" -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com" -TimeoutSec 10 -UseBasicParsing
        Write-Host "  \u2713 GitHub API: Accessible" -ForegroundColor Green
    } catch {
        Write-Host "  \u2717 GitHub API: Not accessible" -ForegroundColor Red
        Write-Host "    -> Check internet connection or proxy settings" -ForegroundColor Cyan
        $allPassed = $false
    }
    
    if ($env:HTTP_PROXY -or $env:HTTPS_PROXY) {
        Write-Host "  \u2713 Proxy configured:" -ForegroundColor Green
        if ($env:HTTP_PROXY) { Write-Host "    HTTP_PROXY: $($env:HTTP_PROXY)" -ForegroundColor Gray }
        if ($env:HTTPS_PROXY) { Write-Host "    HTTPS_PROXY: $($env:HTTPS_PROXY)" -ForegroundColor Gray }
    }
    Write-Host ""
    
    # 6. Configuration Check
    Write-Host "Configuration:" -ForegroundColor Yellow
    $configPath = Join-Path $ScriptDir "copilot-cli.properties"
    if (Test-Path $configPath) {
        Write-Host "  \u2713 Properties file: $configPath" -ForegroundColor Green
    } else {
        Write-Host "  \u25CB Properties file: Not found (using defaults)" -ForegroundColor Gray
    }
    
    $mcpPath = Join-Path $ScriptDir "mcp-config.json"
    if (Test-Path $mcpPath) {
        try {
            $null = Get-Content $mcpPath -Raw | ConvertFrom-Json
            Write-Host "  \u2713 MCP config: $mcpPath (valid JSON)" -ForegroundColor Green
        } catch {
            Write-Host "  \u2717 MCP config: $mcpPath (invalid JSON)" -ForegroundColor Red
            $allPassed = $false
        }
    } else {
        Write-Host "  \u25CB MCP config: Not found (will be skipped)" -ForegroundColor Gray
    }
    Write-Host ""
    
    # 7. Working Directory Check
    Write-Host "Working Directory:" -ForegroundColor Yellow
    $currentDir = Get-Location
    Write-Host "  \u2713 Current: $currentDir" -ForegroundColor Green
    $gitDir = Join-Path $currentDir ".git"
    if (Test-Path $gitDir) {
        Write-Host "  \u2713 Git repository detected" -ForegroundColor Green
    }
    Write-Host ""
    
    # 8. Built-in Agents Check
    Write-Host "Built-in Agents:" -ForegroundColor Yellow
    $agents = Get-BuiltInAgents
    if ($agents.Count -gt 0) {
        Write-Host "  \u2713 Available: $($agents.Count) agents" -ForegroundColor Green
        foreach ($agent in $agents | Select-Object -First 5) {
            Write-Host "    - $($agent.Name)" -ForegroundColor Gray
        }
        if ($agents.Count -gt 5) {
            Write-Host "    - ... and $($agents.Count - 5) more" -ForegroundColor Gray
        }
    } else {
        Write-Host "  \u25CB No built-in agents found" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Summary
    Write-Host "=========================================" -ForegroundColor Cyan
    if ($allPassed -and $warnings -eq 0) {
        Write-Host "  Ready to run: YES \u2713" -ForegroundColor Green
    } elseif ($allPassed) {
        Write-Host "  Ready to run: YES (with $warnings warning(s))" -ForegroundColor Yellow
    } else {
        Write-Host "  Ready to run: NO \u2717" -ForegroundColor Red
        Write-Host "  Fix the issues above and run -Diagnose again" -ForegroundColor Yellow
    }
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
}

# Function to parse boolean values
function Parse-Bool {
    param([string]$Value)
    switch ($Value.ToLower()) {
        { $_ -in @("true", "yes", "1", "on") } { return "true" }
        { $_ -in @("false", "no", "0", "off") } { return "false" }
        default { return $Value }
    }
}

# Function to find similar files for suggestions
function Find-SimilarFiles {
    param(
        [string]$FilePath,
        [string[]]$Extensions = @('.md', '.txt')
    )
    
    $directory = Split-Path $FilePath -Parent
    if ([string]::IsNullOrEmpty($directory)) {
        $directory = $ScriptDir
    }
    
    $fileName = Split-Path $FilePath -Leaf
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    
    $suggestions = @()
    
    if (Test-Path $directory) {
        # Find files with similar names or matching extensions
        $allFiles = Get-ChildItem -Path $directory -File -ErrorAction SilentlyContinue
        
        foreach ($file in $allFiles) {
            $fileExt = $file.Extension.ToLower()
            if ($fileExt -in $Extensions) {
                # Check for similar name
                $similarityScore = 0
                $fileBase = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                
                # Exact extension match with different name
                if ($file.Name -like "*$baseName*" -or $baseName -like "*$fileBase*") {
                    $similarityScore = 2
                } elseif ($file.Extension -eq [System.IO.Path]::GetExtension($fileName)) {
                    $similarityScore = 1
                } elseif ($fileExt -in $Extensions) {
                    $similarityScore = 1
                }
                
                if ($similarityScore -gt 0) {
                    $suggestions += @{
                        Name = $file.Name
                        Path = $file.FullName
                        Score = $similarityScore
                    }
                }
            }
        }
        
        # Sort by score and return top 5
        $suggestions = $suggestions | Sort-Object { -$_.Score } | Select-Object -First 5
    }
    
    return $suggestions
}

# Function to load content from file preserving formatting
function Load-FileContent {
    param(
        [string]$FilePath,
        [string]$ContentType
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "Error: $ContentType file not found: $FilePath" -ForegroundColor Red
        
        # Find and suggest similar files
        $suggestions = Find-SimilarFiles -FilePath $FilePath
        if ($suggestions.Count -gt 0) {
            Write-Host ""
            Write-Host "Did you mean one of these?" -ForegroundColor Yellow
            foreach ($suggestion in $suggestions) {
                Write-Host "  - $($suggestion.Name)" -ForegroundColor Cyan
            }
            Write-Host ""
            Write-Host "Tip: Use the correct file path or create the file:" -ForegroundColor Gray
            Write-Host "  touch $FilePath" -ForegroundColor Cyan
        } else {
            $directory = Split-Path $FilePath -Parent
            if ([string]::IsNullOrEmpty($directory)) { $directory = "." }
            Write-Host ""
            Write-Host "No similar files found in: $directory" -ForegroundColor Gray
            Write-Host "Available .md files:" -ForegroundColor Yellow
            $mdFiles = Get-ChildItem -Path $directory -Filter "*.md" -ErrorAction SilentlyContinue | Select-Object -First 5
            if ($mdFiles) {
                foreach ($file in $mdFiles) {
                    Write-Host "  - $($file.Name)" -ForegroundColor Cyan
                }
            } else {
                Write-Host "  (none)" -ForegroundColor Gray
            }
        }
        
        throw "$ContentType file '$FilePath' not found"
    }
    
    # Validate file extension
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    if ($extension -notin @('.txt', '.md')) {
        Write-Log "Warning: $ContentType file has extension '$extension', expected .txt or .md"
    }
    
    Write-Log "Loading $ContentType from file: $FilePath"
    
    # Read file content preserving line breaks and formatting
    # Using -Raw to preserve exact formatting including line breaks
    $content = Get-Content -Path $FilePath -Raw
    
    # Remove trailing newline if present (Get-Content -Raw adds one)
    if ($content -and $content.EndsWith("`n")) {
        $content = $content.Substring(0, $content.Length - 1)
    }
    if ($content -and $content.EndsWith("`r")) {
        $content = $content.Substring(0, $content.Length - 1)
    }
    
    return $content
}

# Function to check if prompt content has meaningful text (not just comments)
function Test-PromptHasContent {
    param(
        [string]$Content,
        [string]$ContentType
    )
    
    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $false
    }
    
    # Remove HTML comments and check if anything meaningful remains
    $withoutComments = $Content -replace '<!--[\s\S]*?-->', ''
    # Remove markdown headers that are just titles
    $withoutHeaders = $withoutComments -replace '^#.*$', '' -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    
    if ($withoutHeaders.Count -eq 0) {
        Write-Host "Warning: $ContentType appears to contain only comments or headers. The prompt may not produce meaningful results." -ForegroundColor Yellow
        Write-Host "Tip: Add actual instructions to your prompt file, or use -UseDefaults to use the built-in default prompts." -ForegroundColor Gray
        return $false
    }
    
    return $true
}

# Function to get the prompt cache directory
function Get-PromptCacheDir {
    if (-not [string]::IsNullOrEmpty($script:PromptCacheDir)) {
        return $script:PromptCacheDir
    }
    
    # Default to ~/.copilot-cli-automation/prompts/
    $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    return Join-Path $homeDir ".copilot-cli-automation" "prompts"
}

# Function to parse prompt reference (owner/repo:name or just name)
function Parse-PromptReference {
    param([string]$Reference)
    
    $result = @{
        Owner = ""
        Repo = ""
        Path = "prompts"
        Name = ""
        FullRepo = ""
    }
    
    if ($Reference -match '^([^/:]+)/([^/:]+):(.+)$') {
        # Format: owner/repo:name or owner/repo:path/name
        $result.Owner = $matches[1]
        $result.Repo = $matches[2]
        $result.FullRepo = "$($matches[1])/$($matches[2])"
        $pathAndName = $matches[3]
        
        # Check if there's a nested path
        if ($pathAndName -match '^(.+)/([^/]+)$') {
            $result.Path = $matches[1]
            $result.Name = $matches[2]
        } else {
            $result.Path = "prompts"
            $result.Name = $pathAndName
        }
    } else {
        # Format: just name - use default repo
        $defaultParts = $script:DefaultPromptRepo -split '/'
        $result.Owner = $defaultParts[0]
        $result.Repo = $defaultParts[1]
        $result.FullRepo = $script:DefaultPromptRepo
        $result.Path = "prompts"
        $result.Name = $Reference
    }
    
    return $result
}

# Function to get cached prompt path
function Get-CachedPromptPath {
    param([hashtable]$ParsedRef)
    
    $cacheDir = Get-PromptCacheDir
    $repoDir = Join-Path $cacheDir $ParsedRef.Owner $ParsedRef.Repo
    
    # Ensure .prompt.md extension
    $fileName = $ParsedRef.Name
    if (-not $fileName.EndsWith(".prompt.md")) {
        $fileName = "$fileName.prompt.md"
    }
    
    return Join-Path $repoDir $fileName
}

# Function to fetch prompt from GitHub repository
function Get-RemotePrompt {
    param(
        [string]$PromptReference,
        [switch]$ForceRefresh
    )
    
    $parsed = Parse-PromptReference -Reference $PromptReference
    $cachedPath = Get-CachedPromptPath -ParsedRef $parsed
    
    # Check cache first (unless force refresh)
    if (-not $ForceRefresh -and (Test-Path $cachedPath)) {
        Write-Log "Using cached prompt: $cachedPath"
        return Get-Content -Path $cachedPath -Raw
    }
    
    # Ensure .prompt.md extension for URL
    $fileName = $parsed.Name
    if (-not $fileName.EndsWith(".prompt.md")) {
        $fileName = "$fileName.prompt.md"
    }
    
    # Construct GitHub raw URL
    $url = "https://raw.githubusercontent.com/$($parsed.FullRepo)/main/$($parsed.Path)/$fileName"
    
    Write-Host "Fetching prompt from: $url" -ForegroundColor Cyan
    Write-Log "Fetching prompt from URL: $url"
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        $content = $response.Content
        
        # Cache the prompt
        $cacheDir = Split-Path $cachedPath -Parent
        if (-not (Test-Path $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        $content | Set-Content -Path $cachedPath -Encoding UTF8 -NoNewline
        Write-Log "Cached prompt to: $cachedPath"
        
        return $content
    } catch {
        if (Test-Path $cachedPath) {
            Write-Host "Warning: Could not fetch remote prompt, using cached version" -ForegroundColor Yellow
            return Get-Content -Path $cachedPath -Raw
        }
        throw "Failed to fetch prompt '$PromptReference' from $url. Error: $($_.Exception.Message)"
    }
}

# Function to parse prompt file frontmatter (YAML-like)
function Parse-PromptFrontmatter {
    param([string]$Content)
    
    $result = @{
        Description = ""
        Tools = @()
        Agent = ""
        Body = $Content
    }
    
    # Check for YAML frontmatter (--- at start and end)
    if ($Content -match '^---\s*\r?\n([\s\S]*?)\r?\n---\s*\r?\n([\s\S]*)$') {
        $frontmatter = $matches[1]
        $result.Body = $matches[2].Trim()
        
        # Parse frontmatter fields
        if ($frontmatter -match "description:\s*['""]?([^'""]+)['""]?") {
            $result.Description = $matches[1].Trim()
        }
        if ($frontmatter -match "agent:\s*['""]?([^'""]+)['""]?") {
            $result.Agent = $matches[1].Trim()
        }
        if ($frontmatter -match "tools:\s*\[([^\]]+)\]") {
            $toolsStr = $matches[1]
            $result.Tools = $toolsStr -split ',' | ForEach-Object { $_.Trim().Trim("'").Trim('"') }
        }
    }
    
    return $result
}

# Function to list prompts from a repository
function Get-PromptList {
    param(
        [string]$RepoReference = ""
    )
    
    # Parse repo reference or use default
    $repo = if ([string]::IsNullOrEmpty($RepoReference)) { $script:DefaultPromptRepo } else { $RepoReference }
    
    # Use GitHub API to list prompts directory
    $apiUrl = "https://api.github.com/repos/$repo/contents/prompts"
    
    Write-Host "Fetching prompt list from: $repo" -ForegroundColor Cyan
    
    try {
        $headers = @{}
        if (-not [string]::IsNullOrEmpty($env:GH_TOKEN)) {
            $headers["Authorization"] = "token $($env:GH_TOKEN)"
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        
        $prompts = $response | Where-Object { $_.name -match '\.prompt\.md$' } | ForEach-Object {
            $name = $_.name -replace '\.prompt\.md$', ''
            @{
                Name = $name
                FullName = $_.name
                Repo = $repo
                Url = $_.download_url
            }
        }
        
        return $prompts
    } catch {
        throw "Failed to list prompts from $repo. Error: $($_.Exception.Message)"
    }
}

# Function to search prompts by keyword
function Search-Prompts {
    param(
        [string]$Query
    )
    
    # Parse query for repo:keyword format
    $repo = $script:DefaultPromptRepo
    $keyword = $Query
    
    if ($Query -match '^([^/:]+/[^/:]+):(.+)$') {
        $repo = $matches[1]
        $keyword = $matches[2]
    }
    
    Write-Host "Searching for '$keyword' in $repo..." -ForegroundColor Cyan
    
    $allPrompts = Get-PromptList -RepoReference $repo
    
    # Filter by keyword (case-insensitive)
    $matches = $allPrompts | Where-Object { $_.Name -match $keyword }
    
    return $matches
}

# Function to show prompt information
function Show-PromptInfo {
    param([string]$PromptReference)
    
    $content = Get-RemotePrompt -PromptReference $PromptReference
    $parsed = Parse-PromptFrontmatter -Content $content
    $ref = Parse-PromptReference -Reference $PromptReference
    
    Write-Host ""
    Write-Host "Prompt: $($ref.Name)" -ForegroundColor Green
    Write-Host "Repository: $($ref.FullRepo)" -ForegroundColor Gray
    Write-Host ""
    
    if (-not [string]::IsNullOrEmpty($parsed.Description)) {
        Write-Host "Description:" -ForegroundColor Yellow
        Write-Host "  $($parsed.Description)"
        Write-Host ""
    }
    
    if (-not [string]::IsNullOrEmpty($parsed.Agent)) {
        Write-Host "Agent: $($parsed.Agent)" -ForegroundColor Yellow
    }
    
    if ($parsed.Tools.Count -gt 0) {
        Write-Host "Required Tools:" -ForegroundColor Yellow
        foreach ($tool in $parsed.Tools) {
            Write-Host "  - $tool"
        }
        Write-Host ""
    }
    
    Write-Host "Preview (first 500 chars):" -ForegroundColor Yellow
    $preview = if ($parsed.Body.Length -gt 500) { $parsed.Body.Substring(0, 500) + "..." } else { $parsed.Body }
    Write-Host $preview -ForegroundColor Gray
}

# Function to display prompt list
function Show-PromptList {
    param([array]$Prompts)
    
    if ($Prompts.Count -eq 0) {
        Write-Host "No prompts found." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Available Prompts ($($Prompts.Count) found):" -ForegroundColor Green
    Write-Host ""
    
    foreach ($prompt in $Prompts | Sort-Object { $_.Name }) {
        Write-Host "  $($prompt.Name)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Usage: -UsePrompt <name> or -UsePrompt owner/repo:name" -ForegroundColor Gray
    Write-Host "Info:  -PromptInfo <name> for details" -ForegroundColor Gray
}

# Function to initialize a new project with copilot-cli configuration
function Initialize-CopilotCliProject {
    # Check if this is agent creation mode
    if ($AsAgent) {
        if ([string]::IsNullOrEmpty($AgentName)) {
            Write-Host "Error: -AgentName is required when using -AsAgent" -ForegroundColor Red
            Write-Host "Example: -Init -AsAgent -AgentName 'my-custom-agent'" -ForegroundColor Gray
            return
        }
        
        # Create agent in .copilot-agents/ directory
        $agentsBaseDir = Join-Path (Get-Location) ".copilot-agents"
        $agentDir = Join-Path $agentsBaseDir $AgentName
        
        if (Test-Path $agentDir) {
            Write-Host "Error: Agent '$AgentName' already exists at: $agentDir" -ForegroundColor Red
            return
        }
        
        # Create agent directory structure
        New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
        
        $configPath = Join-Path $agentDir "copilot-cli.properties"
        $userPromptPath = Join-Path $agentDir "user.prompt.md"
        $agentMdPath = Join-Path $agentDir "$AgentName.agent.md"
        $descPath = Join-Path $agentDir "description.txt"
        
        $configContent = @"
# Custom Agent Configuration: $AgentName
# Generated by copilot-cli.ps1 -Init -AsAgent

# Prompt Configuration
prompt.file=user.prompt.md
agent.file=$AgentName.agent.md

# Model Selection
copilot.model=claude-sonnet-4.5

# Tool Permissions
allow.all.tools=true
allow.all.paths=false

# GitHub Authentication (if needed)
# github.token=ghp_xxxxxxxxxxxxxxxxxxxx

# Execution settings
log.level=info
timeout.minutes=30
"@

        $userPromptContent = @"
# User Prompt: $AgentName

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
"@

        $agentMdContent = @"
---
name: $AgentName
description: "Custom agent: $AgentName"
tools:
  - read
  - edit
  - search
---

You are an expert code reviewer focused on:
- Code quality and maintainability
- Best practices and design patterns
- Security and performance

Provide:
- Clear, actionable recommendations
- Examples of improvements when possible
- Priority levels for each finding
"@

        $descContent = "Custom agent: $AgentName"
        
        $configContent | Set-Content -Path $configPath -Encoding UTF8
        $userPromptContent | Set-Content -Path $userPromptPath -Encoding UTF8  
        $agentMdContent | Set-Content -Path $agentMdPath -Encoding UTF8
        $descContent | Set-Content -Path $descPath -Encoding UTF8
        
        Write-Host ""
        Write-Host "Created custom agent '$AgentName':" -ForegroundColor Green
        Write-Host "  Location: $agentDir" -ForegroundColor White
        Write-Host ""
        Write-Host "Files created:" -ForegroundColor Cyan
        Write-Host "  - copilot-cli.properties" -ForegroundColor White
        Write-Host "  - user.prompt.md" -ForegroundColor White
        Write-Host "  - $AgentName.agent.md" -ForegroundColor White
        Write-Host "  - description.txt" -ForegroundColor White
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Edit the prompt files in: $agentDir" -ForegroundColor Gray
        Write-Host "  2. Run: .\copilot-cli.ps1 -Agent $AgentName" -ForegroundColor Cyan
        Write-Host ""
        return
    }
    
    # Standard project initialization (original behavior)
    $configPath = Join-Path (Get-Location) "copilot-cli.properties"
    $userPromptPath = Join-Path (Get-Location) "user.prompt.md"
    $agentMdPath = Join-Path (Get-Location) "default.agent.md"
    
    if (Test-Path $configPath) {
        Write-Host "Configuration file already exists: $configPath" -ForegroundColor Yellow
        return
    }
    
    $configContent = @"
# Copilot CLI Wrapper Configuration
# Generated by copilot-cli.ps1 -Init

# Prompt Configuration
# Use one of: prompt, prompt.file, or use.prompt
# prompt=Your prompt text here
prompt.file=user.prompt.md
agent.file=default.agent.md

# Or use a pre-built prompt from awesome-copilot (or custom repo)
# use.prompt=code-review
# default.prompt.repo=github/awesome-copilot

# Custom Agent Directories
# agent.directory=./.copilot-agents
# additional.agent.directories=./ci/agents,./custom-agents

# Model Selection
copilot.model=claude-sonnet-4.5

# Tool Permissions
allow.all.tools=true
allow.all.paths=false

# Timeout (minutes)
timeout.minutes=30

# Log Level (none, error, warning, info, debug, all)
log.level=info
"@

    $userPromptContent = @"
# User Prompt

<!-- 
This file contains the main prompt/task for Copilot CLI.
Edit this file to specify what you want Copilot to do.
-->

Analyze this codebase and provide a summary of:
1. The project structure and architecture
2. Key technologies and frameworks used
3. Potential areas for improvement
"@

    $agentMdContent = @"
---
name: default
description: "Default Copilot CLI agent for code analysis"
tools:
  - read
  - edit
  - search
---

You are a helpful AI assistant focused on code quality and best practices.
Please follow these guidelines:
- Be thorough but concise in your analysis
- Provide actionable recommendations
- Consider security, performance, and maintainability
"@
    
    $configContent | Set-Content -Path $configPath -Encoding UTF8
    $userPromptContent | Set-Content -Path $userPromptPath -Encoding UTF8  
    $agentMdContent | Set-Content -Path $agentMdPath -Encoding UTF8
    
    Write-Host "Initialized Copilot CLI configuration:" -ForegroundColor Green
    Write-Host "  - $configPath" -ForegroundColor White
    Write-Host "  - $userPromptPath" -ForegroundColor White
    Write-Host "  - $agentMdPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Edit these files and run: .\copilot-cli.ps1" -ForegroundColor Cyan
}

# ============================================================================
# Remote Agent Repository Functions
# ============================================================================

# Function to detect if a string references a remote GitHub repository (not a local path)
function Test-IsRemoteAgentRef {
    param([string]$Ref)
    
    if ([string]::IsNullOrEmpty($Ref)) { return $false }
    
    # If it looks like a local path, it's not remote
    if ($Ref.StartsWith('.') -or $Ref.StartsWith('/') -or $Ref.StartsWith('~') -or $Ref -match '^[A-Za-z]:') {
        return $false
    }
    # If it exists as a local directory, it's not remote
    $resolvedPath = Resolve-FilePath -FilePath $Ref
    if (Test-Path $resolvedPath) { return $false }
    
    # Match owner/repo, owner/repo@branch, owner/repo:agent, owner/repo@branch:agent
    if ($Ref -match '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(@[A-Za-z0-9_./%-]+)?(:[A-Za-z0-9_.-]+)?$') {
        return $true
    }
    
    return $false
}

# Function to parse a remote agent repository reference
# Supported formats:
#   owner/repo                    -> all agents from agents/ dir, main branch
#   owner/repo:agent-name         -> single agent, main branch
#   owner/repo@branch             -> all agents, specific branch
#   owner/repo@branch:agent-name  -> single agent, specific branch
function Parse-AgentRepoReference {
    param([string]$Ref)
    
    $result = @{
        Owner = ""
        Repo = ""
        FullRepo = ""
        Branch = "main"
        AgentName = ""
        IsAll = $true
    }
    
    $remaining = $Ref
    
    # Extract agent name after ':'
    if ($remaining -match '^(.+):([^:@]+)$') {
        $remaining = $matches[1]
        $result.AgentName = $matches[2]
        $result.IsAll = $false
    }
    
    # Extract branch after '@'
    if ($remaining -match '^(.+)@(.+)$') {
        $remaining = $matches[1]
        $result.Branch = $matches[2]
    }
    
    # Parse owner/repo
    if ($remaining -match '^([^/]+)/(.+)$') {
        $result.Owner = $matches[1]
        $result.Repo = $matches[2]
        $result.FullRepo = "$($matches[1])/$($matches[2])"
    } else {
        # Bare repo name - cannot form a valid GitHub URL
        Write-Host "Error: Invalid remote agent reference '$Ref'. Expected format: owner/repo[@branch][:agent-name]" -ForegroundColor Red
        return $null
    }
    
    return $result
}

# Function to get the agent cache directory
function Get-AgentCacheDir {
    if (-not [string]::IsNullOrEmpty($script:AgentCacheDir)) {
        return $script:AgentCacheDir
    }
    
    $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    return Join-Path $homeDir ".copilot-cli-automation" "agents"
}

# Function to sync (download) agents from a remote GitHub repository
function Sync-RemoteAgentRepo {
    param(
        [string]$Reference,
        [switch]$ForceRefresh
    )
    
    $parsed = Parse-AgentRepoReference -Ref $Reference
    if (-not $parsed) { return @() }
    
    $cacheBase = Get-AgentCacheDir
    $repoCache = Join-Path $cacheBase $parsed.Owner $parsed.Repo
    
    # Known files that can exist in an agent directory
    $knownFiles = @("copilot-cli.properties", "user.prompt.md", "description.txt", "mcp-config.json")
    
    # Prepare authentication headers
    $headers = @{
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "CopilotCLI-AgentSync"
    }
    $token = $env:GITHUB_TOKEN
    if (-not $token -and $env:GH_TOKEN) { $token = $env:GH_TOKEN }
    if (-not $token) {
        try { $token = & gh auth token 2>$null } catch { }
    }
    if ($token) { $headers["Authorization"] = "Bearer $token" }
    
    $syncedPaths = @()
    
    if ($parsed.IsAll) {
        # List all subdirectories under agents/
        $apiUrl = "https://api.github.com/repos/$($parsed.FullRepo)/contents/agents?ref=$($parsed.Branch)"
        Write-Log "Fetching agent list from: $apiUrl"
        
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 30
            $agentDirs = $response | Where-Object { $_.type -eq "dir" }
            
            if ($agentDirs.Count -eq 0) {
                Write-Host "Warning: No agent directories found in $($parsed.FullRepo)/agents/" -ForegroundColor Yellow
                return @()
            }
            
            foreach ($dir in $agentDirs) {
                $agentName = $dir.name
                $agentCachePath = Join-Path $repoCache $agentName
                
                # Skip if cached and not force refresh
                if (-not $ForceRefresh -and (Test-Path $agentCachePath) -and 
                    (Get-ChildItem -Path $agentCachePath -File -ErrorAction SilentlyContinue).Count -gt 0) {
                    Write-Log "Using cached agent: $agentName"
                    $syncedPaths += $agentCachePath
                    continue
                }
                
                # Create cache directory
                if (-not (Test-Path $agentCachePath)) {
                    New-Item -ItemType Directory -Path $agentCachePath -Force | Out-Null
                }
                
                # Download known files + any .agent.md file
                $downloadedAny = $false
                foreach ($fileName in $knownFiles) {
                    $fileUrl = "https://raw.githubusercontent.com/$($parsed.FullRepo)/$($parsed.Branch)/agents/$agentName/$fileName"
                    $destPath = Join-Path $agentCachePath $fileName
                    try {
                        $fileHeaders = @{ "User-Agent" = "CopilotCLI-AgentSync" }
                        if ($token) { $fileHeaders["Authorization"] = "Bearer $token" }
                        Invoke-WebRequest -Uri $fileUrl -Headers $fileHeaders -OutFile $destPath -UseBasicParsing -ErrorAction Stop | Out-Null
                        $downloadedAny = $true
                    } catch {
                        # File doesn't exist in remote - that's OK
                    }
                }
                
                # Also try to download {agent-name}.agent.md
                $agentMdUrl = "https://raw.githubusercontent.com/$($parsed.FullRepo)/$($parsed.Branch)/agents/$agentName/$agentName.agent.md"
                $agentMdDest = Join-Path $agentCachePath "$agentName.agent.md"
                try {
                    $fileHeaders = @{ "User-Agent" = "CopilotCLI-AgentSync" }
                    if ($token) { $fileHeaders["Authorization"] = "Bearer $token" }
                    Invoke-WebRequest -Uri $agentMdUrl -Headers $fileHeaders -OutFile $agentMdDest -UseBasicParsing -ErrorAction Stop | Out-Null
                    $downloadedAny = $true
                } catch { }
                
                if ($downloadedAny) {
                    Write-Host "Synced remote agent: $agentName (from $($parsed.FullRepo))" -ForegroundColor Green
                    $syncedPaths += $agentCachePath
                }
            }
        } catch {
            $statusCode = $null
            if ($_.Exception -and $_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            
            if ($statusCode -eq 404) {
                Write-Host "Error: Repository '$($parsed.FullRepo)' not found or has no 'agents/' directory" -ForegroundColor Red
                Write-Host "Expected structure: $($parsed.FullRepo)/agents/<agent-name>/" -ForegroundColor Gray
            } elseif ($statusCode -eq 401 -or $statusCode -eq 403) {
                Write-Host "Error: Authentication required for '$($parsed.FullRepo)'. Set GITHUB_TOKEN or run 'gh auth login'" -ForegroundColor Red
            } else {
                Write-Host "Error: Failed to list agents from $($parsed.FullRepo): $($_.Exception.Message)" -ForegroundColor Red
            }
            return @()
        }
    } else {
        # Single agent mode
        $agentName = $parsed.AgentName
        $agentCachePath = Join-Path $repoCache $agentName
        
        # Skip if cached and not force refresh
        if (-not $ForceRefresh -and (Test-Path $agentCachePath) -and 
            (Get-ChildItem -Path $agentCachePath -File -ErrorAction SilentlyContinue).Count -gt 0) {
            Write-Log "Using cached agent: $agentName"
            return @($agentCachePath)
        }
        
        # Create cache directory
        if (-not (Test-Path $agentCachePath)) {
            New-Item -ItemType Directory -Path $agentCachePath -Force | Out-Null
        }
        
        # Download known files
        $downloadedAny = $false
        foreach ($fileName in $knownFiles) {
            $fileUrl = "https://raw.githubusercontent.com/$($parsed.FullRepo)/$($parsed.Branch)/agents/$agentName/$fileName"
            $destPath = Join-Path $agentCachePath $fileName
            try {
                $fileHeaders = @{ "User-Agent" = "CopilotCLI-AgentSync" }
                if ($token) { $fileHeaders["Authorization"] = "Bearer $token" }
                Invoke-WebRequest -Uri $fileUrl -Headers $fileHeaders -OutFile $destPath -UseBasicParsing -ErrorAction Stop | Out-Null
                $downloadedAny = $true
            } catch { }
        }
        
        # Also try {agent-name}.agent.md
        $agentMdUrl = "https://raw.githubusercontent.com/$($parsed.FullRepo)/$($parsed.Branch)/agents/$agentName/$agentName.agent.md"
        $agentMdDest = Join-Path $agentCachePath "$agentName.agent.md"
        try {
            $fileHeaders = @{ "User-Agent" = "CopilotCLI-AgentSync" }
            if ($token) { $fileHeaders["Authorization"] = "Bearer $token" }
            Invoke-WebRequest -Uri $agentMdUrl -Headers $fileHeaders -OutFile $agentMdDest -UseBasicParsing -ErrorAction Stop | Out-Null
            $downloadedAny = $true
        } catch { }
        
        if ($downloadedAny) {
            Write-Host "Synced remote agent: $agentName (from $($parsed.FullRepo))" -ForegroundColor Green
            $syncedPaths += $agentCachePath
        } else {
            Write-Host "Error: Agent '$agentName' not found in $($parsed.FullRepo)/agents/" -ForegroundColor Red
        }
    }
    
    return $syncedPaths
}

# Function to get built-in agents from examples directory and custom directories
function Get-BuiltInAgents {
    $searchDirs = @()
    $agents = @()
    $seenNames = @{}
    
    # 1. User-specified primary directory (highest priority)
    # Supports both local paths and remote repo references (owner/repo[@branch][:agent-name])
    if (-not [string]::IsNullOrEmpty($script:AgentDirectory)) {
        if (Test-IsRemoteAgentRef -Ref $script:AgentDirectory) {
            $remotePaths = Sync-RemoteAgentRepo -Reference $script:AgentDirectory -ForceRefresh:$script:UpdateAgentCache
            foreach ($rp in $remotePaths) {
                $searchDirs += $rp
            }
            Write-Log "Synced remote agent directory: $($script:AgentDirectory)"
        } else {
            $resolvedDir = Resolve-FilePath -FilePath $script:AgentDirectory
            if (Test-Path $resolvedDir) {
                $searchDirs += $resolvedDir
                Write-Log "Using custom agent directory: $resolvedDir"
            }
        }
    }
    
    # 2. User-specified additional directories
    # Each entry can independently be a local path or remote repo reference
    if (-not [string]::IsNullOrEmpty($script:AdditionalAgentDirectories)) {
        $dirs = $script:AdditionalAgentDirectories -split ',' | ForEach-Object { $_.Trim() }
        foreach ($dir in $dirs) {
            if (Test-IsRemoteAgentRef -Ref $dir) {
                $remotePaths = Sync-RemoteAgentRepo -Reference $dir -ForceRefresh:$script:UpdateAgentCache
                foreach ($rp in $remotePaths) {
                    $searchDirs += $rp
                }
                Write-Log "Synced remote additional agent directory: $dir"
            } else {
                $resolvedDir = Resolve-FilePath -FilePath $dir
                if (Test-Path $resolvedDir) {
                    $searchDirs += $resolvedDir
                    Write-Log "Using additional agent directory: $resolvedDir"
                }
            }
        }
    }
    
    # 3. Environment variable (COPILOT_AGENT_DIRECTORIES)
    if ($env:COPILOT_AGENT_DIRECTORIES) {
        $dirs = $env:COPILOT_AGENT_DIRECTORIES -split ';' | ForEach-Object { $_.Trim() }
        foreach ($dir in $dirs) {
            if (-not [string]::IsNullOrEmpty($dir) -and (Test-Path $dir)) {
                $searchDirs += $dir
                Write-Log "Using agent directory from environment: $dir"
            }
        }
    }
    
    # 4. .copilot-agents/ in current working directory (convention)
    $localAgentsDir = Join-Path (Get-Location) ".copilot-agents"
    if (Test-Path $localAgentsDir) {
        $searchDirs += $localAgentsDir
        Write-Log "Using local agent directory: $localAgentsDir"
    }
    
    # 5. Built-in examples (fallback, lowest priority)
    $examplesDir = Join-Path $ScriptDir "examples"
    if (Test-Path $examplesDir) {
        $searchDirs += $examplesDir
    }
    
    # Discover agents from all directories (first occurrence wins)
    foreach ($searchDir in $searchDirs) {
        if (-not (Test-Path $searchDir)) {
            continue
        }
        
        Get-ChildItem -Path $searchDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $agentDir = $_.FullName
            $agentName = $_.Name
            
            # Skip if we've already seen this agent name (first wins)
            if ($seenNames.ContainsKey($agentName)) {
                return
            }
            
            # Check if this is a valid agent directory (has a properties file or prompt files)
            $hasConfig = (Test-Path (Join-Path $agentDir "copilot-cli.properties")) -or 
                         (Test-Path (Join-Path $agentDir "*.properties"))
            $hasPrompt = (Test-Path (Join-Path $agentDir "user.prompt.md")) -or
                         (Test-Path (Join-Path $agentDir "*.agent.md"))
            
            if ($hasConfig -or $hasPrompt) {
                $description = ""
                $descFile = Join-Path $agentDir "description.txt"
                if (Test-Path $descFile) {
                    $description = (Get-Content $descFile -Raw).Trim()
                }
                
                $agents += [PSCustomObject]@{
                    Name = $agentName
                    Path = $agentDir
                    Description = $description
                    Source = $searchDir
                }
                
                $seenNames[$agentName] = $true
            }
        }
    }
    
    return $agents
}

# Function to install an .agent.md file to .github/agents/ in the working directory
function Install-AgentToRepository {
    param(
        [string]$AgentFile,
        [string]$AgentName
    )
    
    if ([string]::IsNullOrEmpty($AgentFile) -or -not (Test-Path $AgentFile)) {
        Write-Log "No agent file to install or file not found: $AgentFile"
        return
    }
    
    $agentFileName = Split-Path -Leaf $AgentFile
    $targetDir = Join-Path (Get-Location) ".github" "agents"
    $targetFile = Join-Path $targetDir $agentFileName
    
    if (Test-Path $targetFile) {
        Write-Log "Agent file already installed at: $targetFile"
        return
    }
    
    # Create .github/agents/ directory if it doesn't exist
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Log "Created directory: $targetDir"
    }
    
    # Copy the agent file
    Copy-Item -Path $AgentFile -Destination $targetFile -Force
    Write-Host "Installed agent '$AgentName' to: $targetFile" -ForegroundColor Green
    Write-Log "Copied agent file from $AgentFile to $targetFile"
}

# Function to display built-in agents list
function Show-BuiltInAgents {
    $agents = Get-BuiltInAgents
    
    if ($agents.Count -eq 0) {
        Write-Host ""
        Write-Host "No agents found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To get started with agents:" -ForegroundColor Cyan
        Write-Host "  - Use a remote agent repo:  -AgentDirectory owner/repo" -ForegroundColor White
        Write-Host "  - Create a custom agent:    -Init -AsAgent -AgentName `"my-agent`"" -ForegroundColor White
        Write-Host "  - Add a local agent dir:    -AgentDirectory ./my-agents" -ForegroundColor White
        Write-Host "  - Reinstall with examples:  Re-run install without -SkipExamples" -ForegroundColor White
        Write-Host ""
        return
    }
    
    Write-Host ""
    Write-Host "Built-in Agents:" -ForegroundColor Green
    Write-Host ""
    
    $maxNameLen = ($agents | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
    $maxNameLen = [Math]::Max($maxNameLen, 20)
    
    foreach ($agent in $agents | Sort-Object Name) {
        $paddedName = $agent.Name.PadRight($maxNameLen)
        if ($agent.Description) {
            Write-Host "  $paddedName  $($agent.Description)" -ForegroundColor White
        } else {
            Write-Host "  $paddedName" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "Usage: -Agent <name>  (e.g., -Agent code-review)" -ForegroundColor Gray
}

# Function to load a built-in agent configuration
function Get-BuiltInAgentConfig {
    param([string]$AgentName)
    
    # Check if AgentName is actually a path (contains / or \)
    if ($AgentName.Contains('/') -or $AgentName.Contains('\')) {
        Write-Log "Agent specified as path: $AgentName"
        
        # Resolve and validate the path
        $agentPath = Resolve-FilePath -FilePath $AgentName
        if (-not (Test-Path $agentPath)) {
            Write-Host "Error: Agent path not found: $AgentName" -ForegroundColor Red
            return $null
        }
        
        # Check if it's a valid agent directory
        $hasConfig = (Test-Path (Join-Path $agentPath "copilot-cli.properties")) -or 
                     (Get-ChildItem -Path $agentPath -Filter "*.properties" -ErrorAction SilentlyContinue).Count -gt 0
        $hasPrompt = (Test-Path (Join-Path $agentPath "user.prompt.md")) -or
                     ((Get-ChildItem -Path $agentPath -Filter "*.agent.md" -ErrorAction SilentlyContinue).Count -gt 0)
        
        if (-not ($hasConfig -or $hasPrompt)) {
            Write-Host "Error: Directory does not appear to be a valid agent (no config or prompt files found)" -ForegroundColor Red
            Write-Host "Expected files: copilot-cli.properties, user.prompt.md, or *.agent.md" -ForegroundColor Gray
            return $null
        }
        
        # Build result from path
        $result = @{
            Path = $agentPath
            PropertiesFile = $null
            UserPromptFile = $null
            AgentFile = $null
        }
        
        # Look for properties file
        $propsFile = Join-Path $agentPath "copilot-cli.properties"
        if (Test-Path $propsFile) {
            $result.PropertiesFile = $propsFile
        } else {
            $propsFiles = Get-ChildItem -Path $agentPath -Filter "*.properties" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($propsFiles) {
                $result.PropertiesFile = $propsFiles.FullName
            }
        }
        
        # Look for prompt files
        $userPrompt = Join-Path $agentPath "user.prompt.md"
        if (Test-Path $userPrompt) {
            $result.UserPromptFile = $userPrompt
        }
        
        $agentMdFiles = Get-ChildItem -Path $agentPath -Filter "*.agent.md" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($agentMdFiles) {
            $result.AgentFile = $agentMdFiles.FullName
        }
        
        return $result
    }
    
    # Search by name in agent directories
    $agents = Get-BuiltInAgents
    $agent = $agents | Where-Object { $_.Name -eq $AgentName }
    
    if (-not $agent) {
        Write-Host "Error: Agent '$AgentName' not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available agents:" -ForegroundColor Yellow
        foreach ($a in $agents | Select-Object -First 10 | Sort-Object Name) {
            $source = if ($a.Source) { " (from $($a.Source))" } else { "" }
            Write-Host "  - $($a.Name)$source" -ForegroundColor Gray
        }
        if ($agents.Count -gt 10) {
            Write-Host "  ... and $($agents.Count - 10) more" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Use -ListAgents to see all available agents" -ForegroundColor Gray
        return $null
    }
    
    $result = @{
        Path = $agent.Path
        PropertiesFile = $null
        UserPromptFile = $null
        AgentFile = $null
    }
    
    # Look for properties file
    $propsFile = Join-Path $agent.Path "copilot-cli.properties"
    if (Test-Path $propsFile) {
        $result.PropertiesFile = $propsFile
    } else {
        # Look for any .properties file
        $propsFiles = Get-ChildItem -Path $agent.Path -Filter "*.properties" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($propsFiles) {
            $result.PropertiesFile = $propsFiles.FullName
        }
    }
    
    # Look for prompt files
    $userPrompt = Join-Path $agent.Path "user.prompt.md"
    if (Test-Path $userPrompt) {
        $result.UserPromptFile = $userPrompt
    }
    
    $agentMdFiles = Get-ChildItem -Path $agent.Path -Filter "*.agent.md" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($agentMdFiles) {
        $result.AgentFile = $agentMdFiles.FullName
    }
    
    return $result
}

# ============================================================================
# Multi-Agent Composition Functions
# ============================================================================

# Function to parse comma-separated agent list
function Get-AgentList {
    param([string]$AgentsString)
    
    $agents = $AgentsString -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    return $agents
}

# Function to validate all agents in a list exist
function Test-AgentList {
    param([string]$AgentsString)
    
    $agents = Get-AgentList -AgentsString $AgentsString
    $allAgents = Get-BuiltInAgents
    $validAgents = @()
    $invalidAgents = @()
    
    foreach ($agentName in $agents) {
        $exists = $allAgents | Where-Object { $_.Name -eq $agentName }
        if ($exists) {
            $validAgents += $agentName
        } else {
            $invalidAgents += $agentName
        }
    }
    
    if ($invalidAgents.Count -gt 0) {
        Write-Host "Error: The following agents were not found:" -ForegroundColor Red
        foreach ($agent in $invalidAgents) {
            Write-Host "  - $agent" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Available agents:" -ForegroundColor Yellow
        foreach ($agent in $allAgents) {
            Write-Host "  - $($agent.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Use -ListAgents to see all available agents." -ForegroundColor Gray
        return $null
    }
    
    return $validAgents
}

# Function to run a single agent and capture results
function Invoke-SingleAgent {
    param(
        [string]$AgentName,
        [int]$AgentIndex,
        [int]$TotalAgents,
        [string]$OutputDir
    )
    
    $startTime = Get-Date
    $outputFile = Join-Path $OutputDir "$AgentName.output.md"
    
    Write-Host ""
    Write-Host "===== Running Agent: $AgentName ($AgentIndex/$TotalAgents) =====" -ForegroundColor Cyan
    Write-Host ""
    
    # Get agent configuration
    $builtInConfig = Get-BuiltInAgentConfig -AgentName $AgentName
    if (-not $builtInConfig) {
        Write-Host "Error: Failed to load agent '$AgentName'" -ForegroundColor Red
        return @{
            Success = $false
            ExitCode = 1
            Duration = 0
            Output = ""
        }
    }
    
    # Store original values
    $origConfig = $script:Config
    $origPromptFile = $script:PromptFile
    $origAgentFile = $script:AgentFile
    $origPrompt = $script:Prompt
    $origAgent = $script:Agent
    
    # Apply agent configuration
    if ($builtInConfig.PropertiesFile) {
        $script:Config = $builtInConfig.PropertiesFile
        Load-Config -ConfigFile $script:Config
    }
    
    if ($builtInConfig.UserPromptFile) {
        $script:PromptFile = $builtInConfig.UserPromptFile
        $script:Prompt = ""
    }
    
    if ($builtInConfig.AgentFile) {
        $script:AgentFile = $builtInConfig.AgentFile
        Install-AgentToRepository -AgentFile $script:AgentFile -AgentName $AgentName
        $script:Agent = $AgentName
    }
    
    # Load prompts from files
    if ([string]::IsNullOrEmpty($script:Prompt) -and -not [string]::IsNullOrEmpty($script:PromptFile)) {
        $resolvedPromptFile = Resolve-FilePath -FilePath $script:PromptFile
        if (Test-Path $resolvedPromptFile) {
            $script:Prompt = Get-Content $resolvedPromptFile -Raw
        }
    }
    
    # Build command
    $copilotCmd = Build-CopilotCommand
    
    Write-Host "Agent command: $copilotCmd" -ForegroundColor Gray
    Write-Host ""
    
    $exitCode = 0
    $output = ""
    
    # Execute with output capture
    $outputBuilder = New-Object System.Text.StringBuilder
    [void]$outputBuilder.AppendLine("# Agent: $AgentName")
    [void]$outputBuilder.AppendLine("## Execution Time: $(Get-Date -Format 'o')")
    [void]$outputBuilder.AppendLine("")
    
    if ($DryRun) {
        $dryRunMsg = "[DRY RUN] Command: $copilotCmd"
        [void]$outputBuilder.AppendLine($dryRunMsg)
        Write-Host $dryRunMsg -ForegroundColor Yellow
    } else {
        try {
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "powershell.exe"
            $processInfo.Arguments = "-Command `"& { $copilotCmd }`""
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.UseShellExecute = $false
            $processInfo.CreateNoWindow = $true
            $processInfo.WorkingDirectory = (Get-Location).Path
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            
            $process.Start() | Out-Null
            
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            
            $timeoutMs = $TimeoutMinutes * 60 * 1000
            $completed = $process.WaitForExit($timeoutMs)
            
            if (-not $completed) {
                $process.Kill()
                throw "Agent execution timed out after $TimeoutMinutes minutes"
            }
            
            $exitCode = $process.ExitCode
            
            # Output stdout
            if ($stdout) {
                Write-Host $stdout
                [void]$outputBuilder.AppendLine($stdout)
            }
            if ($stderr) {
                Write-Host $stderr -ForegroundColor Yellow
                [void]$outputBuilder.AppendLine($stderr)
            }
            
        } catch {
            $exitCode = 1
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            [void]$outputBuilder.AppendLine("Error: $($_.Exception.Message)")
        } finally {
            if ($process -and -not $process.HasExited) {
                try { $process.Kill() } catch { }
            }
            if ($process) {
                $process.Dispose()
            }
        }
    }
    
    $output = $outputBuilder.ToString()
    $output | Out-File -FilePath $outputFile -Encoding utf8
    
    $endTime = Get-Date
    $duration = [int]($endTime - $startTime).TotalSeconds
    
    # Restore original values
    $script:Config = $origConfig
    $script:PromptFile = $origPromptFile
    $script:AgentFile = $origAgentFile
    $script:Prompt = $origPrompt
    $script:Agent = $origAgent
    
    # Report status
    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "Agent '$AgentName' completed successfully (${duration}s)" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Agent '$AgentName' failed with exit code $exitCode (${duration}s)" -ForegroundColor Red
    }
    
    return @{
        Success = ($exitCode -eq 0)
        ExitCode = $exitCode
        Duration = $duration
        Output = $output
    }
}

# Function to run multiple agents sequentially
function Invoke-AgentQueue {
    param(
        [string]$AgentsString,
        [string]$ErrorMode
    )
    
    # Create output directory
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $outputBaseDir = Join-Path $env:USERPROFILE ".copilot-cli-automation\runs"
    $outputDir = Join-Path $outputBaseDir $timestamp
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    
    # Parse and validate agents
    $agents = Test-AgentList -AgentsString $AgentsString
    if (-not $agents) {
        return $false
    }
    
    $totalAgents = $agents.Count
    
    if ($totalAgents -eq 0) {
        Write-Host "Error: No agents specified" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    Write-Host "===== Multi-Agent Execution =====" -ForegroundColor Cyan
    Write-Host "Agents to run: $($agents -join ', ')"
    Write-Host "Error mode: $ErrorMode"
    Write-Host "Output directory: $outputDir"
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Track results
    $passed = 0
    $failed = 0
    $results = @()
    $startTotal = Get-Date
    
    # Run each agent
    $index = 1
    foreach ($agentName in $agents) {
        $status = "PASSED"
        
        $result = Invoke-SingleAgent -AgentName $agentName -AgentIndex $index -TotalAgents $totalAgents -OutputDir $outputDir
        
        if ($result.Success) {
            $passed++
        } else {
            $failed++
            $status = "FAILED"
            
            if ($ErrorMode -eq "stop") {
                Write-Host ""
                Write-Host "Error mode is 'stop'. Aborting remaining agents." -ForegroundColor Yellow
                break
            }
        }
        
        $results += @{
            Name = $agentName
            Status = $status
            Duration = $result.Duration
        }
        
        $index++
    }
    
    $endTotal = Get-Date
    $totalDuration = [int]($endTotal - $startTotal).TotalSeconds
    
    # Generate summary
    Write-Host ""
    Write-Host "===== Multi-Agent Run Summary =====" -ForegroundColor Cyan
    Write-Host "Total agents: $totalAgents | Passed: $passed | Failed: $failed"
    Write-Host "Total duration: ${totalDuration}s"
    Write-Host ""
    
    # Print individual results
    foreach ($r in $results) {
        $color = if ($r.Status -eq "PASSED") { "Green" } else { "Red" }
        Write-Host ("  {0,-25} [{1}] ({2}s)" -f $r.Name, $r.Status, $r.Duration) -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "Outputs saved to: $outputDir" -ForegroundColor Gray
    Write-Host "====================================" -ForegroundColor Cyan
    
    # Save summary to file
    $summaryContent = @"
# Multi-Agent Run Summary
## $(Get-Date -Format 'o')

- **Total agents:** $totalAgents
- **Passed:** $passed
- **Failed:** $failed
- **Total duration:** ${totalDuration}s
- **Error mode:** $ErrorMode

## Results

"@
    foreach ($r in $results) {
        $summaryContent += "- **$($r.Name)**: $($r.Status) ($($r.Duration)s)`n"
    }
    
    $summaryContent | Out-File -FilePath (Join-Path $outputDir "SUMMARY.md") -Encoding utf8
    
    # Return failure if any agent failed
    return ($failed -eq 0)
}

# Function to load configuration from properties file
function Load-Config {
    param([string]$ConfigFile)
    
    if (Test-Path $ConfigFile) {
        Write-Log "Loading configuration from $ConfigFile"
        $config = @{}
        
        Get-Content $ConfigFile | ForEach-Object {
            $line = $_.Trim()
            
            # Skip comments and empty lines
            if ($line -match '^#' -or [string]::IsNullOrEmpty($line)) {
                return
            }
            
            # Parse key=value pairs
            if ($line -match '^([^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                # Remove quotes if present
                if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                    $value = $value.Substring(1, $value.Length - 2)
                } elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
                $config[$key] = $value
            }
        }
        
        # Apply configuration values if not overridden by command line
        if ($config.ContainsKey("prompt") -and [string]::IsNullOrEmpty($script:Prompt)) {
            $script:Prompt = $config["prompt"]
        }
        if ($config.ContainsKey("prompt.file") -and [string]::IsNullOrEmpty($script:PromptFile)) {
            $script:PromptFile = $config["prompt.file"]
        }
        if ($config.ContainsKey("agent.file") -and [string]::IsNullOrEmpty($script:AgentFile)) {
            $script:AgentFile = $config["agent.file"]
        }
        if ($config.ContainsKey("github.token") -and [string]::IsNullOrEmpty($script:GithubToken)) {
            $script:GithubToken = $config["github.token"]
        }
        if ($config.ContainsKey("mcp.config") -and [string]::IsNullOrEmpty($script:McpConfig)) {
            $script:McpConfig = $config["mcp.config"]
        }
        if ($config.ContainsKey("mcp.config.file") -and [string]::IsNullOrEmpty($script:McpConfigFile)) {
            $script:McpConfigFile = $config["mcp.config.file"]
        }
        if ($config.ContainsKey("copilot.model") -and $script:Model -eq "claude-sonnet-4.5") {
            $script:Model = $config["copilot.model"]
        }
        if ($config.ContainsKey("auto.install.cli") -and $script:AutoInstallCli -eq "true") {
            $script:AutoInstallCli = $config["auto.install.cli"]
        }
        if ($config.ContainsKey("allow.all.tools") -and $script:AllowAllTools -eq "true") {
            $script:AllowAllTools = Parse-Bool $config["allow.all.tools"]
        }
        if ($config.ContainsKey("allow.all.paths") -and $script:AllowAllPaths -eq "false") {
            $script:AllowAllPaths = Parse-Bool $config["allow.all.paths"]
        }
        if ($config.ContainsKey("additional.directories") -and [string]::IsNullOrEmpty($script:AdditionalDirectories)) {
            $script:AdditionalDirectories = $config["additional.directories"]
        }
        if ($config.ContainsKey("allowed.tools") -and [string]::IsNullOrEmpty($script:AllowedTools)) {
            $script:AllowedTools = $config["allowed.tools"]
        }
        if ($config.ContainsKey("denied.tools") -and [string]::IsNullOrEmpty($script:DeniedTools)) {
            $script:DeniedTools = $config["denied.tools"]
        }
        if ($config.ContainsKey("disable.builtin.mcps") -and $script:DisableBuiltinMcps -eq "false") {
            $script:DisableBuiltinMcps = Parse-Bool $config["disable.builtin.mcps"]
        }
        if ($config.ContainsKey("disable.mcp.servers") -and [string]::IsNullOrEmpty($script:DisableMcpServers)) {
            $script:DisableMcpServers = $config["disable.mcp.servers"]
        }
        if ($config.ContainsKey("enable.all.github.mcp.tools") -and $script:EnableAllGithubMcpTools -eq "false") {
            $script:EnableAllGithubMcpTools = Parse-Bool $config["enable.all.github.mcp.tools"]
        }
        if ($config.ContainsKey("log.level") -and $script:LogLevel -eq "info") {
            $script:LogLevel = $config["log.level"]
        }
        if ($config.ContainsKey("working.directory") -and $script:WorkingDirectory -eq ".") {
            $script:WorkingDirectory = $config["working.directory"]
        }
        if ($config.ContainsKey("node.version") -and $script:NodeVersion -eq "22") {
            $script:NodeVersion = $config["node.version"]
        }
        if ($config.ContainsKey("timeout.minutes") -and $script:TimeoutMinutes -eq 30) {
            $script:TimeoutMinutes = [int]$config["timeout.minutes"]
        }
        
        # New: Prompt repository options
        if ($config.ContainsKey("use.prompt") -and [string]::IsNullOrEmpty($script:UsePrompt)) {
            $script:UsePrompt = $config["use.prompt"]
        }
        if ($config.ContainsKey("default.prompt.repo") -and $script:DefaultPromptRepo -eq "github/awesome-copilot") {
            $script:DefaultPromptRepo = $config["default.prompt.repo"]
        }
        if ($config.ContainsKey("prompt.cache.dir") -and [string]::IsNullOrEmpty($script:PromptCacheDir)) {
            $script:PromptCacheDir = $config["prompt.cache.dir"]
        }
        
        # New: Custom agent directories
        if ($config.ContainsKey("agent.directory") -and [string]::IsNullOrEmpty($script:AgentDirectory)) {
            $script:AgentDirectory = $config["agent.directory"]
        }
        if ($config.ContainsKey("additional.agent.directories") -and [string]::IsNullOrEmpty($script:AdditionalAgentDirectories)) {
            $script:AdditionalAgentDirectories = $config["additional.agent.directories"]
        }
        if ($config.ContainsKey("agent.cache.dir") -and [string]::IsNullOrEmpty($script:AgentCacheDir)) {
            $script:AgentCacheDir = $config["agent.cache.dir"]
        }
        
        # New: CLI parity options
        if ($config.ContainsKey("agent") -and [string]::IsNullOrEmpty($script:Agent)) {
            $script:Agent = $config["agent"]
        }
        if ($config.ContainsKey("allow.all.urls") -and $script:AllowAllUrls -eq "false") {
            $script:AllowAllUrls = Parse-Bool $config["allow.all.urls"]
        }
        if ($config.ContainsKey("allow.urls") -and [string]::IsNullOrEmpty($script:AllowUrls)) {
            $script:AllowUrls = $config["allow.urls"]
        }
        if ($config.ContainsKey("deny.urls") -and [string]::IsNullOrEmpty($script:DenyUrls)) {
            $script:DenyUrls = $config["deny.urls"]
        }
        if ($config.ContainsKey("available.tools") -and [string]::IsNullOrEmpty($script:AvailableTools)) {
            $script:AvailableTools = $config["available.tools"]
        }
        if ($config.ContainsKey("excluded.tools") -and [string]::IsNullOrEmpty($script:ExcludedTools)) {
            $script:ExcludedTools = $config["excluded.tools"]
        }
        if ($config.ContainsKey("add.github.mcp.tool") -and [string]::IsNullOrEmpty($script:AddGitHubMcpTool)) {
            $script:AddGitHubMcpTool = $config["add.github.mcp.tool"]
        }
        if ($config.ContainsKey("add.github.mcp.toolset") -and [string]::IsNullOrEmpty($script:AddGitHubMcpToolset)) {
            $script:AddGitHubMcpToolset = $config["add.github.mcp.toolset"]
        }
        if ($config.ContainsKey("no.ask.user") -and $script:NoAskUser -eq "false") {
            $script:NoAskUser = Parse-Bool $config["no.ask.user"]
        }
        if ($config.ContainsKey("config.dir") -and [string]::IsNullOrEmpty($script:ConfigDir)) {
            $script:ConfigDir = $config["config.dir"]
        }
        if ($config.ContainsKey("share") -and [string]::IsNullOrEmpty($script:Share)) {
            $script:Share = $config["share"]
        }
        if ($config.ContainsKey("resume") -and [string]::IsNullOrEmpty($script:Resume)) {
            $script:Resume = $config["resume"]
        }
    } else {
        Write-Log "Configuration file $ConfigFile not found, using defaults"
    }
}

# Function to validate required dependencies
function Test-Dependencies {
    Write-Log "Checking dependencies..."
    
    # Check Node.js version
    try {
        $nodeVersion = node --version
        $majorVersion = [int]($nodeVersion -replace 'v(\d+).*', '$1')
        
        if ($majorVersion -lt 20) {
            throw "Node.js version $nodeVersion is not supported. Minimum required: 20"
        }
    } catch {
        throw "Node.js is not installed or not in PATH"
    }
    
    # Check if copilot CLI is installed
    try {
        $null = Get-Command copilot -ErrorAction Stop
        
        # Check if we should update to latest version
        if ($script:AutoInstallCli -eq "true") {
            Write-Log "Checking for Copilot CLI updates..."
            try {
                npm update -g @github/copilot@latest 2>$null
            } catch {
                # Ignore update errors
            }
        }
    } catch {
        if ($script:AutoInstallCli -eq "true") {
            Write-Host "GitHub Copilot CLI not found. Installing latest version..."
            Write-Log "Running: npm install -g @github/copilot@latest"
            try {
                npm install -g @github/copilot@latest
                Write-Host "[OK] GitHub Copilot CLI installed successfully" -ForegroundColor Green
            } catch {
                throw "Failed to install GitHub Copilot CLI. Try installing manually: npm install -g @github/copilot"
            }
        } else {
            throw "GitHub Copilot CLI is not installed. Install with: npm install -g @github/copilot or enable auto-install with: -AutoInstallCli true"
        }
    }
}

# Function to setup GitHub authentication
function Set-GitHubAuth {
    Write-Log "Setting up GitHub authentication..."
    
    # Determine which token to use (in order of precedence)
    $token = ""
    
    if (-not [string]::IsNullOrEmpty($script:GithubToken)) {
        $token = $script:GithubToken
        Write-Log "Using GitHub token from command line parameter"
    } elseif (-not [string]::IsNullOrEmpty($env:COPILOT_GITHUB_TOKEN)) {
        $token = $env:COPILOT_GITHUB_TOKEN
        Write-Log "Using GitHub token from COPILOT_GITHUB_TOKEN environment variable"
    } elseif (-not [string]::IsNullOrEmpty($env:GH_TOKEN)) {
        $token = $env:GH_TOKEN
        Write-Log "Using GitHub token from GH_TOKEN environment variable"
    } elseif (-not [string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
        $token = $env:GITHUB_TOKEN
        Write-Log "Using GitHub token from GITHUB_TOKEN environment variable"
    }
    
    # Set the environment variable for Copilot CLI if we have a token
    if (-not [string]::IsNullOrEmpty($token)) {
        $env:GH_TOKEN = $token
        $env:GITHUB_TOKEN = $token
        $env:COPILOT_GITHUB_TOKEN = $token
        Write-Log "GitHub token configured for authentication"
    } else {
        Write-Log "No GitHub token provided, relying on existing GitHub CLI authentication"
    }
}

# Function to validate MCP configuration
function Test-McpConfig {
    param([string]$Config)
    
    if (-not [string]::IsNullOrEmpty($Config)) {
        try {
            $null = $Config | ConvertFrom-Json
        } catch {
            throw "Invalid JSON in MCP configuration: $($_.Exception.Message)"
        }
    }
}

# Function to build copilot command
function Build-CopilotCommand {
    # Use the user prompt directly (agent behavior is handled by .agent.md in .github/agents/)
    $fullPrompt = $Prompt
    
    # Use single quotes to avoid PowerShell parsing issues with parentheses
    $escapedPrompt = $fullPrompt -replace "'", "''"
    $cmd = "copilot -p '$escapedPrompt'"
    
    # Add model
    if (-not [string]::IsNullOrEmpty($Model)) {
        $cmd += " --model $Model"
    }
    
    # Add agent if specified
    if (-not [string]::IsNullOrEmpty($Agent)) {
        $cmd += " --agent `"$Agent`""
    }
    
    # Add tool permissions
    if ($AllowAllTools -eq "true") {
        $cmd += " --allow-all-tools"
    }
    
    # Add --allow-all-paths flag only if explicitly enabled (FIXED: was always adding this)
    if ($AllowAllPaths -eq "true") {
        $cmd += " --allow-all-paths"
    }
    
    # Add URL permissions
    if ($AllowAllUrls -eq "true") {
        $cmd += " --allow-all-urls"
    }
    
    # Add allowed URLs
    if (-not [string]::IsNullOrEmpty($AllowUrls)) {
        $urls = $AllowUrls -split ',' | ForEach-Object { $_.Trim() }
        foreach ($url in $urls) {
            $cmd += " --allow-url `"$url`""
        }
    }
    
    # Add denied URLs
    if (-not [string]::IsNullOrEmpty($DenyUrls)) {
        $urls = $DenyUrls -split ',' | ForEach-Object { $_.Trim() }
        foreach ($url in $urls) {
            $cmd += " --deny-url `"$url`""
        }
    }
    
    # Add allowed tools
    if (-not [string]::IsNullOrEmpty($AllowedTools)) {
        $tools = $AllowedTools -split ',' | ForEach-Object { $_.Trim() }
        foreach ($tool in $tools) {
            $cmd += " --allow-tool `"$tool`""
        }
    }
    
    # Add denied tools
    if (-not [string]::IsNullOrEmpty($DeniedTools)) {
        $tools = $DeniedTools -split ',' | ForEach-Object { $_.Trim() }
        foreach ($tool in $tools) {
            $cmd += " --deny-tool `"$tool`""
        }
    }
    
    # Add available tools (limit which tools are available)
    if (-not [string]::IsNullOrEmpty($AvailableTools)) {
        $tools = $AvailableTools -split ',' | ForEach-Object { $_.Trim() }
        foreach ($tool in $tools) {
            $cmd += " --available-tools `"$tool`""
        }
    }
    
    # Add excluded tools
    if (-not [string]::IsNullOrEmpty($ExcludedTools)) {
        $tools = $ExcludedTools -split ',' | ForEach-Object { $_.Trim() }
        foreach ($tool in $tools) {
            $cmd += " --excluded-tools `"$tool`""
        }
    }
    
    # Add additional directories
    if (-not [string]::IsNullOrEmpty($AdditionalDirectories)) {
        $dirs = $AdditionalDirectories -split ',' | ForEach-Object { $_.Trim() }
        foreach ($dir in $dirs) {
            $cmd += " --add-dir `"$dir`""
        }
    }
    
    # Add MCP configuration
    if (-not [string]::IsNullOrEmpty($McpConfigFile)) {
        $resolvedMcpConfigFile = Resolve-FilePath -FilePath $McpConfigFile
        if (-not (Test-Path $resolvedMcpConfigFile)) {
            Write-Host "Error: MCP configuration file not found: $McpConfigFile" -ForegroundColor Red
            
            # Find similar JSON files
            $directory = Split-Path $resolvedMcpConfigFile -Parent
            if ([string]::IsNullOrEmpty($directory)) { $directory = $ScriptDir }
            $jsonFiles = Get-ChildItem -Path $directory -Filter "*.json" -ErrorAction SilentlyContinue | Select-Object -First 5
            if ($jsonFiles) {
                Write-Host ""
                Write-Host "Available .json files in directory:" -ForegroundColor Yellow
                foreach ($file in $jsonFiles) {
                    Write-Host "  - $($file.Name)" -ForegroundColor Cyan
                }
            }
            Write-Host ""
            throw "MCP configuration file '$McpConfigFile' not found"
        }
        $cmd += " --additional-mcp-config @$resolvedMcpConfigFile"
    } elseif (-not [string]::IsNullOrEmpty($McpConfig)) {
        # Create temporary file for MCP config
        $tempMcpFile = [System.IO.Path]::GetTempFileName()
        $McpConfig | Set-Content -Path $tempMcpFile -Encoding UTF8
        $cmd += " --additional-mcp-config @$tempMcpFile"
        
        # Store temp file path for cleanup
        $script:TempMcpFile = $tempMcpFile
    }
    
    # Add MCP server options
    if ($DisableBuiltinMcps -eq "true") {
        $cmd += " --disable-builtin-mcps"
    }
    
    if ($EnableAllGithubMcpTools -eq "true") {
        $cmd += " --enable-all-github-mcp-tools"
    }
    
    # Add GitHub MCP tools
    if (-not [string]::IsNullOrEmpty($AddGitHubMcpTool)) {
        $tools = $AddGitHubMcpTool -split ',' | ForEach-Object { $_.Trim() }
        foreach ($tool in $tools) {
            $cmd += " --add-github-mcp-tool `"$tool`""
        }
    }
    
    # Add GitHub MCP toolsets
    if (-not [string]::IsNullOrEmpty($AddGitHubMcpToolset)) {
        $toolsets = $AddGitHubMcpToolset -split ',' | ForEach-Object { $_.Trim() }
        foreach ($toolset in $toolsets) {
            $cmd += " --add-github-mcp-toolset `"$toolset`""
        }
    }
    
    # Add disabled MCP servers
    if (-not [string]::IsNullOrEmpty($DisableMcpServers)) {
        $servers = $DisableMcpServers -split ',' | ForEach-Object { $_.Trim() }
        foreach ($server in $servers) {
            $cmd += " --disable-mcp-server `"$server`""
        }
    }
    
    # Add autonomous mode (no ask user)
    if ($NoAskUser -eq "true") {
        $cmd += " --no-ask-user"
    }
    
    # Add config directory
    if (-not [string]::IsNullOrEmpty($ConfigDir)) {
        $cmd += " --config-dir `"$ConfigDir`""
    }
    
    # Add session resume options
    if ($Continue) {
        $cmd += " --continue"
    } elseif (-not [string]::IsNullOrEmpty($Resume)) {
        $cmd += " --resume `"$Resume`""
    }
    
    # Add share options
    if (-not [string]::IsNullOrEmpty($Share)) {
        $cmd += " --share `"$Share`""
    }
    if ($ShareGist) {
        $cmd += " --share-gist"
    }
    
    # Add silent mode
    if ($Silent) {
        $cmd += " --silent"
    }
    
    # Add log level
    if (-not [string]::IsNullOrEmpty($LogLevel)) {
        $cmd += " --log-level $LogLevel"
    }
    
    # Add no-color flag conditionally (auto-detect CI/CD or use explicit flag)
    $isCI = $env:CI -eq 'true' -or $env:GITHUB_ACTIONS -eq 'true' -or $env:TF_BUILD -eq 'True' -or $env:JENKINS_URL
    if ($NoColor -or $isCI) {
        $cmd += " --no-color"
        Write-Log "No-color mode enabled for better output compatibility"
    }
    
    return $cmd
}

# Function to cleanup temporary files
function Cleanup {
    if ($script:TempMcpFile -and (Test-Path $script:TempMcpFile)) {
        Remove-Item $script:TempMcpFile -Force
    }
}

# Main execution
try {
    # Show help if requested
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    # Handle -Init command
    if ($Init) {
        Initialize-CopilotCliProject
        exit 0
    }
    
    # Handle -ListAgents command
    if ($ListAgents) {
        Show-BuiltInAgents
        exit 0
    }
    
    # Handle -Diagnose command
    if ($Diagnose) {
        Show-DiagnosticStatus
        exit 0
    }
    
    # Handle -UpdateAgentCache: set flag so remote syncs use force refresh
    if ($UpdateAgentCache) {
        Write-Host "Agent cache will be refreshed on next sync operation." -ForegroundColor Cyan
    }
    
    # Check for COPILOT_AGENT environment variable if no agent specified
    if ([string]::IsNullOrEmpty($Agent) -and [string]::IsNullOrEmpty($Agents) -and $env:COPILOT_AGENT) {
        $Agent = $env:COPILOT_AGENT
        Write-Log "Using agent from COPILOT_AGENT environment variable: $Agent"
    }
    
    # Check for mutual exclusivity of -Agent and -Agents
    if (-not [string]::IsNullOrEmpty($Agent) -and -not [string]::IsNullOrEmpty($Agents)) {
        Write-Host "Error: Cannot use both -Agent and -Agents together." -ForegroundColor Red
        Write-Host "Use -Agent for a single agent, or -Agents for multiple agents." -ForegroundColor Yellow
        exit 1
    }
    
    # Handle -Agents: run multiple agents sequentially
    if (-not [string]::IsNullOrEmpty($Agents)) {
        # Setup dependencies and auth first
        Test-Dependencies
        Set-GitHubAuth
        
        # Run the agent queue
        if (Invoke-AgentQueue -AgentsString $Agents -ErrorMode $AgentErrorMode) {
            exit 0
        } else {
            exit 1
        }
    }
    
    # Handle -Agent: check if it's a built-in agent first
    if (-not [string]::IsNullOrEmpty($Agent)) {
        $builtInConfig = Get-BuiltInAgentConfig -AgentName $Agent
        if ($builtInConfig) {
            Write-Host "Using built-in agent: $Agent" -ForegroundColor Cyan
            
            # Load the agent's properties file if it exists
            if ($builtInConfig.PropertiesFile) {
                $Config = $builtInConfig.PropertiesFile
            }
            
            # Set prompt files if not already set
            if ([string]::IsNullOrEmpty($PromptFile) -and $builtInConfig.UserPromptFile) {
                $PromptFile = $builtInConfig.UserPromptFile
            }
            
            # Install the .agent.md file to .github/agents/ in the working directory
            if ($builtInConfig.AgentFile) {
                $AgentFile = $builtInConfig.AgentFile
                Install-AgentToRepository -AgentFile $AgentFile -AgentName $Agent
            }
            
            # Keep the Agent variable so --agent flag is passed to copilot CLI
        }
    }
    
    # Load configuration file
    Load-Config -ConfigFile $Config
    
    # Setup GitHub authentication early (needed for API calls)
    Set-GitHubAuth
    
    # Handle -ListPrompts command
    if ($ListPrompts) {
        $prompts = Get-PromptList -RepoReference $DefaultPromptRepo
        Show-PromptList -Prompts $prompts
        exit 0
    }
    
    # Handle -SearchPrompts command
    if (-not [string]::IsNullOrEmpty($SearchPrompts)) {
        $results = Search-Prompts -Query $SearchPrompts
        Show-PromptList -Prompts $results
        exit 0
    }
    
    # Handle -PromptInfo command
    if (-not [string]::IsNullOrEmpty($PromptInfo)) {
        Show-PromptInfo -PromptReference $PromptInfo
        exit 0
    }
    
    # Handle -UpdatePromptCache command
    if ($UpdatePromptCache) {
        Write-Host "Updating prompt cache..." -ForegroundColor Cyan
        $prompts = Get-PromptList -RepoReference $DefaultPromptRepo
        foreach ($prompt in $prompts) {
            try {
                $null = Get-RemotePrompt -PromptReference $prompt.Name -ForceRefresh
                Write-Host "  Cached: $($prompt.Name)" -ForegroundColor Green
            } catch {
                Write-Host "  Failed: $($prompt.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host "Cache update complete." -ForegroundColor Green
        exit 0
    }
    
    # Handle -UsePrompt: fetch prompt from remote repository
    if (-not [string]::IsNullOrEmpty($UsePrompt)) {
        Write-Log "Fetching prompt: $UsePrompt"
        $promptContent = Get-RemotePrompt -PromptReference $UsePrompt
        $parsedPrompt = Parse-PromptFrontmatter -Content $promptContent
        
        # Use the prompt body as the main prompt
        if ([string]::IsNullOrEmpty($Prompt)) {
            $Prompt = $parsedPrompt.Body
        }
        
        # If the prompt specifies an agent and we don't have one, use it
        if ([string]::IsNullOrEmpty($Agent) -and -not [string]::IsNullOrEmpty($parsedPrompt.Agent)) {
            $Agent = $parsedPrompt.Agent
            Write-Log "Using agent from prompt: $Agent"
        }
        
        # If the prompt specifies tools and we have none configured, suggest them
        if ($parsedPrompt.Tools.Count -gt 0 -and [string]::IsNullOrEmpty($AllowedTools)) {
            Write-Log "Prompt recommends tools: $($parsedPrompt.Tools -join ', ')"
        }
    }
    
    # Handle -UseDefaults: use built-in default prompt files and agent
    if ($UseDefaults) {
        Write-Host "Using built-in default prompts" -ForegroundColor Cyan
        $PromptFile = "user.prompt.md"
        $AgentFile = "default.agent.md"
        # Clear any inline prompts to force loading from files
        $Prompt = ""
        # Install default agent
        $resolvedAgentFile = Resolve-FilePath -FilePath $AgentFile
        if (Test-Path $resolvedAgentFile) {
            Install-AgentToRepository -AgentFile $resolvedAgentFile -AgentName "default"
            $Agent = "default"
        }
    }
    
    # Install agent file if specified via config but not yet installed
    if (-not [string]::IsNullOrEmpty($AgentFile) -and [string]::IsNullOrEmpty($Agent)) {
        $resolvedAgentFile = Resolve-FilePath -FilePath $AgentFile
        if (Test-Path $resolvedAgentFile) {
            # Extract agent name from the filename (e.g., code-review.agent.md -> code-review)
            $agentBaseName = (Split-Path -Leaf $resolvedAgentFile) -replace '\.agent\.md$', ''
            Install-AgentToRepository -AgentFile $resolvedAgentFile -AgentName $agentBaseName
            $Agent = $agentBaseName
        }
    }
    
    # Load prompts from files if specified (command line params override)
    # Load prompt from file if PromptFile is specified and Prompt is empty
    if ([string]::IsNullOrEmpty($Prompt) -and -not [string]::IsNullOrEmpty($PromptFile)) {
        $resolvedPromptFile = Resolve-FilePath -FilePath $PromptFile
        $Prompt = Load-FileContent -FilePath $resolvedPromptFile -ContentType "Prompt"
    }
    
    # Validate that prompts have meaningful content (not just comments)
    if (-not [string]::IsNullOrEmpty($Prompt)) {
        $null = Test-PromptHasContent -Content $Prompt -ContentType "User prompt"
    }
    
    # Validate required parameters
    if ([string]::IsNullOrEmpty($Prompt)) {
        Write-Host ""
        Write-Host "GitHub Copilot CLI Wrapper - No prompt specified" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Quick Start:" -ForegroundColor Cyan
        Write-Host "  .\copilot-cli.ps1 -Prompt `"Your task here`""
        Write-Host "  .\copilot-cli.ps1 -UsePrompt code-review"
        Write-Host "  .\copilot-cli.ps1 -UseDefaults               # Use built-in default prompts"
        Write-Host "  .\copilot-cli.ps1 -Init                      # Create starter config"
        Write-Host ""
        Write-Host "Discover Prompts:" -ForegroundColor Cyan
        Write-Host "  .\copilot-cli.ps1 -ListPrompts              # List available prompts"
        Write-Host "  .\copilot-cli.ps1 -SearchPrompts security   # Search prompts"
        Write-Host "  .\copilot-cli.ps1 -PromptInfo code-review   # Show prompt details"
        Write-Host ""
        Write-Host "Use -Help for full documentation" -ForegroundColor Gray
        exit 1
    }
    
    # Print current working directory
    $currentDir = Get-Location
    $originalDir = $currentDir  # Store original directory to revert back later
    Write-Host "Working directory: $currentDir" -ForegroundColor Cyan
    Write-Log "Current working directory: $currentDir"
    
    # Check dependencies
    Test-Dependencies
    
    # Validate MCP configuration if provided
    if (-not [string]::IsNullOrEmpty($McpConfig)) {
        Test-McpConfig -Config $McpConfig
    }
    
    # Change to working directory
    if ($WorkingDirectory -ne ".") {
        Write-Log "Changing to working directory: $WorkingDirectory"
        if (-not (Test-Path $WorkingDirectory)) {
            throw "Working directory '$WorkingDirectory' does not exist"
        }
        Set-Location $WorkingDirectory
        $newDir = Get-Location
        Write-Host "Changed working directory to: $newDir" -ForegroundColor Cyan
    }
    
    # Build command
    $copilotCmd = Build-CopilotCommand
    
    Write-Host "Generated Copilot CLI command:"
    Write-Host $copilotCmd
    Write-Host
    
    if ($DryRun) {
        Write-Host "Dry run mode - command not executed" -ForegroundColor Yellow
        exit 0
    }
    
    # Execute the command with streaming output and timeout
    Write-Log "Executing Copilot CLI command with streaming output..."
    
    # Set environment variables for authentication
    if (-not [string]::IsNullOrEmpty($script:GithubToken)) {
        $env:GH_TOKEN = $script:GithubToken
        $env:GITHUB_TOKEN = $script:GithubToken
        $env:COPILOT_GITHUB_TOKEN = $script:GithubToken
    }
    
    # Execute with timeout using System.Diagnostics.Process for streaming output
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-Command `"& { $copilotCmd }`""
    $processInfo.RedirectStandardOutput = $false
    $processInfo.RedirectStandardError = $false
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $false
    $processInfo.WorkingDirectory = (Get-Location).Path
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    
    try {
        Write-Host "Starting Copilot CLI execution..." -ForegroundColor Yellow
        $process.Start()
        
        # Wait for completion with timeout
        $timeoutMs = $TimeoutMinutes * 60 * 1000
        $completed = $process.WaitForExit($timeoutMs)
        
        if ($completed) {
            if ($process.ExitCode -eq 0) {
                Write-Host "Copilot CLI execution completed successfully" -ForegroundColor Green
                # Restore original working directory
                if ($WorkingDirectory -ne "." -and $originalDir) {
                    Set-Location $originalDir
                    Write-Host "Restored working directory to: $originalDir" -ForegroundColor Cyan
                    Write-Log "Restored working directory to: $originalDir"
                }
            } else {
                throw "Copilot CLI execution failed with exit code: $($process.ExitCode)"
            }
        } else {
            $process.Kill()
            throw "Copilot CLI execution timed out after $TimeoutMinutes minutes"
        }
    } finally {
        if (-not $process.HasExited) {
            try { $process.Kill() } catch { }
        }
        $process.Dispose()
    }
    
} catch {
    $errorMsg = $_.Exception.Message
    Write-Host "Error: $errorMsg" -ForegroundColor Red
    
    # Provide actionable guidance based on error type
    if ($errorMsg -match "Node\.js is not installed") {
        Write-Host ""
        Write-Host "Quick fix:" -ForegroundColor Yellow
        Write-Host "  Install Node.js 20+ from: https://nodejs.org/" -ForegroundColor Cyan
    } elseif ($errorMsg -match "Copilot CLI .* not installed|GitHub Copilot CLI is not installed") {
        Write-Host ""
        Write-Host "Quick fix:" -ForegroundColor Yellow
        Write-Host "  npm install -g @github/copilot" -ForegroundColor Cyan
    } elseif ($errorMsg -match "authentication|token|401|403") {
        Write-Host ""
        Write-Host "Quick fix:" -ForegroundColor Yellow
        Write-Host "  gh auth login" -ForegroundColor Cyan
        Write-Host "  Or set: `$env:GITHUB_TOKEN = 'ghp_...'" -ForegroundColor Cyan
    } elseif ($errorMsg -match "timed out") {
        Write-Host ""
        Write-Host "The operation took too long. Consider:" -ForegroundColor Yellow
        Write-Host "  - Increasing timeout: -TimeoutMinutes 60" -ForegroundColor Cyan
        Write-Host "  - Simplifying the prompt" -ForegroundColor Cyan
    } elseif ($errorMsg -match "exit code: (\d+)") {
        $exitCode = $matches[1]
        Write-Host ""
        Write-Host "Copilot CLI exited with code $exitCode" -ForegroundColor Yellow
        switch ($exitCode) {
            "1" { Write-Host "  General error - check the output above for details" -ForegroundColor Cyan }
            "2" { Write-Host "  Invalid arguments - check your command syntax" -ForegroundColor Cyan }
            "126" { Write-Host "  Permission denied - check file permissions" -ForegroundColor Cyan }
            "127" { Write-Host "  Command not found - ensure Copilot CLI is installed" -ForegroundColor Cyan }
            default { Write-Host "  Unknown error - check the output above" -ForegroundColor Cyan }
        }
    }
    
    Write-Host ""
    Write-Host "Run with -Diagnose to check all prerequisites" -ForegroundColor Gray
    exit 1
} finally {
    # Restore original directory in case of errors
    if ($WorkingDirectory -ne "." -and $originalDir -and (Get-Location) -ne $originalDir) {
        try {
            Set-Location $originalDir
            Write-Log "Restored working directory to: $originalDir (cleanup)"
        } catch {
            Write-Log "Warning: Could not restore working directory: $($_.Exception.Message)"
        }
    }
    Cleanup
}