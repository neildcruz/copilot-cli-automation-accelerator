# GitHub Copilot CLI Automation - Navigation Guide

This package provides comprehensive automation tools for GitHub Copilot CLI, organized into modular components for different use cases.

## 📁 Package Structure

### GitHub Actions Integration (`actions/`)
Complete GitHub Actions workflows for CI/CD automation:

- **[copilot-cli-action.yml](actions/copilot-cli-action.yml)** - Main reusable GitHub Action workflow
- **[example-copilot-usage.yml](actions/example-copilot-usage.yml)** - Example workflows demonstrating various use cases
- **[README.md](actions/README.md)** - Complete GitHub Action documentation and configuration guide
- **[QUICK_START.md](actions/QUICK_START.md)** - Quick start guide with common patterns

### Local Automation Scripts (`automation/`)
Cross-platform scripts for local development automation:

- **[copilot-cli.sh](automation/copilot-cli.sh)** - Bash script for Linux/macOS environments
- **[copilot-cli.ps1](automation/copilot-cli.ps1)** - PowerShell script for Windows/cross-platform
- **[copilot-cli.properties](automation/copilot-cli.properties)** - Sample configuration file
- **[README.md](automation/README.md)** - Complete scripts documentation and usage guide
- **[examples/mcp-config.json](automation/examples/mcp-config.json)** - Sample MCP server configuration

## 🚀 Quick Setup

### GitHub Action Setup

1. **Copy the main action** to your repository:
   ```bash
   cp actions/copilot-cli-action.yml /path/to/your/repo/.github/workflows/
   ```

2. **Create a simple workflow** to use the action:
   ```yaml
   # .github/workflows/ai-review.yml
   name: AI Code Review
   
   on:
     pull_request:
       types: [opened, synchronize]
   
   jobs:
     review:
       uses: ./.github/workflows/copilot-cli-action.yml
       with:
         prompt: "Review this PR for code quality and potential issues"
         allow_all_tools: true
       secrets:
         GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

### Local Script Setup

1. **Install prerequisites** (Node.js 20+ required):
   ```bash
   # Copilot CLI will be auto-installed by default
   # Or install manually: npm install -g @github/copilot
   
   # Authenticate with GitHub
   gh auth login
   ```

2. **Make scripts executable** (Linux/macOS):
   ```bash
   chmod +x automation/copilot-cli.sh
   ```

3. **Run locally**:
   ```bash
   # Bash (Linux/macOS)
   cd automation/
   ./copilot-cli.sh --prompt "Review the code for issues"
   
   # PowerShell (Windows/Cross-platform)
   cd automation/
   .\copilot-cli.ps1 -Prompt "Review the code for issues"
   ```

4. **Customize configuration**:
   ```bash
   # Edit automation/copilot-cli.properties
   # See automation/README.md for all options
   ```

## 📖 Documentation

### GitHub Actions
- **[actions/QUICK_START.md](actions/QUICK_START.md)** - Get started with GitHub Actions in minutes
- **[actions/README.md](actions/README.md)** - Full GitHub Action documentation with all features
- **[actions/example-copilot-usage.yml](actions/example-copilot-usage.yml)** - Real-world GitHub Action examples

### Local Automation
- **[automation/README.md](automation/README.md)** - Complete guide for local script execution
- **[automation/copilot-cli.properties](automation/copilot-cli.properties)** - Sample configuration file for scripts
- **[automation/examples/mcp-config.json](automation/examples/mcp-config.json)** - MCP server configuration examples

## 🔧 Key Features

### ✅ Comprehensive Configuration
- **Flexible Prompts**: Execute any prompt with customizable parameters
- **MCP Server Support**: Inline JSON or external file configuration
- **Model Selection**: GPT-5, Claude Sonnet models
- **Tool Permissions**: Fine-grained allow/deny control
- **Path Management**: Configurable directory access
- **Environment Variables**: Secure handling via GitHub Secrets

### ✅ Multiple Usage Patterns
- **Reusable Workflow**: Call from other workflows
- **Manual Dispatch**: Trigger with custom parameters
- **CI/CD Integration**: Seamless pipeline integration
- **Multi-Job Workflows**: Complex analysis pipelines

### ✅ Security & Best Practices
- **Principle of Least Privilege**: Granular permissions
- **Path Restrictions**: Limited directory access
- **Secret Management**: Secure environment variables
- **Comprehensive Logging**: Debug and audit trails

## 🎯 Common Use Cases

### Code Review Automation
```yaml
prompt: "Review this PR for code quality, bugs, and best practices"
allow_all_tools: true
```

### Security Analysis
```yaml
prompt: "Scan for security vulnerabilities and provide fixes"
allowed_tools: "write,grep,find"
denied_tools: "shell,bash"
```

### Documentation Generation
```yaml
prompt: "Generate missing documentation and improve existing docs"
additional_directories: "./docs,./README.md"
```

### Custom Tool Integration
```yaml
mcp_config: |
  {
    "mcpServers": {
      "custom-tools": {
        "command": "python",
        "args": ["tools/analyzer.py"],
        "tools": ["*"]
      }
    }
  }
```

## 🔗 MCP Server Integration

The action supports three types of MCP servers:

1. **Local Servers** - Python, Node.js, or any executable
2. **HTTP Servers** - REST API integration
3. **SSE Servers** - Server-sent events for real-time data

See `examples/mcp-config.json` for configuration examples.

## 🛠️ Environment Variables

Configure MCP servers securely:

```yaml
secrets:
  MCP_ENV_VARS: |
    {
      "DATABASE_URL": "${{ secrets.DATABASE_URL }}",
      "API_TOKEN": "${{ secrets.API_TOKEN }}"
    }
```

Variables support expansion syntax:
- `${VAR}` or `$VAR` - Direct expansion
- `${VAR:-default}` - Fallback values

## 📊 Monitoring & Debugging

### Automatic Features
- **Execution Summaries** - Detailed workflow summaries
- **Log Artifacts** - Automatic log upload
- **Debug Logging** - Configurable log levels
- **Error Handling** - Comprehensive error reporting

### Debug Tips
1. Enable debug logging: `log_level: "debug"`
2. Check uploaded artifacts for detailed logs
3. Start with minimal permissions and expand
4. Validate MCP JSON syntax before use

## 🔄 Integration Examples

### Pull Request Analysis
```yaml
on:
  pull_request:
    types: [opened, synchronize]
```

### Scheduled Code Health Checks
```yaml
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly
```

### Manual Workflow Dispatch
```yaml
on:
  workflow_dispatch:
    inputs:
      analysis_type:
        type: choice
        options: ['security', 'quality', 'docs']
```

## 🚀 Getting Started

1. **Read the Quick Start**: [QUICK_START.md](QUICK_START.md)
2. **Review Examples**: [example-copilot-usage.yml](example-copilot-usage.yml)
3. **Check Full Docs**: [README.md](README.md)
4. **Copy and Customize**: Start with basic examples and expand

## 📝 License & Support

This action is designed to work with the GitHub Copilot CLI and requires:
- Active GitHub Copilot subscription
- Appropriate repository permissions
- Node.js 22+ runtime environment

For troubleshooting, check the comprehensive debugging section in the documentation.