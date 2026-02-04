# GitHub Copilot CLI Automation - Reference Guide

> **New here?** Start with [README.md](README.md) to get up and running in 30 seconds.

This is a reference guide for navigating the project structure.

## 📁 Package Structure

### GitHub Actions Integration (`actions/`)

| File | Purpose |
|------|---------|
| [copilot-cli-action.yml](actions/copilot-cli-action.yml) | Main reusable GitHub Action workflow |
| [example-copilot-usage.yml](actions/example-copilot-usage.yml) | Example workflows |
| [README.md](actions/README.md) | Full documentation |
| [QUICK_START.md](actions/QUICK_START.md) | Quick start guide |

### Local Automation Scripts (`automation/`)

| File | Purpose |
|------|---------|
| [copilot-cli.sh](automation/copilot-cli.sh) | Bash script (Linux/macOS) |
| [copilot-cli.ps1](automation/copilot-cli.ps1) | PowerShell script (Windows/cross-platform) |
| [copilot-cli.properties](automation/copilot-cli.properties) | Configuration template |
| [README.md](automation/README.md) | Full documentation |

### Pre-built Agents (`automation/examples/`)

| Agent | Purpose |
|-------|---------|
| [code-review/](automation/examples/code-review/) | Code quality and best practices review |
| [security-analysis/](automation/examples/security-analysis/) | Security vulnerability scanning |
| [test-generation/](automation/examples/test-generation/) | Unit and integration test generation |
| [documentation-generation/](automation/examples/documentation-generation/) | Technical documentation creation |
| [refactoring/](automation/examples/refactoring/) | Code structure improvements |
| [cicd-analysis/](automation/examples/cicd-analysis/) | CI/CD pipeline optimization |

**Quick access:** Run `./copilot-cli.sh --list-agents` to see all available agents.

---

## 🔗 Quick Links

| What you want to do | Where to go |
|---------------------|-------------|
| Get started quickly | [README.md](README.md) |
| Install the toolkit | [INSTALL.md](INSTALL.md) |
| Set up GitHub Actions | [actions/README.md](actions/README.md) |
| Run locally | [automation/README.md](automation/README.md) |
| Browse pre-built agents | [automation/examples/](automation/examples/) |
| Configure MCP servers | [automation/examples/mcp-config.json](automation/examples/mcp-config.json) |

---

## 📝 Requirements

- **Node.js 20+**
- **GitHub Copilot subscription**
- **GitHub authentication** (`gh auth login` or `GITHUB_TOKEN` environment variable)