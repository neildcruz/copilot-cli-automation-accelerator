#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install script for GitHub Copilot CLI Automation Accelerator
    
.DESCRIPTION
    Downloads and installs the complete GitHub Copilot CLI Automation Suite from the remote repository.
    Supports both fresh installations and updates of existing installations.
    
.PARAMETER InstallPath
    Directory where the automation tools will be installed. Defaults to current directory.
    
.PARAMETER Mode
    Installation mode: 'current' (current directory) or 'central' (~/copilot-tools). Default: 'current'
    
.PARAMETER Update
    Update existing installation instead of creating new one
    
.PARAMETER Branch
    Git branch to download from. Default: 'main'
    
.PARAMETER Repository
    GitHub repository in format 'owner/repo'. Default: 'neildcruz/copilot-cli-automation-accelerator'

.EXAMPLE
    .\install.ps1
    
.EXAMPLE
    .\install.ps1 -Mode central
    
.EXAMPLE
    .\install.ps1 -InstallPath "C:\Tools\copilot-automation" -Update
#>

param(
    [string]$InstallPath = "",
    [ValidateSet('current', 'central')]
    [string]$Mode = 'current',
    [switch]$Update,
    [string]$Branch = 'main',
    [string]$Repository = 'neildcruz/copilot-cli-automation-accelerator'
)

# Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Color functions for output
function Write-Success { param($Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[X] $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "[i] $Message" -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "[-] $Message" -ForegroundColor Blue }

function Confirm-Action {
    param(
        [string]$Message,
        [string]$DefaultChoice = 'N'
    )
    
    $choices = if ($DefaultChoice -eq 'Y') { '[Y/n]' } else { '[y/N]' }
    $prompt = "$Message $choices"
    
    do {
        $response = Read-Host $prompt
        if ([string]::IsNullOrWhiteSpace($response)) {
            $response = $DefaultChoice
        }
        $response = $response.Trim().ToUpper()
    } while ($response -notin @('Y', 'YES', 'N', 'NO'))
    
    return $response -in @('Y', 'YES')
}

function Test-GitHubAuthentication {
    Write-Step "Checking GitHub authentication..."
    
    # Check for GitHub token in environment
    if ($env:GITHUB_TOKEN) {
        Write-Success "GitHub token found in environment variable"
        return $true
    }
    
    # Check for GitHub CLI authentication
    try {
        $token = & gh auth token 2>$null
        if ($token) {
            Write-Success "GitHub CLI authentication found"
            return $true
        }
    }
    catch {
        # GitHub CLI not available or not authenticated
    }
    
    return $false
}

function Test-NodeInstalled {
    <#
    .SYNOPSIS
        Check if Node.js is installed and meets version requirements
    .OUTPUTS
        Hashtable with IsInstalled, Version, and MeetsRequirement properties
    #>
    try {
        $nodeVersion = & node --version 2>$null
        if ($nodeVersion) {
            $version = [version]($nodeVersion.TrimStart('v').Split('.')[0..2] -join '.')
            return @{
                IsInstalled = $true
                Version = $nodeVersion
                MeetsRequirement = ($version.Major -ge 20)
            }
        }
    }
    catch {
        # Node.js not available
    }
    
    return @{
        IsInstalled = $false
        Version = $null
        MeetsRequirement = $false
    }
}

function Test-CopilotCliInstalled {
    <#
    .SYNOPSIS
        Check if GitHub Copilot CLI (@github/copilot) is installed globally
    .OUTPUTS
        Boolean indicating if Copilot CLI is installed
    #>
    
    # First try running the copilot command directly (fastest)
    try {
        $null = & copilot --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    }
    catch {
        # Command not found
    }
    
    # Fall back to checking npm global packages
    try {
        $npmList = & npm list -g @github/copilot --depth=0 2>$null
        if ($npmList -match '@github/copilot@') {
            return $true
        }
    }
    catch {
        # npm not available or package not installed
    }
    
    return $false
}

function Test-RepositoryVisibility {
    param(
        [string]$Repository
    )
    
    Write-Step "Checking repository visibility..."
    
    $apiUrl = "https://api.github.com/repos/$Repository"
    
    # Prepare headers
    $headers = @{
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "PowerShell-Installer"
    }
    
    # Add authentication if available
    $token = $env:GITHUB_TOKEN
    if (-not $token) {
        try {
            $token = & gh auth token 2>$null
        }
        catch {
            # No GitHub CLI available
        }
    }
    
    if ($token) {
        $headers["Authorization"] = "token $token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 30
        
        $isPrivate = $response.private
        $visibility = if ($isPrivate) { "private" } else { "public" }
        
        Write-Success "Repository $Repository is $visibility"
        
        return @{
            IsPrivate = $isPrivate
            Visibility = $visibility
            FullName = $response.full_name
            Owner = $response.owner.login
            Name = $response.name
        }
    }
    catch {
        $statusCode = $null
        if ($_.Exception -and $_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        
        switch ($statusCode) {
            404 {
                Write-Warning "Repository not found or you don't have access. It might be private and require authentication."
                return @{ IsPrivate = $true; Visibility = "private (assumed)"; Error = "Not found or no access" }
            }
            403 {
                Write-Warning "Access forbidden. Repository might be private or you've hit rate limits."
                return @{ IsPrivate = $true; Visibility = "private (assumed)"; Error = "Access forbidden" }
            }
            401 {
                Write-Warning "Authentication required. Repository is likely private."
                return @{ IsPrivate = $true; Visibility = "private (assumed)"; Error = "Authentication required" }
            }
            default {
                Write-Error "Failed to check repository visibility: $_"
                throw
            }
        }
    }
}

function Find-GitRepository {
    Write-Step "Looking for git repository..."
    
    $currentPath = Get-Location
    $searchPath = $currentPath
    
    do {
        $gitPath = Join-Path $searchPath ".git"
        if (Test-Path $gitPath) {
            Write-Success "Found git repository at: $searchPath"
            return $searchPath.ToString()
        }
        
        $parentPath = Split-Path $searchPath -Parent
        if ($parentPath -eq $searchPath) {
            # Reached root directory
            break
        }
        $searchPath = $parentPath
    } while ($true)
    
    Write-Info "No git repository found in current directory tree"
    return $null
}

function Test-GitIgnoreEntry {
    param(
        [string]$GitIgnorePath,
        [string]$Entry
    )
    
    if (-not (Test-Path $GitIgnorePath)) {
        return $false
    }
    
    try {
        $content = Get-Content -Path $GitIgnorePath -Encoding UTF8 -ErrorAction Stop
        
        # Check for exact entry or variations
        $patterns = @(
            $Entry,
            "$Entry/",
            "/$Entry",
            "/$Entry/"
        )
        
        foreach ($line in $content) {
            $trimmedLine = $line.Trim()
            if ($trimmedLine -and -not $trimmedLine.StartsWith('#')) {
                foreach ($pattern in $patterns) {
                    if ($trimmedLine -eq $pattern) {
                        return $true
                    }
                }
            }
        }
        
        return $false
    }
    catch {
        Write-Warning "Could not read .gitignore file: $_"
        return $false
    }
}

function Add-GitIgnoreEntry {
    param(
        [string]$GitIgnorePath,
        [string]$Entry
    )
    
    try {
        # Determine the entry format (directory with trailing slash)
        $gitignoreEntry = if ($Entry.EndsWith('/')) { $Entry } else { "$Entry/" }
        
        # Prepare the content to add
        $comment = "# GitHub Copilot CLI Automation Tools (auto-generated)"
        $newContent = "`n$comment`n$gitignoreEntry"
        
        # Check if .gitignore exists
        if (Test-Path $GitIgnorePath) {
            # Read existing content - handle empty files
            $existingContent = ""
            try {
                $rawContent = Get-Content -Path $GitIgnorePath -Encoding UTF8 -Raw -ErrorAction Stop
                if ($null -ne $rawContent) {
                    $existingContent = $rawContent
                }
            }
            catch {
                # File exists but can't be read or is empty
                $existingContent = ""
            }
            
            # Ensure the file doesn't end with the entry we're about to add
            if (-not $existingContent.TrimEnd().EndsWith($gitignoreEntry.TrimEnd())) {
                # Ensure proper newline at end of existing content
                if ($existingContent -and -not $existingContent.EndsWith("`n")) {
                    $newContent = "`n$comment`n$gitignoreEntry"
                }
                
                # Append to existing file
                Add-Content -Path $GitIgnorePath -Value $newContent.TrimStart("`n") -Encoding UTF8 -NoNewline
            }
        } else {
            # Create new .gitignore file
            $fileContent = $comment + "`n" + $gitignoreEntry
            Set-Content -Path $GitIgnorePath -Value $fileContent -Encoding UTF8 -NoNewline
        }
        
        return $true
    }
    catch {
        Write-Warning "Failed to update .gitignore: $_"
        return $false
    }
}

function Update-GitIgnore {
    param(
        [string]$InstallPath
    )
    
    Write-Step "Updating .gitignore to exclude automation tools..."
    
    # Find git repository root
    $gitRepo = Find-GitRepository
    
    if (-not $gitRepo) {
        Write-Info "No git repository detected - skipping .gitignore update"
        return
    }
    
    $gitignorePath = Join-Path $gitRepo ".gitignore"
    $installDirName = Split-Path $InstallPath -Leaf
    
    # Check if entry already exists
    if (Test-GitIgnoreEntry -GitIgnorePath $gitignorePath -Entry $installDirName) {
        Write-Success "Automation directory '$installDirName' already excluded in .gitignore"
        return
    }
    
    # Add entry to .gitignore
    $success = Add-GitIgnoreEntry -GitIgnorePath $gitignorePath -Entry $installDirName
    
    if ($success) {
        Write-Success "Added '$installDirName/' to .gitignore"
    } else {
        Write-Warning "Failed to update .gitignore - you may need to manually exclude '$installDirName/' from version control"
    }
}

# Determine installation path
if (-not $InstallPath) {
    if ($Mode -eq 'central') {
        $InstallPath = Join-Path $env:USERPROFILE ".copilot-cli-automation"
    } else {
        $InstallPath = Join-Path (Get-Location) ".copilot-cli-automation"
    }
}

# Files to download with their paths
$FilesToDownload = @(
    @{ Path = "README.md"; Required = $true },
    @{ Path = "INDEX.md"; Required = $true },
    @{ Path = "automation/README.md"; Required = $true },
    @{ Path = "automation/copilot-cli.ps1"; Required = $true },
    @{ Path = "automation/copilot-cli.properties"; Required = $true },
    @{ Path = "automation/user.prompt.md"; Required = $false },
    @{ Path = "automation/system.prompt.md"; Required = $false }
)

function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
        exit 1
    }
    Write-Success "PowerShell version check passed"
    
    # Check internet connectivity
    try {
        $null = Invoke-RestMethod -Uri "https://api.github.com" -TimeoutSec 10 -UseBasicParsing
        Write-Success "Internet connectivity confirmed"
    }
    catch {
        Write-Error "Unable to connect to GitHub API. Check your internet connection."
        exit 1
    }
    
    # Check repository visibility
    $repoInfo = Test-RepositoryVisibility -Repository $Repository
    
    if ($repoInfo.IsPrivate) {
        Write-Info "Repository is private - authentication required"
        
        # Check for authentication
        $hasAuth = Test-GitHubAuthentication
        if (-not $hasAuth) {
            Write-Error "Private repository requires GitHub authentication."
            Write-Info "Please set up authentication using one of these methods:"
            Write-Info "  1. Set environment variable: `$env:GITHUB_TOKEN = 'your_token'"
            Write-Info "  2. Use GitHub CLI: gh auth login"
            Write-Info "  3. Create token at: https://github.com/settings/personal-access-tokens/new"
            exit 1
        }
    } else {
        Write-Success "Repository is public - no authentication required"
    }
    
    # Check for Node.js (optional but recommended)
    $nodeVersion = $null
    try {
        $nodeVersion = & node --version 2>$null
        if ($nodeVersion) {
            $version = [version]($nodeVersion.TrimStart('v').Split('.')[0..2] -join '.')
            if ($version.Major -ge 20) {
                Write-Success "Node.js $nodeVersion detected (suitable for GitHub Copilot CLI)"
            } else {
                Write-Warning "Node.js $nodeVersion detected, but version 20+ is recommended for GitHub Copilot CLI"
            }
        }
    }
    catch {
        Write-Warning "Node.js not found. You may need to install Node.js 20+ for GitHub Copilot CLI"
        Write-Info "Install from: https://nodejs.org/"
    }
    
    return $repoInfo
}

