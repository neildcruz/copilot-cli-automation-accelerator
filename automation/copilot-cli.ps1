# GitHub Copilot CLI Wrapper Script (PowerShell)
# Provides the same functionality as the GitHub Action but for local execution
# Supports configuration via properties file and command line arguments

param(
    [string]$Config = "copilot-cli.properties",
    [string]$Prompt = "",
    [string]$SystemPrompt = "",
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
    -Config FILE                    Configuration properties file (default: copilot-cli.properties)
    -Prompt TEXT                   The prompt to execute with Copilot CLI (required)
    -SystemPrompt TEXT             System prompt with guidelines to be emphasized and followed
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
    -DryRun                        Show command without executing
    -Verbose                       Enable verbose output
    -Help                          Show this help message

EXAMPLES:
    # Basic usage with prompt
    .\copilot-cli.ps1 -Prompt "Review the code for issues"
    
    # With system prompt for guidelines
    .\copilot-cli.ps1 -Prompt "Review the code" -SystemPrompt "Focus on security and performance issues only"
    
    # Using custom configuration file
    .\copilot-cli.ps1 -Config "my-config.properties" -Prompt "Analyze security"
    
    # With MCP configuration file
    .\copilot-cli.ps1 -Prompt "Use custom tools" -McpConfigFile "examples\mcp-config.json"
    
    # Dry run to see generated command
    .\copilot-cli.ps1 -Prompt "Test" -DryRun

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
                $value = $value -replace '^["\']|["\']$', ''
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
                Write-Host "✓ GitHub Copilot CLI installed successfully" -ForegroundColor Green
            } catch {
                throw "Failed to install GitHub Copilot CLI. Try installing manually: npm install -g @github/copilot"
            }
        } else {
            throw "GitHub Copilot CLI is not installed. Install with: npm install -g @github/copilot or enable auto-install with: -AutoInstallCli true"
        }
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
    
    $cmd = "copilot -p `"$fullPrompt`""
    
    # Add model
    if (-not [string]::IsNullOrEmpty($Model)) {
        $cmd += " --model $Model"
    }
    
    # Add tool permissions
    if ($AllowAllTools -eq "true") {
        $cmd += " --allow-all-tools"
    }
    
    if ($AllowAllPaths -eq "true") {
        $cmd += " --allow-all-paths"
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
    
    # Add no-color for better output
    $cmd += " --no-color"
    
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
    
    # Execute the command with timeout
    Write-Log "Executing Copilot CLI command..."
    
    $job = Start-Job -ScriptBlock {
        param($cmd)
        Invoke-Expression $cmd
    } -ArgumentList $copilotCmd
    
    $completed = Wait-Job -Job $job -Timeout ($TimeoutMinutes * 60)
    
    if ($completed) {
        Receive-Job -Job $job
        Remove-Job -Job $job
        Write-Host "Copilot CLI execution completed successfully" -ForegroundColor Green
    } else {
        Stop-Job -Job $job
        Remove-Job -Job $job
        throw "Copilot CLI execution timed out after $TimeoutMinutes minutes"
    }
    
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
} finally {
    Cleanup
}