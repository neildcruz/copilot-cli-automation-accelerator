# GitHub Copilot CLI Automation Suite

A comprehensive collection of tools for automating GitHub Copilot CLI usage in CI/CD pipelines and local development environments.

## 📁 Project Structure

```
output/
├── README.md                 # This file - project overview
├── INDEX.md                  # Detailed navigation guide
├── actions/                  # GitHub Actions integration
│   ├── README.md            # GitHub Actions documentation
│   ├── QUICK_START.md       # Quick start guide for GitHub Actions
│   ├── copilot-cli-action.yml      # Reusable GitHub Action workflow
│   └── example-copilot-usage.yml   # Example workflows
└── automation/              # Local automation scripts
    ├── README.md           # Automation scripts documentation
    ├── copilot-cli.sh      # Bash script for Linux/macOS
    ├── copilot-cli.ps1     # PowerShell script for Windows/cross-platform
    ├── copilot-cli.properties      # Sample configuration file
    ├── user.prompt.md      # Default user prompt file
    ├── system.prompt.md    # Default system prompt file
    └── examples/
        ├── README.md       # Agent examples documentation
        ├── mcp-config.json # Sample MCP server configuration
        ├── code-review/    # Code review agent with prompt files
        ├── security-analysis/  # Security analysis agent with prompt files
        ├── test-generation/    # Test generation agent with prompt files
        ├── documentation-generation/  # Documentation agent with prompt files
        ├── refactoring/    # Code refactoring agent with prompt files
        └── cicd-analysis/  # CI/CD analysis agent with prompt files
```

## 🚀 Quick Start

### 📦 One-Line Installation

**PowerShell (Windows/Cross-platform):**
```powershell
$token = gh auth token; iwr "https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1" -Headers @{Authorization = "Bearer $token"} | Select-Object -ExpandProperty Content | iex
```

**Bash (Linux/macOS):**
```bash
curl -fsSL -H "Authorization: Bearer $(gh auth token)" https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh | bash
```

> 📋 **See [INSTALL.md](INSTALL.md) for complete installation options and troubleshooting**

### For GitHub Actions (CI/CD)
If you want to integrate Copilot CLI into your GitHub workflows:

```bash
cd actions/
# Copy copilot-cli-action.yml to your .github/workflows/ directory
# See README.md for full setup instructions
```

### For Local Development
If you want to run Copilot CLI locally with configuration management:

```bash
cd automation/
# For Linux/macOS
./copilot-cli.sh --prompt "Review the code for issues"

# For Windows/PowerShell
.\copilot-cli.ps1 -Prompt "Review the code for issues"
# See README.md for full configuration options
```

## 🎯 Use Cases

### GitHub Actions Integration
- **Automated Code Reviews**: Integrate AI-powered code analysis into pull request workflows
- **Security Scanning**: Automated vulnerability detection with custom prompts
- **Documentation Generation**: Auto-generate and update project documentation
- **Test Generation**: Create comprehensive test suites based on code analysis
- **MCP Server Integration**: Connect to custom Model Context Protocol servers for specialized tools

### Local Automation
- **Development Workflow**: Streamline code review and analysis during development
- **Batch Processing**: Analyze multiple files or projects with consistent configuration
- **Custom Tool Integration**: Use MCP servers to extend Copilot CLI capabilities
- **Cross-Platform Support**: Same functionality across Linux, macOS, and Windows

## 🔧 Key Features

### ✅ **Complete Automation**
- Auto-installation of GitHub Copilot CLI (configurable)
- Automatic dependency management
- Environment validation and setup

### ✅ **Flexible Configuration**
- Properties file configuration with command-line overrides
- System prompts for guided AI behavior
- Comprehensive tool permission management
- Environment variable expansion support

### ✅ **MCP Server Support**
- Local Python/Node.js MCP servers
- HTTP REST API integration
- Server-sent events (SSE) support
- Built-in and custom MCP server management

### ✅ **Enterprise Ready**
- Security-focused design with tool restrictions
- Comprehensive logging and error handling
- Timeout management and resource control
- GitHub token and authentication support

## 📖 Documentation

### GitHub Actions
- **[actions/README.md](actions/README.md)** - Complete GitHub Action setup and configuration
- **[actions/QUICK_START.md](actions/QUICK_START.md)** - Quick start guide with common examples

### Local Automation
- **[automation/README.md](automation/README.md)** - Complete script setup and configuration
- **[automation/examples/](automation/examples/)** - Configuration examples and templates

### General
- **[INDEX.md](INDEX.md)** - Detailed navigation guide and component overview

## 🛡️ Security Considerations

- **Tool Permissions**: Granular control over which tools Copilot CLI can execute
- **Path Restrictions**: Limit filesystem access to specific directories
- **Environment Variables**: Secure handling of sensitive configuration data
- **Authentication**: GitHub token management and validation
- **Validation**: Input validation and error handling throughout

## 🌟 Getting Started

1. **Choose your integration method**:
   - Use **actions/** for GitHub workflow integration
   - Use **automation/** for local development automation

2. **Review the documentation**:
   - Start with the Quick Start guide in your chosen folder
   - Review the comprehensive README for advanced configuration

3. **Try the examples**:
   - GitHub Actions: Check `example-copilot-usage.yml`
   - Local Scripts: Use the sample `copilot-cli.properties`

4. **Customize for your needs**:
   - Configure MCP servers for specialized tools
   - Set up system prompts for consistent AI guidance
   - Adjust security settings and tool permissions

## 🤝 Contributing

This automation suite is designed to be modular and extensible. Each component follows established patterns:

- **Configuration**: Properties-based with command-line overrides
- **Error Handling**: Comprehensive validation and helpful error messages  
- **Documentation**: Clear examples and usage patterns
- **Security**: Principle of least privilege with configurable restrictions

## 📋 Requirements

### GitHub Actions
- GitHub repository with Actions enabled
- GitHub Copilot subscription
- Node.js 20+ (provided by GitHub runners)

### Local Automation
- **Node.js 20+** - Required for Copilot CLI
- **GitHub Copilot CLI** - Auto-installed by default
- **GitHub Authentication** - GitHub Personal Access Token, `gh auth login`, or environment variables
- **Platform**: Linux, macOS, or Windows with PowerShell

---

**Need help?** Check the detailed documentation in each folder or review the examples provided.