function Backup-ExistingInstallation {
    if (Test-Path $InstallPath) {
        if ($Update) {
            $backupPath = "$InstallPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Write-Step "Backing up existing installation to: $backupPath"
            try {
                Copy-Item -Path $InstallPath -Destination $backupPath -Recurse -Force
                Write-Success "Backup created successfully"
                return $backupPath
            }
            catch {
                Write-Error "Failed to create backup: $_"
                exit 1
            }
        } else {
            Write-Warning "Installation directory already exists: $InstallPath"
            Write-Host ""
            Write-Host "Options:" -ForegroundColor Cyan
            Write-Host "  1. Use the -Update flag to update the existing installation" -ForegroundColor White
            Write-Host "  2. Choose a different installation path" -ForegroundColor White
            Write-Host "  3. Remove the existing directory and continue with fresh installation" -ForegroundColor White
            Write-Host ""
            
            if (Confirm-Action "Do you want to remove the existing directory and continue with fresh installation?") {
                Write-Step "Removing existing installation directory..."
                try {
                    Remove-Item -Path $InstallPath -Recurse -Force
                    Write-Success "Existing directory removed successfully"
                }
                catch {
                    Write-Error "Failed to remove existing directory: $_"
                    Write-Info "Please remove the directory manually or choose a different path"
                    exit 1
                }
            } else {
                Write-Info "Installation cancelled. Use -Update flag or choose a different path"
                exit 1
            }
        }
    }
    return $null
}

