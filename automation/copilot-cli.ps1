# GitHub Copilot CLI Wrapper Script (PowerShell)
# Provides the same functionality as the GitHub Action but for local execution
# Supports configuration via properties file and command line arguments

param(
    [string]$Config = "copilot-cli.properties",
    [string]$Prompt = "",
    [string]$PromptFile = "",
    [string]$SystemPrompt = "",
    [string]$SystemPromptFile = "",
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
    [switch]$ListAgents
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
    .\copilot-cli.ps1 -ListAgents                      # List available agents
    .\copilot-cli.ps1 -Prompt "Review this code"       # Direct prompt
    .\copilot-cli.ps1 -Init                            # Initialize project config

BUILT-IN AGENTS:
    -ListAgents                    List all available built-in agents
    -Agent NAME                    Use a built-in agent by name
                                   Examples: code-review, security-analysis, test-generation

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
    -SystemPrompt TEXT             System prompt with guidelines to emphasize
    -SystemPromptFile FILE         Load system prompt from file

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
    -Help                          Show this help message

EXAMPLES:
    # Use a pre-built prompt from awesome-copilot
    .\copilot-cli.ps1 -UsePrompt code-review
    .\copilot-cli.ps1 -UsePrompt conventional-commit
    
    # Use a prompt from a custom repository
    .\copilot-cli.ps1 -UsePrompt myorg/internal-prompts:security-audit
    
    # Set custom default repository for your organization
    .\copilot-cli.ps1 -DefaultPromptRepo myorg/prompts -UsePrompt api-review
    
    # Basic usage with inline prompt
    .\copilot-cli.ps1 -Prompt "Review the code for security issues"
    
    # Load prompt from file with system guidelines
    .\copilot-cli.ps1 -PromptFile task.md -SystemPromptFile guidelines.md
    
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

CONFIGURATION FILE (copilot-cli.properties):
    # Prompt options
    use.prompt=code-review
    default.prompt.repo=github/awesome-copilot
    prompt.file=user.prompt.md
    system.prompt.file=system.prompt.md
    
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

# Function to parse boolean values
function Parse-Bool {
    param([string]$Value)
    switch ($Value.ToLower()) {
        { $_ -in @("true", "yes", "1", "on") } { return "true" }
        { $_ -in @("false", "no", "0", "off") } { return "false" }
        default { return $Value }
    }
}

# Function to load content from file preserving formatting
function Load-FileContent {
    param(
        [string]$FilePath,
        [string]$ContentType
    )
    
    if (-not (Test-Path $FilePath)) {
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
    $configPath = Join-Path (Get-Location) "copilot-cli.properties"
    $userPromptPath = Join-Path (Get-Location) "user.prompt.md"
    $systemPromptPath = Join-Path (Get-Location) "system.prompt.md"
    
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
system.prompt.file=system.prompt.md

# Or use a pre-built prompt from awesome-copilot (or custom repo)
# use.prompt=code-review
# default.prompt.repo=github/awesome-copilot

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

    $systemPromptContent = @"
# System Prompt

<!-- 
This file contains guidelines and constraints for Copilot.
These instructions will be emphasized when executing your prompt.
-->

You are a helpful AI assistant focused on code quality and best practices.
Please follow these guidelines:
- Be thorough but concise in your analysis
- Provide actionable recommendations
- Consider security, performance, and maintainability
"@
    
    $configContent | Set-Content -Path $configPath -Encoding UTF8
    $userPromptContent | Set-Content -Path $userPromptPath -Encoding UTF8  
    $systemPromptContent | Set-Content -Path $systemPromptPath -Encoding UTF8
    
    Write-Host "Initialized Copilot CLI configuration:" -ForegroundColor Green
    Write-Host "  - $configPath" -ForegroundColor White
    Write-Host "  - $userPromptPath" -ForegroundColor White
    Write-Host "  - $systemPromptPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Edit these files and run: .\copilot-cli.ps1" -ForegroundColor Cyan
}

# Function to get built-in agents from examples directory
function Get-BuiltInAgents {
    $examplesDir = Join-Path $ScriptDir "examples"
    $agents = @()
    
    if (-not (Test-Path $examplesDir)) {
        return $agents
    }
    
    Get-ChildItem -Path $examplesDir -Directory | ForEach-Object {
        $agentDir = $_.FullName
        $agentName = $_.Name
        
        # Check if this is a valid agent directory (has a properties file or prompt files)
        $hasConfig = (Test-Path (Join-Path $agentDir "copilot-cli.properties")) -or 
                     (Test-Path (Join-Path $agentDir "*.properties"))
        $hasPrompt = (Test-Path (Join-Path $agentDir "user.prompt.md")) -or
                     (Test-Path (Join-Path $agentDir "system.prompt.md"))
        
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
            }
        }
    }
    
    return $agents
}

