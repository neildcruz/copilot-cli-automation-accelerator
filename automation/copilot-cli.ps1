# GitHub Copilot CLI Wrapper Script (PowerShell)
# Provides the same functionality as the GitHub Action but for local execution
# Supports configuration via properties file and command line arguments

param(
    [string]$Config = "copilot-cli.properties",
    [string]$Prompt = "",
    [string]$SystemPrompt = "",
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
    [switch]$Help
)

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Config.Contains('\') -and -not $Config.Contains('/')) {
    $Config = Join-Path $ScriptDir $Config
}

# Function to show usage
function Show-Usage {
    Write-Host @"
GitHub Copilot CLI Wrapper Script (PowerShell)

Usage: .\copilot-cli.ps1 [OPTIONS]

OPTIONS:
    -Config FILE                   Configuration properties file (default: copilot-cli.properties)
    -Prompt TEXT                   The prompt to execute with Copilot CLI (required)
    -SystemPrompt TEXT             System prompt with guidelines to be emphasized and followed
    -GithubToken TOKEN             GitHub Personal Access Token for authentication
    -Model MODEL                   AI model to use (gpt-5, claude-sonnet-4, claude-sonnet-4.5)
    -AutoInstallCli BOOL           Automatically install Copilot CLI if not found (true/false, default: true)
    -McpConfig TEXT                MCP server configuration as JSON string
    -McpConfigFile FILE            MCP server configuration file path
    -AllowAllTools BOOL            Allow all tools to run automatically (true/false)
    -AllowAllPaths BOOL            Allow access to any path (true/false)
    -AdditionalDirectories DIRS    Comma-separated list of additional directories
    -AllowedTools TOOLS            Comma-separated list of allowed tools
    -DeniedTools TOOLS             Comma-separated list of denied tools
    -DisableBuiltinMcps BOOL       Disable all built-in MCP servers (true/false)
    -DisableMcpServers SERVERS     Comma-separated list of MCP servers to disable
    -EnableAllGithubMcpTools BOOL  Enable all GitHub MCP tools (true/false)
    -LogLevel LEVEL                Log level (none, error, warning, info, debug, all)
    -WorkingDirectory DIR          Working directory to run from
    -TimeoutMinutes MINUTES        Timeout in minutes
    -NoColor                       Disable colored output (automatically enabled for CI/CD)
    -DryRun                        Show command without executing
    -Verbose                       Enable verbose output
    -Help                          Show this help message

EXAMPLES:
    # Basic usage with prompt
    .\copilot-cli.ps1 -Prompt "Review the code for issues"
    
    # With system prompt for guidelines
    .\copilot-cli.ps1 -Prompt "Review the code" -SystemPrompt "Focus on security and performance issues only"
    
    # With GitHub token authentication
    .\copilot-cli.ps1 -Prompt "Review the code" -GithubToken "ghp_xxxxxxxxxxxxxxxxxxxx"
    
    # Using custom configuration file
    .\copilot-cli.ps1 -Config "my-config.properties" -Prompt "Analyze security"
    
    # With MCP configuration file
    .\copilot-cli.ps1 -Prompt "Use custom tools" -McpConfigFile "examples\mcp-config.json"
    
    # Dry run to see generated command
    .\copilot-cli.ps1 -Prompt "Test" -DryRun

AUTHENTICATION:
    GitHub Copilot CLI requires authentication via one of these methods (in order of precedence):
    1. -GithubToken command line parameter
    2. github.token in properties file  
    3. GH_TOKEN environment variable
    4. GITHUB_TOKEN environment variable
    5. Existing GitHub CLI authentication (gh auth login)

CONFIGURATION FILE:
    Create a .properties file with key=value pairs for any option.
    Command line arguments override configuration file values.

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
        if ($config.ContainsKey("system.prompt") -and [string]::IsNullOrEmpty($script:SystemPrompt)) {
            $script:SystemPrompt = $config["system.prompt"]
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
    
    # Add tool permissions
    if ($AllowAllTools -eq "true") {
        $cmd += " --allow-all-tools"
    }
    
    # Always add --allow-all-paths flag
    $cmd += " --allow-all-paths"
    
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
    
    # Add additional directories
    if (-not [string]::IsNullOrEmpty($AdditionalDirectories)) {
        $dirs = $AdditionalDirectories -split ',' | ForEach-Object { $_.Trim() }
        foreach ($dir in $dirs) {
            $cmd += " --add-dir `"$dir`""
        }
    }
    
    # Add MCP configuration
    if (-not [string]::IsNullOrEmpty($McpConfigFile)) {
        if (-not (Test-Path $McpConfigFile)) {
            throw "MCP configuration file '$McpConfigFile' not found"
        }
        $cmd += " --additional-mcp-config @$McpConfigFile"
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
    
    # Add disabled MCP servers
    if (-not [string]::IsNullOrEmpty($DisableMcpServers)) {
        $servers = $DisableMcpServers -split ',' | ForEach-Object { $_.Trim() }
        foreach ($server in $servers) {
            $cmd += " --disable-mcp-server `"$server`""
        }
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
    
    # Load configuration file
    Load-Config -ConfigFile $Config
    
    # Validate required parameters
    if ([string]::IsNullOrEmpty($Prompt)) {
        throw "Prompt is required. Use -Prompt parameter or set prompt in config file."
    }
    
    # Print current working directory
    $currentDir = Get-Location
    $originalDir = $currentDir  # Store original directory to revert back later
    Write-Host "Working directory: $currentDir" -ForegroundColor Cyan
    Write-Log "Current working directory: $currentDir"
    
    # Check dependencies
    Test-Dependencies
    
    # Setup GitHub authentication
    Set-GitHubAuth
    
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