function Download-File {
    param(
        [string]$FilePath,
        [string]$DestinationPath,
        [bool]$Required = $true,
        [bool]$IsPrivate = $false
    )
    
    # Prepare headers for authentication if needed
    $headers = @{}
    $token = $null
    
    if ($IsPrivate) {
        # Get token for private repository
        $token = $env:GITHUB_TOKEN
        if (-not $token) {
            try {
                $token = & gh auth token 2>$null
            }
            catch {
                Write-Error "No GitHub token found for private repository access"
                throw
            }
        }
        
        if (-not $token) {
            Write-Error "Authentication required for private repository"
            throw
        }
    }
    
    try {
        # For private repositories, use GitHub Contents API
        # For public repositories, use raw.githubusercontent.com
        if ($IsPrivate) {
            # Use GitHub Contents API for private repositories
            $apiUrl = "https://api.github.com/repos/$Repository/contents/$FilePath`?ref=$Branch"
            $headers["Authorization"] = "token $token"
            $headers["Accept"] = "application/vnd.github.v3.raw"
            $response = Invoke-WebRequest -Uri $apiUrl -Headers $headers -UseBasicParsing -TimeoutSec 30
        } else {
            # Use raw.githubusercontent.com for public repositories
            $url = "https://raw.githubusercontent.com/$Repository/$Branch/$FilePath"
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        }
        
        # Create directory if it doesn't exist
        $destinationDir = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $destinationDir)) {
            $null = New-Item -ItemType Directory -Path $destinationDir -Force
        }
        
        # Write content to file
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($response.Content)
        [System.IO.File]::WriteAllBytes($DestinationPath, $bytes)
        
        Write-Success "Downloaded: $FilePath"
        return $true
    }
    catch {
        if ($Required) {
            Write-Error "Failed to download required file $FilePath`: $_"
            throw
        } else {
            Write-Warning "Failed to download optional file $FilePath`: $_"
            return $false
        }
    }
}

function Set-ExecutablePermissions {
    Write-Step "Setting executable permissions..."
    
    $shellScript = Join-Path $InstallPath "automation/copilot-cli.sh"
    if (Test-Path $shellScript) {
        # On Windows, we can't set Unix permissions, but we can ensure it's not read-only
        try {
            $file = Get-Item $shellScript
            if ($file.IsReadOnly) {
                $file.IsReadOnly = $false
            }
            Write-Success "Shell script permissions configured"
        }
        catch {
            Write-Warning "Could not modify shell script attributes: $_"
        }
    }
}

