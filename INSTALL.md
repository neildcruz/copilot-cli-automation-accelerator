# GitHub Copilot CLI Automation Accelerator - Installation

> **Prerequisites:** 
> - Node.js 20+
> - GitHub authentication (see below)
> - **Windows users:** PowerShell execution policy must allow scripts (see [PowerShell Execution Policy](#powershell-execution-policy-windows))
> 
> See [README.md](README.md) for full requirements.

## Prerequisites

### PowerShell Execution Policy (Windows)

**Before installing on Windows**, ensure PowerShell can execute scripts:

```powershell
# Check current execution policy
Get-ExecutionPolicy

# If it shows 'Restricted', update it:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify the change
Get-ExecutionPolicy
# Should show: RemoteSigned
```

**Alternative for single session:**
```powershell
# Temporarily bypass execution policy for this installation only
powershell -ExecutionPolicy Bypass -File install.ps1
```

This is a **one-time setup** required for PowerShell scripts to run on Windows systems.

---

## Quick Install

> **After Installation:** See [Next Steps](#next-steps) to create your first custom agent for CI/CD pipelines.

### Windows (PowerShell)

**Direct execution (one-liner):**
```powershell
# PowerShell 5.1+ / Windows PowerShell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1'))

# PowerShell 7+ / PowerShell Core (cross-platform)
Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1' -UseBasicParsing).Content

# Short version (PowerShell 7+)
iwr https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1 | iex
```

**Download and run locally:**
```powershell
# Download first
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1' -OutFile 'install.ps1'
# Then execute
.\install.ps1
```

**Alternative download methods:**
```powershell
# Using curl (if available on Windows)
curl -O https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1

# Using wget (if available)
wget https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1

# Using Start-BitsTransfer (Windows built-in)
Start-BitsTransfer -Source 'https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1' -Destination '.\install.ps1'
```

### Linux/macOS (Bash)

**Direct execution (one-liner):**
```bash
curl -fsSL https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh | bash
```

**Download and run locally:**
```bash
wget https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh
chmod +x install.sh
./install.sh
```

---

## Next Steps

After installation, test with built-in examples and create custom agents for your projects:

### 1. Test with Built-in Examples

```bash
# Test installation
cd .copilot-cli-automation/automation
./copilot-cli.sh --agent code-review
```

```powershell
# PowerShell
cd .copilot-cli-automation\automation
.\copilot-cli.ps1 -Agent code-review
```

### 2. Create Your First Custom Agent

```bash
# Go to your project
cd /path/to/your/project

# Create a custom agent in your project
/path/to/copilot-cli.sh --init --as-agent --agent-name "my-agent"

# This creates .copilot-agents/my-agent/ with templates
# Edit the prompts:
#   .copilot-agents/my-agent/user.prompt.md
#   .copilot-agents/my-agent/my-agent.agent.md

# Run your custom agent
/path/to/copilot-cli.sh --agent my-agent
```

```powershell
# PowerShell
cd C:\path\to\your\project
\path\to\copilot-cli.ps1 -Init -AsAgent -AgentName "my-agent"

# Edit the prompts and run
\path\to\copilot-cli.ps1 -Agent my-agent
```

### 3. Explore Advanced Features

**For custom agent creation:**
- See [CUSTOM-AGENTS.md](CUSTOM-AGENTS.md) for complete guide on creating specialized agents

**For general usage:**
- Return to [README.md](README.md) for usage examples and available commands

**For component-specific details:**
- [automation/README.md](automation/README.md) - Local script reference
- [actions/README.md](actions/README.md) - GitHub Actions reference

---

## Installation Options

### Update Behavior

When using `--update` / `-Update` flag to update an existing installation:

✅ **Safe Update Process:**
1. Existing installation backed up to `.copilot-cli-automation.backup.TIMESTAMP/`
2. New files downloaded from repository
3. Your custom configurations preserved (`.copilot-agents/`, custom `copilot-cli.properties`)
4. On failure: Automatic rollback to backup

✅ **What's Preserved:**
- Custom agent directories (`.copilot-agents/`)
- Modified configuration files
- Local prompt customizations
- User-specific settings

✅ **What's Updated:**
- Core scripts (`copilot-cli.sh`, `copilot-cli.ps1`)
- Built-in example agents
- Documentation files
- Action workflow templates

```bash
# Example: Safe update command
./install.sh --update

# Backup location (if rollback needed)
ls .copilot-cli-automation.backup.*/
```

```powershell
# PowerShell update
.\install.ps1 -Update

# Check backups
Get-ChildItem .copilot-cli-automation.backup.*
```

---

## Installation Options

### PowerShell Script (`install.ps1`)

```powershell
# Install in current directory (default)
.\install.ps1

# Install in central location (~/copilot-tools)
.\install.ps1 -Mode central

# Update existing installation
.\install.ps1 -Update

# Custom installation path
.\install.ps1 -InstallPath "C:\Tools\copilot-automation"

# Install from specific branch
.\install.ps1 -Branch develop

# Install from different repository
.\install.ps1 -Repository "username/fork-repo"
```

**Parameters:**
- `-InstallPath` - Custom installation directory
- `-Mode` - `current` (default) or `central` (~/copilot-tools)
- `-Update` - Update existing installation
- `-Branch` - Git branch to download from (default: main)
- `-Repository` - GitHub repository (default: neildcruz/copilot-cli-automation-accelerator)

### Bash Script (`install.sh`)

```bash
# Install in current directory (default)
./install.sh

# Install in central location (~/copilot-tools)
./install.sh --mode central

# Update existing installation
./install.sh --update

# Custom installation path
./install.sh --path ~/my-tools

# Install from specific branch with verbose output
./install.sh --branch develop --verbose

# Install from different repository
./install.sh --repo "username/fork-repo"
```

**Options:**
- `-p, --path PATH` - Custom installation directory
- `-m, --mode MODE` - `current` (default) or `central` (~/copilot-tools)
- `-u, --update` - Update existing installation
- `-b, --branch BRANCH` - Git branch to download from (default: main)
- `-r, --repo REPO` - GitHub repository (default: neildcruz/copilot-cli-automation-accelerator)
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help message

## Installation Modes

### Current Directory Mode (default)
- Installs to `./copilot-cli-automation-accelerator/`
- Best for project-specific installations
- Allows per-project customization

### Central Mode
- **Windows**: `%USERPROFILE%\copilot-tools\`
- **Linux/macOS**: `~/copilot-tools/`
- Best for system-wide access
- Centralized configuration management

## What Gets Installed

The scripts download the complete automation suite. See [README.md](README.md) for project structure details.

## Features

### ✅ Comprehensive
- Downloads all required and optional files
- Maintains proper directory structure
- Preserves file permissions (Unix-like systems)

### ✅ Safe Installation
- Automatic backup of existing installations during updates
- Rollback on failure
- Prerequisite validation
- Error handling and recovery

### ✅ Cross-Platform
- **PowerShell**: Windows, Linux, macOS (PowerShell Core)
- **Bash**: Linux, macOS, Windows (WSL/Git Bash)
- Platform-specific optimizations

### ✅ Network Resilient
- Multiple download attempts
- Connection validation
- Graceful handling of optional files
- Progress feedback

### ✅ User Friendly
- Colored output with clear status indicators
- Comprehensive post-install instructions
- Detailed help and usage information
- Verbose mode for troubleshooting

## Post-Installation

After successful installation, you'll need to:

1. **Configure GitHub Authentication**
   ```bash
   gh auth login
   # OR
   export GITHUB_TOKEN='your_token'
   ```

2. **Install GitHub Copilot CLI** (if not already installed)
   ```bash
   npm install -g @github/copilot
   ```

3. **Customize Configuration**
   - Edit `automation/copilot-cli.properties`
   - Review example configurations in `automation/examples/`

4. **Test the Installation**
   ```bash
   # Linux/macOS
   ./automation/copilot-cli.sh -h
   
   # Windows
   .\automation\copilot-cli.ps1 -h
   ```

## Troubleshooting

### Run System Diagnostics

**First step for any installation issue:** Run the comprehensive diagnostic check:

```bash
# Bash (Linux/macOS)
./automation/copilot-cli.sh --diagnose
```

```powershell
# PowerShell (Windows)
.\automation\copilot-cli.ps1 -Diagnose
```

**What it checks:**
- ✅ GitHub authentication (all methods: `GITHUB_TOKEN`, `GH_TOKEN`, `gh` CLI)
- ✅ Node.js installation and version compatibility
- ✅ GitHub Copilot CLI installation status
- ✅ Agent discovery paths and directories
- ✅ Environment variables configuration
- ✅ MCP server configuration (if applicable)
- ✅ File permissions and accessibility

**Share the diagnostic output when reporting issues** - it provides complete context for troubleshooting.

---

### Common Issues

**Network connectivity errors:**
```bash
# Test connectivity manually
curl -s https://api.github.com
wget --spider https://api.github.com
```

**Permission errors on Unix-like systems:**
```bash
# Make scripts executable
chmod +x install.sh
chmod +x automation/copilot-cli.sh
```

**PowerShell execution policy (Windows):**
```powershell
# Allow script execution (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Check current execution policy
Get-ExecutionPolicy

# Temporarily bypass execution policy for one session
powershell -ExecutionPolicy Bypass -File install.ps1
```

**PowerShell version compatibility:**
```powershell
# Check your PowerShell version
$PSVersionTable.PSVersion

# The script supports:
# - Windows PowerShell 5.1+ (Windows only)
# - PowerShell 7+ (cross-platform)
```

### Verbose Mode

Use verbose mode for detailed troubleshooting:
```bash
# Bash
./install.sh --verbose

# PowerShell (debug mode)
$DebugPreference = 'Continue'; .\install.ps1
```

### Manual Installation

If automatic installation fails, you can manually download files:
```bash
# Download individual files
curl -O https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/automation/copilot-cli.sh
```

## Security Considerations

- Scripts download from official GitHub repository
- No elevated privileges required
- Optional file downloads fail gracefully
- Backup and rollback protection
- No sensitive data transmission

## Support

- 📖 **Documentation**: Check the main README.md after installation
- 🐛 **Issues**: Report problems in the GitHub repository
- 💬 **Discussions**: Community support in repository discussions
- 🔧 **Customization**: See automation/examples/ for configuration patterns