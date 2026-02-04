# Contributing to GitHub Copilot CLI Automation Suite

Thank you for your interest in contributing to this project! This guide will help you get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)

## Code of Conduct

This project has a Code of Conduct to ensure a professional and respectful environment. By participating, you are expected to uphold these standards. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Environment details** (OS, Node.js version, shell, etc.)
- **Relevant logs or error messages**
- **Screenshots** if applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear use case** for the enhancement
- **Expected behavior** and benefits
- **Possible implementation approach** (if you have ideas)
- **Alternative solutions** you've considered

### Pull Requests

We actively welcome your pull requests! See the [Pull Request Process](#pull-request-process) section below.

## Development Setup

### Prerequisites

- **Node.js 20+** - Required for GitHub Copilot CLI
- **Git** - For version control
- **GitHub CLI** (optional) - For authentication testing
- **PowerShell 7+** or **Bash** - For testing automation scripts

### Installation

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/yourusername/copilot-cli-automation-accelerator.git
   cd copilot-cli-automation-accelerator
   ```

2. **Install GitHub Copilot CLI** (if not already installed):
   ```bash
   npm install -g @github/copilot
   ```

3. **Authenticate with GitHub**:
   ```bash
   gh auth login
   # or set GITHUB_TOKEN environment variable
   ```

For detailed installation instructions, see [INSTALL.md](INSTALL.md).

### Project Structure

```
.
├── actions/              # GitHub Actions workflows
├── automation/           # Local automation scripts
│   ├── copilot-cli.sh   # Bash script for Linux/macOS
│   ├── copilot-cli.ps1  # PowerShell script
│   └── examples/        # Configuration examples
├── sample-cli-agents/   # Example implementations
└── [platform]-ci/       # CI/CD platform integrations
```

## Pull Request Process

### Before Submitting

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Follow the [coding standards](#coding-standards)
   - Add tests if applicable
   - Update documentation as needed

3. **Test your changes**:
   - Test on relevant platforms (Linux/macOS/Windows)
   - Verify GitHub Actions workflows if modified
   - Test automation scripts with various configurations

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Brief description of changes"
   ```
   - Use clear, descriptive commit messages
   - Reference issue numbers when applicable (#123)

### Submitting the PR

1. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** with:
   - **Clear title** describing the change
   - **Description** explaining what and why
   - **Related issues** linked
   - **Testing performed** documented
   - **Screenshots** if UI changes

3. **Address review feedback**:
   - Respond to comments promptly
   - Make requested changes
   - Update documentation if needed

### PR Acceptance Criteria

- ✅ Code follows project style guidelines
- ✅ All tests pass (if applicable)
- ✅ Documentation is updated
- ✅ Commit messages are clear
- ✅ No merge conflicts
- ✅ Approved by maintainer(s)

## Coding Standards

### Shell Scripts (Bash)

- Use `#!/bin/bash` shebang
- Use 2-space indentation
- Quote variables: `"$VARIABLE"`
- Use `set -e` for error handling
- Add comments for complex logic
- Follow [ShellCheck](https://www.shellcheck.net/) recommendations

### PowerShell Scripts

- Use 4-space indentation
- Use approved verbs (Get-, Set-, etc.)
- Include parameter validation
- Add comment-based help
- Use `$PSCmdlet.ThrowTerminatingError()` for errors
- Follow [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)

### YAML Files

- Use 2-space indentation
- Use lowercase for keys
- Add comments for complex configurations
- Validate syntax before committing
- Follow GitHub Actions naming conventions

### Markdown Documentation

- Use ATX-style headers (`#`)
- Include table of contents for long docs
- Use code blocks with language tags
- Add links to related documentation
- Keep line length reasonable (~100 chars)

### General Guidelines

- **DRY principle**: Don't Repeat Yourself
- **KISS principle**: Keep It Simple, Stupid
- **Error handling**: Always handle errors gracefully
- **Security**: Never commit secrets or tokens
- **Comments**: Explain why, not what
- **Naming**: Use descriptive, consistent names

## Testing

### Manual Testing

For automation scripts:

1. **Test basic execution**:
   ```bash
   # Bash
   ./automation/copilot-cli.sh --prompt "Test prompt"
   
   # PowerShell
   .\automation\copilot-cli.ps1 -Prompt "Test prompt"
   ```

2. **Test with configuration files**:
   - Test various `copilot-cli.properties` configurations
   - Test MCP server integration
   - Test tool permissions

3. **Test error conditions**:
   - Missing dependencies
   - Invalid configurations
   - Authentication failures

### GitHub Actions Testing

1. **Test workflows locally** (using [act](https://github.com/nektos/act) if possible)
2. **Test in fork** before submitting PR
3. **Verify action outputs** and artifacts

### Platform Testing

If your changes affect cross-platform functionality, test on:

- **Linux** (Ubuntu recommended)
- **macOS** (latest version)
- **Windows** (with PowerShell 7+)

## Questions?

- **General questions**: Open a GitHub Discussion
- **Bug reports**: Create an issue
- **Security issues**: See [SECURITY.md](SECURITY.md)

## License

By contributing, you agree that your contributions will be licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

Thank you for contributing! Your efforts help make this project better for everyone.