function Show-PostInstallInstructions {
    Write-Host ""
    Write-Host "🎉 " -ForegroundColor Green -NoNewline
    Write-Host "GitHub Copilot CLI Automation Suite installed successfully!" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📁 Installation Location: " -ForegroundColor Yellow -NoNewline
    Write-Host $InstallPath -ForegroundColor White
    Write-Host ""
    
    # Check current state of prerequisites
    $hasGitHubAuth = Test-GitHubAuthentication
    $nodeStatus = Test-NodeInstalled
    $hasCopilotCli = Test-CopilotCliInstalled
    
    # Show status of already-configured items
    $allConfigured = $true
    Write-Host "✅ Prerequisites Status:" -ForegroundColor Cyan
    
    if ($hasGitHubAuth) {
        Write-Host "  ✓ GitHub Authentication: " -ForegroundColor Green -NoNewline
        Write-Host "Configured" -ForegroundColor White
    } else {
        Write-Host "  ○ GitHub Authentication: " -ForegroundColor Yellow -NoNewline
        Write-Host "Not configured" -ForegroundColor Gray
        $allConfigured = $false
    }
    
    if ($nodeStatus.IsInstalled -and $nodeStatus.MeetsRequirement) {
        Write-Host "  ✓ Node.js: " -ForegroundColor Green -NoNewline
        Write-Host "$($nodeStatus.Version) (meets requirements)" -ForegroundColor White
    } elseif ($nodeStatus.IsInstalled) {
        Write-Host "  ⚠ Node.js: " -ForegroundColor Yellow -NoNewline
        Write-Host "$($nodeStatus.Version) (version 20+ recommended)" -ForegroundColor Gray
        $allConfigured = $false
    } else {
        Write-Host "  ○ Node.js: " -ForegroundColor Yellow -NoNewline
        Write-Host "Not installed" -ForegroundColor Gray
        $allConfigured = $false
    }
    
    if ($hasCopilotCli) {
        Write-Host "  ✓ GitHub Copilot CLI: " -ForegroundColor Green -NoNewline
        Write-Host "Installed" -ForegroundColor White
    } else {
        Write-Host "  ○ GitHub Copilot CLI: " -ForegroundColor Yellow -NoNewline
        Write-Host "Not installed" -ForegroundColor Gray
        $allConfigured = $false
    }
    Write-Host ""
    
    # Dynamic step numbering for remaining tasks
    $stepNumber = 1
    $hasSteps = $false
    
    # Only show steps that are needed
    if (-not $hasGitHubAuth) {
        if (-not $hasSteps) {
            Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
            $hasSteps = $true
        }
        Write-Host "  $stepNumber. Configure GitHub Authentication:" -ForegroundColor White
        Write-Host "     • GitHub CLI: " -ForegroundColor Gray -NoNewline
        Write-Host "gh auth login" -ForegroundColor Yellow
        Write-Host "     • OR set environment variable: " -ForegroundColor Gray -NoNewline
        Write-Host "`$env:GITHUB_TOKEN = 'your_token'" -ForegroundColor Yellow
        Write-Host ""
        $stepNumber++
    }
    
    if (-not $nodeStatus.IsInstalled) {
        if (-not $hasSteps) {
            Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
            $hasSteps = $true
        }
        Write-Host "  $stepNumber. Install Node.js 20+:" -ForegroundColor White
        Write-Host "     Download from: " -ForegroundColor Gray -NoNewline
        Write-Host "https://nodejs.org/" -ForegroundColor Yellow
        Write-Host ""
        $stepNumber++
    }
    
    if (-not $hasCopilotCli) {
        if (-not $hasSteps) {
            Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
            $hasSteps = $true
        }
        Write-Host "  $stepNumber. Install GitHub Copilot CLI:" -ForegroundColor White
        Write-Host "     " -ForegroundColor Gray -NoNewline
        Write-Host "npm install -g @github/copilot" -ForegroundColor Yellow
        Write-Host ""
        $stepNumber++
    }
    
    # Always show configuration and test steps
    if (-not $hasSteps) {
        Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
        $hasSteps = $true
    }
    
    Write-Host "  $stepNumber. Customize configuration:" -ForegroundColor White
    Write-Host "     • Edit: " -ForegroundColor Gray -NoNewline
    Write-Host "$(Join-Path $InstallPath 'automation/copilot-cli.properties')" -ForegroundColor Yellow
    Write-Host "     • Customize default prompts: " -ForegroundColor Gray -NoNewline
    Write-Host "$(Join-Path $InstallPath 'automation/user.prompt.md')" -ForegroundColor Yellow
    Write-Host "     • Customize system prompts: " -ForegroundColor Gray -NoNewline
    Write-Host "$(Join-Path $InstallPath 'automation/system.prompt.md')" -ForegroundColor Yellow
    Write-Host "     • Review example configurations in: " -ForegroundColor Gray -NoNewline
    Write-Host "$(Join-Path $InstallPath 'automation/examples/')" -ForegroundColor Yellow
    Write-Host ""
    $stepNumber++
    
    Write-Host "  $stepNumber. Test the installation:" -ForegroundColor White
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        Write-Host "     " -ForegroundColor Gray -NoNewline
        Write-Host "cd '$InstallPath'; .\automation\copilot-cli.ps1 -h" -ForegroundColor Yellow
    } else {
        Write-Host "     " -ForegroundColor Gray -NoNewline
        Write-Host "cd '$InstallPath'; ./automation/copilot-cli.sh -h" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Host "📚 Documentation:" -ForegroundColor Cyan
    Write-Host "  • Main README: " -ForegroundColor Gray -NoNewline
    Write-Host "$(Join-Path $InstallPath 'README.md')" -ForegroundColor Yellow
    Write-Host "  • Automation Guide: " -ForegroundColor Gray -NoNewline
    Write-Host "$(Join-Path $InstallPath 'automation/README.md')" -ForegroundColor Yellow
    Write-Host "  • GitHub Actions: " -ForegroundColor Gray -NoNewline
    Write-Host "$(Join-Path $InstallPath 'actions/README.md')" -ForegroundColor Yellow
    Write-Host ""
}