# Function to display built-in agents list
function Show-BuiltInAgents {
    $agents = Get-BuiltInAgents
    
    if ($agents.Count -eq 0) {
        Write-Host "No built-in agents found in examples directory." -ForegroundColor Yellow
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
    
    $agents = Get-BuiltInAgents
    $agent = $agents | Where-Object { $_.Name -eq $AgentName }
    
    if (-not $agent) {
        return $null
    }
    
    $result = @{
        Path = $agent.Path
        PropertiesFile = $null
        UserPromptFile = $null
        SystemPromptFile = $null
    }
    
    # Look for properties file
    $propsFile = Join-Path $agent.Path "copilot-cli.properties"
    if (Test-Path $propsFile) {
        $result.PropertiesFile = $propsFile
    } else {
        # Look for any .properties file
        $propsFiles = Get-ChildItem -Path $agent.Path -Filter "*.properties" | Select-Object -First 1
        if ($propsFiles) {
            $result.PropertiesFile = $propsFiles.FullName
        }
    }
    
    # Look for prompt files
    $userPrompt = Join-Path $agent.Path "user.prompt.md"
    if (Test-Path $userPrompt) {
        $result.UserPromptFile = $userPrompt
    }
    
    $systemPrompt = Join-Path $agent.Path "system.prompt.md"
    if (Test-Path $systemPrompt) {
        $result.SystemPromptFile = $systemPrompt
    }
    
    return $result
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
        if ($config.ContainsKey("system.prompt") -and [string]::IsNullOrEmpty($script:SystemPrompt)) {
            $script:SystemPrompt = $config["system.prompt"]
        }
        if ($config.ContainsKey("system.prompt.file") -and [string]::IsNullOrEmpty($script:SystemPromptFile)) {
            $script:SystemPromptFile = $config["system.prompt.file"]
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
    # Combine system prompt and user prompt
    $fullPrompt = $Prompt
    if (-not [string]::IsNullOrEmpty($SystemPrompt)) {
        $fullPrompt = "IMPORTANT: Please follow these guidelines strictly: $SystemPrompt`n`n$Prompt"
    }
    
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
            if ([string]::IsNullOrEmpty($SystemPromptFile) -and $builtInConfig.SystemPromptFile) {
                $SystemPromptFile = $builtInConfig.SystemPromptFile
            }
            
            # Clear the Agent variable so it doesn't get passed to copilot CLI
            # (built-in agents are handled via config/prompts, not --agent flag)
            $Agent = ""
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
    
    # Load prompts from files if specified (command line params override)
    # Load prompt from file if PromptFile is specified and Prompt is empty
    if ([string]::IsNullOrEmpty($Prompt) -and -not [string]::IsNullOrEmpty($PromptFile)) {
        $resolvedPromptFile = Resolve-FilePath -FilePath $PromptFile
        $Prompt = Load-FileContent -FilePath $resolvedPromptFile -ContentType "Prompt"
    }
    
    # Load system prompt from file if SystemPromptFile is specified and SystemPrompt is empty
    if ([string]::IsNullOrEmpty($SystemPrompt) -and -not [string]::IsNullOrEmpty($SystemPromptFile)) {
        $resolvedSystemPromptFile = Resolve-FilePath -FilePath $SystemPromptFile
        $SystemPrompt = Load-FileContent -FilePath $resolvedSystemPromptFile -ContentType "System prompt"
    }
    
    # Validate required parameters
    if ([string]::IsNullOrEmpty($Prompt)) {
        Write-Host ""
        Write-Host "GitHub Copilot CLI Wrapper - No prompt specified" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Quick Start:" -ForegroundColor Cyan
        Write-Host "  .\copilot-cli.ps1 -Prompt `"Your task here`""
        Write-Host "  .\copilot-cli.ps1 -UsePrompt code-review"
        Write-Host "  .\copilot-cli.ps1 -Init                     # Create starter config"
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
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
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