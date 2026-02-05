# GitHub Copilot CLI Automation Accelerator - Installation

> **Prerequisites:** Node.js 20+, GitHub authentication. See [README.md](README.md) for full requirements.

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
cd copilot-cli-automation-accelerator/automation
./copilot-cli.sh --agent code-review
```

```powershell
# PowerShell
cd copilot-cli-automation-accelerator\automation
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
#   .copilot-agents/my-agent/system.prompt.md

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

### 3. Learn More About Custom Agents

See the comprehensive [CUSTOM-AGENTS.md](CUSTOM-AGENTS.md) guide for:
- Complete agent structure and anatomy
- CI/CD integration examples
- Multi-project and team setups
- Advanced patterns and troubleshooting

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