function Main {
    Write-Host ""
    Write-Host "🤖 GitHub Copilot CLI Automation Accelerator Installer" -ForegroundColor Magenta
    Write-Host "========================================================" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Info "Repository: $Repository"
    Write-Info "Branch: $Branch"
    Write-Info "Installation Path: $InstallPath"
    Write-Info "Mode: $Mode"
    if ($Update) { Write-Info "Update Mode: Enabled" }
    Write-Host ""
    
    try {
        # Step 1: Check prerequisites (now includes repo visibility check)
        $repoInfo = Test-Prerequisites
        
        # Step 2: Handle existing installation
        $backupPath = Backup-ExistingInstallation
        
        # Step 3: Create installation directory
        Write-Step "Creating .copilot-cli-automation directory..."
        if (-not (Test-Path $InstallPath)) {
            $null = New-Item -ItemType Directory -Path $InstallPath -Force
        }
        Write-Success "Installation directory ready: $InstallPath"
        
        # Step 3.5: Update .gitignore
        Update-GitIgnore -InstallPath $InstallPath
        
        # Step 4: Download all files (updated to pass repository info)
        Write-Step "Downloading files from repository..."
        $downloadCount = 0
        $failedCount = 0
        
        foreach ($file in $FilesToDownload) {
            $destinationPath = Join-Path $InstallPath $file.Path
            try {
                $success = Download-File -FilePath $file.Path -DestinationPath $destinationPath -Required $file.Required -IsPrivate $repoInfo.IsPrivate
                if ($success) { $downloadCount++ }
            }
            catch {
                $failedCount++
                if ($file.Required) {
                    Write-Error "Installation failed due to missing required file: $($file.Path)"
                    
                    # Restore backup if update failed
                    if ($backupPath -and (Test-Path $backupPath)) {
                        Write-Step "Restoring backup due to failed update..."
                        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
                        Move-Item -Path $backupPath -Destination $InstallPath
                        Write-Success "Backup restored"
                    }
                    exit 1
                }
            }
        }
        
        Write-Success "Downloaded $downloadCount files successfully"
        if ($failedCount -gt 0) {
            Write-Warning "$failedCount optional files could not be downloaded"
        }
        
        # Step 5: Set permissions
        Set-ExecutablePermissions
        
        # Step 6: Clean up backup if update was successful
        if ($backupPath -and (Test-Path $backupPath) -and $Update) {
            Write-Step "Cleaning up backup..."
            Remove-Item -Path $backupPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Success "Backup cleaned up"
        }
        
        # Step 7: Show post-install instructions
        Show-PostInstallInstructions
        
    }
    catch {
        Write-Error "Installation failed: $_"
        
        # Restore backup if available
        if ($backupPath -and (Test-Path $backupPath)) {
            Write-Step "Restoring backup due to failed installation..."
            Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
            Move-Item -Path $backupPath -Destination $InstallPath
            Write-Success "Backup restored"
        }
        exit 1
    }
}

# Run main function
Main