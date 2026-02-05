# GitHub Copilot CLI Automation Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/neildcruz/copilot-cli-automation-accelerator?include_prereleases)](https://github.com/neildcruz/copilot-cli-automation-accelerator/releases)
[![GitHub last commit](https://img.shields.io/github/last-commit/neildcruz/copilot-cli-automation-accelerator)](https://github.com/neildcruz/copilot-cli-automation-accelerator/commits/main)

A comprehensive collection of tools for automating GitHub Copilot CLI usage in CI/CD pipelines and local development environments.

---

## 🚀 30-Second Quick Start

**Choose your path:**
- **☁️ GitHub Actions (CI/CD)** → [Jump to GitHub Actions setup](#️-for-github-actions-cicd)
- **💻 Local Scripts (Development)** → Continue reading below

### Local Development Quick Start

**Run a code review right now (zero config):**

```bash
# Navigate to your desired install location (e.g., your projects directory)
cd ~/projects  # or any directory you prefer

# Install (one-time) - creates .copilot-cli-automation/ in current directory
curl -fsSL https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh | bash

# Navigate to the automation scripts
cd .copilot-cli-automation/automation

# Run a pre-built agent
./copilot-cli.sh --agent code-review
```

```powershell
# PowerShell (Windows)
# Navigate to your desired install location (e.g., your projects directory)
cd C:\Projects  # or any directory you prefer

# Install (one-time) - creates .copilot-cli-automation\ in current directory
iwr https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1 | iex

# Navigate to the automation scripts
cd .copilot-cli-automation\automation

# Run a pre-built agent
.\copilot-cli.ps1 -Agent code-review
```

**See available agents:**
```bash
./copilot-cli.sh --list-agents
```

> **Note:** The default AI model is `claude-sonnet-4.5`. To use a different model:
> ```bash
> ./copilot-cli.sh --model gpt-5 --agent code-review
> # Or set in copilot-cli.properties: copilot.model=gpt-5
> # Check available models: gh copilot models list
> ```

---

## 📋 What Can I Do?

| Goal | Command |
|------|---------|
| **Code Review** | `./copilot-cli.sh --agent code-review` |
| **Security Scan** | `./copilot-cli.sh --agent security-analysis` |
| **Generate Tests** | `./copilot-cli.sh --agent test-generation` |
| **Generate Docs** | `./copilot-cli.sh --agent documentation` |
| **Use Shared Prompt** | `./copilot-cli.sh --use-prompt code-review` |
| **Create Custom Agent** | `./copilot-cli.sh --init --as-agent --agent-name "my-agent"` |
| **Use Custom Agent** | `./copilot-cli.sh --agent my-custom-agent` |
| **List All Agents** | `./copilot-cli.sh --list-agents` |
| **Custom Prompt** | `./copilot-cli.sh --prompt "Your task here"` |
| **Initialize Config** | `./copilot-cli.sh --init` |

---

## 📦 Installation

**One-liner install:**

```bash
# Bash (Linux/macOS)
curl -fsSL https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.sh | bash
```

```powershell
# PowerShell (Windows/Cross-platform)
iwr https://raw.githubusercontent.com/neildcruz/copilot-cli-automation-accelerator/main/install.ps1 | iex
```

> See [INSTALL.md](INSTALL.md) for advanced installation options, custom paths, and troubleshooting.

**Prerequisites:** Node.js 20+, GitHub authentication (`gh auth login` or `GITHUB_TOKEN` env var)

**Having issues?** Run `./copilot-cli.sh --diagnose` (or `.\copilot-cli.ps1 -Diagnose` on Windows) for a comprehensive system health check.

---

<details>
<summary><strong>📁 Project Structure</strong> (click to expand)</summary>

```
copilot-cli-automation-accelerator/
├── README.md                 # This file - start here
├── INDEX.md                  # Reference navigation guide
├── INSTALL.md                # Installation details
├── actions/                  # GitHub Actions integration
│   ├── copilot-cli-action.yml      # Reusable workflow
│   └── ...
└── automation/              # Local automation scripts
    ├── copilot-cli.sh      # Bash script (Linux/macOS)
    ├── copilot-cli.ps1     # PowerShell script (Windows/cross-platform)
    ├── copilot-cli.properties      # Configuration file
    └── examples/           # Pre-built agents
        ├── code-review/
        ├── security-analysis/
        ├── test-generation/
        ├── documentation-generation/
        ├── refactoring/
        └── cicd-analysis/
```

</details>

<details>
<summary><strong>🔧 For GitHub Actions (CI/CD)</strong> (click to expand)</summary>

Copy the reusable workflow to your repository:

```bash
cp actions/copilot-cli-action.yml /path/to/your/repo/.github/workflows/
```

Create a workflow that uses it:

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

See [actions/README.md](actions/README.md) for full documentation.

</details>

<details>
<summary><strong>💻 For Local Development</strong> (click to expand)</summary>

```bash
cd automation/

# Use a pre-built agent
./copilot-cli.sh --agent code-review

# Use a custom prompt
./copilot-cli.sh --prompt "Review the code for issues"

# Initialize your own configuration
./copilot-cli.sh --init

# See all options
./copilot-cli.sh --help
```

See [automation/README.md](automation/README.md) for full documentation.

</details>

## 🎯 Use Cases

<details>
<summary><strong>GitHub Actions Integration</strong></summary>

- **Automated Code Reviews**: Integrate AI-powered code analysis into pull request workflows
- **Security Scanning**: Automated vulnerability detection with custom prompts
- **Documentation Generation**: Auto-generate and update project documentation
- **Test Generation**: Create comprehensive test suites based on code analysis
- **MCP Server Integration**: Connect to custom Model Context Protocol servers for specialized tools

</details>

<details>
<summary><strong>Local Automation</strong></summary>

- **Development Workflow**: Streamline code review and analysis during development
- **Batch Processing**: Analyze multiple files or projects with consistent configuration
- **Custom Tool Integration**: Use MCP servers to extend Copilot CLI capabilities
- **Cross-Platform Support**: Same functionality across Linux, macOS, and Windows

</details>

## 🔧 Key Features

- **Complete Automation** - Auto-installation of GitHub Copilot CLI, dependency management, environment setup
- **Flexible Configuration** - Properties files with command-line overrides, system prompts, tool permissions
- **MCP Server Support** - Local Python/Node.js servers, HTTP REST, Server-sent events
- **Enterprise Ready** - Security-focused design, logging, timeout management, authentication

## 📖 Documentation

| Component | Documentation |
|-----------|---------------|
| **Creating Custom Agents** | [CUSTOM-AGENTS.md](CUSTOM-AGENTS.md) |
| GitHub Actions | [actions/README.md](actions/README.md) |
| Local Scripts | [automation/README.md](automation/README.md) |
| Pre-built Agents | [automation/examples/](automation/examples/) |
| Navigation Guide | [INDEX.md](INDEX.md) |

<details>
<summary><strong>🛡️ Security Considerations</strong></summary>

- **Tool Permissions**: Granular control over which tools Copilot CLI can execute
- **Path Restrictions**: Limit filesystem access to specific directories
- **Environment Variables**: Secure handling of sensitive configuration data
- **Authentication**: GitHub token management and validation
- **Validation**: Input validation and error handling throughout

</details>

<details>
<summary><strong>🤝 Contributing</strong></summary>

This automation suite is designed to be modular and extensible. Each component follows established patterns:

- **Configuration**: Properties-based with command-line overrides
- **Error Handling**: Comprehensive validation and helpful error messages  
- **Documentation**: Clear examples and usage patterns
- **Security**: Principle of least privilege with configurable restrictions

</details>

---

**Need help?** Run `./copilot-cli.sh --help` or check the [automation/README.md](automation/README.md) for detailed options.